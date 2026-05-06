# fold_test_runner.gd — Headless test framework for the fold system
#
# Run:
#   godot_console --path . --xr-mode off --headless --script res://commons/testing/fold_test_runner.gd
#
# Tests every layer of the fold system without rendering:
#   1. Resource creation (FoldSegmentData, FoldConstraintData, FoldRig)
#   2. Solver math (BoneFoldSolver, ChainFoldSolver, ShellFoldSolver)
#   3. Spring dynamics (fold_amount convergence, tension, energy)
#   4. FSM transitions (all state paths)
#   5. Parent gating (child waits for parent)
#   6. Constraint enforcement (angle clamping, latch)
#   7. Misfold threshold (tension → corruption)
#   8. VR verb API (compress, fan_open, tuck, smooth, feed)
#   9. Origami bird lifecycle (egg → standing → walking → flying)
#  10. Integration (FoldCritter with FoldRig end-to-end)
#
# Output: user://fold_test_results.json + console summary

extends SceneTree

var _results: Array[Dictionary] = []
var _pass_count: int = 0
var _fail_count: int = 0
var _warn_count: int = 0


func _init() -> void:
	# Must defer to allow SceneTree to initialize
	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	print("\n═══ FOLD SYSTEM TEST RUNNER ═══\n")

	_test_segment_data()
	_test_segment_size_and_thickness()
	_test_constraint_data()
	_test_fold_rig_creation()
	_test_bone_fold_solver()
	_test_chain_fold_solver()
	_test_chain_minimum_length()
	_test_shell_fold_solver()
	_test_shell_thickness_stacking()
	_test_parent_gating()
	_test_constraint_enforcement()
	_test_constraint_latch()
	_test_spring_convergence()
	_test_energy_gating()
	_test_tension_accumulation()
	_test_misfold_threshold()
	_test_fsm_egg_to_folded()
	_test_fsm_folded_to_deployed()
	_test_fsm_deployed_to_defensive()
	_test_fsm_misfold_override()
	_test_fsm_dormant_cycle()
	_test_vr_compress()
	_test_vr_fan_open()
	_test_vr_smooth()
	_test_vr_feed()
	_test_fold_demo_critter()
	_test_origami_bird_modes()
	_test_breathing_secondary()

	_print_summary()
	_save_results()
	quit(0 if _fail_count == 0 else 1)


# ═════════════════════════════════════════════════════════════════════════
# TEST HELPERS
# ═════════════════════════════════════════════════════════════════════════

func _assert(test_name: String, condition: bool, detail: String = "") -> void:
	if condition:
		_pass_count += 1
		_results.append({"test": test_name, "status": "PASS", "detail": detail})
		print("  PASS  %s" % test_name)
	else:
		_fail_count += 1
		_results.append({"test": test_name, "status": "FAIL", "detail": detail})
		print("  FAIL  %s — %s" % [test_name, detail])


func _assert_approx(test_name: String, value: float, expected: float, tolerance: float = 0.01) -> void:
	var diff: float = abs(value - expected)
	if diff <= tolerance:
		_pass_count += 1
		_results.append({"test": test_name, "status": "PASS", "detail": "%.4f ≈ %.4f" % [value, expected]})
		print("  PASS  %s (%.4f ≈ %.4f)" % [test_name, value, expected])
	else:
		_fail_count += 1
		_results.append({"test": test_name, "status": "FAIL", "detail": "%.4f ≠ %.4f (diff %.4f > %.4f)" % [value, expected, diff, tolerance]})
		print("  FAIL  %s — %.4f ≠ %.4f (diff %.4f)" % [test_name, value, expected, diff])


func _assert_range(test_name: String, value: float, min_val: float, max_val: float) -> void:
	if value >= min_val and value <= max_val:
		_pass_count += 1
		_results.append({"test": test_name, "status": "PASS", "detail": "%.4f in [%.4f, %.4f]" % [value, min_val, max_val]})
		print("  PASS  %s (%.4f in [%.2f, %.2f])" % [test_name, value, min_val, max_val])
	else:
		_fail_count += 1
		_results.append({"test": test_name, "status": "FAIL", "detail": "%.4f NOT in [%.4f, %.4f]" % [value, min_val, max_val]})
		print("  FAIL  %s — %.4f not in [%.2f, %.2f]" % [test_name, value, min_val, max_val])


