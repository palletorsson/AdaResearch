# Updated GraphSpace.gd with flexible structure system
# GraphSpace.gd
# Drop this on a Node3D. Assign room_scene and portal_scene in the Inspector.
@tool
extends Node3D
class_name GraphSpace

# Structure type enum
enum StructureType {
	RANDOM,          # Randomly choose from available structures
	BY_DEGREE,       # Choose based on node connectivity
	BY_DISTANCE,     # Choose based on distance from focal node
	SINGLE_TYPE,     # Use only one structure type
	CUSTOM_PATTERN   # Custom assignment pattern
}

# --- Assign in Inspector ---
@export var room_scene: PackedScene
@export var portal_scene: PackedScene

# --- Structure Configuration ---
@export_group("Structures")
@export var structure_scenes: Array[PackedScene] = []  # Multiple structure options
@export var structure_type: StructureType = StructureType.BY_DEGREE
@export var place_structures: bool = true
@export var structure_scale_range: Vector2 = Vector2(0.8, 1.2)  # Min/max scale variation
@export var structure_offset_y: float = 0.0
@export var structure_rotation_variation: float = 45.0  # Max random rotation in degrees

# --- Controls ---
@export_group("Graph Layout")
@export var node_count: int = 12
@export var avg_degree: float = 2.2  # average edges per node
@export var layout_iters: int = 250
@export var seed: int = 20250922
@export var room_radius: float = 6.0  # desired spacing between rooms
@export var edge_stiffness: float = 0.08  # spring force
@export var repulsion: float = 180.0  # node repulsion
@export var damping: float = 0.82
@export var bounds_radius: float = 60.0  # soft sphere bounds
@export var show_debug_links: bool = true

# --- Planar layout controls ---
@export_group("Layout")
@export var planar_layout: bool = true
@export var plane_y: float = 0.0
@export var plane_snap: float = 0.25   # 0..1, how strongly we pull toward plane

# --- Bridge system controls ---
@export_group("Bridges")
@export var make_bridges: bool = true
@export var bridge_width: float = 1.2
@export var bridge_thickness: float = 0.12

# Gameplay:
@export_group("Gameplay")
@export var focal_node: int = 0  # ambience source
@export var edge_cost_min: float = 1.0
@export var edge_cost_max: float = 3.0

# Internal
var rng: RandomNumberGenerator
var nodes := []  # Array[Dictionary]: {"pos": Vector3, "vel": Vector3, "inst": Node3D, "degree": int}
var edges := []  # Array[Dictionary]: {"a": int, "b": int, "w": float, "portal": Node}
var adjacency := []  # Array[Array[{to:int, w:float}]]

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	_build_graph()
	_layout_graph()
	_instantiate_world()
	_apply_ambience_by_distance()
	update_gizmos()

# ---------------------------
# 1) Build a connected, weighted undirected graph
# ---------------------------
func _build_graph() -> void:
	nodes.clear()
	edges.clear()
	adjacency = []
	
	for i in node_count:
		nodes.append({
			"pos": _rand_sphere(bounds_radius * 0.25), 
			"vel": Vector3.ZERO, 
			"inst": null,
			"degree": 0,
			"structure": null
		})
		adjacency.append([])
	
	# Ensure connectivity via a random spanning tree
	var remaining := []
	for i in node_count:
		remaining.append(i)
	
	var connected := [remaining.pop_front()]
	while remaining.size() > 0:
		var a = connected[rng.randi() % connected.size()]
		var b = remaining.pop_at(rng.randi() % remaining.size())
		_add_edge(a, b, _rand_cost())
		connected.append(b)
	
	# Add extra edges to reach approx avg_degree
	var target_edges := int(round((avg_degree * node_count) / 2.0))
	while edges.size() < target_edges:
		var a = rng.randi() % node_count
		var b = rng.randi() % node_count
		if a == b:
			continue
		if !_has_edge(a, b):
			_add_edge(a, b, _rand_cost())
	
	# Calculate node degrees
	_calculate_node_degrees()

func _add_edge(a: int, b: int, w: float) -> void:
	edges.append({"a": a, "b": b, "w": w, "portal": null})
	adjacency[a].append({"to": b, "w": w})
	adjacency[b].append({"to": a, "w": w})

func _has_edge(a: int, b: int) -> bool:
	for e in edges:
		if (e.a == a and e.b == b) or (e.a == b and e.b == a):
			return true
	return false

func _calculate_node_degrees() -> void:
	for i in node_count:
		var degree = 0
		for e in edges:
			if e.a == i or e.b == i:
				degree += 1
		nodes[i]["degree"] = degree

func _rand_cost() -> float:
	return lerp(edge_cost_min, edge_cost_max, rng.randf())

func _rand_sphere(r: float) -> Vector3:
	var dir = Vector3(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0).normalized()
	return dir * (rng.randf() * r)

