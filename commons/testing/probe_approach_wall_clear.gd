extends SceneTree

## HOW WIDE IS THE HOLE, IN METRES?
##
## 2026-09-08, Palle, having walked it: *"In the approach_wall rotation the
## element has to be bigger for me to pass. I guess at least 0.5 m width"*.
##
## Everything measured about this wall so far has been measured in OPENNESS — a
## unit-less 0..1 that the artifact invented for itself. openness 0.723 sounds
## like a wall that is most of the way open, and it is not a width. What a body
## needs is a gap it fits through, and nothing until now has reported one.
##
## So this asks the physics world the same question the visitor's shoulders ask:
## stand a body at the wall, sweep a shoulder-wide sphere along the wall's plane,
## and report the widest run of positions that touch nothing. In metres.
##
## It sweeps at several approach distances, because the wall's answer is a
## function of how near you are and the useful number is the one you get when you
## have actually walked up to it.
##
## THE CONTROL IS THE CLOSED WALL: with nobody there the widest free run must be
## about zero. A sweep that always finds a gap would report a triumph on a wall
## that had fallen over.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_approach_wall_clear.gd

const WALL := "res://commons/artifacts/approach_wall/approach_wall.tscn"
const REPORT := "res://ada_run/approach_wall_clear_probe.txt"

## Palle's number, and the bar this probe sets.
const WANT_M := 0.50
## Half a pair of shoulders — the radius of the body doing the asking.
const PROBE_R := 0.26
## A needle, for measuring the gap itself. See _clear: a sweep of spheres reports
## the run of free CENTRES, which is the gap less the sphere's diameter — so the
## shoulder answers "does a body fit" and the needle answers "how wide is it".
const NEEDLE_R := 0.02
const CHEST_Y := 1.05
const STEP_M := 0.02
## Where the visitor stands, in metres in front of the wall's face.
const STANDOFF := [1.60, 1.10, 0.80, 0.55]

var _lines: Array[String] = []
var _fails: Array[String] = []
var _wall: Node3D
var _walker: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node3D.new()
	root.name = "Field"
	get_root().add_child(root)

	var ps: PackedScene = load(WALL) as PackedScene
	_wall = ps.instantiate() as Node3D
	root.add_child(_wall)
	_wall.global_position = Vector3.ZERO

	# the museum's Walker, to its own recipe: bare CharacterBody3D, layer 1,
	# group em_walker and nothing else
	_walker = CharacterBody3D.new()
	_walker.name = "Walker"
	_walker.collision_layer = 1
	_walker.collision_mask = 0
	_walker.add_to_group("em_walker")
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.5
	cs.shape = cap
	cs.position = Vector3(0, 0.75, 0)
	_walker.add_child(cs)
	root.add_child(_walker)
	_park()
	await _settle(20)

	# THE BUILT NUMBERS, NOT THE ASKED-FOR ONES. The first version of this line
	# printed `slats` (the export) and width/slats, and reported "slat 0.629 m"
	# for a wall that had clamped itself to five slats of 0.88 — a probe quoting
	# the request back at me while the object measured something else.
	var mode: String = str(_wall.get("open_by"))
	var w: float = float(_wall.get("width_m"))
	var built: Array = _wall.get("_slats") as Array
	_say("mode=%s  width=%.2f m  asked %d slat(s), BUILT %d of %.3f m  core %d  thickness %.2f  aperture=%.2f  reach=%.2f  swing=%.0f deg"
		% [mode, w, int(_wall.get("slats")), built.size(), float(_wall.get("_slat_w")),
			int(_wall.get("_core")), float(_wall.get("thickness_m")),
			float(_wall.get("aperture_m")), float(_wall.get("reach_m")), float(_wall.get("swing_deg"))])

	# THE CONTROL. Nobody there: the wall must be a wall.
	var shut: float = _gap()
	_say("closed, nobody there        gap %.2f m   a body fits: %s" % [shut, str(_fits())])
	_check(not _fits(), "  the wall is shut", "with nobody there a body can already walk through a %.2f m hole" % shut)

	var best := 0.0
	for d in STANDOFF:
		_walker.global_position = Vector3(0.0, 0.0, -float(d))
		await _settle(75)
		var clear: float = _gap()
		best = maxf(best, clear)
		var opens: PackedFloat32Array = _wall.get("_open")
		var each := ""
		for oi in opens.size():
			each += "%.2f " % opens[oi]
		_say("standing %.2f m out        gap %.2f m   a body fits: %-5s  is_passable %-5s  slats [ %s]"
			% [d, clear, str(_fits()), str(bool(_wall.call("is_passable"))), each])

	_park()
	await _settle(60)
	var after: float = _gap()
	_say("walked away                 gap %.2f m   a body fits: %s" % [after, str(_fits())])
	_check(not _fits(), "  it shut again", "a body could still walk through a %.2f m hole after the visitor left" % after)

	_say("")
	_check(best >= WANT_M,
		"WIDEST HOLE THE WALL EVER OFFERED: %.2f m (Palle asked for %.2f)" % [best, WANT_M],
		"the widest hole is %.2f m and Palle asked for %.2f" % [best, WANT_M])
	_finish()


## THE GAP, IN METRES, and it is not the same number as the sweep.
##
## A sphere of radius r sweeping a gap G has free CENTRES over G - 2r, so a sweep
## of shoulder-spheres reports 0.30 m for a 0.82 m hole and 0.00 m for anything a
## body cannot pass — which is a fine pass/fail and a terrible width. The first
## two runs of this probe reported 0.00 m and I read it as "the wall does not
## open"; it meant "not by 0.52 m", and the difference sent me looking for a
## geometry fault that was partly the ruler.
##
## So: sweep a needle to measure the hole, sweep a shoulder to ask whether a body
## fits, and print both.
func _gap() -> float:
	var run: float = _clear(NEEDLE_R)
	return 0.0 if run <= 0.0 else run + 2.0 * NEEDLE_R


func _fits() -> bool:
	return _clear(PROBE_R) > 0.0


func _clear(r: float) -> float:
	var space: PhysicsDirectSpaceState3D = get_root().world_3d.direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = r
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_bodies = true
	q.collide_with_areas = false
	q.collision_mask = 0xFFFFFFFF
	q.exclude = [_walker.get_rid()]
	var half: float = float(_wall.get("width_m")) * 0.5
	var best := 0.0
	var run := 0.0
	var x: float = -half
	while x <= half:
		q.transform = Transform3D(Basis.IDENTITY, Vector3(x, CHEST_Y, 0.0))
		if space.intersect_shape(q, 1).is_empty():
			run += STEP_M
			best = maxf(best, run)
		else:
			run = 0.0
		x += STEP_M
	return best


func _park() -> void:
	_walker.global_position = Vector3(0, 0, -400)


func _settle(n: int) -> void:
	for i in range(n):
		await process_frame
		await physics_frame


func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
