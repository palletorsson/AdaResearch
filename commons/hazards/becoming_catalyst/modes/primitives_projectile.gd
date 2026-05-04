# PrimitivesProjectile.gd
# A glowing sphere that bounces off walls and slowly shrinks to nothing.
# The most basic expression — geometry finding its voice, then fading.
extends CatalystProjectile

var _light: OmniLight3D = null
# Manual mesh+collision shrink (do NOT tween RigidBody3D.scale — that fights
# the physics integrator and freezes the body in place).
var _shrink_progress: float = 0.0

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
	# Replace the base body_entered handler. The base handler kills the
	# ball on first hit; we want it to BOUNCE while still firing the
	# catalyst transformation on whatever hit-receiver it touches.
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	body_entered.connect(_on_bouncy_hit)

	# Bouncy physics material
	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = 0.85
	phys_mat.friction = 0.2
	physics_material_override = phys_mat

	# Light gravity so it floats around more
	gravity_scale = 0.4
	# Need contact reports so we know when the ball hits a foe/target.
	# Was set to false ("not needed for bouncing"), which silently
	# disabled all hit detection for primitives mode — the original bug.
	contact_monitor = true
	max_contacts_reported = 4

	# Fire forward
	linear_velocity = direction.normalized() * speed

	# Shrink is handled in _update_trajectory by scaling the mesh + collision
	# shape directly. Tweening Node3D.scale on a RigidBody3D fights the
	# physics integrator and pins the body in place.


# Hit handler that fires the transformation without killing the ball.
# The ball keeps bouncing (no _impact_effect / _cleanup), so it can
# transform multiple foes in a single shot if it bounces between them.
func _on_bouncy_hit(body: Node3D) -> void:
	if body.is_in_group("catalyst"):
		return
	# Dispatch FIRST so transformation can never be skipped by a sparks
	# spawn error (e.g. current_scene null during scene-tree teardown).
	_dispatch_transformation(body)
	# Spark burst at the bounce point — every collision feels punchy.
	_spawn_bounce_sparks()


# Tiny spark burst at the ball's current position. Colored to match the
# ball's color. Spawned in the SCENE (not as a child of the ball) so it
# stays at the impact point while the ball bounces away.
func _spawn_bounce_sparks() -> void:
	var sparks := GPUParticles3D.new()
	sparks.amount = 12
	sparks.lifetime = 0.4
	sparks.one_shot = true
	sparks.explosiveness = 0.98
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 90.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 2.5
	pmat.gravity = Vector3(0, -2.0, 0)
	pmat.scale_min = 0.025
	pmat.scale_max = 0.06
	pmat.color = color_primary
	sparks.process_material = pmat
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	sparks.draw_pass_1 = sphere
	var smat := StandardMaterial3D.new()
	smat.albedo_color = color_primary
	smat.emission_enabled = true
	smat.emission = color_primary
	smat.emission_energy_multiplier = 4.0
	sparks.material_override = smat
	# Add to current_scene rather than self — sparks stay at impact while ball bounces.
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	parent.add_child(sparks)
	sparks.global_position = global_position
	sparks.emitting = true
	# Self-cleanup
	var t := get_tree().create_timer(sparks.lifetime + 0.2)
	t.timeout.connect(sparks.queue_free)

func _update_trajectory(delta: float) -> void:
	# Manual shrink — scale mesh + collision child directly, NEVER touch the
	# RigidBody3D's own scale (that pins the body and disables gravity sim).
	var t_norm: float = clamp(time_alive / max(lifetime, 0.001), 0.0, 1.0)
	var shrink_factor: float = 1.0 - (t_norm * t_norm)  # ease-in
	if _mesh_instance:
		_mesh_instance.scale = Vector3.ONE * shrink_factor
	if _collision_shape:
		_collision_shape.scale = Vector3.ONE * shrink_factor
	if shrink_factor <= 0.01 and not has_hit:
		queue_free()
		return
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
