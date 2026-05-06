class_name FrameParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade frame parts — concentric rectangular molding rings around panels.
## Analogous to the mosaic floor border_motifs ring-stack system.
## Cell origin (0,0,0) = bottom-left-front of the cell.
##
## DEPTH MODEL (Galleria Vittorio Emanuele II style):
##   The outer frame molding projects FORWARD from the wall surface.
##   The panel surface is RECESSED behind the wall surface.
##   A beveled chamfer connects the innermost frame to the recessed panel,
##   creating a visible shadow reveal — the hallmark of real stone panel framing.
##
##   Z layout (cell-local, wall front face ~ Z=0):
##     frame_projection  = +0.025  (frame projects forward)
##     wall face          =  0.000
##     panel_recess       = -0.015  (panel sits behind wall face)
##
##   Shadow reveal total = frame_projection + panel_recess = 0.040m


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
			# Giallo di Siena — warm golden-amber base with cream/ivory veins
			mat.set_shader_parameter("base_color", Color(0.831, 0.647, 0.271))  # #D4A545
			mat.set_shader_parameter("vein_color", Color(0.961, 0.902, 0.784))  # #F5E6C8
			mat.set_shader_parameter("vein_style", 1)  # swirled
			mat.set_shader_parameter("vein_intensity", 0.75)
			mat.set_shader_parameter("vein_scale", 4.0)
			mat.set_shader_parameter("roughness_base", 0.22)  # polished marble
			mat.set_shader_parameter("subsurface_strength", 0.25)  # warm translucent glow
		"carrara":
			mat.set_shader_parameter("base_color", Color(0.94, 0.93, 0.90))
			mat.set_shader_parameter("vein_color", Color(0.70, 0.68, 0.65))
			mat.set_shader_parameter("vein_style", 0)  # veined
			mat.set_shader_parameter("vein_intensity", 0.4)
			mat.set_shader_parameter("vein_scale", 8.0)
			mat.set_shader_parameter("roughness_base", 0.25)
			mat.set_shader_parameter("subsurface_strength", 0.15)
		"cream":
			# Cream/ivory for frame moldings — warm off-white
			mat.set_shader_parameter("base_color", Color(0.96, 0.94, 0.88))
			mat.set_shader_parameter("vein_color", Color(0.88, 0.85, 0.78))
			mat.set_shader_parameter("vein_style", 0)  # subtle veins
			mat.set_shader_parameter("vein_intensity", 0.15)
			mat.set_shader_parameter("vein_scale", 12.0)
			mat.set_shader_parameter("roughness_base", 0.30)
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
# DEPTH CONSTANTS — Galleria-style shadow reveals
# ==========================================================================

## How far the outermost frame molding projects forward from the wall face.
const FRAME_PROJECTION := 0.025
## How far the panel surface is recessed behind the wall face.
const PANEL_RECESS := 0.015
## Width of the beveled chamfer transition between frame and panel.
const BEVEL_WIDTH := 0.012
## Thin depth for flat backing behind the recess (fills gap to wall).
const BACKING_DEPTH := 0.005


# ==========================================================================
# FRAME RING BUILDER — the CSS box model for facades (with 3D depth)
# ==========================================================================

