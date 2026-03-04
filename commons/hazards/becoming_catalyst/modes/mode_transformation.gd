# ModeTransformation.gd
# Mode 2 — "Change What Exists"
# A purple sphere that shrinks what it touches.
# Not damage — metamorphosis. What you hit becomes different.
class_name CatalystModeTransformation

const MODE_ID := "transformation"
const MODE_NAME := "Transformation"
const DESCRIPTION := "Change what exists. Transformation is power."
const FIRE_RATE := 0.4
const SEQUENCE := "transformation"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	# set_script() FIRST — it reinitializes all variables
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/transformation_projectile.gd"))
	proj.speed = 12.0
	proj.lifetime = 4.0
	proj.projectile_scale = 0.9
	proj.color_primary = Color(0.7, 0.3, 0.85)
	proj.color_secondary = Color(0.5, 0.15, 0.7)
	proj.emission_energy = 1.8
	proj.direction = dir
	return proj
