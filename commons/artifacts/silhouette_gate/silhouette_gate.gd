extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SilhouetteGate

## @identity
## lineage: the draw-to-open gate — a ghost silhouette of a form (triangle, square, circle…)
##   hangs in the air; the player takes the drawing point (draw_dot) and traces the form. When
##   every vertex of the silhouette has been drawn through, the form is complete: it fades, and
##   a sliding door opens behind it.
## essence: a form is its set of defining points. Hit them all — in the air, with your hand —
##   and you have *made* the shape. Making the shape is the key; the key dissolves into the door.
## truth: you draw the thing that was only ever a suggestion, and the wall it guarded becomes a way.

@export var form: String = "triangle"          # triangle | square | pentagon | hexagon | circle | sphere
@export var form_size: float = 0.7
@export var hit_radius: float = 0.16           # how close the draw point must pass to a vertex
@export var ordered: bool = false              # true = hit vertices in sequence; false = any order
@export var ring_points: int = 8               # checkpoint count for circle / sphere
@export var rotation_offset_deg: float = 0.0   # rotate the form in its plane
@export var silhouette_color: Color = Color(0.30, 0.95, 0.5)   # the abstract green form
@export var hit_color: Color = Color(0.70, 1.0, 0.8)           # brighter green where it has been drawn
@export var show_label: bool = true
@export var open_door: bool = true             # spawn + open a built-in SlidingDoor on completion
@export var door_tag: String = ""              # also trigger a tagged node via TagSystem ("open")

signal form_completed

const DRAW_DOT := "res://commons/primitives/point/draw_dot.tscn"
const SLIDING_DOOR := "res://commons/artifacts/sliding_door/sliding_door.tscn"
const PLANE_Y := 1.3                           # centre height of the form
const PLANE_Z := 0.12                          # the form sits just in front of the door

