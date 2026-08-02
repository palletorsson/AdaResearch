extends Node3D

# @identity
# essence: tiered network visualization — central hub nodes (high centrality), mid-tier cluster nodes, peripheral nodes — all orbiting with speed inversely proportional to centrality, connected by pulsing edges with flow particles
# desire: to see a living network breathe — nodes orbit at different speeds based on their importance, edges pulse with data flow, and community boundaries glow like cell membranes
# critical_parameter: analysis_progress — ramps from 0 to 1 over time, progressively amplifying all visual effects (node pulsing, edge glow, community alpha, particle trail intensity)
# triggers: time drives orbital animation, edge pulse frequency, and community rotation; flow_particles traverse random edges continuously, creating a sense of constant network activity
# emerges: the three-tier layout (central/cluster/peripheral) creates visual hierarchy without explicit label — centrality is expressed through node size, color, orbit radius, and glow intensity
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: appears in GT_Network_Analysis as the analytical complement to networkflow3d's algorithmic flow; provides qualitative network intuition before quantitative algorithms
# truth: a network's structure is not in its nodes or edges alone — it is in the pattern of connections, and centrality measures which nodes the network would miss most

class_name NetworkAnalysis

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `mutuality`
# ═══════════════════════════════════════════════════════════════════
#
# HOW MUCH MUTUAL REACHABILITY THE STANDING NETWORK HOLDS. The word and the
# four values are taken WITHOUT CHANGE from tarjan_algorithm, kosaraju_algorithm
# and rhizomatic_structure, which already carry them. Those three answer the
# question by directed reachability; this one answers it by the undirected
# structure a centrality reading is taken FROM — but it is the same ladder, so a
# sweep sheet with `mutuality: total` on four rows shows one DFS pass, two DFS
# passes, a Deleuzian growth model and a centrality diagram all arriving at
# "everything reaches everything".
#
# The value is carried by the LAYOUT and the EDGE SET, never by the animation.
# Everything this artifact moves — orbit, pulse, glow, particle flow — is driven
# by _process from time 0, so an axis routed through motion would be invisible
# to a still. What varies is the standing graph the shipped animation is run ON.
#
#   pockets  the shipped three-tier network, byte for byte: 5 hubs on a 1.8 m
#            ring, 8 cluster nodes at 3.2 m, 12 peripheral at ~4.7 m, 44 edges
#            (10 hub-hub, 10 hub-cluster, 16 cluster-periphery, 8 random) and
#            three glowing community tori. Loose neighbourhoods, no whole.
#   none     no cycle anywhere. The same 25 nodes restaged as a layered TREE —
#            hubs across the top at y 3.2, cluster row at 0.4, periphery at
#            -2.4 — with exactly 24 edges, every one a bridge. Cut any edge and
#            the graph falls in two. No community tori, because a tree has no
#            community to draw a ring around. This is the value that earns the
#            axis: a network with no mutual return path at all is the negative
#            space centrality is measured against, and it could not be asked for.
#   split    two dense wheels 8.4 m apart — 9 nodes left, 16 right, each node
#            wired to its three nearest neighbours around its own ring — joined
#            by EXACTLY ONE edge. A still reads two objects and one thread.
#   total    the complete graph. One flat 3.4 m ring, all 300 pairs wired, one
#            community torus around the whole thing. Every node mutually
#            reachable; the edges stop being lines and become a woven disc.
#
# `pockets` is a RANDOM graph by nature. Two builds of one axis value must be
# pixel-identical or a pixel critic reads noise as signal, so the three
# deterministic values run on a SEEDED generator while `pockets` keeps the
# global stream it has always used (see graph_seed).
@export_enum("pockets", "none", "split", "total") var mutuality: String = "pockets"

## Allow-list. A typo in a map token falls back to the shipped network rather
## than stranding a placement with no graph at all.
const MUTUALITIES: PackedStringArray = ["pockets", "none", "split", "total"]

