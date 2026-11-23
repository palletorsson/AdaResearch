shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, skip_vertex_transform, fog_disabled, shadows_disabled;

// Inside the white block on Prefab Test: what the eye sees, blurred (Palle, 23 Nov 2026: "add a blur inside the cube").
// A quad over the whole view, under the camera - the way commons/artifacts/rainbow_playground's world wash covers the
// view on desktop and in a headset alike (its vertex function, unchanged). The blur is a spiral of taps read at a
// lower mip level of the screen: where the renderer makes screen mipmaps both soften, where it does not the taps
// still do. white_block.gd sets `amount` by how deep the eye is in the block.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float radius = 0.028;   // of the view's height, at full amount
uniform float lod = 2.4;        // mip level at full amount

const int TAPS = 12;

void vertex() {
	vec2 vert_pos = VERTEX.xy;
	if (length(vert_pos) < 0.99) {
		vec4 offset = PROJECTION_MATRIX * vec4(0.0, 0.0, 1.0, 1.0);
		vert_pos += (offset.xy / offset.w);
	}
	POSITION = vec4(vert_pos, 1.0, 1.0);
}

void fragment() {
	float a = clamp(amount, 0.0, 1.0);
	vec2 uv = SCREEN_UV;
	float level = lod * a;
	vec2 reach = vec2(radius * a * VIEWPORT_SIZE.y / max(VIEWPORT_SIZE.x, 1.0), radius * a);
	vec3 sum = textureLod(screen_texture, uv, level).rgb * 2.0;
	float weight = 2.0;
	for (int i = 0; i < TAPS; i++) {
		float t = float(i) + 0.5;
		float turn = t * 2.39996;                       // the golden angle: taps that never line up
		vec2 o = vec2(cos(turn), sin(turn)) * sqrt(t / float(TAPS)) * reach;
		sum += textureLod(screen_texture, clamp(uv + o, vec2(0.001), vec2(0.999)), level).rgb;
		weight += 1.0;
	}
	ALBEDO = sum / weight;
}
