# particle_chaos.gd
# QFEP E(S) Term Visualization - Chaotic Particle System
# High entropy: maximum spread, random velocities, no coherence
# λ = 1 dissolution zone

extends Node3D

class_name QFEPParticleChaos

# @identity
# essence: GPU_particles(spread=180, gravity=0, angular_velocity=+-360) -> pure entropy cloud
# desire: be surrounded by particles that obey no pattern — feel the freedom of maximum entropy
# critical_parameter: spread (180 = full sphere) — the absence of preferred direction that defines chaos
# triggers: set_intensity() scales velocity and count; pulse() creates momentary burst
# emerges: transient clusters and voids in the noise — the eye finds patterns even where none exist
# needs: VR intensity control [missing], pulse trigger [missing]
# relationships: represents E(S) term; contrasts ordered_grid (F term); paired with random_cubes; feeds into lambda spectrum
# truth: entropy is not disorder but possibility — maximum spread means maximum freedom from constraint

## Particle count
@export var particle_count: int = 200

## Emission radius
@export var emission_radius: float = 0.5

## Particle speed range
@export var speed_min: float = 0.5
@export var speed_max: float = 2.0

## Particle lifetime
@export var lifetime: float = 3.0

## Chaos color (red = entropy)
@export var chaos_color: Color = Color(0.9, 0.2, 0.2, 1.0)

# Internal
var _particles: GPUParticles3D
var _material: ParticleProcessMaterial

func _ready() -> void:
	_build_particles()

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = particle_count
	_particles.lifetime = lifetime
	_particles.explosiveness = 0.0  # Continuous emission
	_particles.randomness = 1.0  # Maximum randomness
	
	# Process material - CHAOS settings
	_material = ParticleProcessMaterial.new()
	
	# Emission from sphere
	_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_material.emission_sphere_radius = emission_radius
	
	# Random directions - full sphere spread
	_material.direction = Vector3(0, 0, 0)  # No preferred direction
	_material.spread = 180.0  # Full sphere
	
	# Velocity - chaotic range
	_material.initial_velocity_min = speed_min
	_material.initial_velocity_max = speed_max
	
	# No gravity - pure chaos
	_material.gravity = Vector3(0, 0, 0)
	
	# Random acceleration for turbulence
	_material.attractor_interaction_enabled = false
	
	# Scale variation
	_material.scale_min = 0.5
	_material.scale_max = 2.0
	
	# Color - red chaos with fade
	_material.color = chaos_color
	
	# Angular velocity - spinning particles
	_material.angular_velocity_min = -360.0
	_material.angular_velocity_max = 360.0
	
	_particles.process_material = _material
	
	# Particle mesh - small spheres
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.02
	particle_mesh.height = 0.04
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	_particles.draw_pass_1 = particle_mesh
	
	# Particle material with glow
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = chaos_color
	mesh_mat.emission_enabled = true
	mesh_mat.emission = chaos_color
	mesh_mat.emission_energy_multiplier = 1.5
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_mesh.material = mesh_mat
	
	add_child(_particles)

## Set chaos intensity (0-1)
func set_intensity(value: float) -> void:
	if _material:
		_material.initial_velocity_max = lerp(speed_min, speed_max * 2, value)
		_material.spread = lerp(90.0, 180.0, value)
	if _particles:
		_particles.amount = int(lerp(50, particle_count * 2, value))

## Pulse the chaos
func pulse() -> void:
	if _particles:
		_particles.explosiveness = 0.8
		await get_tree().create_timer(0.1).timeout
		_particles.explosiveness = 0.0
