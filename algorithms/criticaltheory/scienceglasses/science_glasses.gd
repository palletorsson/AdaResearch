extends Node3D

# Advanced Laboratory Glassware Generator for Godot 4
# Creates a comprehensive set of chemistry lab equipment with ground glass joints

var glass_material = null
var red_text_material = null
var rubber_material = null

func _ready():
	# Create materials
	create_materials()
	
	# Generate the full set of glassware with proper spacing
	var x_spacing = 2.5
	var z_spacing = 2.5
	
	# Row 1
	create_round_bottom_flask(Vector3(0, 0, 0), 1000)
	create_four_neck_flask(Vector3(x_spacing, 0, 0), 1000)
	create_separatory_funnel(Vector3(2*x_spacing, 0, 0), 250)
	create_thermometer(Vector3(3*x_spacing, 0, 0))
	create_liebig_condenser(Vector3(4*x_spacing, 0, 0))
	create_graham_condenser(Vector3(5*x_spacing, 0, 0))
	
	# Row 2
	create_two_neck_flask(Vector3(0, 0, z_spacing), 250)
	create_straight_adapter(Vector3(x_spacing, 0, z_spacing))
	create_angled_adapter(Vector3(2*x_spacing, 0, z_spacing))
	create_addition_funnel(Vector3(3*x_spacing, 0, z_spacing))
	create_vacuum_adapter(Vector3(4*x_spacing, 0, z_spacing))
	
	# Row 3
	create_distillation_adapter(Vector3(0, 0, 2*z_spacing))
	create_three_way_adapter(Vector3(x_spacing, 0, 2*z_spacing))
	create_test_tubes(Vector3(2*x_spacing, 0, 2*z_spacing))
	create_keck_clips(Vector3(3*x_spacing, 0, 2*z_spacing))
	create_rubber_tubing(Vector3(4*x_spacing, 0, 2*z_spacing))
	
	# Create a simple environment
	create_environment()

func create_materials():
	# Glass material
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.9, 0.95, 1.0, 0.4)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.roughness = 0.1
	glass_material.metallic = 0.1
	glass_material.refraction_enabled = true
	glass_material.refraction_scale = 0.05
	
	# Red text material for volume markings
	red_text_material = StandardMaterial3D.new()
	red_text_material.albedo_color = Color(0.9, 0.1, 0.1, 1.0)
	red_text_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Rubber material for clips and tubing
	rubber_material = StandardMaterial3D.new()
	rubber_material.albedo_color = Color(1.0, 0.8, 0.0)
	rubber_material.roughness = 0.8

# --- Round Bottom Flask ---
func create_round_bottom_flask(position, volume):
	var flask = Node3D.new()
	flask.name = "RoundBottomFlask"
	flask.position = position
	add_child(flask)
	
	# Create the bulb
	var bulb = CSGSphere3D.new()
	bulb.name = "Bulb"
	bulb.radius = 0.7
	bulb.material = glass_material
	flask.add_child(bulb)
	
	# Create the neck
	var neck = CSGCylinder3D.new()
	neck.name = "Neck"
	neck.radius = 0.15
	neck.height = 0.6
	neck.position = Vector3(0, 0.7, 0)
	neck.material = glass_material
	flask.add_child(neck)
	
	# Create the ground glass joint
	var joint = create_ground_glass_joint(Vector3(0, 1.0, 0), 0.18, 0.15, 0.3)
	flask.add_child(joint)
	
	# Add volume label
	add_volume_label(flask, volume, Vector3(0, 0, -0.35))
	
	return flask