## Build concentric frame molding rings around a content area.
## frames: Array of { "width": float, "profile": String, "material": String }
##
## Depth behaviour:
##   - The outermost frame ring projects forward by FRAME_PROJECTION.
##   - Each successive inner ring steps back slightly, creating a stacked reveal.
##   - After all rings, the inner content area sits recessed by PANEL_RECESS.
##   - A bevel/chamfer strip connects the innermost frame to the recessed panel.
##
## Returns Dictionary with "node", "inner_w", "inner_h", "inset_x", "inset_y",
## and "panel_z" (the Z position for the recessed panel surface).
static func build_frame_rings(w: float, h: float, frames: Array, p: Dictionary = {}) -> Dictionary:
	var root := _root("FrameRings")

	var frame_projection: float = p.get("frame_projection", FRAME_PROJECTION)
	var panel_recess: float = p.get("panel_recess", PANEL_RECESS)
	var bevel_width: float = p.get("bevel_width", BEVEL_WIDTH)

	var num_frames: int = frames.size()
	var inset_x: float = 0.0
	var inset_y: float = 0.0

	# Total Z travel from outermost frame front to panel surface
	var total_z_travel: float = frame_projection + panel_recess
	# Z step between each frame ring (distribute travel across rings + 1 for panel)
	var z_step: float = total_z_travel / float(num_frames + 1) if num_frames > 0 else 0.0

	for i in num_frames:
		var frame: Dictionary = frames[i]
		var fw: float = float(frame.get("width", 0.03))
		var profile_name: String = str(frame.get("profile", "flat"))
		var mat_name: String = str(frame.get("material", "carrara"))

		var mat := _get_marble_material(mat_name)

		# Current outer dimensions (shrinking inward with each ring)
		var outer_w: float = w - inset_x * 2
		var outer_h: float = h - inset_y * 2
		if outer_w <= 0 or outer_h <= 0:
			break

		# Z position: outermost ring is at +frame_projection, steps back per ring
		var ring_z: float = frame_projection - float(i) * z_step
		# Depth (thickness) of this molding strip — taper inward rings slightly
		var ring_depth: float = maxf(0.01, frame_projection * (1.0 - float(i) * 0.15))

		var cx: float = w * 0.5
		var cy: float = h * 0.5

		match profile_name:
			"flat", "fillet":
				_build_flat_frame(root, outer_w, outer_h, fw, ring_depth,
					inset_x, inset_y, cx, cy, ring_z, mat, i)
			"ogee", "cyma_recta":
				_build_ogee_frame(root, outer_w, outer_h, fw, ring_depth,
					inset_x, inset_y, cx, cy, ring_z, mat, i)
			"torus", "half_round":
				_build_torus_frame(root, outer_w, outer_h, fw, ring_depth,
					inset_x, inset_y, cx, cy, ring_z, mat, i)
			"cavetto":
				_build_cavetto_frame(root, outer_w, outer_h, fw, ring_depth,
					inset_x, inset_y, cx, cy, ring_z, mat, i)
			_:
				_build_flat_frame(root, outer_w, outer_h, fw, ring_depth,
					inset_x, inset_y, cx, cy, ring_z, mat, i)

		inset_x += fw
		inset_y += fw

	# ── Bevel / chamfer transition ──
	# Connects the innermost frame edge down to the recessed panel surface.
	# This angled strip is what creates the visible shadow line.
	var inner_w: float = w - inset_x * 2
	var inner_h: float = h - inset_y * 2
	var panel_z: float = -panel_recess  # Panel sits behind wall face

	if inner_w > 0 and inner_h > 0 and num_frames > 0:
		var last_ring_z: float = frame_projection - float(num_frames - 1) * z_step
		var bevel_mat := _get_marble_material("grey_stone")
		_build_bevel_transition(root, inner_w, inner_h, bevel_width,
			inset_x, inset_y, w * 0.5, h * 0.5,
			last_ring_z, panel_z, bevel_mat)
		inset_x += bevel_width
		inset_y += bevel_width
		inner_w = w - inset_x * 2
		inner_h = h - inset_y * 2

	return {
		"node": root,
		"inner_w": inner_w,
		"inner_h": inner_h,
		"inset_x": inset_x,
		"inset_y": inset_y,
		"panel_z": panel_z,
	}


# ==========================================================================
# FRAME RING PROFILES
# ==========================================================================

