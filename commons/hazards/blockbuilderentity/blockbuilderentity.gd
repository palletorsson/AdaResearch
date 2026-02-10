# Antimatter grey goo entity that consumes geometry and cages the player.
extends CharacterBody3D
class_name BlockBuilderEntity

@export var detection_range: float = 20.0
@export var consumption_radius: float = 6.0
@export var movement_speed: float = 3.5
@export var capture_distance: float = 6.5
@export var hive_layers: int = 2
@export var hive_build_interval: float = 0.65
@export var consumption_rate: float = 160.0
@export var min_vertices_to_capture: float = 6.0
@export var vertex_decay_rate: float = 4.5
@export var hive_block_spacing: float = 1.5
@export var block_lifetime: float = 45.0

@export var block_size: Vector3 = Vector3(1.2, 1.2, 1.2)
@export var block_material_color: Color = Color(0.66, 0.68, 0.72, 1.0)
@export var entity_base_color: Color = Color(0.15, 0.18, 0.22, 1.0)
@export var entity_accent_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var thought_label_height: float = 1.6
@export var thought_update_interval: float = 0.35
@export var geometry_scan_interval: float = 1.4
@export var geometry_max_candidates: int = 160

const OCTAHEDRON_SCENE: PackedScene = preload("res://commons/primitives/octahedron/octahedron.tscn")
const OCTAHEDRON_BASE_VERTICES := [
	Vector3(0, 0.5, 0),
	Vector3(0, -0.5, 0),
	Vector3(0.5, 0, 0),
	Vector3(-0.5, 0, 0),
	Vector3(0, 0, 0.5),
	Vector3(0, 0, -0.5)
]

func _get_brick_spacing() -> float:
	return max(block_size.x, block_size.z, hive_block_spacing)

var player_node: Node3D
var navigation_agent: NavigationAgent3D
var detection_area: Area3D
var consumption_area: Area3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var thought_label: Label3D

var vertex_budget: float = 0.0
var block_vertex_cost: float = 6.0
var build_timer: float = 0.0
var state_timer: float = 0.0
var thought_update_timer: float = 0.0
var last_thought_text: String = ""
var geometry_scan_timer: float = 0.0
var geometry_candidates: Array = []

var built_blocks: Array = []
var consumption_targets: Dictionary = {}
var base_mesh_scale: Vector3 = Vector3.ONE

var hive_offsets: Array = []
var hive_index: int = 0

func _color_with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

func _collect_mesh_instances(node: Node, result: Array, max_count: int) -> void:
	if result.size() >= max_count:
		return
	if node is MeshInstance3D:
		result.append(node)
		if result.size() >= max_count:
			return
	for child in node.get_children():
		_collect_mesh_instances(child, result, max_count)
		if result.size() >= max_count:
			return

func _refresh_geometry_candidates():
	geometry_candidates.clear()
	var tree = get_tree()
	var gathered: Array = []
	if tree:
		for group_name in ["consumable_geometry", "geometry", "static_mesh"]:
			if tree.has_group(group_name):
				for node in tree.get_nodes_in_group(group_name):
					if node is MeshInstance3D:
						gathered.append(node)
	if gathered.is_empty():
		var root = tree.current_scene if tree else null
		if root:
			_collect_mesh_instances(root, gathered, geometry_max_candidates * 2)
	for node in gathered:
		if geometry_candidates.size() >= geometry_max_candidates:
			break
		geometry_candidates.append(node)

func _scan_for_consumable_geometry():
	if geometry_candidates.is_empty():
		_refresh_geometry_candidates()
	if geometry_candidates.is_empty():
		return
	var to_remove: Array = []
	var max_distance = max(consumption_radius * 1.4, detection_range)
	for candidate in geometry_candidates:
		if not is_instance_valid(candidate):
			to_remove.append(candidate)
			continue
		if candidate == mesh_instance:
			continue
		if candidate.is_in_group("grey_goo_block"):
			continue
		if consumption_targets.has(candidate):
			continue
		var host = candidate.get_parent()
		if host and host == self:
			continue
		var distance = global_position.distance_to(candidate.global_position)
		if distance > max_distance:
			continue
		_register_consumption_target(candidate)
	if not to_remove.is_empty():
		for candidate in to_remove:
			geometry_candidates.erase(candidate)
