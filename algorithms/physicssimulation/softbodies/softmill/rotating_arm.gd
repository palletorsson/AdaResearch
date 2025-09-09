extends StaticBody3D

# Simple rotating arm configuration
@export var arm_length: float = 3.0
@export var arm_thickness: float = 0.2
@export var rotation_speed: float = 30.0  # degrees per second
@export var push_force: float = 10.0
@export var show_pivot: bool = true  # Toggle to show/hide the pivot point

var arm_mesh: MeshInstance3D
var arm_collision: CollisionShape3D
var pivot_sphere: MeshInstance3D

func _ready():
	create_centered_rotating_arm()

func create_centered_rotating_arm():
	"""Create a rotating arm that rotates from its CENTER with visible pivot"""
	
	# Create the visual arm (box mesh) - CENTERED at origin
	arm_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(arm_length, arm_thickness, arm_thickness)
	arm_mesh.mesh = box_mesh
	
	# KEY CHANGE: Position at Vector3.ZERO so it rotates from center
	arm_mesh.position = Vector3.ZERO  # This makes it rotate from center!
	
	# Create material for the arm
	var arm_material = StandardMaterial3D.new()
	arm_material.albedo_color = Color(1, 0.239216, 1, 1)  # Your pink/magenta color
	arm_material.metallic = 1.0
	arm_material.roughness = 0.0
	arm_mesh.material_override = arm_material
	
	add_child(arm_mesh)
	
	# CREATE PIVOT POINT VISUAL
	if show_pivot:
		pivot_sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = arm_thickness * 1.5  # Slightly bigger than arm thickness
		sphere_mesh.height = sphere_mesh.radius * 2.0
		pivot_sphere.mesh = sphere_mesh
		
		# Position at exact center (origin)
		pivot_sphere.position = Vector3.ZERO
		
		# Create distinctive pivot material
		var pivot_material = StandardMaterial3D.new()
		pivot_material.albedo_color = Color(1, 0.8, 0.2, 1)  # Golden/orange color
		pivot_material.metallic = 0.8
		pivot_material.roughness = 0.1
		pivot_material.emission_enabled = true
		pivot_material.emission = Color(1, 0.6, 0, 1)  # Glowing orange
		pivot_material.emission_energy_multiplier = 0.5
		pivot_sphere.material_override = pivot_material
		
		add_child(pivot_sphere)
	
	# Create collision shape - ALSO CENTERED
	arm_collision = CollisionShape3D.new()
	var collision_shape = BoxShape3D.new()
	collision_shape.size = Vector3(arm_length, arm_thickness, arm_thickness)
	arm_collision.shape = collision_shape
	
	# KEY CHANGE: Position collision at center too
	arm_collision.position = Vector3.ZERO  # Centered collision
	
	add_child(arm_collision)
	
	# Set collision layers
	collision_layer = 2  # Pusher layer
	collision_mask = 0   # StaticBody doesn't need to detect anythingthickness)
	arm_collision.shape = collision_shape
	
	# KEY CHANGE: Position collision at center too
	arm_collision.position = Vector3.ZERO  # Centered collision
	
	add_child(arm_collision)
	
	# Set collision layers
	collision_layer = 2  # Pusher layer
	collision_mask = 0   # StaticBody doesn't need to detect anything

func _physics_process(delta):
	"""Rotate the arm continuously around its center on Z-axis (negative direction)"""
	rotation.z += deg_to_rad(rotation_speed) * delta  # Z-axis, negative direction
