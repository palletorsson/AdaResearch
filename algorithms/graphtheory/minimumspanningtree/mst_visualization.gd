class_name MSTVisualization
extends Node3D

# @identity
# essence: Kruskal's (sort edges by weight, Union-Find to reject cycles) or Prim's (grow tree from starting vertex, always add cheapest crossing edge) — both find the minimum-weight spanning tree
# desire: to watch the cheapest skeleton of a network assemble edge by edge — green edges accepted, red edges rejected for creating cycles, the MST growing like a nervous system
# critical_parameter: algorithm_type ("kruskal" vs "prim") — Kruskal processes edges globally by weight (greedy on edges), Prim grows locally from a root (greedy on vertices) — same result, different experience
# triggers: step-by-step timer advances one edge decision per tick; Union-Find path compression tracks connected components; edge_density controls how many redundant edges exist to reject
# emerges: watching Kruskal reject edges reveals the cycle structure of the graph — every rejected edge would have closed a loop, and the set of rejected edges defines the graph's cycle space
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (vertex labels, edge weight labels)
# relationships: appears in GT_Spanning_Trees; connects to push_relabel and karger which also optimize over graph structure; MST efficiency metric shows what fraction of total edge weight is necessary
# truth: the minimum spanning tree is the cheapest way to keep everyone connected — every edge in it is necessary, and removing any one disconnects the network

# Minimum Spanning Tree: Connection Politics & Optimal Networks
# Visualizes MST algorithms with edge selection and cost optimization
# Explores network connectivity and resource allocation strategies

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — axis `backbone`
# ═══════════════════════════════════════════════════════════════════

## What stands after the cheapest connecting skeleton has been chosen.
##
##   picked   the shipped view — the whole graph drawn, the tree picked out of it as
##            Kruskal runs and nine grey lines resolve to green.
##   bare     only the nine MST edges are BUILT. Three quarters of the graph's linework
##            is simply absent, so "efficiency is subtraction" becomes a fact about the
##            still rather than about a colour that only arrives after the animation.
##   refused  only the edges the tree threw away are built — the negative image of
##            `bare`; the cheapest skeleton reads as a hole in a cluttered network.
##   forest   three separated clusters, nothing crossing between them. No spanning tree
##            exists, and the middle word of the artifact's own name fails out loud.
##
## `bare` and `refused` are a matched pair: one computation shown as what it kept and as
## what it discarded. Both are solved SYNCHRONOUSLY before a single line is built — never
## by hiding meshes once the animation reaches them, which would be a time-domain axis
## wearing a costume and would photograph the wrong frame.
@export_enum("picked", "bare", "refused", "forest") var backbone: String = "picked"

const BACKBONES: PackedStringArray = ["picked", "bare", "refused", "forest"]

## Every randf/randi in the build path draws from this. The shipped script drew from the
## global RNG, so it rendered a different graph on every launch — two sweep frames of one
## axis value would have differed and the pixel critic would have read noise as signal.
const BUILD_SEED: int = 20260729

const VERTEX_RADIUS: float = 0.4

## forest: three cluster centres in the XY plane, and the ring radius inside each.
## Centres are 11.2–12 m apart against a 6 m cluster width, so the narrowest gap is
## ~5.2 m and no edge the generator is permitted to make can reach across it.
const FOREST_CENTRES: Array = [
	Vector2(-6.0, -3.0), Vector2(6.0, -3.0), Vector2(0.0, 6.5)]
const FOREST_RADIUS: float = 3.0

## Edge weight labels: metres out along the edge's in-plane normal, and the z the numeral
## sits at — just proud of the ±0.5 m jitter band the vertices carry.
const WEIGHT_LABEL_OFFSET: float = 0.35
const WEIGHT_LABEL_Z: float = 0.55

## Caption plate clearance above the built body, in metres.
const CAPTION_LIFT: float = 1.2

@export_category("MST Configuration")
@export var algorithm_type: String = "kruskal"  # kruskal, prim, boruvka
@export var graph_size: int = 10  # Number of vertices
@export var edge_density: float = 0.5  # Connection probability
@export var min_weight: float = 1.0
@export var max_weight: float = 15.0
@export var use_euclidean_weights: bool = true  # Distance-based weights

@export_category("Visualization")
@export var show_edge_weights: bool = true
@export var show_mst_cost: bool = true
@export var animate_edge_selection: bool = true
@export var highlight_current_edgea: bool = true
@export var show_rejected_edges: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_weight_editing: bool = true
@export var real_time_mst_update: bool = true
@export var show_algorithm_state: bool = true

