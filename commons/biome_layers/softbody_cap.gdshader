// softbody_cap.gdshader — per-instance pulsing "softbody" wobble for batched caps.
//
// Replaces the CPU _process scale loop in softbody_flora.gd: the wobble now runs
// on the GPU, per vertex, for free. The cap MultiMesh carries per-instance COLOR
// (albedo) and INSTANCE_CUSTOM = (phase, stiffness, pressure, _). The vertex scale
// is applied in mesh-local space, so it composes with the instance transform's
// base size — identical math to the old `cap.scale = base * (pressure ± wobble)`.
shader_type spatial;
render_mode cull_disabled;

void vertex() {
	float phase = INSTANCE_CUSTOM.r;
	float stiff = INSTANCE_CUSTOM.g;
	float press = INSTANCE_CUSTOM.b;
	float wob = sin(TIME * (1.5 + stiff) + phase) * 0.08;
	VERTEX.x *= (press + wob);
	VERTEX.y *= (press - wob * 0.5);
	VERTEX.z *= (press + wob);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 0.3;
}
