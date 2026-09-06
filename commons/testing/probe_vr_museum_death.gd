extends SceneTree

## WHERE DOES A HEADSET DEATH PUT YOU? (2026-09-05)
##
## Palle: "when I die in the endless museum in VR I ca[n't] restart that map."
## Asked what restarting should do, he chose: put me back at THIS hall's start,
## always somewhere standable, never the lobby and never the world origin.
##
## probe_museum_death.gd already walks the death end to end — on the DESKTOP. It
## builds no rig, so the branch at endless_museum.gd:6933 has never been measured
## by anything: every claim about a headset death is a claim about code that no
## test has entered. And the two halves differ in the one way that matters, which
## is that VR has no walker, so every fallback written in terms of _player is a
## fallback VR does not have.
##
## So this builds a fake rig — an XROrigin3D with an XRCamera3D under it, which is
## all _vr_eye() looks for — walks the eye deep into the museum, and kills it.
##
## TWO DEATHS, NOT ONE. The first is the ordinary case. The second is fired inside
## SAVE_BURN_S of the first, which is what the museum reads as "the save point I
## just used killed you again" — it strikes that threshold off, and the fallback
## is the interesting half: the one that decides whether you are stood up where
## you fell or carried back to the front door.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_vr_museum_death.gd -- --em-vr --em-segments=3

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const REPORT := "res://ada_run/vr_museum_death_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _cap_r: float = 0.30
var _cap_h: float = 1.80
var _rig: Node3D = null
var _eye: Camera3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_envelope()
	_make_rig()

	var mus: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	root.add_child(mus)
	var waited: int = 0
	while waited < 5400:
		await process_frame
		waited += 1
		var segs: Variant = mus.get("_segments")
		if segs is Array and (segs as Array).size() >= 2:
			break
	for _i in range(30):
		await physics_frame
	var segments: Array = mus.get("_segments") if mus.get("_segments") is Array else []
	_check(bool(mus.get("_vr")),
		"the museum is on its headset path (%d segment(s) built, no walker: %s)" % [
			segments.size(), str(mus.get("_player") == null)],
		"--em-vr did not take: the museum built the desktop walker and this probe is measuring the wrong branch")
	if segments.size() < 2:
		_fails.append("only %d segment(s) after %d frames — nothing to die in" % [segments.size(), waited])
		_finish()
		return

	# ── stand the eye deep in the SECOND hall ────────────────────────────
	# Not the first: the first hall's threshold and the museum's entrance are the
	# same place, so a death there cannot tell "put back where I was" apart from
	# "carried to the front door", which is the whole question.
	var hall: Dictionary = segments[1]
	var stand: Vector3 = _a_cell_in(mus, hall)
	if stand.y < -1.0e8:
		_fails.append("hall 2 (%s) has no walkable cell on record" % str(hall.get("map", "?")))
		_finish()
		return
	_put_eye(stand)
	await physics_frame
	_lines.append("[probe] standing in hall 2 '%s' (z %.1f..%.1f) at %s" % [
		str(hall.get("map", "?")), float(hall.get("z0", 0.0)), float(hall.get("z1", 0.0)), str(stand)])

	# ── 1. an ordinary death ─────────────────────────────────────────────
	mus.call("on_lethal_touch", "fire")
	await physics_frame
	var after1: Vector3 = _eye.global_position
	_report_landing(mus, segments, hall, after1, "the first death")

	# ── 2. and one inside the burn window ────────────────────────────────
	# The museum strikes off a save point that kills you again within
	# SAVE_BURN_S of standing you there. That is the fallback path, and it is the
	# one that used to walk all the way back to the shallowest unburned threshold
	# in the whole museum — from deep in, the lobby.
	await physics_frame
	mus.call("on_lethal_touch", "laser")
	await physics_frame
	var after2: Vector3 = _eye.global_position
	_lines.append("[probe] burned save points after the second death: %s" % str(mus.get("_burned_saves")))
	_report_landing(mus, segments, hall, after2, "the second death, inside the burn window")

	# ── 3. and the bound must GIVE WAY ───────────────────────────────────
	# Standing the visitor back up in the same hall is only safe because it is
	# capped: the burn logic exists to break a death loop, and a rescue that never
	# yields would be that loop with a friendlier print. So keep killing, and the
	# museum must eventually carry them out. An untested cap is not a cap.
	var kept_in: int = 2
	var carried_at: int = -1
	for k in range(3, 8):
		await physics_frame
		mus.call("on_lethal_touch", "fire")
		await physics_frame
		var p: Vector3 = _eye.global_position
		var inside: bool = p.z >= float(hall.get("z0", 0.0)) and p.z < float(hall.get("z1", 0.0))
		if inside:
			kept_in = k
		elif carried_at < 0:
			carried_at = k
			_lines.append("[probe] death %d was carried out of the hall, to z %.1f" % [k, p.z])
			break
	_check(carried_at > 0 and kept_in >= 3,
		"the museum stood the visitor up in the hall %d times and then carried them out on death %d — the cap is real and it is not 1" % [
			kept_in, carried_at],
		"the cap never gave way: %d deaths and still being stood back up in the same hall — that is the death loop the burn logic exists to break" % 7
			if carried_at < 0 else
			"the museum gave way on death %d, before the cap of %d — the hall gets fewer chances than it says" % [carried_at, 3])

	_finish()


