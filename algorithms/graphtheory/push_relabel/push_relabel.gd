class_name PushRelabel
extends Node3D

# @identity
# essence: preflow-push with height labels — initialize by saturating source edges, then repeatedly: push excess flow along admissible edges (height[u] > height[v]), or relabel (raise height) if no push is possible
# desire: to see water pile up at nodes and overflow downhill — excess flow accumulates, height labels rise, and the algorithm finds max flow by managing local floods rather than finding global paths
# critical_parameter: height[source] = |V| — the source starts at maximum height, creating initial pressure; excess flow at the sink accumulates into max_flow
# triggers: step-by-step animation with delay between operations; push operations highlighted in orange; active nodes (with excess) glow yellow; height and excess labels update per node
# emerges: the relabel operations create a "waterfall" effect where height labels propagate backward from sink to source, establishing the pressure gradient that drives flow forward
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (info, flow, operation labels; per-node height/excess labels)
# relationships: appears in GT_Flow; solves the same max-flow problem as networkflow3d's Edmonds-Karp but through local operations instead of global augmenting paths
# truth: push-relabel proves that maximum flow can be found without ever finding a complete path — local excess management is sufficient if you get the heights right

# Push-Relabel Algorithm: Maximum Flow
# Visualizes the preflow-based approach to finding maximum flow in networks
# Explores the concepts of excess flow, height labels, and push/relabel operations

@export_category("Push-Relabel Configuration")
@export var graph_size: int = 6  # Number of nodes
@export var edge_density: float = 0.5  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.2

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — the `relief` axis
# ═══════════════════════════════════════════════════════════════════
#
## Is the height function a NUMBER WRITTEN ON A NODE, or an ELEVATION THE NODE
## STANDS AT — and if it is an elevation, what landscape does it make?
##
## Push-relabel is named for a height function. Flow moves because one node is
## above another. The shipped artifact renders that entire idea as the two
## characters `h:0` in a font-12 label while all six nodes sit on one flat 4 m
## ring, so the algorithm's central quantity exists nowhere in space.
##
## This is the honest temporal->standing conversion, not a tempo knob: nothing
## here changes how fast the run animates. What changes is WHERE THE RUN ENDED UP,
## built as terrain.
##
##   flat      the shipped arrangement — six 0.4 m spheres on a 4 m ring, all at
##             y = 0, height and excess readable only as small text.
##   terraced  every node lifted to its FINAL push-relabel height x 0.5 m, each on
##             its own tread: the ring becomes a stepped landscape ~3 m tall, sink
##             at 0, source at the top, and every edge visibly runs downhill.
##   scarp     the initial preflow state built as terrain instead of narrated —
##             only the source lifted, on a solid 3 m column (height |V| = 6 steps),
##             the other five still at 0. One cliff at the ring's edge.
##   shaft     the sink dropped 2 m into a 1 m-wide shaft through a floor collar,
##             the rest standing at their final heights: a ~5 m total drop with the
##             flow running down into a hole. A sink is a hole.
##
## The elevations are solved SYNCHRONOUSLY at build time by running the same push
## and relabel rules to completion into a private copy of the state. The live
## `height` dictionary is never used for geometry — it mutates as the animation
## runs, and driving elevation from it would make this a time-domain axis whose
## still photographs an arbitrary phase.
@export_enum("flat", "terraced", "scarp", "shaft") var relief: String = "flat"

## Allow-list. A token outside it is a typo and falls back to the shipped flat
## ring rather than stranding a placement on a landscape nobody asked for.
const RELIEFS: PackedStringArray = ["flat", "terraced", "scarp", "shaft"]

## Metres of elevation per unit of push-relabel height. At |V| = 6 the source
## stands at 3.0 m — big enough that the landscape reads across a room, small
## enough that a 4 m ring still looks like a ring and not a tower.
const STEP_M: float = 0.5
## `shaft`: how far the sink is dropped below the ring plane.
const SHAFT_DEPTH: float = 2.0
## `shaft`: the hole is 1 m wide — radius 0.5 — and the collar around it is the
## floor the hole is a hole IN. Without the collar the shaft is a hanging tube.
const SHAFT_RADIUS: float = 0.5
const SHAFT_COLLAR: float = 1.15
## Radius of the tread each raised node stands on (`terraced`, `shaft`) and of the
## `scarp` column. Wider than the 0.2 m sphere so the node reads as standing ON
## something rather than skewered by it.
const TREAD_RADIUS: float = 0.30
## The scarp is a monolith, not a taller tread — wider than TREAD_RADIUS on
## purpose, so `scarp` and `terraced` are not two readings of the same pillar.
const COLUMN_RADIUS: float = 0.45
## A node is only given a tread once it is clearly off the ground plane.
const TREAD_MIN: float = 0.10

