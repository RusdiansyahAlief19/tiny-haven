extends Node3D
## Dunia permainan Tiny Haven (iterasi 4).
##
## Pemain masuk ke sini dari tombol Mulai atau Lanjutkan di menu utama.
## Suasananya disamakan dengan menu: malam ungu, bulan sabit, kunang-kunang,
## dan cahaya hangat dari api unggun serta lentera yang ditaruh pemain.
##
## Kontrol lengkap tampil di HUD (scripts/ui/game_hud.gd). Ringkasnya:
##   1-9 pilih alat | Klik kiri taruh | Klik kanan selesai tembok / putar
##   R putar | Z undo | Shift kunci grid | F5 simpan | Esc jeda
##   Klik tengah + geser putar kamera | Scroll zoom | WASD/Panah geser kamera

const CameraRigScript = preload("res://scripts/world/camera_rig.gd")
const WallBuilderScript = preload("res://scripts/world/wall_builder.gd")
const SheepScript = preload("res://scripts/world/sheep.gd")
const FirefliesScript = preload("res://scripts/world/fireflies.gd")
const NightSkyShader = preload("res://shaders/night_sky.gdshader")

## Urutan alat = urutan tombol di toolbar dan tombol angka 1-9.
const TOOLS: Array[Dictionary] = [
	{"id": "wall", "name": "Tembok", "desc": "Tembok batu: klik titik-titik, klik kanan untuk selesai"},
	{"id": "tree", "name": "Pohon", "desc": "Pohon: bentuk dan ukuran diacak setiap ditaruh"},
	{"id": "rock", "name": "Batu", "desc": "Batu, tunggul, dan tumpukan kayu"},
	{"id": "plant", "name": "Tanaman", "desc": "Bunga dan jamur kecil"},
	{"id": "fence", "name": "Pagar", "desc": "Pagar kayu: tekan R untuk memutar"},
	{"id": "tent", "name": "Tenda", "desc": "Tenda kemah"},
	{"id": "campfire", "name": "Api", "desc": "Api unggun: sumber cahaya hangat yang berkedip"},
	{"id": "lantern", "name": "Lentera", "desc": "Lentera: cahaya lembut untuk jalan setapak"},
	{"id": "erase", "name": "Hapus", "desc": "Hapus: klik objek di dalam lingkaran merah"},
]

# Palet dari assets/icon/icon-game.png (sama dengan menu_world.gd)
const NIGHT_DEEP := Color("0b0b2f")
const PURPLE := Color("892bd8")
const LAVENDER := Color("c9a8ff")
const GRASS := Color(0.09, 0.5, 0.39)

## Pemain hanya boleh membangun di dalam lingkaran ini; di luarnya hutan pembatas.
const BUILD_RADIUS := 24.0
const BORDER_INNER := 27.0
const BORDER_OUTER := 40.0
const GRID_STEP := 0.5

var cam_rig
var walls
var placer: PropPlacer
var hud: GameHud

var _tool_index := 0
var _cursor: Variant = null
var _wall_marker: MeshInstance3D

func _ready() -> void:
	_setup_environment()
	_setup_ground()
	_build_border_forest()

	cam_rig = CameraRigScript.new()
	cam_rig.dist = 8.0  # objek Kenney kecil, jadi kamera awal dibuat lebih dekat
	add_child(cam_rig)
	walls = WallBuilderScript.new()
	add_child(walls)
	placer = PropPlacer.new()
	add_child(placer)
	_wall_marker = _make_marker()
	add_child(_wall_marker)

	for i in 5:
		var s = SheepScript.new()
		s.position = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		add_child(s)
	var fireflies := FirefliesScript.new()
	add_child(fireflies)
	fireflies.emission_box_extents = Vector3(BUILD_RADIUS, 1.5, BUILD_RADIUS)
	fireflies.amount = 120

	hud = GameHud.new()
	add_child(hud)
	var names: Array[String] = []
	for tool in TOOLS:
		names.append(tool["name"])
	hud.build(names)
	hud.tool_selected.connect(select_tool)
	hud.save_requested.connect(save_world)
	hud.menu_requested.connect(_on_menu_requested)

	if GameState.continue_requested and _load_world():
		hud.show_toast("Dunia dimuat")
	else:
		_build_starter_camp()
		hud.show_toast("Selamat datang di Tiny Haven")
	select_tool(0)
	_update_stats()

