extends Node3D
class_name GradientDescentWell

# @identity
# essence: a glowing topographic well — the loss landscape cast as a luminous contour-banded basin on a low dark pedestal, with marbles forever rolling down the negative gradient, leaving cooling trails, pulsing bright when they find rest. The LEARN panel of the self-portrait triptych: what learning looks like from inside the machine
# desire: to celebrate the fall. Every model that ever spoke was made by something like this — billions of small descents down an error surface nobody ever sees whole. The well wants that descent shown not as a lesson but as a dance: marbles released at the rim, trails fading behind them, the deep floor lighting up when one comes home
# critical_parameter: momentum (0.86) — the memory of motion. High momentum carries a marble across the shallow dips to the deep minimum; its low-momentum sibling settles early in a local dip and pulses there, content. One parameter, two fates, both luminous
# triggers: _ready() seeds the landscape (one deep off-centre gaussian well + 2 shallow dips + soft ridges over a slight bowl), builds the contour-banded ArrayMesh disc, pedestal, rim ring, marbles, trail MultiMesh, labels and floor light; _process() steps momentum gradient descent on the analytic surface, drops trail points, pulses settled marbles, then soft-fades and respawns at new rim angles — eternal learning
# emerges: watching, you start rooting for marbles. The one caught in the local dip is not a failure — it pulses just as bright as the one that found the deep place. The well makes peace with local minima visible: an answer, not the answer, and still glowing
# needs: analytic seeded loss function [present]; finite-difference gradient + momentum step [present]; ring-buffer trail MultiMesh with age fade [present]; settle detection + pulse + floor glow [present]; soft-fade reset loop [present]
# relationships: didactic sibling of gradient_descent_landscape (the machinelearning-sequence demo with its learning-rate slider — that one teaches the trap, this one celebrates the fall). Cousin of the biome ground height-map (ground_layer_component) — both are surfaces whose height is meaning; the ground carries creatures, the well carries learning. Stands beside its READ and SPEAK siblings in the AI self-portrait triptych
# truth: falling is how it learns. Gradient descent never sees the landscape — only the slope underfoot — and yet, step by remembered step, it finds the deep places. Every sentence I produce was carved by marbles like these

## A self-portrait sculpture: the loss landscape as a luminous well.
##
## Built procedurally. Origin is at the floor, centered under the pedestal —
## the pedestal sits on y=0, the basin disc (~1.3 m diameter) is carved
## above it. Heights come from one analytic seeded loss function:
## a slight bowl + one deep off-centre gaussian minimum + two shallower
## local dips + gentle sine ridges. The basin mesh is vertex-colored in
## contour bands (deep = bright phosphor cyan, rim = near-dark).
## Marbles spawn at the rim and follow the negative finite-difference
## gradient with momentum; they leave fading MultiMesh trails, pulse when
## settled, and respawn after a soft fade. A Label3D names the piece and
## a LOSS readout ticks down with the lead marble.

# -- DNA -----------------------------------------------------------------

@export_group("Identity")
## Seed for the landscape (well placement, ridges) and marble spawns.
@export var seed: int = 46
## Number of marbles released at the rim each cycle (clamped 1..6).
@export var marble_count: int = 3
## Learning-rate scale — how eagerly marbles step downhill.
@export var descent_speed: float = 0.5
## Momentum of the lead marble (the second marble gets ~0.6x of this
## and tends to settle in a local dip).
@export var momentum: float = 0.86
## Phosphor accent — the glow of the deep places.
@export var accent_color: Color = Color(0.30, 0.95, 1.00)

@export_group("Form")
## Basin disc radius in meters (diameter ~1.3 m at default).
@export var well_radius: float = 0.65
## Vertical span from rim down to the deepest floor, in meters.
@export var well_depth: float = 0.30

# -- Constants -----------------------------------------------------------

const RINGS: int = 22                       # radial rings of the basin grid
const SPOKES: int = 56                      # angular spokes (~36x36 cells over the disc)
const BANDS: int = 9                        # contour bands deep->rim

