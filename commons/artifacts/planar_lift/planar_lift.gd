# PlanarLift.gd — what the plane forecloses, the third dimension dissolves
#
# @identity
# essence: a graph on a table; flat, its edges collide where they must cross, and lifting them into arcs makes every collision vanish while the crossings in the plane stay exactly where they were
# desire: learner stops reading a crossing as a mistake in the drawing and meets it as a fact about the WORLD the drawing lives in — K5 has no flat drawing without one, and the price is paid in the plane, not by the graph
# critical_parameter: lift — how much height the edges are given (flat / slight / lifted / spread); under it graph decides whether there is anything to dissolve, and wheel is the control that crosses nowhere
# triggers: none; crossings and 3D clearances are recomputed whenever lift or graph changes, and colliding edges are drawn red
# emerges: the recognition that an impossibility can be local to a dimension — nothing about K5 changed when it was lifted, only the space it was asked to live in
# relationships: the dimensional member of the separation family — [[bridge_cut]] severs, [[boolean_neck]] thins, [[flex_connector]] contains, [[droplet_cusp]] squeezes; here nothing moves but the ceiling, and that is enough
# truth: a crossing is not a property of a graph, it is a property of a graph pressed into a plane
extends Node3D
class_name PlanarLift

## WHAT IS MEASURED, AND WHAT IS ONLY INHERITED.
##
## Two numbers, both computed from the geometry on display. CROSSINGS IN THE
## PLANE: pairs of edges whose straight chords intersect in the table's
## projection, shared endpoints excluded. This number ignores the lift,
## deliberately -- an arc changes nothing about where its shadow runs.
## COLLISIONS IN SPACE: pairs of non-adjacent edge tubes that actually touch in
## 3D, from sampled arc polylines. Flat, the two numbers agree; lifted, the
## second goes to zero while the first stands. The plate prints both, because
## the gap BETWEEN them is the artifact.
##
## What the artifact does not prove but the mathematics does: for k5 and k33 no
## flat drawing whatever avoids crossings (Kuratowski's theorem -- these two are
## the obstructions all non-planarity reduces to). The piece shows THIS drawing
## crossing; the theorem says don't bother trying others. wheel is the honest
## control: planar, drawn flat with zero crossings, so lifting it buys nothing
## and the axis is CONDITIONAL on the graph, as every axis in this family has
## turned out to be conditional on its partner.
##
## THE LIFT THAT WORKS IS FOUND, NOT ASSERTED. Arc peak heights start on a
## ladder, and a resolve pass raises any pair still touching in 3D until none
## do (never at lift=flat -- the plane keeps its verdict). The pass is capped
## and its result is measured again afterwards; if anything still touched, the
## plate would say so, because a verdict is read off the final geometry.

const GRAPHS := ["k5", "k33", "wheel", "chain"]
const LIFTS := {"flat": 0.0, "slight": 0.02, "lifted": 0.07, "spread": 0.12}

@export_enum("k5", "k33", "wheel", "chain") var graph: String = "k5":
	set(v):
		graph = v
		if is_inside_tree():
			_rebuild()

@export_enum("flat", "slight", "lifted", "spread") var lift: String = "flat":
	set(v):
		lift = v
		if is_inside_tree():
			_rebuild()

@export var span: float = 0.36
@export var node_radius: float = 0.011
@export var edge_radius: float = 0.0045
@export var show_readout: bool = true

@export var clear_color: Color = Color(0.30, 0.52, 0.80)
@export var collide_color: Color = Color(0.88, 0.18, 0.18)
@export var node_color: Color = Color(0.92, 0.92, 0.95)
@export var table_color: Color = Color(0.32, 0.30, 0.34)

const ARC_SAMPLES := 12
const TOUCH := 0.001             # beyond tube contact, the margin that counts as touching
const RESOLVE_ROUNDS := 10
const RESOLVE_BUMP := 0.013

var _pos: Array[Vector3] = []    # node positions (y = 0 except spread)
var _edges: Array = []           # [a, b]
var _peaks: Array[float] = []    # arc peak height per edge
var _polys: Array = []           # sampled polyline per edge
var _crossings: int = 0
var _collisions: Array = []      # colliding edge-index pairs
var _min_clear: float = 1e9
var _built: Node3D


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# ----------------------------------------------------------------- the graphs