# --- Four Neck Flask ---
func create_four_neck_flask(position, volume):
	var flask = Node3D.new()
	flask.name = "FourNeckFlask"
	flask.position = position
	add_child(flask)
	
	# Create the bulb (slightly flattened sphere)
	var bulb = CSGSphere3D.new()
	bulb.name = "Bulb"
	bulb.radius = 0.7
	bulb.scale = Vector3(1.0, 0.8, 1.0)
	bulb.material = glass_material
	flask.add_child(bulb)
	
	# Create the main neck (center)
	var main_neck = CSGCylinder3D.new()
	main_neck.name = "MainNeck"
	main_neck.radius = 0.15
	main_neck.height = 0.5
	main_neck.position = Vector3(0, 0.6, 0)
	main_neck.material = glass_material
	flask.add_child(main_neck)
	
	# Create side necks
	var angles = [0, 90, 180, 270] # Degrees around the flask
	for i in range(angles.size()):
		var angle_rad = deg_to_rad(angles[i])
		var offset = Vector3(cos(angle_rad) * 0.5, 0.2, sin(angle_rad) * 0.5)
		
		# Create angled neck
		var side_neck_base = Node3D.new()
		side_neck_base.name = "SideNeckBase_" + str(i)
		side_neck_base.position = offset
		
		# Angle the neck outward
		var direction = offset.normalized()
		var neck_length = 0.4
		
		# Create the neck cylinder
		var side_neck = CSGCylinder3D.new()
		side_neck.name = "SideNeck"
		side_neck.radius = 0.12
		side_neck.height = neck_length
		side_neck.position = direction * (neck_length / 2)
		
		# Rotate the cylinder to point in the right direction
		var y_axis = Vector3(0, 1, 0)
		var angle = y_axis.angle_to(direction)
		var rotation_axis = y_axis.cross(direction).normalized()
		if rotation_axis.length() > 0.0001:
			side_neck.transform.basis = Basis(rotation_axis, angle)
		
		side_neck.material = glass_material
		side_neck_base.add_child(side_neck)
		
		# Add ground glass joint at end of this neck
		var joint_pos = direction * neck_length
		var joint = create_ground_glass_joint(joint_pos, 0.14, 0.12, 0.25)
		
		# Rotate the joint to align with the neck
		if rotation_axis.length() > 0.0001:
			joint.transform.basis = Basis(rotation_axis, angle)
		
		side_neck_base.add_child(joint)
		flask.add_child(side_neck_base)
	
	# Add main joint on top center neck
	var main_joint = create_ground_glass_joint(Vector3(0, 0.85, 0), 0.18, 0.15, 0.3)
	flask.add_child(main_joint)
	
	# Add volume label
	add_volume_label(flask, volume, Vector3(0, 0, -0.4))
	
	return flask

# --- Two Neck Flask ---
func create_two_neck_flask(pos, volume):
	var flask = Node3D.new()
	flask.name = "TwoNeckFlask"
	flask.position = pos
	add_child(flask)
	
	# Create the bulb
	var bulb = CSGSphere3D.new()
	bulb.name = "Bulb"
	bulb.radius = 0.5
	bulb.material = glass_material
	flask.add_child(bulb)
	
	# Create the main neck (center)
	var main_neck = CSGCylinder3D.new()
	main_neck.name = "MainNeck"
	main_neck.radius = 0.12
	main_neck.height = 0.4
	main_neck.position = Vector3(0, 0.45, 0)
	main_neck.material = glass_material
	flask.add_child(main_neck)
	
	# Create side neck
	var side_neck_base = Node3D.new()
	side_neck_base.name = "SideNeckBase"
	side_neck_base.position = Vector3(0.35, 0.2, 0)
	flask.add_child(side_neck_base)
	
	# Direction for side neck
	var direction = Vector3(0.7, 0.7, 0).normalized()
	var neck_length = 0.3
	
	# Create the side neck cylinder
	var side_neck = CSGCylinder3D.new()
	side_neck.name = "SideNeck"
	side_neck.radius = 0.1
	side_neck.height = neck_length
	side_neck.position = direction * (neck_length / 2)
	
	# Rotate the cylinder to point in the right direction
	var y_axis = Vector3(0, 1, 0)
	var angle = y_axis.angle_to(direction)
	var rotation_axis = y_axis.cross(direction).normalized()
	if rotation_axis.length() > 0.0001:
		side_neck.transform.basis = Basis(rotation_axis, angle)
	
	side_neck.material = glass_material
	side_neck_base.add_child(side_neck)
	
	# Add ground glass joint at end of side neck
	var joint_pos = direction * neck_length
	var side_joint = create_ground_glass_joint(joint_pos, 0.12, 0.1, 0.2)
	
	# Rotate the joint to align with the neck
	if rotation_axis.length() > 0.0001:
		side_joint.transform.basis = Basis(rotation_axis, angle)
	
	side_neck_base.add_child(side_joint)
	
	# Add main joint on top center neck
	var main_joint = create_ground_glass_joint(Vector3(0, 0.65, 0), 0.14, 0.12, 0.25)
	flask.add_child(main_joint)
	
	# Add volume label
	add_volume_label(flask, volume, Vector3(0, 0, -0.3))
	
	return flask

