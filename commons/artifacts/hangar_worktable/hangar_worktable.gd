extends Node3D
class_name HangarWorktable

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the sci-fi maintenance worktable — the battered painted-metal bench that turns a patch of floor INTO a workspace. A flat top slab on four sturdy legs, a small DIAG screen at the back, a few fixed tools and a drawer unit. Origin at the floor; the top grows +Y to working height.
# desire: to be the surface you do the work ON — to give a sequence's tools, parts and a readout a place to sit at hand height, and to say "this corner is a bench, things get fixed here".
# critical_parameter: width — THE bench-size decision. 1.2m = a tight single-station bench; 1.6m = a comfortable two-tool workstation; 2.4m = a long shared maintenance run.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with a new width/depth/style.
# emerges: solid top + drawers + screen reads "staffed workstation, in use"; bare grate top reads "drainage / wet bench"; clutter tools read "mid-job, someone stepped away".
# needs: tabletop slab + 4 legs [present]; apron rail under the top with a stencilled ID [present]; back readout screen [optional]; fixed tool clutter [optional]; drawer unit [optional]; grate top slats [optional]
# relationships: the working sibling of [[hangar_podium]] (reach OVER this, stand ON that) and [[hangar_wall_panel]]; carries the framed [[artifact_readout_screen]] as its built-in DIAG screen. The packaging an artifact's spatial_needs.platform="table" asks for.
# truth: a podium says "look at this thing"; a worktable says "here is where you make and mend things". The bench is the floor admitting that work happens.

# ── DNA ───────────────────────────────────────────────────────────────
@export_group("Dimensions")
## Tabletop width along X — THE bench-size decision. 1.6m = a comfortable two-tool workstation.
@export var width: float = 1.6
## Tabletop depth along Z.
@export var depth: float = 0.8
## Top work-surface height — legs reach from floor to here.
@export var top_height: float = 0.95

@export_group("Style")
## "solid" (flush slab) | "grate" (slatted drainage top)
@export var top_style: String = "solid"
## A small framed readout standing at the BACK of the tabletop ("DIAG OK").
@export var with_screen: bool = true
## A few small fixed clutter boxes / short cylinders on top — tools and parts.
@export var with_tools: bool = true
## A drawer unit (2-3 stacked boxes with thin handle lines) under one side.
@export var drawers: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.34, 0.36, 0.40)
@export var top_color: Color = Color(0.42, 0.44, 0.48)

@export_group("Surface")
## Weathering 0..1 — darkens + roughens toward scuffed bare metal.
@export var wear: float = 0.25
## Stencilled ID painted on the apron rail under the top (e.g. "BENCH-01"). Empty = none.
@export var stencil_text: String = ""

# ── Constants ─────────────────────────────────────────────────────────
const TOP_THICK := 0.05
const APRON_H := 0.10
const LEG_W := 0.07

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
	if has_meta("config_top_height"): top_height = float(str(get_meta("config_top_height")))
	if has_meta("config_top_style"): top_style = str(get_meta("config_top_style")).to_lower()
	if has_meta("config_with_screen"): with_screen = str(get_meta("config_with_screen")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_with_tools"): with_tools = str(get_meta("config_with_tools")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_drawers"): drawers = str(get_meta("config_drawers")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_top_color"): top_color = _pc(str(get_meta("config_top_color")), top_color)
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_stencil_text"): stencil_text = str(get_meta("config_stencil_text"))


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true
	var w: float = maxf(width, 0.4)
	var d: float = maxf(depth, 0.3)
	var h: float = maxf(top_height, 0.3)
	var body_mat := _mat(body_color, 0.55, 0.4)
	var top_mat := _mat(top_color, 0.5, 0.45)

	# Four legs — boxes from the floor up to just under the top slab.
	var leg_top: float = h - TOP_THICK
	var lx: float = w * 0.5 - LEG_W
	var lz: float = d * 0.5 - LEG_W
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_box(Vector3(sx * lx, leg_top * 0.5, sz * lz), Vector3(LEG_W, leg_top, LEG_W), body_mat))

	# Apron rail under the top — the front/back/side frame the stencil sits on.
	var apron_cy: float = h - TOP_THICK - APRON_H * 0.5
	var at := 0.04
	add_child(_box(Vector3(0, apron_cy, d * 0.5 - at * 0.5), Vector3(w - LEG_W, APRON_H, at), body_mat))
	add_child(_box(Vector3(0, apron_cy, -d * 0.5 + at * 0.5), Vector3(w - LEG_W, APRON_H, at), body_mat))
	add_child(_box(Vector3(w * 0.5 - at * 0.5, apron_cy, 0), Vector3(at, APRON_H, d - LEG_W), body_mat))
	add_child(_box(Vector3(-w * 0.5 + at * 0.5, apron_cy, 0), Vector3(at, APRON_H, d - LEG_W), body_mat))

	# Cross-brace low between the legs — the sturdy-bench look.
	add_child(_box(Vector3(0, h * 0.22, 0), Vector3(w - LEG_W * 3.0, 0.04, 0.04), body_mat))

	# Tabletop — top sits exactly at top_height.
	if top_style == "grate":
		_build_grate_top(w, d, h, top_mat)
	else:
		add_child(_box(Vector3(0, h - TOP_THICK * 0.5, 0), Vector3(w, TOP_THICK, d), top_mat))

	if drawers:
		_build_drawers(w, d, h)
	if with_tools:
		_build_tools(w, d, h)
	if with_screen:
		_build_screen(w, d, h)
	if stencil_text.strip_edges() != "":
		_build_stencil(w, d, apron_cy)


