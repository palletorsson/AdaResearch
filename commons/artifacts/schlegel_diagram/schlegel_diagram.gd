extends Node3D
class_name SchlegelDiagram

# @identity
# essence: a tesseract projected from a viewpoint parked just outside one of its eight cells, so that cell swells into the glass box every other cell is nested inside — one cube containing seven, none of them actually smaller than the others
# desire: to give the higher-dimensions room its still object; tesseract_bench spins so nothing can be counted, and a projection you cannot hold still teaches nothing about which cell is where
# critical_parameter: view_w — how far outside the near cell the 4D camera stands. 1.6 is just outside and gives the classic 4.3:1 nesting; push it up and the projection flattens toward the parallel shadow, drop it toward 1.0 and the near cell blows up past the room
# triggers: _ready() lays the 16 vertices of (±1)^4, pairs them into 32 edges by Hamming distance 1, projects every point through the perspective divide borrowed live from tesseract_bench, then skins each of the 8 cells as a transparent hull from its own 6 quads
# emerges: the lie you can see through — the outer box looks like a frame and the inner cube looks like a core, and both are ordinary cubes that a 4D observer would call congruent; the hierarchy is entirely an artifact of where the camera stands
# needs: tesseract_bench.gd [present — its _project() is the shared 4D camera]; SurfaceTool [Godot built-in, for the cell hulls]; Grid.gdshader [present]; TextScreen PAD plate [present]
# relationships: the still twin of tesseract_bench and the last rung of dimensional_analogy — same 16 vertices, same 32 edges, same projection call, one parameter apart
# truth: a Schlegel diagram does not show you the fourth dimension, it shows you what one cell's worth of distance does to everything behind it. Perspective is not a window, it is a ranking — and the thing nearest the observer always gets to be the container.

## Tesseract as Schlegel diagram. Take the 4D camera tesseract_bench already
## has, walk it out through one cell's face instead of holding it far away, and
## stop the rotation. The cell you stepped out of projects across the whole
## picture; the opposite cell falls into the middle; the six between become
## frusta joining them. It is the same object, held still enough to count.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const TesseractBenchScript := preload("res://commons/artifacts/tesseract_bench/tesseract_bench.gd")

const PLINTH_W := 1.02
const PLINTH_H := 0.72
const VERT_R := 0.014

## 4D camera distance. Cell faces sit at w = ±1, so anything above 1.0 is
## outside the near cell — "just outside" is the Schlegel condition and the
## whole difference between this artifact and tesseract_bench.
@export var view_w: float = 1.6

## Half-extent of the enclosing hull in metres. size_scale is solved from this
## and view_w so the picture keeps its size when the viewpoint moves.
@export var hull_radius: float = 0.55

## Height of the diagram's centre above the plinth top.
@export var lift: float = 0.60

## A fixed tilt, not an animation. Straight on, two concentric axis-aligned
## cubes read as a square inside a square; a few degrees of tilt is what makes
## the nesting visible without putting the object into motion.
@export var tilt_degrees: Vector3 = Vector3(-16.0, 26.0, 0.0)

## Radians/sec about the room's Y axis. Zero by default — the near cell is
## meant to be held still. A map that wants it turning can say so.
@export var drift_speed: float = 0.0

## The six cells between near and far. They are the honest content of the
## projection, but eight overlapping transparent hulls can turn to soup; a map
## working in a bright room can drop them and keep the two cubes and the edges.
@export var show_side_cells: bool = true

const EDGE_R_OUTER := 0.008
const EDGE_R_INNER := 0.006
const EDGE_R_LINK := 0.005

var _built := false
var _created: Array[Node] = []
## Untyped on purpose — a statically typed Node reference would reject
## view_w / size_scale / _project at compile time. This is a borrowed camera.
var _projector = null
var _hub: Node3D = null
var _drift: float = 0.0

