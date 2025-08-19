extends Node3D
class_name AnickaYiLab

# Visual settings
@export_category("Installation Appearance")
@export var lab_scale: float = 1.0
@export var translucency_amount: float = 0.7
@export var pulsation_speed: float = 0.5
@export var growth_amount: float = 0.2
@export var color_shift_speed: float = 0.3

# Color settings
@export_category("Color Settings")
@export var primary_color: Color = Color(0.8, 0.9, 0.6, 0.8)  # Pale yellowish green
@export var secondary_color: Color = Color(0.6, 0.2, 0.5, 0.6)  # Purple
@export var tertiary_color: Color = Color(0.9, 0.5, 0.2, 0.7)  # Orange
@export var bacterial_color: Color = Color(0.2, 0.7, 0.8, 0.6)  # Cyan

# Equipment settings
@export_category("Lab Equipment")
@export var petri_dish_count: int = 8
@export var test_tube_count: int = 12
@export var flask_count: int = 6
@export var bioreactor_count: int = 3
@export var enable_floating_bacteria: bool = true
@export var bacteria_count: int = 40

# Movement settings
@export_category("Movement")
@export var enable_animation: bool = true
@export var rotation_speed: float = 0.2
@export var floating_speed: float = 0.3
@export var fog_movement_speed: float = 0.1

# Interaction settings
@export_category("Interaction")
@export var enable_interaction: bool = true
@export var interaction_distance: float = 1.5

# Internal variables
var time: float = 0.0
var lab_equipment = []
var bacterial_entities = []
var fog_particles
var glass_material: ShaderMaterial
var liquid_material: ShaderMaterial
var bacterial_material: ShaderMaterial
var metal_material: StandardMaterial3D

func _ready():
	# Create materials
	create_materials()
	
	# Create base structure
	create_lab_base()
	
	# Create lab equipment
	create_lab_equipment()
	
	# Create bacterial entities
	if enable_floating_bacteria:
		create_bacterial_entities()
	
	# Create fog/mist effect
	create_fog_particles()
	
	# Set up interaction areas
	if enable_interaction:
		setup_interaction()

func _process(delta):
	time += delta
	
	if enable_animation:
		# Animate lab equipment
		animate_lab_equipment(delta)
		
		# Animate bacterial entities
		animate_bacterial_entities(delta)
		
		# Update material properties
		update_materials(delta)

func create_materials():
	# Glass material using custom shader
	glass_material = ShaderMaterial.new()
	glass_material.shader = load("res://Translucent/Glass.gdshader")
	# Set shader parameters as needed
	glass_material.set_shader_parameter("albedo", Color(0.9, 0.9, 0.95, 0.6))
	glass_material.set_shader_parameter("roughness", 0.1)
	glass_material.set_shader_parameter("metallic", 0.2)
	glass_material.set_shader_parameter("refraction", 0.05)
	
	# Liquid material using custom shader
	liquid_material = ShaderMaterial.new()
	liquid_material.shader = load("res://Translucent/Liquid.gdshader")
	# Set shader parameters as needed
	liquid_material.set_shader_parameter("albedo", primary_color)
	liquid_material.set_shader_parameter("roughness", 0.2)
	liquid_material.set_shader_parameter("emission_color", primary_color)
	liquid_material.set_shader_parameter("emission_energy", 0.3)
	
	# Bacterial material using custom shader
	bacterial_material = ShaderMaterial.new()
	bacterial_material.shader = load("res://Translucent/BioMatter.gdshader")
	# Set shader parameters as needed
	bacterial_material.set_shader_parameter("albedo", bacterial_color)
	bacterial_material.set_shader_parameter("roughness", 0.7)
	bacterial_material.set_shader_parameter("emission_color", bacterial_color)
	bacterial_material.set_shader_parameter("emission_energy", 0.5)
	
	# Metal material stays as StandardMaterial3D
	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.8, 0.8, 0.85)
	metal_material.roughness = 0.4
	metal_material.metallic = 0.8

func duplicate_shader_material(original_material: ShaderMaterial) -> ShaderMaterial:
	# Create a new shader material with the same shader
	var new_material = ShaderMaterial.new()
	new_material.shader = original_material.shader
	
	# We need to manually copy each parameter
	# Since we don't have get_shader_parameter_list(), we'll set the common parameters we know about
	
	# Common parameters (adjust based on what your shaders actually use)
	var params = [
		"albedo",
		"roughness", 
		"metallic",
		"emission_color",
		"emission_energy",
		"refraction",
		"transparency"
	]
	
	# Try to copy each parameter (will silently fail for unused parameters)
	for param in params:
		var value = original_material.get_shader_parameter(param)
		if value != null:
			new_material.set_shader_parameter(param, value)
	
	return new_material

func update_materials(delta: float):
	# Update liquid materials properties for a subtle dynamic effect
	
	# Update main material properties
	var new_liquid_color = primary_color.lerp(secondary_color, (sin(time * color_shift_speed * 0.3) + 1) / 2.0)
	liquid_material.set_shader_parameter("albedo", new_liquid_color)
	liquid_material.set_shader_parameter("emission_color", new_liquid_color)
	
	# Update bacterial material properties
	var new_bacterial_color = bacterial_color.lerp(tertiary_color, (sin(time * color_shift_speed * 0.5) + 1) / 2.0)
	bacterial_material.set_shader_parameter("albedo", new_bacterial_color)
	bacterial_material.set_shader_parameter("emission_color", new_bacterial_color)
	
	# Update fog particles
	if fog_particles:
		var process_material = fog_particles.process_material
		if process_material:
			var drift_x = sin(time * fog_movement_speed) * 0.1
			var drift_z = cos(time * fog_movement_speed * 0.7) * 0.1
			process_material.direction = Vector3(drift_x, 0.1, drift_z).normalized()

