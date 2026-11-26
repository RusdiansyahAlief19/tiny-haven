class_name UiTheme
extends RefCounted
## Gaya antarmuka bersama untuk menu utama dan HUD permainan.
##
## Palet diambil dari assets/icon/icon-game.png supaya menu dan dunia
## permainan terasa satu kesatuan. Semua fungsi di sini statis, jadi
## cukup dipanggil lewat UiTheme.nama_fungsi().

const NIGHT := Color("110d3a")
const PLATE := Color("2a1f4d")
const PLATE_HOVER := Color("3d2d6b")
const PINK := Color("ff3fa8")
const LAVENDER := Color("c9a8ff")
const CREAM := Color("fff3c4")
const TEAL := Color("1fb89a")
const OUTLINE := Color("1a0f33")

const FONTS_DIR := "res://assets/fonts/"
## Nama file diperiksa berurutan; yang pertama ketemu yang dipakai.
const TITLE_FONT_FILES: Array[String] = [
	"Magiclightdemo-BWzXB.ttf",
	"MagicLight.ttf",
]
const UI_FONT_FILES: Array[String] = [
	"Minecraft.ttf",
	"minecraft.ttf",
]

static var _title_font: Font
static var _ui_font: Font
static var _fonts_loaded := false

static func title_font() -> Font:
	_load_fonts()
	return _title_font

static func ui_font() -> Font:
	_load_fonts()
	return _ui_font

static func _load_fonts() -> void:
	if _fonts_loaded:
		return
	_fonts_loaded = true
	_title_font = _find_font(TITLE_FONT_FILES, false)
	_ui_font = _find_font(UI_FONT_FILES, true)

## Cari file font pertama yang benar-benar ada di assets/fonts/.
## Kalau pixel_perfect true, penghalusan tepinya dimatikan supaya tetap tajam.
## Kalau tidak ada yang ketemu, hasilnya null dan Godot memakai font bawaan.
static func _find_font(candidates: Array[String], pixel_perfect: bool) -> Font:
	for file_name in candidates:
		var path := FONTS_DIR + file_name
		if not ResourceLoader.exists(path):
			continue
		var font := load(path) as Font
		var file := font as FontFile
		if pixel_perfect and file != null:
			file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			file.hinting = TextServer.HINTING_NONE
		return font
	return null

## Pasang font antarmuka (Minecraft) pada Label atau Button.
## Ukuran sebaiknya kelipatan 8 supaya font piksel tidak pecah.
static func apply_font(target: Control, size: int) -> void:
	var font := ui_font()
	if font != null:
		target.add_theme_font_override("font", font)
	target.add_theme_font_size_override("font_size", size)

static func label(text: String, size: int, color: Color = CREAM) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_font(result, size)
	result.add_theme_color_override("font_color", color)
	return result

## Pelat persegi bergaris tepi: dipakai tombol, panel, dan papan judul.
static func plate_style(fill: Color, accent: Color, border: int = 3, alpha: float = 0.9, h_margin: float = 24.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill.r, fill.g, fill.b, alpha)
	style.border_color = accent
	style.set_border_width_all(border)
	style.set_corner_radius_all(0)
	style.content_margin_left = h_margin
	style.content_margin_right = h_margin
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)
	return style

## Tombol pelat bergaya Stormy Knights, sama dengan tombol menu utama.
static func plate_button(text: String, min_size: Vector2, font_size: int = 24, h_margin: float = 24.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	apply_font(button, font_size)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", LAVENDER)
	button.add_theme_color_override("font_disabled_color", Color(LAVENDER.r, LAVENDER.g, LAVENDER.b, 0.35))
	button.add_theme_stylebox_override("normal", plate_style(PLATE, PINK, 3, 0.9, h_margin))
	button.add_theme_stylebox_override("hover", plate_style(PLATE_HOVER, LAVENDER, 3, 0.9, h_margin))
	button.add_theme_stylebox_override("pressed", plate_style(PLATE.darkened(0.2), PINK, 3, 0.9, h_margin))
	button.add_theme_stylebox_override("disabled", plate_style(PLATE.darkened(0.3), Color(PINK.r, PINK.g, PINK.b, 0.3), 3, 0.7, h_margin))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

## Tombol pelat yang bisa "menyala" saat dipilih (misalnya alat di toolbar).
static func set_button_selected(button: Button, selected: bool, h_margin: float = 24.0) -> void:
	if selected:
		button.add_theme_stylebox_override("normal", plate_style(PLATE_HOVER, CREAM, 4, 0.95, h_margin))
		button.add_theme_stylebox_override("hover", plate_style(PLATE_HOVER, CREAM, 4, 0.95, h_margin))
	else:
		button.add_theme_stylebox_override("normal", plate_style(PLATE, PINK, 3, 0.9, h_margin))
		button.add_theme_stylebox_override("hover", plate_style(PLATE_HOVER, LAVENDER, 3, 0.9, h_margin))

## Panel besar berisi judul kecil di atas; dipakai Pengaturan, Kredit, dan Jeda.
## Konten ditambahkan ke VBoxContainer yang dikembalikan lewat meta "body".
static func dialog_panel(heading: String, width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := plate_style(PLATE, PINK, 4, 0.96)
	style.content_margin_left = 40.0
	style.content_margin_right = 40.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 28.0
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(width, 0.0)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	panel.add_child(body)

	var title := Label.new()
	title.text = heading
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font := title_font()
	if font != null:
		title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", CREAM)
	title.add_theme_color_override("font_outline_color", OUTLINE)
	title.add_theme_constant_override("outline_size", 8)
	body.add_child(title)

	panel.set_meta("body", body)
	return panel

static func panel_body(panel: PanelContainer) -> VBoxContainer:
	return panel.get_meta("body") as VBoxContainer

## Lapisan gelap transparan penuh layar di belakang dialog.
## Menahan klik supaya tidak tembus ke dunia 3D di belakangnya.
static func dim_overlay(alpha: float = 0.55) -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(NIGHT.r, NIGHT.g, NIGHT.b, alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return dim
