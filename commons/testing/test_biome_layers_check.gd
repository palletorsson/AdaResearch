extends SceneTree
## Confirms the biome layer stack after removing the abstract 'Kusama' layers and
## adding ambient_particles. Synthetic mode (no ground_only) so non-ground layers
## render. Builds the real accrual via the scrubber, then inspects active kinds.
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_biome_layers_check.gd

const Scr = preload("res://commons/biome_layers/BiomeScrubberDesktop3D.gd")

const REMOVED := ["floating_primitives", "animated_primitives", "color_tint",
	"force_field", "lattice_snap", "wave_displace", "jitter_seed"]
const KEPT := ["ground_ring", "noise_dust", "fractal_bloom", "lsystem_trees",
	"dna_creatures", "softbody_flora", "swarm_creatures"]

func _initialize() -> void:
	var s = Scr.new()
	get_root().add_child(s)
	await process_frame
	await process_frame
	s._set_stage(14)                       # high stage → most layers active
	await process_frame

	var active: Array = s._active_kinds
	print("ACTIVE @14 = ", active)

	var fails := 0
	if not active.has("ambient_particles"):
		print("  FAIL: ambient_particles not active"); fails += 1
	else:
		print("  PASS: ambient_particles active")
	for r in REMOVED:
		if active.has(r):
			print("  FAIL: removed layer still active: ", r); fails += 1
	if fails == 0:
		print("  PASS: no abstract/Kusama layers active")
	for k in KEPT:
		if not active.has(k):
			print("  FAIL: kept layer missing: ", k); fails += 1
	if fails == 0:
		print("  PASS: living kingdoms + ground_ring + noise_dust kept")

	print("RESULT: ", "OK" if fails == 0 else "%d FAIL" % fails)
	quit(fails)
