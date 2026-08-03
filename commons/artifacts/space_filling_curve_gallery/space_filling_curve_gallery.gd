extends Node3D
class_name SpaceFillingCurveGallery

# @identity
# essence: three L-systems (Hilbert, Peano, Moore) → turtle → pixel path → floor triptych
# desire: To lay three space-filling curves side by side on the floor — walk over them, compare their strategies for visiting every point
# critical_parameter: iteration count per curve — controls density and visual complexity of each panel
# triggers: Each curve fills its panel differently — Hilbert (recursive quadrants), Peano (9-fold), Moore (closed loop Hilbert variant)
# emerges: Visual comparison reveals that different grammars can achieve the same goal (space-filling) through different strategies
# needs: VR iteration controls [missing], Label3D [has per panel]
# relationships: Pairs with Hilbert3D (2D gallery vs 3D walkthrough). Feeds into LSystems_Grammars_And_Curves.
# truth: Three grammars, one goal — every point touched, no crossing, each path a different philosophy of exhaustion.

## Space-filling curve triptych — Hilbert, Peano, and Moore curves side by side
## on a floor-lying QuadMesh, generated via L-system rules and turtle graphics.

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(3.2, 1.2)

# ── DNA axes (stage 2) ──────────────────────────────────────────────────────
## comparison — what the triptych is a gallery OF.
##   grammars: three grammars at one depth, side by side (variety)
##   depths:   one grammar (Hilbert) at three growing depths (growth)
##   overlay:  all three superimposed in a single frame (they share the plane)
##   single:   one curve alone, no comparison at all
@export_enum("grammars", "depths", "overlay", "single") var comparison: String = "grammars"

## depth — how far the exhaustion is carried. Shifts every panel's iteration
## count together, so the comparison stays a comparison.
@export_enum("sketch", "sparse", "standard", "fine") var depth: String = "standard"

const PANEL_RES: int = 512
const IMAGE_W: int = PANEL_RES * 3  # 1536 pixels wide (3 panels)
const IMAGE_H: int = PANEL_RES
const BG_COLOR: Color = Color(0.04, 0.04, 0.06)
const HILBERT_COLOR: Color = Color(0.0, 0.85, 0.9)   # Cyan
const PEANO_COLOR: Color = Color(0.9, 0.15, 0.85)     # Magenta
const MOORE_COLOR: Color = Color(0.95, 0.85, 0.1)     # Yellow
const MARGIN: int = 12
const LINE_THICKNESS: int = 3  # Draw lines 3 pixels wide

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _labels: Array[Label3D] = []


func _ready() -> void:
	_build_floor_quad()
	_generate_texture()
	_add_labels()


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "CurveGalleryMesh"
	var quad := QuadMesh.new()
	quad.size = quad_size
	_mesh_inst.mesh = quad
	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.85
	_material.metallic = 0.0
	_material.emission_enabled = true
	_material.emission_energy_multiplier = 0.6
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)


# --- Panel plan (the `comparison` and `depth` axes live here) ---------------

## Iteration shift applied to every panel.
func _depth_offset() -> int:
	match depth:
		"sketch":
			return -2
		"sparse":
			return -1
		"fine":
			return 1
		_:
			return 0


## Line width in pixels. At `fine` the cells get small enough that a 3px stroke
## closes the gaps and the curve reads as a filled block, so it thins to 1.
func _stroke() -> int:
	if depth == "fine":
		return 1
	return LINE_THICKNESS


