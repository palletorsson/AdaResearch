class_name TopologicalSort
extends Node3D

# Topological Sort: Dependency Ordering in DAGs
# Visualizes the ordering of vertices in a directed acyclic graph
# Explores dependency resolution and task scheduling concepts

@export_category("Topological Sort Configuration")

## STAGE-2 DNA AXIS — `precedence`
##
## How much order the dependency set actually FORCES. The DAG's confession is that
## order becomes MANDATORY once arrows forbid cycles — but "mandatory" is a quantity,
## and the shipped artifact froze it at one arbitrary middling value, so no map could
## put the list that is fully forced next to the list that forces nothing.
##
##   levels  the shipped DAG — 8 vertices grouped by in-degree into 4 tiers at
##           1.5 m pitch, widest tier 3, translucent level planes 1.0 m deep;
##           body 3.75 x 4.75 x 1.00 m. THE DEFAULT, frozen from the shipped
##           distribution so two builds are pixel-identical (see LEVELS_EDGES).
##   stair   a total order v0->v1->...->v7 at 0.8 m pitch — eight tiers of exactly
##           one 0.3 m sphere each, eight 2 m level planes stacked into a column
##           only 2 m wide. Every arrow vertical; no choice anywhere.
##   flat    no edges at all — all eight vertices at in-degree 0, a single 9.6 m
##           row on one level plane, 0.3 m tall. Nothing is before anything and
##           the sort has nothing to do.
##   lens    one source, six parallel middles, one sink — three tiers, the middle
##           7.2 m wide, ~3.3 m tall, 12 arrows fanning out of the top vertex and
##           back into the bottom one. The bottleneck shape.
##   snarl   a 3-cycle grafted into the DAG — the five sortable vertices stack into
##           three tiers as usual while the three cyclic vertices stand as a
##           separate clump 3 m to the side on a red 3.6 m level plane, permanently
##           unresolved because their in-degrees never reach zero.
##
## Named `precedence` and NOT `order` because `order` is already a VALUE word live
## in the registries — one keystroke from the rig failure in its other direction.
@export_enum("levels", "stair", "flat", "lens", "snarl") var precedence: String = "levels"

@export var graph_size: int = 8  # Number of vertices
@export var edge_density: float = 0.3  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0

@export_category("Visualization")
@export var show_in_degrees: bool = true
@export var show_queue_state: bool = true
@export var highlight_current_vertex: bool = true
@export var show_sorting_order: bool = true
@export var animate_dependency_resolution: bool = true
@export var show_levels: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_edge_editing: bool = true
@export var real_time_sort_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var ready_color: Color = Color(0.2, 0.9, 0.2, 1.0)  # In-degree 0
@export var processing_color: Color = Color(0.9, 0.9, 0.2, 1.0)  # Currently processing
@export var processed_color: Color = Color(0.9, 0.2, 0.2, 1.0)  # Already processed
@export var level_1_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var level_2_color: Color = Color(0.9, 0.5, 0.2, 1.0)
@export var level_3_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var level_4_color: Color = Color(0.5, 0.9, 0.2, 1.0)
@export var level_5_color: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var dependency_edge_color: Color = Color(0.9, 0.3, 0.3, 1.0)

# ═══════════════════════════════════════════════════════════════════
# AXIS CONSTANTS
# ═══════════════════════════════════════════════════════════════════

## The allow-list. A token outside it falls back to whatever is already set —
## a half-recognised value would strand a placement with no graph at all.
const PRECEDENCES: PackedStringArray = ["levels", "stair", "flat", "lens", "snarl"]

