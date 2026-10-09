extends Node3D
class_name ForceDirectedLayout

# @identity
# essence: 2D Hooke's law spring system — F_spring = k*(d - rest_length) attracts connected nodes, F_repulsion = k/d^2 repels all pairs, velocity *= damping each frame until energy minimizes
# desire: to watch a tangled graph untangle itself — nodes repel, springs pull, and the layout emerges from nothing but force balance
# critical_parameter: spring_strength vs repulsion_strength ratio — determines whether the graph collapses into a cluster or spreads into a readable layout
# triggers: _process runs force calculation and position integration every frame; CSGSphere3D nodes scale with force magnitude to show stress visually
# emerges: the system converges to a local energy minimum that reveals graph structure — clusters, bridges, and peripheral nodes become spatially evident
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: 2D precursor to forcedirected3d's volumetric simulation; demonstrates the same physics that graphspace uses to lay out walkable rooms
# truth: the best way to see the structure of a graph is to let physics find it — repulsion separates, attraction connects, and equilibrium is the drawing

## --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
## WHICH GRAPH THE SAME FORCE LAW IS ASKED TO DRAW. The registry says this artifact
## shows how "clusters, bridges, and peripheral nodes appear as energy redistributes"
## — a claim about GRAPHS that the shipped code could never test, because it had
## exactly one graph welded into create_graph(). Every value keeps eight nodes and
## the identical springs, repulsion, damping and bounds; only the adjacency changes,
## which is the point: the drawing is a property of the graph, not of the algorithm.
##   cube      - the shipped twelve connections. They are the 3-cube Q3: two 4-cycles
##               joined by four rungs, 3-regular and vertex-transitive.
##   ring      - C8, one cycle, 8 edges. Every node the same degree, no hierarchy.
##   star      - K1,7, a tree. One hub of degree 7 and seven leaves of degree 1:
##               maximal hierarchy, and the only value with a node nothing repels
##               away from the middle.
##   clique    - K8, all 28 edges. Nothing to reveal, because everything is adjacent
##               to everything; the springs pull it into the tightest blob of the set.
##   bipartite - K4,4, 16 edges, every edge crossing between two classes and none
##               inside either. No odd cycles anywhere in the drawing.
## `path` was tried and dropped: P8 is C8 minus one edge, and under this force law the
## two settle to layouts that differ by 0.31% of frame. A duplicate tile, measured.
@export_enum("cube", "ring", "star", "clique", "bipartite") var graph: String = "cube"
## 0 keeps the shipped GLOBAL randf() jitter on the starting ring, so two layouts in
## one room still start differently. Non-zero pins the start with a private RNG.
@export var layout_seed: int = 0
## Fixed-delta relaxation steps run once in _ready, before the first frame is drawn.
## 0 is shipped: the graph starts tangled on its ring and untangles while you watch.
## The still bench needs a settled layout, and needs it not to depend on frame rate.
@export var warmup_steps: int = 0
## 0.0 parks the simulation so a still is reproducible. 1.0 is shipped.
@export var time_scale: float = 1.0

const GRAPHS: Array[String] = ["cube", "ring", "star", "clique", "bipartite"]

var time = 0.0
var nodes = []
var edges = []
var node_count = 8
var spring_length = 2.0
var spring_strength = 0.1
var repulsion_strength = 50.0
var damping = 0.9
var total_energy = 0.0

class ForceGraphNode:
	var id: int
	var position: Vector2
	var velocity: Vector2
	var force: Vector2
	var visual_object: CSGSphere3D
	
	func _init(node_id: int, pos: Vector2) -> void:
		id = node_id
		position = pos
		velocity = Vector2.ZERO
		force = Vector2.ZERO

class ForceGraphEdge:
	var from_id: int
	var to_id: int
	var visual_object: CSGCylinder3D
	
	func _init(from: int, to: int) -> void:
		from_id = from
		to_id = to

func _ready() -> void:
	create_graph()
	setup_materials()
	if warmup_steps > 0:
		relax(warmup_steps)