## Flat frame: 4 box strips forming a rectangular ring.
## Each strip has real depth (ring_depth) and sits at ring_z.
static func _build_flat_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, ring_depth: float, ix: float, iy: float,
		cx: float, cy: float, ring_z: float, mat: Material, idx: int) -> void:
	# Top strip
	root.add_child(_box("Frame%d_Top" % idx,
		Vector3(outer_w, fw, ring_depth),
		Vector3(cx, iy + outer_h - fw * 0.5, ring_z),
		CSGShape3D.OPERATION_UNION, mat))
	# Bottom strip
	root.add_child(_box("Frame%d_Bot" % idx,
		Vector3(outer_w, fw, ring_depth),
		Vector3(cx, iy + fw * 0.5, ring_z),
		CSGShape3D.OPERATION_UNION, mat))
	# Left strip (between top and bottom)
	root.add_child(_box("Frame%d_Left" % idx,
		Vector3(fw, outer_h - fw * 2, ring_depth),
		Vector3(ix + fw * 0.5, cy, ring_z),
		CSGShape3D.OPERATION_UNION, mat))
	# Right strip
	root.add_child(_box("Frame%d_Right" % idx,
		Vector3(fw, outer_h - fw * 2, ring_depth),
		Vector3(ix + outer_w - fw * 0.5, cy, ring_z),
		CSGShape3D.OPERATION_UNION, mat))


## Ogee/cyma recta frame: uses CSGPolygon3D for curved cross-section.
## The profile is oriented so the ogee curve faces forward (viewer-facing).
static func _build_ogee_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, ring_depth: float, ix: float, iy: float,
		cx: float, cy: float, ring_z: float, mat: Material, idx: int) -> void:
	# Ogee profile: S-curve cross section rising to ring_depth height
	var profile := PackedVector2Array([
		Vector2(0, 0),
		Vector2(fw * 0.3, fw * 0.6),
		Vector2(fw * 0.7, fw * 0.8),
		Vector2(fw, fw),
		Vector2(fw, 0),
	])

	# Top strip (extruded along width)
	root.add_child(_polygon("Frame%d_OgeeTop" % idx, profile, outer_w,
		Vector3(ix, iy + outer_h - fw, ring_z - ring_depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat))
	# Bottom strip (flipped profile)
	var profile_flip := PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, fw),
		Vector2(fw * 0.3, fw * 0.4),
		Vector2(fw * 0.7, fw * 0.2),
		Vector2(fw, 0),
	])
	root.add_child(_polygon("Frame%d_OgeeBot" % idx, profile_flip, outer_w,
		Vector3(ix, iy, ring_z - ring_depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat))
	# Left and right: use boxes with the same depth as the profile
	root.add_child(_box("Frame%d_OgeeLeft" % idx,
		Vector3(fw, outer_h - fw * 2, ring_depth),
		Vector3(ix + fw * 0.5, cy, ring_z),
		CSGShape3D.OPERATION_UNION, mat))
	root.add_child(_box("Frame%d_OgeeRight" % idx,
		Vector3(fw, outer_h - fw * 2, ring_depth),
		Vector3(ix + outer_w - fw * 0.5, cy, ring_z),
		CSGShape3D.OPERATION_UNION, mat))


## Torus/half-round frame: cylinder-shaped molding at ring_z.
static func _build_torus_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, _ring_depth: float, ix: float, iy: float,
		cx: float, cy: float, ring_z: float, mat: Material, idx: int) -> void:
	var radius: float = fw * 0.5

	# Top run
	var top_cyl := CSGCylinder3D.new()
	top_cyl.name = "Frame%d_TorusTop" % idx
	top_cyl.radius = radius
	top_cyl.height = outer_w
	top_cyl.sides = 12
	top_cyl.rotation_degrees.z = 90
	top_cyl.position = Vector3(cx, iy + outer_h - radius, ring_z)
	top_cyl.material = mat
	root.add_child(top_cyl)

	# Bottom run
	var bot_cyl := CSGCylinder3D.new()
	bot_cyl.name = "Frame%d_TorusBot" % idx
	bot_cyl.radius = radius
	bot_cyl.height = outer_w
	bot_cyl.sides = 12
	bot_cyl.rotation_degrees.z = 90
	bot_cyl.position = Vector3(cx, iy + radius, ring_z)
	bot_cyl.material = mat
	root.add_child(bot_cyl)

	# Left run
	var left_cyl := CSGCylinder3D.new()
	left_cyl.name = "Frame%d_TorusLeft" % idx
	left_cyl.radius = radius
	left_cyl.height = outer_h - fw * 2
	left_cyl.sides = 12
	left_cyl.position = Vector3(ix + radius, cy, ring_z)
	left_cyl.material = mat
	root.add_child(left_cyl)

	# Right run
	var right_cyl := CSGCylinder3D.new()
	right_cyl.name = "Frame%d_TorusRight" % idx
	right_cyl.radius = radius
	right_cyl.height = outer_h - fw * 2
	right_cyl.sides = 12
	right_cyl.position = Vector3(ix + outer_w - radius, cy, ring_z)
	right_cyl.material = mat
	root.add_child(right_cyl)


