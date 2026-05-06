class_name ShutterParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade shutter parts — louvered and paneled shutters flanking a window void.
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


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


# ==========================================================================
# SHUTTERS
# ==========================================================================

## Louvered shutter: pair of shutters with angled slat louvers flanking window void.
static func louvered_shutter(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("LouveredShutter")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var shutter_w: float = w * 0.2
	var shutter_depth: float = 0.02
	var margin_x: float = w * 0.12
	var margin_y: float = h * 0.1
	var opening_h: float = h - margin_y * 2.0
	var cx := w * 0.5

	# Left shutter panel
	var _mat_frame := _M.wood(Color(0.28, 0.38, 0.28))
	var _mat_slat := _M.wood(Color(0.25, 0.35, 0.25))
	var left_x := margin_x - shutter_w * 0.5
	var left_frame := _box("LeftFrame",
		Vector3(shutter_w, opening_h, shutter_depth),
		Vector3(left_x, h * 0.5, wall_depth * 0.5 + shutter_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_frame)
	root.add_child(left_frame)

	# Louver slats on left shutter
	var slat_count: int = p.get("slat_count", clampi(int(opening_h / 0.04), 8, 25))
	var slat_spacing := opening_h / float(slat_count)
	var slat_h := slat_spacing * 0.6
	var slat_depth := shutter_depth * 0.5

	for i in range(slat_count):
		var sy := margin_y + slat_spacing * (float(i) + 0.5)
		var slat_l := _box("LeftSlat_%d" % i,
			Vector3(shutter_w * 0.85, slat_h, slat_depth),
			Vector3(left_x, sy, wall_depth * 0.5 + shutter_depth + slat_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_slat)
		slat_l.rotation_degrees.x = 30.0
		root.add_child(slat_l)

	# Right shutter panel
	var right_x := w - margin_x + shutter_w * 0.5
	var right_frame := _box("RightFrame",
		Vector3(shutter_w, opening_h, shutter_depth),
		Vector3(right_x, h * 0.5, wall_depth * 0.5 + shutter_depth * 0.5),
		CSGShape3D.OPERATION_UNION, _mat_frame)
	root.add_child(right_frame)

	# Louver slats on right shutter
	for i in range(slat_count):
		var sy := margin_y + slat_spacing * (float(i) + 0.5)
		var slat_r := _box("RightSlat_%d" % i,
			Vector3(shutter_w * 0.85, slat_h, slat_depth),
			Vector3(right_x, sy, wall_depth * 0.5 + shutter_depth + slat_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_slat)
		slat_r.rotation_degrees.x = 30.0
		root.add_child(slat_r)

	return root


## Paneled shutter: pair of solid-panel shutters flanking window void.
static func paneled_shutter(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PaneledShutter")
	var wall_depth: float = p.get("wall_depth", 0.25)
	var shutter_w: float = w * 0.2
	var shutter_depth: float = 0.025
	var margin_x: float = w * 0.12
	var margin_y: float = h * 0.1
	var opening_h: float = h - margin_y * 2.0
	var panel_gap := opening_h * 0.04
	var panel_h := (opening_h - panel_gap * 3.0) * 0.5
	var panel_inset := 0.008
	var cx := w * 0.5

	var _mat_pframe := _M.wood(Color(0.28, 0.38, 0.28))
	var _mat_panel := _M.wood(Color(0.30, 0.40, 0.30))
	for side in [-1.0, 1.0]:
		var suffix: String = "Left" if float(side) < 0.0 else "Right"
		var sx: float
		if float(side) < 0.0:
			sx = margin_x - shutter_w * 0.5
		else:
			sx = w - margin_x + shutter_w * 0.5

		# Shutter frame
		var frame := _box(suffix + "Frame",
			Vector3(shutter_w, opening_h, shutter_depth),
			Vector3(sx, h * 0.5, wall_depth * 0.5 + shutter_depth * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_pframe)
		root.add_child(frame)

		# Upper panel (recessed)
		var upper := _box(suffix + "UpperPanel",
			Vector3(shutter_w * 0.8, panel_h, panel_inset),
			Vector3(sx, margin_y + panel_gap * 2.0 + panel_h * 1.5,
				wall_depth * 0.5 + shutter_depth + panel_inset * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_panel)
		root.add_child(upper)

		# Lower panel (recessed)
		var lower := _box(suffix + "LowerPanel",
			Vector3(shutter_w * 0.8, panel_h, panel_inset),
			Vector3(sx, margin_y + panel_gap + panel_h * 0.5,
				wall_depth * 0.5 + shutter_depth + panel_inset * 0.5),
			CSGShape3D.OPERATION_UNION, _mat_panel)
		root.add_child(lower)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"louvered_shutter":
			return louvered_shutter(w, h, params)
		"paneled_shutter":
			return paneled_shutter(w, h, params)
		_:
			push_warning("ShutterParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"louvered_shutter", "paneled_shutter",
	])
