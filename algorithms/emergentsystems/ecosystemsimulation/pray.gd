extends Creature
class_name Prey

var food_collected: float = 0.0

func _init(pos: Vector2, dna_values: Dictionary = {}):
	super._init(pos, dna_values)

func eat_food(amount: float):
	food_collected += amount
	health = min(health + amount * 0.1, 1.0)  # Eating food restores health

func update(delta: float):
	super.update(delta)
	
	# Metabolism - slowly consume collected food
	if food_collected > 0:
		var consumption = min(food_collected, delta * 0.1)
		food_collected -= consumption
		# Food provides energy to maintain health
		health = min(health + consumption * 0.05, 1.0)
