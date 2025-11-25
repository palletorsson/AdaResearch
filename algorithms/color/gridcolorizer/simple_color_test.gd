# Simple MultiMesh color test
# This demonstrates that MultiMesh per-instance colors DO work

extends Node3D

func _ready():
	# Create MultiMeshInstance3D
	var mmi = MultiMeshInstance3D.new()
	add_child(mmi)

	# Create MultiMesh
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true  # CRITICAL: Enable per-instance colors
	mm.mesh = BoxMesh.new()

	# Create shader material (using SimpleGrid shader)
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("show_interior", true)
	material.set_shader_parameter("modelColor", Color.WHITE)
	material.set_shader_parameter("wireframeColor", Color.RED)
	mmi.material_override = material

	# Set up grid
	var grid_size = 5
	mm.instance_count = grid_size * grid_size

	# Position cubes and set colors
	var index = 0
	for x in range(grid_size):
		for z in range(grid_size):
			# Set transform
			var transform = Transform3D()
			transform.origin = Vector3(x * 1.2, 0, z * 1.2)
			mm.set_instance_transform(index, transform)

			# Set color - rainbow based on position
			var hue = float(x + z) / float(2 * grid_size)
			var color = Color.from_hsv(hue, 0.8, 1.0)
			mm.set_instance_color(index, color)

			index += 1

	mmi.multimesh = mm
	print("✅ Created %d cubes with per-instance colors" % mm.instance_count)
	print("   Colors WILL show if shader supports them (SimpleGrid.gdshader does!)")
