class_name WindSway
extends RefCounted
## Memasang shader goyangan angin (shaders/wind_sway.gdshader) pada model.
##
## Bahan bawaan model Kenney (StandardMaterial3D) diganti ShaderMaterial
## yang meniru warna dan teksturnya. Satu ShaderMaterial dipakai bersama
## oleh semua permukaan yang bahannya sama, jadi ratusan pohon cukup
## memakai beberapa bahan saja, dan kekuatan angin bisa diubah sekaligus
## lewat set_strength().

const SwayShader = preload("res://shaders/wind_sway.gdshader")

static var _cache: Dictionary = {}
static var _strength: float = 0.0

static func apply(root: Node, sway_height: float = 1.2) -> void:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for i in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.get_active_material(i) as BaseMaterial3D
			if source == null:
				continue
			mesh_instance.set_surface_override_material(i, _material_for(source, sway_height))

static func set_strength(value: float) -> void:
	_strength = value
	for key in _cache.keys():
		var mat: ShaderMaterial = _cache[key]
		if is_instance_valid(mat):
			mat.set_shader_parameter("strength", value)
		else:
			_cache.erase(key)

static func _material_for(source: BaseMaterial3D, sway_height: float) -> ShaderMaterial:
	var key := "%d_%.2f" % [source.get_instance_id(), sway_height]
	if _cache.has(key) and is_instance_valid(_cache[key]):
		return _cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = SwayShader
	mat.set_shader_parameter("albedo", source.albedo_color)
	mat.set_shader_parameter("roughness", source.roughness)
	mat.set_shader_parameter("use_vertex_color", source.vertex_color_use_as_albedo)
	if source.albedo_texture != null:
		mat.set_shader_parameter("albedo_texture", source.albedo_texture)
		mat.set_shader_parameter("use_texture", true)
	mat.set_shader_parameter("sway_height", sway_height)
	mat.set_shader_parameter("strength", _strength)
	_cache[key] = mat
	return mat
