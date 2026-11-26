class_name PropPlacer
extends Node3D
## Menaruh dan menghapus objek dekorasi (props) di dunia permainan.
##
## Cara kerja:
##   - Setiap alat (pohon, batu, lentera, ...) punya daftar model.
##   - Di bawah kursor ada "ghost", yaitu salinan model yang dibuat
##     transparan, supaya pemain melihat hasilnya sebelum menaruh.
##   - Setiap objek yang ditaruh dicatat sebagai Dictionary sederhana
##     (alat, file, posisi, rotasi, skala) supaya bisa disimpan ke JSON.
##
## Lentera dan api unggun ikut membawa sumber cahaya (OmniLight3D),
## sehingga pemain bisa "melukis" cahaya hangat di malam hari.

const NATURE_DIR := "res://assets/model/nature/"

const FIRE_WARM := Color("ff8a3d")
const LANTERN_WARM := Color("ffcf8a")
const LANTERN_GLASS := Color("fff3c4")
const WOOD_DARK := Color("3b2a2a")
const ERASE_RED := Color("ff3f6a")

## Jarak maksimum (meter) dari kursor ke objek yang bisa dihapus.
const ERASE_RADIUS := 1.2
const ROTATE_STEP := PI / 8.0

## Daftar model untuk setiap alat. Alat "wall" dan "erase" tidak punya model
## karena ditangani terpisah (wall_builder.gd dan erase_at()).
const MODELS := {
	"tree": ["tree_oak.glb", "tree_tall.glb", "tree_default.glb", "tree_pineTallA.glb", "tree_small.glb"],
	"rock": ["rock_largeA.glb", "rock_smallA.glb", "stump_round.glb", "log_stack.glb"],
	"plant": ["flower_redA.glb", "mushroom_redGroup.glb"],
	"fence": ["fence_simple.glb"],
	"tent": ["tent_detailedOpen.glb"],
	"campfire": ["campfire_logs.glb"],
	"lantern": ["lantern"],
}
## Rentang skala acak supaya pohon dan batu tidak terlihat kembar.
const SCALE_RANGE := {
	"tree": Vector2(0.8, 1.35),
	"rock": Vector2(0.7, 1.2),
	"plant": Vector2(0.8, 1.2),
}

var tool_id: String = ""
var placed_count: int:
	get:
		return _placed.size()

var _placed: Array[Node3D] = []
var _ghost: Node3D
var _ghost_file: String = ""
var _ghost_rotation: float = 0.0
var _ghost_scale: float = 1.0
var _erase_marker: MeshInstance3D
var _rng := RandomNumberGenerator.new()
var _scene_cache: Dictionary = {}
## Iterasi 5: lentera dan api unggun hanya menyala saat gelap (diatur DayNightCycle).
var lights_on := true

func _ready() -> void:
	_rng.randomize()
	_erase_marker = _make_disc(ERASE_RADIUS, ERASE_RED)
	_erase_marker.visible = false
	add_child(_erase_marker)

# --- Alat dan ghost ---------------------------------------------------------

func set_tool(id: String) -> void:
	tool_id = id
	_erase_marker.visible = false
	_roll_variant()

## Pilih model dan skala acak berikutnya, lalu bangun ulang ghost-nya.
func _roll_variant() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	if not MODELS.has(tool_id):
		_ghost_file = ""
		return
	var files: Array = MODELS[tool_id]
	_ghost_file = files[_rng.randi() % files.size()]
	var range_v: Vector2 = SCALE_RANGE.get(tool_id, Vector2.ONE)
	_ghost_scale = _rng.randf_range(range_v.x, range_v.y)
	if tool_id in ["tree", "rock", "plant"]:
		_ghost_rotation = _rng.randf() * TAU
	_ghost = build_prop(tool_id, _ghost_file, true)
	if _ghost == null:
		return
	_ghost.scale = Vector3.ONE * _ghost_scale
	_ghost.rotation.y = _ghost_rotation
	_ghost.visible = false
	add_child(_ghost)

