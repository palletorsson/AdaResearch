extends Node3D

# This script creates a 3D science desk similar to a laboratory workstation

func _ready():
	create_science_desk()

func create_science_desk():
	# Create the main desk structure
	var desk_base = create_desk_base()
	add_child(desk_base)
	
	# Create cabinets
	var cabinets = create_cabinets()
	desk_base.add_child(cabinets)
	
	# Create countertop
	var countertop = create_countertop()
	desk_base.add_child(countertop)
	
	# Add lab equipment
	add_lab_equipment(countertop)
	
	# Add lighting
	add_lighting(desk_base)

func create_desk_base():
	var desk_base = Node3D.new()
	desk_base.name = "ScienceDesk"
	
	# Create the main desk structure using CSG for easy prototyping
	var desk_body = CSGBox3D.new()
	desk_body.name = "DeskBody"
	desk_body.size = Vector3(2.5, 0.9, 0.8)
	desk_body.position = Vector3(0, 0.45, 0)
	
	# Create material for desk
	var desk_material = StandardMaterial3D.new()
	desk_material.albedo_color = Color(0.9, 0.9, 0.9)  # White color like in the image
	desk_body.material = desk_material
	
	desk_base.add_child(desk_body)
	
	# Add desk legs
	add_desk_legs(desk_base, desk_body.size)
	
	return desk_base

func add_desk_legs(desk_base, desk_size):
	var leg_material = StandardMaterial3D.new()
	leg_material.albedo_color = Color(0.85, 0.85, 0.85)  # Slightly darker than the desk
	
	# Calculate leg positions based on desk size
	var leg_positions = [
		Vector3(-desk_size.x/2 + 0.05, -desk_size.y/2, -desk_size.z/2 + 0.05),
		Vector3(desk_size.x/2 - 0.05, -desk_size.y/2, -desk_size.z/2 + 0.05),
		Vector3(-desk_size.x/2 + 0.05, -desk_size.y/2, desk_size.z/2 - 0.05),
		Vector3(desk_size.x/2 - 0.05, -desk_size.y/2, desk_size.z/2 - 0.05)
	]
	
	for i in range(leg_positions.size()):
		var leg = CSGBox3D.new()
		leg.name = "Leg_" + str(i)
		leg.size = Vector3(0.08, 0.2, 0.08)
		leg.position = leg_positions[i]
		leg.material = leg_material
		desk_base.add_child(leg)

func create_cabinets():
	var cabinets = Node3D.new()
	cabinets.name = "Cabinets"
	
	# Define cabinet dimensions
	var cabinet_width = 0.5
	var cabinet_height = 0.7
	var cabinet_depth = 0.75
	
	# Create multiple cabinets side by side
	for i in range(4):
		var cabinet = CSGBox3D.new()
		cabinet.name = "Cabinet_" + str(i)
		cabinet.size = Vector3(cabinet_width, cabinet_height, cabinet_depth)
		cabinet.position = Vector3(-0.9 + (i * cabinet_width), -0.1, 0)
		
		# Create cabinet material
		var cabinet_material = StandardMaterial3D.new()
		cabinet_material.albedo_color = Color(0.95, 0.95, 0.95)  # White cabinets
		cabinet.material = cabinet_material
		
		cabinets.add_child(cabinet)
		
		# Add drawer/door handles
		add_cabinet_handle(cabinet, i % 2 == 0)  # Alternate between drawers and doors
	
	return cabinets

func add_cabinet_handle(cabinet, is_drawer):
	var handle_material = StandardMaterial3D.new()
	handle_material.albedo_color = Color(0.8, 0.8, 0.8)  # Light gray handles
	
	if is_drawer:
		# Create drawer front and handle
		for j in range(2):
			var drawer = CSGBox3D.new()
			drawer.name = "Drawer_" + str(j)
			drawer.size = Vector3(cabinet.size.x - 0.04, cabinet.size.y/3 - 0.04, 0.02)
			drawer.position = Vector3(0, -cabinet.size.y/4 + j * (cabinet.size.y/2), cabinet.size.z/2 + 0.01)
			cabinet.add_child(drawer)
			
			var handle = CSGBox3D.new()
			handle.name = "Handle_" + str(j)
			handle.size = Vector3(0.1, 0.01, 0.02)
			handle.position = Vector3(0, 0, 0.02)
			handle.material = handle_material
			drawer.add_child(handle)
	else:
		# Create cabinet door and handle
		var door = CSGBox3D.new()
		door.name = "Door"
		door.size = Vector3(cabinet.size.x - 0.04, cabinet.size.y - 0.04, 0.02)
		door.position = Vector3(0, 0, cabinet.size.z/2 + 0.01)
		cabinet.add_child(door)
		
		var handle = CSGBox3D.new()
		handle.name = "Handle"
		handle.size = Vector3(0.02, 0.08, 0.03)
		handle.position = Vector3(cabinet.size.x/4, 0, 0.02)
		handle.material = handle_material
		door.add_child(handle)

