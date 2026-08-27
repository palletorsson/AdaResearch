extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SwitchboardConstellation

## @identity
## lineage: the graph theory SUPER OBJECT — an operator's switchboard grown into a
##   constellation. Above a wooden desk hangs a graph of lamp-jacks: a tree of brass
##   edges plus two cords that close CYCLES, one hub holding five cords (degree), two
##   clusters coloured teal and rose with a drawbridge cord that lowers on its own
##   clock and marries them gold (components). A call-pulse commutes between two far
##   jacks on the live AStar3D shortest path; every few crossings one cord on its
##   route unplugs and the pulse reroutes (the river, quoted). Between calls, a tide
##   of light floods the tree level by level (traversal). On the desk, a small brass
##   plate engraves the constellation in miniature with one honest "…" (the mirror).
## essence: every rung of the ladder, wired into one instrument that never stops
##   working its own shift. The switchboard was always a graph with a person inside;
##   here the person is the algorithm.
## truth: everything is a graph if you squint — an operator never had to squint.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const TEAL := Color(0.15, 0.75, 0.7)
const ROSE := Color(0.9, 0.35, 0.5)
const GOLD := Color(0.95, 0.78, 0.25)

@export var seed: int = 63
@export var pace: float = 1.1           # pulse metres per second
@export var marry_every: float = 7.0    # the drawbridge's own clock

# the constellation: index -> position; edges as index pairs; first 8 = teal isle,
# next 5 = rose isle. Node 0 is the hub. Jacks 7 and 12 are the call's two ends.
var _pts: Array = []
var _edges: Array = []
var _extra_cycles: Array = []
var _bridge_edge := [3, 9]
var _lamp_mats: Array = []
var _astar := AStar3D.new()
var _pulse: Node3D
var _route := PackedVector3Array()
var _leg := 0
var _t := 0.0
var _going := true
var _married := false
var _clock := 0.0
var _tide_clock := 0.0
var _tide_level := 0
var _bridge_mesh: MeshInstance3D
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_desk()
	_layout_constellation()
	_build_lamps_and_cords()
	_build_astar()
	_build_pulse()
	_build_mirror_plate()
	_build_plaque()
	_recolor()
	_replan()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "pace", "marry_every"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- structure ----------------------------------------------------------------------

func _build_desk() -> void:
	var wood := _matte_mat(Color(0.14, 0.11, 0.09), 0.8)
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(2.6, 0.08, 0.9)
	top.mesh = tm
	top.position = Vector3(0.0, 0.82, 0.55)
	top.material_override = wood
	add_child(top)
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(2.6, 0.85, 0.1)
	panel.mesh = pm
	panel.position = Vector3(0.0, 0.42, 0.95)
	panel.material_override = wood
	add_child(panel)
	for sx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.08, 0.8, 0.7)
		leg.mesh = lm
		leg.position = Vector3(sx * 1.2, 0.4, 0.55)
		leg.material_override = wood
		add_child(leg)

func _layout_constellation() -> void:
	# hub + teal isle (0..7), rose isle (8..12); hand-laid so the shape reads
	_pts = [
		Vector3(-0.7, 2.5, 0.0),                     # 0 hub
		Vector3(-1.3, 2.15, 0.25), Vector3(-0.95, 2.0, -0.3),
		Vector3(-0.45, 2.1, 0.3), Vector3(-0.15, 2.35, -0.2),
		Vector3(-1.55, 1.75, -0.1), Vector3(-0.75, 1.65, 0.15),
		Vector3(-1.15, 1.5, 0.35),                   # 7 far teal jack
		Vector3(0.7, 2.4, 0.1), Vector3(0.45, 2.05, -0.25),
		Vector3(1.15, 2.1, 0.25), Vector3(0.9, 1.7, -0.1),
		Vector3(1.35, 1.6, 0.2),                     # 12 far rose jack
	]
	_edges = [[0,1],[0,2],[0,3],[0,4],[1,5],[2,6],[5,7],[8,9],[8,10],[9,11],[10,12]]
	_extra_cycles = [[3,6],[10,11]]                  # the rings the tree refused

func _cord(a: Vector3, b: Vector3, tint: Color, sag: float = 0.06, thick: float = 0.008) -> MeshInstance3D:
	# one sagging cord as three chained segments; returns the middle segment so a
	# caller can recolour or hide the whole visual cheaply via material sharing
	var mat := _glow_mat(tint, 0.5)
	var mid: MeshInstance3D = null
	var prev := a
	for k in range(1, 4):
		var t := float(k) / 3.0
		var p := a.lerp(b, t) + Vector3(0.0, -sag * sin(PI * t), 0.0)
		var seg := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = thick
		sm.bottom_radius = thick
		sm.height = prev.distance_to(p)
		seg.mesh = sm
		seg.position = (prev + p) * 0.5
		var dir := (p - prev).normalized()
		var axis := Vector3.UP.cross(dir)
		if axis.length() > 0.001:
			seg.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
		seg.material_override = mat
		add_child(seg)
		if k == 2:
			mid = seg
		prev = p
	return mid

