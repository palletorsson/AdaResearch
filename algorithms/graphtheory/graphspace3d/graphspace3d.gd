# Enhanced 3D GraphSpace for VR with volumetric pathways
# GraphSpace3D.gd - Full 3D navigation with multi-level architecture
@tool
extends Node3D
class_name GraphSpace3D

# Structure type enum with 3D-specific options
enum StructureType {
	RANDOM,          # Randomly choose from available structures
	BY_DEGREE,       # Choose based on node connectivity
	BY_ELEVATION,    # Choose based on height in 3D space
	BY_CLUSTER,      # Choose based on 3D spatial clustering
	SINGLE_TYPE,     # Use only one structure type
	CUSTOM_PATTERN,  # Custom assignment pattern
	BY_CENTRALITY    # Choose based on 3D centrality measures
}

# Bridge type enum for 3D pathways
enum BridgeType {
	STRAIGHT,        # Direct linear connection
	CURVED,          # Smooth curved path
	SPIRAL,          # Spiral pathway for large elevation changes
	TUNNEL,          # Enclosed pathway
	SKYWAY,          # Elevated bridge with supports
	TELEPORTER       # Instant transportation nodes
}

# --- Assign in Inspector ---
@export var room_scene: PackedScene
@export var portal_scene: PackedScene

# --- 3D Structure Configuration ---
@export_group("3D Structures")
@export var structure_scenes: Array[PackedScene] = []
@export var structure_type: StructureType = StructureType.BY_ELEVATION
@export var place_structures: bool = true
@export var structure_scale_range: Vector2 = Vector2(0.5, 2.0)
@export var structure_offset_y: float = 0.0
@export var structure_rotation_variation: float = 90.0
@export var multi_story_probability: float = 0.3  # Chance for multi-story buildings

# --- 3D Layout Controls ---
@export_group("3D Graph Layout")
@export var node_count: int = 15
@export var avg_degree: float = 2.5
@export var layout_iters: int = 400
@export var seed: int = 20250922
@export var node_spacing: float = 8.0
@export var edge_stiffness: float = 0.05
@export var volume_repulsion: float = 250.0
@export var damping: float = 0.85

# --- 3D Bounds and Physics ---
@export_group("3D Physics")
@export var volume_bounds: Vector3 = Vector3(80, 40, 80)
@export var elevation_range: Vector2 = Vector2(-15, 25)
@export var gravity_strength: float = 0.02
@export var layer_snap_strength: float = 0.15
@export var discrete_levels: int = 5  # Number of preferred elevation levels

# --- 3D Bridge System ---
@export_group("3D Bridges")
@export var make_bridges: bool = true
@export var bridge_type: BridgeType = BridgeType.CURVED
@export var bridge_width: float = 1.5
@export var bridge_thickness: float = 0.15
@export var bridge_arc_height: float = 3.0
@export var min_bridge_clearance: float = 2.0
@export var comfort_radius: float = 2.0  # VR-comfortable curve radius

# --- VR Interaction ---
@export_group("VR Features")
@export var enable_hand_manipulation: bool = true
@export var teleporter_threshold: float = 20.0  # Distance threshold for teleporters
@export var comfort_locomotion: bool = true
@export var show_pathway_preview: bool = true

# --- Gameplay & Ambience ---
@export_group("3D Gameplay")
@export var focal_node: int = 0
@export var edge_cost_min: float = 1.0
@export var edge_cost_max: float = 5.0
@export var elevation_cost_multiplier: float = 1.5  # Extra cost for vertical movement

# Internal 3D state
var rng: RandomNumberGenerator
var nodes := []  # Array[Dictionary]: {"pos": Vector3, "vel": Vector3, "inst": Node3D, "degree": int, "elevation_level": int}
var edges := []  # Array[Dictionary]: {"a": int, "b": int, "w": float, "portal": Node, "bridge_type": BridgeType}
var adjacency := []  # Array[Array[{to:int, w:float}]]
var elevation_levels := []  # Preferred Y positions for discrete levels

# 3D Visualization elements
var pathway_previews := []
var architectural_elements := []
var comfort_indicators := []

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	_setup_elevation_levels()
	_build_3d_graph()
	_layout_3d_graph()
	_instantiate_3d_world()
	_apply_3d_ambience()
	update_gizmos()

