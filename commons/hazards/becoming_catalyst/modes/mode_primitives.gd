# ModePrimitives.gd
# Mode 1 — "First Expression"
# A slow cube in a straight line. The simplest gesture.
# A thought entering the world for the first time.
class_name CatalystModePrimitives

const MODE_ID := "primitives"
const MODE_NAME := "Primitives"
const DESCRIPTION := "First expression. A shape enters the world."
const FIRE_RATE := 0.5
const SEQUENCE := "primitives"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	proj.speed = 8.0
	proj.lifetime = 4.0
	proj.projectile_scale = 1.0
	proj.color_primary = Color(0.85, 0.85, 0.9)
	proj.color_secondary = Color(0.6, 0.6, 0.65)
	proj.emission_energy = 1.0
	proj.direction = dir
	proj.global_position = pos

	# Override visual to cube instead of sphere
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/primitives_projectile.gd"))
	return proj


# Projectile subclass is defined in primitives_projectile.gd to keep the
# factory pattern clean.  This static class stays lightweight.
