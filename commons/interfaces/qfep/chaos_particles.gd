# chaos_particles.gd
# QFEP λ=1 Visualization - Dissolution Zone
# Maximum entropy: particles exploding outward, no coherence
# The death of pattern, pure noise

extends Node3D

class_name QFEPChaosParticles

## Particle count (high for chaos)
@export var particle_count: int = 300

## Emission radius
@export var emission_radius: float = 0.3

## Explosion speed
@export var speed_min: float = 1.0
@export var speed_max: float = 3.0

## Particle lifetime (short = fast turnover)
@export var lifetime: float = 2.0

## Dissolution color (hot red/orange)
@export var dissolution_color: Color = Color(1.0, 0.3, 0.1, 1.0)

# Internal
var _particles: GPUParticles3D
var _material: ParticleProcessMaterial

func _ready() -> void:
	_build_particles()

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = particle_count
	_particles.lifetime = lifetime
	_particles.explosiveness = 0.3  # Some bursting
	_particles.randomness = 1.0
	
	# Process material - DISSOLUTION settings
	_material = ParticleProcessMaterial.new()
	
	# Emission from center point
	_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_material.emission_sphere_radius = emission_radius
	
	# Exploding outward in all directions
	_material.direction = Vector3(0, 0, 0)
	_material.spread = 180.0
	
	# High velocity - dissolution
	_material.initial_velocity_min = speed_min
	_material.initial_velocity_max = speed_max
	
	# Slight upward drift (heat rising)
	_material.gravity = Vector3(0, 0.5, 0)
	
	# Scale - start big, shrink to nothing (dissolving)
	_material.scale_min = 0.3
	_material.scale_max = 1.5
	
	# Scale curve - shrink over lifetime
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0, 1.0))
	scale_curve.add_point(Vector2(0.5, 0.7))
	scale_curve.add_point(Vector2(1, 0.0))
	var scale_curve_texture = CurveTexture.new()
	scale_curve_texture.curve = scale_curve
	_material.scale_curve = scale_curve_texture
	
	# Color - fade from hot to cold
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, dissolution_color)
	color_ramp.add_point(0.5, Color(0.8, 0.2, 0.1, 0.7))
	color_ramp.add_point(1.0, Color(0.3, 0.1, 0.1, 0.0))
	var color_texture = GradientTexture1D.new()
	color_texture.gradient = color_ramp
	_material.color_ramp = color_texture
	
	# Angular velocity - spinning wildly
	_material.angular_velocity_min = -720.0
	_material.angular_velocity_max = 720.0
	
	# Damping - slow down over time
	_material.damping_min = 0.5
	_material.damping_max = 2.0
	
	_particles.process_material = _material
	
	# Particle mesh - small cubes (dissolving structure)
	var particle_mesh = BoxMesh.new()
	particle_mesh.size = Vector3(0.03, 0.03, 0.03)
	_particles.draw_pass_1 = particle_mesh
	
	# Material with glow
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = dissolution_color
	mesh_mat.emission_enabled = true
	mesh_mat.emission = dissolution_color
	mesh_mat.emission_energy_multiplier = 2.0
	particle_mesh.material = mesh_mat
	
	add_child(_particles)

## Trigger a dissolution burst
func burst() -> void:
	if _particles:
		_particles.explosiveness = 1.0
		_particles.restart()
		await get_tree().create_timer(0.2).timeout
		_particles.explosiveness = 0.3

## Set dissolution intensity
func set_intensity(value: float) -> void:
	if _material:
		_material.initial_velocity_max = lerp(speed_min, speed_max * 2, value)
	if _particles:
		_particles.amount = int(lerp(100, particle_count * 2, value))
