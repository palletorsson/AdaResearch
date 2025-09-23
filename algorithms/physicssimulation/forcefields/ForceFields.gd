extends Node3D

@export var particle_count: int = 80
@export var field_strength: float = 2.0
@export var particle_speed: float = 0.6
@export var drag_coefficient: float = 1.5
@export var buoyancy: float = 0.15
@export var max_speed: float = 2.0
@export var spawn_rate: float = 2.0  # particles per second
@export var max_particles: int = 200
@export var particle_lifetime: float = 8.0  # seconds before removing particles

var fluid_drag_particles: Array[Node3D] = []
var particle_velocity: Array[Vector3] = []
var particle_ages: Array[float] = []

var fluid_drag_center: Node3D

var time: float = 0.0
var spawn_timer: float = 0.0

func _ready() -> void:
	randomize()
	fluid_drag_center = $FluidDragField/FluidDragCenter
	create_particles()

func create_particles() -> void:
	for i in range(particle_count):
		var p: CSGSphere3D = create_particle(Color.GREEN)
		p.position = Vector3(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		$FluidDragField/FluidDragParticles.add_child(p)
		fluid_drag_particles.append(p)
		particle_velocity.append(Vector3.ZERO)
		particle_ages.append(0.0)

func create_particle(color: Color) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = 0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 0.3
	s.material = mat
	return s


func spawn_new_particle() -> void:
	var p: CSGSphere3D = create_particle(Color.GREEN)
	# Spawn particles from random positions around the edges
	var spawn_distance = 8.0
	p.position = Vector3(
		randf_range(-spawn_distance, spawn_distance),
		randf_range(-spawn_distance, spawn_distance),
		randf_range(-spawn_distance, spawn_distance)
	)
	$FluidDragField/FluidDragParticles.add_child(p)
	fluid_drag_particles.append(p)
	particle_velocity.append(Vector3.ZERO)
	particle_ages.append(0.0)

func _process(delta: float) -> void:
	time += delta
	
	# Spawn new particles continuously
	spawn_timer += delta
	if spawn_timer >= 1.0 / spawn_rate and fluid_drag_particles.size() < max_particles:
		spawn_new_particle()
		spawn_timer = 0.0

	# Remove old particles and update ages
	for i in range(fluid_drag_particles.size() - 1, -1, -1):
		particle_ages[i] += delta
		if particle_ages[i] >= particle_lifetime:
			# Remove particle
			fluid_drag_particles[i].queue_free()
			fluid_drag_particles.remove_at(i)
			particle_velocity.remove_at(i)
			particle_ages.remove_at(i)

	# Fluid drag (with turbulence) and buoyant floaty motion
	for i in range(fluid_drag_particles.size()):
		var p: Node3D = fluid_drag_particles[i]
		var v: Vector3 = particle_velocity[i]

		var dir: Vector3 = (fluid_drag_center.global_position - p.global_position)
		var dist: float = max(dir.length(), 0.001)
		dir = dir / dist
		var force: float = field_strength / (dist * dist + 0.1)

		var turbulence: Vector3 = Vector3(
			sin(time + p.position.x) * 0.08,
			cos(time + p.position.y) * 0.08,
			sin(time + p.position.z) * 0.08
		)

		var acceleration: Vector3 = dir * force + turbulence + Vector3(0.0, buoyancy, 0.0)
		v += acceleration * particle_speed * delta

		var damping: float = max(0.0, 1.0 - drag_coefficient * delta)
		v *= damping

		if v.length() > max_speed:
			v = v.normalized() * max_speed

		p.position += v * delta
		particle_velocity[i] = v
