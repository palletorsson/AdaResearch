# @identity
# essence: F -> F[+F]F[-F]F -- L-system grammar drives vine growth toward the player
# desire: a vine growing from axiom F through production rules, branching procedurally toward its target
# critical_parameter: _rules dictionary / _iteration_count -- grammar rules determine branching, iterations control depth
# triggers: iteration_timer drives growth; player position attracts branch direction; damage on contact
# emerges: biological growth pattern as hunting strategy -- the vine does not chase, it grows toward you
# needs: HazardCreatureBase [has]; L-system string rewriting [has]; procedural mesh generation [has]; player targeting [has]
# relationships: embodies L-systems sequence; contrasts with fractal_hydra (growth vs splitting)
# truth: the simplest grammar generates the branching complexity of all plant life.

extends HazardCreatureBase
class_name BranchingVine
## L-systems sequence — procedural vine that grows via L-system rules.
## Initial axiom "F", rule: "F" -> "F[+F][-F]F". Iterates every 3 seconds
## up to depth 4. Branches grow toward the player (angle bias).
## Branch tips (leaves) deal contact damage. Damage prunes branches.

@export_group("L-System")
@export var iteration_interval: float = 3.0
@export var max_iterations: int = 4
@export var segment_length: float = 0.15
@export var branch_angle: float = 25.0
@export var segment_radius: float = 0.015
@export var leaf_radius: float = 0.035
@export var player_bias: float = 0.3

@export_group("Combat")
@export var leaf_damage: float = 8.0

# ── L-System State ─────────────────────────────────────────────────────
var _axiom: String = "F"
var _rules: Dictionary = {"F": "F[+F][-F]F"}
var _current_string: String = "F"
var _iteration_count: int = 0
var _iteration_timer: float = 0.0

# ── Visual State ───────────────────────────────────────────────────────
var _segments: Array[Dictionary] = []  # {mesh, start, end, depth, is_leaf, children_indices}
var _trunk_mat: StandardMaterial3D = null
var _leaf_mat: StandardMaterial3D = null
var _label: Label3D = null
var _vine_root: Node3D = null
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0


func _on_ready() -> void:
	max_health = 85.0
	_health = max_health
	chase_speed = 1.8
	patrol_speed = 1.0
	contact_damage = 8.0
	detection_radius = 7.0

	_build_l_system()


func _create_materials() -> void:
	_trunk_mat = _make_material(Color(0.35, 0.22, 0.1), Color(0.15, 0.1, 0.02))
	_leaf_mat = _make_material(Color(0.3, 0.9, 0.15), Color(0.2, 0.7, 0.1))


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.3
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.0

	_vine_root = Node3D.new()
	_vine_root.name = "VineRoot"
	_mesh_root.add_child(_vine_root)

	# 2 legs (root tendrils)
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.1, 0, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.12
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.01
		var leg_mat := _make_material(Color(0.3, 0.18, 0.08), Color.BLACK)
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, leg_mat)
		mi.position = Vector3(0, -0.06, 0)
		root.add_child(mi)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 1.2, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _build_l_system() -> void:
	# Clear existing segments
	for seg in _segments:
		if is_instance_valid(seg["mesh"]):
			seg["mesh"].queue_free()
	_segments.clear()

	# Interpret the current L-system string using turtle graphics
	var turtle_pos := Vector3(0, 0.05, 0)
	var turtle_dir := Vector3(0, 1, 0)  # Growing upward
	var turtle_right := Vector3(1, 0, 0)
	var stack: Array[Dictionary] = []
	var current_depth: int = 0

	# Player bias direction
	var bias_dir := Vector3.ZERO
	if is_instance_valid(_player_node):
		bias_dir = (_player_node.global_position - global_position).normalized()
		bias_dir.y = 0.0

	var angle_rad: float = deg_to_rad(branch_angle)

	for ch in _current_string:
		var c: String = ch
		match c:
			"F":
				# Draw segment forward
				var biased_dir: Vector3 = turtle_dir
				if bias_dir.length() > 0.01:
					biased_dir = (turtle_dir + bias_dir * player_bias).normalized()

				var end_pos: Vector3 = turtle_pos + biased_dir * segment_length
				_create_segment(turtle_pos, end_pos, current_depth, false)
				turtle_pos = end_pos
			"+":
				# Rotate right
				turtle_dir = turtle_dir.rotated(turtle_right.cross(turtle_dir).normalized(), angle_rad)
				if turtle_dir.length() < 0.01:
					turtle_dir = Vector3(0, 1, 0)
				turtle_dir = turtle_dir.normalized()
			"-":
				# Rotate left
				turtle_dir = turtle_dir.rotated(turtle_right.cross(turtle_dir).normalized(), -angle_rad)
				if turtle_dir.length() < 0.01:
					turtle_dir = Vector3(0, 1, 0)
				turtle_dir = turtle_dir.normalized()
			"[":
				# Push state
				stack.append({
					"pos": turtle_pos,
					"dir": turtle_dir,
					"right": turtle_right,
					"depth": current_depth,
				})
				current_depth += 1
			"]":
				# Pop state — add leaf at current tip before popping
				_create_segment(turtle_pos, turtle_pos, current_depth, true)
				if not stack.is_empty():
					var saved: Dictionary = stack.pop_back()
					turtle_pos = saved["pos"]
					turtle_dir = saved["dir"]
					turtle_right = saved["right"]
					current_depth = saved["depth"]