## Offline-solve guards. This implementation pushes only along FORWARD edges — it
## never builds the reverse residual arcs that bound classical push-relabel — so a
## node whose excess cannot reach the sink would relabel upward forever. Two honest
## limits: a node that would have to rise above the source (which it can never
## return flow to) is declared stuck and dropped, and the whole solve is capped.
## Both mean the terrain's ceiling is the source, exactly as the algorithm claims.
const SOLVE_MAX_STEPS: int = 20000

## Fixed seed, not randomize(). The network is generated with randf()/randi(), so
## without this two builds of one axis value differ and the pixel critic reads
## noise as signal. Reseeded at the head of every generate_random_network() call,
## so all four relief values stand on the SAME graph and differ only in elevation.
const BUILD_SEED: int = 20260729
var _rng := RandomNumberGenerator.new()

# ── CAPTION PLACEMENT ────────────────────────────────────────────────
# LabelFramer turns every HANGING Label3D into an opaque anthracite plate with a
# bezel at spawn. This artifact carries twenty-plus labels in three categories,
# and framing them where they were authored would bury the graph:
#
#   per-node (name / h: / e:)  authored hanging beside each 0.4 m sphere ->
#       eighteen plates standing in the ring plane, each in front of the nodes
#       behind it. They now lie ON the sphere face, billboard disabled. The `h:`
#       and `e:` values are this axis's own subject; they belong on the body whose
#       elevation encodes them.
#   per-edge (c:N)  authored hanging at the edge midpoint + 0.3 m -> ~15 cards
#       floating at node height across the middle of the ring, the worst
#       offenders. They are now printed ALONG the line like a road marking,
#       billboard disabled, offset 0.06 m to one side.
#   the three root captions  authored as three separate plates at y = 4 / 3.5 / 3.
#       They stay hanging (billboard ENABLED, so the framer does its job) but
#       restack into one 0.11 m-gapped column above the body, which merges to ONE
#       nameplate.
#
# Billboard-disabled here is not a dodge of the framer: the framer's own rule is
# that a label lying on a surface is integrated already. These lie on spheres and
# on lines.
#
## Caption column offsets above the BUILT body top. Measured from the AABB, never
## hard-coded: `terraced` raises the body to ~3.2 m, `scarp` likewise, and `shaft`
## extends it 2 m DOWNWARD — a fixed caption height passes at the default and
## fails at three of four values.
const CAP_GAP_INFO: float = 0.55
const CAP_GAP_FLOW: float = 0.44
const CAP_GAP_OP: float = 0.33
## Sideways offset of a capacity numeral from the line it is printed along.
const EDGE_LABEL_OFFSET: float = 0.06

@export_category("Visualization")
@export var show_excess_flow: bool = true
@export var show_height_labels: bool = true
@export var show_flow_values: bool = true
@export var show_capacity_labels: bool = true
@export var highlight_active_nodes: bool = true
@export var animate_push_operations: bool = true
@export var show_residual_graph: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_capacity_editing: bool = true
@export var real_time_flow_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var node_color: Color = Color(0.3, 0.5, 0.8, 1.0)
@export var source_color: Color = Color(0.2, 0.8, 0.2, 1.0)
@export var sink_color: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var active_color: Color = Color(0.9, 0.9, 0.2, 1.0)  # Nodes with excess
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var flow_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var residual_color: Color = Color(0.3, 0.9, 0.3, 0.8)
@export var push_highlight_color: Color = Color(0.9, 0.5, 0.2, 1.0)

# Graph representation
var nodes: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var capacity_matrix: Array = []
var flow_matrix: Array = []
var source: String = ""
var sink: String = ""

# Push-Relabel algorithm state
var height: Dictionary = {}
var excess: Dictionary = {}
var active_nodes: Array = []
var max_flow: int = 0
var algorithm_running: bool = false
var algorithm_step: int = 0
var current_operation: String = ""