func create_countertop():
	var countertop = Node3D.new()
	countertop.name = "Countertop"
	
	# Create the countertop surface
	var surface = CSGBox3D.new()
	surface.name = "Surface"
	surface.size = Vector3(2.6, 0.05, 0.9)
	surface.position = Vector3(0, 0.475, 0)
	
	# Create material for countertop
	var surface_material = StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.98, 0.98, 0.98)  # White surface like in the image
	surface.material = surface_material
	
	countertop.add_child(surface)
	
	# Add backsplash
	var backsplash = CSGBox3D.new()
	backsplash.name = "Backsplash"
	backsplash.size = Vector3(2.6, 0.2, 0.02)
	backsplash.position = Vector3(0, 0.6, -0.44)
	backsplash.material = surface_material
	countertop.add_child(backsplash)
	
	return countertop

func add_lab_equipment(countertop):
	# Add a sink
	var sink = CSGBox3D.new()
	sink.name = "Sink"
	sink.size = Vector3(0.4, 0.05, 0.3)
	sink.position = Vector3(-0.8, 0.01, 0.1)
	
	var sink_material = StandardMaterial3D.new()
	sink_material.albedo_color = Color(0.8, 0.8, 0.8)  # Light gray sink
	sink.material = sink_material
	
	# Create sink basin by subtracting a box
	var sink_basin = CSGBox3D.new()
	sink_basin.name = "SinkBasin"
	sink_basin.size = Vector3(0.35, 0.15, 0.25)
	sink_basin.position = Vector3(0, -0.075, 0)
	sink_basin.operation = CSGShape3D.OPERATION_SUBTRACTION
	sink.add_child(sink_basin)
	
	countertop.add_child(sink)
	
	# Add a faucet
	var faucet_base = CSGCylinder3D.new()
	faucet_base.name = "FaucetBase"
	faucet_base.radius = 0.03
	faucet_base.height = 0.05
	faucet_base.position = Vector3(-0.8, 0.04, -0.05)
	
	var faucet_material = StandardMaterial3D.new()
	faucet_material.albedo_color = Color(0.7, 0.7, 0.7)  # Silver/gray faucet
	faucet_base.material = faucet_material
	
	var faucet_neck = CSGCylinder3D.new()
	faucet_neck.name = "FaucetNeck"
	faucet_neck.radius = 0.015
	faucet_neck.height = 0.2
	faucet_neck.position = Vector3(0, 0.1, 0.05)
	faucet_neck.rotation_degrees = Vector3(90, 0, 0)
	faucet_neck.material = faucet_material
	faucet_base.add_child(faucet_neck)
	
	var faucet_spout = CSGCylinder3D.new()
	faucet_spout.name = "FaucetSpout"
	faucet_spout.radius = 0.012
	faucet_spout.height = 0.1
	faucet_spout.position = Vector3(0, 0, 0.05)
	faucet_spout.rotation_degrees = Vector3(0, 0, 90)
	faucet_spout.material = faucet_material
	faucet_neck.add_child(faucet_spout)
	
	countertop.add_child(faucet_base)
	
	# Add some lab equipment (beakers, bottles, etc.)
	add_beakers_and_bottles(countertop)

func add_beakers_and_bottles(countertop):
	# Create a few beakers
	var positions = [
		Vector3(0.2, 0.05, 0.2),
		Vector3(0.4, 0.05, 0.2),
		Vector3(0.6, 0.05, 0.2)
	]
	
	var colors = [
		Color(0.9, 0.9, 1.0, 0.7),  # Clear glass
		Color(0.2, 0.8, 0.3, 0.6),  # Green liquid
		Color(0.8, 0.7, 0.2, 0.6)   # Amber liquid
	]
	
	for i in range(positions.size()):
		var beaker = create_beaker(colors[i])
		beaker.position = positions[i]
		countertop.add_child(beaker)
	
	# Add a lab bottle (reagent bottle)
	var bottle = create_lab_bottle()
	bottle.position = Vector3(0.8, 0.05, 0.2)
	countertop.add_child(bottle)
	
	# Add a microscope
	var microscope = create_microscope()
	microscope.position = Vector3(-0.3, 0.05, 0)
	countertop.add_child(microscope)

