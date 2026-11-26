extends Node3D
class_name Sheep

var target := Vector3.ZERO
var speed := 0.6
var area := 12.0
var wait := 0.0
## Iterasi 5: titik kumpul (api unggun terdekat) saat malam. null = jalan bebas.
var gather_point: Variant = null
var _body: MeshInstance3D

func _ready() -> void:
	_body = _part(_sphere(0.3), Color(0.95, 0.95, 0.92), Vector3(0, 0.35, 0))
	_body.scale = Vector3(1, 0.85, 1.3)
	_part(_sphere(0.14), Color(0.2, 0.18, 0.18), Vector3(0, 0.5, 0.42))  # kepala (+Z = depan)
	target = position

func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s

func _part(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	m.mesh = mesh
	m.position = pos
	add_child(m)
	return m

func _process(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		return
	var d := target - position
	d.y = 0.0
	if d.length() < 0.1:
		_pick_next_target()
		return
	position += d.normalized() * speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), delta * 4.0)
	_body.position.y = 0.35 + absf(sin(Time.get_ticks_msec() * 0.01)) * 0.03

## Malam hari domba berkumpul melingkari api unggun dan diam lebih lama.
func _pick_next_target() -> void:
	if gather_point != null:
		var angle := randf() * TAU
		var radius := randf_range(1.1, 2.0)
		target = (gather_point as Vector3) + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		wait = randf_range(4.0, 9.0)
	else:
		target = Vector3(randf_range(-area, area), 0, randf_range(-area, area))
		wait = randf_range(1.0, 4.0)

## Kalau titik kumpul baru muncul, domba langsung berjalan ke sana.
func set_gather_point(point: Variant) -> void:
	var changed: bool = (point == null) != (gather_point == null)
	if not changed and point != null:
		changed = (point as Vector3).distance_to(gather_point) > 0.5
	gather_point = point
	if changed:
		wait = 0.0
		_pick_next_target()
		wait = 0.0

func is_gathered() -> bool:
	return gather_point != null and Vector2(position.x - gather_point.x, position.z - gather_point.z).length() < 2.5
