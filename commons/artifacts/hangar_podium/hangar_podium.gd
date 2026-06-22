extends Node3D
class_name HangarPodium

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the sci-fi hangar plinth that an artifact stands ON so the player can reach it — a battered, paneled maintenance-bay pedestal, not a museum case. Origin at the floor; the top is a work surface at a chosen reach height.
# desire: to give a small artifact a body in the room — to lift a thing that would otherwise sit lost on the floor up to hand height, and to say "this is the thing, stand here and work it".
# critical_parameter: top_height — THE reach decision. 1.0m = a small artifact lifted to hand height (the "small vector example needs a podium" case); 0.55m = a low display plinth you look down into; 0.9m+wide = a console-base work surface.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new reach/footprint/style.
# emerges: tray top reads "hold this here"; flat top reads "display"; grate top + corner posts read "maintenance rig"; greebled panels + edge light read "powered, live".
# needs: plinth + tapered body + cap [present]; recessed tray OR grate top [present]; inset/greebled side panels [present]; emissive rim light [present]; corner posts [optional]
# relationships: the grounding sibling of [[hangar_step_base]] (step ONTO that, reach OVER this), [[hangar_wall_panel]] (a podium against a wall), and the framed [[artifact_readout_screen]] that names what stands on it. The packaging an artifact's spatial_needs.platform="pedestal" asks for.
# truth: how a thing meets the floor is part of what the thing IS. A vector on the ground is litter; the same vector at hand height on a lit plinth is an instrument.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Dimensions")
## Top work-surface height — the reach decision. 1.0m lifts a small artifact to hand height.
@export var top_height: float = 1.0
## XZ size of the top surface (square).
@export var top_size: float = 0.6
## How much wider the base is than the top, per side — a battered/tapered plinth.
@export var taper: float = 0.12

@export_group("Style")
## "flat" (flush top) | "tray" (recessed lip holds the artifact) | "grate" (slatted top)
@export var top_style: String = "tray"
## "clean" (smooth) | "paneled" (inset face panels) | "greebled" (panels + detail strips)
@export var panel_style: String = "paneled"
## Four vertical corner posts framing the body — the maintenance-rig look.
@export var corner_posts: bool = false
## Emissive accent strip under the top rim (off by default — the three-colour bar is the accent).
@export var edge_light: bool = false

@export_group("Color")
## Dieter Rams / Braun default — light matte body so the housing recedes; one warm accent.
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

@export_group("Surface")
## Weathering 0..1 — subtle dust by default (Rams clean), not heavy grime.
@export var wear: float = 0.08
## Three-colour Rams accent bar across the front of the body.
@export var three_bar: bool = true
## Faint dust band at the foot (subtle).
@export var grime: bool = true
## Stencilled ID painted on the front face (e.g. "PED-01"). Empty = none.
@export var stencil_text: String = ""
## Diagonal caution-stripe band around the plinth foot.
@export var hazard_trim: bool = false
## Finish preset: "rams" (light Braun default) | "terminal" (dark charcoal console). DNA can pick.
@export var finish: String = "rams"

