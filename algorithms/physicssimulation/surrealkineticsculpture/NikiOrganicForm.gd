
# Niki de Saint Phalle-inspired organic form
class_name NikiOrganicForm
extends Node3D

var base_forms: Array[CSGShape3D] = []
var color_scheme: int = 0
var material_system: SurrealMaterialSystem
var organic_complexity: int = 3

# Animation properties
var base_scale: Vector3
var motion_multiplier: float = 1.0

func setup_organic_form(config: Dictionary):
	"""Create colorful, organic Niki de Saint Phalle-inspired form"""
	color_scheme = config.get("color_scheme", 0)
	organic_complexity = config.get("organic_complexity", 3)
	material_system = config.get("material_system", null)
	
	var base_size = config.get("base_size", 2.0)
	base_scale = Vector3.ONE * base_size
	
	create_organic_structure(base_size)
	apply_niki_materials()
	add_surface_details()

func create_organic_structure(size: float):
	"""Create the main organic structure"""
	# Central body (rounded, feminine form)
	var main_body = CSGSphere3D.new()
	main_body.radius = size
	main_body.radial_segments = 12
	main_body.rings = 8
	add_child(main_body)
	base_forms.append(main_body)
	
	# Add organic protrusions
	for i in range(organic_complexity):
		create_organic_protrusion(main_body, size, i)
	
	# Add flowing appendages
	create_flowing_appendages(size)

func create_organic_protrusion(parent: CSGShape3D, base_size: float, index: int):
	"""Create colorful organic protrusions"""
	var protrusion = CSGSphere3D.new()
	protrusion.radius = base_size * randf_range(0.3, 0.7)
	
	# Position organically around the main form
	var angle = index * TAU / organic_complexity + randf_range(-0.5, 0.5)
	var elevation = randf_range(-PI * 0.3, PI * 0.3)
	var distance = base_size * randf_range(0.8, 1.4)
	
	protrusion.position = Vector3(
		cos(angle) * cos(elevation) * distance,
		sin(elevation) * distance,
		sin(angle) * cos(elevation) * distance
	)
	
	parent.add_child(protrusion)
	base_forms.append(protrusion)
	
	# Add sub-protrusions for complexity
	if randf() > 0.5:
		var sub_protrusion = CSGSphere3D.new()
		sub_protrusion.radius = protrusion.radius * 0.6
		sub_protrusion.position = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		).normalized() * protrusion.radius
		protrusion.add_child(sub_protrusion)
		base_forms.append(sub_protrusion)

func create_flowing_appendages(size: float):
	"""Create flowing, ribbon-like appendages"""
	var appendage_count = randi_range(2, 4)
	
	for i in range(appendage_count):
		var appendage_segments = randi_range(3, 6)
		var current_pos = Vector3.ZERO
		var current_direction = Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.8),
			randf_range(-1, 1)
		).normalized()
		
		for j in range(appendage_segments):
			var segment = CSGCylinder3D.new()
			segment.height = size * 0.8
			segment.radius = size * 0.3 * (1.0 - float(j) / appendage_segments)
			
			current_pos += current_direction * segment.height
			segment.position = current_pos
			segment.look_at_from_position(segment.position, current_pos + current_direction, Vector3.UP)
			
			add_child(segment)
			base_forms.append(segment)
			
			# Organic curve in direction
			current_direction += Vector3(
				randf_range(-0.3, 0.3),
				randf_range(-0.2, 0.2),
				randf_range(-0.3, 0.3)
			)
			current_direction = current_direction.normalized()

func apply_niki_materials():
	"""Apply bright, colorful Niki de Saint Phalle-style materials"""
	if not material_system:
		return
	
	for i in range(base_forms.size()):
		var form = base_forms[i]
		var material = material_system.get_niki_material(color_scheme, i)
		form.material = material

func add_surface_details():
	"""Add surface texture and pattern details"""
	# Add small decorative elements
	for form in base_forms:
		if randf() > 0.7:  # Only some forms get details
			add_decorative_spots(form)

func add_decorative_spots(parent: CSGShape3D):
	"""Add small colorful spots like Niki's mosaic patterns"""
	var spot_count = randi_range(3, 8)
	
	for i in range(spot_count):
		var spot = CSGSphere3D.new()
		spot.radius = 0.1
		spot.position = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized() * parent.radius * randf_range(0.8, 1.1)
		
		if material_system:
			spot.material = material_system.get_accent_material()
		
		parent.add_child(spot)

func update_based_on_motion(motion_data: Dictionary):
	"""Update the Niki form based on the driving mechanism motion"""
	var extension = motion_data.get("extension", 0.0)
	var rotation = motion_data.get("rotation", 0.0)
	
	# Scale based on piston extension
	var scale_factor = 1.0 + (extension / 10.0)  # Subtle scaling
	scale = base_scale * scale_factor
	
	# Gentle rotation based on mechanism
	rotation_degrees.y = rad_to_deg(rotation * 0.2)
	
	# Organic "breathing" motion
	for i in range(base_forms.size()):
		var form = base_forms[i]
		var breath_factor = 1.0 + sin(rotation + i) * 0.1
		if form.has_method("set_radius"):
			# This would work for spheres - adjust for specific form types
			pass
