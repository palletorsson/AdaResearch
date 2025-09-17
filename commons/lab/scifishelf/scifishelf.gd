extends Node3D
class_name SciFiShelf

# Futuristic Holographic Laboratory Shelf
# With quantum equipment and plasma containment systems

@export var shelf_width: float = 2.5
@export var shelf_depth: float = 0.5
@export var shelf_height: float = 0.08
@export var holo_glow_intensity: float = 1.0
@export var equipment_scale: float = 1.0

var shelf_material: StandardMaterial3D
var holo_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var metal_material: StandardMaterial3D

func _ready():
	setup_materials()
	create_holographic_shelf()
	populate_with_equipment()
	setup_lighting_system()
	add_particle_effects()

func setup_materials():
	# Futuristic shelf material
	shelf_material = StandardMaterial3D.new()
	shelf_material.albedo_color = Color(0.15, 0.15, 0.2, 1)
	shelf_material.metallic = 0.9
	shelf_material.roughness = 0.1
	shelf_material.emission_enabled = true
	shelf_material.emission = Color(0.05, 0.1, 0.2, 1) * holo_glow_intensity
	
	# Holographic glow material
	holo_material = StandardMaterial3D.new()
	holo_material.albedo_color = Color(0.0, 0.8, 1.0, 1)
	holo_material.emission_enabled = true
	holo_material.emission = Color(0.0, 0.5, 0.8, 1) * holo_glow_intensity
	holo_material.metallic = 0.8
	holo_material.roughness = 0.2
	
	# Advanced glass
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.8, 0.9, 1.0, 0.2)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.0
	glass_material.roughness = 0.0
	glass_material.refraction_enabled = true
	
	# Future metal
	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.1, 0.1, 0.15, 1)
	metal_material.metallic = 0.95
	metal_material.roughness = 0.05

func create_holographic_shelf():
	var shelf_group = Node3D.new()
	shelf_group.name = "HolographicShelf"
	add_child(shelf_group)
	
	# Main shelf platform
	var shelf_platform = MeshInstance3D.new()
	shelf_platform.name = "ShelfPlatform"
	var shelf_mesh = BoxMesh.new()
	shelf_mesh.size = Vector3(shelf_width, shelf_height, shelf_depth)
	shelf_platform.mesh = shelf_mesh
	shelf_platform.material_override = shelf_material
	shelf_group.add_child(shelf_platform)
	
	# Holographic edge lights
	create_holo_edges(shelf_group)
	
	# Support structure
	create_support_structure(shelf_group)

func create_holo_edges(parent: Node3D):
	var edge_positions = [
		Vector3(-shelf_width/2 + 0.05, shelf_height/2 + 0.1, 0),
		Vector3(shelf_width/2 - 0.05, shelf_height/2 + 0.1, 0)
	]
	
	for i in range(edge_positions.size()):
		var edge = MeshInstance3D.new()
		edge.name = "HoloEdge" + str(i + 1)
		edge.position = edge_positions[i]
		
		var edge_mesh = BoxMesh.new()
		edge_mesh.size = Vector3(0.05, 0.2, shelf_depth)
		edge.mesh = edge_mesh
		edge.material_override = holo_material
		
		parent.add_child(edge)

func create_support_structure(parent: Node3D):
	# Floating support pillars
	var support_positions = [
		Vector3(-shelf_width/3, -0.3, shelf_depth/4),
		Vector3(shelf_width/3, -0.3, shelf_depth/4),
		Vector3(-shelf_width/3, -0.3, -shelf_depth/4),
		Vector3(shelf_width/3, -0.3, -shelf_depth/4)
	]
	
	for i in range(support_positions.size()):
		var support = MeshInstance3D.new()
		support.name = "FloatingSupport" + str(i + 1)
		support.position = support_positions[i]
		
		var support_mesh = CylinderMesh.new()
		support_mesh.height = 0.6
		support_mesh.top_radius = 0.02
		support_mesh.bottom_radius = 0.03
		support.mesh = support_mesh
		support.material_override = holo_material
		
		parent.add_child(support)