## RNG SEED. -1 = randomize exactly as this artifact always has: the shipped
## `pockets` build draws 25 centralities, 20 z-jitters, 12 radius jitters, 24
## random-edge indices and 120 particle draws from the GLOBAL stream, so every
## launch produces a different network. Set a non-negative number to pin that
## stream. The three non-default `mutuality` values always seed themselves
## (NETWORK_SEED) whatever this says, because a sweep tile has to be repeatable.
@export var graph_seed: int = -1

## The seed the deterministic values use when graph_seed is left at -1.
const NETWORK_SEED: int = 20260802

# Layout of the non-default values, in metres.
const TREE_ROW_Y: Array = [3.2, 0.4, -2.4]                # hubs / cluster / periphery
const TIER_CENTRALITY: Array = [0.9, 0.6, 0.2]            # fixed, so a still repeats
const TREE_ROW_SPAN: float = 9.0        # width of the widest tree row
const SPLIT_SEPARATION: float = 8.4     # distance between the two wheel centres
const SPLIT_LEFT_RADIUS: float = 1.6
const SPLIT_RIGHT_RADIUS: float = 2.3
const SPLIT_NEIGHBOURS: int = 3         # each node wired to its 3 ring neighbours
const TOTAL_RADIUS: float = 3.4         # the complete graph's single flat ring

## Non-null only when a value needs repeatability; null keeps the global stream.
var _rng: RandomNumberGenerator = null

var time: float = 0.0
var analysis_progress: float = 0.0
var clustering_coefficient: float = 0.0
var connectivity_index: float = 0.0
var node_count: int = 25
var edge_count: int = 40
var flow_particles: Array = []
var network_nodes: Array = []
var network_edges: Array = []
var communities: Array = []

func _ready() -> void:
	print("Network Analysis Visualization initialized")
	_open_rng()
	setup_scene()
	create_network_nodes()
	create_network_edges()
	create_communities()
	create_flow_particles()

func setup_scene() -> void:
	# Enhanced lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 0.8
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = true
	add_child(light)
	
	var ambient = WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_mode = Environment.BG_COLOR
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.1, 0.1, 0.15)
	ambient.environment.glow_enabled = true
	ambient.environment.glow_intensity = 1.5
	ambient.environment.glow_strength = 1.2
	ambient.environment.glow_bloom = 0.3
	add_child(ambient)
	
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 12)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	add_child(camera)

func _process(delta: float) -> void:
	time += delta
	analysis_progress = min(1.0, time * 0.1)
	clustering_coefficient = 0.3 + analysis_progress * 0.5 + sin(time * 0.5) * 0.1
	connectivity_index = 0.4 + analysis_progress * 0.4 + cos(time * 0.6) * 0.1
	
	animate_network_nodes(delta)
	update_network_edges(delta)
	animate_flow_particles(delta)
	animate_communities(delta)

func create_network_nodes() -> void:
	# `mutuality` restages the whole standing graph; the shipped tiering below is
	# left untouched so the default draws its RNG in exactly the old order.
	if mutuality != "pockets":
		_build_nodes_for_mutuality()
		return

	# Central hub nodes
	for i in range(5):
		var node = create_node_sphere(0.18, Color(1.0, 0.3, 0.3))
		var angle = float(i) / 5.0 * TAU
		var radius = 1.8
		node.position = Vector3(cos(angle) * radius, sin(angle) * radius, 0)
		add_child(node)
		network_nodes.append({
			"node": node,
			"type": "central",
			"centrality": 0.85 + _rf() * 0.15,
			"base_pos": node.position,
			"angle": angle,
			"radius": radius
		})
	
	# Mid-tier cluster nodes
	for i in range(8):
		var node = create_node_sphere(0.13, Color(0.3, 0.7, 1.0))
		var angle = float(i) / 8.0 * TAU + 0.2
		var radius = 3.2
		node.position = Vector3(cos(angle) * radius, sin(angle) * radius, _rf_range(-0.3, 0.3))
		add_child(node)
		network_nodes.append({
			"node": node,
			"type": "cluster",
			"centrality": 0.5 + _rf() * 0.2,
			"base_pos": node.position,
			"angle": angle,
			"radius": radius
		})
	
	# Peripheral nodes
	for i in range(12):
		var node = create_node_sphere(0.09, Color(0.4, 1.0, 0.4))
		var angle = float(i) / 12.0 * TAU
		var radius = 4.5 + _rf() * 0.5
		node.position = Vector3(cos(angle) * radius, sin(angle) * radius, _rf_range(-0.5, 0.5))
		add_child(node)
		network_nodes.append({
			"node": node,
			"type": "peripheral",
			"centrality": _rf() * 0.3,
			"base_pos": node.position,
			"angle": angle,
			"radius": radius
		})

