shader_type spatial;

uniform vec4 color_top = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_bottom = vec4(0.0, 0.0, 1.0, 1.0);
uniform float intensity = 1.0;
uniform float position = 0.0;
uniform float blend = 0.5;
uniform float angle = 90.0;
uniform float line_height_min = 0.01;
uniform float line_height_max = 0.1;
uniform float num_lines = 6.0;
uniform float speed = 0.1;
uniform float vertical_origin = 0.0;

void fragment() {
	vec2 uv = UV;
	
	// Create grid pattern
	float grid_x = step(fract(uv.x * num_lines), 0.1);
	float grid_y = step(fract(uv.y * num_lines), 0.1);
	float grid = max(grid_x, grid_y);
	
	// Create moving lines
	float moving_line = sin(uv.x * 20.0 + TIME * speed) * 0.5 + 0.5;
	moving_line = step(moving_line, 0.1);
	
	// Combine patterns
	float pattern = max(grid, moving_line);
	
	// Create gradient from top to bottom
	vec4 gradient = mix(color_top, color_bottom, uv.y);
	
	// Apply pattern and intensity
	vec4 final_color = gradient * pattern * intensity;
	
	// Set material properties
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	
	// Add some emission for underwater visibility
	EMISSION = final_color.rgb * 0.2;
}
