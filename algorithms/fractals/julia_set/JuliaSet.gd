extends Node3D

# Julia Set Visualization - MultiMesh Optimized
# Parameter-space fractal variants of the Mandelbrot set

# Julia set parameters
@export var c_real := -0.7
@export var c_imag := 0.27015
@export var max_iterations := 50
@export var escape_radius := 2.0
@export var zoom_level := 1.0
@export var grid_resolution := 50
@export var animate_parameters := true
@export var point_size := 0.08

var time := 0.0

# MultiMesh instances for GPU instancing
var julia_multimesh_instance: MultiMeshInstance3D
var julia_multimesh: MultiMesh
var param_multimesh_instance: MultiMeshInstance3D
var param_multimesh: MultiMesh

# Shared mesh for instances
var cube_mesh: BoxMesh
var sphere_mesh: SphereMesh

# Materials
var set_material: StandardMaterial3D
var escape_material: StandardMaterial3D
var param_material: StandardMaterial3D

# Cache for iteration data
var iteration_cache: PackedInt32Array
var needs_regeneration := true
var last_c_real := 0.0
var last_c_imag := 0.0
var last_zoom := 0.0

func _ready():
	_setup_meshes()
	_setup_materials()
	_setup_multimesh_instances()
	_generate_julia_set()

func _setup_meshes():
	# Small cube for Julia set points
	cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(point_size, point_size, point_size)

	# Sphere for parameter space
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3

func _setup_materials():
	# Material for points in the set (black)
	set_material = StandardMaterial3D.new()
	set_material.albedo_color = Color(0.0, 0.0, 0.0)

	# Material for escaped points (will use instance colors)
	escape_material = StandardMaterial3D.new()
	escape_material.vertex_color_use_as_albedo = true
	escape_material.emission_enabled = true
	escape_material.emission_energy_multiplier = 0.3

	# Material for parameter indicator
	param_material = StandardMaterial3D.new()
	param_material.albedo_color = Color(1.0, 0.0, 0.0)
	param_material.emission_enabled = true
	param_material.emission = Color(1.0, 0.0, 0.0)
	param_material.emission_energy_multiplier = 0.8

func _setup_multimesh_instances():
	# Julia set visualization
	julia_multimesh = MultiMesh.new()
	julia_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	julia_multimesh.use_colors = true
	julia_multimesh.mesh = cube_mesh

	julia_multimesh_instance = MultiMeshInstance3D.new()
	julia_multimesh_instance.name = "JuliaMultiMesh"
	julia_multimesh_instance.multimesh = julia_multimesh
	julia_multimesh_instance.material_override = escape_material

	if has_node("JuliaVisualization"):
		$JuliaVisualization.add_child(julia_multimesh_instance)
	else:
		add_child(julia_multimesh_instance)

	# Parameter space visualization
	param_multimesh = MultiMesh.new()
	param_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	param_multimesh.use_colors = true
	param_multimesh.mesh = sphere_mesh

	param_multimesh_instance = MultiMeshInstance3D.new()
	param_multimesh_instance.name = "ParameterMultiMesh"
	param_multimesh_instance.multimesh = param_multimesh

	if has_node("ParameterSpace"):
		$ParameterSpace.add_child(param_multimesh_instance)
	else:
		add_child(param_multimesh_instance)

func _process(delta):
	time += delta

	if animate_parameters:
		# Animate Julia set parameter
		c_real = -0.7 + sin(time * 0.3) * 0.3
		c_imag = 0.27015 + cos(time * 0.5) * 0.2
		zoom_level = 1.0 + sin(time * 0.2) * 0.5

	# Only regenerate if parameters changed significantly
	if _parameters_changed():
		_generate_julia_set()
		last_c_real = c_real
		last_c_imag = c_imag
		last_zoom = zoom_level

	_update_parameter_space()

func _parameters_changed() -> bool:
	return abs(c_real - last_c_real) > 0.001 or \
		   abs(c_imag - last_c_imag) > 0.001 or \
		   abs(zoom_level - last_zoom) > 0.01

func _generate_julia_set():
	var bounds = 3.0 / zoom_level
	var point_data: Array[Dictionary] = []

	# Calculate all points
	for i in range(grid_resolution):
		for j in range(grid_resolution):
			var x = (float(i) / grid_resolution - 0.5) * 2 * bounds
			var y = (float(j) / grid_resolution - 0.5) * 2 * bounds

			var iterations = _julia_iterations(x, y, c_real, c_imag)
			var is_in_set = iterations >= max_iterations

			if is_in_set or iterations > 5:
				var color: Color
				if is_in_set:
					color = Color(0.0, 0.0, 0.0)
				else:
					var color_ratio = float(iterations) / max_iterations
					color = Color.from_hsv(color_ratio * 0.8, 0.8, 1.0)

				point_data.append({
					"position": Vector3(x * 2, 0, y * 2),
					"color": color
				})

	# Update MultiMesh
	var instance_count = point_data.size()
	julia_multimesh.instance_count = instance_count

	for idx in range(instance_count):
		var data = point_data[idx]
		var transform = Transform3D(Basis(), data.position)
		julia_multimesh.set_instance_transform(idx, transform)
		julia_multimesh.set_instance_color(idx, data.color)

func _julia_iterations(x: float, y: float, c_r: float, c_i: float) -> int:
	var z_real = x
	var z_imag = y
	var iteration = 0
	var escape_sq = escape_radius * escape_radius

	while iteration < max_iterations:
		var z_real_sq = z_real * z_real
		var z_imag_sq = z_imag * z_imag

		if z_real_sq + z_imag_sq > escape_sq:
			break

		var new_real = z_real_sq - z_imag_sq + c_r
		var new_imag = 2 * z_real * z_imag + c_i

		z_real = new_real
		z_imag = new_imag
		iteration += 1

	return iteration

func _update_parameter_space():
	# Current parameter point + trajectory
	var trajectory_points = 20
	param_multimesh.instance_count = trajectory_points + 1

	# Current position (larger sphere)
	var main_transform = Transform3D(Basis().scaled(Vector3(1.5, 1.5, 1.5)), Vector3(c_real * 3, 0, c_imag * 3))
	param_multimesh.set_instance_transform(0, main_transform)
	param_multimesh.set_instance_color(0, Color(1.0, 0.0, 0.0))

	# Trail points
	for i in range(trajectory_points):
		var t = time - float(i) * 0.1
		var trail_c_real = -0.7 + sin(t * 0.3) * 0.3
		var trail_c_imag = 0.27015 + cos(t * 0.5) * 0.2

		var scale_factor = 0.3 * (1.0 - float(i) / trajectory_points)
		var trail_transform = Transform3D(
			Basis().scaled(Vector3(scale_factor, scale_factor, scale_factor)),
			Vector3(trail_c_real * 3, 0, trail_c_imag * 3)
		)
		param_multimesh.set_instance_transform(i + 1, trail_transform)

		var alpha = 1.0 - float(i) / trajectory_points
		param_multimesh.set_instance_color(i + 1, Color(1.0, 0.5, 0.0, alpha))

# Public API for external control
func set_julia_parameters(real: float, imag: float):
	c_real = real
	c_imag = imag
	animate_parameters = false

func set_zoom(new_zoom: float):
	zoom_level = new_zoom

func set_resolution(new_resolution: int):
	grid_resolution = new_resolution
	_generate_julia_set()
