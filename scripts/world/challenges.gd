class_name Challenges
extends RefCounted
## Tantangan santai yang opsional (iterasi 5).
##
## Tidak ada batas waktu dan tidak ada kalah. Tantangan hanya memberi arah
## kalau pemain bingung mau membangun apa. Ada dua jenis:
##   - dicek dari isi dunia (jumlah lentera, pohon, bentuk tembok, ...),
##     lewat evaluate() setiap kali dunia berubah,
##   - dipicu kejadian (melewati malam, hujan, domba berkumpul),
##     lewat mark().

signal completed(title: String)

const LIST: Array[Dictionary] = [
	{"id": "lanterns", "title": "Terangi kemah dengan 4 lentera"},
	{"id": "forest", "title": "Tanam hutan kecil: 10 pohon"},
	{"id": "fires", "title": "Nyalakan 2 api unggun"},
	{"id": "door", "title": "Bangun tembok yang punya pintu"},
	{"id": "fortress", "title": "Kelilingi tenda dengan tembok"},
	{"id": "night", "title": "Lewati satu malam sampai pagi"},
	{"id": "rain", "title": "Nikmati hujan di Tiny Haven"},
	{"id": "sheep", "title": "Kumpulkan 3 domba di api unggun"},
]

## Segmen tembok lebih panjang dari ini otomatis punya pintu (wall_builder.gd).
const DOOR_MIN_LENGTH := 4.0
## Ujung tembok dianggap tersambung (tertutup) kalau jaraknya sedekat ini.
const CLOSE_DISTANCE := 2.0

var done: Dictionary = {}

func is_done(id: String) -> bool:
	return done.has(id)

func done_count() -> int:
	return done.size()

func mark(id: String) -> void:
	if done.has(id):
		return
	done[id] = true
	for item in LIST:
		if item["id"] == id:
			completed.emit(item["title"])

## props: hasil PropPlacer.to_data(), walls: hasil WallBuilder.to_data().
func evaluate(props: Array, walls: Array) -> void:
	var counts := {}
	var tents: Array[Vector2] = []
	for record in props:
		var tool: String = record.get("tool", "")
		counts[tool] = counts.get(tool, 0) + 1
		if tool == "tent":
			var p: Array = record["pos"]
			tents.append(Vector2(p[0], p[2]))
	if counts.get("lantern", 0) >= 4:
		mark("lanterns")
	if counts.get("tree", 0) >= 10:
		mark("forest")
	if counts.get("campfire", 0) >= 2:
		mark("fires")

	for wall in walls:
		var pts := _to_points(wall)
		if _has_door(pts):
			mark("door")
		if _is_closed(pts):
			for tent in tents:
				if Geometry2D.is_point_in_polygon(tent, PackedVector2Array(pts)):
					mark("fortress")

func to_data() -> Array:
	return done.keys()

func load_data(data: Array) -> void:
	for id in data:
		done[str(id)] = true

func _to_points(wall: Array) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for p in wall:
		pts.append(Vector2(p[0], p[2]))
	return pts

func _has_door(pts: Array[Vector2]) -> bool:
	for i in pts.size() - 1:
		if pts[i].distance_to(pts[i + 1]) > DOOR_MIN_LENGTH:
			return true
	return false

## Tembok dianggap mengurung area kalau punya minimal 3 sudut (4 titik)
## dan titik terakhirnya kembali ke dekat titik awal.
func _is_closed(pts: Array[Vector2]) -> bool:
	return pts.size() >= 4 and pts[0].distance_to(pts[pts.size() - 1]) <= CLOSE_DISTANCE
