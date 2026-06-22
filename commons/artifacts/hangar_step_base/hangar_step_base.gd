extends Node3D
class_name HangarStepBase

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: a low WIDE section of sci-fi hangar floor the player STEPS ONTO to reach a big artifact or stand inside one — a battered painted-metal stage with an inset paneled skirt, a flat or grated walkable top, and a caution-striped front lip. Origin at the floor; it rises a single step, never a wall.
# desire: to lift the player a hand's-span off the ground so a tall thing comes within reach — to be a mounting block, a place to stand and work, the floor said "here, up onto me" rather than a thing to look at.
# critical_parameter: footprint (width x depth) — THE decision, because this is a stage you MOUNT. 2x2 = one person at a console; 3x3 = stand inside a big artifact; wide+shallow = a kerb you step over to a wall panel. step_height stays a step (<=0.35), not a barrier.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new footprint/ramp/rail/style.
# emerges: bare top + hazard lip reads "step up"; ramp reads "roll a cart / wheel up"; rail on three sides reads "work platform, mind the open front"; grate top reads "maintenance deck".
# needs: slab + inset skirt [present]; walkable top, solid or grated [present]; hazard stripe front edge [present]; stencilled ID [present]; front ramp [optional]; back+side railing [optional]
# relationships: the standing-on sibling of [[hangar_podium]] (step ONTO this, reach OVER that), and a floor section for the wall-side [[hangar_wall_panel]]. The packaging an artifact's spatial_needs.platform="stage" asks for — you enter the artifact's footprint by mounting it.
# truth: where you stand changes what you can reach. The same tall instrument is unusable from the floor and at hand from one step up — the step is not furniture, it is the difference between looking and working.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Dimensions")
## X footprint of the stage — how wide the platform you step onto is.
@export var width: float = 2.0
## Z footprint of the stage — how deep (front-to-back) the platform is.
@export var depth: float = 2.0
## Step rise — keep it a step you mount, not a wall. Clamped <= 0.35.
@export var step_height: float = 0.25

@export_group("Style")
## "solid" (flush plate top) | "grate" (slatted maintenance deck)
@export var top_style: String = "solid"
## Low railing posts + a top rail on the back and two sides (front stays open).
@export var edge_rail: bool = false
## Sloped ramp box on the front (+Z) instead of a vertical step face.
@export var ramp: bool = false
## Caution-stripe strip along the front (+Z) edge.
@export var hazard_edge: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.40, 0.42, 0.46)
@export var accent_color: Color = Color(0.95, 0.75, 0.05)

@export_group("Surface")
## Weathering 0..1 — darkens + roughens toward scuffed bare metal.
@export var wear: float = 0.2
## Stencilled ID painted on the front skirt (e.g. "STEP-01"). Empty = none.
@export var stencil_text: String = "STEP-01"

