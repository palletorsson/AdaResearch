extends Node
class_name NumberHelper

# Generates a random 5-digit number as a string
static func random_5_digit_number() -> String:
	return str(randi() % 100000).pad_zeros(5)