## `levels` is the SHIPPED look, and the shipped look was a fresh random draw on
## every load. Two builds of one axis value must be pixel-identical or the pixel
## critic reads noise as signal, so the draw is frozen here: one representative
## sample of graph_size 8 at edge_density 0.3 (10 edges against an expected 10.4),
## chosen so the in-degrees come out 0,0,1,1,1,2,2,3 — four tiers, widest 3, the
## 3.75 x 4.75 x 1.00 m body the registry already measured.
## A map that overrides graph_size falls through to the seeded generator below.
const LEVELS_EDGES: Array = [
	[0, 2], [0, 4], [1, 3], [1, 7], [2, 5], [3, 5], [3, 6], [4, 6], [5, 7], [6, 7]]
const LEVELS_SIZE: int = 8
## Fixed seed for the off-default graph_size path. Never randomize the randomizer.
const LEVELS_SEED: int = 20260729

## Tier spacing. `stair` is the only value that changes it: eight tiers at the
## shipped 1.5 m would be a 10.5 m pole no camera can frame, and the point of the
## value is the COLUMN, not the height record.
const PITCH_DEFAULT: float = 1.5
const PITCH_STAIR: float = 0.8

## `snarl`: where the unresolvable clump stands, and how wide its plane is.
## CYCLE_BASE_Y lifts it off the tier-0 plane — at y = 0 the red plane would be
## coplanar with, and edge-to-edge against, the bottom tier's plane and the two
## would read as one long shelf instead of a thing standing apart from the ladder.
const CYCLE_OFFSET_X: float = 3.0
const CYCLE_BASE_Y: float = 0.75
const CYCLE_PLANE_COLOR: Color = Color(0.85, 0.15, 0.15, 1.0)
const CYCLE_SPREAD: float = 0.9
const CYCLE_RISE: float = 1.35

## CAPTION PLACEMENT (see the block comment on create_info_labels).
## Lift above the MEASURED body top, and the step between the three lines.
const CAPTION_LIFT: float = 0.23
const CAPTION_STEP: float = 0.11

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var in_degrees: Dictionary = {}

# Topological sort state
var sorted_order: Array = []
var queue: Array = []
var current_vertex: String = ""
var algorithm_running: bool = false
var algorithm_step: int = 0
var level: int = 0
var level_vertices: Dictionary = {}

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var level_indicators: Array = []
var info_label: Label3D
var queue_label: Label3D
var order_label: Label3D

# ── Lifecycle / rebuild bookkeeping ────────────────────────────────
## Every node THIS script adds under the graph build. _rebuild_now frees exactly
## these — never get_children(), which would take the grid's own caption plates,
## the camera and the light down with it.
var _created: Array[Node] = []
var _built: bool = false
## The vertices inside the grafted cycle (`snarl` only). They are laid out beside
## the ladder, not inside it.
var _cycle_vertices: Array = []
## Emission is OFF in the shipped look — the materials set `emission` but never
## `emission_enabled`, so it never lit anything. Kept false by default so the
## pre-promotion render is untouched; `emissive:true` from a map turns it on.
var _emissive: bool = false
## Bumped on every graph build so an in-flight process_queue coroutine that wakes
## after a rebuild retires instead of colouring nodes that no longer exist.
var _run_generation: int = 0
## Top of the built body in local metres — captions hang off this, never off a
## hard-coded number (`stair` raises it, `flat` drops it to 0.15).
var _body_top: float = 0.0

func _ready() -> void:
	setup_environment()
	_build_all()
	_built = true

	if auto_start:
		call_deferred("start_algorithm")


## The whole graph build, SYNCHRONOUS, from @export values alone. No call_deferred
## anywhere in here: a deferred rebuild that removes children first makes the grid's
## auto-grounding measure a zero AABB and bail.
func _build_all() -> void:
	initialize_graph()
	create_visual_elements()


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()
	vertex_nodes.clear()
	edge_lines.clear()
	level_indicators.clear()
	info_label = null
	queue_label = null
	order_label = null
	_build_all()


