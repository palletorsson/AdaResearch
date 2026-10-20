extends "res://algorithms/emergentsystems/boidflocking/Boid.gd"
## Fish silhouette over the existing Boid steering; no duplicate flock solver.
func _ready() -> void:
	boid_manager = get_parent()
	# The school supplies seeded velocity and geometry. No long prism ribbons.
