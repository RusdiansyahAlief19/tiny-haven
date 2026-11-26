class_name FlickerLight
extends OmniLight3D
## Lampu titik (point light) yang nyalanya bergoyang seperti api.
##
## Energinya dijumlahkan dari dua gelombang sinus dengan frekuensi berbeda,
## ditambah fase acak supaya beberapa api unggun tidak berkedip serempak.

@export var base_energy: float = 2.5
@export var amount: float = 0.35
@export var speed: float = 7.0

var _time: float = 0.0

func _ready() -> void:
	_time = randf() * 100.0

func _process(delta: float) -> void:
	_time += delta * speed
	light_energy = base_energy + sin(_time) * amount + sin(_time * 2.3) * amount * 0.6