# Visual elements
var node_spheres: Dictionary = {}
var edge_lines: Dictionary = {}
var flow_particles: Array = []
var info_label: Label3D
var flow_label: Label3D
var operation_label: Label3D

## Per-node caption refs. The old code reached for sphere.get_child(1) and (2),
## which silently breaks the moment anything else is parented to a node.
var node_height_labels: Dictionary = {}
var node_excess_labels: Dictionary = {}

## The elevation each node stands at under the current relief. Solved once at
## build time; NEVER read from the live `height` dictionary.
var _elevation: Dictionary = {}

## Only the nodes THIS SCRIPT created. Grid-added label plates, packaging and tag
## markers are somebody else's children and must survive a rebuild.
var _owned: Array[Node] = []
var _built: bool = false

## Which run the animation loop belongs to. A rebuild retires the old run: the
## loop awaits a timer, so it is not in the deferred queue and cannot be cancelled
## — it has to notice on its own that it has been superseded, or two loops end up
## stepping the same graph at twice the speed.
var _run_gen: int = 0


func _ready() -> void:
	_build_all()
	_built = true

	if auto_start:
		call_deferred("start_algorithm")


## Everything geometric, synchronously, from the @export values alone — so the
## sweep can set `relief` before add_child and get that variant with no config
## call and no deferred frame.
func _build_all() -> void:
	setup_environment()
	initialize_graph()
	create_visual_elements()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called by GridInteractablesComponent via call_deferred, AFTER _ready().
##
## curation_station.gd hands every artifact it curates {"emissive": false} one line
## after framing its labels. An unconditional rebuild there would throw that
## framing away, so a config that changes no geometry key returns without touching
## the tree.
##
## `emissive` is deliberately NOT accepted. This artifact assigns material.emission
## but never sets emission_enabled, so emission is inert in the shipped look;
## wiring the key would either do nothing (an accepted key that no-ops) or light
## the whole graph up and change the default render. Refusing it is the honest
## option — the dict falls through to the unchanged-keys return below.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_relief: String = relief
	var before_size: int = graph_size
	var before_density: float = edge_density

	if config_data.has("relief"):
		relief = _pick_axis(str(config_data["relief"]), RELIEFS, relief)
	if config_data.has("graph_size"):
		graph_size = clampi(int(config_data["graph_size"]), 3, 12)
	if config_data.has("edge_density"):
		edge_density = clampf(float(config_data["edge_density"]), 0.05, 1.0)

	if not _built:
		return
	var same_relief: bool = (relief == before_relief)
	var same_size: bool = (graph_size == before_size)
	var same_density: bool = is_equal_approx(edge_density, before_density)
	if same_relief and same_size and same_density:
		return  # curation_station's {"emissive": false} lands here: touch nothing.

	_rebuild_now()
	print("[PushRelabel] Config applied — relief=%s, graph_size=%d" % [relief, graph_size])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown + rebuild. No call_deferred in the build path: a deferred
## rebuild that removes children first makes _auto_ground_artifact measure a ZERO
## AABB and bail, leaving the artifact floating.
func _rebuild_now() -> void:
	algorithm_running = false
	_run_gen += 1
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	node_spheres.clear()
	edge_lines.clear()
	node_height_labels.clear()
	node_excess_labels.clear()
	flow_particles.clear()
	_elevation.clear()
	info_label = null
	flow_label = null
	operation_label = null

	_build_all()

	if auto_start:
		call_deferred("start_algorithm")


