extends Node3D
class_name SpecimenPlinth

# @identity
# essence: a primitive lifted onto a podium and given a name — the bricoleur's first move, turning a shape into a labelled PART held in reserve for later construction
# desire: one reusable plinth that any of the eight primitives (and the inventory rack) can stand on, so the bricolage sequence's specimen wall needs no per-shape scene — the shape is read from the artifact's own lookup name
# critical_parameter: shape — derived from the lookup_name meta the grid stamps before _ready (point_specimen -> point, cube_specimen -> cube, ...); it decides which mesh is built and what the label says
# triggers: _ready() reads get_meta("artifact_lookup_name"), builds a grid-shaded podium, the named primitive on top, and a 2D-in-3D name plate — a museum specimen, not a scattered mesh
# emerges: a shelf of parts that reads as inventory — each primitive the same size, same plinth, differing only in shape and name, so the eye compares them as candidates rather than admiring them as objects
# needs: Godot built-in meshes [Box/Sphere/Cylinder/Torus/Plane]; small custom meshes for point/line/triangle; Grid.gdshader [present]; TextScreen plate [commons/ui/text_screen.gd, present]; the lookup_name meta [set by GridInteractablesComponent before add_child, verified 2026-07-19]
# relationships: the base of the bricolage sequence (Bricolage_Inventory + Bricolage_Affordances share this plinth); wraps the primitive family (point/line/triangle/plane/cube/sphere/cylinder/torus) as specimens; the affordance variants (cylinder_as_axle, plane_as_seat, ...) reuse it with an action label instead of a category label
# truth: a part is a primitive that has agreed to wait. The plinth does not change the shape — it changes its status, from thing to candidate. Bricolage begins the moment you shelve a cube and call it stock.

## The specimen-plinth wrapper for the bricolage sequence. One script serves
## every specimen and affordance: the shape is read from the lookup_name the
## grid stamps as metadata before _ready(). Build order per instance:
## podium -> primitive -> name plate.

@export var shape: String = ""          # override; empty = derive from lookup_name
@export var specimen_label: String = "" # override; empty = derive from shape
@export var specimen_note: String = ""  # override sub-line
@export var primitive_color: Color = Color(0.55, 0.62, 0.72)
@export var plinth_color: Color = Color(0.14, 0.15, 0.18)

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const PLINTH_W := 0.5
const PLINTH_H := 0.5
const PRIM_SIZE := 0.24   # target half-extent of the specimen primitive

# lookup_name -> [shape, LABEL, note]
const SPECIMENS := {
	"point_specimen":    ["point",    "POINT",    "position without extension"],
	"line_specimen":     ["line",     "LINE",     "two points, a direction"],
	"triangle_specimen": ["triangle", "TRIANGLE", "the first enclosure"],
	"plane_specimen":    ["plane",    "PLANE",    "flatness, extended"],
	"cube_specimen":     ["cube",     "CUBE",     "the volume of the grid"],
	"sphere_specimen":   ["sphere",   "SPHERE",   "not everything is a corner"],
	"cylinder_specimen": ["cylinder", "CYLINDER", "a line given a body"],
	"torus_specimen":    ["torus",    "TORUS",    "a hole you cannot fill"],
	"inventory_workbench": ["workbench", "INVENTORY", "parts before they are used"],
}

var _built := false


func _ready() -> void:
	_resolve_identity()
	_build()


# Resolve shape/label/note from the export overrides, else the lookup_name meta.
func _resolve_identity() -> void:
	var lookup := ""
	if has_meta("artifact_lookup_name"):
		lookup = str(get_meta("artifact_lookup_name"))
	if shape == "" and SPECIMENS.has(lookup):
		var spec: Array = SPECIMENS[lookup]
		shape = str(spec[0])
		if specimen_label == "":
			specimen_label = str(spec[1])
		if specimen_note == "":
			specimen_note = str(spec[2])
	if shape == "":
		shape = "cube"
	if specimen_label == "":
		specimen_label = shape.to_upper()


func _build() -> void:
	if _built:
		for c in get_children():
			c.queue_free()
	_built = true

	_add_plinth()

	var prim := _make_primitive(shape)
	if prim:
		prim.name = "Specimen"
		prim.position = Vector3(0.0, PLINTH_H + PRIM_SIZE + 0.02, 0.0)
		add_child(prim)

	_add_label()


func _add_plinth() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Plinth"
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_W, PLINTH_H, PLINTH_W)
	mi.mesh = box
	mi.position = Vector3(0.0, PLINTH_H * 0.5, 0.0)
	mi.material_override = _grid_material(plinth_color, Color(0.30, 0.34, 0.42), 0.6)
	add_child(mi)