func populate_with_equipment():
	var equipment_group = Node3D.new()
	equipment_group.name = "QuantumEquipment"
	add_child(equipment_group)
	
	# Quantum microscope
	create_quantum_microscope(equipment_group, Vector3(-0.8, shelf_height/2, 0))
	
	# Plasma containment flasks
	create_plasma_flasks(equipment_group, Vector3(-0.3, shelf_height/2, 0))
	
	# Nano tube array
	create_nanotube_array(equipment_group, Vector3(0.3, shelf_height/2, 0))
	
	# Quantum scales
	create_quantum_scales(equipment_group, Vector3(0.8, shelf_height/2, 0))
	
	# Data tablets
	create_data_tablets(equipment_group, Vector3(-1.0, shelf_height/2 + 0.02, -0.15))
	
	# Holographic calipers
	create_holo_calipers(equipment_group, Vector3(1.1, shelf_height/2, 0.1))

func create_quantum_microscope(parent: Node3D, pos: Vector3):
	var microscope = Node3D.new()
	microscope.name = "QuantumMicroscope"
	microscope.position = pos
	parent.add_child(microscope)
	
	# Base
	var base = MeshInstance3D.new()
	base.name = "MicroscopeBase"
	base.position.y = 0.06 * equipment_scale
	var base_mesh = CylinderMesh.new()
	base_mesh.height = 0.12 * equipment_scale
	base_mesh.top_radius = 0.18 * equipment_scale
	base_mesh.bottom_radius = 0.18 * equipment_scale
	base.mesh = base_mesh
	base.material_override = metal_material
	microscope.add_child(base)
	
	# Holographic column
	var column = MeshInstance3D.new()
	column.name = "HoloColumn"
	column.position.y = 0.35 * equipment_scale
	var column_mesh = CylinderMesh.new()
	column_mesh.height = 0.5 * equipment_scale
	column_mesh.top_radius = 0.025 * equipment_scale
	column_mesh.bottom_radius = 0.025 * equipment_scale
	column.mesh = column_mesh
	column.material_override = holo_material
	microscope.add_child(column)
	
	# Quantum eyepiece
	var eyepiece = MeshInstance3D.new()
	eyepiece.name = "QuantumEyepiece"
	eyepiece.position.y = 0.65 * equipment_scale
	var eye_mesh = CylinderMesh.new()
	eye_mesh.height = 0.1 * equipment_scale
	eye_mesh.top_radius = 0.035 * equipment_scale
	eye_mesh.bottom_radius = 0.035 * equipment_scale
	eyepiece.mesh = eye_mesh
	var eye_material = holo_material.duplicate()
	eye_material.emission = Color(0.2, 0.6, 1.0, 1) * holo_glow_intensity
	eyepiece.material_override = eye_material
	microscope.add_child(eyepiece)

func create_plasma_flasks(parent: Node3D, pos: Vector3):
	var flask_group = Node3D.new()
	flask_group.name = "PlasmaFlasks"
	flask_group.position = pos
	parent.add_child(flask_group)
	
	var flask_data = [
		[Vector3(0, 0.1, 0), 0.08, Color(0.2, 0.6, 1.0, 1)],
		[Vector3(0.18, 0.08, 0), 0.06, Color(1.0, 0.4, 0.0, 1)],
		[Vector3(-0.18, 0.06, 0), 0.05, Color(0.0, 1.0, 0.5, 1)]
	]
	
	for i in range(flask_data.size()):
		var data = flask_data[i]
		
		# Glass flask
		var flask = MeshInstance3D.new()
		flask.name = "Flask" + str(i + 1)
		flask.position = data[0] * equipment_scale
		var flask_mesh = SphereMesh.new()
		flask_mesh.radius = data[1] * equipment_scale
		flask_mesh.height = data[1] * 1.5 * equipment_scale
		flask.mesh = flask_mesh
		flask.material_override = glass_material
		flask_group.add_child(flask)
		
		# Plasma energy inside
		var plasma = MeshInstance3D.new()
		plasma.name = "Plasma" + str(i + 1)
		plasma.position = data[0] * equipment_scale
		var plasma_mesh = SphereMesh.new()
		plasma_mesh.radius = data[1] * 0.7 * equipment_scale
		plasma_mesh.height = data[1] * 1.0 * equipment_scale
		plasma.mesh = plasma_mesh
		
		var plasma_material = StandardMaterial3D.new()
		plasma_material.albedo_color = data[2]
		plasma_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		plasma_material.emission_enabled = true
		plasma_material.emission = data[2] * 0.5 * holo_glow_intensity
		plasma.material_override = plasma_material
		flask_group.add_child(plasma)

