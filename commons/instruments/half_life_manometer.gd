extends "res://commons/instruments/lab_instrument.gd"

# @identity
# essence: a piece of bench glassware that does not measure what a thing IS but how fast it is ceasing to be that — the rate of becoming, QFEP's ΦΔE term. A vertical glass tube holds not mercury but vortessence (the shared light of all living things); a dial beside it carries a needle that reads zero at perfect order (nothing becomes) and zero at pure noise (all becomes, so nothing is) and climbs only at the living edge. The needle never rests; it twitches toward 0.4.
# desire: it wants to make the invisible term visible. Every other gauge on Earth reads state. This one reads the half-life — the slope of transformation — and so it is the only instrument that can point at life, which is neither order nor noise but the becoming between them.
# critical_parameter: the needle angle = ΦΔE, pinned toward the 0.4 mark (life at the edge). The fluid column = the vortessence charge. Both pulse; neither settles, because becoming that settles is just state again.
# triggers: _build assembles bench + glass tube + glowing fluid + dial face + ticks (0, 0.4, 1) + a twitching needle; apply_grid_config rebuilds.
# emerges: mounted on the QFEP lab wall beside the formula board, it turns the abstract ΦΔE into a thing you watch flicker — the cost of delta given a needle.
# needs: a glass tube [present]; a glowing vortessence column [present]; a dial reading 0..1 with 0.4 marked as the living edge [present]; a needle that never rests [present]
# relationships: sibling to the qfep_chalkboard (the board states QFE = F - λE + ΦΔE; this instrument reads the ΦΔE term live); the keystone of Turing's bench; calibrates every other instrument in the family.
# truth: state has a thousand gauges; becoming has none. To build a needle for ΦΔE is to claim that the rate of difference — the half-life, the cost of delta — is a measurable thing, and that life is found not at rest but where the needle will not hold still.

func _build() -> void:
	bench(0.95, Color(0.17, 0.19, 0.23))
	var y := 1.0

	# the vortessence tube: glass shell + glowing fluid column
	add_cyl(0.065, 0.62, Vector3(-0.18, y + 0.31, 0.0), Color(0.6, 0.9, 1.0, 0.22))
	var fluid := add_cyl(0.048, 0.34, Vector3(-0.18, y + 0.17, 0.0), Color(0.2, 1.0, 0.7), 2.4)
	animate_node(fluid, "pulse", 2.4, 1.3)
	add_cyl(0.07, 0.03, Vector3(-0.18, y + 0.62, 0.0), Color(0.7, 0.72, 0.78))  # cap

	# the dial
	add_box(Vector3(0.32, 0.32, 0.02), Vector3(0.18, y + 0.36, 0.04), Color(0.09, 0.11, 0.14))
	add_torus(0.15, 0.2, Vector3(0.18, y + 0.36, 0.06), Color(0.82, 0.84, 0.9))
	add_label("0", Vector3(0.03, y + 0.27, 0.08), 0.0024, Color(0.7, 0.7, 0.75))
	add_label("0.4", Vector3(0.17, y + 0.56, 0.08), 0.0026, Color(0.3, 1.0, 0.6))
	add_label("1", Vector3(0.33, y + 0.27, 0.08), 0.0024, Color(0.7, 0.7, 0.75))

	# the needle, pivoting at the dial centre, pinned toward the 0.4 mark
	var pivot := add_node(Vector3(0.18, y + 0.36, 0.08))
	var needle := MeshInstance3D.new()
	var nm := CylinderMesh.new(); nm.top_radius = 0.0; nm.bottom_radius = 0.013; nm.height = 0.17
	needle.mesh = nm
	needle.material_override = mat(Color(1.0, 0.7, 0.1), 2.6)
	needle.position = Vector3(0, 0.085, 0)
	pivot.add_child(needle)
	add_sphere(0.022, Vector3(0.18, y + 0.36, 0.08), Color(0.9, 0.9, 0.95))  # hub
	pivot.rotation_degrees = Vector3(0, 0, 32)
	animate_node(pivot, "twitch", 0.22, 1.0)

	# titles
	add_label("dE/dt", Vector3(0.18, y + 0.78, 0.05), 0.0042, Color(0.3, 1.0, 0.6))
	add_label("HALF-LIFE MANOMETER", Vector3(0.0, y + 0.96, 0.0), 0.003, Color(0.82, 0.86, 0.92))
