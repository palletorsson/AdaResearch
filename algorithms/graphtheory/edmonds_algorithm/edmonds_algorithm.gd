class_name EdmondsAlgorithm
extends Node3D

# @identity
# essence: greedy maximum matching — iterate edges in order; if both endpoints are unmatched, add the edge to the matching; matched vertices turn green, matching edges turn red
# desire: to watch pairs form across a graph — each matched edge is a partnership, and the unmatched vertices that remain are the ones the graph's structure could not pair
# critical_parameter: coupling — what the graph's structure permits of pairing; partial leaves a few over, perfect pairs everyone, stranded pairs almost no one, blossom builds the odd cycle greed cannot solve
# triggers: step-by-step animation highlights each edge in yellow before accepting (green) or skipping it; matching_size counter tracks progress; ui_accept toggles start/stop
# emerges: the greedy order matters — different edge orderings produce different matchings, and the greedy result is not always maximum; the gap between greedy and optimal reveals augmenting path opportunities
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [has] (info_label, matching_label, vertex labels)
# relationships: synthesis artifact in GT_Matching; contrasts with flow-based matching approaches; the symmetry of the room layout mirrors the pairing theme
# truth: matching is the mathematics of pairing — who connects with whom, who remains alone, and whether the graph's structure permits everyone to find a partner

# Edmonds' Algorithm: Maximum Matching (Simplified Greedy Version)
# For demonstration purposes, using a greedy matching approach

@export_category("Edmonds Configuration")
@export var graph_size: int = 10
@export var edge_density: float = 0.35
@export var auto_start: bool = true
@export var animation_speed: float = 0.5

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — the `coupling` axis
# ═══════════════════════════════════════════════════════════════════
#
# This artifact is not the flow/cut member of the family its filename suggests. It is
# MAXIMUM MATCHING, and its question is who can be paired and who is stranded. The axis
# therefore varies the EDGE SET (and, for `blossom`, the STAGING) — never the animation.
# The greedy pass steps at animation_speed and a still photographs the opening frames,
# so a star, five disjoint diameters and a pentagon-inside-a-ring have to be three
# unmistakably different pictures at frame one. They are.
#
#   partial   the shipped graph — ten spheres on the 6 m ring, edge_density rolled over
#             the 45 candidate chords, greedy leaving a couple of vertices unmatched.
#             (The .tscn overrides edge_density to 0.30 and unmatched_color to red, so
#             the shipped still is ~13 chords in red, not the script defaults' ~16 in
#             orange. The scene is the truth; nothing here overrides it.)
#   perfect   five disjoint diameters first, six decoy chords after; everyone pairs and
#             the matched edges cross the middle as a clean five-line star.
#   stranded  a star: one hub joined to all nine others and no other edge. Maximum
#             matching is ONE edge. Structure deciding pairing at its harshest.
#   blossom   an odd cycle staged as a 2 m pentagon inside the 6 m ring, each of its
#             vertices carrying a pendant leaf out on the ring. Edmonds' own case: the
#             optimum pairs all ten, this greedy pass strands four.
#
# The word is `coupling` and not `pairing` because `pair` is already a live VALUE in
# room_shape_demonstrator's `plan` ladder, and pair/pairing is the uptake/upkeep trap.
## What the graph's structure permits of pairing.
@export_enum("partial", "perfect", "stranded", "blossom") var coupling: String = "partial"

## Allow-list for _pick_axis. A typo in a map token falls back to the legacy look
## rather than half-recognising a value and stranding the placement with no graph.
const COUPLINGS: PackedStringArray = ["partial", "perfect", "stranded", "blossom"]

## `partial` is the only value that draws from a distribution, and two builds of one
## axis value must be pixel-identical or the pixel critic reads noise as signal. The
## generator still honours edge_density — it is just no longer a different graph every
## launch. Nothing else in the build touches randf/randi.
const GRAPH_SEED: int = 20260729

