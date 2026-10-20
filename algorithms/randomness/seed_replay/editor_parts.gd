extends RefCounted
## part_<id>:x,z,yaw[,height,scale] stores a pose in authored map coordinates.
## The loader supplies the map frame so streamed halls and grid scenes agree.

static func place(bench: Node3D, part: Node3D, id: String, fallback: Transform3D) -> void:
	var removed: bool = str(bench._part_layout.get("part_" + id + "_removed", "false")).to_lower() in ["true", "1"]
	set_present(part, not removed)
	if removed: return
	var pose: Transform3D = fallback
	var text: String = str(bench._part_layout.get("part_" + id, ""))
	if not text.is_empty() and bench.has_meta("artifact_map_frame"):
		var fields := text.split(",")
		var valid: bool = fields.size() in [3, 5]
		for field in fields:
			valid = valid and field.is_valid_float() and is_finite(float(field))
		if valid:
			var x := float(fields[0]); var z := float(fields[1]); var yaw := float(fields[2])
			var height := float(fields[3]) if fields.size() == 5 else 0.0
			var size := float(fields[4]) if fields.size() == 5 else 1.0
			if size >= 0.01 and size <= 5.0:
				var frame: Transform3D = bench.get_parent().global_transform * bench.get_meta("artifact_map_frame")
				pose = frame * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)).scaled(Vector3.ONE * size), Vector3(x, height, z))
	part.top_level = true
	part.global_transform = pose
	# Parts remain owned by their source exhibit; include them in its visibility
	# envelope so approaching a moved instrument also wakes its controller.
	include_in_bounds(bench, part)
	var parent := part.get_parent() as Node3D
	if parent != null and parent != bench:
		include_in_bounds(parent, part)

## Keep shared seed references alive, but remove every visible and physical
## surface. Undo restores the original process/collision settings exactly.
static func set_present(part: Node3D, present: bool) -> void:
	if present == (not bool(part.get_meta("editor_removed", false))): return
	part.set_meta("editor_removed", not present)
	var nodes: Array[Node] = [part]
	nodes.append_array(part.find_children("*", "", true, false))
	for node in nodes:
		if not present:
			var state := {"process_mode": node.process_mode}
			if node is CollisionObject3D:
				state["collision_layer"] = node.collision_layer
				state["collision_mask"] = node.collision_mask
				state["input_ray_pickable"] = node.input_ray_pickable
				node.collision_layer = 0; node.collision_mask = 0
				node.input_ray_pickable = false
			if node is RigidBody3D:
				state["freeze"] = node.freeze
				node.freeze = true
			node.set_meta("editor_removed_state", state)
			node.process_mode = Node.PROCESS_MODE_DISABLED
		elif node.has_meta("editor_removed_state"):
			var state: Dictionary = node.get_meta("editor_removed_state")
			for key in state: node.set(key, state[key])
			node.remove_meta("editor_removed_state")
	if not present: part.set_meta("editor_previous_visible", part.visible)
	part.visible = bool(part.get_meta("editor_previous_visible", true)) if present else false

static func include_in_bounds(owner: Node3D, part: Node3D) -> void:
	var bounds: AABB = owner.get_meta("em_visibility_bounds", AABB(Vector3(-3, 0, -3), Vector3(6, 3, 6)))
	var relative: Transform3D = owner.global_transform.affine_inverse() * part.global_transform
	# Conservative envelope of the complete stand, board, labels and controls.
	owner.set_meta("em_visibility_bounds", bounds.merge(relative * AABB(Vector3(-2, 0, -1), Vector3(4, 3.5, 2))))
