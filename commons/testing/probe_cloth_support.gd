extends SceneTree

## GATE — SoftBodies_Cloth_Physics: the support changes and the cloth does not.
##
## The hall already says "A convincing support does not prove how the simulation is
## attached to it." Until now nothing let a visitor test it: cloth_straps ships five
## suspension rigs and no map token or console control selected any of them, so every
## visitor saw exactly one frame. The new SUPPORT control exposes them.
##
## This probe proves the sentence rather than repeating it. The pins are computed from
## REST MESH COORDINATES —
##     absf(rest[index].y - strap_height * 0.5) < 0.001
## — and never consult the rig, so swapping the frame must leave the pinned index set
## and the pinned world positions untouched. If that is not true, the writing is wrong
## and must not ship.
##
##   A  lesson build          -> 8 strips, each pinned along its top row
##   B  SUPPORT changes rig   -> the frame's children genuinely differ
##   C  pinned INDEX SET      -> identical across the change
##   D  the HELD EDGE              -> identical across the change. NOTE: pinned points cannot
##                              move, so this proves the PIN SET SURVIVED the rebuild,
##                              not that the cloth is undisturbed. It was written as the
##                              latter and a review caught it.
##   J  the free body              -> IS moving, so any claim that "the cloth does not move"
##                              is false on its face; only the held edge is still
##   E  suspension "none"     -> no rig at all, and the cloth still hangs pinned
##   F  all five values       -> cycle without error and each is accepted
##   H  act("SUPPORT")       -> the real dispatch path changes the artifact
##   I  the desk itself      -> 7 buttons built, SUPPORT wired to act, firing it works
##   G  pin arithmetic        -> mode 0 top row, mode 1 exactly two corners, mode 2 none,
##                              and mode 0 IS reachable again without REBUILD

const STRAPS := "res://algorithms/softbodies/cloth_straps/cloth_straps.tscn"
const DESK := "res://commons/artifacts/timing_machines/soft_workshop.gd"
const RIGS := ["gantry", "none", "hoop", "mast", "wall"]
const STOP := "res://algorithms/physicssimulation/softbodies/softbodystop/fourstopsoftbody.tscn"
const CLOTH_IDS := ["PINS", "SUPPORT", "STIFFNESS", "RELEASE", "REBUILD", "LANDING", "RULE"]

var _fails: Array = []
## Set only by the final line of _run(). Without it, an abort reads as success.
var _finished: bool = false