# --- Separatory Funnel ---
func create_separatory_funnel(position, volume):
	var funnel = Node3D.new()
	funnel.name = "SeparatoryFunnel"
	funnel.position = position
	add_child(funnel)
	
	# Create the funnel body using a sphere with cone cut out
	var body = CSGSphere3D.new()
	body.name = "Body"
	body.radius = 0.5
	body.material = glass_material
	funnel.add_child(body)
	
	# Make the drop shape by cutting out cones
	var cut_bottom = CSGCylinder3D.new()
	cut_bottom.name = "CutBottom"
	cut_bottom.radius = 0.35
	cut_bottom.height = 1.2
	cut_bottom.position = Vector3(0, -0.7, 0)
	cut_bottom.operation = CSGShape3D.OPERATION_SUBTRACTION
	body.add_child(cut_bottom)
	
	# Add neck at top
	var top_neck = CSGCylinder3D.new()
	top_neck.name = "TopNeck"
	top_neck.radius = 0.12
	top_neck.height = 0.3
	top_neck.position = Vector3(0, 0.4, 0)
	top_neck.material = glass_material
	funnel.add_child(top_neck)
	
	# Add ground glass joint at top
	var top_joint = create_ground_glass_joint(Vector3(0, 0.55, 0), 0.14, 0.12, 0.25)
	funnel.add_child(top_joint)
	
	# Add stopcock at bottom
	create_stopcock(funnel, Vector3(0, -0.65, 0))
	
	# Add volume label
	add_volume_label(funnel, volume, Vector3(0, 0, -0.3))
	
	return funnel

# --- Stopcock ---
func create_stopcock(parent, position):
	var stopcock = Node3D.new()
	stopcock.name = "Stopcock"
	stopcock.position = position
	parent.add_child(stopcock)
	
	# Create valve body
	var valve_body = CSGCylinder3D.new()
	valve_body.name = "ValveBody"
	valve_body.radius = 0.08
	valve_body.height = 0.25
	valve_body.rotation_degrees = Vector3(90, 0, 0)
	valve_body.material = glass_material
	stopcock.add_child(valve_body)
	
	# Create handle
	var handle = CSGBox3D.new()
	handle.name = "Handle"
	handle.size = Vector3(0.04, 0.15, 0.04)
	handle.position = Vector3(0, 0, 0.12)
	
	var handle_material = StandardMaterial3D.new()
	handle_material.albedo_color = Color(0.9, 0.2, 0.2)
	handle.material = handle_material
	stopcock.add_child(handle)
	
	# Create outlet tube
	var outlet = CSGCylinder3D.new()
	outlet.name = "Outlet"
	outlet.radius = 0.05
	outlet.height = 0.2
	outlet.position = Vector3(0, -0.15, 0)
	outlet.material = glass_material
	stopcock.add_child(outlet)
	
	return stopcock

# --- Thermometer ---
func create_thermometer(position):
	var thermometer = Node3D.new()
	thermometer.name = "Thermometer"
	thermometer.position = position
	add_child(thermometer)
	
	# Create the main glass tube
	var tube = CSGCylinder3D.new()
	tube.name = "Tube"
	tube.radius = 0.03
	tube.height = 1.5
	tube.material = glass_material
	thermometer.add_child(tube)
	
	# Create the bulb at bottom
	var bulb = CSGSphere3D.new()
	bulb.name = "Bulb"
	bulb.radius = 0.08
	bulb.position = Vector3(0, -0.75, 0)
	bulb.material = glass_material
	thermometer.add_child(bulb)
	
	# Create the red liquid inside
	var liquid = CSGCylinder3D.new()
	liquid.name = "Liquid"
	liquid.radius = 0.01
	liquid.height = 0.9
	liquid.position = Vector3(0, -0.2, 0)
	
	var liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = Color(0.9, 0.1, 0.1)
	liquid.material = liquid_material
	thermometer.add_child(liquid)
	
	# Create measurement markings
	for i in range(10):
		var y_pos = -0.6 + i * 0.12
		var mark = CSGBox3D.new()
		mark.name = "Mark_" + str(i)
		mark.size = Vector3(0.06, 0.005, 0.01)
		mark.position = Vector3(0, y_pos, 0.03)
		
		var mark_material = StandardMaterial3D.new()
		mark_material.albedo_color = Color(0.9, 0.1, 0.1)
		mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.material = mark_material
		
		thermometer.add_child(mark)
	
	# Create ground glass joint at the top
	var joint = create_ground_glass_joint(Vector3(0, 0.7, 0), 0.1, 0.08, 0.2)
	thermometer.add_child(joint)
	
	return thermometer

# --- Liebig Condenser ---
func create_liebig_condenser(position):
	var condenser = Node3D.new()
	condenser.name = "LiebigCondenser"
	condenser.position = position
	add_child(condenser)
	
	# Create the outer jacket
	var outer_tube = CSGCylinder3D.new()
	outer_tube.name = "OuterTube"
	outer_tube.radius = 0.2
	outer_tube.height = 1.4
	outer_tube.material = glass_material
	condenser.add_child(outer_tube)
	
	# Create the inner tube
	var inner_tube = CSGCylinder3D.new()
	inner_tube.name = "InnerTube"
	inner_tube.radius = 0.08
	inner_tube.height = 1.6
	inner_tube.material = glass_material
	condenser.add_child(inner_tube)
	
	# Create side arms for water inlet/outlet
	create_side_arm(condenser, Vector3(0, 0.4, 0), Vector3(0.3, 0.4, 0), 0.06)
	create_side_arm(condenser, Vector3(0, -0.4, 0), Vector3(0.3, -0.4, 0), 0.06)
	
	# Create ground glass joints at both ends
	var top_joint = create_ground_glass_joint(Vector3(0, 0.8, 0), 0.12, 0.08, 0.2)
	var bottom_joint = create_ground_glass_joint(Vector3(0, -0.8, 0), 0.12, 0.08, 0.2)
	bottom_joint.rotation_degrees = Vector3(180, 0, 0) # Flip the bottom joint
	
	condenser.add_child(top_joint)
	condenser.add_child(bottom_joint)
	
	return condenser

