class_name Weather
extends Node3D
## Cuaca Tiny Haven (iterasi 5): cerah, berangin, atau hujan.
##
## - Hujan: ribuan tetes dari CPUParticles3D yang selalu mengikuti kamera,
##   jadi hujan terlihat di mana pun pemain melihat tanpa menutup seluruh peta.
## - Angin: kekuatannya dikirim ke shader goyangan pohon (WindSway) dan
##   sekaligus memiringkan arah jatuh tetes hujan.
## - Mendung: nilai overcast dikirim ke DayNightCycle untuk meredupkan
##   cahaya dan menggelapkan langit.
## Semua nilai berubah perlahan (lerp) supaya pergantian cuaca halus.
## Cuaca berganti sendiri tiap 1-2 menit, atau manual dengan tombol C.

signal weather_changed(label: String)

enum Kind { CLEAR, WINDY, RAIN }
const LABELS: Array[String] = ["Cerah", "Berangin", "Hujan"]
## Target [angin, hujan, mendung] untuk setiap jenis cuaca.
const TARGETS: Array[Vector3] = [
	Vector3(0.15, 0.0, 0.0),
	Vector3(1.0, 0.0, 0.25),
	Vector3(0.7, 1.0, 0.85),
]

@export var auto_change := true
@export var min_duration: float = 70.0
@export var max_duration: float = 140.0

var kind: Kind = Kind.CLEAR
var wind: float = 0.15
var rain: float = 0.0
var overcast: float = 0.0

## Node yang diikuti hujan (rig kamera).
var follow: Node3D
var day_night: DayNightCycle

var _rain: CPUParticles3D
var _rain_material: StandardMaterial3D
var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_timer = _rng.randf_range(min_duration, max_duration)
	_rain = _build_rain()
	add_child(_rain)

func set_kind(value: Kind) -> void:
	kind = value
	_timer = _rng.randf_range(min_duration, max_duration)
	weather_changed.emit(LABELS[kind])

func cycle_kind() -> void:
	set_kind(((kind + 1) % LABELS.size()) as Kind)

func label() -> String:
	return LABELS[kind]

func is_raining() -> bool:
	return rain > 0.5

## Langsung lompat ke nilai target (dipakai saat memuat simpanan).
func snap_to_target() -> void:
	var t := TARGETS[kind]
	wind = t.x
	rain = t.y
	overcast = t.z
	_apply()

func _process(delta: float) -> void:
	if auto_change:
		_timer -= delta
		if _timer <= 0.0:
			# Hujan lebih jarang daripada cerah atau berangin.
			var roll := _rng.randf()
			set_kind(Kind.CLEAR if roll < 0.45 else (Kind.WINDY if roll < 0.75 else Kind.RAIN))

	var t := TARGETS[kind]
	var k := 1.0 - exp(-delta * 0.6)
	wind = lerpf(wind, t.x, k)
	rain = lerpf(rain, t.y, k)
	overcast = lerpf(overcast, t.z, k)
	if follow:
		global_position = Vector3(follow.global_position.x, 0.0, follow.global_position.z)
	_apply()

func _apply() -> void:
	WindSway.set_strength(wind)
	if day_night:
		day_night.overcast = overcast
	_rain.emitting = rain > 0.05
	# Tetes makin tipis saat hujan mereda.
	_rain_material.albedo_color.a = 0.45 * clampf(rain, 0.0, 1.0)
	_rain.gravity = Vector3(wind * 4.0, -22.0, wind * 1.5)

func _build_rain() -> CPUParticles3D:
	var drops := CPUParticles3D.new()
	drops.amount = 1600
	drops.lifetime = 0.9
	drops.local_coords = false
	drops.emitting = false
	drops.position = Vector3(0.0, 11.0, 0.0)
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drops.emission_box_extents = Vector3(16.0, 0.5, 16.0)
	drops.direction = Vector3.DOWN
	drops.spread = 2.0
	drops.initial_velocity_min = 6.0
	drops.initial_velocity_max = 8.0
	drops.particle_flag_align_y = true

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.32, 0.012)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.85, 1.0, 0.45)
	mesh.material = mat
	_rain_material = mat
	drops.mesh = mesh
	return drops
