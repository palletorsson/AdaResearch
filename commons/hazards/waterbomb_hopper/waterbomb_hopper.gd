extends CharacterBody3D
class_name WaterbombHopper
## Bouncing waterbomb tessellation enemy — origami-themed hazard.
## Builds a waterbomb base shape from triangular faces, animates bouncing
## with squash-and-stretch, and patrols a rectangular path.

signal enemy_destroyed(enemy: Node3D)

enum State { PATROL, DETECT, CHASE, STUNNED, DEAD }

@export_group("Geometry")
@export var base_size: float = 0.35
@export var fold_angle: float = 55.0
@export var radial_segments: int = 8

@export_group("Combat")
@export var max_health: float = 50.0
@export var patrol_speed: float = 1.8
@export var chase_speed: float = 3.2
@export var detection_radius: float = 7.0
@export var disengage_radius: float = 12.0
@export var contact_damage: float = 15.0
@export var contact_cooldown: float = 0.8

@export_group("Bounce")
@export var bounce_height: float = 0.6
@export var bounce_frequency: float = 3.5
@export var squash_amount: float = 0.3

@export_group("Patrol")
@export var patrol_width: float = 3.0
@export var patrol_depth: float = 2.0

@export_group("Appearance")
@export var body_color: Color = Color(0.85, 0.25, 0.15, 1.0)
@export var crease_color: Color = Color(1.0, 0.6, 0.1, 1.0)
@export var emission_color: Color = Color(1.0, 0.35, 0.08, 1.0)

# State
var _health: float = 0.0
var _state: State = State.PATROL
var _state_time: float = 0.0
var _bounce_phase: float = 0.0
var _breath_phase: float = 0.0
var _contact_timer: float = 0.0
var _player_node: Node3D = null
var _patrol_origin: Vector3 = Vector3.ZERO
var _patrol_index: int = 0
var _patrol_corners: Array[Vector3] = []

# Visual
var _mesh_root: Node3D = null
var _im: ImmediateMesh = null
var _mesh_instance: MeshInstance3D = null
var _body_material: StandardMaterial3D = null
var _crease_im: ImmediateMesh = null
var _crease_instance: MeshInstance3D = null
var _crease_material: StandardMaterial3D = null

# Geometry cache
var _base_verts: PackedVector3Array = []
var _base_tris: PackedInt32Array = []
var _crease_edges: Array[Vector2i] = []


func _ready() -> void:
	_health = max_health
	_patrol_origin = global_position
	_build_patrol_corners()
	_create_materials()
	_build_collision()
	_generate_waterbomb_geometry()
	_build_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("origami_enemy")