func _resolve_node3d(node: Node) -> Node3D:
	var current = node
	while current:
		if current is Node3D and current != self:
			return current
		current = current.get_parent()
	return null

enum GooState {
	SCAVENGING,
	PURSUING,
	BUILDING
}
var current_state: GooState = GooState.SCAVENGING

signal block_built(position: Vector3, remaining_vertex_budget: float)
signal player_path_blocked(block_count: int)
signal entity_destroyed()

func _ready():
	add_to_group("block_builder")
	_create_entity_mesh()
	_setup_collision()
	_setup_detection_area()
	_setup_consumption_area()
	_setup_navigation()
	_find_player()
	_refresh_geometry_candidates()
	_scan_for_consumable_geometry()
	base_mesh_scale = mesh_instance.scale
	hive_offsets = _generate_octa_brick_offsets(hive_layers)
	block_vertex_cost = _estimate_block_vertex_cost()
	_update_thought_label(true)
	print("BlockBuilderEntity: Grey goo initialized; block cost =", block_vertex_cost)

func _create_entity_mesh():
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.0
	sphere.radial_segments = 24
	sphere.rings = 16
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = _color_with_alpha(entity_base_color, 0.85)
	material.metallic = 0.25
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = entity_accent_color * 0.25
	material.emission_energy = 1.75
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	add_child(mesh_instance)

	for i in range(3):
		var tendril = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		capsule.radius = 0.15
		capsule.height = 1.1
		tendril.mesh = capsule
		var tendril_material = material.duplicate()
		tendril_material.emission = entity_accent_color * 0.4
		tendril_material.emission_energy = 2.0
		tendril_material.albedo_color = _color_with_alpha(entity_base_color, 0.6)
		tendril.material_override = tendril_material
		var angle = TAU * float(i) / 3.0
		tendril.position = Vector3(cos(angle) * 0.45, 0.0, sin(angle) * 0.45)
		tendril.rotation = Vector3(0.0, angle, 0.0)
		mesh_instance.add_child(tendril)

	_create_thought_label()

func _create_thought_label():
	thought_label = Label3D.new()
	thought_label.name = "ThoughtLabel"
	thought_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	thought_label.font_size = 22
	thought_label.outline_size = 3
	thought_label.no_depth_test = true
	thought_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thought_label.position = Vector3(0.0, thought_label_height, 0.0)
	thought_label.modulate = Color(1.0, 0.92, 0.45, 1.0)
	thought_label.text = "..."
	add_child(thought_label)

func _update_thought_label(force: bool = false):
	if not thought_label:
		return
	var message = _compose_thought_text()
	if not force and message == last_thought_text:
		return
	thought_label.text = message
	last_thought_text = message

func _compose_thought_text() -> String:
	var stored = int(vertex_budget)
	var required = max(min_vertices_to_capture, block_vertex_cost)
	match current_state:
		GooState.SCAVENGING:
			if consumption_targets.is_empty():
				if vertex_budget < required:
					var deficit = int(max(required - vertex_budget, 0.0))
					return "Need " + str(deficit) + " verts to hunt."
				return "Cache primed (" + str(stored) + "/" + str(int(required)) + "). Seeking player."
			var target_desc = _describe_current_target()
			return "Dissolving " + target_desc + ". Cache: " + str(stored) + " verts."
		GooState.PURSUING:
			var target_name := "target"
			if player_node:
				target_name = str(player_node.name)
			return "Hunting " + target_name + ". Cache: " + str(stored) + " verts."
		GooState.BUILDING:
			var remaining_blocks = max(hive_offsets.size() - hive_index, 0)
			return "Setting octa bricks (" + str(remaining_blocks) + " spots left). Cache: " + str(stored) + " verts."
	return "..."

func _describe_current_target() -> String:
	for mesh_node in consumption_targets.keys():
		if is_instance_valid(mesh_node):
			var data: Dictionary = consumption_targets[mesh_node]
			var remaining = int(data.get("remaining", 0.0))
			return mesh_node.name + " (" + str(remaining) + " verts)"
	return "geometry"

func _setup_collision():
	collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.65
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

func _setup_detection_area():
	detection_area = Area3D.new()
	detection_area.monitoring = true
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	var detection_shape = CollisionShape3D.new()
	var detection_sphere = SphereShape3D.new()
	detection_sphere.radius = detection_range
	detection_shape.shape = detection_sphere
	detection_area.add_child(detection_shape)
	add_child(detection_area)

