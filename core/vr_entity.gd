class_name VREntity
extends Node3D

## Base class for all VR interactive objects in Nature of Code examples
## Handles physics properties, visualization, and tank constraints

# Physics properties
var position_v: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var mass: float = 1.0

# Visual representation
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

# Pink color palette
var primary_pink: Color = Color(1.0, 0.7, 0.9, 1.0)    # Light pink
var secondary_pink: Color = Color(0.9, 0.5, 0.8, 1.0)  # Medium pink
var accent_pink: Color = Color(1.0, 0.6, 1.0, 1.0)     # Bright pink

# Lifespan (for particles)
var lifespan: float = -1.0  # -1 = infinite
var max_lifespan: float = 1.0

# Tank reference
var fish_tank: FishTank = null

func _ready():
	setup_mesh()
	setup_material()
	find_fish_tank()

func find_fish_tank():
	"""Find FishTank parent in scene tree"""
	var node = get_parent()
	while node:
		if node is FishTank:
			fish_tank = node
			return
		node = node.get_parent()

func setup_mesh():
	"""Override in subclasses to create custom mesh"""
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	mesh_instance.mesh = sphere
	add_child(mesh_instance)

func setup_material():
	"""Setup pink material with emission glow"""
	material = StandardMaterial3D.new()
	material.albedo_color = primary_pink
	material.emission_enabled = true
	material.emission = primary_pink * 0.5
	material.emission_energy_multiplier = 0.8
	material.metallic = 0.7
	material.roughness = 0.1

	if mesh_instance:
		mesh_instance.material_override = material

func _physics_process(delta):
	update_motion(delta)
	update_lifespan(delta)
	update_transform()
	check_boundaries()

func apply_force(force: Vector3):
	"""Apply force using F = ma"""
	acceleration += force / mass

func update_motion(delta: float):
	"""Update position based on velocity and acceleration"""
	velocity += acceleration * delta
	position_v += velocity * delta
	acceleration = Vector3.ZERO  # Reset acceleration each frame

func update_lifespan(delta: float):
	"""Update lifespan for particles"""
	if lifespan > 0:
		lifespan -= delta

		# Fade out based on lifespan
		if max_lifespan > 0:
			var alpha = lifespan / max_lifespan
			if material:
				var color = material.albedo_color
				material.albedo_color = Color(color.r, color.g, color.b, alpha)

func update_transform():
	"""Update Godot transform from position_v"""
	position = position_v

func check_boundaries():
	"""Override in subclasses for custom boundary behavior"""
	if fish_tank:
		position_v = fish_tank.constrain_position(position_v)

func is_dead() -> bool:
	"""Check if entity should be removed"""
	return lifespan > 0 and lifespan <= 0

func set_color(color: Color):
	"""Set entity color"""
	if material:
		material.albedo_color = color
		material.emission = color * 0.5

func attract(other: VREntity) -> Vector3:
	"""Calculate gravitational attraction force to another entity"""
	var force = position_v - other.position_v
	var distance = force.length()
	distance = clamp(distance, 5.0, 100.0)  # Constrain for stability

	var G: float = 1.0  # Gravitational constant
	var strength = (G * mass * other.mass) / (distance * distance)
	force = force.normalized() * strength
	return force

func repel(other: VREntity, max_distance: float = 25.0) -> Vector3:
	"""Calculate repulsion force from another entity"""
	var force = position_v - other.position_v
	var distance = force.length()

	if distance > 0 and distance < max_distance:
		var strength = 1.0 / distance
		force = force.normalized() * strength
		return force

	return Vector3.ZERO
