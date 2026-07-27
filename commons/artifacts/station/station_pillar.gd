extends Node3D
class_name StationPillar

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR corner column of a curation station — a square painted-metal pillar that claims one 1 m cell and rises to height, banded with a lit accent groove, a chamfered base/capital, a Rams three-colour bar, a caution-stripe kick band and a bolted foot. Origin at the floor centre. The vertical that turns a flat backing into a built bay corner.
# desire: to mark where the room turns — to give a wall run a corner to die into and an artifact set an upright frame, so the stage reads as architecture, not furniture in a void.
# critical_parameter: height + post_width — how tall and how heavy the corner reads; the composer matches it to the backing wall height; upkeep — WHICH MOMENT of the bay's working life this corner is caught in (service | works | store | scrap), the shared axis with [[station_crates]].
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a plain shaft reads "structure"; a lit groove reads "powered"; a chamfered capital + bolted base reads "finished, intentional, load-bearing"; a fluted shaft reads "monumental"; a readout face reads "this corner reports"; a scaffolded shaft reads "mid-job"; a sleeved shaft reads "not in commission"; a half-clad shaft with a dead groove reads "robbed".
# needs: a bolted base plate [present]; a chamfered shaft [present]; a chamfered capital [present]; a lit accent groove [present]; a caution kick band [present]; a Rams accent bar [present]; optional readout face / surface-pinned signage [optional].
# relationships: the upright that ends a [[station_wall]] run and frames the [[station_stage]]; placed at the back corners by [[curation_station]]; the single-upright cousin of [[station_frame]]'s ring; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family look; KIN of [[station_crates]] — the two halves of one `upkeep` vocabulary, the structure and the stuff telling the same time.
# truth: a column is the oldest claim that a place is built. One upright, repeated, makes a room out of an open floor — and how it meets the floor (bolted, chamfered, banded) is the proof that it was meant.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27) — the KIN PAIR axis, shared verbatim with
# station_crates.gd. Read that file's block too; they are one promotion.
#
# This artifact's truth line says the way a column meets the floor is "the proof
# that it was MEANT" — a claim about time, about a decision made once and then
# maintained. But the column had no time. Every one of its 77 placements, and
# every pillar inside the 451 curation_station bays, renders the same instant:
# commissioned, powered, unscuffed, hours old. A column that can only be new
# cannot make a claim about having been meant.
#
#   upkeep   WHICH MOMENT of the working life   service · works · store · scrap
#
#   service  in commission  — the legacy lineage, byte for byte
#   works    mid-job        — a scaffold cage, a board deck, conduit, WORKS
#   store    packed down    — the shaft sleeved and banded, the groove dark
#   scrap    robbed         — half the cladding gone, dead groove, rust, tape
#
# The groove is the pivot. It is the only emissive surface on the piece and so
# owns the brightest pixels in any frame the column appears in; `store` covers it
# and `scrap` rebuilds it as a dead recessed channel in worn metal. That is the
# difference between a column that is on and a column that is not, and it is
# visible from across a room rather than only under measurement.
#
# What it cost: `_build()` now carries four guards through what used to be a
# straight run of construction, and `_face_z()` means the front-face literals no
# longer appear inline — a reader has to hop one function to know where a stencil
# lands. Every guard is written so `service` evaluates to the old expression.
#
# Deliberately NOT routed through upkeep: `height` and `post_width`. The composer
# matches pillar height to its backing wall, so an upkeep value that changed the
# envelope would tear a hole in every bay it was used in. Upkeep dresses the
# column; it never resizes it.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Pillar height (Y).
@export var height: float = 2.5
## Shaft width (X/Z) — fits inside a 1 m cell.
@export var post_width: float = 0.42
## Chamfer cut on the base + capital edges (0 = square block, larger = more tapered/finished).
@export var chamfer: float = 0.06

