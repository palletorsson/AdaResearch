extends Node3D

## Pendulum Wave Demo
## A physical pendulum drives a record of its own past. The bob swings in the
## X-Y plane; every sample of its position is kept with the experiment time it
## was taken at, and drawn at a depth (-Z) proportional to how long ago that was.
## Agent-VisualizationExpert: Physics visualization
## Protocol: IACP v2.2
##
## 2026-09-10 (doc/research/waves-chance-noise, batch W1): the motion moved to
## the fixed physics step, the sampler became a fixed-time policy with two
## limits (a count and an age), the trail gained countable marks, and the
## installation gained a frame, a cased readout and a four-button panel.

# The Driver (Pendulum)

# @identity
# essence: angular acceleration = -(g/L) * sin(angle); integrate on physics ticks
# desire: Watch a pendulum swing and see its trajectory traced as a time-domain waveform
# critical_parameter: length — determines natural frequency via sqrt(g/L)
# triggers: initial_angle sets energy; damping controls decay envelope
# emerges: the fundamental connection between pendulum length and oscillation period
# needs: VR grab to set initial angle [missing], length adjustment [missing]
# relationships: depends on gravity simulation; contrasts with spring_demo (gravity vs elasticity); unlocks harmonic motion intuition
# truth: Gravity and a string are sufficient to generate periodic motion.

@onready var pivot: Node3D = $Pivot
@onready var rod: MeshInstance3D = $Pivot/Rod
@onready var bob: MeshInstance3D = $Pivot/Bob

# The Product (Wave Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Physics Parameters
@export var length: float = 2.0
@export var gravity: float = 9.8
@export var initial_angle: float = 45.0 # Degrees
@export var damping: float = 0.0 # Air resistance

# Visualization Parameters
## Depth per second of history: a sample taken s seconds ago is drawn s * time_speed
## metres behind the bob.
@export var time_speed: float = 0.6
## The record's first limit: at most this many samples are kept.
@export var max_trail_length: int = 300
## The record's second limit: nothing older than this many seconds is kept.
@export var max_history_seconds: float = 10.0
## Target intervals are serviced on physics ticks. A 25 ms target at 60 Hz
## produces alternating one/two-tick gaps; the readout exposes that difference.
## "strobe" targets one measured period, so the marks nearly align.
@export_enum("fine", "coarse", "strobe") var sampler: String = "fine"
## Seconds between samples for the fixed-interval policies.
@export var fine_interval: float = 0.025
@export var coarse_interval: float = 0.2
## Height of the pivot above the installation's base.
@export var pivot_height: float = 2.9
## Build the gallows frame, the cased readout and the panel (off for a bare driver).
@export var housed: bool = true

const SAMPLERS: PackedStringArray = ["fine", "coarse", "strobe"]
const FRAME_HALF_WIDTH := 1.7
const MARK_RADIUS := 0.02
const TRAIL_COLOR := Color(0.0, 0.52, 0.72)   # deep teal: pale cyan washed out over the bright floor (12 September)

var time: float = 0.0            # experiment time, advanced by the physics step only
var angle: float = 0.0
var angular_velocity: float = 0.0
var angular_acceleration: float = 0.0
## Each entry is (bob x, bob y, experiment time of the sample). Newest first.
var trail_points: Array[Vector3] = []

var sample_interval: float = 0.025
var _sample_clock: float = 0.0
var _prev_angle: float = 0.0
var _last_upward_crossing: float = -1.0
var _period_measured: float = 0.0
var _marks: MultiMeshInstance3D
var _readout: Label3D
var _panel: Node3D
var _frame_root: Node3D

func _ready() -> void:
	if has_meta("config_sampler"):
		var s: String = str(get_meta("config_sampler")).strip_edges().to_lower()
		sampler = s if SAMPLERS.has(s) else sampler
	if has_meta("config_housed"):
		housed = str(get_meta("config_housed")).strip_edges().to_lower() in ["on", "true", "yes", "1"]
	_strip_standalone_chrome()
	_setup_visuals()
	if housed:
		_build_frame()
		_build_readout()
		_build_panel()
	_apply_sampler()
	reset_experiment()

