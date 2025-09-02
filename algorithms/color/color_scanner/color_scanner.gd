# Color Scanner - Handheld Ray Tracer for Color Detection
# Scans surfaces to detect and display their colors on a small built-in screen
extends Node3D

@export_category("Scanner Settings")
@export var scan_range: float = 10.0  # Maximum scanning distance
@export var scan_beam_width: float = 0.1  # Width of the scanning beam
@export var scan_frequency: float = 60.0  # Scans per second
@export var beam_color: Color = Color(0.8, 0.2, 0.2, 0.6)  # Red scanning beam
@export var scanner_sensitivity: float = 1.0

@export_category("Display Settings")
@export var screen_size: Vector2 = Vector2(0.2, 0.2)  # Screen dimensions
@export var screen_resolution: Vector2i = Vector2i(128, 96)  # Pixel resolution
@export var display_brightness: float = 1.0
@export var show_debug_info: bool = true

@export_category("Visual Effects")
@export var emit_scanning_beam: bool = true
@export var beam_intensity: float = 0.5
@export var screen_glow: bool = true
@export var scanner_animation: bool = true

# Scanner components
var scanner_body: MeshInstance3D
var display_screen: MeshInstance3D
var scanning_beam: MeshInstance3D
var screen_material: StandardMaterial3D
var beam_material: StandardMaterial3D

# Scanning system
var space_state: PhysicsDirectSpaceState3D
var scan_timer: float = 0.0
var current_scan_result: Dictionary = {}
var detected_color: Color = Color.BLACK
var is_scanning: bool = true

# Ray tracing data
var scan_origin: Vector3
var scan_direction: Vector3
var hit_point: Vector3
var hit_normal: Vector3
var hit_object: Node3D

# Screen display system
var screen_texture: ImageTexture
var screen_image: Image
var color_history: Array[Color] = []
var display_mode: String = "color_display"  # "color_display", "debug_info", "scan_pattern"

func _ready():
	# Enable debug for troubleshooting
	show_debug_info = true
	
	setup_scanner_geometry()
	setup_materials()
	setup_physics()
	setup_display_system()
	setup_scanning_beam()

func _process(delta):
	scan_timer += delta
	
	if is_scanning and scan_timer >= (1.0 / scan_frequency):
		perform_color_scan()
		update_display()
		scan_timer = 0.0
	
	if scanner_animation:
		animate_scanner(delta)
	
	update_scanning_beam()

func setup_scanner_geometry():
	"""Create the physical scanner device"""
	
	# Main scanner body
	scanner_body = MeshInstance3D.new()
	var scanner_mesh = BoxMesh.new()
	scanner_mesh.size = Vector3(0.8, 1.5, 0.3)
	scanner_body.mesh = scanner_mesh
	add_child(scanner_body)
	
	# Scanner body material
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.2, 0.2, 0.3)
	body_material.metallic = 0.8
	body_material.roughness = 0.3
	scanner_body.material_override = body_material
	
	# Display screen (mounted on top)
	display_screen = MeshInstance3D.new()
	var screen_mesh = BoxMesh.new()
	screen_mesh.size = Vector3(screen_size.x, 0.1, screen_size.y)
	display_screen.mesh = screen_mesh
	display_screen.position = Vector3(0, 0.8, 0)
	scanner_body.add_child(display_screen)
	
	# Scanner lens/sensor (front of device)
	var lens = MeshInstance3D.new()
	var lens_mesh = CylinderMesh.new()
	lens_mesh.top_radius = 0.15
	lens_mesh.bottom_radius = 0.15
	lens_mesh.height = 0.2
	lens.mesh = lens_mesh
	lens.position = Vector3(0, 0, -0.25)
	lens.rotation = Vector3(PI/2, 0, 0)
	scanner_body.add_child(lens)
	
	# Lens material
	var lens_material = StandardMaterial3D.new()
	lens_material.albedo_color = Color(0.1, 0.1, 0.1)
	lens_material.metallic = 0.9
	lens_material.roughness = 0.1
	lens.material_override = lens_material

func setup_materials():
	"""Setup materials for screen and beam"""
	
	# Screen material with texture
	screen_material = StandardMaterial3D.new()
	screen_material.emission_enabled = true
	screen_material.emission_energy = display_brightness
	screen_material.albedo_color = Color.BLACK
	
	if screen_glow:
		screen_material.emission = Color.WHITE
	
	display_screen.material_override = screen_material
	
	# Beam material for scanning ray
	beam_material = StandardMaterial3D.new()
	beam_material.albedo_color = beam_color
	beam_material.emission_enabled = true
	beam_material.emission = beam_color * beam_intensity
	beam_material.flags_transparent = true
	beam_material.flags_unshaded = true