func create_node_sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 1.5
	material.emission_energy_multiplier = 2.0
	material.metallic = 0.6
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	return mesh_instance

func create_network_edges() -> void:
	if mutuality != "pockets":
		_build_edges_for_mutuality()
		return

	# Connect central nodes to each other
	for i in range(5):
		for j in range(i + 1, 5):
			create_edge(i, j, 0.8)
	
	# Connect central to mid-tier
	for i in range(5):
		for j in range(2):
			var target = 5 + (i * 2 + j) % 8
			create_edge(i, target, 0.6)
	
	# Connect mid-tier to peripheral
	for i in range(8):
		for j in range(2):
			var target = 13 + (i + j * 6) % 12
			create_edge(5 + i, target, 0.4)
	
	# Add some random connections
	for i in range(8):
		var n1 = _ri(network_nodes.size())
		var n2 = _ri(network_nodes.size())
		if n1 != n2:
			create_edge(n1, n2, _rf_range(0.2, 0.5))

func create_edge(idx1: int, idx2: int, weight: float) -> void:
	var edge_container = Node3D.new()
	add_child(edge_container)
	
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	line.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0, 0.7)
	material.emission_enabled = true
	material.emission = Color(0.4, 0.6, 1.0) * 0.8
	material.emission_energy_multiplier = 1.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	line.material_override = material
	
	edge_container.add_child(line)
	
	network_edges.append({
		"container": edge_container,
		"line": line,
		"node1": idx1,
		"node2": idx2,
		"weight": weight
	})

func update_network_edges(_delta) -> void:
	for edge_data in network_edges:
		var node1_pos = network_nodes[edge_data["node1"]]["node"].global_position
		var node2_pos = network_nodes[edge_data["node2"]]["node"].global_position
		
		var container = edge_data["container"]
		var line = edge_data["line"]
		
		# Position at midpoint
		var midpoint = (node1_pos + node2_pos) * 0.5
		container.position = midpoint
		
		# Calculate direction and distance
		var direction = node2_pos - node1_pos
		var distance = direction.length()
		
		# Scale to match distance
		line.scale.y = distance
		
		# Orient toward target
		if distance > 0.001:
			var up = Vector3.UP
			if abs(direction.normalized().dot(up)) > 0.99:
				up = Vector3.RIGHT
			container.look_at_from_position(container.position, node2_pos, up)
			container.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		# Animate pulse
		var weight = edge_data["weight"]
		var pulse = 1.0 + sin(time * 3.0 + edge_data["node1"] * 0.5) * 0.3 * weight * analysis_progress
		line.scale.x = pulse * 0.02
		line.scale.z = pulse * 0.02
		
		# Animate color flow
		var flow = fmod(time * 2.0 + edge_data["node1"] * 0.3, 1.0)
		var intensity = 0.5 + sin(flow * TAU) * 0.5
		var material = line.material_override as StandardMaterial3D
		material.emission_energy_multiplier = 1.0 + intensity * analysis_progress * 2.0

func create_communities() -> void:
	# The ring count IS part of the claim: three loose neighbourhoods, none at all
	# on a tree, one per component when the graph splits, one around the whole
	# wheel when everything reaches everything.
	var rings: Array = _community_rings()
	for i in range(rings.size()):
		var spec: Dictionary = rings[i]
		var torus = MeshInstance3D.new()
		var torus_mesh = TorusMesh.new()
		torus_mesh.inner_radius = float(spec["inner"])
		torus_mesh.outer_radius = float(spec["outer"])
		torus.mesh = torus_mesh
		
		var material = StandardMaterial3D.new()
		var hue = float(i) / 3.0
		var color = Color.from_hsv(hue, 0.7, 0.8, 0.15)
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = Color.from_hsv(hue, 0.7, 1.0) * 0.5
		material.emission_energy_multiplier = 1.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		torus.material_override = material
		
		torus.position = spec["pos"]
		add_child(torus)

		communities.append({
			"mesh": torus,
			"base_pos": torus.position,
			"hue": hue,
			"phase": float(i) / 3.0 * TAU
		})

