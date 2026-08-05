# Partial Derivative Terrain — ∂f/∂x and ∂f/∂y on a surface
#
# A bumpy terrain height-field z = f(x, y). Two arrows hover above the surface:
#   - red arrow points in +x direction, length = ∂f/∂x at that point
#   - green arrow points in +y direction, length = ∂f/∂y at that point
# The arrows ride the surface as the cursor moves over it, showing both partial slopes.
#
# Introduces partial differentiation: when you have a function of two variables, you can
# take its derivative with respect to either one. This is the substrate for forces' 3D
# vector calculus and for ML's gradient descent.
#
# @qfep_term: F over a 2D domain.
#
# @identity
# essence: a bumpy height-field z=f(x,y) with two arrows riding the surface — a red ∂f/∂x and a green ∂f/∂y — reading both partial slopes at the sampled point
# desire: to make two-variable differentiation visible as two independent directional slopes on one surface, not a formula on a page
# critical_parameter: height_scale — how pronounced the terrain's bumps are; too flat and the partials vanish, too steep and the arrows overshoot the surface they measure
# triggers: _ready() builds the terrain ArrayMesh from f(x,y) then two arrow meshes; _process walks the sample point and re-reads ∂f/∂x and ∂f/∂y, re-orienting each arrow
# emerges: two slopes at one point — the seed of the gradient vector that forces' 3D calculus and ML's gradient descent later stack into a single arrow
# needs: terrain ArrayMesh [present]; red ∂x + green ∂y arrows [present]; apply_grid_config for grid_size/span [present]; class_name PartialDerivativeTerrain [present]; @identity [present, 2026-07-12]
# relationships: precursor to vector_field_grid (a whole field of such slopes); feeds gradient_descent in formfinding/ML; sibling of riemann_pump and ftc_bridge in the change sequence
# truth: a derivative in more than one dimension is not one number but a choice of direction — you differentiate with respect to whichever axis you think to ask about.

extends Node3D
class_name PartialDerivativeTerrain

