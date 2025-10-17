extends Node3D
class_name SurrealKineticSculpture

## Satterwhite-inspired kinetic sculpture combining Yves Tanguy and Niki de Saint Phalle aesthetics
## Features 3 black Tanguy pistons/rotors driving colorful organic Niki de Saint Phalle forms

@export var sculpture_scale: float = 1.0
@export var piston_speed_multiplier: float = 1.0
@export var color_intensity: float = 1.2
@export var mechanical_precision: float = 0.95
@export var organic_distortion: float = 0.8

# Animation parameters
@export var rotation_speeds: Array[float] = [0.5, 0.7, 0.3]  # Different speeds for each piston
@export var piston_amplitudes: Array[float] = [2.0, 1.5, 2.5]  # Forward/backward motion range
@export var phase_offsets: Array[float] = [0.0, 120.0, 240.0]  # Degrees offset for variation

# Components
var tanguy_mechanisms: Array[TanguyPistonRotor] = []
var niki_objects: Array[NikiOrganicForm] = []
var base_platform: Node3D
var material_system: SurrealMaterialSystem

# Containers
var sculpture_container: Node3D
var lighting_system: Node3D

func _ready():
	setup_sculpture_base()
	create_material_system()
	build_tanguy_mechanisms()
	create_niki_extensions()
	setup_kinetic_lighting()
	start_kinetic_animation()

func setup_sculpture_base():
	"""Create the main sculpture container and base platform"""
	sculpture_container = Node3D.new()
	sculpture_container.name = "SurrealSculpture"
	sculpture_container.scale = Vector3.ONE * sculpture_scale
	add_child(sculpture_container)
	
	# Create surreal base platform (Tanguy-inspired)
	base_platform = Node3D.new()
	base_platform.name = "TanguyBase"
	sculpture_container.add_child(base_platform)
	
	create_base_platform()

func create_base_platform():
	"""Create the dark, mechanical base inspired by Tanguy's landscapes"""
	# Main platform
	var platform = CSGCylinder3D.new()
	platform.height = 0.8

	platform.radius = 9.0
	platform.sides = 16
	
	# Dark metallic material
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(0.1, 0.1, 0.12, 1.0)
	base_material.metallic = 0.8
	base_material.roughness = 0.3
	platform.material = base_material
	
	base_platform.add_child(platform)
	
	# Add Tanguy-style protrusions
	for i in range(5):
		var protrusion = CSGSphere3D.new()
		protrusion.radius = randf_range(0.5, 1.2)
		var angle = i * TAU / 5
		protrusion.position = Vector3(
			cos(angle) * 6.0,
			randf_range(-0.2, 0.8),
			sin(angle) * 6.0
		)
		protrusion.material = base_material
		base_platform.add_child(protrusion)

func create_material_system():
	"""Initialize the surreal material system"""
	material_system = SurrealMaterialSystem.new()
	add_child(material_system)

func build_tanguy_mechanisms():
	"""Create the three black Tanguy-inspired piston/rotor mechanisms"""
	tanguy_mechanisms.clear()
	
	for i in range(3):
		var mechanism = TanguyPistonRotor.new()
		mechanism.name = "TanguyMechanism%d" % (i + 1)
		
		# Position mechanisms in triangular formation
		var angle = i * TAU / 3
		var radius = 4.0
		mechanism.position = Vector3(
			cos(angle) * radius,
			1.5,
			sin(angle) * radius
		)
		
		# Configure each mechanism
		mechanism.setup_mechanism({
			"piston_length": 3.0 + i * 0.5,
			"rotor_radius": 1.0 + i * 0.2,
			"material": material_system.get_tanguy_material(),
			"rotation_speed": rotation_speeds[i] * piston_speed_multiplier,
			"piston_amplitude": piston_amplitudes[i],
			"phase_offset": deg_to_rad(phase_offsets[i])
		})
		
		sculpture_container.add_child(mechanism)
		tanguy_mechanisms.append(mechanism)

func create_niki_extensions():
	"""Create Niki de Saint Phalle-inspired organic forms attached to pistons"""
	niki_objects.clear()
	
	for i in range(3):
		var niki_form = NikiOrganicForm.new()
		niki_form.name = "NikiForm%d" % (i + 1)
		
		# Attach to corresponding Tanguy mechanism
		var mechanism = tanguy_mechanisms[i]
		var attachment_point = mechanism.get_piston_tip()
		attachment_point.add_child(niki_form)
		
		# Configure organic form
		niki_form.setup_organic_form({
			"base_size": randf_range(1.5, 2.5),
			"color_scheme": i,  # Different color scheme for each
			"organic_complexity": 3 + i,
			"surface_detail": organic_distortion,
			"material_system": material_system
		})
		
		niki_objects.append(niki_form)

func setup_kinetic_lighting():
	"""Create dynamic lighting that responds to the kinetic motion"""
	lighting_system = Node3D.new()
	lighting_system.name = "KineticLighting"
	add_child(lighting_system)
	
	# Main sculpture light
	var key_light = DirectionalLight3D.new()
	key_light.light_energy = 0.8
	key_light.light_color = Color(0.95, 0.95, 1.0)
	key_light.position = Vector3(5, 10, 5)
	key_light.look_at_from_position(key_light.position, Vector3.ZERO, Vector3.UP)
	key_light.shadow_enabled = true
	lighting_system.add_child(key_light)
	
	# Colored accent lights that follow the Niki objects
	for i in range(3):
		var accent_light = OmniLight3D.new()
		var colors = [
			Color(1.0, 0.3, 0.6),  # Pink
			Color(0.3, 0.8, 1.0),  # Blue
			Color(1.0, 0.8, 0.2)   # Yellow
		]
		accent_light.light_color = colors[i]
		accent_light.light_energy = 0.6
		accent_light.omni_range = 8.0
		
		# Attach to Niki object for dynamic lighting
		niki_objects[i].add_child(accent_light)

func start_kinetic_animation():
	"""Begin the kinetic animation sequence"""
	for i in range(tanguy_mechanisms.size()):
		var mechanism = tanguy_mechanisms[i]
		mechanism.start_kinetic_motion()

func _process(delta):
	"""Update the kinetic sculpture animation"""
	# Update each mechanism
	for mechanism in tanguy_mechanisms:
		mechanism.update_motion(delta)
	
	# Update Niki forms based on motion
	for i in range(niki_objects.size()):
		var niki_form = niki_objects[i]
		var mechanism = tanguy_mechanisms[i]
		niki_form.update_based_on_motion(mechanism.get_motion_data())