func _setup_consumption_area():
	consumption_area = Area3D.new()
	consumption_area.monitoring = true
	consumption_area.body_entered.connect(_on_consumption_area_body_entered)
	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = consumption_radius
	shape.shape = sphere_shape
	consumption_area.add_child(shape)
	add_child(consumption_area)

func _setup_navigation():
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 0.75
	add_child(navigation_agent)

func _find_player():
	player_node = null
	for candidate in get_tree().get_nodes_in_group("player"):
		var resolved = _resolve_node3d(candidate)
		if resolved:
			player_node = resolved
			break
	if not player_node and get_tree().current_scene:
		var named_candidate = get_tree().current_scene.find_child("*Player*", true, false)
		if named_candidate:
			player_node = _resolve_node3d(named_candidate)
	if not player_node and get_tree().current_scene:
		_search_for_player(get_tree().current_scene)
	if player_node:
		print("BlockBuilderEntity: Player located - ", player_node.name)

func _search_for_player(node: Node):
	if not node or player_node:
		return
	if node.is_in_group("player") or node.name.to_lower().find("player") != -1:
		var resolved = _resolve_node3d(node)
		if resolved:
			player_node = resolved
			return
	for child in node.get_children():
		_search_for_player(child)
		if player_node:
			return

func _physics_process(delta):
	build_timer += delta
	state_timer += delta

	if not player_node:
		_find_player()

	_update_consumption(delta)
	vertex_budget = max(0.0, vertex_budget - vertex_decay_rate * delta)
	_update_state(delta)
	_update_movement(delta)
	_cleanup_old_blocks()
	_update_entity_appearance()

	if thought_label:
		if thought_update_interval <= 0.0:
			_update_thought_label()
		else:
			thought_update_timer += delta
			if thought_update_timer >= thought_update_interval:
				thought_update_timer = 0.0
				_update_thought_label()

	geometry_scan_timer += delta
	if geometry_scan_timer >= geometry_scan_interval:
		geometry_scan_timer = 0.0
		_scan_for_consumable_geometry()
func _update_state(_delta):
	match current_state:
		GooState.SCAVENGING:
			_update_scavenging_state()
		GooState.PURSUING:
			_update_pursuing_state()
		GooState.BUILDING:
			_update_building_state()

func _update_scavenging_state():
	if not player_node:
		return
	var distance = global_position.distance_to(player_node.global_position)
	var required = max(min_vertices_to_capture, block_vertex_cost)
	if vertex_budget >= required and distance <= detection_range:
		_change_state(GooState.PURSUING)

func _update_pursuing_state():
	if not player_node:
		_change_state(GooState.SCAVENGING)
		return
	if vertex_budget < block_vertex_cost and state_timer > 5.0:
		_change_state(GooState.SCAVENGING)
		return
	var distance = global_position.distance_to(player_node.global_position)
	if distance <= capture_distance and vertex_budget >= block_vertex_cost:
		hive_index = 0
		build_timer = hive_build_interval
		_change_state(GooState.BUILDING)

func _update_building_state():
	if not player_node:
		_change_state(GooState.SCAVENGING)
		return
	var distance = global_position.distance_to(player_node.global_position)
	if distance > capture_distance * 2.0:
		_change_state(GooState.PURSUING)
		return
	_attempt_hive_construction()

func _update_movement(_delta):
	if not navigation_agent:
		return
	var target = global_position
	if current_state == GooState.SCAVENGING and not consumption_targets.is_empty():
		for mesh_node in consumption_targets.keys():
			if is_instance_valid(mesh_node):
				target = mesh_node.global_position
				break
	elif player_node:
		target = player_node.global_position
	navigation_agent.target_position = target
	var direction = Vector3.ZERO
	if navigation_agent.is_navigation_finished():
		direction = (target - global_position).normalized()
	else:
		var next_position = navigation_agent.get_next_path_position()
		direction = (next_position - global_position).normalized()
	velocity = direction * movement_speed * _state_speed_multiplier()
	move_and_slide()
	if velocity.length() > 0.1:
		look_at(global_position + velocity.normalized(), Vector3.UP)

func _state_speed_multiplier() -> float:
	match current_state:
		GooState.SCAVENGING:
			return 0.75
		GooState.PURSUING:
			return 1.0
		GooState.BUILDING:
			return 0.45
	return 1.0

