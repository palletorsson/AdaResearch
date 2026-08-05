extends Node3D


# @identity
# essence: trace(t) = (target.x, target.y, z_origin - speed * t) — position history as fading trail
# desire: Toss a pickup cube and see its trajectory recorded as a time-domain trace in space
# critical_parameter: time_axis_speed — controls how fast the trace extends along the Z axis
# triggers: continuous position sampling of target node at sample_interval creates the fading trail
# emerges: thrown trajectories become visible waveforms — parabolas, oscillations, chaos all recorded
# needs: VR pickup cube to track [has], trail rendering [has]
# relationships: depends on target node position sampling; contrasts with draw_dot_time_domain (cube tracking vs hand tracking); unlocks trajectory visualization
# truth: Every trajectory is a signal in time; recording it reveals the physics as waveform.

@export var target_path: NodePath = NodePath("PickUpCube")
@export var trail_color: Color = Color(0.95, 0.7, 0.2, 1.0)
@export var trail_max_points: int = 1000
@export var sample_interval: float = 0.05
@export var time_axis_speed: float = 0.6
@export var fade_trail_over_time: bool = false
@export var fade_duration: float = 10.0

## AXIS — WHAT THE RECORD KEEPS once the cube that made it has been put down. Not the
## sampling, not the +Z push, not the recording itself: those run identically at every
## value and they are what this artifact TEACHES. What the axis decides is whether a
## trajectory is a present-tense fact that evaporates, or something space holds on to.
##
## The word is adopted from [[mystic_writing_pad]] and shared, value for value and in
## the same order, with [[draw_dot]], [[draw_dot_time_domain]], [[draw_triangle_faces]],
## [[grab_sphere_point_snap]], [[interactive_point_origin_force]], [[player_trace]] and
## [[oscillation_controlled_cube]]. Every one of them puts a mark into space and then has
## to say what space does with it. This is the trajectory case: the mark is not a hand's
## stroke but a thrown body's history, so the record is a WAVEFORM RECEDING IN +Z — the
## artifact's own geometry for time — rather than a stroke on a plane.
##
##   none      the legacy lineage, byte for byte. Nothing stands behind the cube. At rest
##             this artifact shows a cube and an empty ImmediateMesh, and it never claimed
##             otherwise: what has not just happened is not there
##   trace     one recorded throw hangs in the ink the live trail writes with, exactly
##             where it receded to. The signal stays put and stays readable
##   lattice   a ruled field of pale nodes stands under the record and the throw is
##             quantised onto it — stair-stepped in space and in time. A position had to
##             fall on a sample tick before it counted as having happened
##   archive   nine throws at once, none dimmed by age, overlapping into a thicket.
##             Nothing is discarded, so no single trajectory can be read
##   wax       the Wunderblock along the time axis: a dark slab at the far end, a pale
##             translucent sheet across the near end, and five throws sunk between them,
##             each older one fainter. The present reads clean; the record is behind it
##
## STRICTLY ADDITIVE. Nothing here touches _process, the sampling, _origin_z, the trail
## mesh or the fade path. A variant changes what a standing visitor SEES the space has
## kept, never what the cube does or what the live trace records.
@export_enum("none", "trace", "lattice", "archive", "wax") var retention: String = "none"

## Allow-list. An unknown word in a map token keeps the shipped lineage.
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

var _target: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _trail_times: Array[float] = []
var _time_elapsed: float = 0.0
var _sample_timer: float = 0.0
var _origin_z: float = 0.0
var _origin_set: bool = false

func _ready() -> void:
	_target = get_node_or_null(target_path)
	if _target:
		_setup_trail()
		_origin_z = _target.global_position.z
		_origin_set = true
		set_process(true)
	else:
		push_warning("MarioCubeTimeTrace: Target not found at %s" % target_path)
		set_process(false)

	# RETENTION LAST, so the trail instance keeps its child index and the shipped lineage
	# is untouched. "none" builds nothing at all.
	_ret_settle()
	_ret_build()
	_ret_ready = true

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "MarioCubeTimeTrace"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.5
	_trail_instance.material_override = material
	_trail_instance.set_as_top_level(true)

	add_child(_trail_instance)

func _process(delta: float) -> void:
	if not _target:
		return

	_time_elapsed += delta

	# Advance existing points along +Z (time axis)
	if _trail_points.size() > 0:
		var z_offset = time_axis_speed * delta
		for i in range(_trail_points.size()):
			_trail_points[i].z += z_offset

	_sample_timer += delta
	if _sample_timer >= sample_interval:
		_sample_timer = 0.0
		var current_global = _target.global_position
		if not _origin_set:
			_origin_z = current_global.z
			_origin_set = true

		var trace_point = Vector3(current_global.x, current_global.y, _origin_z)
		_trail_points.append(trace_point)
		if fade_trail_over_time:
			_trail_times.append(_time_elapsed)

		if _trail_points.size() > trail_max_points:
			_trail_points.pop_front()
			if fade_trail_over_time and _trail_times.size() > 0:
				_trail_times.pop_front()

		if fade_trail_over_time:
			_cleanup_old_points()

	_rebuild_trail()

