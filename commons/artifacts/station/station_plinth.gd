extends Node3D
class_name StationPlinth

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR display plinth one curated artifact stands ON — a width_cells × depth_cells (1 m per cell) painted-metal block with a tray cap, per-cell panels, and an ID stencil. ANY footprint snaps to the grid: 1×1 and 1×2/1×3 podiums for held things, 2×2/3×3/4×4 plinths for big ones. Origin at the floor centre; the cap top sits at top_height.
# desire: to give one thing its own measured patch of ground at the right size and the right height — a tall narrow podium for a small precious thing, a low broad plinth for a large one — so the lift always says "this one, here, by itself".
# critical_parameter: width_cells × depth_cells + top_height — how much grid the item claims and how high it is presented; the composer measures each artifact and picks these so the plinth fits.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new size.
# emerges: 1×1 tall = a single specimen at eye height; 1×2/1×3 = a long thing laid across; 3×3/4×4 low = a big thing on a broad stage. Per-cell panels keep every size reading modular.
# needs: a chamfered foot plate with corner bolts [present]; a recessed base reveal [present]; a body block [present]; per-cell inset panels [present]; a chamfered collar + cap at top_height [present]; optional tray rim, wrapped lit groove, three-colour bar, surface-pinned caption, stencil [optional].
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
## A slim emissive accent line under the cap rim (front face).
@export var edge_light: bool = true
## Run the lit accent as a continuous groove all the way around the cap rim (not just the front).
@export var edge_light_wrap: bool = true
## A chamfered collar where the body meets the cap — reads as a finished slab, not a raw box.
@export var chamfer_cap: bool = true
## A recessed shadow reveal between the foot plate and the body, so the block reads as set down on purpose.
@export var base_reveal: bool = true
## Rows of bolt heads on the foot-plate corners (the bolted-down look).
@export var corner_bolts: bool = true

@export_group("Surface")
@export var stencil_text: String = ""
@export var wear: float = 0.08
@export var three_bar: bool = true
@export var grime: bool = true
## Faint vertical dust streaks down the front face (subtle, deterministic).
@export var dust: bool = true