func animate_communities(delta) -> void:
	for comm_data in communities:
		var comm = comm_data["mesh"]
		var phase = comm_data["phase"]
		
		# Rotate
		comm.rotation.z += delta * 0.3
		
		# Pulse
		var pulse = 1.0 + sin(time * 1.5 + phase) * 0.15 * analysis_progress
		comm.scale = Vector3.ONE * pulse
		
		# Glow intensity
		var material = comm.material_override as StandardMaterial3D
		var intensity = 0.5 + sin(time * 2.0 + phase) * 0.5
		material.emission_energy_multiplier = 1.0 + intensity * analysis_progress * 2.0
		
		# Update alpha
		var alpha = 0.1 + intensity * analysis_progress * 0.2
		var color = material.albedo_color
		color.a = alpha
		material.albedo_color = color

func create_flow_particles() -> void:
	for i in range(40):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		particle.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 1.0, 0.5)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.3) * 2.0
		material.emission_energy_multiplier = 3.0
		particle.material_override = material
		
		add_child(particle)
		flow_particles.append({
			"particle": particle,
			"edge_index": _ri(network_edges.size()),
			"progress": _rf(),
			"speed": _rf_range(0.3, 0.8)
		})

func animate_flow_particles(delta) -> void:
	for particle_data in flow_particles:
		var particle = particle_data["particle"]
		var edge_idx = particle_data["edge_index"]
		
		# Move along edge
		particle_data["progress"] += delta * particle_data["speed"]
		if particle_data["progress"] > 1.0:
			particle_data["progress"] = 0.0
			particle_data["edge_index"] = _ri(network_edges.size())
			edge_idx = particle_data["edge_index"]
		
		var edge = network_edges[edge_idx]
		var node1_pos = network_nodes[edge["node1"]]["node"].global_position
		var node2_pos = network_nodes[edge["node2"]]["node"].global_position
		
		particle.position = node1_pos.lerp(node2_pos, particle_data["progress"])
		
		# Pulse
		var pulse = 1.0 + sin(time * 4.0 + edge_idx) * 0.3
		particle.scale = Vector3.ONE * pulse
		
		# Trail effect via opacity
		var trail_factor = sin(particle_data["progress"] * PI)
		var material = particle.material_override as StandardMaterial3D
		material.emission_energy_multiplier = 2.0 + trail_factor * 2.0 * analysis_progress

func animate_network_nodes(delta) -> void:
	# The shipped orbit is POLAR AROUND THE ORIGIN — it lerps every node onto
	# cos(angle)*radius, sin(angle)*radius. Run on a tree or on two wheels 8.4 m
	# apart it would drag the whole layout back onto one circle inside a second,
	# and the axis would be gone before any camera saw it. Non-default values get
	# the same breathing about their OWN standing position instead.
	if mutuality != "pockets":
		_animate_in_place(delta)
		return
	for i in range(network_nodes.size()):
		var node_data = network_nodes[i]
		var node = node_data["node"]
		var centrality = node_data["centrality"]
		
		# Orbital animation
		var orbit_speed = 0.1 * (1.0 - centrality * 0.5)
		node_data["angle"] += delta * orbit_speed
		
		var base_radius = node_data["radius"]
		var wobble = sin(time * 2.0 + i * 0.5) * 0.2
		var current_radius = base_radius + wobble * centrality
		
		var target_x = cos(node_data["angle"]) * current_radius
		var target_y = sin(node_data["angle"]) * current_radius
		var target_z = sin(time * 0.5 + i * 0.3) * 0.3 * centrality
		
		node.position.x = lerp(node.position.x, target_x, delta * 2.0)
		node.position.y = lerp(node.position.y, target_y, delta * 2.0)
		node.position.z = lerp(node.position.z, target_z, delta * 2.0)
		
		# Pulse based on centrality
		var pulse = 1.0 + sin(time * 3.0 + i * 0.4) * 0.25 * centrality * analysis_progress
		node.scale = Vector3.ONE * pulse
		
		# Emission intensity
		var material = node.material_override as StandardMaterial3D
		var intensity = 1.5 + centrality * analysis_progress * 2.0
		material.emission_energy_multiplier = intensity

