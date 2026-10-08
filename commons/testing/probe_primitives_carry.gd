extends SceneTree

## GATE — the two additions that give the primitives chapter a hand and a memory.
##
## Both are gated on a word key and default to the shipped behaviour, so the thing
## worth proving is not that they work but that they BITE when asked and stay
## completely inert when not. 36 maps place you_are_here and none of them asked.
##
## A SceneTree probe has no autoloads, so /root/TraceData is stood up here from the
## real script. Everything after that — the meta read, the bus lookup, the
## reduction, the flattening, the grid collapse guard, the peeled build — is the
## live path.
##
##   A  carry:none with a trace waiting   -> opens EMPTY (the default is untouched)
##   B  carry:trace with an empty bus     -> opens empty, no crash
##   C  carry:trace with a real trace     -> carry_corners corners, one plane, in span
##   D  carry:trace with a 2-point trace  -> opens empty (nothing to close)
##   E  carry:trace, trace on one spot    -> opens empty, not 1 stray corner
##   F  peel:fixed                        -> the shipped decal, nothing grabbable
##   G  peel:loose                        -> struck word on a body with a collider
##   H  peel:loose, no strike             -> falls back to the shipped decal

const TRIANGLES := "res://commons/primitives/point/draw_triangle_faces.tscn"
const DECAL := "res://commons/primitives/you_are_here/you_are_here.tscn"
const BUS_SCRIPT := "res://commons/globals/trace_data.gd"

var _fails: Array = []
var _bus: Node = null


