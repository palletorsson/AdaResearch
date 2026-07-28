extends Node3D
class_name FilterBubbleDemo

# @identity
# essence: a topic circle carrying forty content points, and an engine that each tick keeps the point nearest its last choice and re-draws the whole population inside that neighbourhood — the live arc contracts, the radius pulls in, the colours converge on one hue, and every point it dropped stays on the circle as a dimmed ghost at the angle it was first offered at
# desire: to make a recommender's narrowing visible as geometry rather than as a complaint, and to refuse the version of this demo where the discarded options simply vanish and leave a tidy story about preference
# critical_parameter: contraction — the fraction of the angular window that survives each tick; at 0.76 a full circle collapses to a point in nineteen steps, and the ghost spiral those nineteen steps leave behind is the only record that the circle was ever whole
# triggers: _process runs a tick clock; each tick ghosts the current population at its current radius, finds the live point at the smallest angular distance from the last selection, re-centres the window on it, multiplies the window by contraction, and re-samples every point inside the new window
# emerges: the ghosts spiral inward as a legible history — the outer band is the topic as it was first presented, each tighter arc a round of personalisation — so the collapse reads as a sequence of foreclosures with timestamps, not as a preference discovered
# needs: SphereMesh in two MultiMeshes [Godot built-ins]; TorusMesh for the horizon ring that never moves; Grid.gdshader for pad and pedestal [present]; Label3D for the window readout
# relationships: the demand side of the criticalalgorithms room that attention_economy_sim reads from the supply side — one shows five things competing for you, this shows what survives of the world once that competition is resolved on your behalf
# truth: the engine never deletes anything. It only stops sampling, and stopping sampling is indistinguishable from deletion unless something keeps drawing what was dropped — which is why the ghosts are the artifact and the shrinking arc is only the evidence.

## Filter Bubble Demo — a contracting window on a circle that never shrinks.
##
## Everything is procedural in _ready(). One pad, one fixed horizon ring, a live
## population in a MultiMesh, and a ghost MultiMesh that is only ever appended to
## for the length of a run.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

@export var point_count: int = 40
## Radius of the topic circle as first presented — the horizon ring sits here and
## never moves, so the live ring always has something to have shrunk away from.
@export var ring_radius: float = 0.82
## Radius the live ring approaches as the window closes. Never zero: a bubble is
## a small neighbourhood, not a point, and drawing it as a point would overstate.
@export var inner_radius: float = 0.26
@export var tick_period: float = 0.9
## Fraction of the angular window that survives a tick.
@export var contraction: float = 0.76
## Window width (radians, half-angle) at which the run is declared collapsed.
@export var collapse_at: float = 0.03
## Seconds the collapsed state is held before the circle is offered whole again.
@export var hold_seconds: float = 4.0
## Ticks pre-run at build so the artifact is never photographed at step zero,
## with a full circle and no ghosts and therefore no argument.
@export var warm_ticks: int = 5

const RING_Y := 0.52
const PAD_W := 1.86
const GHOST_CAPACITY := 1024
const POINT_R := 0.036

var _rng := RandomNumberGenerator.new()

var _live_angles: Array[float] = []
var _center: float = 0.0
var _spread: float = PI
var _last_sel: float = 0.0
var _foreclosed: int = 0
var _ghost_used: int = 0
var _hold_left: float = 0.0

var _live_field: MultiMeshInstance3D
var _ghost_field: MultiMeshInstance3D
var _selector: MeshInstance3D
var _spoke: MeshInstance3D
var _readout: Label3D

var _accum: float = 0.0
var _t: float = 0.0
var _built: bool = false
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	# Fixed seed: two builds of the same artifact must be pixel-identical, or a
	# render diff cannot tell a live mechanism from scatter noise.
	_rng.seed = 20260729
	_build_pad()
	_build_pedestal()
	_build_horizon()
	_build_fields()
	_build_selector()
	_build_readout()
	_begin_run()
	for _i in range(maxi(0, warm_ticks)):
		_tick()
	_apply_live()
	_update_readout()


func _build_pad() -> void:
	var pad := MeshInstance3D.new()
	pad.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(PAD_W, 0.04, PAD_W)
	pad.mesh = box
	pad.position = Vector3(0.0, 0.02, 0.0)
	pad.material_override = _grid_material(
		Color(0.14, 0.15, 0.19), Color(0.38, 0.43, 0.54), 0.4)
	_own(pad)


func _build_pedestal() -> void:
	var col := MeshInstance3D.new()
	col.name = "Pedestal"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.14
	cyl.height = RING_Y - 0.04
	cyl.radial_segments = 16
	col.mesh = cyl
	col.position = Vector3(0.0, 0.04 + (RING_Y - 0.04) * 0.5, 0.0)
	col.material_override = _grid_material(
		Color(0.20, 0.22, 0.27), Color(0.44, 0.49, 0.60), 0.35)
	_own(col)


