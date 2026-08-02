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
# relationships: the single-item sibling of [[station_stage]] (the set stands on the stage, each item on a plinth); the grid-tiling cousin of [[hangar_podium]]; sized + placed by [[curation_station]]; KIN of [[station_pillar]], [[station_crates]], [[station_wall]] and [[station_floorline]] — one `upkeep` vocabulary across the kit, the display telling the same time as the structure.
# truth: a plinth is a claim that one thing is worth isolating, cut to the thing's own measure. Size IS part of the argument — what you raise high and narrow, you call precious; what you set low and broad, you call a world.

# ─────────────────────────────────────────────────────────────────────────────
# ONE SCRIPT, THREE REGISTRY NAMES. station_plinth.tscn, station_micropod.tscn and
# station_plinth_wide.tscn are three .tscn files over this one script, differing
# only in the exports they set in the scene (base_meters 0.6 for the micropod,
# cap_meters for the wide one). They are a family, not three artifacts, so they
# take ONE axis and are meant to measure alike.
#
#   upkeep   WHICH MOMENT of the working life   service · works · store · scrap
#
#   service  in commission — the legacy lineage, byte for byte
#   store    packed down   — sleeved head to foot and banded; the rim light under the cover
#   works    mid-job       — the access panel swung open, loom spilling out, a tray on the cap
#   scrap    robbed        — the front cladding gone, studs bared, a dead rim channel, tape
#
# The rim light is the pivot, exactly as the groove is on the pillar and the seam is
# on the wall: it is the only emissive surface the piece has and owns the brightest
# pixels in any frame it appears in. `store` covers it; `scrap` rebuilds it as a dead
# recessed channel in worn metal.
#
# Deliberately NOT routed through upkeep: `top_height`, `cap_w/cap_d` and the cap
# itself. An artifact STANDS on this cap at exactly top_height — 8 plinth placements
# plus every one inside a curation_station bay — so an upkeep value that removed or
# lowered the presenting surface would leave the thing it carries hanging in the air.
# Upkeep dresses the pedestal; it never moves the surface an object sits on.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Grid")
## Footprint in 1 m cells along X (width) and Z (depth). Any combo: 1×1, 1×2, 1×3, 2×2, 3×3, 4×4 …
@export var width_cells: int = 1
@export var depth_cells: int = 1

@export_group("Dimensions")
## Cap-top height — where the artifact's base sits (reach height ≈ 1.0 m for small; lower for big plinths).
@export var top_height: float = 1.0
## Cap inset from the footprint edge (so the block reads narrower than its cells).
@export var cap_inset: float = 0.16
## If > 0, overrides the cell footprint with a true sub-grid metric width — a MICRO-PEDESTAL that
## still snaps to one grid cell but reads narrower than 1 m, for genuinely sub-1 m precious things
## (a held instrument, a thin readout). 0 = use width_cells × depth_cells (the normal plinth).
@export var base_meters: float = 0.0
## If > 0, sets the CAP (tray + body + foot) to this fixed metric width, OVERRIDING the cap_inset
## taper — so a 1-cell plinth can present a full ~1 m cap a 1 m-base artifact sits flush on (the
## default cap tapers to ~0.68 m, so a 1 m thing overhangs). The foot follows at cap + 0.06.
@export var cap_meters: float = 0.0

@export_group("Style")
## "tray" (rimmed dish) | "flat" | "grate" cap.
@export var top_style: String = "tray"
## A REAL light integrated into the plinth: a warm OmniLight3D rising from the
## cap, lighting the artifact from its own base — no external lamp needed.
@export var glow_light: bool = false
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

