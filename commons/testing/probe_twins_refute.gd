extends SceneTree
## probe_twins_refute.gd — an ADVERSARIAL second opinion on composition_twins.
##
## The first probe measured the link with the artifact sitting at the world
## origin, and drove every lead by writing its LOCAL position. That is the one
## configuration in which a global/local confusion cannot show. A map token
## places this thing at a cell, with a rotation, and both hands write GLOBAL
## coordinates. So every measurement here is taken in WORLD space, under a
## parent that is rotated AND translated, and the leads are driven exactly the
## way the two hands drive them.
##
## It also tests the states the first probe declared safe by construction:
## the clamp turned OFF, no basin at all, a free with a hand still holding, and
## the grid's own grounding arithmetic against the registry's opt-out.
##
## Run (headless, ONE Godot at a time):
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_twins_refute.gd

const SCENE := "res://commons/artifacts/composition_twins/composition_twins.tscn"
const REG := "res://commons/artifacts/registry/composition_twins.json"
const OUT := "res://ada_run/twins_refute_probe.txt"
const SETTLE := 0.45

var _lines: Array[String] = []
var _fails: Array[String] = []
var _packed: PackedScene = null


func _initialize() -> void:
	# Written before anything else so a run that dies mid-way is still readable:
	# the non-console Godot exe prints nothing, so the file IS the instrument.
	_lines.append("boot: script parsed and _initialize reached")
	_flush("running")
	call_deferred("_run")


func _say(s: String) -> void:
	_lines.append(s)
	_flush("running")


func _fail(s: String) -> void:
	_fails.append(s)
	_flush("running")


func _settle() -> void:
	await create_timer(0.12).timeout
	await physics_frame
	await process_frame
	await process_frame


func _run() -> void:
	if not ResourceLoader.exists(SCENE):
		_fail("no scene at " + SCENE)
		_report()
		return
	_packed = load(SCENE)

	await _test_negative_control()
	await _test_transplanted_hall()
	await _test_per_axis()
	await _test_release_and_idle()
	await _test_clamp_off()
	await _test_no_basin()
	_test_grounding_arithmetic()
	await _test_twin_has_no_body()
	await _test_free_and_rebuild()

	_report()


# ─────────────────────────────────────────────────────────────────────────────
# 0. CAN THIS PROBE SEE A TWIN THAT DOES NOT FOLLOW? Every number below is a
#    ratio between two reads, and a ratio can come out right for the wrong
#    reason — an aliased reference, a constant, a value read from the artifact's
#    own arithmetic instead of from the scene. So: cut the follow loop
#    (set_process(false) on the artifact — the loop and nothing else), move the
#    lead, and require the twin to STAY. A probe that reports x10 here is
#    measuring itself, and nothing it says afterwards is worth anything.
# ─────────────────────────────────────────────────────────────────────────────
func _test_negative_control() -> void:
	var art: Node3D = await _fresh({
		"basin_depth": 4.0, "object_count": 3, "pool_m": 7.0}, "NegControl")
	var lead: Node3D = art.call("lead_node", 0) as Node3D
	var twin: Node3D = art.call("twin_node", 0) as Node3D

	art.set_process(false)
	var tb: Vector3 = twin.position
	lead.position = lead.position + Vector3(0.05, 0.02, -0.03)
	await _settle()
	var moved_while_cut: float = (twin.position - tb).length()
	var err_while_cut: float = _map_err(art, 0)
	_say("NEGATIVE CONTROL, follow loop cut: lead moved 0.0616 m, twin moved %.6f m, mapping error %.4f m (expected: twin still, error ~0.616)" % [
		moved_while_cut, err_while_cut])
	if moved_while_cut > 0.001 or err_while_cut < 0.1:
		_fail("the negative control did not bite — the probe reports a following twin with the follow loop switched OFF, so every other number here is measuring the probe, not the artifact")

	art.set_process(true)
	await _settle()
	var recovered: float = _map_err(art, 0)
	_say("        loop restored: mapping error back to %.6f m, twin moved %.4f m to catch up" % [
		recovered, (twin.position - tb).length()])
	if recovered > 0.002:
		_fail("the twin never caught up after the loop was restored: %.4f m" % recovered)
	art.get_parent().queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 1. THE HALL IS NOT AT THE ORIGIN. A map token puts this at a cell with a