# --- Graham Condenser (Coil Condenser) ---
func create_graham_condenser(position):
	var condenser = Node3D.new()
	condenser.name = "GrahamCondenser"
	condenser.position = position
	add_child(condenser)
	
	# Create the outer jacket
	var outer_tube = CSGCylinder3D.new()
	outer_tube.name = "OuterTube"
	outer_tube.radius = 0.2
	outer_tube.height = 1.4
	outer_tube.material = glass_material
	condenser.add_child(outer_tube)
	
	# Create the coiled inner tube using a path
	var path = Path3D.new()
	path.name = "CoilPath"
	var curve = Curve3D.new()
	path.curve = curve
	condenser.add_child(path)
	
	# Generate a spiral path
	var segments = 30
	var coil_height = 1.2
	var coil_radius = 0.12
	var turns = 6
	var pitch = coil_height / turns
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * turns * 2 * PI
		var y = -coil_height/2 + t * coil_height
		var x = coil_radius * sin(angle)
		var z = coil_radius * cos(angle)
		curve.add_point(Vector3(x, y, z))
	
	# Create CSGPolygon to follow the path
	var coil = CSGPolygon3D.new()
	coil.name = "CoilTube"
	coil.polygon = create_circle_polygon(0.04)
	coil.mode = CSGPolygon3D.MODE_PATH
	coil.path_node = NodePath("../CoilPath")
	coil.material = glass_material
	condenser.add_child(coil)
	
	# Create side arms for water inlet/outlet
	create_side_arm(condenser, Vector3(0, 0.4, 0), Vector3(0.3, 0.4, 0), 0.06)
	create_side_arm(condenser, Vector3(0, -0.4, 0), Vector3(0.3, -0.4, 0), 0.06)
	
	# Extend the ends of the coil outside the jacket
	var top_extension = CSGCylinder3D.new()
	top_extension.name = "TopExtension"
	top_extension.radius = 0.04
	top_extension.height = 0.3
	top_extension.position = Vector3(0, 0.8, 0)
	top_extension.material = glass_material
	condenser.add_child(top_extension)
	
	var bottom_extension = CSGCylinder3D.new()
	bottom_extension.name = "BottomExtension"
	bottom_extension.radius = 0.04
	bottom_extension.height = 0.3
	bottom_extension.position = Vector3(0, -0.8, 0)
	bottom_extension.material = glass_material
	condenser.add_child(bottom_extension)
	
	# Create ground glass joints at both ends
	var top_joint = create_ground_glass_joint(Vector3(0, 0.95, 0), 0.12, 0.08, 0.2)
	var bottom_joint = create_ground_glass_joint(Vector3(0, -0.95, 0), 0.12, 0.08, 0.2)
	bottom_joint.rotation_degrees = Vector3(180, 0, 0) # Flip the bottom joint
	
	condenser.add_child(top_joint)
	condenser.add_child(bottom_joint)
	
	return condenser

# --- Straight Adapter ---
func create_straight_adapter(position):
	var adapter = Node3D.new()
	adapter.name = "StraightAdapter"
	adapter.position = position
	add_child(adapter)
	
	# Create the middle tube
	var tube = CSGCylinder3D.new()
	tube.name = "Tube"
	tube.radius = 0.1
	tube.height = 0.5
	tube.material = glass_material
	adapter.add_child(tube)
	
	# Create ground glass joints at both ends
	var top_joint = create_ground_glass_joint(Vector3(0, 0.35, 0), 0.14, 0.1, 0.25)
	var bottom_joint = create_ground_glass_joint(Vector3(0, -0.35, 0), 0.14, 0.1, 0.25)
	bottom_joint.rotation_degrees = Vector3(180, 0, 0) # Flip the bottom joint
	
	adapter.add_child(top_joint)
	adapter.add_child(bottom_joint)
	
	# Add joint size text
	add_text_label(adapter, "24/40", Vector3(0.12, 0, 0))
	
	return adapter