@export_group("Style")
## Vertical lit accent groove down each face.
@export var lit_groove: bool = true
## A small framed readout on the +Z face.
@export var readout_face: bool = false
## "plate" (flat slab cap) | "stepped" (two-tier crown) | "bevel" (chamfer-only). Capital + base style.
@export var cap_style: String = "stepped"
## Number of vertical flutes (recessed reeds) per face. 0 = a single recessed panel (classic look).
@export var flute_count: int = 0
## "rams" (light Braun default) | "terminal" (dark charcoal console finish).
@export var finish: String = "rams"

@export_group("Upkeep")
## THE AXIS (shared with station_crates) — which moment of the bay's working life
## this corner is caught in. "service" is the legacy default and reproduces the
## commissioned column exactly. The other three dress, sleeve or strip it; none of
## them changes `height` or `post_width`, so a bay's framing survives every value.
## service | works | store | scrap
@export var upkeep: String = "service"

@export_group("Surface")
## A Dieter-Rams three-colour accent bar near the capital.
@export var three_bar: bool = true
## Bolt rows on the base plate corners and capital underside.
@export var bolts: bool = true
## A diagonal caution-stripe kick band around the base.
@export var caution_stripe: bool = true
## Faint vertical dust streaks down the front face (restrained dirt).
@export var dust: bool = true
@export var stencil_text: String = ""
## Surface-pinned signage line (header on a bracketed plate, +Z). Empty = none.
@export var signage_text: String = ""
@export var wear: float = 0.08
@export var grime: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const BASE_H := 0.14
const CAP_H := 0.12
const SLEEVE_OUT := 0.10          # how far the "store" wrap stands proud of the shaft

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
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_post_width"): post_width = float(str(get_meta("config_post_width")))
	if has_meta("config_chamfer"): chamfer = float(str(get_meta("config_chamfer")))
	if has_meta("config_lit_groove"): lit_groove = _b(get_meta("config_lit_groove"))
	if has_meta("config_readout_face"): readout_face = _b(get_meta("config_readout_face"))
	if has_meta("config_cap_style"): cap_style = str(get_meta("config_cap_style")).to_lower()
	if has_meta("config_flute_count"): flute_count = int(str(get_meta("config_flute_count")))
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()
	if has_meta("config_upkeep"): upkeep = str(get_meta("config_upkeep")).to_lower()
	if has_meta("config_three_bar"): three_bar = _b(get_meta("config_three_bar"))
	if has_meta("config_bolts"): bolts = _b(get_meta("config_bolts"))
	if has_meta("config_caution_stripe"): caution_stripe = _b(get_meta("config_caution_stripe"))
	if has_meta("config_dust"): dust = _b(get_meta("config_dust"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_signage_text"): signage_text = str(get_meta("config_signage_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_grime"): grime = _b(get_meta("config_grime"))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var h: float = maxf(height, 0.6)
	var pw: float = clampf(post_width, 0.2, 0.95)
	var ch: float = clampf(chamfer, 0.0, pw * 0.32)

	# Finish drives the family palette; explicit colours still win if they were set away from default.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var is_terminal: bool = finish == "terminal"
	var bcol: Color = body_color if not is_terminal else pal["body"]
	var pcol: Color = panel_color if not is_terminal else pal["panel"]
	var acol: Color = accent_color if not is_terminal else pal["accent"]
	var ewear: float = maxf(wear, float(pal.get("wear", wear)))

	var body_mat := _body_mat(bcol, ewear)
	var trim_mat := _body_mat(bcol.darkened(0.05), ewear)
	var foot_mat := HangarKit.worn_metal(pcol.darkened(0.06))

	var shaft_bottom: float = BASE_H
	var shaft_top: float = h - CAP_H
	var shaft_h: float = maxf(shaft_top - shaft_bottom, 0.2)
	var shaft_cy: float = shaft_bottom + shaft_h * 0.5

	# ── Base: a wide foot plate + a chamfered plinth block ──
	var foot_w: float = pw + 0.18
	add_child(_box(Vector3(0, BASE_H * 0.32, 0), Vector3(foot_w, BASE_H * 0.64, foot_w), foot_mat))
	_build_crown(pw + 0.10, BASE_H * 0.62, BASE_H * 0.64 + (BASE_H * 0.38) * 0.5, ch, trim_mat, false)

	# ── Shaft ──
	# upkeep "scrap" swaps the solid shaft for the frame that is left after the
	# cladding was pulled. Every other value takes the legacy line unchanged.
	if upkeep == "scrap":
		_scrap_shaft(pw, shaft_cy, shaft_h, pcol, ewear, body_mat)
	else:
		add_child(_box(Vector3(0, shaft_cy, 0), Vector3(pw, shaft_h, pw), body_mat))

	# ── Capital crown ── (a robbed column has lost its top tier)
	_build_crown(pw + 0.12, CAP_H, h - CAP_H * 0.5, ch, trim_mat,
		cap_style == "stepped" and upkeep != "scrap")

	# ── Recessed face detail: flutes or a single inset panel, per side ──
	# _clad() is false only under "store" (the sleeve covers the faces) and
	# "scrap" (_scrap_shaft has already put back the two panels that survived).
	if flute_count > 0:
		if _clad():
			_build_flutes(pw, shaft_cy, shaft_h, pcol, ewear)
	elif _clad():
		_build_panels(pw, shaft_cy, shaft_h, pcol, ewear)

	# ── Lit accent groove down each face ──
	# The pivot of the whole axis: the only emissive surface on the piece. "store"
	# buries it under the sleeve; "scrap" keeps the channel but kills the light.
	if lit_groove and upkeep != "store":
		var lit: StandardMaterial3D = HangarKit.emissive(acol, 0.85)
		if upkeep == "scrap":
			lit = HangarKit.worn_metal(Color(0.07, 0.07, 0.08))   # the channel, unpowered
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var center: Vector3 = nrm * (pw * 0.5 + 0.012) + Vector3(0, shaft_cy, 0)
			var size: Vector3 = Vector3(0.022, shaft_h * 0.72, 0.034) if absf(nrm.x) > 0.5 else Vector3(0.034, shaft_h * 0.72, 0.022)
			add_child(_box(center, size, lit))

	# ── Caution-stripe kick band around the base of the shaft ──
	if caution_stripe:
		var smat: StandardMaterial3D = HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
		if upkeep == "scrap":
			smat = HangarKit.striped_mat(Color(0.52, 0.46, 0.30), Color(0.13, 0.12, 0.11))   # sun-bleached
		var band_y: float = shaft_bottom + 0.10
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var center: Vector3 = nrm * (pw * 0.5 + 0.006) + Vector3(0, band_y, 0)
			var size: Vector3 = Vector3(0.012, 0.075, pw * 0.9) if absf(nrm.x) > 0.5 else Vector3(pw * 0.9, 0.075, 0.012)
			add_child(_box(center, size, smat))

	# ── Bolt rows: foot corners + under the capital ──
	if bolts:
		var bolt_mat := HangarKit.worn_metal(pcol.darkened(0.2))
		var br: float = 0.014
		var bz: float = pw * 0.5 + 0.012
		# two bolts low on the front face (foot)
		add_child(HangarKit.bolts(Vector3(-pw * 0.32, BASE_H + 0.05, bz), Vector3(pw * 0.32, BASE_H + 0.05, bz), 2, br, bolt_mat))
		# two bolts under the capital on the front face
		add_child(HangarKit.bolts(Vector3(-pw * 0.32, shaft_top - 0.06, bz), Vector3(pw * 0.32, shaft_top - 0.06, bz), 2, br, bolt_mat))

	# ── Rams three-colour accent bar near the capital (front face) ──
	# A sealed bale still wears the maker's bar (it rides out onto the sleeve via
	# _face_z); a robbed column has lost it.
	if three_bar and upkeep != "scrap":
		var bar: Node3D = HangarKit.three_color_bar(pw * 0.78, 0.032, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, shaft_top - 0.16, _face_z() + 0.016)
		add_child(bar)

	# ── Readout face (framed 2D-in-3D screen) ──
	if readout_face:
		var screen: Node3D = HangarKit.readout("NODE", ["ONLINE", "PWR OK"], Vector2(pw * 0.74, pw * 0.5),
			pal["screen"], pal["text"], pal["header"])
		if screen:
			screen.position = Vector3(0, h * 0.6, _face_z() + 0.03)
			add_child(screen)

	# ── Surface-pinned signage line (header on a bracketed plate) ──
	# Inset within the column face: the readout() bezel adds ~max(w,h)*0.06 on each side, so
	# size.x is kept to ~0.62 of pw → the framed plate (panel + bezel) lands ~0.7*pw, leaving a
	# clear margin to the fluted outer edge. A small reach keeps it just proud, not floating off.
	if signage_text.strip_edges() != "":
		var sign_w: float = pw * 0.62
		var sign: Node3D = HangarKit.signage(signage_text, [], Vector2(sign_w, 0.16), 0.045, Vector3(0, 0, 1))
		if sign:
			sign.position = Vector3(0, h * 0.45, _face_z() + 0.01)
			add_child(sign)

	# ── Dust + grime weathering ──
	if dust:
		add_child(HangarKit.dust_streaks(pw * 0.8, shaft_h * 0.6, _face_z() + 0.014, 3))
	if grime:
		add_child(HangarKit.grime_band(foot_w, 0.05, foot_w * 0.5 + 0.004, bcol))

	# ── Stencil text painted onto the shaft ──
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(pw * 0.72, 0.12))
		if q:
			q.position = Vector3(0, shaft_bottom + shaft_h * 0.28, _face_z() + 0.02)
			add_child(q)

	# ── UPKEEP dressing ──
	match upkeep:
		"works":
			_upkeep_works(h, pw, shaft_bottom, shaft_top, pcol, acol, ewear)
		"store":
			_upkeep_store(pw, shaft_bottom, shaft_top, pcol, acol)
		"scrap":
			_upkeep_scrap(pw, shaft_bottom, shaft_h, pcol, ewear)
		_:
			pass                                   # "service" — the legacy lineage


# ── UPKEEP ───────────────────────────────────────────────────────────────────
# One axis, four moments, shared word-for-word with station_crates.gd. Everything
# is built from HangarKit helpers so the family stays inside the cabinet grammar.

# True whenever the shaft's own faces are visible and want their panels/flutes.
func _clad() -> bool:
	return upkeep != "store" and upkeep != "scrap"


# The outermost front face at this upkeep — where a stencil, a sign, a bar or a
# screen has to land to be seen. Returns the literal pw * 0.5 for every value but
# "store", so the legacy placements are unmoved.
func _face_z() -> float:
	var pw: float = clampf(post_width, 0.2, 0.95)
	if upkeep == "store":
		return (pw + SLEEVE_OUT) * 0.5
	return pw * 0.5


# SCRAP shaft — what is left when the cladding has been pulled: a narrow core,
# four corner angles standing full height, and the two panels nobody bothered to
# take (the -X and -Z faces, so the front reads open and the back reads intact).
func _scrap_shaft(pw: float, shaft_cy: float, shaft_h: float, pcol: Color, ewear: float,
		body_mat: Material) -> void:
	var core: float = pw * 0.54
	add_child(_box(Vector3(0, shaft_cy, 0), Vector3(core, shaft_h, core), body_mat))
	var angle_mat: StandardMaterial3D = HangarKit.worn_metal(pcol.darkened(0.18))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_box(Vector3(float(sx) * (pw * 0.5 - 0.026), shaft_cy, float(sz) * (pw * 0.5 - 0.026)),
					Vector3(0.052, shaft_h, 0.052), angle_mat))
	# the surviving cladding
	var pmat: StandardMaterial3D = _body_mat(pcol, ewear)
	var t := 0.02
	for nrm in [Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
		var center: Vector3 = nrm * (pw * 0.5 + t * 0.5) + Vector3(0, shaft_cy, 0)
		var size: Vector3 = Vector3(t, shaft_h * 0.82, pw * 0.62) if absf(nrm.x) > 0.5 else Vector3(pw * 0.62, shaft_h * 0.82, t)
		add_child(_box(center, size, pmat))


# WORKS — the column mid-job. A four-standard scaffold cage rings it with three
# ledger rounds and a board deck at working height; a conduit and junction box run
# up the face; caution tape crosses the front standards and a WORKS placard names
# it. The slim upright becomes a wide hatched mass: the biggest change of outline
# in the family, and the deck boards and tape put bright pixels out at the cage
# edge where the bare column had only floor.
func _upkeep_works(h: float, pw: float, shaft_bottom: float, shaft_top: float,
		pcol: Color, acol: Color, ewear: float) -> void:
	var reach: float = pw * 0.5 + 0.20                 # 0.82 m across at pw = 0.42 — inside the cell
	var tube: StandardMaterial3D = HangarKit.worn_metal(pcol.darkened(0.10))
	var std_h: float = maxf(h - 0.16, 0.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_box(Vector3(float(sx) * reach, std_h * 0.5, float(sz) * reach),
					Vector3(0.048, std_h, 0.048), tube))
	# three ledger rounds
	for i in range(3):
		var ly: float = shaft_bottom + (shaft_top - shaft_bottom) * (0.22 + 0.30 * float(i))
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var lc: Vector3 = nrm * reach + Vector3(0, ly, 0)
			var ls: Vector3 = Vector3(0.036, 0.036, reach * 2.0) if absf(nrm.x) > 0.5 else Vector3(reach * 2.0, 0.036, 0.036)
			add_child(_box(lc, ls, tube))
	# A board deck on the +Z side at the middle round. The boards are fitted into the
	# gap BETWEEN the shaft face and the outer standard — laid any deeper they would
	# be buried inside the column and the deck would read as nothing at all.
	var deck_y: float = shaft_bottom + (shaft_top - shaft_bottom) * 0.52 + 0.04
	var board: StandardMaterial3D = HangarKit.rams_body(Color(0.72, 0.66, 0.54), 0.30)
	var deck_in: float = pw * 0.5 + 0.015
	var deck_out: float = reach - 0.024
	var bw: float = maxf((deck_out - deck_in) * 0.48, 0.05)
	for i in range(2):
		var bz2: float = deck_in + bw * 0.5 + float(i) * maxf(deck_out - deck_in - bw, 0.0)
		add_child(_box(Vector3(0, deck_y, bz2), Vector3(reach * 2.0 - 0.02, 0.028, bw), board))
	# conduit up the -X face into a junction box on the front
	var cond: StandardMaterial3D = HangarKit.worn_metal(pcol.darkened(0.28))
	add_child(_box(Vector3(-pw * 0.5 - 0.028, shaft_bottom + (shaft_top - shaft_bottom) * 0.5, 0.0),
			Vector3(0.05, (shaft_top - shaft_bottom) * 0.86, 0.05), cond))
	var jy: float = shaft_bottom + (shaft_top - shaft_bottom) * 0.22
	add_child(_box(Vector3(-pw * 0.28, jy, pw * 0.5 + 0.04),
			Vector3(0.15, 0.20, 0.08), _body_mat(pcol, ewear)))
	add_child(_box(Vector3(-pw * 0.28, jy + 0.06, pw * 0.5 + 0.083),
			Vector3(0.030, 0.018, 0.008), HangarKit.emissive(acol, 1.6)))   # the box is live
	# caution tape across the two front standards
	var tape: StandardMaterial3D = HangarKit.striped_mat()
	add_child(_tilted(Vector3(0, shaft_bottom + (shaft_top - shaft_bottom) * 0.38, reach),
			Vector3(reach * 2.0, 0.062, 0.010), tape, Vector3(0, 0, -4.0)))
	# the state, named
	var plate: MeshInstance3D = HangarKit.brand_patch("WORKS", Vector2(pw * 0.74, 0.115),
			Color(0.95, 0.75, 0.05), Color(0.10, 0.10, 0.12))
	if plate:
		plate.position = Vector3(0, h * 0.66, pw * 0.5 + 0.014)
		add_child(plate)


# STORE — the column packed down. A pale protective sleeve swallows the shaft from
# just above the base cap to just under the capital, taped at both ends, banded
# with three straps and stamped SEALED. The groove is gone, the panels are gone,
# the silhouette is fatter and much brighter, and the caution kick band still
# shows below the wrap so the piece is still legible as a column.
func _upkeep_store(pw: float, shaft_bottom: float, shaft_top: float,
		pcol: Color, acol: Color) -> void:
	var out: float = pw + SLEEVE_OUT
	var hi: float = shaft_top - 0.06
	# minf so a very short pillar still gets a sleeve rather than one above its capital
	var lo: float = minf(shaft_bottom + 0.30, hi - 0.30)
	var sh: float = maxf(hi - lo, 0.2)
	var cy: float = lo + sh * 0.5
	# The wrap follows the AUTHOR's panel colour (pcol), not the finish palette's,
	# so a bay that was recoloured through curation_station stays one manufacturer.
	var wrap_col: Color = pcol
	var sleeve: StandardMaterial3D = HangarKit.finish_body(finish, wrap_col.lightened(0.34), 0.02)
	add_child(_box(Vector3(0, cy, 0), Vector3(out, sh, out), sleeve))
	# gathered folds down the front so the wrap does not read as another box
	for i in range(3):
		add_child(_box(Vector3((float(i) - 1.0) * (out * 0.28), cy, out * 0.5 + 0.007),
				Vector3(0.018, sh * 0.94, 0.014), sleeve))
	# taped ends
	var tape_mat: StandardMaterial3D = HangarKit.worn_metal(wrap_col.darkened(0.32))
	for e in [lo + 0.03, hi - 0.03]:
		add_child(_box(Vector3(0, float(e), 0), Vector3(out + 0.028, 0.058, out + 0.028), tape_mat))
	# three banding straps
	var band: StandardMaterial3D = HangarKit.worn_metal(Color(0.15, 0.14, 0.13))
	for i in range(3):
		var by: float = lo + sh * (0.22 + 0.28 * float(i))
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var bc: Vector3 = nrm * (out * 0.5 + 0.008) + Vector3(0, by, 0)
			var bs: Vector3 = Vector3(0.014, 0.036, out) if absf(nrm.x) > 0.5 else Vector3(out, 0.036, 0.014)
			add_child(_box(bc, bs, band))
	# the seal
	var seal: MeshInstance3D = HangarKit.brand_patch("SEALED", Vector2(out * 0.66, 0.10),
			acol, Color(0.98, 0.96, 0.92))
	if seal:
		seal.position = Vector3(0, lo + sh * 0.62, out * 0.5 + 0.016)
		add_child(seal)


# SCRAP — the column robbed. _scrap_shaft has already opened the front two faces;
# this adds what fell off and what grew after: a stripped cladding panel stood
# against the base, rust runs down the exposed core, a heavy rust bloom at the
# floor, and a torn length of barrier tape. The tape matters — without one bright
# thing this value would differ from "service" only by getting darker, and a
# variant that is merely darker is a variant you have to measure.
func _upkeep_scrap(pw: float, shaft_bottom: float, shaft_h: float,
		pcol: Color, ewear: float) -> void:
	var rust: StandardMaterial3D = HangarKit.painted_metal(Color(0.38, 0.19, 0.09), 0.55, 0.15, 0.94)
	# the panel that came off, stood against the foot
	var pl: float = shaft_h * 0.44
	var panel_mat: StandardMaterial3D = _body_mat(pcol.darkened(0.10), maxf(ewear, 0.4))
	add_child(_tilted(Vector3(pw * 0.16, pl * 0.50, pw * 0.5 + 0.20),
			Vector3(pw * 0.62, 0.022, pl), panel_mat, Vector3(72.0, 9.0, 0)))
	# rust runs down the open core
	for i in range(3):
		var rx: float = (float(i) - 1.0) * (pw * 0.20)
		var rl: float = shaft_h * (0.24 + 0.16 * float(i % 2))
		add_child(_box(Vector3(rx, shaft_bottom + shaft_h * 0.72 - rl * 0.5, pw * 0.28 + 0.006),
				Vector3(0.026, rl, 0.008), rust))
	# rust bloom where it meets the floor
	add_child(HangarKit.grime_band(pw + 0.22, 0.16, (pw + 0.18) * 0.5 + 0.006, Color(0.36, 0.18, 0.08)))
	# torn barrier tape, wrapped once round the base and trailing
	var tape: StandardMaterial3D = HangarKit.striped_mat(Color(0.92, 0.72, 0.06), Color(0.14, 0.13, 0.12))
	add_child(_tilted(Vector3(0, 0.74, pw * 0.5 + 0.03), Vector3(pw * 1.5, 0.055, 0.008), tape,
			Vector3(0, 0, -17.0)))
	add_child(_tilted(Vector3(pw * 0.55, 0.008, pw * 0.72), Vector3(0.44, 0.006, 0.055), tape,
			Vector3(0, 38.0, 0)))
	# the state, named once, painted not printed
	var mark: MeshInstance3D = HangarKit.stencil("SCRAP", Vector2(pw * 0.56, 0.10), Color(0.46, 0.22, 0.10))
	if mark:
		mark.position = Vector3(0, shaft_bottom + shaft_h * 0.40, pw * 0.28 + 0.014)
		add_child(mark)


func _tilted(center: Vector3, size: Vector3, mat: Material, rot_deg: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = _box(center, size, mat)
	mi.rotation_degrees = rot_deg
	return mi


# A crown block (capital or base cap): a main slab, an optional smaller top tier (stepped),
# and a chamfer collar that fakes a bevelled edge so the block doesn't read as a raw box.
func _build_crown(w: float, slab_h: float, cy: float, ch: float, mat: Material, stepped: bool) -> void:
	add_child(_box(Vector3(0, cy, 0), Vector3(w, slab_h, w), mat))
	if ch > 0.005:
		# a slightly inset collar just under the slab = a chamfer read without a custom mesh
		var collar_h: float = slab_h * 0.34
		add_child(_box(Vector3(0, cy - slab_h * 0.5 - collar_h * 0.5 + 0.002, 0), Vector3(w - ch * 2.0, collar_h, w - ch * 2.0), mat))
	if stepped:
		add_child(_box(Vector3(0, cy + slab_h * 0.5 + slab_h * 0.22, 0), Vector3(w * 0.74, slab_h * 0.44, w * 0.74), mat))


# Single recessed inset panel per face — the classic clean column look.
func _build_panels(pw: float, shaft_cy: float, shaft_h: float, pcol: Color, ewear: float) -> void:
	var pmat := _body_mat(pcol, ewear)
	var t := 0.02
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var center: Vector3 = nrm * (pw * 0.5 + t * 0.5) + Vector3(0, shaft_cy, 0)
		var size: Vector3 = Vector3(t, shaft_h * 0.82, pw * 0.62) if absf(nrm.x) > 0.5 else Vector3(pw * 0.62, shaft_h * 0.82, t)
		add_child(_box(center, size, pmat))


# Vertical fluting — recessed reeds down each face, for a monumental/greebled read.
func _build_flutes(pw: float, shaft_cy: float, shaft_h: float, pcol: Color, ewear: float) -> void:
	var fmat := _body_mat(pcol.darkened(0.04), ewear)
	var n: int = clampi(flute_count, 1, 6)
	var t := 0.018
	var fh: float = shaft_h * 0.84
	var span: float = pw * 0.74
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		for i in range(n):
			var tt: float = -0.5 + (float(i) + 0.5) / float(n)
			var off: float = tt * span
			var fw: float = (span / float(n)) * 0.62
			var center: Vector3
			var size: Vector3
			if absf(nrm.x) > 0.5:
				center = nrm * (pw * 0.5 + t * 0.5) + Vector3(0, shaft_cy, off)
				size = Vector3(t, fh, fw)
			else:
				center = nrm * (pw * 0.5 + t * 0.5) + Vector3(off, shaft_cy, 0)
				size = Vector3(fw, fh, t)
			add_child(_box(center, size, fmat))


func _body_mat(c: Color, w: float) -> StandardMaterial3D:
	return HangarKit.finish_body(finish, c, w)


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
