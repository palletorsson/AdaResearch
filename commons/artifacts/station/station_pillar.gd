extends Node3D
class_name StationPillar

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR corner column of a curation station — a square painted-metal pillar that claims one 1 m cell and rises to height, banded with a lit accent groove, a chamfered base/capital, a Rams three-colour bar, a caution-stripe kick band and a bolted foot. Origin at the floor centre. The vertical that turns a flat backing into a built bay corner.
# desire: to mark where the room turns — to give a wall run a corner to die into and an artifact set an upright frame, so the stage reads as architecture, not furniture in a void.
# critical_parameter: height + post_width — how tall and how heavy the corner reads; the composer matches it to the backing wall height.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds.
# emerges: a plain shaft reads "structure"; a lit groove reads "powered"; a chamfered capital + bolted base reads "finished, intentional, load-bearing"; a fluted shaft reads "monumental"; a readout face reads "this corner reports".
# needs: a bolted base plate [present]; a chamfered shaft [present]; a chamfered capital [present]; a lit accent groove [present]; a caution kick band [present]; a Rams accent bar [present]; optional readout face / surface-pinned signage [optional].
# relationships: the upright that ends a [[station_wall]] run and frames the [[station_stage]]; placed at the back corners by [[curation_station]]; the single-upright cousin of [[station_frame]]'s ring; shares the HangarKit / Dieter-Rams ARC-Raiders weathered painted-metal family look.
# truth: a column is the oldest claim that a place is built. One upright, repeated, makes a room out of an open floor — and how it meets the floor (bolted, chamfered, banded) is the proof that it was meant.

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
	add_child(_box(Vector3(0, shaft_cy, 0), Vector3(pw, shaft_h, pw), body_mat))

	# ── Capital crown ──
	_build_crown(pw + 0.12, CAP_H, h - CAP_H * 0.5, ch, trim_mat, cap_style == "stepped")

	# ── Recessed face detail: flutes or a single inset panel, per side ──
	if flute_count > 0:
		_build_flutes(pw, shaft_cy, shaft_h, pcol, ewear)
	else:
		_build_panels(pw, shaft_cy, shaft_h, pcol, ewear)

	# ── Lit accent groove down each face ──
	if lit_groove:
		var lit := HangarKit.emissive(acol, 0.85)
		for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var center: Vector3 = nrm * (pw * 0.5 + 0.012) + Vector3(0, shaft_cy, 0)
			var size: Vector3 = Vector3(0.022, shaft_h * 0.72, 0.034) if absf(nrm.x) > 0.5 else Vector3(0.034, shaft_h * 0.72, 0.022)
			add_child(_box(center, size, lit))

	# ── Caution-stripe kick band around the base of the shaft ──
	if caution_stripe:
		var smat := HangarKit.striped_mat(acol.lerp(Color(0.95, 0.78, 0.10), 0.5), HangarKit.DISPLAY_DARK)
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
	if three_bar:
		var bar: Node3D = HangarKit.three_color_bar(pw * 0.78, 0.032, [acol, HangarKit.DISPLAY_DARK, pcol])
		bar.position = Vector3(0, shaft_top - 0.16, pw * 0.5 + 0.016)
		add_child(bar)

	# ── Readout face (framed 2D-in-3D screen) ──
	if readout_face:
		var screen: Node3D = HangarKit.readout("NODE", ["ONLINE", "PWR OK"], Vector2(pw * 0.74, pw * 0.5),
			pal["screen"], pal["text"], pal["header"])
		if screen:
			screen.position = Vector3(0, h * 0.6, pw * 0.5 + 0.03)
			add_child(screen)

	# ── Surface-pinned signage line (header on a bracketed plate) ──
	if signage_text.strip_edges() != "":
		var sign: Node3D = HangarKit.signage(signage_text, [], Vector2(pw * 1.05, 0.16), 0.10, Vector3(0, 0, 1))
		if sign:
			sign.position = Vector3(0, h * 0.45, pw * 0.5 + 0.01)
			add_child(sign)

	# ── Dust + grime weathering ──
	if dust:
		add_child(HangarKit.dust_streaks(pw * 0.8, shaft_h * 0.6, pw * 0.5 + 0.014, 3))
	if grime:
		add_child(HangarKit.grime_band(foot_w, 0.05, foot_w * 0.5 + 0.004, bcol))

	# ── Stencil text painted onto the shaft ──
	if stencil_text.strip_edges() != "":
		var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(pw * 0.72, 0.12))
		if q:
			q.position = Vector3(0, shaft_bottom + shaft_h * 0.28, pw * 0.5 + 0.02)
			add_child(q)


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