func create_bioreactors():
	var bioreactor_container = Node3D.new()
	bioreactor_container.name = "Bioreactors"
	
	for i in range(bioreactor_count):
		var bioreactor = Node3D.new()
		bioreactor.name = "Bioreactor_" + str(i)
		
		# Create main vessel
		var vessel = MeshInstance3D.new()
		var vessel_mesh = CylinderMesh.new()
		vessel_mesh.top_radius = 0.15 * lab_scale
		vessel_mesh.bottom_radius = 0.15 * lab_scale
		vessel_mesh.height = 0.4 * lab_scale
		
		vessel.mesh = vessel_mesh
		vessel.material_override = glass_material
		
		bioreactor.add_child(vessel)
		
		# Create top cap
		var cap = MeshInstance3D.new()
		var cap_mesh = CylinderMesh.new()
		cap_mesh.top_radius = 0.16 * lab_scale
		cap_mesh.bottom_radius = 0.16 * lab_scale
		cap_mesh.height = 0.03 * lab_scale
		
		cap.mesh = cap_mesh
		cap.material_override = metal_material
		cap.position.y = vessel_mesh.height / 2.0 + cap_mesh.height / 2.0
		
		bioreactor.add_child(cap)
		
		# Create tubes coming out of the cap
		var tube_count = 3
		for j in range(tube_count):
			var angle = 2.0 * PI * j / tube_count
			var tube_radius = 0.1 * lab_scale
			
			var tube = MeshInstance3D.new()
			var tube_mesh = CylinderMesh.new()
			tube_mesh.top_radius = 0.01 * lab_scale
			tube_mesh.bottom_radius = 0.01 * lab_scale
			tube_mesh.height = 0.15 * lab_scale
			
			tube.mesh = tube_mesh
			tube.material_override = glass_material
			tube.position = Vector3(cos(angle) * tube_radius, cap.position.y, sin(angle) * tube_radius)
			tube.rotation.x = PI/2  # Point upward
			
			bioreactor.add_child(tube)
			
			# Add a small valve or connector at the top of each tube
			var valve = MeshInstance3D.new()
			var valve_mesh = SphereMesh.new()
			valve_mesh.radius = 0.015 * lab_scale
			valve_mesh.height = 0.03 * lab_scale
			
			valve.mesh = valve_mesh
			valve.material_override = metal_material
			valve.position = tube.position + Vector3(0, tube_mesh.height, 0)
			
			bioreactor.add_child(valve)
		
		# Create liquid inside the vessel
		var fill_percentage = randf_range(0.6, 0.9)
		var liquid = MeshInstance3D.new()
		var liquid_mesh = CylinderMesh.new()
		liquid_mesh.top_radius = 0.14 * lab_scale
		liquid_mesh.bottom_radius = 0.14 * lab_scale
		liquid_mesh.height = vessel_mesh.height * fill_percentage
		
		# Create a new shader material for bioreactor liquid
		var bioreactor_material = ShaderMaterial.new()
		bioreactor_material.shader = liquid_material.shader

		# Modify as needed
		var hue_shift = float(i) / bioreactor_count
		var bioreactor_color = bacterial_color.lerp(tertiary_color, hue_shift)
		bioreactor_material.set_shader_parameter("albedo", bioreactor_color)
		bioreactor_material.set_shader_parameter("roughness", 0.2)
		bioreactor_material.set_shader_parameter("emission_color", bioreactor_color)
		bioreactor_material.set_shader_parameter("emission_energy", 0.3)
		
		liquid.mesh = liquid_mesh
		liquid.material_override = bioreactor_material
		liquid.position.y = -vessel_mesh.height * (1.0 - fill_percentage) / 2.0
		
		bioreactor.add_child(liquid)
		
		# Add some bacterial particles floating in the liquid
		var particle_count = randi() % 15 + 10
		for k in range(particle_count):
			var particle = MeshInstance3D.new()
			var particle_mesh = SphereMesh.new()
			var particle_size = randf_range(0.01, 0.025) * lab_scale
			particle_mesh.radius = particle_size
			particle_mesh.height = particle_size * 2
			
			# Create a new shader material for each particle
			var particle_material = ShaderMaterial.new()
			particle_material.shader = bacterial_material.shader
			
			var mixed_color = bacterial_color.lerp(primary_color, randf())
			particle_material.set_shader_parameter("albedo", mixed_color)
			particle_material.set_shader_parameter("roughness", 0.7)
			particle_material.set_shader_parameter("emission_color", mixed_color)
			particle_material.set_shader_parameter("emission_energy", 0.5)
			
			particle.mesh = particle_mesh
			particle.material_override = particle_material
			
			# Random position within the liquid
			var angle_p = randf() * 2.0 * PI
			var radius_p = randf() * 0.13 * lab_scale
			var height_p = randf() * liquid_mesh.height - liquid_mesh.height / 2.0
			particle.position = Vector3(cos(angle_p) * radius_p, height_p + liquid.position.y, sin(angle_p) * radius_p)
			
			bioreactor.add_child(particle)
		
		# Create a stirring rod or impeller
		var stirrer = MeshInstance3D.new()
		var stirrer_mesh = CylinderMesh.new()
		stirrer_mesh.top_radius = 0.005 * lab_scale
		stirrer_mesh.bottom_radius = 0.005 * lab_scale
		stirrer_mesh.height = vessel_mesh.height * 0.8
		
		stirrer.mesh = stirrer_mesh
		stirrer.material_override = metal_material
		stirrer.position.y = 0
		
		bioreactor.add_child(stirrer)
		
		# Add impeller blades
		var blade_count = 4
		for bl in range(blade_count):
			var blade = MeshInstance3D.new()
			var blade_mesh = BoxMesh.new()
			blade_mesh.size = Vector3(0.08, 0.01, 0.02) * lab_scale
			
			blade.mesh = blade_mesh
			blade.material_override = metal_material
			
			var angle_b = 2.0 * PI * bl / blade_count
			blade.position = Vector3(cos(angle_b) * 0.04 * lab_scale, -0.1 * lab_scale, sin(angle_b) * 0.04 * lab_scale)
			blade.rotation_degrees.y = bl * (360.0 / blade_count)
			
			stirrer.add_child(blade)
		
		# Position on the table
		var x_pos = (-1 + i) * 0.5 * lab_scale
		bioreactor.position = Vector3(x_pos, 0.95 * lab_scale, 0.6 * lab_scale)
		
		bioreactor_container.add_child(bioreactor)
		lab_equipment.append(bioreactor)
	
	add_child(bioreactor_container)