# ---------------------------
# 1) Setup 3D elevation system
# ---------------------------
func _setup_elevation_levels() -> void:
	elevation_levels.clear()
	for i in range(discrete_levels):
		var level_y = lerp(elevation_range.x, elevation_range.y, float(i) / float(discrete_levels - 1))
		elevation_levels.append(level_y)

# ---------------------------
# 2) Build 3D connected graph with elevation awareness
# ---------------------------
func _build_3d_graph() -> void:
	nodes.clear()
	edges.clear()
	adjacency = []
	
	for i in node_count:
		# Initial 3D position with elevation preference
		var initial_pos = _rand_volume(volume_bounds * 0.3)
		var preferred_level = _get_nearest_elevation_level(initial_pos.y)
		
		nodes.append({
			"pos": initial_pos,
			"vel": Vector3.ZERO,
			"inst": null,
			"degree": 0,
			"structure": null,
			"elevation_level": preferred_level,
			"centrality": 0.0
		})
		adjacency.append([])
	
	# Ensure connectivity via 3D spanning tree
	var remaining := []
	for i in node_count:
		remaining.append(i)
	
	var connected := [remaining.pop_front()]
	while remaining.size() > 0:
		var a = connected[rng.randi() % connected.size()]
		var b = remaining.pop_at(rng.randi() % remaining.size())
		_add_3d_edge(a, b, _calculate_3d_cost(a, b))
		connected.append(b)
	
	# Add extra edges considering 3D proximity
	var target_edges := int(round((avg_degree * node_count) / 2.0))
	while edges.size() < target_edges:
		var a = rng.randi() % node_count
		var b = rng.randi() % node_count
		if a == b:
			continue
		if !_has_edge(a, b) and _is_3d_connection_viable(a, b):
			_add_3d_edge(a, b, _calculate_3d_cost(a, b))
	
	_calculate_node_properties()

func _add_3d_edge(a: int, b: int, w: float) -> void:
	var selected_bridge_type = _determine_bridge_type(a, b)
	edges.append({
		"a": a, 
		"b": b, 
		"w": w, 
		"portal": null,
		"bridge_type": selected_bridge_type
	})
	adjacency[a].append({"to": b, "w": w})
	adjacency[b].append({"to": a, "w": w})

func _calculate_3d_cost(a: int, b: int) -> float:
	var pos_a = nodes[a]["pos"]
	var pos_b = nodes[b]["pos"]
	var horizontal_distance = Vector2(pos_a.x - pos_b.x, pos_a.z - pos_b.z).length()
	var vertical_distance = abs(pos_a.y - pos_b.y)
	
	# Base cost with elevation penalty
	var base_cost = lerp(edge_cost_min, edge_cost_max, rng.randf())
	var elevation_penalty = vertical_distance * elevation_cost_multiplier
	
	return base_cost + elevation_penalty

func _is_3d_connection_viable(a: int, b: int) -> bool:
	var pos_a = nodes[a]["pos"]
	var pos_b = nodes[b]["pos"]
	var distance = pos_a.distance_to(pos_b)
	
	# Don't connect nodes that are too far apart
	if distance > node_spacing * 3.0:
		return false
	
	# Check for extreme elevation differences
	var elevation_diff = abs(pos_a.y - pos_b.y)
	if elevation_diff > volume_bounds.y * 0.6:
		return false
	
	return true

func _determine_bridge_type(a: int, b: int) -> BridgeType:
	var pos_a = nodes[a]["pos"]
	var pos_b = nodes[b]["pos"]
	var distance = pos_a.distance_to(pos_b)
	var elevation_diff = abs(pos_a.y - pos_b.y)
	
	# Use teleporter for very long distances
	if distance > teleporter_threshold:
		return BridgeType.TELEPORTER
	
	# Use spiral for large elevation changes
	if elevation_diff > node_spacing * 1.5:
		return BridgeType.SPIRAL
	
	# Use tunnel for underground connections
	if pos_a.y < elevation_range.x * 0.5 and pos_b.y < elevation_range.x * 0.5:
		return BridgeType.TUNNEL
	
	# Use skyway for high elevation connections
	if pos_a.y > elevation_range.y * 0.7 and pos_b.y > elevation_range.y * 0.7:
		return BridgeType.SKYWAY
	
	# Default to curved for VR comfort
	return BridgeType.CURVED if comfort_locomotion else BridgeType.STRAIGHT