# ---------------------------
# 2) Force-directed 3D layout with planar option
# ---------------------------
func _layout_graph() -> void:
	for _i in layout_iters:
		# repulsion
		for i in node_count:
			var force := Vector3.ZERO
			var pi: Vector3 = nodes[i]["pos"]
			
			for j in node_count:
				if i == j:
					continue
				var pj: Vector3 = nodes[j]["pos"]
				var d := pi.distance_to(pj) + 0.001
				var dir := (pi - pj) / d
				force += dir * (repulsion / (d * d))
			
			# spring attraction along edges
			for nb in adjacency[i]:
				var j = nb.to
				var pj2: Vector3 = nodes[j]["pos"]
				var d2 := pi.distance_to(pj2) + 0.001
				var dir2 := (pj2 - pi).normalized()
				var desired := room_radius
				var stretch := d2 - desired
				force += dir2 * (stretch * edge_stiffness)
			
			# soft bounds pull
			var dist := pi.length()
			if dist > bounds_radius:
				force += -pi.normalized() * (dist - bounds_radius) * 0.02
			
			# Apply planar layout constraints
			if planar_layout:
				# Kill vertical component of forces (XZ only)
				force.y = 0.0
			
			nodes[i]["vel"] = (nodes[i]["vel"] + force) * damping
		
		# Integrate
		for i in node_count:
			nodes[i]["pos"] += nodes[i]["vel"]
			
			# Gentle attraction to plane
			if planar_layout:
				nodes[i]["pos"].y = lerp(nodes[i]["pos"].y, plane_y, plane_snap)

# ---------------------------
# 3) Flexible Structure Selection System
# ---------------------------
func _select_structure_for_node(node_index: int) -> PackedScene:
	if structure_scenes.is_empty():
		return null
	
	match structure_type:
		StructureType.RANDOM:
			return structure_scenes[rng.randi() % structure_scenes.size()]
		
		StructureType.BY_DEGREE:
			return _select_by_degree(node_index)
		
		StructureType.BY_DISTANCE:
			return _select_by_distance(node_index)
		
		StructureType.SINGLE_TYPE:
			return structure_scenes[0]
		
		StructureType.CUSTOM_PATTERN:
			return _select_by_custom_pattern(node_index)
		
		_:
			return structure_scenes[0]