## The topic as first presented. It does not move, it does not shrink, and it is
## the only thing in the piece that the engine cannot touch.
func _build_horizon() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "Horizon"
	var torus := TorusMesh.new()
	torus.inner_radius = ring_radius - 0.008
	torus.outer_radius = ring_radius + 0.008
	torus.rings = 64
	torus.ring_segments = 6
	ring.mesh = torus
	ring.position = Vector3(0.0, RING_Y, 0.0)
	ring.material_override = _grid_material(
		Color(0.24, 0.26, 0.32), Color(0.52, 0.58, 0.70), 0.7)
	_own(ring)


func _build_fields() -> void:
	_ghost_field = _sphere_field(GHOST_CAPACITY, 0.25)
	_ghost_field.name = "Ghosts"
	_own(_ghost_field)

	_live_field = _sphere_field(maxi(1, point_count), 2.2)
	_live_field.name = "LivePoints"
	_own(_live_field)


func _sphere_field(capacity: int, emit: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 10
	s.rings = 6
	mm.mesh = s
	mm.instance_count = capacity
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = emit
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _build_selector() -> void:
	_selector = MeshInstance3D.new()
	_selector.name = "Selection"
	var s := SphereMesh.new()
	s.radius = POINT_R * 1.9
	s.height = POINT_R * 3.8
	s.radial_segments = 12
	s.rings = 8
	_selector.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selector.material_override = mat
	_own(_selector)

	# The spoke: centre to selection. It names the neighbourhood the next round
	# will be drawn from, so the contraction is a decision you can see being made.
	_spoke = MeshInstance3D.new()
	_spoke.name = "Spoke"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.006
	cyl.height = 1.0
	cyl.radial_segments = 6
	_spoke.mesh = cyl
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.85, 0.90, 1.0)
	smat.emission_enabled = true
	smat.emission = Color(0.85, 0.90, 1.0)
	smat.emission_energy_multiplier = 1.2
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spoke.material_override = smat
	_own(_spoke)


func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.name = "WindowReadout"
	_readout.text = "FILTER BUBBLE"
	_readout.font_size = 30
	# pixel_size, not font_size, sets the metre width. At the default 0.005 the
	# FORECLOSED line would be 2.3 m across on a 1.86 m pad.
	_readout.pixel_size = 0.0019
	_readout.outline_size = 6
	_readout.modulate = Color(0.92, 0.95, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0.0, RING_Y + 0.62, 0.0)
	_own(_readout)


func _own(n: Node) -> void:
	add_child(n)
	_created.append(n)


# ═══════════════════════════════════════════════════════════════════
# THE ENGINE
# ═══════════════════════════════════════════════════════════════════

## Offer the topic whole. Only called at build and after a collapse has been held
## long enough to be read.
func _begin_run() -> void:
	_center = _rng.randf_range(0.0, TAU)
	_spread = PI
	_foreclosed = 0
	_ghost_used = 0
	_hold_left = 0.0
	if _ghost_field and _ghost_field.multimesh:
		_ghost_field.multimesh.visible_instance_count = 0
	_live_angles.clear()
	var n: int = maxi(1, point_count)
	for i in range(n):
		# The first population is spread evenly — the circle as it is presented
		# before anything has been personalised.
		_live_angles.append(_center + (float(i) / float(n)) * TAU)
	_last_sel = _live_angles[0]


## One round of personalisation.
func _tick() -> void:
	if _live_angles.is_empty():
		return
	var r_now: float = _live_radius()

	# Everything currently on offer becomes a ghost AT ITS OWN ANGLE AND RADIUS,
	# before anything is chosen. Nothing leaves the circle; it only stops being
	# sampled — and the difference between those two is the entire artifact.
	for i in range(_live_angles.size()):
		_add_ghost(_live_angles[i], r_now)

	# Pick the live point at the smallest angular distance from the last choice.
	var best: int = 0
	var best_d: float = _adiff(_live_angles[0], _last_sel)
	for i in range(1, _live_angles.size()):
		var d: float = _adiff(_live_angles[i], _last_sel)
		if d < best_d:
			best_d = d
			best = i
	_last_sel = _live_angles[best]
	_center = _last_sel
	_foreclosed += maxi(0, _live_angles.size() - 1)

	# Close the window and re-draw the whole population inside it.
	_spread = maxf(collapse_at * 0.5, _spread * clampf(contraction, 0.05, 0.99))
	for i in range(_live_angles.size()):
		_live_angles[i] = _center + _rng.randf_range(-_spread, _spread)


## Live ring radius, tied to how open the window still is. The ring shrinks with
## the argument rather than as decoration.
func _live_radius() -> float:
	var openness: float = clampf(_spread / PI, 0.0, 1.0)
	return inner_radius + (ring_radius - inner_radius) * openness


## Hue is read off the ABSOLUTE angle, not off the index. That is what makes the
## convergence on one colour a consequence of the contraction instead of a
## separate effect layered on top of it.
func _hue_at(angle: float) -> Color:
	return Color.from_hsv(fposmod(angle, TAU) / TAU, 0.78, 1.0)


