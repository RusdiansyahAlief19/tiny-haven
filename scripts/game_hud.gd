class_name GameHud
extends CanvasLayer
## HUD di dalam dunia permainan Tiny Haven.
##
## Isi layar:
##   kiri atas    - judul kecil dan jumlah objek
##   kanan atas   - daftar kontrol (tombol H untuk sembunyikan)
##   bawah tengah - toolbar alat, tombol angka 1-9 juga bisa dipakai
##   tengah atas  - pesan singkat (toast), misalnya "Dunia tersimpan"
##   Esc          - menu jeda: lanjut, simpan, pengaturan, ke menu utama
##
## Gaya visual diambil dari UiTheme supaya sama dengan menu utama.

signal tool_selected(index: int)
signal save_requested
signal menu_requested

const TOOLBAR_BUTTON_SIZE := Vector2(108.0, 48.0)
const TOOLBAR_MARGIN := 6.0

const CONTROLS_TEXT := """Klik kiri   taruh / titik tembok
Klik kanan  selesai tembok / putar
R           putar objek
Z           undo
Shift       kunci ke grid
Tengah+geser  putar kamera
Scroll      zoom
WASD/Panah  geser kamera
F5          simpan
H           sembunyikan bantuan
Esc         jeda"""

var _tool_buttons: Array[Button] = []
var _stats_label: Label
var _tool_label: Label
var _controls_panel: PanelContainer
var _toast: Label
var _toast_tween: Tween
var _pause_root: Control
var _pause_column: Control

func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS

## Dibangun oleh main.gd setelah daftar alat diketahui.
func build(tool_names: Array[String]) -> void:
	_build_top_left()
	_build_controls()
	_build_toolbar(tool_names)
	_build_toast()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if is_paused():
			_resume()
		else:
			_pause()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H and not is_paused():
		_controls_panel.visible = not _controls_panel.visible

# --- Bagian HUD -------------------------------------------------------------

func _build_top_left() -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.position = Vector2(20.0, 16.0)
	box.add_theme_constant_override("separation", 2)
	add_child(box)

	var title := Label.new()
	title.text = "Tiny Haven"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := UiTheme.title_font()
	if font != null:
		title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UiTheme.CREAM)
	title.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
	title.add_theme_constant_override("outline_size", 8)
	box.add_child(title)

	_tool_label = UiTheme.label("", 16, UiTheme.TEAL)
	_tool_label.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
	_tool_label.add_theme_constant_override("outline_size", 4)
	box.add_child(_tool_label)

	_stats_label = UiTheme.label("", 16, UiTheme.LAVENDER)
	_stats_label.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
	_stats_label.add_theme_constant_override("outline_size", 4)
	box.add_child(_stats_label)

func _build_controls() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiTheme.plate_style(UiTheme.PLATE, UiTheme.PINK, 2, 0.78, 14.0)
	_controls_panel.add_theme_stylebox_override("panel", style)
	_controls_panel.anchor_left = 1.0
	_controls_panel.anchor_right = 1.0
	_controls_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_controls_panel.offset_right = -16.0
	_controls_panel.offset_top = 16.0
	add_child(_controls_panel)

	var text := UiTheme.label(CONTROLS_TEXT, 16, UiTheme.CREAM)
	_controls_panel.add_child(text)

func _build_toolbar(tool_names: Array[String]) -> void:
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 6)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -14.0
	add_child(bar)

	for i in tool_names.size():
		var slot := VBoxContainer.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_constant_override("separation", 2)
		var key := UiTheme.label(str(i + 1), 16, UiTheme.LAVENDER)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
		key.add_theme_constant_override("outline_size", 4)
		slot.add_child(key)

		var button := UiTheme.plate_button(tool_names[i], TOOLBAR_BUTTON_SIZE, 16, TOOLBAR_MARGIN)
		button.pressed.connect(func() -> void: tool_selected.emit(i))
		slot.add_child(button)
		bar.add_child(slot)
		_tool_buttons.append(button)

func _build_toast() -> void:
	_toast = UiTheme.label("", 24, UiTheme.CREAM)
	_toast.add_theme_color_override("font_outline_color", UiTheme.OUTLINE)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.offset_top = 22.0
	_toast.modulate.a = 0.0
	add_child(_toast)

# --- Dipanggil dari main.gd -------------------------------------------------

func set_selected_tool(index: int, description: String) -> void:
	for i in _tool_buttons.size():
		UiTheme.set_button_selected(_tool_buttons[i], i == index, TOOLBAR_MARGIN)
	_tool_label.text = description

func set_stats(prop_count: int, wall_count: int) -> void:
	_stats_label.text = "Objek: %d   Tembok: %d" % [prop_count, wall_count]

func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)

func is_paused() -> bool:
	return _pause_root != null

# --- Menu jeda --------------------------------------------------------------

func _pause() -> void:
	get_tree().paused = true
	_pause_root = Control.new()
	_pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_root.add_child(UiTheme.dim_overlay())
	add_child(_pause_root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_root.add_child(center)
	_pause_column = center

	var panel := UiTheme.dialog_panel("Jeda", 480.0)
	center.add_child(panel)
	var body := UiTheme.panel_body(panel)
	body.add_child(_pause_button("Lanjut", _resume))
	body.add_child(_pause_button("Simpan", func() -> void: save_requested.emit()))
	body.add_child(_pause_button("Pengaturan", _open_settings))
	body.add_child(_pause_button("Ke Menu Utama", func() -> void: menu_requested.emit()))

	var note := UiTheme.label("Dunia otomatis disimpan\nsaat kembali ke menu.", 16, UiTheme.LAVENDER)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(note)

func _resume() -> void:
	if _pause_root:
		_pause_root.queue_free()
		_pause_root = null
	get_tree().paused = false

func _pause_button(text: String, action: Callable) -> Control:
	var wrap := CenterContainer.new()
	var button := UiTheme.plate_button(text, Vector2(340.0, 52.0))
	button.pressed.connect(action)
	wrap.add_child(button)
	return wrap

func _open_settings() -> void:
	_pause_column.visible = false
	var panel := SettingsPanel.new()
	panel.closed.connect(func() -> void:
		if _pause_column:
			_pause_column.visible = true)
	_pause_root.add_child(panel)
