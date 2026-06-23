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
	if has_meta("config_start_cap"): start_cap = _b(get_meta("config_start_cap"))
	if has_meta("config_end_cap"): end_cap = _b(get_meta("config_end_cap"))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_panel_style"): panel_style = str(get_meta("config_panel_style")).to_lower()
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

	# Main slab — origin at floor centre, grows +Y, thin in Z, XY plane facing +Z.
	add_child(_box(Vector3(0, h * 0.5, 0), Vector3(w, h, SLAB_DEPTH), body_mat))

	# Top rail beam — caps the run visually and continues across joins.
	add_child(_box(Vector3(0, h - RAIL_H * 0.5, 0), Vector3(w, RAIL_H, SLAB_DEPTH + 0.05), _mat(panel_color)))

	# Per-cell dressing so seams land on every 1 m boundary (the modular read).
	match panel_style:
		"ribbed": _build_ribs(n, w, h)
		"perforated": _build_perforation(n, w, h)
		_: _build_cell_panels(n, w, h)

	# Boundary seam strips at every internal 1 m line.
	_build_seams(n, w, h)

	# End-cap posts — only where this section begins/ends a run.
	if start_cap:
		_build_cap(-w * 0.5, h)
	if end_cap:
		_build_cap(w * 0.5, h)

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
		add_child(_box(Vector3(0, 0.09, FRONT_Z + 0.02), Vector3(w, 0.18, 0.02), HangarKit.striped_mat()))
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.32, 0.6), h * 0.07))
		if q:
			q.position = Vector3(-w * 0.5 + 0.4, h * 0.12, FRONT_Z + 0.07)
			add_child(q)


# One inset plate per grid cell — the seams between them sit on the 1 m lines.
func _build_cell_panels(n: int, w: float, h: float) -> void:
	var pmat := _mat(panel_color)
	var inset := 0.08
	var ph: float = h - RAIL_H - inset * 2.0
	var t := 0.03
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		add_child(_box(Vector3(cx, inset + ph * 0.5, FRONT_Z + t * 0.5), Vector3(CELL - inset * 2.0, ph, t), pmat))


func _build_ribs(n: int, w: float, h: float) -> void:
	var rmat := _mat(body_color.lightened(0.05))
	var rib_h: float = h - RAIL_H - 0.16
	# two ribs per cell — a reinforced bulkhead read, still on the grid.
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		for off in [-0.22, 0.22]:
			add_child(_box(Vector3(cx + off, 0.08 + rib_h * 0.5, FRONT_Z + 0.04), Vector3(0.08, rib_h, 0.06), rmat))


func _build_perforation(n: int, w: float, h: float) -> void:
	var holes := _mat(panel_color.darkened(0.5))
	var rows := 6
	for i in range(n):
		var cx: float = -w * 0.5 + (float(i) + 0.5) * CELL
		for c in range(3):
			for r in range(rows):
				var px: float = cx + lerpf(-0.3, 0.3, float(c) / 2.0)
				var py: float = lerpf(h * 0.32, h * 0.72, float(r) / float(rows - 1))
				add_child(_box(Vector3(px, py, FRONT_Z + 0.04), Vector3(0.14, 0.14, 0.04), holes))


# Thin vertical strips on every internal cell boundary — the visible grid join.
func _build_seams(n: int, w: float, h: float) -> void:
	var smat := HangarKit.worn_metal(panel_color)
	var sh: float = h - RAIL_H
	for i in range(1, n):
		var sx: float = -w * 0.5 + float(i) * CELL
		add_child(_box(Vector3(sx, sh * 0.5, FRONT_Z + 0.03), Vector3(0.04, sh, 0.04), smat))


# A vertical end-cap post — a structural column that begins or closes a wall run.
func _build_cap(x: float, h: float) -> void:
	var post_mat := _mat(panel_color.darkened(0.06))
	add_child(_box(Vector3(x, h * 0.5, 0), Vector3(POST_W, h, POST_W), post_mat))
	# a slim accent groove down the outward face
	add_child(_box(Vector3(x, h * 0.5, POST_W * 0.5 + 0.01), Vector3(0.04, h * 0.7, 0.02), _emi(accent_color, 0.5)))


func _build_screen(w: float, h: float) -> void:
	var sw: float = minf(w * 0.42, 0.8)
	var sh: float = sw * 0.62
	var screen: Node3D = HangarKit.readout(screen_header, screen_lines, Vector2(sw, sh))
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
