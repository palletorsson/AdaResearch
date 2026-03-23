class_name OpeningParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade opening parts — windows, doors, and portals.
## Cell origin (0,0,0) = bottom-left-front of the cell.
## +X = right, +Y = up, +Z = toward viewer (out of wall face).


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
	if mat:
		b.material = mat
	return b


static func _cyl(cname: String, radius: float, height: float,
		pos: Vector3 = Vector3.ZERO, sides: int = 16,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.name = cname
	c.radius = radius
	c.height = height
	c.sides = sides
	c.position = pos
	c.operation = op
	c.use_collision = false
	if mat:
		c.material = mat
	return c


static func _combiner(cname: String,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION) -> CSGCombiner3D:
	var c := CSGCombiner3D.new()
	c.name = cname
	c.operation = op
	c.use_collision = false
	return c


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


# ==========================================================================
# WINDOWS
# ==========================================================================

## Rectangular window with frame, optional mullion and transom.
static func rect_window(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RectWindow")
	var inset: float = p.get("inset", 0.15)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var wall_depth: float = p.get("wall_depth", 0.25)
	var has_mullion: bool = p.get("mullion", false)
	var has_transom: bool = p.get("transom", false)
	var margin_x: float = w * inset
	var margin_y: float = h * 0.1
	var opening_w: float = w - margin_x * 2.0
	var opening_h: float = h - margin_y * 2.0
	var cx := w * 0.5
	var cy := h * 0.5

	var mat_glass := _M.stone(Color(0.08, 0.1, 0.15))
	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))

	# Glass pane (dark void behind opening)
	var glass := _box("GlassPane", Vector3(opening_w, opening_h, 0.01),
		Vector3(cx, cy, 0.03), CSGShape3D.OPERATION_UNION, mat_glass)
	root.add_child(glass)

	# Frame strips
	var lintel := _box("Lintel", Vector3(opening_w + frame_t * 2.0, frame_t, wall_depth * 0.3),
		Vector3(cx, cy + opening_h * 0.5 + frame_t * 0.5, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(lintel)

	var sill := _box("Sill", Vector3(opening_w + frame_t * 3.0, frame_t, wall_depth * 0.4),
		Vector3(cx, cy - opening_h * 0.5 - frame_t * 0.5, wall_depth * 0.2),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(sill)

	var jamb_left := _box("JambLeft", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, cy, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, cy, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_right)

	if has_mullion:
		var mullion := _box("Mullion", Vector3(frame_t * 0.7, opening_h, wall_depth * 0.2),
			Vector3(cx, cy, wall_depth * 0.1),
			CSGShape3D.OPERATION_UNION, mat_frame)
		root.add_child(mullion)

	if has_transom:
		var transom := _box("Transom", Vector3(opening_w, frame_t * 0.7, wall_depth * 0.2),
			Vector3(cx, cy + opening_h * 0.15, wall_depth * 0.1),
			CSGShape3D.OPERATION_UNION, mat_frame)
		root.add_child(transom)

	return root


## Arched window: rectangular lower portion + semicircular arch at top.
## Supports keystone, archivolt molding, spandrel fill, ornate frame, and
## dark/reflective glazing — designed for Galleria-style gallery arches.
## Params:
##   keystone (bool=false)     — trapezoidal keystone at apex
##   ornate_frame (bool=false) — thicker, projected frame with archivolt ring
##   arch_ratio (float=0.5)    — arch semicircle radius as fraction of opening_w
##   arch_height_frac (float=0.85) — how much of zone height the opening uses
##   archivolt_depth (float=0.02)  — forward projection of archivolt molding
##   mullion (bool=false)      — vertical mullion bar
static func arched_window(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ArchedWindow")
	var inset: float = p.get("inset", 0.12)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var wall_depth: float = p.get("wall_depth", 0.25)
	var has_keystone: bool = p.get("keystone", false)
	var ornate: bool = p.get("ornate_frame", false)
	var arch_ratio: float = p.get("arch_ratio", 0.5)
	var height_frac: float = p.get("arch_height_frac", 0.85)
	var archivolt_depth: float = p.get("archivolt_depth", 0.02)
	var has_mullion: bool = p.get("mullion", false)

	# --- Geometry ---
	var margin_x: float = w * inset
	var total_opening_h: float = h * height_frac
	var bottom_margin: float = h * (1.0 - height_frac) * 0.5
	var opening_w: float = w - margin_x * 2.0
	var arch_r: float = opening_w * arch_ratio
	var rect_h: float = total_opening_h - arch_r
	if rect_h < 0.0:
		rect_h = 0.0
		arch_r = total_opening_h
	var cx := w * 0.5
	var rect_bottom := bottom_margin
	var rect_cy := rect_bottom + rect_h * 0.5
	var spring_y := rect_bottom + rect_h  # where the arch starts

	# --- Materials ---
	# Dark / reflective glass
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.04, 0.05, 0.08)
	mat_glass.roughness = 0.08
	mat_glass.metallic = 0.6
	mat_glass.metallic_specular = 0.9
	mat_glass.cull_mode = BaseMaterial3D.CULL_BACK
	mat_glass.resource_name = "ArchGlass"

	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))
	var mat_keystone := _M.stone(Color(0.82, 0.78, 0.72))
	var mat_wall := _M.stone(Color(0.78, 0.74, 0.68))
	# Archivolt molding — slightly lighter than frame
	var mat_archivolt := _M.stone(Color(0.80, 0.76, 0.70))
	if ornate:
		frame_t *= 1.4

	# ==================================================================
	# 1. Glass panes (dark / reflective window behind the opening)
	# ==================================================================
	var glass_z := 0.005  # slightly recessed behind frame

	# Rectangular glass
	if rect_h > 0.001:
		var glass_rect := _box("GlassPaneRect", Vector3(opening_w, rect_h, 0.008),
			Vector3(cx, rect_cy, glass_z), CSGShape3D.OPERATION_UNION, mat_glass)
		root.add_child(glass_rect)

	# Semicircular glass (upper arch)
	var glass_arch := _cyl("GlassPaneArch", arch_r, 0.008,
		Vector3(cx, spring_y, glass_z), 32,
		CSGShape3D.OPERATION_UNION, mat_glass)
	glass_arch.rotation_degrees.x = 90.0
	root.add_child(glass_arch)

	# Clip lower half of the glass cylinder (keep only semicircle)
	var glass_clip := _box("GlassArchClip",
		Vector3(opening_w + 0.1, arch_r + 0.01, 0.03),
		Vector3(cx, spring_y - (arch_r + 0.01) * 0.5, glass_z),
		CSGShape3D.OPERATION_SUBTRACTION)
	root.add_child(glass_clip)

	# ==================================================================
	# 2. Spandrel fill — wall-colored triangles above the arch curve
	#    Fills the rectangular zone corners that sit above the semicircle.
	# ==================================================================
	var spandrel_top := spring_y + arch_r
	var spandrel_h := spandrel_top - spring_y
	var spandrel_z := 0.01
	if spandrel_h > 0.01:
		# Left spandrel (box covering left quarter, then arch subtracts the curve)
		var sp_combiner := _combiner("SpandrelGroup")
		root.add_child(sp_combiner)

		# Full rectangular block spanning the arch zone
		var sp_block := _box("SpanBlock",
			Vector3(opening_w + frame_t * 2.0, spandrel_h, wall_depth * 0.18),
			Vector3(cx, spring_y + spandrel_h * 0.5, wall_depth * 0.09),
			CSGShape3D.OPERATION_UNION, mat_wall)
		sp_combiner.add_child(sp_block)

		# Subtract the arch cylinder from the spandrel block
		var sp_cut := _cyl("SpanCut", arch_r + 0.001, wall_depth * 0.5,
			Vector3(cx, spring_y, wall_depth * 0.09), 32,
			CSGShape3D.OPERATION_SUBTRACTION)
		sp_cut.rotation_degrees.x = 90.0
		sp_combiner.add_child(sp_cut)

	# ==================================================================
	# 3. Sill (bottom ledge)
	# ==================================================================
	var sill := _box("Sill",
		Vector3(opening_w + frame_t * 3.0, frame_t, wall_depth * 0.4),
		Vector3(cx, rect_bottom - frame_t * 0.5, wall_depth * 0.2),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(sill)

	# ==================================================================
	# 4. Jambs (vertical side frames)
	# ==================================================================
	var jamb_h := rect_h
	var jamb_depth := wall_depth * 0.3 if not ornate else wall_depth * 0.38
	var jamb_left := _box("JambLeft",
		Vector3(frame_t, jamb_h, jamb_depth),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, rect_cy, jamb_depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight",
		Vector3(frame_t, jamb_h, jamb_depth),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, rect_cy, jamb_depth * 0.5),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_right)

	# ==================================================================
	# 5. Archivolt — raised molding ring following the arch curve
	#    Built as outer cylinder minus inner cylinder, projected forward.
	# ==================================================================
	var archivolt_t := frame_t * 1.2  # thickness of the ring
	var archivolt_z := archivolt_depth + wall_depth * 0.08  # projected in front of wall

	var av_combiner := _combiner("ArchivolGroup")
	root.add_child(av_combiner)

	# Outer ring
	var av_outer := _cyl("ArchivoltOuter", arch_r + archivolt_t, archivolt_depth + 0.01,
		Vector3(cx, spring_y, archivolt_z), 32,
		CSGShape3D.OPERATION_UNION, mat_archivolt)
	av_outer.rotation_degrees.x = 90.0
	av_combiner.add_child(av_outer)

	# Inner subtraction (hollow the ring)
	var av_inner := _cyl("ArchivoltInner", arch_r - 0.002, archivolt_depth + 0.05,
		Vector3(cx, spring_y, archivolt_z), 32,
		CSGShape3D.OPERATION_SUBTRACTION)
	av_inner.rotation_degrees.x = 90.0
	av_combiner.add_child(av_inner)

	# Clip bottom half of archivolt (keep only semicircular top)
	var av_clip := _box("ArchivoltClip",
		Vector3(arch_r * 3.0, arch_r + 0.02, archivolt_depth + 0.1),
		Vector3(cx, spring_y - (arch_r + 0.02) * 0.5, archivolt_z),
		CSGShape3D.OPERATION_SUBTRACTION)
	av_combiner.add_child(av_clip)

	# ==================================================================
	# 6. Keystone — trapezoidal block at the apex of the arch
	# ==================================================================
	if has_keystone:
		var ks_h := arch_r * 0.30
		var ks_top_w := frame_t * 1.2
		var ks_bot_w := frame_t * 2.2
		var ks_depth := archivolt_depth + wall_depth * 0.12
		var ks_center_y := spring_y + arch_r - ks_h * 0.35

		# Build trapezoidal keystone with CSGPolygon3D
		# Profile in XY, extruded along Z (depth)
		var ks_profile := PackedVector2Array()
		ks_profile.append(Vector2(-ks_bot_w * 0.5, -ks_h * 0.5))   # bottom-left
		ks_profile.append(Vector2( ks_bot_w * 0.5, -ks_h * 0.5))   # bottom-right
		ks_profile.append(Vector2( ks_top_w * 0.5,  ks_h * 0.5))   # top-right
		ks_profile.append(Vector2(-ks_top_w * 0.5,  ks_h * 0.5))   # top-left

		var keystone := CSGPolygon3D.new()
		keystone.name = "Keystone"
		keystone.polygon = ks_profile
		keystone.depth = ks_depth
		keystone.mode = CSGPolygon3D.MODE_DEPTH
		keystone.operation = CSGShape3D.OPERATION_UNION
		keystone.material = mat_keystone
		keystone.position = Vector3(cx, ks_center_y, -ks_depth * 0.5)
		root.add_child(keystone)

	# ==================================================================
	# 7. Optional mullion
	# ==================================================================
	if has_mullion:
		var mullion := _box("Mullion",
			Vector3(frame_t * 0.5, rect_h + arch_r * 0.7, wall_depth * 0.15),
			Vector3(cx, rect_bottom + (rect_h + arch_r * 0.7) * 0.5, wall_depth * 0.08),
			CSGShape3D.OPERATION_UNION, mat_frame)
		root.add_child(mullion)

	return root


## Venetian bifora: two arched openings with central column.
static func venetian_bifora(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("VenetianBifora")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var margin_x: float = w * 0.08
	var margin_y: float = h * 0.08
	var total_opening_w: float = w - margin_x * 2.0
	var col_w: float = total_opening_w * 0.08
	var single_w: float = (total_opening_w - col_w) * 0.5
	var arch_r: float = single_w * 0.5
	var rect_h: float = h - margin_y * 2.0 - arch_r
	var cx := w * 0.5

	var mat_glass := _M.stone(Color(0.08, 0.1, 0.15))
	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))

	# Glass panes (dark voids behind openings)
	var left_cx := margin_x + single_w * 0.5
	var right_cx := margin_x + single_w + col_w + single_w * 0.5

	var glass_left_rect := _box("GlassLeftRect", Vector3(single_w, rect_h, 0.01),
		Vector3(left_cx, margin_y + rect_h * 0.5, 0.03),
		CSGShape3D.OPERATION_UNION, mat_glass)
	root.add_child(glass_left_rect)

	var glass_left_arch := _cyl("GlassLeftArch", arch_r, 0.01,
		Vector3(left_cx, margin_y + rect_h, 0.03), 24,
		CSGShape3D.OPERATION_UNION, mat_glass)
	glass_left_arch.rotation_degrees.x = 90.0
	root.add_child(glass_left_arch)

	var glass_right_rect := _box("GlassRightRect", Vector3(single_w, rect_h, 0.01),
		Vector3(right_cx, margin_y + rect_h * 0.5, 0.03),
		CSGShape3D.OPERATION_UNION, mat_glass)
	root.add_child(glass_right_rect)

	var glass_right_arch := _cyl("GlassRightArch", arch_r, 0.01,
		Vector3(right_cx, margin_y + rect_h, 0.03), 24,
		CSGShape3D.OPERATION_UNION, mat_glass)
	glass_right_arch.rotation_degrees.x = 90.0
	root.add_child(glass_right_arch)

	# Central column
	var col_radius := col_w * 0.4
	var column := _cyl("CentralColumn", col_radius, rect_h,
		Vector3(cx, margin_y + rect_h * 0.5, wall_depth * 0.15), 12,
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(column)

	# Sill
	var sill := _box("Sill", Vector3(total_opening_w + frame_t * 2.0, frame_t, wall_depth * 0.4),
		Vector3(cx, margin_y - frame_t * 0.5, wall_depth * 0.2),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(sill)

	return root


## Rose window: circular opening with radial tracery.
static func rose_window(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RoseWindow")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var cx := w * 0.5
	var cy := h * 0.5
	var outer_r := minf(w, h) * 0.38

	var mat_glass := _M.stone(Color(0.08, 0.1, 0.15))
	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))
	var mat_decorative := _M.stone(Color(0.82, 0.78, 0.72))

	# Glass pane (dark void behind opening)
	var glass := _cyl("GlassPane", outer_r, 0.01,
		Vector3(cx, cy, 0.03), 32,
		CSGShape3D.OPERATION_UNION, mat_glass)
	glass.rotation_degrees.x = 90.0
	root.add_child(glass)

	# Outer frame ring
	var ring_outer := _cyl("RingOuter", outer_r + frame_t, frame_t * 1.5,
		Vector3(cx, cy, wall_depth * 0.15), 32,
		CSGShape3D.OPERATION_UNION, mat_frame)
	ring_outer.rotation_degrees.x = 90.0
	root.add_child(ring_outer)

	# Radial tracery spokes
	var spoke_count: int = p.get("spoke_count", 8)
	for i in range(spoke_count):
		var angle := TAU * float(i) / float(spoke_count)
		var spoke_len := outer_r * 0.9
		var spoke_cx := cx + cos(angle) * spoke_len * 0.5
		var spoke_cy := cy + sin(angle) * spoke_len * 0.5
		var spoke := _box("Spoke_%d" % i,
			Vector3(frame_t * 0.6, spoke_len, wall_depth * 0.15),
			Vector3(spoke_cx, spoke_cy, wall_depth * 0.15),
			CSGShape3D.OPERATION_UNION, mat_decorative)
		spoke.rotation_degrees.z = rad_to_deg(angle) - 90.0
		root.add_child(spoke)

	return root


## Porthole: circular window.
static func porthole(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Porthole")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.04)
	var cx := w * 0.5
	var cy := h * 0.5
	var radius := minf(w, h) * 0.3

	var mat_glass := _M.stone(Color(0.08, 0.1, 0.15))
	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))

	# Glass pane (dark void behind opening)
	var glass := _cyl("GlassPane", radius, 0.01,
		Vector3(cx, cy, 0.03), 24,
		CSGShape3D.OPERATION_UNION, mat_glass)
	glass.rotation_degrees.x = 90.0
	root.add_child(glass)

	# Frame ring
	var ring := _cyl("FrameRing", radius + frame_t, frame_t * 1.5,
		Vector3(cx, cy, wall_depth * 0.15), 24,
		CSGShape3D.OPERATION_UNION, mat_frame)
	ring.rotation_degrees.x = 90.0
	root.add_child(ring)

	return root


