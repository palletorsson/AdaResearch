# ModeFractal.gd
# Mode 7 — "One Becomes Many"
# Splitting self-similar projectiles.  Boundary dissolution.
class_name CatalystModeFractal

const MODE_ID := "fractal"
const MODE_NAME := "Fractal"
const DESCRIPTION := "One becomes many. Boundary dissolution."
const FIRE_RATE := 0.6
const SEQUENCE := "fractals"

static func create_projectile(pos: Vector3, dir: Vector3, depth: int = 0) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	var scale_factor := pow(0.6, depth)
	proj.speed = 11.0
	proj.lifetime = 3.5
	proj.projectile_scale = scale_factor
	# Hue shifts with each generation
	var hue := fmod(0.6 + depth * 0.12, 1.0)
	proj.color_primary = Color.from_hsv(hue, 0.7, 1.0)
	proj.color_secondary = Color.from_hsv(fmod(hue + 0.1, 1.0), 0.5, 0.8)
	proj.emission_energy = 1.8
	proj.direction = dir
	proj.global_position = pos
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/fractal_projectile.gd"))
	# Store depth for split logic
	proj.set_meta("fractal_depth", depth)
	return proj
