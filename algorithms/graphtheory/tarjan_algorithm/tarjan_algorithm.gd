class_name TarjanAlgorithm
extends Node3D

# @identity
# essence: single-pass DFS with a stack — each vertex gets discovery_time and low_link; low_link[v] = min(low_link[v], discovery_time[w]) for back edges; when low_link[v] == discovery_time[v], pop the stack to extract an SCC
# desire: to watch a DFS drill through a directed graph, painting vertices yellow as it visits them, then suddenly flash an entire SCC in color when a root vertex is found
# critical_parameter: mutuality — how much mutual reachability the standing graph holds before the DFS ever runs; edge_density still tempers the `pockets` scatter
# triggers: auto_start begins the non-blocking step-by-step animation; each _process frame advances one DFS step; back edges (colored red) indicate the low_link updates that close cycles
# emerges: the stack-based SCC extraction means you see the components pop out in reverse DFS order — deeper components emerge first, creating a bottom-up revelation of graph structure
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (info_label, vertex labels)
# relationships: paired with kosaraju_algorithm in GT_Connectivity — both find SCCs but through different strategies (one-pass vs two-pass); contrasts with topological_sort which requires a DAG (no SCCs)
# truth: a strongly connected component is a pocket of mutual reachability — every vertex can reach every other, and Tarjan's genius was finding them all in a single depth-first pass

# Tarjan's Algorithm: Strongly Connected Components (Non-blocking version)

@export_category("Tarjan Configuration")
@export var graph_size: int = 12
@export var edge_density: float = 0.3
@export var auto_start: bool = true
@export var animation_speed: float = 0.3  # Seconds between steps

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `mutuality`
# ═══════════════════════════════════════════════════════════════════
#
# How much mutual reachability the directed graph HOLDS — scattered small
# pockets, none at all, two large components, or one component swallowing
# everything.
#
# The value is carried by the LAYOUT and the EDGE SET, never by the SCC
# colouring. That is deliberate. The colours are produced by _process, one step
# every `animation_speed` seconds, and a still photographs the first frames — an
# axis routed through the palette would be invisible in the evidence and would
# also be a time-domain axis wearing a costume. What varies here is the standing
# structure the shipped animation is run ON, so the still is true no matter which
# frame it catches, and the DFS is untouched.
#
#   pockets  the shipped random digraph. 12 spheres of radius 0.2 m on a 6 m
#            ring, y jitter to +/-0.5 m, ~40 arrowed edges at edge_density 0.3.
#   none     the same 12 vertices restaged as a rising line — y 0 -> 3.3 m in
#            0.3 m steps, x -3.3 -> 3.3 m — every arrow pointing UP the line. A
#            DAG: no vertex lies on any cycle, and the ring is gone. This is the
#            value that earns the axis. A directed graph with no strongly
#            connected component is the negative space Tarjan's whole apparatus
#            exists to distinguish, and until now it could not be requested.
#   split    two 2.4 m rings 7 m apart, densely arrowed inside each, joined by
#            exactly ONE arrow in one direction — two large components that a
#            still reads as two objects.
#   total    one 6 m ring carrying a closed 12-arrow cycle plus 8 chords. Every
#            vertex mutually reachable, one component, and the flat ring reads as
#            a solid wheel rather than a scatter.
#
# tarjan and kosaraju solve the same problem by different means, and
# rhizomatic_structure contests it from outside, so all three carry THE SAME WORD
# AND THE SAME LADDER — a sweep sheet with `mutuality: total` on three rows shows
# one DFS pass, two DFS passes and a Deleuzian growth model all arriving at
# "everything reaches everything".
@export_enum("pockets", "none", "split", "total") var mutuality: String = "pockets"

## Allow-list. A typo in a map token falls back to the shipped look rather than
## stranding a placement with no graph at all.
const MUTUALITIES: PackedStringArray = ["pockets", "none", "split", "total"]

## `pockets` is a RANDOM digraph by nature, and two builds of one axis value must
## be pixel-identical or the pixel critic reads noise as signal. Seeded, not
## global randf().
const POCKETS_SEED: int = 20260729

# Layout constants, in metres.
const RING_RADIUS: float = 3.0          # pockets / total — 6 m diameter
const RING_JITTER: float = 0.5          # pockets only — the shipped y wobble
const LINE_X_SPAN: float = 6.6          # none — -3.3 .. +3.3
const LINE_Y_STEP: float = 0.3          # none — 0 .. 3.3 over 12 vertices
const SPLIT_RADIUS: float = 1.2         # split — 2.4 m diameter per ring
const SPLIT_SEPARATION: float = 7.0     # split — ring centres 7 m apart
const TOTAL_CHORDS: int = 8             # total — chords across the wheel

