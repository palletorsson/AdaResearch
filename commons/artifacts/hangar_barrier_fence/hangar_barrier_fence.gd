extends Node3D
class_name HangarBarrierFence

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: a branded modular crowd/area barrier — pale-grey panels strung between dark posts on foot plates, a horizontal seam across each panel, a lab brand patch spanning the run. The thing that says "do not cross here".
# desire: to draw a line on the floor and hold a body back from it — to mark off a wet-lab, a hazard bay, a roped queue — and to wear the lab's name while doing it.
# critical_parameter: panel_count — the length of the line. 2 = a short gate; 5 = a long cordon that fills a corridor mouth. corner=true bends the line into an L to wrap a space.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new length/branding/style.
# emerges: brand patch reads "official, owned ground"; caution stripe at the base reads "hazard, keep out"; the L-corner reads "this area, specifically".
# relationships: the area-marking sibling of [[hangar_podium]] (stand AT this, reach OVER that) and [[hangar_wall_panel]]; the barrier a map draws around a forbidden_wet_lab zone.
# truth: a barrier is an argument made in metal — it does not stop you, it tells you that someone decided you should stop.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Run")
## THE length decision — how many panel slabs make up the barrier run.
@export var panel_count: int = 3
## Width of each panel slab (X), between its two posts.
@export var panel_width: float = 1.4
## Total height of the barrier (posts + panel).
@export var height: float = 1.1

@export_group("Branding")
## Brand patch spanning the front of the run near the top. Empty = none.
@export var brand_text: String = "VALLEY LABORATORIES"
## Optional smaller stencil line under the brand. Empty = none.
@export var subtitle_text: String = ""

@export_group("Layout")
## Bend the run into an L — rotate the last 1-2 panels 90 deg around the end post.
@export var corner: bool = false
## Diagonal caution-stripe band along the bottom edge of the run.
@export var stripe_base: bool = false

@export_group("Color")
@export var panel_color: Color = Color(0.62, 0.64, 0.68)
@export var post_color: Color = Color(0.10, 0.11, 0.13)

@export_group("Surface")
## Weathering 0..1 — darkens + roughens toward scuffed bare metal.
@export var wear: float = 0.15