func create_bacterial_entities():
	var bacteria_container = Node3D.new()
	bacteria_container.name = "BacterialEntities"
	
	for i in range(bacteria_count):
		var bacteria = MeshInstance3D.new()
		bacteria.name = "Bacteria_" + str(i)
		
		# Randomly select a bacteria shape
		var shape_type = randi() % 3
		var bacteria_mesh
		
		match shape_type:
			0:  # Rod-shaped (bacillus)
				bacteria_mesh = CapsuleMesh.new()
				bacteria_mesh.radius = randf_range(0.02, 0.04) * lab_scale
				bacteria_mesh.height = randf_range(0.08, 0.15) * lab_scale
			1:  # Spherical (coccus)
				bacteria_mesh = SphereMesh.new()
				bacteria_mesh.radius = randf_range(0.03, 0.06) * lab_scale
				bacteria_mesh.height = bacteria_mesh.radius * 2
			2:  # Spiral (spirillum) - approximated with stretched sphere
				bacteria_mesh = SphereMesh.new()
				bacteria_mesh.radius = randf_range(0.02, 0.04) * lab_scale
				bacteria_mesh.height = randf_range(0.1, 0.2) * lab_scale
		
		bacteria.mesh = bacteria_mesh
		
		# Create unique material for each bacteria
		var bacteria_mat = ShaderMaterial.new()
		bacteria_mat.shader = bacterial_material.shader
		
		var hue_offset = randf()
		var bacteria_color_instance = bacterial_color.lerp(tertiary_color, hue_offset)
		
		# Set shader parameters
		bacteria_mat.set_shader_parameter("albedo", bacteria_color_instance)
		bacteria_mat.set_shader_parameter("roughness", 0.7)
		bacteria_mat.set_shader_parameter("emission_color", bacteria_color_instance)
		bacteria_mat.set_shader_parameter("emission_energy", randf_range(0.3, 0.8))
		
		bacteria.material_override = bacteria_mat
		
		# Random position in the lab space
		var x_range = 1.5 * lab_scale
		var y_range = 1.0 * lab_scale
		var z_range = 1.0 * lab_scale
		
		bacteria.position = Vector3(
			randf_range(-x_range, x_range),
			randf_range(0.8, 0.8 + y_range),
			randf_range(-z_range, z_range)
		)
		
		# Random rotation
		bacteria.rotation = Vector3(
			randf_range(0, 2 * PI),
			randf_range(0, 2 * PI),
			randf_range(0, 2 * PI)
		)
		
		bacteria_container.add_child(bacteria)
		bacterial_entities.append(bacteria)
	
	add_child(bacteria_container)

func create_fog_particles():
	fog_particles = GPUParticles3D.new()
	fog_particles.name = "FogParticles"
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particles_material.emission_box_extents = Vector3(1.5, 0.5, 1.0) * lab_scale
	
	particles_material.direction = Vector3(0, 1, 0)
	particles_material.spread = 10.0
	particles_material.gravity = Vector3(0, 0.01, 0)
	
	particles_material.initial_velocity_min = 0.05
	particles_material.initial_velocity_max = 0.15
	particles_material.angular_velocity_min = -0.2
	particles_material.angular_velocity_max = 0.2
	
	particles_material.scale_min = 0.2 * lab_scale
	particles_material.scale_max = 0.5 * lab_scale
	
	particles_material.color = primary_color.lerp(Color.WHITE, 0.8)
	particles_material.color.a = 0.2  # Low alpha for subtle effect
	
	particles_material.lifetime_randomness = 0.5
	
	fog_particles.process_material = particles_material
	
	# Use a sphere mesh for the particles
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.1 * lab_scale
	particle_mesh.height = 0.2 * lab_scale
	
	# Create a mesh instance for the particle
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = particle_mesh
	
	# Create material for particles
	var fog_material = StandardMaterial3D.new()
	fog_material.albedo_color = primary_color.lerp(Color.WHITE, 0.8)
	fog_material.albedo_color.a = 0.3
	fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_material.emission_enabled = true
	fog_material.emission = fog_material.albedo_color
	fog_material.emission_energy = 0.1
	
	mesh_instance.material_override = fog_material
	
	fog_particles.draw_pass_1 = particle_mesh
	fog_particles.amount = 100
	fog_particles.lifetime = 8.0
	fog_particles.randomness = 1.0
	fog_particles.visibility_aabb = AABB(Vector3(-2, -1, -2) * lab_scale, Vector3(4, 3, 4) * lab_scale)
	
	fog_particles.position = Vector3(0, 0.9 * lab_scale, 0)
	
	add_child(fog_particles)

