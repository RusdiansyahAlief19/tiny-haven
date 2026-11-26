extends SceneTree
## Tes simpan dan muat dunia.
## Jalankan: godot --headless --path . -s res://tests/save_load_test.gd
## Keluar dengan kode 0 kalau lulus, 1 kalau gagal.

const TEST_SAVE := "user://test_world.json"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var gs = root.get_node("GameState")
	gs.save_path = TEST_SAVE
	gs.continue_requested = false
	var scene: Node = load("res://scenes/world/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	scene.select_tool(1)
	scene.placer.place(Vector3(3, 0, 3))
	scene.select_tool(7)
	scene.placer.place(Vector3(-3, 0, 3))
	scene.select_tool(0)
	scene.walls.add_point(Vector3(-5, 0, -5))
	scene.walls.add_point(Vector3(0, 0, -6))
	scene.walls.add_point(Vector3(5, 0, -5))
	scene.walls.commit()
	scene.select_tool(8)
	var erased: bool = scene.placer.erase_at(Vector3(3.3, 0, 3.1))
	# Tembok kedua lalu dihapus dengan alat Hapus (klik dekat sisinya).
	scene.select_tool(0)
	scene.walls.add_point(Vector3(-8, 0, 6))
	scene.walls.add_point(Vector3(-2, 0, 6))
	scene.walls.commit()
	var walls_before: int = scene.walls.wall_count()
	scene.select_tool(8)
	scene._on_left_click(Vector3(-5, 0, 6.4))
	var wall_erased: bool = scene.walls.wall_count() == walls_before - 1
	print("tembok terhapus=", wall_erased)
	erased = erased and wall_erased
	scene.save_world()
	var props_saved: int = scene.placer.placed_count
	scene.queue_free()
	await process_frame

	gs.continue_requested = true
	var scene2: Node = load("res://scenes/world/main.tscn").instantiate()
	root.add_child(scene2)
	await process_frame
	var ok: bool = erased \
		and scene2.placer.placed_count == props_saved \
		and scene2.walls.wall_count() == 1
	print("objek tersimpan=%d dimuat=%d tembok=%d terhapus=%s" % [
		props_saved, scene2.placer.placed_count, scene2.walls.wall_count(), erased])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("HASIL: ", "LULUS" if ok else "GAGAL")
	quit(0 if ok else 1)
