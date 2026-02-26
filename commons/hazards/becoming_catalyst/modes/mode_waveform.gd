# ModeWaveform.gd
# Mode 5 — "Neither Particle nor Wave"
# Sinusoidal/helix trajectory.  Wave-particle duality as identity.
class_name CatalystModeWaveform

const MODE_ID := "waveform"
const MODE_NAME := "Waveform"
const DESCRIPTION := "Neither particle nor wave. Both."
const FIRE_RATE := 0.35
const SEQUENCE := "wavefunctions"

static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
	var proj := CatalystProjectile.new()
	proj.speed = 13.0
	proj.lifetime = 4.0
	proj.projectile_scale = 0.85
	proj.color_primary = Color(0.3, 0.85, 0.85)
	proj.color_secondary = Color(0.2, 0.6, 0.8)
	proj.emission_energy = 1.8
	proj.direction = dir
	proj.global_position = pos
	proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/waveform_projectile.gd"))
	return proj