func _attempt_hive_construction():
	if hive_offsets.is_empty():
		return
	if vertex_budget < block_vertex_cost:
		return
	if build_timer < hive_build_interval:
		return
	if not player_node:
		return
	var attempts = hive_offsets.size()
	while attempts > 0 and hive_index < hive_offsets.size():
		attempts -= 1
		var offset: Vector3 = hive_offsets[hive_index]
		hive_index += 1
		var target_position = _align_position(player_node.global_position + offset)
		if not _can_place_block_at(target_position):
			continue
		if _create_block(target_position):
			build_timer = 0.0
			break
	if hive_index >= hive_offsets.size():
		if vertex_budget >= min_vertices_to_capture * 0.5:
			hive_index = 0
		else:
			_change_state(GooState.PURSUING)

func _align_position(position: Vector3) -> Vector3:
	return position

func _can_place_block_at(position: Vector3) -> bool:
	if global_position.distance_to(position) > capture_distance * 1.8:
		return false
	if player_node and player_node.global_position.distance_to(position) < block_size.length():
		return false
	for block_data in built_blocks:
		var body: RigidBody3D = block_data.get("rigid_body")
		if is_instance_valid(body) and body.global_position.distance_to(position) < _get_brick_spacing() * 0.6:
			return false
	return true

func _create_block(position: Vector3) -> bool:
	if vertex_budget < block_vertex_cost:
		return false
	var block_data = _create_block_data()
	var block_body: RigidBody3D = block_data.get("rigid_body")
	if not block_body:
		return false
	block_body.global_position = position
	add_child(block_body)
	block_body.add_to_group("grey_goo_block")
	vertex_budget -= block_vertex_cost
	block_data["creation_time"] = Time.get_ticks_msec()
	built_blocks.append(block_data)
	emit_signal("block_built", position, vertex_budget)
	if built_blocks.size() % 6 == 0:
		emit_signal("player_path_blocked", built_blocks.size())
	_update_thought_label(true)
	return true

func _create_block_data() -> Dictionary:
	var block_body = RigidBody3D.new()
	block_body.freeze = true
	block_body.name = "GooOcta"

	var octa_node = OCTAHEDRON_SCENE.instantiate()
	if octa_node:
		var camera = octa_node.get_node_or_null('Camera3D')
		if camera:
			octa_node.remove_child(camera)
			camera.queue_free()
		if octa_node.has_method('set_base_color'):
			octa_node.set_base_color(block_material_color)
		octa_node.scale = block_size
		block_body.add_child(octa_node)
		octa_node.add_to_group("grey_goo_block")
		for child in octa_node.get_children():
			if child is MeshInstance3D:
				child.add_to_group("grey_goo_block")

	var collision = CollisionShape3D.new()
	var shape = ConvexPolygonShape3D.new()
	var scaled_points = PackedVector3Array()
	for vertex in OCTAHEDRON_BASE_VERTICES:
		var scaled = Vector3(vertex.x * block_size.x, vertex.y * block_size.y, vertex.z * block_size.z)
		scaled_points.append(scaled)
	shape.points = scaled_points
	collision.shape = shape
	block_body.add_child(collision)

	return {
		"rigid_body": block_body,
		"creation_time": Time.get_ticks_msec(),
		"vertex_cost": block_vertex_cost,
		"octa_node": octa_node
	}