@export_category("Terrain Settings")
@export var terrain_color: Color = Color(0.3, 0.5, 0.4, 1.0)
@export var dx_arrow_color: Color = Color(1.0, 0.4, 0.45, 1.0)  # red = ∂/∂x
@export var dy_arrow_color: Color = Color(0.5, 1.0, 0.55, 1.0)  # green = ∂/∂y
@export var grid_size: int = 24
@export var span: float = 2.0
@export var height_scale: float = 0.35
@export var sample_speed: float = 0.5

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — promoted 2026-08-05 (hand promotion; the runner refused
#  this token for NO TURNABLE KNOBS. Three colours and four numbers, and
#  apply_grid_config took two of the numbers AFTER _ready had already
#  used them, so nothing declared changed what the picture ARGUED.)
#
#  phase   — WHERE THE TWO SLOPES ARE READ. slope_tangent_demo's and
#            velocity_arrow's word, and `traverse` is their word for the
#            shipped un-pinned sweep, character for character. THE OTHER
#            THREE VALUES ARE THIS SURFACE'S OWN and were measured, not
#            assumed: crest / trough / saddle were the obvious borrowing
#            and every critical point of this f lies ON THE BOUNDARY of
#            the drawn terrain (at x=±1 or y=±1), so all three would have
#            pinned the arrows off the edge of the mesh they measure.
#            What this surface can answer is the SIGN PATTERN of the two
#            partials, which is the thing a 1D demo cannot have at all:
#              agree  (-0.525, +0.520)  fx +0.305  fy +0.304
#              oppose (-0.550, -0.545)  fx +0.263  fy -0.262
#              single (+0.170, +0.200)  fx +0.525  fy  0.000
#  asked   — WHICH DERIVATIVE YOU THOUGHT TO ASK FOR. This artifact's own
#            truth statement, made settable: `both` is the shipped pair,
#            partial_x and partial_y each withhold the question nobody
#            asked, and `gradient` composes the two into the single arrow
#            that forces and ML later stack them into.
#
#  WHAT IS ADDED, AND ONLY OFF THE DEFAULT. Two things exist only when
#  `phase` names a station, which no map does:
#    - the SLICE RIBBONS: f(·, y0) and f(x0, ·), the two curves the
#      partials are literally the slopes of, drawn on the surface. They
#      are the definition of a partial derivative and were never drawn.
#      They are also the ink: two 2 m ribbons against two 4 cm bars.
#    - SIGNED arrows. _update_arrows has always used abs(dx) and abs(dy)
#      and always placed the bars on the +x and +z side, so a NEGATIVE
#      partial has never been distinguishable from a positive one — the
#      artifact could not show the disagreement it exists to show. At a
#      station the bar is placed on the side its sign points to. At
#      `traverse` the abs() behaviour is untouched, because that is what
#      all 25 placements draw today.
# ─────────────────────────────────────────────────────────────────────

const PHASES := {
	"traverse": Vector2(0.0, 0.0),      # not a station: the shipped moving sample
	"agree": Vector2(-0.525, 0.520),    # fx +0.305, fy +0.304 — both rising
	"oppose": Vector2(-0.550, -0.545),  # fx +0.263, fy -0.262 — the 2D-only case
	"single": Vector2(0.170, 0.200),    # fx +0.525, fy  0.000 — one axis carries it
}
const ASKED := ["both", "partial_x", "partial_y", "gradient"]

@export_enum("traverse", "agree", "oppose", "single") var phase: String = "traverse"
@export_enum("both", "partial_x", "partial_y", "gradient") var asked: String = "both"

var _terrain_mesh: MeshInstance3D
var _dx_arrow: MeshInstance3D
var _dy_arrow: MeshInstance3D
var _slice_x: MeshInstance3D
var _slice_y: MeshInstance3D
var _grad_arrow: MeshInstance3D
var _t: float = 0.0
var _built: bool = false


func _ready() -> void:
	_build_terrain()
	_dx_arrow = _build_arrow(dx_arrow_color)
	_dy_arrow = _build_arrow(dy_arrow_color)
	add_child(_dx_arrow)
	add_child(_dy_arrow)
	_build_dna()
	_built = true


## Reads the two declared axes. GUARDED: a value is taken only when it validates
## AND differs, and the DNA geometry is rebuilt only after the first build. All 25
## placements carry the bare token with no config keys, so none reaches a rebuild.
##
## grid_size and span keep their pre-promotion behaviour INCLUDING THE BROKEN PART
## OF IT: they are still assigned after _ready has already consumed them, so they
## still do nothing, and a map that has been quietly ignoring `span` does not start
## redrawing because this file was touched.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("grid_size"):
		grid_size = int(config_data["grid_size"])
	if config_data.has("span"):
		span = float(config_data["span"])

	var changed: bool = false
	if config_data.has("phase"):
		var p: String = str(config_data["phase"]).to_lower()
		if PHASES.has(p) and p != phase:
			phase = p
			changed = true
	if config_data.has("asked"):
		var a: String = str(config_data["asked"]).to_lower()
		if ASKED.has(a) and a != asked:
			asked = a
			changed = true

	if not changed or not _built:
		return
	_rebuild_dna()


func _process(delta: float) -> void:
	_t += delta * sample_speed
	_update_arrows()


func _f(x: float, y: float) -> float:
	# A double-frequency wavy terrain.
	return sin(x * 1.5) * cos(y * 1.5) * height_scale + sin(x + y) * 0.12 * height_scale


func _df_dx(x: float, y: float) -> float:
	# ∂f/∂x analytically.
	return 1.5 * cos(x * 1.5) * cos(y * 1.5) * height_scale + cos(x + y) * 0.12 * height_scale


func _df_dy(x: float, y: float) -> float:
	# ∂f/∂y analytically.
	return -1.5 * sin(x * 1.5) * sin(y * 1.5) * height_scale + cos(x + y) * 0.12 * height_scale


func _build_terrain() -> void:
	_terrain_mesh = MeshInstance3D.new()
	_terrain_mesh.name = "Terrain"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = span / float(grid_size)
	for i in grid_size:
		for j in grid_size:
			var x0: float = -span * 0.5 + float(i) * step
			var z0: float = -span * 0.5 + float(j) * step
			var x1: float = x0 + step
			var z1: float = z0 + step
			var y00: float = _f(x0, z0)
			var y10: float = _f(x1, z0)
			var y01: float = _f(x0, z1)
			var y11: float = _f(x1, z1)
			# Two triangles per quad.
			st.add_vertex(Vector3(x0, y00, z0))
			st.add_vertex(Vector3(x1, y10, z0))
			st.add_vertex(Vector3(x1, y11, z1))
			st.add_vertex(Vector3(x0, y00, z0))
			st.add_vertex(Vector3(x1, y11, z1))
			st.add_vertex(Vector3(x0, y01, z1))
	st.generate_normals()
	_terrain_mesh.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = terrain_color
	mat.roughness = 0.85
	_terrain_mesh.material_override = mat
	add_child(_terrain_mesh)


func _build_arrow(color: Color) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.4)
	arrow.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow.material_override = mat
	return arrow


# ── DNA geometry ────────────────────────────────────────────────────
# Everything below builds only when an axis asks for it. At phase=traverse and
# asked=both — the shipped pair, and what all 25 placements carry — _build_dna()
# adds no node and changes no visibility flag.

func _build_dna() -> void:
	if phase != "traverse":
		var station: Vector2 = PHASES[phase]
		_slice_x = _build_slice(true, station, dx_arrow_color)
		_slice_y = _build_slice(false, station, dy_arrow_color)
		add_child(_slice_x)
		add_child(_slice_y)
	if asked == "gradient":
		_grad_arrow = _build_arrow(Color(1.0, 0.92, 0.45, 1.0))
		_grad_arrow.name = "GradientArrow"
		add_child(_grad_arrow)
	_apply_asked()