func setup_interaction():
	for equipment in lab_equipment:
		var area = Area3D.new()
		area.name = "InteractionArea"
		
		var collision_shape = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = interaction_distance
		
		collision_shape.shape = shape
		area.add_child(collision_shape)
		
		# Connect signals
		area.connect("input_event", _on_area_input_event.bind(equipment))
		area.connect("mouse_entered", _on_area_mouse_entered.bind(equipment))
		area.connect("mouse_exited", _on_area_mouse_exited.bind(equipment))
		
		equipment.add_child(area)

func _on_area_input_event(camera, event, click_position, click_normal, shape_idx, equipment):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Handle interaction with the equipment
		print("Interacted with: ", equipment.name)
		
		# Create a highlight effect
		var highlight = create_highlight_effect(equipment)
		equipment.add_child(highlight)
		
		# Show information about the equipment
		show_equipment_info(equipment)

func _on_area_mouse_entered(equipment):
	# Change cursor or provide visual feedback
	print("Hover over: ", equipment.name)
	
	# Apply a subtle highlight
	var material = equipment.get_child(0).material_override
	if material is ShaderMaterial:
		material.set_shader_parameter("emission_energy", 0.5)

func _on_area_mouse_exited(equipment):
	# Restore original state
	print("Exit from: ", equipment.name)
	
	# Remove the subtle highlight
	var material = equipment.get_child(0).material_override
	if material is ShaderMaterial:
		material.set_shader_parameter("emission_energy", 0.3)

func create_highlight_effect(node: Node3D) -> Node3D:
	var highlight = Node3D.new()
	highlight.name = "Highlight"
	
	# Create a glowing outline effect
	var outline = MeshInstance3D.new()
	
	# Get the mesh from the target node
	var original_mesh = null
	for child in node.get_children():
		if child is MeshInstance3D:
			original_mesh = child.mesh
			break
	
	if original_mesh:
		outline.mesh = original_mesh
		
		# Create highlight material - keep as StandardMaterial3D for the highlight effect
		var highlight_material = StandardMaterial3D.new()
		highlight_material.albedo_color = Color(1, 1, 1, 0.2)
		highlight_material.emission_enabled = true
		highlight_material.emission = Color(1, 1, 0.5)
		highlight_material.emission_energy = 2.0
		highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		outline.material_override = highlight_material
		outline.scale = Vector3(1.05, 1.05, 1.05)  # Slightly larger than original
		
		highlight.add_child(outline)
	
	# Create a timer to remove the highlight after a delay
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.autostart = true
	timer.connect("timeout", highlight.queue_free)
	highlight.add_child(timer)
	
	return highlight

func show_equipment_info(equipment: Node3D):
	# In a real implementation, this would show UI with information
	# about the selected lab equipment
	var equipment_type = equipment.name.split("_")[0]
	var info = ""
	
	match equipment_type:
		"PetriDish":
			info = "Petri Dish: Used for culturing microorganisms. Contains agar growth medium."
		"TestTube":
			info = "Test Tube: Container for holding and mixing chemicals or biological samples."
		"Flask":
			info = "Flask: Used for mixing, heating, cooling, or growing cultures in liquid media."
		"Bioreactor":
			info = "Bioreactor: System for growing organisms under controlled conditions."
	
	print("INFO: ", info)
	# In a real implementation, display this in UI

func animate_lab_equipment(delta: float):
	# Subtle movement and effects for lab equipment
	for i in range(lab_equipment.size()):
		var equipment = lab_equipment[i]
		
		# Different animation for different types of equipment
		if "PetriDish" in equipment.name:
			# Subtle glow pulsation for bacterial colonies
			for child in equipment.get_children():
				if child is MeshInstance3D and "colony" in child.name.to_lower():
					var material = child.material_override
					if material is ShaderMaterial:
						var pulse = (sin(time * pulsation_speed + i) + 1) / 2.0
						material.set_shader_parameter("emission_energy", 0.3 + pulse * 0.2)
		
		elif "TestTube" in equipment.name:
			# Subtle bubbling effect
			for child in equipment.get_children():
				if child is MeshInstance3D and child.name.begins_with("liquid"):
					var material = child.material_override
					if material is ShaderMaterial:
						var pulse = (sin(time * pulsation_speed * 0.7 + i * 0.5) + 1) / 2.0
						material.set_shader_parameter("emission_energy", 0.2 + pulse * 0.15)
		
		elif "Flask" in equipment.name:
			# Gentle rocking/swirling motion
			var orig_rot = equipment.rotation
			var sway_amount = 0.01
			equipment.rotation.x = orig_rot.x + sin(time * rotation_speed * 0.3 + i) * sway_amount
			equipment.rotation.z = orig_rot.z + cos(time * rotation_speed * 0.2 + i) * sway_amount
		
		elif "Bioreactor" in equipment.name:
			# Rotating stirrer and bubbling liquid
			for child in equipment.get_children():
				if child is MeshInstance3D and "stirrer" in child.name:
					child.rotation.y += rotation_speed * delta * 2.0
				
				if child is MeshInstance3D and "liquid" in child.name:
					var material = child.material_override
					if material is ShaderMaterial:
						var pulse = (sin(time * pulsation_speed * 0.5 + i) + 1) / 2.0
						material.set_shader_parameter("emission_energy", 0.3 + pulse * 0.2)

