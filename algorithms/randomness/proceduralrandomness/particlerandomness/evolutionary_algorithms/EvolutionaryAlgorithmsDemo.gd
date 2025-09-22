extends "res://algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd"

const DEMO_INDEX := 4

func _ready() -> void:
	super._ready()
	display_time = 1000000.0
	demo_time = 0.0
	current_demo = DEMO_INDEX
	start_demo(current_demo)

func _process(delta: float) -> void:
	update_evolutionary_algorithms(delta)