# --- Suasana malam ----------------------------------------------------------

## Langit malam dari shader (bintang + bulan sabit), kabut ungu, cahaya bulan.
func _setup_environment() -> void:
	var sky_material := ShaderMaterial.new()
	sky_material.shader = NightSkyShader
	sky_material.set_shader_parameter("top_color", NIGHT_DEEP)
	sky_material.set_shader_parameter("horizon_color", PURPLE)
	sky_material.set_shader_parameter("ground_color", NIGHT_DEEP)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.2
	env.fog_enabled = true
	env.fog_light_color = Color("3a2060")
	env.fog_density = 0.012
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# Bulan lebih terang daripada di menu supaya pemain tetap bisa membangun.
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-42.0, -130.0, 0.0)
	moon.light_color = LAVENDER
	moon.light_energy = 0.75
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	add_child(moon)

func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(BORDER_OUTER * 2.5, BORDER_OUTER * 2.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GRASS
	mat.roughness = 1.0
	plane.material = mat
	ground.mesh = plane
	add_child(ground)

	# Lingkaran tipis penanda batas area bangun.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = BUILD_RADIUS - 0.06
	torus.outer_radius = BUILD_RADIUS + 0.06
	torus.rings = 96
	torus.ring_segments = 4
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(LAVENDER, 0.35)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = ring_mat
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.05, 1.0)
	ring.position.y = 0.01
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

## Hutan di luar area bangun. Seed tetap supaya bentuknya selalu sama.
func _build_border_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var trees: Array = PropPlacer.MODELS["tree"]
	var forest := Node3D.new()
	forest.name = "BorderForest"
	add_child(forest)
	for i in 140:
		var packed := load(PropPlacer.NATURE_DIR + trees[rng.randi() % trees.size()]) as PackedScene
		if packed == null:
			continue
		var tree := packed.instantiate() as Node3D
		var angle := rng.randf() * TAU
		var radius := BORDER_INNER + sqrt(rng.randf()) * (BORDER_OUTER - BORDER_INNER)
		tree.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		tree.rotation.y = rng.randf() * TAU
		tree.scale = Vector3.ONE * rng.randf_range(1.0, 1.8)
		forest.add_child(tree)

## Dunia baru tidak kosong: ada api unggun, tenda, dan dua lentera.
func _build_starter_camp() -> void:
	placer.place_record({"tool": "campfire", "file": "campfire_logs.glb", "pos": [1.5, 0.0, 0.5], "rot": 0.0, "scale": 1.0})
	placer.place_record({"tool": "tent", "file": "tent_detailedOpen.glb", "pos": [0.0, 0.0, -0.5], "rot": 0.26, "scale": 1.0})
	placer.place_record({"tool": "lantern", "file": "lantern", "pos": [-2.5, 0.0, 2.0], "rot": 0.0, "scale": 1.0})
	placer.place_record({"tool": "lantern", "file": "lantern", "pos": [4.0, 0.0, 2.5], "rot": 0.0, "scale": 1.0})

# --- Alat -------------------------------------------------------------------

func select_tool(index: int) -> void:
	if index < 0 or index >= TOOLS.size():
		return
	if _tool_id() == "wall" and index != _tool_index:
		walls.commit()
	_tool_index = index
	placer.set_tool(_tool_id())
	placer.update_cursor(_cursor)
	_update_wall_marker()
	hud.set_selected_tool(index, TOOLS[index]["desc"])

func _tool_id() -> String:
	return TOOLS[_tool_index]["id"]

# --- Input ------------------------------------------------------------------