func _shape() -> void:
	_pos.clear()
	_edges.clear()
	var s := span
	match graph:
		"k5":
			# five nodes, every pair joined: the smaller Kuratowski obstruction
			for i in range(5):
				var th := TAU * float(i) / 5.0 - PI * 0.5
				_pos.append(Vector3(cos(th) * s * 0.42, 0, sin(th) * s * 0.42))
			for i in range(5):
				for j in range(i + 1, 5):
					_edges.append([i, j])
		"k33":
			# three and three, every left joined to every right: the other one
			for i in range(3):
				_pos.append(Vector3(-s * 0.36, 0, (float(i) - 1.0) * s * 0.30))
			for i in range(3):
				_pos.append(Vector3(s * 0.36, 0, (float(i) - 1.0) * s * 0.30))
			for i in range(3):
				for j in range(3):
					_edges.append([i, 3 + j])
		"wheel":
			# a hub and a rim: PLANAR, zero crossings as drawn. The control --
			# proof the red marks are facts about k5, not about flatness itself
			_pos.append(Vector3.ZERO)
			for i in range(6):
				var th := TAU * float(i) / 6.0
				_pos.append(Vector3(cos(th) * s * 0.40, 0, sin(th) * s * 0.40))
			for i in range(6):
				_edges.append([0, i + 1])
				_edges.append([i + 1, 1 + ((i + 1) % 6)])
		"chain":
			for i in range(6):
				_pos.append(Vector3(
					-s * 0.45 + s * 0.18 * float(i), 0,
					s * 0.12 * (1.0 if i % 2 == 0 else -1.0)))
			for i in range(5):
				_edges.append([i, i + 1])

	if lift == "spread":
		# the nodes leave the table too: a genuinely three-dimensional embedding
		for i in range(_pos.size()):
			_pos[i].y = (float((i * 7) % 3) - 1.0) * LIFTS["spread"] * 0.35


# ------------------------------------------------------------ the two numbers

## Pairs of edges whose straight chords cross in the table projection. The lift
## never changes this: an arc's shadow runs where the chord runs.
func _count_crossings() -> int:
	var n := 0
	for i in range(_edges.size()):
		for j in range(i + 1, _edges.size()):
			var e: Array = _edges[i]
			var f: Array = _edges[j]
			if e[0] == f[0] or e[0] == f[1] or e[1] == f[0] or e[1] == f[1]:
				continue
			if _segs_cross_2d(_pos[e[0]], _pos[e[1]], _pos[f[0]], _pos[f[1]]):
				n += 1
	return n


func _segs_cross_2d(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> bool:
	var p1 := Vector2(a.x, a.z)
	var p2 := Vector2(b.x, b.z)
	var p3 := Vector2(c.x, c.z)
	var p4 := Vector2(d.x, d.z)
	var d1 := _ccw(p3, p4, p1)
	var d2 := _ccw(p3, p4, p2)
	var d3 := _ccw(p1, p2, p3)
	var d4 := _ccw(p1, p2, p4)
	return ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) \
		and ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0))


func _ccw(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)


func _sample_arcs() -> void:
	_polys.clear()
	for e in range(_edges.size()):
		var a: Vector3 = _pos[_edges[e][0]]
		var b: Vector3 = _pos[_edges[e][1]]
		var pts: Array[Vector3] = []
		for k in range(ARC_SAMPLES + 1):
			var t := float(k) / float(ARC_SAMPLES)
			pts.append(a.lerp(b, t) + Vector3.UP * (_peaks[e] * sin(PI * t)))
		_polys.append(pts)


## Non-adjacent tube pairs that touch in 3D, and the closest approach overall.
func _measure_space() -> void:
	_collisions.clear()
	_min_clear = 1e9
	var touch_at := edge_radius * 2.0 + TOUCH
	for i in range(_edges.size()):
		for j in range(i + 1, _edges.size()):
			var e: Array = _edges[i]
			var f: Array = _edges[j]
			if e[0] == f[0] or e[0] == f[1] or e[1] == f[0] or e[1] == f[1]:
				continue
			var d := _poly_distance(_polys[i], _polys[j])
			_min_clear = minf(_min_clear, d - edge_radius * 2.0)
			if d < touch_at:
				_collisions.append([i, j])


## Exact closest approach between the two polylines, SEGMENT against segment.
## Point sampling missed it: two coplanar K5 chords that truly intersect read
## as 10 mm apart because the crossing fell between samples, while k33's only
## passed by the luck of its grid putting samples on the crossings.
func _poly_distance(p: Array, q: Array) -> float:
	var best := 1e9
	for i in range(p.size() - 1):
		for j in range(q.size() - 1):
			best = minf(best, _seg_seg(p[i], p[i + 1], q[j], q[j + 1]))
	return best


