extends RigidBody3D
## Relative contact speed, including an object thrown by either XRTools hand.
## Ground contact and stationary supports never count as thrown objects.
var mine: Node3D
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_instance_valid(mine) or mine.spent or mine.age < mine.arm_delay:return
	for i in state.get_contact_count():
		var other: Object = state.get_contact_collider_object(i)
		if not other is RigidBody3D or other == self or other.has_meta("electrical_mine"):continue
		if other.has_method("is_picked_up") and other.is_picked_up():continue
		var impact := (state.get_contact_collider_velocity_at_position(i) - state.get_contact_local_velocity_at_position(i)).length()
		if impact >= mine.impact_speed:
			mine.call_deferred("receive_impact", other.get_instance_id())
			return