func _ground_point(screen_pos: Vector2) -> Variant:
	var cam: Camera3D = cam_rig.cam
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if hit == null:
		return null
	var p: Vector3 = hit
	if Input.is_key_pressed(KEY_SHIFT):
		p = Vector3(snappedf(p.x, GRID_STEP), 0.0, snappedf(p.z, GRID_STEP))
	return p

func _inside_build_area(p: Vector3) -> bool:
	return Vector2(p.x, p.z).length() <= BUILD_RADIUS

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_cursor = _ground_point(e.position)
		placer.update_cursor(_cursor)
		_update_wall_marker()
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(_ground_point(e.position))
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if _tool_id() == "wall":
				walls.commit()
				_update_stats()
			else:
				placer.rotate_ghost(1)
	elif e is InputEventKey and e.pressed and not e.echo:
		_on_key(e.keycode)

func _on_left_click(p: Variant) -> void:
	if p == null:
		return
	if not _inside_build_area(p):
		hud.show_toast("Di luar area bangun")
		return
	match _tool_id():
		"wall":
			walls.add_point(p)
		"erase":
			if not placer.erase_at(p):
				hud.show_toast("Tidak ada objek di situ")
		_:
			placer.place(p)
	_update_stats()

func _on_key(keycode: Key) -> void:
	if keycode >= KEY_1 and keycode <= KEY_9:
		select_tool(keycode - KEY_1)
		return
	match keycode:
		KEY_R:
			placer.rotate_ghost(1)
		KEY_Z:
			_undo()
		KEY_F5:
			save_world()

## Undo mengikuti alat yang aktif: tembok untuk alat Tembok, objek untuk lainnya.
func _undo() -> void:
	var done: bool = walls.undo() if _tool_id() == "wall" else placer.undo_last()
	if not done:
		hud.show_toast("Tidak ada yang bisa di-undo")
	_update_stats()

func _update_stats() -> void:
	hud.set_stats(placer.placed_count, walls.wall_count())

## Penanda kecil di bawah kursor saat alat Tembok aktif.
func _update_wall_marker() -> void:
	_wall_marker.visible = _tool_id() == "wall" and _cursor != null
	if _wall_marker.visible:
		_wall_marker.position = (_cursor as Vector3) + Vector3(0.0, 0.02, 0.0)

func _make_marker() -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.18
	mesh.height = 0.03
	mesh.radial_segments = 16
	var mat := StandardMaterial3D.new()
	mat.albedo_color = UiTheme.PINK
	mat.emission_enabled = true
	mat.emission = UiTheme.PINK
	mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	var marker := MeshInstance3D.new()
	marker.mesh = mesh
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker

# --- Simpan dan muat --------------------------------------------------------

func save_world() -> void:
	var data := {
		"walls": walls.to_data(),
		"props": placer.to_data(),
		"camera": {
			"pos": [cam_rig.position.x, cam_rig.position.y, cam_rig.position.z],
			"yaw": cam_rig.yaw,
			"pitch": cam_rig.pitch,
			"dist": cam_rig.dist,
		},
	}
	if GameState.save_world(data):
		hud.show_toast("Dunia tersimpan")
	else:
		hud.show_toast("Gagal menyimpan dunia")

func _load_world() -> bool:
	var data := GameState.load_world()
	if data.is_empty():
		return false
	walls.load_data(data.get("walls", []))
	placer.load_data(data.get("props", []))
	var cam: Dictionary = data.get("camera", {})
	if cam.has("pos"):
		cam_rig.position = Vector3(cam["pos"][0], cam["pos"][1], cam["pos"][2])
		cam_rig.yaw = cam.get("yaw", cam_rig.yaw)
		cam_rig.pitch = cam.get("pitch", cam_rig.pitch)
		cam_rig.dist = cam.get("dist", cam_rig.dist)
		cam_rig._apply()
	return true

func _on_menu_requested() -> void:
	save_world()
	GameState.back_to_menu()
