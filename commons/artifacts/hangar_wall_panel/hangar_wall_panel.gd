extends Node3D
class_name HangarWallPanel

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the modular sci-fi maintenance-bay WALL that stands BEHIND an artifact — a perforated/greebled/ribbed painted-metal backing panel that gives a thing a surface to be against, not float in front of. Origin at the floor; the wall plane is XY facing +Z, thin in Z.
# desire: to put a back on the room — to take an artifact that would read as adrift in empty space and press it against a worked, powered surface that says "this belongs to a bay, there is a behind here".
# critical_parameter: panel_style — THE backing decision. "perforated" = a recessed dark hole-grid (vent/server wall); "ribbed" = vertical structural rib strips (a reinforced bulkhead); "greebled" = inset panels + bolt rows + a vent block (a busy serviced wall).
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new size/style/dressing.
# emerges: perforated reads "ventilated, machine"; ribbed reads "structural, load"; greebled reads "serviced, live"; seam strips lit + a readout reads "powered, monitored"; a hazard base reads "stand clear of the foot".
# needs: thin wall slab y=0..height [present]; a few large inset panels [present]; per-style detail proud of +Z [present]; optional lit seams / readout / brand patch / hazard stripe / stencil ID [optional]
# relationships: the against-the-wall sibling of [[hangar_podium]] (stand a thing ON that, back a thing AGAINST this) and the framed [[artifact_readout_screen]] it can embed. The packaging an artifact's spatial_needs.wall_backing=true asks for.
# truth: a thing needs a behind. Floating in void it is a sample; pressed against a worked wall it is installed — part of a place that was built and is maintained.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Dimensions")
## Wall width (X span).
@export var width: float = 2.4
## Wall height (Y, grows up from the floor).
@export var height: float = 2.6

@export_group("Style")
## "perforated" (recessed hole-grid) | "greebled" (inset panels + bolts + vent) | "ribbed" (vertical rib strips)
@export var panel_style: String = "greebled"
## Embed a small framed readout screen in the upper centre.
@export var screen_slot: bool = false
## Thin emissive vertical seam strips down the face.
@export var lit_channels: bool = true
## Caution-stripe band along the floor foot.
@export var hazard_base: bool = false

@export_group("Surface")
## Printed brand patch near the top (e.g. "VALLEY LABORATORIES"). Empty = none.
@export var brand_text: String = ""
## Stencilled ID painted low on the face (e.g. "WP-01"). Empty = none.
@export var stencil_text: String = ""
## Weathering 0..1 — darkens + roughens toward scuffed bare metal.
@export var wear: float = 0.2

@export_group("Color")
@export var body_color: Color = Color(0.38, 0.40, 0.45)
@export var panel_color: Color = Color(0.28, 0.30, 0.34)
@export var accent_color: Color = Color(0.25, 0.85, 0.95)

