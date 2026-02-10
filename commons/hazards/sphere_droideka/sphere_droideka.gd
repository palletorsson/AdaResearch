extends CharacterBody3D
class_name SphereDroideka
## Armadillidiidae-style spherical droideka.
## Rolls as a compact ball of overlapping shell plates.
## Unfolds to tripod stance with shield dome and twin blasters.

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State { BALL, UNROLL, DEPLOY, AIM, FIRE, RETRACT, ROLL_UP, DEAD }

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Geometry")
@export var shell_segments: int = 8          # Latitudinal bands
@export var shell_slices: int = 12           # Longitudinal divisions
@export var ball_radius: float = 0.35
@export var deployed_height: float = 1.2
@export var leg_count: int = 3

@export_group("Combat")
@export var max_health: float = 120.0
@export var roll_speed: float = 4.5
@export var detection_radius: float = 12.0
@export var attack_radius: float = 10.0
@export var fire_speed: float = 18.0
@export var fire_damage: float = 14.0
@export var shots_per_burst: int = 6
@export var fire_interval: float = 0.15
@export var shield_strength: float = 50.0

@export_group("Timing")
@export var unroll_duration: float = 4.0
@export var deploy_duration: float = 3.0
@export var retract_duration: float = 2.5
@export var rollup_duration: float = 3.0

@export_group("Appearance")
@export var shell_color: Color = Color(0.25, 0.28, 0.32, 1.0)
@export var inner_color: Color = Color(0.15, 0.15, 0.18, 1.0)
@export var accent_color: Color = Color(0.8, 0.3, 0.1, 1.0)
@export var shield_color: Color = Color(0.3, 0.5, 1.0, 0.3)

# State
var _health: float = 0.0
var _shield_hp: float = 0.0
var _state: State = State.BALL
var _state_time: float = 0.0
var _fold_amount: float = 1.0  # 1 = ball, 0 = deployed
var _roll_angle: float = 0.0
var _shot_count: int = 0
var _shot_timer: float = 0.0
var _player_node: Node3D = null

# Geometry nodes
var _shell_root: Node3D = null
var _shell_bands: Array[Node3D] = []      # Latitudinal bands of plates
var _shell_plates: Array[Array] = []       # [band][slice] = MeshInstance3D
var _leg_roots: Array[Node3D] = []
var _leg_upper: Array[MeshInstance3D] = []
var _leg_lower: Array[MeshInstance3D] = []
var _leg_feet: Array[MeshInstance3D] = []
var _core: Node3D = null
var _turret: Node3D = null
var _muzzle_left: Marker3D = null
var _muzzle_right: Marker3D = null
var _shield_mesh: MeshInstance3D = null

# Materials
var _shell_material: StandardMaterial3D
var _inner_material: StandardMaterial3D
var _accent_material: StandardMaterial3D
var _shield_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_shield_hp = 0.0
	_create_materials()
	_build_shell()
	_build_legs()
	_build_core()
	_build_shield()
	_build_collision()
	_find_player()
	add_to_group("enemy")
	add_to_group("sphere_droideka")
	print("SphereDroideka: READY at %s" % global_position)


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.BALL:
			_process_ball(delta)
		State.UNROLL:
			_process_unroll(delta)
		State.DEPLOY:
			_process_deploy(delta)
		State.AIM:
			_process_aim(delta)
		State.FIRE:
			_process_fire(delta)
		State.RETRACT:
			_process_retract(delta)
		State.ROLL_UP:
			_process_rollup(delta)
		State.DEAD:
			_process_dead(delta)
	
	_apply_fold_pose()
	
	if _state != State.DEAD:
		move_and_slide()


## State Processors

func _process_ball(delta: float) -> void:
	_fold_amount = move_toward(_fold_amount, 1.0, delta * 3.0)
	
	var dist: float = _get_player_distance()
	
	if dist <= detection_radius:
		# Roll toward player
		if dist > attack_radius * 0.8:
			var to_player: Vector3 = _get_player_direction()
			velocity = to_player * roll_speed
			_roll_angle += delta * roll_speed * 4.0
			_face_velocity(delta)
		else:
			# Close enough, start unrolling
			velocity = velocity.move_toward(Vector3.ZERO, delta * 10.0)
			_set_state(State.UNROLL)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, delta * 5.0)
		_roll_angle += delta * 0.5  # Idle wobble