func _generate_octa_brick_offsets(layers: int) -> Array:
	var offsets: Array = []
	if layers < 1:
		return offsets
	var spacing: float = _get_brick_spacing()
	var half_shift: float = spacing * 0.5
	var vertical_step: float = max(block_size.y * 0.95, spacing * 0.75)
	var directions := [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1),
		Vector3(1, 0, 1), Vector3(-1, 0, 1),
		Vector3(1, 0, -1), Vector3(-1, 0, -1)
	]
	var level_offsets: Array[float] = [0.0]
	for l in range(1, layers + 1):
		level_offsets.append(float(l))
		level_offsets.append(-float(l))
		var half := float(l) - 0.5
		if half > 0.0:
			level_offsets.append(half)
			level_offsets.append(-half)
	var unique: Dictionary = {}
	for level in level_offsets:
		var base_layer: int = int(floor(abs(level)))
		var y_offset: float = level * vertical_step
		var has_half: bool = abs(level - float(base_layer)) > 0.01
		var shift: Vector3 = Vector3.ZERO
		if has_half:
			shift = Vector3(half_shift, 0.0, half_shift)
		else:
			if base_layer % 2 == 0:
				shift = Vector3.ZERO
			else:
				shift = Vector3(half_shift, 0.0, 0.0)
		var max_radius: int = max(1, layers - base_layer + 1)
		for radius in range(1, max_radius + 1):
			for dir in directions:
				var lateral_offset: Vector3 = Vector3(dir.x * float(radius) * spacing, 0.0, dir.z * float(radius) * spacing)
				var offset: Vector3 = lateral_offset + shift + Vector3(0.0, y_offset, 0.0)
				var key: String = "%0.3f:%0.3f:%0.3f" % [offset.x, offset.y, offset.z]
				if unique.has(key):
					continue
				unique[key] = true
				offsets.append(offset)
		if abs(level) > 0.01:
			var column_offset: Vector3 = shift + Vector3(0.0, y_offset, 0.0)
			var col_key: String = "%0.3f:%0.3f:%0.3f" % [column_offset.x, column_offset.y, column_offset.z]
			if not unique.has(col_key):
				unique[col_key] = true
				offsets.append(column_offset)
	offsets.sort_custom(Callable(self, "_sort_offsets_by_distance"))
	return offsets

func _sort_offsets_by_distance(a: Vector3, b: Vector3) -> bool:
	var da := a.length()
	var db := b.length()
	if is_equal_approx(da, db):
		return abs(a.y) < abs(b.y)
	return da < db

func _update_consumption(delta):
	if consumption_targets.is_empty():
		return
	var to_remove: Array = []
	var label_refresh_needed = false
	for mesh_node in consumption_targets.keys():
		var data: Dictionary = consumption_targets[mesh_node]
		if not is_instance_valid(mesh_node):
			to_remove.append(mesh_node)
			continue
		var remaining: float = data.get("remaining", 0.0)
		if remaining <= 0.0:
			to_remove.append(mesh_node)
			continue
		var consume_amount = min(consumption_rate * delta, remaining)
		if consume_amount > 0.0:
			label_refresh_needed = true
		remaining -= consume_amount
		vertex_budget += consume_amount
		data["remaining"] = remaining
		consumption_targets[mesh_node] = data
		var total: float = max(data.get("total", 1.0), 0.001)
		var ratio = 1.0 - (remaining / total)
		var original_scale: Vector3 = data.get("original_scale", Vector3.ONE)
		var shrink = clamp(1.0 - ratio, 0.05, 1.0)
		mesh_node.scale = original_scale * shrink
		if remaining <= 0.0:
			_finalize_consumption(mesh_node, data)
			to_remove.append(mesh_node)
			label_refresh_needed = true
	for mesh_node in to_remove:
		consumption_targets.erase(mesh_node)
		label_refresh_needed = true
	if label_refresh_needed:
		_update_thought_label(true)

func _register_consumption_target(mesh_node: MeshInstance3D):
	if consumption_targets.has(mesh_node):
		return
	if mesh_node == player_node or mesh_node == mesh_instance:
		return
	if mesh_node.is_in_group("grey_goo_block"):
		return
	if geometry_candidates.has(mesh_node) == false and geometry_candidates.size() < geometry_max_candidates:
		geometry_candidates.append(mesh_node)
	var vertex_count = _estimate_mesh_vertex_count(mesh_node.mesh)
	if vertex_count <= 0:
		vertex_count = int(mesh_node.get_aabb().size.length() * 12.0)
		vertex_count = max(vertex_count, 24)
	consumption_targets[mesh_node] = {
		"remaining": float(vertex_count),
		"total": float(vertex_count),
		"original_scale": mesh_node.scale,
		"host": mesh_node.get_parent()
	}
	_update_thought_label(true)

func _resolve_mesh_instance(body: Node) -> MeshInstance3D:
	if body is MeshInstance3D:
		return body
	if body is Node:
		for child in body.get_children():
			var mesh_node = _resolve_mesh_instance(child)
			if mesh_node:
				return mesh_node
	return null

func _finalize_consumption(mesh_node: MeshInstance3D, data: Dictionary):
	var host: Node = data.get("host")
	if host and is_instance_valid(host) and host != self and (not host.is_in_group("player")):
		host.queue_free()
	elif is_instance_valid(mesh_node):
		mesh_node.queue_free()
	if geometry_candidates.has(mesh_node):
		geometry_candidates.erase(mesh_node)