## The 6 m-diameter ring every value stands on, and the 2 m-diameter pentagon that
## `blossom` stages inside it. The inner cycle sits at the ring's own y, so the body
## stays flat and 0.4 m tall at every value.
const RING_RADIUS: float = 3.0
const BLOSSOM_RADIUS: float = 1.0

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var matched_color: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var unmatched_color: Color = Color(0.9, 0.5, 0.2, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.6)
@export var matching_edge_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var current_edge_color: Color = Color(0.9, 0.9, 0.2, 1.0)
## Curation hands every artifact it curates {"emissive": false}. Here that switches the
## glow off the spheres and the chords IN PLACE — it is not a rebuild key.
@export var emissive: bool = true

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}

# Matching state
var matching: Dictionary = {}  # vertex -> matched_vertex (or null)
var algorithm_running: bool = false
var matching_size: int = 0

# Non-blocking state
var current_edge_index: int = 0
var step_timer: float = 0.0

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var info_label: Label3D
var matching_label: Label3D

## Every node THIS script created for the graph, so a rebuild frees its own work and
## never the plates the grid added afterwards. The environment (light, world env,
## camera) is built once and deliberately kept out of this list.
var _created: Array[Node] = []
var _built: bool = false


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

	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.background_mode = Environment.BG_COLOR
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	add_child(ambient)

	var camera := Camera3D.new()
	camera.position = Vector3(8.0, 6.0, 12.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)


## SYNCHRONOUS, from the @export values alone. No call_deferred anywhere in the build
## path: a deferred rebuild that removes children first makes auto-grounding measure a
## zero AABB and bail.
func _build_all() -> void:
	initialize_graph()
	create_visual_elements()

func initialize_graph() -> void:
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	matching.clear()
	algorithm_running = false
	matching_size = 0
	current_edge_index = 0

	generate_random_graph()

	# Initialize matching - all vertices start unmatched
	for vertex in vertices:
		matching[vertex] = null


## How many vertices this value needs. `perfect` needs an even count to pair off,
## `blossom` needs an ODD cycle plus one leaf each, so both round graph_size to the
## nearest shape their claim is true at instead of silently building a broken one.
func _vertex_count() -> int:
	if coupling == "perfect":
		return maxi(4, (graph_size / 2) * 2)
	if coupling == "blossom":
		return _blossom_cycle() * 2
	return maxi(2, graph_size)


## Largest odd cycle that fits in half the graph. Even would not be a blossom.
func _blossom_cycle() -> int:
	var c: int = graph_size / 2
	if c % 2 == 0:
		c -= 1
	return maxi(3, c)

func generate_random_graph() -> void:
	# Create vertices
	for i in range(_vertex_count()):
		var vertex = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []

	# The axis reads here: each value is a different EDGE SET over the same vertices.
	match coupling:
		"perfect":
			_edges_perfect()
		"stranded":
			_edges_stranded()
		"blossom":
			_edges_blossom()
		_:
			_edges_partial()


## The shipped graph: every candidate chord rolled against edge_density, in i<j order,
## from a fixed seed. Ten vertices give 45 candidates, so the scene's 0.30 lands around
## thirteen chords and the greedy pass leaves two to four vertices unmatched.
func _edges_partial() -> void:
	var n: int = vertices.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = GRAPH_SEED
	for i in range(n):
		for j in range(i + 1, n):
			if rng.randf() < edge_density:
				_add_edge(i, j)

	# Ensure minimum connectivity
	if edges.size() < n / 2:
		for i in range(n / 2):
			_add_edge(i, i + n / 2)


## Five disjoint diameters FIRST — the greedy pass takes them in order and finishes
## with nothing orange, so the still shows a complete pairing rather than a lucky one.
## The decoys go in after: short chords that can never be taken, there so the picture
## is a matching found inside a graph and not a graph that had no choice.
func _edges_perfect() -> void:
	var n: int = vertices.size()
	var half: int = n / 2
	for i in range(half):
		_add_edge(i, i + half)

	var k: int = 0
	while k < n:
		_add_edge(k, (k + 2) % n)
		k += 2
	_add_edge(1, 3)


## A star. One hub, a spoke to every other vertex, and nothing else. The maximum
## matching of a star is ONE edge no matter how many spokes there are — the sentence
## "the graph decides, not the greed" in a single picture.
func _edges_stranded() -> void:
	var n: int = vertices.size()
	for i in range(1, n):
		_add_edge(0, i)