## The scene carries a camera, a light, an environment and a floor for running it
## on its own. Inside a map or the museum those would fight the room's.
func _strip_standalone_chrome() -> void:
	if get_tree() == null or get_tree().current_scene == self:
		return
	for n in ["Camera3D", "DirectionalLight3D", "WorldEnvironment", "Floor", "Label3D"]:
		var c := get_node_or_null(n)
		if c != null:
			c.queue_free()

func _setup_visuals() -> void:
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = TRAIL_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_instance.material_override = material
	# countable marks: one small sphere per retained sample
	_marks = MultiMeshInstance3D.new()
	_marks.name = "Marks"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = max_trail_length
	mm.visible_instance_count = 0
	var sphere := SphereMesh.new()
	sphere.radius = MARK_RADIUS
	sphere.height = MARK_RADIUS * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var mark_mat := StandardMaterial3D.new()
	mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_mat.albedo_color = Color(0.05, 0.62, 0.78)
	sphere.material = mark_mat
	mm.mesh = sphere
	_marks.multimesh = mm
	add_child(_marks)
	# the pivot, rod and bob
	pivot.position = Vector3(0.0, pivot_height, 0.0)
	rod.position.y = -length / 2.0
	rod.mesh.height = length
	bob.position.y = -length
	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.18, 0.17, 0.16)
	rod_mat.roughness = 0.6
	rod.material_override = rod_mat
	var bob_mat := StandardMaterial3D.new()
	bob_mat.albedo_color = Color(0.93, 0.9, 0.84)
	bob_mat.roughness = 0.55
	bob.material_override = bob_mat

## A gallows: two posts outside the widest swing, a beam, a short drop to the pivot.
func _build_frame() -> void:
	_frame_root = Node3D.new()
	_frame_root.name = "Frame"
	add_child(_frame_root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.15, 0.14)
	mat.roughness = 0.7
	var top := pivot_height + 0.15
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post" + ("L" if side < 0.0 else "R")
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.035
		cyl.bottom_radius = 0.035
		cyl.height = top
		post.mesh = cyl
		post.material_override = mat
		post.position = Vector3(side * FRAME_HALF_WIDTH, top * 0.5, 0.0)
		_frame_root.add_child(post)
		var foot := MeshInstance3D.new()
		foot.name = "Foot" + ("L" if side < 0.0 else "R")
		var disc := CylinderMesh.new()
		disc.top_radius = 0.24
		disc.bottom_radius = 0.26
		disc.height = 0.04
		foot.mesh = disc
		foot.material_override = mat
		foot.position = Vector3(side * FRAME_HALF_WIDTH, 0.02, 0.0)
		_frame_root.add_child(foot)
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.03
	bcyl.bottom_radius = 0.03
	bcyl.height = FRAME_HALF_WIDTH * 2.0
	beam.mesh = bcyl
	beam.material_override = mat
	beam.position = Vector3(0.0, top, 0.0)
	beam.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	_frame_root.add_child(beam)
	var drop := MeshInstance3D.new()
	drop.name = "Drop"
	var dcyl := CylinderMesh.new()
	dcyl.top_radius = 0.02
	dcyl.bottom_radius = 0.02
	dcyl.height = 0.15
	drop.mesh = dcyl
	drop.material_override = mat
	drop.position = Vector3(0.0, pivot_height + 0.075, 0.0)
	_frame_root.add_child(drop)