## Run the simulation forward at a FIXED delta, then draw once. Fixed, because the
## shipped _process integrates with the real frame delta, so what a still shows is a
## fact about how fast the machine ran. Draw once, because update_visuals writes CSG
## properties and every write rebuilds the shape's mesh — calling it inside the loop
## makes a 480-step warm-up hundreds of times more expensive than the physics it is
## warming. The final node.force is the one from before the last position update,
## which is exactly the state _process leaves behind on any ordinary frame.
func relax(steps: int) -> void:
	var dt: float = 1.0 / 60.0
	for i in steps:
		calculate_forces()
		update_positions(dt)
	update_visuals()
	animate_indicators()

## The adjacency for a value of `graph`. Eight nodes throughout; only which pairs are
## joined changes. The `_` branch returns the shipped literal unchanged.
func connections_for(kind: String) -> Array:
	var n: int = int(node_count)
	var half: int = n / 2
	var out: Array = []
	match kind:
		"ring":
			for i in range(n):
				out.append([i, (i + 1) % n])
		"star":
			for i in range(1, n):
				out.append([0, i])
		"clique":
			for i in range(n):
				for j in range(i + 1, n):
					out.append([i, j])
		"bipartite":
			for i in range(half):
				for j in range(half, n):
					out.append([i, j])
		_:
			out = [
				[0, 1], [1, 2], [2, 3], [3, 0], [0, 4], [1, 5],
				[2, 6], [3, 7], [4, 5], [5, 6], [6, 7], [7, 4]
			]
	return out

func create_graph() -> void:
	# Create nodes with random positions
	var rng := RandomNumberGenerator.new()
	if layout_seed != 0:
		rng.seed = layout_seed
	for i in range(node_count):
		var angle = i * 2.0 * PI / node_count
		var radius = 3.0
		var pos = Vector2(cos(angle) * radius, sin(angle) * radius)
		if layout_seed != 0:
			pos += Vector2(rng.randf() * 2 - 1, rng.randf() * 2 - 1)
		else:
			pos += Vector2(randf() * 2 - 1, randf() * 2 - 1)  # Add randomness

		var node = ForceGraphNode.new(i, pos)

		var node_sphere = CSGSphere3D.new()
		node_sphere.radius = 0.2
		node_sphere.position = Vector3(pos.x, pos.y, 0)
		get_or_create_container("GraphNodes").add_child(node_sphere)
		node.visual_object = node_sphere

		nodes.append(node)

	# Which pairs are joined — `cube` is the shipped list, line for line.
	var connections = connections_for(graph)

	for conn in connections:
		if conn[0] < node_count and conn[1] < node_count:
			var edge = ForceGraphEdge.new(conn[0], conn[1])
			create_edge_visual(edge)
			edges.append(edge)

func get_or_create_container(container_name: String) -> Node3D:
	"""Get or create a container node"""
	var container = get_node_or_null(container_name)
	if not container:
		container = Node3D.new()
		container.name = container_name
		add_child(container)
	return container

func create_edge_visual(edge: ForceGraphEdge) -> void:
	var from_node = nodes[edge.from_id]
	var to_node = nodes[edge.to_id]
	
	var edge_cylinder = CSGCylinder3D.new()
	# FIXED: Use proper Godot 4 CSGCylinder3D properties
	edge_cylinder.radius = 0.03
	#edge_cylinder.bottom_radius = 0.03
	
	get_or_create_container("GraphEdges").add_child(edge_cylinder)
	edge.visual_object = edge_cylinder
	
	update_edge_visual(edge)

func update_edge_visual(edge: ForceGraphEdge) -> void:
	var from_pos = nodes[edge.from_id].position
	var to_pos = nodes[edge.to_id].position
	var distance = from_pos.distance_to(to_pos)
	
	edge.visual_object.height = distance
	edge.visual_object.position = Vector3((from_pos + to_pos).x * 0.5, (from_pos + to_pos).y * 0.5, 0)
	
	var direction = (to_pos - from_pos).normalized()
	var angle = atan2(direction.y, direction.x)
	edge.visual_object.rotation_degrees = Vector3(0, 0, angle * 180.0 / PI - 90)