# --- Angled Adapter ---
func create_angled_adapter(position):
	var adapter = Node3D.new()
	adapter.name = "AngledAdapter"
	adapter.position = position
	add_child(adapter)
	
	# Create the bent tube using a path
	var path = Path3D.new()
	path.name = "Path"
	var curve = Curve3D.new()
	path.curve = curve
	
	# Define the curve for a 75-degree bend
	var segments = 10
	var bend_radius = 0.3
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * deg_to_rad(75) # 75-degree bend
		var x = bend_radius * sin(angle)
		var y = bend_radius * (1 - cos(angle))
		curve.add_point(Vector3(x, y, 0))
	
	adapter.add_child(path)
	
	# Create CSGPolygon to follow the path
	var tube = CSGPolygon3D.new()
	tube.name = "Tube"
	tube.polygon = create_circle_polygon(0.1)
	tube.mode = CSGPolygon3D.MODE_PATH
	tube.path_node = NodePath("../Path")
	tube.material = glass_material
	adapter.add_child(tube)
	
	# Create ground glass joints at both ends
	# Calculate end positions and orientations from the path
	var start_point = curve.get_point_position(0)
	var end_point = curve.get_point_position(curve.get_point_count() - 1)
	var start_direction = Vector3(0, -1, 0)
	var end_direction = Vector3(1, 0, 0)
	
	# Bottom joint (input)
	var bottom_joint = create_ground_glass_joint(start_point, 0.14, 0.1, 0.25)
	# Orient the joint to point down
	bottom_joint.rotation_degrees = Vector3(180, 0, 0)
	adapter.add_child(bottom_joint)
	
	# Top joint (output)
	var side_joint = create_ground_glass_joint(end_point, 0.14, 0.1, 0.25)
	# Orient the joint to point to the side
	side_joint.rotation_degrees = Vector3(0, 0, -75)
	adapter.add_child(side_joint)
	
	# Add joint size text
	add_text_label(adapter, "24/40", Vector3(0, -0.3, 0))
	add_text_label(adapter, "24/40", Vector3(0.4, 0.1, 0))
	
	return adapter

# --- Addition Funnel ---
func create_addition_funnel(position):
	var funnel = Node3D.new()
	funnel.name = "AdditionFunnel"
	funnel.position = position
	add_child(funnel)
	
	# Create the funnel body (cylinder with cone on top)
	var body = CSGCylinder3D.new()
	body.name = "Body"
	body.radius = 0.2
	body.height = 0.8
	body.material = glass_material
	funnel.add_child(body)
	
	# Create conical top
	var top_cone = CSGCylinder3D.new()
	top_cone.name = "TopCone"
	top_cone.radius = 0.2
	top_cone.height = 0.3
	top_cone.cone = true
	top_cone.position = Vector3(0, 0.55, 0)
	top_cone.material = glass_material
	funnel.add_child(top_cone)
	
	# Add neck at top
	var top_neck = CSGCylinder3D.new()
	top_neck.name = "TopNeck"
	top_neck.radius = 0.08
	top_neck.height = 0.2
	top_neck.position = Vector3(0, 0.8, 0)
	top_neck.material = glass_material
	funnel.add_child(top_neck)
	
	# Add stopcock at bottom
	create_stopcock(funnel, Vector3(0, -0.5, 0))
	
	# Add ground glass joint at top and bottom
	var top_joint = create_ground_glass_joint(Vector3(0, 0.9, 0), 0.1, 0.08, 0.2)
	funnel.add_child(top_joint)
	
	# Add volume markers
	for i in range(5):
		var y_pos = -0.3 + i * 0.15
		var mark = CSGBox3D.new()
		mark.name = "Mark_" + str(i)
		mark.size = Vector3(0.06, 0.005, 0.01)
		mark.position = Vector3(0, y_pos, 0.2)
		
		var mark_material = StandardMaterial3D.new()
		mark_material.albedo_color = Color(0.9, 0.1, 0.1)
		mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.material = mark_material
		
		funnel.add_child(mark)
	
	# Add joint size text
	add_text_label(funnel, "24/40", Vector3(0, 0.9, 0))
	
	return funnel
# Continuing from create_vacuum_adapter function