func _process_unroll(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / unroll_duration, 0.0, 1.0)
	_fold_amount = lerp(1.0, 0.5, ease(t, 0.3))
	
	if t >= 1.0:
		_set_state(State.DEPLOY)


func _process_deploy(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / deploy_duration, 0.0, 1.0)
	_fold_amount = lerp(0.5, 0.0, ease(t, 0.4))
	
	# Activate shield
	_shield_hp = lerp(0.0, shield_strength, t)
	if _shield_mesh:
		_shield_mesh.visible = t > 0.3
	
	if t >= 1.0:
		_set_state(State.AIM)


func _process_aim(delta: float) -> void:
	velocity = Vector3.ZERO
	_fold_amount = 0.0
	
	_aim_at_player(delta)
	
	var dist: float = _get_player_distance()
	
	# Player fled? Retract and chase
	if dist > detection_radius * 1.3:
		_set_state(State.RETRACT)
		return
	
	if _state_time >= 0.3:
		_shot_count = 0
		_shot_timer = 0.0
		_set_state(State.FIRE)


func _process_fire(delta: float) -> void:
	velocity = Vector3.ZERO
	_aim_at_player(delta)
	
	_shot_timer -= delta
	if _shot_timer <= 0.0 and _shot_count < shots_per_burst:
		_fire_projectile(_shot_count % 2 == 0)
		_shot_count += 1
		_shot_timer = fire_interval
	
	if _shot_count >= shots_per_burst:
		var dist: float = _get_player_distance()
		if dist > attack_radius or dist < attack_radius * 0.3:
			_set_state(State.RETRACT)
		else:
			_set_state(State.AIM)


func _process_retract(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / retract_duration, 0.0, 1.0)
	_fold_amount = lerp(0.0, 0.5, ease(t, 2.0))
	
	# Deactivate shield
	_shield_hp = lerp(shield_strength, 0.0, t)
	if _shield_mesh:
		_shield_mesh.visible = t < 0.7
	
	if t >= 1.0:
		_set_state(State.ROLL_UP)


func _process_rollup(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / rollup_duration, 0.0, 1.0)
	_fold_amount = lerp(0.5, 1.0, ease(t, 0.5))
	
	if t >= 1.0:
		_set_state(State.BALL)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_fold_amount = move_toward(_fold_amount, 0.6, delta * 0.5)
	
	if _shield_mesh:
		_shield_mesh.visible = false
	
	if _state_time >= 3.0:
		# Reset for dev observation
		_health = max_health
		_shield_hp = 0.0
		_set_state(State.BALL)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


## Geometry Building

func _create_materials() -> void:
	_shell_material = StandardMaterial3D.new()
	_shell_material.albedo_color = shell_color
	_shell_material.metallic = 0.7
	_shell_material.roughness = 0.3
	_shell_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_inner_material = StandardMaterial3D.new()
	_inner_material.albedo_color = inner_color
	_inner_material.metallic = 0.5
	_inner_material.roughness = 0.5
	
	_accent_material = StandardMaterial3D.new()
	_accent_material.albedo_color = accent_color
	_accent_material.metallic = 0.6
	_accent_material.roughness = 0.4
	_accent_material.emission_enabled = true
	_accent_material.emission = accent_color
	_accent_material.emission_energy_multiplier = 0.8
	
	_shield_material = StandardMaterial3D.new()
	_shield_material.albedo_color = shield_color
	_shield_material.metallic = 0.0
	_shield_material.roughness = 0.1
	_shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_material.emission_enabled = true
	_shield_material.emission = Color(0.4, 0.6, 1.0)
	_shield_material.emission_energy_multiplier = 1.5
	_shield_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _build_shell() -> void:
	_shell_root = Node3D.new()
	_shell_root.name = "ShellRoot"
	add_child(_shell_root)
	
	_shell_bands.clear()
	_shell_plates.clear()
	
	# Create latitudinal bands from top to bottom
	for band_idx in range(shell_segments):
		var band_node: Node3D = Node3D.new()
		band_node.name = "Band_%d" % band_idx
		_shell_root.add_child(band_node)
		_shell_bands.append(band_node)
		
		var band_plates: Array = []
		
		# Latitude angles for this band
		var lat_top: float = PI * float(band_idx) / float(shell_segments)
		var lat_bottom: float = PI * float(band_idx + 1) / float(shell_segments)
		
		# Create plates around this band
		for slice_idx in range(shell_slices):
			var lon_left: float = TAU * float(slice_idx) / float(shell_slices)
			var lon_right: float = TAU * float(slice_idx + 1) / float(shell_slices)
			
			var plate: MeshInstance3D = _create_shell_plate(
				lat_top, lat_bottom, lon_left, lon_right
			)
			plate.name = "Plate_%d_%d" % [band_idx, slice_idx]
			band_node.add_child(plate)
			band_plates.append(plate)
		
		_shell_plates.append(band_plates)