## The odd cycle Edmonds' real algorithm exists for, with a pendant leaf on each of
## its vertices. The optimum is a perfect matching — every leaf to its cycle vertex.
## The cycle edges are listed first, so this greedy pass eats into the pentagon, cannot
## back out, and strands four leaves the optimum would have paired.
func _edges_blossom() -> void:
	var c: int = vertices.size() / 2
	for i in range(c):
		_add_edge(i, (i + 1) % c)
	for i in range(c):
		_add_edge(i, c + i)


func _add_edge(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or to_index < 0:
		return
	if from_index >= vertices.size() or to_index >= vertices.size():
		return
	var from_vertex: String = vertices[from_index]
	var to_vertex: String = vertices[to_index]
	if has_edge(from_vertex, to_vertex):
		return
	edges.append({"from": from_vertex, "to": to_vertex})
	adjacency_list[from_vertex].append(to_vertex)
	adjacency_list[to_vertex].append(from_vertex)

func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if (edge.from == from and edge.to == to) or (edge.from == to and edge.to == from):
			return true
	return false


## Where vertex i stands. Three of the four values share the ring exactly — the axis is
## carried by the chords drawn across it. `blossom` is the one that restages, because an
## odd cycle you cannot see is not evidence of anything: its cycle goes on a 2 m
## pentagon inside the ring and its leaves stay out on the 6 m ring, at the same y, so
## the body's height is unchanged.
func _vertex_position(index: int) -> Vector3:
	var n: int = maxi(vertices.size(), 1)
	if coupling == "blossom":
		var c: int = maxi(n / 2, 1)
		var step: float = TAU / float(c)
		if index < c:
			var a: float = float(index) * step
			return Vector3(cos(a) * BLOSSOM_RADIUS, 0.0, sin(a) * BLOSSOM_RADIUS)
		var b: float = float(index - c) * step
		return Vector3(cos(b) * RING_RADIUS, 0.0, sin(b) * RING_RADIUS)
	var angle: float = float(index) * TAU / float(n)
	return Vector3(cos(angle) * RING_RADIUS, 0.0, sin(angle) * RING_RADIUS)

func create_visual_elements() -> void:
	vertex_nodes.clear()
	edge_lines.clear()

	for i in range(vertices.size()):
		var vertex = vertices[i]

		var sphere := MeshInstance3D.new()
		sphere.name = "Vertex_" + vertex
		sphere.mesh = SphereMesh.new()
		(sphere.mesh as SphereMesh).radius = 0.2
		(sphere.mesh as SphereMesh).height = 0.4
		(sphere.mesh as SphereMesh).radial_segments = 16
		(sphere.mesh as SphereMesh).rings = 8
		sphere.position = _vertex_position(i)
		sphere.material_override = _vertex_material(unmatched_color)

		_track(sphere)
		vertex_nodes[vertex] = sphere

		# ON the sphere, not hanging beside it. A per-node caption becomes a per-node
		# OPAQUE plate under the framer and ten of them would bury the graph — but a
		# name printed on the front face of the ball it names is integrated already,
		# which is exactly the category the framer skips. 0.10 m of glyph on a 0.4 m
		# face, standing 0.01 m proud of a 0.2 m radius so it never z-fights.
		var label := Label3D.new()
		label.text = vertex
		label.font_size = 20
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.position = Vector3(0, 0, 0.21)
		label.modulate = Color(1, 1, 1, 0.9)
		sphere.add_child(label)

	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)

	# THE TWO ROOT CAPTIONS. They used to sit at y=5.0 and y=4.3 over a body that is
	# 0.4 m tall, so the sweep framed a 5.2 m column with a pancake at the bottom —
	# occlusion was never the problem, FRAMING was. Billboarded (so the framer plates
	# them properly) and dropped to 0.60 m and 0.48 m over the measured body top: a
	# 0.12 m gap in one column, which merges into ONE nameplate spanning roughly
	# 0.60..0.88 m. That clears the body by ~0.4 m and cuts the framed height to 1.1 m.
	var body_top: float = _measure_body_top()

	info_label = Label3D.new()
	info_label.text = "Maximum Matching - Press Space to Start"
	info_label.font_size = 24
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.position = Vector3(0, body_top + 0.60, 0)
	info_label.modulate = Color(1, 1, 1, 0.95)
	_track(info_label)

	matching_label = Label3D.new()
	matching_label.text = "Matching Size: 0"
	matching_label.font_size = 20
	matching_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	matching_label.position = Vector3(0, body_top + 0.48, 0)
	matching_label.modulate = Color(1, 1, 1, 0.9)
	_track(matching_label)