## Cavetto frame: concave quarter-circle profile (like a cove molding).
## Uses CSGPolygon3D with an inward-curving cross section.
static func _build_cavetto_frame(root: Node3D, outer_w: float, outer_h: float,
		fw: float, ring_depth: float, ix: float, iy: float,
		cx: float, cy: float, ring_z: float, mat: Material, idx: int) -> void:
	# Cavetto profile: concave quarter-circle approximated with segments
	var steps := 6
	var profile := PackedVector2Array()
	profile.append(Vector2(0, 0))
	for s in range(steps + 1):
		var t: float = float(s) / float(steps)
		var angle: float = t * PI * 0.5
		var px: float = sin(angle) * fw
		var py: float = cos(angle) * fw
		profile.append(Vector2(px, py))
	profile.append(Vector2(fw, 0))

	# Top strip
	root.add_child(_polygon("Frame%d_CavettoTop" % idx, profile, outer_w,
		Vector3(ix, iy + outer_h - fw, ring_z - ring_depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat))
	# Bottom, left, right as flat boxes
	root.add_child(_box("Frame%d_CavettoBot" % idx,
		Vector3(outer_w, fw, ring_depth),
		Vector3(cx, iy + fw * 0.5, ring_z),
		CSGShape3D.OPERATION_UNION, mat))
	root.add_child(_box("Frame%d_CavettoLeft" % idx,
		Vector3(fw, outer_h - fw * 2, ring_depth),
		Vector3(ix + fw * 0.5, cy, ring_z),
		CSGShape3D.OPERATION_UNION, mat))
	root.add_child(_box("Frame%d_CavettoRight" % idx,
		Vector3(fw, outer_h - fw * 2, ring_depth),
		Vector3(ix + outer_w - fw * 0.5, cy, ring_z),
		CSGShape3D.OPERATION_UNION, mat))


# ==========================================================================
# BEVEL / CHAMFER TRANSITION
# ==========================================================================

## Build 4 angled strips that connect the innermost frame edge (at frame_z)
## down to the recessed panel surface (at panel_z).
## This creates the shadow reveal — the sloped face catches directional light
## and casts a dark line that reads as depth.
static func _build_bevel_transition(root: Node3D, inner_w: float, inner_h: float,
		bevel_w: float, ix: float, iy: float, cx: float, cy: float,
		frame_z: float, panel_z: float, mat: Material) -> void:
	var z_drop: float = frame_z - panel_z  # positive value
	var bevel_depth: float = sqrt(bevel_w * bevel_w + z_drop * z_drop)
	var mid_z: float = (frame_z + panel_z) * 0.5

	# Top bevel strip
	var top_bevel := _box("Bevel_Top",
		Vector3(inner_w, bevel_w, bevel_depth),
		Vector3(cx, iy + inner_h - bevel_w * 0.5, mid_z),
		CSGShape3D.OPERATION_UNION, mat)
	if bevel_w > 0.001:
		top_bevel.rotation.x = atan2(z_drop, bevel_w)
	root.add_child(top_bevel)

	# Bottom bevel strip
	var bot_bevel := _box("Bevel_Bot",
		Vector3(inner_w, bevel_w, bevel_depth),
		Vector3(cx, iy + bevel_w * 0.5, mid_z),
		CSGShape3D.OPERATION_UNION, mat)
	if bevel_w > 0.001:
		bot_bevel.rotation.x = -atan2(z_drop, bevel_w)
	root.add_child(bot_bevel)

	# Left bevel strip
	var left_bevel := _box("Bevel_Left",
		Vector3(bevel_w, inner_h - bevel_w * 2, bevel_depth),
		Vector3(ix + bevel_w * 0.5, cy, mid_z),
		CSGShape3D.OPERATION_UNION, mat)
	if bevel_w > 0.001:
		left_bevel.rotation.y = -atan2(z_drop, bevel_w)
	root.add_child(left_bevel)

	# Right bevel strip
	var right_bevel := _box("Bevel_Right",
		Vector3(bevel_w, inner_h - bevel_w * 2, bevel_depth),
		Vector3(ix + inner_w - bevel_w * 0.5, cy, mid_z),
		CSGShape3D.OPERATION_UNION, mat)
	if bevel_w > 0.001:
		right_bevel.rotation.y = atan2(z_drop, bevel_w)
	root.add_child(right_bevel)


# ==========================================================================
# BACKING PLATE — fills the recess behind the panel to prevent see-through
# ==========================================================================

## A thin plate behind the recessed panel area, colored to match the wall.
## Prevents any gaps between the panel and the base wall.
static func _build_backing_plate(root: Node3D, inner_w: float, inner_h: float,
		cx: float, cy: float, panel_z: float) -> void:
	var backing_mat := _M.stone(Color(0.78, 0.74, 0.68))
	var backing_z: float = panel_z - BACKING_DEPTH
	root.add_child(_box("BackingPlate",
		Vector3(inner_w, inner_h, BACKING_DEPTH),
		Vector3(cx, cy, backing_z),
		CSGShape3D.OPERATION_UNION, backing_mat))


# ==========================================================================
# MARBLE PANEL — a field content with frame rings and recessed depth
# ==========================================================================

## Create a marble panel with concentric frame moldings and realistic depth.
##
## The outer frame projects forward from the wall, the inner panel is recessed,
## and a bevel/chamfer transition connects them — creating the deep shadow
## reveal characteristic of Galleria Vittorio Emanuele II stonework.
##
## Params (via p Dictionary):
##   "frames"           : Array of { "width", "profile", "material" }
##   "panel_material"   : String — marble type for the field (default "siena")
##   "depth"            : float — legacy param (ignored, kept for compat)
##   "frame_projection" : float — how far frame projects (default 0.025)
##   "panel_recess"     : float — how far panel recesses (default 0.015)
##   "bevel_width"      : float — chamfer strip width (default 0.012)
##   "panel_thickness"  : float — thickness of the marble slab (default 0.008)
static func framed_marble_panel(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("FramedMarblePanel")
	var frames: Array = p.get("frames", [])
	var panel_material: String = p.get("panel_material", "siena")
	var frame_projection: float = p.get("frame_projection", FRAME_PROJECTION)
	var panel_recess: float = p.get("panel_recess", PANEL_RECESS)
	var bevel_width: float = p.get("bevel_width", BEVEL_WIDTH)
	var panel_thickness: float = p.get("panel_thickness", 0.008)

	# Build frame rings (projects forward, steps back toward panel)
	var frame_result: Dictionary = {}
	if frames.size() > 0:
		frame_result = build_frame_rings(w, h, frames, {
			"frame_projection": frame_projection,
			"panel_recess": panel_recess,
			"bevel_width": bevel_width,
		})
		root.add_child(frame_result["node"])

	# Inner panel (the "field") — sits recessed behind wall face
	var inner_w: float = frame_result.get("inner_w", w)
	var inner_h: float = frame_result.get("inner_h", h)
	var panel_z: float = frame_result.get("panel_z", -panel_recess)

	if inner_w > 0 and inner_h > 0:
		var panel_mat := _get_marble_material(panel_material)
		# Panel surface: thin marble slab at the recessed depth
		root.add_child(_box("MarbleField",
			Vector3(inner_w, inner_h, panel_thickness),
			Vector3(w * 0.5, h * 0.5, panel_z),
			CSGShape3D.OPERATION_UNION, panel_mat))

		# Backing plate to fill gap between panel and wall
		_build_backing_plate(root, inner_w, inner_h,
			w * 0.5, h * 0.5, panel_z - panel_thickness * 0.5)

	return root