## Track a node this script owns, then parent it. Everything that goes through
## here comes back out in _rebuild_now.
func _track(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n

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
	in_degrees.clear()
	sorted_order.clear()
	queue.clear()
	level = 0
	level_vertices.clear()
	_cycle_vertices.clear()
	algorithm_running = false
	algorithm_step = 0
	_run_generation += 1

	# Generate the dependency set this axis value names
	generate_random_dag()
	
	# Initialize in-degrees
	for vertex in vertices:
		in_degrees[vertex] = 0
	
	# Calculate in-degrees
	for edge in edges:
		in_degrees[edge.to] += 1

## The axis lives here. The vertex COUNT never changes — what changes is how much
## order the arrows between them force, which is the whole content of the word.
func generate_random_dag() -> void:
	# Create vertices
	for i in range(graph_size):
		var vertex: String = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []

	match precedence:
		"stair":
			_edges_stair()
		"flat":
			pass  # the point: no edges at all
		"lens":
			_edges_lens()
		"snarl":
			_edges_snarl()
		_:
			_edges_levels()


## Add one arrow by vertex index. Accepts from > to — `snarl` needs that and it is
## the one value allowed to break the acyclic promise.
func _add_edge(from_index: int, to_index: int) -> void:
	if from_index < 0 or to_index < 0:
		return
	if from_index >= graph_size or to_index >= graph_size or from_index == to_index:
		return
	var from_vertex: String = "v" + str(from_index)
	var to_vertex: String = "v" + str(to_index)
	if has_edge(from_vertex, to_vertex):
		return
	edges.append({"from": from_vertex, "to": to_vertex})
	adjacency_list[from_vertex].append(to_vertex)


## levels — the shipped middling lattice, frozen. Off the default graph_size the
## original generator runs, but through a SEEDED RNG so it is still reproducible.
func _edges_levels() -> void:
	if graph_size == LEVELS_SIZE:
		for pair in LEVELS_EDGES:
			_add_edge(int(pair[0]), int(pair[1]))
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = LEVELS_SEED
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			if rng.randf() < edge_density:
				_add_edge(i, j)
	var additional_edges: int = 0
	var guard: int = 0
	while additional_edges < 2 and edges.size() < graph_size * (graph_size - 1) / 2 and guard < 256:
		guard += 1
		var i: int = rng.randi() % maxi(graph_size - 1, 1)
		var j: int = rng.randi() % maxi(graph_size - i - 1, 1) + i + 1
		var before: int = edges.size()
		_add_edge(i, j)
		if edges.size() > before:
			additional_edges += 1


## stair — a total order. Eight tiers of one vertex, every in-degree distinct,
## nothing reorderable. The maximum of the quantity the axis measures.
func _edges_stair() -> void:
	for i in range(graph_size - 1):
		_add_edge(i, i + 1)


## lens — one source, everything in the middle in parallel, one sink. The shape
## most real dependency graphs actually have; it reads instantly as a bottleneck.
func _edges_lens() -> void:
	var last: int = graph_size - 1
	if last < 2:
		return
	for i in range(1, last):
		_add_edge(0, i)
		_add_edge(i, last)


## snarl — the value that earns the axis. A ladder of sortable vertices PLUS a
## three-vertex ring whose in-degrees never reach zero, so the algorithm builds the
## case it declares impossible and leaves the residue standing.
func _edges_snarl() -> void:
	var k: int = graph_size - 3          # the sortable ladder
	for i in range(k - 2):
		_add_edge(i, i + 2)
	if k >= 5:
		# lift the last sortable vertex to in-degree 2 so the ladder is three
		# tiers deep and reads as an ordering, not a pair of rows
		_add_edge(k - 4, k - 1)

	if graph_size < 3:
		return
	var a: int = graph_size - 3
	var b: int = graph_size - 2
	var c: int = graph_size - 1
	_cycle_vertices = ["v" + str(a), "v" + str(b), "v" + str(c)]
	_add_edge(a, b)
	_add_edge(b, c)
	_add_edge(c, a)


func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if edge.from == from and edge.to == to:
			return true
	return false

func create_visual_elements() -> void:
	vertex_nodes.clear()
	edge_lines.clear()
	level_indicators.clear()

	# Create vertex spheres arranged in levels
	create_hierarchical_layout()

	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)

	# Create info labels
	create_info_labels()


