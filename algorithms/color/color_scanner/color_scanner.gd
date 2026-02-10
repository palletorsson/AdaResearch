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
@export var ray_thickness: float = 0.005

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
var texture_image_cache: Dictionary = {} # Cache for texture images to avoid expensive get_image() calls
var current_direction: Vector3 = Vector3(0, 0, -1)
# Optical Scanning System
var scan_viewport: SubViewport
var scan_camera: Camera3D
var scan_texture: ViewportTexture
var viewport_ready: bool = false


func _ready():
	print("=== UV TEXTURE PIXEL SCANNER STARTING ===")
	setup_components()
	setup_optical_scanner()
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
	
	# Find display screen
	display_screen = get_node_or_null("../GrabStick_ColorScanner#DisplayScreen")
	# If parent not found, try finding it by name under this node's parent's parent structure (Scene dependent)
	if not display_screen:
		# Search up the tree or siblings
		var parent = get_parent()
		if parent:
			display_screen = parent.get_node_or_null("GrabStick_ColorScanner#DisplayScreen")

	setup_display_screen()
	
	# Setup Label ON the display screen
	if display_screen:
		color_data_label = display_screen.find_child("ColorDisplay", false, false)
		if not color_data_label:
			color_data_label = Label3D.new()
			color_data_label.name = "ColorDisplay"
			display_screen.add_child(color_data_label)
			
		color_data_label.position = Vector3(0, 0.06, 0) # Just above surface
	# Updated rotation per user request: -x 90, 0 z
		color_data_label.rotation_degrees = Vector3(-90, 0, 0) 
		color_data_label.font_size = 128
		color_data_label.outline_size = 8
		# Inverse scale to counteract parent's non-uniform scale
		# Screen is approx (2.7, 4.4, 1.0) ? Wait, let's just try small uniform scale first.
		color_data_label.scale = Vector3(0.05, 0.05, 0.05)
	else:
		print("Warning: Display Screen not found for Label attachment")

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
	visual_ray.scale = Vector3(0.15, 1.0, 1.0) # Fix scale distortion
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
	
	# Update Scan Camera to match RayCast/Scanner direction
	if viewport_ready and scan_camera:
		# Sync camera global transform with this node
		scan_camera.global_transform = global_transform
	
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
		
		if uv_debug:
			print("=== UV TEXTURE SCAN ===")
			print("HIT: ", hit_object.name, " (", hit_object.get_class(), ")")
			print("Hit point: ", hit_point)
		
		# Extract color using Optical Scanning (Secondary) or UV texture sampling (Primary)
		detected_color = extract_texture_pixel_color(hit_object, hit_point, hit_normal)
		# detected_color = scan_actual_color()
		
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
	
	if uv_debug: print("UV coordinates: ", uv_coord)
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

	# Check parent (common case: StaticBody3D is child of MeshInstance3D)
	if hit_object.get_parent() and hit_object.get_parent() is MeshInstance3D:
		print("Found mesh as parent of: ", hit_object.name)
		return hit_object.get_parent() as MeshInstance3D

	# Physics body with mesh children (alternative structure)
	if hit_object.has_method("get_children"):
		for child in hit_object.get_children():
			if child is MeshInstance3D:
				return child as MeshInstance3D

	# Search siblings (if StaticBody3D and MeshInstance3D are siblings)
	if hit_object.get_parent():
		for sibling in hit_object.get_parent().get_children():
			if sibling is MeshInstance3D:
				print("Found mesh as sibling of: ", hit_object.name)
				return sibling as MeshInstance3D

	return null

func scan_actual_color() -> Color:
	if not viewport_ready or not scan_viewport:
		return Color.BLACK
		
	# Get the image from the viewport
	# Optimization: Only scan every N frames is handled by scan_frequency in _process
	
	var img = scan_viewport.get_texture().get_image()
	if img:
		# Sample the center pixel (1, 1) of 2x2 viewport
		return img.get_pixel(1, 1)
	return Color.BLACK

