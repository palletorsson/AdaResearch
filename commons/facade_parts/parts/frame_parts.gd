class_name FrameParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade frame parts — concentric rectangular molding rings around panels.
## Analogous to the mosaic floor border_motifs ring-stack system.
## Cell origin (0,0,0) = bottom-left-front of the cell.


# ==========================================================================
# Internal helpers
# ==========================================================================

static func _box(bname: String, size: Vector3, pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = bname
	b.size = size
	b.position = pos
	b.operation = op
	b.use_collision = false
	if mat: b.material = mat
	return b


static func _polygon(pname: String, profile: PackedVector2Array, depth: float,
		pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGPolygon3D:
	var p := CSGPolygon3D.new()
	p.name = pname
	p.polygon = profile
	p.depth = depth
	p.mode = CSGPolygon3D.MODE_DEPTH
	p.position = pos
	p.operation = op
	p.use_collision = false
	if mat: p.material = mat
	return p


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


static func _get_marble_material(material_name: String, color: Color = Color.WHITE) -> Material:
	## Load the marble shader and configure for the given stone type.
	var shader := load("res://commons/facade_parts/marble_surface.gdshader") as Shader
	if not shader:
		return _M.stone(color)

	var mat := ShaderMaterial.new()
	mat.shader = shader

	match material_name:
		"siena":
			mat.set_shader_parameter("base_color", Color(0.85, 0.72, 0.45))
			mat.set_shader_parameter("vein_color", Color(0.95, 0.82, 0.55))
			mat.set_shader_parameter("vein_style", 1)  # swirled
			mat.set_shader_parameter("vein_intensity", 0.7)
			mat.set_shader_parameter("vein_scale", 4.0)
		"carrara":
			mat.set_shader_parameter("base_color", Color(0.94, 0.93, 0.90))
			mat.set_shader_parameter("vein_color", Color(0.70, 0.68, 0.65))
			mat.set_shader_parameter("vein_style", 0)  # veined
			mat.set_shader_parameter("vein_intensity", 0.4)
			mat.set_shader_parameter("vein_scale", 8.0)
		"dark_stone":
			mat.set_shader_parameter("base_color", Color(0.25, 0.24, 0.22))
			mat.set_shader_parameter("vein_color", Color(0.18, 0.17, 0.16))
			mat.set_shader_parameter("vein_style", 2)  # breccia
			mat.set_shader_parameter("vein_intensity", 0.3)
			mat.set_shader_parameter("vein_scale", 6.0)
		"grey_stone":
			mat.set_shader_parameter("base_color", Color(0.60, 0.58, 0.55))
			mat.set_shader_parameter("vein_color", Color(0.50, 0.48, 0.45))
			mat.set_shader_parameter("vein_style", 0)
			mat.set_shader_parameter("vein_intensity", 0.25)
			mat.set_shader_parameter("vein_scale", 10.0)
		_:
			mat.set_shader_parameter("base_color", color)
			mat.set_shader_parameter("vein_color", color * 0.8)
			mat.set_shader_parameter("vein_intensity", 0.2)

	return mat


# ==========================================================================
# FRAME RING BUILDER — the CSS box model for facades
# ==========================================================================

## Build concentric frame molding rings around a content area.
## frames: Array of { "width": float, "profile": String, "material": String }
## Returns Node3D with all frame rings + the inner content dimensions.
static func build_frame_rings(w: float, h: float, frames: Array, p: Dictionary = {}) -> Dictionary:
	var root := _root("FrameRings")
	var depth: float = p.get("depth", 0.08)

	var inset_x: float = 0.0
	var inset_y: float = 0.0

	for i in frames.size():
		var frame: Dictionary = frames[i]
		var fw: float = float(frame.get("width", 0.03))
		var profile_name: String = str(frame.get("profile", "flat"))
		var mat_name: String = str(frame.get("material", "carrara"))

		var mat := _get_marble_material(mat_name)

		# Current outer dimensions
		var outer_w: float = w - inset_x * 2
		var outer_h: float = h - inset_y * 2
		if outer_w <= 0 or outer_h <= 0:
			break

		var frame_depth: float = depth * (1.0 + float(i) * 0.3)  # Each ring steps forward slightly
		var z_offset: float = depth * 0.5 + float(i) * depth * 0.15

		# Build the 4 sides of this frame ring
		var cx: float = w * 0.5
		var cy: float = h * 0.5

		match profile_name:
			"flat", "fillet":
				_build_flat_frame(root, outer_w, outer_h, fw, frame_depth,
					inset_x, inset_y, cx, cy, z_offset, mat, i)
			"ogee", "cyma_recta":
				_build_ogee_frame(root, outer_w, outer_h, fw, frame_depth,
					inset_x, inset_y, cx, cy, z_offset, mat, i)
			"torus", "half_round":
				_build_torus_frame(root, outer_w, outer_h, fw, frame_depth,
					inset_x, inset_y, cx, cy, z_offset, mat, i)
			"cavetto":
				_build_flat_frame(root, outer_w, outer_h, fw, frame_depth,
					inset_x, inset_y, cx, cy, z_offset, mat, i)
			_:
				_build_flat_frame(root, outer_w, outer_h, fw, frame_depth,
					inset_x, inset_y, cx, cy, z_offset, mat, i)

		inset_x += fw
		inset_y += fw

	# Return root + inner content dimensions
	var inner_w: float = w - inset_x * 2
	var inner_h: float = h - inset_y * 2
	return {
		"node": root,
		"inner_w": inner_w,
		"inner_h": inner_h,
		"inset_x": inset_x,
		"inset_y": inset_y,
	}


## Flat frame: 4 box strips forming a rectangular ring.
static func _build_flat_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, depth: float, ix: float, iy: float,
		cx: float, cy: float, z_off: float, mat: Material, idx: int) -> void:
	# Top strip
	root.add_child(_box("Frame%d_Top" % idx,
		Vector3(outer_w, fw, depth),
		Vector3(cx, iy + outer_h - fw * 0.5, z_off), CSGShape3D.OPERATION_UNION, mat))
	# Bottom strip
	root.add_child(_box("Frame%d_Bot" % idx,
		Vector3(outer_w, fw, depth),
		Vector3(cx, iy + fw * 0.5, z_off), CSGShape3D.OPERATION_UNION, mat))
	# Left strip (between top and bottom)
	root.add_child(_box("Frame%d_Left" % idx,
		Vector3(fw, outer_h - fw * 2, depth),
		Vector3(ix + fw * 0.5, cy, z_off), CSGShape3D.OPERATION_UNION, mat))
	# Right strip
	root.add_child(_box("Frame%d_Right" % idx,
		Vector3(fw, outer_h - fw * 2, depth),
		Vector3(ix + outer_w - fw * 0.5, cy, z_off), CSGShape3D.OPERATION_UNION, mat))


## Ogee/cyma recta frame: uses CSGPolygon3D for curved cross-section.
static func _build_ogee_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, depth: float, ix: float, iy: float,
		cx: float, cy: float, z_off: float, mat: Material, idx: int) -> void:
	# Ogee profile: S-curve cross section
	var profile := PackedVector2Array([
		Vector2(0, 0),
		Vector2(fw * 0.3, fw * 0.6),
		Vector2(fw * 0.7, fw * 0.8),
		Vector2(fw, fw),
		Vector2(fw, 0),
	])

	# Top strip (extruded along width)
	root.add_child(_polygon("Frame%d_OgeeTop" % idx, profile, outer_w,
		Vector3(ix, iy + outer_h - fw, z_off - depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat))
	# Bottom strip (flipped)
	var profile_flip := PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, fw),
		Vector2(fw * 0.3, fw * 0.4),
		Vector2(fw * 0.7, fw * 0.2),
		Vector2(fw, 0),
	])
	root.add_child(_polygon("Frame%d_OgeeBot" % idx, profile_flip, outer_w,
		Vector3(ix, iy, z_off - depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat))
	# Left and right: use flat boxes (ogee profile is tricky to rotate in CSG)
	root.add_child(_box("Frame%d_OgeeLeft" % idx,
		Vector3(fw, outer_h - fw * 2, depth),
		Vector3(ix + fw * 0.5, cy, z_off), CSGShape3D.OPERATION_UNION, mat))
	root.add_child(_box("Frame%d_OgeeRight" % idx,
		Vector3(fw, outer_h - fw * 2, depth),
		Vector3(ix + outer_w - fw * 0.5, cy, z_off), CSGShape3D.OPERATION_UNION, mat))


## Torus/half-round frame: cylinder-shaped molding.
static func _build_torus_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, depth: float, ix: float, iy: float,
		cx: float, cy: float, z_off: float, mat: Material, idx: int) -> void:
	# Use CSGCylinder for the horizontal runs, boxes for vertical
	var radius: float = fw * 0.5

	# Top run
	var top_cyl := CSGCylinder3D.new()
	top_cyl.name = "Frame%d_TorusTop" % idx
	top_cyl.radius = radius
	top_cyl.height = outer_w
	top_cyl.sides = 12
	top_cyl.rotation_degrees.z = 90
	top_cyl.position = Vector3(cx, iy + outer_h - radius, z_off)
	top_cyl.material = mat
	root.add_child(top_cyl)

	# Bottom run
	var bot_cyl := CSGCylinder3D.new()
	bot_cyl.name = "Frame%d_TorusBot" % idx
	bot_cyl.radius = radius
	bot_cyl.height = outer_w
	bot_cyl.sides = 12
	bot_cyl.rotation_degrees.z = 90
	bot_cyl.position = Vector3(cx, iy + radius, z_off)
	bot_cyl.material = mat
	root.add_child(bot_cyl)

	# Left run
	var left_cyl := CSGCylinder3D.new()
	left_cyl.name = "Frame%d_TorusLeft" % idx
	left_cyl.radius = radius
	left_cyl.height = outer_h - fw * 2
	left_cyl.sides = 12
	left_cyl.position = Vector3(ix + radius, cy, z_off)
	left_cyl.material = mat
	root.add_child(left_cyl)

	# Right run
	var right_cyl := CSGCylinder3D.new()
	right_cyl.name = "Frame%d_TorusRight" % idx
	right_cyl.radius = radius
	right_cyl.height = outer_h - fw * 2
	right_cyl.sides = 12
	right_cyl.position = Vector3(ix + outer_w - radius, cy, z_off)
	right_cyl.material = mat
	root.add_child(right_cyl)