## Tier pitch. `stair` is the only value that moves it — see PITCH_STAIR.
func _level_pitch() -> float:
	return PITCH_STAIR if precedence == "stair" else PITCH_DEFAULT


func create_hierarchical_layout() -> void:
	var pitch: float = _level_pitch()

	# The ladder is every vertex the sort can actually reach. Under `snarl` the
	# ringed three are held out and staged separately — putting them on a tier
	# would claim an in-degree rank they will never earn.
	var ladder: Array = []
	for vertex in vertices:
		if not _cycle_vertices.has(vertex):
			ladder.append(vertex)

	# Group vertices by level based on in-degree
	var level_groups: Dictionary = {}
	for vertex in ladder:
		var vertex_level: int = int(in_degrees[vertex])
		if not level_groups.has(vertex_level):
			level_groups[vertex_level] = []
		level_groups[vertex_level].append(vertex)

	# Rank the distinct in-degrees into CONSECUTIVE tiers. For the shipped draw
	# the in-degrees are already 0,1,2,3 so this is the identity and the default
	# render is untouched; it is what stops `lens` (in-degrees 0,1,6) from
	# stranding its sink nine metres up with nothing under it.
	var keys: Array = level_groups.keys()
	keys.sort()

	for tier in range(keys.size()):
		var level_key: int = int(keys[tier])
		var level_vertices_list: Array = level_groups[level_key]
		var y_pos: float = float(tier) * pitch

		for i in range(level_vertices_list.size()):
			var vertex: String = str(level_vertices_list[i])
			var x_pos: float = (i - level_vertices_list.size() / 2.0) * 1.2
			_spawn_vertex(vertex, Vector3(x_pos, y_pos, 0.0))

			# Store level information
			level_vertices[vertex] = tier

		# Create level indicator
		create_level_indicator(tier, level_vertices_list.size(), y_pos, 0.0,
				get_level_color(tier))

	if precedence == "snarl":
		_build_cycle_clump()


## One vertex sphere plus the two labels PRINTED ON its +Z face.
##
## Child order is load-bearing: update_in_degree_display reaches for get_child(1).
func _spawn_vertex(vertex: String, pos: Vector3) -> void:
	var sphere := MeshInstance3D.new()
	sphere.name = "Vertex_" + vertex
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3
	sphere.mesh = sphere_mesh
	sphere.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = vertex_color
	material.emission = vertex_color * 0.3
	material.emission_enabled = _emissive
	sphere.material_override = material

	_track(sphere)
	vertex_nodes[vertex] = sphere

	# CAPTION PLACEMENT — these two are INK ON THE SPHERE, not hanging labels.
	# They sit 0.01 m off a 0.3 m face as two 0.055-0.06 m lines, so billboard is
	# set to DISABLED *explicitly*: LabelFramer's own rule is that a label lying on
	# a body is integrated already and must be skipped. Naming that category
	# correctly is the rule, not a dodge — the alternative here is 16 opaque plates
	# hanging 0.25 m below the spheres, each one directly in front of the
	# translucent level plane of the tier beneath.
	var label := Label3D.new()
	label.text = vertex
	label.font_size = 11
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.position = Vector3(0.0, 0.045, 0.16)
	sphere.add_child(label)

	# Add in-degree label
	var in_degree_label := Label3D.new()
	in_degree_label.text = "in:" + str(in_degrees[vertex])
	in_degree_label.font_size = 12
	in_degree_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	in_degree_label.position = Vector3(0.0, -0.045, 0.16)
	sphere.add_child(in_degree_label)