func setup_optical_scanner():
	# Create a tiny viewport for fetching render data
	scan_viewport = SubViewport.new()
	scan_viewport.size = Vector2i(2, 2) # Very small for performance
	scan_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	scan_viewport.handle_input_locally = false
	scan_viewport.gui_disable_input = true
	add_child(scan_viewport)
	
	# Create camera for the viewport
	scan_camera = Camera3D.new()
	scan_camera.fov = 5.0 # Narrow FOV to focus on the "ray"
	scan_camera.near = 0.05
	scan_camera.far = 100.0
	scan_viewport.add_child(scan_camera)
	
	viewport_ready = true
	if texture_debug: print("Optical scanner initialized")

func calculate_precise_uv(mesh_instance: MeshInstance3D, world_hit_point: Vector3) -> Vector2:
	"""Calculate precise UV coordinates for the hit point"""
	
	if not mesh_instance.mesh:
		return Vector2(-1, -1)
	
	# Convert to local space
	var local_hit = mesh_instance.to_local(world_hit_point)
	
	# if uv_debug: print("Local hit point: ", local_hit)
	
	# Handle different mesh types
	if mesh_instance.mesh is BoxMesh:
		return calculate_box_uv(mesh_instance.mesh as BoxMesh, local_hit)
	elif mesh_instance.mesh is CylinderMesh:
		return calculate_cylinder_uv(mesh_instance.mesh as CylinderMesh, local_hit)
	elif mesh_instance.mesh is PlaneMesh:
		return calculate_plane_uv(mesh_instance.mesh as PlaneMesh, local_hit)
	elif mesh_instance.mesh is QuadMesh:
		return calculate_quad_uv(mesh_instance.mesh as QuadMesh, local_hit)
	elif mesh_instance.mesh is ArrayMesh:
		return calculate_arraymesh_uv(mesh_instance.mesh as ArrayMesh, local_hit)
	elif mesh_instance.mesh is SphereMesh:
		return calculate_sphere_uv(mesh_instance.mesh as SphereMesh, local_hit)
	else:
		print("Unsupported mesh type: ", mesh_instance.mesh.get_class())
		return Vector2(0.5, 0.5)  # Center fallback

func calculate_box_uv(box_mesh: BoxMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for BoxMesh at local hit point"""
	
	var size = box_mesh.size
	# if uv_debug: print("Box size: ", size)
	
	var half_size = size * 0.5
	# Normalize point relative to size to find dominant axis
	var relative_p = Vector3(
		local_point.x / half_size.x,
		local_point.y / half_size.y,
		local_point.z / half_size.z
	)
	var abs_p = relative_p.abs()
	var max_axis = abs_p.max_axis_index() # 0=x, 1=y, 2=z
	
	if max_axis == 0:
		# Hit X face (left/right side)
		var u = (local_point.z + half_size.z) / size.z
		var v = (local_point.y + half_size.y) / size.y
		# Flip U if on negative side? Depends on Godot mapping.
		if local_point.x < 0: u = 1.0 - u
		
		# if uv_debug: print("Hit X face, UV: ", Vector2(u, 1.0 - v))
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))
		
	elif max_axis == 1:
		# Hit Y face (top/bottom)
		var u = (local_point.x + half_size.x) / size.x
		var v = (local_point.z + half_size.z) / size.z
		# if uv_debug: print("Hit Y face, UV: ", Vector2(u, 1.0 - v))
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))
		
	else: # max_axis == 2
		# Hit Z face (front/back)
		var u = (local_point.x + half_size.x) / size.x
		var v = (local_point.y + half_size.y) / size.y
		if local_point.z > 0: u = 1.0 - u # Flip for front face logic
		
		# if uv_debug: print("Hit Z face, UV: ", Vector2(u, 1.0 - v))
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))

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

func calculate_cylinder_uv(cylinder_mesh: CylinderMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for CylinderMesh"""

	var height = cylinder_mesh.height
	var top_radius = cylinder_mesh.top_radius
	var bottom_radius = cylinder_mesh.bottom_radius

	# Check if hit top or bottom cap
	var half_height = height * 0.5
	var tolerance = 0.01

	if abs(local_point.y - half_height) < tolerance:
		# Top cap
		var u = (local_point.x / top_radius + 1.0) * 0.5
		var v = (local_point.z / top_radius + 1.0) * 0.5
		return Vector2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0))
	elif abs(local_point.y + half_height) < tolerance:
		# Bottom cap
		var u = (local_point.x / bottom_radius + 1.0) * 0.5
		var v = (local_point.z / bottom_radius + 1.0) * 0.5
		return Vector2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0))
	else:
		# Cylinder side - use cylindrical coordinates
		var angle = atan2(local_point.z, local_point.x)
		var u = (angle + PI) / (2.0 * PI)
		var v = (local_point.y + half_height) / height
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))