#    rotation; the museum stamps it under a hall node that is itself moved.
#    Both hands write GLOBAL coordinates. Everything below is measured in world
#    space so a local/global confusion has somewhere to show.
# ─────────────────────────────────────────────────────────────────────────────
func _test_transplanted_hall() -> void:
	var hall := Node3D.new()
	hall.name = "HallMoved"
	# A hall rotated off the axis and moved far from the origin. 37 degrees
	# rather than 90 on purpose: 90 hides an axis swap, 37 does not.
	hall.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(37.0)), Vector3(12.0, 0.0, -7.0))
	get_root().add_child(hall)

	var art: Node3D = _packed.instantiate() as Node3D
	art.call("apply_grid_config", {
		"basin_depth": 4.0, "object_count": 3, "twin_scale": 10.0,
		"offset_scale": 10.0, "pool_m": 7.0, "body_m": 0.16,
		"primitives": "cube,sphere,tetra", "tether": "line"})
	# The token's own rotation, on top of the hall's.
	art.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(0.0, 0.0, 0.0))
	hall.add_child(art)
	await create_timer(SETTLE).timeout

	var n: int = int(art.call("lead_count"))
	if n != 3:
		_fail("transplanted hall: %d pairs, wanted 3" % n)
		return

	# The pool floor in WORLD y. The hall is not lifted, so it is still -4.
	var base_w: float = _twin_base_world_y(art, 0)
	_say("hall at (12,0,-7) yaw 37 + token yaw 90: twin 0 base world y = %.4f (pool floor -4.0000)" % base_w)
	if absf(base_w + 4.0) > 0.01:
		_fail("transplanted: twin base world y %.4f, not on the -4.0 pool floor" % base_w)

	# ── the desktop hand: global_position only ───────────────────────────────
	var lead0: Node3D = art.call("lead_node", 0) as Node3D
	var twin0: Node3D = art.call("twin_node", 0) as Node3D
	var l0: Vector3 = lead0.global_position
	var t0: Vector3 = twin0.global_position
	# A shove expressed in WORLD axes — which is what the pointer's
	# camera-forward lerp produces, and it is not aligned with the artifact.
	lead0.global_position = l0 + Vector3(0.06, 0.010, 0.05)
	await _settle()
	var dl: Vector3 = lead0.global_position - l0
	var dt: Vector3 = twin0.global_position - t0
	if dl.length() < 0.001:
		_fail("transplanted: the lead did not move at all under a global write")
	else:
		var ratio: float = dt.length() / dl.length()
		var ang: float = rad_to_deg(dl.normalized().angle_to(dt.normalized())) if dt.length() > 0.0001 else 999.0
		_say("WORLD-space shove: lead moved %s (%.4f m), twin moved %s (%.4f m) = x%.4f, direction error %.4f deg" % [
			_v(dl), dl.length(), _v(dt), dt.length(), ratio, ang])
		if absf(ratio - 10.0) > 0.05:
			_fail("transplanted: world-space factor is %.4f, not 10" % ratio)
		if ang > 0.05:
			_fail("transplanted: the twin travelled %.3f deg off the lead's own direction — the offset is being scaled in the wrong frame" % ang)

	# ── the VR hand: the whole global_transform, rotation included ────────────
	var lead1: Node3D = art.call("lead_node", 1) as Node3D
	var twin1: Node3D = art.call("twin_node", 1) as Node3D
	var l1: Vector3 = lead1.global_position
	var t1: Vector3 = twin1.global_position
	# A rotation about an axis that is neither world-up nor artifact-up.
	var spin := Basis(Vector3(0.3, 0.8, 0.52).normalized(), deg_to_rad(41.0))
	lead1.global_transform = Transform3D(spin * lead1.global_transform.basis,
		l1 + Vector3(-0.04, 0.014, 0.03))
	await _settle()
	var dl1: Vector3 = lead1.global_position - l1
	var dt1: Vector3 = twin1.global_position - t1
	var lb: Basis = lead1.global_transform.basis.orthonormalized()
	var tb: Basis = twin1.global_transform.basis.orthonormalized()
	var qerr: float = rad_to_deg(lb.get_rotation_quaternion().angle_to(tb.get_rotation_quaternion()))
	var r1: float = dt1.length() / maxf(dl1.length(), 0.00001)
	_say("WORLD-space grab (41 deg about a tilted axis): factor x%.4f, world rotation error %.5f deg" % [r1, qerr])
	if absf(r1 - 10.0) > 0.05:
		_fail("transplanted VR write: factor %.4f, not 10" % r1)
	if qerr > 0.05:
		_fail("transplanted: the twin's WORLD rotation is %.4f deg off the lead's" % qerr)

	# Twin scale must still be exactly 10 after all that.
	var sc: Vector3 = twin1.global_transform.basis.get_scale()
	_say("twin 1 world scale after the tilted grab: (%.5f, %.5f, %.5f)" % [sc.x, sc.y, sc.z])
	if absf(sc.x - 10.0) > 0.01 or absf(sc.y - 10.0) > 0.01 or absf(sc.z - 10.0) > 0.01:
		_fail("twin scale sheared under a tilted rotation: %s" % _v(sc))

	hall.queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 2. THE FACTOR, ONE AXIS AT A TIME. "x10" as a single ratio can hide 9.5 in y