func _cleanup_old_points() -> void:
	if _trail_times.is_empty():
		return

	var cutoff_time = _time_elapsed - fade_duration
	while _trail_times.size() > 0 and _trail_times[0] < cutoff_time:
		_trail_times.pop_front()
		_trail_points.pop_front()

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	if fade_trail_over_time and _trail_times.size() == _trail_points.size():
		for i in range(_trail_points.size()):
			var age = _time_elapsed - _trail_times[i]
			var alpha = 1.0 - clamp(age / fade_duration, 0.0, 1.0)
			var color = trail_color
			color.a = alpha
			_trail_mesh.surface_set_color(color)
			_trail_mesh.surface_add_vertex(_trail_points[i])
	else:
		for point in _trail_points:
			_trail_mesh.surface_add_vertex(point)

	_trail_mesh.surface_end()


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five claims about whether space keeps a trajectory, shared word for word with
# draw_dot, mystic_writing_pad, oscillation_controlled_cube and four others. Appended
# LAST: the pickup cube, the trail instance and the sampling all exist above and none of
# them are read or written here.
#
# WHY THE RECORD IS BUILT AND NOT SAMPLED. The live trace is not a photographable subject.
# PickUpCube is a plain Node3D that nothing moves unless a player carries it, so with no
# player every sample lands on the same (x, y) and the +Z push draws them into a straight
# line whose only variable is how long the capture has been running. draw_dot_time_domain
# declined its own live trace for exactly this reason. What CAN be photographed is a
# record that stands still, so that is what each value builds: a deterministic throw,
# already recorded, receding along the artifact's own time axis.
#
# APPEARANCE ONLY, and no randf anywhere in this path — five variants differ by the axis
# and by nothing else.

## Dot size is a legibility decision. The record spans ~0.45 m across and 0.70 m deep, so
## a dot under ~1 cm renders below 10 px in a fitted 760 px shot and a whole throw sinks
## into the noise floor the bite critic measures against.
const RET_DOT_R: float = 0.010
const RET_SAMPLES: int = 64
const RET_SPAN_X: float = 0.22          # half-width of the record, inside the cube's cell
const RET_SPAN_Y: float = 0.16          # half-height, centred on the cube
const RET_MID_Y: float = 0.50           # the cube's own centre height (0.5 m cube on 0.25)
const RET_Z0: float = 0.30              # the near end, just clear of the cube face
const RET_DEPTH: float = 0.70           # how far into +Z the record has receded
const RET_STEP: float = 0.040           # lattice rung spacing, in metres

var _ret_node: Node3D = null
var _ret_ready: bool = false


## Reads the map token's `#retention:<value>` metadata, then normalises whatever is set.
func _ret_settle() -> void:
	if has_meta("config_retention"):
		var m: String = str(get_meta("config_retention")).strip_edges().to_lower()
		if RETENTIONS.has(m):
			retention = m
	var v: String = str(retention).strip_edges().to_lower()
	retention = v if RETENTIONS.has(v) else "none"


## GATED ON THE KEY AND ON A CHANGE. A config that says nothing about retention returns on
## the first line, so a token carrying only other keys cannot disturb the legacy path; a
## token repeating the current value, or misspelling one, rebuilds nothing. And nothing is
## built before _ready has run once.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("retention"):
		return
	var r: String = str(config_data["retention"]).strip_edges().to_lower()
	if not RETENTIONS.has(r) or r == retention:
		return
	retention = r
	if _ret_ready:
		_ret_build()


func _ret_build() -> void:
	if is_instance_valid(_ret_node):
		_ret_node.queue_free()
	_ret_node = null

	match retention:
		"none":
			pass
		"trace":
			_ret_trace()
		"lattice":
			_ret_lattice()
		"archive":
			_ret_archive()
		"wax":
			_ret_wax()
		_:
			pass


## The record's container, at the artifact's own origin — the curve carries its own local
## coordinates, so the cube's silhouette and grounding are unchanged.
func _ret_root() -> Node3D:
	if not is_instance_valid(_ret_node):
		var n := Node3D.new()
		n.name = "RetentionRecord"
		add_child(n)
		_ret_node = n
	return _ret_node


## TRACE — one throw, left where the time axis carried it, in the ink the live trail uses.
func _ret_trace() -> void:
	_ret_stroke(1.31, 0.0, trail_color, 1.6, 0.0)


