extends Node3D
class_name StationStage

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR raised deck a curated set stands ON — a low painted-metal platform exactly width_cells × depth_cells metres (1 m per cell), with a panelled skirt and a caution-striped front lip. Origin at the floor centre; the walkable cap sits at step_height.
# desire: to lift a set a hand's-height off the floor so it reads as staged, presented, on display — not scattered on the ground; and to do it on whole cells so plinths land on grid centres.
# critical_parameter: width_cells × depth_cells — the footprint of the stage, which the composer sizes to hold N plinths plus margin, always whole cells.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new footprint.
# emerges: a low solid deck reads "stand here"; the striped front lip reads "the front, mind the step"; a grate top reads "serviced floor"; the skirt panels read "built, modular".
# needs: a deck cap at step_height [present]; a skirt body below it [present]; a hazard front lip + corner foot plates [present]; optional grate top [optional].
# relationships: the floor sibling of [[station_wall]] (stand ON this, back AGAINST that); holds [[station_plinth]] columns; assembled by [[curation_station]]. Shares the HangarKit look with [[hangar_step_base]] but tiles on the grid.
# truth: to stage a thing is to raise it a little and admit you are presenting it. The step is the smallest honest pedestal — height enough to mean "look", low enough to step onto.

@export_group("Grid")
## Stage width in 1 m cells (X).
@export var width_cells: int = 5
## Stage depth in 1 m cells (Z).
@export var depth_cells: int = 3

@export_group("Dimensions")
## Step rise — the deck height above the floor (clamped ≤ 0.35 m, a single comfortable step).
@export var step_height: float = 0.22

@export_group("Style")
## "solid" | "grate" walkable cap.
@export var top_style: String = "solid"
## Caution stripe along the front (+Z) lip.
@export var hazard_edge: bool = true
## A slim emissive accent line under the front lip.
@export var edge_light: bool = false

@export_group("Surface")
@export var stencil_text: String = "STAGE-01"
@export var wear: float = 0.08
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const TOP_THICK := 0.05
const SKIRT_INSET := 0.07

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
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))
	if has_meta("config_depth_cells"): depth_cells = int(str(get_meta("config_depth_cells")))
	if has_meta("config_step_height"): step_height = float(str(get_meta("config_step_height")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_hazard_edge"): hazard_edge = _b(get_meta("config_hazard_edge"))
	if has_meta("config_edge_light"): edge_light = _b(get_meta("config_edge_light"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var w: float = float(maxi(width_cells, 1)) * CELL
	var d: float = float(maxi(depth_cells, 1)) * CELL
	var sh: float = clampf(step_height, 0.08, 0.35)
	var body_mat := _mat(body_color)
	var cap_mat := _mat(body_color.lightened(0.05))

	# Skirt body — the bulk below the deck, slightly inset so the cap overhangs.
	add_child(_box(Vector3(0, (sh - TOP_THICK) * 0.5, 0),
		Vector3(w - SKIRT_INSET * 2.0, sh - TOP_THICK, d - SKIRT_INSET * 2.0), body_mat))

	# Walkable cap — overhangs the skirt; top sits exactly at step_height.
	if top_style == "grate":
		_build_grate(w, d, sh)
	else:
		add_child(_box(Vector3(0, sh - TOP_THICK * 0.5, 0), Vector3(w, TOP_THICK, d), cap_mat))

	# Skirt panels on the four faces — the modular built read.
	_build_skirt_panels(w, d, sh)

	# Corner foot plates.
	var fmat := HangarKit.worn_metal(panel_color)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_box(Vector3(sx * (w * 0.5 - 0.18), 0.015, sz * (d * 0.5 - 0.18)), Vector3(0.3, 0.03, 0.3), fmat))

	if hazard_edge:
		add_child(_box(Vector3(0, sh * 0.5, d * 0.5 + 0.005), Vector3(w * 0.96, sh * 0.7, 0.02), HangarKit.striped_mat()))
	if edge_light:
		add_child(_box(Vector3(0, sh - TOP_THICK - 0.02, d * 0.5 + 0.01), Vector3(w * 0.9, 0.025, 0.02), _emi(accent_color, 0.7)))
	if grime:
		add_child(HangarKit.grime_band(w, 0.05, d * 0.5 - SKIRT_INSET + 0.004, body_color))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.22, 0.5), sh * 0.5))
		if q:
			q.position = Vector3(-w * 0.5 + 0.45, sh * 0.45, d * 0.5 + 0.02)
			add_child(q)


func _build_skirt_panels(w: float, d: float, sh: float) -> void:
	var pmat := _mat(panel_color)
	var ph: float = (sh - TOP_THICK) * 0.7
	var t := 0.02
	var cy: float = (sh - TOP_THICK) * 0.5
	# front/back run a panel per cell; sides one panel.
	for sz in [1.0, -1.0]:
		for i in range(maxi(width_cells, 1)):
			var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
			add_child(_box(Vector3(cx, cy, sz * (d * 0.5 - SKIRT_INSET) + sz * t * 0.5), Vector3(CELL * 0.82, ph, t), pmat))
	for sx in [1.0, -1.0]:
		add_child(_box(Vector3(sx * (w * 0.5 - SKIRT_INSET) + sx * t * 0.5, cy, 0), Vector3(t, ph, d * 0.8), pmat))


func _build_grate(w: float, d: float, sh: float) -> void:
	var fmat := HangarKit.worn_metal(panel_color.darkened(0.1))
	# perimeter frame
	add_child(_box(Vector3(0, sh - TOP_THICK * 0.5, 0), Vector3(w, TOP_THICK, d), _mat(body_color.darkened(0.1)).duplicate()))
	var slats := maxi(int(d / 0.18), 4)
	for i in range(slats):
		var z: float = lerpf(-d * 0.46, d * 0.46, float(i) / float(slats - 1))
		add_child(_box(Vector3(0, sh - TOP_THICK + 0.01, z), Vector3(w * 0.94, 0.02, 0.05), fmat))


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
