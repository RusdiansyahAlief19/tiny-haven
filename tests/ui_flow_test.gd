extends SceneTree
## Tes alur antarmuka: menu, pengaturan, kredit, menu jeda.
## Jalankan: godot --headless --path . -s res://tests/ui_flow_test.gd
## Catatan: jangan beri anotasi tipe class (misalnya SettingsPanel) di sini,
## karena autoload GameState belum terdaftar saat skrip tes dikompilasi.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var gs = root.get_node("GameState")
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var ui = menu.get_node("CanvasLayer")
	ui._open_settings()
	ui._open_credits()
	await process_frame

	var world: Node = load("res://scenes/world/main.tscn").instantiate()
	menu.queue_free()
	root.add_child(world)
	await process_frame
	world.hud._pause()
	var paused_ok := paused
	world.hud._open_settings()
	await process_frame
	var panel = null
	for n in world.hud.find_children("*", "", true, false):
		if n.has_method("_cycle"):
			panel = n
	var before: int = gs.shadow_quality
	panel._cycle("shadow_quality")
	var changed: bool = gs.shadow_quality != before
	panel._cycle("shadow_quality")
	panel._cycle("shadow_quality")
	panel._close()
	world.hud._resume()

	var ok: bool = paused_ok and changed and not paused and gs.shadow_quality == before
	print("HASIL: ", "LULUS" if ok else "GAGAL")
	quit(0 if ok else 1)