# ── Constants ─────────────────────────────────────────────────────────
const SLAB_DEPTH := 0.15
const PANEL_INSET := 0.02   # how far panels sit proud of the slab front
const FRONT_Z := SLAB_DEPTH * 0.5   # +Z face of the slab

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
	if has_meta("config_width"): width = float(str(get_meta("config_width")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_panel_style"): panel_style = str(get_meta("config_panel_style")).to_lower()
	if has_meta("config_screen_slot"): screen_slot = str(get_meta("config_screen_slot")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_lit_channels"): lit_channels = str(get_meta("config_lit_channels")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_hazard_base"): hazard_base = str(get_meta("config_hazard_base")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_brand_text"): brand_text = str(get_meta("config_brand_text"))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var w: float = maxf(width, 0.4)
	var h: float = maxf(height, 0.4)
	var body_mat := _mat(body_color, 0.6, 0.35)

	# Wall slab — origin at floor, grows +Y, thin in Z, XY plane facing +Z.
	add_child(_box(Vector3(0, h * 0.5, 0), Vector3(w, h, SLAB_DEPTH), body_mat))

	# A few large inset panels across the face (the modular backing read).
	_build_inset_panels(w, h)

	# Per-style detail, all proud of the +Z face.
	match panel_style:
		"perforated": _build_perforation(w, h)
		"ribbed": _build_ribs(w, h)
		_: _build_greebles(w, h)   # "greebled" default

	if lit_channels:
		_build_lit_channels(w, h)
	if screen_slot:
		_build_screen_slot(w, h)
	if hazard_base:
		_build_hazard_base(w)
	if brand_text.strip_edges() != "":
		_build_brand(w, h)
	if stencil_text.strip_edges() != "":
		_build_stencil(w, h)


# A few large recessed panels — split the wall into 2 columns x 2 rows of inset plates.
func _build_inset_panels(w: float, h: float) -> void:
	var pmat := _mat(panel_color, 0.65, 0.3)
	var t := 0.03
	var cols := 2
	var rows := 2
	var margin: float = minf(w, h) * 0.06
	var gap := margin
	var cell_w: float = (w - margin * 2.0 - gap * float(cols - 1)) / float(cols)
	var cell_h: float = (h - margin * 2.0 - gap * float(rows - 1)) / float(rows)
	for c in range(cols):
		for r in range(rows):
			var px: float = -w * 0.5 + margin + cell_w * 0.5 + float(c) * (cell_w + gap)
			var py: float = margin + cell_h * 0.5 + float(r) * (cell_h + gap)
			add_child(_box(Vector3(px, py, FRONT_Z + t * 0.5), Vector3(cell_w, cell_h, t), pmat))


# "perforated" — a modest grid (<=8x10) of small recessed dark boxes across the centre.
func _build_perforation(w: float, h: float) -> void:
	var holes := _mat(panel_color.darkened(0.5), 0.8, 0.1)
	var cols := 8
	var rows := 10
	var area_w: float = w * 0.62
	var area_h: float = h * 0.5
	var cy: float = h * 0.52
	var hole := minf(area_w / float(cols), area_h / float(rows)) * 0.55
	for c in range(cols):
		for r in range(rows):
			var px: float = lerpf(-area_w * 0.5, area_w * 0.5, float(c) / float(cols - 1))
			var py: float = cy + lerpf(-area_h * 0.5, area_h * 0.5, float(r) / float(rows - 1))
			# slightly proud, dark — reads as a recessed vent hole on the panel
			add_child(_box(Vector3(px, py, FRONT_Z + 0.045), Vector3(hole, hole, 0.04), holes))


# "ribbed" — several vertical rib strips standing proud of the face.
func _build_ribs(w: float, h: float) -> void:
	var rmat := _mat(body_color.lightened(0.05), 0.5, 0.5)
	var n := 5
	var rib_w := 0.07
	var rib_h: float = h * 0.86
	for i in range(n):
		var x: float = lerpf(-w * 0.4, w * 0.4, float(i) / float(n - 1))
		add_child(_box(Vector3(x, h * 0.5, FRONT_Z + 0.04), Vector3(rib_w, rib_h, 0.06), rmat))


# "greebled" — bolt rows around the panel seams + a vent block, proud of the face.
func _build_greebles(w: float, h: float) -> void:
	var bolt_mat := HangarKit.worn_metal(panel_color)
	var br := 0.022
	var bz: float = FRONT_Z + 0.05
	var inx: float = w * 0.4
	var lo: float = h * 0.12
	var hi: float = h * 0.88
	# bolt rows: top, bottom, and two verticals
	add_child(_bolts(Vector3(-inx, hi, bz), Vector3(inx, hi, bz), 6, br, bolt_mat))
	add_child(_bolts(Vector3(-inx, lo, bz), Vector3(inx, lo, bz), 6, br, bolt_mat))
	add_child(_bolts(Vector3(-inx, lo, bz), Vector3(-inx, hi, bz), 5, br, bolt_mat))
	add_child(_bolts(Vector3(inx, lo, bz), Vector3(inx, hi, bz), 5, br, bolt_mat))
	# a vent block (louvre slats) lower-right
	var vmat := _mat(panel_color.darkened(0.2), 0.6, 0.45)
	var vw: float = w * 0.26
	var vh: float = h * 0.2
	var vx: float = w * 0.22
	var vy: float = h * 0.28
	add_child(_box(Vector3(vx, vy, FRONT_Z + 0.05), Vector3(vw, vh, 0.04), vmat))
	var smat := _mat(panel_color.darkened(0.45), 0.7, 0.3)
	var slats := 4
	for i in range(slats):
		var sy: float = vy + lerpf(-vh * 0.32, vh * 0.32, float(i) / float(slats - 1))
		add_child(_box(Vector3(vx, sy, FRONT_Z + 0.075), Vector3(vw * 0.86, 0.02, 0.02), smat))


# Thin emissive vertical seam strips down the face.
func _build_lit_channels(w: float, h: float) -> void:
	var gmat := _emi(accent_color, 1.8)
	var sh: float = h * 0.82
	var sw := 0.02
	for sx in [-w * 0.28, w * 0.28]:
		add_child(_box(Vector3(sx, h * 0.5, FRONT_Z + 0.055), Vector3(sw, sh, 0.015), gmat))


# Embedded framed readout screen in the upper centre (faces +Z).
func _build_screen_slot(w: float, h: float) -> void:
	var sw: float = minf(w * 0.42, 0.7)
	var sh: float = sw * 0.62
	var screen: Node3D = HangarKit.readout("STATUS", ["BAY ONLINE", "PWR  100%", "LINK  OK"], Vector2(sw, sh))
	if screen:
		screen.position = Vector3(0, h * 0.74, FRONT_Z + 0.06)
		add_child(screen)


# Caution-stripe band along the floor foot.
func _build_hazard_base(w: float) -> void:
	var smat := HangarKit.striped_mat()
	var bh := 0.18
	add_child(_box(Vector3(0, bh * 0.5, FRONT_Z + 0.02), Vector3(w, bh, 0.02), smat))


# Printed brand patch near the top.
func _build_brand(w: float, h: float) -> void:
	var q: MeshInstance3D = HangarKit.brand_patch(brand_text, Vector2(minf(w * 0.5, 1.1), h * 0.08))
	if q:
		q.position = Vector3(0, h * 0.9, FRONT_Z + 0.07)
		add_child(q)


# Stencilled ID painted low on the face.
func _build_stencil(w: float, h: float) -> void:
	var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.3, 0.6), h * 0.07))
	if q:
		q.position = Vector3(-w * 0.32, h * 0.1, FRONT_Z + 0.07)
		add_child(q)


# ── Local helpers (delegate to the shared HangarKit for the family look) ──
func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	return HangarKit.painted_metal(c, wear, metal, rough)


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


func _bolts(a: Vector3, b: Vector3, count: int, radius: float, mat: Material) -> Node3D:
	return HangarKit.bolts(a, b, count, radius, mat)


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
