# ModeChaos.gd
# Mode 6 — "Embrace Disorder"
# Random direction, random impulses.  Letting go of the trajectory.
# Queer as uncontainable — you cannot predict where this goes.
class_name CatalystModeChaos

const MODE_ID := "chaos"
const MODE_NAME := "Chaos"
const DESCRIPTION := "Embrace disorder. Let go of the trajectory."
const FIRE_RATE := 0.3
const SEQUENCE := "randomness"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	proj.speed = 12.0
	proj.lifetime = 3.5
	proj.projectile_scale = 0.8
	proj.color_primary = Color(0.9, 0.2, 0.5)
	proj.color_secondary = Color(0.7, 0.1, 0.6)
	proj.emission_energy = 2.0
	# Random deviation within 45° cone
	var random_dir := dir.normalized()
	random_dir = random_dir.rotated(Vector3.UP, randf_range(-0.4, 0.4))
	random_dir = random_dir.rotated(Vector3.RIGHT, randf_range(-0.4, 0.4))
	proj.direction = random_dir
	proj.global_position = pos
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/chaos_projectile.gd"))
	return proj
