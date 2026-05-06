extends Node3D

# @identity
# essence: three labeled CSGCylinder3D axes (X=red, Y=green, Z=blue) assembled into a pickable coordinate reference object that the player can hold in their hand
# desire: to hold space in your hand — to pick up the XYZ gadget and reorient it until you understand that X, Y, and Z are directions relative to you, not absolute truths about the world
# critical_parameter: initial_scale — at 3.2x the gadget is large enough to read labels comfortably in VR; at 1.0 it would be too small to hold and read simultaneously
# triggers: grabbing the object lets the player physically rotate it, embodying the relationship between coordinate axes; the axes' emission glow makes them readable in dark VR environments
# emerges: students consistently discover that "X goes right" is only true when you're looking in the default direction — rotating the gadget breaks this assumption and makes coordinates genuinely spatial rather than notational
# needs: colored axis cylinders [has]; pickup physics [has via grab_sphere]; Label3D axis labels [has]; no slider or button controls [has none needed]
# relationships: appears in Tutorial_Single (first VR object encounter), Tutorial_Row, Tutorial_2D_Build (coordinate reference throughout array tutorial); contrasts with basis_vectors_rig (mathematical vs intuitive representation)
# truth: coordinate systems are conventions about shared directions, not properties of space itself — the XYZ gadget makes this visible by being rotatable

# XYZ Coordinate Gadget for VR Interaction
@export var initial_scale: Vector3 = Vector3(3.2, 3.2, 3.2)  # Smaller scale for VR
@export var rotation_speed: float = 1.0  # Rotation speed in radians per second
@export var camera_rotation_sensitivity: float = 2.0  # Sensitivity of camera rotation
@export var camera_movement_sensitivity: float = 0.5  # Sensitivity of camera movement

var is_grabbed: bool = false
var initial_camera_transform: Transform3D
var initial_camera_rotation: Basis

func _ready():
	# Scale down the gadget
	scale = initial_scale
	create_axes()

func create_axes():
	# Create axes visualization to show X, Y, Z directions
	var axes = Node3D.new()
	axes.name = "CoordinateAxes"
	add_child(axes)
	
	# Create X axis (red)
	var x_axis = CSGCylinder3D.new()
	x_axis.radius = 0.02
	x_axis.height = 1.2  # Match label position
	x_axis.rotation_degrees.z = 90
	x_axis.position = Vector3(0.6, 0, 0)  # Centered at half the height
	var x_material = StandardMaterial3D.new()
	x_material.albedo_color = Color(1, 0, 0)  # Red
	x_material.emission_enabled = true
	x_material.emission = Color(1, 0, 0, 0.5)
	x_axis.material = x_material
	axes.add_child(x_axis)
	
	# Create Y axis (green)
	var y_axis = CSGCylinder3D.new()
	y_axis.radius = 0.02
	y_axis.height = 1.2  # Match label position
	y_axis.position = Vector3(0, 0.6, 0)  # Centered at half the height
	var y_material = StandardMaterial3D.new()
	y_material.albedo_color = Color(0, 1, 0)  # Green
	y_material.emission_enabled = true
	y_material.emission = Color(0, 1, 0, 0.5)
	y_axis.material = y_material
	axes.add_child(y_axis)
	
	# Create Z axis (blue)
	var z_axis = CSGCylinder3D.new()
	z_axis.radius = 0.02
	z_axis.height = 1.2  # Match label position
	z_axis.rotation_degrees.x = 90
	z_axis.position = Vector3(0, 0, 0.6)  # Centered at half the height
	var z_material = StandardMaterial3D.new()
	z_material.albedo_color = Color(0, 0, 1)  # Blue
	z_material.emission_enabled = true
	z_material.emission = Color(0, 0, 1, 0.5)
	z_axis.material = z_material
	axes.add_child(z_axis)
	
	# Add axis labels
	add_axis_label("X", Vector3(1.2, 0, 0), Color(1, 0, 0))
	add_axis_label("Y", Vector3(0, 1.2, 0), Color(0, 1, 0))
	add_axis_label("Z", Vector3(0, 0, 1.2), Color(0, 0, 1))

func add_axis_label(text: String, position: Vector3, color: Color):
	var label_3d = Label3D.new()
	label_3d.text = text
	label_3d.font_size = 32
	label_3d.modulate = color
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.position = position
	add_child(label_3d)