var _checkpoints: Array = []                   # [{pos, node, hit}]
var _edges: Array = []                         # [{a, b, node}]
var _draw_sphere: Node3D
var _silhouette: Node3D
var _door: Node3D
var _next: int = 0
var _done: bool = false


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("form"): form = str(config["form"])
	if config.has("door_tag"): door_tag = str(config["door_tag"])
	if config.has("form_size"): form_size = float(config["form_size"])
	if config.has("ring_points"): ring_points = int(config["ring_points"])
	if config.has("ordered"): ordered = bool(config["ordered"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_checkpoints.clear(); _edges.clear(); _next = 0; _done = false
	_build()


func _n_sides() -> int:
	match form:
		"triangle": return 3
		"square", "quad": return 4
		"pentagon": return 5
		"hexagon": return 6
		_: return max(3, ring_points)            # circle / sphere -> checkpoints around the ring


func _ring(n: int) -> Array:
	# point-up for odd polygons; flat-top (axis-aligned) for even ones (so a square reads as a quad)
	var start := PI / 2.0
	if n % 2 == 0:
		start += PI / float(n)
	start += deg_to_rad(rotation_offset_deg)
	var pts: Array = []
	for i in range(n):
		var a: float = start + TAU * float(i) / float(n)
		pts.append(Vector3(cos(a) * form_size, PLANE_Y + sin(a) * form_size, PLANE_Z))
	return pts


func _form_geometry() -> Dictionary:
	# returns { points (checkpoints), outline? (visual verts if != checkpoints), edges [[i,j]], fill_tris [[a,b,c]] }
	if form == "cube":
		var s := form_size * 0.7
		var c := Vector3(0.0, PLANE_Y, PLANE_Z)
		var pts: Array = []
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					pts.append(c + Vector3(sx, sy, sz) * s)
		var edges: Array = []
		var el := 2.0 * s                        # a cube edge joins corners that differ on exactly one axis
		for i in range(8):
			for j in range(i + 1, 8):
				if absf(pts[i].distance_to(pts[j]) - el) < el * 0.1:
					edges.append([i, j])
		return {"points": pts, "edges": edges, "fill_tris": []}   # wireframe — minimal/abstract
	# 2D forms: a polygon ring (with a smooth outline for circle/sphere)
	var n := _n_sides()
	var ring := _ring(n)
	if form == "circle" or form == "sphere":
		var op := _ring(max(40, ring_points))
		var oe: Array = []
		var of: Array = []
		for i in range(op.size()):
			oe.append([i, (i + 1) % op.size()])
		for i in range(1, op.size() - 1):
			of.append([0, i, i + 1])
		return {"points": ring, "outline": op, "edges": oe, "fill_tris": of}
	var pe: Array = []
	var pf: Array = []
	for i in range(n):
		pe.append([i, (i + 1) % n])
	for i in range(1, n - 1):
		pf.append([0, i, i + 1])
	return {"points": ring, "edges": pe, "fill_tris": pf}


func _filled_tris(verts: Array, tris: Array, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		st.add_vertex(verts[t[0]]); st.add_vertex(verts[t[1]]); st.add_vertex(verts[t[2]])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _fill_mat(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.4
	return m


func _build() -> void:
	var g := _form_geometry()
	var pts: Array = g["points"]                  # the checkpoints the draw point must hit
	var verts: Array = g.get("outline", pts)      # vertices the edges + fill index into
	# the silhouette — an abstract green form: translucent fill (2D) or a clean wireframe (cube)
	_silhouette = Node3D.new(); _silhouette.name = "Silhouette"; add_child(_silhouette)
	var fill: Array = g.get("fill_tris", [])
	if fill.size() > 0:
		_silhouette.add_child(_filled_tris(verts, fill, _fill_mat(silhouette_color, 0.16)))
	var edges_are_checkpoints := verts.size() == pts.size()
	for e in g["edges"]:
		var seg := _cylinder_between(verts[e[0]], verts[e[1]], 0.015, _glow_mat(silhouette_color, 0.55))
		_silhouette.add_child(seg)
		if edges_are_checkpoints:
			_edges.append({"a": e[0], "b": e[1], "node": seg})
	# the vertices — minimal corner dots (brighten when drawn through)
	for i in range(pts.size()):
		var cp := _sphere(pts[i], 0.015, _glow_mat(silhouette_color, 0.9))
		add_child(cp)
		_checkpoints.append({"pos": pts[i], "node": cp, "hit": false})
	if show_label:
		add_child(_billboard_label(form, Vector3(0, PLANE_Y + form_size + 0.3, 0), 18, silhouette_color.lerp(Color.WHITE, 0.4)))
	# the drawing instrument — the point in front of the form (clean: no reference frame, green trail)
	if ResourceLoader.exists(DRAW_DOT):
		var dd: Node = load(DRAW_DOT).instantiate()
		(dd as Node3D).position = Vector3(0.0, PLANE_Y, 0.55)
		if "show_reference_frame" in dd: dd.set("show_reference_frame", false)
		if "trail_color" in dd: dd.set("trail_color", silhouette_color)
		add_child(dd)
		_draw_sphere = dd.get_node_or_null("GrabPoint/DrawSphere")
	# the door it guards — closed, behind the form
	if open_door and ResourceLoader.exists(SLIDING_DOOR):
		_door = load(SLIDING_DOOR).instantiate()
		(_door as Node3D).position = Vector3(0.0, 0.0, -0.6)
		if "panels_open_amount" in _door:
			_door.set("panels_open_amount", 0.0)
		add_child(_door)


func _process(_dt: float) -> void:
	if _done or _draw_sphere == null:
		return
	var p := _draw_sphere.global_position
	if ordered:
		if _next < _checkpoints.size():
			var cp: Dictionary = _checkpoints[_next]
			if not cp["hit"] and p.distance_to(to_global(cp["pos"])) < hit_radius:
				_mark(_next)
				_next += 1
	else:
		for i in range(_checkpoints.size()):
			var cp: Dictionary = _checkpoints[i]
			if not cp["hit"] and p.distance_to(to_global(cp["pos"])) < hit_radius:
				_mark(i)
	if not _done and _all_hit():
		_complete()


func _mark(i: int) -> void:
	_checkpoints[i]["hit"] = true
	(_checkpoints[i]["node"] as MeshInstance3D).material_override = _glow_mat(hit_color, 1.8)
	# fill any edge whose both endpoints are now drawn
	for e in _edges:
		if _checkpoints[e["a"]]["hit"] and _checkpoints[e["b"]]["hit"]:
			(e["node"] as MeshInstance3D).material_override = _glow_mat(hit_color, 1.4)


func _all_hit() -> bool:
	for cp in _checkpoints:
		if not cp["hit"]:
			return false
	return true


func _complete() -> void:
	_done = true
	emit_signal("form_completed")
	# the form dissolves
	if _silhouette:
		create_tween().tween_property(_silhouette, "scale", Vector3.ZERO, 0.6)
	# the door opens
	if _door and ("panels_open_amount" in _door):
		create_tween().tween_method(_set_door, 0.0, 1.0, 1.4)
	# and any externally-tagged door, if wired
	if door_tag != "" and TagSystem:
		TagSystem.trigger_tag_action(door_tag, "open")
	await get_tree().create_timer(0.7).timeout
	if _silhouette:
		_silhouette.queue_free()
	for cp in _checkpoints:
		if is_instance_valid(cp["node"]):
			cp["node"].queue_free()


func _set_door(v: float) -> void:
	if is_instance_valid(_door):
		_door.set("panels_open_amount", v)
		if _door.has_method("_build_panels"):
			_door._build_panels()