func _seg_seg(p1: Vector3, p2: Vector3, q1: Vector3, q2: Vector3) -> float:
	var d1 := p2 - p1
	var d2 := q2 - q1
	var r := p1 - q1
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0
	if a <= 1e-12 and e <= 1e-12:
		return r.length()
	if a <= 1e-12:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c := d1.dot(r)
		if e <= 1e-12:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b := d1.dot(d2)
			var den := a * e - b * b
			if den > 1e-12:
				s = clampf((b * f - c * e) / den, 0.0, 1.0)
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(q1 + d2 * t)


func _resolve_space() -> void:
	# find the lift that works -- never at flat, where the plane keeps its verdict
	for _round in range(RESOLVE_ROUNDS):
		_sample_arcs()
		_measure_space()
		if _collisions.is_empty():
			return
		for pair in _collisions:
			_peaks[maxi(pair[0], pair[1])] += RESOLVE_BUMP
	_sample_arcs()
	_measure_space()


# ----------------------------------------------------------------- the body

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit
	return m


func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()

	_shape()
	_crossings = _count_crossings()

	var base_h: float = float(LIFTS.get(lift, 0.0))
	_peaks.clear()
	for e in range(_edges.size()):
		if base_h <= 0.0:
			_peaks.append(0.0)
		else:
			_peaks.append(base_h * (0.4 + 0.6 * float(e) / maxf(float(_edges.size() - 1), 1.0)))

	if base_h > 0.0:
		_resolve_space()
	else:
		_sample_arcs()
		_measure_space()

	# the table: the plane itself, drawn, so the shadow has somewhere to live
	var table := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(span * 1.15, 0.008, span * 1.15)
	table.mesh = tm
	table.material_override = _mat(table_color, 0.04)
	table.position = Vector3(0, -0.008, 0)
	_built.add_child(table)

	var collide_set := {}
	for pair in _collisions:
		collide_set[pair[0]] = true
		collide_set[pair[1]] = true

	for e in range(_edges.size()):
		var col: Color = collide_color if collide_set.has(e) else clear_color
		var m := _mat(col, 0.55 if collide_set.has(e) else 0.3)
		var pts: Array = _polys[e]
		for k in range(pts.size() - 1):
			_rod(pts[k], pts[k + 1], m)

	for p in _pos:
		var sph := SphereMesh.new()
		sph.radius = node_radius
		sph.height = node_radius * 2.0
		sph.radial_segments = 12
		sph.rings = 6
		var mi := MeshInstance3D.new()
		mi.mesh = sph
		mi.material_override = _mat(node_color, 0.5)
		mi.position = p
		_built.add_child(mi)

	if show_readout:
		var plate := Label3D.new()
		plate.text = _verdict()
		plate.font_size = 40
		plate.pixel_size = 0.00040
		plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.modulate = collide_color if not _collisions.is_empty() else clear_color
		plate.position = Vector3(0, maxf(float(LIFTS.get(lift, 0.0)) * 1.6, 0.10) + 0.07, 0)
		_built.add_child(plate)

	var anchor := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(span * 1.2, 0.22, span * 1.2)
	anchor.mesh = am
	anchor.layers = 0
	anchor.name = "ExtentAnchor"
	anchor.position = Vector3(0, 0.08, 0)
	_built.add_child(anchor)


func _rod(a: Vector3, b: Vector3, m: StandardMaterial3D) -> void:
	var d := b - a
	if d.length() < 1e-6:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = edge_radius
	cyl.bottom_radius = edge_radius
	cyl.height = d.length() * 1.06        # a hair long, so the segments read as one arc
	cyl.radial_segments = 7
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = m
	var mid := (a + b) * 0.5
	mi.position = mid
	if absf(d.normalized().dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mid, mid + d.normalized(), Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	_built.add_child(mi)


func _verdict() -> String:
	var clear_mm := maxf(_min_clear, 0.0) * 1000.0
	if _crossings == 0:
		return "PLANAR\n0 crossings flat -- lifting buys nothing"
	if _collisions.is_empty():
		return "%d CROSSINGS IN THE PLANE\n0 in space -- closest %.0f mm" \
			% [_crossings, clear_mm]
	return "FORCED FLAT\n%d crossings, %d collisions" \
		% [_crossings, _collisions.size()]


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("graph"):
		var g := str(config_data["graph"]).to_lower().strip_edges()
		if GRAPHS.has(g):
			graph = g
			dirty = true
	if config_data.has("lift"):
		var l := str(config_data["lift"]).to_lower().strip_edges()
		if LIFTS.has(l):
			lift = l
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim is testable without reading pixels.
func crossings_in_plane() -> int:
	return _crossings


func collisions_in_space() -> int:
	return _collisions.size()


func min_clearance_m() -> float:
	return _min_clear
