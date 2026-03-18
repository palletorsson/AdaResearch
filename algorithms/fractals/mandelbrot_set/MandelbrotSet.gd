# Mandelbrot Set Visualization - MultiMesh Optimized
# VR-optimized with GPU instancing for high performance

extends Node3D

# Fractal parameters
@export var resolution := 100
@export var max_iterations := 100
@export var zoom := 1.0
@export var center := Vector2(-0.5, 0.0)
@export var point_size := 0.08
@export var height_scale := 2.0
@export var use_3d_height := true

var time := 0.0

# MultiMesh for GPU instancing
var fractal_multimesh_instance: MultiMeshInstance3D
var fractal_multimesh: MultiMesh
var point_mesh: BoxMesh

# Material
var fractal_material: StandardMaterial3D

# Generation state for incremental updates
var is_generating := false
var generation_progress := 0.0

func _ready() -> void:
	_setup_mesh()
	_setup_material()
	_setup_multimesh()
	_generate_fractal()

func _setup_mesh() -> void:
	# Small cube for each point
	point_mesh = BoxMesh.new()
	point_mesh.size = Vector3(point_size, point_size, point_size)

func _setup_material() -> void:
	fractal_material = StandardMaterial3D.new()
	fractal_material.vertex_color_use_as_albedo = true
	fractal_material.emission_enabled = true
	fractal_material.emission_energy_multiplier = 0.4

func _setup_multimesh() -> void:
	fractal_multimesh = MultiMesh.new()
	fractal_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	fractal_multimesh.use_colors = true
	fractal_multimesh.mesh = point_mesh

	fractal_multimesh_instance = MultiMeshInstance3D.new()
	fractal_multimesh_instance.name = "MandelbrotMultiMesh"
	fractal_multimesh_instance.multimesh = fractal_multimesh
	fractal_multimesh_instance.material_override = fractal_material
	add_child(fractal_multimesh_instance)

func _process(delta: float) -> void:
	time += delta
	_animate_fractal()

func _generate_fractal() -> void:
	# Pre-calculate all points
	var point_data: Array[Dictionary] = []
	var scale_factor = 4.0 / zoom / resolution

	for y in range(resolution):
		for x in range(resolution):
			var real = center.x + (float(x) - resolution / 2.0) * scale_factor
			var imag = center.y + (float(y) - resolution / 2.0) * scale_factor

			var iterations = _mandelbrot_iterations(real, imag)
			var normalized_iter = float(iterations) / max_iterations

			# Calculate position
			var pos_x = (float(x) - resolution / 2.0) * point_size * 1.2
			var pos_z = (float(y) - resolution / 2.0) * point_size * 1.2
			var pos_y = 0.0

			if use_3d_height and iterations < max_iterations:
				# Use iteration count for height - creates a 3D landscape
				pos_y = normalized_iter * height_scale

			# Calculate color
			var point_color: Color
			if iterations >= max_iterations:
				point_color = Color.BLACK
			else:
				# Smooth coloring using continuous potential
				var hue = fmod(normalized_iter * 5.0, 1.0)
				point_color = Color.from_hsv(hue, 0.85, 1.0)

			point_data.append({
				"position": Vector3(pos_x, pos_y, pos_z),
				"color": point_color,
				"iterations": iterations
			})

	# Update MultiMesh in one batch
	var instance_count = point_data.size()
	fractal_multimesh.instance_count = instance_count

	for idx in range(instance_count):
		var data = point_data[idx]
		var transform = Transform3D(Basis(), data.position)
		fractal_multimesh.set_instance_transform(idx, transform)
		fractal_multimesh.set_instance_color(idx, data.color)

	print("Mandelbrot: Generated %d points" % instance_count)

func _mandelbrot_iterations(c_real: float, c_imag: float) -> int:
	var z_real := 0.0
	var z_imag := 0.0
	var iteration := 0

	while iteration < max_iterations:
		var z_real_sq = z_real * z_real
		var z_imag_sq = z_imag * z_imag

		if z_real_sq + z_imag_sq > 4.0:
			break

		var new_real = z_real_sq - z_imag_sq + c_real
		var new_imag = 2.0 * z_real * z_imag + c_imag
		z_real = new_real
		z_imag = new_imag
		iteration += 1

	return iteration

func _animate_fractal() -> void:
	if not fractal_multimesh_instance:
		return

	# Gentle pulsing animation
	var pulse = 1.0 + sin(time * 2.0) * 0.05
	fractal_multimesh_instance.scale = Vector3.ONE * pulse

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Generate new view
		zoom = 1.0 + randf() * 500.0
		center = Vector2(randf() * 2.0 - 1.5, randf() * 2.0 - 1.0)
		_generate_fractal()
		print("Mandelbrot: New zoom=%.1f center=(%.3f, %.3f)" % [zoom, center.x, center.y])

# Public API
func set_zoom_level(new_zoom: float) -> void:
	zoom = new_zoom
	_generate_fractal()

func set_center_point(new_center: Vector2) -> void:
	center = new_center
	_generate_fractal()

func set_resolution_level(new_resolution: int) -> void:
	resolution = new_resolution
	_generate_fractal()

func zoom_to_point(point: Vector2, new_zoom: float) -> void:
	center = point
	zoom = new_zoom
	_generate_fractal()

# Interesting locations to explore
func goto_seahorse_valley() -> void:
	center = Vector2(-0.75, 0.1)
	zoom = 50.0
	_generate_fractal()

func goto_elephant_valley() -> void:
	center = Vector2(0.275, 0.0)
	zoom = 30.0
	_generate_fractal()

func goto_spiral() -> void:
	center = Vector2(-0.761574, -0.0847596)
	zoom = 200.0
	_generate_fractal()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