var _vertices_4d: Array[Vector4] = []
var _edges: Array[Vector2i] = []
var _projected: Array[Vector3] = []


func _ready() -> void:
	_projector = TesseractBenchScript.new()
	_build_all()
	_built = true
	set_process(not Engine.is_editor_hint() and absf(drift_speed) > 0.0001)


func _exit_tree() -> void:
	if _projector != null and is_instance_valid(_projector):
		_projector.free()
	_projector = null


# --- 4D ------------------------------------------------------------------

func _hamming4(a: Vector4, b: Vector4) -> int:
	var d: int = 0
	if not is_equal_approx(a.x, b.x):
		d += 1
	if not is_equal_approx(a.y, b.y):
		d += 1
	if not is_equal_approx(a.z, b.z):
		d += 1
	if not is_equal_approx(a.w, b.w):
		d += 1
	return d


func _axis(v: Vector4, i: int) -> float:
	match i:
		0: return v.x
		1: return v.y
		2: return v.z
		_: return v.w


func _make4(c: Array) -> Vector4:
	return Vector4(float(c[0]), float(c[1]), float(c[2]), float(c[3]))


## size_scale that puts the near cell's corners at hull_radius. Solved rather
## than tuned, so hull_radius stays a promise when view_w changes.
func _solved_scale() -> float:
	var vw: float = maxf(view_w, 1.02)
	return hull_radius * (vw - 1.0) / vw


## The borrowed perspective divide. _angle is pinned to 0 — the Schlegel
## condition is a fixed viewpoint, and any x-w rotation would immediately undo
## the nesting this whole artifact is about.
func _project(v: Vector4) -> Vector3:
	if _projector == null:
		var denom: float = maxf(view_w - v.w, 0.001)
		return Vector3(v.x, v.y, v.z) * (view_w * _solved_scale() / denom)
	_projector.view_w = maxf(view_w, 1.02)
	_projector.size_scale = _solved_scale()
	_projector._angle = 0.0
	var out: Vector3 = _projector._project(v)
	return out


# --- build ---------------------------------------------------------------

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_all() -> void:
	_vertices_4d.clear()
	_edges.clear()
	_projected.clear()

	_add_plinth()

	for ix in range(2):
		for iy in range(2):
			for iz in range(2):
				for iw in range(2):
					var x: float = -1.0 if ix == 0 else 1.0
					var y: float = -1.0 if iy == 0 else 1.0
					var z: float = -1.0 if iz == 0 else 1.0
					var w: float = -1.0 if iw == 0 else 1.0
					_vertices_4d.append(Vector4(x, y, z, w))

	for i in range(_vertices_4d.size()):
		for j in range(i + 1, _vertices_4d.size()):
			if _hamming4(_vertices_4d[i], _vertices_4d[j]) == 1:
				_edges.append(Vector2i(i, j))

	for i in range(_vertices_4d.size()):
		_projected.append(_project(_vertices_4d[i]))

	_hub = Node3D.new()
	_hub.name = "SchlegelHub"
	_hub.position = Vector3(0.0, PLINTH_H + lift, 0.0)
	_hub.rotation_degrees = tilt_degrees
	_own(_hub)

	_build_cells()
	_build_edges()
	_build_vertices()
	_add_plate()