func animate_bacterial_entities(delta: float):
	# Movement for floating bacterial entities
	for i in range(bacterial_entities.size()):
		var bacteria = bacterial_entities[i]
		
		# Calculate movement
		var movement = Vector3(
			sin(time * floating_speed + i),
			cos(time * floating_speed * 0.7 + i * 0.5),
			sin(time * floating_speed * 0.5 + i * 0.3)
		) * delta * 0.05 * lab_scale
		
		bacteria.position += movement
		
		# Keep within boundaries
		var bounds = 1.5 * lab_scale
		var y_min = 0.8 * lab_scale
		var y_max = 1.8 * lab_scale
		
		if abs(bacteria.position.x) > bounds:
			bacteria.position.x = sign(bacteria.position.x) * bounds
		
		if bacteria.position.y < y_min:
			bacteria.position.y = y_min
		elif bacteria.position.y > y_max:
			bacteria.position.y = y_max
		
		if abs(bacteria.position.z) > bounds:
			bacteria.position.z = sign(bacteria.position.z) * bounds
		
		# Random rotation
		bacteria.rotate_x(randf_range(-0.01, 0.01) * rotation_speed)
		bacteria.rotate_y(randf_range(-0.01, 0.01) * rotation_speed)
		bacteria.rotate_z(randf_range(-0.01, 0.01) * rotation_speed)
		
		# Pulsating emission
		var material = bacteria.material_override
		if material is ShaderMaterial:
			var pulse = (sin(time * pulsation_speed * 0.8 + i * 0.7) + 1) / 2.0
			material.set_shader_parameter("emission_energy", 0.3 + pulse * 0.4)
			
			# Subtle color shifting
			var hue_shift = (sin(time * color_shift_speed * 0.2 + i) + 1) / 2.0
			var base_color = bacterial_color.lerp(tertiary_color, hue_shift)
			material.set_shader_parameter("albedo", base_color)
			material.set_shader_parameter("emission_color", base_color)

func create_lab_base():
	var base = Node3D.new()
	base.name = "LabBase"
	
	# Create a central table/platform
	var table = MeshInstance3D.new()
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(3.0, 0.1, 2.0) * lab_scale
	
	table.mesh = table_mesh
	table.material_override = metal_material
	table.position.y = 0.7 * lab_scale  # Table height
	
	base.add_child(table)
	
	# Create table legs
	for x in [-1, 1]:
		for z in [-1, 1]:
			var leg = MeshInstance3D.new()
			var leg_mesh = CylinderMesh.new()
			leg_mesh.top_radius = 0.05 * lab_scale
			leg_mesh.bottom_radius = 0.05 * lab_scale
			leg_mesh.height = 1.4 * lab_scale
			
			leg.mesh = leg_mesh
			leg.material_override = metal_material
			leg.position = Vector3(x * 1.4 * lab_scale, 0.0, z * 0.9 * lab_scale)
			leg.position.y = (leg_mesh.height / 2.0)
			
			base.add_child(leg)
	

	# Create a backdrop structure
	var backdrop = MeshInstance3D.new()
	var backdrop_mesh = BoxMesh.new()
	backdrop_mesh.size = Vector3(3.0, 2.0, 0.05) * lab_scale
	
	backdrop.mesh = backdrop_mesh
	backdrop.material_override = metal_material
	backdrop.position = Vector3(0, 1.7 * lab_scale, -1.0 * lab_scale)
	
	base.add_child(backdrop)
	
	# Add some lighting elements to the base
	var light1 = OmniLight3D.new()
	light1.light_color = primary_color.lerp(Color.WHITE, 0.7)
	light1.light_energy = 0.5
	light1.omni_range = 3.0 * lab_scale
	light1.position = Vector3(0, 1.5 * lab_scale, 0)
	
	base.add_child(light1)
	
	# Add some decorative pipes and tubes
	create_decorative_pipes(base)
	
	add_child(base)

func create_decorative_pipes(parent: Node3D):
	# Create some interconnecting tubes and pipes for aesthetic
	var pipes = Node3D.new()
	pipes.name = "DecorativePipes"
	
	# Create a network of pipes
	var pipe_positions = [
		[Vector3(-1.0, 0.9, -0.9), Vector3(-0.5, 1.2, -0.9)],
		[Vector3(-0.5, 1.2, -0.9), Vector3(0.2, 1.2, -0.9)],
		[Vector3(0.2, 1.2, -0.9), Vector3(0.2, 0.9, -0.9)],
		[Vector3(0.5, 0.9, -0.9), Vector3(1.0, 1.1, -0.9)],
		[Vector3(-0.8, 0.75, -0.5), Vector3(-0.8, 0.75, 0.0)],
		[Vector3(0.8, 0.75, -0.5), Vector3(0.8, 0.75, 0.0)]
	]
	
	for pipe_data in pipe_positions:
		var start_pos = pipe_data[0] * lab_scale
		var end_pos = pipe_data[1] * lab_scale
		
		var pipe = create_pipe_segment(start_pos, end_pos, 0.03 * lab_scale)
		pipes.add_child(pipe)
	
	# Add some valves or connectors at intersections
	var valve_positions = [
		Vector3(-0.5, 1.2, -0.9),
		Vector3(0.2, 1.2, -0.9),
		Vector3(-0.8, 0.75, -0.5),
		Vector3(0.8, 0.75, -0.5)
	]
	
	for pos in valve_positions:
		var valve = create_valve(pos * lab_scale, 0.06 * lab_scale)
		pipes.add_child(valve)
	
	parent.add_child(pipes)

