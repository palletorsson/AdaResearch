extends Node3D
class_name GraphColoring

## Graph coloring — greedy chromatic number exploration on a Petersen graph.
## 10 nodes, 15 edges. Nodes are colored step-by-step with the greedy algorithm:
## each node gets the lowest color not used by any neighbor.

# --- Configuration ---

@export var node_radius: float = 0.018
@export var edge_width: float = 0.003
@export var graph_radius_outer: float = 0.28
@export var graph_radius_inner: float = 0.12
@export var color_step_delay: float = 0.35

# --- Palette: 4-color chromatic palette ---

var _palette: Array[Color] = [
	Color(0.85, 0.25, 0.2),    # Red
	Color(0.2, 0.55, 0.85),    # Blue
	Color(0.25, 0.75, 0.35),   # Green
	Color(0.9, 0.7, 0.15),     # Yellow
]

var _uncolored: Color = Color(0.35, 0.35, 0.4)
var _edge_color: Color = Color(0.5, 0.55, 0.65, 0.6)
var _edge_colored: Color = Color(0.7, 0.72, 0.78, 0.8)

# --- Internal ---

# Petersen graph adjacency
var _adjacency: Array = []    # Array[Array[int]] — neighbor lists
var _node_positions: Array = [] # Array[Vector3]
var _node_colors: Array = []   # Array[int] — -1 = uncolored
var _node_count: int = 10

var _node_meshes: Array = []   # Array[MeshInstance3D]
var _node_materials: Array = [] # Array[StandardMaterial3D]
var _edge_mesh: MeshInstance3D
var _edge_mat: StandardMaterial3D
var _title_label: Label3D
var _chromatic_label: Label3D

var _coloring_step: int = 0
var _coloring_timer: float = 0.0
var _coloring_done: bool = false
var _chromatic_number: int = 0


func _ready() -> void:
	_build_petersen_graph()
	_compute_positions()
	_create_node_visuals()
	_create_edge_visual()
	_create_labels()


# ------------------------------------------------------------------
# Graph definition — Petersen graph
# ------------------------------------------------------------------

func _build_petersen_graph() -> void:
	# 10 nodes: 0-4 outer pentagon, 5-9 inner pentagram
	# 15 edges: 5 outer, 5 inner (pentagram), 5 spokes
	_adjacency.resize(_node_count)
	_node_colors.resize(_node_count)

	for i in range(_node_count):
		_adjacency[i] = []
		_node_colors[i] = -1

	# Outer pentagon: 0-1-2-3-4-0
	_add_edge(0, 1)
	_add_edge(1, 2)
	_add_edge(2, 3)
	_add_edge(3, 4)
	_add_edge(4, 0)

	# Inner pentagram: 5-7-9-6-8-5
	_add_edge(5, 7)
	_add_edge(7, 9)
	_add_edge(9, 6)
	_add_edge(6, 8)
	_add_edge(8, 5)

	# Spokes connecting outer to inner: 0-5, 1-6, 2-7, 3-8, 4-9
	_add_edge(0, 5)
	_add_edge(1, 6)
	_add_edge(2, 7)
	_add_edge(3, 8)
	_add_edge(4, 9)


func _add_edge(a: int, b: int) -> void:
	_adjacency[a].append(b)
	_adjacency[b].append(a)


# ------------------------------------------------------------------
# Node positions — pentagon + inner pentagram in 3D
# ------------------------------------------------------------------

func _compute_positions() -> void:
	_node_positions.resize(_node_count)

	# Outer pentagon — 5 nodes equally spaced, starting from top
	for i in range(5):
		var angle = -PI / 2.0 + i * TAU / 5.0
		_node_positions[i] = Vector3(
			cos(angle) * graph_radius_outer,
			sin(angle) * graph_radius_outer,
			0.0
		)

	# Inner pentagram — 5 nodes, rotated half-step
	for i in range(5):
		var angle = -PI / 2.0 + i * TAU / 5.0
		_node_positions[5 + i] = Vector3(
			cos(angle) * graph_radius_inner,
			sin(angle) * graph_radius_inner,
			0.0
		)


# ------------------------------------------------------------------
# Visuals — node spheres
# ------------------------------------------------------------------

