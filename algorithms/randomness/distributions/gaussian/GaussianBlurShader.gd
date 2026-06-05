# @identity
# essence: GPU-accelerated gaussian blur — same dissolution, real-time, larger kernel possible
# desire: see the same hard-to-soft transition that GaussianBlurCircle shows, but at frame rate
# critical_parameter: max_blur_radius — controlled to 40 here vs 8 on CPU; GPU permits a wider kernel without lag
# triggers: shader_material runs the blur each frame using the animated current_blur_radius parameter
# emerges: a 512x512 image that blurs in real time, demonstrating the cost-of-precision tradeoff between CPU and GPU
# needs: GPU/CPU toggle [missing]; live kernel size slider [missing]; quality dial [missing]
# relationships: GPU twin of GaussianBlurCircle; both share the time-as-blur premise but differ in where the work happens
# truth: The kernel is the same; only the substrate is faster. Hardware decides what randomness can afford.

extends MeshInstance3D
class_name GaussianBlurShader

# Animation control
@export var blur_duration: float = 10.0  # Duration to go from sharp to fully blurred
@export var max_blur_radius: float = 40.0  # Maximum blur kernel radius
@export var auto_start: bool = true
@export var show_visual_frame: bool = true
@export var frame_margin: float = 0.16
@export var frame_border_thickness: float = 0.06
@export var frame_depth: float = 0.02
@export var frame_back_offset: float = 0.02
@export var frame_back_color: Color = Color(0.08, 0.1, 0.14, 0.9)
@export var frame_border_color: Color = Color(0.72, 0.78, 0.9, 1.0)

var blur_time: float = 0.0
var current_blur_radius: float = 0.0
var active: bool = false
var shader_material: ShaderMaterial
var visual_frame_root: Node3D

func _ready() -> void:
	_setup_visual_frame()
	_setup_shader_material()

	if auto_start:
		start()

	print("GaussianBlurShader: Initialized (GPU-accelerated)")

func _setup_shader_material() -> void:
	"""Setup the shader material"""
	# Create the circle texture
	var img = Image.create(512, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)

	# Draw black circle in center
	var center = Vector2(256, 256)
	var radius = 150

	for y in range(512):
		for x in range(512):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= radius:
				img.set_pixel(x, y, Color.BLACK)

	var circle_texture = ImageTexture.create_from_image(img)

	# Load the spatial shader
	var shader = load("res://algorithms/randomness/distributions/gaussian/gaussian_blur_shader_3d.gdshader")

	# Create shader material
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	# Set shader parameters
	shader_material.set_shader_parameter("blur_amount", 0.0)
	shader_material.set_shader_parameter("circle_texture", circle_texture)

	# Apply to mesh
	material_override = shader_material

func _process(delta: float) -> void:
	if not active or not shader_material:
		return

	if blur_time < blur_duration:
		blur_time += delta
		var progress = min(blur_time / blur_duration, 1.0)

		# Calculate current blur radius with easing (exponential ease-in for more intensity)
		current_blur_radius = ease(progress, -2.0) * max_blur_radius

		# Update shader parameter
		shader_material.set_shader_parameter("blur_amount", current_blur_radius)

		# Debug output every 0.5 seconds
		if int(blur_time * 2) != int((blur_time - delta) * 2):
			print("GaussianBlurShader: Blur progress: %.1f%%, radius: %.2f" % [progress * 100, current_blur_radius])
	else:
		active = false
		print("GaussianBlurShader: Animation complete")

# Public API
func start() -> void:
	"""Start the blur animation"""
	active = true
	blur_time = 0.0
	current_blur_radius = 0.0
	if shader_material:
		shader_material.set_shader_parameter("blur_amount", 0.0)
	print("GaussianBlurShader: Started")

func reset() -> void:
	"""Reset to sharp circle"""
	blur_time = 0.0
	current_blur_radius = 0.0
	active = false
	if shader_material:
		shader_material.set_shader_parameter("blur_amount", 0.0)
	print("GaussianBlurShader: Reset to sharp circle")

func pause() -> void:
	"""Pause the blur animation"""
	active = false

func resume() -> void:
	"""Resume the blur animation"""
	active = true

func set_blur_amount(amount: float) -> void:
	"""Manually set blur amount"""
	current_blur_radius = clamp(amount, 0.0, max_blur_radius)
	if shader_material:
		shader_material.set_shader_parameter("blur_amount", current_blur_radius)

func set_blur_duration(duration: float) -> void:
	"""Set the duration of the blur animation"""
	blur_duration = duration

func set_max_blur_radius(radius: float) -> void:
	"""Set the maximum blur radius"""
	max_blur_radius = radius

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
