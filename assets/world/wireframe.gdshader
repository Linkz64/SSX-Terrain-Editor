shader_type spatial;
render_mode cull_disabled, unshaded;

void vertex() {
	vec3 direction_to_vertex = normalize(CAMERA_POSITION_WORLD - VERTEX);
	VERTEX += direction_to_vertex * vec3(100.0);
}

void fragment() {
	ALBEDO = vec3(0);
}