func _create_shell_plate(lat_top: float, lat_bottom: float, lon_left: float, lon_right: float) -> MeshInstance3D:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	
	# Create curved quad on sphere surface
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var indices: PackedInt32Array = []
	
	# Subdivide for smooth curve
	var subdiv: int = 3
	var vert_idx: int = 0
	
	for i in range(subdiv + 1):
		var t_lat: float = float(i) / float(subdiv)
		var lat: float = lerp(lat_top, lat_bottom, t_lat)
		
		for j in range(subdiv + 1):
			var t_lon: float = float(j) / float(subdiv)
			var lon: float = lerp(lon_left, lon_right, t_lon)
			
			# Spherical to cartesian
			var pos: Vector3 = Vector3(
				sin(lat) * cos(lon),
				cos(lat),
				sin(lat) * sin(lon)
			) * ball_radius
			
			verts.append(pos)
			normals.append(pos.normalized())
			uvs.append(Vector2(t_lon, t_lat))
	
	# Create triangles
	for i in range(subdiv):
		for j in range(subdiv):
			var tl: int = i * (subdiv + 1) + j
			var tr: int = tl + 1
			var bl: int = tl + (subdiv + 1)
			var br: int = bl + 1
			
			indices.append(tl)
			indices.append(bl)
			indices.append(tr)
			
			indices.append(tr)
			indices.append(bl)
			indices.append(br)
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var arr_mesh: ArrayMesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	mesh_inst.mesh = arr_mesh
	mesh_inst.material_override = _shell_material
	
	return mesh_inst


func _build_legs() -> void:
	_leg_roots.clear()
	_leg_upper.clear()
	_leg_lower.clear()
	_leg_feet.clear()
	
	for i in range(leg_count):
		var angle: float = TAU * float(i) / float(leg_count)
		
		# Leg root (hip)
		var root: Node3D = Node3D.new()
		root.name = "Leg_%d" % i
		root.rotation.y = angle
		add_child(root)
		_leg_roots.append(root)
		
		# Upper leg
		var upper: MeshInstance3D = MeshInstance3D.new()
		var upper_mesh: CylinderMesh = CylinderMesh.new()
		upper_mesh.height = 0.25
		upper_mesh.top_radius = 0.04
		upper_mesh.bottom_radius = 0.035
		upper.mesh = upper_mesh
		upper.material_override = _inner_material
		root.add_child(upper)
		_leg_upper.append(upper)
		
		# Lower leg
		var lower: MeshInstance3D = MeshInstance3D.new()
		var lower_mesh: CylinderMesh = CylinderMesh.new()
		lower_mesh.height = 0.35
		lower_mesh.top_radius = 0.035
		lower_mesh.bottom_radius = 0.025
		lower.mesh = lower_mesh
		lower.material_override = _inner_material
		root.add_child(lower)
		_leg_lower.append(lower)
		
		# Foot
		var foot: MeshInstance3D = MeshInstance3D.new()
		var foot_mesh: SphereMesh = SphereMesh.new()
		foot_mesh.radius = 0.04
		foot_mesh.height = 0.08
		foot.mesh = foot_mesh
		foot.material_override = _accent_material
		root.add_child(foot)
		_leg_feet.append(foot)


