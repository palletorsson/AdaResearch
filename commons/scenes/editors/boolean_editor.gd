# boolean_editor.gd — CSG boolean operations
#
# Union, subtract, or intersect between two CSG shapes.
# Shapes: sphere, box, cylinder, torus. Position and rotate
# shape B relative to A.

extends BaseGeometryEditor

func _get_editor_name() -> String: return "Boolean CSG"

func _get_parameter_groups() -> Array:
	return [
		{"name": "Shapes", "params": [
			{"id": "shape_a", "label": "Shape A", "options": ["Sphere", "Box", "Cylinder", "Torus"], "default": 0.0},
			{"id": "shape_b", "label": "Shape B", "options": ["Sphere", "Box", "Cylinder", "Torus"], "default": 1.0},
			{"id": "operation", "label": "Operation", "options": ["Union", "Subtract", "Intersect"], "default": 1.0},
		]},
		{"name": "Size", "params": [
			{"id": "size_a", "label": "Size A", "min": 0.2, "max": 2.0, "step": 0.1, "default": 1.0},
			{"id": "size_b", "label": "Size B", "min": 0.2, "max": 2.0, "step": 0.1, "default": 0.7},
		]},
		{"name": "Position B", "params": [
			{"id": "offset_x", "label": "X", "min": -1.5, "max": 1.5, "step": 0.05, "default": 0.4},
			{"id": "offset_y", "label": "Y", "min": -1.5, "max": 1.5, "step": 0.05, "default": 0.0},
			{"id": "offset_z", "label": "Z", "min": -1.5, "max": 1.5, "step": 0.05, "default": 0.0},
			{"id": "rotation", "label": "Rotate", "min": 0.0, "max": 360.0, "step": 5.0, "default": 0.0},
		]},
	]

func _rebuild() -> void:
	_clear_content()
	_auto_rotate = false  # CSG nodes don't rotate well with auto-rotate on content_root

	var combiner := CSGCombiner3D.new()
	combiner.use_collision = false

	var ops: Array = [CSGShape3D.OPERATION_UNION, CSGShape3D.OPERATION_SUBTRACTION, CSGShape3D.OPERATION_INTERSECTION]

	# Shape A
	var sa: CSGShape3D = _make_csg_shape(int(p("shape_a", 0)), p("size_a", 1.0))
	sa.operation = CSGShape3D.OPERATION_UNION
	combiner.add_child(sa)

	# Shape B
	var sb: CSGShape3D = _make_csg_shape(int(p("shape_b", 1)), p("size_b", 0.7))
	sb.operation = ops[clampi(int(p("operation", 1)), 0, 2)]
	sb.position = Vector3(p("offset_x", 0.4), p("offset_y", 0.0), p("offset_z", 0.0))
	sb.rotation_degrees.y = p("rotation", 0.0)
	combiner.add_child(sb)

	content_root.add_child(combiner)

	var op_names: Array[String] = ["Union", "Subtract", "Intersect"]
	if info_label:
		info_label.text = "CSG %s | A=%s B=%s" % [op_names[clampi(int(p("operation", 1)), 0, 2)], _shape_name(int(p("shape_a", 0))), _shape_name(int(p("shape_b", 1)))]

func _make_csg_shape(type: int, size: float) -> CSGShape3D:
	match type:
		0:
			var s := CSGSphere3D.new()
			s.radius = size * 0.5
			s.radial_segments = 16
			s.rings = 8
			return s
		1:
			var s := CSGBox3D.new()
			s.size = Vector3.ONE * size
			return s
		2:
			var s := CSGCylinder3D.new()
			s.radius = size * 0.4
			s.height = size
			return s
		3:
			var s := CSGTorus3D.new()
			s.inner_radius = size * 0.15
			s.outer_radius = size * 0.4
			return s
	return CSGSphere3D.new()

func _shape_name(type: int) -> String:
	return ["Sphere", "Box", "Cylinder", "Torus"][clampi(type, 0, 3)]