func _get_nearest_elevation_level(y: float) -> int:
	var nearest_level = 0
	var min_distance = abs(y - elevation_levels[0])
	
	for i in range(1, elevation_levels.size()):
		var distance = abs(y - elevation_levels[i])
		if distance < min_distance:
			min_distance = distance
			nearest_level = i
	
	return nearest_level

func _calculate_node_properties() -> void:
	# Calculate degrees
	for i in node_count:
		var degree = 0
		for e in edges:
			if e.a == i or e.b == i:
				degree += 1
		nodes[i]["degree"] = degree
	
	# Calculate 3D centrality (simplified betweenness centrality)
	_calculate_3d_centrality()

func _calculate_3d_centrality() -> void:
	for i in node_count:
		var centrality = 0.0
		var distances = _dijkstra_3d(i)
		
		for j in node_count:
			if i != j and distances[j] != INF:
				centrality += 1.0 / distances[j]
		
		nodes[i]["centrality"] = centrality

func _rand_volume(bounds: Vector3) -> Vector3:
	return Vector3(
		rng.randf_range(-bounds.x/2, bounds.x/2),
		rng.randf_range(-bounds.y/2, bounds.y/2),
		rng.randf_range(-bounds.z/2, bounds.z/2)
	)

# ---------------------------
# 3) 3D Force-directed layout with elevation layers
# ---------------------------
func _layout_3d_graph() -> void:
	for _i in layout_iters:
		# 3D repulsion forces
		for i in node_count:
			var force := Vector3.ZERO
			var pi: Vector3 = nodes[i]["pos"]
			
			# Repulsion from other nodes
			for j in node_count:
				if i == j:
					continue
				var pj: Vector3 = nodes[j]["pos"]
				var d := pi.distance_to(pj) + 0.001
				var dir := (pi - pj) / d
				force += dir * (volume_repulsion / (d * d))
			
			# 3D spring attraction along edges
			for nb in adjacency[i]:
				var j = nb.to
				var pj: Vector3 = nodes[j]["pos"]
				var d := pi.distance_to(pj) + 0.001
				var dir := (pj - pi).normalized()
				var desired := node_spacing
				var stretch := d - desired
				force += dir * (stretch * edge_stiffness)
			
			# Soft bounds containment in 3D
			if pi.length() > volume_bounds.length() * 0.5:
				var bounds_center = Vector3.ZERO
				force += (bounds_center - pi).normalized() * 0.03
			
			# Gravity pull
			force.y -= gravity_strength
			
			# Attraction to preferred elevation levels
			var preferred_level_y = elevation_levels[nodes[i]["elevation_level"]]
			var level_attraction = (preferred_level_y - pi.y) * layer_snap_strength
			force.y += level_attraction
			
			nodes[i]["vel"] = (nodes[i]["vel"] + force) * damping
		
		# Integrate positions
		for i in node_count:
			nodes[i]["pos"] += nodes[i]["vel"]
			
			# Clamp to volume bounds
			var pos = nodes[i]["pos"]
			pos.x = clamp(pos.x, -volume_bounds.x/2, volume_bounds.x/2)
			pos.y = clamp(pos.y, elevation_range.x, elevation_range.y)
			pos.z = clamp(pos.z, -volume_bounds.z/2, volume_bounds.z/2)
			nodes[i]["pos"] = pos

# ---------------------------
# 4) Enhanced 3D structure selection
# ---------------------------
func _select_structure_for_node(node_index: int) -> PackedScene:
	if structure_scenes.is_empty():
		return null
	
	match structure_type:
		StructureType.RANDOM:
			return structure_scenes[rng.randi() % structure_scenes.size()]
		
		StructureType.BY_DEGREE:
			return _select_by_degree(node_index)
		
		StructureType.BY_ELEVATION:
			return _select_by_elevation(node_index)
		
		StructureType.BY_CLUSTER:
			return _select_by_cluster(node_index)
		
		StructureType.BY_CENTRALITY:
			return _select_by_centrality(node_index)
		
		StructureType.SINGLE_TYPE:
			return structure_scenes[0]
		
		StructureType.CUSTOM_PATTERN:
			return _select_by_custom_pattern(node_index)
		
		_:
			return structure_scenes[0]

