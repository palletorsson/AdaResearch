shader_type spatial;
render_mode cull_disabled, unshaded;

// Rainbow trail shader - creates flowing multicolor effect along trail

uniform float speed : hint_range(0.5, 10.0) = 3.0;
uniform float color_frequency : hint_range(1.0, 10.0) = 2.0;
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.15;
uniform float wave_frequency : hint_range(1.0, 10.0) = 4.0;
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.5;
uniform float saturation : hint_range(0.5, 1.0) = 0.9;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	// Flowing wave effect
	float wave = sin(UV.y * wave_frequency - TIME * speed) * wave_amplitude * UV.y;
	VERTEX.x += wave;
	VERTEX.z += cos(UV.y * wave_frequency * 0.7 - TIME * speed * 1.3) * wave_amplitude * 0.6 * UV.y;
}

void fragment() {
	// Create flowing rainbow based on position along trail and time
	float hue = fract(UV.y * color_frequency - TIME * speed * 0.2);

	// Add shimmer variation across width
	hue += sin(UV.x * PI * 2.0 + TIME * speed) * 0.1;
	hue = fract(hue);

	// Secondary color wave for extra depth
	float hue2 = fract(UV.y * color_frequency * 0.5 + TIME * speed * 0.15);

	// Blend two rainbow frequencies
	vec3 color1 = hsv2rgb(vec3(hue, saturation, brightness));
	vec3 color2 = hsv2rgb(vec3(hue2, saturation * 0.8, brightness * 1.1));

	// Fresnel-like edge glow
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 normal = normalize(NORMAL);
	float fresnel = pow(1.0 - abs(dot(view_dir, normal)), 2.0);

	// Mix colors with fresnel for edge shimmer
	vec3 final_color = mix(color1, color2, fresnel * 0.5 + 0.25);

	// Sparkle effect
	float sparkle = sin(UV.y * 50.0 + TIME * 15.0) * sin(UV.x * 30.0 - TIME * 10.0);
	sparkle = max(0.0, sparkle) * 0.3;
	final_color += vec3(sparkle);

	// Alpha fades along trail length (older = more transparent)
	float alpha = 1.0 - UV.y * 0.7;
	alpha *= 0.5 + 0.5 * fresnel; // Edges slightly more visible

	ALBEDO = final_color;
	ALPHA = alpha;
	EMISSION = final_color * glow_intensity;
}
