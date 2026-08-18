class_name KosarajuAlgorithm
extends Node3D

# @identity
# essence: two-pass DFS — first pass on original graph records finish_times; second pass on transpose_adjacency_list processes vertices in reverse finish order, each new DFS tree is an SCC
# desire: to see the graph flip — the transpose reversal switches edge directions, and the fact that SCCs survive this reversal is the visual proof that mutual reachability is symmetric
# critical_parameter: mutuality — how much mutual reachability the digraph holds (pockets / none / split / total); edge_density still shapes the `pockets` draw, and the transpose graph is computed alongside the forward graph and drawn with distinct orange arrows in phase 2
# triggers: first_dfs_pass colors vertices as they finish (gray); second_dfs_pass processes the transpose in reverse finish order, coloring each SCC distinctly; phase_label tracks which pass is active
# emerges: watching the same graph from two directions reveals that SCCs are the invariant structure under edge reversal — what you can reach forward, you can also be reached from backward
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (info_label, phase_label, vertex labels)
# relationships: paired with tarjan_algorithm in GT_Connectivity — same problem, different strategy; the two-pass approach makes the transpose relationship explicit where Tarjan hides it in low_link; shares the `mutuality` axis with tarjan_algorithm and rhizomatic_structure
# truth: Kosaraju's algorithm proves that strongly connected components are the same in a graph and its transpose — mutual reachability is a symmetric property of directed structure

# Kosaraju's Algorithm: Strongly Connected Components
# Visualizes the two-pass DFS approach to finding strongly connected components
# Explores the relationship between original graph and its transpose

## The framer is preloaded, not class_name'd, so headless runs resolve it. It is only
## reached on a REBUILD that happened after the grid already framed this artifact —
## see _rebuild_now.
const LABEL_FRAMER = preload("res://commons/grid/LabelFramer.gd")

@export_category("Kosaraju Configuration")
@export var graph_size: int = 10  # Number of vertices
@export var edge_density: float = 0.4  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — mutuality
# ═══════════════════════════════════════════════════════════════════
#
# Kosaraju's claim is that strongly connected components SURVIVE TRANSPOSITION.
# That claim is only interesting when there is something to survive, and until now
# the artifact could only ever be asked one question: a bare `randf() < 0.4` double
# loop, unreachable from any map, on a graph where the answer is whatever the dice
# said. The two demonstrations the algorithm was built to give — a DAG, where the
# transpose flips every arrowhead and still yields ten singletons, and a single
# all-swallowing component, where it flips every arrowhead and still yields one —
# were both unreachable.
#
# `mutuality` names how much mutual reachability the directed structure holds.
# Same word, same ladder as tarjan_algorithm and rhizomatic_structure: one question
# asked three ways. The sizes here (4 m ring) sit deliberately inside Tarjan's 6 m
# so the two SCC artifacts stay distinguishable standing side by side in one map —
# the shared axis is about the question, not about making them twins.
#
# NOT A TIME AXIS. Nothing here varies how fast the traversal runs. Every value
# changes the STANDING ARRANGEMENT the algorithm is run on: where the vertices
# stand and which arrows exist between them.
@export_category("DNA")
## How much mutual reachability the directed graph holds — scattered small pockets,
## none at all, two large components, or one component swallowing everything.
@export_enum("pockets", "none", "split", "total") var mutuality: String = "pockets"

## Allow-list. A token outside it is a typo and must land on the shipped look
## rather than half-resolving into a staging with no edges.
const MUTUALITIES: PackedStringArray = ["pockets", "none", "split", "total"]

## Fixed seed. The `pockets` draw is random BY NATURE — that randomness is the
## shipped look — but two builds of one axis value have to be pixel-identical or
## the pixel critic reads dice as signal.
const GRAPH_SEED: int = 4820736

const VERTEX_RADIUS: float = 0.15

## pockets / total: one 4 m-diameter ring.
const RING_RADIUS: float = 2.0
## pockets: the shipped height jitter, +/-0.5 m.
const RING_JITTER: float = 0.5