# --- Vacuum Adapter (continued) ---
func create_vacuum_adapter(position):
	var adapter = Node3D.new()
	adapter.name = "VacuumAdapter"
	adapter.position = position
	add_child(adapter)
	
	# Create the main vertical tube
	var main_tube = CSGCylinder3D.new()
	main_tube.name = "MainTube"
	main_tube.radius = 0.1
	main_tube.height = 0.7
	main_tube.material = glass_material
	adapter.add_child(main_tube)
	
	# Create the side arm
	var arm_base = Node3D.new()
	arm_base.name = "ArmBase"
	arm_base.position = Vector3(0, 0, 0)
	adapter.add_child(arm_base)
	
	var side_arm_direction = Vector3(0.7, 0, 0).normalized()
	var arm_length = 0.4
	
	var side_arm = CSGCylinder3D.new()
	side_arm.name = "SideArm"
	side_arm.radius = 0.06
	side_arm.height = arm_length
	side_arm.position = side_arm_direction * (arm_length / 2)
	
	# Rotate to point sideways
	side_arm.rotation_degrees = Vector3(0, 0, 90)
	side_arm.material = glass_material
	arm_base.add_child(side_arm)
	
	# Create vacuum connector at the end of side arm
	var hose_connector = CSGCylinder3D.new()
	hose_connector.name = "HoseConnector"
	hose_connector.radius = 0.07  # Slightly wider than the arm
	hose_connector.height = 0.1
	hose_connector.position = Vector3(arm_length, 0, 0)
	hose_connector.rotation_degrees = Vector3(0, 0, 90)
	hose_connector.material = glass_material
	arm_base.add_child(hose_connector)
	
	# Add ridges on the connector for securing tubing
	for i in range(3):
		var ridge = CSGTorus3D.new()
		ridge.name = "Ridge_" + str(i)
		ridge.inner_radius = 0.07
		ridge.outer_radius = 0.085
		ridge.position = Vector3(arm_length + 0.02 + i * 0.03, 0, 0)
		ridge.rotation_degrees = Vector3(0, 0, 90)
		ridge.material = glass_material
		arm_base.add_child(ridge)
	
	# Create ground glass joints at top and bottom of main tube
	var top_joint = create_ground_glass_joint(Vector3(0, 0.35, 0), 0.14, 0.1, 0.25)
	var bottom_joint = create_ground_glass_joint(Vector3(0, -0.35, 0), 0.14, 0.1, 0.25)
	bottom_joint.rotation_degrees = Vector3(180, 0, 0) # Flip the bottom joint
	
	adapter.add_child(top_joint)
	adapter.add_child(bottom_joint)
	
	# Add joint size text
	add_text_label(adapter, "24/40", Vector3(0, 0.35, 0.12))
	add_text_label(adapter, "24/40", Vector3(0, -0.35, 0.12))
	
	return adapter

# --- Distillation Adapter ---
func create_distillation_adapter(position):
	var adapter = Node3D.new()
	adapter.name = "DistillationAdapter"
	adapter.position = position
	add_child(adapter)
	
	# Create the bent tube using a path
	var path = Path3D.new()
	path.name = "Path"
	var curve = Curve3D.new()
	path.curve = curve
	
	# Define the curve for a 105-degree bend
	var segments = 12
	var bend_radius = 0.3
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * deg_to_rad(105) # 105-degree bend
		var x = bend_radius * sin(angle)
		var y = bend_radius * (1 - cos(angle))
		curve.add_point(Vector3(x, y, 0))
	
	adapter.add_child(path)
	
	# Create CSGPolygon to follow the path
	var tube = CSGPolygon3D.new()
	tube.name = "Tube"
	tube.polygon = create_circle_polygon(0.1)
	tube.mode = CSGPolygon3D.MODE_PATH
	tube.path_node = NodePath("../Path")
	tube.material = glass_material
	adapter.add_child(tube)
	
	# Create thermometer port
	var thermo_port_base = Node3D.new()
	thermo_port_base.name = "ThermoPortBase"
	thermo_port_base.position = Vector3(0.1, 0.15, 0)
	adapter.add_child(thermo_port_base)
	
	var thermo_port = CSGCylinder3D.new()
	thermo_port.name = "ThermoPort"
	thermo_port.radius = 0.06
	thermo_port.height = 0.25
	thermo_port.position = Vector3(0, 0.125, 0)
	thermo_port.material = glass_material
	thermo_port_base.add_child(thermo_port)
	
	# Add ground glass joint for thermometer
	var thermo_joint = create_ground_glass_joint(Vector3(0, 0.25, 0), 0.1, 0.06, 0.15)
	thermo_port_base.add_child(thermo_joint)
	
	# Create ground glass joints at both ends of main tube
	var start_point = curve.get_point_position(0)
	var end_point = curve.get_point_position(curve.get_point_count() - 1)
	
	# Bottom joint (input)
	var bottom_joint = create_ground_glass_joint(start_point, 0.14, 0.1, 0.25)
	bottom_joint.rotation_degrees = Vector3(180, 0, 0)
	adapter.add_child(bottom_joint)
	
	# Top/side joint (output)
	var side_joint = create_ground_glass_joint(end_point, 0.14, 0.1, 0.25)
	side_joint.rotation_degrees = Vector3(0, 0, -105)
	adapter.add_child(side_joint)
	
	# Add joint size text
	add_text_label(adapter, "24/40", Vector3(0, -0.3, 0))
	add_text_label(adapter, "24/40", Vector3(0.4, 0.3, 0))
	add_text_label(thermo_port_base, "24/40", Vector3(0, 0.25, 0.07))
	
	return adapter

