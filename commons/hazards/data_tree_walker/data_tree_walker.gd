# @identity
# essence: BST.traverse(node) -> walk(node.position) -- binary search tree that walks on its own leaves
# desire: sphere nodes connected by edges forming a walking tree -- data structure IS the skeleton
# critical_parameter: tree balance / traversal order -- BST rebalancing determines the creature's gait
# triggers: player proximity triggers traversal; in-order/pre-order/post-order determines attack pattern
# emerges: the data structure literally walks -- binary search becomes bipedal locomotion
# needs: HazardCreatureBase [has]; BST node/edge visualization [has]; traversal animation [has]; VR interaction [missing]
# relationships: embodies datastructures sequence; pairs with index_sentinel (linear vs tree traversal)
# truth: a binary search tree balancing on its own leaves -- structure is not abstract, it walks.

extends HazardCreatureBase
class_name DataTreeWalker
## Data Structures hazard — a walking binary tree made of sphere nodes
## connected by cylinder edges. Walks on leaf nodes. AVL rotations
## visible when damaged. Teaches tree structure and rebalancing.

@export_group("Tree")
@export var node_radius: float = 0.06
@export var edge_radius: float = 0.015
@export var level_height: float = 0.2
@export var level_spread: float = 0.15
@export var max_depth: int = 3

@export_group("Appearance")
@export var node_color: Color = Color(0.3, 0.7, 1.0)
@export var root_color: Color = Color(1.0, 0.8, 0.2)
@export var edge_color: Color = Color(0.4, 0.5, 0.6)
@export var emission: Color = Color(0.2, 0.5, 1.0)

# Tree data
var _tree_nodes: Array[Dictionary] = []  # {value, left_idx, right_idx, depth, mesh, edge_mesh, pos}
var _node_mat: StandardMaterial3D
var _root_mat: StandardMaterial3D
var _edge_mat: StandardMaterial3D
var _label: Label3D = null
var _walk_phase: float = 0.0


func _on_ready() -> void:
	add_to_group("tree_enemy")
	_build_initial_tree()


func _create_materials() -> void:
	_node_mat = _make_material(node_color, emission)
	_root_mat = _make_material(root_color, Color(1.0, 0.7, 0.1))
	_root_mat.emission_energy_multiplier = 2.5
	_edge_mat = _make_material(edge_color)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	_label = Label3D.new()
	_label.text = "BST"
	_label.font_size = 24
	_label.pixel_size = 0.002
	_label.modulate = root_color
	_label.position = Vector3(0.0, 0.9, 0.05)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _build_initial_tree() -> void:
	# Build a balanced BST with values 1-7
	var values: Array[int] = [4, 2, 6, 1, 3, 5, 7]
	for v in values:
		_insert_value(v)
	_rebuild_tree_meshes()


func _insert_value(val: int) -> void:
	var node := {
		"value": val,
		"left_idx": -1,
		"right_idx": -1,
		"depth": 0,
		"mesh": null,
		"edge_mesh": null,
		"label": null,
	}

	if _tree_nodes.is_empty():
		_tree_nodes.append(node)
		return

	# Simple BST insert
	var current: int = 0
	var depth: int = 0
	while true:
		depth += 1
		if val < _tree_nodes[current]["value"]:
			if _tree_nodes[current]["left_idx"] == -1:
				node["depth"] = depth
				_tree_nodes[current]["left_idx"] = _tree_nodes.size()
				_tree_nodes.append(node)
				return
			current = _tree_nodes[current]["left_idx"]
		else:
			if _tree_nodes[current]["right_idx"] == -1:
				node["depth"] = depth
				_tree_nodes[current]["right_idx"] = _tree_nodes.size()
				_tree_nodes.append(node)
				return
			current = _tree_nodes[current]["right_idx"]


func _get_node_position(idx: int) -> Vector3:
	if idx < 0 or idx >= _tree_nodes.size():
		return Vector3.ZERO

	# Compute position by traversing from root
	var path: Array[int] = []
	_find_path(0, idx, path)

	var x: float = 0.0
	var y: float = 0.75  # Root height
	var spread: float = level_spread * pow(2, max_depth - 1)

	for i in range(path.size()):
		var parent_idx: int = path[i]
		if i + 1 < path.size():
			var child_idx: int = path[i + 1]
			spread *= 0.5
			if _tree_nodes[parent_idx]["left_idx"] == child_idx:
				x -= spread
			else:
				x += spread
			y -= level_height

	return Vector3(x, y, 0.0)