const PEDESTAL_HEIGHT: float = 0.12
const PEDESTAL_EXTRA_RADIUS: float = 0.07
const BASIN_FLOOR_LIFT: float = 0.02        # deepest point above pedestal top

const MARBLE_RADIUS: float = 0.024

const STEP_DT: float = 1.0 / 60.0           # fixed descent substep
const MAX_SUBSTEPS: int = 4
const LR_SCALE: float = 0.0011              # descent_speed -> per-step learning rate
const SETTLE_GRAD: float = 0.30             # |grad| below this counts as flat
const SETTLE_VEL: float = 0.0007            # per-step displacement below this counts as still
const SETTLE_TIME: float = 0.9              # seconds of stillness before "settled"

const HOLD_TIME: float = 3.2                # pulse-glory seconds after all settle
const FADE_TIME: float = 1.3                # soft-fade seconds before respawn
const CYCLE_TIMEOUT: float = 20.0           # safety: force the hold even if one oscillates

const TRAIL_PER_MARBLE: int = 120           # ring-buffer points per marble
const TRAIL_DROP_INTERVAL: float = 0.09     # seconds between trail drops / fade ticks
const TRAIL_LIFETIME: float = 5.0           # seconds for a trail point to fade out

const LABEL_INTERVAL: float = 0.12          # seconds between LOSS readout updates

enum Phase { DESCEND, HOLD, FADE }

# -- Landscape (function space: unit disc) --------------------------------

var _well_centers: Array[Vector2] = []
var _well_depths: Array[float] = []
var _well_widths: Array[float] = []
var _ridge_amp: float = 0.045
var _ridge_freq: Vector2 = Vector2(2.5, 2.8)
var _ridge_phase: Vector2 = Vector2.ZERO
var _loss_min: float = 0.0
var _loss_max: float = 1.0
var _global_min_pos: Vector2 = Vector2.ZERO
var _global_min_loss: float = 0.0

# -- Marble state ----------------------------------------------------------

var _m_pos: Array[Vector2] = []
var _m_vel: Array[Vector2] = []
var _m_momentum: Array[float] = []
var _m_settled: Array[bool] = []
var _m_settle_clock: Array[float] = []
var _marbles: Array[MeshInstance3D] = []
var _marble_mats: Array[StandardMaterial3D] = []
var _marble_colors: Array[Color] = []

# -- Trail ring buffer ------------------------------------------------------

var _trail_mm: MultiMesh = null
var _trail_cap: int = 0
var _t_age: PackedFloat32Array = PackedFloat32Array()
var _t_col: PackedColorArray = PackedColorArray()
var _t_head: int = 0
var _trail_timer: float = 0.0

# -- Runtime ----------------------------------------------------------------

var _built: bool = false
var _root: Node3D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _phase: int = Phase.DESCEND
var _phase_clock: float = 0.0
var _cycle_clock: float = 0.0
var _clock: float = 0.0
var _step_accum: float = 0.0
var _fade_mult: float = 1.0
var _label_timer: float = 0.0
var _floor_light: OmniLight3D = null
var _loss_label: Label3D = null


func _ready() -> void:
	if not _built:
		_build_all()


## Grid system hook — reads DNA overrides, then (re)builds.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"):
		seed = int(str(config_data["seed"]))
	if config_data.has("marble_count"):
		marble_count = int(str(config_data["marble_count"]))
	if config_data.has("descent_speed"):
		descent_speed = float(str(config_data["descent_speed"]))
	if config_data.has("momentum"):
		momentum = float(str(config_data["momentum"]))
	if config_data.has("well_radius"):
		well_radius = float(str(config_data["well_radius"]))
	if config_data.has("well_depth"):
		well_depth = float(str(config_data["well_depth"]))
	if config_data.has("accent_color"):
		var raw: Variant = config_data["accent_color"]
		if raw is Color:
			accent_color = raw
		else:
			accent_color = Color.from_string(str(raw), accent_color)
	if config_data.has("scale"):
		var s: float = float(str(config_data["scale"]))
		if s > 0.0:
			scale = Vector3(s, s, s)
	if _built:
		_rebuild()