func set_analysis_progress(progress: float) -> void:
	analysis_progress = clamp(progress, 0.0, 1.0)

func set_clustering_coefficient(clustering: float) -> void:
	clustering_coefficient = clamp(clustering, 0.0, 1.0)

func set_connectivity_index(connectivity: float) -> void:
	connectivity_index = clamp(connectivity, 0.0, 1.0)

func get_analysis_progress() -> float:
	return analysis_progress

func get_clustering_coefficient() -> float:
	return clustering_coefficient

func get_connectivity_index() -> float:
	return connectivity_index

func reset_analysis() -> void:
	time = 0.0
	analysis_progress = 0.0
	clustering_coefficient = 0.0
	connectivity_index = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the declared axis (and its seed) are read; every other key in a map
	# token is ignored exactly as before.
	if config.has("graph_seed"):
		graph_seed = int(str(config["graph_seed"]))
	if not config.has("mutuality"):
		return
	mutuality = str(config["mutuality"])
	_rebuild()


func _rebuild() -> void:
	for entry in network_edges:
		var container = entry["container"]
		if is_instance_valid(container):
			container.queue_free()
	for entry in network_nodes:
		if is_instance_valid(entry["node"]):
			entry["node"].queue_free()
	for entry in communities:
		if is_instance_valid(entry["mesh"]):
			entry["mesh"].queue_free()
	for entry in flow_particles:
		if is_instance_valid(entry["particle"]):
			entry["particle"].queue_free()
	network_nodes.clear()
	network_edges.clear()
	communities.clear()
	flow_particles.clear()
	_open_rng()
	create_network_nodes()
	create_network_edges()
	create_communities()
	create_flow_particles()


# ═══════════════════════════════════════════════════════════════════
# `mutuality` — APPENDED LAST. Nothing above this line changed order.
# ═══════════════════════════════════════════════════════════════════

## Seeded only when repeatability is needed. At the shipped value with the
## shipped seed this leaves _rng null, so every draw below goes to the global
## stream in exactly the old order.
func _open_rng() -> void:
	var want: String = String(mutuality).strip_edges().to_lower()
	if not MUTUALITIES.has(want):
		want = "pockets"
	mutuality = want
	if graph_seed < 0 and want == "pockets":
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = graph_seed if graph_seed >= 0 else NETWORK_SEED


func _rf() -> float:
	return _rng.randf() if _rng != null else randf()


func _rf_range(a: float, b: float) -> float:
	return _rng.randf_range(a, b) if _rng != null else randf_range(a, b)


func _ri(n: int) -> int:
	if n <= 0:
		return 0
	return (_rng.randi() % n) if _rng != null else (randi() % n)


## The three tiers, restaged. Same counts, same sphere sizes, same tier colours —
## only WHERE they stand changes, because the tier is what centrality is read from.
func _build_nodes_for_mutuality() -> void:
	var tiers: Array = [
		{"count": 5, "radius": 0.18, "color": Color(1.0, 0.3, 0.3), "type": "central"},
		{"count": 8, "radius": 0.13, "color": Color(0.3, 0.7, 1.0), "type": "cluster"},
		{"count": 12, "radius": 0.09, "color": Color(0.4, 1.0, 0.4), "type": "peripheral"},
	]
	var index: int = 0
	for t in range(tiers.size()):
		var tier: Dictionary = tiers[t]
		for i in range(int(tier["count"])):
			var node = create_node_sphere(float(tier["radius"]), tier["color"])
			node.position = _standing_position(index, t, i, int(tier["count"]))
			add_child(node)
			network_nodes.append({
				"node": node,
				"type": tier["type"],
				"centrality": float(TIER_CENTRALITY[t]),
				"base_pos": node.position,
				"angle": 0.0,
				"radius": 0.0,
			})
			index += 1


