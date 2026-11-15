shader_type spatial;
render_mode cull_disabled;
// A floor banded by one number. East is F, north is E; the number is F - lam E + 0.3 phi, the hall console's own.
// Every tenth of it is a band and a thin line; the line of the kept number is red; where the walker stands, a ring.
uniform float lam = 0.5;
uniform float phi = 0.0;
uniform float kept = -9.0;               // the kept number, or -9 for none
uniform vec2 kept_at = vec2(-9.0);       // (F, E) of the kept place
uniform vec2 here = vec2(-9.0);          // (F, E) of the walker
uniform float side = 6.0;                // metres across

varying vec2 fe;

void vertex() {
	fe = vec2(UV.x, 1.0 - UV.y);
}

void fragment() {
	float t = fe.x - lam * fe.y + 0.3 * phi;
	float per_m = sqrt(1.0 + lam * lam) / side;          // how much the number changes in one metre across the lines
	float tone = mod(floor(t * 10.0), 2.0);
	vec3 low = vec3(0.13, 0.19, 0.38);
	vec3 high = vec3(0.94, 0.74, 0.38);
	vec3 col = mix(low, high, clamp((t + 1.0) / 2.3, 0.0, 1.0)) * (0.9 + 0.1 * tone);
	float d = abs(fract(t * 10.0 + 0.5) - 0.5) / 10.0;   // to the nearest tenth, in the number's own units
	col = mix(col, vec3(0.06, 0.07, 0.1), 1.0 - smoothstep(0.006 * per_m, 0.012 * per_m, d));
	col = mix(col, vec3(0.95, 0.94, 0.9), 1.0 - smoothstep(0.014 * per_m, 0.024 * per_m, abs(t)));      // nought
	vec3 red = vec3(0.88, 0.1, 0.16);          // not pink: the tower paints its own walk in pink on every floor
	if (kept > -8.0) {
		col = mix(col, red, 1.0 - smoothstep(0.03 * per_m, 0.045 * per_m, abs(t - kept)));
		col = mix(col, red, 1.0 - smoothstep(0.13, 0.15, length((fe - kept_at) * side)));
	}
	if (here.x > -8.0) {
		float ring = abs(length((fe - here) * side) - 0.34);
		col = mix(col, vec3(0.97), 1.0 - smoothstep(0.015, 0.03, ring));
	}
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