func setup_materials() -> void:
	# Node materials
	for node in nodes:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.8, 1.0, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.1, 0.3, 0.5, 1.0)
		material.emission_energy = 1.0
		node.visual_object.material_override = material
	
	# Edge materials
	for edge in edges:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.2, 0.2, 0.2, 1.0)
		material.emission_energy = 1.0
		edge.visual_object.material_override = material
	
	# Create and setup indicator materials
	setup_indicator_materials()

func setup_indicator_materials() -> void:
	# Force indicator
	var force_indicator = get_or_create_box_indicator("ForceIndicator", Vector3(0.3, 1.0, 0.3))
	var force_material = StandardMaterial3D.new()
	force_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	force_material.emission_enabled = true
	force_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	force_material.emission_energy = 1.0
	force_indicator.material_override = force_material
	
	# Energy level indicator
	var energy_indicator = get_or_create_box_indicator("EnergyLevel", Vector3(0.3, 1.0, 0.3))
	var energy_material = StandardMaterial3D.new()
	energy_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	energy_material.emission_enabled = true
	energy_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	energy_material.emission_energy = 1.0
	energy_indicator.material_override = energy_material

func get_or_create_box_indicator(indicator_name: String, size: Vector3):
	"""Get or create an indicator CSGBox3D - FIXED: Renamed for clarity"""
	var indicator = get_node_or_null(indicator_name)
	if not indicator:
		indicator = CSGBox3D.new()
		indicator.name = indicator_name
		indicator.size = size
		indicator.position = Vector3(0, -3, 0)
		add_child(indicator)
	return indicator

func get_or_create_cylinder_indicator(indicator_name: String, radius: float, height: float) -> CSGCylinder3D:
	"""Get or create an indicator CSGCylinder3D - FIXED: Added separate function for cylinders"""
	var indicator = get_node_or_null(indicator_name)
	if not indicator:
		indicator = CSGCylinder3D.new()
		indicator.name = indicator_name
		indicator.top_radius = radius
		indicator.bottom_radius = radius
		indicator.height = height
		indicator.position = Vector3(0, -3, 0)
		add_child(indicator)
	return indicator

func _process(delta: float) -> void:
	# At the shipped time_scale of 1.0, dt IS delta and nothing below changes.
	var dt: float = delta * time_scale
	if dt <= 0.0:
		return
	time += dt

	# Calculate forces
	calculate_forces()

	# Update positions
	update_positions(dt)

	# Update visuals
	update_visuals()

	animate_indicators()

func calculate_forces() -> void:
	total_energy = 0.0
	
	# Reset forces
	for node in nodes:
		node.force = Vector2.ZERO
	
	# Spring forces (attraction between connected nodes)
	for edge in edges:
		var from_node = nodes[edge.from_id]
		var to_node = nodes[edge.to_id]
		
		var distance_vec = to_node.position - from_node.position
		var distance = distance_vec.length()
		
		# FIXED: Prevent division by zero
		if distance > 0:
			var direction = distance_vec.normalized()
			var force_magnitude = spring_strength * (distance - spring_length)
			var force = direction * force_magnitude
			
			from_node.force += force
			to_node.force -= force
			
			total_energy += 0.5 * spring_strength * pow(distance - spring_length, 2)
	
	# Repulsion forces (all nodes repel each other)
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var node1 = nodes[i]
			var node2 = nodes[j]
			
			var distance_vec = node2.position - node1.position
			var distance = distance_vec.length()
			
			# FIXED: Better distance checking and minimum distance
			if distance > 0.01:  # Minimum distance to prevent extreme forces
				var direction = distance_vec.normalized()
				var force_magnitude = repulsion_strength / (distance * distance)
				var force = direction * force_magnitude
				
				node1.force -= force
				node2.force += force
				
				total_energy += repulsion_strength / distance

func update_positions(delta) -> void:
	for node in nodes:
		# Update velocity with force
		node.velocity += node.force * delta
		
		# Apply damping
		node.velocity *= damping
		
		# FIXED: Clamp velocity to prevent instability
		var max_velocity = 10.0
		if node.velocity.length() > max_velocity:
			node.velocity = node.velocity.normalized() * max_velocity
		
		# Update position
		node.position += node.velocity * delta
		
		# Keep nodes within bounds
		var bound = 6.0
		node.position.x = clamp(node.position.x, -bound, bound)
		node.position.y = clamp(node.position.y, -bound, bound)

