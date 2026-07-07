extends Node3D
class_name StationBench

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR worktable of a curation station — a length_cells × depth_cells (1 m per cell) painted-metal bench with a top at working height, an apron, legs, and optional drawers, that gives a set a surface to be worked on or laid out across rather than raised on plinths. Origin at the floor centre; top faces +Y.
# desire: to offer the OTHER way to present — flat, at hand, spread out: the lab bench where things are used and compared, not the pedestal where one thing is enshrined.
# critical_parameter: length_cells × depth_cells + top_height — the working surface footprint and how high it sits.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a long bench reads "lay it all out, work"; a short one reads "a station"; drawers + an edge strip read "serviced, lab". On the grid it lines up with walls and stages.
# needs: a top slab at top_height [present]; apron + legs [present]; optional drawer block + edge light + stencil [optional].
# relationships: the flat sibling of [[station_plinth]] (lay on this, enshrine on that); shares the HangarKit look with the packaging worktable but tiles on the grid; placed by [[curation_station]].
# truth: not everything is enshrined; some things are worked. The bench is the station admitting that study is also a kind of display.

@export_group("Grid")
@export var length_cells: int = 2
@export var depth_cells: int = 1
@export_group("Dimensions")
@export var top_height: float = 0.92
@export_group("Style")
@export var drawers: bool = true
@export var edge_light: bool = true
@export_group("Surface")
@export var stencil_text: String = ""
@export var wear: float = 0.08
@export var three_bar: bool = true
@export var grime: bool = true
@export_group("Content")
## Integrated INFO SCREEN — a lit console readout standing at the back of the
## worktop, facing the operator: the bench's own display, part of the body.
@export var info_lines: Array = []
@export var info_header: String = ""
@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var top_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const TOP_THICK := 0.05
const APRON_H := 0.1
const LEG_W := 0.08

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
	if has_meta("config_depth_cells"): depth_cells = int(str(get_meta("config_depth_cells")))
	if has_meta("config_top_height"): top_height = float(str(get_meta("config_top_height")))
	if has_meta("config_drawers"): drawers = _b(get_meta("config_drawers"))
	if has_meta("config_edge_light"): edge_light = _b(get_meta("config_edge_light"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_info_lines"):
		var il = get_meta("config_info_lines")
		if il is Array: info_lines = il
		elif il is String and str(il).strip_edges() != "": info_lines = [str(il)]
	if has_meta("config_info_header"): info_header = str(get_meta("config_info_header"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_top_color"): top_color = _pc(str(get_meta("config_top_color")), top_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)

func _build() -> void:
	_built = true
	var w: float = float(maxi(length_cells, 1)) * CELL
	var d: float = float(maxi(depth_cells, 1)) * CELL
	var th: float = maxf(top_height, 0.4)
	var body_mat := _mat(body_color)
	var top_mat := _mat(top_color)
	var leg_top: float = th - TOP_THICK

	# Legs.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var lx: float = sx * (w * 0.5 - LEG_W)
			var lz: float = sz * (d * 0.5 - LEG_W)
			add_child(_box(Vector3(lx, leg_top * 0.5, lz), Vector3(LEG_W, leg_top, LEG_W), body_mat))
	# Apron rails (front/back).
	for sz2 in [-1.0, 1.0]:
		add_child(_box(Vector3(0, leg_top - APRON_H * 0.5, sz2 * (d * 0.5 - LEG_W * 0.5)), Vector3(w - LEG_W, APRON_H, LEG_W * 0.7), body_mat))
	# Top slab — top sits exactly at top_height.
	add_child(_box(Vector3(0, th - TOP_THICK * 0.5, 0), Vector3(w, TOP_THICK, d), top_mat))

	if drawers:
		var dw: float = minf(CELL * 0.9, w * 0.45)
		var dx: float = w * 0.5 - dw * 0.5 - 0.08
		add_child(_box(Vector3(dx, leg_top - 0.18, 0), Vector3(dw, 0.34, d - 0.18), _mat(body_color.darkened(0.03))))
		for k in range(2):
			add_child(_box(Vector3(dx, leg_top - 0.1 - float(k) * 0.16, d * 0.5 - 0.09), Vector3(dw * 0.8, 0.02, 0.02), HangarKit.worn_metal(top_color)))
	if edge_light:
		add_child(_box(Vector3(0, th - TOP_THICK - 0.012, d * 0.5 + 0.005), Vector3(w * 0.92, 0.02, 0.02), _emi(accent_color, 0.7)))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.5, 0.9), 0.04, [accent_color, HangarKit.DISPLAY_DARK, top_color])
		bar.position = Vector3(-w * 0.25, leg_top - APRON_H * 0.5, d * 0.5 - LEG_W * 0.5 + 0.03)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(w, 0.05, d * 0.5 - 0.02, body_color))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.3, 0.5), APRON_H * 0.7))
		if q:
			q.position = Vector3(w * 0.1, leg_top - APRON_H * 0.5, d * 0.5 - LEG_W * 0.5 + 0.03)
			add_child(q)

	# Integrated info screen — a lit console standing at the back of the worktop,
	# facing the operator (+Z), on a strut that ties it into the bench body.
	if info_lines.size() > 0:
		_build_info_screen(w, d, th)

	# Solid in-game: a body collider covering the bench volume.
	add_child(HangarKit.box_collider(Vector3(w, th, d), Vector3(0, th * 0.5, 0)))

func _build_info_screen(w: float, d: float, th: float) -> void:
	var sw: float = clampf(w * 0.5, 0.24, 1.1)
	var sh: float = 0.30
	var sx: float = -w * 0.20                 # back-left, clear of the drawers (right)
	var sz: float = -(d * 0.5 - 0.05)         # back edge; screen faces +Z toward the operator
	var sy: float = th + sh * 0.5 + 0.08      # standing above the worktop
	# Riser backing panel behind the screen.
	add_child(_box(Vector3(sx, th + sh * 0.5 + 0.03, sz - 0.015),
		Vector3(sw + 0.05, sh + 0.12, 0.03), _mat(body_color.darkened(0.05))))
	var screen: Node3D = HangarKit.readout(info_header, info_lines, Vector2(sw, sh),
		Color(0.06, 0.07, 0.09), Color(0.82, 0.88, 0.94), accent_color)
	screen.position = Vector3(sx, sy, sz + 0.03)
	add_child(screen)
	# A lit strut from the worktop up to the console — the "connection".
	add_child(_box(Vector3(sx - sw * 0.5, th + 0.06, sz + 0.01),
		Vector3(0.014, 0.16, 0.014), _emi(accent_color, 0.9)))

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