## `snarl` only: the three ringed vertices, standing beside the ladder as a
## triangle on their own red plane. They are laid out as a closed loop on purpose —
## three arrows chasing each other is the one picture a topological sort cannot
## flatten, and it is the picture the sequence's connectivity room needs so
## tarjan's success can hang next to this failure on the same input.
func _build_cycle_clump() -> void:
	var cx: float = CYCLE_OFFSET_X
	var by: float = CYCLE_BASE_Y
	var spots: Array = [
		Vector3(cx - CYCLE_SPREAD, by, 0.0),
		Vector3(cx + CYCLE_SPREAD, by, 0.0),
		Vector3(cx, by + CYCLE_RISE, 0.0),
	]
	for i in range(_cycle_vertices.size()):
		var vertex: String = str(_cycle_vertices[i])
		_spawn_vertex(vertex, spots[i % spots.size()])
		level_vertices[vertex] = -1

	create_level_indicator(-1, 3, by, cx, CYCLE_PLANE_COLOR)


func create_level_indicator(level_num: int, vertex_count: int, y_pos: float,
		center_x: float, color: Color) -> void:
	var indicator := MeshInstance3D.new()
	indicator.name = "Level_" + str(level_num)
	indicator.mesh = create_level_plane(y_pos, vertex_count, center_x)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.1
	material.emission_enabled = _emissive
	material.flags_transparent = true
	material.flags_unshaded = true
	indicator.material_override = material

	_track(indicator)
	level_indicators.append(indicator)