func setup_physics():
	"""Initialize physics for ray casting"""
	space_state = get_world_3d().direct_space_state

func setup_display_system():
	"""Create the color display system"""
	
	# Create screen image and texture
	screen_image = Image.create(screen_resolution.x, screen_resolution.y, false, Image.FORMAT_RGB8)
	screen_image.fill(Color.BLACK)
	screen_texture = ImageTexture.new()
	screen_texture.set_image(screen_image)
	
	# Apply texture to screen material
	screen_material.albedo_texture = screen_texture
	
	# Initialize color history
	for i in range(10):
		color_history.append(Color.BLACK)

func setup_scanning_beam():
	"""Create the visible scanning beam"""
	if not emit_scanning_beam:
		return
		
	scanning_beam = MeshInstance3D.new()
	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(scan_beam_width, scan_beam_width, scan_range)
	scanning_beam.mesh = beam_mesh
	scanning_beam.material_override = beam_material
	scanning_beam.position = Vector3(0, 0, -scan_range * 0.5)
	scanner_body.add_child(scanning_beam)

func perform_color_scan():
	"""Perform ray tracing to detect surface color"""
	
	# Calculate scan origin and direction
	scan_origin = scanner_body.global_position + Vector3(0, 0, -0.3)
	scan_direction = -scanner_body.global_transform.basis.z
	
	# Create ray query
	var query = PhysicsRayQueryParameters3D.create(
		scan_origin, 
		scan_origin + scan_direction * scan_range
	)
	query.collision_mask = 0xFFFFFFFF  # Scan all layers
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Perform ray cast
	var result = space_state.intersect_ray(query)
	
	if result:
		hit_point = result.position
		hit_normal = result.normal
		hit_object = result.collider
		
		# Extract color from the hit surface
		detected_color = extract_surface_color(result)
		
		# Update scan result data
		current_scan_result = {
			"has_hit": true,
			"distance": scan_origin.distance_to(hit_point),
			"color": detected_color,
			"position": hit_point,
			"normal": hit_normal,
			"object_name": hit_object.name if hit_object else "Unknown"
		}
	else:
		# No hit - scanning empty space
		detected_color = Color.BLACK
		current_scan_result = {
			"has_hit": false,
			"distance": scan_range,
			"color": Color.BLACK,
			"position": scan_origin + scan_direction * scan_range,
			"normal": Vector3.ZERO,
			"object_name": "No Target"
		}
	
	# Add to color history
	color_history.append(detected_color)
	if color_history.size() > 10:
		color_history.pop_front()