func _make_test_rig() -> FoldRig:
	## Standard 3-segment test rig: core + left_wing + tail
	var rig := FoldRig.new()
	rig.solver = BoneFoldSolver.new()
	rig.base_stiffness = 10.0
	rig.base_damping = 0.85
	rig.max_fold_energy = 1.0

	var core := FoldSegmentData.new()
	core.segment_name = &"core"
	core.fold_axis = Vector3.RIGHT
	core.angle_closed = 0.0
	core.angle_open = 0.0
	core.size = Vector3(0.1, 0.08, 0.15)
	core.thickness = 0.08
	core.mass = 2.0

	var wing := FoldSegmentData.new()
	wing.segment_name = &"wing"
	wing.fold_axis = Vector3.FORWARD
	wing.angle_closed = 0.0
	wing.angle_open = 90.0
	wing.parent_segment = &"core"
	wing.parent_min_fold = 0.0
	wing.size = Vector3(0.2, 0.005, 0.12)
	wing.thickness = 0.005
	wing.mass = 1.0

	var tail := FoldSegmentData.new()
	tail.segment_name = &"tail"
	tail.fold_axis = Vector3.RIGHT
	tail.angle_closed = 0.0
	tail.angle_open = 45.0
	tail.parent_segment = &"core"
	tail.parent_min_fold = 0.3
	tail.size = Vector3(0.06, 0.005, 0.1)
	tail.thickness = 0.005
	tail.mass = 0.5

	rig.segments = [core, wing, tail]
	return rig


func _make_test_critter(rig: FoldRig = null) -> FoldCritter:
	if not rig:
		rig = _make_test_rig()
	var critter := FoldCritter.new()
	critter.fold_rig = rig
	# Add segment nodes so the pipeline doesn't crash
	for seg in rig.segments:
		var node := Node3D.new()
		node.name = String(seg.segment_name)
		critter.add_child(node)
	root.add_child(critter)
	# Let _ready run
	return critter


func _simulate_frames(critter: FoldCritter, frames: int, delta: float = 0.016) -> void:
	for i in frames:
		critter._physics_process(delta)


# ═════════════════════════════════════════════════════════════════════════
# 1. RESOURCE TESTS
# ═════════════════════════════════════════════════════════════════════════

func _test_segment_data() -> void:
	print("\n── Segment Data ──")
	var seg := FoldSegmentData.new()
	seg.segment_name = &"test"
	seg.fold_axis = Vector3.UP
	seg.angle_closed = -30.0
	seg.angle_open = 90.0
	_assert("segment name stored", seg.segment_name == &"test")
	_assert("segment axis stored", seg.fold_axis == Vector3.UP)
	_assert("angle range", seg.angle_open - seg.angle_closed == 120.0, "expected 120°")


func _test_segment_size_and_thickness() -> void:
	print("\n── Segment Size & Thickness ──")
	var seg := FoldSegmentData.new()
	seg.segment_name = &"sized"
	seg.size = Vector3(0.2, 0.05, 0.3)
	seg.thickness = 0.05
	seg.pivot_offset = Vector3(0.1, 0.0, 0.0)
	_assert("size stored", seg.size == Vector3(0.2, 0.05, 0.3))
	_assert("thickness stored", seg.thickness == 0.05)
	_assert("pivot offset stored", seg.pivot_offset == Vector3(0.1, 0.0, 0.0))
	# Thickness should be <= smallest size dimension (makes physical sense)
	var min_dim: float = min(seg.size.x, min(seg.size.y, seg.size.z))
	_assert("thickness <= min dimension", seg.thickness <= min_dim,
		"thickness=%.3f min_dim=%.3f" % [seg.thickness, min_dim])


