
# Yves Tanguy-inspired piston/rotor mechanism
class_name TanguyPistonRotor
extends Node3D

var piston_rod: Node3D
var rotor_disc: Node3D
var connecting_arm: Node3D
var piston_tip: Node3D

var rotation_speed: float = 1.0
var piston_amplitude: float = 2.0
var phase_offset: float = 0.0
var current_rotation: float = 0.0

# Mechanism components
var base_cylinder: CSGCylinder3D
var rotor_assembly: Node3D
var piston_assembly: Node3D

func setup_mechanism(config: Dictionary):
	"""Configure the Tanguy mechanism with dark, biomechanical aesthetics"""
	rotation_speed = config.get("rotation_speed", 1.0)
	piston_amplitude = config.get("piston_amplitude", 2.0)
	phase_offset = config.get("phase_offset", 0.0)
	
	var material = config.get("material", null)
	
	create_base_assembly(material)
	create_rotor_assembly(material, config.get("rotor_radius", 1.0))
	create_piston_assembly(material, config.get("piston_length", 3.0))
	connect_assemblies()

func create_base_assembly(material: StandardMaterial3D):
	"""Create the dark mechanical base"""
	base_cylinder = CSGCylinder3D.new()
	base_cylinder.height = 1.5
	base_cylinder.radius = 0.8
	base_cylinder.sides = 8  # Octagonal for mechanical feel
	base_cylinder.material = material
	add_child(base_cylinder)
	
	# Add mechanical details
	for i in range(4):
		var detail = CSGBox3D.new()
		detail.size = Vector3(0.3, 0.1, 0.1)
		var angle = i * TAU / 4
		detail.position = Vector3(cos(angle) * 0.9, 0.5, sin(angle) * 0.9)
		detail.material = material
		base_cylinder.add_child(detail)

func create_rotor_assembly(material: StandardMaterial3D, radius: float):
	"""Create the rotating disc mechanism"""
	rotor_assembly = Node3D.new()
	rotor_assembly.name = "RotorAssembly"
	rotor_assembly.position = Vector3(0, 0.75, 0)
	add_child(rotor_assembly)
	
	# Main rotor disc
	rotor_disc = CSGCylinder3D.new()
	rotor_disc.height = 0.2
	rotor_disc.radius = radius
	rotor_disc.sides = 16
	rotor_disc.material = material
	rotor_assembly.add_child(rotor_disc)
	
	# Rotor arms (Tanguy-style biomechanical)
	for i in range(3):
		var arm = CSGBox3D.new()
		arm.size = Vector3(radius * 1.5, 0.1, 0.3)
		arm.position = Vector3(radius * 0.5, 0, 0)
		arm.rotation_degrees = Vector3(0, i * 120, 0)
		arm.material = material
		rotor_disc.add_child(arm)
		
		# Organic bulges on arms
		var bulge = CSGSphere3D.new()
		bulge.radius = 0.2
		bulge.position = Vector3(radius * 0.8, 0, 0)
		bulge.material = material
		arm.add_child(bulge)

func create_piston_assembly(material: StandardMaterial3D, length: float):
	"""Create the extending piston mechanism"""
	piston_assembly = Node3D.new()
	piston_assembly.name = "PistonAssembly"
	add_child(piston_assembly)
	
	# Piston rod
	piston_rod = CSGCylinder3D.new()
	piston_rod.height = length
	piston_rod.radius = 0.15
	piston_rod.sides = 8
	piston_rod.material = material
	piston_assembly.add_child(piston_rod)
	
	# Piston tip (attachment point for Niki object)
	piston_tip = Node3D.new()
	piston_tip.name = "PistonTip"
	piston_tip.position = Vector3(0, length * 0.5, 0)
	piston_rod.add_child(piston_tip)
	
	# Tip detail
	var tip_sphere = CSGSphere3D.new()
	tip_sphere.radius = 0.3
	tip_sphere.material = material
	piston_tip.add_child(tip_sphere)

func connect_assemblies():
	"""Create connecting arm between rotor and piston"""
	connecting_arm = Node3D.new()
	connecting_arm.name = "ConnectingArm"
	rotor_assembly.add_child(connecting_arm)
	
	# Position on rotor edge
	connecting_arm.position = Vector3(rotor_disc.radius * 0.7, 0, 0)

func start_kinetic_motion():
	"""Begin the kinetic animation"""
	current_rotation = phase_offset

func update_motion(delta: float):
	"""Update the kinetic motion of the mechanism"""
	current_rotation += rotation_speed * delta
	
	# Rotate the rotor
	rotor_assembly.rotation_degrees.y = rad_to_deg(current_rotation)
	
	# Calculate piston extension based on rotor position
	var piston_extension = sin(current_rotation) * piston_amplitude
	piston_assembly.position.y = 0.75 + piston_extension
	
	# Add slight rotation to piston for organic feel
	piston_assembly.rotation_degrees.z = sin(current_rotation * 0.5) * 5.0

func get_piston_tip() -> Node3D:
	"""Get the piston tip for attaching Niki objects"""
	return piston_tip

func get_motion_data() -> Dictionary:
	"""Return current motion data for Niki objects"""
	return {
		"rotation": current_rotation,
		"extension": sin(current_rotation) * piston_amplitude,
		"speed": rotation_speed
	}