#    against 10.5 in x. Three isolated moves, three separate numbers.
# ─────────────────────────────────────────────────────────────────────────────
func _test_per_axis() -> void:
	var art: Node3D = await _fresh({
		"basin_depth": 4.0, "object_count": 3, "pool_m": 7.0, "body_m": 0.16,
		"primitives": "cube,sphere,tetra"}, "PerAxis")
	var axes: Array = [
		[Vector3(0.05, 0.0, 0.0), "x"],
		[Vector3(0.0, 0.05, 0.0), "y"],
		[Vector3(0.0, 0.0, 0.05), "z"]]
	var ratios: Array[float] = []
	for a in axes:
		var d: Vector3 = a[0]
		var lead: Node3D = art.call("lead_node", 0) as Node3D
		var twin: Node3D = art.call("twin_node", 0) as Node3D
		var lb: Vector3 = lead.position
		var tb: Vector3 = twin.position
		lead.position = lb + d
		await _settle()
		var ml: Vector3 = lead.position - lb
		var mt: Vector3 = twin.position - tb
		var r: float = 0.0
		if ml.length() > 0.0001:
			r = mt.length() / ml.length()
		ratios.append(r)
		_say("axis %s: lead %s -> twin %s = x%.5f (cross-talk %.6f m)" % [
			str(a[1]), _v(ml), _v(mt),
			r, (mt - ml * 10.0).length()])
		# put it back
		lead.position = lb
		await _settle()
	var spread: float = 0.0
	for r in ratios:
		spread = maxf(spread, absf(r - 10.0))
	_say("worst per-axis deviation from 10: %.6f" % spread)
	if spread > 0.02:
		_fail("the factor is not 10 in every axis: %s" % str(ratios))
	art.get_parent().queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 3. AFTER THE RELEASE, AND THEN LEFT ALONE. The claim is that the pair holds