## none: a rising line. 0.3 m of height per vertex — ten vertices span 0 .. 2.7 m —
## laid out across 4 m of x so the ramp reads as a ramp and not as a pole.
const LINE_STEP: float = 0.3
const LINE_HALF_X: float = 2.0

## split: two 1.6 m-diameter rings, centres 5 m apart, so the body spans 6.6 m.
const SPLIT_RADIUS: float = 0.8
const SPLIT_GAP: float = 5.0
const SPLIT_JITTER: float = 0.25

## total: the closed cycle is the perimeter; these are the chords laid across it.
## None of them duplicates a cycle edge (i -> i+1), so all six are new arrows.
const TOTAL_CHORDS: Array = [[0, 4], [1, 7], [2, 6], [3, 9], [5, 0], [8, 3]]

# ═══════════════════════════════════════════════════════════════════
# CAPTION PLACEMENT
# ═══════════════════════════════════════════════════════════════════
#
# Twelve Label3D nodes, and until now not one of them was framed — Label3D defaults
# to BILLBOARD_DISABLED and this script never set it, so LabelFramer skipped all
# twelve. Fixing that naively would have been a disaster: ten per-node captions
# hanging 0.4 m above ten 0.3 m spheres, each turning into its own opaque plate,
# would bury the graph under a mobile of cards.
#
# So the twelve split into two categories, and naming them correctly is the work.
#
# TEN VERTEX NAMES are ink on the node. Moved from (0, 0.4, 0) — a card floating
# above the sphere — onto the sphere's own face at (0, 0, 0.16), with
# BILLBOARD_DISABLED set EXPLICITLY. A 0.08 m glyph (font 16 x pixel_size 0.005) on
# a 0.30 m face. The framer's own rule is that a label lying on a body is already
# integrated and gets skipped; this is that case, not a dodge.
#
# TWO ROOT CAPTIONS are a nameplate, and here the merge is used ON PURPOSE. As
# authored, info_label (0, 4, 0) font 20 and phase_label (0, 3.5, 0) font 16 are
# 0.50 m apart — far outside MERGE_GAP (0.16) — so framing them would shingle TWO
# plates of different widths above the ring. Restacked to body_top + 0.30 and
# body_top + 0.19 they are 0.11 m apart in one column, which _plate_group merges
# into ONE panel. At the default (body top ~0.65 m) that puts the plate around
# 0.77 .. 1.03 m, clearing the body by roughly 0.12 m. The artifact should read as
# one object carrying a two-line nameplate, not as a graph orbited by two loose
# cards.
#
# body_top is DERIVED from the built AABB, never hard-coded: `none` raises the body
# to 2.85 m and `split` widens it to 6.6 m, and a fixed caption height would put the
# plate inside the ramp on one value and adrift on another.
const CAPTION_LIFT_TOP: float = 0.30
const CAPTION_LIFT_SECOND: float = 0.19

@export_category("Visualization")
@export var show_finish_times: bool = true
@export var show_transpose_graph: bool = true
@export var highlight_current_vertex: bool = true
@export var show_scc_colors: bool = true
@export var animate_dfs_traversal: bool = true
@export var show_stack_order: bool = true