## Where node `index` stands under the current value.
func _standing_position(index: int, tier: int, slot: int, tier_count: int) -> Vector3:
	match mutuality:
		"none":
			# A layered tree: one row per tier, widest at the bottom.
			var span: float = TREE_ROW_SPAN * (0.45 + 0.275 * float(tier))
			var step: float = span / maxf(1.0, float(tier_count - 1))
			return Vector3(float(slot) * step - span * 0.5, float(TREE_ROW_Y[tier]), 0.0)
		"split":
			# 9 nodes in the left wheel (5 hubs + 4 cluster), 16 in the right.
			var left: bool = index < 9
			var count: int = 9 if left else 16
			var seat: int = index if left else index - 9
			var ring: float = SPLIT_LEFT_RADIUS if left else SPLIT_RIGHT_RADIUS
			var a: float = float(seat) / float(count) * TAU
			var cx: float = (-SPLIT_SEPARATION * 0.5) if left else (SPLIT_SEPARATION * 0.5)
			return Vector3(cx + cos(a) * ring, sin(a) * ring, 0.0)
		"total":
			# One flat ring, tiers interleaved so the wheel reads as one body.
			var b: float = float(index) / 25.0 * TAU
			return Vector3(cos(b) * TOTAL_RADIUS, sin(b) * TOTAL_RADIUS, 0.0)
	return Vector3.ZERO


## The edge set that carries the claim.
func _build_edges_for_mutuality() -> void:
	match mutuality:
		"none":
			# 24 edges over 25 nodes: a tree. Every edge is a bridge; no cycle.
			for i in range(4):
				create_edge(i, i + 1, 0.8)                 # the hub row, chained
			for i in range(8):
				create_edge(5 + i, i % 5, 0.6)             # cluster -> a hub
			for i in range(12):
				create_edge(13 + i, 5 + (i % 8), 0.4)      # periphery -> a cluster
		"split":
			# Each wheel densely wired to itself; ONE thread between them.
			for k in range(1, SPLIT_NEIGHBOURS + 1):
				for i in range(9):
					create_edge(i, (i + k) % 9, 0.7)
				for i in range(16):
					create_edge(9 + i, 9 + (i + k) % 16, 0.5)
			create_edge(4, 12, 0.9)                        # the single bridge
		"total":
			# K25 — all 300 pairs.
			for i in range(25):
				for j in range(i + 1, 25):
					create_edge(i, j, 0.5)


## Community tori: none on a tree, one per component when the graph splits, one
## around the whole wheel when everything reaches everything.
func _community_rings() -> Array:
	match mutuality:
		"none":
			return []
		"split":
			return [
				{"pos": Vector3(-SPLIT_SEPARATION * 0.5, 0, 0), "inner": 1.35, "outer": 1.85},
				{"pos": Vector3(SPLIT_SEPARATION * 0.5, 0, 0), "inner": 2.05, "outer": 2.55},
			]
		"total":
			return [{"pos": Vector3.ZERO, "inner": 3.15, "outer": 3.65}]
	# pockets — the shipped three, on the same 1.8 m ring, same radii.
	var out: Array = []
	for i in range(3):
		var angle: float = float(i) / 3.0 * TAU
		out.append({
			"pos": Vector3(cos(angle) * 1.8, sin(angle) * 1.8, 0),
			"inner": 1.5, "outer": 2.0,
		})
	return out


## The shipped breathing, applied about each node's own standing position rather
## than about the origin, so a tree stays a tree.
func _animate_in_place(_delta) -> void:
	for i in range(network_nodes.size()):
		var node_data = network_nodes[i]
		var node = node_data["node"]
		var centrality = node_data["centrality"]
		var base: Vector3 = node_data["base_pos"]
		node.position = base + Vector3(
			0.0, 0.0, sin(time * 0.5 + i * 0.3) * 0.3 * centrality)
		var pulse = 1.0 + sin(time * 3.0 + i * 0.4) * 0.25 * centrality * analysis_progress
		node.scale = Vector3.ONE * pulse
		var material = node.material_override as StandardMaterial3D
		material.emission_energy_multiplier = 1.5 + centrality * analysis_progress * 2.0
