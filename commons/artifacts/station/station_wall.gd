extends Node3D
class_name StationWall

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR backing wall for a curation station — a painted-metal panel run that is EXACTLY length_cells metres wide (1 m per cell), with optional end caps, so sections butt edge-to-edge on the 1 m grid and read as one continuous wall. Origin at the floor centre; plane is XY facing +Z, thin in Z.
# desire: to give a curated set a built behind — a wall you assemble from a start cap, repeated 1 m/2 m mid panels, and an end cap, every seam landing on a grid line so nothing floats and nothing misaligns.
# critical_parameter: length_cells + start_cap/end_cap — THE tiling decision. A run is [start_cap wall] + [no-cap mids] + [end_cap wall]; panel seams sit on every 1 m boundary so adjacent sections continue the rhythm.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new length/style/dressing.
# emerges: capped ends read "this is where the wall begins/ends"; uncapped ends read "more wall continues here"; lit seam + readout read "powered, monitored"; the per-cell panels read "modular, built to a grid".
# needs: a slab body of width length_cells m [present]; per-cell inset panels + boundary seam strips [present]; optional end-cap posts, top rail, lit seam, readout, three-colour bar, stencil [optional].
# relationships: the backing sibling of [[station_stage]] (stand the set ON that, back it AGAINST this); shares the HangarKit family look with [[hangar_wall_panel]] but tiles on the grid; assembled by [[curation_station]].
# truth: a modular wall is an argument that a place was built to a measure. The grid is visible in the seams; the room admits it was made, cell by cell.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Grid")
## Wall length in 1 m grid cells (the body is exactly this many metres wide).
@export var length_cells: int = 2
## A vertical end-cap post at the start (−X) face — the piece that begins a run.
@export var start_cap: bool = false
## A vertical end-cap post at the end (+X) face — the piece that closes a run.
@export var end_cap: bool = false

@export_group("Dimensions")
## Wall height (Y, grows up from the floor).
@export var height: float = 2.5

@export_group("Style")
## "panel" (inset plates per cell) | "ribbed" (vertical ribs) | "perforated" (vent hole grid).
@export var panel_style: String = "panel"
## Cells per panel face. 1 = a plate every metre (busy on long walls); higher groups cells into
## fewer, larger plates (seams land on panel boundaries to match).
@export var panel_cells: int = 1
## Embed a small framed readout screen in the upper centre.
@export var screen_slot: bool = false
## Readout header + lines (2D-in-3D screen text). The composer fills these with the curated set.
@export var screen_header: String = "CURATION"
@export var screen_lines: Array = ["SET ONLINE", "LINK  OK"]
## Emissive accent band along the top, full wall width — runs edge-to-edge and continues across tiled sections.
@export var lit_seam: bool = true
## Caution-stripe band along the floor foot.
@export var hazard_base: bool = false

@export_group("Surface")
## Stencilled ID painted low on the face (e.g. "WALL-A"). Empty = none.
@export var stencil_text: String = ""
## Weathering 0..1 — subtle dust by default (Rams clean).
@export var wear: float = 0.08
## Three-colour Rams accent bar across the upper front face.
@export var three_bar: bool = true
## Faint dust band at the foot + dust streaks on the main face.
@export var grime: bool = true
## A thin recessed bevel border framing the whole slab face — the machined-edge read.
@export var bevel_frame: bool = true
## Rows of bolt heads at the top/bottom rails and end-cap posts — the bolted-on read.
@export var bolt_rows: bool = true
## A continuous shadow-gap reveal lifting the slab a few cm off the floor (reads "set onto a base").
@export var base_reveal: bool = true
## A vertical recessed accent groove (a lit channel) at each end of the run — the warm seam down the face.
@export var lit_groove: bool = true
## Mount a framed 2D-in-3D caption plate proud of the face on a small bracket (the curation caption).
@export var caption_text: String = ""
## Caption sub-lines under the caption header.
@export var caption_lines: Array = []

@export_group("Color")
## Dieter Rams / Braun default — light matte body so the housing recedes; one warm accent.
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

# ── Constants ─────────────────────────────────────────────────────────
const CELL := 1.0
const SLAB_DEPTH := 0.15
const POST_W := 0.26          # end-cap post width (X/Z)
const RAIL_H := 0.12          # top rail height
const FRONT_Z := SLAB_DEPTH * 0.5

var _built := false