#    with nothing touching it. So: grab the desktop way, carry, drop the
#    desktop way, then run a long idle and see whether either body drifts.
#    Then hit it with a velocity, which is what a VR throw leaves behind.
# ─────────────────────────────────────────────────────────────────────────────
func _test_release_and_idle() -> void:
	var art: Node3D = await _fresh({
		"basin_depth": 4.0, "object_count": 3, "pool_m": 7.0}, "Release")
	var rb: RigidBody3D = art.call("lead_node", 0) as RigidBody3D
	var twin: Node3D = art.call("twin_node", 0) as Node3D

	# _grab_held, verbatim
	var keep_freeze: bool = rb.freeze
	var keep_layer: int = rb.collision_layer
	var keep_mask: int = rb.collision_mask
	rb.freeze = true
	rb.collision_layer = 0
	rb.collision_mask = 0
	for _f in range(8):
		rb.global_position = rb.global_position + Vector3(0.01, 0.002, -0.008)
		await physics_frame
		await process_frame
	await _settle()

	# _drop_held, verbatim
	rb.freeze = keep_freeze
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	rb.collision_layer = keep_layer
	rb.collision_mask = keep_mask
	await _settle()
	var lead_at_release: Vector3 = rb.position
	var twin_at_release: Vector3 = twin.position
	var map_release: float = _map_err(art, 0)

	# LEFT ALONE. 60 physics frames with nobody touching anything.
	for _f in range(60):
		await physics_frame
	await _settle()
	var lead_drift: float = (rb.position - lead_at_release).length()
	var twin_drift: float = (twin.position - twin_at_release).length()
	var map_after: float = _map_err(art, 0)
	_say("release then 60 idle physics frames: lead drift %.6f m, twin drift %.6f m, mapping error %.6f -> %.6f m (freeze=%s)" % [
		lead_drift, twin_drift, map_release, map_after, str(rb.freeze)])
	if map_after > 0.02:
		_fail("after release + idle the twin is %.4f m off its mapping" % map_after)
	if lead_drift > 0.002 and twin_drift < lead_drift * 9.0:
		_fail("the lead drifted %.4f m while idle and the twin only followed %.4f m" % [lead_drift, twin_drift])

	# A VR throw leaves a velocity on the body. If freeze does not hold, the
	# small object sails off the table AND takes the twin with it.
	rb.linear_velocity = Vector3(2.0, 0.0, 0.0)
	rb.angular_velocity = Vector3(0.0, 3.0, 0.0)
	var before_throw: Vector3 = rb.position
	for _f in range(60):
		await physics_frame
	await _settle()
	var moved: float = (rb.position - before_throw).length()
	_say("a 2 m/s velocity applied after release moved the small body %.6f m in 1 s (release_mode FROZEN should hold it)" % moved)
	_say("mapping error after the throw: %.6f m" % _map_err(art, 0))
	if _map_err(art, 0) > 0.02:
		_fail("after a velocity was applied the twin is %.4f m off its mapping" % _map_err(art, 0))
	art.get_parent().queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 4. THE CLAMP IS A DEFAULT, NOT A GUARANTEE. clamp_reach is an export and a
#    token key, so a map can turn it off. What does the pool look like then?
#    This is the "moved off the table / dropped in the pool" question.
# ─────────────────────────────────────────────────────────────────────────────
func _test_clamp_off() -> void:
	var art: Node3D = await _fresh({
		"basin_depth": 4.0, "object_count": 3, "pool_m": 7.0, "body_m": 0.16,
		"clamp_reach": false}, "ClampOff")
	var lead: Node3D = art.call("lead_node", 0) as Node3D
	var twin: Node3D = art.call("twin_node", 0) as Node3D
	var start: Vector3 = lead.position

	# DROPPED. The desktop pointer restores freeze on release, so a real drop
	# leaves it hovering; this is the harder case — a hand carries it down off
	# the front of the bench, 40 cm below the table top.
	lead.position = start + Vector3(0.0, -0.40, 0.0)
	await _settle()
	var base_y: float = _twin_base_world_y(art, 0)
	_say("clamp OFF, small body carried 0.40 m BELOW the table top: twin base world y = %.3f (pool floor -4.000, so %.2f m through the floor)" % [
		base_y, maxf(-4.0 - base_y, 0.0)])
	_say("        mapping still exact? error %.6f m" % _map_err(art, 0))

	# OFF THE TABLE SIDEWAYS. A 2 m walk with the object in hand.
	lead.position = start + Vector3(2.0, 0.0, 0.0)
	await _settle()
	var twin_x: float = twin.position.x
	var rim: float = 7.0 * 0.5
	_say("clamp OFF, small body walked 2.00 m sideways: twin centre x = %.2f m, pool rim at %.2f m -> %.2f m outside the basin" % [
		twin_x, rim, maxf(absf(twin_x) - rim, 0.0)])
	_say("        mapping still exact? error %.6f m" % _map_err(art, 0))
	if _map_err(art, 0) > 0.02:
		_fail("clamp off: the link itself broke, mapping error %.4f m" % _map_err(art, 0))
	_say("        (the LINK holds in both cases — what is lost is the containment, and the containment is the default `clamp_reach` and nothing else)")

	# And with the clamp ON, the same two shoves.
	art.call("apply_grid_config", {"clamp_reach": true})
	await create_timer(0.35).timeout
	var lead2: Node3D = art.call("lead_node", 0) as Node3D
	lead2.position = Vector3(2.0, 0.0, 2.0)
	await _settle()
	var b2: float = _twin_base_world_y(art, 0)
	var bed: Vector2 = Vector2((art.call("link_report") as Dictionary)["bed"])
	_say("clamp ON, the same 2 m shove: lead lands at %s inside a bed of (%.3f, %.3f), twin base y = %.4f" % [
		_v(lead2.position), bed.x, bed.y, b2])
	if absf(b2 + 4.0) > 0.01:
		_fail("clamp on: the twin base left the pool floor at %.4f" % b2)
	art.get_parent().queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 5. NO BASIN UNDER IT AT ALL — the capture bench, the gallery, and any map
