// Langit malam Tiny Haven: gradasi ungu, bintang, dan bulan sabit.
//
// - Warna langit dicampur dari horizon ke puncak memakai smoothstep.
// - Bintang: arah pandang dibagi menjadi sel-sel kecil; sel yang nilai
//   hash-nya melewati ambang mendapat satu titik bintang.
// - Bulan: digambar di arah cahaya bulan (LIGHT0). Bentuk sabit didapat
//   dari lingkaran penuh dikurangi lingkaran kedua yang sedikit digeser.
//
// Iterasi 5: night_factor (0 siang, 1 malam) dari day_night_cycle.gd
// memudarkan bintang dan bulan, lalu menampilkan matahari saat siang.
// cloud_cover dari weather.gd meredupkan bintang, bulan, dan matahari.
//
// Shader ini sengaja tidak memakai TIME supaya cubemap radiance langit
// tidak dihitung ulang tiap frame (lebih ringan).
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.043, 0.043, 0.184);
uniform vec3 horizon_color : source_color = vec3(0.537, 0.169, 0.847);
uniform vec3 ground_color : source_color = vec3(0.043, 0.043, 0.184);
uniform float horizon_blend : hint_range(0.05, 1.0) = 0.35;

uniform float star_cells = 160.0;
uniform float star_density : hint_range(0.0, 0.05) = 0.012;
uniform float star_brightness = 3.0;

uniform vec3 moon_color : source_color = vec3(1.0, 0.95, 0.82);
uniform float moon_size : hint_range(0.01, 0.2) = 0.06;
uniform float moon_energy = 3.0;

uniform float night_factor : hint_range(0.0, 1.0) = 1.0;
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sun_color : source_color = vec3(1.0, 0.92, 0.75);
uniform float sun_size : hint_range(0.01, 0.2) = 0.05;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;

	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon_color, top_color, smoothstep(0.0, horizon_blend, h));
	} else {
		col = mix(horizon_color, ground_color, smoothstep(0.0, 0.1, -h));
	}

	if (AT_CUBEMAP_PASS == false && h > 0.0) {
		vec3 cell = floor(dir * star_cells);
		float n = hash(cell);
		if (n > 1.0 - star_density) {
			vec3 center = normalize((cell + 0.5) / star_cells);
			float d = distance(center, dir) * star_cells;
			// Kecerahan tiap bintang berbeda, diambil dari hash yang sama.
			float glow = smoothstep(0.45, 0.0, d) * (0.4 + 0.6 * fract(n * 37.0));
			col += vec3(1.0, 0.95, 0.9) * star_brightness * glow * smoothstep(0.0, 0.15, h)
				* night_factor * (1.0 - cloud_cover);
		}
	}

	if (LIGHT0_ENABLED) {
		vec3 to_moon = LIGHT0_DIRECTION;
		float md = distance(dir, to_moon);
		float disc = smoothstep(moon_size, moon_size * 0.9, md);
		// Geser lingkaran penutup ke samping kanan-atas bulan.
		vec3 right = normalize(cross(to_moon, vec3(0.0, 1.0, 0.0)));
		vec3 shadow_dir = normalize(to_moon + right * moon_size * 0.55 + vec3(0.0, moon_size * 0.25, 0.0));
		float cover = smoothstep(moon_size * 0.92, moon_size * 0.82, distance(dir, shadow_dir));
		float crescent = disc * (1.0 - cover);
		float clear = 1.0 - cloud_cover * 0.85;
		col += moon_color * crescent * moon_energy * night_factor * clear;
		// Halo lembut di sekitar bulan.
		col += moon_color * 0.18 * exp(-md * 9.0) * night_factor * clear;
		// Matahari: cakram bulat dengan cahaya lembut di sekitarnya.
		float sun = smoothstep(sun_size, sun_size * 0.8, md);
		col += sun_color * (sun * 4.0 + 0.35 * exp(-md * 6.0)) * (1.0 - night_factor) * clear;
	}

	COLOR = col;
}