func _build_lamps_and_cords() -> void:
	for i in range(_pts.size()):
		var lamp := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.055 if i != 0 else 0.08
		lm.height = lm.radius * 2.0
		lamp.mesh = lm
		lamp.position = _pts[i]
		var mat := _glow_mat(TEAL if i < 8 else ROSE, 1.4)
		lamp.material_override = mat
		add_child(lamp)
		_lamp_mats.append(mat)
	for e in _edges:
		_cord(_pts[e[0]], _pts[e[1]], Color(0.8, 0.72, 0.5))
	for e in _extra_cycles:
		_cord(_pts[e[0]], _pts[e[1]], Color(0.9, 0.5, 0.25), 0.1)   # the cycle cords, warmer
	_bridge_mesh = _cord(_pts[_bridge_edge[0]], _pts[_bridge_edge[1]], GOLD, 0.14, 0.012)

func _build_astar() -> void:
	for i in range(_pts.size()):
		_astar.add_point(i, _pts[i])
	for e in _edges + _extra_cycles:
		_astar.connect_points(e[0], e[1])
	# the bridge starts open: two components, no route across

func _build_pulse() -> void:
	_pulse = Node3D.new()
	add_child(_pulse)
	var orb := MeshInstance3D.new()
	var om := SphereMesh.new()
	om.radius = 0.035
	om.height = 0.07
	orb.mesh = om
	orb.material_override = _glow_mat(Color(0.98, 0.9, 0.6), 2.6)
	_pulse.add_child(orb)

func _build_mirror_plate() -> void:
	# the mirror, quoted at desk scale: the constellation engraved in miniature,
	# plus one honest ellipsis node for the engraving itself
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.5, 0.015, 0.35)
	plate.mesh = pm
	plate.position = Vector3(0.75, 0.87, 0.45)
	plate.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(plate)
	var center := Vector3(0.75, 0.9, 0.45)
	var scale := 0.12
	for i in range(_pts.size()):
		var src: Vector3 = _pts[i]
		var p := center + (src - Vector3(0.0, 2.0, 0.0)) * scale
		var dot := MeshInstance3D.new()
		var dm := SphereMesh.new()
		dm.radius = 0.008
		dm.height = 0.016
		dot.mesh = dm
		dot.position = p
		dot.material_override = _glow_mat(Color(0.9, 0.85, 0.7), 1.0)
		add_child(dot)
	var ellipsis := TextScreenScript.new()
	ellipsis.mode = 2
	ellipsis.width_m = 0.08
	ellipsis.position = center + Vector3(0.2, 0.0, 0.12)
	add_child(ellipsis)
	if ellipsis.has_method("set_text"):
		ellipsis.set_text("...", "this plate")

# --- the working shift --------------------------------------------------------------

func _replan() -> void:
	var from := 7 if _going else 12
	var to := 12 if _going else 7
	_route = _astar.get_point_path(from, to)
	_leg = 0
	_t = 0.0
	if _route.size() > 0:
		_pulse.position = _route[0]
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("call: %s" % ("connected, %d jacks" % _route.size() if _route.size() > 1 else "NO ROUTE - islands"),
			"married" if _married else "two components")

func _process(delta: float) -> void:
	# the drawbridge keeps its own clock: marry, divorce, remarry — components live
	_clock += delta
	if _clock >= marry_every:
		_clock = 0.0
		_married = not _married
		_astar.set_point_disabled(_bridge_edge[0], false)
		if _married:
			_astar.connect_points(_bridge_edge[0], _bridge_edge[1])
		elif _astar.are_points_connected(_bridge_edge[0], _bridge_edge[1]):
			_astar.disconnect_points(_bridge_edge[0], _bridge_edge[1])
		_bridge_mesh.visible = _married
		_recolor()
		_replan()
	# the tide: between calls, flood the teal tree level by level
	_tide_clock += delta
	if _tide_clock > 0.5:
		_tide_clock = 0.0
		_tide_level = (_tide_level + 1) % 4
		var levels := [[0], [1, 2, 3, 4], [5, 6], [7]]
		for i in range(8):
			var base_c := GOLD if _married else TEAL
			_lamp_mats[i].emission_energy_multiplier = 2.6 if levels[_tide_level].has(i) else 1.1
			_lamp_mats[i].emission = base_c
	# the call walks its live shortest path
	if _route.size() < 2:
		return
	var a := _route[_leg]
	var b := _route[_leg + 1]
	_t += delta * pace / maxf(a.distance_to(b), 0.05)
	if _t >= 1.0:
		_t = 0.0
		_leg += 1
		if _leg >= _route.size() - 1:
			_going = not _going
			_replan()
		return
	_pulse.position = a.lerp(b, _t) + Vector3(0.0, -0.05 * sin(PI * _t), 0.0)

func _recolor() -> void:
	for i in range(_lamp_mats.size()):
		var c := GOLD if _married else (TEAL if i < 8 else ROSE)
		_lamp_mats[i].albedo_color = c
		_lamp_mats[i].emission = c

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "SwitchboardPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-1.55, 0.24, 1.15)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("SWITCHBOARD CONSTELLATION",
			"The whole ladder on one shift: a tree plus the cycles it refused, a hub\nof five cords, two isles married and divorced on the bridge's own clock,\na call commuting the live shortest path, the tide flooding level by level,\nand the desk plate engraving it all - with one honest '...' for itself.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.34
	_readout.position = Vector3(1.55, 0.24, 1.15)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
