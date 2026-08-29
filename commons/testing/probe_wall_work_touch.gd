extends SceneTree
## WALL WORKS YOU CAN CUT AND CARRY (2026-08-29, Palle: "in VR the laser does not
## destroy the wall art and the wall art is not grabable").
##
## Both complaints are one fact, and this probe states it first rather than
## assuming it: a showing is instances of a MultiMesh with NO COLLIDER, so a
## physics ray passes through it and a hand closes on nothing. The fix does not
## break that contract — it gives the beam and the hand their own reach — so the
## first thing measured here is that the wall is STILL uncollidable.
##
## Then the two behaviours, each with its negative:
##   a beam through a work takes it out — and a beam two metres wide of it does
##   NOT, which is the whole reason it measures perpendicular distance to the
##   ray instead of opening a cone from the emitter
##   a hand within reach turns one work into a real pickable — and a hand across
##   the room turns nothing into anything
##
##   godot --headless --path . --xr-mode off --log-file <log> \
##       --script res://commons/testing/probe_wall_work_touch.gd
const OUT := "res://ada_run/wall_work_touch.txt"

var _l: Array = []
var fails: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)
func _fail(s: String) -> void: fails.append(s)


## Is this showing still hanging? Read the stash, never the buffer — instance
## transforms come back as identity under the dummy renderer.
func _still_hung(inst: Node3D, seg: Node3D, si: int) -> bool:
	var f: Dictionary = inst.call("_showing_field", seg, si)
	return not f.is_empty()


## THE PROBE MUST PROVE ITS OWN PREMISE. Both negatives failed on the first run
## and neither was a fault in the museum: a hall carries 38 works on BOTH side
## walls, so a beam "two metres wide" of one picture ran straight through
## another, and a hand "across the room" was standing at a third. A negative
## that has not measured its own clearance is not evidence of anything.
func _nearest_off_line(seg: Node3D, from: Vector3, dir: Vector3, reach: float) -> float:
	var best: float = 1.0e9
	for n in _showings_of(seg):
		var to: Vector3 = (n as Node3D).global_position - from
		var along: float = to.dot(dir)
		if along < 0.0 or along > reach:
			continue
		best = minf(best, (to - dir * along).length())
	return best


func _nearest_to(seg: Node3D, at: Vector3) -> float:
	var best: float = 1.0e9
	for n in _showings_of(seg):
		best = minf(best, (n as Node3D).global_position.distance_to(at))
	return best


func _showings_of(seg: Node3D) -> Array:
	var out: Array = []
	for n in seg.get_children():
		if n is Node3D and n.has_meta("em_showing") and not n.has_meta("em_hand_removed"):
			out.append(n)
	return out