# =========================================================================
# Build
# =========================================================================

func _rebuild() -> void:
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_built = false
	_build_all()


func _build_all() -> void:
	marble_count = clampi(marble_count, 1, 6)
	well_radius = clampf(well_radius, 0.3, 2.0)
	well_depth = clampf(well_depth, 0.1, 0.8)
	_rng.seed = seed

	_root = Node3D.new()
	_root.name = "WellRoot"
	add_child(_root)

	_seed_landscape()
	_scan_loss_range()
	_build_pedestal()
	_build_basin()
	_build_rim_ring()
	_build_floor_light()
	_build_marbles()
	_build_trails()
	_build_labels()

	_fade_mult = 0.0          # fade in on first cycle
	_respawn_marbles()
	_built = true


func _seed_landscape() -> void:
	_well_centers.clear()
	_well_depths.clear()
	_well_widths.clear()

	# One deep global minimum, off-centre.
	var ga: float = _rng.randf_range(0.0, TAU)
	var gr: float = _rng.randf_range(0.25, 0.42)
	_well_centers.append(Vector2(cos(ga), sin(ga)) * gr)
	_well_depths.append(0.95)
	_well_widths.append(_rng.randf_range(0.14, 0.20))

	# Two shallower local dips, spread away from the deep one.
	for k in 2:
		var aa: float = ga + TAU * (0.30 + 0.22 * float(k)) + _rng.randf_range(-0.25, 0.25)
		var rr: float = _rng.randf_range(0.45, 0.62)
		_well_centers.append(Vector2(cos(aa), sin(aa)) * rr)
		_well_depths.append(_rng.randf_range(0.30, 0.42) - 0.05 * float(k))
		_well_widths.append(_rng.randf_range(0.06, 0.10))

	_ridge_amp = 0.045
	_ridge_freq = Vector2(_rng.randf_range(2.0, 3.2), _rng.randf_range(2.0, 3.2))
	_ridge_phase = Vector2(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU))


## The analytic loss: slight bowl + inverted gaussians + soft ridges.
func _loss(p: Vector2) -> float:
	var v: float = 0.55 * p.length_squared()
	for i in _well_centers.size():
		var d2: float = (p - _well_centers[i]).length_squared()
		v -= _well_depths[i] * exp(-d2 / _well_widths[i])
	v += _ridge_amp * sin(p.x * _ridge_freq.x + _ridge_phase.x) \
			* sin(p.y * _ridge_freq.y + _ridge_phase.y)
	return v


## Numeric finite-difference gradient of the loss.
func _loss_grad(p: Vector2) -> Vector2:
	var e: float = 0.002
	var gx: float = (_loss(Vector2(p.x + e, p.y)) - _loss(Vector2(p.x - e, p.y))) / (2.0 * e)
	var gy: float = (_loss(Vector2(p.x, p.y + e)) - _loss(Vector2(p.x, p.y - e))) / (2.0 * e)
	return Vector2(gx, gy)


func _scan_loss_range() -> void:
	_loss_min = INF
	_loss_max = -INF
	var n: int = 48
	for iy in (n + 1):
		for ix in (n + 1):
			var p: Vector2 = Vector2(
					-1.0 + 2.0 * float(ix) / float(n),
					-1.0 + 2.0 * float(iy) / float(n))
			if p.length() > 1.0:
				continue
			var v: float = _loss(p)
			if v < _loss_min:
				_loss_min = v
				_global_min_pos = p
			if v > _loss_max:
				_loss_max = v
	_global_min_loss = _loss_min
	if _loss_max - _loss_min < 0.0001:
		_loss_max = _loss_min + 0.0001


