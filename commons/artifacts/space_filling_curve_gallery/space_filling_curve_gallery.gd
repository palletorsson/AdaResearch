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


func _generate_texture() -> void:
	var image := Image.create(IMAGE_W, IMAGE_H, false, Image.FORMAT_RGBA8)
	image.fill(BG_COLOR)

	# Draw separator lines between panels
	for y in range(IMAGE_H):
		image.set_pixel(PANEL_RES, y, Color(0.2, 0.2, 0.25))
		image.set_pixel(PANEL_RES * 2, y, Color(0.2, 0.2, 0.25))

	# Generate and draw each curve
	var hilbert_pts := _generate_lsystem_curve(_hilbert_rules(), 4, 90.0)
	_draw_curve(image, hilbert_pts, 0, HILBERT_COLOR)

	var peano_pts := _generate_lsystem_curve(_peano_rules(), 3, 90.0)
	_draw_curve(image, peano_pts, PANEL_RES, PEANO_COLOR)

	var moore_pts := _generate_lsystem_curve(_moore_rules(), 3, 90.0)
	_draw_curve(image, moore_pts, PANEL_RES * 2, MOORE_COLOR)

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


func _draw_curve(image: Image, points: PackedVector2Array, x_offset: int, color: Color) -> void:
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

		_draw_line(image, px0, py0, px1, py1, color)


func _draw_line(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy
	var cx := x0
	var cy := y0
	var half_t: int = LINE_THICKNESS / 2

	while true:
		# Draw thick pixel (LINE_THICKNESS x LINE_THICKNESS block)
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
	var names := ["Hilbert", "Peano", "Moore"]
	var colors := [HILBERT_COLOR, PEANO_COLOR, MOORE_COLOR]
	var panel_width := quad_size.x / 3.0

	for i in range(3):
		var label := Label3D.new()
		label.text = names[i]
		label.font_size = 64
		label.pixel_size = 0.003
		label.modulate = colors[i]
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		# Position above the floor quad, centered over each panel
		var x_pos := -quad_size.x * 0.5 + panel_width * (i + 0.5)
		label.position = Vector3(x_pos, 0.01, -quad_size.y * 0.5 - 0.02)
		label.rotation_degrees.x = -90
		add_child(label)


func apply_grid_config(config_data: Dictionary) -> void:
	pass
