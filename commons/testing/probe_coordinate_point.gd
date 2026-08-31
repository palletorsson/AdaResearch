extends SceneTree
## THE POINT IS INSIDE THE LINES, AND THE NUMBERS ARE THE WORLD'S.
##
## 2026-08-31, Palle: "the CoordinateSystem3M the point is not inside the x,y,z
## lines. can we do like the point is at x:6. z:10 7:1. do not think about
## CoordinateSystem3M as local but the global values from vector.zero" — and
## "also make the point a bit bigger and more bright".
##
## The standard bench cannot see any of this: capture_multi_angle instantiates the
## scene with its shipped exports, and `floating_point` ships false, so every
## portrait of this artifact ever taken is of a frame with no point in it. Three
## changes that all live on the point are therefore invisible to the capture that
## would normally be the evidence. Hence a probe.
##
##   godot --headless --path . --xr-mode off --log-file <log> \
##       --script res://commons/testing/probe_coordinate_point.gd
const SCENE := "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn"
const OUT := "res://ada_run/coordinate_point.txt"

var _l: Array = []
var _fails: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _say(s: String) -> void:
	_l.append(s)
	print(s)

func _check(ok: bool, s: String) -> void:
	_say(("  ok   " if ok else "  FAIL ") + s)
	if not ok:
		_fails.append(s)