func create_level_plane(y_pos: float, vertex_count: int, center_x: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices_array := PackedVector3Array()
	var indices := PackedInt32Array()

	var width: float = maxf(2.0, vertex_count * 1.2)

	# Create plane vertices
	vertices_array.append(Vector3(center_x - width/2, y_pos - 0.1, -0.5))
	vertices_array.append(Vector3(center_x + width/2, y_pos - 0.1, -0.5))
	vertices_array.append(Vector3(center_x + width/2, y_pos - 0.1, 0.5))
	vertices_array.append(Vector3(center_x - width/2, y_pos - 0.1, 0.5))

	# Create indices for two triangles
	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(0)
	indices.append(2)
	indices.append(3)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func get_level_color(level_num: int) -> Color:
	var colors = [level_1_color, level_2_color, level_3_color, level_4_color, level_5_color]
	return colors[level_num % colors.size()]

func create_edge_visual(edge: Dictionary) -> void:
	var from_pos = vertex_nodes[edge.from].position
	var to_pos = vertex_nodes[edge.to].position
	
	var line := MeshInstance3D.new()
	line.name = "Edge_" + edge.from + "_" + edge.to
	line.mesh = create_arrow_mesh(from_pos, to_pos)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission = edge_color * 0.2
	material.emission_enabled = _emissive
	line.material_override = material

	_track(line)
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
	# The shipped expression collapses to the zero vector for a VERTICAL arrow
	# (direction.x and direction.z both zero) and the head disappears. No edge in
	# the default `levels` draw is vertical, so this changes nothing there — but
	# `stair` is nothing BUT vertical arrows and `snarl`'s ladder has two.
	var perpendicular: Vector3 = Vector3(-direction.z, 0, direction.x)
	if perpendicular.length() < 0.0001:
		perpendicular = Vector3(0, 0, 1)
	perpendicular = perpendicular.normalized()

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

## Top of everything this build put on the floor, in local metres. Measured, never
## assumed: `stair` lifts it to ~5.75 m and `flat` drops it to 0.15 m, and a caption
## that clears at the default and crosses at another value is exactly the failure
## the placement probe exists to catch.
func _measure_body_top() -> float:
	var top: float = -INF
	for n in _created:
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var box: AABB = mi.get_aabb()
			top = maxf(top, mi.position.y + box.position.y + box.size.y)
	if top == -INF:
		return 0.0
	return top


## CAPTION PLACEMENT — one nameplate, above the body, out of the viewing corridor.
##
## These three were authored at a hard-coded y = 6 / 5.5 / 5 with billboard left at
## its DEFAULT of DISABLED, which meant LabelFramer._framable rejected all three and
## they rendered as see-through glyphs floating over the graph. That was an accident
## of the default, not a decision, so it is fixed in the opposite direction from the
## per-vertex labels: these genuinely hang, so they say so, and get real plates.
##
## The stack is then rebuilt to MERGE. Same parent, same column (x = z = 0), gaps of
## 0.11 m — inside LabelFramer.MERGE_GAP (0.16) — so _plate_group issues ONE panel
## spanning the whole block instead of three shingled cards. At the default it runs
## about 4.81..5.19 m, clearing the 4.65 m body top by ~0.16 m. `order_label` grows
## to ~34 characters as the sort completes, so the plate is ~1.7 m wide over a 3.75 m
## body — wide, but entirely above it, and its frontal overlap is zero at every
## value because the base is taken from _measure_body_top and not from a number.
func create_info_labels() -> void:
	_body_top = _measure_body_top()
	var base_y: float = _body_top + CAPTION_LIFT

	# Bottom-up, so the block reads info / queue / order top-down as authored.
	order_label = _hanging_label("Sorted Order: []", 16, base_y)
	queue_label = _hanging_label("Queue: []", 16, base_y + CAPTION_STEP)
	info_label = _hanging_label("Topological Sort: Dependency Ordering", 20,
			base_y + CAPTION_STEP * 2.0)


func _hanging_label(text: String, font_size: int, y: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	# Declare the hanging category explicitly — this is what asks the framer for a
	# plate. It sets billboard back to DISABLED itself once the panel is behind it.
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, y, 0.0)
	_track(label)
	return label

func start_algorithm() -> void:
	if algorithm_running:
		return
	
	algorithm_running = true
	algorithm_step = 0
	sorted_order.clear()
	queue.clear()
	
	# Reset all vertices
	for vertex in vertices:
		update_vertex_color(vertex, vertex_color)
	
	# Find vertices with in-degree 0
	for vertex in vertices:
		if in_degrees[vertex] == 0:
			queue.append(vertex)
			update_vertex_color(vertex, ready_color)
	
	update_queue_display()
	call_deferred("process_queue")

func process_queue() -> void:
	# A rebuild retires every coroutine started against the previous graph.
	var gen: int = _run_generation
	if not algorithm_running:
		# Stopped by hand or retired by a rebuild — leave whatever message the
		# stopper wrote. The shipped code overwrote it with "completed!".
		return
	if queue.is_empty():
		algorithm_running = false
		var stranded: int = vertices.size() - sorted_order.size()
		if stranded > 0:
			# `snarl` lands here and only `snarl` does: the ring's in-degrees never
			# reach zero, so the sort drains with vertices left over. Saying
			# "completed" would be the artifact lying about the one case that
			# proves the axis. Every other value sorts all 8 and reads as before.
			update_info_text("Halted — %d vertices unresolved (cycle)" % stranded)
		else:
			update_info_text("Topological sort completed!")
		return

	current_vertex = queue.pop_front()
	algorithm_step += 1
	
	# Process current vertex
	update_vertex_color(current_vertex, processing_color)
	update_info_text("Processing vertex: " + current_vertex)
	
	if step_by_step:
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(animation_delay).timeout
		if gen != _run_generation:
			return

	# Add to sorted order
	sorted_order.append(current_vertex)
	update_order_display()
	
	# Process neighbors
	for neighbor in adjacency_list[current_vertex]:
		in_degrees[neighbor] -= 1
		update_in_degree_display(neighbor)
		
		# Highlight dependency edge
		update_edge_color(current_vertex, neighbor, dependency_edge_color)
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(animation_delay * 0.5).timeout
		if gen != _run_generation:
			return

		# If in-degree becomes 0, add to queue
		if in_degrees[neighbor] == 0:
			queue.append(neighbor)
			update_vertex_color(neighbor, ready_color)
	
	# Mark as processed
	update_vertex_color(current_vertex, processed_color)
	update_queue_display()
	
	# Continue processing
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(animation_delay * 0.5).timeout
	if gen != _run_generation:
		return
	call_deferred("process_queue")

func update_vertex_color(vertex: String, color: Color) -> void:
	if vertex_nodes.has(vertex):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.3
		material.emission_enabled = _emissive
		vertex_nodes[vertex].material_override = material

func update_edge_color(from: String, to: String, color: Color) -> void:
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.2
		material.emission_enabled = _emissive
		edge_lines[edge_key].material_override = material

func update_in_degree_display(vertex: String) -> void:
	if vertex_nodes.has(vertex):
		var in_degree_label = vertex_nodes[vertex].get_child(1)  # Second child is in-degree label
		if in_degree_label and in_degree_label.text.begins_with("in:"):
			in_degree_label.text = "in:" + str(in_degrees[vertex])

func update_queue_display() -> void:
	if queue_label:
		queue_label.text = "Queue: " + str(queue)

func update_order_display() -> void:
	if order_label:
		order_label.text = "Sorted Order: " + str(sorted_order)

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
	update_info_text("Algorithm stopped. Sorted order: " + str(sorted_order))

func reset_algorithm() -> void:
	algorithm_running = false
	algorithm_step = 0
	# _rebuild_now, not a bare re-build: the old spheres, arrows and planes have to
	# come off the tree first or every reset stacked another copy on top of the last.
	_rebuild_now()
	update_info_text("Topological Sort: Dependency Ordering")

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Topological Sort",
		"description": "Orders vertices in a directed acyclic graph based on dependencies",
		"time_complexity": "O(V + E)",
		"space_complexity": "O(V)",
		"sorted_count": sorted_order.size(),
		"current_step": algorithm_step,
		"queue_size": queue.size()
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called by GridInteractablesComponent via call_deferred, AFTER _ready() and first
## in the deferred queue — so the artifact is already standing when this runs and
## this function's only job is to decide whether it has to stand differently.
##
## curation_station hands EVERY artifact it curates {"emissive": false} one line
## after framing its labels. That dict carries no axis key, so it must change no
## geometry — and `emissive` must still DO something rather than be accepted and
## dropped. It is applied in place, above the early returns.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_precedence: String = precedence
	var before_size: int = graph_size
	var before_density: float = edge_density

	if config_data.has("precedence"):
		precedence = _pick_axis(str(config_data["precedence"]), PRECEDENCES, precedence)
	if config_data.has("graph_size"):
		graph_size = clampi(int(config_data["graph_size"]), 3, 24)
	if config_data.has("edge_density"):
		edge_density = clampf(float(config_data["edge_density"]), 0.0, 1.0)

	# Non-geometry, applied IN PLACE so it lands whether or not we rebuild below.
	if config_data.has("emissive"):
		_emissive = bool(config_data["emissive"])
		_apply_emissive()

	if not _built:
		return
	if precedence == before_precedence and graph_size == before_size \
			and is_equal_approx(edge_density, before_density):
		return

	_rebuild_now()
	if auto_start:
		call_deferred("start_algorithm")
	print("[TopologicalSort] Config applied — precedence=%s, vertices=%d, edges=%d" % [
		precedence, vertices.size(), edges.size()])


## Accept an axis value only if it names something we actually build. A typo has to
## fall back to the shipped look — a half-recognised value would strand a placement
## with no dependency set at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Emission is off in the shipped materials (they set `emission` but never
## `emission_enabled`, so it lit nothing). Flipping the flag on the overrides that
## are already standing is the whole effect — no rebuild, no geometry touched.
func _apply_emissive() -> void:
	for n in _created:
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var mat: Material = mi.material_override
			if mat is StandardMaterial3D:
				(mat as StandardMaterial3D).emission_enabled = _emissive
