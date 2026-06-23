extends Node3D
class_name StationBarrier

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the GRID-MODULAR front barrier of a curation station — a length_cells × 1 m (per cell) run of posts with a low panel or rail between them and a caution-striped base, that marks the front edge of the stage: stand back, look, do not cross. Origin at the floor centre; faces +Z.
# desire: to draw the line a viewer stops at — to turn an open stage into a presented one with a threshold, the way a museum rope or a lab barrier says "the exhibit begins here".
# critical_parameter: length_cells + style — how wide the threshold is and whether it reads as a solid panel (lab) or an open rail (gallery rope).
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a solid panel reads "contained, lab"; a rail reads "gallery, look-but"; brand text + stripes read "official, keep clear"; posts on every cell read "modular, built to a grid".
# needs: posts on every cell boundary + foot plates [present]; a panel or rail spanning each bay [present]; optional caution base + 2D-in-3D brand text [optional].
# relationships: the threshold sibling of [[station_stage]] (the front edge it guards); shares the HangarKit look with the packaging barrier fence but tiles on the grid; placed at the stage front by [[curation_station]].
# truth: a barrier is the smallest grammar of presentation: it says "this side is yours, that side is the work". To draw the line is to make a thing an exhibit.

@export_group("Grid")
@export var length_cells: int = 4
@export_group("Dimensions")
@export var height: float = 1.0
@export_group("Style")
## "panel" (solid bays) | "rail" (open horizontal rails).
@export var style: String = "panel"
@export var hazard_base: bool = true
## 2D-in-3D brand text across the front (empty = none).
@export var brand_text: String = ""
@export_group("Surface")
@export var wear: float = 0.08
@export var three_bar: bool = true
@export var grime: bool = true
@export_group("Color")
@export var panel_color: Color = Color(0.81, 0.79, 0.75)
@export var post_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const POST_W := 0.1
const PANEL_T := 0.05
const FOOT_W := 0.24

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_metadata_overrides() -> void:
	if has_meta("config_length_cells"): length_cells = int(str(get_meta("config_length_cells")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_style"): style = str(get_meta("config_style")).to_lower()
	if has_meta("config_hazard_base"): hazard_base = _b(get_meta("config_hazard_base"))
	if has_meta("config_brand_text"): brand_text = str(get_meta("config_brand_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_post_color"): post_color = _pc(str(get_meta("config_post_color")), post_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)

func _build() -> void:
	_built = true
	var n: int = maxi(length_cells, 1)
	var w: float = float(n) * CELL
	var h: float = maxf(height, 0.4)
	var post_mat := _mat(post_color.darkened(0.04))
	var foot_mat := HangarKit.worn_metal(post_color)

	# Posts + feet on every cell boundary.
	for i in range(n + 1):
		var x: float = -w * 0.5 + float(i) * CELL
		add_child(_box(Vector3(x, h * 0.5, 0), Vector3(POST_W, h, POST_W), post_mat))
		add_child(_box(Vector3(x, 0.015, 0), Vector3(FOOT_W, 0.03, FOOT_W), foot_mat))
		# accent cap on each post
		add_child(_box(Vector3(x, h - 0.03, 0), Vector3(POST_W + 0.03, 0.05, POST_W + 0.03), _emi(accent_color, 0.5)))

	# Per-bay fill.
	var pmat := _mat(panel_color)
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		if style == "rail":
			for fy in [0.45, 0.85]:
				add_child(_box(Vector3(cx, h * fy, 0), Vector3(CELL - POST_W, 0.05, 0.04), pmat))
		else:
			add_child(_box(Vector3(cx, h * 0.46, 0), Vector3(CELL - POST_W, h * 0.7, PANEL_T), pmat))

	if hazard_base and style == "panel":
		add_child(_box(Vector3(0, 0.1, PANEL_T * 0.5 + 0.005), Vector3(w * 0.98, 0.14, 0.02), HangarKit.striped_mat()))
	if three_bar and style == "panel":
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.5, 1.0), 0.04, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
		bar.position = Vector3(0, h * 0.66, PANEL_T * 0.5 + 0.02)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(w, 0.05, PANEL_T * 0.5 + 0.004, panel_color))
	if brand_text.strip_edges() != "" and style == "panel":
		var plate: MeshInstance3D = BakedText.make_panel_mesh(brand_text.to_upper(), Color(0.10, 0.11, 0.13), Color(0.93, 0.91, 0.86), Vector2(minf(w * 0.55, 1.4), 0.16), 1400, true)
		if plate:
			plate.position = Vector3(0, h * 0.5, PANEL_T * 0.5 + 0.03)
			add_child(plate)

func _mat(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)

func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)

func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi

func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]

func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
