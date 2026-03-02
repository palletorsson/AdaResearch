# ModePrimitives.gd
# Mode 1 — "First Expression"
# A glowing sphere that bounces off walls and slowly shrinks away.
# A thought entering the world, echoing, then fading.
class_name CatalystModePrimitives

const MODE_ID := "primitives"
const MODE_NAME := "Primitives"
const DESCRIPTION := "First expression. A shape enters the world."
const FIRE_RATE := 0.4
const SEQUENCE := "primitives"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	proj.speed = 6.0
	proj.lifetime = 8.0
	proj.projectile_scale = 1.0
	proj.color_primary = Color(0.85, 0.85, 0.9)
	proj.color_secondary = Color(0.6, 0.6, 0.65)
	proj.emission_energy = 1.2
	proj.direction = dir
	proj.global_position = pos
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/primitives_projectile.gd"))
	return proj
