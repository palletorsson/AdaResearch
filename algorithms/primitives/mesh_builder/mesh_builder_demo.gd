extends Node3D
class_name MeshBuilderDemo

# @identity
# essence: 8 vertex positions in a 2x2x2 cube — press ADD to place spheres, CONNECT to draw edges between them, FILL to make triangle faces — building a mesh from nothing, vertex by vertex
# desire: to feel that meshes are not magic black boxes but things you build from points, lines, and faces — to understand that every 3D model is just vertices connected by topology
# critical_parameter: vertex_positions — the 8 corners of a 0.15m cube provide enough structure for a tetrahedron, a cube wireframe, or freeform construction without overwhelming the learner
# triggers: ADD places next unused vertex as a sphere; CONNECT links the last two placed vertices with a cylinder edge; FILL creates a triangle from the last three vertices; CLEAR resets; PRESET cycles through known shapes
# emerges: the V/E/F counter updates live, and when you build a closed tetrahedron (4V 6E 4F) or cube wireframe (8V 12E 0F) the numbers match Euler's formula — the math is already in your hands
# needs: RackTemplates panel [has]; vertex spheres [has]; edge cylinders [has]; face ArrayMesh [has]; preset animations [has]; V/E/F counter [has]
# relationships: foundational to all mesh-based artifacts — once you understand vertex/edge/face, every procedural mesh in the project makes sense; pairs with platonic solids
# truth: a mesh is a graph drawn in space — vertices are nodes, edges are connections, faces are enclosed regions — mesh_builder_demo lets you feel this construction with your hands

const VERTEX_RADIUS := 0.01
const EDGE_RADIUS := 0.003
const BUILD_AREA := 0.15  # half-size of the 2x2x2 grid

# 8 vertex positions: corners of a cube centered at origin
var _vertex_positions: Array = []
var _placed_vertices: Array = []     # Array of int (index into _vertex_positions)
var _edges: Array = []               # Array of [int, int] pairs
var _faces: Array = []               # Array of [int, int, int] triples
var _vertex_meshes: Array = []       # MeshInstance3D per placed vertex
var _edge_meshes: Array = []         # MeshInstance3D per edge
var _face_mesh: MeshInstance3D = null # single ArrayMesh for all faces
var _stats_label: Label3D = null
var _preset_index: int = 0
var _presets: Array = ["triangle", "quad", "tetrahedron", "cube"]
var _animating_preset: bool = false
var _preset_steps: Array = []
var _preset_step_idx: int = 0
var _preset_timer: float = 0.0

func _ready() -> void:
	_init_vertex_positions()
	_build_panel()
	_build_stats_label()
	_build_guide_frame()

func apply_grid_config(config_data: Dictionary) -> void:
	pass

# ── Vertex grid ─────────────────────────────────────────────────────

func _init_vertex_positions() -> void:
	# 2x2x2 grid corners
	for x in [- BUILD_AREA, BUILD_AREA]:
		for y in [- BUILD_AREA, BUILD_AREA]:
			for z in [- BUILD_AREA, BUILD_AREA]:
				_vertex_positions.append(Vector3(x, y, z))

# ── Panel ───────────────────────────────────────────────────────────

func _build_panel() -> void:
	var panel := RackTemplates.create_panel("MESH BUILDER", [
		[
			{"type": "button", "label": "ADD"},
			{"type": "button", "label": "CONNECT"},
		],
		[
			{"type": "button", "label": "FILL"},
			{"type": "button", "label": "CLEAR"},
		],
		[
			{"type": "button", "label": "PRESET"},
		],
	])
	panel.transform.origin = Vector3(0, -0.28, 0)
	add_child(panel)

	# Wire buttons
	var btn_names := ["Btn_0", "Btn_1", "Btn_2", "Btn_3", "Btn_4"]
	var callbacks := [
		Callable(self, "_on_add_pressed"),
		Callable(self, "_on_connect_pressed"),
		Callable(self, "_on_fill_pressed"),
		Callable(self, "_on_clear_pressed"),
		Callable(self, "_on_preset_pressed"),
	]
	for i in btn_names.size():
		var btn := panel.find_child(btn_names[i], true, false)
		if btn:
			var area := btn.get_node_or_null("InteractableAreaButton")
			if area and area.has_signal("button_pressed"):
				area.button_pressed.connect(callbacks[i])

