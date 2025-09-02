# UV-Based Texture Pixel Scanner - Samples actual texture pixels at hit point
extends Node3D

@export_category("Scanner Settings")
@export var scan_range: float = 15.0
@export var scan_frequency: float = 30.0

@export_category("Texture Pixel Sampling")
@export var enable_pixel_sampling: bool = true
@export var uv_debug: bool = true
@export var texture_debug: bool = true
@export var sample_area_size: int = 1  # Sample NxN pixels for averaging

@export_category("Visual Ray Settings")
@export var show_ray: bool = true
@export var ray_color_scanning: Color = Color(1, 0, 0, 0.8)
@export var ray_color_hit: Color = Color(0, 1, 0, 0.8)
@export var ray_thickness: float = 0.02

@export_category("Display Screen Settings")
@export var enable_screen_updates: bool = true
@export var screen_brightness: float = 1.5
@export var screen_off_color: Color = Color(0.1, 0.1, 0.1, 1.0)

var raycast: RayCast3D
var color_data_label: Label3D
var visual_ray: MeshInstance3D
var ray_material: StandardMaterial3D
var display_screen: MeshInstance3D
var screen_material: StandardMaterial3D
var scan_timer: float = 0.0
var detected_color: Color = Color.BLACK

# UV and texture data
var last_uv_coord: Vector2
var last_texture_data: Dictionary = {}
var current_direction: Vector3 = Vector3(0, 0, -1)

func _ready():
	print("=== UV TEXTURE PIXEL SCANNER STARTING ===")
	setup_components()
	setup_visual_ray()
	setup_raycast()
	
	print("UV texture pixel scanner ready!")
	update_display_screen(Color.BLACK, false)

func setup_components():
	"""Setup scanner components"""
	
	# RayCast3D
	raycast = find_child("RayCast3D", true, false)
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "UVScannerRayCast"
		add_child(raycast)
	
	# Label
	color_data_label = find_child("ColorDataLabel", true, false)
	if not color_data_label:
		color_data_label = Label3D.new()
		color_data_label.name = "ColorDisplay"
		color_data_label.position = Vector3(0, 0.1, 0)
		color_data_label.font_size = 28
		color_data_label.outline_size = 2
		add_child(color_data_label)
	
	# Find display screen
	display_screen = get_node_or_null("../GrabStick_ColorScanner#DisplayScreen")
	setup_display_screen()

func setup_display_screen():
	"""Setup display screen"""
	
	if not display_screen:
		enable_screen_updates = false
		return
	
	screen_material = display_screen.get_surface_override_material(0)
	if not screen_material:
		screen_material = StandardMaterial3D.new()
		display_screen.set_surface_override_material(0, screen_material)
	
	screen_material.flags_unshaded = true
	screen_material.emission_enabled = true
	screen_material.emission_energy = screen_brightness
	screen_material.albedo_color = screen_off_color
	screen_material.emission = screen_off_color

func setup_visual_ray():
	"""Create visual ray"""
	
	if not show_ray:
		return
	
	visual_ray = MeshInstance3D.new()
	visual_ray.name = "UVSampleRay"
	add_child(visual_ray)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(ray_thickness, ray_thickness, scan_range)
	visual_ray.mesh = box_mesh
	visual_ray.position = Vector3(0, 0, -scan_range / 2)
	
	ray_material = StandardMaterial3D.new()
	ray_material.flags_unshaded = true
	ray_material.flags_transparent = true
	ray_material.emission_enabled = true
	ray_material.emission = ray_color_scanning
	ray_material.albedo_color = ray_color_scanning
	visual_ray.set_surface_override_material(0, ray_material)

func setup_raycast():
	"""Setup RayCast3D"""
	
	raycast.enabled = true
	raycast.target_position = current_direction * scan_range
	raycast.collision_mask = 0xFFFFFFFF
	raycast.collide_with_bodies = true
	raycast.collide_with_areas = true

func _process(delta):
	scan_timer += delta
	
	if scan_timer >= (1.0 / scan_frequency):
		perform_uv_texture_scan()
		scan_timer = 0.0

func perform_uv_texture_scan():
	"""Perform UV-based texture pixel sampling"""
	
	if not raycast:
		return
	
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit_object = raycast.get_collider()
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		var hit_distance = global_position.distance_to(hit_point)
		
		print("=== UV TEXTURE SCAN ===")
		print("HIT: ", hit_object.name, " (", hit_object.get_class(), ")")
		print("Hit point: ", hit_point)
		
		# Extract color using UV texture sampling
		detected_color = extract_texture_pixel_color(hit_object, hit_point, hit_normal)
		
		update_ray_for_hit(hit_distance)
		update_display_hit(hit_object, hit_distance)
		update_display_screen(detected_color, true)
		
	else:
		detected_color = Color.BLACK
		update_ray_for_miss()
		update_display_miss()
		update_display_screen(screen_off_color, false)

