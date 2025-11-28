@tool
extends CSGCombiner3D

# Agent-Necromancer: Procedural Death Skull Generator (Foundation)
# Agent-Osteologist: Enhanced with anatomical accuracy
# Generates a skull using CSG primitives with realistic bone structure.

@export var random_seed: int = 0:
	set(value):
		random_seed = value
		if is_inside_tree():
			generate_skull()

@export var bone_color: Color = Color(0.9, 0.85, 0.8, 1.0):
	set(value):
		bone_color = value
		update_material()

@export_group("Cranium")
@export var cranium_radius: float = 0.5
@export var cranium_elongation: float = 1.2 # Vertical stretch

@export_group("Jaw")
@export var jaw_width: float = 0.4
@export var jaw_height: float = 0.35
@export var jaw_protrusion: float = 0.4

@export_group("Features")
@export var eye_socket_radius: float = 0.15
@export var eye_spacing: float = 0.25
@export var eye_height: float = 0.1
@export var nose_width: float = 0.1
@export var nose_height: float = 0.15

@export_group("Teeth")
@export var enable_teeth: bool = true
@export var tooth_count: int = 8

var _rng = RandomNumberGenerator.new()

func _ready():
	generate_skull()

func generate_skull():
	# Initialize RNG
	if random_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = random_seed
	
	# Clear existing children to avoid duplicates on regen
	for child in get_children():
		child.queue_free()
	
	# 1. Cranium (Base Sphere) - Agent-Necromancer's foundation
	var cranium = CSGSphere3D.new()
	cranium.name = "Cranium"
	cranium.radius = cranium_radius
	cranium.scale = Vector3(1.0, cranium_elongation, 1.1) # Slightly longer back-to-front
	cranium.radial_segments = 24
	cranium.rings = 16
	add_child(cranium)
	
	# 2. Temporal Bones (Agent-Osteologist addition)
	_add_temporal_bones()
	
	# 3. Occipital Bone (back of skull) - Agent-Osteologist
	var occipital = CSGSphere3D.new()
	occipital.name = "Occipital"
	occipital.radius = cranium_radius * 0.7
	occipital.position = Vector3(0, -0.1, -cranium_radius * 0.8)
	add_child(occipital)
	
	# 4. Foramen Magnum (hole for spinal cord) - Agent-Osteologist
	_add_subtraction_sphere("ForamenMagnum", Vector3(0, -cranium_radius * 0.9, -cranium_radius * 0.5), 0.12)
	
	# 5. Maxilla (Upper jaw with teeth sockets) - Agent-Osteologist
	_add_maxilla()
	
	# 6. Mandible (Lower jaw) - Enhanced from Agent-Necromancer's jaw
	var jaw = CSGBox3D.new()
	jaw.name = "Mandible"
	jaw.size = Vector3(jaw_width, jaw_height * 0.6, jaw_protrusion)
	jaw.position = Vector3(0, -cranium_radius * 0.95, cranium_radius * 0.4)
	add_child(jaw)
	
	# 7. Mandibular Ramus (jaw connection to skull)
	_add_mandibular_ramus()
	
	# 8. Zygomatic Bones (Cheekbones) - Agent-Necromancer's foundation
	var cheek_left = CSGSphere3D.new()
	cheek_left.name = "ZygomaticLeft"
	cheek_left.radius = 0.15
	cheek_left.position = Vector3(-jaw_width * 0.8, -cranium_radius * 0.5, 0.1)
	add_child(cheek_left)
	
	var cheek_right = CSGSphere3D.new()
	cheek_right.name = "ZygomaticRight"
	cheek_right.radius = 0.15
	cheek_right.position = Vector3(jaw_width * 0.8, -cranium_radius * 0.5, 0.1)
	add_child(cheek_right)
	
	# 9. Eye Sockets (Orbits) - Agent-Necromancer's foundation
	_add_subtraction_sphere("OrbitLeft", Vector3(-eye_spacing * 0.5, eye_height, cranium_radius * 0.8), eye_socket_radius)
	_add_subtraction_sphere("OrbitRight", Vector3(eye_spacing * 0.5, eye_height, cranium_radius * 0.8), eye_socket_radius)
	
	# 10. Nasal Cavity - Agent-Necromancer's foundation, enhanced
	var nose = CSGCylinder3D.new()
	nose.name = "NasalCavity"
	nose.operation = CSGShape3D.OPERATION_SUBTRACTION
	nose.cone = true
	nose.radius = nose_width
	nose.height = nose_height
	nose.sides = 3 # Triangular aperture
	nose.position = Vector3(0, -0.1, cranium_radius * 0.9)
	nose.rotation_degrees = Vector3(-15, 0, 0)
	add_child(nose)
	
	# 11. Teeth - Agent-Osteologist addition
	if enable_teeth:
		_add_teeth()
	
	# Apply Material
	update_material()