## Everything that must be true of a landing, said as four numbers rather than
## one boolean — which of the four is wrong is the whole diagnosis.
func _report_landing(mus: Node3D, segments: Array, died_in: Dictionary, at: Vector3, what: String) -> void:
	var hall_now: Dictionary = _hall_at(segments, at.z)
	var same: bool = not hall_now.is_empty() and int(hall_now.get("index", -1)) == int(died_in.get("index", -2))
	_check(same,
		"%s put the eye at %s — still in '%s', the hall it died in" % [
			what, str(at.snapped(Vector3(0.1, 0.1, 0.1))), str(died_in.get("map", "?"))],
		"%s put the eye at %s — that is %s, and it died in '%s' at z %.1f..%.1f" % [
			what, str(at.snapped(Vector3(0.1, 0.1, 0.1))),
			("hall '%s'" % str(hall_now.get("map", "?"))) if not hall_now.is_empty() else "outside every built hall",
			str(died_in.get("map", "?")), float(died_in.get("z0", 0.0)), float(died_in.get("z1", 0.0))])

	# ...and not the two places the visitor must never wake up in
	var lobby := Vector3(7.5, 0.0, 1.5)
	_check(Vector2(at.x, at.z).distance_to(Vector2(lobby.x, lobby.z)) > 3.0
			and Vector2(at.x, at.z).length() > 3.0,
		"  not the lobby and not the world origin",
		"  it landed on %s" % ("the lobby standing spot (7.5, 1.5)"
			if Vector2(at.x, at.z).distance_to(Vector2(lobby.x, lobby.z)) <= 3.0 else "the world origin"))

	# floor under the feet, from the physics server rather than from the record
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var down := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, at.y + 0.5, at.z), Vector3(at.x, at.y - 4.0, at.z))
	var hit: Dictionary = space.intersect_ray(down)
	# AND THE HEIGHT IS THE TEST, not merely that something is down there. The
	# first version reported "floor 0.90 m under the eye" beside a passing capsule
	# and read as fine: 0.90 against the 1.65 a standing eye sits at means the
	# visitor was three quarters of a metre INSIDE the deck. The capsule missed it
	# because the capsule was placed on the floor the ray found rather than where
	# the rig actually is — a check standing somewhere the subject is not.
	var drop: float = at.y - float(hit.get("position", Vector3.ZERO).y) if not hit.is_empty() else -1.0
	_check(not hit.is_empty() and absf(drop - 1.65) < 0.45,
		"  the eye stands %.2f m over the floor" % drop,
		"  nothing under the eye within 4 m — it is standing in the air" if hit.is_empty()
			else "  the eye is %.2f m over the floor, not the ~1.65 of a standing visitor — it is %s the deck" % [
				drop, "sunk into" if drop < 1.65 else "floating over"])

	# and the body fits, AT THE EYE'S OWN COLUMN. margin 0.0: the default 0.04
	# reports a body RESTING on a floor as intersecting it, and has called every
	# honest standing spot in this project stuck.
	var feet: float = at.y - 1.65
	var cap := CapsuleShape3D.new()
	cap.radius = _cap_r
	cap.height = _cap_h
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), Vector3(at.x, feet + _cap_h * 0.5 + 0.06, at.z))
	q.margin = 0.0
	var hits: Array = space.intersect_shape(q, 4)
	var names := PackedStringArray()
	for h in hits:
		names.append(str(h.get("collider", "?")))
	_check(hits.is_empty(),
		"  the player's own capsule (r %.2f, h %.2f) stands clear" % [_cap_r, _cap_h],
		"  the capsule is inside %d thing(s): %s" % [hits.size(), String(", ").join(names)])