## The panels to draw: name, grammar, iteration count, colour, x offset.
func _panels() -> Array:
	var off: int = _depth_offset()
	var out: Array = []
	match comparison:
		"depths":
			var base: Array = [2, 3, 4]
			for i in range(3):
				var it: int = maxi(1, int(base[i]) + off)
				out.append({
					"name": "Hilbert n=%d" % it,
					"rules": _hilbert_rules(),
					"iterations": it,
					"color": HILBERT_COLOR,
					"x_offset": PANEL_RES * i,
				})
		"overlay":
			out.append({"name": "Hilbert", "rules": _hilbert_rules(),
				"iterations": maxi(1, 4 + off), "color": HILBERT_COLOR, "x_offset": PANEL_RES})
			out.append({"name": "Peano", "rules": _peano_rules(),
				"iterations": maxi(1, 3 + off), "color": PEANO_COLOR, "x_offset": PANEL_RES})
			out.append({"name": "Moore", "rules": _moore_rules(),
				"iterations": maxi(1, 3 + off), "color": MOORE_COLOR, "x_offset": PANEL_RES})
		"single":
			out.append({"name": "Hilbert", "rules": _hilbert_rules(),
				"iterations": maxi(1, 4 + off), "color": HILBERT_COLOR, "x_offset": PANEL_RES})
		_:
			out.append({"name": "Hilbert", "rules": _hilbert_rules(),
				"iterations": maxi(1, 4 + off), "color": HILBERT_COLOR, "x_offset": 0})
			out.append({"name": "Peano", "rules": _peano_rules(),
				"iterations": maxi(1, 3 + off), "color": PEANO_COLOR, "x_offset": PANEL_RES})
			out.append({"name": "Moore", "rules": _moore_rules(),
				"iterations": maxi(1, 3 + off), "color": MOORE_COLOR, "x_offset": PANEL_RES * 2})
	return out


## Three panels means separators; a single shared frame means none.
func _is_triptych() -> bool:
	return comparison == "grammars" or comparison == "depths"


func _generate_texture() -> void:
	var image := Image.create(IMAGE_W, IMAGE_H, false, Image.FORMAT_RGBA8)
	image.fill(BG_COLOR)

	# Draw separator lines between panels
	if _is_triptych():
		for y in range(IMAGE_H):
			image.set_pixel(PANEL_RES, y, Color(0.2, 0.2, 0.25))
			image.set_pixel(PANEL_RES * 2, y, Color(0.2, 0.2, 0.25))

	# Generate and draw each curve
	var stroke: int = _stroke()
	for panel in _panels():
		var iterations: int = int(panel["iterations"])
		var x_offset: int = int(panel["x_offset"])
		var color: Color = panel["color"]
		var rules_def: Dictionary = panel["rules"]
		var pts := _generate_lsystem_curve(rules_def, iterations, 90.0)
		_draw_curve(image, pts, x_offset, color, stroke)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture
	_material.emission_texture = texture


# --- L-System definitions ---

func _hilbert_rules() -> Dictionary:
	return {
		"axiom": "A",
		"rules": {"A": "-BF+AFA+FB-", "B": "+AF-BFB-FA+"},
	}

func _peano_rules() -> Dictionary:
	return {
		"axiom": "X",
		"rules": {
			"X": "XFYFX+F+YFXFY-F-XFYFX",
			"Y": "YFXFY-F-XFYFX+F+YFXFY",
		},
	}

func _moore_rules() -> Dictionary:
	return {
		"axiom": "LFL+F+LFL",
		"rules": {"L": "-RF+LFL+FR-", "R": "+LF-RFR-FL+"},
	}


# --- L-System expansion + turtle ---

func _generate_lsystem_curve(def: Dictionary, iterations: int, angle_deg: float) -> PackedVector2Array:
	# Expand L-system string
	var current: String = def["axiom"]
	var rules: Dictionary = def["rules"]
	for _i in range(iterations):
		var next := ""
		for ch_idx in range(current.length()):
			var ch := current[ch_idx]
			if rules.has(ch):
				next += rules[ch]
			else:
				next += ch
		current = next

	# Turtle interpretation — collect points where F moves
	var points := PackedVector2Array()
	var x := 0.0
	var y := 0.0
	var heading := 0.0  # degrees, 0 = right
	var angle_step := angle_deg

	points.append(Vector2(x, y))

	for ch_idx in range(current.length()):
		var ch := current[ch_idx]
		match ch:
			"F":
				x += cos(deg_to_rad(heading))
				y += sin(deg_to_rad(heading))
				points.append(Vector2(x, y))
			"+":
				heading += angle_step
			"-":
				heading -= angle_step

	return points