# ── Stats label ─────────────────────────────────────────────────────

func _build_stats_label() -> void:
	_stats_label = Label3D.new()
	_stats_label.font_size = 16
	_stats_label.pixel_size = 0.0004
	_stats_label.modulate = Color(0.9, 0.9, 0.9)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.transform.origin = Vector3(0, BUILD_AREA + 0.04, 0)
	add_child(_stats_label)
	_update_stats()

func _update_stats() -> void:
	if _stats_label:
		_stats_label.text = "V: %d  E: %d  F: %d" % [_placed_vertices.size(), _edges.size(), _faces.size()]

# ── Guide frame (wireframe cube showing build area) ─────────────────

func _build_guide_frame() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var s := BUILD_AREA
	var corners := [
		Vector3(-s, -s, -s), Vector3(s, -s, -s),
		Vector3(s, -s, -s), Vector3(s, -s, s),
		Vector3(s, -s, s), Vector3(-s, -s, s),
		Vector3(-s, -s, s), Vector3(-s, -s, -s),
		Vector3(-s, s, -s), Vector3(s, s, -s),
		Vector3(s, s, -s), Vector3(s, s, s),
		Vector3(s, s, s), Vector3(-s, s, s),
		Vector3(-s, s, s), Vector3(-s, s, -s),
		Vector3(-s, -s, -s), Vector3(-s, s, -s),
		Vector3(s, -s, -s), Vector3(s, s, -s),
		Vector3(s, -s, s), Vector3(s, s, s),
		Vector3(-s, -s, s), Vector3(-s, s, s),
	]
	for v in corners:
		im.surface_add_vertex(v)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.name = "GuideFrame"
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)

	# Ghost spheres at unused positions
	for i in _vertex_positions.size():
		var ghost := MeshInstance3D.new()
		ghost.name = "Ghost_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = VERTEX_RADIUS * 0.5
		sphere.height = VERTEX_RADIUS
		ghost.mesh = sphere
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.4, 0.4, 0.4, 0.15)
		gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost.material_override = gmat
		ghost.transform.origin = _vertex_positions[i]
		add_child(ghost)

# ── Actions ─────────────────────────────────────────────────────────

func _on_add_pressed() -> void:
	if _animating_preset:
		return
	_add_next_vertex()

func _on_connect_pressed() -> void:
	if _animating_preset:
		return
	_connect_last_two()

func _on_fill_pressed() -> void:
	if _animating_preset:
		return
	_fill_last_three()

func _on_clear_pressed() -> void:
	_animating_preset = false
	_clear_all()

func _on_preset_pressed() -> void:
	_clear_all()
	_start_preset(_presets[_preset_index])
	_preset_index = (_preset_index + 1) % _presets.size()

# ── Vertex placement ────────────────────────────────────────────────

func _add_next_vertex() -> void:
	if _placed_vertices.size() >= _vertex_positions.size():
		return

	var idx := _placed_vertices.size()
	_placed_vertices.append(idx)

	var sphere := MeshInstance3D.new()
	sphere.name = "Vertex_%d" % idx
	var smesh := SphereMesh.new()
	smesh.radius = VERTEX_RADIUS
	smesh.height = VERTEX_RADIUS * 2.0
	sphere.mesh = smesh
	var mat := StandardMaterial3D.new()
	var hue := float(idx) / 8.0
	mat.albedo_color = Color.from_hsv(hue, 0.7, 0.95)
	mat.emission = Color.from_hsv(hue, 0.5, 0.5)
	mat.emission_energy_multiplier = 0.4
	mat.roughness = 0.3
	sphere.material_override = mat
	sphere.transform.origin = _vertex_positions[idx]
	add_child(sphere)
	_vertex_meshes.append(sphere)
	_update_stats()

