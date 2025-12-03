shader_type spatial;

uniform sampler2D noise_tex;
uniform float perturb_strength : hint_range(0.0, 2.0) = 0.5;
uniform vec3 alive_color : source_color = vec3(0.2, 0.8, 0.2);
uniform vec3 dead_color : source_color = vec3(0.2, 0.2, 0.8);
uniform float height_scale : hint_range(0.0, 5.0) = 1.0;

varying vec3 v_world_pos;
varying float v_state;

void vertex() {
	// Instance custom data: x = state (0.0 or 1.0), y = random/noise offset
	float state = INSTANCE_CUSTOM.x;
	v_state = state;
	
	// Perturb vertices based on world position (Catlike Coding Part 4 style)
	// We use the vertex position relative to the instance + instance position
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_pos = world_pos;
	
	vec2 noise_uv = world_pos.xz * 0.1;
	vec4 noise = texture(noise_tex, noise_uv);
	
	// Perturb X and Z
	VERTEX.x += (noise.x - 0.5) * perturb_strength;
	VERTEX.z += (noise.y - 0.5) * perturb_strength;
	
	// Adjust height based on state (Terraces)
	// We assume the mesh is a cylinder with y from -1 to 1 or 0 to 1.
	// Let's assume we scale Y in the transform, but we can also add detail here.
	
	// Flat top shading fix (optional)
}

void fragment() {
	// Biome coloring (Part 26 style - simplified)
	vec3 color = mix(dead_color, alive_color, v_state);
	
	// Add some noise to color
	vec4 noise = texture(noise_tex, v_world_pos.xz * 0.2);
	color = mix(color, color * noise.rgb, 0.2);
	
	ALBEDO = color;
	ROUGHNESS = 0.8;
	METALLIC = 0.1;
}
