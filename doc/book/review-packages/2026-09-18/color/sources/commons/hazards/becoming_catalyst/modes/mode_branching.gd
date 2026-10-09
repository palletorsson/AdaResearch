# ModeBranching.gd
# Mode 9 — "Grammar of Growth"
# L-system style branching projectile.  A seed that grows into a tree.
# Grammar-based becoming — generative identity.
class_name CatalystModeBranching

const MODE_ID := "branching"
const MODE_NAME := "Branching"
const DESCRIPTION := "Grammar of growth. Generative identity."
const FIRE_RATE := 0.8
const SEQUENCE := "lsystems"

static func create_projectile(pos: Vector3, dir: Vector3, depth: int = 0) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	# set_script() FIRST — it reinitializes all variables
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/branching_projectile.gd"))
	var scale_factor := pow(0.7, depth)
	proj.speed = 10.0
	proj.lifetime = 3.5
	proj.projectile_scale = scale_factor
	proj.color_primary = Color(0.4, 0.75, 0.3)
	proj.color_secondary = Color(0.25, 0.5, 0.15)
	proj.emission_energy = 1.2
	proj.direction = dir
	proj.set_meta("branch_depth", depth)
	return proj