## add_child + remember. Freeing get_children() would destroy grid-added plates.
func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func setup_environment() -> void:
	# Add lighting
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	light.light_energy = 1.2
	_own(light)

	# Add ambient lighting
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.background_mode = Environment.BG_COLOR
	_own(ambient)

	# Add camera
	var camera := Camera3D.new()
	camera.name = "AlgorithmCamera"
	camera.position = Vector3(8.0, 6.0, 12.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	_own(camera)

func initialize_graph() -> void:
	nodes.clear()
	edges.clear()
	adjacency_list.clear()
	height.clear()
	excess.clear()
	active_nodes.clear()
	max_flow = 0
	algorithm_running = false
	algorithm_step = 0
	current_operation = ""

	# Generate random flow network
	generate_random_network()

	# Initialize algorithm state
	for node in nodes:
		height[node] = 0
		excess[node] = 0

func generate_random_network() -> void:
	# Determinism: same graph on every build, so the four relief values are the
	# same network at four elevations and nothing else.
	_rng.seed = BUILD_SEED

	# Create nodes
	for i in range(graph_size):
		var node = "n" + str(i)
		nodes.append(node)
		adjacency_list[node] = []

	# Set source and sink
	source = nodes[0]
	sink = nodes[graph_size - 1]

	# Initialize matrices
	capacity_matrix.resize(graph_size)
	flow_matrix.resize(graph_size)
	for i in range(graph_size):
		capacity_matrix[i] = []
		flow_matrix[i] = []
		for j in range(graph_size):
			capacity_matrix[i].append(0)
			flow_matrix[i].append(0)

	# Create edges with random capacities
	for i in range(graph_size):
		for j in range(graph_size):
			if i != j and _rng.randf() < edge_density:
				var capacity = _rng.randi() % 10 + 1
				edges.append({"from": nodes[i], "to": nodes[j], "capacity": capacity})
				adjacency_list[nodes[i]].append(nodes[j])
				capacity_matrix[i][j] = capacity

	# Ensure connectivity from source to sink
	ensure_connectivity()

func ensure_connectivity() -> void:
	# Add a path from source to sink if none exists
	var has_path = false
	for edge in edges:
		if edge.from == source and edge.to == sink:
			has_path = true
			break

	if not has_path:
		# Create a simple path through middle nodes
		var middle_nodes = nodes.slice(1, graph_size - 1)
		if middle_nodes.size() > 0:
			var path_node = middle_nodes[0]
			edges.append({"from": source, "to": path_node, "capacity": 5})
			edges.append({"from": path_node, "to": sink, "capacity": 5})
			adjacency_list[source].append(path_node)
			adjacency_list[path_node].append(sink)
			capacity_matrix[0][1] = 5
			capacity_matrix[1][graph_size - 1] = 5


# ═══════════════════════════════════════════════════════════════════
# RELIEF — the height function as elevation
# ═══════════════════════════════════════════════════════════════════

## Run this artifact's own push and relabel rules to completion into a PRIVATE
## copy of the state and return the final height vector. Nothing here touches
## `height`, `excess`, `flow_matrix` or `active_nodes` — the animation keeps its
## own run and is untouched by this.
func _solve_final_heights() -> Dictionary:
	var n: int = nodes.size()
	var h: Dictionary = {}
	var ex: Dictionary = {}
	for node in nodes:
		h[node] = 0
		ex[node] = 0
	var flow: Array = []
	for i in range(n):
		var row: Array = []
		for j in range(n):
			row.append(0)
		flow.append(row)

	# initialize_preflow, offline: the source starts at |V| and saturates outward.
	h[source] = n
	var active: Array = []
	var si: int = get_node_index(source)
	for edge in edges:
		if edge.from == source:
			var ti: int = get_node_index(edge.to)
			var cap: int = int(edge.capacity)
			flow[si][ti] = cap
			ex[edge.to] = int(ex[edge.to]) + cap
			ex[source] = int(ex[source]) - cap
			if edge.to != sink and not active.has(edge.to):
				active.append(edge.to)

	var guard: int = 0
	while not active.is_empty() and guard < SOLVE_MAX_STEPS:
		guard += 1
		var u: String = str(active[0])
		var ui: int = get_node_index(u)
		var pushed: bool = false
		for edge in edges:
			if edge.from == u and int(ex[u]) > 0:
				var v: String = str(edge.to)
				var vi: int = get_node_index(v)
				var residual: int = int(edge.capacity) - int(flow[ui][vi])
				if residual > 0 and int(h[u]) > int(h[v]):
					var amount: int = mini(int(ex[u]), residual)
					flow[ui][vi] = int(flow[ui][vi]) + amount
					ex[u] = int(ex[u]) - amount
					ex[v] = int(ex[v]) + amount
					if v != sink and not active.has(v):
						active.append(v)
					pushed = true
					break

		if not pushed and int(ex[u]) > 0:
			var min_h: int = -1
			for edge in edges:
				if edge.from == u:
					var v2: String = str(edge.to)
					var residual2: int = int(edge.capacity) - int(flow[ui][get_node_index(v2)])
					if residual2 > 0 and (min_h < 0 or int(h[v2]) < min_h):
						min_h = int(h[v2])
			# No residual out-edge at all, or the relabel would put this node above
			# the source it can never return flow to: stuck, and the terrain says so
			# by leaving it where it stands.
			if min_h < 0 or min_h + 1 > n:
				active.erase(u)
				continue
			h[u] = min_h + 1

		if int(ex[u]) <= 0:
			active.erase(u)

	return h


## The y each node stands at. Solved once, at build time.
func _compute_elevations() -> void:
	_elevation.clear()
	for node in nodes:
		_elevation[node] = 0.0

	match relief:
		"terraced":
			var final_h: Dictionary = _solve_final_heights()
			for node in nodes:
				_elevation[node] = float(int(final_h.get(node, 0))) * STEP_M
		"scarp":
			# The initial preflow, frozen: height[source] = |V|, everyone else 0.
			_elevation[source] = float(nodes.size()) * STEP_M
		"shaft":
			var final_h2: Dictionary = _solve_final_heights()
			for node in nodes:
				_elevation[node] = float(int(final_h2.get(node, 0))) * STEP_M
			_elevation[sink] = -SHAFT_DEPTH
		_:
			pass  # flat: the shipped ring, every node at y = 0


## Terrain the relief needs under (or around) the nodes.
func _build_relief_terrain(ring_radius: float, angle_step: float) -> void:
	if relief == "flat":
		return

	var rock: StandardMaterial3D = StandardMaterial3D.new()
	rock.albedo_color = Color(0.26, 0.27, 0.32)
	rock.roughness = 0.9

	for i in range(nodes.size()):
		var node: String = str(nodes[i])
		var angle: float = float(i) * angle_step
		var px: float = cos(angle) * ring_radius
		var pz: float = sin(angle) * ring_radius
		var y: float = float(_elevation.get(node, 0.0))

		if relief == "scarp":
			if node != source:
				continue
			# One cliff: a solid column, not a stack of steps.
			_own(_pillar(Vector3(px, y * 0.5, pz), COLUMN_RADIUS, y, rock))
			continue

		if y > TREAD_MIN:
			# The tread the node stands on — this is what makes an elevation read
			# as terrain instead of a sphere that happens to float.
			_own(_pillar(Vector3(px, y * 0.5, pz), TREAD_RADIUS, y, rock))

	if relief == "shaft":
		var si: int = get_node_index(sink)
		var sa: float = float(si) * angle_step
		var sx: float = cos(sa) * ring_radius
		var sz: float = sin(sa) * ring_radius
		var dark: StandardMaterial3D = StandardMaterial3D.new()
		dark.albedo_color = Color(0.10, 0.10, 0.13)
		dark.roughness = 1.0

		# The collar IS the floor; without it the shaft is a hanging tube rather
		# than a hole in something. Culling disabled: a hand-built annulus is a
		# single flat surface and the viewer may well be above or below it.
		var collar_mat := StandardMaterial3D.new()
		collar_mat.albedo_color = Color(0.26, 0.27, 0.32)
		collar_mat.roughness = 0.9
		collar_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var collar := MeshInstance3D.new()
		collar.name = "Shaft_Collar"
		collar.mesh = _annulus_mesh(SHAFT_RADIUS, SHAFT_COLLAR, 40)
		collar.position = Vector3(sx, 0.0, sz)
		collar.material_override = collar_mat
		_own(collar)

		# The wall of the hole: an uncapped tube from the collar down past the sink.
		var wall := MeshInstance3D.new()
		wall.name = "Shaft_Wall"
		var tube := CylinderMesh.new()
		tube.top_radius = SHAFT_RADIUS
		tube.bottom_radius = SHAFT_RADIUS
		tube.height = SHAFT_DEPTH + 0.4
		tube.cap_top = false
		tube.cap_bottom = false
		tube.radial_segments = 32
		wall.mesh = tube
		wall.position = Vector3(sx, -(SHAFT_DEPTH + 0.4) * 0.5, sz)
		wall.material_override = dark
		_own(wall)

		var floor_disc := MeshInstance3D.new()
		floor_disc.name = "Shaft_Floor"
		var disc := CylinderMesh.new()
		disc.top_radius = SHAFT_RADIUS
		disc.bottom_radius = SHAFT_RADIUS
		disc.height = 0.04
		disc.radial_segments = 32
		floor_disc.mesh = disc
		floor_disc.position = Vector3(sx, -(SHAFT_DEPTH + 0.4), sz)
		floor_disc.material_override = dark
		_own(floor_disc)


func _pillar(centre: Vector3, radius: float, tall: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Relief_Pillar"
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = maxf(tall, 0.02)
	cyl.radial_segments = 20
	mi.mesh = cyl
	mi.position = centre
	mi.material_override = mat
	return mi


## A flat ring lying in the XZ plane, facing up — the floor the shaft goes through.
func _annulus_mesh(inner: float, outer: float, segments: int) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	for s in range(segments + 1):
		var a: float = TAU * float(s) / float(segments)
		verts.append(Vector3(cos(a) * inner, 0.0, sin(a) * inner))
		verts.append(Vector3(cos(a) * outer, 0.0, sin(a) * outer))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)

	for s in range(segments):
		var i0: int = s * 2
		var i1: int = s * 2 + 1
		var i2: int = s * 2 + 2
		var i3: int = s * 2 + 3
		indices.append(i0)
		indices.append(i2)
		indices.append(i1)
		indices.append(i1)
		indices.append(i2)
		indices.append(i3)

	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func create_visual_elements() -> void:
	node_spheres.clear()
	edge_lines.clear()
	node_height_labels.clear()
	node_excess_labels.clear()
	flow_particles.clear()

	_compute_elevations()

	# Create node spheres
	var radius: float = 2.0
	var angle_step: float = 2.0 * PI / float(nodes.size())

	for i in range(nodes.size()):
		var node: String = str(nodes[i])
		var angle: float = float(i) * angle_step
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		var y: float = float(_elevation.get(node, 0.0))

		var sphere := MeshInstance3D.new()
		sphere.name = "Node_" + node
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = 0.2
		sphere_mesh.height = 0.4
		sphere.mesh = sphere_mesh
		sphere.position = Vector3(x, y, z)

		var material := StandardMaterial3D.new()
		if node == source:
			material.albedo_color = source_color
		elif node == sink:
			material.albedo_color = sink_color
		else:
			material.albedo_color = node_color
		material.emission = material.albedo_color * 0.3
		sphere.material_override = material

		_own(sphere)
		node_spheres[node] = sphere

		# ── the node's three captions, ON its face ──────────────────
		# Authored hanging at y +0.5 / -0.5 / -0.7, which framed into three plates
		# per node standing in the ring plane. They are the sphere's own readout —
		# and `h:` in particular is the very quantity this axis turns into
		# elevation — so they belong printed on the body, billboard off.
		var label := Label3D.new()
		label.text = node
		label.font_size = 14
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.position = Vector3(0.0, 0.07, 0.21)
		sphere.add_child(label)

		var height_label := Label3D.new()
		height_label.text = "h:0"
		height_label.font_size = 12
		height_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		height_label.position = Vector3(0.0, -0.01, 0.21)
		sphere.add_child(height_label)
		node_height_labels[node] = height_label

		var excess_label := Label3D.new()
		excess_label.text = "e:0"
		excess_label.font_size = 12
		excess_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		excess_label.position = Vector3(0.0, -0.08, 0.21)
		sphere.add_child(excess_label)
		node_excess_labels[node] = excess_label

	# Terrain first, so the AABB the captions are placed against includes it.
	_build_relief_terrain(radius, angle_step)

	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)

	# Create info labels
	create_info_labels()