func rotate_ghost(direction: int) -> void:
	_ghost_rotation = wrapf(_ghost_rotation + ROTATE_STEP * direction, 0.0, TAU)
	if _ghost:
		_ghost.rotation.y = _ghost_rotation

## Dipanggil setiap mouse bergerak. point = null kalau kursor tidak di tanah.
func update_cursor(point: Variant) -> void:
	var on_ground := point != null
	if _ghost:
		_ghost.visible = on_ground
		if on_ground:
			_ghost.position = point
	if tool_id == "erase":
		_erase_marker.visible = on_ground
		if on_ground:
			_erase_marker.position = (point as Vector3) + Vector3(0.0, 0.02, 0.0)

# --- Menaruh, menghapus, undo ----------------------------------------------

func place(point: Vector3) -> bool:
	if _ghost_file == "":
		return false
	place_record({
		"tool": tool_id,
		"file": _ghost_file,
		"pos": [point.x, point.y, point.z],
		"rot": _ghost_rotation,
		"scale": _ghost_scale,
	})
	_roll_variant()
	update_cursor(point)
	return true

## Membuat objek dari catatan. Dipakai saat menaruh dan saat memuat simpanan.
func place_record(record: Dictionary) -> Node3D:
	var id: String = record.get("tool", "")
	var file: String = record.get("file", "")
	var node := build_prop(id, file, false)
	if node == null:
		return null
	var pos: Array = record.get("pos", [0.0, 0.0, 0.0])
	node.position = Vector3(pos[0], pos[1], pos[2])
	node.rotation.y = float(record.get("rot", 0.0))
	node.scale = Vector3.ONE * float(record.get("scale", 1.0))
	node.set_meta("record", record)
	add_child(node)
	_placed.append(node)
	_apply_night(node, lights_on)
	return node

## Hapus objek terdekat dari titik klik (hanya bidang XZ yang dihitung).
func erase_at(point: Vector3) -> bool:
	var best: Node3D = null
	var best_dist := ERASE_RADIUS
	for node in _placed:
		var d := Vector2(node.position.x - point.x, node.position.z - point.z).length()
		if d < best_dist:
			best_dist = d
			best = node
	if best == null:
		return false
	_placed.erase(best)
	best.queue_free()
	return true

func undo_last() -> bool:
	if _placed.is_empty():
		return false
	var node: Node3D = _placed.pop_back()
	node.queue_free()
	return true

## Nyalakan atau padamkan semua lentera dan api unggun.
func set_lights(on: bool) -> void:
	lights_on = on
	for node in _placed:
		_apply_night(node, on)

func _apply_night(node: Node, on: bool) -> void:
	for child in node.find_children("*", "", true, false):
		if child.has_meta("night_only"):
			if child is Light3D:
				child.visible = on
			elif child is CPUParticles3D:
				child.emitting = on
		if child.has_meta("night_glow"):
			var mat: StandardMaterial3D = child.get_meta("night_glow")
			mat.emission_energy_multiplier = 2.5 if on else 0.15