func extract_surface_color(ray_result: Dictionary) -> Color:
	"""Extract color from the surface at the hit point"""
	
	var surface_color = Color.BLACK  # Default color (black for no detection)
	
	# Debug output to help troubleshoot
	if show_debug_info:
		print("Scanner hit object: ", ray_result.collider.name if ray_result.collider else "None")
	
	# Try to get color from the material
	if ray_result.collider and ray_result.collider is StaticBody3D:
		# If we hit a StaticBody3D, find the closest MeshInstance3D child at the hit point
		var static_body = ray_result.collider as StaticBody3D
		var hit_position = ray_result.position
		var closest_mesh: MeshInstance3D = null
		var closest_distance = INF
		
		# Find the closest color sheet to the hit point
		for child in static_body.get_children():
			if child is MeshInstance3D and child.name.begins_with("ColorSheet"):
				var mesh_instance = child as MeshInstance3D
				var distance = mesh_instance.global_position.distance_to(hit_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_mesh = mesh_instance
		
		if closest_mesh:
			if show_debug_info:
				print("Found closest color sheet: ", closest_mesh.name)
			
			# Check surface material overrides (this is the format used in our scene)
			if closest_mesh.get_surface_override_material(0):
				surface_color = get_material_color(closest_mesh.get_surface_override_material(0))
				if show_debug_info:
					print("Found surface override material color: ", surface_color)
			
			# Check material override
			elif closest_mesh.material_override:
				surface_color = get_material_color(closest_mesh.material_override)
				if show_debug_info:
					print("Found material override color: ", surface_color)
			
			# Check surface materials
			elif closest_mesh.mesh and closest_mesh.mesh.get_surface_count() > 0:
				var surface_material = closest_mesh.mesh.surface_get_material(0)
				if surface_material:
					surface_color = get_material_color(surface_material)
					if show_debug_info:
						print("Found surface material color: ", surface_color)
	
	# Also handle direct MeshInstance3D hits
	elif ray_result.collider and ray_result.collider is MeshInstance3D:
		var mesh_instance = ray_result.collider as MeshInstance3D
		
		# Check surface material overrides (new format)
		if mesh_instance.get_surface_override_material(0):
			surface_color = get_material_color(mesh_instance.get_surface_override_material(0))
			if show_debug_info:
				print("Found direct surface override material color: ", surface_color)
		
		# Check material override first
		elif mesh_instance.material_override:
			surface_color = get_material_color(mesh_instance.material_override)
			if show_debug_info:
				print("Found direct material override color: ", surface_color)
		
		# Check surface materials
		elif mesh_instance.mesh and mesh_instance.mesh.get_surface_count() > 0:
			var surface_material = mesh_instance.mesh.surface_get_material(0)
			if surface_material:
				surface_color = get_material_color(surface_material)
				if show_debug_info:
					print("Found direct surface material color: ", surface_color)
	
	# For colorsheet palette detection, check for ColorRect nodes
	elif ray_result.collider and ray_result.collider.has_method("get_color"):
		surface_color = ray_result.collider.get_color()
		if show_debug_info:
			print("Found custom color method: ", surface_color)
	
	# Apply scanner sensitivity
	surface_color = surface_color * scanner_sensitivity
	surface_color.a = 1.0  # Ensure full opacity for display
	
	if show_debug_info:
		print("Final detected color: ", surface_color)
	
	return surface_color

func get_material_color(material: Material) -> Color:
	"""Extract color from different material types"""
	
	if material is StandardMaterial3D:
		var std_mat = material as StandardMaterial3D
		return std_mat.albedo_color
		
	elif material is ShaderMaterial:
		var shader_mat = material as ShaderMaterial
		# Try to get color from common shader parameters
		if shader_mat.get_shader_parameter("albedo"):
			return shader_mat.get_shader_parameter("albedo")
		elif shader_mat.get_shader_parameter("color"):
			return shader_mat.get_shader_parameter("color")
		elif shader_mat.get_shader_parameter("base_color"):
			return shader_mat.get_shader_parameter("base_color")
	
	return Color.WHITE

func update_display():
	"""Update the scanner's display screen"""
	
	match display_mode:
		"color_display":
			draw_color_display()
		"debug_info":
			draw_debug_display()
		"scan_pattern":
			draw_scan_pattern()
	
	# Update the texture
	screen_texture.update(screen_image)

func draw_color_display():
	"""Draw the detected color on the screen"""
	
	# Clear screen
	screen_image.fill(Color.BLACK)
	
	# Main color display (center area)
	var center_rect = Rect2i(
		screen_resolution.x * 0.1,
		screen_resolution.y * 0.1,
		screen_resolution.x * 0.8,
		screen_resolution.y * 0.6
	)
	screen_image.fill_rect(center_rect, detected_color)
	
	# Color history strip (bottom)
	var history_width = screen_resolution.x / color_history.size()
	for i in range(color_history.size()):
		var hist_rect = Rect2i(
			i * history_width,
			screen_resolution.y * 0.8,
			history_width,
			screen_resolution.y * 0.2
		)
		screen_image.fill_rect(hist_rect, color_history[i])
	
	# Add border
	draw_border(Color.WHITE, 2)

func draw_debug_display():
	"""Draw debugging information"""
	
	screen_image.fill(Color(0.1, 0.1, 0.1))
	
	# This would be more complex with actual text rendering
	# For now, just show colored indicators
	
	# Hit indicator
	var hit_color = Color.GREEN if current_scan_result.get("has_hit", false) else Color.RED
	var hit_rect = Rect2i(10, 10, 20, 20)
	screen_image.fill_rect(hit_rect, hit_color)
	
	# Distance indicator (as a color gradient)
	if current_scan_result.has("distance"):
		var distance_normalized = current_scan_result.distance / scan_range
		var distance_color = Color(distance_normalized, 1.0 - distance_normalized, 0.0)
		var dist_rect = Rect2i(40, 10, 60, 20)
		screen_image.fill_rect(dist_rect, distance_color)
	
	# Current color sample
	var color_rect = Rect2i(10, 40, screen_resolution.x - 20, 30)
	screen_image.fill_rect(color_rect, detected_color)

func draw_scan_pattern():
	"""Draw scanning pattern visualization"""
	
	screen_image.fill(Color.BLACK)
	
	# Radar-like sweep pattern
	var center = Vector2i(screen_resolution.x / 2, screen_resolution.y / 2)
	var radius = min(screen_resolution.x, screen_resolution.y) / 3
	
	# Draw concentric circles
	for r in range(1, 4):
		draw_circle_outline(center, radius * r / 3, Color(0.2, 0.8, 0.2, 0.5))
	
	# Draw sweep line
	var sweep_angle = Time.get_ticks_msec() * 0.002
	var sweep_end = center + Vector2i(
		cos(sweep_angle) * radius,
		sin(sweep_angle) * radius
	)
	draw_line(center, sweep_end, Color.GREEN)
	
	# Show detected color as a dot
	if current_scan_result.get("has_hit", false):
		var dot_pos = center + Vector2i(
			cos(sweep_angle) * radius * 0.8,
			sin(sweep_angle) * radius * 0.8
		)
		draw_filled_circle(dot_pos, 5, detected_color)

func draw_border(color: Color, thickness: int):
	"""Draw a border around the screen"""
	
	# Top and bottom borders
	for i in range(thickness):
		var top_rect = Rect2i(0, i, screen_resolution.x, 1)
		var bottom_rect = Rect2i(0, screen_resolution.y - 1 - i, screen_resolution.x, 1)
		screen_image.fill_rect(top_rect, color)
		screen_image.fill_rect(bottom_rect, color)
	
	# Left and right borders
	for i in range(thickness):
		var left_rect = Rect2i(i, 0, 1, screen_resolution.y)
		var right_rect = Rect2i(screen_resolution.x - 1 - i, 0, 1, screen_resolution.y)
		screen_image.fill_rect(left_rect, color)
		screen_image.fill_rect(right_rect, color)

func draw_circle_outline(center: Vector2i, radius: int, color: Color):
	"""Draw a circle outline on the screen"""
	
	# Simple circle drawing using Bresenham-like algorithm
	for angle in range(0, 360, 5):
		var rad = deg_to_rad(angle)
		var x = center.x + int(cos(rad) * radius)
		var y = center.y + int(sin(rad) * radius)
		
		if x >= 0 and x < screen_resolution.x and y >= 0 and y < screen_resolution.y:
			screen_image.set_pixel(x, y, color)

func draw_line(start: Vector2i, end: Vector2i, color: Color):
	"""Draw a line on the screen"""
	
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var x = start.x
	var y = start.y
	var x_inc = 1 if end.x > start.x else -1
	var y_inc = 1 if end.y > start.y else -1
	var error = dx - dy
	
	while true:
		if x >= 0 and x < screen_resolution.x and y >= 0 and y < screen_resolution.y:
			screen_image.set_pixel(x, y, color)
		
		if x == end.x and y == end.y:
			break
			
		var e2 = 2 * error
		if e2 > -dy:
			error -= dy
			x += x_inc
		if e2 < dx:
			error += dx
			y += y_inc

func draw_filled_circle(center: Vector2i, radius: int, color: Color):
	"""Draw a filled circle on the screen"""
	
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				var px = center.x + x
				var py = center.y + y
				if px >= 0 and px < screen_resolution.x and py >= 0 and py < screen_resolution.y:
					screen_image.set_pixel(px, py, color)

func animate_scanner(delta):
	"""Add subtle animation to the scanner"""
	
	var time = Time.get_ticks_msec() * 0.001
	
	# Gentle bobbing motion
	var bob_offset = sin(time * 0.5) * 0.05
	position.y += bob_offset * delta
	
	# Subtle beam pulsing
	if scanning_beam:
		var pulse = 0.8 + 0.2 * sin(time * 3.0)
		beam_material.emission = beam_color * beam_intensity * pulse

func update_scanning_beam():
	"""Update the scanning beam visualization"""
	
	if not scanning_beam or not emit_scanning_beam:
		return
	
	# Adjust beam length based on scan result
	var beam_length = scan_range
	if current_scan_result.get("has_hit", false):
		beam_length = current_scan_result.distance
	
	# Update beam geometry
	var beam_mesh = scanning_beam.mesh as BoxMesh
	beam_mesh.size.z = beam_length
	scanning_beam.position.z = -beam_length * 0.5 - 0.3
	
	# Change beam color when hitting something
	if current_scan_result.get("has_hit", false):
		beam_material.emission = Color.GREEN * beam_intensity
	else:
		beam_material.emission = beam_color * beam_intensity

# Public API for external control
func set_scanning_enabled(enabled: bool):
	"""Enable or disable scanning"""
	is_scanning = enabled

func set_display_mode(mode: String):
	"""Change display mode"""
	if mode in ["color_display", "debug_info", "scan_pattern"]:
		display_mode = mode

func get_current_color() -> Color:
	"""Get the currently detected color"""
	return detected_color

func get_scan_data() -> Dictionary:
	"""Get complete scan result data"""
	return current_scan_result

func calibrate_scanner():
	"""Perform scanner calibration"""
	# Reset color history
	color_history.clear()
	for i in range(10):
		color_history.append(Color.BLACK)
	
	# Reset detection sensitivity
	scanner_sensitivity = 1.0
	
	print("Color Scanner calibrated")
