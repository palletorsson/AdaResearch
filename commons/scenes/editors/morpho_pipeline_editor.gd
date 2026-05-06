# morpho_pipeline_editor.gd — Full pipeline: skeleton -> surface -> modifiers -> instancing
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Morpho Pipeline"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Skeleton", "params": [
			{"id": "skeleton_type", "label": "Skeleton", "options": ["None", "Spine", "Spiral"], "default": 1.0},
			{"id": "spine_points", "label": "Points", "min": 2.0, "max": 12.0, "step": 1.0, "default": 4.0},
			{"id": "curvature", "label": "Curvature", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
			{"id": "length", "label": "Length", "min": 0.3, "max": 3.0, "step": 0.1, "default": 1.0},
		]},
		{"name": "Surface", "params": [
			{"id": "surface_type", "label": "Surface", "options": ["Sweep", "Revolution", "SDF", "Primitive"], "default": 0.0},
			{"id": "sides", "label": "Sides", "min": 4.0, "max": 16.0, "step": 1.0, "default": 8.0},
			{"id": "start_radius", "label": "Start Radius", "min": 0.02, "max": 0.5, "step": 0.01, "default": 0.1},
			{"id": "end_radius", "label": "End Radius", "min": 0.01, "max": 0.5, "step": 0.01, "default": 0.05},
		]},
		{"name": "Taper", "params": [
			{"id": "taper_amount", "label": "Amount", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
		]},
		{"name": "Twist", "params": [
			{"id": "twist_degrees", "label": "Degrees", "min": -360.0, "max": 360.0, "step": 5.0, "default": 0.0},
		]},
		{"name": "Noise", "params": [
			{"id": "noise_strength", "label": "Strength", "min": 0.0, "max": 0.3, "step": 0.01, "default": 0.0},
			{"id": "noise_frequency", "label": "Frequency", "min": 0.1, "max": 3.0, "step": 0.1, "default": 0.5},
		]},
		{"name": "Instance", "params": [
			{"id": "instance_count", "label": "Count", "min": 0.0, "max": 8.0, "step": 1.0, "default": 0.0},
			{"id": "symmetry", "label": "Symmetry", "min": 1.0, "max": 8.0, "step": 1.0, "default": 1.0},
		]},
		{"name": "Recursion", "params": [
			{"id": "recursion_depth", "label": "Depth", "min": 0.0, "max": 2.0, "step": 1.0, "default": 0.0},
			{"id": "child_scale", "label": "Child Scale", "min": 0.2, "max": 0.8, "step": 0.05, "default": 0.5},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var pipeline := MorphoPipeline.new()

	# Skeleton
	var skel_type: int = int(p("skeleton_type", 1))
	match skel_type:
		0: pipeline.skeleton_type = MorphoPipeline.SkeletonType.NONE
		1: pipeline.skeleton_type = MorphoPipeline.SkeletonType.SPINE
		2: pipeline.skeleton_type = MorphoPipeline.SkeletonType.SPIRAL

	pipeline.spine_points = int(p("spine_points", 4))
	pipeline.spine_curvature = p("curvature", 0.0)
	pipeline.spine_length = p("length", 1.0)

	# Surface
	var surf_type: int = int(p("surface_type", 0))
	match surf_type:
		0: pipeline.surface_type = MorphoPipeline.SurfaceType.SWEEP
		1: pipeline.surface_type = MorphoPipeline.SurfaceType.REVOLUTION
		2: pipeline.surface_type = MorphoPipeline.SurfaceType.SDF
		3: pipeline.surface_type = MorphoPipeline.SurfaceType.PRIMITIVE

	pipeline.sides = int(p("sides", 8))
	pipeline.start_radius = p("start_radius", 0.1)
	pipeline.end_radius = p("end_radius", 0.05)

	# Modifier stack
	pipeline.modifier_stack.clear()
	if absf(p("taper_amount")) > 0.01:
		pipeline.modifier_stack.append({
			"type": "taper",
			"params": {"amount": p("taper_amount")}
		})
	if absf(p("twist_degrees")) > 1.0:
		pipeline.modifier_stack.append({
			"type": "twist",
			"params": {"degrees": p("twist_degrees")}
		})
	if p("noise_strength") > 0.005:
		pipeline.modifier_stack.append({
			"type": "noise",
			"params": {
				"strength": p("noise_strength"),
				"frequency": p("noise_frequency", 0.5),
			}
		})

	# Instancing
	pipeline.instance_count = int(p("instance_count", 0))
	pipeline.instance_symmetry = int(p("symmetry", 1))

	# Recursion — add child pipeline if depth > 0
	pipeline.children.clear()
	var depth: int = int(p("recursion_depth", 0))
	if depth > 0:
		var child_s: float = p("child_scale", 0.5)
		var child := MorphoPipeline.new()
		child.skeleton_type = pipeline.skeleton_type
		child.surface_type = pipeline.surface_type
		child.spine_points = maxi(pipeline.spine_points - 1, 2)
		child.spine_length = pipeline.spine_length * child_s
		child.start_radius = pipeline.end_radius * 0.8
		child.end_radius = child.start_radius * 0.3
		child.sides = maxi(pipeline.sides - 2, 3)
		child.child_attachment = MorphoPipeline.Attachment.AT_TIPS
		child.child_per_parent = int(clampf(p("symmetry", 1), 1.0, 4.0))

		# Second level of recursion
		if depth > 1:
			var grandchild := MorphoPipeline.new()
			grandchild.skeleton_type = MorphoPipeline.SkeletonType.SPINE
			grandchild.surface_type = MorphoPipeline.SurfaceType.SWEEP
			grandchild.spine_points = 2
			grandchild.spine_length = child.spine_length * child_s
			grandchild.start_radius = child.end_radius * 0.6
			grandchild.end_radius = grandchild.start_radius * 0.3
			grandchild.sides = maxi(child.sides - 2, 3)
			child.children.append(grandchild)
			child.child_attachment = MorphoPipeline.Attachment.AT_TIPS

		pipeline.children.append(child)
		pipeline.child_attachment = MorphoPipeline.Attachment.AT_TIPS

	# Build
	pipeline.build(content_root, 2)

	# Apply a default material to all mesh instances
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.72, 0.78)
	mat.roughness = 0.35
	mat.metallic = 0.15
	_apply_material_recursive(content_root, mat)


func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child: Node in node.get_children():
		_apply_material_recursive(child, mat)
