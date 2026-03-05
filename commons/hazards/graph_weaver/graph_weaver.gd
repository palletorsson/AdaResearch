extends HazardCreatureBase
class_name GraphWeaver
## Graph theory sequence — network creature with 8 SphereMesh nodes
## connected by CylinderMesh edges. Starts with a random spanning tree.
## During CHASE: reconfigures edges to form shortest path toward player
## with a visual BFS traversal wave. Can fire edge projectiles.

@export_group("Graph")
@export var num_nodes: int = 8
@export var node_radius: float = 0.05
@export var edge_radius: float = 0.01
@export var arrangement_radius: float = 0.5
@export var orbit_speed: float = 0.15
@export var reconfigure_interval: float = 4.0
@export var traversal_speed: float = 0.3
@export var edge_fire_damage: float = 10.0
@export var projectile_speed: float = 5.0

# ── State ──────────────────────────────────────────────────────────────
var _node_positions: Array[Vector3] = []   # Local positions
var _node_meshes: Array[MeshInstance3D] = []
var _node_mats: Array[StandardMaterial3D] = []
var _edges: Array[Array] = []              # Array of [int, int] pairs
var _edge_meshes: Array[MeshInstance3D] = []
var _edge_mat: StandardMaterial3D = null
var _active_edge_mat: StandardMaterial3D = null
var _shortest_path: Array[int] = []
var _traversal_order: Array[int] = []
var _traversal_index: int = 0
var _traversal_timer: float = 0.0
var _reconfig_timer: float = 0.0
var _label: Label3D = null
var _projectiles: Array[Dictionary] = []
var _node_default_mat: StandardMaterial3D = null
var _node_active_mat: StandardMaterial3D = null
var _path_mat: StandardMaterial3D = null
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0
var _time: float = 0.0


func _on_ready() -> void:
	max_health = 80.0
	_health = max_health
	chase_speed = 2.5
	patrol_speed = 1.5
	contact_damage = 12.0
	detection_radius = 9.0


func _create_materials() -> void:
	_node_default_mat = _make_material(Color(0.2, 0.4, 0.9), Color(0.1, 0.2, 0.6))
	_node_active_mat = _make_material(Color(1.0, 0.85, 0.1), Color(0.9, 0.75, 0.05))
	_path_mat = _make_material(Color(0.95, 0.15, 0.1), Color(0.8, 0.1, 0.05))
	_edge_mat = _make_material(Color(0.5, 0.5, 0.5), Color(0.2, 0.2, 0.2))
	_active_edge_mat = _make_material(Color(0.95, 0.15, 0.1), Color(0.8, 0.1, 0.05))


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	col.position.y = 0.5
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.5

	# Place nodes in a rough circle with slight random offsets
	for i in range(num_nodes):
		var angle: float = (float(i) / float(num_nodes)) * TAU
		var pos := Vector3(
			cos(angle) * arrangement_radius + randf_range(-0.08, 0.08),
			randf_range(-0.1, 0.1),
			sin(angle) * arrangement_radius + randf_range(-0.08, 0.08)
		)
		_node_positions.append(pos)

		var mat := _node_default_mat.duplicate()
		_node_mats.append(mat)

		var sphere := SphereMesh.new()
		sphere.radius = node_radius
		sphere.height = node_radius * 2.0
		var mi := _add_mesh(sphere, mat, pos)
		mi.name = "GraphNode_%d" % i
		_node_meshes.append(mi)

	# Generate random spanning tree
	_generate_spanning_tree()
	_rebuild_edge_meshes()

	# 2 legs
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.15, -0.4, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.2
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.015
		var leg_mat := _make_material(Color(0.3, 0.3, 0.4), Color.BLACK)
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, leg_mat)
		mi.position = Vector3(0, -0.1, 0)
		root.add_child(mi)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.5, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _generate_spanning_tree() -> void:
	# Prim's algorithm for random spanning tree
	_edges.clear()
	var in_tree: Array[bool] = []
	in_tree.resize(num_nodes)
	for i in range(num_nodes):
		in_tree[i] = false

	in_tree[0] = true
	var tree_count: int = 1

	while tree_count < num_nodes:
		# Collect candidate edges: (in_tree node, not-in-tree node)
		var candidates: Array[Array] = []
		for i in range(num_nodes):
			if not in_tree[i]:
				continue
			for j in range(num_nodes):
				if in_tree[j]:
					continue
				candidates.append([i, j])

		if candidates.is_empty():
			break

		var pick: Array = candidates[randi() % candidates.size()]
		_edges.append(pick)
		in_tree[pick[1]] = true
		tree_count += 1