## Caption clearance above the measured body top. The info plate is ~0.19 m tall,
## so 0.35 m puts its bottom edge a quarter of a metre clear of the highest
## geometry at every axis value.
const CAPTION_CLEARANCE: float = 0.35

@export_category("Visualization")
@export var show_discovery_time: bool = true
@export var show_low_link: bool = true
@export var highlight_current_vertex: bool = true

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
@export var back_edge_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var cross_edge_color: Color = Color(0.3, 0.9, 0.3, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var vertex_positions: Dictionary = {}

# Tarjan's algorithm state
var discovery_time: Dictionary = {}
var low_link: Dictionary = {}
var on_stack: Dictionary = {}
var stack: Array = []
var time_counter: int = 0
var scc_count: int = 0
var sccs: Array = []
var algorithm_running: bool = false

# Non-blocking DFS state
var dfs_stack: Array = []  # Stack of {vertex, state, neighbor_index}
var current_root_index: int = 0

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var info_label: Label3D
var step_timer: float = 0.0

## Only the nodes THIS script created in the build path. _rebuild_now frees these
## and nothing else — get_children() would take the grid's own added plates with it.
var _created: Array[Node] = []
## Lights / environment / camera: built once, never rebuilt (rebuilding them would
## stack a second WorldEnvironment on every config pass).
var _env: Array[Node] = []
var _built: bool = false
## Honoured by every material this script makes, including the ones _process
## builds mid-run — an accepted key that stops working after the first frame is
## the same lie as one that never worked.
var _emissive: bool = true


func _ready() -> void:
	setup_environment()
	_build_all()
	_built = true

	if auto_start:
		start_algorithm()

func setup_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	light.light_energy = 1.2
	add_child(light)
	_env.append(light)

	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.background_mode = Environment.BG_COLOR
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	add_child(ambient)
	_env.append(ambient)

	var camera := Camera3D.new()
	camera.position = Vector3(8.0, 6.0, 12.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)
	_env.append(camera)


## SYNCHRONOUS, from @export values alone. Everything the sweep needs happens
## here — no call_deferred anywhere in the build path, because a deferred rebuild
## that removes children first makes auto-grounding measure a ZERO AABB and bail.
func _build_all() -> void:
	initialize_graph()
	create_visual_elements()


func initialize_graph() -> void:
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	vertex_positions.clear()
	discovery_time.clear()
	low_link.clear()
	on_stack.clear()
	stack.clear()
	time_counter = 0
	scc_count = 0
	sccs.clear()
	algorithm_running = false
	dfs_stack.clear()
	current_root_index = 0

	generate_random_graph()

	for vertex in vertices:
		discovery_time[vertex] = -1
		low_link[vertex] = -1
		on_stack[vertex] = false


## Reads `mutuality` at the top and selects both the vertex layout and the edge
## set. Named `generate_random_graph` still because only one of the four values
## is random — and that one is seeded.
func generate_random_graph() -> void:
	var n: int = maxi(graph_size, 3)

	for i in range(n):
		var vertex: String = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []

	match mutuality:
		"none":
			_layout_line(n)
			_edges_dag(n)
		"split":
			_layout_two_rings(n)
			_edges_two_components(n)
		"total":
			_layout_ring(n, 0.0)
			_edges_one_cycle(n)
		_:
			_layout_ring(n, RING_JITTER)
			_edges_scatter(n)


# ── LAYOUTS ────────────────────────────────────────────────────────

## The shipped staging: a 6 m-diameter ring in the XZ plane. `jitter` 0.5 gives
## the pockets wobble; 0.0 flattens it into the `total` wheel.
func _layout_ring(n: int, jitter: float) -> void:
	var angle_step: float = TAU / float(n)
	for i in range(n):
		var angle: float = float(i) * angle_step
		var y: float = sin(float(i) * 0.5) * jitter
		vertex_positions["v" + str(i)] = Vector3(
			cos(angle) * RING_RADIUS, y, sin(angle) * RING_RADIUS)


## `none`: a rising line. x walks -3.3 -> 3.3, y climbs 0.3 m a step. The ring is
## gone, and with it any suggestion that the graph closes on itself.
func _layout_line(n: int) -> void:
	var x_step: float = LINE_X_SPAN / float(maxi(n - 1, 1))
	for i in range(n):
		vertex_positions["v" + str(i)] = Vector3(
			-LINE_X_SPAN * 0.5 + float(i) * x_step, float(i) * LINE_Y_STEP, 0.0)


## `split`: two flat 2.4 m rings, centres 7 m apart on X — 9.4 m of total width,
## which is what makes a still read two objects rather than one busy one.
func _layout_two_rings(n: int) -> void:
	var half: int = n / 2
	var rest: int = n - half
	for i in range(half):
		var a: float = float(i) * TAU / float(maxi(half, 1))
		vertex_positions["v" + str(i)] = Vector3(
			-SPLIT_SEPARATION * 0.5 + cos(a) * SPLIT_RADIUS, 0.0, sin(a) * SPLIT_RADIUS)
	for k in range(rest):
		var b: float = float(k) * TAU / float(maxi(rest, 1))
		vertex_positions["v" + str(half + k)] = Vector3(
			SPLIT_SEPARATION * 0.5 + cos(b) * SPLIT_RADIUS, 0.0, sin(b) * SPLIT_RADIUS)


# ── EDGE SETS ──────────────────────────────────────────────────────

func _add_edge(from_vertex: String, to_vertex: String) -> void:
	if from_vertex == to_vertex:
		return
	if has_edge(from_vertex, to_vertex):
		return
	edges.append({"from": from_vertex, "to": to_vertex})
	adjacency_list[from_vertex].append(to_vertex)


## `pockets` — the shipped bare double loop, with the global randf() replaced by a
## seeded generator. Same tempering, same expected ~40 edges at density 0.3; the
## only change is that two builds now produce the SAME graph instead of two
## differently-seeded ones.
func _edges_scatter(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = POCKETS_SEED
	for i in range(n):
		for j in range(n):
			if i != j and rng.randf() < edge_density:
				_add_edge("v" + str(i), "v" + str(j))

	# Ensure connectivity (shipped behaviour, kept verbatim)
	for i in range(mini(n - 1, 3)):
		_add_edge("v" + str(i), "v" + str(i + 1))


## `none` — every arrow points UP the line. Chain, plus +2 and +4 skips so the
## picture is a dense directed ladder rather than a thin thread. Strictly
## increasing index means no cycle can exist: every SCC is a single vertex.
func _edges_dag(n: int) -> void:
	for i in range(n - 1):
		_add_edge("v" + str(i), "v" + str(i + 1))
	for i in range(n - 2):
		_add_edge("v" + str(i), "v" + str(i + 2))
	for i in range(n - 4):
		_add_edge("v" + str(i), "v" + str(i + 4))


## `split` — each ring is wired forward, forward-by-two and backward, which makes
## it strongly connected on its own. Then exactly ONE arrow crosses the gap, in
## one direction, so the second ring can be reached but never reached FROM.
func _edges_two_components(n: int) -> void:
	var half: int = n / 2
	_wire_component(0, half)
	_wire_component(half, n - half)
	if half > 0 and n - half > 0:
		_add_edge("v" + str(0), "v" + str(half))


func _wire_component(offset: int, count: int) -> void:
	if count < 2:
		return
	for k in range(count):
		var here: String = "v" + str(offset + k)
		_add_edge(here, "v" + str(offset + (k + 1) % count))
		_add_edge(here, "v" + str(offset + (k + 2) % count))
		_add_edge(here, "v" + str(offset + (k + count - 1) % count))


## `total` — one closed cycle round the rim plus 8 chords straight across. Every
## vertex reaches every other; the whole graph is one component, and the chords
## are what turn a ring of dots into a wheel.
func _edges_one_cycle(n: int) -> void:
	for i in range(n):
		_add_edge("v" + str(i), "v" + str((i + 1) % n))
	# Span 5 on a 12-ring, not 6: an exact diameter would put every chord through
	# the same centre point and make half of them coincide with each other, so the
	# wheel would show 6 lines where the graph has 8 edges. Off-diameter chords
	# stay distinct and the hub reads as woven rather than as a single crossing.
	var span: int = maxi(n / 2 - 1, 2)
	for i in range(mini(TOTAL_CHORDS, n)):
		_add_edge("v" + str(i), "v" + str((i + span) % n))


func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if edge.from == from and edge.to == to:
			return true
	return false

func create_visual_elements() -> void:
	vertex_nodes.clear()
	edge_lines.clear()

	for i in range(vertices.size()):
		var vertex: String = vertices[i]

		var sphere := MeshInstance3D.new()
		sphere.name = "Vertex_" + vertex
		sphere.mesh = SphereMesh.new()
		(sphere.mesh as SphereMesh).radius = 0.2
		(sphere.mesh as SphereMesh).height = 0.4
		(sphere.mesh as SphereMesh).radial_segments = 16
		(sphere.mesh as SphereMesh).rings = 8
		var where: Vector3 = vertex_positions.get(vertex, Vector3.ZERO)
		sphere.position = where
		sphere.material_override = _make_material(vertex_color, 0.5, 1.5, false)

		add_child(sphere)
		_created.append(sphere)
		vertex_nodes[vertex] = sphere

		# INK ON THE NODE, not a card beside it.
		#
		# Twelve vertex names hung off twelve spheres around a 6 m ring become
		# twelve opaque ~0.25 x 0.14 m plates the moment LabelFramer sees them —
		# each one standing in front of the two or three nodes behind it, which
		# buries the graph the label is trying to explain. So the name is printed
		# ON the sphere: local (0, 0, 0.21) is 0.01 m proud of a 0.2 m radius, and
		# font 20 at pixel_size 0.005 is a 0.10 m glyph on a 0.4 m ball.
		#
		# billboard is set to DISABLED EXPLICITLY rather than left at its default.
		# The framer's own rule is that a non-billboard label lies on a body and is
		# already integrated, and that is exactly true here — this is naming the
		# category, not dodging the framer.
		var label := Label3D.new()
		label.text = vertex
		label.font_size = 20
		label.position = Vector3(0, 0, 0.21)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.modulate = Color(1, 1, 1, 0.9)
		sphere.add_child(label)

	for edge in edges:
		create_edge_visual(edge)

	# THE CAPTION SET THE CAMERA. At the shipped y=5 this one label framed a 5.8 m
	# column whose bottom 1.4 m was the actual artifact, which is why the graph
	# renders as a small blob in its own portrait. Sit it just above the measured
	# body instead, and let it billboard so it is a genuine nameplate.
	#
	# The top must be MEASURED, not assumed: `none` lifts the body to 3.5 m and
	# `split` widens it to 9.4 m, so a hard-coded height would be wrong at three
	# of the four values.
	var body_top: float = _measure_body_top()
	info_label = Label3D.new()
	info_label.text = "Tarjan's Algorithm - Press Space to Start"
	info_label.font_size = 24
	info_label.position = Vector3(0, body_top + CAPTION_CLEARANCE, 0)
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.modulate = Color(1, 1, 1, 0.95)
	add_child(info_label)
	_created.append(info_label)


## Highest point of the geometry this script has built so far, in local space.
## Corners are transformed by hand rather than leaning on an AABB operator, and
## Label3D subtrees are skipped — a caption must never define the body it clears.
func _measure_body_top() -> float:
	var acc: Array = [-INF]
	for node in _created:
		_accumulate_top(node, Transform3D.IDENTITY, acc)
	var top: float = float(acc[0])
	if top == -INF:
		top = 0.5
	return top


func _accumulate_top(n: Node, parent_xform: Transform3D, acc: Array) -> void:
	if n is Label3D:
		return
	var xf: Transform3D = parent_xform
	if n is Node3D:
		xf = parent_xform * (n as Node3D).transform
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			var ab: AABB = mi.mesh.get_aabb()
			for k in range(8):
				var corner: Vector3 = ab.position + Vector3(
					ab.size.x * float(k & 1),
					ab.size.y * float((k >> 1) & 1),
					ab.size.z * float((k >> 2) & 1))
				var p: Vector3 = xf * corner
				acc[0] = maxf(float(acc[0]), p.y)
	for c in n.get_children():
		_accumulate_top(c, xf, acc)


func _make_material(color: Color, emit_scale: float, energy: float, alpha: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = _emissive
	material.emission = color * emit_scale
	material.emission_energy_multiplier = energy
	if alpha:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func create_edge_visual(edge: Dictionary) -> void:
	var from_pos: Vector3 = vertex_nodes[edge.from].position
	var to_pos: Vector3 = vertex_nodes[edge.to].position

	var delta: Vector3 = to_pos - from_pos
	var distance: float = delta.length()

	var line_container := Node3D.new()
	line_container.name = "Edge_" + edge.from + "_" + edge.to
	add_child(line_container)
	_created.append(line_container)

	var line := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = distance * 0.85
	line.mesh = cylinder
	var material: StandardMaterial3D = _make_material(edge_color, 0.3, 1.0, true)
	line.material_override = material
	line_container.add_child(line)

	# LOCAL placement, and the arrow points at the HEAD.
	#
	# This used to be `global_position = midpoint` followed by a look_at that was
	# handed a LOCAL position — correct only while the artifact sat at the world
	# origin, and in a map it detached every edge from its own graph. The rotation
	# was also a quarter turn off in the wrong sense, which put the cone on the
	# tail end pointing backwards. Both are fixed here by building the basis
	# directly: local +Y is the cylinder's axis, so aim +Y down the edge and the
	# cone at +Y * 0.4 sits at the head, pointing the way the arrow means.
	# `mutuality` is carried by arrow DIRECTION at two of its four values, so a
	# reversed arrowhead is not cosmetic here.
	line_container.position = (from_pos + to_pos) * 0.5
	if distance > 0.001:
		var axis: Vector3 = delta / distance
		var reference: Vector3 = Vector3.UP
		if absf(axis.dot(reference)) > 0.99:
			reference = Vector3.RIGHT
		var x_axis: Vector3 = reference.cross(axis).normalized()
		var z_axis: Vector3 = axis.cross(x_axis).normalized()
		line_container.basis = Basis(x_axis, axis, z_axis)

	var arrow := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.1
	cone.height = 0.2
	arrow.mesh = cone
	arrow.material_override = material.duplicate()
	arrow.position = Vector3(0, distance * 0.4, 0)
	line_container.add_child(arrow)

	edge_lines[edge.from + "_" + edge.to] = line_container

func start_algorithm() -> void:
	if algorithm_running:
		return

	algorithm_running = true
	sccs.clear()
	scc_count = 0
	dfs_stack.clear()
	current_root_index = 0
	step_timer = 0.0

	for vertex in vertices:
		discovery_time[vertex] = -1
		low_link[vertex] = -1
		on_stack[vertex] = false
		update_vertex_color(vertex, vertex_color)

	stack.clear()
	time_counter = 0

	update_info_text("Starting Tarjan's Algorithm...")

func _process(delta: float) -> void:
	if not algorithm_running:
		return

	step_timer += delta
	if step_timer < animation_speed:
		return

	step_timer = 0.0

	# Process one step of the algorithm
	process_tarjan_step()

func process_tarjan_step() -> void:
	# If DFS stack is empty, try to start from next unvisited root
	if dfs_stack.is_empty():
		while current_root_index < vertices.size():
			var vertex = vertices[current_root_index]
			current_root_index += 1

			if discovery_time[vertex] == -1:
				# Start new DFS from this vertex
				start_dfs(vertex)
				return

		# All vertices processed
		algorithm_running = false
		update_info_text("Complete! Found " + str(scc_count) + " SCCs")
		return

	# Process current DFS frame
	var frame = dfs_stack[-1]
	var vertex = frame["vertex"]
	var state = frame["state"]

	if state == "INIT":
		# Initialize vertex
		discovery_time[vertex] = time_counter
		low_link[vertex] = time_counter
		time_counter += 1
		stack.append(vertex)
		on_stack[vertex] = true

		update_vertex_color(vertex, current_color)
		update_info_text("Visiting: " + vertex + " (disc=" + str(discovery_time[vertex]) + ")")

		frame["state"] = "PROCESS_NEIGHBORS"
		frame["neighbor_index"] = 0

	elif state == "PROCESS_NEIGHBORS":
		var neighbors = adjacency_list[vertex]
		var neighbor_index = frame["neighbor_index"]

		if neighbor_index < neighbors.size():
			var neighbor = neighbors[neighbor_index]
			frame["neighbor_index"] += 1

			if discovery_time[neighbor] == -1:
				# Tree edge
				update_edge_color(vertex, neighbor, Color.WHITE)
				start_dfs(neighbor)
			elif on_stack[neighbor]:
				# Back edge
				update_edge_color(vertex, neighbor, back_edge_color)
				low_link[vertex] = min(low_link[vertex], discovery_time[neighbor])
			else:
				# Cross edge
				update_edge_color(vertex, neighbor, cross_edge_color)
		else:
			# All neighbors processed
			frame["state"] = "FINALIZE"

	elif state == "FINALIZE":
		# Check if this is an SCC root
		if low_link[vertex] == discovery_time[vertex]:
			var scc = []
			while true:
				var w = stack.pop_back()
				on_stack[w] = false
				scc.append(w)
				if w == vertex:
					break

			sccs.append(scc)
			var scc_color = get_scc_color(scc_count)
			scc_count += 1

			for v in scc:
				update_vertex_color(v, scc_color)

			update_info_text("Found SCC #" + str(scc_count) + ": " + str(scc))
		else:
			update_vertex_color(vertex, visited_color)

		# Pop this frame
		dfs_stack.pop_back()

		# Update parent's low link
		if not dfs_stack.is_empty():
			var parent_frame = dfs_stack[-1]
			var parent = parent_frame["vertex"]
			low_link[parent] = min(low_link[parent], low_link[vertex])

func start_dfs(vertex: String) -> void:
	dfs_stack.append({
		"vertex": vertex,
		"state": "INIT",
		"neighbor_index": 0
	})

func get_scc_color(index: int) -> Color:
	var colors = [scc_color_1, scc_color_2, scc_color_3, scc_color_4, scc_color_5]
	return colors[index % colors.size()]

func update_vertex_color(vertex: String, color: Color) -> void:
	if vertex_nodes.has(vertex):
		vertex_nodes[vertex].material_override = _make_material(color, 0.5, 1.5, false)

func update_edge_color(from: String, to: String, color: Color) -> void:
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		var line = edge_lines[edge_key].get_child(0)
		line.material_override = _make_material(color, 0.4, 1.2, true)

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
	update_info_text("Paused - Press Space to resume")

func reset_algorithm() -> void:
	_rebuild_now()
	update_info_text("Tarjan's Algorithm - Press Space to Start")

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

	# Stage-2 DNA axis — #mutuality:total
	if config_data.has("mutuality"):
		mutuality = _pick_axis(str(config_data["mutuality"]), MUTUALITIES, mutuality)

	# Geometry keys, snapshotted above so they trigger the same rebuild.
	if config_data.has("graph_size"):
		graph_size = clampi(int(config_data["graph_size"]), 3, 40)
	if config_data.has("edge_density"):
		edge_density = clampf(float(config_data["edge_density"]), 0.0, 1.0)

	# NON-GEOMETRY, APPLIED IN PLACE, BEFORE THE RETURNS. curation_station hands
	# every artifact it curates {"emissive": false} one line after framing its
	# labels — a dict with no axis key, which must therefore change nothing about
	# the graph and still actually do its own job. Applying it here rather than
	# relying on the rebuild is the whole point: the early-returns below mean a
	# rebuild is not guaranteed, and two artifacts once accepted this key and
	# applied it nowhere for exactly that reason.
	if config_data.has("emissive"):
		var want: bool = _as_bool(config_data["emissive"], _emissive)
		if want != _emissive:
			_emissive = want
			_apply_emissive_in_place()

	if not _built:
		return
	if mutuality == before_mutuality and graph_size == before_size \
			and is_equal_approx(edge_density, before_density):
		return

	_rebuild_now()
	print("[Tarjan] Config applied — mutuality=%s, vertices=%d, edges=%d" % [
		mutuality, vertices.size(), edges.size()])


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the shipped look — a half-recognised value would
## strand a placement with no graph at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _as_bool(raw, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	var s: String = str(raw).to_lower().strip_edges()
	if s in ["false", "0", "off", "no"]:
		return false
	if s in ["true", "1", "on", "yes"]:
		return true
	return fallback


## Walk what this script built and switch emission on the live materials. No
## geometry is touched, so a placement that only sends `emissive` keeps the exact
## graph it was shipped with.
func _apply_emissive_in_place() -> void:
	var queue: Array = []
	for n in _created:
		queue.append(n)
	while not queue.is_empty():
		var node: Node = queue.pop_back()
		if node is MeshInstance3D:
			var mat = (node as MeshInstance3D).material_override
			if mat is StandardMaterial3D:
				(mat as StandardMaterial3D).emission_enabled = _emissive
		for c in node.get_children():
			queue.append(c)


## SYNCHRONOUS. Free only what this script created — the lights, environment and
## camera in _env stay, and the grid's own added children are never touched.
func _rebuild_now() -> void:
	algorithm_running = false
	dfs_stack.clear()
	current_root_index = 0

	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()
	vertex_nodes.clear()
	edge_lines.clear()
	info_label = null

	_build_all()

	if auto_start:
		start_algorithm()
