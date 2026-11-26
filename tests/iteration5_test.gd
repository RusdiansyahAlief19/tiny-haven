extends SceneTree
## Tes fitur iterasi 5: siang-malam, cuaca, tantangan, domba.
## Jalankan: godot --headless --path . -s res://tests/iteration5_test.gd

const TEST_SAVE := "user://test_world_i5.json"

var _failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  GAGAL ") + what)
	if not ok:
		_failures.append(what)

func _run() -> void:
	var gs = root.get_node("GameState")
	gs.save_path = TEST_SAVE
	gs.continue_requested = false
	var world: Node = load("res://scenes/world/main.tscn").instantiate()
	root.add_child(world)
	await process_frame

	# Siang-malam: lentera padam siang, menyala malam.
	world.day_night.set_time(12.0)
	_check(not world.day_night.is_night() and not world.placer.lights_on, "siang: lampu padam")
	world.day_night.set_time(0.0)
	_check(world.day_night.is_night() and world.placer.lights_on, "malam: lampu menyala")

	# Tantangan dari isi dunia.
	for i in 10:
		world.select_tool(1)
		world.placer.place(Vector3(-10 + i * 2.0, 0, 8))
	world._update_stats()
	_check(world.challenges.is_done("forest"), "tantangan 10 pohon")
	world.select_tool(0)
	for p in [Vector3(-3, 0, -3), Vector3(3, 0, -3), Vector3(3, 0, 3), Vector3(-3, 0, 3), Vector3(-3, 0, -2.5)]:
		world.walls.add_point(p)
	world.walls.commit()
	world._update_stats()
	_check(world.challenges.is_done("door"), "tantangan tembok berpintu")
	_check(world.challenges.is_done("fortress"), "tantangan tenda dikelilingi tembok")

	# Kejadian: pagi hari dan hujan.
	world.day_night.set_time(5.9)
	world.day_night._process(5.0)
	_check(world.challenges.is_done("night"), "tantangan melewati malam")
	world.weather.set_kind(Weather.Kind.RAIN)
	world.weather.snap_to_target()
	world._process(1.0)
	_check(world.challenges.is_done("rain"), "tantangan hujan")

	# Domba diberi titik kumpul api unggun saat malam.
	world.day_night.set_time(23.0)
	world._update_sheep()
	var has_gather := true
	for s in world.sheep:
		has_gather = has_gather and s.gather_point != null
	_check(has_gather, "domba menuju api unggun saat malam")

	# Simpan lalu muat: jam, cuaca, tantangan ikut tersimpan.
	world.save_world()
	var done_before: int = world.challenges.done_count()
	world.queue_free()
	await process_frame
	gs.continue_requested = true
	var world2: Node = load("res://scenes/world/main.tscn").instantiate()
	root.add_child(world2)
	await process_frame
	_check(absf(world2.day_night.time_of_day - 23.0) < 0.1, "jam tersimpan")
	_check(world2.weather.kind == Weather.Kind.RAIN, "cuaca tersimpan")
	_check(world2.challenges.done_count() == done_before, "tantangan tersimpan")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("HASIL: ", "LULUS" if _failures.is_empty() else "GAGAL")
	quit(0 if _failures.is_empty() else 1)
