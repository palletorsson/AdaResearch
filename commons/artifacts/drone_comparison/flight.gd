extends Node3D
## Each flight exposes only its own neighbours to the original Boid solver.
var assigned := false
var encounter: Node3D
var drones: Array[Node3D] = []
func get_boids() -> Array[Node3D]: return drones
