extends Creature
class_name Predator

func _init(pos: Vector2, dna_values: Dictionary = {}):
	# Call parent _init to set up the base DNA if empty
	super._init(pos, dna_values)
	
	# Now modify the DNA that was created in the parent class
	# This way we know the keys already exist
	dna["max_speed"] = dna["max_speed"] * 1.5
	dna["lifespan"] = dna["lifespan"] * 0.8
	dna["size"] = dna["size"] * 1.5
	
	# Update the instance properties with the modified DNA values
	max_speed = dna["max_speed"]
	lifespan = dna["lifespan"]
	size = dna["size"]

func eat_prey(prey: Prey):
	# Gain health based on prey size
	var nutrition = prey.size / 10.0
	health = min(health + nutrition, 1.0)
