shader_type spatial;
render_mode cull_disabled, unshaded; // Unshaded for glowing "neon" look, or diffuse for cloth? User said "mesmerizing", "crazy". unshaded + glow implies neon. Let's try unshaded first or handling light manually.
// Let's use standard lighting but with high emission?
// "Mesmerizing" often implies iridescence.

uniform vec4 base_color : source_color = vec4(0.1, 0.5, 1.0, 0.8);
uniform vec4 shimmer_color : source_color = vec4(1.0, 0.2, 0.8, 0.5);
uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float frequency : hint_range(0.1, 10.0) = 2.0;
uniform float amplitude : hint_range(0.0, 1.0) = 0.2;

void vertex() {
	// Waving effect
	float wave = sin(UV.y * frequency - TIME * speed) * amplitude * UV.y; // wave increases along length
	VERTEX.x += wave;
	VERTEX.z += cos(UV.y * frequency * 0.5 - TIME * speed * 0.7) * amplitude * 0.5 * UV.y;
}

void fragment() {
	// Holographic / Iridescent effect
	// Fresnel-like calculation
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 normal = normalize(NORMAL);
	float fresnel = pow(1.0 - abs(dot(view_dir, normal)), 3.0);
	
	// Moving color bands along UV.y
	float bands = sin(UV.y * 10.0 + TIME * 2.0) * 0.5 + 0.5;
	
	vec3 color = mix(base_color.rgb, shimmer_color.rgb, fresnel + bands * 0.5);
	
	ALBEDO = color;
	ALPHA = base_color.a * (0.5 + 0.5 * fresnel); // Edges are more opaque
	EMISSION = color * 0.5; // Slight glow
}
