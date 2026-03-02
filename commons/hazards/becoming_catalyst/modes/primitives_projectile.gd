# PrimitivesProjectile.gd
# A glowing sphere that bounces off walls and slowly shrinks to nothing.
# The most basic expression — geometry finding its voice, then fading.
extends CatalystProjectile

var _shrink_tween: Tween = null
var _light: OmniLight3D = null

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08 * projectile_scale
	sphere.height = 0.16 * projectile_scale
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Small point light so the ball illuminates nearby walls
	_light = OmniLight3D.new()
	_light.light_color = color_primary
	_light.light_energy = 0.6
	_light.omni_range = 1.5
	_light.omni_attenuation = 2.0
	add_child(_light)

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.09 * projectile_scale
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _apply_initial_velocity() -> void:
	# Disconnect the base body_entered handler — bouncing balls don't die on hit
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)

	# Bouncy physics material
	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = 0.85
	phys_mat.friction = 0.2
	physics_material_override = phys_mat

	# Light gravity so it floats around more
	gravity_scale = 0.4
	contact_monitor = false  # Don't need contact reports for bouncing

	# Fire forward
	linear_velocity = direction.normalized() * speed

	# Start the shrink — ball disappears over its lifetime
	_shrink_tween = create_tween()
	_shrink_tween.tween_property(self, "scale", Vector3.ZERO, lifetime).set_ease(Tween.EASE_IN)
	_shrink_tween.tween_callback(queue_free)

func _update_trajectory(_delta: float) -> void:
	# Gentle color pulse while bouncing
	if _mesh_instance:
		var pulse := 0.8 + sin(time_alive * 3.0) * 0.2
		var mat := _mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = emission_energy * pulse
		if _light:
			_light.light_energy = 0.6 * pulse

func _expire() -> void:
	# The shrink tween handles cleanup, so skip the base expire.
	pass