#    that drops the token without editing map_info.
# ─────────────────────────────────────────────────────────────────────────────
func _test_no_basin() -> void:
	var art: Node3D = await _fresh({}, "NoBasin")
	var n: int = int(art.call("lead_count"))
	var rep: Dictionary = art.call("link_report")
	var pa: Vector3 = Vector3(rep["pool_anchor"])
	var base0: float = _twin_base_world_y(art, 0)
	_say("no basin: %d pairs, pool anchor %s, twin 0 base world y = %.4f (floor 0)" % [n, _v(pa), base0])
	if absf(base0) > 0.01:
		_fail("no basin: the twin base is at %.4f, not on the floor" % base0)

	# The twins stand in a row in FRONT of the table. Can a hand drive one back
	# into the table — and into the visitor standing at it?
	var lead: Node3D = art.call("lead_node", 0) as Node3D
	var twin: Node3D = art.call("twin_node", 0) as Node3D
	var bed: Vector2 = Vector2(rep["bed"])
	lead.position = Vector3(lead.position.x, lead.position.y, -bed.y * 2.0)
	await _settle()
	var mi: MeshInstance3D = twin.get_node_or_null("Body") as MeshInstance3D
	var half_z: float = mi.get_aabb().size.z * 0.5 * twin.scale.z
	var near_edge: float = twin.position.z - half_z
	_say("no basin, small body pulled to the near edge of its bed: twin centre z = %.3f, near face z = %.3f (the bench occupies about z -0.50 .. +0.50)" % [
		twin.position.z, near_edge])
	if near_edge < 0.5:
		_say("        NOTE a %.2f m body reaches %.2f m into the bench/visitor volume. It has no collider so nothing is pushed, but standing at the table you are inside it." % [
			mi.get_aabb().size.z * twin.scale.z, 0.5 - near_edge])
	_say("        mapping error %.6f m" % _map_err(art, 0))
	art.get_parent().queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 6. THE GRID'S GROUNDING PASS, reproduced. GridInteractablesComponent
#    (_compute_local_aabb / _auto_ground_artifact) merges MeshInstance3D,
#    MultiMeshInstance3D and CSGShape3D AABBs, takes correction = -min_y, and
#    APPLIES it if |correction| <= 5.0. The registry's auto_ground flag is the
#    only thing standing between the twin and a 4 m lift out of the pool.
# ─────────────────────────────────────────────────────────────────────────────
func _test_grounding_arithmetic() -> void:
	var txt := FileAccess.get_file_as_string(REG)
	var parsed: Variant = JSON.parse_string(txt)
	var declared: Variant = null
	if typeof(parsed) == TYPE_DICTIONARY:
		var arts: Dictionary = parsed.get("artifacts", {})
		var e: Dictionary = arts.get("composition_twins", {})
		declared = e.get("auto_ground", null)
	_say("registry auto_ground = %s (grid default when the key is ABSENT is true)" % str(declared))
	if declared == null:
		_fail("the registry does not declare auto_ground at all — the grid defaults to TRUE and would lift the artifact out of the pool")
	elif bool(declared):
		_fail("the registry declares auto_ground TRUE")