## Highest point of what was actually built, in this node's own space. Only `blossom`
## restages anything and it stages flat, so this returns 0.2 m at every value — but it
## is measured rather than assumed, because a caption placed from a remembered number
## is a caption that drifts the first time the geometry moves.
func _measure_body_top() -> float:
	var top: float = -INF
	var inv: Transform3D = global_transform.affine_inverse()
	var stack: Array = []
	for node in _created:
		stack.append(node)
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D:
			var mi: MeshInstance3D = cur
			if mi.mesh != null:
				var box: AABB = (inv * mi.global_transform) * mi.get_aabb()
				top = maxf(top, box.position.y + box.size.y)
		for c in cur.get_children():
			stack.append(c)
	if top == -INF:
		return 0.2
	return top

func create_edge_visual(edge: Dictionary) -> void:
	var from_pos: Vector3 = vertex_nodes[edge.from].position
	var to_pos: Vector3 = vertex_nodes[edge.to].position

	var line_container = Node3D.new()
	line_container.name = "Edge_" + edge.from + "_" + edge.to

	var line := MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	line.mesh = cylinder

	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission_enabled = emissive
	material.emission = edge_color * 0.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material

	line_container.add_child(line)

	# Local, not global. The chord has to sit between its two spheres wherever the
	# grid puts the artifact, and it has to be identical on every rebuild — a
	# global_position written before the placement is settled is neither.
	var midpoint: Vector3 = (from_pos + to_pos) * 0.5
	var distance: float = from_pos.distance_to(to_pos)
	line.scale.y = distance
	line_container.transform = Transform3D(_axis_basis(to_pos - from_pos), midpoint)

	_track(line_container)
	edge_lines[edge.from + "_" + edge.to] = line_container


## A basis whose +Y runs along `dir` — the cylinder's own axis. Built arithmetically
## rather than with look_at so it needs no global space and no deferred frame.
func _axis_basis(dir: Vector3) -> Basis:
	if dir.length_squared() < 0.000001:
		return Basis()
	var y_axis: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.UP
	if absf(y_axis.dot(ref)) > 0.999:
		ref = Vector3.RIGHT
	var x_axis: Vector3 = ref.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)


func _track(node: Node) -> void:
	_created.append(node)
	add_child(node)


func _vertex_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = emissive
	material.emission = color * 0.5
	material.emission_energy_multiplier = 1.5
	return material

func start_algorithm() -> void:
	if algorithm_running:
		return

	algorithm_running = true
	current_edge_index = 0
	matching_size = 0
	step_timer = 0.0

	# Reset all vertices to unmatched
	for vertex in vertices:
		matching[vertex] = null
		update_vertex_color(vertex, unmatched_color)

	# Reset all edges
	for edge_key in edge_lines.keys():
		update_edge_color_direct(edge_key, edge_color)

	update_info_text("Finding maximum matching...")
	update_matching_display()

func _process(delta: float) -> void:
	if not algorithm_running:
		return

	step_timer += delta
	if step_timer < animation_speed:
		return

	step_timer = 0.0
	process_matching_step()

func process_matching_step() -> void:
	if current_edge_index >= edges.size():
		# Algorithm complete
		algorithm_running = false
		update_info_text("Complete! Maximum matching found.")
		return

	var edge = edges[current_edge_index]
	var u = edge.from
	var v = edge.to

	# Highlight current edge
	var edge_key = get_edge_key(u, v)
	update_edge_color_direct(edge_key, current_edge_color)
	update_info_text("Checking edge " + u + " - " + v)

	# Check if both vertices are unmatched
	if matching[u] == null and matching[v] == null:
		# Add to matching
		matching[u] = v
		matching[v] = u
		matching_size += 1

		# Update visuals
		update_vertex_color(u, matched_color)
		update_vertex_color(v, matched_color)
		update_edge_color_direct(edge_key, matching_edge_color)
		update_matching_display()
	else:
		# Can't add this edge, reset color
		update_edge_color_direct(edge_key, edge_color)

	current_edge_index += 1

