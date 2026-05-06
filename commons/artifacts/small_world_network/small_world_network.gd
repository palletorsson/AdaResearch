extends Node3D
class_name SmallWorldNetwork

## Watts-Strogatz small-world network — ring lattice with rewirable edges.
## 20 nodes arranged in a circle, k=4 nearest neighbors. VR slider controls
## rewiring probability p: p=0 is regular, p=1 is random. Shows how shortcuts
## dramatically reduce average path length while clustering stays high.

# --- Configuration ---

@export var node_count: int = 20
@export var k_neighbors: int = 4       # Each side; total degree = 2*k
@export var graph_radius: float = 0.30
@export var node_radius: float = 0.015
@export var edge_width: float = 0.003

# --- Colors ---

var _color_regular: Color = Color(0.45, 0.48, 0.55, 0.5)   # Gray — original edges
var _color_rewired: Color = Color(1.0, 0.9, 0.2, 0.9)      # Bright yellow — shortcuts
var _color_node_low: Color = Color(0.3, 0.5, 0.85)          # Blue — low degree
var _color_node_high: Color = Color(0.95, 0.3, 0.25)        # Red — high degree

# --- Internal state ---

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _rewire_probability: float = 0.0

# Graph data
var _node_positions: Array = []        # Array[Vector3]
var _edges: Array = []                 # Array[Vector2i] — (from, to)
var _edge_is_rewired: Array = []       # Array[bool]
var _adjacency: Array = []             # Array[Dictionary] — neighbor sets

# Visuals
var _node_meshes: Array = []           # Array[MeshInstance3D]
var _node_materials: Array = []        # Array[StandardMaterial3D]
var _edge_mesh: MeshInstance3D
var _edge_mat: StandardMaterial3D
var _title_label: Label3D
var _stats_label: Label3D

# VR controls
var _control_panel: Node3D
var _p_slider: Node


func _ready() -> void:
	_rng.seed = hash("small_world") + 42
	_compute_node_positions()
	_build_ring_lattice()
	_create_node_visuals()
	_create_edge_visual()
	_create_labels()
	_create_vr_controls()
	_update_stats()


# ------------------------------------------------------------------
# Node positions — circle in the XY plane
# ------------------------------------------------------------------

func _compute_node_positions() -> void:
	_node_positions.resize(node_count)
	for i in range(node_count):
		var angle = -PI / 2.0 + float(i) * TAU / float(node_count)
		_node_positions[i] = Vector3(
			cos(angle) * graph_radius,
			sin(angle) * graph_radius,
			0.0
		)


# ------------------------------------------------------------------
# Ring lattice — connect each node to k nearest neighbors on each side
# ------------------------------------------------------------------

func _build_ring_lattice() -> void:
	_edges.clear()
	_edge_is_rewired.clear()
	_adjacency.clear()
	_adjacency.resize(node_count)
	for i in range(node_count):
		_adjacency[i] = {}

	# Connect each node to k_neighbors on each side (total 2*k connections)
	for i in range(node_count):
		for j in range(1, k_neighbors / 2 + 1):
			var neighbor = (i + j) % node_count
			if not _adjacency[i].has(neighbor):
				_add_edge(i, neighbor, false)


func _add_edge(a: int, b: int, rewired: bool) -> void:
	_edges.append(Vector2i(a, b))
	_edge_is_rewired.append(rewired)
	_adjacency[a][b] = true
	_adjacency[b][a] = true


func _remove_edge_at(idx: int) -> void:
	var e = _edges[idx]
	_adjacency[e.x].erase(e.y)
	_adjacency[e.y].erase(e.x)
	_edges.remove_at(idx)
	_edge_is_rewired.remove_at(idx)


# ------------------------------------------------------------------
# Watts-Strogatz rewiring
# ------------------------------------------------------------------

func _rewire_network() -> void:
	# Rebuild from scratch — ring lattice then rewire
	_build_ring_lattice()

	if _rewire_probability <= 0.0:
		return

	# Iterate over original edges and rewire with probability p
	# We iterate by index carefully since we modify the list
	var edge_count = _edges.size()
	var i = 0
	while i < edge_count:
		if _rng.randf() < _rewire_probability:
			var e = _edges[i]
			var u = e.x
			var v = e.y

			# Pick a random new target for u (not self, not existing neighbor)
			var new_target = -1
			var attempts = 0
			while attempts < 50:
				var candidate = _rng.randi_range(0, node_count - 1)
				if candidate != u and not _adjacency[u].has(candidate):
					new_target = candidate
					break
				attempts += 1

			if new_target >= 0:
				# Remove old edge, add rewired one
				_adjacency[u].erase(v)
				_adjacency[v].erase(u)
				_edges[i] = Vector2i(u, new_target)
				_edge_is_rewired[i] = true
				_adjacency[u][new_target] = true
				_adjacency[new_target][u] = true
		i += 1


# ------------------------------------------------------------------
# Graph metrics — BFS path lengths + clustering coefficient
# ------------------------------------------------------------------

