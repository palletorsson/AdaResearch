// biome_ground.gdshader — height-banded ground + a painted/bled colour overlay.
// The height bands give the terrain its base earth→grass→light look; the
// paint_tex (a per-grid RGBA texture composed in biome_ground_substrate.gd)
// overlays shader-painted colour and plant "bleed" (plants seeping their
// kingdom colour into the ground). See doc/PAINT_LAYERS.md.
shader_type spatial;
render_mode cull_disabled;

uniform vec3 color_low  = vec3(0.26, 0.22, 0.17);
uniform vec3 color_mid  = vec3(0.34, 0.40, 0.26);
uniform vec3 color_high = vec3(0.62, 0.66, 0.52);
uniform float height_min = 0.0;
uniform float height_max = 1.5;
uniform sampler2D paint_tex : source_color, filter_linear;

varying float v_height;

void vertex() {
	v_height = VERTEX.y;
}

void fragment() {
	float t = clamp((v_height - height_min) / max(0.001, height_max - height_min), 0.0, 1.0);
	vec3 base = (t < 0.5) ? mix(color_low, color_mid, t * 2.0)
						  : mix(color_mid, color_high, (t - 0.5) * 2.0);
	vec4 p = texture(paint_tex, UV);   // rgb = painted/bled colour, a = coverage
	ALBEDO = mix(base, p.rgb, clamp(p.a, 0.0, 1.0));
	ROUGHNESS = mix(0.9, 0.55, p.a);   // painted/wet areas read a touch glossier
	METALLIC = 0.0;
}
