// MILKY GLASS — frosting is a BLUR, and alpha is not one.
//
// The first pass glazed this window with a translucent white material and the
// capture came back a flat white rectangle: alpha dims what is behind it, it
// never spreads it, so a hard lamp behind the pane stayed a hard lamp at 38%
// and the room's own light on the near face buried it. Frosted glass scatters
// each ray into a cone — one point behind the pane arrives as a disc in front
// of it — which is a read of the NEIGHBOURHOOD, and only a shader can do that.
//
// So the pane samples the screen behind it twelve times around a jittered ring
// and averages. The ring is the cone; `frost` is its half-angle in screen
// units. Then the average is mixed toward the milk colour, which is what glass
// with something suspended in it actually does to transmitted light.
//
// UNSHADED and opaque on purpose. The composite is finished here: what is
// behind is already in the sample, so letting the room light this surface again
// would add the near face's illumination on top of light that has, physically,
// come through from the other side.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

// What the glass itself is made of. Not white: a white pane is brighter than
// anything behind it and the colour never arrives.
uniform vec4 milk_color : source_color = vec4(0.80, 0.81, 0.84, 1.0);
// How much of the pane is milk and how much is the room behind it. 0 is a clear
// window, 1 is a painted one; the artifact lives around 0.4.
uniform float milk : hint_range(0.0, 1.0) = 0.45;
// The scatter radius, in screen widths. 0 is polished glass. Above ~0.03 the
// window stops reading as glass and starts reading as fog.
uniform float frost : hint_range(0.0, 0.06) = 0.016;
// Rolled surface. Fine speckle so the pane has a material and not just a value.
uniform float grain : hint_range(0.0, 1.0) = 0.30;
// Lifts what comes through, so a dim lamp still reads as colour rather than as
// a grey patch. This is the "backlit" feeling, done to the sample.
uniform float transmit : hint_range(0.0, 3.0) = 1.25;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	// The taps sit on a ring at a per-pixel random start angle. A FIXED start
	// makes twelve ghost copies of every bright edge — the rotation is what
	// turns the taps into a disc instead of a rosette.
	float a0 = hash12(FRAGCOORD.xy) * 6.2831853;
	// SCREEN_UV is 0..1 across the viewport, so an equal step in u and v is a
	// wider step in metres on a wide screen. Without this the frost is an
	// ellipse that changes shape with the window size.
	float aspect = VIEWPORT_SIZE.y / max(1.0, VIEWPORT_SIZE.x);

	vec3 acc = vec3(0.0);
	for (int i = 0; i < 12; i++) {
		float fi = float(i);
		float ang = a0 + fi * 0.5235988;              // 30 degrees apart
		// golden-ratio radii: the taps fill the disc instead of all landing on
		// its rim, which is what a single-radius ring gives you
		float rad = frost * (0.30 + 0.70 * fract(fi * 0.6180340));
		vec2 off = vec2(cos(ang) * aspect, sin(ang)) * rad;
		acc += texture(screen_tex, SCREEN_UV + off).rgb;
	}
	acc /= 12.0;

	vec3 through = acc * transmit;
	vec3 pane = mix(through, milk_color.rgb, milk);

	// the roll of the glass — a percent or two, enough to catch the eye as
	// surface without becoming noise
	float g = hash12(FRAGCOORD.xy * 0.61 + 3.7);
	pane *= 1.0 + (g - 0.5) * 0.09 * grain;

	ALBEDO = pane;
	ALPHA = 1.0;
}