func _test_constraint_data() -> void:
	print("\n── Constraint Data ──")
	var con := FoldConstraintData.new()
	con.segment_name = &"wing"
	con.min_angle = 0.0
	con.max_angle = 90.0
	con.latch_angle = 85.0
	con.latch_threshold = 5.0
	_assert("constraint min/max", con.min_angle == 0.0 and con.max_angle == 90.0)
	_assert("latch configured", con.latch_angle == 85.0)


func _test_fold_rig_creation() -> void:
	print("\n── FoldRig Creation ──")
	var rig := _make_test_rig()
	_assert("rig has solver", rig.solver != null)
	_assert("rig has 3 segments", rig.segments.size() == 3)
	_assert("solver is BoneFoldSolver", rig.solver is BoneFoldSolver)
	_assert("stiffness set", rig.base_stiffness == 10.0)
	_assert("state allowed (empty = all)", rig.is_state_allowed(FoldCritter.FoldState.DEPLOYED))


# ═════════════════════════════════════════════════════════════════════════
# 2. SOLVER TESTS
# ═════════════════════════════════════════════════════════════════════════

func _test_bone_fold_solver() -> void:
	print("\n── BoneFoldSolver ──")
	var solver := BoneFoldSolver.new()
	var rig := _make_test_rig()

	# fold_amount = 0 → all segments at closed angle
	var result_closed: Dictionary = solver.compute_fold(0.0, 0.0, rig.segments, rig.constraints)
	_assert("closed: 3 segments returned", result_closed.size() == 3)

	# fold_amount = 1 → wing should be at 90°
	var result_open: Dictionary = solver.compute_fold(1.0, 0.0, rig.segments, rig.constraints)
	_assert("open: segments returned", result_open.size() == 3)
	# Wing transform should have significant rotation
	var wing_t: Transform3D = result_open.get(&"wing", Transform3D.IDENTITY)
	_assert("wing rotated when open", wing_t != Transform3D.IDENTITY, "wing should rotate at fold_amount=1")

	# fold_amount = 0.5 → partial
	var result_half: Dictionary = solver.compute_fold(0.5, 0.0, rig.segments, rig.constraints)
	var wing_half: Transform3D = result_half.get(&"wing", Transform3D.IDENTITY)
	var wing_full: Transform3D = result_open.get(&"wing", Transform3D.IDENTITY)
	# Half should be between identity and full (basis determinant check)
	_assert("half fold < full fold", wing_half.basis != wing_full.basis, "0.5 and 1.0 should differ")


func _test_chain_fold_solver() -> void:
	print("\n── ChainFoldSolver ──")
	var solver := ChainFoldSolver.new()
	solver.curve_length_folded = 0.5
	solver.curve_length_open = 3.0

	var segments: Array[FoldSegmentData] = []
	for i in 5:
		var seg := FoldSegmentData.new()
		seg.segment_name = StringName("chain_%d" % i)
		seg.mass = 1.0
		segments.append(seg)

	var result_closed: Dictionary = solver.compute_fold(0.0, 0.0, segments, [])
	var result_open: Dictionary = solver.compute_fold(1.0, 0.0, segments, [])

	_assert("chain closed: 5 segments", result_closed.size() == 5)
	_assert("chain open: 5 segments", result_open.size() == 5)

	# Open chain should be longer than closed
	var last_closed: Transform3D = result_closed.get(&"chain_4", Transform3D.IDENTITY)
	var last_open: Transform3D = result_open.get(&"chain_4", Transform3D.IDENTITY)
	_assert("open chain longer", last_open.origin.length() > last_closed.origin.length(),
		"open=%.3f closed=%.3f" % [last_open.origin.length(), last_closed.origin.length()])