# Agent-Osteologist: Add temporal bones (sides of skull)
func _add_temporal_bones():
	var temporal_left = CSGSphere3D.new()
	temporal_left.name = "TemporalLeft"
	temporal_left.radius = 0.18
	temporal_left.position = Vector3(-cranium_radius * 0.85, -0.15, 0)
	temporal_left.scale = Vector3(0.8, 1.0, 1.2)
	add_child(temporal_left)
	
	var temporal_right = CSGSphere3D.new()
	temporal_right.name = "TemporalRight"
	temporal_right.radius = 0.18
	temporal_right.position = Vector3(cranium_radius * 0.85, -0.15, 0)
	temporal_right.scale = Vector3(0.8, 1.0, 1.2)
	add_child(temporal_right)

# Agent-Osteologist: Add maxilla (upper jaw)
func _add_maxilla():
	var maxilla = CSGBox3D.new()
	maxilla.name = "Maxilla"
	maxilla.size = Vector3(jaw_width * 0.9, 0.25, jaw_protrusion * 0.8)
	maxilla.position = Vector3(0, -cranium_radius * 0.6, cranium_radius * 0.55)
	add_child(maxilla)

# Agent-Osteologist: Add mandibular ramus (jaw hinge)
func _add_mandibular_ramus():
	var ramus_left = CSGBox3D.new()
	ramus_left.name = "RamusLeft"
	ramus_left.size = Vector3(0.08, 0.3, 0.15)
	ramus_left.position = Vector3(-jaw_width * 0.45, -cranium_radius * 0.75, cranium_radius * 0.15)
	ramus_left.rotation_degrees = Vector3(0, 0, -15)
	add_child(ramus_left)
	
	var ramus_right = CSGBox3D.new()
	ramus_right.name = "RamusRight"
	ramus_right.size = Vector3(0.08, 0.3, 0.15)
	ramus_right.position = Vector3(jaw_width * 0.45, -cranium_radius * 0.75, cranium_radius * 0.15)
	ramus_right.rotation_degrees = Vector3(0, 0, 15)
	add_child(ramus_right)

# Agent-Osteologist: Add procedural teeth
func _add_teeth():
	var tooth_spacing = jaw_width / (tooth_count + 1)
	
	# Upper teeth
	for i in range(tooth_count):
		var tooth = CSGCylinder3D.new()
		tooth.name = "UpperTooth_%d" % i
		tooth.radius = 0.02
		tooth.height = 0.08
		tooth.sides = 8
		var x_pos = -jaw_width * 0.4 + (i * tooth_spacing)
		tooth.position = Vector3(x_pos, -cranium_radius * 0.55, cranium_radius * 0.65)
		tooth.rotation_degrees = Vector3(80, 0, 0)
		add_child(tooth)
	
	# Lower teeth
	for i in range(tooth_count):
		var tooth = CSGCylinder3D.new()
		tooth.name = "LowerTooth_%d" % i
		tooth.radius = 0.02
		tooth.height = 0.08
		tooth.sides = 8
		var x_pos = -jaw_width * 0.35 + (i * tooth_spacing)
		tooth.position = Vector3(x_pos, -cranium_radius * 0.88, cranium_radius * 0.5)
		tooth.rotation_degrees = Vector3(100, 0, 0)
		add_child(tooth)

func _add_subtraction_sphere(name_str: String, pos: Vector3, rad: float):
	var sub = CSGSphere3D.new()
	sub.name = name_str
	sub.operation = CSGShape3D.OPERATION_SUBTRACTION
	sub.radius = rad
	sub.position = pos
	sub.radial_segments = 16
	add_child(sub)

func update_material():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = bone_color
	mat.roughness = 0.9
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	# Agent-Osteologist: Add subtle subsurface for bone translucency
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.1
	mat.subsurf_scatter_skin_mode = false
	self.material_override = mat
