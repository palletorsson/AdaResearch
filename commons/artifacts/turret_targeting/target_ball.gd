extends Node3D
## One damage receiver for the dropper's reusable balls. Physics is the child;
## health and pool ownership live here, where ray/weapon ancestor walks end.
var dropper: Node3D

func take_damage(amount: float) -> bool:
	if amount <= 0.0 or not is_instance_valid(dropper) or not dropper.active_balls.has(self):
		return false
	var remaining := maxf(0.0, float(get_meta("health", 80.0)) - amount)
	set_meta("health", remaining)
	if remaining > 0.0: return false
	return dropper.destroy_ball(self)

func trigger_explosion() -> void:
	take_damage(float(get_meta("health", 80.0)))

func hit_by_laser() -> void:
	trigger_explosion()