# ── Constants ─────────────────────────────────────────────────────────
const CAP_THICK := 0.08
const PLINTH_THICK := 0.10
const RIM_H := 0.06

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
	if has_meta("config_top_height"): top_height = float(str(get_meta("config_top_height")))
	if has_meta("config_top_size"): top_size = float(str(get_meta("config_top_size")))
	if has_meta("config_taper"): taper = float(str(get_meta("config_taper")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_panel_style"): panel_style = str(get_meta("config_panel_style")).to_lower()
	if has_meta("config_corner_posts"): corner_posts = str(get_meta("config_corner_posts")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_edge_light"): edge_light = str(get_meta("config_edge_light")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_hazard_trim"): hazard_trim = str(get_meta("config_hazard_trim")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_three_bar"): three_bar = str(get_meta("config_three_bar")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_grime"): grime = str(get_meta("config_grime")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_finish"): finish = str(get_meta("config_finish")).to_lower()


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	# Apply the finish preset to any colours still at their Braun defaults (explicit DNA wins).
	if finish.to_lower() != "rams":
		var pal := HangarKit.finish_palette(finish)
		if body_color.is_equal_approx(HangarKit.BODY_LIGHT): body_color = pal["body"]
		if panel_color.is_equal_approx(HangarKit.PANEL_TRIM): panel_color = pal["panel"]
		if accent_color.is_equal_approx(HangarKit.BRAUN_ACCENT): accent_color = pal["accent"]
		if absf(wear - 0.08) < 0.001: wear = float(pal["wear"])
	var base_w: float = top_size + taper * 2.0
	var body_mat := _mat(body_color, 0.55, 0.35)
	var cap_mat := _mat(body_color.lightened(0.06), 0.45, 0.45)

	# Plinth — wide foot on the floor.
	add_child(_box(Vector3(0, PLINTH_THICK * 0.5, 0), Vector3(base_w, PLINTH_THICK, base_w), body_mat))

	# Body — from plinth top to under the cap. A mid-width box reads as a battered taper.
	var body_bottom: float = PLINTH_THICK
	var body_top: float = top_height - CAP_THICK
	var body_h: float = maxf(body_top - body_bottom, 0.12)
	var body_w: float = top_size + taper
	add_child(_box(Vector3(0, body_bottom + body_h * 0.5, 0), Vector3(body_w, body_h, body_w), body_mat))

	if panel_style != "clean":
		_build_panels(body_w, body_bottom, body_h)
	if corner_posts:
		_build_corner_posts(base_w)

	# Cap — the work surface, top sits exactly at top_height.
	add_child(_box(Vector3(0, top_height - CAP_THICK * 0.5, 0), Vector3(top_size, CAP_THICK, top_size), cap_mat))

	match top_style:
		"tray": _build_tray_rim()
		"grate": _build_grate()
		_: pass

	if edge_light:
		_build_edge_light()
	if three_bar:
		_build_three_bar(body_w, body_bottom, body_h)
	if grime:
		add_child(HangarKit.grime_band(base_w, 0.07, base_w * 0.5 + 0.004, body_color))
		var streaks := HangarKit.dust_streaks(body_w * 0.8, body_h * 0.8, body_w * 0.5 + 0.014, 4)
		streaks.position = Vector3(0, body_bottom + body_h * 0.5, 0)
		add_child(streaks)
	if hazard_trim:
		_build_hazard_trim(base_w)
	if stencil_text.strip_edges() != "":
		_build_stencil(body_w, body_bottom, body_h)


func _build_panels(body_w: float, body_bottom: float, body_h: float) -> void:
	var pmat := _mat(panel_color, 0.65, 0.25)
	var body_cy: float = body_bottom + body_h * 0.5
	var pw: float = body_w * 0.74
	var ph: float = body_h * 0.78
	var t := 0.022
	for n in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var center: Vector3 = n * (body_w * 0.5 + t * 0.5) + Vector3(0, body_cy, 0)
		var size: Vector3 = Vector3(t, ph, pw) if absf(n.x) > 0.5 else Vector3(pw, ph, t)
		add_child(_box(center, size, pmat))
		if panel_style == "greebled":
			# two thin horizontal detail strips + a small vent block
			var smat := _mat(panel_color.darkened(0.25), 0.6, 0.4)
			for fy in [0.28, 0.66]:
				var sy: float = body_bottom + body_h * fy
				var ssize: Vector3 = Vector3(t * 1.6, 0.02, pw * 0.7) if absf(n.x) > 0.5 else Vector3(pw * 0.7, 0.02, t * 1.6)
				add_child(_box(n * (body_w * 0.5 + t * 1.3) + Vector3(0, sy, 0), ssize, smat))


func _build_corner_posts(base_w: float) -> void:
	var cmat := _mat(panel_color.lightened(0.04), 0.45, 0.5)
	var pr := 0.045
	var half: float = base_w * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_box(Vector3(sx * half, top_height * 0.5, sz * half), Vector3(pr * 2.0, top_height, pr * 2.0), cmat))


func _build_tray_rim() -> void:
	var rmat := _mat(body_color.lightened(0.05), 0.5, 0.4)
	var rt := 0.035
	var ry: float = top_height + RIM_H * 0.5
	var rs: float = top_size
	add_child(_box(Vector3(0, ry, rs * 0.5 - rt * 0.5), Vector3(rs, RIM_H, rt), rmat))
	add_child(_box(Vector3(0, ry, -rs * 0.5 + rt * 0.5), Vector3(rs, RIM_H, rt), rmat))
	add_child(_box(Vector3(rs * 0.5 - rt * 0.5, ry, 0), Vector3(rt, RIM_H, rs), rmat))
	add_child(_box(Vector3(-rs * 0.5 + rt * 0.5, ry, 0), Vector3(rt, RIM_H, rs), rmat))


func _build_grate() -> void:
	var gmat := _mat(panel_color, 0.45, 0.55)
	var n := 6
	for i in range(n):
		var x: float = lerpf(-top_size * 0.42, top_size * 0.42, float(i) / float(n - 1))
		add_child(_box(Vector3(x, top_height + 0.014, 0), Vector3(top_size * 0.07, 0.028, top_size * 0.86), gmat))


func _build_edge_light() -> void:
	var gmat := _emi(accent_color, 1.7)
	var ly: float = top_height - CAP_THICK - 0.016
	var lt := 0.014
	var ls: float = top_size + 0.006
	add_child(_box(Vector3(0, ly, ls * 0.5), Vector3(ls, lt, lt), gmat))
	add_child(_box(Vector3(0, ly, -ls * 0.5), Vector3(ls, lt, lt), gmat))
	add_child(_box(Vector3(ls * 0.5, ly, 0), Vector3(lt, lt, ls), gmat))
	add_child(_box(Vector3(-ls * 0.5, ly, 0), Vector3(lt, lt, ls), gmat))


# Caution-stripe band around the plinth foot (the hazard-bay look).
func _build_hazard_trim(base_w: float) -> void:
	var smat := HangarKit.striped_mat()
	var y: float = PLINTH_THICK * 0.5
	var t := 0.014
	add_child(_box(Vector3(0, y, base_w * 0.5 + t * 0.5), Vector3(base_w, PLINTH_THICK * 0.7, t), smat))
	add_child(_box(Vector3(0, y, -base_w * 0.5 - t * 0.5), Vector3(base_w, PLINTH_THICK * 0.7, t), smat))
	add_child(_box(Vector3(base_w * 0.5 + t * 0.5, y, 0), Vector3(t, PLINTH_THICK * 0.7, base_w), smat))
	add_child(_box(Vector3(-base_w * 0.5 - t * 0.5, y, 0), Vector3(t, PLINTH_THICK * 0.7, base_w), smat))


# Stencilled ID painted on the front face — replaces a floating label.
func _build_stencil(body_w: float, body_bottom: float, body_h: float) -> void:
	var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(body_w * 0.62, body_h * 0.16), HangarKit.TEXT_DARK)
	if q:
		q.position = Vector3(0, body_bottom + body_h * 0.5, body_w * 0.5 + 0.012)
		add_child(q)


# The Dieter-Rams three-colour accent bar across the upper front of the body.
func _build_three_bar(body_w: float, body_bottom: float, body_h: float) -> void:
	var bar: Node3D = HangarKit.three_color_bar(body_w * 0.72, 0.05, [accent_color, HangarKit.DISPLAY_DARK, panel_color])
	bar.position = Vector3(0, body_bottom + body_h * 0.72, body_w * 0.5 + 0.013)
	add_child(bar)


# ── Local helpers (delegate to the shared HangarKit for the family look) ──
# Finish-aware body material (light matte "rams" or dark worn "terminal").
func _mat(c: Color, _rough: float, _metal: float) -> StandardMaterial3D:
	return HangarKit.finish_body(finish, c, wear)


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


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