func create_edge_visual(edge: Dictionary) -> void:
	var from_pos: Vector3 = node_spheres[edge.from].position
	var to_pos: Vector3 = node_spheres[edge.to].position

	var line := MeshInstance3D.new()
	line.name = "Edge_" + edge.from + "_" + edge.to
	line.mesh = create_arrow_mesh(from_pos, to_pos)

	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission = edge_color * 0.2
	line.material_override = material

	_own(line)
	edge_lines[edge.from + "_" + edge.to] = line

	# ── the capacity numeral, PRINTED ALONG THE LINE ────────────────
	# Authored hanging at the midpoint + 0.3 m, which framed into ~15 opaque cards
	# floating at node height straight across the middle of the ring. A capacity
	# belongs to its edge: lay it in the plane that contains the edge and faces up,
	# running along the line, nudged 0.06 m to one side so it sits beside the line
	# rather than through it. Billboard off — this is ink on a surface, and the
	# framer's own rule leaves such labels alone.
	var capacity_label := Label3D.new()
	capacity_label.text = "c:" + str(edge.capacity)
	capacity_label.font_size = 10
	capacity_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED

	var mid: Vector3 = (from_pos + to_pos) * 0.5
	var dir: Vector3 = to_pos - from_pos
	if dir.length() < 0.0001:
		capacity_label.position = mid
		_own(capacity_label)
		return
	dir = dir.normalized()
	var up_ref: Vector3 = Vector3.UP
	if absf(dir.dot(up_ref)) > 0.98:
		up_ref = Vector3.FORWARD
	# Face normal: as close to straight up as the edge allows, so the numeral reads
	# like a road marking on the line even when the line runs downhill.
	var face: Vector3 = (up_ref - dir * dir.dot(up_ref)).normalized()
	var side: Vector3 = face.cross(dir).normalized()
	capacity_label.transform = Transform3D(Basis(dir, side, face),
		mid + side * EDGE_LABEL_OFFSET)
	_own(capacity_label)

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