## The count, cased: a dark plate on a stem beside the trail, three metres down
## the record on the side a visitor walks, at reading height, facing the way
## they arrive (+Z).
func _build_readout() -> void:
	# a dark matte runner on the floor under the record, so the trail and its marks are read
	# against it rather than against the museum's bright floor (12 September)
	var runner := MeshInstance3D.new()
	runner.name = "Runner"
	var rbox := BoxMesh.new()
	rbox.size = Vector3(1.9, 0.012, 4.8)
	runner.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.17, 0.17, 0.18)
	rmat.roughness = 0.95
	runner.material_override = rmat
	runner.position = Vector3(0.0, 0.006, -2.8)
	add_child(runner)
	var housing := Node3D.new()
	housing.name = "ReadoutCase"
	housing.position = Vector3(-FRAME_HALF_WIDTH, 0.0, -3.0)
	add_child(housing)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.13, 0.14)
	mat.roughness = 0.75
	var stem := MeshInstance3D.new()
	stem.name = "Stem"
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.018
	scyl.bottom_radius = 0.018
	scyl.height = 1.3
	stem.mesh = scyl
	stem.material_override = mat
	stem.position = Vector3(0.0, 0.65, 0.0)
	housing.add_child(stem)
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var box := BoxMesh.new()
	box.size = Vector3(0.66, 0.26, 0.02)
	plate.mesh = box
	plate.material_override = mat
	plate.position = Vector3(0.0, 1.45, 0.0)
	housing.add_child(plate)
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.pixel_size = 0.0016
	_readout.font_size = 20
	_readout.outline_size = 0
	_readout.modulate = Color(0.85, 0.95, 1.0)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.position = Vector3(-0.3, 1.45, 0.012)
	housing.add_child(_readout)

## Four buttons on the walk-side post at hand height: the two fixed intervals, the
## strobe, and a reset of this experiment (its swing, its clock and its record —
## never the room's).
func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	_panel = RackTpl.create_panel("SAMPLER", [
		[{"type": "button", "label": "FINE"}, {"type": "button", "label": "COARSE"}],
		[{"type": "button", "label": "STROBE"}, {"type": "button", "label": "RESET"}],
	])
	_panel.name = "Panel"
	# the panel's button areas are hand targets, not the installation's footprint
	_panel.set_meta("em_local_instrument", true)
	# outboard of the walk-side post and turned to face the walkway (local -x; the map's
	# token turns the whole installation 180°, so this is the east walkway), where a
	# standing visitor sees the bob, the trail and the buttons in one frame — it had faced
	# the arrival and showed the walkway its back (Astra's visual review, 12 September)
	_panel.position = Vector3(-FRAME_HALF_WIDTH - 0.12, 1.15, 0.0)
	_panel.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	add_child(_panel)
	var actions := {"Btn_0": func(): set_sampler("fine"), "Btn_1": func(): set_sampler("coarse"),
		"Btn_2": func(): set_sampler("strobe"), "Btn_3": func(): reset_experiment()}
	for btn_name in actions.keys():
		var btn: Node = _panel.find_child(btn_name, true, false)
		if btn == null:
			continue
		var area: Node = btn.get_node_or_null("InteractableAreaButton")
		if area != null and area.has_signal("button_pressed"):
			var action: Callable = actions[btn_name]
			area.button_pressed.connect(func(_b): action.call())

func _physics_process(delta: float) -> void:
	# --- PHYSICS SIMULATION (The Driver), on the fixed step ---
	# Simple Pendulum Equation: alpha = -(g/L) * sin(theta)
	angular_acceleration = -(gravity / length) * sin(angle)
	angular_velocity += angular_acceleration * delta
	angular_velocity *= (1.0 - damping * delta) # Apply damping
	angle += angular_velocity * delta
	time += delta
	_measure_period()
	_update_pendulum_visuals()
	# --- THE RECORD (The Product): a fixed-time sampler with two limits ---
	_sample_clock += delta
	if _sample_clock >= sample_interval:
		_sample_clock -= sample_interval
		var bob_local := Vector3(length * sin(angle), pivot_height - length * cos(angle), 0.0)
		trail_points.push_front(Vector3(bob_local.x, bob_local.y, time))
	while trail_points.size() > max_trail_length:
		trail_points.pop_back()
	while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
		trail_points.pop_back()

func _process(_delta: float) -> void:
	_draw_trail()
	_update_readout()

## The period is measured from the pendulum itself: two successive upward
## crossings of the centre. Constant amplitude (no damping) keeps it steady.
func _measure_period() -> void:
	if _prev_angle < 0.0 and angle >= 0.0 and angular_velocity > 0.0:
		if _last_upward_crossing >= 0.0:
			_period_measured = time - _last_upward_crossing
			if sampler == "strobe":
				sample_interval = _period_measured
		_last_upward_crossing = time
	_prev_angle = angle

func _update_pendulum_visuals() -> void:
	# Rotate pivot to match angle
	pivot.rotation.z = angle