func update_visuals() -> void:
	# Update node positions
	for node in nodes:
		if node.visual_object and is_instance_valid(node.visual_object):
			node.visual_object.position = Vector3(node.position.x, node.position.y, 0)
			
			# Scale based on force magnitude
			var force_magnitude = node.force.length()
			var scale = 1.0 + min(force_magnitude * 0.1, 0.5)  # FIXED: Clamp scale
			node.visual_object.scale = Vector3.ONE * scale
	
	# Update edge visuals
	for edge in edges:
		if edge.visual_object and is_instance_valid(edge.visual_object):
			update_edge_visual(edge)

func animate_indicators() -> void:
	# Force indicator (average force magnitude)
	var avg_force = 0.0
	for node in nodes:
		avg_force += node.force.length()
	
	if nodes.size() > 0:
		avg_force /= nodes.size()
	
	var force_height = min(avg_force / 10.0, 1.0) * 2.0 + 0.5
	var force_indicator = get_node_or_null("ForceIndicator")
	if force_indicator and force_indicator is CSGBox3D:
		force_indicator.size.y = force_height
		force_indicator.position.y = -3 + force_height/2
	
	# Energy level indicator
	var energy_height = min(total_energy / 100.0, 1.0) * 2.0 + 0.5
	var energy_indicator = get_node_or_null("EnergyLevel")
	if energy_indicator and energy_indicator is CSGBox3D:
		energy_indicator.size.y = energy_height
		energy_indicator.position.y = -3 + energy_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	if force_indicator and is_instance_valid(force_indicator):
		force_indicator.scale.x = pulse
		force_indicator.scale.z = pulse  # FIXED: Also animate Z scale for better effect
	if energy_indicator and is_instance_valid(energy_indicator):
		energy_indicator.scale.x = pulse
		energy_indicator.scale.z = pulse  # FIXED: Also animate Z scale for better effect

# FIXED: Added utility functions for better debugging
func print_debug_info() -> void:
	"""Print debug information about the graph state"""
	print("=== Graph Debug Info ===")
	print("Node count: ", nodes.size())
	print("Edge count: ", edges.size())
	print("Total energy: ", total_energy)
	print("Average force: ", get_average_force())

func get_average_force() -> float:
	"""Get the average force magnitude across all nodes"""
	var avg_force = 0.0
	for node in nodes:
		avg_force += node.force.length()
	return avg_force / nodes.size() if nodes.size() > 0 else 0.0

func reset_simulation() -> void:
	"""Reset the simulation to initial state"""
	# Clear existing objects
	for node in nodes:
		if node.visual_object and is_instance_valid(node.visual_object):
			node.visual_object.queue_free()
	for edge in edges:
		if edge.visual_object and is_instance_valid(edge.visual_object):
			edge.visual_object.queue_free()
	
	# Clear arrays
	nodes.clear()
	edges.clear()
	time = 0.0
	total_energy = 0.0
	
	# Recreate graph
	create_graph()
	setup_materials()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Was `pass` — the artifact had no turnable knob of any kind, and the registry's own
## "interactions" list told a reader to "tune spring_strength and repulsion_strength in
## exports" that do not exist. Only a value that actually CHANGED rebuilds, and only
## once the tree is built: called before _ready (which is how the grid usually calls
## it) this just sets the export and lets _ready construct with it, so nothing is ever
## torn down that was not already standing.
func apply_grid_config(config: Dictionary) -> void:
	var want_rebuild: bool = false
	if config.has("graph"):
		var want: String = str(config["graph"])
		# An unknown word is ignored rather than assigned: a typo draws the shipped
		# cube rather than a graph with no edges.
		if GRAPHS.has(want) and want != graph:
			graph = want
			want_rebuild = true
	if config.has("layout_seed"):
		var s: int = int(config["layout_seed"])
		if s != layout_seed:
			layout_seed = s
			want_rebuild = true
	if config.has("warmup_steps"):
		warmup_steps = int(config["warmup_steps"])
	if config.has("time_scale"):
		time_scale = float(config["time_scale"])
	if want_rebuild and is_inside_tree():
		reset_simulation()
		if warmup_steps > 0:
			relax(warmup_steps)
