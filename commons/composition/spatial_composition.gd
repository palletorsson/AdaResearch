## SpatialComposition — Reusable spatial composition system
## Maps grid positions to named zones. Content-agnostic.
## Used by PatternCompositor, FacadeBuilder, or any element-based layout.
##
## Inner classes: Region (hit-testing), Zone (region + properties)
## Static presets: carpet, facade, mosaic, quilt, tunnel

extends RefCounted

static var _script: GDScript

static func _make(w: int = 20, h: int = 20):
	if not _script:
		_script = load("res://commons/composition/spatial_composition.gd")
	var inst = _script.new(w, h)
	return inst

var width: int = 20
var height: int = 20
var zones: Array = []
var modifiers: Array = []

# ═══════════════════════════════════════════════════════════════════
# INNER CLASS: Region — spatial hit-testing primitive
# ═══════════════════════════════════════════════════════════════════

class Region:
	enum Type { FILL, BORDER, RECT, ELLIPSE, CORNERS, STRIPE, COLUMNS, RING }
	var type: int = Type.FILL
	var params: Dictionary = {}

	func contains(gx: int, gy: int, grid_w: int, grid_h: int) -> bool:
		match type:
			Type.FILL:
				return true
			Type.BORDER:
				var inset: int = params.get("inset", 0)
				var thickness: int = params.get("thickness", 1)
				var ol := inset; var ot := inset
				var orr := grid_w - 1 - inset; var ob := grid_h - 1 - inset
				var il := ol + thickness; var it := ot + thickness
				var ir := orr - thickness; var ib := ob - thickness
				var in_outer := gx >= ol and gx <= orr and gy >= ot and gy <= ob
				var in_inner := gx >= il and gx <= ir and gy >= it and gy <= ib
				return in_outer and not in_inner
			Type.RECT:
				var rx: int = params.get("x", 0); var ry: int = params.get("y", 0)
				var rw: int = params.get("w", 1); var rh: int = params.get("h", 1)
				return gx >= rx and gx < rx + rw and gy >= ry and gy < ry + rh
			Type.ELLIPSE:
				var cx: float = params.get("cx", float(grid_w) / 2.0)
				var cy: float = params.get("cy", float(grid_h) / 2.0)
				var rx: float = params.get("rx", 3.0); var ry: float = params.get("ry", 3.0)
				if rx <= 0.0 or ry <= 0.0: return false
				var dx := (float(gx) + 0.5 - cx) / rx
				var dy := (float(gy) + 0.5 - cy) / ry
				return (dx * dx + dy * dy) <= 1.0
			Type.CORNERS:
				var inset: int = params.get("inset", 0); var sz: int = params.get("size", 3)
				var tl := gx >= inset and gx < inset + sz and gy >= inset and gy < inset + sz
				var tr := gx >= grid_w - inset - sz and gx < grid_w - inset and gy >= inset and gy < inset + sz
				var bl := gx >= inset and gx < inset + sz and gy >= grid_h - inset - sz and gy < grid_h - inset
				var br := gx >= grid_w - inset - sz and gx < grid_w - inset and gy >= grid_h - inset - sz and gy < grid_h - inset
				return tl or tr or bl or br
			Type.STRIPE:
				var axis: String = params.get("axis", "x")
				var pos: int = params.get("position", 0); var thick: int = params.get("thickness", 1)
				if axis == "y": return gy >= pos and gy < pos + thick
				else: return gx >= pos and gx < pos + thick
			Type.COLUMNS:
				var positions: Array = params.get("x_positions", [])
				var col_w: int = params.get("width", 1)
				var y_start: int = params.get("y_start", 0); var y_end: int = params.get("y_end", grid_h)
				if gy < y_start or gy >= y_end: return false
				for px in positions:
					if gx >= int(px) and gx < int(px) + col_w: return true
				return false
			Type.RING:
				var cx: float = params.get("cx", float(grid_w) / 2.0)
				var cy: float = params.get("cy", float(grid_h) / 2.0)
				var inner_r: float = params.get("inner_radius", 2.0)
				var outer_r: float = params.get("outer_radius", 4.0)
				var dx := float(gx) + 0.5 - cx; var dy := float(gy) + 0.5 - cy
				var dist := sqrt(dx * dx + dy * dy)
				return dist >= inner_r and dist <= outer_r
		return false

	static func fill() -> Region:
		var r := Region.new(); r.type = Type.FILL; return r
	static func border(inset: int, thickness: int) -> Region:
		var r := Region.new(); r.type = Type.BORDER; r.params = {"inset": inset, "thickness": thickness}; return r
	static func make_rect(x: int, y: int, w: int, h: int) -> Region:
		var r := Region.new(); r.type = Type.RECT; r.params = {"x": x, "y": y, "w": w, "h": h}; return r
	static func ellipse(cx: float, cy: float, rx: float, ry: float) -> Region:
		var r := Region.new(); r.type = Type.ELLIPSE; r.params = {"cx": cx, "cy": cy, "rx": rx, "ry": ry}; return r
	static func corners(inset: int, size: int) -> Region:
		var r := Region.new(); r.type = Type.CORNERS; r.params = {"inset": inset, "size": size}; return r
	static func stripe(axis: String, position: int, thickness: int) -> Region:
		var r := Region.new(); r.type = Type.STRIPE; r.params = {"axis": axis, "position": position, "thickness": thickness}; return r
	static func columns(x_positions: Array, col_width: int, y_start: int, y_end: int) -> Region:
		var r := Region.new(); r.type = Type.COLUMNS; r.params = {"x_positions": x_positions, "width": col_width, "y_start": y_start, "y_end": y_end}; return r
	static func ring(cx: float, cy: float, inner_radius: float, outer_radius: float) -> Region:
		var r := Region.new(); r.type = Type.RING; r.params = {"cx": cx, "cy": cy, "inner_radius": inner_radius, "outer_radius": outer_radius}; return r

	func to_dict() -> Dictionary:
		return {"type": type, "params": params}
	static func from_dict(data: Dictionary) -> Region:
		var r := Region.new(); r.type = int(data.get("type", 0)); r.params = data.get("params", {}); return r