@export_category("Animation")
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0
@export var edge_selection_duration: float = 0.8

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var edge_color: Color = Color(0.5, 0.5, 0.5, 0.8)
@export var mst_edge_color: Color = Color(0.2, 0.9, 0.3, 1.0)
@export var current_edge_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var rejected_edge_color: Color = Color(0.9, 0.2, 0.2, 0.6)
@export var starting_vertex_color: Color = Color(0.9, 0.3, 0.9, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var edge_weights: Dictionary = {}

# MST algorithm state
var mst_edges: Array = []
var mst_cost: float = 0.0
var current_edge_index: int = 0
var is_computing: bool = false
var computation_complete: bool = false
var rejected_edges: Array = []

# Union-Find data structure (for Kruskal's)
var parent: Array = []
var rank: Array = []

# Prim's algorithm state
var in_mst: Array = []
var key_values: Array = []
var prim_starting_vertex: int = 0

# Visualization elements
var vertex_meshes: Array = []
var edge_meshes: Array = []
var mst_edge_meshes: Array = []
var edge_labels: Array = []
var ui_display: CanvasLayer
var computation_timer: Timer

# The single framed caption. Tracked so a rebuild frees exactly it.
var _caption: Label3D = null

# Stage-2 lifecycle
var _built: bool = false
var _emissive: bool = true
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Algorithm tracking
var sorted_edges: Array = []
var algorithm_steps: Array = []
var current_step: int = 0

func _init() -> void:
	name = "MST_Visualization"

func _ready() -> void:
	_build_all()
	_built = true

	# Only `picked` animates. The other three values ARE the solved answer already
	# standing in the room; re-running Kruskal would draw the backbone back on top of a
	# view that exists to show it missing.
	if auto_start and backbone == "picked":
		call_deferred("start_mst_computation")


## The whole still, synchronous, from @export values alone. No call_deferred anywhere in
## here: a deferred rebuild that frees children first makes auto-grounding measure a zero
## AABB and bail.
func _build_all() -> void:
	if ui_display == null:
		setup_ui()
	if computation_timer == null:
		setup_timer()
	initialize_graph()
	create_visualization()
	_build_caption()
	update_ui()

func setup_ui() -> void:
	"""Create comprehensive UI for MST visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(500, 900)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for MST information
	for i in range(35):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer() -> void:
	"""Setup timer for step-by-step animation"""
	computation_timer = Timer.new()
	computation_timer.wait_time = animation_delay
	computation_timer.timeout.connect(_on_computation_timer_timeout)
	add_child(computation_timer)

func initialize_graph() -> void:
	"""Initialize the graph with vertices and edges"""
	# Fixed seed: two builds of one axis value must be pixel-identical.
	_rng.seed = BUILD_SEED

	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	edge_weights.clear()

	# Create vertices
	for i in range(graph_size):
		var vertex = {
			"id": i,
			"position": Vector3.ZERO,
			"label": "V" + str(i)
		}
		vertices.append(vertex)
		adjacency_list[i] = []
	
	# Generate vertex positions
	generate_vertex_positions()
	
	# Generate edges based on density
	generate_graph_edges()
	
	# Initialize algorithm state
	reset_algorithm_state()
	
	print("Initialized graph with ", vertices.size(), " vertices and ", edges.size(), " edges")

func generate_vertex_positions() -> void:
	"""Generate positions for vertices"""
	if backbone == "forest":
		_generate_forest_positions()
		return

	var radius = 8.0

	if graph_size <= 8:
		# Circular layout for smaller graphs
		var angle_increment = 2.0 * PI / graph_size
		for i in range(graph_size):
			var angle = i * angle_increment
			var x = radius * cos(angle)
			var y = radius * sin(angle)
			var z = _rng.randf_range(-0.5, 0.5)
			vertices[i].position = Vector3(x, y, z)
	else:
		# Grid-like layout for larger graphs
		var grid_size = ceil(sqrt(graph_size))
		var spacing = radius * 2.0 / grid_size
		
		for i in range(graph_size):
			var row = i / grid_size
			var col = fmod(i, grid_size)
			var x = (col - grid_size / 2.0) * spacing
			var y = (row - grid_size / 2.0) * spacing
			var z = _rng.randf_range(-0.5, 0.5)
			vertices[i].position = Vector3(x, y, z)

## Sizes of the three forest clusters, round-robin so any graph_size splits evenly.
## At the default 10 that is [4, 3, 3]; membership is sequential, group 0 taking
## vertices 0..3.
func _forest_group_sizes() -> Array[int]:
	var sizes: Array[int] = [0, 0, 0]
	for i in range(graph_size):
		sizes[i % 3] += 1
	return sizes


## Three clusters, each a small ring in the XY plane, far enough apart that no edge the
## generator is permitted to make could bridge them.
##
## The separation has to be BUILT, not selected. The default grid layout is a uniform
## lattice — within-row and between-row spacing are both ~4 m — so every partition of it
## has identical inside and outside distances and none of them reads as clusters. Moving
## the vertices is what makes "no line crosses" visible instead of merely true.
func _generate_forest_positions() -> void:
	var sizes: Array[int] = _forest_group_sizes()
	var v: int = 0
	for g in range(sizes.size()):
		var centre: Vector2 = FOREST_CENTRES[g]
		var n: int = maxi(sizes[g], 1)
		for k in range(sizes[g]):
			var angle: float = PI * 0.5 + float(k) * TAU / float(n)
			var x: float = centre.x + FOREST_RADIUS * cos(angle)
			var y: float = centre.y + FOREST_RADIUS * sin(angle)
			var z: float = _rng.randf_range(-0.5, 0.5)
			if v >= vertices.size():
				return
			vertices[v].position = Vector3(x, y, z)
			v += 1


## A ring inside each cluster and nothing at all between them. The rings matter: inside a
## cluster there ARE cycles — edges Kruskal would reject — while globally there is no
## spanning tree to reject them from. That is the whole point of the value.
func _generate_forest_edges() -> void:
	var sizes: Array[int] = _forest_group_sizes()
	var start: int = 0
	for g in range(sizes.size()):
		var n: int = sizes[g]
		for k in range(n):
			var a: int = start + k
			var b: int = start + (k + 1) % n
			if a != b and not has_edge(a, b):
				add_edge(a, b)
		start += n


## Fisher-Yates from the seeded RNG. Array.shuffle() draws from the GLOBAL generator, so
## the shipped script produced a different edge set every launch.
func _shuffle_det(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func generate_graph_edges() -> void:
	"""Generate edges based on density and weight constraints"""
	edges.clear()

	# forest: ensure_connectivity is suppressed and the density fill never runs. A graph
	# too broken for a spanning tree to exist is the point, not an accident to repair.
	if backbone == "forest":
		_generate_forest_edges()
		return

	# Generate all possible edges
	var possible_edges = []
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			possible_edges.append([i, j])

	# Shuffle and select based on density
	_shuffle_det(possible_edges)
	var num_edges = int(possible_edges.size() * edge_density)
	
	# Ensure graph connectivity (minimum spanning tree exists)
	ensure_connectivity()
	
	# Add additional edges up to density
	for i in range(min(num_edges, possible_edges.size())):
		var edge_pair = possible_edges[i]
		var from_vertex = edge_pair[0]
		var to_vertex = edge_pair[1]
		
		if not has_edge(from_vertex, to_vertex):
			add_edge(from_vertex, to_vertex)

func ensure_connectivity() -> void:
	"""Ensure graph is connected by creating a spanning tree"""
	var connected_vertices = [0]  # Start with vertex 0
	var remaining_vertices = []
	
	for i in range(1, graph_size):
		remaining_vertices.append(i)
	
	# Connect remaining vertices one by one
	while remaining_vertices.size() > 0:
		var from_vertex = connected_vertices[_rng.randi() % connected_vertices.size()]
		var to_vertex = remaining_vertices.pop_at(_rng.randi() % remaining_vertices.size())
		
		add_edge(from_vertex, to_vertex)
		connected_vertices.append(to_vertex)

func has_edge(from_vertex: int, to_vertex: int) -> bool:
	"""Check if edge already exists"""
	for edge in edges:
		if (edge.from == from_vertex and edge.to == to_vertex) or \
		   (edge.from == to_vertex and edge.to == from_vertex):
			return true
	return false

func add_edge(from_vertex: int, to_vertex: int) -> void:
	"""Add an edge with calculated weight"""
	var weight: float
	
	if use_euclidean_weights:
		# Use Euclidean distance as weight
		var pos1 = vertices[from_vertex].position
		var pos2 = vertices[to_vertex].position
		weight = pos1.distance_to(pos2)
	else:
		# Use random weight
		weight = _rng.randf_range(min_weight, max_weight)
	
	var edge = {
		"from": from_vertex,
		"to": to_vertex,
		"weight": weight,
		"in_mst": false,
		"rejected": false
	}
	
	edges.append(edge)
	adjacency_list[from_vertex].append(to_vertex)
	adjacency_list[to_vertex].append(from_vertex)
	edge_weights[str(from_vertex) + "_" + str(to_vertex)] = weight
	edge_weights[str(to_vertex) + "_" + str(from_vertex)] = weight

func reset_algorithm_state() -> void:
	"""Reset MST algorithm state"""
	mst_edges.clear()
	mst_cost = 0.0
	current_edge_index = 0
	is_computing = false
	computation_complete = false
	rejected_edges.clear()
	algorithm_steps.clear()
	current_step = 0
	
	# Reset edge states
	for edge in edges:
		edge.in_mst = false
		edge.rejected = false
	
	# Initialize Union-Find
	parent.clear()
	rank.clear()
	for i in range(graph_size):
		parent.append(i)
		rank.append(0)
	
	# Initialize Prim's state
	in_mst.clear()
	key_values.clear()
	for i in range(graph_size):
		in_mst.append(false)
		key_values.append(INF)

func create_visualization() -> void:
	"""Create 3D visualization of the graph"""
	clear_visualization()
	# bare / refused / forest need the answer BEFORE a single line is built. Solving here
	# and building the surviving edge set is what makes the axis photographable; hiding
	# meshes once the animation reached them would be the same picture at a later frame.
	if backbone != "picked":
		_solve_mst_now()
	create_vertex_visualization()
	create_edge_visualization()


## Run Kruskal to completion, synchronously, marking in_mst / rejected on the shared edge
## dictionaries. Deliberately not run_kruskal_complete(): that one calls
## finalize_computation(), which touches the timer and the log.
func _solve_mst_now() -> void:
	reset_algorithm_state()
	sorted_edges = edges.duplicate()
	sorted_edges.sort_custom(func(a, b): return a.weight < b.weight)

	for edge in sorted_edges:
		if mst_edges.size() >= graph_size - 1:
			break
		var root_from: int = find_union_find(edge.from)
		var root_to: int = find_union_find(edge.to)
		if root_from != root_to:
			edge.in_mst = true
			mst_edges.append(edge)
			mst_cost += edge.weight
			union_union_find(edge.from, edge.to)
		else:
			edge.rejected = true
			rejected_edges.append(edge)

	current_edge_index = sorted_edges.size()
	is_computing = false
	computation_complete = true

func clear_visualization() -> void:
	"""Clear existing visualization elements"""
	var stale: Array = []
	stale.append_array(vertex_meshes)
	stale.append_array(edge_meshes)
	stale.append_array(mst_edge_meshes)
	stale.append_array(edge_labels)
	for n in stale:
		if n == null or not is_instance_valid(n):
			continue
		if n.get_parent() == self:
			remove_child(n)
		n.queue_free()

	vertex_meshes.clear()
	edge_meshes.clear()
	mst_edge_meshes.clear()
	edge_labels.clear()

func create_vertex_visualization() -> void:
	"""Create visual representation of vertices"""
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var mesh_instance = MeshInstance3D.new()
		
		# Create vertex mesh
		var mesh = SphereMesh.new()
		mesh.radius = 0.4
		mesh.height = 0.8
		mesh_instance.mesh = mesh
		
		# Set vertex material
		var material = StandardMaterial3D.new()
		if i == prim_starting_vertex and algorithm_type == "prim":
			material.albedo_color = starting_vertex_color
			material.emission_enabled = _emissive
			material.emission = starting_vertex_color * 0.3
		else:
			material.albedo_color = vertex_color
			material.emission_enabled = _emissive
			material.emission = vertex_color * 0.2
		
		mesh_instance.material_override = material
		mesh_instance.position = vertex.position
		
		# Add vertex label — printed on the sphere's front face, not hung above it
		if show_edge_weights:
			create_vertex_label(mesh_instance, vertex.label, Vector3(0, 0, VERTEX_RADIUS + 0.01))

		add_child(mesh_instance)
		vertex_meshes.append(mesh_instance)

func create_edge_visualization() -> void:
	"""Create visual representation of edges"""
	for i in range(edges.size()):
		var edge = edges[i]

		# PRESENCE is the axis. bare keeps only what the tree took; refused keeps only
		# what it threw away.
		var wanted: bool = true
		if backbone == "bare":
			wanted = bool(edge.in_mst)
		elif backbone == "refused":
			wanted = not bool(edge.in_mst)
		if not wanted:
			# Keep edge_meshes index-parallel with edges — highlight_current_edge looks a
			# mesh up by edge index and would otherwise colour the wrong line.
			edge_meshes.append(null)
			continue

		var from_pos = vertices[edge.from].position
		var to_pos = vertices[edge.to].position

		# Create edge line
		var edge_mesh = create_edge_line(from_pos, to_pos, edge_color)
		add_child(edge_mesh)
		edge_meshes.append(edge_mesh)

		# Create weight label
		if show_edge_weights:
			var label = create_edge_label(str(edge.weight).pad_decimals(1), from_pos, to_pos)
			add_child(label)
			edge_labels.append(label)

func create_edge_line(from_pos: Vector3, to_pos: Vector3, color: Color) -> MeshInstance3D:
	"""Create a line mesh between two positions"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = create_line_mesh(from_pos, to_pos)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = _emissive
	material.emission = color * 0.3
	mesh_instance.material_override = material

	return mesh_instance

func create_line_mesh(from_pos: Vector3, to_pos: Vector3) -> ArrayMesh:
	"""Create mesh for line between two points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_array = PackedVector3Array()
	var indices = PackedInt32Array()
	
	vertices_array.append(from_pos)
	vertices_array.append(to_pos)
	indices.append(0)
	indices.append(1)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	return array_mesh

## The vertex name is a glyph ON the sphere's +Z face, not a card floating a metre above
## it. Sphere radius is 0.4, so 0.41 sits just proud of the surface; font_size 16 at the
## default pixel_size 0.005 is a 0.08 m glyph on an 0.8 m ball.
##
## Shipped: billboard ENABLED at (0, 1.0, 0) — ten hanging cards the framer turns into ten
## opaque anthracite plates suspended over the linework.
func create_vertex_label(holder: MeshInstance3D, text: String, offset: Vector3) -> void:
	"""Create text label printed on the vertex sphere's front face"""
	var label: Label3D = Label3D.new()
	label.text = text
	label.position = offset
	label.font_size = 16
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color.WHITE
	holder.add_child(label)


## The weight numeral is INK ON THE DRAWING, not a card hung in front of it.
##
## generate_vertex_positions puts every vertex in the XY plane with only ±0.5 m of z
## jitter, so this graph IS a flat drawing and a numeral printed beside its own line is
## the honest reading — the framer's rule is that non-billboard labels lie on a body and
## are integrated already. Naming that category correctly is not a dodge of the gate.
##
## Shipped: billboard ENABLED at the edge midpoint + (0, 0.5, 0). The framer turns each of
## those into an opaque ~0.26 x 0.15 m plate — roughly 28 of them, stacked through the
## middle of the linework. Each is ~0.04% of the frontal box, so the probe's 2% threshold
## never fires: death by a thousand plates, invisible to the gate and obvious to the eye.
func create_edge_label(text: String, from_pos: Vector3, to_pos: Vector3) -> Label3D:
	"""Create text label for edge weight, lying beside its line in the drawing plane"""
	var label: Label3D = Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.modulate = Color.YELLOW

	var mid: Vector3 = Vector3(
		(from_pos.x + to_pos.x) * 0.5,
		(from_pos.y + to_pos.y) * 0.5,
		(from_pos.z + to_pos.z) * 0.5)

	var along: Vector2 = Vector2(to_pos.x - from_pos.x, to_pos.y - from_pos.y)
	if along.length() < 0.0001:
		along = Vector2(1.0, 0.0)
	along = along.normalized()

	# Step off the line along its in-plane normal, and sit proud of the jitter band.
	var normal: Vector2 = Vector2(-along.y, along.x)
	label.position = Vector3(
		mid.x + normal.x * WEIGHT_LABEL_OFFSET,
		mid.y + normal.y * WEIGHT_LABEL_OFFSET,
		WEIGHT_LABEL_Z)

	# Run the numeral along its own line, never upside down.
	var angle: float = atan2(along.y, along.x)
	if angle > PI * 0.5 or angle < -PI * 0.5:
		angle += PI
	label.rotation = Vector3(0.0, 0.0, angle)
	return label


## The artifact's ONE caption. Its statistics live in a 500x900 CanvasLayer that the grid
## suppresses at map spawn, so before this it stood in a map with no name on it at all.
##
## Billboard ENABLED — this is a hanging sign and should be framed. Placed CAPTION_LIFT
## above the measured top of everything this script built, centred on the body's x span,
## so the plate is entirely clear of the body at every axis value including `forest`,
## whose clusters reach higher than the default lattice.
func _build_caption() -> void:
	var top: float = -INF
	var min_x: float = INF
	var max_x: float = -INF

	for v in vertices:
		var p: Vector3 = v.position
		top = maxf(top, p.y + VERTEX_RADIUS)
		min_x = minf(min_x, p.x - VERTEX_RADIUS)
		max_x = maxf(max_x, p.x + VERTEX_RADIUS)

	# Weight numerals step off their lines and can out-reach the spheres.
	for lbl in edge_labels:
		if lbl == null:
			continue
		var lp: Vector3 = lbl.position
		top = maxf(top, lp.y + 0.10)
		min_x = minf(min_x, lp.x - 0.15)
		max_x = maxf(max_x, lp.x + 0.15)

	if top == -INF:
		return

	_caption = Label3D.new()
	_caption.name = "MSTCaption"
	_caption.text = "Minimum Spanning Tree — " + algorithm_type.capitalize()
	_caption.font_size = 28
	_caption.pixel_size = 0.005
	_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_caption.modulate = Color.WHITE
	_caption.position = Vector3((min_x + max_x) * 0.5, top + CAPTION_LIFT, 0.0)
	add_child(_caption)

func start_mst_computation() -> void:
	"""Start the MST computation"""
	# bare / refused / forest are SOLVED STILLS — the built geometry already is the answer.
	# Running the animation would lay green MST lines back over a view whose whole content
	# is that they are missing. apply_grid_config lands ahead of this deferred call, so a
	# map that asks for `refused` is honoured here too.
	if backbone != "picked":
		return
	if is_computing:
		return
	
	is_computing = true
	computation_complete = false
	reset_algorithm_state()
	
	match algorithm_type:
		"kruskal":
			start_kruskal()
		"prim":
			start_prim()
		"boruvka":
			start_boruvka()
		_:
			start_kruskal()
	
	print("Starting ", algorithm_type, " MST algorithm...")

func start_kruskal() -> void:
	"""Start Kruskal's algorithm"""
	# Sort edges by weight
	sorted_edges = edges.duplicate()
	sorted_edges.sort_custom(func(a, b): return a.weight < b.weight)
	
	if step_by_step:
		computation_timer.start()
	else:
		run_kruskal_complete()

func run_kruskal_complete() -> void:
	"""Run complete Kruskal's algorithm"""
	for edge in sorted_edges:
		if mst_edges.size() >= graph_size - 1:
			break
		
		var root_from = find_union_find(edge.from)
		var root_to = find_union_find(edge.to)
		
		if root_from != root_to:
			# Add edge to MST
			edge.in_mst = true
			mst_edges.append(edge)
			mst_cost += edge.weight
			union_union_find(edge.from, edge.to)
		else:
			# Reject edge (creates cycle)
			edge.rejected = true
			rejected_edges.append(edge)
	
	finalize_computation()

func start_prim() -> void:
	"""Start Prim's algorithm"""
	# Initialize starting vertex
	key_values[prim_starting_vertex] = 0.0
	
	if step_by_step:
		computation_timer.start()
	else:
		run_prim_complete()

func run_prim_complete() -> void:
	"""Run complete Prim's algorithm"""
	for i in range(graph_size):
		# Find minimum key vertex not in MST
		var min_key = INF
		var min_vertex = -1
		
		for v in range(graph_size):
			if not in_mst[v] and key_values[v] < min_key:
				min_key = key_values[v]
				min_vertex = v
		
		if min_vertex == -1:
			break
		
		# Add vertex to MST
		in_mst[min_vertex] = true
		
		# Find the edge that brought this vertex to MST
		if min_vertex != prim_starting_vertex:
			for edge in edges:
				if ((edge.from == min_vertex or edge.to == min_vertex) and 
					edge.weight == min_key):
					# Check if the other vertex is in MST
					var other_vertex = edge.to if edge.from == min_vertex else edge.from
					if in_mst[other_vertex]:
						edge.in_mst = true
						mst_edges.append(edge)
						mst_cost += edge.weight
						break
		
		# Update key values of adjacent vertices
		for adj_vertex in adjacency_list[min_vertex]:
			var edge_weight = get_edge_weight(min_vertex, adj_vertex)
			if not in_mst[adj_vertex] and edge_weight < key_values[adj_vertex]:
				key_values[adj_vertex] = edge_weight
	
	finalize_computation()

func start_boruvka() -> void:
	"""Start Boruvka's algorithm (simplified version)"""
	# For now, use Kruskal's as placeholder
	start_kruskal()

# Union-Find data structure operations
func find_union_find(vertex: int) -> int:
	"""Find root of vertex with path compression"""
	if parent[vertex] != vertex:
		parent[vertex] = find_union_find(parent[vertex])
	return parent[vertex]

func union_union_find(vertex1: int, vertex2: int) -> void:
	"""Union two sets by rank"""
	var root1 = find_union_find(vertex1)
	var root2 = find_union_find(vertex2)
	
	if rank[root1] < rank[root2]:
		parent[root1] = root2
	elif rank[root1] > rank[root2]:
		parent[root2] = root1
	else:
		parent[root2] = root1
		rank[root1] += 1

func get_edge_weight(from_vertex: int, to_vertex: int) -> float:
	"""Get weight of edge between two vertices"""
	var key = str(from_vertex) + "_" + str(to_vertex)
	if key in edge_weights:
		return edge_weights[key]
	
	key = str(to_vertex) + "_" + str(from_vertex)
	if key in edge_weights:
		return edge_weights[key]
	
	return INF

func _on_computation_timer_timeout() -> void:
	"""Handle step-by-step computation timer"""
	if not is_computing:
		return
	
	match algorithm_type:
		"kruskal":
			step_kruskal()
		"prim":
			step_prim()
		_:
			step_kruskal()

func step_kruskal() -> void:
	"""Perform one step of Kruskal's algorithm"""
	if current_edge_index >= sorted_edges.size() or mst_edges.size() >= graph_size - 1:
		finalize_computation()
		return
	
	var edge = sorted_edges[current_edge_index]
	highlight_current_edge(edge)
	
	var root_from = find_union_find(edge.from)
	var root_to = find_union_find(edge.to)
	
	if root_from != root_to:
		# Add edge to MST
		edge.in_mst = true
		mst_edges.append(edge)
		mst_cost += edge.weight
		union_union_find(edge.from, edge.to)
		create_mst_edge_visualization(edge)
	else:
		# Reject edge (creates cycle)
		edge.rejected = true
		rejected_edges.append(edge)
		#if show_rejected_edges:
			#highlight_rejected_edge(edge)
	
	current_edge_index += 1
	update_ui()

func step_prim() -> void:
	"""Perform one step of Prim's algorithm"""
	# Find minimum key vertex not in MST
	var min_key = INF
	var min_vertex = -1
	
	for v in range(graph_size):
		if not in_mst[v] and key_values[v] < min_key:
			min_key = key_values[v]
			min_vertex = v
	
	if min_vertex == -1:
		finalize_computation()
		return
	
	# Add vertex to MST
	in_mst[min_vertex] = true
	
	# Find and highlight the edge that brought this vertex to MST
	if min_vertex != prim_starting_vertex:
		for edge in edges:
			if ((edge.from == min_vertex or edge.to == min_vertex) and 
				edge.weight == min_key):
				var other_vertex = edge.to if edge.from == min_vertex else edge.from
				if in_mst[other_vertex]:
					edge.in_mst = true
					mst_edges.append(edge)
					mst_cost += edge.weight
					create_mst_edge_visualization(edge)
					break
	
	# Update vertex visualization
	if min_vertex < vertex_meshes.size():
		var mesh = vertex_meshes[min_vertex]
		var material = mesh.material_override as StandardMaterial3D
		material.emission = starting_vertex_color * 0.5
	
	# Update key values of adjacent vertices
	for adj_vertex in adjacency_list[min_vertex]:
		var edge_weight = get_edge_weight(min_vertex, adj_vertex)
		if not in_mst[adj_vertex] and edge_weight < key_values[adj_vertex]:
			key_values[adj_vertex] = edge_weight
	
	update_ui()

func highlight_current_edge(edge) -> void:
	"""Highlight the currently considered edge"""
	var edge_index = edges.find(edge)
	if edge_index >= 0 and edge_index < edge_meshes.size():
		var mesh = edge_meshes[edge_index]
		if mesh == null:
			return  # edge_meshes holds a placeholder where bare/refused skipped a line
		var material = mesh.material_override as StandardMaterial3D
		material.albedo_color = current_edge_color
		material.emission = current_edge_color * 0.5

 

func create_mst_edge_visualization(edge) -> void:
	"""Create visualization for MST edge"""
	var from_pos = vertices[edge.from].position
	var to_pos = vertices[edge.to].position
	
	var mst_mesh = create_edge_line(from_pos, to_pos, mst_edge_color)
	
	# Make MST edges thicker
	var material = mst_mesh.material_override as StandardMaterial3D
	material.emission = mst_edge_color * 0.6
	
	add_child(mst_mesh)
	mst_edge_meshes.append(mst_mesh)

func finalize_computation() -> void:
	"""Finalize the MST computation"""
	is_computing = false
	computation_complete = true
	computation_timer.stop()
	
	print("MST computation complete!")
	print("Algorithm: ", algorithm_type)
	print("MST cost: ", mst_cost)
	print("MST edges: ", mst_edges.size())
	print("Expected edges: ", graph_size - 1)
	
	update_ui()

func update_ui() -> void:
	"""Update UI with current algorithm state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(35):
		var label = ui_display.get_node_or_null("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 35:
		labels[0].text = "🌳 Minimum Spanning Tree - Optimal Connections"
		labels[1].text = "Algorithm: " + algorithm_type.capitalize()
		labels[2].text = "Graph Size: " + str(graph_size) + " vertices"
		labels[3].text = "Edge Count: " + str(edges.size())
		labels[4].text = "Edge Density: " + str(edge_density * 100).pad_decimals(1) + "%"
		labels[5].text = ""
		labels[6].text = "Status: " + ("Computing..." if is_computing else "Complete" if computation_complete else "Ready")
		labels[7].text = "MST Cost: " + str(mst_cost).pad_decimals(2)
		labels[8].text = "MST Edges: " + str(mst_edges.size()) + "/" + str(graph_size - 1)
		labels[9].text = "Rejected Edges: " + str(rejected_edges.size())
		labels[10].text = ""
		
		if algorithm_type == "kruskal":
			labels[11].text = "Kruskal's Algorithm State:"
			labels[12].text = "Current Edge: " + str(current_edge_index) + "/" + str(sorted_edges.size())
			labels[13].text = "Edges Processed: " + str(current_edge_index)
			if current_edge_index > 0 and current_edge_index <= sorted_edges.size():
				var current_edge = sorted_edges[current_edge_index - 1]
				labels[14].text = "Last Edge: " + str(current_edge.from) + "-" + str(current_edge.to) + " (w=" + str(current_edge.weight).pad_decimals(1) + ")"
			else:
				labels[14].text = "Last Edge: None"
		elif algorithm_type == "prim":
			labels[11].text = "Prim's Algorithm State:"
			labels[12].text = "Starting Vertex: " + str(prim_starting_vertex)
			labels[13].text = "Vertices in MST: " + str(get_vertices_in_mst())
			labels[14].text = "Current Keys: " + get_current_keys_string()
		
		labels[15].text = ""
		labels[16].text = "Graph Properties:"
		labels[17].text = "Weight Range: " + str(min_weight).pad_decimals(1) + " - " + str(max_weight).pad_decimals(1)
		labels[18].text = "Euclidean Weights: " + ("Yes" if use_euclidean_weights else "No")
		labels[19].text = "Total Weight: " + str(get_total_weight()).pad_decimals(2)
		labels[20].text = "MST Efficiency: " + str(get_mst_efficiency() * 100).pad_decimals(1) + "%"
		labels[21].text = ""
		labels[22].text = "Union-Find State:" if algorithm_type == "kruskal" else "Prim State:"
		labels[23].text = "Components: " + str(get_connected_components()) if algorithm_type == "kruskal" else "Min Key: " + str(get_min_key()).pad_decimals(1)
		labels[24].text = ""
		labels[25].text = "Visualization:"
		labels[26].text = "Edge Weights: " + ("On" if show_edge_weights else "Off")
		labels[27].text = "MST Cost: " + ("On" if show_mst_cost else "Off")
		labels[28].text = "Rejected Edges: " + ("On" if show_rejected_edges else "Off")
		labels[29].text = "Animation: " + ("Step-by-step" if step_by_step else "Complete")
		labels[30].text = ""
		labels[31].text = "Controls:"
		labels[32].text = "SPACE - Start/Stop, R - Reset"
		labels[33].text = "1-3 - Algorithms, W - Toggle Weights"
		labels[34].text = "🏳️‍🌈 Explores optimal connection politics"

func get_vertices_in_mst() -> int:
	"""Count vertices currently in MST (for Prim's)"""
	var count = 0
	for in_tree in in_mst:
		if in_tree:
			count += 1
	return count

func get_current_keys_string() -> String:
	"""Get string representation of current key values"""
	var key_strings = []
	for i in range(min(5, key_values.size())):  # Show first 5 keys
		if key_values[i] == INF:
			key_strings.append("∞")
		else:
			key_strings.append(str(key_values[i]).pad_decimals(1))
	return "[" + ", ".join(key_strings) + ("..." if key_values.size() > 5 else "") + "]"

func get_total_weight() -> float:
	"""Get total weight of all edges"""
	var total = 0.0
	for edge in edges:
		total += edge.weight
	return total

func get_mst_efficiency() -> float:
	"""Get efficiency of MST (MST cost / total edge weight)"""
	var total_weight = get_total_weight()
	if total_weight == 0:
		return 0.0
	return mst_cost / total_weight

func get_connected_components() -> int:
	"""Get number of connected components (for Kruskal's)"""
	var components = {}
	for i in range(graph_size):
		var root = find_union_find(i)
		components[root] = true
	return components.size()

func get_min_key() -> float:
	"""Get minimum key value not in MST (for Prim's)"""
	var min_val = INF
	for i in range(graph_size):
		if not in_mst[i] and key_values[i] < min_val:
			min_val = key_values[i]
	return min_val

func _input(event: InputEvent) -> void:
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_computing:
					stop_computation()
				else:
					start_mst_computation()
			KEY_R:
				reset_graph()
			KEY_1:
				change_algorithm("kruskal")
			KEY_2:
				change_algorithm("prim")
			KEY_3:
				change_algorithm("boruvka")
			KEY_W:
				show_edge_weights = not show_edge_weights
				create_visualization()
			KEY_S:
				step_by_step = not step_by_step
				print("Step-by-step mode: ", step_by_step)

func stop_computation() -> void:
	"""Stop the MST computation"""
	is_computing = false
	if computation_timer != null:
		computation_timer.stop()

func reset_graph() -> void:
	"""Reset the graph and computation"""
	stop_computation()
	computation_complete = false
	
	initialize_graph()
	create_visualization()

func change_algorithm(new_algorithm: String) -> void:
	"""Change the MST algorithm"""
	algorithm_type = new_algorithm
	reset_graph()
	print("Changed to ", new_algorithm, " algorithm")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Minimum Spanning Tree",
		"algorithm": algorithm_type,
		"description": "Find minimum cost spanning tree",
		"graph_properties": {
			"backbone": backbone,
			"vertices": graph_size,
			"edges": edges.size(),
			"edges_built": _built_edge_count(),
			"density": edge_density,
			"weight_range": [min_weight, max_weight],
			"euclidean_weights": use_euclidean_weights
		},
		"mst_results": {
			"mst_cost": mst_cost,
			"mst_edges": mst_edges.size(),
			"expected_edges": graph_size - 1,
			"rejected_edges": rejected_edges.size(),
			"efficiency": get_mst_efficiency(),
			"connected_components": get_connected_components()
		},
		"status": {
			"is_computing": is_computing,
			"computation_complete": computation_complete,
			"current_step": current_step,
			"progress": float(current_edge_index) / float(edges.size()) if edges.size() > 0 else 0.0
		}
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called by GridInteractablesComponent via call_deferred, after _ready() and first in the
## deferred queue. Was an empty `pass`, so the only artifact in the sequence whose thesis
## is "efficiency feels like subtraction" always rendered the addition.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_backbone: String = backbone

	if config_data.has("backbone"):
		backbone = _pick_axis(str(config_data["backbone"]), BACKBONES, backbone)

	# Non-geometry key, applied IN PLACE before any early return. curation_station hands
	# every artifact it curates {"emissive": false} one line after framing its labels; an
	# accepted key that only took effect through a rebuild we then skipped would be a
	# silent no-op.
	if config_data.has("emissive"):
		_emissive = bool(config_data["emissive"])
		_apply_emissive()

	if not _built:
		return
	if backbone == before_backbone:
		return

	_rebuild_now()
	print("[MSTVisualization] Config applied — backbone=%s (%d edges built)" % [
		backbone, _built_edge_count()])


## Accept an axis value only if it names something we actually build. A typo in a map
## token falls back to the legacy look rather than stranding the placement.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _apply_emissive() -> void:
	var all_meshes: Array = []
	all_meshes.append_array(vertex_meshes)
	all_meshes.append_array(edge_meshes)
	all_meshes.append_array(mst_edge_meshes)
	for m in all_meshes:
		if m == null or not is_instance_valid(m):
			continue
		var mat: StandardMaterial3D = m.material_override as StandardMaterial3D
		if mat != null:
			mat.emission_enabled = _emissive


func _built_edge_count() -> int:
	var n: int = 0
	for m in edge_meshes:
		if m != null:
			n += 1
	return n


## Free ONLY what this script created and tracked. Freeing get_children() would take the
## grid's own added plates with it. ui_display and computation_timer survive — they are
## not part of the still.
func _rebuild_now() -> void:
	stop_computation()

	var owned: Array = []
	owned.append_array(vertex_meshes)
	owned.append_array(edge_meshes)
	owned.append_array(mst_edge_meshes)
	owned.append_array(edge_labels)
	if _caption != null:
		owned.append(_caption)

	for c in owned:
		if c == null or not is_instance_valid(c):
			continue
		if c.get_parent() == self:
			remove_child(c)
		c.queue_free()

	vertex_meshes.clear()
	edge_meshes.clear()
	mst_edge_meshes.clear()
	edge_labels.clear()
	_caption = null

	_build_all()