func calculate_sphere_uv(_sphere_mesh: SphereMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for SphereMesh"""
	var normalized = local_point.normalized()
	var u = 0.5 + atan2(normalized.z, normalized.x) / (2.0 * PI)
	var v = 0.5 - asin(normalized.y) / PI
	return Vector2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0))

func calculate_arraymesh_uv(array_mesh: ArrayMesh, local_point: Vector3) -> Vector2:
	"""Calculate UV for ArrayMesh by finding closest triangle"""

	if array_mesh.get_surface_count() == 0:
		print("ArrayMesh has no surfaces")
		return Vector2(0.5, 0.5)

	var arrays = array_mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		print("ArrayMesh has no vertex data")
		return Vector2(0.5, 0.5)

	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var uvs = null
	if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV]:
		uvs = arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array

	if not uvs or uvs.is_empty():
		print("ArrayMesh has no UV data, using fallback")
		# Fallback: create basic UV from position
		var bounds = _calculate_mesh_bounds(vertices)
		var u = (local_point.x - bounds[0].x) / (bounds[1].x - bounds[0].x)
		var v = (local_point.z - bounds[0].z) / (bounds[1].z - bounds[0].z)
		return Vector2(clamp(u, 0.0, 1.0), clamp(1.0 - v, 0.0, 1.0))

	# Find closest vertex and use its UV
	var closest_idx = 0
	var min_dist_sq = INF

	for i in range(vertices.size()):
		var dist_sq = local_point.distance_squared_to(vertices[i])
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_idx = i

	print("Closest vertex index: ", closest_idx, " UV: ", uvs[closest_idx])
	return uvs[closest_idx]

func _calculate_mesh_bounds(vertices: PackedVector3Array) -> Array:
	"""Calculate bounding box of mesh vertices"""
	if vertices.is_empty():
		return [Vector3.ZERO, Vector3.ONE]

	var min_pos = vertices[0]
	var max_pos = vertices[0]

	for v in vertices:
		min_pos.x = min(min_pos.x, v.x)
		min_pos.y = min(min_pos.y, v.y)
		min_pos.z = min(min_pos.z, v.z)
		max_pos.x = max(max_pos.x, v.x)
		max_pos.y = max(max_pos.y, v.y)
		max_pos.z = max(max_pos.z, v.z)

	return [min_pos, max_pos]

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
	
	# Check cache first
	var cache_key = texture.get_instance_id()
	if texture_image_cache.has(cache_key):
		image = texture_image_cache[cache_key]
	else:
		# Get image from texture and cache it
		if texture is ImageTexture:
			image = (texture as ImageTexture).get_image()
		elif texture.has_method("get_image"):
			image = texture.get_image()
			
		if image:
			texture_image_cache[cache_key] = image
	
	if not image:
		if texture_debug: print("Could not get image from texture")
		return Color.BLACK
	
	# Ensure image was properly loaded/cached
	if image.is_empty():
		return Color.BLACK
		
	var texture_size = image.get_size()
	# if texture_debug: print("Texture size: ", texture_size)
	
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
		# if texture_debug: print("Sampled pixel color: ", pixel_color)
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

func update_display_hit(_hit_object: Node, distance: float):
	"""Update display for hits"""
	
	if not color_data_label:
		return
	
	var r = int(detected_color.r * 255)
	var g = int(detected_color.g * 255)
	var b = int(detected_color.b * 255)
	
	# Simplified display: Only RGB values per user request
	var info_text = "%d, %d, %d" % [r, g, b]
	
	color_data_label.text = info_text
	
	var display_color = detected_color
	if display_color.get_luminance() < 0.3:
		display_color = display_color.lightened(0.5)
	color_data_label.modulate = display_color

func update_display_miss():
	"""Update display for misses"""
	
	if not color_data_label:
		return
	
	# Simplified display for miss state
	color_data_label.text = "---" 
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