func _grounding_correction(art: Node3D) -> float:
	var ab: AABB = _local_aabb(art)
	if ab.size.length() < 0.01:
		return NAN
	return -ab.position.y


## A faithful copy of GridInteractablesComponent._compute_local_aabb.
func _local_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh: Mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = (child as MeshInstance3D).transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm: MultiMesh = (child as MultiMeshInstance3D).multimesh
			if mm and mm.instance_count > 0:
				child_aabb = (child as MultiMeshInstance3D).transform * mm.get_aabb()
				has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub: AABB = _local_aabb(child as Node3D)
			if sub.size.length() > 0:
				sub = (child as Node3D).transform * sub
				if first:
					result = sub
					first = false
				else:
					result = result.merge(sub)
	return result


# ─────────────────────────────────────────────────────────────────────────────
# 7. A 1.6 m BODY STANDING IN A POOL MUST NOT BE ABLE TO SHOVE ANYONE, and
#    must not be grabbable itself — otherwise the visitor drags the consequence
#    and the control surface means nothing.
# ─────────────────────────────────────────────────────────────────────────────
func _test_twin_has_no_body() -> void:
	var art: Node3D = await _fresh({"basin_depth": 4.0, "object_count": 3, "pool_m": 7.0}, "NoBody")
	var bad: int = 0
	var grabbable: int = 0
	for i in range(int(art.call("lead_count"))):
		var twin: Node3D = art.call("twin_node", i) as Node3D
		bad += twin.find_children("*", "CollisionObject3D", true, false).size()
		if twin.has_method("pick_up"):
			grabbable += 1
	_say("twins: %d CollisionObject3D among them, %d with pick_up()" % [bad, grabbable])
	if bad > 0 or grabbable > 0:
		_fail("a twin carries a physics body — it can shove the walker or be grabbed directly")

	# And the grounding arithmetic, on this exact instance.
	var corr: float = _grounding_correction(art)
	_say("grid grounding it WOULD apply if auto_ground were true: %+.4f m (cap 5.0, so it would be APPLIED, not skipped)" % corr)
	if absf(corr) > 5.0:
		_say("        (above the 5.0 cap, so the grid would skip it and only print)")
	art.get_parent().queue_free()
	await process_frame


