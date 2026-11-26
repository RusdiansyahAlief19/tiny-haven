class_name SettingsPanel
extends Control
## Jendela Pengaturan yang dipakai di menu utama dan di menu jeda.
##
## Isinya empat pilihan grafis. Setiap kali diklik, nilainya langsung
## diterapkan dan disimpan lewat autoload GameState, jadi tidak perlu
## tombol "Terapkan".

signal closed

var _rows: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiTheme.dim_overlay())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	var panel := UiTheme.dialog_panel("Pengaturan", 560.0)
	center.add_child(panel)
	var body := UiTheme.panel_body(panel)

	_add_row(body, "fullscreen", "Layar penuh")
	_add_row(body, "vsync", "VSync")
	_add_row(body, "shadow_quality", "Bayangan")
	_add_row(body, "msaa", "Anti-aliasing")

	var hint := UiTheme.label("Bayangan dan anti-aliasing tinggi\nlebih halus tapi lebih berat.", 16, UiTheme.LAVENDER)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(hint)

	var close := UiTheme.plate_button("Kembali", Vector2(260.0, 52.0))
	close.pressed.connect(_close)
	var close_wrap := CenterContainer.new()
	close_wrap.add_child(close)
	body.add_child(close_wrap)

	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _add_row(body: VBoxContainer, key: String, title: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var name_label := UiTheme.label(title, 24)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var button := UiTheme.plate_button("", Vector2(190.0, 48.0), 24)
	button.pressed.connect(_cycle.bind(key))
	row.add_child(button)
	body.add_child(row)
	_rows[key] = button

## Klik tombol = maju ke pilihan berikutnya (berputar kembali ke awal).
func _cycle(key: String) -> void:
	match key:
		"fullscreen", "vsync":
			GameState.set_and_apply(key, not GameState.get(key))
		"shadow_quality":
			GameState.set_and_apply(key, (GameState.shadow_quality + 1) % GameState.SHADOW_LABELS.size())
		"msaa":
			GameState.set_and_apply(key, (GameState.msaa + 1) % GameState.MSAA_LABELS.size())
	_refresh()

func _refresh() -> void:
	(_rows["fullscreen"] as Button).text = "Nyala" if GameState.fullscreen else "Mati"
	(_rows["vsync"] as Button).text = "Nyala" if GameState.vsync else "Mati"
	(_rows["shadow_quality"] as Button).text = GameState.SHADOW_LABELS[GameState.shadow_quality]
	(_rows["msaa"] as Button).text = GameState.MSAA_LABELS[GameState.msaa]

func _close() -> void:
	closed.emit()
	queue_free()
