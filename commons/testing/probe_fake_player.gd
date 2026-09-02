extends Node3D

## A player for probes: a Node3D in group "player" that COUNTS what hits it,
## and reaches no GameManager — so a creature's contact damage can be asserted
## without the real health pool draining and DeathEffect reloading the scene
## under the probe. (2026-08-29)

var hits: int = 0
var total: float = 0.0


func _ready() -> void:
	add_to_group("player")


func apply_health_damage(amount: float) -> void:
	hits += 1
	total += amount