# ─────────────────────────────────────────────────────────────────────────────
# 8. FREEING IT. Mid-build, and with a hand still holding a lead. The repo has
#    a documented segfault class for queue_free during procedural generation.
# ─────────────────────────────────────────────────────────────────────────────
func _test_free_and_rebuild() -> void:
	var n_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	# (a) freed 40 ms after entering the tree, i.e. mid-build
	for _k in range(3):
		var host := Node3D.new()
		get_root().add_child(host)
		var a: Node3D = _packed.instantiate() as Node3D
		a.call("apply_grid_config", {"basin_depth": 4.0, "object_count": 6, "pool_m": 14.0,
			"primitives": "cube,sphere,cone,cylinder,wedge,torus"})
		host.add_child(a)
		await create_timer(0.04).timeout
		host.queue_free()
		await process_frame
		await process_frame
	await create_timer(0.4).timeout
	_say("three instances built and freed 40 ms in (mid-build): survived")

	# (b) a rebuild while a hand still holds a lead — the lead is queue_freed
	#     under the holder. Does anything crash, and does the pair recover?
	var host2 := Node3D.new()
	get_root().add_child(host2)
	var art: Node3D = _packed.instantiate() as Node3D
	art.call("apply_grid_config", {"basin_depth": 4.0, "object_count": 3, "pool_m": 7.0})
	host2.add_child(art)
	await create_timer(SETTLE).timeout
	var held: Node3D = art.call("lead_node", 0) as Node3D
	var held_name: String = held.name
	# the pointer's held state
	(held as RigidBody3D).freeze = true
	(held as RigidBody3D).collision_layer = 0
	art.call("apply_grid_config", {"object_count": 5, "pool_m": 12.0, "basin_depth": 4.0})
	await create_timer(0.4).timeout
	var still: bool = is_instance_valid(held)
	var n5: int = int(art.call("lead_count"))
	_say("rebuild while a hand held '%s': the held body is %s, artifact now has %d pairs" % [
		held_name, "STILL VALID" if still else "FREED under the hand", n5])
	if not still:
		_say("        (DesktopInteractionPointer guards this — `elif _held and not is_instance_valid(_held): _held = null` — so the desktop hand recovers. A rebuild only happens on a CHANGED config, which no live map does mid-grab.)")
	# does the new set still follow?
	if n5 > 0:
		var lead: Node3D = art.call("lead_node", 0) as Node3D
		var twin: Node3D = art.call("twin_node", 0) as Node3D
		var lb: Vector3 = lead.position
		var tb: Vector3 = twin.position
		lead.position = lb + Vector3(0.03, 0.006, -0.02)
		await _settle()
		var r: float = (twin.position - tb).length() / maxf((lead.position - lb).length(), 0.00001)
		_say("after that rebuild the new pair still follows at x%.4f, mapping error %.6f m" % [r, _map_err(art, 0)])
		if absf(r - 10.0) > 0.05:
			_fail("after a rebuild-under-a-hand the factor is %.4f" % r)
	host2.queue_free()
	await create_timer(0.4).timeout

	var n_after: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_say("node count %d -> %d after everything was freed; orphan nodes %d" % [n_before, n_after, orphans])
	if n_after > n_before + 8:
		_fail("%d nodes left behind after every instance was freed" % (n_after - n_before))


# ─────────────────────────────────────────────────────────────────────────────

func _fresh(cfg: Dictionary, tag: String) -> Node3D:
	var host := Node3D.new()
	host.name = tag
	get_root().add_child(host)
	var a: Node3D = _packed.instantiate() as Node3D
	if not cfg.is_empty():
		a.call("apply_grid_config", cfg)
	host.add_child(a)
	await create_timer(SETTLE).timeout
	return a


func _map_err(art: Node3D, i: int) -> float:
	var rep: Dictionary = art.call("link_report")
	var lead: Node3D = art.call("lead_node", i) as Node3D
	var twin: Node3D = art.call("twin_node", i) as Node3D
	if lead == null or twin == null:
		return INF
	var want: Vector3 = Vector3(rep["pool_anchor"]) \
		+ (lead.position - Vector3(rep["table_anchor"])) * float(rep["offset_scale"])
	return (twin.position - want).length()


func _twin_base_world_y(art: Node3D, i: int) -> float:
	var twin: Node3D = art.call("twin_node", i) as Node3D
	if twin == null:
		return NAN
	var mi: MeshInstance3D = twin.get_node_or_null("Body") as MeshInstance3D
	if mi == null:
		return NAN
	var ab: AABB = mi.get_aabb()
	var local_base := Vector3(0.0, mi.position.y + ab.position.y, 0.0)
	return (twin.global_transform * local_base).y


func _v(v: Vector3) -> String:
	return "(%.4f, %.4f, %.4f)" % [v.x, v.y, v.z]


func _flush(state: String) -> void:
	var out := "COMPOSITION TWINS — REFUTATION PROBE [%s]\n\n" % state
	for l in _lines:
		out += "  %s\n" % l
	out += "\n"
	if _fails.is_empty():
		out += "  no refutation yet — 0 fail(s)\n"
	else:
		for f in _fails:
			out += "  FAIL %s\n" % f
		out += "\n  %d fail(s)\n" % _fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	if fh != null:
		fh.store_string(out)
		fh.close()


func _report() -> void:
	_flush("COMPLETE")
	quit(1 if not _fails.is_empty() else 0)
