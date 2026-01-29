# edge_core.gd
# QFEP Edge of Chaos Core - Central Visualization
# The heart of the edge of chaos: λ ≈ 0.4
# Alive, pulsing, dancing - where complexity emerges

extends Node3D

class_name QFEPEdgeCore

## Core size
@export var core_radius: float = 0.4

## Pulse parameters
@export var pulse_speed: float = 1.0
@export var pulse_amount: float = 0.1

## Rotation speed
@export var rotation_speed: float = 0.3

## Particle ring
@export var ring_particles: int = 100

## Edge color (green = life)
@export var edge_color: Color = Color(0.2, 0.9, 0.4, 1.0)

# Internal
var _core_mesh: MeshInstance3D
var _core_material: StandardMaterial3D
var _inner_mesh: MeshInstance3D
var _particles: GPUParticles3D
var _time: float = 0.0

func _ready() -> void:
	_build_core()
	_build_inner()
	_build_ring_particles()
	add_to_group("qfep_visualizations")

func _build_core() -> void:
	# Outer translucent sphere
	_core_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = core_radius
	sphere.height = core_radius * 2
	sphere.radial_segments = 32
	sphere.rings = 16
	_core_mesh.mesh = sphere
	
	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = Color(edge_color.r, edge_color.g, edge_color.b, 0.3)
	_core_material.emission_enabled = true
	_core_material.emission = edge_color
	_core_material.emission_energy_multiplier = 1.0
	_core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_core_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_core_mesh.material_override = _core_material
	
	add_child(_core_mesh)

func _build_inner() -> void:
	# Inner bright core
	_inner_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = core_radius * 0.4
	sphere.height = core_radius * 0.8
	_inner_mesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = edge_color
	mat.emission_energy_multiplier = 3.0
	_inner_mesh.material_override = mat
	
	add_child(_inner_mesh)

func _build_ring_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = ring_particles
	_particles.lifetime = 3.0
	
	var mat = ParticleProcessMaterial.new()
	
	# Emit in a ring around the core
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_axis = Vector3(0, 1, 0)
	mat.emission_ring_height = 0.1
	mat.emission_ring_inner_radius = core_radius * 0.8
	mat.emission_ring_radius = core_radius * 1.2
	
	# Orbit around (tangential velocity)
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.4
	
	# Gentle float
	mat.gravity = Vector3(0, 0.1, 0)
	
	# Color
	mat.color = edge_color
	
	# Scale
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	
	_particles.process_material = mat
	
	# Particle mesh
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.015
	particle_mesh.height = 0.03
	_particles.draw_pass_1 = particle_mesh
	
	# Glow material
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = edge_color
	mesh_mat.emission_enabled = true
	mesh_mat.emission = edge_color
	mesh_mat.emission_energy_multiplier = 2.0
	particle_mesh.material = mesh_mat
	
	add_child(_particles)

func _process(delta: float) -> void:
	_time += delta
	
	# Pulse the core
	var pulse = 1.0 + sin(_time * pulse_speed * TAU) * pulse_amount
	_core_mesh.scale = Vector3.ONE * pulse
	
	# Counter-pulse inner
	var inner_pulse = 1.0 + sin(_time * pulse_speed * TAU + PI) * pulse_amount * 2
	_inner_mesh.scale = Vector3.ONE * inner_pulse
	
	# Rotate everything slowly
	rotation.y += delta * rotation_speed
	
	# Vary emission intensity
	var emission_pulse = 1.0 + sin(_time * pulse_speed * 2 * TAU) * 0.5
	_core_material.emission_energy_multiplier = emission_pulse

## React to lambda value
func set_lambda(value: float) -> void:
	# Color shifts based on how close to edge (0.4)
	var distance_from_edge = abs(value - 0.4)
	var edge_factor = 1.0 - clamp(distance_from_edge * 3, 0, 1)
	
	# More alive at the edge
	pulse_speed = lerp(0.3, 2.0, edge_factor)
	pulse_amount = lerp(0.02, 0.2, edge_factor)
	
	# Color: green at edge, blue/red away
	var color: Color
	if value < 0.4:
		color = Color(0.2, 0.4, 0.9).lerp(edge_color, edge_factor)  # Blue → Green
	else:
		color = edge_color.lerp(Color(0.9, 0.2, 0.2), 1.0 - edge_factor)  # Green → Red
	
	_core_material.emission = color
	_core_material.albedo_color = Color(color.r, color.g, color.b, 0.3)

## Pulse effect
func pulse() -> void:
	var tween = create_tween()
	tween.tween_property(_core_mesh, "scale", Vector3.ONE * 1.5, 0.1)
	tween.tween_property(_core_mesh, "scale", Vector3.ONE, 0.3)