func get_edge_key(u: String, v: String) -> String:
	var key1 = u + "_" + v
	var key2 = v + "_" + u
	if edge_lines.has(key1):
		return key1
	return key2

func update_vertex_color(vertex: String, color: Color) -> void:
	if vertex_nodes.has(vertex):
		vertex_nodes[vertex].material_override = _vertex_material(color)

func update_edge_color_direct(edge_key: String, color: Color) -> void:
	if edge_lines.has(edge_key):
		var line = edge_lines[edge_key].get_child(0)
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = emissive
		material.emission = color * 0.5
		material.emission_energy_multiplier = 1.2
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = material

func update_info_text(text: String) -> void:
	if info_label:
		info_label.text = text

func update_matching_display() -> void:
	if matching_label:
		matching_label.text = "Matching Size: " + str(matching_size)

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_coupling: String = coupling
	var before_size: int = graph_size
	var before_density: float = edge_density

	# Stage-2 DNA axis — #coupling:stranded
	if config_data.has("coupling"):
		coupling = _pick_axis(str(config_data["coupling"]), COUPLINGS, coupling)
	if config_data.has("graph_size"):
		graph_size = clampi(int(config_data["graph_size"]), 4, 24)
	if config_data.has("edge_density"):
		edge_density = clampf(float(config_data["edge_density"]), 0.05, 1.0)
	if config_data.has("animation_speed"):
		animation_speed = clampf(float(config_data["animation_speed"]), 0.05, 5.0)

	# Non-geometry keys apply IN PLACE, BEFORE the early returns. Curation hands every
	# artifact {"emissive": false} and that dict carries no axis key — an accepted key
	# that only took effect via a rebuild that never runs is an accepted key that does
	# nothing, which is how two artifacts in the last wave lied about their emission.
	if config_data.has("emissive"):
		_apply_emissive(bool(config_data["emissive"]))

	if not _built:
		return
	if coupling == before_coupling and graph_size == before_size \
			and is_equal_approx(edge_density, before_density):
		return

	_rebuild_now()
	print("[EdmondsAlgorithm] Config applied — coupling=%s" % [coupling])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to fall back to the shipped look — a half-recognised value would strand
## the placement with an empty ring.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Glow on or off, on the materials that already exist. Live-updated colours read the
## same flag, so it survives every step of the animation and every later rebuild.
func _apply_emissive(on: bool) -> void:
	emissive = on
	for vertex in vertex_nodes.keys():
		var mi: MeshInstance3D = vertex_nodes[vertex]
		var m: StandardMaterial3D = mi.material_override as StandardMaterial3D
		if m != null:
			m.emission_enabled = on
	for edge_key in edge_lines.keys():
		var container: Node = edge_lines[edge_key]
		if container.get_child_count() == 0:
			continue
		var line: MeshInstance3D = container.get_child(0) as MeshInstance3D
		if line == null:
			continue
		var lm: StandardMaterial3D = line.material_override as StandardMaterial3D
		if lm != null:
			lm.emission_enabled = on


## Free ONLY what this script created, then build again INLINE. No call_deferred:
## a deferred rebuild that removes children first makes auto-grounding measure a zero
## AABB and bail. The environment nodes are not in _created and are never freed here,
## so the camera is not re-made current on every config pass.
##
## The one exception is the framer's own nameplate. GridInteractablesComponent frames
## labels SYNCHRONOUSLY at placement (line 1197) and only then runs the deferred
## apply_grid_config, so by the time we rebuild, the two root captions already share a
## plate — and a merged plate is parented to the labels' PARENT, which is this node.
## Freeing the labels alone would strand it and the deferred re-frame would hang a
## second identical plate on top of it. Direct children carrying `label_plate` can only
## have come from our own two captions, so they go with them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_created.clear()

	for child in get_children():
		if child.has_meta("label_plate"):
			remove_child(child)
			child.queue_free()
	vertex_nodes.clear()
	edge_lines.clear()
	info_label = null
	matching_label = null

	_build_all()

	if auto_start:
		start_algorithm()
