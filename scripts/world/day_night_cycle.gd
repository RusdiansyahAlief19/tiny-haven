class_name DayNightCycle
extends Node
## Siklus siang-malam Tiny Haven (iterasi 5).
##
## Satu DirectionalLight3D bergantian menjadi matahari (siang) dan bulan
## (malam). Posisi, warna, dan energinya dihitung dari jam (0-24):
##   sun_height = sin((jam - 6) / 24 * 2π)   -> 1 saat 12:00, -1 saat 00:00
##   daylight   = smoothstep(-0.12, 0.25, sun_height)
## Nilai daylight lalu dipakai untuk mencampur (lerp) warna langit, kabut,
## cahaya ambient, dan warna cahaya utama antara palet siang dan malam.
##
## Saat gelap (darkness > 0.5) sinyal lights_changed(true) dikirim supaya
## lentera dan api unggun menyala otomatis.

signal lights_changed(on: bool)
signal new_day

## Panjang satu hari penuh dalam detik pada kecepatan 1x.
@export var day_length: float = 300.0
@export var time_of_day: float = 21.0

## Pilihan kecepatan waktu, diganti dengan tombol T.
const SPEEDS: Array[float] = [1.0, 6.0, 0.0]
const SPEED_LABELS: Array[String] = ["1x", "6x", "berhenti"]

# Palet siang (langit pastel) dan malam (ungu dari ikon game).
const DAY_TOP := Color("5aa9e6")
const DAY_HORIZON := Color("ffc7d9")
const DAY_GROUND := Color("3d6e8f")
const DUSK_HORIZON := Color("ff7a8a")
const NIGHT_TOP := Color("0b0b2f")
const NIGHT_HORIZON := Color("892bd8")
const NIGHT_GROUND := Color("0b0b2f")

const SUN_COLOR := Color("fff1d6")
const DUSK_COLOR := Color("ff9a6b")
const MOON_COLOR := Color("c9a8ff")
const DAY_FOG := Color("9fc4e0")
const NIGHT_FOG := Color("3a2060")
# Rumput: toska saat malam (seperti menu), hijau segar saat siang.
const NIGHT_GRASS := Color(0.09, 0.5, 0.39)
const DAY_GRASS := Color(0.3, 0.56, 0.28)

var speed_index := 0
## 0 = siang penuh, 1 = malam penuh.
var darkness: float = 1.0
## Diisi oleh sistem cuaca: 0 = cerah, 1 = mendung tebal.
var overcast: float = 0.0

var _light: DirectionalLight3D
var _env: Environment
var _sky: ShaderMaterial
var _ground: StandardMaterial3D
var _lights_on := true

## Renderer Compatibility (dipakai versi web) menghitung cahaya lebih terang
## daripada Forward+, jadi semua energi cahaya dikali faktor ini.
static func light_scale() -> float:
	return 0.6 if RenderingServer.get_current_rendering_method() == "gl_compatibility" else 1.0

func setup(light: DirectionalLight3D, env: Environment, sky: ShaderMaterial, ground: StandardMaterial3D = null) -> void:
	_light = light
	_env = env
	_sky = sky
	_ground = ground
	_update(true)

func _process(delta: float) -> void:
	var before := time_of_day
	time_of_day = fmod(time_of_day + delta * SPEEDS[speed_index] * 24.0 / day_length, 24.0)
	if before < 6.0 and time_of_day >= 6.0:
		new_day.emit()
	_update(false)

func cycle_speed() -> String:
	speed_index = (speed_index + 1) % SPEEDS.size()
	return SPEED_LABELS[speed_index]

func speed_label() -> String:
	return SPEED_LABELS[speed_index]

func clock_text() -> String:
	var minutes := int(time_of_day * 60.0) % (24 * 60)
	return "%02d:%02d" % [minutes / 60, minutes % 60]

func is_night() -> bool:
	return darkness > 0.5

func set_time(hour: float) -> void:
	time_of_day = fposmod(hour, 24.0)
	_update(true)

func _update(force: bool) -> void:
	if _light == null:
		return
	var sun_height := sin((time_of_day - 6.0) / 24.0 * TAU)
	var daylight := smoothstep(-0.12, 0.25, sun_height)
	# Senja: paling kuat saat matahari dekat cakrawala.
	var dusk := clampf(1.0 - absf(sun_height) / 0.3, 0.0, 1.0)
	darkness = 1.0 - daylight

	# Matahari di atas cakrawala saat siang; bulan di posisi cermin saat malam.
	var elevation := maxf(asin(absf(sun_height)), deg_to_rad(12.0))
	var azimuth := time_of_day / 24.0 * TAU + PI * 0.25
	_light.rotation = Vector3(-elevation, azimuth, 0.0)

	var body_color := MOON_COLOR.lerp(SUN_COLOR, daylight).lerp(DUSK_COLOR, dusk * 0.6)
	var cloud_dim := 1.0 - overcast * 0.55
	_light.light_color = body_color
	_light.light_energy = lerpf(0.7, 1.1, daylight) * lerpf(0.35, 1.0, 1.0 - dusk * 0.7) * cloud_dim * light_scale()

	var grey := Color(0.45, 0.47, 0.55)
	var top := NIGHT_TOP.lerp(DAY_TOP, daylight).lerp(grey * 0.6, overcast * 0.6)
	var horizon := NIGHT_HORIZON.lerp(DAY_HORIZON, daylight).lerp(DUSK_HORIZON, dusk * 0.7).lerp(grey, overcast * 0.6)
	_sky.set_shader_parameter("top_color", top)
	_sky.set_shader_parameter("horizon_color", horizon)
	_sky.set_shader_parameter("ground_color", NIGHT_GROUND.lerp(DAY_GROUND, daylight))
	_sky.set_shader_parameter("night_factor", darkness)
	_sky.set_shader_parameter("cloud_cover", overcast)

	_env.ambient_light_energy = lerpf(0.85, 0.22, daylight) * cloud_dim * light_scale()
	if _ground:
		_ground.albedo_color = NIGHT_GRASS.lerp(DAY_GRASS, daylight)
	_env.fog_light_color = NIGHT_FOG.lerp(DAY_FOG, daylight).lerp(grey, overcast * 0.5)
	_env.fog_density = lerpf(0.012, 0.002, daylight) + overcast * 0.012

	var want_on := is_night()
	if force or want_on != _lights_on:
		_lights_on = want_on
		lights_changed.emit(want_on)
