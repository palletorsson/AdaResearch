# PhysicsController.gd
# Chapter 5: The Physics Cube
# Handles RigidBody3D physics interactions and effects

extends Node3D

@export var impulse_strength: float = 5.0
@export var bounce_sound_threshold: float = 2.0
@export var sleep_timeout: float = 3.0

var rigid_body: RigidBody3D
var shader_controller: Node3D
var collision_count: int = 0
var last_collision_time: float = 0.0

# Physics signals
signal cube_bounced(impact_force: float)
signal cube_settled()
signal cube_thrown(velocity: Vector3)

func _ready():
	# Find the rigid body
	rigid_body = find_child("CubeRigidBody", false, false)
	shader_controller = find_child("CubeShaderController", false, false)
	
	if rigid_body:
		# Connect physics signals
		rigid_body.body_entered.connect(_on_collision)
		rigid_body.sleeping_state_changed.connect(_on_sleep_changed)
		print("PhysicsController: Connected to RigidBody3D")
	
	print("PhysicsController: Physics cube ready")

func _process(delta):
	# Auto-settle detection
	if rigid_body and not rigid_body.sleeping:
		if rigid_body.linear_velocity.length() < 0.1:
			last_collision_time += delta
			if last_collision_time > sleep_timeout:
				_settle_cube()
		else:
			last_collision_time = 0.0

func _on_collision(body: Node):
	if not rigid_body:
		return
	
	var impact_velocity = rigid_body.linear_velocity.length()
	collision_count += 1
	last_collision_time = 0.0
	
	print("PhysicsController: Collision #%d with impact: %f" % [collision_count, impact_velocity])
	
	# Trigger bounce effects if impact is significant
	if impact_velocity > bounce_sound_threshold:
		_trigger_bounce_effects(impact_velocity)
		cube_bounced.emit(impact_velocity)

func _on_sleep_changed():
	if rigid_body.sleeping:
		print("PhysicsController: Cube has settled (physics sleep)")
		cube_settled.emit()
		_apply_settled_effects()

func _trigger_bounce_effects(impact_force: float):
	# Visual feedback for bounce
	if shader_controller:
		var bounce_color = Color.ORANGE
		shader_controller.set_emission_color(bounce_color)
		
		# Flash briefly then restore
		await get_tree().create_timer(0.2).timeout
		if shader_controller:
			shader_controller.set_emission_color(Color.CYAN)
	
	# Scale impact based on force
	var scale_boost = 1.0 + (impact_force * 0.1)
	if rigid_body:
		var tween = create_tween()
		var original_scale = scale
		tween.tween_property(self, "scale", original_scale * scale_boost, 0.1)
		tween.tween_property(self, "scale", original_scale, 0.2)

func _apply_settled_effects():
	# Gentle glow when settled
	if shader_controller:
		shader_controller.set_emission_color(Color.GREEN)

func _settle_cube():
	if rigid_body and not rigid_body.sleeping:
		# Force physics sleep
		rigid_body.sleeping = true
		print("PhysicsController: Force settled cube")

# Public interaction methods
func apply_impulse(direction: Vector3, strength: float = -1.0):
	if not rigid_body:
		return
	
	var force = strength if strength > 0 else impulse_strength
	var impulse_vector = direction.normalized() * force
	
	# Wake up if sleeping
	if rigid_body.sleeping:
		rigid_body.sleeping = false
	
	rigid_body.apply_central_impulse(impulse_vector)
	cube_thrown.emit(impulse_vector)
	print("PhysicsController: Applied impulse: %s" % impulse_vector)

func apply_upward_force():
	apply_impulse(Vector3.UP, impulse_strength * 1.5)

func apply_random_impulse():
	var random_direction = Vector3(
		randf_range(-1, 1),
		randf_range(0.5, 1),  # Always some upward component
		randf_range(-1, 1)
	).normalized()
	apply_impulse(random_direction)

func reset_physics():
	if rigid_body:
		rigid_body.linear_velocity = Vector3.ZERO
		rigid_body.angular_velocity = Vector3.ZERO
		rigid_body.sleeping = false
		collision_count = 0
		last_collision_time = 0.0
		print("PhysicsController: Physics reset")

# Configuration methods
func set_mass(new_mass: float):
	if rigid_body:
		rigid_body.mass = new_mass

func set_bounce(bounce_factor: float):
	if rigid_body:
		var physics_material = PhysicsMaterial.new()
		physics_material.bounce = bounce_factor
		rigid_body.physics_material_override = physics_material

func set_friction(friction_factor: float):
	if rigid_body:
		if not rigid_body.physics_material_override:
			rigid_body.physics_material_override = PhysicsMaterial.new()
		rigid_body.physics_material_override.friction = friction_factor

# Status queries
func is_moving() -> bool:
	return rigid_body and not rigid_body.sleeping and rigid_body.linear_velocity.length() > 0.1

func get_velocity() -> Vector3:
	return rigid_body.linear_velocity if rigid_body else Vector3.ZERO

func get_collision_count() -> int:
	return collision_count
