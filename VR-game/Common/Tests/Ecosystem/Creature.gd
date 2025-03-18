extends Node2D
class_name Creature

var velocity: Vector2 = Vector2.ZERO
var max_speed: float
var max_force: float
var size: float
var health: float
var dna: Dictionary
var lifespan: float
var age: float = 0.0

func _init(pos: Vector2, dna_values: Dictionary = {}):
	position = pos  # Using the built-in position property from Node2D
	
	# Default DNA values if none provided
	if dna_values.size() == 0:
		dna = {
			"max_speed": randf_range(2.0, 4.0),
			"max_force": randf_range(0.1, 0.5),
			"size": randf_range(5.0, 15.0),
			"perception_radius": randf_range(50.0, 150.0),
			"lifespan": randf_range(10.0, 30.0),
			"reproduction_rate": randf_range(0.001, 0.005),
			# Steering weights
			"separation_weight": randf_range(1.0, 2.0),
			"alignment_weight": randf_range(1.0, 2.0),
			"cohesion_weight": randf_range(1.0, 2.0),
			"flee_weight": randf_range(1.0, 3.0),
			"seek_weight": randf_range(1.0, 3.0)
		}
	else:
		dna = dna_values
	
	# Apply DNA to properties
	max_speed = dna["max_speed"]
	max_force = dna["max_force"]
	size = dna["size"]
	lifespan = dna["lifespan"]
	health = 1.0  # Full health at birth

func _process(delta: float):
	# Not needed since we'll handle updates through the ecosystem
	pass

func update(delta: float):
	age += delta
	health -= delta / lifespan  # Gradually lose health over lifespan
	
	# Apply forces and move
	position += velocity * delta
	
	# Wrap around edges of screen
	var viewport_size = get_viewport_rect().size
	if position.x < 0: position.x = viewport_size.x
	if position.y < 0: position.y = viewport_size.y
	if position.x > viewport_size.x: position.x = 0
	if position.y > viewport_size.y: position.y = 0

func apply_force(force: Vector2):
	velocity += force
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func is_dead() -> bool:
	return health <= 0

func can_reproduce() -> bool:
	# Can reproduce if mature and has enough health
	return age > lifespan * 0.3 and health > 0.5

# Implement steering behaviors
func seek(target: Vector2) -> Vector2:
	var desired = target - position
	desired = desired.normalized() * max_speed
	var steer = desired - velocity
	steer = steer.limit_length(max_force)
	return steer

func flee(target: Vector2) -> Vector2:
	return -seek(target)
