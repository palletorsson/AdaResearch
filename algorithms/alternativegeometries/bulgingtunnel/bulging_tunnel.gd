extends Node3D

# Parameters for tunnel
@export var tunnel_length := 10.0
@export var tunnel_radius := 1.0
@export var num_bulges := 5
@export var bulge_max_radius := 2.0
@export var tunnel_segments := 32
@export var use_random_bulges := true
@export var bulge_seed := 42
@export_color_no_alpha var tunnel_color := Color(0.6, 0.4, 0.3)
@export var metallic := 0.1
@export var roughness := 0.7

# CSG nodes
var csg_root: CSGCombiner3D
var tunnel_base: CSGCylinder3D
var bulges: Array = []

# Called when the node enters the scene tree for the first time
func _ready():
	# Create a CSG root node
	csg_root = CSGCombiner3D.new()
	csg_root.name = "BulgingTunnelCSG"
	csg_root.use_collision = true
	add_child(csg_root)
	
	# Initialize RNG if using random bulges
	if use_random_bulges:
		seed(bulge_seed)
	
	# Create the tunnel
	create_tunnel()
	
	# Apply material to all CSG nodes
	apply_material()

# Creates the main tunnel structure with bulges
func create_tunnel():
	# Create the main tunnel cylinder (oriented along Z-axis)
	tunnel_base = CSGCylinder3D.new()
	tunnel_base.radius = tunnel_radius
	tunnel_base.height = tunnel_length
	tunnel_base.sides = tunnel_segments
	
	# Move the cylinder so its base is at the origin and it extends along positive Z
	tunnel_base.transform.origin = Vector3(0, 0, tunnel_length/2)
	tunnel_base.rotation_degrees.x = 90
	
	csg_root.add_child(tunnel_base)
	
	# Create bulges
	create_bulges()

# Creates the bulging sections of the tunnel
func create_bulges():
	# Calculate spacing between bulges
	var spacing = tunnel_length / (num_bulges + 1)
	
	# Create each bulge
	for i in range(num_bulges):
		# Calculate position along tunnel
		var pos = spacing * (i + 1)
		
		# Create bulge
		var bulge = create_single_bulge(pos)
		csg_root.add_child(bulge)
		bulges.append(bulge)

# Creates a single bulge at the specified position
func create_single_bulge(pos: float) -> CSGSphere3D:
	var bulge = CSGSphere3D.new()
	
	# Set bulge properties
	if use_random_bulges:
		bulge.radius = randf_range(tunnel_radius * 1.2, bulge_max_radius)
	else:
		# Calculate radius that varies sinusoidally along the tunnel
		var t = pos / tunnel_length
		bulge.radius = lerp(tunnel_radius * 1.2, bulge_max_radius, sin(t * PI))
	
	# Position the bulge along the tunnel
	bulge.transform.origin = Vector3(0, 0, pos)
	
	# Set operation to union so bulge adds to the tunnel
	bulge.operation = CSGShape3D.OPERATION_UNION
	
	# Set sufficient detail level
	bulge.radial_segments = tunnel_segments
	bulge.rings = tunnel_segments / 2.0
	
	return bulge

# Apply material to all CSG shapes
func apply_material():
	# Create a new material
	var material = StandardMaterial3D.new()
	material.albedo_color = tunnel_color
	material.metallic = metallic
	material.roughness = roughness
	
	# Apply to base tunnel
	tunnel_base.material = material
	
	# Apply to all bulges
	for bulge in bulges:
		bulge.material = material

# Optional: Expose a function to rebuild the tunnel with new parameters
func rebuild_tunnel():
	# Remove existing bulges
	for bulge in bulges:
		bulge.queue_free()
	bulges.clear()
	
	# Rebuild the tunnel using current parameters
	tunnel_base.radius = tunnel_radius
	tunnel_base.height = tunnel_length
	tunnel_base.transform.origin = Vector3(0, 0, tunnel_length/2)
	
	# Create new bulges
	create_bulges()
	
	# Update material
	apply_material()

# Creates a hollow tunnel (subtract a smaller cylinder from the main one)
func create_hollow_tunnel():
	# Add the main base cylinder first
	create_tunnel()
	
	# Create an inner cylinder to hollow out the tunnel
	var inner_cylinder = CSGCylinder3D.new()
	inner_cylinder.radius = tunnel_radius * 0.8  # Slightly smaller
	inner_cylinder.height = tunnel_length * 1.1  # Slightly longer to ensure complete subtraction
	inner_cylinder.sides = tunnel_segments
	
	# Position it the same as the base tunnel
	inner_cylinder.transform.origin = Vector3(0, 0, tunnel_length/2)
	inner_cylinder.rotation_degrees.x = 90
	
	# Set to subtract operation
	inner_cylinder.operation = CSGShape3D.OPERATION_SUBTRACTION
	
	csg_root.add_child(inner_cylinder)

# Creates a more complex bulging tunnel with multiple shapes
func create_complex_tunnel():
	# Create basic tunnel as foundation
	create_tunnel()
	
	# Add some interesting deformations or additional shapes
	for i in range(num_bulges):
		# Calculate position with offset from regular bulges
		var offset = randf_range(-0.5, 0.5)  # Random offset
		var pos = (tunnel_length / (num_bulges + 1)) * (i + 1) + offset
		
		# Add some variety with different shapes
		var shape_type = randi() % 3
		var shape: CSGShape3D
		
		match shape_type:
			0:  # Add a box deformation
				shape = CSGBox3D.new()
				var box = shape as CSGBox3D
				box.size = Vector3(
					randf_range(tunnel_radius, bulge_max_radius),
					randf_range(tunnel_radius, bulge_max_radius),
					randf_range(tunnel_radius, bulge_max_radius)
				)
			1:  # Add a torus deformation
				shape = CSGTorus3D.new()
				var torus = shape as CSGTorus3D
				torus.inner_radius = tunnel_radius * 0.3
				torus.outer_radius = randf_range(tunnel_radius, bulge_max_radius)
				torus.sides = tunnel_segments / 2.0
				torus.ring_sides = tunnel_segments / 2.0
				torus.rotation_degrees.x = 90  # Orient perpendicular to tunnel
			2:  # Add a cylinder deformation
				shape = CSGCylinder3D.new()
				var cylinder = shape as CSGCylinder3D
				cylinder.radius = randf_range(tunnel_radius * 0.8, bulge_max_radius * 0.8)
				cylinder.height = randf_range(tunnel_radius, tunnel_radius * 2)
				cylinder.sides = tunnel_segments
				cylinder.rotation_degrees.z = 90  # Orient perpendicular to tunnel
		
		# Position and add the shape
		shape.transform.origin = Vector3(0, 0, pos)
		shape.operation = CSGShape3D.OPERATION_UNION
		
		csg_root.add_child(shape)
		
	# Apply material
	apply_material()