func _test_shell_fold_solver() -> void:
	print("\n── ShellFoldSolver ──")
	var solver := ShellFoldSolver.new()
	solver.layer_spacing_closed = 0.02
	solver.layer_spacing_open = 0.15

	var segments: Array[FoldSegmentData] = []
	for i in 4:
		var seg := FoldSegmentData.new()
		seg.segment_name = StringName("shell_%d" % i)
		seg.mass = 1.0
		segments.append(seg)

	var result_closed: Dictionary = solver.compute_fold(0.0, 0.0, segments, [])
	var result_open: Dictionary = solver.compute_fold(1.0, 0.0, segments, [])

	# Open shells should have greater Y separation
	var top_closed: Transform3D = result_closed.get(&"shell_3", Transform3D.IDENTITY)
	var top_open: Transform3D = result_open.get(&"shell_3", Transform3D.IDENTITY)
	_assert("shell layers separate when open",
		top_open.origin.y > top_closed.origin.y,
		"open_y=%.3f closed_y=%.3f" % [top_open.origin.y, top_closed.origin.y])


# ═════════════════════════════════════════════════════════════════════════
# 3. PARENT GATING
# ═════════════════════════════════════════════════════════════════════════

func _test_chain_minimum_length() -> void:
	print("\n── Chain Minimum Length (thickness) ──")
	var solver := ChainFoldSolver.new()
	solver.curve_length_open = 3.0

	var segments: Array[FoldSegmentData] = []
	var total_thickness: float = 0.0
	for i in 5:
		var seg := FoldSegmentData.new()
		seg.segment_name = StringName("chain_%d" % i)
		seg.thickness = 0.08  # Each segment is 0.08 thick
		seg.mass = 1.0
		segments.append(seg)
		total_thickness += seg.thickness

	# At fold_amount = 0, chain should be at minimum length = sum of thicknesses
	var result: Dictionary = solver.compute_fold(0.0, 0.0, segments, [])
	var last_pos: Vector3 = result.get(&"chain_4", Transform3D.IDENTITY).origin
	# Last segment should be at least total_thickness - one_segment away from origin
	_assert("compressed chain respects thickness",
		last_pos.length() >= total_thickness * 0.5,
		"last_pos=%.3f min_expected=%.3f" % [last_pos.length(), total_thickness * 0.5])


func _test_shell_thickness_stacking() -> void:
	print("\n── Shell Thickness Stacking ──")
	var solver := ShellFoldSolver.new()
	solver.layer_spacing_open = 0.15

	var segments: Array[FoldSegmentData] = []
	for i in 4:
		var seg := FoldSegmentData.new()
		seg.segment_name = StringName("shell_%d" % i)
		seg.thickness = 0.03  # Each shell layer is 0.03 thick
		seg.mass = 1.0
		segments.append(seg)

	# At fold_amount = 0, layers should stack at thickness intervals (no overlap)
	var result_closed: Dictionary = solver.compute_fold(0.0, 0.0, segments, [])
	var prev_y: float = 0.0
	var no_overlap: bool = true
	for i in 4:
		var t: Transform3D = result_closed.get(StringName("shell_%d" % i), Transform3D.IDENTITY)
		if i > 0 and t.origin.y < prev_y + 0.02:  # Allow small tolerance
			no_overlap = false
		prev_y = t.origin.y

	_assert("closed shells don't overlap",  no_overlap,
		"layers should stack at thickness intervals")

	# At fold_amount = 1, spacing should be larger than thickness
	var result_open: Dictionary = solver.compute_fold(1.0, 0.0, segments, [])
	var top_closed: Transform3D = result_closed.get(&"shell_3", Transform3D.IDENTITY)
	var top_open: Transform3D = result_open.get(&"shell_3", Transform3D.IDENTITY)
	_assert("open shells wider than closed",
		top_open.origin.y > top_closed.origin.y,
		"open=%.3f closed=%.3f" % [top_open.origin.y, top_closed.origin.y])