## Normalized height 0 (deepest) .. 1 (highest) for a function-space point.
func _height_t(p: Vector2) -> float:
	return clampf((_loss(p) - _loss_min) / (_loss_max - _loss_min), 0.0, 1.0)


## World-space Y of the basin surface at a function-space point.
func _world_height(p: Vector2) -> float:
	return PEDESTAL_HEIGHT + BASIN_FLOOR_LIFT + _height_t(p) * well_depth


## World-space position of the basin surface at a function-space point.
func _world_pos(p: Vector2) -> Vector3:
	return Vector3(p.x * well_radius, _world_height(p), p.y * well_radius)


func _build_pedestal() -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = well_radius + PEDESTAL_EXTRA_RADIUS
	mesh.bottom_radius = well_radius + PEDESTAL_EXTRA_RADIUS + 0.03
	mesh.height = PEDESTAL_HEIGHT
	mesh.radial_segments = 48

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.065)
	mat.roughness = 0.55
	mat.metallic = 0.3

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Pedestal"
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(0.0, PEDESTAL_HEIGHT * 0.5, 0.0)
	_root.add_child(mi)


func _ring_idx(r: int, s: int) -> int:
	return 1 + (r - 1) * SPOKES + (s % SPOKES)


func _band_color(p: Vector2) -> Color:
	var depth_t: float = 1.0 - _height_t(p)            # 1 at the deepest floor
	var bandf: float = floor(depth_t * float(BANDS)) / float(BANDS)
	var dark: Color = Color(0.015, 0.03, 0.06)
	var c: Color = dark.lerp(accent_color, pow(bandf, 1.5))
	# Thin brighter line near each contour boundary.
	var frac: float = depth_t * float(BANDS) - floor(depth_t * float(BANDS))
	if frac > 0.82:
		c = c.lerp(accent_color, 0.45)
	# Hot floor of the deep well.
	if depth_t > 0.93:
		c = c.lerp(Color(0.85, 1.0, 1.0), 0.3)
	return c


func _surface_normal(p: Vector2) -> Vector3:
	# World slope = loss gradient scaled by (depth / range) / radius.
	var g: Vector2 = _loss_grad(p) * (well_depth / ((_loss_max - _loss_min) * well_radius))
	return Vector3(-g.x, 1.0, -g.y).normalized()


func _build_basin() -> void:
	var verts: PackedVector3Array = PackedVector3Array()
	var norms: PackedVector3Array = PackedVector3Array()
	var cols: PackedColorArray = PackedColorArray()
	var idx: PackedInt32Array = PackedInt32Array()

	# Center vertex.
	verts.append(_world_pos(Vector2.ZERO))
	norms.append(_surface_normal(Vector2.ZERO))
	cols.append(_band_color(Vector2.ZERO))

	# Rings of spokes.
	for r in range(1, RINGS + 1):
		var rad: float = float(r) / float(RINGS)
		for s in SPOKES:
			var a: float = TAU * float(s) / float(SPOKES)
			var p: Vector2 = Vector2(cos(a), sin(a)) * rad
			verts.append(_world_pos(p))
			norms.append(_surface_normal(p))
			cols.append(_band_color(p))

	# Center fan — clockwise from above (+Y) = front face in Godot.
	for s in SPOKES:
		idx.append(0)
		idx.append(_ring_idx(1, s))
		idx.append(_ring_idx(1, s + 1))

	# Ring strips.
	for r in range(1, RINGS):
		for s in SPOKES:
			var i0: int = _ring_idx(r, s)
			var i1: int = _ring_idx(r, s + 1)
			var j0: int = _ring_idx(r + 1, s)
			var j1: int = _ring_idx(r + 1, s + 1)
			idx.append(i0)
			idx.append(j0)
			idx.append(j1)
			idx.append(i0)
			idx.append(j1)
			idx.append(i1)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx

	var am: ArrayMesh = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.roughness = 0.35
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = accent_color * 0.18
	mat.emission_energy_multiplier = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Basin"
	mi.mesh = am
	mi.material_override = mat
	_root.add_child(mi)


