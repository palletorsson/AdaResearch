shader_type canvas_item;

// Fullscreen chromatic world-colour wash for Color_Rainbow's Color Crossroad
// and Colour Mushroom Baskets (Desktop CanvasLayer pass).
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform vec3 tint_color: source_color = vec3(1.0, 0.3, 0.6);
uniform float intensity: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float dream_wave: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float i = clamp(intensity, 0.0, 1.0);
	if (i < 0.001) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		float w = clamp(dream_wave, 0.0, 1.0) * i;
		if (w > 0.001) {
			uv.x += sin(uv.y * 7.0 + TIME * 1.8) * 0.010 * w;
			uv.y += cos(uv.x * 6.0 + TIME * 1.5) * 0.008 * w;
		}
		vec3 scene = texture(SCREEN_TEXTURE, uv).rgb;
		float lum = dot(scene, vec3(0.299, 0.587, 0.114));
		// Duotone chromatic wash preserves contrast and readability while
		// unmistakably flooding the world in the chosen hue.
		vec3 shadow_col = tint_color * (0.28 + 0.55 * lum);
		vec3 highlight_col = mix(tint_color, vec3(1.0), 0.45) * (0.45 + 0.75 * lum);
		vec3 washed = mix(shadow_col, highlight_col, smoothstep(0.15, 0.85, lum));
		// Blend softly with a multiplicative filter so existing rainbow geometry stays legible.
		vec3 multiplied = scene * mix(vec3(1.0), tint_color * 1.35 + vec3(0.06), 0.72);
		vec3 target = mix(multiplied, washed, 0.52);
		float vig = 1.0 - smoothstep(0.45, 1.35, length(SCREEN_UV - vec2(0.5)) * 2.0) * 0.18 * i;
		vec3 final_col = mix(scene, target * vig, i * 0.62);
		COLOR = vec4(final_col, 1.0);
	}
}