## Eight cells, eight hulls. Only the tint and the alpha distinguish them —
## the geometry of all eight is the same six-quad box, put through the same
## projection. That is the claim: the near cell is not a frame, it is a cube.
func _build_cells() -> void:
	var specs := [
		[3, 1.0, Color(0.45, 0.85, 1.00), 0.055],   # near cell — the enclosing hull
		[3, -1.0, Color(1.00, 0.72, 0.35), 0.170],  # far cell — the nested core
		[0, 1.0, Color(0.55, 0.75, 1.00), 0.055],
		[0, -1.0, Color(0.55, 0.75, 1.00), 0.055],
		[1, 1.0, Color(0.70, 0.62, 1.00), 0.055],
		[1, -1.0, Color(0.70, 0.62, 1.00), 0.055],
		[2, 1.0, Color(0.50, 0.95, 0.85), 0.055],
		[2, -1.0, Color(0.50, 0.95, 0.85), 0.055],
	]
	for si in range(specs.size()):
		if si >= 2 and not show_side_cells:
			break
		var s: Array = specs[si]
		var mi := MeshInstance3D.new()
		mi.name = "Cell%d" % si
		mi.mesh = _cell_hull(int(s[0]), float(s[1]))
		mi.material_override = _hull_mat(s[2], float(s[3]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hub.add_child(mi)


## One cell's skin: fix one of the four coordinates, let the other three run to
## ±1, and walk the six quads that bound the result. Projected corner by corner,
## so the hull is the shape the projection actually makes, not a box scaled to
## look like it.
func _cell_hull(fixed_axis: int, fixed_val: float) -> ArrayMesh:
	var free: Array[int] = []
	for i in range(4):
		if i != fixed_axis:
			free.append(i)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]
	for fi in range(3):
		var d: int = free[fi]
		var others: Array[int] = []
		for o in free:
			var oi: int = o
			if oi != d:
				others.append(oi)
		for dvi in range(2):
			var dv: float = -1.0 if dvi == 0 else 1.0
			var quad: Array[Vector3] = []
			for r in ring:
				var rr: Vector2 = r
				var coords := [0.0, 0.0, 0.0, 0.0]
				coords[fixed_axis] = fixed_val
				coords[d] = dv
				coords[others[0]] = rr.x
				coords[others[1]] = rr.y
				quad.append(_project(_make4(coords)))
			st.add_vertex(quad[0])
			st.add_vertex(quad[1])
			st.add_vertex(quad[2])
			st.add_vertex(quad[0])
			st.add_vertex(quad[2])
			st.add_vertex(quad[3])
	st.generate_normals()
	return st.commit()


## The 32 edges, sorted by which cube they belong to. The 12 of the near cell
## are drawn heaviest because that is what a viewer will read as the room; the
## 8 that connect near to far are the ones with no 3D counterpart at all.
func _build_edges() -> void:
	var outer_mat := _line_mat(Color(0.60, 0.72, 0.85), Color(0.45, 0.90, 1.00), 2.6)
	var inner_mat := _line_mat(Color(0.75, 0.60, 0.40), Color(1.00, 0.74, 0.36), 2.6)
	var link_mat := _line_mat(Color(0.44, 0.48, 0.58), Color(0.62, 0.70, 0.88), 1.1)
	for e in _edges:
		var pair: Vector2i = e
		var wa: float = _vertices_4d[pair.x].w
		var wb: float = _vertices_4d[pair.y].w
		var mat: Material = link_mat
		var r: float = EDGE_R_LINK
		if wa > 0.0 and wb > 0.0:
			mat = outer_mat
			r = EDGE_R_OUTER
		elif wa < 0.0 and wb < 0.0:
			mat = inner_mat
			r = EDGE_R_INNER
		_hub.add_child(_strut(_projected[pair.x], _projected[pair.y], r, mat))


func _build_vertices() -> void:
	var outer_mat := _line_mat(Color(0.80, 0.90, 1.00), Color(0.55, 0.95, 1.00), 2.8)
	var inner_mat := _line_mat(Color(1.00, 0.85, 0.60), Color(1.00, 0.78, 0.40), 2.8)
	for i in range(_vertices_4d.size()):
		var near: bool = _vertices_4d[i].w > 0.0
		var mat: Material = outer_mat if near else inner_mat
		var r: float = VERT_R if near else VERT_R * 0.8
		_hub.add_child(_sphere(_projected[i], r, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _hub == null:
		return
	_drift += drift_speed * delta
	# Yaw added to the fixed tilt rather than rotate_y() — rotate_y turns about
	# the hub's own tilted axis, which would make the diagram wobble instead of
	# turn on the room's vertical.
	_hub.rotation = Vector3(
		deg_to_rad(tilt_degrees.x),
		deg_to_rad(tilt_degrees.y) + _drift,
		deg_to_rad(tilt_degrees.z))


# --- pieces --------------------------------------------------------------

func _sphere(pos: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	return mi


func _strut(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.001)
	cyl.radial_segments = 6
	cyl.rings = 1
	mi.mesh = cyl
	var dir: Vector3 = (b - a)
	if dir.length() < 0.0001:
		dir = Vector3.UP
	dir = dir.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa: Vector3 = up.cross(dir).normalized()
	var za: Vector3 = dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (a + b) * 0.5)
	mi.material_override = mat
	return mi


func _add_plinth() -> void:
	var top := MeshInstance3D.new()
	top.name = "PlinthTop"
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_W, 0.05, PLINTH_W)
	top.mesh = box
	top.position = Vector3(0.0, PLINTH_H - 0.025, 0.0)
	top.material_override = _witness_mat()
	_own(top)

	var body := MeshInstance3D.new()
	body.name = "PlinthBody"
	var bb := BoxMesh.new()
	bb.size = Vector3(PLINTH_W - 0.16, PLINTH_H - 0.05, PLINTH_W - 0.16)
	body.mesh = bb
	body.position = Vector3(0.0, (PLINTH_H - 0.05) * 0.5, 0.0)
	body.material_override = _witness_mat()
	_own(body)


func _add_plate() -> void:
	# Set every property BEFORE add_child — TextScreen rebuilds only once it is
	# in the tree, so configuring afterwards costs one rebuild per setter.
	var ts := TextScreenScript.new()
	ts.name = "Plate"
	ts.mode = 2                       # Mode.PAD
	ts.width_m = 0.44
	ts.position = Vector3(0.0, PLINTH_H + 0.005, PLINTH_W * 0.5 - 0.16)
	if ts.has_method("set_text"):
		ts.set_text("SCHLEGEL DIAGRAM", "camera parked just outside one cell —\nthe cell you left becomes the box\nholding the seven you did not")
	_own(ts)


# --- material ------------------------------------------------------------

func _hull_mat(tint: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = 0.35
	return m


func _line_mat(fill: Color, wire: Color, emit: float) -> Material:
	return _grid_material(fill, wire, emit)


func _witness_mat() -> Material:
	return _grid_material(Color(0.28, 0.30, 0.36), Color(0.42, 0.47, 0.57), 0.4)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	fallback.emission_enabled = true
	fallback.emission = wire
	fallback.emission_energy_multiplier = emit
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_hub = null
	_build_all()


## Grid config. Keys: "view_w", "hull_radius", "lift", "drift_speed",
## "show_side_cells". Only geometric changes rebuild — curation_station hands
## every artifact it curates {"emissive": false} straight after framing its
## labels, and rebuilding on that would discard the framing.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_view: float = view_w
	var before_radius: float = hull_radius
	var before_lift: float = lift
	var before_sides: bool = show_side_cells

	if config_data.has("view_w"):
		view_w = maxf(float(config_data["view_w"]), 1.02)
	if config_data.has("hull_radius"):
		hull_radius = maxf(float(config_data["hull_radius"]), 0.08)
	if config_data.has("lift"):
		lift = float(config_data["lift"])
	if config_data.has("drift_speed"):
		drift_speed = float(config_data["drift_speed"])
		set_process(not Engine.is_editor_hint() and absf(drift_speed) > 0.0001)
	if config_data.has("show_side_cells"):
		show_side_cells = bool(config_data["show_side_cells"])

	if not _built:
		return
	if is_equal_approx(view_w, before_view) and is_equal_approx(hull_radius, before_radius) \
			and is_equal_approx(lift, before_lift) and show_side_cells == before_sides:
		return
	_rebuild_now()