## Posisi semua objek dengan alat tertentu, misalnya semua api unggun.
func positions_of(id: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for node in _placed:
		if (node.get_meta("record") as Dictionary).get("tool", "") == id:
			result.append(node.position)
	return result

func to_data() -> Array:
	var result: Array = []
	for node in _placed:
		var record: Dictionary = node.get_meta("record")
		var pos: Array = record["pos"]
		record["pos"] = [snappedf(pos[0], 0.001), snappedf(pos[1], 0.001), snappedf(pos[2], 0.001)]
		result.append(record)
	return result

func load_data(data: Array) -> void:
	for record in data:
		if record is Dictionary:
			place_record(record)

# --- Pembuat model ----------------------------------------------------------

## Membuat satu objek. Kalau ghost = true, model dibuat transparan dan
## semua cahaya serta partikelnya dibuang supaya tidak menerangi dunia.
func build_prop(id: String, file: String, ghost: bool) -> Node3D:
	var node: Node3D
	if id == "lantern":
		node = _build_lantern()
	else:
		var packed := _load_scene(file)
		if packed == null:
			return null
		node = packed.instantiate() as Node3D
		if id == "campfire":
			_decorate_campfire(node)
	if ghost:
		_make_ghost(node)
	elif id == "tree" or id == "plant":
		WindSway.apply(node, 1.4 if id == "tree" else 0.4)
	return node

func _load_scene(file: String) -> PackedScene:
	if not _scene_cache.has(file):
		var path := NATURE_DIR + file
		_scene_cache[file] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scene_cache[file]

func _make_ghost(node: Node) -> void:
	for child in node.get_children():
		if child is Light3D or child is GPUParticles3D or child is CPUParticles3D:
			node.remove_child(child)
			child.queue_free()
			continue
		_make_ghost(child)
	if node is GeometryInstance3D:
		var geo := node as GeometryInstance3D
		geo.transparency = 0.5
		geo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Api unggun: model kayu + cahaya oranye berkedip + percikan bara.
func _decorate_campfire(node: Node3D) -> void:
	var light := FlickerLight.new()
	light.position = Vector3(0.0, 0.6, 0.0)
	light.light_color = FIRE_WARM
	light.base_energy = 2.6
	light.omni_range = 7.5
	light.shadow_enabled = true
	light.set_meta("night_only", true)
	node.add_child(light)

	var embers := CPUParticles3D.new()
	embers.amount = 24
	embers.lifetime = 1.6
	embers.position = Vector3(0.0, 0.25, 0.0)
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.18
	embers.direction = Vector3.UP
	embers.spread = 18.0
	embers.gravity = Vector3(0.0, 0.6, 0.0)
	embers.initial_velocity_min = 0.4
	embers.initial_velocity_max = 0.9
	embers.scale_amount_min = 0.5
	embers.scale_amount_max = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = _emissive_material(FIRE_WARM, 4.0)
	embers.mesh = mesh
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	embers.color_ramp = fade
	embers.set_meta("night_only", true)
	node.add_child(embers)

## Lentera dibuat dari primitif: tiang, kap, dan kaca bercahaya.
## Bahan kaca memakai emission supaya terlihat menyala dan memicu efek glow.
func _build_lantern() -> Node3D:
	var root := Node3D.new()

	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.02
	pole_mesh.bottom_radius = 0.03
	pole_mesh.height = 0.56
	pole_mesh.radial_segments = 8
	pole_mesh.material = _matte_material(WOOD_DARK)
	_add_mesh(root, pole_mesh, Vector3(0.0, 0.28, 0.0))

	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(0.1, 0.12, 0.1)
	glass_mesh.material = _emissive_material(LANTERN_GLASS, 2.5)
	var glass := _add_mesh(root, glass_mesh, Vector3(0.0, 0.62, 0.0))
	glass.set_meta("night_glow", glass_mesh.material)

	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.02
	cap_mesh.bottom_radius = 0.09
	cap_mesh.height = 0.07
	cap_mesh.radial_segments = 4
	cap_mesh.material = _matte_material(WOOD_DARK)
	var cap := _add_mesh(root, cap_mesh, Vector3(0.0, 0.71, 0.0))
	cap.rotation.y = PI / 4.0

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.62, 0.0)
	light.light_color = LANTERN_WARM
	light.light_energy = 1.4
	light.omni_range = 4.0
	light.omni_attenuation = 1.4
	light.set_meta("night_only", true)
	root.add_child(light)
	return root

func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	parent.add_child(instance)
	return instance

func _matte_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

## Cakram datar penanda area hapus.
func _make_disc(radius: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	mesh.radial_segments = 32
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