func _rebuild_edge_meshes() -> void:
	# Clear old edge meshes
	for em in _edge_meshes:
		if is_instance_valid(em):
			em.queue_free()
	_edge_meshes.clear()

	# Build new edge meshes
	for edge in _edges:
		var from_pos: Vector3 = _node_positions[edge[0]]
		var to_pos: Vector3 = _node_positions[edge[1]]
		var mid: Vector3 = (from_pos + to_pos) * 0.5
		var diff: Vector3 = to_pos - from_pos
		var length: float = diff.length()

		var cyl := CylinderMesh.new()
		cyl.height = length
		cyl.top_radius = edge_radius
		cyl.bottom_radius = edge_radius
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, _edge_mat.duplicate())
		mi.position = mid
		_mesh_root.add_child(mi)

		# Orient the cylinder along the edge direction
		if diff.length() > 0.01:
			var up := Vector3.UP
			if abs(diff.normalized().dot(up)) > 0.95:
				up = Vector3.RIGHT
			mi.look_at_from_position(mid, mid + diff.normalized(), up)
			mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

		_edge_meshes.append(mi)


func _bfs_from(start: int) -> Array[int]:
	# Build adjacency list
	var adj: Array[Array] = []
	adj.resize(num_nodes)
	for i in range(num_nodes):
		adj[i] = []
	for edge in _edges:
		adj[edge[0]].append(edge[1])
		adj[edge[1]].append(edge[0])

	# BFS
	var visited: Array[bool] = []
	visited.resize(num_nodes)
	for i in range(num_nodes):
		visited[i] = false

	var queue: Array[int] = [start]
	var order: Array[int] = []
	visited[start] = true

	while not queue.is_empty():
		var current: int = queue.pop_front()
		order.append(current)
		for neighbor in adj[current]:
			var n: int = int(neighbor)
			if not visited[n]:
				visited[n] = true
				queue.append(n)

	return order


func _find_shortest_path_to_closest() -> Array[int]:
	# Find the node closest to the player
	if not is_instance_valid(_player_node):
		return []

	var player_local: Vector3 = _player_node.global_position - global_position
	player_local.y = 0.0
	var closest_idx: int = 0
	var closest_dist: float = INF
	for i in range(num_nodes):
		var d: float = _node_positions[i].distance_to(player_local)
		if d < closest_dist:
			closest_dist = d
			closest_idx = i

	# BFS from node 0 to closest_idx
	var adj: Array[Array] = []
	adj.resize(num_nodes)
	for i in range(num_nodes):
		adj[i] = []
	for edge in _edges:
		adj[edge[0]].append(edge[1])
		adj[edge[1]].append(edge[0])

	var visited: Array[bool] = []
	var parent: Array[int] = []
	visited.resize(num_nodes)
	parent.resize(num_nodes)
	for i in range(num_nodes):
		visited[i] = false
		parent[i] = -1

	var queue: Array[int] = [0]
	visited[0] = true

	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == closest_idx:
			break
		for neighbor in adj[current]:
			var n: int = int(neighbor)
			if not visited[n]:
				visited[n] = true
				parent[n] = current
				queue.append(n)

	# Reconstruct path
	var path: Array[int] = []
	var at: int = closest_idx
	while at != -1:
		path.insert(0, at)
		at = parent[at]
	return path