# ═══════════════════════════════════════════════════════════════════
# INNER CLASS: Zone — named region with arbitrary properties
# ═══════════════════════════════════════════════════════════════════

class Zone:
	var id: String = ""
	var region: Region = null
	var properties: Dictionary = {}
	var priority: int = 0

	func contains(gx: int, gy: int, grid_w: int, grid_h: int) -> bool:
		return region.contains(gx, gy, grid_w, grid_h) if region else false

	func to_dict() -> Dictionary:
		return {"id": id, "region": region.to_dict() if region else {}, "properties": properties, "priority": priority}
	static func from_dict(data: Dictionary) -> Zone:
		var z := Zone.new()
		z.id = str(data.get("id", ""))
		if data.has("region"): z.region = Region.from_dict(data["region"])
		z.properties = data.get("properties", {})
		z.priority = int(data.get("priority", 0))
		return z

# ═══════════════════════════════════════════════════════════════════
# CONSTRUCTOR & ZONE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

func _init(p_width: int = 20, p_height: int = 20) -> void:
	width = p_width; height = p_height

func add_zone(id: String, region: Region, properties: Dictionary = {}, priority: int = -1) -> Zone:
	if priority < 0: priority = zones.size()
	var z := Zone.new()
	z.id = id; z.region = region; z.properties = properties; z.priority = priority
	zones.append(z)
	return z

func get_zone_by_id(id: String):
	for z in zones:
		if z.id == id: return z
	return null

# ═══════════════════════════════════════════════════════════════════
# ZONE RESOLUTION
# ═══════════════════════════════════════════════════════════════════

func resolve_zone(gx: int, gy: int):
	var pos := _apply_modifiers(gx, gy)
	var best = null; var best_priority: int = -1
	for zone in zones:
		if zone.priority > best_priority and zone.contains(pos.x, pos.y, width, height):
			best = zone; best_priority = zone.priority
	return best

func resolve_zone_id(gx: int, gy: int) -> String:
	var zone = resolve_zone(gx, gy)
	return zone.id if zone else ""

func get_zone_grid() -> Array:
	var grid: Array = []
	for gy in height:
		var row: Array = []
		for gx in width: row.append(resolve_zone_id(gx, gy))
		grid.append(row)
	return grid

# ═══════════════════════════════════════════════════════════════════
# MODIFIERS
# ═══════════════════════════════════════════════════════════════════

func add_modifier(mod_type: String, params: Dictionary = {}) -> void:
	modifiers.append({"type": mod_type, "params": params})