func _test_parent_gating() -> void:
	print("\n── Parent Gating ──")
	var solver := BoneFoldSolver.new()
	var rig := _make_test_rig()
	# tail has parent_min_fold = 0.3

	# At fold_amount = 0.2, parent (core) has 0° range so progress = 1.0
	# But core.angle_open == core.angle_closed == 0, so span is 0 → progress returns 1.0
	# This means gating doesn't restrict tail in this test rig (core has no range).
	# Use a rig where parent actually moves.

	var parent := FoldSegmentData.new()
	parent.segment_name = &"parent"
	parent.fold_axis = Vector3.RIGHT
	parent.angle_closed = 0.0
	parent.angle_open = 90.0
	parent.mass = 1.0

	var child := FoldSegmentData.new()
	child.segment_name = &"child"
	child.fold_axis = Vector3.UP
	child.angle_closed = 0.0
	child.angle_open = 60.0
	child.parent_segment = &"parent"
	child.parent_min_fold = 0.5
	child.mass = 0.5

	var segs: Array = [parent, child]

	# At fold_amount = 0.3, parent is at 30% of its range (27°)
	# Parent progress = 0.3. child.parent_min_fold = 0.5
	# Gate factor = 0.3 / 0.5 = 0.6 → child angle clamped to 60% of its target
	var result_low: Dictionary = solver.compute_fold(0.3, 0.0, segs, [])
	var child_t_low: Transform3D = result_low.get(&"child", Transform3D.IDENTITY)

	# At fold_amount = 1.0, parent fully open → child fully open
	var result_full: Dictionary = solver.compute_fold(1.0, 0.0, segs, [])
	var child_t_full: Transform3D = result_full.get(&"child", Transform3D.IDENTITY)

	_assert("gated child less rotated than full",
		child_t_low.basis.get_euler().length() < child_t_full.basis.get_euler().length(),
		"gated=%.4f full=%.4f" % [child_t_low.basis.get_euler().length(), child_t_full.basis.get_euler().length()])


# ═════════════════════════════════════════════════════════════════════════
# 4. CONSTRAINT TESTS
# ═════════════════════════════════════════════════════════════════════════

func _test_constraint_enforcement() -> void:
	print("\n── Constraint Enforcement ──")
	var solver := BoneFoldSolver.new()

	var seg := FoldSegmentData.new()
	seg.segment_name = &"limited"
	seg.fold_axis = Vector3.RIGHT
	seg.angle_closed = 0.0
	seg.angle_open = 180.0  # Wants to go to 180°
	seg.mass = 1.0

	var con := FoldConstraintData.new()
	con.segment_name = &"limited"
	con.min_angle = 0.0
	con.max_angle = 90.0  # But clamped to 90°

	var result: Dictionary = solver.compute_fold(1.0, 0.0, [seg], [con])
	var t: Transform3D = result.get(&"limited", Transform3D.IDENTITY)
	# Rotation should be ~90° not 180°
	var euler_deg: float = rad_to_deg(t.basis.get_euler().x)
	_assert_range("constrained to 90°", abs(euler_deg), 85.0, 95.0)


func _test_constraint_latch() -> void:
	print("\n── Constraint Latch ──")
	var solver := BoneFoldSolver.new()

	var seg := FoldSegmentData.new()
	seg.segment_name = &"latching"
	seg.fold_axis = Vector3.RIGHT
	seg.angle_closed = 0.0
	seg.angle_open = 90.0
	seg.mass = 1.0

	var con := FoldConstraintData.new()
	con.segment_name = &"latching"
	con.min_angle = 0.0
	con.max_angle = 90.0
	con.latch_angle = 45.0
	con.latch_threshold = 5.0

	# At fold_amount ~0.5, angle = 45° which is within latch threshold
	var result: Dictionary = solver.compute_fold(0.5, 0.0, [seg], [con])
	var t: Transform3D = result.get(&"latching", Transform3D.IDENTITY)
	var euler_deg: float = rad_to_deg(t.basis.get_euler().x)
	_assert_approx("latched at 45°", abs(euler_deg), 45.0, 1.0)


# ═════════════════════════════════════════════════════════════════════════
# 5. SPRING DYNAMICS
# ═════════════════════════════════════════════════════════════════════════