func create_nanotube_array(parent: Node3D, pos: Vector3):
	var array_group = Node3D.new()
	array_group.name = "NanoTubeArray"
	array_group.position = pos
	parent.add_child(array_group)
	
	# Base rack
	var rack = MeshInstance3D.new()
	rack.name = "NanoRack"
	rack.position.y = 0.02 * equipment_scale
	var rack_mesh = BoxMesh.new()
	rack_mesh.size = Vector3(0.3, 0.04, 0.1) * equipment_scale
	rack.mesh = rack_mesh
	rack.material_override = metal_material
	array_group.add_child(rack)
	
	# Nano tubes with different fluids
	var tube_positions = [
		Vector3(-0.12, 0.12, 0),
		Vector3(-0.04, 0.12, 0),
		Vector3(0.04, 0.12, 0),
		Vector3(0.12, 0.12, 0)
	]
	
	var fluid_colors = [
		Color(1.0, 0.3, 0.0, 0.8),
		Color(0.0, 1.0, 0.4, 0.7),
		Color(0.8, 0.0, 1.0, 0.6),
		Color(0.0, 0.8, 1.0, 0.7)
	]
	
	for i in range(tube_positions.size()):
		# Glass tube
		var tube = MeshInstance3D.new()
		tube.name = "NanoTube" + str(i + 1)
		tube.position = tube_positions[i] * equipment_scale
		var tube_mesh = CylinderMesh.new()
		tube_mesh.height = 0.16 * equipment_scale
		tube_mesh.top_radius = 0.01 * equipment_scale
		tube_mesh.bottom_radius = 0.01 * equipment_scale
		tube.mesh = tube_mesh
		tube.material_override = glass_material
		array_group.add_child(tube)
		
		# Nano fluid
		var fluid = MeshInstance3D.new()
		fluid.name = "NanoFluid" + str(i + 1)
		fluid.position = tube_positions[i] * equipment_scale
		fluid.position.y -= 0.04 * equipment_scale
		var fluid_mesh = CylinderMesh.new()
		fluid_mesh.height = 0.08 * equipment_scale
		fluid_mesh.top_radius = 0.008 * equipment_scale
		fluid_mesh.bottom_radius = 0.008 * equipment_scale
		fluid.mesh = fluid_mesh
		
		var fluid_material = StandardMaterial3D.new()
		fluid_material.albedo_color = fluid_colors[i]
		fluid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fluid_material.emission_enabled = true
		fluid_material.emission = fluid_colors[i] * 0.3 * holo_glow_intensity
		fluid.material_override = fluid_material
		array_group.add_child(fluid)

func create_quantum_scales(parent: Node3D, pos: Vector3):
	var scales = Node3D.new()
	scales.name = "QuantumScales"
	scales.position = pos
	parent.add_child(scales)
	
	# Base
	var base = MeshInstance3D.new()
	base.name = "ScaleBase"
	base.position.y = 0.03 * equipment_scale
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(0.35, 0.06, 0.25) * equipment_scale
	base.mesh = base_mesh
	base.material_override = metal_material
	scales.add_child(base)
	
	# Holographic beam
	var beam = MeshInstance3D.new()
	beam.name = "HoloBeam"
	beam.position.y = 0.4 * equipment_scale
	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(0.5, 0.02, 0.03) * equipment_scale
	beam.mesh = beam_mesh
	beam.material_override = holo_material
	scales.add_child(beam)
	
	# Quantum pans
	var pan_positions = [Vector3(-0.22, 0.36, 0), Vector3(0.22, 0.36, 0)]
	for i in range(pan_positions.size()):
		var pan = MeshInstance3D.new()
		pan.name = "QuantumPan" + str(i + 1)
		pan.position = pan_positions[i] * equipment_scale
		var pan_mesh = CylinderMesh.new()
		pan_mesh.height = 0.02 * equipment_scale
		pan_mesh.top_radius = 0.08 * equipment_scale
		pan_mesh.bottom_radius = 0.06 * equipment_scale
		pan.mesh = pan_mesh
		pan.material_override = holo_material
		scales.add_child(pan)

