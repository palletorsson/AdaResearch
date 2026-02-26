# PrimitivesProjectile.gd
# A simple glowing cube that travels in a straight line.
# The most basic expression — geometry finding its voice.
extends CatalystProjectile

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.12 * projectile_scale
	_mesh_instance.mesh = box
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Slow gentle rotation
	set_physics_process(true)

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * 0.14 * projectile_scale
	_collision_shape.shape = shape
	add_child(_collision_shape)

func _update_trajectory(_delta: float) -> void:
	# Gentle tumble
	if _mesh_instance and not has_hit:
		_mesh_instance.rotate_y(_delta * 2.0)
		_mesh_instance.rotate_x(_delta * 1.5)

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	# Gentle: no damage, just a soft bounce notification
	if body is RigidBody3D and not body.freeze:
		var push := direction.normalized() * 0.5
		body.apply_central_impulse(push)
