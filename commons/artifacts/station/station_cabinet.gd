extends Node3D
class_name StationCabinet

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR storage / display cabinet of a curation station — a width_cells × 1 m (per cell) painted-metal case with a tinted glass front, lit internal shelves, and a frame, so cabinets line up cell-to-cell as a glowing back wall of stored specimens. Origin at the floor centre; the case faces +Z.
# desire: to give a set a context of MANY — shelves of related things behind the few on plinths, so the curated items read as chosen from a collection, lit and kept; the glowing display case the reference renders are built around.
# critical_parameter: width_cells + shelf_count — how much grid the storage claims and how densely it reads; the composer flanks the stage with these.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: glass front + lit shelves reads "display, kept, valuable"; solid doors read "stored, sealed"; a top readout reads "monitored". Per-cell mullions read "modular, built to a grid".
# needs: a case body + back [present]; per-cell mullion frame [present]; lit shelves [present]; a tinted glass front [present]; base + top cap [present]; optional readout + accent bar [optional].
# relationships: the storage sibling of [[station_wall]] (a wall you can see into); flanks the [[station_stage]]; shares the HangarKit look with the packaging cabinet cluster but tiles on the grid; placed by [[curation_station]].
# truth: to store behind glass is to say "these are kept, and there are more". The plinths show the argument; the cabinet shows the archive it was drawn from.

@export_group("Grid")
@export var width_cells: int = 2
@export_group("Dimensions")
@export var height: float = 1.9
@export var depth: float = 0.5
@export var shelf_count: int = 4
@export_group("Style")
## "glass" (tinted front + lit shelves) | "solid" (panelled doors).
@export var front_style: String = "glass"
## Soft interior glow colour for the lit shelves (display light).
@export var glow_color: Color = Color(0.62, 0.82, 0.92)
@export var top_readout: bool = false
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
const FRAME_T := 0.06
const BASE_H := 0.12

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
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_depth"): depth = float(str(get_meta("config_depth")))
	if has_meta("config_shelf_count"): shelf_count = int(str(get_meta("config_shelf_count")))
	if has_meta("config_front_style"): front_style = str(get_meta("config_front_style")).to_lower()
	if has_meta("config_glow_color"): glow_color = _pc(str(get_meta("config_glow_color")), glow_color)
	if has_meta("config_top_readout"): top_readout = _b(get_meta("config_top_readout"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)

func _build() -> void:
	_built = true
	var n: int = maxi(width_cells, 1)
	var w: float = float(n) * CELL
	var h: float = maxf(height, 0.6)
	var d: float = maxf(depth, 0.25)
	var body_mat := _mat(body_color)
	var fz: float = d * 0.5   # +Z face

	# Base, top cap.
	add_child(_box(Vector3(0, BASE_H * 0.5, 0), Vector3(w, BASE_H, d), _mat(panel_color.darkened(0.04))))
	add_child(_box(Vector3(0, h - FRAME_T * 0.5, 0), Vector3(w, FRAME_T, d), _mat(body_color.lightened(0.04))))
	# Back panel.
	add_child(_box(Vector3(0, h * 0.5, -d * 0.5 + 0.02), Vector3(w, h, 0.04), _mat(panel_color)))
	# Side posts + per-cell mullions (the grid frame).
	for i in range(n + 1):
		var x: float = -w * 0.5 + float(i) * CELL
		add_child(_box(Vector3(x, h * 0.5, fz - FRAME_T * 0.5), Vector3(FRAME_T, h, FRAME_T), body_mat))

	# Lit shelves per cell.
	var inner_lo: float = BASE_H + 0.06
	var inner_hi: float = h - FRAME_T - 0.06
	var sc: int = maxi(shelf_count, 1)
	var shelf_mat := _mat(panel_color.lightened(0.05))
	var glow := _emi(glow_color, 0.9)
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		for s in range(sc):
			var sy: float = lerpf(inner_lo, inner_hi, float(s) / float(maxi(sc - 1, 1)))
			add_child(_box(Vector3(cx, sy, 0), Vector3(CELL - FRAME_T * 1.6, 0.02, d - 0.1), shelf_mat))
			# under-shelf glow strip
			add_child(_box(Vector3(cx, sy - 0.025, fz - 0.06), Vector3(CELL - FRAME_T * 2.2, 0.012, 0.02), glow))

	# Front: tinted glass or panelled doors.
	if front_style == "solid":
		for i in range(n):
			var cx2: float = -w * 0.5 + (float(i) + 0.5) * CELL
			add_child(_box(Vector3(cx2, h * 0.5, fz - 0.02), Vector3(CELL - FRAME_T * 1.4, h - FRAME_T * 2.0, 0.03), _mat(panel_color)))
	else:
		var glass := _glass_mat()
		add_child(_box(Vector3(0, (inner_lo + inner_hi) * 0.5, fz - 0.015), Vector3(w - FRAME_T * 0.5, inner_hi - inner_lo, 0.02), glass))

	if top_readout:
		var ro: Node3D = HangarKit.readout("ARCHIVE", ["%d UNITS" % (n * sc), "SEALED"], Vector2(minf(w * 0.5, 0.7), 0.3))
		if ro:
			ro.position = Vector3(0, h - 0.02, fz - 0.04)
			add_child(ro)
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.5, 0.9), 0.04, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
		bar.position = Vector3(0, h - FRAME_T - 0.06, fz + 0.01)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(w, 0.06, fz - 0.02, body_color))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.3, 0.5), 0.09))
		if q:
			q.position = Vector3(-w * 0.5 + 0.35, BASE_H + 0.12, fz + 0.01)
			add_child(q)

func _glass_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.82, 0.88, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.2
	m.roughness = 0.08
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

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