# ==========================================================================
# DOORS
# ==========================================================================

## Single door: one-panel door reaching near ground level.
static func single_door(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("SingleDoor")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.05)
	var margin_x: float = w * 0.15
	var opening_w: float = w - margin_x * 2.0
	var opening_h: float = h * 0.92
	var cx := w * 0.5
	var cy := opening_h * 0.5

	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))
	var mat_door := _M.wood(Color(0.35, 0.25, 0.15))
	var mat_metal := _M.metal()

	# Dark void behind door
	var void_back := _box("DoorVoid", Vector3(opening_w, opening_h, 0.01),
		Vector3(cx, cy, 0.03),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	root.add_child(void_back)

	# Frame
	var lintel := _box("Lintel", Vector3(opening_w + frame_t * 2.5, frame_t * 1.5, wall_depth * 0.35),
		Vector3(cx, opening_h + frame_t * 0.75, wall_depth * 0.18),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(lintel)

	var jamb_left := _box("JambLeft", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, cy, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, cy, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_right)

	# Panels
	var panel_w := opening_w * 0.8
	var panel_gap := opening_h * 0.05
	var panel_h := (opening_h - panel_gap * 3.0) * 0.5
	var panel_depth := 0.02

	var upper_panel := _box("UpperPanel", Vector3(panel_w, panel_h, panel_depth),
		Vector3(cx, opening_h - panel_gap - panel_h * 0.5, wall_depth * 0.08),
		CSGShape3D.OPERATION_UNION, mat_door)
	root.add_child(upper_panel)

	var lower_panel := _box("LowerPanel", Vector3(panel_w, panel_h, panel_depth),
		Vector3(cx, panel_gap + panel_h * 0.5, wall_depth * 0.08),
		CSGShape3D.OPERATION_UNION, mat_door)
	root.add_child(lower_panel)

	# Handle
	var handle := _cyl("Handle", 0.015, 0.04,
		Vector3(cx + opening_w * 0.3, opening_h * 0.45, wall_depth * 0.12), 8,
		CSGShape3D.OPERATION_UNION, mat_metal)
	handle.rotation_degrees.x = 90.0
	root.add_child(handle)

	return root


## Double door: two-leaf door with central meeting stile.
static func double_door(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("DoubleDoor")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.05)
	var margin_x: float = w * 0.1
	var opening_w: float = w - margin_x * 2.0
	var opening_h: float = h * 0.92
	var cx := w * 0.5
	var cy := opening_h * 0.5

	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))
	var mat_door := _M.wood(Color(0.35, 0.25, 0.15))
	var mat_metal := _M.metal()

	# Dark void behind door
	var void_back := _box("DoorVoid", Vector3(opening_w, opening_h, 0.01),
		Vector3(cx, cy, 0.03),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	root.add_child(void_back)

	# Frame
	var lintel := _box("Lintel", Vector3(opening_w + frame_t * 2.5, frame_t * 1.5, wall_depth * 0.35),
		Vector3(cx, opening_h + frame_t * 0.75, wall_depth * 0.18),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(lintel)

	var jamb_left := _box("JambLeft", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, cy, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, opening_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, cy, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_right)

	# Meeting stile (central vertical bar)
	var stile := _box("MeetingStile", Vector3(frame_t * 0.8, opening_h, wall_depth * 0.2),
		Vector3(cx, cy, wall_depth * 0.1),
		CSGShape3D.OPERATION_UNION, mat_door)
	root.add_child(stile)

	# Panels (two per leaf)
	var leaf_w := (opening_w - frame_t * 0.8) * 0.5
	var panel_w := leaf_w * 0.75
	var panel_gap := opening_h * 0.05
	var panel_h := (opening_h - panel_gap * 3.0) * 0.5
	var panel_depth := 0.02

	for side in [-1.0, 1.0]:
		var leaf_cx: float = cx + float(side) * (leaf_w * 0.5 + frame_t * 0.2)
		var suffix: String = "L" if float(side) < 0 else "R"

		var upper := _box("UpperPanel" + suffix, Vector3(panel_w, panel_h, panel_depth),
			Vector3(leaf_cx, opening_h - panel_gap - panel_h * 0.5, wall_depth * 0.08),
			CSGShape3D.OPERATION_UNION, mat_door)
		root.add_child(upper)

		var lower := _box("LowerPanel" + suffix, Vector3(panel_w, panel_h, panel_depth),
			Vector3(leaf_cx, panel_gap + panel_h * 0.5, wall_depth * 0.08),
			CSGShape3D.OPERATION_UNION, mat_door)
		root.add_child(lower)

	# Handles
	var handle_left := _cyl("HandleLeft", 0.015, 0.04,
		Vector3(cx - frame_t * 1.5, opening_h * 0.45, wall_depth * 0.12), 8,
		CSGShape3D.OPERATION_UNION, mat_metal)
	handle_left.rotation_degrees.x = 90.0
	root.add_child(handle_left)

	var handle_right := _cyl("HandleRight", 0.015, 0.04,
		Vector3(cx + frame_t * 1.5, opening_h * 0.45, wall_depth * 0.12), 8,
		CSGShape3D.OPERATION_UNION, mat_metal)
	handle_right.rotation_degrees.x = 90.0
	root.add_child(handle_right)

	return root


## Arched door: door with semicircular arch top.
static func arched_door(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("ArchedDoor")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.05)
	var margin_x: float = w * 0.12
	var opening_w: float = w - margin_x * 2.0
	var arch_r: float = opening_w * 0.5
	var rect_h: float = h * 0.92 - arch_r
	var cx := w * 0.5

	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))
	var mat_keystone := _M.stone(Color(0.82, 0.78, 0.72))
	var mat_door := _M.wood(Color(0.35, 0.25, 0.15))

	# Dark void behind door
	var void_rect := _box("DoorVoidRect", Vector3(opening_w, rect_h, 0.01),
		Vector3(cx, rect_h * 0.5, 0.03),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	root.add_child(void_rect)

	var void_arch := _cyl("DoorVoidArch", arch_r, 0.01,
		Vector3(cx, rect_h, 0.03), 24,
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	void_arch.rotation_degrees.x = 90.0
	root.add_child(void_arch)

	# Frame jambs
	var jamb_left := _box("JambLeft", Vector3(frame_t, rect_h, wall_depth * 0.3),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.5, rect_h * 0.5, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t, rect_h, wall_depth * 0.3),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.5, rect_h * 0.5, wall_depth * 0.15),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_right)

	# Keystone
	var keystone_h := arch_r * 0.25
	var keystone := _box("Keystone",
		Vector3(frame_t * 2.0, keystone_h, wall_depth * 0.35),
		Vector3(cx, rect_h + arch_r - keystone_h * 0.3, wall_depth * 0.18),
		CSGShape3D.OPERATION_UNION, mat_keystone)
	root.add_child(keystone)

	return root