# ── Edge connection ─────────────────────────────────────────────────

func _connect_last_two() -> void:
	if _placed_vertices.size() < 2:
		return
	var a := _placed_vertices[_placed_vertices.size() - 2]
	var b := _placed_vertices[_placed_vertices.size() - 1]
	_add_edge(a, b)

func _add_edge(a: int, b: int) -> void:
	# Check for duplicate
	for e in _edges:
		if (e[0] == a and e[1] == b) or (e[0] == b and e[1] == a):
			return
	_edges.append([a, b])

	var pa: Vector3 = _vertex_positions[a]
	var pb: Vector3 = _vertex_positions[b]
	var mid := (pa + pb) / 2.0
	var length := pa.distance_to(pb)
	var dir := (pb - pa).normalized()

	var cyl := MeshInstance3D.new()
	cyl.name = "Edge_%d_%d" % [a, b]
	var cmesh := CylinderMesh.new()
	cmesh.top_radius = EDGE_RADIUS
	cmesh.bottom_radius = EDGE_RADIUS
	cmesh.height = length
	cyl.mesh = cmesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.7)
	mat.emission = Color(0.3, 0.3, 0.3)
	mat.emission_energy_multiplier = 0.2
	mat.roughness = 0.4
	mat.metallic = 0.3
	cyl.material_override = mat

	cyl.transform.origin = mid
	# Align cylinder (default Y-up) to direction
	if dir != Vector3.UP and dir != Vector3.DOWN:
		cyl.transform = cyl.transform.looking_at(mid + dir, Vector3.UP)
		cyl.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	elif dir == Vector3.DOWN:
		cyl.rotation.z = PI
	cyl.transform.origin = mid

	add_child(cyl)
	_edge_meshes.append(cyl)
	_update_stats()

# ── Face filling ────────────────────────────────────────────────────

func _fill_last_three() -> void:
	if _placed_vertices.size() < 3:
		return
	var a := _placed_vertices[_placed_vertices.size() - 3]
	var b := _placed_vertices[_placed_vertices.size() - 2]
	var c := _placed_vertices[_placed_vertices.size() - 1]
	_add_face(a, b, c)

func _add_face(a: int, b: int, c: int) -> void:
	_faces.append([a, b, c])
	_rebuild_face_mesh()
	_update_stats()

func _rebuild_face_mesh() -> void:
	if _face_mesh:
		_face_mesh.queue_free()
		_face_mesh = null

	if _faces.is_empty():
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for tri in _faces:
		var pa: Vector3 = _vertex_positions[tri[0]]
		var pb: Vector3 = _vertex_positions[tri[1]]
		var pc: Vector3 = _vertex_positions[tri[2]]
		var normal := (pb - pa).cross(pc - pa).normalized()

		# Front face
		st.set_normal(normal)
		st.set_color(Color(0.3, 0.6, 0.9, 0.6))
		st.add_vertex(pa)
		st.set_color(Color(0.3, 0.9, 0.6, 0.6))
		st.add_vertex(pb)
		st.set_color(Color(0.9, 0.6, 0.3, 0.6))
		st.add_vertex(pc)

		# Back face
		st.set_normal(-normal)
		st.set_color(Color(0.3, 0.6, 0.9, 0.4))
		st.add_vertex(pc)
		st.set_color(Color(0.3, 0.9, 0.6, 0.4))
		st.add_vertex(pb)
		st.set_color(Color(0.9, 0.6, 0.3, 0.4))
		st.add_vertex(pa)

	_face_mesh = MeshInstance3D.new()
	_face_mesh.name = "Faces"
	_face_mesh.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission = Color(0.2, 0.4, 0.6)
	mat.emission_energy_multiplier = 0.2
	_face_mesh.material_override = mat
	add_child(_face_mesh)

# ── Clear ───────────────────────────────────────────────────────────