func _build_core() -> void:
	_core = Node3D.new()
	_core.name = "Core"
	add_child(_core)
	
	# Central body
	var body: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: SphereMesh = SphereMesh.new()
	body_mesh.radius = ball_radius * 0.5
	body_mesh.height = ball_radius
	body.mesh = body_mesh
	body.material_override = _inner_material
	_core.add_child(body)
	
	# Turret
	_turret = Node3D.new()
	_turret.name = "Turret"
	_turret.position.y = ball_radius * 0.3
	_core.add_child(_turret)
	
	# Twin barrels
	for side in [-1, 1]:
		var barrel: MeshInstance3D = MeshInstance3D.new()
		var barrel_mesh: CylinderMesh = CylinderMesh.new()
		barrel_mesh.height = 0.2
		barrel_mesh.top_radius = 0.025
		barrel_mesh.bottom_radius = 0.03
		barrel.mesh = barrel_mesh
		barrel.material_override = _accent_material
		barrel.position = Vector3(side * 0.08, 0.0, -0.1)
		barrel.rotation.x = PI * 0.5
		_turret.add_child(barrel)
		
		var muzzle: Marker3D = Marker3D.new()
		muzzle.name = "Muzzle_%s" % ("L" if side < 0 else "R")
		muzzle.position.z = -0.1
		barrel.add_child(muzzle)
		
		if side < 0:
			_muzzle_left = muzzle
		else:
			_muzzle_right = muzzle
	
	# Eye sensor
	var eye: MeshInstance3D = MeshInstance3D.new()
	var eye_mesh: SphereMesh = SphereMesh.new()
	eye_mesh.radius = 0.05
	eye_mesh.height = 0.1
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 0.05, -ball_radius * 0.4)
	
	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.1, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.2, 0.1)
	eye_mat.emission_energy_multiplier = 2.0
	eye.material_override = eye_mat
	_turret.add_child(eye)


func _build_shield() -> void:
	_shield_mesh = MeshInstance3D.new()
	_shield_mesh.name = "Shield"
	
	var shield_geo: SphereMesh = SphereMesh.new()
	shield_geo.radius = ball_radius * 2.0
	shield_geo.height = ball_radius * 4.0
	_shield_mesh.mesh = shield_geo
	_shield_mesh.material_override = _shield_material
	_shield_mesh.visible = false
	
	add_child(_shield_mesh)


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Collision"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = ball_radius * 1.2
	shape.shape = sphere
	add_child(shape)


## Pose Application

func _apply_fold_pose() -> void:
	var fold: float = clamp(_fold_amount, 0.0, 1.0)
	var deploy: float = 1.0 - fold
	
	# Shell bands fold inward when deployed
	for band_idx in range(_shell_bands.size()):
		var band: Node3D = _shell_bands[band_idx]
		
		# Calculate band's natural latitude (center of band)
		var lat_center: float = PI * (float(band_idx) + 0.5) / float(shell_segments)
		var is_upper: bool = lat_center < PI * 0.5
		
		# Fold angle: plates hinge outward from equator
		var equator_dist: float = abs(lat_center - PI * 0.5) / (PI * 0.5)
		var fold_angle: float = deploy * equator_dist * 0.8  # Radians
		
		if is_upper:
			band.rotation.x = -fold_angle
			band.position.y = deploy * equator_dist * 0.3
		else:
			band.rotation.x = fold_angle
			band.position.y = -deploy * equator_dist * 0.1
		
		# Slight outward expansion
		var scale_factor: float = 1.0 + deploy * equator_dist * 0.15
		band.scale = Vector3.ONE * scale_factor
	
	# Apply roll rotation when in ball form
	if _shell_root:
		_shell_root.rotation.x = _roll_angle * fold
		_shell_root.position.y = ball_radius + deploy * (deployed_height - ball_radius)
	
	# Core rises when deployed
	if _core:
		_core.position.y = ball_radius * 0.5 + deploy * (deployed_height * 0.6)
		_core.visible = deploy > 0.3
	
	# Legs unfold
	for i in range(leg_count):
		var root: Node3D = _leg_roots[i]
		var upper: MeshInstance3D = _leg_upper[i]
		var lower: MeshInstance3D = _leg_lower[i]
		var foot: MeshInstance3D = _leg_feet[i]
		
		# Leg angle from vertical
		var leg_spread: float = deploy * 0.6  # Radians outward
		var leg_length: float = 0.25 + deploy * 0.35
		
		root.position.y = ball_radius * 0.3 + deploy * deployed_height * 0.3
		root.rotation.x = leg_spread
		
		# Upper leg
		upper.position = Vector3(0.15 * deploy, -0.1 * deploy, 0)
		upper.rotation.z = -leg_spread * 0.5
		upper.visible = deploy > 0.2
		
		# Lower leg hinges from upper
		lower.position = upper.position + Vector3(0.1 * deploy, -0.2 - 0.15 * deploy, 0)
		lower.rotation.z = leg_spread * 0.3
		lower.visible = deploy > 0.2
		
		# Foot at bottom
		var foot_y: float = -0.1 - deploy * (deployed_height - ball_radius - 0.1)
		foot.position = Vector3(0.2 * deploy, foot_y, 0)
		foot.visible = deploy > 0.3
	
	# Shield scales with deployment
	if _shield_mesh and _shield_mesh.visible:
		var shield_scale: float = 0.5 + deploy * 0.5
		_shield_mesh.scale = Vector3.ONE * shield_scale
		_shield_mesh.position.y = _core.position.y if _core else deployed_height * 0.5