func _compute_avg_path_length() -> float:
	var total_dist: int = 0
	var pair_count: int = 0

	for source in range(node_count):
		var dist = _bfs_distances(source)
		for target in range(source + 1, node_count):
			if dist[target] >= 0:
				total_dist += dist[target]
				pair_count += 1

	if pair_count == 0:
		return 0.0
	return float(total_dist) / float(pair_count)


func _bfs_distances(source: int) -> Array:
	var dist: Array = []
	dist.resize(node_count)
	for i in range(node_count):
		dist[i] = -1
	dist[source] = 0

	var queue: Array = [source]
	var head: int = 0
	while head < queue.size():
		var u = queue[head]
		head += 1
		for v in _adjacency[u]:
			if dist[v] < 0:
				dist[v] = dist[u] + 1
				queue.append(v)
	return dist


func _compute_clustering_coefficient() -> float:
	var total_cc: float = 0.0

	for i in range(node_count):
		var neighbors = _adjacency[i].keys()
		var deg = neighbors.size()
		if deg < 2:
			continue

		var triangles: int = 0
		for a_idx in range(deg):
			for b_idx in range(a_idx + 1, deg):
				if _adjacency[neighbors[a_idx]].has(neighbors[b_idx]):
					triangles += 1

		var possible = deg * (deg - 1) / 2
		total_cc += float(triangles) / float(possible)

	return total_cc / float(node_count)


# ------------------------------------------------------------------
# Node visuals — spheres colored by degree
# ------------------------------------------------------------------

func _create_node_visuals() -> void:
	var sphere = SphereMesh.new()
	sphere.radius = node_radius
	sphere.height = node_radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6

	for i in range(node_count):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = _color_node_low
		mat.emission_enabled = true
		mat.emission = _color_node_low * 0.4
		mat.emission_energy_multiplier = 0.6
		mat.roughness = 0.3

		var mi = MeshInstance3D.new()
		mi.mesh = sphere
		mi.position = _node_positions[i]
		mi.material_override = mat
		add_child(mi)

		_node_meshes.append(mi)
		_node_materials.append(mat)


func _update_node_colors() -> void:
	# Color by degree — min degree is k_neighbors (ring), max could be higher
	var min_deg = 999
	var max_deg = 0
	for i in range(node_count):
		var deg = _adjacency[i].size()
		min_deg = mini(min_deg, deg)
		max_deg = maxi(max_deg, deg)

	var deg_range = max_deg - min_deg
	if deg_range == 0:
		deg_range = 1

	for i in range(node_count):
		var deg = _adjacency[i].size()
		var t = float(deg - min_deg) / float(deg_range)
		var col = _color_node_low.lerp(_color_node_high, t)
		_node_materials[i].albedo_color = col
		_node_materials[i].emission = col * 0.4


# ------------------------------------------------------------------
# Edge visuals — ImmediateMesh, gray=regular, yellow=rewired
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

	for idx in range(_edges.size()):
		var e = _edges[idx]
		var col = _color_rewired if _edge_is_rewired[idx] else _color_regular
		im.surface_set_color(col)
		im.surface_add_vertex(_node_positions[e.x])
		im.surface_set_color(col)
		im.surface_add_vertex(_node_positions[e.y])

	im.surface_end()
	_edge_mesh.mesh = im


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "SMALL WORLD NETWORK"
	_title_label.font_size = 18
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, graph_radius + 0.07, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.88, 0.9, 0.95)
	_title_label.outline_size = 3
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.font_size = 14
	_stats_label.pixel_size = 0.001
	_stats_label.position = Vector3(0, -(graph_radius + 0.06), 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.modulate = Color(0.72, 0.75, 0.82)
	_stats_label.outline_size = 2
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_stats_label)


func _update_stats() -> void:
	var avg_L = _compute_avg_path_length()
	var C = _compute_clustering_coefficient()
	_stats_label.text = "p = %.2f   L = %.2f   C = %.3f" % [_rewire_probability, avg_L, C]
	_update_node_colors()
	_rebuild_edges()


# ------------------------------------------------------------------
# VR Controls — rewire probability slider + rewire button
# ------------------------------------------------------------------

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("SMALL WORLD", [
		[{"type": "slider_h", "label": "p", "default": _rewire_probability}],
		[{"type": "button", "label": "REWIRE"}],
	])
	_control_panel.position = Vector3(0, -(graph_radius + 0.13), 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	_p_slider = _control_panel.find_child("Param_0", true, false)
	if _p_slider and _p_slider.has_signal("slider_moved"):
		_p_slider.slider_moved.connect(_on_p_slider)

	var rewire_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if rewire_btn:
		var area: Node = rewire_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _do_rewire())


func _on_p_slider(_pos) -> void:
	if _p_slider and _p_slider.has_method("get_normalized_value"):
		_rewire_probability = _p_slider.get_normalized_value()
		_do_rewire()


func _do_rewire() -> void:
	_rng.seed = hash("small_world") + randi() % 10000
	_rewire_network()
	_update_stats()


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("node_count"):
		node_count = int(config_data["node_count"])
	if config_data.has("k_neighbors"):
		k_neighbors = int(config_data["k_neighbors"])
	if config_data.has("rewire_probability"):
		_rewire_probability = float(config_data["rewire_probability"])