@export_group("Content")
## A caption harvested onto a framed, surface-pinned plate on the front face (the curation text rule).
@export var caption_text: String = ""
## Caption mounts as: "frame" (a flat printed label on the front face) | "signage" (a framed plate on a small bracket).
@export var caption_style: String = "frame"

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0
const PLINTH_THICK := 0.09
const CAP_THICK := 0.07
const RIM_H := 0.05
const REVEAL_H := 0.018       # height of the recessed shadow gap under the body
const CHAMFER := 0.05         # chamfer collar size at the body→cap join

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
	if has_meta("config_edge_light_wrap"): edge_light_wrap = _b(get_meta("config_edge_light_wrap"))
	if has_meta("config_chamfer_cap"): chamfer_cap = _b(get_meta("config_chamfer_cap"))
	if has_meta("config_base_reveal"): base_reveal = _b(get_meta("config_base_reveal"))
	if has_meta("config_corner_bolts"): corner_bolts = _b(get_meta("config_corner_bolts"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_caption_text"): caption_text = str(get_meta("config_caption_text"))
	if has_meta("config_caption_style"): caption_style = str(get_meta("config_caption_style")).to_lower()
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
	var trim_mat := _mat(panel_color.darkened(0.04))
	var bolt_mat := HangarKit.worn_metal(panel_color)

	# Foot — a wide plate on the cells, slightly chamfered (a thin bevel skirt under the main plate
	# reads as a cast base rather than a flat slab).
	add_child(_box(Vector3(0, PLINTH_THICK * 0.5, 0), Vector3(cap_w + 0.06, PLINTH_THICK, cap_d + 0.06), trim_mat))
	add_child(_box(Vector3(0, PLINTH_THICK + 0.012, 0), Vector3(cap_w + 0.02, 0.024, cap_d + 0.02), body_mat))

	# Corner bolts on the foot plate — the bolted-down detail.
	if corner_bolts:
		_build_corner_bolts(cap_w, cap_d, bolt_mat)

	# A recessed shadow reveal: the body sits on a slightly narrower neck, leaving a dark gap so the
	# block reads as set down on purpose (the Rams "let the join show" move).
	var foot_top: float = PLINTH_THICK + 0.024
	var body_bottom: float = foot_top
	if base_reveal:
		var neck_mat := _mat(body_color.darkened(0.34))
		add_child(_box(Vector3(0, foot_top + REVEAL_H * 0.5, 0), Vector3(body_w - 0.06, REVEAL_H, body_d - 0.06), neck_mat))
		body_bottom = foot_top + REVEAL_H

	# Body block.
	var body_top: float = th - CAP_THICK - (CHAMFER if chamfer_cap else 0.0)
	var body_h: float = maxf(body_top - body_bottom, 0.12)
	add_child(_box(Vector3(0, body_bottom + body_h * 0.5, 0), Vector3(body_w, body_h, body_d), body_mat))

	# Per-cell inset panels on the four faces (modular at every size).
	_build_panels(body_w, body_d, body_bottom, body_h, wcells, dcells)

	# Chamfered collar where the body meets the cap (a beveled flare, wider than the body, narrower
	# than the cap) — turns the box-on-box silhouette into a finished slab.
	if chamfer_cap:
		var collar_cy: float = body_top + CHAMFER * 0.5
		var collar_w: float = lerpf(body_w, cap_w, 0.6)
		var collar_d: float = lerpf(body_d, cap_d, 0.6)
		add_child(_box(Vector3(0, collar_cy, 0), Vector3(collar_w, CHAMFER, collar_d), cap_mat))

	# Cap — top sits exactly at top_height.
	add_child(_box(Vector3(0, th - CAP_THICK * 0.5, 0), Vector3(cap_w, CAP_THICK, cap_d), cap_mat))

	match top_style:
		"tray": _build_tray(cap_w, cap_d, th)
		"grate": _build_grate(cap_w, cap_d, th)
		_: pass

	# Front face is +Z (toward the viewer): dressing sits there.
	# Lit accent groove under the cap rim — front only, or wrapped continuously around all four edges.
	if edge_light:
		var lit := _emi(accent_color, 0.7)
		var gy: float = th - CAP_THICK - 0.018
		add_child(_box(Vector3(0, gy, cap_d * 0.5 + 0.006), Vector3(cap_w * 0.96, 0.02, 0.018), lit))
		if edge_light_wrap:
			add_child(_box(Vector3(0, gy, -cap_d * 0.5 - 0.006), Vector3(cap_w * 0.96, 0.02, 0.018), lit))
			add_child(_box(Vector3(cap_w * 0.5 + 0.006, gy, 0), Vector3(0.018, 0.02, cap_d * 0.96), lit))
			add_child(_box(Vector3(-cap_w * 0.5 - 0.006, gy, 0), Vector3(0.018, 0.02, cap_d * 0.96), lit))
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(body_w * 0.6, 1.0), 0.04, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
		bar.position = Vector3(0, body_bottom + body_h * 0.62, body_d * 0.5 + 0.02)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(cap_w + 0.06, 0.06, (cap_d + 0.06) * 0.5 + 0.004, body_color))
	if dust:
		var streaks: Node3D = HangarKit.dust_streaks(body_w * 0.9, body_h * 0.8, body_d * 0.5 + 0.011, maxi(wcells + 1, 3))
		streaks.position = Vector3(0, body_bottom + body_h * 0.5, 0)
		add_child(streaks)
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(body_w * 0.7, 0.5), body_h * 0.16))
		if q:
			q.position = Vector3(0, body_bottom + body_h * 0.28, body_d * 0.5 + 0.02)
			add_child(q)

	# Caption — harvested onto a framed, surface-pinned plate on the front face (the curation text rule).
	if caption_text.strip_edges() != "":
		_build_caption(body_w, body_d, body_bottom, body_h)


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