## Combat

func _fire_projectile(left: bool) -> void:
	if not FIRE_BOLT_SCENE:
		return
	
	var muzzle: Marker3D = _muzzle_left if left else _muzzle_right
	if not muzzle:
		return
	
	var bolt: Node = FIRE_BOLT_SCENE.instantiate()
	if not bolt:
		return
	
	var spawn_pos: Vector3 = muzzle.global_position
	var fire_dir: Vector3 = -_turret.global_transform.basis.z.normalized()
	
	var scene: Node = get_tree().current_scene
	if scene:
		scene.add_child(bolt)
	else:
		add_child(bolt)
	
	if bolt.has_method("launch"):
		bolt.launch(spawn_pos, fire_dir, fire_speed, fire_damage)
	
	fired_projectile.emit(spawn_pos, fire_dir)


func _aim_at_player(delta: float) -> void:
	if not _turret or not is_instance_valid(_player_node):
		return
	
	var target: Vector3 = _player_node.global_position + Vector3(0, 1.0, 0)
	var to_target: Vector3 = target - _turret.global_position
	
	if to_target.length_squared() < 0.01:
		return
	
	var yaw: float = atan2(to_target.x, to_target.z)
	_turret.rotation.y = lerp_angle(_turret.rotation.y, yaw, delta * 6.0)


## Damage

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	
	# Shield absorbs damage first
	if _shield_hp > 0.0:
		var absorbed: float = min(_shield_hp, amount)
		_shield_hp -= absorbed
		amount -= absorbed
		
		# Shield flicker
		if _shield_mesh and _shield_material:
			var tween: Tween = create_tween()
			tween.tween_property(_shield_material, "emission_energy_multiplier", 3.0, 0.05)
			tween.tween_property(_shield_material, "emission_energy_multiplier", 1.5, 0.1)
	
	if amount <= 0.0:
		return
	
	_health -= amount
	
	if _health <= 0.0:
		_set_state(State.DEAD)
		enemy_destroyed.emit(self)
	else:
		# Hit flash
		var tween: Tween = create_tween()
		tween.tween_property(_accent_material, "emission_energy_multiplier", 3.0, 0.05)
		tween.tween_property(_accent_material, "emission_energy_multiplier", 0.8, 0.15)


## Utility

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players:
			if p is Node3D:
				_player_node = p
				return
	
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	
	for node_name in ["XROrigin3D", "Player", "PlayerController"]:
		var found = scene.find_child(node_name, true, false)
		if found and found is Node3D:
			_player_node = found
			return


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


func _get_player_direction() -> Vector3:
	if not is_instance_valid(_player_node):
		return Vector3.FORWARD
	var dir: Vector3 = _player_node.global_position - global_position
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.1 else Vector3.FORWARD


func _face_velocity(delta: float) -> void:
	var flat_vel: Vector3 = Vector3(velocity.x, 0, velocity.z)
	if flat_vel.length_squared() < 0.01:
		return
	var target_yaw: float = atan2(flat_vel.x, flat_vel.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 5.0)


func configure(config: Dictionary) -> void:
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("shield"):
		shield_strength = float(config["shield"])
	if config.has("damage"):
		fire_damage = float(config["damage"])
	if config.has("speed"):
		roll_speed = float(config["speed"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
