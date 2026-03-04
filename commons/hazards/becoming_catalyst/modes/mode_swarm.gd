# ModeSwarm.gd
# Mode 10 — "Collective Movement"
# 8 tiny boid spheres that flock together.  Mutual aid in motion.
# The swarm cares for itself — collective behaviour, not individual force.
class_name CatalystModeSwarm

const MODE_ID := "swarm"
const MODE_NAME := "Swarm"
const DESCRIPTION := "Collective movement. Mutual aid in motion."
const FIRE_RATE := 1.0
const SEQUENCE := "swarmintelligence"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	# set_script() FIRST — it reinitializes all variables
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/swarm_projectile.gd"))
	proj.speed = 12.0
	proj.lifetime = 4.0
	proj.projectile_scale = 1.0
	proj.color_primary = Color(1.0, 0.85, 0.4)
	proj.color_secondary = Color(0.9, 0.65, 0.2)
	proj.emission_energy = 1.8
	proj.direction = dir
	return proj