func extract_texture_pixel_color(hit_object: Node, hit_point: Vector3, hit_normal: Vector3) -> Color:
	"""Extract actual texture pixel color at hit point"""
	
	var mesh_instance = find_mesh_instance(hit_object)
	if not mesh_instance:
		print("No MeshInstance3D found")
		return Color.BLACK
	
	#print("Found mesh: ", mesh_instance.name)
	
	# Calculate UV coordinates at hit point
	var uv_coord = calculate_precise_uv(mesh_instance, hit_point)
	if uv_coord == Vector2(-1, -1):
		print("UV calculation failed")
		return fallback_material_color(mesh_instance)
	
	print("UV coordinates: ", uv_coord)
	last_uv_coord = uv_coord
	
	# Get material and sample texture
	var sampled_color = sample_texture_at_uv(mesh_instance, uv_coord)
	
	if sampled_color != Color.BLACK:
		print("Successfully sampled texture pixel: ", sampled_color)
		return sampled_color
	else:
		print("Texture sampling failed, using material fallback")
		return fallback_material_color(mesh_instance)

func find_mesh_instance(hit_object: Node) -> MeshInstance3D:
	"""Find the MeshInstance3D associated with the hit collider"""
	
	# Direct mesh hit
	if hit_object is MeshInstance3D:
		return hit_object as MeshInstance3D
	
	# Physics body with mesh children
	if hit_object.has_method("get_children"):
		for child in hit_object.get_children():
			if child is MeshInstance3D:
				return child as MeshInstance3D
	
	return null

func calculate_precise_uv(mesh_instance: MeshInstance3D, world_hit_point: Vector3) -> Vector2:
	"""Calculate precise UV coordinates for the hit point"""
	
	if not mesh_instance.mesh:
		return Vector2(-1, -1)
	
	# Convert to local space
	var local_hit = mesh_instance.to_local(world_hit_point)
	
	print("Local hit point: ", local_hit)
	
	# Handle different mesh types
	if mesh_instance.mesh is BoxMesh:
		return calculate_box_uv(mesh_instance.mesh as BoxMesh, local_hit)
	elif mesh_instance.mesh is PlaneMesh:
		return calculate_plane_uv(mesh_instance.mesh as PlaneMesh, local_hit)
	elif mesh_instance.mesh is QuadMesh:
		return calculate_quad_uv(mesh_instance.mesh as QuadMesh, local_hit)
	else:
		print("Unsupported mesh type: ", mesh_instance.mesh.get_class())
		return Vector2(0.5, 0.5)  # Center fallback

func calculate_box_uv(box_mesh: BoxMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for BoxMesh at local hit point"""
	
	var size = box_mesh.size
	print("Box size: ", size)
	
	# Find which face was hit by checking which coordinate is at the edge
	var abs_point = Vector3(abs(local_point.x), abs(local_point.y), abs(local_point.z))
	var half_size = size * 0.5
	
	# Determine which face by finding the coordinate closest to the edge
	var face_tolerance = 0.01
	
	if abs(abs_point.x - half_size.x) < face_tolerance:
		# Hit X face (left/right side)
		var u = (local_point.z + half_size.z) / size.z
		var v = (local_point.y + half_size.y) / size.y
		print("Hit X face, UV: ", Vector2(u, 1.0 - v))
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))
		
	elif abs(abs_point.y - half_size.y) < face_tolerance:
		# Hit Y face (top/bottom)
		var u = (local_point.x + half_size.x) / size.x
		var v = (local_point.z + half_size.z) / size.z
		print("Hit Y face, UV: ", Vector2(u, 1.0 - v))
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))
		
	elif abs(abs_point.z - half_size.z) < face_tolerance:
		# Hit Z face (front/back)
		var u = (local_point.x + half_size.x) / size.x
		var v = (local_point.y + half_size.y) / size.y
		print("Hit Z face, UV: ", Vector2(u, 1.0 - v))
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))
	
	print("Could not determine hit face")
	return Vector2(0.5, 0.5)

func calculate_plane_uv(plane_mesh: PlaneMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for PlaneMesh"""
	
	var size = plane_mesh.size
	var u = (local_point.x + size.x/2) / size.x
	var v = (local_point.z + size.y/2) / size.y
	
	return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))

