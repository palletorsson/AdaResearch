shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_back;

uniform float grid_size = 1.0;
uniform float major_grid_size = 5.0;
uniform vec4 grid_color : source_color = vec4(0.3, 0.5, 0.8, 0.7);
uniform vec4 major_grid_color : source_color = vec4(0.5, 0.7, 1.0, 0.9);
uniform vec4 background_color : source_color = vec4(0.03, 0.03, 0.1, 0.2);
uniform float grid_thickness = 0.02;
uniform float major_grid_thickness = 0.05;
uniform float fade_distance = 10.0;
uniform float pulse_speed = 1.0;
uniform float pulse_intensity = 0.3;

varying vec3 world_position;
varying vec3 world_normal;
varying float distance_to_camera;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	distance_to_camera = length(CAMERA_POSITION_WORLD - world_position);
}

void fragment() {
	vec2 grid_pos = world_position.xz;
	
	// Calculate grid lines
	vec2 grid_coord = grid_pos / grid_size;
	vec2 major_grid_coord = grid_pos / major_grid_size;
	
	// Create grid pattern
	vec2 grid_lines = abs(fract(grid_coord) - 0.5) / fwidth(grid_coord);
	vec2 major_grid_lines = abs(fract(major_grid_coord) - 0.5) / fwidth(major_grid_coord);
	
	// Apply thickness
	float grid_line = 1.0 - min(min(grid_lines.x, grid_lines.y) / grid_thickness, 1.0);
	float major_grid_line = 1.0 - min(min(major_grid_lines.x, major_grid_lines.y) / major_grid_thickness, 1.0);
	
	// Distance-based fade
	float distance_fade = 1.0 - clamp(distance_to_camera / fade_distance, 0.0, 1.0);
	
	// Pulse effect
	float pulse = sin(TIME * pulse_speed) * pulse_intensity + 1.0;
	
	// Combine colors
	vec4 final_color = background_color;
	final_color = mix(final_color, grid_color, grid_line * distance_fade * pulse);
	final_color = mix(final_color, major_grid_color, major_grid_line * distance_fade * pulse);
	
	// Apply alpha based on distance
	final_color.a *= distance_fade;
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}