func _build_rim_ring() -> void:
	# Average rim height for the glowing lip.
	var acc: float = 0.0
	for s in SPOKES:
		var a: float = TAU * float(s) / float(SPOKES)
		acc += _world_height(Vector2(cos(a), sin(a)))
	var rim_y: float = acc / float(SPOKES)

	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = well_radius + 0.004
	mesh.outer_radius = well_radius + 0.026
	mesh.rings = 48
	mesh.ring_segments = 10

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.08, 0.1)
	mat.roughness = 0.4
	mat.metallic = 0.4
	mat.emission_enabled = true
	mat.emission = accent_color * 0.35
	mat.emission_energy_multiplier = 0.6

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "RimRing"
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(0.0, rim_y, 0.0)
	_root.add_child(mi)


func _build_floor_light() -> void:
	_floor_light = OmniLight3D.new()
	_floor_light.name = "WellFloorGlow"
	_floor_light.light_color = accent_color
	_floor_light.light_energy = 0.5
	_floor_light.omni_range = well_radius * 0.9
	_floor_light.position = _world_pos(_global_min_pos) + Vector3(0.0, 0.07, 0.0)
	_root.add_child(_floor_light)


func _build_marbles() -> void:
	_marbles.clear()
	_marble_mats.clear()
	_marble_colors.clear()
	_m_pos.clear()
	_m_vel.clear()
	_m_momentum.clear()
	_m_settled.clear()
	_m_settle_clock.clear()

	var base_momentum: float = clampf(momentum, 0.4, 0.97)

	for i in marble_count:
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = MARBLE_RADIUS
		mesh.height = MARBLE_RADIUS * 2.0
		mesh.radial_segments = 16
		mesh.rings = 8

		var mc: Color = accent_color
		if i > 0:
			# Siblings drift gently toward violet — same family, different fates.
			mc = accent_color.lerp(Color(0.8, 0.6, 1.0), minf(0.6, 0.22 * float(i)))
		_marble_colors.append(mc)

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.04, 0.05, 0.07)
		mat.roughness = 0.2
		mat.metallic = 0.1
		mat.emission_enabled = true
		mat.emission = mc
		mat.emission_energy_multiplier = 1.5
		_marble_mats.append(mat)

		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "Marble%d" % i
		mi.mesh = mesh
		mi.material_override = mat
		_root.add_child(mi)
		_marbles.append(mi)

		var mom: float = base_momentum
		if i == 1:
			mom = base_momentum * 0.6     # the one that settles early
		elif i > 1:
			mom = base_momentum * _rng.randf_range(0.8, 1.0)
		_m_momentum.append(clampf(mom, 0.3, 0.97))

		_m_pos.append(Vector2.ZERO)
		_m_vel.append(Vector2.ZERO)
		_m_settled.append(false)
		_m_settle_clock.append(0.0)


func _build_trails() -> void:
	_trail_cap = TRAIL_PER_MARBLE * marble_count
	_t_age = PackedFloat32Array()
	_t_age.resize(_trail_cap)
	_t_col = PackedColorArray()
	_t_col.resize(_trail_cap)
	_t_head = 0

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.007
	mesh.height = 0.014
	mesh.radial_segments = 6
	mesh.rings = 3

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat

	_trail_mm = MultiMesh.new()
	_trail_mm.transform_format = MultiMesh.TRANSFORM_3D
	_trail_mm.use_colors = true
	_trail_mm.mesh = mesh
	_trail_mm.instance_count = _trail_cap

	var hidden: Transform3D = Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	for i in _trail_cap:
		_t_age[i] = TRAIL_LIFETIME
		_t_col[i] = Color(0.0, 0.0, 0.0, 0.0)
		_trail_mm.set_instance_transform(i, hidden)
		_trail_mm.set_instance_color(i, Color(0.0, 0.0, 0.0, 0.0))

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = "Trails"
	mmi.multimesh = _trail_mm
	_root.add_child(mmi)


