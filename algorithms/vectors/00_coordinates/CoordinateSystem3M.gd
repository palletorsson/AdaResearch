@tool
extends Node3D

# Coordinate System Visualization
# Illustrates X, Y, Z axes with 3m length.

@export var axis_length: float = 3.0
@export var axis_thickness: float = 0.02 # Thinner lines

func _ready():
	# Clear existing children to avoid duplication if running in tool mode updates
	for child in get_children():
		child.queue_free()
		
	create_axis(Vector3.RIGHT, Color.RED, "X")
	create_axis(Vector3.UP, Color.GREEN, "Y")
	create_axis(Vector3.BACK, Color.BLUE, "Z")

func create_axis(direction: Vector3, color: Color, label_text: String):
	# 1. The Shaft (Cylinder)
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = axis_thickness
	mesh.bottom_radius = axis_thickness
	mesh.height = axis_length
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Transparency settings
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.5 # 50% Transparent
	
	mesh_instance.material_override = material
	
	# Position: The cylinder is centered at (0,0,0) by default.
	# We want it to start at (0,0,0) and go to direction * length.
	# So center should be at direction * (length / 2).
	mesh_instance.position = direction * (axis_length / 2.0)
	
	# Orientation: Cylinder is Y-aligned by default.
	# We need to rotate it to match 'direction'.
	if direction != Vector3.UP:
		var up = Vector3.UP
		var axis = up.cross(direction).normalized()
		var angle = up.angle_to(direction)
		mesh_instance.rotate(axis, angle)
		
	add_child(mesh_instance)
	
	# 2. The Tip (Cone)
	var cone_instance = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = axis_thickness * 2.5
	cone.height = axis_thickness * 4.0
	cone_instance.mesh = cone
	cone_instance.material_override = material
	
	cone_instance.position = direction * axis_length
	if direction != Vector3.UP:
		var up = Vector3.UP
		var axis = up.cross(direction).normalized()
		var angle = up.angle_to(direction)
		cone_instance.rotate(axis, angle)
		
	add_child(cone_instance)
	
	# 3. The Label (Label3D)
	var label = Label3D.new()
	label.text = label_text
	label.modulate = color
	label.font_size = 64
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = direction * (axis_length + 0.2)
	add_child(label)
