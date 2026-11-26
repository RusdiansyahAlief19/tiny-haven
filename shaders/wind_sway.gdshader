// Goyangan angin untuk pohon dan tanaman (iterasi 5).
//
// Vertex shader menggeser setiap titik secara horizontal. Besarnya geseran:
//   - naik kuadratik terhadap tinggi titik (pangkal diam, pucuk bergoyang),
//   - mengikuti dua gelombang sinus yang fasenya bergantung pada posisi
//     dunia objek, supaya pohon yang berdekatan tidak bergoyang serempak,
//   - dikali strength yang diatur oleh weather.gd (0 = tenang).
// Bagian fragment hanya meniru bahan standar: warna albedo dan kekasaran.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform bool use_vertex_color = false;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;

uniform float strength = 0.0;
uniform float sway_height = 1.2;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0) / sway_height;
	float wave = sin(TIME * 1.7 + origin.x * 0.6 + origin.z * 0.4)
		+ 0.4 * sin(TIME * 3.3 + origin.z * 0.9);
	VERTEX.x += wave * strength * h * h * 0.12;
	VERTEX.z += wave * strength * h * h * 0.06;
}

void fragment() {
	vec4 color = albedo;
	if (use_texture) {
		color *= texture(albedo_texture, UV);
	}
	if (use_vertex_color) {
		color *= COLOR;
	}
	ALBEDO = color.rgb;
	ROUGHNESS = roughness;
}