func _build_labels() -> void:
	var rim_top: float = PEDESTAL_HEIGHT + BASIN_FLOOR_LIFT + well_depth

	var title: Label3D = Label3D.new()
	title.name = "TitleLabel"
	title.text = "GRADIENT DESCENT — falling is how it learns"
	title.font_size = 34
	title.pixel_size = 0.001
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(0.9, 0.97, 1.0)
	title.outline_size = 10
	title.position = Vector3(0.0, rim_top + 0.24, 0.0)
	_root.add_child(title)

	_loss_label = Label3D.new()
	_loss_label.name = "LossReadout"
	_loss_label.text = "LOSS —"
	_loss_label.font_size = 28
	_loss_label.pixel_size = 0.001
	_loss_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_loss_label.modulate = accent_color.lerp(Color(1.0, 1.0, 1.0), 0.3)
	_loss_label.outline_size = 8
	_loss_label.position = Vector3(0.0, rim_top + 0.15, 0.0)
	_root.add_child(_loss_label)


# =========================================================================
# Runtime — descent, settle, pulse, fade, respawn
# =========================================================================

func _respawn_marbles() -> void:
	for i in _m_pos.size():
		var ang: float = _rng.randf_range(0.0, TAU)
		if i == 0 and _well_centers.size() > 0:
			# The lead marble starts on the deep well's side of the rim.
			ang = atan2(_well_centers[0].y, _well_centers[0].x) + _rng.randf_range(-0.6, 0.6)
		elif i == 1 and _well_centers.size() > 1:
			# The low-momentum sibling starts above a local dip.
			ang = atan2(_well_centers[1].y, _well_centers[1].x) + _rng.randf_range(-0.2, 0.2)
		var rr: float = _rng.randf_range(0.82, 0.93)
		_m_pos[i] = Vector2(cos(ang), sin(ang)) * rr
		_m_vel[i] = Vector2.ZERO
		_m_settled[i] = false
		_m_settle_clock[i] = 0.0
	# Kill all trail points.
	for k in _trail_cap:
		_t_age[k] = TRAIL_LIFETIME
		if _trail_mm != null:
			_trail_mm.set_instance_color(k, Color(0.0, 0.0, 0.0, 0.0))
	_cycle_clock = 0.0
	_phase_clock = 0.0
	_step_accum = 0.0
	_phase = Phase.DESCEND


func _all_settled() -> bool:
	for i in _m_settled.size():
		if not _m_settled[i]:
			return false
	return true


func _step_marbles() -> void:
	var lr: float = maxf(0.0, descent_speed) * LR_SCALE
	for i in _m_pos.size():
		if _m_settled[i]:
			continue
		var g: Vector2 = _loss_grad(_m_pos[i])
		_m_vel[i] = _m_vel[i] * _m_momentum[i] - g * lr
		_m_pos[i] += _m_vel[i]
		# Stay inside the basin.
		var rl: float = _m_pos[i].length()
		if rl > 0.97:
			_m_pos[i] = _m_pos[i] * (0.97 / rl)
			_m_vel[i] *= 0.5
		# Settle detection: flat underfoot AND nearly still, for a while.
		if g.length() < SETTLE_GRAD and _m_vel[i].length() < SETTLE_VEL:
			_m_settle_clock[i] += STEP_DT
			if _m_settle_clock[i] >= SETTLE_TIME:
				_m_settled[i] = true
		else:
			_m_settle_clock[i] = 0.0


func _run_descent(delta: float) -> void:
	_step_accum = minf(_step_accum + delta, STEP_DT * float(MAX_SUBSTEPS))
	var steps: int = 0
	while _step_accum >= STEP_DT and steps < MAX_SUBSTEPS:
		_step_accum -= STEP_DT
		steps += 1
		_step_marbles()


