# stub_color_mutator.gd — probe stand-in for the mutator stack (biome-7).
# Extends GridMutatorBase so _collect_mutators finds it; the filename carries
# the "color" channel (no class_name — routing falls back to the path slug).
# Counts advance calls instead of touching any MultiMesh.
extends GridMutatorBase

var advances: int = 0


func _ready() -> void:
	pass  # skip the base's multimesh discovery — this stub only counts


func advance_to_next_pattern() -> void:
	advances += 1
