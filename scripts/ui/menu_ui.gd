extends CanvasLayer
## Tampilan menu utama Tiny Haven.
##
## Tata letaknya mengikuti gaya Stormy Knights: papan judul di atas tengah,
## lalu deretan tombol pelat selebar papan di bawahnya.
##
## Font dan gaya pelat diambil dari scripts/ui/ui_theme.gd supaya sama
## dengan HUD di dalam permainan:
##   judul      - Magic Light, dibiarkan halus karena hurufnya berlekuk
##   sisanya    - Minecraft, penghalusan tepi dimatikan supaya pikselnya tajam
##                dan ukurannya dipilih kelipatan 8 agar tidak pecah
##
## Iterasi 4: semua tombol sudah berfungsi.
##   Mulai       - dunia baru di scenes/world/main.tscn
##   Lanjutkan   - memuat dunia tersimpan (redup kalau belum ada simpanan)
##   Pengaturan  - jendela pengaturan grafis (scripts/ui/settings_panel.gd)
##   Kredit      - daftar tim dan aset
##   Keluar      - menutup game
##
## Pasang pada node CanvasLayer di scenes/ui/main_menu.tscn.

const TITLE := "TINY HAVEN"
const SUBTITLE := "A COZY MINIATURE WORLD BUILDER"
const VERSION_TEXT := "Iterasi 4 - Prototipe"

const CREDITS_TEAM: Array[String] = [
	"Rusdiansyah Alief Prasetya",
	"Fevoura Agnesia Tatontos",
	"Ahmad Syafi Nurroyyan",
	"Shafiyyah Daniswara Nurwijayanti",
]
const CREDITS_ASSETS: Array[String] = [
	"Model 3D: Kenney Nature Kit (CC0)",
	"Font judul: Magic Light - Edric Studio",
	"Font antarmuka: Minecraft",
	"Mesin: Godot Engine 4.7",
]

var _column: VBoxContainer

func _ready() -> void:
	layer = 1
	_add_vignette()
	_add_menu()
	_add_version()

## Gelap di tepi atas dan bawah supaya teks tetap terbaca di atas scene 3D.
func _add_vignette() -> void:
	var night := UiTheme.NIGHT
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([
		Color(night.r, night.g, night.b, 0.72),
		Color(night.r, night.g, night.b, 0.08),
		Color(night.r, night.g, night.b, 0.62),
	])

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)

	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)

func _add_menu() -> void:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)

	_column = VBoxContainer.new()
	_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	_column.add_theme_constant_override("separation", 12)
	margin.add_child(_column)

	_column.add_child(_title_banner())
	_column.add_child(_spacer(46))

	_column.add_child(_menu_button("Mulai", GameState.start_new_world))
	var continue_button := _menu_button("Lanjutkan", GameState.continue_world)
	(continue_button.get_child(0) as Button).disabled = not GameState.has_save()
	_column.add_child(continue_button)
	_column.add_child(_menu_button("Pengaturan", _open_settings))
	_column.add_child(_menu_button("Kredit", _open_credits))
	_column.add_child(_menu_button("Keluar", _on_quit_pressed))

## Papan judul: pelat gelap bergaris merah muda, judul dan subjudul di dalamnya.
func _title_banner() -> Control:
	var wrapper := CenterContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _banner_style())
	wrapper.add_child(panel)

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 2)
	panel.add_child(inner)

	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_font := UiTheme.title_font()
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", UiTheme.CREAM)
	title.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
	title.add_theme_constant_override("outline_size", 12)
	inner.add_child(title)

	var subtitle := UiTheme.label(SUBTITLE, 16, UiTheme.TEAL)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(subtitle)

	return wrapper

func _banner_style() -> StyleBoxFlat:
	var style := UiTheme.plate_style(UiTheme.PLATE, UiTheme.PINK, 4, 0.92)
	style.content_margin_left = 54.0
	style.content_margin_right = 54.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 18.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0.0, 5.0)
	return style

func _spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, float(height))
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer

## Tombol pelat lebar bergaya Stormy Knights.
func _menu_button(text: String, action: Callable) -> Control:
	var wrapper := CenterContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS

	var button := UiTheme.plate_button(text, Vector2(430.0, 56.0))
	button.pressed.connect(action)
	wrapper.add_child(button)
	return wrapper

func _add_version() -> void:
	var label := UiTheme.label(VERSION_TEXT, 16, Color(UiTheme.LAVENDER, 0.8))
	label.anchor_left = 0.0
	label.anchor_right = 0.0
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 26.0
	label.offset_right = 420.0
	label.offset_top = -44.0
	label.offset_bottom = -20.0
	add_child(label)

# --- Jendela tambahan -------------------------------------------------------

## Menu disembunyikan selama jendela terbuka supaya tidak bertumpuk.
func _show_dialog(dialog: Control) -> void:
	_column.visible = false
	add_child(dialog)

func _on_dialog_closed() -> void:
	_column.visible = true

func _open_settings() -> void:
	var panel := SettingsPanel.new()
	panel.closed.connect(_on_dialog_closed)
	_show_dialog(panel)

func _open_credits() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(UiTheme.dim_overlay())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := UiTheme.dialog_panel("Kredit", 620.0)
	center.add_child(panel)
	var body := UiTheme.panel_body(panel)

	body.add_child(_credit_heading("Regu Tulip"))
	for member in CREDITS_TEAM:
		body.add_child(_credit_line(member))
	body.add_child(_spacer(6))
	body.add_child(_credit_heading("Aset"))
	for line in CREDITS_ASSETS:
		body.add_child(_credit_line(line))
	body.add_child(_spacer(6))

	var close := UiTheme.plate_button("Kembali", Vector2(260.0, 52.0))
	close.pressed.connect(func() -> void:
		root.queue_free()
		_on_dialog_closed())
	var close_wrap := CenterContainer.new()
	close_wrap.add_child(close)
	body.add_child(close_wrap)

	_show_dialog(root)

func _credit_heading(text: String) -> Label:
	var label := UiTheme.label(text, 24, UiTheme.TEAL)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _credit_line(text: String) -> Label:
	var label := UiTheme.label(text, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _on_quit_pressed() -> void:
	get_tree().quit()
