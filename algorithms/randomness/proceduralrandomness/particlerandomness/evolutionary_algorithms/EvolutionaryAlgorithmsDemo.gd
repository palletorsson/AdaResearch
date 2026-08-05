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

## STAGE-2 DNA. The axis is `selection`, declared by this token and by
## particle_randomness_evolutionary — which is the same scene under a second name — and
## implemented in the parent, extrem_randomness.gd, because chapter five's update rule
## lives there. The four values, and how they were measured, are documented on the axis
## declaration in that file.
##
## Do not write the words that spell an export declaration into a comment here: the
## declaration gate resolves an axis to the FIRST script in the scene that appears to
## export it, and a prose mention in this file sent it to a script with no enum in it.
##
## This does NOT call super. The parent's hook also owns `chapter`, and this subclass
## exists precisely to pin the chapter to evolution: forwarding it would let a map token
## restage a DIFFERENT demo under a name that promises this one, and every chapter value
## would still photograph identically because _ready overrides it a line later. So the
## only key taken here is the axis this token actually declares.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("selection"):
		_apply_selection(str(config["selection"]))