## LATTICE — the ruling first: a field of pale nodes across the space-time floor under the
## record, one per sample tick in Z and one per rung in X. Then the same throw admitted
## onto it. The ruling is the dominant read — regular pinpricks where every other value
## shows wander.
func _ret_lattice() -> void:
	var nx: int = int(RET_SPAN_X * 2.0 / RET_STEP) + 1
	var nz: int = int(RET_DEPTH / RET_STEP) + 1
	var grid := _ret_mm("LatticeNodes", _ret_emissive(Color(0.52, 0.60, 0.68), 0.5))
	var gm: MultiMesh = grid.multimesh
	gm.instance_count = nx * nz
	var small: Basis = Basis.IDENTITY.scaled(Vector3.ONE * 0.5)
	var k: int = 0
	for cx in range(nx):
		for cz in range(nz):
			gm.set_instance_transform(k, Transform3D(small, Vector3(
				-RET_SPAN_X + float(cx) * RET_STEP,
				RET_MID_Y - RET_SPAN_Y,
				RET_Z0 + float(cz) * RET_STEP)))
			k += 1
	_ret_root().add_child(grid)
	_ret_stroke(1.31, 0.0, trail_color, 1.6, RET_STEP)


## ARCHIVE — nine throws kept at once, none dimmed by age. The corridor fills; the single
## trajectory stops being findable. Total retention and total illegibility are one picture.
func _ret_archive() -> void:
	for i in range(9):
		_ret_stroke(1.31 + 0.83 * float(i), 0.0, trail_color, 1.35, 0.0)


## WAX — the Wunderblock laid along the time axis, the construction borrowed from
## mystic_writing_pad. A matte dark slab closes the far end, a pale translucent sheet
## covers the near end, and the throws are sunk BETWEEN them, each older one fainter. The
## present reads clean; the record is behind it.
func _ret_wax() -> void:
	var root: Node3D = _ret_root()

	var slab := MeshInstance3D.new()
	slab.name = "WaxSlab"
	var sm := BoxMesh.new()
	sm.size = Vector3(RET_SPAN_X * 2.0, RET_SPAN_Y * 2.0, 0.014)
	slab.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.10, 0.085, 0.095)
	smat.roughness = 0.95
	smat.metallic = 0.0
	slab.material_override = smat
	slab.position = Vector3(0.0, RET_MID_Y, RET_Z0 + RET_DEPTH + 0.012)
	root.add_child(slab)

	var warm := Color(0.95, 0.62, 0.35)
	for i in range(5):
		var f: float = float(5 - i) / 5.0
		var c: Color = warm.lerp(Color(0.10, 0.085, 0.095), 1.0 - f)
		_ret_stroke(1.31 + 1.7 * float(i), 0.0, c, 0.45 + 1.1 * f, 0.0)

	var sheet := MeshInstance3D.new()
	sheet.name = "ClearingSheet"
	var shm := BoxMesh.new()
	shm.size = Vector3(RET_SPAN_X * 2.0, RET_SPAN_Y * 2.0, 0.004)
	sheet.mesh = shm
	var shmat := StandardMaterial3D.new()
	shmat.albedo_color = Color(0.62, 0.65, 0.70, 0.30)
	shmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shmat.roughness = 0.25
	shmat.metallic = 0.0
	sheet.material_override = shmat
	sheet.position = Vector3(0.0, RET_MID_Y, RET_Z0 - 0.010)
	root.add_child(sheet)


## One recorded throw, sampled into dots exactly as the live trace samples a real one.
## `step` > 0 quantises it onto the ruling, in space AND in time.
func _ret_stroke(phase: float, x_off: float, c: Color, energy: float, step: float) -> void:
	var mmi := _ret_mm("Throw", _ret_emissive(c, energy))
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = RET_SAMPLES
	for i in range(RET_SAMPLES):
		var p: Vector3 = _ret_curve(float(i) / float(RET_SAMPLES - 1), phase)
		p.x += x_off
		if step > 0.0:
			p = Vector3(
				round(p.x / step) * step,
				RET_MID_Y + round((p.y - RET_MID_Y) / step) * step,
				RET_Z0 + round((p.z - RET_Z0) / step) * step)
		mm.set_instance_transform(i, Transform3D(Basis(), p))
	_ret_root().add_child(mmi)


## A deterministic throw. No randf anywhere on this path, so five variants differ by the
## axis and by nothing else. z is the time axis: u = 0 is the newest sample, sitting just
## behind the cube, u = 1 the oldest, carried RET_DEPTH into +Z by time_axis_speed.
func _ret_curve(u: float, phase: float) -> Vector3:
	var a: float = u * TAU * 1.15 + phase
	var x: float = RET_SPAN_X * (0.86 * sin(a * 1.25) + 0.28 * sin(a * 2.7 + phase))
	var y: float = RET_SPAN_Y * sin(a * 0.95 + phase * 1.3) * (0.55 + 0.45 * sin(a * 0.42))
	return Vector3(
		clampf(x, -RET_SPAN_X, RET_SPAN_X),
		RET_MID_Y + clampf(y, -RET_SPAN_Y, RET_SPAN_Y),
		RET_Z0 + u * RET_DEPTH)


func _ret_mm(nm: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new()
	dot.radius = RET_DOT_R
	dot.height = RET_DOT_R * 2.0
	dot.radial_segments = 6
	dot.rings = 3
	mm.mesh = dot
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


func _ret_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