# ── Lifecycle ─────────────────────────────────────────────────────────
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
	elif has_meta("config_width_cells"): length_cells = int(str(get_meta("config_width_cells")))   # editor/cluster/WallHangar pass width_cells for the wall's run length
	if has_meta("config_start_cap"): start_cap = _b(get_meta("config_start_cap"))
	if has_meta("config_end_cap"): end_cap = _b(get_meta("config_end_cap"))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_panel_style"): panel_style = str(get_meta("config_panel_style")).to_lower()
	if has_meta("config_panel_cells"): panel_cells = maxi(1, int(str(get_meta("config_panel_cells"))))
	if has_meta("config_screen_slot"): screen_slot = _b(get_meta("config_screen_slot"))
	if has_meta("config_screen_header"): screen_header = str(get_meta("config_screen_header"))
	if has_meta("config_screen_lines"):
		var raw = get_meta("config_screen_lines")
		if raw is Array:
			screen_lines = []
			for ln in raw:
				screen_lines.append(str(ln))
	if has_meta("config_lit_seam"): lit_seam = _b(get_meta("config_lit_seam"))
	if has_meta("config_hazard_base"): hazard_base = _b(get_meta("config_hazard_base"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_bevel_frame"): bevel_frame = _b(get_meta("config_bevel_frame"))
	if has_meta("config_bolt_rows"): bolt_rows = _b(get_meta("config_bolt_rows"))
	if has_meta("config_base_reveal"): base_reveal = _b(get_meta("config_base_reveal"))
	if has_meta("config_lit_groove"): lit_groove = _b(get_meta("config_lit_groove"))
	if has_meta("config_caption_text"): caption_text = str(get_meta("config_caption_text"))
	if has_meta("config_caption_lines"):
		var rawc = get_meta("config_caption_lines")
		if rawc is Array:
			caption_lines = []
			for ln in rawc:
				caption_lines.append(str(ln))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var n: int = maxi(length_cells, 1)
	var w: float = float(n) * CELL
	var h: float = maxf(height, 0.5)
	var body_mat := _mat(body_color)

	# Shadow-gap base reveal: the slab sits on a slim recessed plinth so it reads as
	# SET ONTO the floor (a machined edge, not poured into it). The reveal lifts the body.
	var foot: float = 0.05 if base_reveal else 0.0
	if base_reveal:
		# A slightly inset, darker base shoe running the full width — the shadow gap.
		add_child(_box(Vector3(0, foot * 0.5, 0), Vector3(w + 0.02, foot, SLAB_DEPTH * 0.78), HangarKit.worn_metal(panel_color)))

	# Main slab — origin at floor centre (lifted by the reveal foot), grows +Y, thin in Z.
	var body_cy: float = foot + (h - foot) * 0.5
	add_child(_box(Vector3(0, body_cy, 0), Vector3(w, h - foot, SLAB_DEPTH), body_mat))

	# Top rail beam — a chamfered cap: a wide trim plus a slim chamfer lip proud of the front.
	add_child(_box(Vector3(0, h - RAIL_H * 0.5, 0), Vector3(w, RAIL_H, SLAB_DEPTH + 0.05), _mat(panel_color)))
	add_child(_box(Vector3(0, h - RAIL_H - 0.012, FRONT_Z + 0.012), Vector3(w, 0.024, 0.03), HangarKit.worn_metal(panel_color)))

	# Recessed bevel frame around the whole face — the machined-edge read (a thin inner border).
	if bevel_frame:
		_build_bevel_frame(w, h, foot)

	# Per-cell dressing so seams land on every 1 m boundary (the modular read).
	match panel_style:
		"ribbed": _build_ribs(n, w, h, foot)
		"perforated": _build_perforation(n, w, h, foot)
		_: _build_cell_panels(n, w, h, foot)

	# Boundary seam strips at every internal 1 m line.
	_build_seams(n, w, h, foot)

	# Bolt rows along the top and bottom rails — the bolted-on read (skips cap posts; they get their own).
	if bolt_rows:
		var bmat := HangarKit.worn_metal(panel_color.darkened(0.1))
		var inX: float = 0.18
		add_child(HangarKit.bolts(Vector3(-w * 0.5 + inX, h - RAIL_H * 0.5, FRONT_Z + 0.03), Vector3(w * 0.5 - inX, h - RAIL_H * 0.5, FRONT_Z + 0.03), maxi(n + 1, 2), 0.022, bmat))
		add_child(HangarKit.bolts(Vector3(-w * 0.5 + inX, foot + 0.12, FRONT_Z + 0.03), Vector3(w * 0.5 - inX, foot + 0.12, FRONT_Z + 0.03), maxi(n + 1, 2), 0.022, bmat))

	# End-cap posts — only where this section begins/ends a run.
	if start_cap:
		_build_cap(-w * 0.5, h, foot)
	if end_cap:
		_build_cap(w * 0.5, h, foot)

	# Vertical recessed accent grooves down the inner edges — the warm lit channel.
	if lit_groove:
		var gx: float = w * 0.5 - 0.14
		for sx in [-gx, gx]:
			# a recessed dark channel...
			add_child(_box(Vector3(sx, foot + (h - foot) * 0.5, FRONT_Z + 0.015), Vector3(0.05, (h - foot) * 0.82, 0.02), HangarKit.worn_metal(panel_color.darkened(0.4))))
			# ...with a slim warm light inside it.
			add_child(_box(Vector3(sx, foot + (h - foot) * 0.5, FRONT_Z + 0.03), Vector3(0.018, (h - foot) * 0.7, 0.015), _emi(accent_color, 0.7)))

	if lit_seam:
		# Full slab width so the band reaches the wall ends (the caps) and butts
		# continuously across tiled sections — no gap at the joins.
		add_child(_box(Vector3(0, h - RAIL_H - 0.04, FRONT_Z + 0.05), Vector3(w, 0.06, 0.025), _emi(accent_color, 0.8)))
	if screen_slot:
		_build_screen(w, h)
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(minf(w * 0.5, 1.2), 0.05, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
		bar.position = Vector3(0, h - RAIL_H - 0.16, FRONT_Z + 0.05)
		add_child(bar)
	if grime:
		add_child(HangarKit.grime_band(w, 0.08, FRONT_Z + 0.02, body_color))
		var streaks := HangarKit.dust_streaks(w * 0.85, h * 0.8, FRONT_Z + 0.06, 4)
		streaks.position = Vector3(0, h * 0.5, 0)
		add_child(streaks)
	if hazard_base:
		add_child(_box(Vector3(0, foot + 0.09, FRONT_Z + 0.02), Vector3(w, 0.18, 0.02), HangarKit.striped_mat()))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.32, 0.6), h * 0.07))
		if q:
			q.position = Vector3(-w * 0.5 + 0.4, foot + 0.12, FRONT_Z + 0.07)
			add_child(q)

	# Curation caption — a framed 2D-in-3D plate mounted proud of the face on a bracket
	# (surface-pinned text, joined to the wall; not a floating label).
	if caption_text.strip_edges() != "":
		var cw: float = minf(w * 0.5, 0.9)
		var sign: Node3D = HangarKit.signage(caption_text, caption_lines, Vector2(cw, cw * 0.32), 0.12, Vector3(0, 0, 1))
		sign.position = Vector3(0, h * 0.40, FRONT_Z + 0.02)
		add_child(sign)

	# Solid in-game: a body collider covering the wall slab.
	add_child(HangarKit.box_collider(Vector3(w, h, SLAB_DEPTH), Vector3(0, h * 0.5, 0)))