## Top of the artifact's own geometry, measured from what was actually built.
## A hard-coded caption height would pass at `flat` (body top 0.2 m) and fail at
## `terraced` and `scarp` (~3.2 m).
func _body_top() -> float:
	var box: AABB = AABB()
	var seen: bool = false
	for n in _owned:
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var b: AABB = mi.transform * mi.get_aabb()
			if seen:
				box = box.merge(b)
			else:
				box = b
				seen = true
	if not seen:
		return 0.2
	return box.position.y + box.size.y


func create_info_labels() -> void:
	# THE ONLY HANGING CAPTIONS LEFT. Authored as three separate plates at
	# y = 4 / 3.5 / 3 with 0.5 m gaps — three cards orbiting the graph. Billboarded
	# (so the framer does frame them) and restacked into one 0.11 m-gapped column
	# just above the body, which is under LabelFramer's 0.16 m MERGE_GAP and so
	# fuses into a single nameplate. The column sits clear of the body's frontal
	# footprint at every relief value because it is measured from the built AABB.
	var top: float = _body_top()

	info_label = Label3D.new()
	info_label.text = "Push-Relabel Algorithm: Maximum Flow"
	info_label.font_size = 20
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.position = Vector3(0.0, top + CAP_GAP_INFO, 0.0)
	_own(info_label)

	flow_label = Label3D.new()
	flow_label.text = "Max Flow: 0"
	flow_label.font_size = 16
	flow_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flow_label.position = Vector3(0.0, top + CAP_GAP_FLOW, 0.0)
	_own(flow_label)

	operation_label = Label3D.new()
	operation_label.text = "Operation: Initializing"
	operation_label.font_size = 16
	operation_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	operation_label.position = Vector3(0.0, top + CAP_GAP_OP, 0.0)
	_own(operation_label)