## AXIS — WHICH MOMENT of the working life this pedestal is caught in. Adopted word for word
## from [[station_pillar]], [[station_crates]], [[station_wall]] and [[station_floorline]],
## which already share it: one kit, one vocabulary, so a bay whose corners read "packed down"
## cannot have a plinth in the middle of it that still reads "in commission".
##
##   service  in commission — the legacy lineage, byte for byte
##   works    mid-job       — access panel swung open, loom spilling out, a tool tray on the cap
##   store    packed down   — sleeved head to foot and banded, the rim light under the cover
##   scrap    robbed        — front cladding gone, studs bared, the rim channel dead, tape
@export var upkeep: String = "service"
const UPKEEPS: PackedStringArray = ["service", "works", "store", "scrap"]

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
## The integrated INFO SCREEN — the artifact's simulation info as a lit console
## readout SET INTO the plinth's own front face (the board IS part of the body,
## not a plate floating beside it). A lit conduit wires it up to the cap.
@export var info_lines: Array = []
## Header shown at the top of the info screen (usually the artifact's title).
@export var info_header: String = ""

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
	if has_meta("config_base_meters"): base_meters = float(str(get_meta("config_base_meters")))
	if has_meta("config_cap_meters"): cap_meters = float(str(get_meta("config_cap_meters")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_glow_light"): glow_light = _b(get_meta("config_glow_light"))
	if has_meta("config_edge_light"): edge_light = _b(get_meta("config_edge_light"))
	if has_meta("config_edge_light_wrap"): edge_light_wrap = _b(get_meta("config_edge_light_wrap"))
	if has_meta("config_chamfer_cap"): chamfer_cap = _b(get_meta("config_chamfer_cap"))
	if has_meta("config_base_reveal"): base_reveal = _b(get_meta("config_base_reveal"))
	if has_meta("config_corner_bolts"): corner_bolts = _b(get_meta("config_corner_bolts"))
	if has_meta("config_upkeep"):
		var _u: String = str(get_meta("config_upkeep")).strip_edges().to_lower()
		upkeep = _u if UPKEEPS.has(_u) else upkeep
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_caption_text"): caption_text = str(get_meta("config_caption_text"))
	if has_meta("config_caption_style"): caption_style = str(get_meta("config_caption_style")).to_lower()
	if has_meta("config_info_lines"):
		var il = get_meta("config_info_lines")
		if il is Array: info_lines = il
		elif il is String and str(il).strip_edges() != "": info_lines = [str(il)]
	if has_meta("config_info_header"): info_header = str(get_meta("config_info_header"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var wcells: int = maxi(width_cells, 1)
	var dcells: int = maxi(depth_cells, 1)
	var wc: float = float(wcells) * CELL
	var dc: float = float(dcells) * CELL
	if base_meters > 0.0:
		# Micro-pedestal: build the foot below the grid cell (the piece still snaps to one cell, but
		# its visible base no longer over-claims 1 m under a genuinely sub-1 m thing).
		wc = clampf(base_meters, 0.2, CELL)
		dc = clampf(base_meters, 0.2, CELL)
	var inset: float = minf(cap_inset, minf(wc, dc) * 0.28)
	var cap_w: float = wc - inset * 2.0
	var cap_d: float = dc - inset * 2.0
	if cap_meters > 0.0:
		# Fixed cap width — overrides the taper so the cap fits the artifact's base; foot follows at +0.06.
		cap_w = clampf(cap_meters, 0.2, 4.0)
		cap_d = clampf(cap_meters, 0.2, 4.0)
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

	# Integrated glow — the plinth lights its own artifact from the cap
	# (replaces any external lamp; the light source IS the pedestal).
	if glow_light:
		var gl := OmniLight3D.new()
		gl.light_color = Color(1.0, 0.95, 0.85)
		gl.light_energy = 1.1
		gl.omni_range = 2.6
		gl.position = Vector3(0, th + 0.55, 0)
		add_child(gl)

	# Front face is +Z (toward the viewer): dressing sits there.
	# Lit accent groove under the cap rim — front only, or wrapped continuously around all four edges.
	# `store` withholds the rim light: the cover goes OVER it, so the pedestal loses the only
	# emissive surface it has. `scrap` rebuilds the same groove in dead worn metal — the
	# fitting robbed, the channel still there. Every other value evaluates to the old
	# expression, byte for byte.
	if edge_light and upkeep != "store":
		var lit: Material = _emi(accent_color, 0.7)
		if upkeep == "scrap":
			lit = HangarKit.worn_metal(panel_color.darkened(0.45))
		var gy: float = th - CAP_THICK - 0.018
		add_child(_box(Vector3(0, gy, cap_d * 0.5 + 0.006), Vector3(cap_w * 0.96, 0.02, 0.018), lit))
		if edge_light_wrap:
			add_child(_box(Vector3(0, gy, -cap_d * 0.5 - 0.006), Vector3(cap_w * 0.96, 0.02, 0.018), lit))
			add_child(_box(Vector3(cap_w * 0.5 + 0.006, gy, 0), Vector3(0.018, 0.02, cap_d * 0.96), lit))
			add_child(_box(Vector3(-cap_w * 0.5 - 0.006, gy, 0), Vector3(0.018, 0.02, cap_d * 0.96), lit))
	if three_bar and upkeep != "scrap":
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

	# Integrated info screen — the artifact's simulation info as a lit console
	# readout set INTO the front face, wired to the cap by a conduit so the
	# whole plinth reads as one connected body (mount + display + light).
	if info_lines.size() > 0:
		_build_info_screen(body_w, body_d, body_bottom, body_h, th - CAP_THICK - 0.018)

	# Solid in-game: a body collider covering the plinth column (foot → cap).
	add_child(HangarKit.box_collider(Vector3(cap_w, th, cap_d), Vector3(0, th * 0.5, 0)))

	# UPKEEP dressing, appended LAST so every child index and position above is untouched
	# on the legacy path. "service" falls through and adds nothing at all.
	match upkeep:
		"works":
			_upkeep_works(cap_w, cap_d, body_w, body_d, body_bottom, body_h, th)
		"store":
			_upkeep_store(cap_w, cap_d, th)
		"scrap":
			_upkeep_scrap(body_w, body_d, body_bottom, body_h)
		_:
			pass                                  # "service" — the legacy lineage


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


func _build_info_screen(body_w: float, body_d: float, body_bottom: float, body_h: float, groove_y: float) -> void:
	# A lit console readout inset on the upper front (+Z) face. Dark screen_bg →
	# HangarKit.readout renders it as a softly-lit screen (not a matte label).
	var sw: float = clampf(body_w * 0.84, 0.14, 0.92)
	var sh: float = clampf(body_h * 0.42, 0.10, 0.55)
	var scy: float = body_bottom + body_h * 0.66
	var fz: float = body_d * 0.5 + 0.02
	var screen: Node3D = HangarKit.readout(info_header, info_lines, Vector2(sw, sh),
		Color(0.06, 0.07, 0.09), Color(0.82, 0.88, 0.94), accent_color)
	screen.position = Vector3(0, scy, fz)
	add_child(screen)
	# Connection — a lit conduit from the cap groove down to the screen's top
	# corner, plus a small junction box: the cap (mount + light) and the screen
	# (display) read as one wired system, an electronic installation.
	var bezel: float = maxf(sw, sh) * 0.06
	var screen_top: float = scy + sh * 0.5 + bezel
	var x_off: float = -(sw * 0.5 + bezel + 0.03)
	if groove_y > screen_top + 0.02:
		var lit := _emi(accent_color, 0.95)
		add_child(_box(Vector3(x_off, (groove_y + screen_top) * 0.5, fz - 0.006),
			Vector3(0.016, groove_y - screen_top, 0.014), lit))
		# junction box where the conduit meets the screen bezel
		add_child(_box(Vector3(x_off, screen_top, fz - 0.002),
			Vector3(0.05, 0.035, 0.024), _mat(panel_color.darkened(0.22))))


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


# ── UPKEEP ───────────────────────────────────────────────────────────────────
# One axis, four moments, shared word for word with station_pillar.gd,
# station_crates.gd, station_wall.gd and station_floorline.gd. Every value dresses
# the pedestal below the cap; none of them touches the presenting surface, because
# something is standing on it.

## WORKS — the pedestal opened up. The front access panel is swung out on its hinge, the loom
## behind it spills down to the floor, and a tray of tools has been left on the cap. The panel
## is the silhouette change: a plate standing off a face that is otherwise flush, projecting
## about a fifth of the body width into the room.
func _upkeep_works(cap_w: float, cap_d: float, body_w: float, body_d: float,
		body_bottom: float, body_h: float, th: float) -> void:
	var steel: StandardMaterial3D = HangarKit.worn_metal(panel_color.lightened(0.05))
	var dark: StandardMaterial3D = HangarKit.finish_body("terminal", body_color.darkened(0.6), 0.9)
	var pw: float = body_w * 0.78
	var ph2: float = body_h * 0.46
	var cy: float = body_bottom + body_h * 0.52
	# The opening the panel came off — a recessed dark bay in the front face.
	add_child(_box(Vector3(0, cy, body_d * 0.5 + 0.006), Vector3(pw, ph2, 0.012), dark))
	# The panel itself, hinged at the -X edge and swung out toward the room.
	var hinge := Node3D.new()
	hinge.position = Vector3(-pw * 0.5, cy, body_d * 0.5 + 0.014)
	hinge.rotation_degrees = Vector3(0, -58, 0)
	add_child(hinge)
	var leaf: MeshInstance3D = _box(Vector3(pw * 0.5, 0, 0), Vector3(pw, ph2, 0.018), _mat(panel_color))
	hinge.add_child(leaf)
	hinge.add_child(_box(Vector3(pw * 0.5, ph2 * 0.5 - 0.02, 0.012), Vector3(pw * 0.7, 0.016, 0.008),
		HangarKit.worn_metal(panel_color.darkened(0.2))))
	# The loom, spilling out of the bay and down to the floor in three runs.
	var loom: StandardMaterial3D = HangarKit.worn_metal(accent_color.darkened(0.35))
	add_child(_box(Vector3(pw * 0.18, cy - ph2 * 0.4, body_d * 0.5 + 0.05),
		Vector3(0.03, ph2 * 0.5, 0.03), loom))
	add_child(_box(Vector3(pw * 0.18, body_bottom + 0.06, body_d * 0.5 + 0.10),
		Vector3(0.03, 0.03, 0.16), loom))
	add_child(_box(Vector3(pw * 0.18 + 0.07, body_bottom + 0.03, body_d * 0.5 + 0.17),
		Vector3(0.17, 0.028, 0.028), loom))
	# A tray of tools left on the cap — the surface in use as a bench, not as a display.
	var tw: float = cap_w * 0.52
	var td: float = cap_d * 0.52
	add_child(_box(Vector3(cap_w * 0.16, th + 0.018, -cap_d * 0.12), Vector3(tw, 0.03, td), steel))
	add_child(_box(Vector3(cap_w * 0.16, th + 0.048, -cap_d * 0.12 - td * 0.45),
		Vector3(tw, 0.03, 0.012), steel))
	add_child(_box(Vector3(cap_w * 0.10, th + 0.048, -cap_d * 0.12), Vector3(tw * 0.6, 0.022, 0.022),
		HangarKit.worn_metal(panel_color.darkened(0.3))))
	var q: MeshInstance3D = HangarKit.stencil("WORKS", Vector2(minf(body_w * 0.6, 0.42), body_h * 0.09))
	if q:
		q.position = Vector3(0, body_bottom + body_h * 0.14, body_d * 0.5 + 0.024)
		add_child(q)


## STORE — the pedestal packed down. A dust cover is pulled over it from the foot to above the
## cap and banded twice, which covers the panel field, the three-colour bar and the rim light
## together. The plinth stops being a surface that presents anything and becomes a wrapped
## volume: the one silhouette in the family that is bigger than the piece inside it.
func _upkeep_store(cap_w: float, cap_d: float, th: float) -> void:
	var sheet: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.31, 0.33), 0.88)
	sheet.roughness = 0.95
	var y0: float = PLINTH_THICK + 0.01
	var y1: float = th + 0.05
	add_child(_box(Vector3(0, (y0 + y1) * 0.5, 0),
		Vector3(cap_w + 0.05, y1 - y0, cap_d + 0.05), sheet))
	var strap: StandardMaterial3D = HangarKit.painted_metal(Color(0.86, 0.34, 0.11), 0.55)
	for f in [0.28, 0.72]:
		add_child(_box(Vector3(0, y0 + (y1 - y0) * f, 0),
			Vector3(cap_w + 0.075, 0.022, cap_d + 0.075), strap))
	var q: MeshInstance3D = HangarKit.stencil("PACKED", Vector2(minf(cap_w * 0.62, 0.42), th * 0.07))
	if q:
		q.position = Vector3(0, y0 + (y1 - y0) * 0.50, (cap_d + 0.05) * 0.5 + 0.008)
		add_child(q)


## SCRAP — robbed. The front cladding has been taken off the body and the studs behind it are
## bared, with tape across the opening and the fixings left on the foot plate. The rim channel
## above it is already dead metal from the guard in _build(). The block is still there; what
## was ON it is not.
func _upkeep_scrap(body_w: float, body_d: float, body_bottom: float, body_h: float) -> void:
	var dark: StandardMaterial3D = HangarKit.finish_body("terminal", body_color.darkened(0.58), 0.95)
	var stud: StandardMaterial3D = HangarKit.worn_metal(panel_color.darkened(0.32))
	var cy: float = body_bottom + body_h * 0.5
	var vw: float = body_w * 0.98
	var vh: float = body_h * 0.86
	var fz: float = body_d * 0.5 + 0.022
	# The void where the panel field was — set proud of the face so the plates behind it
	# cannot show past its edge at the shallow angle the sweep camera reads it from.
	add_child(_box(Vector3(0, cy, fz), Vector3(vw, vh, 0.014), dark))
	# Studs standing in the void — the structure the cladding was hiding.
	for i in range(3):
		var sx: float = lerpf(-vw * 0.36, vw * 0.36, float(i) / 2.0)
		add_child(_box(Vector3(sx, cy, fz + 0.010), Vector3(0.028, vh * 0.94, 0.018), stud))
	# Two tape runs across the opening, crossed off square.
	for i in range(2):
		var f: float = 0.32 if i == 0 else 0.66
		var t: MeshInstance3D = _box(Vector3(0, body_bottom + body_h * f, fz + 0.020),
			Vector3(vw * 1.02, 0.05, 0.008), HangarKit.striped_mat())
		t.rotation_degrees = Vector3(0, 0, 7.0 if i == 0 else -7.0)
		add_child(t)
	# The fixings, left on the foot plate in front of the robbed face.
	var loose: Node3D = HangarKit.bolts(
		Vector3(-body_w * 0.3, PLINTH_THICK + 0.03, body_d * 0.5 + 0.055),
		Vector3(body_w * 0.3, PLINTH_THICK + 0.03, body_d * 0.5 + 0.055),
		4, 0.018, HangarKit.worn_metal(panel_color.darkened(0.36)))
	loose.rotation_degrees = Vector3(-90, 0, 0)
	add_child(loose)