func _initialize() -> void:
	await _run()
	if _fails.is_empty():
		print("\nprobe_primitives_carry: ALL 8 CASES PASS")
		quit(0)
	else:
		print("\nprobe_primitives_carry: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)


func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("  ok    %s%s" % [label, (" — " + detail) if detail != "" else ""])
	else:
		_fails.append("%s%s" % [label, (" — " + detail) if detail != "" else ""])
		print("  FAIL  %s%s" % [label, (" — " + detail) if detail != "" else ""])


## The REAL /root/TraceData when this harness has autoloads — which it does; a stub
## added under the same name is silently renamed TraceData2 and then the probe and
## the artifact are reading two different buses, with the probe green on a dead path.
func _bus_up() -> void:
	if _bus != null:
		return
	_bus = root.get_node_or_null("TraceData")
	if _bus == null:
		_bus = Node.new()
		_bus.set_script(load(BUS_SCRIPT))
		_bus.name = "TraceData"
		root.add_child(_bus)
		print("  (no TraceData autoload; probe stood one up)")
	if root.get_node_or_null("TraceData") != _bus:
		_fails.append("bus setup: /root/TraceData is not the node the probe is writing to")


func _bus_set(points: Array) -> void:
	_bus_up()
	_bus.clear_traces()
	if not points.is_empty():
		# The real API, so the probe exercises the bus the rooms actually use.
		_bus.add_trace(points)
	var n: int = _bus.get_all_traces().size()
	if not points.is_empty() and n != 1:
		_fails.append("bus setup: wanted 1 trace, bus holds %d" % n)


## A ring of n points, 2 m across, well clear of the 0.1 m grid at every corner.
func _ring(n: int) -> Array:
	var out: Array = []
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		out.append(Vector3(cos(a) * 1.0, 1.4 + sin(a * 3.0) * 0.3, sin(a) * 1.0))
	return out


func _triangles(carry_value: String) -> Node3D:
	var n: Node3D = load(TRIANGLES).instantiate()
	n.set_meta("config_carry", carry_value)
	root.add_child(n)
	return n


func _decal(peel_value: String, strike: bool) -> Node3D:
	var n: Node3D = load(DECAL).instantiate()
	n.set_meta("config_peel", peel_value)
	n.set_meta("config_strike_first_word", "true" if strike else "false")
	root.add_child(n)
	return n


func _find(n: Node, want: String) -> Node:
	for c in n.get_children():
		if c.name == want:
			return c
	return null


func _run() -> void:
	print("probe_primitives_carry")

	# --- A: the default must not move, even with a trace waiting ---
	_bus_set(_ring(200))
	var a := _triangles("none")
	await process_frame
	_check("A carry:none ignores a waiting trace", a.placed_points.is_empty(),
		"%d corners" % a.placed_points.size())
	a.queue_free()

	# --- B: asked for, nothing there ---
	_bus_set([])
	var b := _triangles("trace")
	await process_frame
	_check("B carry:trace on an empty bus opens empty", b.placed_points.is_empty(),
		"%d corners" % b.placed_points.size())
	b.queue_free()

	# --- C: the real path ---
	_bus_set(_ring(200))
	var c := _triangles("trace")
	await process_frame
	var pts: Array = c.placed_points
	_check("C carry:trace lays carry_corners corners", pts.size() == c.carry_corners,
		"%d corners, wanted %d" % [pts.size(), c.carry_corners])
	if pts.size() >= 2:
		var flat: bool = true
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for p: Vector3 in pts:
			if not is_equal_approx(p.y, pts[0].y):
				flat = false
			lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
			hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
		_check("C flattened to one plane", flat, "y spread %.4f" % (hi.y - lo.y))
		var widest: float = maxf(hi.x - lo.x, hi.z - lo.z)
		_check("C scaled into carry_span", widest <= c.carry_span + 0.25,
			"%.3f m across, span %.2f" % [widest, c.carry_span])
	c.queue_free()

	# --- D: too short to close ---
	_bus_set([Vector3(0, 1, 0), Vector3(0.5, 1, 0.5)])
	var d := _triangles("trace")
	await process_frame
	_check("D a 2-point trace opens empty", d.placed_points.is_empty(),
		"%d corners" % d.placed_points.size())
	d.queue_free()

	# --- E: the grid-collapse guard. A stray corner or two would be worse than none:
	#        an outline that cannot be closed and cannot be told from a real one.
	var same: Array = []
	for i in range(40):
		same.append(Vector3(0.31, 1.2, -0.22))
	_bus_set(same)
	var e := _triangles("trace")
	await process_frame
	_check("E a trace on one spot opens empty", e.placed_points.is_empty(),
		"%d corners" % e.placed_points.size())
	e.queue_free()

	# --- F: the shipped decal, untouched ---
	var f := _decal("fixed", true)
	await process_frame
	_check("F peel:fixed keeps one flat FloorText", _find(f, "FloorText") != null)
	_check("F peel:fixed has nothing grabbable", _find(f, "StruckWord") == null)
	f.queue_free()

	# --- G: the peel ---
	var g := _decal("loose", true)
	await process_frame
	var body: Node = _find(g, "StruckWord")
	_check("G peel:loose builds a pickable struck word", body != null)
	if body != null:
		_check("G the body is a RigidBody3D", body is RigidBody3D, body.get_class())
		var shaped: bool = false
		var worded: bool = false
		for ch in body.get_children():
			if ch is CollisionShape3D and ch.shape != null:
				shaped = true
			if ch.name == "Word":
				worded = true
		_check("G the body carries a shaped collider", shaped)
		_check("G the body carries the word", worded)
		# XR Tools' pickable.gd names XRToolsUserSettings, which a SceneTree probe
		# cannot resolve at compile time. If that happened the .tscn still yields a
		# bare RigidBody3D and every check above passes on a DEAD script. Say which.
		_check("G the pickable script is live (else: headset needed to trust G)",
			body.has_method("pick_up"),
			"script %s" % ("present" if body.get_script() != null else "FAILED TO COMPILE"))
	_check("G the remainder stays printed", _find(g, "FloorTextRest") != null)
	_check("G the one-piece sentence is gone", _find(g, "FloorText") == null)
	g.queue_free()

	# --- H: no first word to separate ---
	var h := _decal("loose", false)
	await process_frame
	_check("H peel:loose without a strike falls back", _find(h, "FloorText") != null
		and _find(h, "StruckWord") == null)
	h.queue_free()

	await process_frame
