extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CurvatureBench

## @identity
## name: Non-Euclidean Geometry — The Surface Decides
## lineage: the moment geometry split. Drop the parallel postulate and triangles
##   stop summing to 180 — the answer depends on the curvature of the surface
##   you draw on.
## essence: three small surfaces in a row. A saddle (hyperbolic, negative
##   curvature) carries a triangle whose angles sum to LESS than 180; a flat
##   plane gives exactly 180; a sphere (elliptic, positive curvature) bulges a
##   triangle to MORE than 180. Each angle-sum is labelled.
## truth: the surface decides the geometry — there is no single "true" geometry,
##   only the one that fits the curvature you are standing on.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_gold: Color = Color(0.98, 0.80, 0.32)
@export var spacing: float = 0.62

var _saddle_tri: Node3D
var _plane_tri: Node3D
var _sphere_tri: Node3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	var purple_mat := _glow_mat(wire_purple, 0.7)

	# floor chalk disc
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.92, 0.01, purple_mat))

	var y: float = 0.46
	# --- saddle (hyperbolic) on the left ---
	var left := Vector3(-spacing, y, 0.0)
	_build_saddle(left)
	_saddle_tri = _build_surface_triangle(left + Vector3(0.0, 0.06, 0.0), "hyperbolic")
	add_child(_saddle_tri)
	add_child(_billboard_label("SADDLE", left + Vector3(0.0, 0.36, 0.0), 16, cool_white))
	add_child(_billboard_label("angles < 180", left + Vector3(0.0, 0.24, 0.0), 14, accent_gold))
	add_child(_billboard_label("negative curvature", left + Vector3(0.0, -0.30, 0.0), 11, wire_purple))

	# --- plane (euclidean) in the middle ---
	var mid := Vector3(0.0, y, 0.0)
	_build_plane(mid)
	_plane_tri = _build_surface_triangle(mid + Vector3(0.0, 0.02, 0.0), "flat")
	add_child(_plane_tri)
	add_child(_billboard_label("PLANE", mid + Vector3(0.0, 0.36, 0.0), 16, cool_white))
	add_child(_billboard_label("angles = 180", mid + Vector3(0.0, 0.24, 0.0), 14, accent_gold))
	add_child(_billboard_label("zero curvature", mid + Vector3(0.0, -0.30, 0.0), 11, wire_purple))

	# --- sphere (elliptic) on the right ---
	var right := Vector3(spacing, y, 0.0)
	_build_sphere(right)
	_sphere_tri = _build_surface_triangle(right + Vector3(0.0, 0.0, 0.0), "elliptic")
	add_child(_sphere_tri)
	add_child(_billboard_label("SPHERE", right + Vector3(0.0, 0.36, 0.0), 16, cool_white))
	add_child(_billboard_label("angles > 180", right + Vector3(0.0, 0.24, 0.0), 14, accent_gold))
	add_child(_billboard_label("positive curvature", right + Vector3(0.0, -0.30, 0.0), 11, wire_purple))

	# --- title ---
	add_child(_billboard_label("NON-EUCLIDEAN GEOMETRY", Vector3(0.0, 1.5, 0.0), 30, cool_white))
	add_child(_billboard_label("the surface decides the geometry", Vector3(0.0, 1.36, 0.0), 15, wire_purple))


func _build_saddle(center: Vector3) -> void:
	# a hyperbolic-paraboloid patch: z = x^2 - y^2, as a wire grid
	var mat := _glow_mat(Color(0.55, 0.70, 0.98), 0.6)
	var n: int = 6
	var r: float = 0.20
	var pts: Array = []
	for i in range(n + 1):
		var row: Array = []
		for j in range(n + 1):
			var u: float = lerpf(-1.0, 1.0, float(i) / float(n))
			var v: float = lerpf(-1.0, 1.0, float(j) / float(n))
			var h: float = (u * u - v * v) * 0.18
			row.append(center + Vector3(u * r, h, v * r))
		pts.append(row)
	_wire_grid(pts, n, mat)


