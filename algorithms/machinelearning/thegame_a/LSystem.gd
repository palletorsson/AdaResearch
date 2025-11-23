extends Node
class_name LSystem

# The Axiom Garden - Iteration 1: The Seed
# Handles the string rewriting logic for L-Systems.

var axiom: String = ""
var rules: Dictionary = {}
var generations: int = 0

func _init(start_axiom: String = "", production_rules: Dictionary = {}):
	axiom = start_axiom
	rules = production_rules

# Generates the string for a specific number of generations
func generate(iterations: int) -> String:
	var current_string = axiom
	
	for i in range(iterations):
		var next_string = ""
		for character in current_string:
			if rules.has(character):
				var replacement = rules[character]
				if replacement is Array:
					# Stochastic choice
					next_string += replacement.pick_random()
				else:
					# Deterministic
					next_string += replacement
			else:
				next_string += character
		current_string = next_string
		
	return current_string

# Helper to set rules easily
func set_rule(predecessor: String, successor: String):
	rules[predecessor] = successor