func _find_path(current: int, target: int, path: Array[int]) -> bool:
	path.append(current)
	if current == target:
		return true
	var left: int = _tree_nodes[current]["left_idx"]
	var right: int = _tree_nodes[current]["right_idx"]
	if left != -1 and _find_path(left, target, path):
		return true
	if right != -1 and _find_path(right, target, path):
		return true
	path.pop_back()
	return false


func _rebuild_tree_meshes() -> void:
	# Clear existing
	for n in _tree_nodes:
		if n["mesh"] and is_instance_valid(n["mesh"]):
			n["mesh"].queue_free()
		if n["edge_mesh"] and is_instance_valid(n["edge_mesh"]):
			n["edge_mesh"].queue_free()
		if n["label"] and is_instance_valid(n["label"]):
			n["label"].queue_free()

	# Build new
	var sphere := SphereMesh.new()
	sphere.radius = node_radius
	sphere.height = node_radius * 2.0

	for i in range(_tree_nodes.size()):
		var pos: Vector3 = _get_node_position(i)
		var mat: StandardMaterial3D = _root_mat if i == 0 else _node_mat
		var mi := _add_mesh(sphere, mat.duplicate(), pos)
		_tree_nodes[i]["mesh"] = mi

		# Value label
		var lbl := Label3D.new()
		lbl.text = str(_tree_nodes[i]["value"])
		lbl.font_size = 18
		lbl.pixel_size = 0.001
		lbl.modulate = Color.WHITE
		lbl.position = Vector3(0.0, node_radius + 0.02, 0.03)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mi.add_child(lbl)
		_tree_nodes[i]["label"] = lbl

		# Edge to parent
		if i > 0:
			var parent_idx: int = _find_parent(i)
			if parent_idx >= 0:
				var parent_pos: Vector3 = _get_node_position(parent_idx)
				var edge := _create_edge(parent_pos, pos)
				_tree_nodes[i]["edge_mesh"] = edge

	if _label:
		_label.text = "BST | %d nodes" % _tree_nodes.size()


func _find_parent(child_idx: int) -> int:
	for i in range(_tree_nodes.size()):
		if _tree_nodes[i]["left_idx"] == child_idx or _tree_nodes[i]["right_idx"] == child_idx:
			return i
	return -1


func _create_edge(from_pos: Vector3, to_pos: Vector3) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	var dist: float = from_pos.distance_to(to_pos)
	cyl.height = dist
	cyl.top_radius = edge_radius
	cyl.bottom_radius = edge_radius

	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, _edge_mat)

	# Position at midpoint, rotate to connect
	var mid: Vector3 = (from_pos + to_pos) * 0.5
	mi.position = mid
	var dir: Vector3 = (to_pos - from_pos).normalized()
	if dir.length() > 0.01:
		mi.look_at(mi.global_position + dir, Vector3.RIGHT)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_mesh_root.add_child(mi)
	return mi


func _process_visual(delta: float) -> void:
	# Walk on leaf nodes
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * patrol_speed * 3.0
		if _mesh_root:
			_mesh_root.position.y = abs(sin(_walk_phase)) * 0.05

	# Pulse root node
	if _tree_nodes.size() > 0:
		var root_mesh: MeshInstance3D = _tree_nodes[0]["mesh"]
		if root_mesh and is_instance_valid(root_mesh):
			var pulse: float = 0.8 + 0.2 * sin(_walk_phase * 0.5)
			root_mesh.scale = Vector3.ONE * pulse


func _on_damaged(_amount: float) -> void:
	# Visual "rotation" effect — shuffle a random subtree
	if _tree_nodes.size() > 2:
		var idx: int = randi() % _tree_nodes.size()
		var node_data: Dictionary = _tree_nodes[idx]
		# Swap left and right children (simple rotation demo)
		var tmp: int = node_data["left_idx"]
		node_data["left_idx"] = node_data["right_idx"]
		node_data["right_idx"] = tmp
		_rebuild_tree_meshes()
	_set_state(BaseState.STUNNED)