func _select_by_degree(node_index: int) -> PackedScene:
	var degree = nodes[node_index]["degree"]
	var max_degree = 0
	for i in node_count:
		max_degree = max(max_degree, nodes[i]["degree"])
	
	if max_degree == 0:
		return structure_scenes[0]
	
	# Map degree to structure index
	var structure_index = int((float(degree) / float(max_degree)) * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_distance(node_index: int) -> PackedScene:
	var distances = _dijkstra(focal_node)
	var max_distance = 0.0
	for d in distances:
		if d != INF:
			max_distance = max(max_distance, d)
	
	if max_distance <= 0.0:
		return structure_scenes[0]
	
	var normalized_distance = clamp(distances[node_index] / max_distance, 0.0, 1.0)
	var structure_index = int(normalized_distance * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_custom_pattern(node_index: int) -> PackedScene:
	# Example custom pattern: alternate structures in a pattern
	# You can modify this to create any pattern you want
	match node_index % 4:
		0: return structure_scenes[0] if structure_scenes.size() > 0 else null
		1: return structure_scenes[1 % structure_scenes.size()]
		2: return structure_scenes[0] if structure_scenes.size() > 0 else null
		3: return structure_scenes[min(2, structure_scenes.size() - 1)]
		_: return structure_scenes[0]

# ---------------------------
# 4) Instantiate world with flexible structures
# ---------------------------
func _instantiate_world() -> void:
	# Rooms
	for i in node_count:
		if room_scene:
			var room := room_scene.instantiate()
			room.name = "Room_%d" % i
			room.transform.origin = nodes[i]["pos"]
			add_child(room)
			nodes[i]["inst"] = room
		
		# Place structure at each intersection/node with flexible selection
		if place_structures and structure_scenes.size() > 0:
			var selected_structure_scene = _select_structure_for_node(i)
			if selected_structure_scene:
				var structure := selected_structure_scene.instantiate()
				structure.name = "Structure_%d" % i
				
				# Position with offset
				var struct_pos = nodes[i]["pos"]
				struct_pos.y += structure_offset_y
				structure.position = struct_pos
				
				# Apply variable scaling
				var scale_factor = rng.randf_range(structure_scale_range.x, structure_scale_range.y)
				structure.scale = Vector3.ONE * scale_factor
				
				# Apply rotation variation
				var rotation_y = rng.randf_range(-structure_rotation_variation, structure_rotation_variation) * PI / 180.0
				structure.rotation.y = rotation_y
				
				# Additional rotation based on node properties (optional)
				if structure_type == StructureType.BY_DEGREE:
					structure.rotation.y += (nodes[i]["degree"] * 15.0) * PI / 180.0
				
				add_child(structure)
				nodes[i]["structure"] = structure
	
	# Pre-collect unit directions to neighbors per node
	var neighbor_dirs := []
	neighbor_dirs.resize(node_count)
	for i in node_count:
		neighbor_dirs[i] = []
	
	for e in edges:
		var a  = e.a
		var b  = e.b
		var pa: Vector3 = nodes[a]["pos"]
		var pb: Vector3 = nodes[b]["pos"]
		var ab := (pb - pa).normalized()
		neighbor_dirs[a].append(ab)
		neighbor_dirs[b].append(-ab)
	
	# Carve doors toward each neighbor
	for i in node_count:
		var room  = nodes[i]["inst"]
		if room and room.has_method("carve_door_facing"):
			for d in neighbor_dirs[i]:
				room.call("carve_door_facing", d)
	
	# Portals/links + bridges
	for e in edges:
		var a = e.a
		var b = e.b
		var pa: Vector3 = nodes[a]["pos"]
		var pb: Vector3 = nodes[b]["pos"]
		var mid := (pa + pb) * 0.5
		var dir := (pb - pa).normalized()
		var dist := pa.distance_to(pb)
		
		# Create bridge first (walkable pathway)
		if make_bridges:
			var bridge := CSGBox3D.new()
			bridge.name = "Bridge_%d_%d" % [a, b]
			bridge.size = Vector3(bridge_width, bridge_thickness, dist)  # Z = length
			var basis := Basis().looking_at(dir, Vector3.UP)  # -Z faces dir
			bridge.transform = Transform3D(basis, mid)
			bridge.operation = CSGShape3D.OPERATION_UNION
			bridge.use_collision = true
			add_child(bridge)
		
		# Create portal (on top of bridge if both exist)
		if portal_scene:
			var portal := portal_scene.instantiate()
			portal.name = "Portal_%d_%d" % [a, b]
			var basis := Basis.looking_at(dir, Vector3.UP)
			portal.transform = Transform3D(basis, mid)
			
			# Optional: scale/mesh length to span between rooms if your portal uses a beam
			if portal.has_method("set_link_length"):
				portal.call("set_link_length", dist)
			
			# Tell the portal who it connects
			if portal.has_method("set_link_nodes"):
				portal.call("set_link_nodes", a, b)
			
			add_child(portal)
			e.portal = portal

# ---------------------------
# 5) Compute graph distances and drive ambience
# ---------------------------
func _apply_ambience_by_distance() -> void:
	var dist := _dijkstra(focal_node)
	var maxd := 0.0
	for d in dist:
		maxd = max(maxd, d)
	if maxd <= 0.0:
		maxd = 1.0
	
	for i in node_count:
		var t = clamp(dist[i] / maxd, 0.0, 1.0)
		# Example mappings:
		# - room light gets cooler & dimmer as distance increases
		# - background audio volume lowers with distance
		var room = nodes[i]["inst"]
		if room == null:
			continue
		
		if room.has_node("Light"):
			var light = room.get_node("Light")
			if light is OmniLight3D:
				light.light_energy = lerp(4.0, 0.8, t)
		
		if room.has_node("AudioStream"):
			var audio = room.get_node("AudioStream")
			if audio is AudioStreamPlayer3D:
				audio.volume_db = lerp(-2.0, -12.0, t)

# Dijkstra for non-negative weights
func _dijkstra(src: int) -> PackedFloat32Array:
	var dist := PackedFloat32Array()
	dist.resize(node_count)
	for i in node_count:
		dist[i] = INF
	dist[src] = 0.0
	
	var visited := {}
	while visited.size() < node_count:
		var u := -1
		var best := INF
		for i in node_count:
			if i in visited:
				continue
			if dist[i] < best:
				best = dist[i]
				u = i
		if u == -1:
			break
		visited[u] = true
		
		for nb in adjacency[u]:
			var alt = dist[u] + nb.w
			if alt < dist[nb.to]:
				dist[nb.to] = alt
	
	return dist

# ---------------------------
# Debug draw in-editor (Godot gizmos)
# ---------------------------
func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_gizmos()

func _get_configuration_warnings() -> PackedStringArray:
	var warns: PackedStringArray = []
	if room_scene == null:
		warns.append("Assign a Room PackedScene.")
	if portal_scene == null:
		warns.append("Assign a Portal PackedScene.")
	if structure_scenes.is_empty() and place_structures:
		warns.append("Add Structure PackedScenes to the array or disable place_structures.")
	return warns

func _draw() -> void:
	if !show_debug_links:
		return
	for e in edges:
		var pa: Vector3 = nodes[e.a]["pos"]
		var pb: Vector3 = nodes[e.b]["pos"]
		get_viewport().debug_draw_line_3d(pa, pb, Color(0.3, 0.9, 1.0, 0.7))
