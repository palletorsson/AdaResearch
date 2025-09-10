extends Node3D

# Dynamic Cylinder Connector
# Add this script to your Doublestick scene to create a cylinder between ForceOne and ForceTwo

@export var cylinder_radius: float = 0.02
@export var cylinder_transparency: float = 0.6
@export var cylinder_color: Color = Color.WHITE
@export var update_frequency: float = 0.016  # 60 FPS

var connecting_cylinder: MeshInstance3D
var cylinder_material: StandardMaterial3D
var force_one: MeshInstance3D
var force_two: MeshInstance3D
var update_timer: Timer

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	setup_connector()
	setup_update_timer()

func setup_connector():
	# Find ForceOne and ForceTwo nodes
	force_one = find_child("ForceOne")
	force_two = find_child("ForceTwo")
	
	if not force_one or not force_two:
		print("Error: Could not find ForceOne or ForceTwo nodes")
		return
	
	# Create cylinder mesh
	connecting_cylinder = MeshInstance3D.new()
	connecting_cylinder.name = "ConnectingCylinder"
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = cylinder_radius
	cylinder_mesh.bottom_radius = cylinder_radius
	cylinder_mesh.height = 1.0  # Will be scaled dynamically
	
	connecting_cylinder.mesh = cylinder_mesh
	
	# Create transparent material
	cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = Color(cylinder_color.r, cylinder_color.g, cylinder_color.b, 1.0 - cylinder_transparency)
	cylinder_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cylinder_material.metallic = 0.2
	cylinder_material.roughness = 0.8
	
	connecting_cylinder.material_override = cylinder_material
	
	# Add to scene
	add_child(connecting_cylinder)
	
	# Initial update
	update_cylinder()

func setup_update_timer():
	update_timer = Timer.new()
	update_timer.wait_time = update_frequency
	update_timer.timeout.connect(update_cylinder)
	update_timer.autostart = true
	add_child(update_timer)

func update_cylinder():
	if not connecting_cylinder or not force_one or not force_two:
		return
	
	# Get global positions of both force points
	var pos_one = force_one.global_position
	var pos_two = force_two.global_position
	
	# Calculate distance and midpoint
	var distance = pos_one.distance_to(pos_two)
	var midpoint = (pos_one + pos_two) * 0.5
	
	# Position cylinder at midpoint
	connecting_cylinder.global_position = midpoint
	
	# Scale cylinder to match distance
	connecting_cylinder.scale = Vector3(1.0, distance, 1.0)
	
	# Orient cylinder to point from one force to the other
	var direction = (pos_two - pos_one).normalized()
	if direction.length() > 0.001:  # Avoid division by zero
		connecting_cylinder.look_at(pos_two, Vector3.UP)
		# Rotate 90 degrees around X axis since cylinder points up by default
		connecting_cylinder.rotate_object_local(Vector3.RIGHT, PI/2)

func set_cylinder_color(color: Color):
	cylinder_color = color
	if cylinder_material:
		cylinder_material.albedo_color = Color(color.r, color.g, color.b, 1.0 - cylinder_transparency)

func set_cylinder_transparency(transparency: float):
	cylinder_transparency = clamp(transparency, 0.0, 1.0)
	if cylinder_material:
		cylinder_material.albedo_color.a = 1.0 - cylinder_transparency

func set_cylinder_radius(radius: float):
	cylinder_radius = radius
	if connecting_cylinder and connecting_cylinder.mesh:
		connecting_cylinder.mesh.top_radius = radius
		connecting_cylinder.mesh.bottom_radius = radius

func set_update_rate(frequency: float):
	update_frequency = frequency
	if update_timer:
		update_timer.wait_time = frequency