# --- Three-Way Adapter ---
func create_three_way_adapter(position):
	var adapter = Node3D.new()
	adapter.name = "ThreeWayAdapter"
	adapter.position = position
	add_child(adapter)
	
	# Create the center sphere
	var center = CSGSphere3D.new()
	center.name = "Center"
	center.radius = 0.15
	center.material = glass_material
	adapter.add_child(center)
	
	# Create three arms at different angles
	var angles = [0, 120, 240] # Degrees around the sphere
	for i in range(angles.size()):
		var angle_rad = deg_to_rad(angles[i])
		var direction = Vector3(cos(angle_rad), sin(angle_rad), 0)
		
		# Create arm
		var arm = CSGCylinder3D.new()
		arm.name = "Arm_" + str(i)
		arm.radius = 0.08
		arm.height = 0.3
		arm.position = direction * 0.3
		
		# Rotate to point outward
		var y_axis = Vector3(0, 1, 0)
		var rotation_axis = Vector3(0, 0, 1)
		arm.rotation_degrees = Vector3(0, 0, angles[i])
		
		arm.material = glass_material
		adapter.add_child(arm)
		
		# Add ground glass joint at end
		var joint = create_ground_glass_joint(direction * 0.45, 0.12, 0.08, 0.2)
		joint.rotation_degrees = Vector3(0, 0, angles[i])
		adapter.add_child(joint)
		
		# Add joint size text
		add_text_label(adapter, "24/40", direction * 0.5 + Vector3(0, 0, 0.1))
	
	return adapter

# --- Test Tubes ---
func create_test_tubes(position):
	var test_tubes = Node3D.new()
	test_tubes.name = "TestTubes"
	test_tubes.position = position
	add_child(test_tubes)
	
	# Create a rack of 5 test tubes
	for i in range(5):
		var offset = Vector3(i * 0.15 - 0.3, 0, 0)
		var tube = create_test_tube_single(offset, false)
		test_tubes.add_child(tube)
	
	return test_tubes

# Create a single test tube
func create_test_tube_single(position, add_ground_joint=false):
	var tube = Node3D.new()
	tube.name = "TestTube"
	tube.position = position
	
	# Create the glass tube
	var glass_tube = CSGCylinder3D.new()
	glass_tube.name = "GlassTube"
	glass_tube.radius = 0.06
	glass_tube.height = 0.4
	glass_tube.material = glass_material
	tube.add_child(glass_tube)
	
	# Create the rounded bottom
	var bottom = CSGSphere3D.new()
	bottom.name = "Bottom"
	bottom.radius = 0.06
	bottom.position = Vector3(0, -0.2, 0)
	bottom.material = glass_material
	tube.add_child(bottom)
	
	# Add ground glass joint if requested
	if add_ground_joint:
		var joint = create_ground_glass_joint(Vector3(0, 0.2, 0), 0.08, 0.06, 0.15)
		tube.add_child(joint)
	
	return tube

# --- Keck Clips ---
func create_keck_clips(position):
	var clips = Node3D.new()
	clips.name = "KeckClips"
	clips.position = position
	add_child(clips)
	
	# Create a row of 10 clips
	for i in range(10):
		var offset = Vector3(i * 0.2 - 0.9, 0, 0)
		create_keck_clip_single(clips, offset)
	
	return clips

# Create a single keck clip
func create_keck_clip_single(parent, position):
	var clip = Node3D.new()
	clip.name = "KeckClip"
	clip.position = position
	parent.add_child(clip)
	
	# Create the clip base (c-shaped)
	var path = Path3D.new()
	path.name = "ClipPath"
	var curve = Curve3D.new()
	path.curve = curve
	
	# Create a C-shaped curve
	var segments = 8
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * deg_to_rad(300) # 300-degree arc (not quite closed)
		var radius = 0.1
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		curve.add_point(Vector3(x, y, 0))
	
	clip.add_child(path)
	
	# Create CSGPolygon to follow the path
	var clip_body = CSGPolygon3D.new()
	clip_body.name = "ClipBody"
	
	# Create a rectangular profile
	var points = PackedVector2Array()
	points.append(Vector2(-0.02, -0.02))
	points.append(Vector2(0.02, -0.02))
	points.append(Vector2(0.02, 0.02))
	points.append(Vector2(-0.02, 0.02))
	
	clip_body.polygon = points
	clip_body.mode = CSGPolygon3D.MODE_PATH
	clip_body.path_node = NodePath("../ClipPath")
	clip_body.material = rubber_material
	clip.add_child(clip_body)
	
	# Rotate to stand vertically
	clip.rotation_degrees = Vector3(90, 0, 0)
	
	return clip

