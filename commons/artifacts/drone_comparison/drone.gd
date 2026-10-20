extends "res://algorithms/emergentsystems/boidflocking/Boid.gd"
## The existing museum Boid integrator with one explicit destination request.
var flight: Node3D
var slot := Vector3.ZERO

func _ready() -> void:
	boid_manager = get_parent()
	steering_source = self

func destination() -> Vector3:
	var offset: Vector3 = slot if flight.assigned else Vector3.ZERO
	return flight.to_global(flight.encounter.target_offset + offset)

func steering_at(at: Vector3, v: Vector3) -> Vector3:
	var toward := destination() - at
	var desired: Vector3 = toward.normalized() * max_speed * minf(toward.length() / 1.0, 1.0)
	return ((desired - v) * 2.0).limit_length(3.0)