func create_data_tablets(parent: Node3D, pos: Vector3):
	var tablet_group = Node3D.new()
	tablet_group.name = "DataTablets"
	tablet_group.position = pos
	parent.add_child(tablet_group)
	
	var tablet_data = [
		[Vector3(0, 0, 0), Color(0.2, 0.6, 1.0, 1)],
		[Vector3(0.02, 0.02, 0), Color(1.0, 0.4, 0.0, 1)],
		[Vector3(-0.02, 0.04, 0), Color(0.0, 1.0, 0.5, 1)]
	]
	
	for i in range(tablet_data.size()):
		var data = tablet_data[i]
		
		# Tablet body
		var tablet = MeshInstance3D.new()
		tablet.name = "Tablet" + str(i + 1)
		tablet.position = data[0] * equipment_scale
		if i > 0:
			tablet.rotation.y = (i - 1) * 0.1
		var tablet_mesh = BoxMesh.new()
		tablet_mesh.size = Vector3(0.18, 0.015, 0.25) * equipment_scale
		tablet.mesh = tablet_mesh
		
		var tablet_material = StandardMaterial3D.new()
		tablet_material.albedo_color = Color(0.05, 0.05, 0.08, 1)
		tablet_material.metallic = 0.9
		tablet_material.roughness = 0.1
		tablet_material.emission_enabled = true
		tablet_material.emission = Color(0.02, 0.05, 0.1, 1) * holo_glow_intensity
		tablet.material_override = tablet_material
		tablet_group.add_child(tablet)
		
		# Screen
		var screen = MeshInstance3D.new()
		screen.name = "Screen" + str(i + 1)
		screen.position = data[0] * equipment_scale
		screen.position.y += 0.01 * equipment_scale
		if i > 0:
			screen.rotation.y = (i - 1) * 0.1
		var screen_mesh = BoxMesh.new()
		screen_mesh.size = Vector3(0.16, 0.005, 0.22) * equipment_scale
		screen.mesh = screen_mesh
		
		var screen_material = StandardMaterial3D.new()
		screen_material.albedo_color = data[1]
		screen_material.emission_enabled = true
		screen_material.emission = data[1] * 0.3 * holo_glow_intensity
		screen.material_override = screen_material
		tablet_group.add_child(screen)

func create_holo_calipers(parent: Node3D, pos: Vector3):
	var calipers = Node3D.new()
	calipers.name = "HolographicCalipers"
	calipers.position = pos
	parent.add_child(calipers)
	
	# Caliper arms
	var arm_positions = [
		[Vector3(-0.01, 0.08, 0), 0.0998334],
		[Vector3(0.01, 0.08, 0), -0.198669]
	]
	
	for i in range(arm_positions.size()):
		var arm = MeshInstance3D.new()
		arm.name = "CaliperArm" + str(i + 1)
		arm.position = arm_positions[i][0] * equipment_scale
		arm.rotation.z = arm_positions[i][1]
		var arm_mesh = BoxMesh.new()
		arm_mesh.size = Vector3(0.01, 0.18, 0.015) * equipment_scale
		arm.mesh = arm_mesh
		arm.material_override = holo_material
		calipers.add_child(arm)
	
	# Pivot point
	var pivot = MeshInstance3D.new()
	pivot.name = "CaliperPivot"
	pivot.position.y = 0.16 * equipment_scale
	var pivot_mesh = SphereMesh.new()
	pivot_mesh.radius = 0.012 * equipment_scale
	pivot_mesh.height = 0.024 * equipment_scale
	pivot.mesh = pivot_mesh
	
	var pivot_material = holo_material.duplicate()
	pivot_material.emission = Color(0.2, 0.6, 1.0, 1) * holo_glow_intensity
	pivot.material_override = pivot_material
	calipers.add_child(pivot)

