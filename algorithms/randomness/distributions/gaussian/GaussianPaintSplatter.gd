# @identity
# essence: gaussian sampling as paint — dots fall in a normal distribution around a safe zone
# desire: see how often a sample lands far from center vs near center, mediated by stddev
# critical_parameter: stddev — the standard deviation that controls splatter spread vs concentration
# triggers: timer ticks every splatter_update_interval; each tick samples (x,y) from gaussian and stamps a translucent dot
# emerges: a painting that IS the gaussian PDF — densest at center, sparser at the tails, with edge detection tracing the boundary
# needs: stddev slider [missing]; safe zone radius dial [missing]; clear-canvas button [missing]
# relationships: kin to GaussianBlurCircle (gaussian as smear); contrast to BlueNoise (rejection-based) and probability_distributions_3d (3D variant)
# truth: A bell curve drawn in the air, made visible by the dots that miss. Density is the proof of distribution.

extends MeshInstance3D
class_name GaussianPaintSplatter

# Export variables for customization
@export var splatter_width: int = 640
@export var splatter_height: int = 640
@export var stddev: float = 80.0  # Standard deviation for splatter distribution
@export var splatter_update_interval: float = 0.05  # Timer interval for updating splatter
@export var safe_zone_radius: float = 80.0  # Radius of the safe zone where no splatter will occur
@export var dot_radius: int = 5  # Radius of splatter dots
@export var dot_alpha: float = 0.6  # Alpha (transparency) value for the dots
@export var edge_toggle: bool = true  # Toggle for showing/hiding the edge outline
@export var edge_detection_frequency: int = 50  # Detect edges every N splatter updates
@export var show_visual_frame: bool = true
@export var frame_margin: float = 0.2
@export var frame_border_thickness: float = 0.08
@export var frame_depth: float = 0.03
@export var frame_back_offset: float = 0.02
@export var frame_back_color: Color = Color(0.08, 0.1, 0.14, 0.9)
@export var frame_border_color: Color = Color(0.72, 0.78, 0.9, 1.0)
@export var color_palette: Array[Color] = [
	Color(1.0, 0.4, 0.4, 0.6),  # Red
	Color(0.4, 1.0, 0.4, 0.6),  # Green
	Color(0.4, 0.4, 1.0, 0.6),  # Blue
	Color(1.0, 1.0, 0.4, 0.6),  # Yellow
	Color(1.0, 0.4, 1.0, 0.6),  # Magenta
]

# Internal variables
var img: Image
var texture: ImageTexture
var edge_points: Array = []
var splatter_count: int = 0
var timer: Timer

# Outline mesh
var outline_mesh: ImmediateMesh
var outline_mesh_instance: MeshInstance3D
var visual_frame_root: Node3D

func _ready() -> void:
	randomize()
	_setup_visual_frame()
	_initialize_texture()
	_setup_timer()
	_setup_outline_mesh()
	print("GaussianPaintSplatter: Initialized with safe zone radius %.0f" % safe_zone_radius)