func _select_by_elevation(node_index: int) -> PackedScene:
	var node_y = nodes[node_index]["pos"].y
	var normalized_elevation = (node_y - elevation_range.x) / (elevation_range.y - elevation_range.x)
	var structure_index = int(normalized_elevation * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_cluster(node_index: int) -> PackedScene:
	# Simple clustering based on 3D proximity
	var node_pos = nodes[node_index]["pos"]
	var cluster_id = int(node_pos.x / (volume_bounds.x / 3.0)) + int(node_pos.z / (volume_bounds.z / 3.0)) * 3
	cluster_id = cluster_id % structure_scenes.size()
	return structure_scenes[cluster_id]

func _select_by_centrality(node_index: int) -> PackedScene:
	var centrality = nodes[node_index]["centrality"]
	var max_centrality = 0.0
	for i in node_count:
		max_centrality = max(max_centrality, nodes[i]["centrality"])
	
	if max_centrality == 0.0:
		return structure_scenes[0]
	
	var normalized_centrality = centrality / max_centrality
	var structure_index = int(normalized_centrality * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_degree(node_index: int) -> PackedScene:
	var degree = nodes[node_index]["degree"]
	var max_degree = 0
	for i in node_count:
		max_degree = max(max_degree, nodes[i]["degree"])
	
	if max_degree == 0:
		return structure_scenes[0]
	
	var structure_index = int((float(degree) / float(max_degree)) * (structure_scenes.size() - 1))
	return structure_scenes[clamp(structure_index, 0, structure_scenes.size() - 1)]

func _select_by_custom_pattern(node_index: int) -> PackedScene:
	# Custom pattern considering elevation level
	var elevation_level = nodes[node_index]["elevation_level"]
	var pattern_index = (node_index + elevation_level) % structure_scenes.size()
	return structure_scenes[pattern_index]

# ---------------------------
# 5) Instantiate 3D world with enhanced bridge system
# ---------------------------
func _instantiate_3d_world() -> void:
	# Create room structures with 3D positioning
	for i in node_count:
		_create_node_room(i)
		_create_node_structure(i)
	
	# Create 3D pathways between nodes
	_create_3d_pathways()

func _create_node_room(node_index: int) -> void:
	if room_scene:
		var room := room_scene.instantiate()
		room.name = "Room_%d" % node_index
		room.transform.origin = nodes[node_index]["pos"]
		add_child(room)
		nodes[node_index]["inst"] = room

func _create_node_structure(node_index: int) -> void:
	if place_structures and structure_scenes.size() > 0:
		var selected_structure_scene = _select_structure_for_node(node_index)
		if selected_structure_scene:
			var structure := selected_structure_scene.instantiate()
			structure.name = "Structure_%d" % node_index
			
			# 3D positioning with elevation offset
			var struct_pos = nodes[node_index]["pos"]
			struct_pos.y += structure_offset_y
			structure.position = struct_pos
			
			# Variable scaling with elevation influence
			var elevation_factor = (nodes[node_index]["pos"].y - elevation_range.x) / (elevation_range.y - elevation_range.x)
			var base_scale = rng.randf_range(structure_scale_range.x, structure_scale_range.y)
			var elevation_scale = lerp(0.8, 1.2, elevation_factor)
			structure.scale = Vector3.ONE * base_scale * elevation_scale
			
			# 3D rotation variation
			var rotation_variation = Vector3(
				rng.randf_range(-structure_rotation_variation, structure_rotation_variation) * PI / 180.0,
				rng.randf_range(-structure_rotation_variation, structure_rotation_variation) * PI / 180.0,
				rng.randf_range(-structure_rotation_variation, structure_rotation_variation) * PI / 180.0
			)
			structure.rotation = rotation_variation
			
			# Multi-story probability based on centrality
			if rng.randf() < multi_story_probability * nodes[node_index]["centrality"]:
				structure.scale.y *= rng.randf_range(1.5, 3.0)
			
			add_child(structure)
			nodes[node_index]["structure"] = structure

func _create_3d_pathways() -> void:
	# Pre-calculate neighbor directions in 3D
	var neighbor_dirs := []
	neighbor_dirs.resize(node_count)
	for i in node_count:
		neighbor_dirs[i] = []
	
	for e in edges:
		var a = e.a
		var b = e.b
		var pa: Vector3 = nodes[a]["pos"]
		var pb: Vector3 = nodes[b]["pos"]
		var ab := (pb - pa).normalized()
		neighbor_dirs[a].append(ab)
		neighbor_dirs[b].append(-ab)
	
	# Create doors based on 3D directions
	for i in node_count:
		var room = nodes[i]["inst"]
		if room and room.has_method("carve_door_facing"):
			for d in neighbor_dirs[i]:
				room.call("carve_door_facing", d)
	
	# Create 3D bridges and portals
	for e in edges:
		_create_3d_bridge(e)
		_create_3d_portal(e)

func _create_3d_bridge(edge: Dictionary) -> void:
	if not make_bridges:
		return
	
	var a = edge.a
	var b = edge.b
	var pa: Vector3 = nodes[a]["pos"]
	var pb: Vector3 = nodes[b]["pos"]
	
	match edge.bridge_type:
		BridgeType.STRAIGHT:
			_create_straight_bridge(pa, pb, edge)
		BridgeType.CURVED:
			_create_curved_bridge(pa, pb, edge)
		BridgeType.SPIRAL:
			_create_spiral_bridge(pa, pb, edge)
		BridgeType.TUNNEL:
			_create_tunnel_bridge(pa, pb, edge)
		BridgeType.SKYWAY:
			_create_skyway_bridge(pa, pb, edge)
		BridgeType.TELEPORTER:
			_create_teleporter_nodes(pa, pb, edge)

func _create_straight_bridge(pa: Vector3, pb: Vector3, edge: Dictionary) -> void:
	var bridge := CSGBox3D.new()
	bridge.name = "Bridge_%d_%d" % [edge.a, edge.b]
	var distance = pa.distance_to(pb)
	bridge.size = Vector3(bridge_width, bridge_thickness, distance)
	
	var mid = (pa + pb) * 0.5
	var dir = (pb - pa).normalized()
	var basis = Basis().looking_at(dir, Vector3.UP)
	bridge.transform = Transform3D(basis, mid)
	bridge.operation = CSGShape3D.OPERATION_UNION
	bridge.use_collision = true
	add_child(bridge)

func _create_curved_bridge(pa: Vector3, pb: Vector3, edge: Dictionary) -> void:
	# Create curved path using multiple segments
	var segments = 8
	var control_height = bridge_arc_height
	
	for i in range(segments):
		var t1 = float(i) / float(segments)
		var t2 = float(i + 1) / float(segments)
		
		var p1 = _bezier_curve_point(pa, pb, control_height, t1)
		var p2 = _bezier_curve_point(pa, pb, control_height, t2)
		
		var segment := CSGBox3D.new()
		segment.name = "BridgeSegment_%d_%d_%d" % [edge.a, edge.b, i]
		var seg_distance = p1.distance_to(p2)
		segment.size = Vector3(bridge_width, bridge_thickness, seg_distance)
		
		var mid = (p1 + p2) * 0.5
		var dir = (p2 - p1).normalized()
		var basis = Basis().looking_at(dir, Vector3.UP)
		segment.transform = Transform3D(basis, mid)
		segment.operation = CSGShape3D.OPERATION_UNION
		segment.use_collision = true
		add_child(segment)

func _create_spiral_bridge(pa: Vector3, pb: Vector3, edge: Dictionary) -> void:
	# Create spiral path for large elevation changes
	var segments = 16
	var turns = abs(pb.y - pa.y) / node_spacing  # Number of spiral turns
	
	for i in range(segments):
		var t = float(i) / float(segments)
		var next_t = float(i + 1) / float(segments)
		
		var p1 = _spiral_path_point(pa, pb, turns, t)
		var p2 = _spiral_path_point(pa, pb, turns, next_t)
		
		var segment := CSGBox3D.new()
		segment.name = "SpiralSegment_%d_%d_%d" % [edge.a, edge.b, i]
		var seg_distance = p1.distance_to(p2)
		segment.size = Vector3(bridge_width, bridge_thickness, seg_distance)
		
		var mid = (p1 + p2) * 0.5
		var dir = (p2 - p1).normalized()
		var basis = Basis().looking_at(dir, Vector3.UP)
		segment.transform = Transform3D(basis, mid)
		segment.operation = CSGShape3D.OPERATION_UNION
		segment.use_collision = true
		add_child(segment)

func _create_tunnel_bridge(pa: Vector3, pb: Vector3, edge: Dictionary) -> void:
	# Create enclosed tunnel
	var tunnel := CSGBox3D.new()
	tunnel.name = "Tunnel_%d_%d" % [edge.a, edge.b]
	var distance = pa.distance_to(pb)
	tunnel.size = Vector3(bridge_width * 1.5, bridge_width * 1.5, distance)
	
	var mid = (pa + pb) * 0.5
	mid.y = min(pa.y, pb.y) - 1.0  # Place tunnel below ground level
	var dir = (pb - pa).normalized()
	var basis = Basis().looking_at(dir, Vector3.UP)
	tunnel.transform = Transform3D(basis, mid)
	tunnel.operation = CSGShape3D.OPERATION_UNION
	tunnel.use_collision = true
	add_child(tunnel)

func _create_skyway_bridge(pa: Vector3, pb: Vector3, edge: Dictionary) -> void:
	# Create elevated bridge with supports
	_create_curved_bridge(pa, pb, edge)  # Main bridge
	
	# Add support pillars
	var mid = (pa + pb) * 0.5
	var support := CSGBox3D.new()
	support.name = "SkywaySupport_%d_%d" % [edge.a, edge.b]
	support.size = Vector3(0.5, mid.y - elevation_range.x, 0.5)
	support.position = Vector3(mid.x, (mid.y + elevation_range.x) * 0.5, mid.z)
	support.operation = CSGShape3D.OPERATION_UNION
	support.use_collision = true
	add_child(support)

func _create_teleporter_nodes(pa: Vector3, pb: Vector3, edge: Dictionary) -> void:
	# Create teleporter entry/exit points
	for i in range(2):
		var pos = pa if i == 0 else pb
		var teleporter := CSGCylinder3D.new()
		teleporter.name = "Teleporter_%d_%d_%d" % [edge.a, edge.b, i]
		teleporter.radius = 1.0
		teleporter.height = 0.2
		teleporter.position = pos + Vector3(0, 0.1, 0)
		teleporter.operation = CSGShape3D.OPERATION_UNION
		teleporter.use_collision = true
		
		# Add glowing material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.1, 0.4, 0.8)
		teleporter.material_override = material
		
		add_child(teleporter)

func _create_3d_portal(edge: Dictionary) -> void:
	if not portal_scene:
		return
	
	var a = edge.a
	var b = edge.b
	var pa: Vector3 = nodes[a]["pos"]
	var pb: Vector3 = nodes[b]["pos"]
	var mid := (pa + pb) * 0.5
	var dir := (pb - pa).normalized()
	
	var portal := portal_scene.instantiate()
	portal.name = "Portal_%d_%d" % [a, b]
	var basis := Basis.looking_at(dir, Vector3.UP)
	portal.transform = Transform3D(basis, mid)
	
	# Enhanced portal properties for 3D
	if portal.has_method("set_3d_properties"):
		portal.call("set_3d_properties", edge.bridge_type, pa.distance_to(pb))
	
	if portal.has_method("set_link_length"):
		portal.call("set_link_length", pa.distance_to(pb))
	
	if portal.has_method("set_link_nodes"):
		portal.call("set_link_nodes", a, b)
	
	add_child(portal)
	edge.portal = portal

# ---------------------------
# 6) 3D Helper functions
# ---------------------------
func _bezier_curve_point(start: Vector3, end: Vector3, height: float, t: float) -> Vector3:
	var mid = (start + end) * 0.5
	var control = mid + Vector3(0, height, 0)
	
	# Quadratic Bezier curve
	var p1 = start.lerp(control, t)
	var p2 = control.lerp(end, t)
	return p1.lerp(p2, t)

func _spiral_path_point(start: Vector3, end: Vector3, turns: float, t: float) -> Vector3:
	var horizontal_pos = start.lerp(end, t)
	var radius = start.distance_to(end) * 0.3
	var angle = t * turns * 2.0 * PI
	
	var offset = Vector3(
		cos(angle) * radius * (1.0 - t),
		0,
		sin(angle) * radius * (1.0 - t)
	)
	
	return horizontal_pos + offset

# ---------------------------
# 7) Enhanced 3D ambience and distance calculation
# ---------------------------
func _apply_3d_ambience() -> void:
	var dist := _dijkstra_3d(focal_node)
	var maxd := 0.0
	for d in dist:
		if d != INF:
			maxd = max(maxd, d)
	if maxd <= 0.0:
		maxd = 1.0
	
	for i in node_count:
		var t = clamp(dist[i] / maxd, 0.0, 1.0)
		var room = nodes[i]["inst"]
		if room == null:
			continue
		
		# Enhanced 3D lighting based on elevation and distance
		var elevation_factor = (nodes[i]["pos"].y - elevation_range.x) / (elevation_range.y - elevation_range.x)
		
		if room.has_node("Light"):
			var light = room.get_node("Light")
			if light is OmniLight3D:
				var base_energy = lerp(3.0, 0.5, t)
				var elevation_bonus = elevation_factor * 2.0
				light.light_energy = base_energy + elevation_bonus
				
				# Color variation based on elevation
				var base_color = Color.WHITE
				var elevation_color = Color(1.0, 0.8 + elevation_factor * 0.2, 0.6 + elevation_factor * 0.4)
				light.light_color = base_color.lerp(elevation_color, elevation_factor)
		
		if room.has_node("AudioStream"):
			var audio = room.get_node("AudioStream")
			if audio is AudioStreamPlayer3D:
				audio.volume_db = lerp(-1.0, -15.0, t)

func _dijkstra_3d(src: int) -> PackedFloat32Array:
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
# 8) Utility functions
# ---------------------------
func _has_edge(a: int, b: int) -> bool:
	for e in edges:
		if (e.a == a and e.b == b) or (e.a == b and e.b == a):
			return true
	return false

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_gizmos()

func _get_configuration_warnings() -> PackedStringArray:
	var warns: PackedStringArray = []
	if room_scene == null:
		warns.append("Assign a Room PackedScene for 3D nodes.")
	if portal_scene == null:
		warns.append("Assign a Portal PackedScene for 3D connections.")
	if structure_scenes.is_empty() and place_structures:
		warns.append("Add Structure PackedScenes for 3D buildings or disable place_structures.")
	if discrete_levels < 2:
		warns.append("Use at least 2 discrete elevation levels for 3D layering.")
	return warns

# ---------------------------
# 9) VR Interaction and real-time manipulation
# ---------------------------
func get_node_at_position(world_pos: Vector3, threshold: float = 2.0) -> int:
	"""Get the nearest node to a world position (for VR interaction)"""
	var nearest_node = -1
	var min_distance = threshold
	
	for i in node_count:
		var distance = nodes[i]["pos"].distance_to(world_pos)
		if distance < min_distance:
			min_distance = distance
			nearest_node = i
	
	return nearest_node

func move_node(node_index: int, new_position: Vector3) -> void:
	"""Move a node to a new position (for VR hand manipulation)"""
	if node_index >= 0 and node_index < node_count:
		nodes[node_index]["pos"] = new_position
		
		# Update visual representation
		if nodes[node_index]["inst"]:
			nodes[node_index]["inst"].position = new_position
		
		# Recalculate affected edges
		_update_affected_edges(node_index)

func _update_affected_edges(node_index: int) -> void:
	"""Update edges connected to a moved node"""
	for edge in edges:
		if edge.a == node_index or edge.b == node_index:
			# Recalculate edge cost
			edge.w = _calculate_3d_cost(edge.a, edge.b)
			
			# Update bridge type if needed
			edge.bridge_type = _determine_bridge_type(edge.a, edge.b)

func preview_connection(from_pos: Vector3, to_pos: Vector3) -> void:
	"""Show a preview of a potential connection (for VR path sketching)"""
	if show_pathway_preview:
		# Create temporary preview path
		var preview_path = _create_preview_bridge(from_pos, to_pos)
		pathway_previews.append(preview_path)

func _create_preview_bridge(pa: Vector3, pb: Vector3) -> Node3D:
	"""Create a temporary preview bridge for VR interaction"""
	var preview := CSGBox3D.new()
	preview.name = "PreviewBridge"
	var distance = pa.distance_to(pb)
	preview.size = Vector3(bridge_width * 0.5, bridge_thickness * 0.5, distance)
	
	var mid = (pa + pb) * 0.5
	var dir = (pb - pa).normalized()
	var basis = Basis().looking_at(dir, Vector3.UP)
	preview.transform = Transform3D(basis, mid)
	
	# Semi-transparent material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.0, 0.5)
	material.flags_transparent = true
	preview.material_override = material
	
	add_child(preview)
	return preview

func clear_pathway_previews() -> void:
	"""Clear all pathway preview elements"""
	for preview in pathway_previews:
		if preview and is_instance_valid(preview):
			preview.queue_free()
	pathway_previews.clear()