## Whether the vertex and edge materials actually glow. Ships FALSE, which is
## exactly what the artifact has always rendered: it assigned `material.emission`
## without ever setting `emission_enabled`, so the emission was inert. Making it a
## real switch keeps the shipped look byte-for-byte and gives the curation station's
## `{"emissive": false}` something honest to land on.
@export var emissive: bool = false

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_edge_editing: bool = true
@export var real_time_scc_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var visited_color: Color = Color(0.9, 0.6, 0.2, 1.0)
@export var current_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var scc_color_1: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var scc_color_2: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var scc_color_3: Color = Color(0.2, 0.2, 0.9, 1.0)
@export var scc_color_4: Color = Color(0.9, 0.2, 0.9, 1.0)
@export var scc_color_5: Color = Color(0.2, 0.9, 0.9, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var transpose_edge_color: Color = Color(0.9, 0.5, 0.2, 0.8)
@export var finished_color: Color = Color(0.5, 0.5, 0.5, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var transpose_adjacency_list: Dictionary = {}

# Kosaraju's algorithm state
var visited: Dictionary = {}
var finish_times: Array = []
var scc_count: int = 0
var sccs: Array = []
var current_vertex: String = ""
var algorithm_running: bool = false
var algorithm_step: int = 0
var current_phase: String = "first_pass"  # first_pass, second_pass

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var transpose_edge_lines: Dictionary = {}
var scc_labels: Array = []
var info_label: Label3D
var phase_label: Label3D

## Every node THIS SCRIPT parented to self. A rebuild frees these and nothing else —
## get_children() would also carry away the grid's own plates and markers.
var _owned: Array[Node] = []
var _built: bool = false

func _ready() -> void:
	# The environment (light, world env, camera) is not part of the axis and is
	# never rebuilt, so it stays out of _owned.
	setup_environment()
	_build_all()
	_built = true

	if auto_start:
		call_deferred("start_algorithm")

## SYNCHRONOUS, from @export values alone. No call_deferred anywhere in here: a
## deferred build after children were removed makes the grid's auto-grounding
## measure a zero AABB and bail.
func _build_all() -> void:
	initialize_graph()
	create_visual_elements()

func setup_environment() -> void:
	# Add lighting
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	light.light_energy = 1.2
	add_child(light)

	# Add ambient lighting
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.background_mode = Environment.BG_COLOR
	add_child(ambient)

	# Add camera
	var camera := Camera3D.new()
	camera.name = "AlgorithmCamera"
	camera.position = Vector3(8.0, 6.0, 12.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)

func initialize_graph() -> void:
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	transpose_adjacency_list.clear()
	visited.clear()
	finish_times.clear()
	scc_count = 0
	sccs.clear()
	algorithm_running = false
	algorithm_step = 0
	current_phase = "first_pass"

	# Generate the graph the axis asks for
	generate_random_graph()

	# Initialize algorithm state
	for vertex in vertices:
		visited[vertex] = false

# ═══════════════════════════════════════════════════════════════════
# EDGE SETS — one per value of `mutuality`
# ═══════════════════════════════════════════════════════════════════

func generate_random_graph() -> void:
	# Create vertices
	for i in range(graph_size):
		var vertex: String = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []
		transpose_adjacency_list[vertex] = []

	match mutuality:
		"none":
			_edges_forward_dag()
		"split":
			_edges_two_blocks()
		"total":
			_edges_one_cycle()
		_:
			_edges_random()

## Both directions are recorded in one place, so a value that edits the edge set
## gets its transpose for free — which is the whole reason the axis can be honest
## about what survives reversal.
func _add_edge(i: int, j: int) -> void:
	var from_vertex: String = "v" + str(i)
	var to_vertex: String = "v" + str(j)
	if not adjacency_list.has(from_vertex) or not adjacency_list.has(to_vertex):
		return
	edges.append({"from": from_vertex, "to": to_vertex})
	adjacency_list[from_vertex].append(to_vertex)
	transpose_adjacency_list[to_vertex].append(from_vertex)

## pockets — the shipped digraph, now seeded. ~36 arrows at density 0.4 on ten
## vertices, scattered mutual reachability, whatever the dice gave.
func _edges_random() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GRAPH_SEED
	for i in range(graph_size):
		for j in range(graph_size):
			if i != j and rng.randf() < edge_density:
				_add_edge(i, j)

	# Ensure the graph is not shattered by adding the spine (shipped behaviour)
	if edges.size() < graph_size - 1:
		for i in range(graph_size - 1):
			if not has_edge("v" + str(i), "v" + str(i + 1)):
				_add_edge(i, i + 1)

## none — every arrow forward, so the graph is a total order and its transpose is
## a total order too. Both passes find ten singletons. Forty-five arrowheads flip
## and the answer does not move: the strongest possible statement of the artifact's
## thesis, made by having nothing to survive.
func _edges_forward_dag() -> void:
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			_add_edge(i, j)

## split — two blocks, each internally complete (every ordered pair), joined by ONE
## directed arrow. Two large components, and the transpose stage visibly reverses
## that single bridging arrow while leaving the two blocks exactly as they were.
func _edges_two_blocks() -> void:
	var half: int = graph_size / 2
	for i in range(graph_size):
		for j in range(graph_size):
			if i == j:
				continue
			if (i < half) == (j < half):
				_add_edge(i, j)
	if half >= 1 and half < graph_size:
		_add_edge(half - 1, half)

## total — a closed cycle through every vertex plus six chords. One component
## swallowing everything: transposing changes every arrowhead in the picture and
## changes nothing at all about the answer, which is the point.
func _edges_one_cycle() -> void:
	if graph_size < 2:
		return
	for i in range(graph_size):
		_add_edge(i, (i + 1) % graph_size)
	for pair in TOTAL_CHORDS:
		var a: int = int(pair[0]) % graph_size
		var b: int = int(pair[1]) % graph_size
		if a != b and not has_edge("v" + str(a), "v" + str(b)):
			_add_edge(a, b)

func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if edge.from == from and edge.to == to:
			return true
	return false

# ═══════════════════════════════════════════════════════════════════
# STAGING — where the vertices stand, one per value of `mutuality`
# ═══════════════════════════════════════════════════════════════════

func _vertex_position(i: int) -> Vector3:
	var n: int = maxi(vertices.size(), 1)

	if mutuality == "none":
		# A rising ramp: height climbs 0.3 m per vertex, x walks the width.
		var t: float = 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		return Vector3(LINE_HALF_X * (t * 2.0 - 1.0), float(i) * LINE_STEP, 0.0)

	if mutuality == "split":
		var half_b: int = n / 2
		var in_b: bool = i >= half_b
		var k: int = (i - half_b) if in_b else i
		var m: int = (n - half_b) if in_b else half_b
		if m < 1:
			m = 1
		var ang_b: float = float(k) * TAU / float(m)
		var cx: float = (SPLIT_GAP * 0.5) if in_b else (-SPLIT_GAP * 0.5)
		return Vector3(
			cx + cos(ang_b) * SPLIT_RADIUS,
			sin(float(i) * 1.2) * SPLIT_JITTER,
			sin(ang_b) * SPLIT_RADIUS)

	if mutuality == "total":
		# Flat, so the closed 10-arrow cycle reads as a closed loop.
		var ang_t: float = float(i) * TAU / float(n)
		return Vector3(cos(ang_t) * RING_RADIUS, 0.0, sin(ang_t) * RING_RADIUS)

	# pockets — the shipped ring: 4 m across, height jittered +/-0.5 m.
	var ang_p: float = float(i) * TAU / float(n)
	return Vector3(
		cos(ang_p) * RING_RADIUS,
		sin(float(i) * 0.5) * RING_JITTER,
		sin(ang_p) * RING_RADIUS)

# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## add_child + remember. Everything this script parents to self goes through here.
func _own(node: Node) -> void:
	add_child(node)
	_owned.append(node)

func _make_material(color: Color, emission_scale: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * emission_scale
	material.emission_enabled = emissive
	return material

## Top of the artifact's own geometry, measured from what was just built. Called
## after the spheres and arrows exist and before the captions are placed.
func _body_top() -> float:
	var top: float = -INF
	for node in _owned:
		if not (node is MeshInstance3D):
			continue
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = mi.transform * mi.get_aabb()
		top = maxf(top, box.position.y + box.size.y)
	if top == -INF:
		return 0.0
	return top

func create_visual_elements() -> void:
	vertex_nodes.clear()
	edge_lines.clear()
	transpose_edge_lines.clear()
	scc_labels.clear()

	# Create vertex spheres
	for i in range(vertices.size()):
		var vertex: String = vertices[i]

		var sphere := MeshInstance3D.new()
		sphere.name = "Vertex_" + vertex
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = VERTEX_RADIUS
		sphere_mesh.height = VERTEX_RADIUS * 2.0
		sphere.mesh = sphere_mesh
		sphere.position = _vertex_position(i)
		sphere.material_override = _make_material(vertex_color, 0.3)

		_own(sphere)
		vertex_nodes[vertex] = sphere

		# Vertex name — INK ON THE NODE, not a card beside it. A per-node hanging
		# caption becomes a per-node opaque plate and would bury the graph; a
		# 0.08 m glyph on the 0.30 m face is the same information with none of the
		# occlusion. BILLBOARD_DISABLED is set explicitly because that is what this
		# label now is, not to dodge the framer.
		var label := Label3D.new()
		label.name = "VertexLabel_" + vertex
		label.text = vertex
		label.font_size = 16
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.position = Vector3(0.0, 0.0, VERTEX_RADIUS + 0.01)
		sphere.add_child(label)

	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)

	# Nameplate. Two lines, 0.11 m apart in one column, so LabelFramer merges them
	# into a single panel sitting clear above whatever this value built.
	var top: float = _body_top()

	info_label = Label3D.new()
	info_label.name = "InfoLabel"
	info_label.text = "Kosaraju's Algorithm: Strongly Connected Components"
	info_label.font_size = 20
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.position = Vector3(0.0, top + CAPTION_LIFT_TOP, 0.0)
	_own(info_label)

	phase_label = Label3D.new()
	phase_label.name = "PhaseLabel"
	phase_label.text = "Phase 1: First DFS Pass"
	phase_label.font_size = 16
	phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	phase_label.position = Vector3(0.0, top + CAPTION_LIFT_SECOND, 0.0)
	_own(phase_label)

func create_edge_visual(edge: Dictionary) -> void:
	if not vertex_nodes.has(edge.from) or not vertex_nodes.has(edge.to):
		return
	var from_pos: Vector3 = vertex_nodes[edge.from].position
	var to_pos: Vector3 = vertex_nodes[edge.to].position

	var line := MeshInstance3D.new()
	line.name = "Edge_" + edge.from + "_" + edge.to
	line.mesh = create_arrow_mesh(from_pos, to_pos)
	line.material_override = _make_material(edge_color, 0.2)

	_own(line)
	edge_lines[edge.from + "_" + edge.to] = line

func create_arrow_mesh(from: Vector3, to: Vector3) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices_array := PackedVector3Array()
	var indices := PackedInt32Array()

	# Create arrow line
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var mid_point = from + direction * (length * 0.7)

	# Line vertices
	vertices_array.append(from)
	vertices_array.append(mid_point)

	# Arrow head
	var arrow_size = 0.1
	var perpendicular = Vector3(-direction.z, 0, direction.x).normalized()

	vertices_array.append(mid_point)
	vertices_array.append(to)
	vertices_array.append(to + perpendicular * arrow_size - direction * arrow_size)
	vertices_array.append(to - perpendicular * arrow_size - direction * arrow_size)

	# Indices for line
	indices.append(0)
	indices.append(1)

	# Indices for arrow head
	indices.append(2)
	indices.append(3)
	indices.append(4)
	indices.append(2)
	indices.append(3)
	indices.append(5)

	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func start_algorithm() -> void:
	if algorithm_running:
		return

	algorithm_running = true
	algorithm_step = 0
	sccs.clear()
	scc_count = 0
	current_phase = "first_pass"

	# Reset all vertices
	for vertex in vertices:
		visited[vertex] = false
		update_vertex_color(vertex, vertex_color)

	finish_times.clear()

	# Phase 1: First DFS pass to get finish times
	call_deferred("first_dfs_pass")

func first_dfs_pass() -> void:
	if not algorithm_running:
		return

	phase_label.text = "Phase 1: First DFS Pass (Getting finish times)"
	update_info_text("First DFS pass: Finding finish times for each vertex")

	# Perform DFS on original graph
	for vertex in vertices:
		if not visited[vertex]:
			call_deferred("dfs_first_pass", vertex)

	# After first pass, start second pass
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(animation_delay * 2).timeout
	call_deferred("second_dfs_pass")

func dfs_first_pass(vertex: String) -> void:
	if not algorithm_running or visited[vertex]:
		return

	current_vertex = vertex
	algorithm_step += 1

	visited[vertex] = true
	update_vertex_color(vertex, current_color)
	update_info_text("Processing vertex: " + vertex + " (First pass)")

	if step_by_step:
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(animation_delay).timeout

	# Process neighbors in original graph
	for neighbor in adjacency_list[vertex]:
		if not visited[neighbor]:
			update_edge_color(vertex, neighbor, Color.WHITE)
			# out-of-tree guard: get_tree() is null once a map is torn down
			if not is_inside_tree():
				await tree_entered
			await get_tree().create_timer(animation_delay * 0.5).timeout
			dfs_first_pass(neighbor)

	# Add to finish times (in reverse order)
	finish_times.push_front(vertex)
	update_vertex_color(vertex, finished_color)
	update_info_text("Finished vertex: " + vertex + " (Added to finish times)")

func second_dfs_pass() -> void:
	if not algorithm_running:
		return

	current_phase = "second_pass"
	phase_label.text = "Phase 2: Second DFS Pass (On transpose graph)"
	update_info_text("Second DFS pass: Processing transpose graph in reverse finish time order")

	# Reset visited for second pass
	for vertex in vertices:
		visited[vertex] = false

	# Show transpose edges
	show_transpose_edges()

	# Process vertices in reverse finish time order
	for vertex in finish_times:
		if not visited[vertex]:
			call_deferred("dfs_second_pass", vertex)
			scc_count += 1

func dfs_second_pass(vertex: String) -> void:
	if not algorithm_running or visited[vertex]:
		return

	current_vertex = vertex
	algorithm_step += 1

	visited[vertex] = true
	update_vertex_color(vertex, current_color)
	update_info_text("Processing vertex: " + vertex + " (Second pass - SCC " + str(scc_count) + ")")

	if step_by_step:
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(animation_delay).timeout

	# Process neighbors in transpose graph
	for neighbor in transpose_adjacency_list[vertex]:
		if not visited[neighbor]:
			update_transpose_edge_color(vertex, neighbor, Color.WHITE)
			# out-of-tree guard: get_tree() is null once a map is torn down
			if not is_inside_tree():
				await tree_entered
			await get_tree().create_timer(animation_delay * 0.5).timeout
			dfs_second_pass(neighbor)

	# Color the vertex with its SCC color
	var scc_color = get_scc_color(scc_count - 1)
	update_vertex_color(vertex, scc_color)

	# Add to current SCC (ensure capacity to avoid out-of-bounds)
	while sccs.size() <= scc_count - 1:
		sccs.append([])
	sccs[scc_count - 1].append(vertex)

func show_transpose_edges() -> void:
	# Create transpose edge visuals
	for edge in edges:
		var transpose_key = edge.to + "_" + edge.from
		if not transpose_edge_lines.has(transpose_key):
			if not vertex_nodes.has(edge.to) or not vertex_nodes.has(edge.from):
				continue
			var from_pos: Vector3 = vertex_nodes[edge.to].position
			var to_pos: Vector3 = vertex_nodes[edge.from].position

			var line := MeshInstance3D.new()
			line.name = "TransposeEdge_" + edge.to + "_" + edge.from
			line.mesh = create_arrow_mesh(from_pos, to_pos)
			line.material_override = _make_material(transpose_edge_color, 0.2)

			_own(line)
			transpose_edge_lines[transpose_key] = line

func get_scc_color(index: int) -> Color:
	var colors = [scc_color_1, scc_color_2, scc_color_3, scc_color_4, scc_color_5]
	return colors[index % colors.size()]

func update_vertex_color(vertex: String, color: Color) -> void:
	if vertex_nodes.has(vertex):
		vertex_nodes[vertex].material_override = _make_material(color, 0.3)

func update_edge_color(from: String, to: String, color: Color) -> void:
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		edge_lines[edge_key].material_override = _make_material(color, 0.2)

func update_transpose_edge_color(from: String, to: String, color: Color) -> void:
	var edge_key = from + "_" + to
	if transpose_edge_lines.has(edge_key):
		transpose_edge_lines[edge_key].material_override = _make_material(color, 0.2)

func update_info_text(text: String) -> void:
	if info_label:
		info_label.text = text

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if algorithm_running:
			stop_algorithm()
		else:
			start_algorithm()
	elif event.is_action_pressed("ui_cancel"):
		reset_algorithm()

func stop_algorithm() -> void:
	algorithm_running = false
	update_info_text("Algorithm completed. Found " + str(scc_count) + " strongly connected components.")
	phase_label.text = "Algorithm Complete"

func reset_algorithm() -> void:
	_rebuild_now()
	update_info_text("Kosaraju's Algorithm: Strongly Connected Components")
	phase_label.text = "Phase 1: First DFS Pass"

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Kosaraju's Algorithm",
		"description": "Two-pass DFS algorithm for finding strongly connected components",
		"time_complexity": "O(V + E)",
		"space_complexity": "O(V)",
		"scc_count": scc_count,
		"current_step": algorithm_step,
		"current_phase": current_phase
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_mutuality: String = mutuality
	var before_size: int = graph_size
	var before_density: float = edge_density

	if config_data.has("mutuality"):
		mutuality = _pick_axis(str(config_data["mutuality"]), MUTUALITIES, mutuality)
	if config_data.has("graph_size"):
		graph_size = clampi(int(config_data["graph_size"]), 3, 24)
	if config_data.has("edge_density"):
		edge_density = clampf(float(config_data["edge_density"]), 0.05, 1.0)

	# Non-geometry key, applied IN PLACE — before the early returns below, because
	# an accepted key that only bites when something else also changed is a key
	# that does nothing. curation_station hands every artifact {"emissive": false}
	# one line after framing its labels; that dict carries no axis, so it must
	# repaint (to the same shipped value) and NOT rebuild.
	if config_data.has("emissive"):
		emissive = _as_bool(config_data["emissive"], emissive)
		_apply_emissive_in_place()

	if not _built:
		return
	if mutuality == before_mutuality and graph_size == before_size \
			and is_equal_approx(edge_density, before_density):
		return

	_rebuild_now()
	print("[Kosaraju] Config applied — mutuality=%s, graph_size=%d, edge_density=%.2f" % [
		mutuality, graph_size, edge_density])

## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the shipped look; a half-recognised value would strand a
## placement on a staging with no edge set.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

func _as_bool(value: Variant, fallback: bool) -> bool:
	var t: int = typeof(value)
	if t == TYPE_BOOL:
		return bool(value)
	if t == TYPE_INT or t == TYPE_FLOAT:
		return float(value) != 0.0
	var s: String = str(value).to_lower().strip_edges()
	if s in ["true", "1", "yes", "on"]:
		return true
	if s in ["false", "0", "no", "off"]:
		return false
	return fallback

func _apply_emissive_in_place() -> void:
	for key in vertex_nodes.keys():
		_set_emission_enabled(vertex_nodes[key])
	for key in edge_lines.keys():
		_set_emission_enabled(edge_lines[key])
	for key in transpose_edge_lines.keys():
		_set_emission_enabled(transpose_edge_lines[key])

func _set_emission_enabled(node: Node) -> void:
	if not (node is MeshInstance3D):
		return
	var mi: MeshInstance3D = node as MeshInstance3D
	if mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).emission_enabled = emissive

## Free ONLY what this script created, then build again INLINE. No call_deferred:
## a deferred rebuild leaves the node empty for a frame and the grid's
## auto-grounding measures a zero AABB and gives up.
func _rebuild_now() -> void:
	algorithm_running = false
	algorithm_step = 0
	current_phase = "first_pass"

	# The grid frames labels BEFORE it calls apply_grid_config, so by now the two
	# root captions may already carry a merged plate parented to self. Those plates
	# belong to labels we are about to free — leaving them would strand an
	# anthracite panel in mid-air. They are the one exception to "only free what we
	# created", and the framer is re-run afterwards so the nameplate comes back.
	var had_plates: bool = false
	for child in get_children():
		if child is MeshInstance3D and child.has_meta("label_plate"):
			had_plates = true
			remove_child(child)
			child.queue_free()

	for node in _owned:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_owned.clear()

	vertex_nodes.clear()
	edge_lines.clear()
	transpose_edge_lines.clear()
	scc_labels.clear()
	info_label = null
	phase_label = null

	_build_all()

	if had_plates:
		LABEL_FRAMER.frame_labels(self)