## Depth is elapsed history: a sample s seconds old stands s * time_speed metres
## behind the bob. The oldest retained sample is the farthest mark.
func _draw_trail() -> void:
	trail_mesh.clear_surfaces()
	var mm: MultiMesh = _marks.multimesh
	mm.visible_instance_count = trail_points.size()
	if trail_points.is_empty():
		return
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(trail_points.size()):
		var p: Vector3 = trail_points[i]
		var depth: float = (time - p.z) * time_speed
		var at := Vector3(p.x, p.y, -depth)
		trail_mesh.surface_add_vertex(at)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
	trail_mesh.surface_end()

func _update_readout() -> void:
	if _readout == null:
		return
	var kept: float = retained_seconds()
	var period_line: String
	if _period_measured > 0.0:
		period_line = "period %.2f s measured" % _period_measured
	else:
		period_line = "period %.2f s small-angle" % small_angle_period()
	var every: String = ("%.2f s" % sample_interval) if sample_interval >= 1.0 else ("%d ms" % int(round(sample_interval * 1000.0)))
	var gaps: Vector2 = recorded_interval_range()
	var actual := "actual gaps: waiting for 2 marks"
	if trail_points.size() >= 2:
		actual = "actual gaps %.1f–%.1f ms" % [gaps.x * 1000.0, gaps.y * 1000.0]
	_readout.text = "t %.1f s · %d marks kept %.1f s\ntarget %s · %.1f m per s\n%s\n%s · step %.1f ms" % [
		time, trail_points.size(), kept, every, time_speed, actual,
		period_line, 1000.0 / float(Engine.physics_ticks_per_second)]

# ── controls ─────────────────────────────────────────────────────────────────

## Change the sampling policy. The swing is not touched — the same motion is
## recorded under the new policy — but the record starts again, so the count
## that fills is the new policy's.
func set_sampler(name: String) -> void:
	if not SAMPLERS.has(name):
		return
	sampler = name
	_apply_sampler()
	trail_points.clear()
	_sample_clock = 0.0

func _apply_sampler() -> void:
	match sampler:
		"coarse":
			sample_interval = coarse_interval
		"strobe":
			sample_interval = _period_measured if _period_measured > 0.0 else small_angle_period()
		_:
			sample_interval = fine_interval

## Reset THIS experiment: the swing to its starting angle at rest, its clock to
## zero, its record to empty. The room's clock is not ours to reset.
func reset_experiment() -> void:
	angle = deg_to_rad(initial_angle)
	angular_velocity = 0.0
	angular_acceleration = 0.0
	time = 0.0
	_prev_angle = angle
	_last_upward_crossing = -1.0
	_period_measured = 0.0
	trail_points.clear()
	_sample_clock = 0.0
	_apply_sampler()
	_update_pendulum_visuals()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("sampler"):
		var s: String = str(config["sampler"]).strip_edges().to_lower()
		if SAMPLERS.has(s) and s != sampler:
			set_sampler(s)

# ── accessors (probes and readouts) ───────────────────────────────────────────

func small_angle_period() -> float:
	return TAU * sqrt(length / gravity)

func sample_count() -> int:
	return trail_points.size()

## Age of the oldest retained sample, in experiment seconds.
func retained_seconds() -> float:
	if trail_points.is_empty():
		return 0.0
	return time - trail_points.back().z

func experiment_time() -> float:
	return time

func period_measured() -> float:
	return _period_measured

func current_interval() -> float:
	return sample_interval

## Observed gaps between retained timestamped samples, not the requested rate.
func recorded_interval_range() -> Vector2:
	if trail_points.size() < 2:
		return Vector2.ZERO
	var lo := INF
	var hi := 0.0
	for i in range(1, trail_points.size()):
		var gap: float = trail_points[i - 1].z - trail_points[i].z
		lo = minf(lo, gap)
		hi = maxf(hi, gap)
	return Vector2(lo, hi)

func oldest_depth() -> float:
	return retained_seconds() * time_speed

func mark_world_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in trail_points:
		out.append(to_global(Vector3(p.x, p.y, -(time - p.z) * time_speed)))
	return out

func bob_world_position() -> Vector3:
	return bob.global_position

func readout_text() -> String:
	return _readout.text if _readout != null else ""
