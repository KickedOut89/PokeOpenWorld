shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

// Tall-grass tufts: vertex colour gives a dark base and lighter tips; tips sway in the wind.
uniform float sway = 0.12;
uniform float speed = 1.8;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp(VERTEX.y / 0.8, 0.0, 1.0);
	float wave = sin(TIME * speed + world.x * 0.7 + world.z * 0.5) * sway * h * h;
	VERTEX.x += wave;
	VERTEX.z += wave * 0.5;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.9;
}
