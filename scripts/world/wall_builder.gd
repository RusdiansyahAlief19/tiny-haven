extends Node3D
class_name WallBuilder
# Tembok prosedural: tiap segmen disusun dari batu acak (MultiMesh).
# Segmen yang cukup panjang otomatis dapat lubang pintu di tengah.
# Batu di baris atas sebagian berwarna hijau (efek ivy).
# Iterasi 4: tembok yang sudah selesai dicatat supaya bisa disimpan dan di-undo.

const ROW_H := 0.22
const ROWS := 6
const THICK := 0.35
const DOOR_W := 1.0
const DOOR_ROWS := 4

var points: Array[Vector3] = []
var _mmi: MultiMeshInstance3D
var _rng := RandomNumberGenerator.new()
# Tembok yang sudah selesai: titik-titiknya (untuk disimpan) dan node-nya (untuk dihapus).
var _finished: Array[PackedVector3Array] = []
var _finished_nodes: Array[Node] = []

func add_point(p: Vector3) -> void:
	points.append(p)
	_rebuild()

## Hapus titik terakhir. Kalau tembok yang sedang dibuat sudah kosong,
## tembok terakhir yang sudah selesai ikut dihapus.
func undo() -> bool:
	if points.size() > 0:
		points.pop_back()
		_rebuild()
		return true
	if _finished.size() > 0:
		_finished.pop_back()
		var node: Node = _finished_nodes.pop_back()
		if node:
			node.queue_free()
		return true
	return false

func commit() -> void:
	# Selesaikan tembok saat ini, mulai tembok baru.
	if points.size() >= 2 and _mmi:
		_finished.append(PackedVector3Array(points))
		_finished_nodes.append(_mmi)
	points.clear()
	_mmi = null

## Hapus satu tembok utuh yang salah satu sisinya paling dekat ke titik klik.
## Mengembalikan false kalau tidak ada tembok dalam jarak radius.
func erase_near(p: Vector3, radius: float) -> bool:
	commit()
	var target := Vector2(p.x, p.z)
	var best := -1
	var best_dist := radius
	for i in _finished.size():
		var wall := _finished[i]
		for j in wall.size() - 1:
			var a := Vector2(wall[j].x, wall[j].z)
			var b := Vector2(wall[j + 1].x, wall[j + 1].z)
			var d := target.distance_to(Geometry2D.get_closest_point_to_segment(target, a, b))
			if d < best_dist:
				best_dist = d
				best = i
	if best < 0:
		return false
	_finished.remove_at(best)
	var node: Node = _finished_nodes[best]
	_finished_nodes.remove_at(best)
	if node:
		node.queue_free()
	return true

func wall_count() -> int:
	return _finished.size() + (1 if points.size() >= 2 else 0)

## Data tembok untuk disimpan: daftar tembok, tiap tembok daftar titik [x, y, z].
func to_data() -> Array:
	var result: Array = []
	var all_walls := _finished.duplicate()
	if points.size() >= 2:
		all_walls.append(PackedVector3Array(points))
	for wall in all_walls:
		var pts: Array = []
		for p in wall:
			pts.append([snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001)])
		result.append(pts)
	return result

func load_data(data: Array) -> void:
	for wall in data:
		if not wall is Array:
			continue
		points.clear()
		for p in wall:
			if p is Array and p.size() == 3:
				points.append(Vector3(p[0], p[1], p[2]))
		_rebuild()
		commit()

func _rebuild() -> void:
	if _mmi:
		_mmi.queue_free()
		_mmi = null
	if points.size() < 2:
		return
	_rng.seed = 12345  # seed tetap supaya batu tidak "berubah" tiap rebuild
	var xforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in points.size() - 1:
		_wall_segment(points[i], points[i + 1], xforms, colors)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var box := BoxMesh.new()
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = box
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = mm
	add_child(_mmi)

func _wall_segment(a: Vector3, b: Vector3, xf: Array[Transform3D], col: Array[Color]) -> void:
	var dir := b - a
	var seg_len := dir.length()
	if seg_len < 0.1:
		return
	dir /= seg_len
	var angle := atan2(-dir.z, dir.x)
	var door_mid := seg_len * 0.5 if seg_len > 4.0 else -1.0
	for row in ROWS:
		var t := _rng.randf_range(0.0, 0.15) if row % 2 == 0 else _rng.randf_range(0.2, 0.35)
		while t < seg_len:
			var w := _rng.randf_range(0.3, 0.5)
			w = minf(w, seg_len - t)
			var c := t + w * 0.5
			t += w + 0.01
			if door_mid > 0.0 and row < DOOR_ROWS and absf(c - door_mid) < DOOR_W * 0.5:
				continue
			var size := Vector3(w, ROW_H * _rng.randf_range(0.9, 1.0), THICK * _rng.randf_range(0.85, 1.0))
			var bs := Basis(Vector3.UP, angle + _rng.randf_range(-0.05, 0.05)) * Basis.from_scale(size)
			var pos := a + dir * c + Vector3(0, ROW_H * (row + 0.5), 0)
			xf.append(Transform3D(bs, pos))
			if row >= ROWS - 2 and _rng.randf() < 0.4:
				col.append(Color(0.35, 0.5, 0.25))  # ivy
			else:
				col.append(Color.from_hsv(0.08, 0.1, _rng.randf_range(0.55, 0.75)))