# A thin recessed bevel border framing the slab face — four worn-metal trim bars set just inside
# the edges, reading as a machined inset around the negative space of the panel field.
func _build_bevel_frame(w: float, h: float, foot: float) -> void:
	var fmat := HangarKit.worn_metal(panel_color.darkened(0.18))
	var m: float = 0.05                       # margin in from each edge
	var t: float = 0.03                       # bar thickness
	var iy0: float = foot + m
	var iy1: float = h - RAIL_H - m
	var ih: float = iy1 - iy0
	var iw: float = w - m * 2.0
	var cy: float = (iy0 + iy1) * 0.5
	var z: float = FRONT_Z + 0.01
	# top + bottom
	add_child(_box(Vector3(0, iy1, z), Vector3(iw, t, 0.018), fmat))
	add_child(_box(Vector3(0, iy0, z), Vector3(iw, t, 0.018), fmat))
	# left + right
	add_child(_box(Vector3(-iw * 0.5, cy, z), Vector3(t, ih, 0.018), fmat))
	add_child(_box(Vector3(iw * 0.5, cy, z), Vector3(t, ih, 0.018), fmat))


# One inset plate per grid cell — the seams between them sit on the 1 m lines. Each plate gets a
# slim recessed inner border (a double-bevel read) so the panel field feels machined, not flat.
func _build_cell_panels(n: int, w: float, h: float, foot: float) -> void:
	var pmat := _mat(panel_color)
	var imat := _mat(panel_color.darkened(0.08))
	var inset := 0.10
	var ph: float = h - RAIL_H - foot - inset * 2.0
	# Group cells into fewer, larger plates: count panels by panel_cells, divide w evenly so they fit.
	var count: int = maxi(1, int(round(w / (float(maxi(panel_cells, 1)) * CELL))))
	var step: float = w / float(count)
	var pw: float = step - inset * 2.0
	var t := 0.03
	for i in range(count):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * step
		var cy: float = foot + inset + ph * 0.5
		# the raised plate...
		add_child(_box(Vector3(cx, cy, FRONT_Z + t * 0.5), Vector3(pw, ph, t), pmat))
		# ...with a slightly recessed darker inner face for depth.
		add_child(_box(Vector3(cx, cy, FRONT_Z + t * 0.5 - 0.006), Vector3(pw - 0.07, ph - 0.07, t * 0.5), imat))