## Portal: large arched entrance, wider proportions.
static func portal(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Portal")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var frame_t: float = p.get("frame_thickness", 0.06)
	var margin_x: float = w * 0.05
	var opening_w: float = w - margin_x * 2.0
	var arch_r: float = opening_w * 0.5
	var rect_h: float = h * 0.95 - arch_r
	var cx := w * 0.5

	var mat_frame := _M.stone(Color(0.75, 0.72, 0.66))
	var mat_keystone := _M.stone(Color(0.82, 0.78, 0.72))

	# Dark void behind portal
	var void_rect := _box("PortalVoidRect", Vector3(opening_w, rect_h, 0.01),
		Vector3(cx, rect_h * 0.5, 0.03),
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	root.add_child(void_rect)

	var void_arch_bg := _cyl("PortalVoidArch", arch_r, 0.01,
		Vector3(cx, rect_h, 0.03), 32,
		CSGShape3D.OPERATION_UNION, _M.stone(Color(0.08, 0.1, 0.15)))
	void_arch_bg.rotation_degrees.x = 90.0
	root.add_child(void_arch_bg)

	# Archivolt (decorative arch surround)
	var archivolt_t := frame_t * 2.0
	var archivolt := _cyl("Archivolt", arch_r + archivolt_t, archivolt_t,
		Vector3(cx, rect_h, wall_depth * 0.15), 32,
		CSGShape3D.OPERATION_UNION, mat_keystone)
	archivolt.rotation_degrees.x = 90.0
	root.add_child(archivolt)

	# Jambs (thicker)
	var jamb_left := _box("JambLeft", Vector3(frame_t * 1.5, rect_h, wall_depth * 0.4),
		Vector3(cx - opening_w * 0.5 - frame_t * 0.75, rect_h * 0.5, wall_depth * 0.2),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_left)

	var jamb_right := _box("JambRight", Vector3(frame_t * 1.5, rect_h, wall_depth * 0.4),
		Vector3(cx + opening_w * 0.5 + frame_t * 0.75, rect_h * 0.5, wall_depth * 0.2),
		CSGShape3D.OPERATION_UNION, mat_frame)
	root.add_child(jamb_right)

	# Keystone (larger)
	var keystone_h := arch_r * 0.3
	var keystone := _box("Keystone",
		Vector3(frame_t * 3.0, keystone_h, wall_depth * 0.4),
		Vector3(cx, rect_h + arch_r - keystone_h * 0.3, wall_depth * 0.2),
		CSGShape3D.OPERATION_UNION, mat_keystone)
	root.add_child(keystone)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"rect_window":
			return rect_window(w, h, params)
		"arched_window":
			return arched_window(w, h, params)
		"venetian_bifora":
			return venetian_bifora(w, h, params)
		"rose_window":
			return rose_window(w, h, params)
		"porthole":
			return porthole(w, h, params)
		"single_door":
			return single_door(w, h, params)
		"double_door":
			return double_door(w, h, params)
		"arched_door":
			return arched_door(w, h, params)
		"portal":
			return portal(w, h, params)
		_:
			push_warning("OpeningParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"rect_window", "arched_window", "venetian_bifora", "rose_window", "porthole",
		"single_door", "double_door", "arched_door", "portal",
	])
