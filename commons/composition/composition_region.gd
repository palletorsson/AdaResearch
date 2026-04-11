## CompositionRegion
## A spatial region primitive used for zone hit-testing.
## Content-agnostic — just answers "does this cell belong to this region?"
##
## Region types:
##   FILL     — covers everything (background/default zone)
##   BORDER   — rectangular ring at inset with thickness
##   RECT     — arbitrary rectangle
##   ELLIPSE  — elliptical area
##   CORNERS  — corner squares within a border
##   STRIPE   — horizontal or vertical band
##   COLUMNS  — repeating vertical strips
##   RING     — circular ring (annulus)

class_name CompositionRegion extends RefCounted

enum Type { FILL, BORDER, RECT, ELLIPSE, CORNERS, STRIPE, COLUMNS, RING }

var type: Type = Type.FILL
var params: Dictionary = {}

# ═══════════════════════════════════════════════════════════════════
# HIT TEST — does (gx, gy) fall within this region?
# ═══════════════════════════════════════════════════════════════════

func contains(gx: int, gy: int, grid_w: int, grid_h: int) -> bool:
	match type:
		Type.FILL:
			return true

		Type.BORDER:
			var inset: int = params.get("inset", 0)
			var thickness: int = params.get("thickness", 1)
			var outer_left := inset
			var outer_top := inset
			var outer_right := grid_w - 1 - inset
			var outer_bottom := grid_h - 1 - inset
			var inner_left := outer_left + thickness
			var inner_top := outer_top + thickness
			var inner_right := outer_right - thickness
			var inner_bottom := outer_bottom - thickness
			# Inside outer rect but outside inner rect
			var in_outer := gx >= outer_left and gx <= outer_right and gy >= outer_top and gy <= outer_bottom
			var in_inner := gx >= inner_left and gx <= inner_right and gy >= inner_top and gy <= inner_bottom
			return in_outer and not in_inner

		Type.RECT:
			var rx: int = params.get("x", 0)
			var ry: int = params.get("y", 0)
			var rw: int = params.get("w", 1)
			var rh: int = params.get("h", 1)
			return gx >= rx and gx < rx + rw and gy >= ry and gy < ry + rh

		Type.ELLIPSE:
			var cx: float = params.get("cx", float(grid_w) / 2.0)
			var cy: float = params.get("cy", float(grid_h) / 2.0)
			var rx: float = params.get("rx", 3.0)
			var ry: float = params.get("ry", 3.0)
			if rx <= 0.0 or ry <= 0.0:
				return false
			var dx := (float(gx) + 0.5 - cx) / rx
			var dy := (float(gy) + 0.5 - cy) / ry
			return (dx * dx + dy * dy) <= 1.0

		Type.CORNERS:
			var inset: int = params.get("inset", 0)
			var sz: int = params.get("size", 3)
			# Four corner squares
			var tl := gx >= inset and gx < inset + sz and gy >= inset and gy < inset + sz
			var tr := gx >= grid_w - inset - sz and gx < grid_w - inset and gy >= inset and gy < inset + sz
			var bl := gx >= inset and gx < inset + sz and gy >= grid_h - inset - sz and gy < grid_h - inset
			var br := gx >= grid_w - inset - sz and gx < grid_w - inset and gy >= grid_h - inset - sz and gy < grid_h - inset
			return tl or tr or bl or br

		Type.STRIPE:
			var axis: String = params.get("axis", "x")  # "x" = vertical stripe, "y" = horizontal
			var pos: int = params.get("position", 0)
			var thick: int = params.get("thickness", 1)
			if axis == "y":
				return gy >= pos and gy < pos + thick
			else:
				return gx >= pos and gx < pos + thick

		Type.COLUMNS:
			var positions: Array = params.get("x_positions", [])
			var col_w: int = params.get("width", 1)
			var y_start: int = params.get("y_start", 0)
			var y_end: int = params.get("y_end", grid_h)
			if gy < y_start or gy >= y_end:
				return false
			for px in positions:
				if gx >= int(px) and gx < int(px) + col_w:
					return true
			return false

		Type.RING:
			var cx: float = params.get("cx", float(grid_w) / 2.0)
			var cy: float = params.get("cy", float(grid_h) / 2.0)
			var inner_r: float = params.get("inner_radius", 2.0)
			var outer_r: float = params.get("outer_radius", 4.0)
			var dx := float(gx) + 0.5 - cx
			var dy := float(gy) + 0.5 - cy
			var dist := sqrt(dx * dx + dy * dy)
			return dist >= inner_r and dist <= outer_r

	return false

# ═══════════════════════════════════════════════════════════════════
# FACTORY METHODS — convenient constructors
# ═══════════════════════════════════════════════════════════════════

static func fill() -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.FILL
	return r

static func border(inset: int, thickness: int) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.BORDER
	r.params = {"inset": inset, "thickness": thickness}
	return r

static func rect(x: int, y: int, w: int, h: int) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.RECT
	r.params = {"x": x, "y": y, "w": w, "h": h}
	return r

static func ellipse(cx: float, cy: float, rx: float, ry: float) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.ELLIPSE
	r.params = {"cx": cx, "cy": cy, "rx": rx, "ry": ry}
	return r

static func corners(inset: int, size: int) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.CORNERS
	r.params = {"inset": inset, "size": size}
	return r

static func stripe(axis: String, position: int, thickness: int) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.STRIPE
	r.params = {"axis": axis, "position": position, "thickness": thickness}
	return r

static func columns(x_positions: Array, width: int, y_start: int, y_end: int) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.COLUMNS
	r.params = {"x_positions": x_positions, "width": width, "y_start": y_start, "y_end": y_end}
	return r

static func ring(cx: float, cy: float, inner_radius: float, outer_radius: float) -> CompositionRegion:
	var r := CompositionRegion.new()
	r.type = Type.RING
	r.params = {"cx": cx, "cy": cy, "inner_radius": inner_radius, "outer_radius": outer_radius}
	return r

# ═══════════════════════════════════════════════════════════════════
# SERIALIZATION
# ═══════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	return {"type": Type.keys()[type].to_lower(), "params": params}

static func from_dict(data: Dictionary) -> CompositionRegion:
	var r := CompositionRegion.new()
	var type_str: String = str(data.get("type", "fill")).to_upper()
	for i in Type.size():
		if Type.keys()[i] == type_str:
			r.type = i as Type
			break
	r.params = data.get("params", {})
	return r