func calculate_quad_uv(quad_mesh: QuadMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for QuadMesh"""
	
	var size = quad_mesh.size
	var u = (local_point.x + size.x/2) / size.x
	var v = (local_point.y + size.y/2) / size.y
	
	return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))

func sample_texture_at_uv(mesh_instance: MeshInstance3D, uv_coord: Vector2) -> Color:
	"""Sample texture pixel at UV coordinate"""
	
	var material = get_material_from_mesh(mesh_instance)
	if not material:
		print("No material found")
		return Color.BLACK
	
	print("Material type: ", material.get_class())
	
	# Handle StandardMaterial3D
	if material is StandardMaterial3D:
		var std_mat = material as StandardMaterial3D
		
		# Check if there's an albedo texture
		if std_mat.albedo_texture:
			print("Found albedo texture!")
			var texture_color = sample_texture_pixel(std_mat.albedo_texture, uv_coord)
			
			# Combine texture color with albedo color (material tinting)
			var final_color = texture_color * std_mat.albedo_color
			print("Texture color: ", texture_color, " * Albedo: ", std_mat.albedo_color, " = ", final_color)
			return final_color
		else:
			# No texture, just return albedo color
			print("No texture, using albedo color: ", std_mat.albedo_color)
			return std_mat.albedo_color
	
	# Handle ShaderMaterial
	elif material is ShaderMaterial:
		var shader_mat = material as ShaderMaterial
		return sample_shader_texture(shader_mat, uv_coord)
	
	return Color.BLACK

func get_material_from_mesh(mesh_instance: MeshInstance3D) -> Material:
	"""Get material from mesh in priority order"""
	
	# Priority 1: Material override
	if mesh_instance.material_override:
		print("Using material_override")
		return mesh_instance.material_override
	
	# Priority 2: Surface material overrides
	if mesh_instance.get_surface_override_material(0):
		print("Using surface_override_material")
		return mesh_instance.get_surface_override_material(0)
	
	# Priority 3: Mesh surface materials
	if mesh_instance.mesh and mesh_instance.mesh.get_surface_count() > 0:
		var surface_mat = mesh_instance.mesh.surface_get_material(0)
		if surface_mat:
			print("Using mesh surface material")
			return surface_mat
	
	return null

func sample_texture_pixel(texture: Texture2D, uv_coord: Vector2) -> Color:
	"""Sample a pixel from texture at UV coordinate"""
	
	if not texture:
		return Color.BLACK
	
	var image: Image = null
	
	# Get image from texture
	if texture is ImageTexture:
		image = (texture as ImageTexture).get_image()
	elif texture.has_method("get_image"):
		image = texture.get_image()
	
	if not image:
		print("Could not get image from texture")
		return Color.BLACK
	
	var texture_size = image.get_size()
	print("Texture size: ", texture_size)
	
	# Convert UV to pixel coordinates
	var pixel_x = int(uv_coord.x * (texture_size.x - 1))
	var pixel_y = int(uv_coord.y * (texture_size.y - 1))
	
	# Clamp to texture bounds
	pixel_x = clamp(pixel_x, 0, texture_size.x - 1)
	pixel_y = clamp(pixel_y, 0, texture_size.y - 1)
	
	print("Sampling texture pixel at: (", pixel_x, ", ", pixel_y, ")")
	
	# Sample pixel or area
	if sample_area_size > 1:
		return sample_texture_area(image, pixel_x, pixel_y, sample_area_size)
	else:
		var pixel_color = image.get_pixel(pixel_x, pixel_y)
		print("Sampled pixel color: ", pixel_color)
		return pixel_color

func sample_texture_area(image: Image, center_x: int, center_y: int, area_size: int) -> Color:
	"""Sample an area of texture pixels and average them"""
	
	var total_r = 0.0
	var total_g = 0.0
	var total_b = 0.0
	var sample_count = 0
	
	var half_area = area_size / 2
	var texture_size = image.get_size()
	
	for x in range(center_x - half_area, center_x + half_area + 1):
		for y in range(center_y - half_area, center_y + half_area + 1):
			if x >= 0 and x < texture_size.x and y >= 0 and y < texture_size.y:
				var pixel = image.get_pixel(x, y)
				total_r += pixel.r
				total_g += pixel.g
				total_b += pixel.b
				sample_count += 1
	
	if sample_count == 0:
		return Color.BLACK
	
	var average_color = Color(total_r / sample_count, total_g / sample_count, total_b / sample_count, 1.0)
	print("Averaged ", sample_count, " texture pixels: ", average_color)
	return average_color

func sample_shader_texture(shader_mat: ShaderMaterial, uv_coord: Vector2) -> Color:
	"""Sample texture from shader material"""
	
	# Common texture parameter names in shaders
	var texture_params = ["texture", "albedo_texture", "main_texture", "diffuse", "base_texture"]
	
	for param_name in texture_params:
		var texture = shader_mat.get_shader_parameter(param_name)
		if texture and texture is Texture2D:
			print("Found shader texture parameter: ", param_name)
			return sample_texture_pixel(texture, uv_coord)
	
	# Try color parameters as fallback
	var color_params = ["color", "albedo", "base_color", "tint"]
	for param_name in color_params:
		var color = shader_mat.get_shader_parameter(param_name)
		if color and color is Color:
			print("Found shader color parameter: ", param_name, " = ", color)
			return color
	
	return Color.BLACK

func fallback_material_color(mesh_instance: MeshInstance3D) -> Color:
	"""Fallback to material color when texture sampling fails"""
	
	var material = get_material_from_mesh(mesh_instance)
	
	if material is StandardMaterial3D:
		var std_mat = material as StandardMaterial3D
		print("Fallback to albedo color: ", std_mat.albedo_color)
		return std_mat.albedo_color
	
	return Color.BLACK

func update_ray_for_hit(distance: float):
	"""Update ray for hit"""
	
	if not visual_ray or not ray_material:
		return
	
	var box_mesh = visual_ray.mesh as BoxMesh
	if box_mesh:
		box_mesh.size.z = distance
		visual_ray.position.z = -distance / 2
	
	ray_material.emission = ray_color_hit
	ray_material.albedo_color = ray_color_hit

func update_ray_for_miss():
	"""Update ray for miss"""
	
	if not visual_ray or not ray_material:
		return
	
	var box_mesh = visual_ray.mesh as BoxMesh
	if box_mesh:
		box_mesh.size.z = scan_range
		visual_ray.position.z = -scan_range / 2
	
	ray_material.emission = ray_color_scanning
	ray_material.albedo_color = ray_color_scanning

func update_display_hit(hit_object: Node, distance: float):
	"""Update display for hits"""
	
	if not color_data_label:
		return
	
	var r = int(detected_color.r * 255)
	var g = int(detected_color.g * 255)
	var b = int(detected_color.b * 255)
	
	var info_text = "TEXTURE PIXEL!\n%s\nRGB: %d,%d,%d\n%.1fm" % [
		hit_object.name,
		r, g, b,
		distance
	]
	
	# Add UV info
	info_text += "\nUV: %.3f,%.3f" % [last_uv_coord.x, last_uv_coord.y]
	
	color_data_label.text = info_text
	
	var display_color = detected_color
	if display_color.get_luminance() < 0.3:
		display_color = display_color.lightened(0.5)
	color_data_label.modulate = display_color

func update_display_miss():
	"""Update display for misses"""
	
	if not color_data_label:
		return
	
	color_data_label.text = "UV SCANNING...\nRange: %.1fm" % scan_range
	color_data_label.modulate = Color.WHITE

func update_display_screen(color: Color, is_active: bool):
	"""Update display screen"""
	
	if not enable_screen_updates or not display_screen or not screen_material:
		return
	
	if is_active and color != Color.BLACK:
		screen_material.albedo_color = color
		screen_material.emission = color * screen_brightness
		
		var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
		screen_material.emission_energy = screen_brightness * pulse
	else:
		screen_material.albedo_color = screen_off_color
		screen_material.emission = screen_off_color
		screen_material.emission_energy = screen_brightness * 0.3

# Public API
func get_last_uv_coordinates() -> Vector2:
	"""Get UV coordinates of last hit"""
	return last_uv_coord

func get_texture_data() -> Dictionary:
	"""Get detailed texture sampling data"""
	return last_texture_data

func toggle_uv_debug():
	"""Toggle UV calculation debug output"""
	uv_debug = not uv_debug
	texture_debug = not texture_debug
	print("UV/Texture debug: ", "enabled" if uv_debug else "disabled")

func test_uv_calculation():
	"""Test UV calculation with current hit"""
	print("=== UV CALCULATION TEST ===")
	if raycast and raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var hit_object = raycast.get_collider()
		var mesh_instance = find_mesh_instance(hit_object)
		
		if mesh_instance:
			print("Testing UV calculation for: ", mesh_instance.name)
			var uv = calculate_precise_uv(mesh_instance, hit_point)
			print("Calculated UV: ", uv)
		else:
			print("No mesh instance found for UV test")
	else:
		print("No current hit to test UV calculation")