func _apply_modifiers(gx: int, gy: int) -> Vector2i:
	var x := gx; var y := gy
	for mod in modifiers:
		var mt: String = mod.get("type", "")
		var p: Dictionary = mod.get("params", {})
		match mt:
			"mirror_x":
				var axis: int = p.get("axis", width / 2)
				if x >= axis: x = 2 * axis - x - 1
			"mirror_y":
				var axis: int = p.get("axis", height / 2)
				if y >= axis: y = 2 * axis - y - 1
			"rotate_180":
				x = width - 1 - x; y = height - 1 - y
			"kaleidoscope":
				if x >= width / 2: x = width - 1 - x
				if y >= height / 2: y = height - 1 - y
	return Vector2i(x, y)

# ═══════════════════════════════════════════════════════════════════
# SERIALIZATION
# ═══════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	var zone_dicts: Array = []
	for z in zones: zone_dicts.append(z.to_dict())
	return {"width": width, "height": height, "zones": zone_dicts, "modifiers": modifiers}

static func from_dict(data: Dictionary) :
	var comp = _make(int(data.get("width", 20)), int(data.get("height", 20)))
	for zd in data.get("zones", []): comp.zones.append(Zone.from_dict(zd))
	comp.modifiers = data.get("modifiers", [])
	return comp

# ═══════════════════════════════════════════════════════════════════
# PRESETS
# ═══════════════════════════════════════════════════════════════════

static func preset_carpet(w: int = 20, h: int = 20) :
	var comp = _make(w, h)
	comp.add_zone("field", Region.fill(), {}, 0)
	comp.add_zone("border_outer", Region.border(0, 2), {}, 10)
	comp.add_zone("gutter", Region.border(2, 1), {}, 20)
	comp.add_zone("border_inner", Region.border(3, 1), {}, 15)
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("medallion", Region.ellipse(cx, cy, float(w) * 0.2, float(h) * 0.2), {}, 30)
	comp.add_zone("corners", Region.corners(0, 3), {}, 25)
	comp.add_modifier("kaleidoscope")
	return comp

static func preset_facade(w: int = 15, h: int = 10) :
	var comp = _make(w, h)
	comp.add_zone("wall", Region.fill(), {}, 0)
	comp.add_zone("base", Region.make_rect(0, h - 2, w, 2), {}, 10)
	comp.add_zone("cornice", Region.make_rect(0, 0, w, 1), {}, 15)
	comp.add_zone("frieze", Region.make_rect(0, 1, w, 1), {}, 12)
	var col_spacing := w / 4
	var col_positions: Array = []
	for i in range(1, 4): col_positions.append(i * col_spacing)
	comp.add_zone("columns", Region.columns(col_positions, 1, 2, h - 2), {}, 20)
	for i in range(4):
		var wx := i * col_spacing + 1
		if wx + 2 < w:
			comp.add_zone("window_%d" % i, Region.make_rect(wx, 3, 2, 2), {"window_index": i}, 25)
	comp.add_zone("door", Region.make_rect(w / 2 - 1, h - 4, 2, 4), {}, 30)
	comp.add_modifier("mirror_x")
	return comp

static func preset_mosaic(w: int = 16, h: int = 16) :
	var comp = _make(w, h)
	comp.add_zone("background", Region.fill(), {}, 0)
	comp.add_zone("border", Region.border(0, 1), {}, 10)
	var panel_size := 3; var gap := 1; var idx := 0; var py := 2
	while py + panel_size <= h - 2:
		var px := 2
		while px + panel_size <= w - 2:
			comp.add_zone("panel_%d" % idx, Region.make_rect(px, py, panel_size, panel_size), {"panel_index": idx}, 20)
			idx += 1; px += panel_size + gap
		py += panel_size + gap
	return comp

static func preset_quilt(w: int = 16, h: int = 16) :
	var comp = _make(w, h)
	comp.add_zone("sashing", Region.fill(), {}, 0)
	comp.add_zone("border", Region.border(0, 1), {}, 10)
	var block_size := 3; var step := block_size + 1; var idx := 0; var by := 2
	while by + block_size <= h - 2:
		var bx := 2
		while bx + block_size <= w - 2:
			var bt := "block_a" if (idx % 2) == 0 else "block_b"
			comp.add_zone("%s_%d" % [bt, idx], Region.make_rect(bx, by, block_size, block_size), {"block_type": bt, "block_index": idx}, 20)
			idx += 1; bx += step
		by += step
	return comp

static func get_preset(preset_name: String, w: int = 20, h: int = 20) :
	match preset_name.to_lower():
		"carpet": return preset_carpet(w, h)
		"facade": return preset_facade(w, h)
		"mosaic": return preset_mosaic(w, h)
		"quilt": return preset_quilt(w, h)
		_: return preset_carpet(w, h)
