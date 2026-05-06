extends "res://algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd"

# @identity
# essence: population(t+1) = select(fit) + mutate(crossover(parents)), repeated. Fitness landscape as selection pressure.
# desire: To evolve — particles compete, mutate, and reproduce, and the population visibly converges on fitness peaks
# critical_parameter: the fitness function (inherited from extrem_randomness demo 4) — determines what "good" means and thus what evolution finds
# triggers: Each frame updates evolutionary_algorithms step: selection → crossover → mutation → fitness evaluation → render
# emerges: Convergence toward fitness peaks from undirected random variation — no particle knows the goal, yet the population finds it
# needs: VR fitness landscape control [missing], mutation rate slider [missing]
# relationships: Cross-sequence guest from randomness; bridges fractals (stochastic variation) with emergence (population dynamics)
# truth: Evolution is not design — it is the statistical consequence of reproduction with variation under selection pressure.

const DEMO_INDEX := 4

func _ready() -> void:
	super._ready()
	display_time = 1000000.0
	demo_time = 0.0
	current_demo = DEMO_INDEX
	start_demo(current_demo)

func _process(delta: float) -> void:
	update_evolutionary_algorithms(delta)

func apply_grid_config(config: Dictionary) -> void:
	pass