func create_pipe_segment(start: Vector3, end: Vector3, radius: float) -> MeshInstance3D:
	var pipe = MeshInstance3D.new()
	
	# Calculate length and orientation
	var direction = end - start
	var length = direction.length()
	var center = (start + end) / 2
	
	# Create cylinder mesh
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = 12
	
	pipe.mesh = cylinder
	pipe.position = center
	
	# Orient the cylinder to point from start to end
	pipe.look_at_from_position(center, end, Vector3.UP)
	pipe.rotate_object_local(Vector3(1, 0, 0), PI/2)
	
	pipe.material_override = glass_material
	
	return pipe

func create_valve(position: Vector3, radius: float) -> MeshInstance3D:
	var valve = MeshInstance3D.new()
	
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	
	valve.mesh = sphere
	valve.position = position
	valve.material_override = metal_material
	
	return valve

func create_lab_equipment():
	# Create various lab equipment and place on the table
	
	# Create petri dishes
	create_petri_dishes()
	
	# Create test tubes
	create_test_tubes()
	
	# Create flasks
	create_flasks()
	
	# Create bioreactors
	create_bioreactors()

func create_petri_dishes():
	var petri_dish_container = Node3D.new()
	petri_dish_container.name = "PetriDishes"
	
	for i in range(petri_dish_count):
		var petri = Node3D.new()
		petri.name = "PetriDish_" + str(i)
		
		# Create base
		var base = MeshInstance3D.new()
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 0.15 * lab_scale
		base_mesh.bottom_radius = 0.15 * lab_scale
		base_mesh.height = 0.02 * lab_scale
		
		base.mesh = base_mesh
		base.material_override = glass_material
		
		petri.add_child(base)
		
		# Create rim
		var rim = MeshInstance3D.new()
		var rim_mesh = CylinderMesh.new()
		rim_mesh.top_radius = 0.15 * lab_scale
		rim_mesh.bottom_radius = 0.14 * lab_scale
		rim_mesh.height = 0.03 * lab_scale
		
		rim.mesh = rim_mesh
		rim.material_override = glass_material
		rim.position.y = 0.025 * lab_scale
		
		petri.add_child(rim)
		
		# Create culture medium
		var medium = MeshInstance3D.new()
		var medium_mesh = CylinderMesh.new()
		medium_mesh.top_radius = 0.14 * lab_scale
		medium_mesh.bottom_radius = 0.14 * lab_scale
		medium_mesh.height = 0.01 * lab_scale

		# Create a new ShaderMaterial for culture medium
		var culture_material = ShaderMaterial.new()
		culture_material.shader = load("res://Translucent/BioMatter.gdshader")  # Using BioMatter shader as it seems most appropriate

		# Vary colors for different petri dishes
		var hue_shift = float(i) / petri_dish_count
		var culture_color = primary_color.lerp(secondary_color, hue_shift)

		# Set shader parameters
		culture_material.set_shader_parameter("albedo", culture_color)
		culture_material.set_shader_parameter("roughness", 0.2)
		culture_material.set_shader_parameter("emission_color", culture_color)
		culture_material.set_shader_parameter("emission_energy", 0.3)

		medium.mesh = medium_mesh
		medium.material_override = culture_material
		medium.position.y = 0.015 * lab_scale

		petri.add_child(medium)

		# Create bacterial colonies on the medium
		var colony_count = randi() % 8 + 3
		for j in range(colony_count):
			var colony = MeshInstance3D.new()
			var colony_mesh = SphereMesh.new()
			var colony_size = randf_range(0.01, 0.03) * lab_scale
			colony_mesh.radius = colony_size
			colony_mesh.height = colony_size * 1.5

			# Create a new ShaderMaterial for each colony
			var colony_material = ShaderMaterial.new()
			colony_material.shader = load("res://Translucent/BioMatter.gdshader")

			var colony_color = bacterial_color.lerp(tertiary_color, randf())

			# Set shader parameters
			colony_material.set_shader_parameter("albedo", colony_color)
			colony_material.set_shader_parameter("roughness", 0.7)
			colony_material.set_shader_parameter("emission_color", colony_color)
			colony_material.set_shader_parameter("emission_energy", 0.5)

			colony.mesh = colony_mesh
			colony.material_override = colony_material

			var angle = randf() * 2.0 * PI
			var distance = randf() * 0.12 * lab_scale
			colony.position = Vector3(cos(angle) * distance, 0.025 * lab_scale, sin(angle) * distance)

			petri.add_child(colony)

		# Position on the table
		var grid_size = sqrt(petri_dish_count) + 1
		var x_index = i % int(grid_size)
		var z_index = i / int(grid_size)
		
		var x_pos = (x_index - grid_size/2 + 0.5) * 0.35 * lab_scale + randf_range(-0.05, 0.05) * lab_scale
		var z_pos = (z_index - grid_size/3 + 0.5) * 0.35 * lab_scale + randf_range(-0.05, 0.05) * lab_scale
		
		petri.position = Vector3(x_pos, 0.75 * lab_scale, z_pos - 0.4 * lab_scale)
		petri.rotation_degrees.y = randf_range(-30, 30)
		
		petri_dish_container.add_child(petri)
		lab_equipment.append(petri)
	
	add_child(petri_dish_container)