# --- Rubber Tubing ---
func create_rubber_tubing(position):
	var tubing = Node3D.new()
	tubing.name = "RubberTubing"
	tubing.position = position
	add_child(tubing)
	
	# Create a coiled rubber tube using a path
	var path = Path3D.new()
	path.name = "TubingPath"
	var curve = Curve3D.new()
	path.curve = curve
	tubing.add_child(path)
	
	# Generate a spiral path (like a spring)
	var segments = 40
	var coil_height = 0.5
	var coil_radius = 0.25
	var turns = 3
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * turns * 2 * PI
		var y = -coil_height/2 + t * coil_height
		var x = coil_radius * sin(angle)
		var z = coil_radius * cos(angle)
		curve.add_point(Vector3(x, y, z))
	
	# Create CSGPolygon to follow the path
	var tube = CSGPolygon3D.new()
	tube.name = "Tube"
	tube.polygon = create_circle_polygon(0.05)
	tube.mode = CSGPolygon3D.MODE_PATH
	tube.path_node = NodePath("../TubingPath")
	tube.material = rubber_material
	tubing.add_child(tube)
	
	return tubing

# --- Ground Glass Joint ---
func create_ground_glass_joint(position, outer_radius, inner_radius, height):
	var joint = Node3D.new()
	joint.name = "GroundJoint"
	joint.position = position
	
	# Create an outer transparent cone
	var outer_joint = CSGCylinder3D.new()
	outer_joint.name = "OuterJoint"
	outer_joint.radius = outer_radius

	outer_joint.height = height
	outer_joint.material = glass_material
	joint.add_child(outer_joint)
	
	# Create inner frosted surface to show ground glass texture
	var inner_joint = CSGCylinder3D.new()
	inner_joint.name = "InnerJoint"
	inner_joint.radius = inner_radius * 0.95

	inner_joint.height = height * 0.95
	inner_joint.position = Vector3(0, 0.01, 0)
	
	# Create frosted/ground glass material
	var frosted_material = StandardMaterial3D.new()
	frosted_material.albedo_color = Color(0.9, 0.95, 1.0, 0.7)
	frosted_material.roughness = 0.9
	frosted_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_joint.material = frosted_material
	
	joint.add_child(inner_joint)
	
	return joint

# --- Side Arm ---
func create_side_arm(parent, start_pos, end_pos, radius):
	var side_arm = CSGCylinder3D.new()
	side_arm.name = "SideArm"
	side_arm.radius = radius
	
	# Calculate position, height, and rotation
	var direction = end_pos - start_pos
	var height = direction.length()
	side_arm.height = height
	
	# Position at the midpoint
	side_arm.position = (start_pos + end_pos) / 2
	
	# Rotate to align with the direction vector
	var y_axis = Vector3(0, 1, 0)
	var axis = y_axis.cross(direction.normalized())
	var angle = y_axis.angle_to(direction.normalized())
	if axis.length() > 0.0001:  # Avoid normalization of zero vector
		side_arm.transform.basis = Basis(axis.normalized(), angle)
	
	side_arm.material = glass_material
	parent.add_child(side_arm)
	
	return side_arm

# --- Volume Label ---
func add_volume_label(parent, volume, position):
	# Create a 3D text node in Godot 4
	var label = MeshInstance3D.new()
	label.name = "VolumeLabel"
	label.position = position
	
	# Use a simple colored material for visibility
	label.material_override = red_text_material
	
	# Use a quad with texture instead of Text3D for compatibility
	var text_mesh = QuadMesh.new()
	text_mesh.size = Vector2(0.3, 0.15)
	label.mesh = text_mesh
	
	# Create text texture
	#var dynamic_font = Font.new()
	var font_material = StandardMaterial3D.new()
	font_material.albedo_color = Color(0.9, 0.1, 0.1)
	font_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Use a temporary workaround - in a real implementation you would create
	# a proper text texture and apply it here
	
	parent.add_child(label)
	
	return label

# --- Text Label ---
func add_text_label(parent, text, position):
	var label = CSGBox3D.new()
	label.name = "TextLabel"
	label.size = Vector3(0.15, 0.05, 0.01)
	label.position = position
	label.material = red_text_material
	parent.add_child(label)
	
	return label

# --- Utility Functions ---
func create_circle_polygon(radius, segments=16):
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = 2 * PI * i / segments
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		points.append(Vector2(x, y))
	return points

# Create a simple environment
func create_environment():
	# Add a light
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight"
	light.position = Vector3(0, 10, 0)
	light.look_at_from_position(light.position, Vector3(0, 0, 0), Vector3(0, 0, 1))
	add_child(light)
	
	# Add a camera
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 3, 8)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0), Vector3(0, 1, 0))
	add_child(camera)
	
	# Add a simple environment
	var environment = Environment.new()
	var world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