func _initialize() -> void:
	await _run()
	if not _finished:
		_fails.append("the probe aborted before the last case — a SCRIPT ERROR above "
			+ "killed the coroutine, so the checks after it never ran and their silence "
			+ "is not a pass")
	if _fails.is_empty():
		print("\nprobe_cloth_support: ALL 10 CASES PASS")
		quit(0)
	else:
		print("\nprobe_cloth_support: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)


func _check(label: String, ok: bool, detail: String = "") -> void:
	var line: String = "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	if ok:
		print("  ok    %s" % line)
	else:
		_fails.append(line)
		print("  FAIL  %s" % line)


func _strips(n: Node) -> Array:
	var out: Array = []
	for c in n.find_children("*", "SoftBody3D", true, false):
		if c.visible:
			out.append(c)
	return out


## Which indices the solver currently holds fixed.
func _pinned(sb: SoftBody3D) -> Array:
	var out: Array = []
	for i in sb.mesh.surface_get_array_len(0):
		if sb.is_point_pinned(i):
			out.append(i)
	return out


## Where those fixed points actually are in the world, read back from the physics
## server rather than from the mesh resource, which the solver does not write.
func _pinned_positions(sb: SoftBody3D) -> Array:
	var out: Array = []
	var rid: RID = sb.get_physics_rid()
	for i in _pinned(sb):
		out.append(PhysicsServer3D.soft_body_get_point_global_position(rid, i))
	return out


func _settle(frames: int) -> void:
	for i in frames:
		await physics_frame


func _run() -> void:
	print("probe_cloth_support")

	var straps: Node3D = load(STRAPS).instantiate()
	straps.set_meta("config_lesson", "true")
	root.add_child(straps)
	await _settle(20)

	# --- A ---
	var strips: Array = _strips(straps)
	_check("A the lesson build makes 8 strips", strips.size() == 8, "%d strips" % strips.size())
	if strips.is_empty():
		return
	var first: SoftBody3D = strips[0]
	var pins_before: Array = _pinned(first)
	_check("A each strip is pinned along its top row", pins_before.size() > 2,
		"%d of %d points pinned" % [pins_before.size(), first.mesh.surface_get_array_len(0)])

	var pos_before: Array = _pinned_positions(first)
	var rig_before: int = 0
	var rig_node: Node = straps.get_node_or_null("SuspensionFrame")
	for c in straps.get_children():
		if c is StaticBody3D:
			rig_node = c
	if rig_node != null:
		rig_before = rig_node.get_child_count()

	# --- B: change the support ---
	straps.apply_grid_config({"suspension": "hoop"})
	await _settle(20)
	_check("B SUPPORT changed the artifact's suspension", str(straps.suspension) == "hoop",
		str(straps.suspension))
	var rig_after_node: Node = null
	for c in straps.get_children():
		if c is StaticBody3D:
			rig_after_node = c
	var rig_after: int = rig_after_node.get_child_count() if rig_after_node != null else 0
	_check("B the frame is genuinely a different rig",
		rig_after_node != rig_node or rig_after != rig_before,
		"gantry had %d parts, hoop has %d" % [rig_before, rig_after])

	# --- C and D: the cloth must not have noticed ---
	var strips_after: Array = _strips(straps)
	_check("C the same 8 strips survive the rig change", strips_after.size() == 8,
		"%d strips" % strips_after.size())
	var pins_after: Array = _pinned(first)
	_check("C the pinned index set is identical", pins_after == pins_before,
		"%d -> %d pinned" % [pins_before.size(), pins_after.size()])

	var pos_after: Array = _pinned_positions(first)
	var worst: float = 0.0
	if pos_after.size() == pos_before.size():
		for i in pos_before.size():
			worst = maxf(worst, (pos_before[i] as Vector3).distance_to(pos_after[i]))
	_check("D the held edge survives the rebuild (pinned points cannot move: see header)",
		pos_after.size() == pos_before.size() and worst < 0.001,
		"largest movement %.6f m" % worst)

	# --- J: the correction. A free vertex must be measured before anyone writes that the
	#        cloth "does not move". The artifact's own note says a 3.5 m sheet at
	#        linear_stiffness 0.34 is still stretching and swinging; if that is true the
	#        absolute claim is false regardless of what the frame does. ---
	var free_idx: int = -1
	for i in first.mesh.surface_get_array_len(0):
		if not first.is_point_pinned(i):
			free_idx = i
			break
	var rid: RID = first.get_physics_rid()
	var f0: Vector3 = PhysicsServer3D.soft_body_get_point_global_position(rid, free_idx)
	await _settle(30)
	var f1: Vector3 = PhysicsServer3D.soft_body_get_point_global_position(rid, free_idx)
	_check("J the unpinned body is still in motion — so \"does not move\" is false",
		free_idx >= 0 and f0.distance_to(f1) > 0.0001,
		"free vertex %d moved %.5f m in 30 frames with no frame change" % [free_idx, f0.distance_to(f1)])

	# --- E: no rig at all ---
	straps.apply_grid_config({"suspension": "none"})
	await _settle(20)
	var bare: Node = null
	for c in straps.get_children():
		if c is StaticBody3D:
			bare = c
	var bare_parts: int = bare.get_child_count() if bare != null else 0
	_check("E \"none\" leaves no frame to hang from", bare_parts == 0,
		"%d frame parts" % bare_parts)
	var pos_bare: Array = _pinned_positions(first)
	var drift: float = 0.0
	if pos_bare.size() == pos_before.size():
		for i in pos_before.size():
			drift = maxf(drift, (pos_before[i] as Vector3).distance_to(pos_bare[i]))
	_check("E and the cloth still hangs from nothing, unmoved",
		pos_bare.size() == pos_before.size() and drift < 0.001,
		"largest movement %.6f m" % drift)

	# --- F: every value the control offers is accepted ---
	var accepted: int = 0
	for rig: String in RIGS:
		straps.apply_grid_config({"suspension": rig})
		await _settle(4)
		if str(straps.suspension) == rig:
			accepted += 1
	_check("F all five SUPPORT values are accepted", accepted == RIGS.size(),
		"%d of %d" % [accepted, RIGS.size()])

	# --- G: the desk's pin arithmetic, on the real function ---
	var desk: Node = load(DESK).new()
	desk.model = straps
	desk._cloth_pins(0)
	await _settle(2)
	var n0: int = _pinned(first).size()
	desk._cloth_pins(1)
	await _settle(2)
	var n1: int = _pinned(first).size()
	desk._cloth_pins(2)
	await _settle(2)
	var n2: int = _pinned(first).size()
	_check("G mode 0 pins the top row", n0 == pins_before.size(), "%d pinned" % n0)
	_check("G mode 1 pins exactly the two upper corners", n1 == 2, "%d pinned" % n1)
	_check("G mode 2 pins nothing", n2 == 0, "%d pinned" % n2)

	# The claim under test: that after RELEASE only REBUILD restores the full edge.
	# PINS is (pin_mode+1)%2, so from 2 the first press gives 1 and the second gives 0.
	desk.pin_mode = 2
	desk._cloth_pins((desk.pin_mode + 1) % 2)
	await _settle(2)
	var press1: int = _pinned(first).size()
	desk._cloth_pins((desk.pin_mode + 1) % 2)
	await _settle(2)
	var press2: int = _pinned(first).size()
	_check("G two presses of PINS restore the full edge without REBUILD",
		press1 == 2 and press2 == pins_before.size(),
		"after release: %d then %d pinned" % [press1, press2])

	# --- H: the branch I added, reached through act() exactly as the button reaches it ---
	var stop: Node3D = load(STOP).instantiate()
	root.add_child(stop)
	await _settle(4)
	desk.chapter = "cloth"
	desk.other = stop
	desk.ready_for_input = true
	straps.apply_grid_config({"suspension": "gantry"})
	await _settle(4)
	desk.control_indices = {}
	desk.act("SUPPORT")
	await _settle(6)
	_check("H act(\"SUPPORT\") reaches the artifact", str(straps.suspension) == "none",
		"first press gave %s" % str(straps.suspension))
	desk.act("SUPPORT")
	await _settle(6)
	_check("H a second press advances the cycle", str(straps.suspension) == "hoop",
		"second press gave %s" % str(straps.suspension))

	# --- I: the desk. This builds the real console geometry and fires the real signal.
	#        It proves BUTTON -> act -> artifact. It does NOT prove a hand can reach the
	#        button: emitting a signal is not input. That needs a museum-lane walk. ---
	var stage: Node3D = Node3D.new()
	root.add_child(stage)
	var deck: Node = load(DESK).new()
	deck.set_meta("config_chapter", "cloth")
	stage.add_child(deck)
	await _settle(4)
	deck.model = straps
	deck.other = stop
	deck._build_compact_console(CLOTH_IDS, "WHICH POINTS MUST STAY?")
	await _settle(4)
	_check("I the desk builds all seven controls", deck.buttons.size() == 7,
		"%d buttons: %s" % [deck.buttons.size(), ", ".join(deck.buttons.keys())])
	var has_support: bool = deck.buttons.has("SUPPORT")
	_check("I SUPPORT is one of them", has_support)
	if has_support:
		var b: Node = deck.buttons["SUPPORT"]
		_check("I its pressed signal is connected", b.pressed.get_connections().size() > 0,
			"%d connection(s)" % b.pressed.get_connections().size())
		straps.apply_grid_config({"suspension": "gantry"})
		await _settle(4)
		deck.ready_for_input = true
		deck.control_indices = {}
		b.pressed.emit()
		await _settle(6)
		_check("I firing that button changes the support", str(straps.suspension) == "none",
			"suspension is now %s" % str(straps.suspension))

	stop.queue_free()
	stage.queue_free()
	desk.free()
	straps.queue_free()
	await _settle(2)
	_finished = true