func _create_node_visuals() -> void:
	var sphere = SphereMesh.new()
	sphere.radius = node_radius
	sphere.height = node_radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6

	for i in range(_node_count):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = _uncolored
		mat.emission_enabled = true
		mat.emission = _uncolored * 0.4
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.4

		var mi = MeshInstance3D.new()
		mi.mesh = sphere
		mi.position = _node_positions[i]
		mi.material_override = mat
		add_child(mi)

		_node_meshes.append(mi)
		_node_materials.append(mat)


# ------------------------------------------------------------------
# Visuals — edge lines (ImmediateMesh)
# ------------------------------------------------------------------

func _create_edge_visual() -> void:
	_edge_mesh = MeshInstance3D.new()
	_edge_mesh.name = "EdgeLines"

	_edge_mat = StandardMaterial3D.new()
	_edge_mat.vertex_color_use_as_albedo = true
	_edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_edge_mesh.material_override = _edge_mat
	add_child(_edge_mesh)

	_rebuild_edges()


func _rebuild_edges() -> void:
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Track drawn edges to avoid duplicates
	var drawn: Dictionary = {}

	for i in range(_node_count):
		for j in _adjacency[i]:
			var key = mini(i, j) * 100 + maxi(i, j)
			if drawn.has(key):
				continue
			drawn[key] = true

			# Color edge brighter if both endpoints are colored
			var col = _edge_color
			if _node_colors[i] >= 0 and _node_colors[j] >= 0:
				col = _edge_colored

			im.surface_set_color(col)
			im.surface_add_vertex(_node_positions[i])
			im.surface_set_color(col)
			im.surface_add_vertex(_node_positions[j])

	im.surface_end()
	_edge_mesh.mesh = im


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "GRAPH COLORING"
	_title_label.font_size = 18
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, graph_radius_outer + 0.06, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.85, 0.88, 0.95)
	_title_label.outline_size = 3
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	# Chromatic number label
	_chromatic_label = Label3D.new()
	_chromatic_label.name = "ChromaticLabel"
	_chromatic_label.text = "Petersen Graph  |  χ = ?"
	_chromatic_label.font_size = 14
	_chromatic_label.pixel_size = 0.001
	_chromatic_label.position = Vector3(0, -(graph_radius_outer + 0.06), 0)
	_chromatic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chromatic_label.modulate = Color(0.7, 0.72, 0.78)
	_chromatic_label.outline_size = 2
	_chromatic_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_chromatic_label)


# ------------------------------------------------------------------
# Step-by-step greedy coloring in _process
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if _coloring_done:
		return

	_coloring_timer += delta
	if _coloring_timer < color_step_delay:
		return

	_coloring_timer = 0.0

	if _coloring_step < _node_count:
		_color_node(_coloring_step)
		_coloring_step += 1
		_rebuild_edges()
	else:
		_coloring_done = true
		_compute_chromatic_number()
		_chromatic_label.text = "Petersen Graph  |  χ = %d" % _chromatic_number


func _color_node(idx: int) -> void:
	# Greedy: assign lowest color index not used by any neighbor
	var used: Dictionary = {}
	for neighbor in _adjacency[idx]:
		var c = _node_colors[neighbor]
		if c >= 0:
			used[c] = true

	var chosen = 0
	while used.has(chosen):
		chosen += 1

	_node_colors[idx] = chosen

	# Update visual
	var color = _palette[chosen] if chosen < _palette.size() else Color.WHITE
	_node_materials[idx].albedo_color = color
	_node_materials[idx].emission = color * 0.5
	_node_materials[idx].emission_energy_multiplier = 1.0

	# Brief scale pulse on the node being colored
	var tween = create_tween()
	tween.tween_property(_node_meshes[idx], "scale", Vector3.ONE * 1.6, 0.1)
	tween.tween_property(_node_meshes[idx], "scale", Vector3.ONE, 0.15)


func _compute_chromatic_number() -> void:
	var max_color = 0
	for c in _node_colors:
		if c > max_color:
			max_color = c
	_chromatic_number = max_color + 1


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("color_step_delay"):
		color_step_delay = float(config_data["color_step_delay"])
	if config_data.has("graph_radius"):
		graph_radius_outer = float(config_data["graph_radius"])
		graph_radius_inner = graph_radius_outer * 0.43