func _build_plane(center: Vector3) -> void:
	var mat := _glow_mat(Color(0.70, 0.98, 0.75), 0.6)
	var n: int = 6
	var r: float = 0.20
	var pts: Array = []
	for i in range(n + 1):
		var row: Array = []
		for j in range(n + 1):
			var u: float = lerpf(-1.0, 1.0, float(i) / float(n))
			var v: float = lerpf(-1.0, 1.0, float(j) / float(n))
			row.append(center + Vector3(u * r, 0.0, v * r))
		pts.append(row)
	_wire_grid(pts, n, mat)


func _build_sphere(center: Vector3) -> void:
	# upper hemisphere as latitude/longitude wires
	var mat := _glow_mat(Color(0.98, 0.65, 0.70), 0.6)
	var r: float = 0.22
	add_child(_sphere(center, r * 0.98, _glass_mat(Color(0.98, 0.65, 0.70), 0.10)))
	var rings: int = 4
	for a in range(1, rings):
		var lat: float = lerpf(0.05, PI * 0.5 - 0.05, float(a) / float(rings))
		var rr: float = sin(lat) * r
		var yy: float = cos(lat) * r
		var seg: int = 16
		for s in range(seg):
			var t0: float = TAU * float(s) / float(seg)
			var t1: float = TAU * float(s + 1) / float(seg)
			var p0 := center + Vector3(cos(t0) * rr, yy, sin(t0) * rr)
			var p1 := center + Vector3(cos(t1) * rr, yy, sin(t1) * rr)
			add_child(_cylinder_between(p0, p1, 0.005, mat))


func _wire_grid(pts: Array, n: int, mat: Material) -> void:
	for i in range(n + 1):
		for j in range(n):
			add_child(_cylinder_between(pts[i][j], pts[i][j + 1], 0.005, mat))
	for j in range(n + 1):
		for i in range(n):
			add_child(_cylinder_between(pts[i][j], pts[i + 1][j], 0.005, mat))


func _build_surface_triangle(center: Vector3, kind: String) -> Node3D:
	# a small glowing triangle drawn on/above the surface; bow its edges by kind
	var root := Node3D.new()
	root.position = center
	var mat := _glow_mat(accent_gold, 1.3)
	var a := Vector3(-0.14, 0.10, 0.10)
	var b := Vector3(0.14, 0.10, 0.10)
	var c := Vector3(0.0, 0.10, -0.16)
	# bow factor: hyperbolic caves in (<180), elliptic bulges out (>180)
	var bow: float = 0.0
	if kind == "hyperbolic":
		bow = -0.05
	elif kind == "elliptic":
		bow = 0.07
	_bowed_edge(root, a, b, bow, mat)
	_bowed_edge(root, b, c, bow, mat)
	_bowed_edge(root, c, a, bow, mat)
	return root


func _bowed_edge(root: Node3D, a: Vector3, b: Vector3, bow: float, mat: Material) -> void:
	var mid: Vector3 = (a + b) * 0.5
	# push the midpoint up (elliptic) or down (hyperbolic) to bow the geodesic
	var ctrl: Vector3 = mid + Vector3(0.0, bow, 0.0) + (mid - Vector3.ZERO).normalized() * bow * 1.5
	var steps: int = 5
	var prev: Vector3 = a
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		# quadratic bezier a -> ctrl -> b
		var omt: float = 1.0 - t
		var p: Vector3 = a * (omt * omt) + ctrl * (2.0 * omt * t) + b * (t * t)
		root.add_child(_cylinder_between(prev, p, 0.008, mat))
		prev = p


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# each triangle pulses; the gold accent breathes across all three
	var pulse: float = 0.5 + 0.5 * sin(_t * 2.0)
	var tris: Array = [_saddle_tri, _plane_tri, _sphere_tri]
	for idx in range(tris.size()):
		var tri: Node3D = tris[idx]
		if is_instance_valid(tri):
			var ph: float = pulse
			tri.scale = Vector3.ONE * (1.0 + ph * 0.10)
			tri.rotation.y = sin(_t * 0.6 + float(idx)) * 0.25