func create_test_tubes():
	var test_tube_container = Node3D.new()
	test_tube_container.name = "TestTubes"
	
	var rack = create_test_tube_rack(test_tube_count)
	test_tube_container.add_child(rack)
	
	for i in range(test_tube_count):
		var tube = Node3D.new()
		tube.name = "TestTube_" + str(i)
		
		# Create glass tube
		var glass = MeshInstance3D.new()
		var glass_mesh = CylinderMesh.new()
		glass_mesh.top_radius = 0.025 * lab_scale
		glass_mesh.bottom_radius = 0.025 * lab_scale
		glass_mesh.height = 0.25 * lab_scale
		
		glass.mesh = glass_mesh
		glass.material_override = glass_material
		
		tube.add_child(glass)
		
		# Create liquid inside
		var fill_percentage = randf_range(0.3, 0.8)
		var liquid = MeshInstance3D.new()
		var liquid_mesh = CylinderMesh.new()
		liquid_mesh.top_radius = 0.02 * lab_scale
		liquid_mesh.bottom_radius = 0.02 * lab_scale
		liquid_mesh.height = 0.25 * fill_percentage * lab_scale
		
		# Create a new shader material for each test tube liquid
		var tube_material = ShaderMaterial.new()
		tube_material.shader = liquid_material.shader
		
		# Vary colors for different test tubes
		var hue_shift = float(i) / test_tube_count
		var tube_color
		
		if i % 3 == 0:
			tube_color = primary_color.lerp(tertiary_color, hue_shift)
		elif i % 3 == 1:
			tube_color = secondary_color.lerp(primary_color, hue_shift)
		else:
			tube_color = tertiary_color.lerp(secondary_color, hue_shift)
			
		# Set shader parameters
		tube_material.set_shader_parameter("albedo", tube_color)
		tube_material.set_shader_parameter("roughness", 0.2)
		tube_material.set_shader_parameter("emission_color", tube_color)
		tube_material.set_shader_parameter("emission_energy", 0.3)
		
		liquid.mesh = liquid_mesh
		liquid.material_override = tube_material
		liquid.position.y = -0.25 * (1.0 - fill_percentage) / 2.0 * lab_scale
		
		tube.add_child(liquid)
		
		# Position in the rack
		var x_index = i % int(sqrt(test_tube_count) + 1)
		var z_index = i / int(sqrt(test_tube_count) + 1)
		
		var x_pos = (x_index - int(sqrt(test_tube_count))/2) * 0.06 * lab_scale
		var z_pos = (z_index) * 0.06 * lab_scale
		
		tube.position = Vector3(x_pos, 0.87 * lab_scale, z_pos - 0.8 * lab_scale)
		
		test_tube_container.add_child(tube)
		lab_equipment.append(tube)
	
	test_tube_container.position = Vector3(0.8 * lab_scale, 0, 0.2 * lab_scale)
	
	add_child(test_tube_container)

func create_test_tube_rack(tube_count: int) -> Node3D:
	var rack = Node3D.new()
	rack.name = "TestTubeRack"
	
	var columns = int(sqrt(tube_count) + 1)
	var rows = int(tube_count / columns) + 1
	
	# Create the base
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3((columns + 1) * 0.06, 0.02, (rows + 1) * 0.06) * lab_scale
	
	base.mesh = base_mesh
	base.material_override = metal_material
	base.position = Vector3(0, 0.75 * lab_scale, -0.8 * lab_scale)
	
	rack.add_child(base)
	
	# Create top support
	var top = MeshInstance3D.new()
	var top_mesh = BoxMesh.new()
	top_mesh.size = Vector3((columns + 1) * 0.06, 0.02, (rows + 1) * 0.06) * lab_scale
	
	top.mesh = top_mesh
	top.material_override = metal_material
	top.position = Vector3(0, 0.95 * lab_scale, -0.8 * lab_scale)
	
	rack.add_child(top)
	
	# Create holes in the top support
	for i in range(tube_count):
		var x_index = i % columns
		var z_index = i / columns
		
		var x_pos = (x_index - columns/2) * 0.06 * lab_scale
		var z_pos = (z_index) * 0.06 * lab_scale
		
		var hole = MeshInstance3D.new()
		var hole_mesh = CylinderMesh.new()
		hole_mesh.top_radius = 0.027 * lab_scale
		hole_mesh.bottom_radius = 0.027 * lab_scale
		hole_mesh.height = 0.022 * lab_scale
		
		hole.mesh = hole_mesh
		hole.material_override = metal_material
		hole.position = Vector3(x_pos, 0.95 * lab_scale, z_pos - 0.8 * lab_scale)
		
		rack.add_child(hole)
	
	return rack

