extends Node3D

# Configuration for the tulip arrangement
@export var tulip_count: int = 15
@export var bucket_radius: float = 0.4
@export var bucket_height: float = 0.3
@export var color_variation: bool = true

# Arrays to store references
var tulips = []
var tulip_positions = []

func _ready():
	# Create the bucket and tulips
	create_bucket()
	create_tulips()

func create_bucket():
	# Create the bucket container
	var bucket = MeshInstance3D.new()
	bucket.name = "FlowerBucket"
	
	# Use a cylinder mesh for the bucket
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = bucket_radius
	cylinder.bottom_radius = bucket_radius * 0.8
	cylinder.height = bucket_height
	
	# Add some segments for detail
	cylinder.radial_segments = 16
	cylinder.rings = 4
	
	bucket.mesh = cylinder
	
	# Create bucket material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.2)  # Dark gray bucket
	material.metallic = 0.8
	material.roughness = 0.3
	bucket.material_override = material
	
	# Add bucket handle
	create_bucket_handle(bucket)
	
	# Add collision shape for the bucket
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = bucket_radius
	shape.height = bucket_height
	collision.shape = shape
	static_body.add_child(collision)
	bucket.add_child(static_body)
	
	# Add to scene
	add_child(bucket)

func create_bucket_handle(bucket):
	# Create handle for the bucket
	var handle = MeshInstance3D.new()
	handle.name = "BucketHandle"
	
	# Create a curved handle using a torus slice
	var torus = TorusMesh.new()
	torus.inner_radius = 1.1
	torus.outer_radius = bucket_radius * 1.2
	handle.mesh = torus
	
	# Position the handle
	handle.rotation_degrees.x = 0  # Rotate to correct orientation
	handle.position.y = bucket_height * 0.6  # Position above bucket
	
	# Create handle material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.15, 0.15)  # Darker gray for handle
	material.metallic = 0.9
	material.roughness = 0.2
	handle.material_override = material
	
	# Add to bucket
	bucket.add_child(handle)

func create_tulips():
	# Generate a few tulip templates to clone
	var tulip_templates = []
	
	# Create a few different tulip styles
	for i in range(3):
		var template = create_tulip_template(i)
		tulip_templates.append(template)
	
	# Generate positions for tulips
	generate_tulip_positions()
	
	# Create each tulip in the arrangement
	for i in range(tulip_count):
		# Choose a random template
		var template_index = randi() % tulip_templates.size()
		var tulip = tulip_templates[template_index].duplicate()
		
		# Randomize tulip
		randomize_tulip(tulip, i)
		
		# Add to scene
		add_child(tulip)
		tulips.append(tulip)

func create_tulip_template(style_index):
	# Create a tulip base node
	var tulip = Node3D.new()
	tulip.name = "Tulip"
	
	# Create stem
	create_tulip_stem(tulip)
	
	# Create flower head based on style
	match style_index:
		0: create_tulip_flower_closed(tulip)
		1: create_tulip_flower_open(tulip)
		2: create_tulip_flower_drooping(tulip)
	
	# Add leaves
	create_tulip_leaves(tulip)
	
	return tulip

func create_tulip_stem(tulip):
	# Create the stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	# Use a cylinder for the stem
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.015
	cylinder.height = 0.5
	cylinder.radial_segments = 8
	stem.mesh = cylinder
	
	# Position stem
	stem.position.y = cylinder.height / 2
	
	# Create stem material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.2)  # Green stem
	stem.material_override = material
	
	# Add to tulip
	tulip.add_child(stem)

func create_tulip_flower_closed(tulip):
	# Create a closed tulip flower (pointed)
	var flower = MeshInstance3D.new()
	flower.name = "FlowerHead"
	
	# Create a tall cone for closed tulip
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.05
	cone.height = 0.12
	cone.radial_segments = 6
	flower.mesh = cone
	
	# Position flower on top of stem
	flower.position.y = 0.5  # Stem height
	
	# Create petal material (will be randomized later)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.2, 0.2)  # Default red
	flower.material_override = material
	
	# Add to tulip
	tulip.add_child(flower)

func create_tulip_flower_open(tulip):
	# Create an open tulip flower
	var flower = Node3D.new()
	flower.name = "FlowerHead"
	
	# Create 6 petals for an open tulip
	var petal_material = StandardMaterial3D.new()
	petal_material.albedo_color = Color(0.9, 0.5, 0.1)  # Default orange
	
	for i in range(6):
		var petal = MeshInstance3D.new()
		petal.name = "Petal_" + str(i)
		
		# Create curved petal shape
		var curve_surface = SphereMesh.new()
		curve_surface.radius = 0.06
		curve_surface.height = 0.12
		# Slice to get petal shape
		curve_surface.radial_segments = 8
		curve_surface.rings = 4
		petal.mesh = curve_surface
		
		# Position and rotate petal
		var angle = (2.0 * PI / 6) * i
		petal.position = Vector3(cos(angle) * 0.03, 0.5, sin(angle) * 0.03)  # Arrange in circle
		petal.rotation = Vector3(0.3, angle, 0.8)  # Tilt outward
		
		# Use shared material
		petal.material_override = petal_material
		
		# Add to flower
		flower.add_child(petal)
	
	# Add to tulip
	tulip.add_child(flower)