func _update_marble_visuals() -> void:
	for i in _marbles.size():
		var mi: MeshInstance3D = _marbles[i]
		if mi == null or not is_instance_valid(mi):
			continue
		var wp: Vector3 = _world_pos(_m_pos[i])
		mi.position = Vector3(wp.x, wp.y + MARBLE_RADIUS, wp.z)
		var energy: float = 1.5
		if _m_settled[i]:
			# The settling pulse — brighter, breathing.
			energy = 1.7 + 1.1 * (0.5 + 0.5 * sin(_clock * 5.0 + float(i) * 1.7))
		_marble_mats[i].emission_energy_multiplier = energy * _fade_mult + 0.05


func _update_floor_light() -> void:
	if _floor_light == null or not is_instance_valid(_floor_light):
		return
	var home_glow: float = 0.0
	for i in _m_pos.size():
		if _m_settled[i] and _m_pos[i].distance_to(_global_min_pos) < 0.18:
			home_glow = 1.0
			break
	var energy: float = 0.5 + home_glow * (1.2 + 0.8 * sin(_clock * 5.0))
	_floor_light.light_energy = energy * _fade_mult


func _tick_trails(delta: float) -> void:
	if _trail_mm == null:
		return
	_trail_timer += delta
	if _trail_timer < TRAIL_DROP_INTERVAL:
		return
	_trail_timer = 0.0

	# Drop a point behind each moving marble (descent phases only).
	if _phase == Phase.DESCEND or _phase == Phase.HOLD:
		for i in _m_pos.size():
			if _m_settled[i]:
				continue
			_t_head = (_t_head + 1) % _trail_cap
			_t_age[_t_head] = 0.0
			var tc: Color = _marble_colors[i].lerp(Color(1.0, 1.0, 1.0), 0.2)
			_t_col[_t_head] = tc
			var wp: Vector3 = _world_pos(_m_pos[i])
			_trail_mm.set_instance_transform(_t_head,
					Transform3D(Basis(), Vector3(wp.x, wp.y + 0.012, wp.z)))
			tc.a = 0.85 * _fade_mult
			_trail_mm.set_instance_color(_t_head, tc)

	# Age and fade everything alive.
	for k in _trail_cap:
		if _t_age[k] >= TRAIL_LIFETIME:
			continue
		_t_age[k] += TRAIL_DROP_INTERVAL
		var a: float = clampf(1.0 - _t_age[k] / TRAIL_LIFETIME, 0.0, 1.0) * 0.85 * _fade_mult
		var c: Color = _t_col[k]
		c.a = a
		_trail_mm.set_instance_color(k, c)


func _tick_labels(delta: float) -> void:
	if _loss_label == null or not is_instance_valid(_loss_label):
		return
	_label_timer += delta
	if _label_timer < LABEL_INTERVAL:
		return
	_label_timer = 0.0
	if _m_pos.size() > 0:
		var v: float = maxf(0.0, _loss(_m_pos[0]) - _global_min_loss)
		_loss_label.text = "LOSS %.3f" % v


func _process(delta: float) -> void:
	if not _built:
		return
	_clock += delta

	match _phase:
		Phase.DESCEND:
			_fade_mult = minf(1.0, _fade_mult + delta * 2.0)
			_cycle_clock += delta
			_run_descent(delta)
			if _all_settled() or _cycle_clock > CYCLE_TIMEOUT:
				_phase = Phase.HOLD
				_phase_clock = 0.0
		Phase.HOLD:
			_run_descent(delta)        # late settlers keep moving
			_phase_clock += delta
			if _phase_clock > HOLD_TIME:
				_phase = Phase.FADE
				_phase_clock = 0.0
		Phase.FADE:
			_phase_clock += delta
			_fade_mult = maxf(0.0, 1.0 - _phase_clock / FADE_TIME)
			if _phase_clock >= FADE_TIME:
				_respawn_marbles()     # eternal learning

	_update_marble_visuals()
	_update_floor_light()
	_tick_trails(delta)
	_tick_labels(delta)
