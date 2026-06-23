extends Node3D
class_name StationPlinth

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR display plinth one curated artifact stands ON — a width_cells × depth_cells (1 m per cell) painted-metal block with a tray cap, per-cell panels, and an ID stencil. ANY footprint snaps to the grid: 1×1 and 1×2/1×3 podiums for held things, 2×2/3×3/4×4 plinths for big ones. Origin at the floor centre; the cap top sits at top_height.
# desire: to give one thing its own measured patch of ground at the right size and the right height — a tall narrow podium for a small precious thing, a low broad plinth for a large one — so the lift always says "this one, here, by itself".
# critical_parameter: width_cells × depth_cells + top_height — how much grid the item claims and how high it is presented; the composer measures each artifact and picks these so the plinth fits.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new size.
# emerges: 1×1 tall = a single specimen at eye height; 1×2/1×3 = a long thing laid across; 3×3/4×4 low = a big thing on a broad stage. Per-cell panels keep every size reading modular.
# needs: a foot plate [present]; a body block [present]; a cap at top_height [present]; per-cell inset panels [present]; optional tray rim, edge light, stencil [optional].
# relationships: the single-item sibling of [[station_stage]] (the set stands on the stage, each item on a plinth); the grid-tiling cousin of [[hangar_podium]]; sized + placed by [[curation_station]].
# truth: a plinth is a claim that one thing is worth isolating, cut to the thing's own measure. Size IS part of the argument — what you raise high and narrow, you call precious; what you set low and broad, you call a world.

@export_group("Grid")
## Footprint in 1 m cells along X (width) and Z (depth). Any combo: 1×1, 1×2, 1×3, 2×2, 3×3, 4×4 …
@export var width_cells: int = 1
@export var depth_cells: int = 1

@export_group("Dimensions")
## Cap-top height — where the artifact's base sits (reach height ≈ 1.0 m for small; lower for big plinths).
@export var top_height: float = 1.0
## Cap inset from the footprint edge (so the block reads narrower than its cells).
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
	# footprint_cells (legacy / convenience) = square; width_cells/depth_cells override per axis.
	if has_meta("config_footprint_cells"):
		var fc := int(str(get_meta("config_footprint_cells")))
		width_cells = fc
		depth_cells = fc
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))
	if has_meta("config_depth_cells"): depth_cells = int(str(get_meta("config_depth_cells")))
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
	var wcells: int = maxi(width_cells, 1)
	var dcells: int = maxi(depth_cells, 1)
	var wc: float = float(wcells) * CELL
	var dc: float = float(dcells) * CELL
	var inset: float = minf(cap_inset, minf(wc, dc) * 0.28)
	var cap_w: float = wc - inset * 2.0
	var cap_d: float = dc - inset * 2.0
	var body_w: float = cap_w - 0.1
	var body_d: float = cap_d - 0.1
	var th: float = maxf(top_height, 0.25)
	var body_mat := _mat(body_color)
	var cap_mat := _mat(body_color.lightened(0.06))

	# Foot — wide plate on the cells.
	add_child(_box(Vector3(0, PLINTH_THICK * 0.5, 0), Vector3(cap_w + 0.06, PLINTH_THICK, cap_d + 0.06), body_mat))

	# Body block.
	var body_bottom: float = PLINTH_THICK
	var body_top: float = th - CAP_THICK
	var body_h: float = maxf(body_top - body_bottom, 0.12)
	add_child(_box(Vector3(0, body_bottom + body_h * 0.5, 0), Vector3(body_w, body_h, body_d), body_mat))

	# Per-cell inset panels on the four faces (modular at every size).
	_build_panels(body_w, body_d, body_bottom, body_h, wcells, dcells)

	# Cap — top sits exactly at top_height.
	add_child(_box(Vector3(0, th - CAP_THICK * 0.5, 0), Vector3(cap_w, CAP_THICK, cap_d), cap_mat))

	match top_style:
		"tray": _build_tray(cap_w, cap_d, th)
		"grate": _build_grate(cap_w, cap_d, th)
		_: pass

	# Front face is +Z (toward the viewer): dressing sits there.
	if edge_light:
		add_child(_box(Vector3(0, th - CAP_THICK - 0.02, body_d * 0.5 + 0.012), Vector3(body_w * 0.84, 0.022, 0.02), _emi(accent_color, 0.7)))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(body_w * 0.6, 1.0), 0.04, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
		bar.position = Vector3(0, body_bottom + body_h * 0.62, body_d * 0.5 + 0.02)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(cap_w + 0.06, 0.06, (cap_d + 0.06) * 0.5 + 0.004, body_color))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(body_w * 0.7, 0.5), body_h * 0.16))
		if q:
			q.position = Vector3(0, body_bottom + body_h * 0.28, body_d * 0.5 + 0.02)
			add_child(q)


func _build_panels(body_w: float, body_d: float, body_bottom: float, body_h: float, wcells: int, dcells: int) -> void:
	var pmat := _mat(panel_color)
	var body_cy: float = body_bottom + body_h * 0.5
	var ph: float = body_h * 0.78
	var t := 0.02
	# Front + back faces (±Z): one panel per width cell.
	var cell_w: float = body_w / float(wcells)
	for sz in [1.0, -1.0]:
		for i in range(wcells):
			var px: float = -body_w * 0.5 + (float(i) + 0.5) * cell_w
			add_child(_box(Vector3(px, body_cy, sz * (body_d * 0.5 + t * 0.5)), Vector3(cell_w * 0.82, ph, t), pmat))
	# Side faces (±X): one panel per depth cell.
	var cell_d: float = body_d / float(dcells)
	for sx in [1.0, -1.0]:
		for i in range(dcells):
			var pz: float = -body_d * 0.5 + (float(i) + 0.5) * cell_d
			add_child(_box(Vector3(sx * (body_w * 0.5 + t * 0.5), body_cy, pz), Vector3(t, ph, cell_d * 0.82), pmat))


func _build_tray(cap_w: float, cap_d: float, th: float) -> void:
	var rim_mat := _mat(panel_color)
	var ry: float = th + RIM_H * 0.5
	add_child(_box(Vector3(0, ry, cap_d * 0.5 - 0.02), Vector3(cap_w, RIM_H, 0.04), rim_mat))
	add_child(_box(Vector3(0, ry, -cap_d * 0.5 + 0.02), Vector3(cap_w, RIM_H, 0.04), rim_mat))
	add_child(_box(Vector3(cap_w * 0.5 - 0.02, ry, 0), Vector3(0.04, RIM_H, cap_d), rim_mat))
	add_child(_box(Vector3(-cap_w * 0.5 + 0.02, ry, 0), Vector3(0.04, RIM_H, cap_d), rim_mat))


func _build_grate(cap_w: float, cap_d: float, th: float) -> void:
	var fmat := HangarKit.worn_metal(panel_color.darkened(0.1))
	var slats: int = maxi(int(cap_w / 0.18), 4)
	for i in range(slats):
		var x: float = lerpf(-cap_w * 0.44, cap_w * 0.44, float(i) / float(slats - 1))
		add_child(_box(Vector3(x, th + 0.012, 0), Vector3(0.04, 0.02, cap_d * 0.92), fmat))


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