func setup_lighting_system():
	var lighting = Node3D.new()
	lighting.name = "QuantumLighting"
	add_child(lighting)
	
	# Main directional light
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.position = Vector3(0, 3, 3)
	main_light.look_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 0.6
	main_light.light_color = Color(0.9, 0.95, 1, 1)
	main_light.shadow_enabled = true
	lighting.add_child(main_light)
	
	# Blue accent light
	var blue_light = OmniLight3D.new()
	blue_light.name = "BlueAccentLight"
	blue_light.position = Vector3(-0.8, 1.8, 0.5)
	blue_light.light_color = Color(0.3, 0.6, 1, 1)
	blue_light.light_energy = 0.8 * holo_glow_intensity
	blue_light.omni_range = 4.0
	lighting.add_child(blue_light)
	
	# Orange accent light
	var orange_light = OmniLight3D.new()
	orange_light.name = "OrangeAccentLight"
	orange_light.position = Vector3(0.8, 1.8, 0.5)
	orange_light.light_color = Color(1, 0.5, 0.1, 1)
	orange_light.light_energy = 0.6 * holo_glow_intensity
	orange_light.omni_range = 3.5
	lighting.add_child(orange_light)
	
	# Under-shelf glow
	var under_glow = OmniLight3D.new()
	under_glow.name = "UnderShelfGlow"
	under_glow.position = Vector3(0, -0.2, 0)
	under_glow.light_color = Color(0.2, 0.8, 1, 1)
	under_glow.light_energy = 0.4 * holo_glow_intensity
	under_glow.omni_range = 2.0
	lighting.add_child(under_glow)
	
	# Environment
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.08, 0.12, 1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.3, 0.4, 0.6, 1)
	environment.ambient_light_energy = 0.3
	world_env.environment = environment
	add_child(world_env)

func add_particle_effects():
	var particles_group = Node3D.new()
	particles_group.name = "ParticleEffects"
	add_child(particles_group)
	
	# Quantum particles around microscope
	var quantum_particles = GPUParticles3D.new()
	quantum_particles.name = "QuantumParticles"
	quantum_particles.position = Vector3(-0.8, 0.3, 0)
	quantum_particles.emitting = true
	quantum_particles.amount = 50
	quantum_particles.lifetime = 3.0
	particles_group.add_child(quantum_particles)
	
	# Plasma particles around flasks
	var plasma_particles = GPUParticles3D.new()
	plasma_particles.name = "PlasmaParticles"
	plasma_particles.position = Vector3(-0.3, 0.2, 0)
	plasma_particles.emitting = true
	plasma_particles.amount = 30
	plasma_particles.lifetime = 2.0
	particles_group.add_child(plasma_particles)
	
	# Holo glow particles around edges
	var holo_particles = GPUParticles3D.new()
	holo_particles.name = "HoloGlowParticles"
	holo_particles.position = Vector3(1.2, 0.2, 0)
	holo_particles.emitting = true
	holo_particles.amount = 25
	holo_particles.lifetime = 4.0
	particles_group.add_child(holo_particles)

# Utility functions for dynamic adjustments
func set_glow_intensity(intensity: float):
	holo_glow_intensity = intensity
	# Update all materials with new intensity
	update_material_emissions()

func update_material_emissions():
	# This would iterate through all materials and update emission values
	# Implementation depends on how you want to organize material updates
	pass

func animate_equipment():
	# Add subtle animations to equipment
	var tween = create_tween()
	tween.set_loops()
	
	# Rotate quantum fields
	var quantum_microscope = get_node_or_null("QuantumEquipment/QuantumMicroscope")
	if quantum_microscope:
		tween.tween_method(
			func(angle): quantum_microscope.rotation.y = angle,
			0.0, TAU, 10.0
		)

# Add quantum field visualization
func add_quantum_field_visualization(pos: Vector3, color: Color):
	var field = MeshInstance3D.new()
	field.position = pos
	
	var field_mesh = SphereMesh.new()
	field_mesh.radius = 0.05
	field.mesh = field_mesh
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = color
	field_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	field_material.emission_enabled = true
	field_material.emission = color * 0.8
	field.material_override = field_material
	
	get_node("QuantumEquipment").add_child(field)
	
	# Animate the field
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(
		func(scale): field.scale = Vector3.ONE * (1.0 + sin(scale) * 0.2),
		0.0, TAU, 2.0
	)
