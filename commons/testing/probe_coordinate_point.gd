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

	# --- 2. the point cannot leave the frame -----------------------------------
	# shove it far outside the positive octant, both directions, and let a frame run
	pt.global_position = frame.to_global(Vector3(axis_len + 5.0, -4.0, axis_len + 9.0))
	await process_frame
	await process_frame
	var lp: Vector3 = frame.to_local(pt.global_position)
	_say("  after a shove to (+%.0f, -4, +%.0f) beyond the axes, local = (%.2f, %.2f, %.2f)"
		% [axis_len + 5.0, axis_len + 9.0, lp.x, lp.y, lp.z])
	_check(lp.x <= axis_len + 0.001 and lp.y <= axis_len + 0.001 and lp.z <= axis_len + 0.001,
		"no axis overrun — every component within axis_length %.2f" % axis_len)
	_check(lp.x >= -0.001 and lp.y >= -0.001 and lp.z >= -0.001,
		"no negative overrun — the point stayed in the positive octant")

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
	_finish()


func _finish() -> void:
	_say("")
	_say("%d checks, %d failed" % [_l.size(), _fails.size()])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(_l)) + "\n")
		f.close()
	quit(1 if _fails.size() > 0 else 0)
