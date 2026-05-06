# ModeForces.gd
# Mode 4 — "Calming, Harnessing, Focusing"
# A warm amber mortar that calms and slows what it touches.
# Force used to tame, passage, harness — not destroy.
class_name CatalystModeForces

const MODE_ID := "forces"
const MODE_NAME := "Forces"
const DESCRIPTION := "Calm, harness, focus. Force as care."
const FIRE_RATE := 0.8
const SEQUENCE := "forces"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	# set_script() FIRST — it reinitializes all variables
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/forces_projectile.gd"))
	proj.speed = 10.0
	proj.lifetime = 5.0
	proj.projectile_scale = 1.3
	proj.color_primary = Color(1.0, 0.75, 0.3)
	proj.color_secondary = Color(0.9, 0.5, 0.15)
	proj.emission_energy = 1.6
	proj.direction = dir
	return proj