func _build_ribs(n: int, w: float, h: float, foot: float) -> void:
	var rmat := _mat(body_color.lightened(0.05))
	var rib_h: float = h - RAIL_H - foot - 0.16
	# two ribs per cell — a reinforced bulkhead read, still on the grid.
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		for off in [-0.22, 0.22]:
			add_child(_box(Vector3(cx + off, foot + 0.08 + rib_h * 0.5, FRONT_Z + 0.04), Vector3(0.08, rib_h, 0.06), rmat))


func _build_perforation(n: int, w: float, h: float, foot: float) -> void:
	var holes := _mat(panel_color.darkened(0.5))
	var rows := 6
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		for c in range(3):
			for r in range(rows):
				var px: float = cx + lerpf(-0.3, 0.3, float(c) / 2.0)
				var py: float = lerpf(maxf(h * 0.32, foot + 0.3), h * 0.72, float(r) / float(rows - 1))
				add_child(_box(Vector3(px, py, FRONT_Z + 0.04), Vector3(0.14, 0.14, 0.04), holes))


# Thin vertical strips on every internal cell boundary — the visible grid join.
func _build_seams(n: int, w: float, h: float, foot: float) -> void:
	var smat := HangarKit.worn_metal(panel_color)
	var sh: float = h - RAIL_H - foot
	# Seams on panel boundaries (match _build_cell_panels' grouping), not every metre.
	var count: int = maxi(1, int(round(w / (float(maxi(panel_cells, 1)) * CELL))))
	var step: float = w / float(count)
	for i in range(1, count):
		var sx: float = -w * 0.5 + float(i) * step
		add_child(_box(Vector3(sx, foot + sh * 0.5, FRONT_Z + 0.03), Vector3(0.04, sh, 0.04), smat))


# A vertical end-cap post — a structural column that begins or closes a wall run, with a slim
# warm accent groove down the outward face and a vertical bolt row pinning it on.
func _build_cap(x: float, h: float, foot: float) -> void:
	var post_mat := _mat(panel_color.darkened(0.06))
	var ph: float = h - foot
	add_child(_box(Vector3(x, foot + ph * 0.5, 0), Vector3(POST_W, ph, POST_W), post_mat))
	# a slim accent groove down the outward face
	add_child(_box(Vector3(x, foot + ph * 0.5, POST_W * 0.5 + 0.01), Vector3(0.04, ph * 0.7, 0.02), _emi(accent_color, 0.5)))
	# a vertical bolt row on the front face of the post.
	if bolt_rows:
		var bmat := HangarKit.worn_metal(panel_color.darkened(0.12))
		var bz: float = POST_W * 0.5 + 0.02
		add_child(HangarKit.bolts(Vector3(x, foot + ph * 0.18, bz), Vector3(x, foot + ph * 0.82, bz), 4, 0.02, bmat))


func _build_screen(w: float, h: float) -> void:
	var sw: float = minf(w * 0.42, 0.8)
	var sh: float = sw * 0.62
	# Black text on a matte off-white label (not a dark screen).
	var screen: Node3D = HangarKit.readout(screen_header, screen_lines, Vector2(sw, sh), Color(0.88, 0.86, 0.80), Color(0.09, 0.09, 0.11), Color(0.09, 0.09, 0.11))
	if screen:
		screen.position = Vector3(0, h * 0.62, FRONT_Z + 0.06)
		add_child(screen)


# ── Local helpers ─────────────────────────────────────────────────────
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