# ═══════════════════════════════════════════════════════════════════
# RUN — untouched by the axis; the animation is the same animation
# ═══════════════════════════════════════════════════════════════════

func start_algorithm() -> void:
	if algorithm_running:
		return

	algorithm_running = true
	algorithm_step = 0
	max_flow = 0
	_run_gen += 1

	# Initialize preflow
	initialize_preflow()

	# Start push-relabel operations
	call_deferred("push_relabel_loop", _run_gen)

func initialize_preflow() -> void:
	# Set source height to number of nodes
	height[source] = len(nodes)

	# Saturate all edges from source
	for edge in edges:
		if edge.from == source:
			var flow = edge.capacity
			flow_matrix[0][get_node_index(edge.to)] = flow
			excess[edge.to] += flow
			excess[source] -= flow

			# Add to active nodes if not sink
			if edge.to != sink and edge.to not in active_nodes:
				active_nodes.append(edge.to)

	update_visuals()

func push_relabel_loop(gen: int = -1) -> void:
	var my_gen: int = gen if gen >= 0 else _run_gen
	if my_gen != _run_gen:
		return  # superseded by a rebuild — leave the current run alone
	if not algorithm_running or active_nodes.is_empty():
		algorithm_running = false
		max_flow = excess[sink]
		update_flow_display()
		update_operation_text("Algorithm completed! Max flow: " + str(max_flow))
		return

	# Select active node (first in list)
	var u = active_nodes[0]
	current_operation = "Processing node: " + u

	# Try to push flow
	var pushed = false
	for edge in edges:
		if edge.from == u and excess[u] > 0:
			var v = edge.to
			var residual_capacity = edge.capacity - flow_matrix[get_node_index(u)][get_node_index(v)]

			if residual_capacity > 0 and height[u] > height[v]:
				# Push operation
				var push_amount = min(excess[u], residual_capacity)
				flow_matrix[get_node_index(u)][get_node_index(v)] += push_amount
				excess[u] -= push_amount
				excess[v] += push_amount

				# Add to active nodes if not sink
				if v != sink and v not in active_nodes:
					active_nodes.append(v)

				pushed = true
				update_operation_text("Push: " + str(push_amount) + " from " + u + " to " + v)
				highlight_push_operation(u, v)
				break

	if not pushed and excess[u] > 0:
		# Relabel operation
		var min_height = INF
		for edge in edges:
			if edge.from == u:
				var v = edge.to
				var residual_capacity = edge.capacity - flow_matrix[get_node_index(u)][get_node_index(v)]
				if residual_capacity > 0:
					min_height = min(min_height, height[v])

		if min_height != INF:
			height[u] = min_height + 1
			update_operation_text("Relabel: " + u + " height = " + str(height[u]))

	# Remove from active nodes if no excess
	if excess[u] <= 0:
		active_nodes.erase(u)

	update_visuals()
	algorithm_step += 1

	if step_by_step:
		await get_tree().create_timer(animation_delay).timeout
		if my_gen != _run_gen:
			return

	call_deferred("push_relabel_loop", my_gen)