# Initialize the image and texture
func _initialize_texture() -> void:
	img = Image.create(splatter_width, splatter_height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.new()

	# Fill background with white
	img.fill(Color.WHITE)

	texture = ImageTexture.create_from_image(img)
	_update_material(texture)

# Set up the timer for continuous splatter
func _setup_timer() -> void:
	timer = Timer.new()
	timer.wait_time = splatter_update_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

# Set up the outline mesh
func _setup_outline_mesh() -> void:
	outline_mesh = ImmediateMesh.new()
	outline_mesh_instance = MeshInstance3D.new()
	outline_mesh_instance.mesh = outline_mesh

	# Create material for outline
	var outline_material = StandardMaterial3D.new()
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.albedo_color = Color.BLACK
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_mesh_instance.material_override = outline_material

	add_child(outline_mesh_instance)
	outline_mesh_instance.visible = edge_toggle

# Timer callback
func _on_timer_timeout() -> void:
	_add_gaussian_splatter()
	texture.update(img)

	splatter_count += 1

	# Periodically detect edges
	if splatter_count % edge_detection_frequency == 0:
		_detect_edges()
		_create_outline_mesh()
		print("GaussianPaintSplatter: Edge detection at splatter count %d" % splatter_count)

# Add a splatter dot using Gaussian distribution
func _add_gaussian_splatter() -> void:
	var x := _random_gaussian(splatter_width / 2.0, stddev)
	var y := _random_gaussian(splatter_height / 2.0, stddev)

	# Calculate distance from center
	var center := Vector2(splatter_width / 2.0, splatter_height / 2.0)
	var splatter_pos := Vector2(x, y)
	var dist_from_center := center.distance_to(splatter_pos)

	# Skip if within safe zone
	if dist_from_center < safe_zone_radius:
		return

	# Pick a random color from palette
	var color := color_palette[randi() % color_palette.size()]

	# Draw circular splatter
	_draw_circle(int(x), int(y), dot_radius, color)

# Draw a circular splatter on the image
func _draw_circle(center_x: int, center_y: int, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			# Check if point is inside circle
			if dx * dx + dy * dy <= radius * radius:
				var px = clamp(center_x + dx, 0, splatter_width - 1)
				var py = clamp(center_y + dy, 0, splatter_height - 1)

				# Blend with existing pixel
				var current_color := img.get_pixel(px, py)
				var blended := current_color.blend(color)
				img.set_pixel(px, py, blended)

# Detect edges using radial sampling
func _detect_edges() -> void:
	edge_points.clear()

	var center := Vector2(splatter_width / 2.0, splatter_height / 2.0)
	var num_directions := 360  # Number of radial directions
	var max_distance := splatter_width / 2
	var color_threshold := 0.9  # Threshold to detect non-white pixels

	for angle in range(num_directions):
		var radian_angle := deg_to_rad(float(angle))
		var direction := Vector2(cos(radian_angle), sin(radian_angle))

		var found_edge := false
		for distance in range(int(safe_zone_radius), max_distance):
			var point := center + direction * distance

			# Check bounds
			if point.x < 0 or point.x >= splatter_width or point.y < 0 or point.y >= splatter_height:
				break

			# Check if pixel is colored (not white)
			var pixel_color := img.get_pixel(int(point.x), int(point.y))
			if pixel_color.r < color_threshold or pixel_color.g < color_threshold or pixel_color.b < color_threshold:
				# Found edge - store normalized coordinates
				edge_points.append(point)
				found_edge = true
				break

# Create outline mesh from detected edge points
func _create_outline_mesh() -> void:
	if edge_points.is_empty():
		return

	outline_mesh.clear_surfaces()
	outline_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Scale factor to convert image coordinates to 3D coordinates
	var scale_factor := 2.0 / float(splatter_width)
	var offset := Vector2(splatter_width / 2.0, splatter_height / 2.0)

	for point in edge_points:
		# Convert from image space to 3D space
		var normalized = (point - offset) * scale_factor
		outline_mesh.surface_add_vertex(Vector3(normalized.x, 0, normalized.y))

	# Close the loop
	if edge_points.size() > 0:
		var first_point = edge_points[0]
		var normalized = (first_point - offset) * scale_factor
		outline_mesh.surface_add_vertex(Vector3(normalized.x, 0, normalized.y))

	outline_mesh.surface_end()
	outline_mesh_instance.visible = edge_toggle

# Generate Gaussian random number using Box-Muller transform
func _random_gaussian(mean: float, stddev: float) -> float:
	var u1 := randf()
	var u2 := randf()

	# Prevent log(0)
	if u1 < 0.0001:
		u1 = 0.0001

	var z0 := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + stddev * z0

# Update material with texture
func _update_material(tex: ImageTexture) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = tex
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material_override = material

# Public API
func reset() -> void:
	"""Reset the splatter"""
	img.fill(Color.WHITE)
	texture.update(img)
	edge_points.clear()
	splatter_count = 0
	_create_outline_mesh()
	print("GaussianPaintSplatter: Reset")

func pause() -> void:
	"""Pause splatter generation"""
	timer.paused = true

func resume() -> void:
	"""Resume splatter generation"""
	timer.paused = false

func set_safe_zone_radius(radius: float) -> void:
	"""Change the safe zone radius"""
	safe_zone_radius = radius
	print("GaussianPaintSplatter: Safe zone radius set to %.0f" % radius)

func set_standard_deviation(new_stddev: float) -> void:
	"""Change the standard deviation"""
	stddev = new_stddev
	print("GaussianPaintSplatter: Standard deviation set to %.1f" % stddev)

func toggle_edge_outline() -> void:
	"""Toggle edge outline visibility"""
	edge_toggle = !edge_toggle
	outline_mesh_instance.visible = edge_toggle

func _setup_visual_frame() -> void:
	if not show_visual_frame or mesh == null:
		return

	var aabb := mesh.get_aabb()
	var size := aabb.size
	if size.length_squared() <= 0.0:
		return

	var normal_axis := _smallest_axis_index(size)
	var axis_u := (normal_axis + 1) % 3
	var axis_v := (normal_axis + 2) % 3
	var size_u := _component_by_axis(size, axis_u)
	var size_v := _component_by_axis(size, axis_v)

	if size_u <= 0.0 or size_v <= 0.0:
		return

	var center := aabb.position + size * 0.5
	var normal_dir := _axis_vector(normal_axis)
	var u_dir := _axis_vector(axis_u)
	var v_dir := _axis_vector(axis_v)

	var frame_u := size_u + frame_margin * 2.0
	var frame_v := size_v + frame_margin * 2.0
	var back_center := center - normal_dir * frame_back_offset

	visual_frame_root = Node3D.new()
	visual_frame_root.name = "VisualFrame"
	add_child(visual_frame_root)

	var back_material := _create_frame_material(frame_back_color, false)
	var border_material := _create_frame_material(frame_border_color, true)

	# Backplate behind the visual
	_add_frame_piece(back_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_u, frame_v), back_material)

	# Border ring around the visual
	var half_u := frame_u * 0.5
	var half_v := frame_v * 0.5
	var half_t := frame_border_thickness * 0.5

	var top_center := back_center + v_dir * (half_v - half_t)
	var bottom_center := back_center - v_dir * (half_v - half_t)
	var left_center := back_center - u_dir * (half_u - half_t)
	var right_center := back_center + u_dir * (half_u - half_t)

	_add_frame_piece(top_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_u, frame_border_thickness), border_material)
	_add_frame_piece(bottom_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_u, frame_border_thickness), border_material)
	_add_frame_piece(left_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_border_thickness, frame_v), border_material)
	_add_frame_piece(right_center, _size_from_axes(normal_axis, axis_u, axis_v, frame_depth, frame_border_thickness, frame_v), border_material)

func _create_frame_material(color: Color, emissive: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.2
	return mat

func _add_frame_piece(center: Vector3, size_vec: Vector3, material: Material) -> void:
	var piece := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	piece.mesh = box
	piece.material_override = material
	piece.position = center
	piece.scale = size_vec
	visual_frame_root.add_child(piece)

func _smallest_axis_index(v: Vector3) -> int:
	if v.x <= v.y and v.x <= v.z:
		return 0
	if v.y <= v.x and v.y <= v.z:
		return 1
	return 2

func _component_by_axis(v: Vector3, axis: int) -> float:
	if axis == 0:
		return v.x
	if axis == 1:
		return v.y
	return v.z

func _axis_vector(axis: int) -> Vector3:
	if axis == 0:
		return Vector3.RIGHT
	if axis == 1:
		return Vector3.UP
	return Vector3.BACK

func _size_from_axes(normal_axis: int, axis_u: int, axis_v: int, depth: float, size_u: float, size_v: float) -> Vector3:
	var out := Vector3.ZERO
	out = out + _axis_vector(normal_axis) * depth
	out = out + _axis_vector(axis_u) * size_u
	out = out + _axis_vector(axis_v) * size_v
	return Vector3(absf(out.x), absf(out.y), absf(out.z))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
