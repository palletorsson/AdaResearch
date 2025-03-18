extends Node3D

# Magnetic simulation parameters
@export var field_size := Vector3(10, 10, 10)
@export var resolution := 16  # Number of points per axis
@export var visualization_scale := 0.5  # Scale of the visualization arrows
@export var field_strength := 2.0  # Overall field strength

# References to the magnets
var magnet1: MagneticObject
var magnet2: MagneticObject

# The flow field visualization
var field_arrows = []
var field_points = []

func _ready():
	# Create the magnetic objects
	magnet1 = $pickMe_1/MagneticObject1
	magnet2 = $pickMe_2/MagneticObject2
	
	# Initialize the field visualization
	create_field_visualization()
	
	# Update the field initially
	update_field()

func _process(delta):
	# Update the field every frame
	update_field()

func create_field_visualization():
	# Create a 3D grid of arrows to represent the field
	var step = field_size / resolution
	
	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				# Calculate the position
				var pos = Vector3(
					x * step.x - field_size.x / 2 + step.x / 2,
					y * step.y - field_size.y / 2 + step.y / 2,
					z * step.z - field_size.z / 2 + step.z / 2
				)
				
				# Create an arrow to represent the field at this point
				var arrow = create_arrow()
				arrow.position = pos
				add_child(arrow)
				field_arrows.append(arrow)
				field_points.append(pos)

func create_arrow() -> MeshInstance3D:
	# Create a simple arrow mesh
	var arrow = MeshInstance3D.new()
	
	# Create a cone mesh for the arrow head
	var arrow_mesh = CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.05
	arrow_mesh.height = 0.2
	
	# Create a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 1.0)
	material.metallic = 0.8
	material.roughness = 0.1
	
	arrow_mesh.material = material
	arrow.mesh = arrow_mesh
	
	# Adjust the orientation
	arrow.rotation_degrees.x = -90
	
	return arrow

func update_field():
	# Calculate the magnetic field at each point and update the arrows
	for i in range(field_arrows.size()):
		var point = field_points[i]
		
		# Get the current world position of the magnets
		var magnet1_pos = magnet1.global_position
		var magnet2_pos = magnet2.global_position
		
		# Calculate field vector using the world positions
		var field_vector = calculate_magnetic_field(point, magnet1_pos, magnet2_pos)
		
		# Skip if field is very weak
		if field_vector.length() < 0.001:
			field_arrows[i].visible = false
			continue
		
		field_arrows[i].visible = true
		
		# Scale the arrow based on field strength
		var field_magnitude = field_vector.length()
		field_arrows[i].scale = Vector3(1, field_magnitude * visualization_scale, 1)
		
		# Point the arrow in the direction of the field
		if field_magnitude > 0:
			var look_dir = field_vector.normalized()
			if look_dir.length() > 0:
				field_arrows[i].look_at(field_arrows[i].position + look_dir, Vector3.UP)

func calculate_magnetic_field(point: Vector3, magnet1_pos: Vector3, magnet2_pos: Vector3) -> Vector3:
	# Implementation based on the magnetic dipole formula
	var field = Vector3.ZERO
	
	# Contribution from magnet1
	var r1 = point - magnet1_pos
	var r1_mag = r1.length()
	if r1_mag > 0.001:  # Avoid division by zero
		var m1 = magnet1.get_magnetic_moment()
		var r1_norm = r1.normalized()
		field += (3 * r1_norm * r1_norm.dot(m1) - m1) / pow(r1_mag, 3)
	
	# Contribution from magnet2
	var r2 = point - magnet2_pos
	var r2_mag = r2.length()
	if r2_mag > 0.001:  # Avoid division by zero
		var m2 = magnet2.get_magnetic_moment()
		var r2_norm = r2.normalized()
		field += (3 * r2_norm * r2_norm.dot(m2) - m2) / pow(r2_mag, 3)
	
	# Scale the field for better visualization
	return field * field_strength

# Helper method to clear the current field
func clear_field():
	for arrow in field_arrows:
		arrow.queue_free()
	field_arrows.clear()
	field_points.clear()
	
# Method to adjust the field resolution
func set_resolution(new_resolution: int):
	resolution = new_resolution
	clear_field()
	create_field_visualization()
