extends Node3D
class_name StationPlinth

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR display column one curated artifact stands ON — a footprint_cells × footprint_cells (1 m per cell) painted-metal plinth with a tray cap at reach height, an ID stencil, and an optional small readout collar. Origin at the floor centre; the cap top sits at top_height.
# desire: to give one thing its own square of ground and lift it to where a hand and an eye meet it — to say "this one, here, by itself".
# critical_parameter: top_height + footprint_cells — how high the thing is presented and how much grid it claims; the composer sets these so a row of plinths reads even.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a tray cap reads "set the thing in here"; a flat cap reads "stand the thing on top"; the stencil reads "catalogued"; the collar light reads "powered station".
# needs: a plinth foot [present]; a body column [present]; a cap at top_height [present]; optional tray rim, edge light, stencil [optional].
# relationships: the single-item sibling of [[station_stage]] (the set stands on the stage, each item on a plinth); the grid-tiling cousin of [[hangar_podium]]; placed in rows by [[curation_station]].
# truth: a plinth is a claim that one thing is worth isolating. To pick it up off the floor and give it a square is the smallest act of curation.

@export_group("Grid")
## Plinth footprint in 1 m cells, square (1 = 1×1, 2 = 2×2).
@export var footprint_cells: int = 1

@export_group("Dimensions")
## Cap-top height — where the artifact's base sits (reach height ≈ 1.0 m).
@export var top_height: float = 1.0
## Cap inset from the footprint edge (so the column reads narrower than its cell).
@export var cap_inset: float = 0.16

@export_group("Style")
## "tray" (rimmed dish) | "flat" | "grate" cap.
@export var top_style: String = "tray"
## A slim emissive accent line under the cap rim.
@export var edge_light: bool = true

@export_group("Surface")
@export var stencil_text: String = ""
@export var wear: float = 0.08
@export var three_bar: bool = true
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const PLINTH_THICK := 0.09
const CAP_THICK := 0.07
const RIM_H := 0.05

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
	if has_meta("config_footprint_cells"): footprint_cells = int(str(get_meta("config_footprint_cells")))
	if has_meta("config_top_height"): top_height = float(str(get_meta("config_top_height")))
	if has_meta("config_cap_inset"): cap_inset = float(str(get_meta("config_cap_inset")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_edge_light"): edge_light = _b(get_meta("config_edge_light"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var fc: float = float(maxi(footprint_cells, 1)) * CELL
	var cap_w: float = fc - cap_inset * 2.0
	var body_w: float = cap_w - 0.1
	var th: float = maxf(top_height, 0.4)
	var body_mat := _mat(body_color)
	var cap_mat := _mat(body_color.lightened(0.06))

	# Foot — wide plate on the cell.
	add_child(_box(Vector3(0, PLINTH_THICK * 0.5, 0), Vector3(cap_w + 0.06, PLINTH_THICK, cap_w + 0.06), body_mat))

	# Body column.
	var body_bottom: float = PLINTH_THICK
	var body_top: float = th - CAP_THICK
	var body_h: float = maxf(body_top - body_bottom, 0.12)
	add_child(_box(Vector3(0, body_bottom + body_h * 0.5, 0), Vector3(body_w, body_h, body_w), body_mat))

	# Inset panels on the four faces.
	_build_panels(body_w, body_bottom, body_h)

	# Cap — top sits exactly at top_height.
	add_child(_box(Vector3(0, th - CAP_THICK * 0.5, 0), Vector3(cap_w, CAP_THICK, cap_w), cap_mat))

	match top_style:
		"tray": _build_tray(cap_w, th)
		"grate": _build_grate(cap_w, th)
		_: pass

	if edge_light:
		var lit := _emi(accent_color, 0.7)
		add_child(_box(Vector3(0, th - CAP_THICK - 0.02, body_w * 0.5 + 0.012), Vector3(body_w * 0.8, 0.022, 0.02), lit))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(body_w * 0.6, 0.04, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
		bar.position = Vector3(0, body_bottom + body_h * 0.62, body_w * 0.5 + 0.02)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(cap_w + 0.06, 0.06, (cap_w + 0.06) * 0.5 + 0.004, body_color))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(body_w * 0.7, 0.5), body_h * 0.16))
		if q:
			q.position = Vector3(0, body_bottom + body_h * 0.28, body_w * 0.5 + 0.02)
			add_child(q)


func _build_panels(body_w: float, body_bottom: float, body_h: float) -> void:
	var pmat := _mat(panel_color)
	var body_cy: float = body_bottom + body_h * 0.5
	var pw: float = body_w * 0.74
	var ph: float = body_h * 0.78
	var t := 0.02
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var center: Vector3 = nrm * (body_w * 0.5 + t * 0.5) + Vector3(0, body_cy, 0)
		var size: Vector3 = Vector3(t, ph, pw) if absf(nrm.x) > 0.5 else Vector3(pw, ph, t)
		add_child(_box(center, size, pmat))


func _build_tray(cap_w: float, th: float) -> void:
	var rim_mat := _mat(panel_color)
	var inner: float = cap_w - 0.1
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var center: Vector3 = nrm * (inner * 0.5) + Vector3(0, th + RIM_H * 0.5, 0)
		var size: Vector3 = Vector3(0.04, RIM_H, cap_w) if absf(nrm.x) > 0.5 else Vector3(cap_w, RIM_H, 0.04)
		add_child(_box(center, size, rim_mat))


func _build_grate(cap_w: float, th: float) -> void:
	var fmat := HangarKit.worn_metal(panel_color.darkened(0.1))
	var slats := 5
	for i in range(slats):
		var x: float = lerpf(-cap_w * 0.42, cap_w * 0.42, float(i) / float(slats - 1))
		add_child(_box(Vector3(x, th + 0.012, 0), Vector3(0.04, 0.02, cap_w * 0.9), fmat))


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