func create_flasks():
	var flask_container = Node3D.new()
	flask_container.name = "Flasks"
	
	for i in range(flask_count):
		var flask = Node3D.new()
		flask.name = "Flask_" + str(i)
		
		# Create flask body (use a combination of meshes for Erlenmeyer flask shape)
		var body = MeshInstance3D.new()
		
		# Create a custom flask shape using SurfaceTool
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var flask_height = 0.2 * lab_scale
		var top_radius = 0.03 * lab_scale
		var bottom_radius = 0.08 * lab_scale
		var segments = 16
		
		# Top ring vertices
		var top_verts = []
		for ai in range(segments):
			var angle = 2.0 * PI * ai / segments
			var x = cos(angle) * top_radius
			var z = sin(angle) * top_radius
			top_verts.append(Vector3(x, flask_height, z))
		
		# Bottom ring vertices
		var bottom_verts = []
		for ip in range(segments):
			var angle = 2.0 * PI * ip / segments
			var x = cos(angle) * bottom_radius
			var z = sin(angle) * bottom_radius
			bottom_verts.append(Vector3(x, 0, z))
		
		# Create triangles for the flask sides
		for oi in range(segments):
			var next_i = (oi + 1) % segments
			
			# Add two triangles for each segment
			# Triangle 1
			st.add_vertex(top_verts[oi])
			st.add_vertex(bottom_verts[oi])
			st.add_vertex(bottom_verts[next_i])
			
			# Triangle 2
			st.add_vertex(top_verts[oi])
			st.add_vertex(bottom_verts[next_i])
			st.add_vertex(top_verts[next_i])
		
		# Create the bottom of the flask
		var center_bottom = Vector3(0, 0, 0)
		for id in range(segments):
			var next_i = (id + 1) % segments
			st.add_vertex(center_bottom)
			st.add_vertex(bottom_verts[id])
			st.add_vertex(bottom_verts[next_i])
		
		# Commit to mesh
		body.mesh = st.commit()
		body.material_override = glass_material
		
		flask.add_child(body)
		
		# Create neck
		var neck = MeshInstance3D.new()
		var neck_mesh = CylinderMesh.new()
		neck_mesh.top_radius = 0.02 * lab_scale
		neck_mesh.bottom_radius = 0.02 * lab_scale
		neck_mesh.height = 0.1 * lab_scale
		
		neck.mesh = neck_mesh
		neck.material_override = glass_material
		neck.position.y = flask_height + neck_mesh.height / 2.0
		
		flask.add_child(neck)
		
		# Create liquid inside
		var fill_percentage = randf_range(0.2, 0.6)
		var liquid = MeshInstance3D.new()
		
		# Create liquid mesh similar to the flask but smaller
		var liquid_st = SurfaceTool.new()
		liquid_st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var liquid_height = flask_height * fill_percentage
		var liquid_top_radius 
		
		# Calculate the radius at the fill level (lerp between bottom and top)
		if fill_percentage < 1.0:
			liquid_top_radius = bottom_radius + (top_radius - bottom_radius) * fill_percentage
		else:
			liquid_top_radius = top_radius
			
		liquid_top_radius *= 0.95 # Slightly smaller than the container
		var liquid_bottom_radius = bottom_radius * 0.95  # Slightly smaller than the container
		
		# Top ring vertices (at fill level)
		var liquid_top_verts = []
		for iv in range(segments):
			var angle = 2.0 * PI * iv / segments
			var x = cos(angle) * liquid_top_radius
			var z = sin(angle) * liquid_top_radius
			liquid_top_verts.append(Vector3(x, liquid_height, z))
		
		# Bottom ring vertices
		var liquid_bottom_verts = []
		for ii in range(segments):
			var angle = 2.0 * PI * ii / segments
			var x = cos(angle) * liquid_bottom_radius
			var z = sin(angle) * liquid_bottom_radius
			liquid_bottom_verts.append(Vector3(x, 0.005, z))  # Slightly above bottom
		
		# Create triangles for the liquid sides
		for pi in range(segments):
			var next_i = (pi + 1) % segments
			
			# Add two triangles for each segment
			#Triangle 1
			liquid_st.add_vertex(liquid_top_verts[pi])
			liquid_st.add_vertex(liquid_bottom_verts[pi])
			liquid_st.add_vertex(liquid_bottom_verts[next_i])
			
			# Triangle 2
			liquid_st.add_vertex(liquid_top_verts[pi])
			liquid_st.add_vertex(liquid_bottom_verts[next_i])
			liquid_st.add_vertex(liquid_top_verts[next_i])
		
		# Create the bottom of the liquid
		var liquid_center_bottom = Vector3(0, 0.005, 0)  #  Slightly above bottom
		for ji in range(segments):
			var next_i = (ji + 1) % segments
			liquid_st.add_vertex(liquid_center_bottom)
			liquid_st.add_vertex(liquid_bottom_verts[ji])
			liquid_st.add_vertex(liquid_bottom_verts[next_i])
		
		# Create the top surface of the liquid
		var liquid_center_top = Vector3(0, liquid_height, 0)
		for _i in range(segments):
			var next_i = (_i + 1) % segments
			liquid_st.add_vertex(liquid_center_top)
			liquid_st.add_vertex(liquid_top_verts[next_i])
			liquid_st.add_vertex(liquid_top_verts[_i])
		
		liquid.mesh = liquid_st.commit()
		
		# Create a new shader material for the flask liquid
		var flask_liquid_material = ShaderMaterial.new()
		flask_liquid_material.shader = liquid_material.shader

		# Vary colors for different flasks
		var hue_shift = float(i) / flask_count
		var flask_color

		if i % 3 == 0:
			flask_color = primary_color.lerp(bacterial_color, hue_shift)
		elif i % 3 == 1:
			flask_color = secondary_color.lerp(tertiary_color, hue_shift)
		else:
			flask_color = tertiary_color.lerp(primary_color, hue_shift)

		# Set shader parameters
		flask_liquid_material.set_shader_parameter("albedo", flask_color)
		flask_liquid_material.set_shader_parameter("roughness", 0.2)
		flask_liquid_material.set_shader_parameter("emission_color", flask_color)
		flask_liquid_material.set_shader_parameter("emission_energy", 0.3)

		liquid.material_override = flask_liquid_material
		
		flask.add_child(liquid)
		
		# Position on the table
		var angle = 2.0 * PI * i / flask_count
		var radius = 0.6 * lab_scale
		var x_pos = cos(angle) * radius
		var z_pos = sin(angle) * radius
		
		flask.position = Vector3(x_pos, 0.75 * lab_scale, z_pos)
		flask.rotation_degrees.y = randf_range(-30, 30)
		
		flask_container.add_child(flask)
		lab_equipment.append(flask)
	
	add_child(flask_container)
