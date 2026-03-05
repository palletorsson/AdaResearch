# ModeCellular.gd
# Mode 8 — "Emergence from Rules"
# 3×3 grid of tiny cubes fired simultaneously.
# Alive/dead pattern from CA Rule 30.  The pattern IS the algorithm.
class_name CatalystModeCellular

const MODE_ID := "cellular"
const MODE_NAME := "Cellular"
const DESCRIPTION := "Emergence from simple rules. The pattern IS the algorithm."
const FIRE_RATE := 0.7
const SEQUENCE := "cellularautomata"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	# This mode spawns a grid, so we create a container projectile
	var proj := CatalystProjectile.new()
	# set_script() FIRST — it reinitializes all variables
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/cellular_projectile.gd"))
	proj.speed = 5.0
	proj.lifetime = 8.0
	proj.projectile_scale = 0.6
	proj.color_primary = Color(0.95, 0.95, 0.95)
	proj.color_secondary = Color(0.4, 0.4, 0.5)
	proj.emission_energy = 1.5
	proj.direction = dir
	return proj