func get_node_index(node: String) -> int:
	return nodes.find(node)

func highlight_push_operation(from: String, to: String) -> void:
	# Highlight the edge being used for push
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		var line: MeshInstance3D = edge_lines[edge_key]
		if not is_instance_valid(line):
			return
		var material := StandardMaterial3D.new()
		material.albedo_color = push_highlight_color
		material.emission = push_highlight_color * 0.5
		line.material_override = material

func update_visuals() -> void:
	# Update node colors based on state
	for node in nodes:
		if not node_spheres.has(node):
			continue
		var sphere: MeshInstance3D = node_spheres[node]
		if not is_instance_valid(sphere):
			continue
		var material := StandardMaterial3D.new()

		if node == source:
			material.albedo_color = source_color
		elif node == sink:
			material.albedo_color = sink_color
		elif node in active_nodes:
			material.albedo_color = active_color
		else:
			material.albedo_color = node_color

		material.emission = material.albedo_color * 0.3
		sphere.material_override = material

		# Update height and excess labels — by reference, not by child index.
		var height_label: Label3D = node_height_labels.get(node, null) as Label3D
		var excess_label: Label3D = node_excess_labels.get(node, null) as Label3D
		if is_instance_valid(height_label):
			height_label.text = "h:" + str(height[node])
		if is_instance_valid(excess_label):
			excess_label.text = "e:" + str(excess[node])

	# Update edge colors based on flow
	for edge in edges:
		var edge_key = edge.from + "_" + edge.to
		if edge_lines.has(edge_key):
			var line: MeshInstance3D = edge_lines[edge_key]
			if not is_instance_valid(line):
				continue
			var flow = flow_matrix[get_node_index(edge.from)][get_node_index(edge.to)]
			var material := StandardMaterial3D.new()

			if flow > 0:
				material.albedo_color = flow_color
				material.emission = flow_color * 0.3
			else:
				material.albedo_color = edge_color
				material.emission = edge_color * 0.2

			line.material_override = material

func update_flow_display() -> void:
	if is_instance_valid(flow_label):
		flow_label.text = "Max Flow: " + str(max_flow)

func update_operation_text(text: String) -> void:
	if is_instance_valid(operation_label):
		operation_label.text = "Operation: " + text

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
	update_operation_text("Algorithm stopped")

func reset_algorithm() -> void:
	# Through _rebuild_now, so the old visuals are actually removed. The previous
	# version re-ran create_visual_elements and only swept children whose names
	# began Node_/Edge_/Flow_, leaving every caption behind to accumulate.
	_rebuild_now()
	update_operation_text("Initializing")

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Push-Relabel Algorithm",
		"description": "Preflow-based algorithm for finding maximum flow",
		"time_complexity": "O(V²E)",
		"space_complexity": "O(V + E)",
		"max_flow": max_flow,
		"current_step": algorithm_step,
		"active_nodes": active_nodes.size(),
		"relief": relief
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
