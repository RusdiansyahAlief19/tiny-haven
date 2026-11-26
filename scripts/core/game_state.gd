extends Node
## Status global Tiny Haven, didaftarkan sebagai autoload bernama GameState.
##
## Tugasnya:
##   1. menyimpan dan memuat pengaturan grafis (user://settings.cfg),
##   2. menyimpan dan memuat dunia buatan pemain (user://tiny_haven_world.json),
##   3. membawa pesan dari menu utama ke dunia: dunia baru atau lanjutkan.

const SETTINGS_PATH := "user://settings.cfg"
const SAVE_PATH := "user://tiny_haven_world.json"
## Bisa diganti oleh skrip tes supaya simpanan pemain tidak tertimpa.
var save_path := SAVE_PATH
const SAVE_VERSION := 1

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const WORLD_SCENE := "res://scenes/world/main.tscn"

## Pilihan kualitas bayangan: ukuran atlas bayangan matahari/bulan dan
## kualitas filter bayangan lembut (PCF). Makin tinggi makin halus tepinya.
const SHADOW_LABELS: Array[String] = ["Rendah", "Sedang", "Tinggi"]
const SHADOW_ATLAS: Array[int] = [2048, 4096, 4096]
const SHADOW_FILTER: Array[int] = [
	RenderingServer.SHADOW_QUALITY_HARD,
	RenderingServer.SHADOW_QUALITY_SOFT_LOW,
	RenderingServer.SHADOW_QUALITY_SOFT_HIGH,
]
## Pilihan anti-aliasing MSAA untuk tepi model 3D.
const MSAA_LABELS: Array[String] = ["Mati", "2x", "4x"]
const MSAA_VALUES: Array[int] = [
	Viewport.MSAA_DISABLED,
	Viewport.MSAA_2X,
	Viewport.MSAA_4X,
]

var fullscreen := false
var vsync := true
var shadow_quality := 2
var msaa := 1

## true kalau pemain menekan Lanjutkan di menu utama.
var continue_requested := false
## Dipakai alat tangkapan layar (--time=, --weather=). -1 = tidak diubah.
var debug_time: float = -1.0
var debug_weather: int = -1

func _ready() -> void:
	load_settings()
	apply_settings()
	_handle_capture_args()

## Alat bantu dokumentasi: ambil tangkapan layar otomatis lalu keluar.
## Contoh (jalankan dari folder proyek):
##   godot --path . -- --shot=user://menu.png
##   godot --path . -- --world --shot=user://dunia.png --frames=90
## Tambahkan --continue untuk membuka dunia tersimpan, --time=12 untuk
## mengatur jam, dan --weather=0/1/2 (cerah/berangin/hujan).
func _handle_capture_args() -> void:
	var shot := ""
	var frames := 60
	var open_world := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			shot = arg.trim_prefix("--shot=")
		elif arg.begins_with("--frames="):
			frames = maxi(1, arg.trim_prefix("--frames=").to_int())
		elif arg.begins_with("--time="):
			debug_time = arg.trim_prefix("--time=").to_float()
			open_world = true
		elif arg.begins_with("--weather="):
			debug_weather = arg.trim_prefix("--weather=").to_int()
			open_world = true
		elif arg == "--world":
			open_world = true
		elif arg == "--continue":
			continue_requested = true
			open_world = true
	if open_world:
		get_tree().change_scene_to_file.call_deferred(WORLD_SCENE)
	if shot == "":
		return
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(shot)
	print("Tangkapan layar disimpan: ", ProjectSettings.globalize_path(shot))
	get_tree().quit()

# --- Pengaturan -------------------------------------------------------------

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	vsync = config.get_value("display", "vsync", vsync)
	shadow_quality = clampi(config.get_value("graphics", "shadow_quality", shadow_quality), 0, SHADOW_LABELS.size() - 1)
	msaa = clampi(config.get_value("graphics", "msaa", msaa), 0, MSAA_LABELS.size() - 1)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync", vsync)
	config.set_value("graphics", "shadow_quality", shadow_quality)
	config.set_value("graphics", "msaa", msaa)
	config.save(SETTINGS_PATH)

func apply_settings() -> void:
	RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS[shadow_quality], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(SHADOW_FILTER[shadow_quality])
	RenderingServer.positional_soft_shadow_filter_set_quality(SHADOW_FILTER[shadow_quality])
	get_viewport().msaa_3d = MSAA_VALUES[msaa]

	# Mode jendela dan VSync tidak berlaku saat dijalankan tanpa layar (headless).
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

func set_and_apply(key: String, value: Variant) -> void:
	set(key, value)
	apply_settings()
	save_settings()

# --- Simpan dunia -----------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func save_world(data: Dictionary) -> bool:
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Gagal menyimpan dunia: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

## Mengembalikan Dictionary kosong kalau belum ada simpanan atau isinya rusak.
func load_world() -> Dictionary:
	if not has_save():
		return {}
	var text := FileAccess.get_file_as_string(save_path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_warning("File simpanan rusak, dunia baru dibuat.")
	return {}

# --- Pindah scene -----------------------------------------------------------

func start_new_world() -> void:
	continue_requested = false
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)

func continue_world() -> void:
	continue_requested = true
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)

func back_to_menu() -> void:
	continue_requested = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