func _physics_process(delta: float) -> void:
	_state_time += delta
	_bounce_phase += delta * bounce_frequency * TAU
	_breath_phase += delta * 1.8
	_contact_timer = max(0.0, _contact_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	match _state:
		State.PATROL:
			_process_patrol(delta)
		State.DETECT:
			_process_detect(delta)
		State.CHASE:
			_process_chase(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.DEAD:
			_process_dead(delta)

	_update_bounce()
	_rebuild_mesh_data()

	if _state != State.DEAD:
		move_and_slide()
		_handle_contact_damage()


# ── State Processing ─────────────────────────────────────────────────────

func _process_patrol(delta: float) -> void:
	var target: Vector3 = _patrol_corners[_patrol_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	if dist < 0.3:
		_patrol_index = (_patrol_index + 1) % _patrol_corners.size()
		target = _patrol_corners[_patrol_index]
		to_target = target - global_position
		to_target.y = 0.0

	if to_target.length() > 0.01:
		var move_dir: Vector3 = to_target.normalized()
		velocity.x = move_dir.x * patrol_speed
		velocity.z = move_dir.z * patrol_speed
		_face_direction(move_dir, delta * 3.0)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0

	if _get_player_distance() <= detection_radius:
		_set_state(State.DETECT)


func _process_detect(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.2)

	if _state_time >= 0.4:
		_set_state(State.CHASE)


func _process_chase(delta: float) -> void:
	var dist: float = _get_player_distance()

	if dist > disengage_radius:
		_set_state(State.PATROL)
		return

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
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0


func _process_stunned(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.15)

	if _state_time >= 1.5:
		_set_state(State.PATROL)


func _process_dead(_delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, 0.1)

	if _state_time >= 3.0:
		queue_free()


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


# ── Bounce & Visual ──────────────────────────────────────────────────────

func _update_bounce() -> void:
	if not _mesh_root:
		return

	var bounce_t: float = abs(sin(_bounce_phase))
	var y_offset: float = bounce_t * bounce_height

	# Squash at bottom, stretch at top
	var squash_factor: float = 1.0 - squash_amount * (1.0 - bounce_t)
	var stretch_factor: float = 1.0 + squash_amount * 0.5 * (1.0 - bounce_t)

	_mesh_root.position.y = y_offset + base_size * 0.5
	_mesh_root.scale = Vector3(stretch_factor, squash_factor, stretch_factor)

	# Dead state: collapse
	if _state == State.DEAD:
		var fade: float = clamp(_state_time / 2.0, 0.0, 1.0)
		_mesh_root.scale *= (1.0 - fade * 0.7)
		_mesh_root.position.y *= (1.0 - fade)


# ── Geometry Generation ──────────────────────────────────────────────────

func _generate_waterbomb_geometry() -> void:
	_base_verts.clear()
	_base_tris.clear()
	_crease_edges.clear()

	# Waterbomb base: top apex, bottom ring of vertices, center bottom
	# Classic waterbomb has 4 triangular flaps meeting at an apex
	# We generalize to radial_segments flaps for a fuller shape

	var n: int = max(4, radial_segments)
	var half_angle: float = deg_to_rad(fold_angle)
	var apex_height: float = base_size * cos(half_angle * 0.5)
	var ring_radius: float = base_size * sin(half_angle * 0.5)

	# Vertex 0: top apex
	_base_verts.append(Vector3(0.0, apex_height, 0.0))

	# Vertex 1: bottom center
	_base_verts.append(Vector3(0.0, 0.0, 0.0))

	# Vertices 2..n+1: bottom ring
	var angle_step: float = TAU / float(n)
	for i in range(n):
		var angle: float = angle_step * float(i)
		_base_verts.append(Vector3(
			cos(angle) * ring_radius,
			0.0,
			sin(angle) * ring_radius
		))

	# Upper triangles: apex to ring edges
	for i in range(n):
		var next_i: int = (i + 1) % n
		_base_tris.append(0)             # apex
		_base_tris.append(i + 2)         # ring vertex
		_base_tris.append(next_i + 2)    # next ring vertex

	# Lower triangles: bottom center to ring edges (reversed winding)
	for i in range(n):
		var next_i: int = (i + 1) % n
		_base_tris.append(1)             # bottom center
		_base_tris.append(next_i + 2)    # next ring vertex
		_base_tris.append(i + 2)         # ring vertex

	# Crease edges: apex to ring, ring to center, ring segments
	for i in range(n):
		_crease_edges.append(Vector2i(0, i + 2))     # apex to ring
		_crease_edges.append(Vector2i(1, i + 2))     # center to ring
		var next_i: int = (i + 1) % n
		_crease_edges.append(Vector2i(i + 2, next_i + 2))  # ring edge


func _create_materials() -> void:
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = body_color
	_body_material.metallic = 0.15
	_body_material.roughness = 0.55
	_body_material.emission_enabled = true
	_body_material.emission = emission_color
	_body_material.emission_energy_multiplier = 0.8
	_body_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_color
	_crease_material.metallic = 0.3
	_crease_material.roughness = 0.4
	_crease_material.emission_enabled = true
	_crease_material.emission = crease_color
	_crease_material.emission_energy_multiplier = 0.5


func _build_mesh() -> void:
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)

	# Body mesh
	_im = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "BodyMesh"
	_mesh_instance.mesh = _im
	_mesh_instance.material_override = _body_material
	_mesh_root.add_child(_mesh_instance)

	# Crease lines mesh
	_crease_im = ImmediateMesh.new()
	_crease_instance = MeshInstance3D.new()
	_crease_instance.name = "CreaseMesh"
	_crease_instance.mesh = _crease_im
	_crease_instance.material_override = _crease_material
	_mesh_root.add_child(_crease_instance)

	_rebuild_mesh_data()


func _rebuild_mesh_data() -> void:
	if not _im or not _crease_im:
		return

	# Breathing: oscillate fold angle slightly
	var breath_offset: float = sin(_breath_phase) * 8.0
	var current_fold: float = fold_angle + breath_offset

	# Recalculate vertices with current fold
	var n: int = max(4, radial_segments)
	var half_angle: float = deg_to_rad(current_fold)
	var apex_height: float = base_size * cos(half_angle * 0.5)
	var ring_radius: float = base_size * sin(half_angle * 0.5)

	var verts: PackedVector3Array = []
	verts.append(Vector3(0.0, apex_height, 0.0))
	verts.append(Vector3(0.0, 0.0, 0.0))

	var angle_step: float = TAU / float(n)
	for i in range(n):
		var angle: float = angle_step * float(i)
		verts.append(Vector3(
			cos(angle) * ring_radius,
			0.0,
			sin(angle) * ring_radius
		))

	# Rebuild body triangles
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for tri_idx in range(_base_tris.size() / 3):
		var i0: int = _base_tris[tri_idx * 3]
		var i1: int = _base_tris[tri_idx * 3 + 1]
		var i2: int = _base_tris[tri_idx * 3 + 2]

		var v0: Vector3 = verts[i0]
		var v1: Vector3 = verts[i1]
		var v2: Vector3 = verts[i2]

		var normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()

		_im.surface_set_normal(normal)
		_im.surface_add_vertex(v0)
		_im.surface_set_normal(normal)
		_im.surface_add_vertex(v1)
		_im.surface_set_normal(normal)
		_im.surface_add_vertex(v2)

	_im.surface_end()

	# Rebuild crease lines
	_crease_im.clear_surfaces()
	_crease_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for edge in _crease_edges:
		if edge.x < verts.size() and edge.y < verts.size():
			var v0: Vector3 = verts[edge.x]
			var v1: Vector3 = verts[edge.y]
			_crease_im.surface_set_normal(Vector3.UP)
			_crease_im.surface_add_vertex(v0)
			_crease_im.surface_set_normal(Vector3.UP)
			_crease_im.surface_add_vertex(v1)

	_crease_im.surface_end()


# ── Collision & Damage ───────────────────────────────────────────────────

func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = base_size * 0.7
	shape.shape = sphere
	add_child(shape)


func _handle_contact_damage() -> void:
	if _contact_timer > 0.0 or contact_damage <= 0.0:
		return

	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if _try_damage(collider):
			_contact_timer = contact_cooldown
			break


func _try_damage(target: Object) -> bool:
	if target == null:
		return false

	for method in ["take_damage", "apply_damage", "damage"]:
		if target.has_method(method):
			target.call(method, contact_damage)
			return true

	return false


func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return

	_health -= max(0.0, amount)

	if _health <= 0.0:
		_set_state(State.DEAD)
		enemy_destroyed.emit(self)
	else:
		_set_state(State.STUNNED)
		# Hit flash
		if _body_material:
			var tween: Tween = create_tween()
			tween.tween_property(_body_material, "emission_energy_multiplier", 3.0, 0.05)
			tween.tween_property(_body_material, "emission_energy_multiplier", 0.8, 0.15)


# ── Patrol ───────────────────────────────────────────────────────────────

func _build_patrol_corners() -> void:
	var hw: float = patrol_width * 0.5
	var hd: float = patrol_depth * 0.5
	_patrol_corners = [
		_patrol_origin + Vector3(-hw, 0.0, -hd),
		_patrol_origin + Vector3(hw, 0.0, -hd),
		_patrol_origin + Vector3(hw, 0.0, hd),
		_patrol_origin + Vector3(-hw, 0.0, hd),
	]


# ── Utility ──────────────────────────────────────────────────────────────

func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		_player_node = null
		return

	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return

	_player_node = null


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


func _face_direction(dir: Vector3, blend: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, blend)


func configure(config: Dictionary) -> void:
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		patrol_speed = float(config["speed"])
	if config.has("chase_speed"):
		chase_speed = float(config["chase_speed"])
	if config.has("damage"):
		contact_damage = float(config["damage"])
	if config.has("bounce_height"):
		bounce_height = float(config["bounce_height"])
	if config.has("patrol_width"):
		patrol_width = float(config["patrol_width"])
		_build_patrol_corners()
	if config.has("patrol_depth"):
		patrol_depth = float(config["patrol_depth"])
		_build_patrol_corners()
	if config.has("segments"):
		radial_segments = int(config["segments"])
		_generate_waterbomb_geometry()


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