# Slatted drainage top — front-to-back slats instead of a solid slab.
func _build_grate_top(w: float, d: float, h: float, mat: Material) -> void:
	var smat := _mat(top_color.darkened(0.1), 0.45, 0.55)
	var n := maxi(int(w / 0.14), 4)
	var slat_w: float = (w * 0.94) / float(n) * 0.6
	for i in range(n):
		var x: float = lerpf(-w * 0.47, w * 0.47, float(i) / float(n - 1))
		add_child(_box(Vector3(x, h - TOP_THICK * 0.5, 0), Vector3(slat_w, TOP_THICK, d * 0.94), smat))
	# thin rim frame so the grate reads as a fitted top, not loose bars
	add_child(_box(Vector3(0, h - TOP_THICK * 0.5, d * 0.47), Vector3(w, TOP_THICK, 0.03), mat))
	add_child(_box(Vector3(0, h - TOP_THICK * 0.5, -d * 0.47), Vector3(w, TOP_THICK, 0.03), mat))


# A drawer unit (2-3 stacked drawer faces with a thin handle line) under one side.
func _build_drawers(w: float, d: float, h: float) -> void:
	var face_mat := _mat(body_color.lightened(0.05), 0.5, 0.4)
	var handle_mat := HangarKit.worn_metal(body_color)
	var unit_w: float = minf(w * 0.32, 0.42)
	var unit_d: float = d * 0.78
	# nestle the unit under the +X end of the bench, just inside the legs
	var ux: float = w * 0.5 - LEG_W - unit_w * 0.5 - 0.02
	var top_under: float = h - TOP_THICK - 0.02
	var bottom: float = h * 0.30
	var stack_h: float = maxf(top_under - bottom, 0.18)
	var count := 3
	var dh: float = stack_h / float(count)
	# carcass back so the drawers read as a box, not floating faces
	add_child(_box(Vector3(ux, bottom + stack_h * 0.5, 0), Vector3(unit_w, stack_h, unit_d), _mat(body_color.darkened(0.1), 0.6, 0.35)))
	for i in range(count):
		var cy: float = bottom + dh * (float(i) + 0.5)
		add_child(_box(Vector3(ux, cy, unit_d * 0.5 + 0.012), Vector3(unit_w * 0.92, dh * 0.82, 0.02), face_mat))
		# thin horizontal handle line near the top of each face
		add_child(_box(Vector3(ux, cy + dh * 0.28, unit_d * 0.5 + 0.03), Vector3(unit_w * 0.5, 0.018, 0.02), handle_mat))


# A few small FIXED tools / parts on the surface — deterministic positions.
func _build_tools(w: float, d: float, h: float) -> void:
	var ty: float = h + 0.001
	var tool_mat := HangarKit.worn_metal(Color(0.55, 0.57, 0.60))
	var part_mat := _mat(Color(0.50, 0.52, 0.56), 0.5, 0.5)
	# a small toolbox-ish box toward the -X back corner
	var bx: float = -w * 0.5 + minf(w * 0.18, 0.22)
	add_child(_box(Vector3(bx, ty + 0.05, -d * 0.22), Vector3(minf(w * 0.18, 0.24), 0.10, d * 0.30), tool_mat))
	# two short cylinders (canisters / parts) standing near centre
	for off in [Vector3(0.02, 0.0, 0.18), Vector3(0.14, 0.0, 0.06)]:
		add_child(_cyl(Vector3(off.x, ty + 0.05, off.z), 0.035, 0.10, part_mat))
	# a flat plate / lid lying near the +X-ish working edge
	add_child(_box(Vector3(w * 0.10, ty + 0.012, 0.0), Vector3(0.18, 0.024, 0.12), part_mat))


# A small framed readout standing at the BACK of the tabletop ("DIAG OK").
func _build_screen(w: float, d: float, h: float) -> void:
	var sw: float = minf(w * 0.34, 0.42)
	var sh: float = sw * 0.62
	var screen: Node3D = HangarKit.readout("DIAG", ["DIAG OK", "ALL NOMINAL"], Vector2(sw, sh))
	if screen:
		# stand it at the back edge, lifted so the bezel clears the top
		screen.position = Vector3(-w * 0.12, h + sh * 0.5 + 0.04, -d * 0.5 + 0.06)
		add_child(screen)
		# a short stalk down to the tabletop so it reads as standing, not floating
		var stalk_h: float = sh * 0.5 + 0.04
		add_child(_box(Vector3(-w * 0.12, h + stalk_h * 0.5, -d * 0.5 + 0.06), Vector3(0.03, stalk_h, 0.03), HangarKit.worn_metal(body_color)))


# Stencilled ID painted on the front apron rail — replaces a floating label.
func _build_stencil(w: float, d: float, apron_cy: float) -> void:
	var q: MeshInstance3D = HangarKit.stencil(stencil_text, Vector2(minf(w * 0.5, 0.7), APRON_H * 0.7))
	if q:
		q.position = Vector3(0, apron_cy, d * 0.5 + 0.012)
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


func _cyl(center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
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