# ── Constants ─────────────────────────────────────────────────────────
const TOP_THICK := 0.04          # walkable cap thickness (top sits at step_height)
const SKIRT_INSET := 0.06        # how far the paneled skirt is inset per side
const RAIL_H := 0.42             # railing post height above the deck
const RAIL_POST_R := 0.025

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
	if has_meta("config_depth"): depth = float(str(get_meta("config_depth")))
	if has_meta("config_step_height"): step_height = float(str(get_meta("config_step_height")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_edge_rail"): edge_rail = str(get_meta("config_edge_rail")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_ramp"): ramp = str(get_meta("config_ramp")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_hazard_edge"): hazard_edge = str(get_meta("config_hazard_edge")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var h: float = clampf(step_height, 0.08, 0.35)
	var w: float = maxf(width, 0.5)
	var d: float = maxf(depth, 0.5)
	var body_mat := _mat(body_color, 0.55, 0.35)
	var skirt_mat := _mat(body_color.darkened(0.22), 0.65, 0.3)
	var cap_mat := _mat(body_color.lightened(0.06), 0.45, 0.45)

	# Slab — the thick step block, y = 0..h. Slightly inset so the skirt sits proud.
	var slab_w: float = w - SKIRT_INSET * 2.0
	var slab_d: float = d - SKIRT_INSET * 2.0
	add_child(_box(Vector3(0, h * 0.5, 0), Vector3(slab_w, h, slab_d), body_mat))

	# Inset paneled skirt on the 4 sides — a thin panel band proud of the slab.
	_build_skirt(w, d, h, skirt_mat)

	# Walkable top — flush plate, or a grated maintenance deck.
	if top_style == "grate":
		_build_grate_top(slab_w, slab_d, h, cap_mat)
	else:
		add_child(_box(Vector3(0, h - TOP_THICK * 0.5, 0), Vector3(slab_w, TOP_THICK, slab_d), cap_mat))

	# Front: a sloped ramp box (+Z), or a simple front step lip.
	if ramp:
		_build_ramp(w, d, h, body_mat)
	else:
		_build_front_lip(w, d, h, cap_mat)

	# Optional railing on back + the two sides (front left open to step on).
	if edge_rail:
		_build_rail(slab_w, slab_d, h)

	# Hazard stripe along the front (+Z) edge.
	if hazard_edge:
		_build_hazard_edge(w, d, h)

	# Stencilled ID on the front skirt.
	if stencil_text.strip_edges() != "":
		_build_stencil(w, d, h)


# Inset paneled skirt — one panel band per side, proud of the slab face.
func _build_skirt(w: float, d: float, h: float, mat: Material) -> void:
	var t := 0.03
	var cy: float = h * 0.5
	var ph: float = h * 0.82
	# +X / -X faces (panel spans Z)
	for sx in [1.0, -1.0]:
		add_child(_box(Vector3(sx * (w * 0.5 - t * 0.5), cy, 0), Vector3(t, ph, d - SKIRT_INSET * 2.0), mat))
	# +Z / -Z faces (panel spans X)
	for sz in [1.0, -1.0]:
		add_child(_box(Vector3(0, cy, sz * (d * 0.5 - t * 0.5)), Vector3(w - SKIRT_INSET * 2.0, ph, t), mat))


# Grated walkable top — slats running along X, gaps between.
func _build_grate_top(slab_w: float, slab_d: float, h: float, mat: Material) -> void:
	var n := 7
	var slat_d: float = slab_d * 0.86
	for i in range(n):
		var x: float = lerpf(-slab_w * 0.42, slab_w * 0.42, float(i) / float(n - 1))
		add_child(_box(Vector3(x, h - TOP_THICK * 0.5, 0), Vector3(slab_w * 0.08, TOP_THICK, slat_d), mat))
	# two cross rails so the deck reads as a frame
	for sz in [1.0, -1.0]:
		add_child(_box(Vector3(0, h - TOP_THICK * 0.5, sz * slab_d * 0.46), Vector3(slab_w, TOP_THICK, slab_w * 0.06), mat))


# Sloped ramp on the front (+Z) — a tilted wedge box from floor up to the deck.
func _build_ramp(w: float, d: float, h: float, mat: Material) -> void:
	var ramp_len: float = maxf(h * 3.0, 0.6)        # run along +Z
	var ramp_w: float = w * 0.8
	var mi := _box(Vector3.ZERO, Vector3(ramp_w, TOP_THICK * 1.4, ramp_len), mat)
	# tilt so the back edge meets the deck top and the front edge meets the floor
	var ang: float = atan2(h, ramp_len)
	mi.rotation = Vector3(ang, 0, 0)
	mi.position = Vector3(0, h * 0.5, d * 0.5 + cos(ang) * ramp_len * 0.5)
	add_child(mi)


# A simple front step lip — a thin nosing along the front top edge.
func _build_front_lip(w: float, d: float, h: float, mat: Material) -> void:
	var lt := 0.05
	add_child(_box(Vector3(0, h - TOP_THICK - lt * 0.5, d * 0.5 - lt * 0.5), Vector3(w - SKIRT_INSET * 2.0, lt, lt), mat))


# Railing on back + the two sides — thin posts and a top rail. Front stays open.
func _build_rail(slab_w: float, slab_d: float, h: float) -> void:
	var rmat := _mat(body_color.lightened(0.04), 0.45, 0.5)
	var hx: float = slab_w * 0.5
	var hz: float = slab_d * 0.5
	var rail_y: float = h + RAIL_H
	# Posts: back two corners + two mid-side + front-side anchors (front rail itself omitted).
	var posts := [
		Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz),       # back corners
		Vector3(-hx, 0, 0), Vector3(hx, 0, 0),           # side mids
		Vector3(-hx, 0, hz), Vector3(hx, 0, hz),         # front-side anchors
	]
	for p in posts:
		add_child(_box(Vector3(p.x, h + RAIL_H * 0.5, p.z), Vector3(RAIL_POST_R * 2.0, RAIL_H, RAIL_POST_R * 2.0), rmat))
	# Top rails: back span + the two side spans (no front rail).
	add_child(_box(Vector3(0, rail_y, -hz), Vector3(slab_w, RAIL_POST_R * 2.0, RAIL_POST_R * 2.0), rmat))
	for sx in [1.0, -1.0]:
		add_child(_box(Vector3(sx * hx, rail_y, 0), Vector3(RAIL_POST_R * 2.0, RAIL_POST_R * 2.0, slab_d), rmat))


# Caution-stripe strip along the front (+Z) edge of the step.
func _build_hazard_edge(w: float, d: float, h: float) -> void:
	var smat := HangarKit.striped_mat(accent_color, Color(0.10, 0.10, 0.12))
	var t := 0.02
	var strip_h: float = h * 0.5
	add_child(_box(Vector3(0, strip_h * 0.5 + h - strip_h, d * 0.5 + t * 0.5), Vector3(w, strip_h, t), smat))


# Stencilled ID painted on the front skirt — replaces a floating label.
func _build_stencil(w: float, d: float, h: float) -> void:
	var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.5, 0.7), h * 0.5))
	if q:
		q.position = Vector3(0, h * 0.42, d * 0.5 + 0.04)
		add_child(q)


# ── Local helpers (delegate to the shared HangarKit for the family look) ──
func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	return HangarKit.painted_metal(c, wear, metal, rough)


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