func _create_segment(start: Vector3, end: Vector3, depth: int, is_leaf: bool) -> void:
	if is_leaf:
		# Leaf sphere
		var sphere := SphereMesh.new()
		sphere.radius = leaf_radius
		sphere.height = leaf_radius * 2.0
		# Darken green with depth
		var green_val: float = max(0.3, 0.9 - depth * 0.15)
		var leaf_color := Color(0.2, green_val, 0.1)
		var mat := _make_material(leaf_color, leaf_color * 0.8)
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.set_surface_override_material(0, mat)
		mi.position = start
		_vine_root.add_child(mi)

		_segments.append({
			"mesh": mi,
			"start": start,
			"end": end,
			"depth": depth,
			"is_leaf": true,
		})
		return

	var diff: Vector3 = end - start
	var length: float = diff.length()
	if length < 0.001:
		return

	var mid: Vector3 = (start + end) * 0.5

	# Branch cylinder — thinner with depth
	var cyl := CylinderMesh.new()
	cyl.height = length
	var radius_factor: float = max(0.3, 1.0 - depth * 0.2)
	cyl.top_radius = segment_radius * radius_factor * 0.8
	cyl.bottom_radius = segment_radius * radius_factor

	# Darken trunk color with depth
	var brown_val: float = max(0.1, 0.35 - depth * 0.05)
	var green_tint: float = min(0.3, depth * 0.06)
	var branch_color := Color(brown_val, 0.15 + green_tint, 0.08)
	var mat := _make_material(branch_color, Color.BLACK)

	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, mat)
	mi.position = mid
	_vine_root.add_child(mi)

	# Orient cylinder along segment
	if diff.normalized().length() > 0.01:
		var up := Vector3.UP
		if abs(diff.normalized().dot(up)) > 0.95:
			up = Vector3.RIGHT
		mi.look_at_from_position(mid, mid + diff.normalized(), up)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_segments.append({
		"mesh": mi,
		"start": start,
		"end": end,
		"depth": depth,
		"is_leaf": false,
	})


func _iterate_l_system() -> void:
	if _iteration_count >= max_iterations:
		return

	var new_string: String = ""
	for ch in _current_string:
		var c: String = ch
		if _rules.has(c):
			new_string += _rules[c]
		else:
			new_string += c

	_current_string = new_string
	_iteration_count += 1
	_build_l_system()


func _process_visual(delta: float) -> void:
	# Iteration timer
	_iteration_timer += delta
	if _iteration_timer >= iteration_interval and _iteration_count < max_iterations:
		_iteration_timer = 0.0
		_iterate_l_system()

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 4.0
		for i in range(_leg_roots.size()):
			_leg_roots[i].rotation.x = sin(_walk_phase + float(i) * PI) * 0.2

	# Gentle sway of vine
	if is_instance_valid(_vine_root):
		_vine_root.rotation.z = sin(_walk_phase * 0.3) * 0.05

	# Leaf proximity damage during chase
	if _state == BaseState.CHASE and is_instance_valid(_player_node):
		for seg in _segments:
			if seg["is_leaf"] and is_instance_valid(seg["mesh"]):
				var leaf_world: Vector3 = seg["mesh"].global_position
				var dist: float = leaf_world.distance_to(_player_node.global_position)
				if dist < 0.25:
					var gm = get_node_or_null("/root/GameManager")
					if gm and gm.has_method("apply_health_damage"):
						gm.apply_health_damage(leaf_damage * delta)
					break  # Only one leaf damages per frame

	# Label
	if _label:
		_label.text = "ITERATION: %d, BRANCHES: %d" % [_iteration_count, _segments.size()]


func _on_damaged(_amount: float) -> void:
	# Prune a random branch segment (and its children at higher depth)
	if _segments.is_empty():
		_set_state(BaseState.STUNNED)
		return

	# Pick a random segment to prune
	var prune_idx: int = randi() % _segments.size()
	var prune_depth: int = _segments[prune_idx]["depth"]

	# Remove this segment and all segments at deeper depth after it
	var to_remove: Array[int] = [prune_idx]
	for i in range(prune_idx + 1, _segments.size()):
		if _segments[i]["depth"] > prune_depth:
			to_remove.append(i)
		else:
			break  # Stop when we reach same or shallower depth

	# Remove from back to front
	for idx in range(to_remove.size() - 1, -1, -1):
		var ri: int = to_remove[idx]
		if ri < _segments.size():
			if is_instance_valid(_segments[ri]["mesh"]):
				_segments[ri]["mesh"].queue_free()
			_segments.remove_at(ri)

	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_iteration_timer = iteration_interval * 0.5  # Iterate sooner when chasing