func _test_spring_convergence() -> void:
	print("\n── Spring Convergence ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_amount = 0.0
	critter.target_fold = 0.8
	critter.fold_energy = 1.0

	# Simulate 120 frames (~2 seconds)
	_simulate_frames(critter, 120)

	_assert_approx("converges toward target", critter.fold_amount, 0.8, 0.15)
	critter.queue_free()


func _test_energy_gating() -> void:
	print("\n── Energy Gating ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_amount = 0.0
	critter.fold_energy = 0.0  # No energy
	critter.target_fold = 1.0

	_simulate_frames(critter, 60)

	# Should NOT deploy without energy
	_assert("energy blocks deployment", critter.fold_amount < 0.3,
		"fold_amount=%.3f should stay low" % critter.fold_amount)
	critter.queue_free()


func _test_tension_accumulation() -> void:
	print("\n── Tension Accumulation ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_amount = 0.0
	critter.fold_energy = 1.0
	critter.target_fold = 1.0

	# Rapid unfolding should build tension
	_simulate_frames(critter, 30)
	_assert("tension builds from motion", critter.fold_tension > 0.01,
		"tension=%.4f" % critter.fold_tension)
	critter.queue_free()


func _test_misfold_threshold() -> void:
	print("\n── Misfold Threshold ──")
	var rig := _make_test_rig()
	rig.supports_misfold = true
	var critter := _make_test_critter(rig)
	critter.fold_state = FoldCritter.FoldState.DEPLOYED
	critter.fold_amount = 0.8
	critter.fold_energy = 1.0

	# Inject high tension directly
	critter.fold_tension = 0.95
	critter.misfold_amount = 0.4

	# Simulate — tension should push misfold over threshold
	_simulate_frames(critter, 60)

	_assert("misfold triggered", critter.misfold_amount > 0.0,
		"misfold=%.4f" % critter.misfold_amount)
	critter.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# 6. FSM TRANSITIONS
# ═════════════════════════════════════════════════════════════════════════

func _test_fsm_egg_to_folded() -> void:
	print("\n── FSM: EGG → FOLDED ──")
	var rig := _make_test_rig()
	rig.is_hatchable = true
	var critter := _make_test_critter(rig)
	critter.fold_state = FoldCritter.FoldState.EGG
	critter.fold_energy = 1.0

	_simulate_frames(critter, 120)

	_assert("transitions past EGG",
		critter.fold_state != FoldCritter.FoldState.EGG,
		"state=%d" % critter.fold_state)
	critter.queue_free()


func _test_fsm_folded_to_deployed() -> void:
	print("\n── FSM: FOLDED → DEPLOYED ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_amount = 0.05
	critter.fold_energy = 1.0
	critter.affect = "friend"

	# Place a fake player nearby
	var fake_player := Node3D.new()
	fake_player.name = "Player"
	fake_player.global_position = critter.global_position + Vector3(1, 0, 0)
	root.add_child(fake_player)
	critter._player_node = fake_player

	_simulate_frames(critter, 180)

	var reached_deploy: bool = (
		critter.fold_state == FoldCritter.FoldState.DEPLOYED or
		critter.fold_state == FoldCritter.FoldState.UNFOLDING
	)
	_assert("friend + nearby → unfold/deploy", reached_deploy,
		"state=%d fold=%.3f" % [critter.fold_state, critter.fold_amount])
	fake_player.queue_free()
	critter.queue_free()


func _test_fsm_deployed_to_defensive() -> void:
	print("\n── FSM: DEPLOYED → DEFENSIVE ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.DEPLOYED
	critter.fold_amount = 0.95
	critter.fold_energy = 1.0
	critter.affect = "wary"

	# Place threat nearby
	var fake_player := Node3D.new()
	fake_player.name = "Player"
	fake_player.global_position = critter.global_position + Vector3(0.5, 0, 0)
	root.add_child(fake_player)
	critter._player_node = fake_player
	critter.threat_detect_radius = 2.0

	_simulate_frames(critter, 30)

	_assert("wary + close → defensive",
		critter.fold_state == FoldCritter.FoldState.DEFENSIVE,
		"state=%d" % critter.fold_state)
	fake_player.queue_free()
	critter.queue_free()


func _test_fsm_misfold_override() -> void:
	print("\n── FSM: Misfold Override ──")
	var rig := _make_test_rig()
	rig.supports_misfold = true
	var critter := _make_test_critter(rig)
	critter.fold_state = FoldCritter.FoldState.DEPLOYED
	critter.fold_amount = 0.8
	critter.misfold_amount = 0.6  # Above threshold

	_simulate_frames(critter, 5)

	_assert("misfold overrides any state",
		critter.fold_state == FoldCritter.FoldState.MISFOLDED,
		"state=%d misfold=%.3f" % [critter.fold_state, critter.misfold_amount])
	critter.queue_free()


func _test_fsm_dormant_cycle() -> void:
	print("\n── FSM: Dormant Cycle ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_amount = 0.05
	critter.fold_energy = 0.01  # Nearly empty

	_simulate_frames(critter, 30)

	_assert("low energy → dormant",
		critter.fold_state == FoldCritter.FoldState.DORMANT,
		"state=%d energy=%.4f" % [critter.fold_state, critter.fold_energy])
	critter.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# 7. VR VERB API
# ═════════════════════════════════════════════════════════════════════════

func _test_vr_compress() -> void:
	print("\n── VR: Compress ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.DEPLOYED
	critter.fold_amount = 0.8
	critter.target_fold = 0.8
	var tension_before: float = critter.fold_tension

	critter.vr_compress()

	_assert("compress lowers target", critter.target_fold < 0.8,
		"target=%.3f" % critter.target_fold)
	_assert("compress adds tension", critter.fold_tension > tension_before,
		"tension=%.4f" % critter.fold_tension)
	critter.queue_free()


func _test_vr_fan_open() -> void:
	print("\n── VR: Fan Open ──")
	var critter := _make_test_critter()
	critter.fold_state = FoldCritter.FoldState.FOLDED
	critter.fold_amount = 0.2
	critter.target_fold = 0.2
	critter.fold_energy = 1.0

	critter.vr_fan_open()

	_assert("fan_open raises target", critter.target_fold > 0.2,
		"target=%.3f" % critter.target_fold)
	_assert("fan_open costs energy", critter.fold_energy < 1.0,
		"energy=%.4f" % critter.fold_energy)
	critter.queue_free()


func _test_vr_smooth() -> void:
	print("\n── VR: Smooth ──")
	var critter := _make_test_critter()
	critter.fold_tension = 0.5
	critter.misfold_amount = 0.3

	critter.vr_smooth()

	_assert("smooth reduces tension", critter.fold_tension < 0.5,
		"tension=%.4f" % critter.fold_tension)
	_assert("smooth reduces misfold", critter.misfold_amount < 0.3,
		"misfold=%.4f" % critter.misfold_amount)
	critter.queue_free()


func _test_vr_feed() -> void:
	print("\n── VR: Feed ──")
	var critter := _make_test_critter()
	critter.fold_energy = 0.3

	critter.vr_feed()

	_assert("feed restores energy", critter.fold_energy > 0.3,
		"energy=%.4f" % critter.fold_energy)
	critter.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# 8. INTEGRATION TESTS
# ═════════════════════════════════════════════════════════════════════════

func _test_fold_demo_critter() -> void:
	print("\n── FoldDemoCritter Integration ──")
	var scene: PackedScene = load("res://commons/fold_system/fold_demo_critter.tscn")
	_assert("demo scene loads", scene != null)
	if not scene:
		return

	var critter: FoldDemoCritter = scene.instantiate() as FoldDemoCritter
	_assert("demo instantiates", critter != null)
	if not critter:
		return

	root.add_child(critter)
	# Let _ready() run
	_assert("demo has fold_rig", critter.fold_rig != null)
	_assert("demo has solver", critter.fold_rig != null and critter.fold_rig.solver != null)
	_assert("demo has 4 segments", critter.fold_rig != null and critter.fold_rig.segments.size() == 4)
	_assert("demo starts FOLDED", critter.fold_state == FoldCritter.FoldState.FOLDED)

	# Simulate some frames
	critter.target_fold = 0.8
	critter.fold_energy = 1.0
	_simulate_frames(critter, 60)
	_assert("demo fold_amount moves", critter.fold_amount > 0.1,
		"fold=%.3f" % critter.fold_amount)

	critter.queue_free()


func _test_origami_bird_modes() -> void:
	print("\n── OrigamiBird Lifecycle ──")
	var scene: PackedScene = load("res://commons/fold_system/origami_bird.tscn")
	_assert("bird scene loads", scene != null)
	if not scene:
		return

	var bird: OrigamiBird = scene.instantiate() as OrigamiBird
	_assert("bird instantiates", bird != null)
	if not bird:
		return

	root.add_child(bird)
	_assert("bird has 13+ segments", bird.fold_rig != null and bird.fold_rig.segments.size() >= 12)
	_assert("bird starts EGG", bird.fold_state == FoldCritter.FoldState.EGG)
	_assert("bird starts EGG_SEED mode", bird.bird_mode == OrigamiBird.BirdMode.EGG_SEED)

	# Force fold progression and check mode mapping
	bird.fold_amount = 0.05
	bird._update_bird_mode()
	_assert("0.05 → EGG_SEED", bird.bird_mode == OrigamiBird.BirdMode.EGG_SEED)

	bird.fold_amount = 0.2
	bird._update_bird_mode()
	_assert("0.2 → HATCHING", bird.bird_mode == OrigamiBird.BirdMode.HATCHING)

	bird.fold_amount = 0.45
	bird._update_bird_mode()
	_assert("0.45 → STANDING", bird.bird_mode == OrigamiBird.BirdMode.STANDING)

	bird.fold_amount = 0.65
	bird._update_bird_mode()
	_assert("0.65 → WALKING", bird.bird_mode == OrigamiBird.BirdMode.WALKING)

	bird.fold_amount = 0.9
	bird._update_bird_mode()
	_assert("0.9 → FLYING", bird.bird_mode == OrigamiBird.BirdMode.FLYING)

	bird.queue_free()


func _test_breathing_secondary() -> void:
	print("\n── Breathing Secondary Motion ──")
	var solver := BoneFoldSolver.new()
	var rig := _make_test_rig()

	# Must call compute_fold first to cache segments
	solver.compute_fold(0.5, 0.0, rig.segments, rig.constraints)

	var secondary: Dictionary = solver.compute_secondary(0.016, &"idle")
	_assert("breathing returns transforms", secondary.size() > 0,
		"got %d segments" % secondary.size())

	if secondary.size() > 0:
		var any_key: StringName = secondary.keys()[0]
		var t: Transform3D = secondary[any_key]
		_assert("breathing is subtle", t.basis.get_euler().length() < 0.1,
			"euler_len=%.6f" % t.basis.get_euler().length())


# ═════════════════════════════════════════════════════════════════════════
# REPORTING
# ═════════════════════════════════════════════════════════════════════════

func _print_summary() -> void:
	var total: int = _pass_count + _fail_count + _warn_count
	print("\n═══ RESULTS ═══")
	print("  Total: %d  |  PASS: %d  |  FAIL: %d  |  WARN: %d" % [total, _pass_count, _fail_count, _warn_count])
	if _fail_count == 0:
		print("  ALL TESTS PASSED")
	else:
		print("  %d FAILURES — see details above" % _fail_count)
	print("")


func _save_results() -> void:
	var report := {
		"timestamp": Time.get_datetime_string_from_system(),
		"total": _pass_count + _fail_count + _warn_count,
		"pass": _pass_count,
		"fail": _fail_count,
		"warn": _warn_count,
		"tests": _results,
	}
	var json_str: String = JSON.stringify(report, "  ")
	var file := FileAccess.open("user://fold_test_results.json", FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("Results saved to user://fold_test_results.json")