func _adiff(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func _add_ghost(angle: float, radius: float) -> void:
	if _ghost_field == null or _ghost_field.multimesh == null:
		return
	var mm: MultiMesh = _ghost_field.multimesh
	if _ghost_used >= mm.instance_count:
		return
	var s: float = POINT_R * 0.62
	var pos := Vector3(cos(angle) * radius, RING_Y - 0.012, sin(angle) * radius)
	mm.set_instance_transform(_ghost_used,
		Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
	mm.set_instance_color(_ghost_used, _hue_at(angle).darkened(0.62))
	_ghost_used += 1
	mm.visible_instance_count = _ghost_used


func _apply_live() -> void:
	if _live_field == null or _live_field.multimesh == null:
		return
	var mm: MultiMesh = _live_field.multimesh
	var r: float = _live_radius()
	var n: int = mini(_live_angles.size(), mm.instance_count)
	for i in range(n):
		var a: float = _live_angles[i]
		var pos := Vector3(cos(a) * r, RING_Y, sin(a) * r)
		mm.set_instance_transform(i,
			Transform3D(Basis().scaled(Vector3(POINT_R, POINT_R, POINT_R)), pos))
		mm.set_instance_color(i, _hue_at(a))
	mm.visible_instance_count = n

	# Selector and spoke follow the last choice.
	var sel := Vector3(cos(_last_sel) * r, RING_Y, sin(_last_sel) * r)
	if is_instance_valid(_selector):
		_selector.position = sel
		var mat := _selector.material_override as StandardMaterial3D
		if mat:
			var tint: Color = _hue_at(_last_sel)
			mat.albedo_color = tint
			mat.emission = tint
	if is_instance_valid(_spoke):
		var length: float = maxf(0.02, sel.length())
		var mid := Vector3(sel.x * 0.5, RING_Y, sel.z * 0.5)
		var dir: Vector3 = sel.normalized()
		var up := Vector3.UP
		if absf(dir.dot(up)) > 0.999:
			up = Vector3.RIGHT
		var xa: Vector3 = up.cross(dir).normalized()
		var za: Vector3 = dir.cross(xa).normalized()
		_spoke.transform = Transform3D(
			Basis(xa, dir, za).scaled(Vector3(1.0, length, 1.0)), mid)


func _update_readout() -> void:
	if _readout == null:
		return
	var deg: int = int(round(rad_to_deg(_spread) * 2.0))
	_readout.text = "FILTER BUBBLE\nWINDOW %d° OF 360°\nFORECLOSED %d — STILL ON THE CIRCLE" % [
		deg, _foreclosed]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	if _hold_left > 0.0:
		# Collapsed. Held on screen long enough to be read, ghosts intact.
		_hold_left -= delta
		if _hold_left <= 0.0:
			_begin_run()
			_apply_live()
			_update_readout()
		return

	_accum += delta
	if _accum >= tick_period:
		_accum -= tick_period
		_tick()
		_apply_live()
		_update_readout()
		if _spread <= collapse_at:
			_hold_left = maxf(0.5, hold_seconds)

	# Slow drift so the ghost spiral is read as a solid, not a flat diagram.
	if is_instance_valid(_selector):
		_selector.position.y = RING_Y + 0.02 * sin(_t * 2.2)


# ═══════════════════════════════════════════════════════════════════
# MATERIAL + CONFIG
# ═══════════════════════════════════════════════════════════════════

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Free only what this script made, then rebuild synchronously in place. Nothing
## deferred: the grid frames labels and grounds the artifact immediately after
## add_child, and a deferred rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_live_field = null
	_ghost_field = null
	_selector = null
	_spoke = null
	_readout = null
	_accum = 0.0
	_t = 0.0
	_build_all()


## Grid config. Keys: "points", "contraction", "tick_period", "ring_radius",
## "warm_ticks".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_points: int = point_count
	var before_radius: float = ring_radius
	var before_warm: int = warm_ticks

	if config_data.has("points"):
		point_count = clampi(int(config_data["points"]), 6, 120)
	if config_data.has("contraction"):
		contraction = clampf(float(config_data["contraction"]), 0.05, 0.99)
	if config_data.has("tick_period"):
		tick_period = maxf(0.1, float(config_data["tick_period"]))
	if config_data.has("ring_radius"):
		ring_radius = clampf(float(config_data["ring_radius"]), 0.3, 1.4)
	if config_data.has("warm_ticks"):
		warm_ticks = clampi(int(config_data["warm_ticks"]), 0, 30)

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	if (point_count == before_points and is_equal_approx(ring_radius, before_radius)
			and warm_ticks == before_warm):
		# Only the clock or the contraction rate moved — no geometry to rebuild.
		# Rebuilding here would discard the framing curation_station applies one
		# line after config and never re-applies.
		return

	_rebuild_now()
	print("[FilterBubbleDemo] Config applied — points=%d, contraction=%.2f, radius=%.2f" % [
		point_count, contraction, ring_radius])
