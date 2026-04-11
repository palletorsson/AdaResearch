# @identity
# essence: width(z) = max_width * (1 - exp(-z^2 / 2*spread^2)). A corridor shaped by the bell curve.
# desire: To walk through a probability distribution. The narrow center is the mean; the widening walls are the tails.
# critical_parameter: spread — controls how quickly the alley widens. Low spread = tight corridor. High spread = gradual opening.
# triggers: Automatic — builds on _ready(). Walk through it.
# emerges: The feeling of moving through statistics. The center is certain; the edges are improbable.
# needs: Procedural generation [has]. Missing: height variation, color gradient by probability.
# relationships: Physical embodiment of the normal distribution. Contrasts with distribution_visualization (abstract) — this is the same math made architectural.
# truth: A bell curve is a corridor. The mean is where you walk. The tails are where the walls go.

extends Node3D

@export var grid_x: int = 30
@export var grid_z: int = 60
@export var cube_spacing: float = 1.0
@export var spread: float = 4.0
@export var height_y: float = 0.0
@export var cube_scene: PackedScene = preload("res://commons/primitives/cubes/cube_scene.tscn")

func _ready() -> void:
	create_bellcurve_alley()
	_add_bell_curve_line()
	_add_label()

func create_bellcurve_alley() -> void:
	var mid_z := grid_z / 2.0

	for z in range(grid_z):
		var z_offset := float(z) - mid_z
		var width_factor := exp(-pow(z_offset, 2) / (2.0 * pow(spread, 2)))
		var max_half_width := int(grid_x / 2)
		var row_width := int(lerp(1, max_half_width, 1.0 - width_factor))

		for x in range(-row_width, row_width + 1):
			if abs(z - mid_z) < 2 and abs(x) > 0:
				continue
			if abs(x) > 0 and randf() > 0.8:
				continue

			var cube := cube_scene.instantiate()
			cube.position = Vector3(x * cube_spacing, height_y, z * cube_spacing)
			add_child(cube)

func _add_bell_curve_line() -> void:
	# Draw the bell curve itself as a glowing line along the right wall edge
	var imesh := ImmediateMesh.new()
	var instance := MeshInstance3D.new()
	instance.mesh = imesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2) * 0.6
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = mat

	var mid_z := grid_z / 2.0

	# Right edge curve
	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for z in range(grid_z):
		var z_offset := float(z) - mid_z
		var width_factor := exp(-pow(z_offset, 2) / (2.0 * pow(spread, 2)))
		var max_half_width := int(grid_x / 2)
		var row_width := int(lerp(1, max_half_width, 1.0 - width_factor))
		imesh.surface_add_vertex(Vector3(
			row_width * cube_spacing + 0.5,
			height_y + 1.5,
			z * cube_spacing
		))
	imesh.surface_end()

	# Left edge curve (mirror)
	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for z in range(grid_z):
		var z_offset := float(z) - mid_z
		var width_factor := exp(-pow(z_offset, 2) / (2.0 * pow(spread, 2)))
		var max_half_width := int(grid_x / 2)
		var row_width := int(lerp(1, max_half_width, 1.0 - width_factor))
		imesh.surface_add_vertex(Vector3(
			-row_width * cube_spacing - 0.5,
			height_y + 1.5,
			z * cube_spacing
		))
	imesh.surface_end()

	add_child(instance)

func _add_label() -> void:
	var label := Label3D.new()
	label.text = "Bell Curve Alley\nspread = %.1f" % spread
	label.font_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1, 0.8)
	label.position = Vector3(0, height_y + 4.0, grid_z * cube_spacing * 0.5)
	add_child(label)

func apply_grid_config(config: Dictionary) -> void:
	pass
