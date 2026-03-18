extends Node3D
class_name Creature

var velocity: Vector3 = Vector3.ZERO
var max_speed: float
var max_force: float
var size: float
var health: float
var dna: Dictionary
var lifespan: float
var age: float = 0.0

# Bounding box for wraparound (half-extents)
const BOUNDS_X: float = 0.4
const BOUNDS_Y: float = 0.2
const BOUNDS_Z: float = 0.4

func _init(pos: Vector3, dna_values: Dictionary = {}) -> void:
	position = pos

	# Default DNA values if none provided
	if dna_values.size() == 0:
		dna = {
			"max_speed": randf_range(0.05, 0.15),
			"max_force": randf_range(0.005, 0.02),
			"size": randf_range(0.005, 0.015),
			"perception_radius": randf_range(0.05, 0.15),
			"lifespan": randf_range(10.0, 30.0),
			"reproduction_rate": randf_range(0.001, 0.005),
			"separation_weight": randf_range(1.0, 2.0),
			"alignment_weight": randf_range(1.0, 2.0),
			"cohesion_weight": randf_range(1.0, 2.0),
			"flee_weight": randf_range(1.0, 3.0),
			"seek_weight": randf_range(1.0, 3.0)
		}
	else:
		dna = dna_values

	max_speed = dna["max_speed"]
	max_force = dna["max_force"]
	size = dna["size"]
	lifespan = dna["lifespan"]
	health = 1.0

func update(delta: float) -> void:
	age += delta
	health -= delta / lifespan

	position += velocity * delta

	# Wrap around 3D bounding box (0.8 x 0.4 x 0.8)
	if position.x < -BOUNDS_X: position.x = BOUNDS_X
	if position.x > BOUNDS_X: position.x = -BOUNDS_X
	if position.y < 0.0: position.y = BOUNDS_Y * 2.0
	if position.y > BOUNDS_Y * 2.0: position.y = 0.0
	if position.z < -BOUNDS_Z: position.z = BOUNDS_Z
	if position.z > BOUNDS_Z: position.z = -BOUNDS_Z

func apply_force(force: Vector3) -> void:
	velocity += force
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func is_dead() -> bool:
	return health <= 0

func can_reproduce() -> bool:
	return age > lifespan * 0.3 and health > 0.5

func seek(target: Vector3) -> Vector3:
	var desired = target - position
	desired = desired.normalized() * max_speed
	var steer = desired - velocity
	if steer.length() > max_force:
		steer = steer.normalized() * max_force
	return steer

func flee(target: Vector3) -> Vector3:
	return -seek(target)

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	pass