func _build_corner_bolts(cap_w: float, cap_d: float, mat: Material) -> void:
	# Four bolt heads near the foot-plate corners; on larger feet, a short row along each long edge.
	var by: float = PLINTH_THICK + 0.006
	var ix: float = cap_w * 0.5 - 0.07
	var iz: float = cap_d * 0.5 - 0.07
	var n: int = clampi(int(cap_w / 0.55), 1, 3)
	for sx in [1.0, -1.0]:
		var a := Vector3(sx * ix, by, -iz)
		var b := Vector3(sx * ix, by, iz)
		var row: Node3D = HangarKit.bolts(a, b, maxi(n, 1), 0.016, mat)
		# bolts() lays cylinders with caps facing +Z; lay them flat to face up instead.
		row.rotation_degrees = Vector3(-90, 0, 0)
		add_child(row)


func _build_caption(body_w: float, body_d: float, body_bottom: float, body_h: float) -> void:
	# A framed 2D-in-3D caption pinned to the front (+Z) face — words on a surface, never floating.
	# The caption must sit INSIDE the front per-cell panel it is pinned to, and its inner text-plate
	# must sit inside the surrounding frame border with a margin on all four sides. We derive sizes so
	# the whole framed caption (HangarKit's readout = inner face + bezel added OUTSIDE the requested
	# size) stays within the panel, then recess the inner plate from the frame by PANEL_PAD.
	const PANEL_PAD := 0.022          # inset of the framed caption from the panel edge (all sides)
	const FRAME_MARGIN := 0.018       # gap between the inner text-plate and its frame border (all sides)

	# Front per-cell panel region the caption is mounted on (mirrors _build_panels for the 1×1 cell).
	var panel_w: float = body_w * 0.82
	var panel_h: float = body_h * 0.78
	var panel_cy: float = body_bottom + body_h * 0.5

	# Target OUTER extent of the framed caption — fit inside the panel with PANEL_PAD on every side.
	var outer_w: float = clampf(panel_w - PANEL_PAD * 2.0, 0.16, 0.9)
	var outer_h: float = clampf(minf(panel_h - PANEL_PAD * 2.0, body_h * 0.22), 0.08, 0.28)
	var cy: float = panel_cy   # centred on the panel so the margins read evenly

	if caption_style == "signage":
		# Signage adds its own bracket/struts; size its panel to the available outer extent.
		var sign: Node3D = HangarKit.signage("", [caption_text], Vector2(outer_w, outer_h), 0.1, Vector3(0, 0, 1))
		if sign:
			sign.position = Vector3(0, cy, body_d * 0.5 + 0.012)
			add_child(sign)
	else:
		# readout() grows the bezel OUTSIDE the requested face size by ft = max(w,h) * 0.06 per side.
		# Back the requested face out of the outer extent so the bezel (the frame border) lands inside
		# the panel, then shrink the face again by FRAME_MARGIN so the inner text-plate is inset from
		# that frame border on all four sides.
		var ft_guess: float = maxf(outer_w, outer_h) * 0.06
		var frame_w: float = maxf(outer_w - ft_guess * 2.0, 0.12)
		var frame_h: float = maxf(outer_h - ft_guess * 2.0, 0.06)
		var plate_w: float = maxf(frame_w - FRAME_MARGIN * 2.0, 0.08)
		var plate_h: float = maxf(frame_h - FRAME_MARGIN * 2.0, 0.05)

		# Frame border: a recessed backing plate sized to (frame_w, frame_h) sits behind the inner
		# plate; the inner text-plate is smaller (plate_w, plate_h) so a uniform border shows around it.
		var frame_mat := _mat(panel_color.darkened(0.18))
		add_child(_box(Vector3(0, cy, body_d * 0.5 + 0.016), Vector3(frame_w, frame_h, 0.02), frame_mat))

		var plate: Node3D = HangarKit.readout("", [caption_text], Vector2(plate_w, plate_h),
			Color(0.88, 0.86, 0.80), Color(0.10, 0.10, 0.12), Color(0.10, 0.10, 0.12))
		if plate:
			plate.position = Vector3(0, cy, body_d * 0.5 + 0.030)
			add_child(plate)


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