func _process_visual(delta: float) -> void:
	_time += delta

	# Slowly orbit node positions
	for i in range(num_nodes):
		var base_angle: float = (float(i) / float(num_nodes)) * TAU + _time * orbit_speed
		_node_positions[i] = Vector3(
			cos(base_angle) * arrangement_radius,
			sin(base_angle * 1.5) * 0.08,
			sin(base_angle) * arrangement_radius
		)
		_node_meshes[i].position = _node_positions[i]

	# Update edge visuals
	for ei in range(_edge_meshes.size()):
		if ei >= _edges.size():
			break
		var edge: Array = _edges[ei]
		var from_pos: Vector3 = _node_positions[edge[0]]
		var to_pos: Vector3 = _node_positions[edge[1]]
		var mid: Vector3 = (from_pos + to_pos) * 0.5
		var diff: Vector3 = to_pos - from_pos
		var length: float = diff.length()

		_edge_meshes[ei].position = mid
		# Rescale
		var cyl: CylinderMesh = _edge_meshes[ei].mesh as CylinderMesh
		if cyl:
			cyl.height = length

		if diff.length() > 0.01:
			var up := Vector3.UP
			if abs(diff.normalized().dot(up)) > 0.95:
				up = Vector3.RIGHT
			_edge_meshes[ei].look_at_from_position(mid, mid + diff.normalized(), up)
			_edge_meshes[ei].rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Traversal animation
	if not _traversal_order.is_empty():
		_traversal_timer += delta
		if _traversal_timer >= traversal_speed:
			_traversal_timer = 0.0
			if _traversal_index < _traversal_order.size():
				var node_idx: int = _traversal_order[_traversal_index]
				_node_mats[node_idx].albedo_color = Color(1.0, 0.85, 0.1)
				_node_mats[node_idx].emission = Color(0.9, 0.75, 0.05)
				_node_mats[node_idx].emission_energy_multiplier = 2.5
				_traversal_index += 1
			else:
				_traversal_order.clear()
				_traversal_index = 0

	# Color shortest path nodes in red
	for idx in _shortest_path:
		if idx < _node_mats.size():
			_node_mats[idx].albedo_color = Color(0.95, 0.15, 0.1)
			_node_mats[idx].emission = Color(0.8, 0.1, 0.05)

	# Color edges on shortest path
	for ei in range(_edges.size()):
		var edge: Array = _edges[ei]
		var on_path: bool = false
		for pi in range(_shortest_path.size() - 1):
			if (edge[0] == _shortest_path[pi] and edge[1] == _shortest_path[pi + 1]) or \
			   (edge[1] == _shortest_path[pi] and edge[0] == _shortest_path[pi + 1]):
				on_path = true
				break
		if on_path and ei < _edge_meshes.size():
			_edge_meshes[ei].set_surface_override_material(0, _active_edge_mat)

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			_leg_roots[i].rotation.x = sin(_walk_phase + float(i) * PI) * 0.25

	# Update projectiles
	var remove_list: Array[int] = []
	for i in range(_projectiles.size()):
		var proj: Dictionary = _projectiles[i]
		proj["lifetime"] -= delta
		if proj["lifetime"] <= 0.0 or not is_instance_valid(proj["node"]):
			remove_list.append(i)
			if is_instance_valid(proj["node"]):
				proj["node"].queue_free()
			continue
		proj["node"].global_position += proj["velocity"] * delta
		if is_instance_valid(_player_node):
			if proj["node"].global_position.distance_to(_player_node.global_position) < 0.3:
				_try_damage_target(_player_node)
				proj["node"].queue_free()
				remove_list.append(i)
	for idx in range(remove_list.size() - 1, -1, -1):
		_projectiles.remove_at(remove_list[idx])

	# Label
	if _label:
		_label.text = "EDGES: %d, SHORTEST PATH: %d" % [_edges.size(), _shortest_path.size()]


func _process_chase(delta: float) -> void:
	var dist: float = _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	# Reconfigure edges periodically
	_reconfig_timer += delta
	if _reconfig_timer >= reconfigure_interval:
		_reconfig_timer = 0.0
		_reconfigure_edges()

	# Standard chase movement
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity.x = move_dir.x * chase_speed
			velocity.z = move_dir.z * chase_speed
			_face_direction(move_dir, delta * 5.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	velocity.y = 0.0


func _reconfigure_edges() -> void:
	# Reset all node colors
	for mat in _node_mats:
		mat.albedo_color = Color(0.2, 0.4, 0.9)
		mat.emission = Color(0.1, 0.2, 0.6)
		mat.emission_energy_multiplier = 1.5

	# Regenerate spanning tree
	_generate_spanning_tree()
	_rebuild_edge_meshes()

	# Run BFS traversal for visual effect
	_traversal_order = _bfs_from(0)
	_traversal_index = 0
	_traversal_timer = 0.0

	# Compute shortest path
	_shortest_path = _find_shortest_path_to_closest()

	# Fire an edge projectile
	_fire_edge_projectile()


func _fire_edge_projectile() -> void:
	if not is_instance_valid(_player_node):
		return

	var dir: Vector3 = (_player_node.global_position - global_position).normalized()
	var cyl := CylinderMesh.new()
	cyl.height = 0.3
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	var proj_mat := _make_material(Color(0.8, 0.8, 0.8), Color(0.6, 0.6, 0.6))
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, proj_mat)
	mi.global_position = global_position + Vector3(0, 0.5, 0)
	get_parent().add_child(mi)

	# Orient along fire direction
	if dir.length() > 0.01:
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.95:
			up = Vector3.RIGHT
		mi.look_at_from_position(mi.global_position, mi.global_position + dir, up)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_projectiles.append({
		"node": mi,
		"velocity": dir * projectile_speed,
		"lifetime": 3.0,
	})


func _on_damaged(_amount: float) -> void:
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_reconfig_timer = reconfigure_interval - 1.0  # Trigger soon
		_shortest_path.clear()
	elif new_state == BaseState.PATROL:
		_reconfig_timer = 0.0
		_shortest_path.clear()
		_traversal_order.clear()
		for mat in _node_mats:
			mat.albedo_color = Color(0.2, 0.4, 0.9)
			mat.emission = Color(0.1, 0.2, 0.6)
			mat.emission_energy_multiplier = 1.5