# ── Constants ─────────────────────────────────────────────────────────
const PANEL_DEPTH := 0.05
const POST_W := 0.09
const FOOT_W := 0.22
const FOOT_H := 0.03
const SEAM_T := 0.018

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
	if has_meta("config_panel_count"): panel_count = int(float(str(get_meta("config_panel_count"))))
	if has_meta("config_panel_width"): panel_width = float(str(get_meta("config_panel_width")))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_brand_text"): brand_text = str(get_meta("config_brand_text"))
	if has_meta("config_subtitle_text"): subtitle_text = str(get_meta("config_subtitle_text"))
	if has_meta("config_corner"): corner = str(get_meta("config_corner")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_stripe_base"): stripe_base = str(get_meta("config_stripe_base")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_panel_color"): panel_color = _pc(str(get_meta("config_panel_color")), panel_color)
	if has_meta("config_post_color"): post_color = _pc(str(get_meta("config_post_color")), post_color)
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var pc: int = clampi(panel_count, 2, 5)
	# How many of the trailing panels bend off to make the L-corner.
	var bend: int = (2 if pc >= 4 else 1) if corner else 0
	var straight: int = pc - bend

	# The straight run extends along +X, centered on origin.
	var run_w: float = float(pc) * panel_width
	var n_posts: int = pc + 1
	var start_x: float = -run_w * 0.5

	var post_mat := HangarKit.painted_metal(post_color, wear, 0.6, 0.5)
	var foot_mat := HangarKit.worn_metal(post_color)
	var panel_mat := HangarKit.painted_metal(panel_color, wear, 0.25, 0.6)
	var seam_mat := HangarKit.painted_metal(panel_color.darkened(0.35), wear, 0.3, 0.55)

	# Posts + feet for the straight section (and the pivot post shared with the bend).
	for i in range(straight + 1):
		var px: float = start_x + float(i) * panel_width
		_add_post(Vector3(px, 0, 0), post_mat, foot_mat)

	# Straight panels: each fills the gap between post i and i+1.
	for i in range(straight):
		var cx: float = start_x + (float(i) + 0.5) * panel_width
		_add_panel(Vector3(cx, 0, 0), 0.0, panel_mat, seam_mat)

	# L-corner: the trailing panels turn 90 deg about the end post of the straight run.
	if bend > 0:
		var pivot_x: float = start_x + float(straight) * panel_width
		for j in range(bend):
			# Panel center steps out along +Z from the pivot.
			var cz: float = (float(j) + 0.5) * panel_width
			_add_panel(Vector3(pivot_x, 0, cz), 90.0, panel_mat, seam_mat)
			# Post at the far end of each bent panel.
			var post_z: float = (float(j) + 1.0) * panel_width
			_add_post(Vector3(pivot_x, 0, post_z), post_mat, foot_mat)

	# Brand patch spanning the front of the straight run, near the top, placed proud.
	if brand_text.strip_edges() != "":
		var straight_w: float = float(straight) * panel_width
		var center_x: float = start_x + straight_w * 0.5
		var bw: float = clampf(straight_w * 0.7, 0.4, straight_w)
		var bh: float = clampf(height * 0.16, 0.08, 0.3)
		var patch: MeshInstance3D = HangarKit.brand_patch(brand_text, Vector2(bw, bh))
		if patch:
			patch.position = Vector3(center_x, height * 0.72, PANEL_DEPTH * 0.5 + 0.02)
			add_child(patch)
		if subtitle_text.strip_edges() != "":
			var sq: MeshInstance3D = HangarKit.stencil(subtitle_text, Vector2(bw * 0.8, bh * 0.6))
			if sq:
				sq.position = Vector3(center_x, height * 0.72 - bh * 0.85, PANEL_DEPTH * 0.5 + 0.02)
				add_child(sq)

	if stripe_base:
		_add_base_stripe(start_x, run_w)


# A vertical post on a small foot plate. Origin at floor.
func _add_post(base: Vector3, post_mat: Material, foot_mat: Material) -> void:
	add_child(_box(base + Vector3(0, FOOT_H * 0.5, 0), Vector3(FOOT_W, FOOT_H, FOOT_W), foot_mat))
	add_child(_box(base + Vector3(0, height * 0.5, 0), Vector3(POST_W, height, POST_W), post_mat))


# A light panel slab with a subtle recessed horizontal seam line.
# rot_y rotates the slab about its center (0 = facing +Z, 90 = facing +X for the L-corner).
func _add_panel(center: Vector3, rot_y: float, panel_mat: Material, seam_mat: Material) -> void:
	var inner_w: float = panel_width - POST_W
	var ph: float = height * 0.86
	var root := Node3D.new()
	root.position = center + Vector3(0, height * 0.5, 0)
	root.rotation_degrees = Vector3(0, rot_y, 0)
	# Slab (local XY facing +Z).
	root.add_child(_box(Vector3.ZERO, Vector3(inner_w, ph, PANEL_DEPTH), panel_mat))
	# Recessed seam line across the middle, set just behind the front face.
	root.add_child(_box(Vector3(0, 0, PANEL_DEPTH * 0.5 - SEAM_T * 0.5), Vector3(inner_w * 0.96, SEAM_T, SEAM_T), seam_mat))
	add_child(root)


# Diagonal caution-stripe band along the bottom edge of the straight run, on the +Z face.
func _add_base_stripe(start_x: float, run_w: float) -> void:
	var smat := HangarKit.striped_mat()
	var band_h: float = height * 0.14
	var cx: float = start_x + run_w * 0.5
	add_child(_box(Vector3(cx, band_h * 0.5 + FOOT_H, PANEL_DEPTH * 0.5 + 0.006),
		Vector3(run_w, band_h, 0.012), smat))


# ── Local helpers (delegate to the shared HangarKit for the family look) ──
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
