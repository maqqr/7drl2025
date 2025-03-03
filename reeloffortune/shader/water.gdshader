shader_type spatial;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;
uniform vec4 out_color : source_color = vec4(0.5, 0.5, 1.0, 1.0);
uniform float specular = 0.9;
uniform float roughness = 0.2;
uniform float time_scale = 2.0;
uniform float beer_factor = 2;

varying flat vec3 v_normal;

float get_wave(vec2 pos, float time, vec2 dir, float period, float amplitude) {
	return amplitude * sin((pos.x * dir.x + pos.y * dir.y + time) / period);
}

float get_height(vec2 pos, float time) {
	time *= 0.3;
	return -0.4 + get_wave(pos, time, vec2(0.5, 0.5), 0.3, 0.1)
		+ get_wave(pos, time, vec2(-0.6, 0.4), 0.12, 0.1)
		+ get_wave(pos, time, vec2(0.7, -0.2), 0.5, 0.06)
		+ get_wave(pos, time, vec2(0.9, 0.1), 0.3, 0.03);
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float amount = 0.5;
	float side_step = 0.01;
	float h = amount * get_height(world_pos.xz, TIME * time_scale);
	float h_right = amount * get_height(world_pos.xz + vec2(side_step, 0.0), TIME * time_scale);
	float h_up = amount * get_height(world_pos.xz + vec2(0.0, side_step), TIME * time_scale);
	float dx = (h_right - h) / side_step;
	float dz = (h_up - h) / side_step;
	vec3 pos_right = vec3(1, dx, 0);
	vec3 pos_up = vec3(0, dz, 1);
	v_normal = -cross(normalize(pos_right), normalize(pos_up));
	NORMAL = v_normal;
	VERTEX.y = h;
}

void fragment() {
	NORMAL = (VIEW_MATRIX * (vec4(v_normal, 0.0))).xyz;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	ALBEDO = out_color.rgb;
	
	ALPHA = 0.5;
	
	//float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	//vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	//vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	//view.xyz /= view.w;
	//float linear_depth = -view.z;
	//ALBEDO = vec3(linear_depth, linear_depth, linear_depth);
	
	//depth = depth * 2.0 - 1.0;
	//depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	//depth = depth + VERTEX.z;
//
	//depth = exp(-depth * beer_factor);
	//ALPHA = clamp(1.0 - depth, 0.0, 1.0);
}