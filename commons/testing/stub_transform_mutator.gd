# Test double for smoke_catalyst_mutation.gd.
# It IS a GridMutatorBase (so _collect_mutators finds it) but skips the real
# _ready — which awaits a 1 s timer, hunts a MultiMesh and starts cycling
# timers. Only the routing contract is under test here: the class name
# carries the channel word and advance_to_next_pattern() is the call.
extends "res://commons/grid/mutators/grid_mutator_base.gd"

var advances: int = 0

func _ready() -> void:
	pass   # deliberately NOT calling super() — no timers, no multimesh hunt

func advance_to_next_pattern() -> void:
	advances += 1
