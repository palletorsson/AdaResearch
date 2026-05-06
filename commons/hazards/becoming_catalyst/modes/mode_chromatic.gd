# ModeChromatic.gd
# Mode 3 — "Color as Identity"
# Fast rainbow spheres.  Each shot a different hue.
# Chromatic expression — identity as spectrum.
class_name CatalystModeChromatic

const MODE_ID := "chromatic"
const MODE_NAME := "Chromatic"
const DESCRIPTION := "Color as identity. Each shot a different hue."
const FIRE_RATE := 0.25
const SEQUENCE := "color"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	# set_script() FIRST — it reinitializes all variables
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/chromatic_projectile.gd"))
	proj.speed = 15.0
	proj.lifetime = 3.5
	proj.projectile_scale = 0.7
	# Random hue each shot
	var hue := randf()
	proj.color_primary = Color.from_hsv(hue, 0.85, 1.0)
	proj.color_secondary = Color.from_hsv(fmod(hue + 0.15, 1.0), 0.7, 0.9)
	proj.emission_energy = 2.2
	proj.direction = dir
	return proj