func create_beaker(liquid_color):
	var beaker_node = Node3D.new()
	beaker_node.name = "Beaker"
	
	# Create beaker body
	var beaker_body = CSGCylinder3D.new()
	beaker_body.name = "BeakerBody"
	beaker_body.radius = 0.04
	beaker_body.height = 0.1
	beaker_body.position = Vector3(0, 0.05, 0)
	
	var glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.9, 0.9, 1.0, 0.4)
	glass_material.metallic = 0.1
	glass_material.roughness = 0.1
	glass_material.flags_transparent = true
	beaker_body.material = glass_material
	
	beaker_node.add_child(beaker_body)
	
	# Add liquid to the beaker
	var liquid = CSGCylinder3D.new()
	liquid.name = "Liquid"
	liquid.radius = 0.038
	liquid.height = 0.07
	liquid.position = Vector3(0, 0.035 - 0.015, 0)  # Adjust to be inside the beaker
	
	var liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = liquid_color
	liquid_material.flags_transparent = true
	liquid.material = liquid_material
	
	beaker_node.add_child(liquid)
	
	return beaker_node

func create_lab_bottle():
	var bottle_node = Node3D.new()
	bottle_node.name = "LabBottle"
	
	# Create bottle body
	var bottle_body = CSGCylinder3D.new()
	bottle_body.name = "BottleBody"
	bottle_body.radius = 0.035
	bottle_body.height = 0.12
	bottle_body.position = Vector3(0, 0.06, 0)
	
	var bottle_material = StandardMaterial3D.new()
	bottle_material.albedo_color = Color(0.6, 0.3, 0.1, 0.8)  # Amber bottle
	bottle_material.flags_transparent = true
	bottle_body.material = bottle_material
	
	bottle_node.add_child(bottle_body)
	
	# Add bottle neck
	var bottle_neck = CSGCylinder3D.new()
	bottle_neck.name = "BottleNeck"
	bottle_neck.radius = 0.015
	bottle_neck.height = 0.04
	bottle_neck.position = Vector3(0, 0.14, 0)
	bottle_neck.material = bottle_material
	
	bottle_node.add_child(bottle_neck)
	
	# Add cap
	var bottle_cap = CSGCylinder3D.new()
	bottle_cap.name = "BottleCap"
	bottle_cap.radius = 0.018
	bottle_cap.height = 0.015
	bottle_cap.position = Vector3(0, 0.17, 0)
	
	var cap_material = StandardMaterial3D.new()
	cap_material.albedo_color = Color(0.2, 0.2, 0.2)  # Dark cap
	bottle_cap.material = cap_material
	
	bottle_node.add_child(bottle_cap)
	
	return bottle_node

func create_microscope():
	var microscope_node = Node3D.new()
	microscope_node.name = "Microscope"
	
	# Create microscope base
	var base = CSGBox3D.new()
	base.name = "Base"
	base.size = Vector3(0.15, 0.02, 0.1)
	base.position = Vector3(0, 0.01, 0)
	
	var microscope_material = StandardMaterial3D.new()
	microscope_material.albedo_color = Color(0.2, 0.2, 0.2)  # Dark color
	base.material = microscope_material
	
	microscope_node.add_child(base)
	
	# Create microscope arm
	var arm = CSGBox3D.new()
	arm.name = "Arm"
	arm.size = Vector3(0.03, 0.15, 0.03)
	arm.position = Vector3(-0.05, 0.085, 0)
	arm.material = microscope_material
	
	microscope_node.add_child(arm)
	
	# Create microscope head
	var head = CSGBox3D.new()
	head.name = "Head"
	head.size = Vector3(0.1, 0.06, 0.05)
	head.position = Vector3(0, 0.16, 0)
	head.material = microscope_material
	
	microscope_node.add_child(head)
	
	# Create eyepiece
	var eyepiece = CSGCylinder3D.new()
	eyepiece.name = "Eyepiece"
	eyepiece.radius = 0.015
	eyepiece.height = 0.06
	eyepiece.position = Vector3(0, 0.19, -0.04)
	eyepiece.rotation_degrees = Vector3(90, 0, 0)
	eyepiece.material = microscope_material
	
	microscope_node.add_child(eyepiece)
	
	return microscope_node

func add_lighting(desk_base):
	# Add subtle lighting to illuminate the desk
	var light = OmniLight3D.new()
	light.name = "DeskLight"
	light.position = Vector3(0, 1.5, 0.5)
	light.light_energy = 1.0
	light.light_color = Color(0.9, 0.9, 1.0)  # Slightly cool white light
	light.shadow_enabled = true
	
	desk_base.add_child(light)
