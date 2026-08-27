extends Node3D
## A stand-in player for probe_crab_bite: it stands still and counts its wounds.
## take_damage is the FIRST of the three method names head_crab tries, so a hit
## that lands here proves the first branch of the damage protocol.
var health: float = 100.0
var taken: float = 0.0
var hits: int = 0
var last_amount: float = 0.0

func take_damage(amount: float) -> void:
	last_amount = amount
	taken += amount
	hits += 1
	health = maxf(0.0, health - amount)