func _run() -> void:
	# trial control files, never the ones a live session reads
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_ww_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_ww_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_ww_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_ww_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(4.5).timeout

	var segs: Array = inst.get("_segments")
	var seg: Node3D = null
	var works: Array = []
	for sv in segs:
		var s0: Node3D = (sv as Dictionary).get("node")
		if s0 == null or not is_instance_valid(s0):
			continue
		var w0: Array = _showings_of(s0)
		if w0.size() >= 3:
			seg = s0
			works = w0
			break
	if seg == null:
		_say("FAIL no hall with three wall works to test against")
		_finish()
		return
	_say("A HALL WITH %d WALL WORK(S) STILL HANGING" % works.size())

	# ── the diagnosis, stated rather than assumed ────────────────────────
	var target: Node3D = works[0]
	var si: int = int(target.get_meta("em_showing"))
	var at: Vector3 = target.global_position
	_say("")
	_say("IS THERE ANYTHING FOR A RAY TO HIT?")
	var space := (inst as Node3D).get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 0, -0.9), at + Vector3(0, 0, 0.9))
	q.collide_with_areas = true
	var r: Dictionary = space.intersect_ray(q)
	var hit_name: String = String((r.get("collider") as Node).name) if r.has("collider") else "nothing"
	_say("  a ray straight through wall work %d hits: %s" % [si, hit_name])
	_say("  (the wall behind it is a body; the picture itself is not — that is the whole bug)")

	# ── the beam takes out what it crosses ───────────────────────────────
	_say("")
	_say("A BEAM THROUGH IT")
	# read the field while it is still hanging — after the cut it is unreadable,
	# which is the whole reason the burst has to be built before the hide
	var mat0: Material = (inst.call("_showing_field", seg, si) as Dictionary).get("mat")
	_say("  the picture's material before the cut: %s" % ("none" if mat0 == null else mat0.get_class()))
	var from: Vector3 = at + Vector3(0, 0, 2.5)
	inst.call("on_beam_swept", from, (at - from).normalized(), 6.0)
	await create_timer(0.1).timeout
	var gone: bool = not _still_hung(inst, seg, si)
	# _showing_field returns {} once the field is scaled to zero, so if the burst
	# were read AFTER the hide it would size its shards off nothing at all
	_say("  the field is unreadable once it is taken out: %s" % str(gone))
	_say("  wall work %d still hanging: %s" % [si, str(not gone)])
	if not gone:
		_fail("a beam straight through wall work %d left it hanging" % si)
	if not target.has_meta("em_hand_removed"):
		_fail("the work was hidden but never marked taken out — the cull will not agree with the beam")

	# ── and what the hit LOOKED like ─────────────────────────────────────
	_say("")
	_say("SMOKE, A BANG, AND SHARDS")
	var sparks := 0
	var smokes := 0
	var lights := 0
	for n in seg.get_children():
		if n is GPUParticles3D:
			if String(n.name).begins_with("BeamSpark"): sparks += 1
			elif String(n.name).begins_with("BeamSmoke"): smokes += 1
		elif n is OmniLight3D and String(n.name).begins_with("BeamFlash"):
			lights += 1
	var shards: Array = inst.get("_debris")
	_say("  flash %d, explosion %d, smoke plume %d, shards %d" % [lights, sparks, smokes, shards.size()])
	if sparks < 1: _fail("the hit made no explosion")
	if smokes < 1: _fail("the hit made no smoke")
	if lights < 1: _fail("the hit made no flash")
	if shards.size() < 1:
		_fail("the hit threw no debris")
	else:
		var sh: Node3D = shards[0]
		var sh_layer: int = int((sh as CollisionObject3D).collision_layer)
		var sh_mask: int = int((sh as CollisionObject3D).collision_mask)
		# BY CLASS, NEVER BY NAME. A node added with no name of its own gets an
		# auto one — the shard's mesh is "@MeshInstance3D@2409" — so
		# get_node_or_null("MeshInstance3D") returns null and the probe reports a
		# blank shard for a shard that is painted correctly. That reading cost a
		# boot and a wrong diagnosis before the child list was printed.
		var kids: PackedStringArray = []
		for k in sh.get_children():
			kids.append("%s(%s)" % [k.name, k.get_class()])
		_say("  the shard contains: %s" % ", ".join(kids))
		var sh_mi: MeshInstance3D = null
		for k in sh.get_children():
			if k is MeshInstance3D:
				sh_mi = k as MeshInstance3D
		var sh_mat: Material = null
		if sh_mi != null:
			sh_mat = sh_mi.material_override
			if sh_mat == null:
				sh_mat = sh_mi.get_active_material(0)
			_say("  its mesh is %s, override %s, active %s"
				% [str(sh_mi.mesh != null), str(sh_mi.material_override != null),
					str(sh_mi.get_active_material(0) != null)])
		var near: float = sh.global_position.distance_to(at)
		_say("  a shard is a %s on layer %d masking %d, %.2f m from the cut"
			% [sh.get_class(), sh_layer, sh_mask, near])
		_say("  it carries the picture's OWN material (not merely some material): %s"
			% str(sh_mat != null and sh_mat == mat0))
		if not (sh is RigidBody3D):
			_fail("the debris is a %s, so it will never fall or tumble" % sh.get_class())
		if sh_mat == null:
			_fail("the shards carry no material — the work broke into blank boxes")
		elif mat0 != null and sh_mat != mat0:
			_fail("the shards carry a different material than the picture did")
		# THE WALKER MUST BE ABLE TO WALK THROUGH IT. Debris that a body collides
		# with can wedge a visitor into a corner, and the autopilot would unlearn
		# a floor cell because a shard happened to land on it.
		if sh_mask != 1:
			_fail("debris masks %d — it should collide with the world and nothing else" % sh_mask)
		if sh_layer == 1:
			_fail("debris sits on the world layer, so the walker will bump into it")
		if near > 3.0:
			_fail("a shard spawned %.2f m from the cut" % near)

	# ── and the negative: a beam that misses must miss ───────────────────
	_say("")
	_say("A BEAM THAT CROSSES NOTHING")
	var before: int = _showings_of(seg).size()
	# ABOVE the pictures, not merely to one side of one of them: the works line
	# both walls, so sideways clearance from one is standing in front of another.
	var far: Vector3 = at + Vector3(0.0, 5.0, 4.0)
	var far_dir := Vector3(0, 0, -1)
	var clear: float = _nearest_off_line(seg, far, far_dir, 8.0)
	_say("  the test beam passes %.2f m from the nearest work (it cuts within %.2f m)"
		% [clear, float(inst.get("BEAM_CUT_R"))])
	if clear <= float(inst.get("BEAM_CUT_R")):
		_fail("the probe's own miss-beam is not a miss (%.2f m) — it proves nothing" % clear)
	inst.call("on_beam_swept", far, far_dir, 8.0)
	await create_timer(0.1).timeout
	var after: int = _showings_of(seg).size()
	_say("  wall works hanging before %d, after %d" % [before, after])
	if after != before:
		_fail("a beam that misses took %d work(s) out anyway — it is opening a cone, not following a line"
			% (before - after))

	# ── a hand within reach gets something to hold ───────────────────────
	_say("")
	_say("A HAND THAT REACHES")
	var live: Array = _showings_of(seg)
	if live.is_empty():
		_fail("nothing left hanging to reach for")
		_finish()
		return
	var want: Node3D = live[0]
	var want_si: int = int(want.get_meta("em_showing"))
	# the real path: _vr on, a controller in the group, within arm's reach
	inst.set("_vr", true)
	var hand := Node3D.new()
	hand.name = "FakeHand"
	hand.add_to_group("xr_controllers")
	get_root().add_child(hand)
	hand.global_position = want.global_position + Vector3(0, 0, 0.25)
	inst.set("_hand_reach_t", 0.0)
	inst.call("_showing_hand_tick", 1.0)
	await create_timer(0.2).timeout

	var bodies: Dictionary = inst.get("_showing_bodies")
	_say("  bodies now standing off the wall: %d" % bodies.size())
	var body: Node3D = null
	for k in bodies.keys():
		if is_instance_valid(bodies[k]):
			body = bodies[k]
	if body == null:
		_fail("a hand 0.25 m from wall work %d got nothing to hold" % want_si)
	else:
		var is_rb: bool = body is RigidBody3D
		var layer: int = int((body as CollisionObject3D).collision_layer) if body is CollisionObject3D else 0
		var grabbable: bool = body.has_signal("picked_up")
		var cs := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var shape_size: Vector3 = (cs.shape as BoxShape3D).size if cs != null and cs.shape is BoxShape3D else Vector3.ZERO
		_say("  it is a %s on collision layer %d, carries picked_up: %s"
			% [body.get_class(), layer, str(grabbable)])
		_say("  its collider is %.2f x %.2f x %.2f m, standing %.3f m from where the picture hung"
			% [shape_size.x, shape_size.y, shape_size.z,
				body.global_position.distance_to(want.global_position)])
		if not is_rb:
			_fail("what the hand gets is a %s, not a body — nothing can pick that up" % body.get_class())
		if not grabbable:
			_fail("the body carries no picked_up signal — it is not an XRToolsPickable")
		if layer == 0:
			_fail("the body is on no collision layer, so no hand will ever find it")
		if shape_size.length() < 0.01:
			_fail("the body has no collider of any size")
		if body.global_position.distance_to(want.global_position) > 0.5:
			_fail("the body stands %.2f m from the picture it replaced"
				% body.global_position.distance_to(want.global_position))
		if _still_hung(inst, seg, want_si):
			_fail("the picture is in your hands AND still on the wall")

	# ── and the negative: a hand across the room takes nothing ───────────
	_say("")
	_say("A HAND NOWHERE NEAR A PICTURE")
	var n_before: int = (inst.get("_showing_bodies") as Dictionary).size()
	# straight up, for the same reason the miss-beam goes up: eight metres along
	# the hall is simply a different picture.
	hand.global_position = want.global_position + Vector3(0, 8.0, 0)
	var away: float = _nearest_to(seg, hand.global_position)
	_say("  the hand is %.2f m from the nearest work (it reaches %.2f m)"
		% [away, float(inst.get("SHOWING_TAKE_M"))])
	if away <= float(inst.get("SHOWING_TAKE_M")):
		_fail("the probe put the far hand %.2f m from a work — that is not far" % away)
	inst.set("_hand_reach_t", 0.0)
	inst.call("_showing_hand_tick", 1.0)
	await create_timer(0.2).timeout
	var n_after: int = (inst.get("_showing_bodies") as Dictionary).size()
	_say("  bodies before %d, after %d" % [n_before, n_after])
	if n_after != n_before:
		_fail("a hand 8 m away pulled %d work(s) off the wall" % (n_after - n_before))

	_finish()


func _finish() -> void:
	_say("")
	for f in fails:
		_say("FAIL %s" % f)
	_say("VERDICT: %s" % ("the beam cuts what it crosses and a hand within reach gets something to hold"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	if fh != null:
		fh.store_string("\n".join(PackedStringArray(_l)) + "\n")
		fh.close()
	quit(0 if fails.is_empty() else 1)