func _clear_all() -> void:
	for m in _vertex_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_vertex_meshes.clear()

	for m in _edge_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_edge_meshes.clear()

	if _face_mesh:
		_face_mesh.queue_free()
		_face_mesh = null

	_placed_vertices.clear()
	_edges.clear()
	_faces.clear()
	_update_stats()

# ── Presets (animated step-by-step) ─────────────────────────────────

func _start_preset(preset_name: String) -> void:
	_preset_steps.clear()
	_preset_step_idx = 0
	_preset_timer = 0.0

	match preset_name:
		"triangle":
			# 3 vertices, 3 edges, 1 face
			_preset_steps = [
				{"action": "add"}, {"action": "add"}, {"action": "add"},
				{"action": "edge", "a": 0, "b": 1},
				{"action": "edge", "a": 1, "b": 2},
				{"action": "edge", "a": 2, "b": 0},
				{"action": "face", "a": 0, "b": 1, "c": 2},
			]
		"quad":
			# 4 vertices (front face of cube), 4 edges, 2 faces
			_preset_steps = [
				{"action": "add"}, {"action": "add"}, {"action": "add"}, {"action": "add"},
				{"action": "edge", "a": 0, "b": 1},
				{"action": "edge", "a": 1, "b": 3},
				{"action": "edge", "a": 3, "b": 2},
				{"action": "edge", "a": 2, "b": 0},
				{"action": "edge", "a": 0, "b": 3},
				{"action": "face", "a": 0, "b": 1, "c": 3},
				{"action": "face", "a": 0, "b": 3, "c": 2},
			]
		"tetrahedron":
			# vertices 0,1,2,4 (skip 3) form a tetrahedron
			_preset_steps = [
				{"action": "add"}, {"action": "add"}, {"action": "add"},
				{"action": "add"},  # vertex 3
				{"action": "add"},  # vertex 4
				{"action": "edge", "a": 0, "b": 1},
				{"action": "edge", "a": 0, "b": 2},
				{"action": "edge", "a": 0, "b": 4},
				{"action": "edge", "a": 1, "b": 2},
				{"action": "edge", "a": 1, "b": 4},
				{"action": "edge", "a": 2, "b": 4},
				{"action": "face", "a": 0, "b": 1, "c": 2},
				{"action": "face", "a": 0, "b": 1, "c": 4},
				{"action": "face", "a": 0, "b": 2, "c": 4},
				{"action": "face", "a": 1, "b": 2, "c": 4},
			]
		"cube":
			# All 8 vertices, 12 edges, no faces (wireframe)
			_preset_steps = [
				{"action": "add"}, {"action": "add"}, {"action": "add"}, {"action": "add"},
				{"action": "add"}, {"action": "add"}, {"action": "add"}, {"action": "add"},
				# Bottom face edges
				{"action": "edge", "a": 0, "b": 1},
				{"action": "edge", "a": 1, "b": 3},
				{"action": "edge", "a": 3, "b": 2},
				{"action": "edge", "a": 2, "b": 0},
				# Top face edges
				{"action": "edge", "a": 4, "b": 5},
				{"action": "edge", "a": 5, "b": 7},
				{"action": "edge", "a": 7, "b": 6},
				{"action": "edge", "a": 6, "b": 4},
				# Vertical edges
				{"action": "edge", "a": 0, "b": 4},
				{"action": "edge", "a": 1, "b": 5},
				{"action": "edge", "a": 2, "b": 6},
				{"action": "edge", "a": 3, "b": 7},
			]

	_animating_preset = true

func _process(delta: float) -> void:
	if not _animating_preset:
		return

	_preset_timer += delta
	if _preset_timer < 0.25:
		return
	_preset_timer = 0.0

	if _preset_step_idx >= _preset_steps.size():
		_animating_preset = false
		return

	var step: Dictionary = _preset_steps[_preset_step_idx]
	match step["action"]:
		"add":
			_add_next_vertex()
		"edge":
			_add_edge(step["a"], step["b"])
		"face":
			_add_face(step["a"], step["b"], step["c"])

	_preset_step_idx += 1