func _add_label() -> void:
	# Canonical 2D-in-3D plate (TextScreen) in PAD mode — a reclined museum
	# plaque on a low wedge, sat on the plinth top's front edge. Add to the tree
	# first so its own _ready() builds before we drive it (its export setters
	# touch child nodes that only exist post-_ready).
	var ts := TextScreenScript.new()
	ts.name = "NamePlate"
	add_child(ts)
	ts.mode = 2                      # Mode.PAD (SCREEN=0, STAND=1, PAD=2)
	ts.width_m = 0.34
	ts.position = Vector3(0.0, PLINTH_H + 0.005, PLINTH_W * 0.5 - 0.06)
	if ts.has_method("set_text"):
		ts.set_text(specimen_label, specimen_note)


# --- primitive meshes ------------------------------------------------------

func _make_primitive(kind: String) -> MeshInstance3D:
	match kind:
		"workbench":
			return _make_workbench()
		_:
			var mi := MeshInstance3D.new()
			mi.mesh = _mesh_for(kind)
			mi.material_override = _grid_material(primitive_color, Color(0.45, 0.85, 1.0), 2.0)
			return mi


func _mesh_for(kind: String) -> Mesh:
	match kind:
		"cube":
			var b := BoxMesh.new()
			b.size = Vector3(PRIM_SIZE * 2.0, PRIM_SIZE * 2.0, PRIM_SIZE * 2.0)
			return b
		"sphere":
			var s := SphereMesh.new()
			s.radius = PRIM_SIZE
			s.height = PRIM_SIZE * 2.0
			s.radial_segments = 24
			s.rings = 12
			return s
		"cylinder":
			var c := CylinderMesh.new()
			c.top_radius = PRIM_SIZE * 0.7
			c.bottom_radius = PRIM_SIZE * 0.7
			c.height = PRIM_SIZE * 2.0
			return c
		"torus":
			var t := TorusMesh.new()
			t.inner_radius = PRIM_SIZE * 0.45
			t.outer_radius = PRIM_SIZE
			return t
		"plane":
			var p := PlaneMesh.new()
			p.size = Vector2(PRIM_SIZE * 2.0, PRIM_SIZE * 2.0)
			return p
		"point":
			var pt := SphereMesh.new()
			pt.radius = 0.04
			pt.height = 0.08
			pt.radial_segments = 12
			pt.rings = 6
			return pt
		"line":
			var ln := CylinderMesh.new()
			ln.top_radius = 0.02
			ln.bottom_radius = 0.02
			ln.height = PRIM_SIZE * 2.4
			return ln
		"triangle":
			return _triangle_mesh(PRIM_SIZE * 1.4)
		_:
			var d := BoxMesh.new()
			d.size = Vector3(PRIM_SIZE * 2.0, PRIM_SIZE * 2.0, PRIM_SIZE * 2.0)
			return d


# A flat equilateral triangle standing upright, double-sided.
func _triangle_mesh(s: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := s * sqrt(3.0) * 0.5
	var a := Vector3(0.0, h * 0.66, 0.0)
	var b := Vector3(-s * 0.5, -h * 0.34, 0.0)
	var c := Vector3(s * 0.5, -h * 0.34, 0.0)
	for v in [a, b, c]:
		st.add_vertex(v)
	for v in [a, c, b]:   # back face
		st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# The inventory rack: a wide low bench with the eight primitives in a row.
func _make_workbench() -> MeshInstance3D:
	var root := MeshInstance3D.new()
	var bench := BoxMesh.new()
	bench.size = Vector3(1.6, 0.06, 0.34)
	root.mesh = bench
	root.material_override = _grid_material(plinth_color, Color(0.30, 0.34, 0.42), 0.6)
	var kinds := ["point", "line", "triangle", "plane", "cube", "sphere", "cylinder", "torus"]
	var i := 0
	for k in kinds:
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_for(k)
		mi.scale = Vector3(0.45, 0.45, 0.45)
		mi.position = Vector3(-0.7 + float(i) * 0.2, 0.12, 0.0)
		mi.material_override = _grid_material(primitive_color, Color(0.45, 0.85, 1.0), 1.6)
		root.add_child(mi)
		i += 1
	return root


# --- material --------------------------------------------------------------

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
	return fallback


## Grid config. Keys: "shape" (override the derived shape), "label", "note",
## "color" (Color or [r,g,b]), "plinth_color".
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("shape"):
		shape = str(config_data["shape"])
	if config_data.has("label"):
		specimen_label = str(config_data["label"])
	if config_data.has("note"):
		specimen_note = str(config_data["note"])
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			primitive_color = c
		elif c is Array and c.size() >= 3:
			primitive_color = Color(float(c[0]), float(c[1]), float(c[2]))
	if config_data.has("plinth_color"):
		var p = config_data["plinth_color"]
		if p is Color:
			plinth_color = p
		elif p is Array and p.size() >= 3:
			plinth_color = Color(float(p[0]), float(p[1]), float(p[2]))
	if _built:
		_build()