# ==========================================================================
# MARBLE PANEL — a field content with optional frame rings
# ==========================================================================

## Create a marble panel with concentric frame moldings.
## This is the "floor composition turned vertical" — frames are the borders,
## the marble surface is the field.
static func framed_marble_panel(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("FramedMarblePanel")
	var frames: Array = p.get("frames", [])
	var panel_material: String = p.get("panel_material", "siena")
	var panel_depth: float = p.get("depth", 0.06)

	# Build frame rings
	var frame_result: Dictionary = {}
	if frames.size() > 0:
		frame_result = build_frame_rings(w, h, frames, { "depth": panel_depth })
		root.add_child(frame_result["node"])

	# Inner panel (the "field")
	var inner_w: float = frame_result.get("inner_w", w)
	var inner_h: float = frame_result.get("inner_h", h)
	var inset_x: float = frame_result.get("inset_x", 0.0)
	var inset_y: float = frame_result.get("inset_y", 0.0)

	if inner_w > 0 and inner_h > 0:
		var panel_mat := _get_marble_material(panel_material)
		var z_off: float = panel_depth * 0.5 + frames.size() * panel_depth * 0.15
		root.add_child(_box("MarbleField",
			Vector3(inner_w, inner_h, panel_depth * 0.5),
			Vector3(w * 0.5, h * 0.5, z_off),
			CSGShape3D.OPERATION_UNION, panel_mat))

	return root