func create_tulip_flower_drooping(tulip):
	# Create a tulip with drooping flower
	var flower = MeshInstance3D.new()
	flower.name = "FlowerHead"
	
	# Create a bell shape for drooping tulip
	var bell = CapsuleMesh.new()
	bell.radius = 0.05
	bell.height = 0.15
	flower.mesh = bell
	
	# Position flower on top of stem, with droop
	flower.position.y = 0.5  # Stem height
	flower.rotation_degrees.x = 60  # Droop angle
	
	# Create petal material (will be randomized later)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0, 0.5)  # Default purple
	flower.material_override = material
	
	# Add to tulip
	tulip.add_child(flower)

func create_tulip_leaves(tulip):
	# Add 1-2 leaves to the tulip stem
	var leaf_count = 1 + randi() % 2  # 1 or 2 leaves
	
	for i in range(leaf_count):
		var leaf = MeshInstance3D.new()
		leaf.name = "Leaf_" + str(i)
		
		# Create an elongated prism for the leaf
		var prism = PrismMesh.new()
		prism.size = Vector3(0.2, 0.02, 0.05)
		leaf.mesh = prism
		
		# Position leaf along stem
		var height = 0.1 + (i * 0.15)  # Space out multiple leaves
		leaf.position.y = height
		
		# Randomize rotation around stem
		var angle = randf() * PI * 2
		leaf.rotation_degrees.y = rad_to_deg(angle)
		
		# Angle leaf upward
		leaf.rotation_degrees.z = 30
		
		# Create leaf material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.55, 0.2)  # Green leaf
		leaf.material_override = material
		
		# Add to tulip
		tulip.add_child(leaf)

func generate_tulip_positions():
	# Generate positions for tulips within the bucket
	for i in range(tulip_count):
		# Random position within bucket
		var angle = randf() * PI * 2
		var radius = randf() * bucket_radius * 0.8  # Keep within bucket
		
		var pos_x = cos(angle) * radius
		var pos_z = sin(angle) * radius
		
		# Bottom of bucket
		var pos_y = -bucket_height / 2
		
		tulip_positions.append(Vector3(pos_x, pos_y, pos_z))

func randomize_tulip(tulip, index):
	# Position the tulip
	tulip.position = tulip_positions[index]
	
	# Randomize height slightly
	tulip.position.y += randf() * 0.05
	
	# Randomize scale (height variation)
	var scale_factor = 0.85 + randf() * 0.3  # 0.85 to 1.15
	tulip.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Randomize rotation (slight lean)
	var lean_angle_x = (randf() * 2 - 1) * 10  # -10 to 10 degrees
	var lean_angle_z = (randf() * 2 - 1) * 10  # -10 to 10 degrees
	tulip.rotation_degrees = Vector3(lean_angle_x, randf() * 360, lean_angle_z)
	
	# Randomize flower color if enabled
	if color_variation:
		randomize_flower_color(tulip)

func randomize_flower_color(tulip):
	# Find the flower head
	var flower_head = tulip.get_node("FlowerHead")
	
	if flower_head is MeshInstance3D:
		# Single flower head (closed or drooping)
		var material = flower_head.material_override
		if material is StandardMaterial3D:
			material.albedo_color = get_random_tulip_color()
	else:
		# Multiple petals (open flower)
		for child in flower_head.get_children():
			if "Petal" in child.name:
				var material = child.material_override
				if material is StandardMaterial3D:
					material.albedo_color = get_random_tulip_color()

func get_random_tulip_color():
	# Generate common tulip colors
	var colors = [
		Color(0.9, 0.1, 0.1),  # Red
		Color(0.9, 0.5, 0.1),  # Orange
		Color(0.9, 0.9, 0.1),  # Yellow
		Color(0.8, 0.0, 0.5),  # Purple
		Color(0.9, 0.5, 0.5),  # Pink
		Color(1.0, 1.0, 1.0),  # White
	]
	
	# Pick a random color
	var color_index = randi() % colors.size()
	
	# Add slight variation to the chosen color
	var chosen_color = colors[color_index]
	chosen_color.r += (randf() * 0.1 - 0.05)
	chosen_color.g += (randf() * 0.1 - 0.05)
	chosen_color.b += (randf() * 0.1 - 0.05)
	
	# Clamp values
	chosen_color.r = clamp(chosen_color.r, 0, 1)
	chosen_color.g = clamp(chosen_color.g, 0, 1)
	chosen_color.b = clamp(chosen_color.b, 0, 1)
	
	return chosen_color