func _draw_curve(image: Image, points: PackedVector2Array, x_offset: int, color: Color,
		thickness: int = LINE_THICKNESS) -> void:
	if points.size() < 2:
		return

	# Find bounding box
	var min_pt := points[0]
	var max_pt := points[0]
	for pt in points:
		min_pt.x = minf(min_pt.x, pt.x)
		min_pt.y = minf(min_pt.y, pt.y)
		max_pt.x = maxf(max_pt.x, pt.x)
		max_pt.y = maxf(max_pt.y, pt.y)

	var range_x := max_pt.x - min_pt.x
	var range_y := max_pt.y - min_pt.y
	var range_max := maxf(range_x, range_y)
	if range_max < 0.001:
		return

	var draw_size := PANEL_RES - MARGIN * 2
	var scale_factor := float(draw_size) / range_max

	# Center the curve within the panel
	var offset_x := MARGIN + (draw_size - range_x * scale_factor) * 0.5
	var offset_y := MARGIN + (draw_size - range_y * scale_factor) * 0.5

	# Draw line segments using Bresenham
	for i in range(points.size() - 1):
		var p0 := points[i]
		var p1 := points[i + 1]

		var px0 := int((p0.x - min_pt.x) * scale_factor + offset_x) + x_offset
		var py0 := int((p0.y - min_pt.y) * scale_factor + offset_y)
		var px1 := int((p1.x - min_pt.x) * scale_factor + offset_x) + x_offset
		var py1 := int((p1.y - min_pt.y) * scale_factor + offset_y)

		_draw_line(image, px0, py0, px1, py1, color, thickness)


func _draw_line(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color,
		thickness: int = LINE_THICKNESS) -> void:
	var dx := absi(x1 - x0)
	var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy
	var cx := x0
	var cy := y0
	var half_t: int = thickness / 2

	while true:
		# Draw thick pixel (thickness x thickness block)
		for ox in range(-half_t, half_t + 1):
			for oy in range(-half_t, half_t + 1):
				var px: int = cx + ox
				var py: int = cy + oy
				if px >= 0 and px < IMAGE_W and py >= 0 and py < IMAGE_H:
					image.set_pixel(px, py, color)
		if cx == x1 and cy == y1:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			cx += sx
		if e2 < dx:
			err += dx
			cy += sy


func _add_labels() -> void:
	var panels := _panels()
	# When several curves share one frame their captions stack in front of it
	# instead of sitting side by side.
	var shared_frame: bool = not _is_triptych() and panels.size() > 1

	for i in range(panels.size()):
		var panel: Dictionary = panels[i]
		var label := Label3D.new()
		label.text = str(panel["name"])
		label.font_size = 64
		label.pixel_size = 0.003
		label.modulate = panel["color"]
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		# Position above the floor quad, centered over the panel it names.
		var centre_px: float = float(int(panel["x_offset"])) + float(PANEL_RES) * 0.5
		var x_pos: float = -quad_size.x * 0.5 + centre_px / float(IMAGE_W) * quad_size.x
		var z_pos: float = -quad_size.y * 0.5 - 0.02
		if shared_frame:
			z_pos -= float(i) * 0.16
		label.position = Vector3(x_pos, 0.01, z_pos)
		label.rotation_degrees.x = -90
		add_child(label)
		_labels.append(label)


## Redraw the texture and re-caption. Only called when a value actually changed
## and only after _ready has built once — never on a plain placement.
func _rebuild() -> void:
	if _mesh_inst != null and _mesh_inst.mesh is QuadMesh:
		var quad: QuadMesh = _mesh_inst.mesh
		quad.size = quad_size
	_generate_texture()
	for lbl in _labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_labels.clear()
	_add_labels()


func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("comparison"):
		var c: String = str(config_data["comparison"])
		if c in ["grammars", "depths", "overlay", "single"] and c != comparison:
			comparison = c
			changed = true
	if config_data.has("depth"):
		var d: String = str(config_data["depth"])
		if d in ["sketch", "sparse", "standard", "fine"] and d != depth:
			depth = d
			changed = true
	if config_data.has("quad_size") and config_data["quad_size"] is Vector2:
		var qs: Vector2 = config_data["quad_size"]
		if qs != quad_size:
			quad_size = qs
			changed = true

	if changed and _mesh_inst != null:
		_rebuild()