func _run() -> void:
	var ps: PackedScene = load(SCENE)
	if ps == null:
		_say("cannot load " + SCENE)
		quit(1)
		return
	var frame: Node3D = ps.instantiate() as Node3D
	frame.set("floating_point", true)
	# stand the frame AWAY from the origin: if the readout were still frame-local
	# this offset would be invisible, which is the whole bug.
	var origin := Vector3(6.0, 0.0, 10.0)
	var holder := Node3D.new()
	root.add_child(holder)
	holder.add_child(frame)
	frame.global_position = origin
	await process_frame
	await process_frame

	_say("CoordinateSystem3M — frame standing at %s" % str(origin))

	var pt: Node3D = frame.get_node_or_null("FloatingPoint") as Node3D
	_check(pt != null, "the floating point exists")
	if pt == null:
		_finish()
		return

	var axis_len: float = float(frame.get("axis_length"))
	var scl: float = float(frame.get("display_scale"))

	# --- 1. bigger and brighter ------------------------------------------------
	var ps_mult: float = float(frame.get("point_scale"))
	var energy: float = float(pt.get("glow_emission_energy"))
	_check(ps_mult > 1.0, "point_scale is above 1 (%.2f) — the point is bigger" % ps_mult)
	_check(is_equal_approx(pt.scale.x, (1.0 / scl) * ps_mult),
		"the point wears it: scale %.3f = 1/%.2f x %.2f" % [pt.scale.x, scl, ps_mult])
	_check(energy > 2.0, "glow_emission_energy reached the point BEFORE _ready (%.2f > 2.0 default)" % energy)

	# --- 2. the fence is OPT-IN, and it is off ---------------------------------
	# It shipped ON for a few hours and was immediately the thing in the way:
	# "now we can not move the point beyond its local z 0, the blue line." A frame
	# that refuses to read past its own arrow is not reading anything, so the
	# default is free movement and the fence is a knob.
	var beyond := Vector3(axis_len + 5.0, -4.0, -6.0)   # behind the blue line
	pt.global_position = frame.to_global(beyond)
	await process_frame
	await process_frame
	var lp: Vector3 = frame.to_local(pt.global_position)
	_say("  shoved to local (+%.0f, -4, %.0f), outside the box and behind z=0:" % [beyond.x, beyond.z])
	_say("     it sits at (%.2f, %.2f, %.2f)" % [lp.x, lp.y, lp.z])
	_check(not bool(frame.get("confine_point")), "confine_point is off by default")
	_check(lp.is_equal_approx(beyond), "the point STAYED where it was put — no fence")
	_check(lp.z < 0.0, "and it can go behind the blue line: local z = %.2f" % lp.z)

	# turning the fence on still works, for a map that wants a contained demo
	frame.set("confine_point", true)
	pt.global_position = frame.to_global(beyond)
	await process_frame
	await process_frame
	await process_frame
	var fenced: Vector3 = frame.to_local(pt.global_position)
	_check(fenced.x <= axis_len + 0.001 and fenced.z >= -0.001,
		"with confine_point on it clamps again: (%.2f, %.2f, %.2f)" % [fenced.x, fenced.y, fenced.z])
	frame.set("confine_point", false)

	# --- 3. the readout is measured from Vector3.ZERO --------------------------
	_check(str(frame.get("readout_space")) == "world", "readout_space defaults to world")
	pt.global_position = frame.to_global(Vector3(1.0, 1.0, 1.0))
	await process_frame
	var world: Vector3 = pt.global_position
	var local: Vector3 = frame.to_local(pt.global_position)
	_say("  point one unit out on each axis:")
	_say("     world (from Vector3.ZERO) = (%.2f, %.2f, %.2f)" % [world.x, world.y, world.z])
	_say("     local (from the frame)    = (%.2f, %.2f, %.2f)" % [local.x, local.y, local.z])
	_check(not world.is_equal_approx(local),
		"the two readings DIFFER — which is why the old one said 1.00/1.00/1.00 in all 47 halls")
	_check(absf(world.x - origin.x) < scl * 2.0 and absf(world.z - origin.z) < scl * 2.0,
		"the world reading carries the frame's own place in the map (x near %.0f, z near %.0f)"
			% [origin.x, origin.z])
	# --- 4. a point placed SEPARATELY is adopted, and is NOT fenced ------------
	var ext_scene := "res://commons/primitives/point/interactive_point_origin.tscn"
	var frame2: Node3D = ps.instantiate() as Node3D
	frame2.set("floating_point", false)        # no point of its own
	holder.add_child(frame2)
	frame2.global_position = Vector3(20.0, 0.0, 20.0)
	var loose: Node3D = (load(ext_scene) as PackedScene).instantiate() as Node3D
	holder.add_child(loose)
	# well outside the frame's 3-unit box, and BEHIND it in z — the case that could
	# not be reached while the point had to live inside its own axes
	loose.global_position = Vector3(28.0, 1.2, 11.0)
	await process_frame
	await process_frame
	_say("")
	_say("a point placed on its own at (28.0, 1.2, 11.0), frame at (20, 0, 20):")
	var adopted: Variant = frame2.call("_find_point")
	_check(adopted == loose, "the frame adopted the separately placed point")
	await process_frame
	_check(loose.global_position.is_equal_approx(Vector3(28.0, 1.2, 11.0)),
		"it was NOT dragged back into the axis box — still at %s" % str(loose.global_position))
	_check(not bool(frame2.get("confine_point")), "confine_point is off by default")
	# --- 5. the museum's ORDERING: config before the tree, position after ------
	# endless_museum.gd configures the root while it is still OUTSIDE the tree and
	# moves it into the hall afterwards. Reproduced exactly, because resolving a
	# world start at _ready reads a transform the frame does not have yet.
	var f3: Node3D = ps.instantiate() as Node3D
	f3.set("floating_point", true)
	f3.set("floating_point_space", "world")
	f3.call("apply_grid_config", {
		"floating_point_space": "world", "floating_point_at": "8,1.2,11"})
	holder.add_child(f3)                      # _ready runs HERE, frame still at origin
	f3.global_position = Vector3(4.5, -2.1, 12.5)   # the hall places it AFTER
	await process_frame
	# ...and the plan's `offset` nudges it again a frame later, which a one-shot
	# resolve would miss entirely
	f3.global_position += Vector3(0.0, 0.20, 0.0)
	await process_frame
	await process_frame
	await process_frame
	var p3: Node3D = f3.get_node_or_null("FloatingPoint") as Node3D
	_say("")
	_say("museum ordering — config outside the tree, hall position after _ready:")
	_check(p3 != null, "the point was built")
	if p3 != null:
		var w: Vector3 = p3.global_position
		_say("     point world = (%.2f, %.2f, %.2f)  (asked for 8.00, 1.20, 11.00)" % [w.x, w.y, w.z])
		_check(w.is_equal_approx(Vector3(8.0, 1.2, 11.0)),
			"it resolved against the FINAL transform, not the one at _ready")
	_finish()


func _finish() -> void:
	_say("")
	_say("%d checks, %d failed" % [_l.size(), _fails.size()])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(_l)) + "\n")
		f.close()
	quit(1 if _fails.size() > 0 else 0)
