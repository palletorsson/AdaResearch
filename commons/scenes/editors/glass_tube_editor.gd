# glass_tube_editor.gd — Glass tube shape editor using GlassMeshGenerator
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Glass Tube"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Shape", "params": [
			{"id": "shape_type", "label": "Type (0=str 1=crn 2=sbn 3=spi 4=flk 5=bkr)", "min": 0.0, "max": 5.0, "step": 1.0, "default": 0.0},
			{"id": "tube_radius", "label": "Radius", "min": 0.01, "max": 0.1, "step": 0.005, "default": 0.015},
			{"id": "width", "label": "Width", "min": 0.2, "max": 2.0, "step": 0.05, "default": 0.5},
			{"id": "height", "label": "Height", "min": 0.2, "max": 2.0, "step": 0.05, "default": 0.8},
			{"id": "curve_segments", "label": "Curve Segments", "min": 8.0, "max": 48.0, "step": 4.0, "default": 24.0},
		]},
		{"name": "Material", "params": [
			{"id": "transparency", "label": "Transparency", "min": 0.0, "max": 0.9, "step": 0.05, "default": 0.6},
			{"id": "roughness", "label": "Roughness", "min": 0.0, "max": 0.5, "step": 0.02, "default": 0.05},
			{"id": "color_r", "label": "Tint R", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.85},
			{"id": "color_g", "label": "Tint G", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.92},
			{"id": "color_b", "label": "Tint B", "min": 0.0, "max": 1.0, "step": 0.05, "default": 1.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var shape: int = int(p("shape_type", 0))
	var radius: float = p("tube_radius", 0.015)
	var w: float = p("width", 0.5)
	var h: float = p("height", 0.8)

	# Map shape type to GlassMeshGenerator segment type
	var segment_type: String
	match shape:
		0: segment_type = "straight"
		1: segment_type = "corner"
		2: segment_type = "sbend"
		3: segment_type = "spiral"
		4: segment_type = "flask"
		5: segment_type = "beaker"

	# Build glass material
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(
		p("color_r", 0.85),
		p("color_g", 0.92),
		p("color_b", 1.0),
		1.0 - p("transparency", 0.6)
	)
	mat.roughness = p("roughness", 0.05)
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Use GlassMeshGenerator.create_segment which returns a Node3D
	var node: Node3D = GlassMeshGenerator.create_segment(
		segment_type, w, h, radius, mat)

	if node:
		# Center the geometry so it orbits nicely
		node.position = Vector3(0, -h * 0.5, -w * 0.5)
		content_root.add_child(node)