func _rebuild_dna() -> void:
	for node in [_slice_x, _slice_y, _grad_arrow]:
		if node != null and is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_slice_x = null
	_slice_y = null
	_grad_arrow = null
	_build_dna()


# One slice curve drawn as a ribbon lying on the surface. along_x true gives
# f(·, y0) — the curve whose ordinary derivative IS ∂f/∂x at this station — and
# false gives f(x0, ·). Nothing else in this artifact has ever drawn the curve a
# partial derivative is the slope of.
func _build_slice(along_x: bool, station: Vector2, color: Color) -> MeshInstance3D:
	var ribbon: MeshInstance3D = MeshInstance3D.new()
	ribbon.name = "SliceX" if along_x else "SliceY"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = 72
	var half: float = span * 0.5
	var w: float = 0.028   # half-width of the ribbon
	var lift: float = 0.014
	for i in steps:
		var t0: float = -half + 2.0 * half * float(i) / float(steps)
		var t1: float = -half + 2.0 * half * float(i + 1) / float(steps)
		var a0: Vector3
		var a1: Vector3
		var b0: Vector3
		var b1: Vector3
		if along_x:
			a0 = Vector3(t0, _f(t0, station.y) + lift, station.y - w)
			a1 = Vector3(t1, _f(t1, station.y) + lift, station.y - w)
			b0 = Vector3(t0, _f(t0, station.y) + lift, station.y + w)
			b1 = Vector3(t1, _f(t1, station.y) + lift, station.y + w)
		else:
			a0 = Vector3(station.x - w, _f(station.x, t0) + lift, t0)
			a1 = Vector3(station.x - w, _f(station.x, t1) + lift, t1)
			b0 = Vector3(station.x + w, _f(station.x, t0) + lift, t0)
			b1 = Vector3(station.x + w, _f(station.x, t1) + lift, t1)
		st.add_vertex(a0)
		st.add_vertex(a1)
		st.add_vertex(b1)
		st.add_vertex(a0)
		st.add_vertex(b1)
		st.add_vertex(b0)
	st.generate_normals()
	ribbon.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.9
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon.material_override = mat
	return ribbon


# Which of the two questions is on show. `both` leaves everything visible, which
# is the shipped state.
func _apply_asked() -> void:
	var want_x: bool = asked == "both" or asked == "partial_x"
	var want_y: bool = asked == "both" or asked == "partial_y"
	if _dx_arrow != null:
		_dx_arrow.visible = want_x
	if _dy_arrow != null:
		_dy_arrow.visible = want_y
	if _slice_x != null:
		_slice_x.visible = want_x
	if _slice_y != null:
		_slice_y.visible = want_y
	if _grad_arrow != null:
		_grad_arrow.visible = asked == "gradient"


func _update_arrows() -> void:
	# Sample point moves in a small circle.
	var sx: float = sin(_t * 0.4) * 0.7
	var sz: float = cos(_t * 0.6) * 0.7
	if phase != "traverse":
		var station: Vector2 = PHASES[phase]
		sx = station.x
		sz = station.y
	var sy: float = _f(sx, sz)
	var dx: float = _df_dx(sx, sz)
	var dy: float = _df_dy(sx, sz)
	# Place the arrows just above the surface at (sx, sy, sz).
	var lift := Vector3(0, 0.05, 0)
	var origin := Vector3(sx, sy, sz) + lift
	# The shipped drawing reads |∂f/∂x| and always hangs the bar on the +x side,
	# so a sign has never been visible. Off the default the bar moves to the side
	# its sign points to; at `traverse` both signs stay +1 and nothing changes.
	var sign_x: float = 1.0
	var sign_y: float = 1.0
	if phase != "traverse":
		sign_x = -1.0 if dx < 0.0 else 1.0
		sign_y = -1.0 if dy < 0.0 else 1.0
	# +x direction arrow with length = |dx|.
	_dx_arrow.position = origin + Vector3(0.25 * sign_x, 0, 0)
	_dx_arrow.transform.basis = Basis().looking_at(Vector3.RIGHT * sign_x, Vector3.UP)
	_dx_arrow.scale.z = clamp(abs(dx) * 6.0, 0.3, 2.0)
	# +y direction arrow with length = |dy|.
	_dy_arrow.position = origin + Vector3(0, 0, 0.25 * sign_y)
	_dy_arrow.transform.basis = Basis().looking_at(Vector3.FORWARD * sign_y, Vector3.UP)
	_dy_arrow.scale.z = clamp(abs(dy) * 6.0, 0.3, 2.0)
	# The two partials composed — the arrow the later sequences stack them into.
	if _grad_arrow != null:
		var grad: Vector3 = Vector3(dx, 0.0, dy)
		if grad.length() < 0.0005:
			grad = Vector3.RIGHT * 0.0005
		var dir: Vector3 = grad.normalized()
		_grad_arrow.position = origin + dir * 0.25
		_grad_arrow.transform.basis = Basis().looking_at(dir, Vector3.UP)
		_grad_arrow.scale.z = clamp(grad.length() * 6.0, 0.3, 2.0)