func _hall_at(segments: Array, z: float) -> Dictionary:
	for s_v in segments:
		var s: Dictionary = s_v
		if z >= float(s.get("z0", 0.0)) and z < float(s.get("z1", 0.0)):
			return s
	return {}


## A cell the museum itself says can be stood on, inside this hall. _walk_cells
## has hazard cells erased from it as they are built, so a cell from it is floor
## and is not the thing that would kill you the moment you arrived.
func _a_cell_in(mus: Node3D, hall: Dictionary) -> Vector3:
	var wc: Variant = mus.get("_walk_cells")
	if not (wc is Dictionary):
		return Vector3(0, -1.0e9, 0)
	var z0: float = float(hall.get("z0", 0.0))
	var z1: float = float(hall.get("z1", 0.0))
	var mid: float = (z0 + z1) * 0.5
	var best := Vector3(0, -1.0e9, 0)
	var best_d: float = 1.0e9
	for k in (wc as Dictionary):
		var c: Vector2i = k
		if float(c.y) < z0 + 5.0 or float(c.y) >= z1:
			continue                      # past the vestibule, inside the hall
		var d: float = absf(float(c.y) - mid)
		if d < best_d:
			best_d = d
			best = Vector3(float(c.x) + 0.5, 0.0, float(c.y) + 0.5)
	return best


func _make_rig() -> void:
	_rig = XROrigin3D.new()
	_rig.name = "ProbeRig"
	_rig.set("current", true)
	var cam := XRCamera3D.new()
	cam.name = "ProbeEye"
	# OFF ITS OWN ORIGIN BY 1.4 m, deliberately. A room-scale visitor stands away
	# from the rig's centre, and _vr_drop exists entirely because of that; a probe
	# whose eye sits on its origin cannot tell a correct drop from a lazy one.
	cam.position = Vector3(0.9, 1.65, -1.1)
	_rig.add_child(cam)
	root.add_child(_rig)
	_eye = cam
	_lines.append("[probe] fake rig in the tree: eye %.2f m off its own origin" % [
		Vector2(cam.position.x, cam.position.z).length()])


func _put_eye(at: Vector3) -> void:
	var off := Vector3(_eye.position.x, 0.0, _eye.position.z)
	_rig.global_position = Vector3(at.x - off.x, at.y, at.z - off.z)


func _read_envelope() -> void:
	if not ResourceLoader.exists(PLAYER):
		return
	var p: Node = (load(PLAYER) as PackedScene).instantiate()
	for cs in _shapes(p):
		if cs.shape is CapsuleShape3D:
			_cap_r = (cs.shape as CapsuleShape3D).radius
			_cap_h = (cs.shape as CapsuleShape3D).height
			break
	p.free()


func _shapes(n: Node) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	if n is CollisionShape3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_shapes(c))
	return out


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