func _estimate_mesh_vertex_count(mesh: Mesh) -> int:
	if not mesh:
		return 0
	var total = 0
	for surface_index in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface_index)
		if arrays.size() > Mesh.ARRAY_VERTEX:
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += vertices.size()
	if total == 0 and mesh.has_method("get_faces"):
		var faces = mesh.call("get_faces")
		if faces is PackedVector3Array:
			total = faces.size()
	return total

func _estimate_block_vertex_cost() -> float:
	return 6.0

func _cleanup_old_blocks():
	if built_blocks.is_empty():
		return
	var now = Time.get_ticks_msec()
	var to_remove: Array = []
	for i in range(built_blocks.size()):
		var block_data: Dictionary = built_blocks[i]
		var body: RigidBody3D = block_data.get("rigid_body")
		if not is_instance_valid(body):
			to_remove.append(i)
			continue
		if block_lifetime <= 0.0:
			continue
		var creation_time: int = block_data.get("creation_time", now)
		if now - creation_time >= int(block_lifetime * 1000.0):
			vertex_budget += block_data.get("vertex_cost", block_vertex_cost) * 0.35
			body.queue_free()
			to_remove.append(i)
	for n in range(to_remove.size()):
		var idx = to_remove[to_remove.size() - 1 - n]
		built_blocks.remove_at(idx)

func _update_entity_appearance():
	if not mesh_instance:
		return
	var scale_factor = clamp(1.0 + vertex_budget / 400.0, 1.0, 3.5)
	mesh_instance.scale = base_mesh_scale * scale_factor
	var material: StandardMaterial3D = mesh_instance.material_override
	if material:
		material.emission = entity_accent_color * clamp(0.2 + vertex_budget / 600.0, 0.2, 3.5)
		material.emission_energy = clamp(0.6 + vertex_budget / 220.0, 0.6, 6.0)

func _on_detection_area_entered(body):
	if body == self:
		return
	var candidate = _resolve_node3d(body)
	if candidate and (candidate == player_node or candidate.is_in_group("player") or body.is_in_group("player") or candidate.name.to_lower().find("player") != -1):
		player_node = candidate
		if current_state == GooState.SCAVENGING and vertex_budget >= min_vertices_to_capture:
			_change_state(GooState.PURSUING)

func _on_detection_area_exited(_body):
	pass

func _on_consumption_area_body_entered(body):
	if body == self:
		return
	var candidate = _resolve_node3d(body)
	if candidate and candidate == player_node:
		return
	if body.is_in_group("grey_goo_block"):
		return
	var mesh_node = _resolve_mesh_instance(body)
	if mesh_node and mesh_node != mesh_instance and not mesh_node.is_in_group("grey_goo_block"):
		_register_consumption_target(mesh_node)

func remove_block(block_rigid_body: RigidBody3D):
	for i in range(built_blocks.size()):
		var block_data: Dictionary = built_blocks[i]
		if block_data.get("rigid_body") == block_rigid_body:
			vertex_budget += block_data.get("vertex_cost", block_vertex_cost) * 0.5
			built_blocks.remove_at(i)
			if is_instance_valid(block_rigid_body):
				block_rigid_body.queue_free()
			_update_thought_label(true)
			return

func set_aggressiveness(level: float):
	level = clamp(level, 0.0, 1.0)
	movement_speed = 2.8 + level * 3.2
	consumption_rate = 110.0 + level * 240.0
	hive_build_interval = clamp(0.85 - level * 0.5, 0.25, 0.85)

func destroy_entity():
	for block_data in built_blocks:
		var body: RigidBody3D = block_data.get("rigid_body")
		if is_instance_valid(body):
			body.queue_free()
	emit_signal("entity_destroyed")
	queue_free()

func get_ai_state() -> String:
	match current_state:
		GooState.SCAVENGING:
			return "SCAVENGING"
		GooState.PURSUING:
			return "PURSUING"
		GooState.BUILDING:
			return "BUILDING"
	return "UNKNOWN"

func get_block_count() -> int:
	return built_blocks.size()

func _change_state(new_state: GooState):
	if current_state == new_state:
		state_timer = 0.0
		return
	current_state = new_state
	state_timer = 0.0
	print("BlockBuilderEntity: State -> ", new_state)
	_update_thought_label(true)
