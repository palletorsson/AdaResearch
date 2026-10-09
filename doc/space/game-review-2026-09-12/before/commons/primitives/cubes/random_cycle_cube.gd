extends Node3D

const GRID_SHADER: Shader = preload("res://commons/resourses/shaders/SimpleGrid.gdshader")

# --- DNA (stage 2 - variation), promoted 2026-08-03 -------------------------
#
# WHAT THIS IS. A one-metre cube in a floor that sinks out from under you on
# randomised timing and comes back. Every knob it had was a DURATION - waits,
# sink time, rise time, collider lead and lag - and a still photograph cannot
# see a duration. Sweeping any of them would have produced identical frames at
# random moments, which is the failure this codebase already paid for once with
# info_board. So neither axis below is a rate.
#
# AXIS 1 - POSTURE: which moment of the cycle this one is caught at. Borrowed
# from [[spring_hopper]], [[kresling_spire]] and [[armadillo_eggling]] in this
# same corpus - same question (which body is this thing holding), same
# sentinel-first shape where `cycle` means the state machine keeps sole
# ownership. The four states already exist as CycleState and drive height,
# colour, indicator and collider together; nothing outside the loop could ever
# select one, so every r_c in the corpus is photographed at a coin-flip moment.
#
#   cycle     SHIPPED. The random loop runs and owns position, colour and
#             collider exactly as before. A pure no-op branch.
#   seated    IDLE held. Full height, cyan, collider on, indicator dark.
#   leaving   GOING_OUT held partway down. Orange, indicator LIT, collider
#             still on - the frame where the floor has not yet betrayed you.
#   sunken    HIDDEN held. Down a full sink_distance, dimmed to hidden_color
#             at alpha 0.25, collider OFF. The gap you fall through.
#   arriving  COMING_IN held near the top. Green, indicator LIT, collider back
#             on. The same geometry as `leaving` and the opposite promise.
#
# `leaving` and `arriving` are pinned at different fractions of the travel
# (0.45 and 0.20) on purpose: they are both mid-transit snapshots, the exact
# fraction is arbitrary, and two frames that differ only in hue would buy a
# rung that answers less than it costs.
#
# AXIS 2 - WARNING: how much the block tells you before it costs you anything.
# Adopted word for word from [[path_block]] and [[catalyst_vent]], which ask it
# of an obstacle and of a spawn seam. This cube belongs in that conversation:
# it is a floor tile whose entire function is CONSEQUENCE, and it already ships
# with one answer - a lit mote on its crown - that nobody had ever named.
#
#   beacon  SHIPPED. The emissive sphere at y=0.72, lit only while the block is
#           moving. Broadcast as light, and silent at both ends of the cycle.
#   stain   no mote; a discolouration soaked into the floor at its foot, always
#           there. Addressed to your feet: readable only from the cell itself.
#   cage    no mote; four bars standing at the corners of the cell, always
#           there. Someone catalogued the hazard and fenced it. The block sinks
#           through the bars on exactly the same rule.
#   none    nothing at all. Only the cube's own colour, and colour is the one
#           thing you are not looking at when you are looking where to step.
#
# `stain` and `cage` are top_level, so they stay in the floor while the cube
# leaves it - which is the entire difference between a warning and a skirt.
#
# BOTH DEFAULTS ARE NO-OPS. `cycle` takes the identical _ready path as before
# (_set_state(IDLE) then a deferred loop start) and `beacon` leaves the
# indicator's visibility rule as `is_visible and true`. The 6 existing
# placements (Random_Game and its three placement siblings, Random_Game_Placed,
# TemplateMap_Descent13) are byte-identical to before.
#
# CYCLE_SEED is a fixture knob, not an axis. _rng.randomize() is right in a map
# and fatal on a bench. 0 keeps it; any non-zero pins the wait draw.

const POSTURES: PackedStringArray = ["cycle", "seated", "leaving", "sunken", "arriving"]
const WARNINGS: PackedStringArray = ["beacon", "stain", "cage", "none"]

@export_enum("cycle", "seated", "leaving", "sunken", "arriving") var posture: String = "cycle"
@export_enum("beacon", "stain", "cage", "none") var warning: String = "beacon"
@export var cycle_seed: int = 0

@export_group("Timing")
@export var wait_min_seconds: float = 1.0
@export var wait_span_seconds: float = 6.0
@export var sink_duration: float = 0.5
@export var disable_collider_delay: float = 0.2
@export var enable_collider_delay: float = 0.2
@export var rise_duration: float = 0.2
@export var sink_distance: float = 0.5

@export_group("Visual")
@export var idle_color: Color = Color(0.20, 0.92, 1.00, 1.0)
@export var outgoing_color: Color = Color(1.00, 0.44, 0.18, 1.0)
@export var incoming_color: Color = Color(0.28, 1.00, 0.52, 1.0)
@export var hidden_color: Color = Color(0.12, 0.14, 0.18, 0.25)
@export var wireframe_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var wireframe_width: float = 1.8
@export var wireframe_blur: float = 1.0
@export var wireframe_emission_strength: float = 1.45
@export var force_upright: bool = true

# ── THE CHASM (stand:chasm) — R5, 12 September 2026 ─────────────────────────
#
# WHAT THIS IS FOR. Everything above is one tile. The room this tile was written
# for asks a question a single tile cannot pose: HOW CAN YOU PLAN WHEN THE NEXT
# STATE IS KNOWN BUT ITS TIMING IS NOT? The state order is fixed and public —
# it stands, it leaves, it is gone, it returns — and only the waits are drawn.
# So the staging is a CROSSING: a row of these tiles across a hole in the floor,
# read from its near lip and rewarded at its far one.
#
# THE HOLE IS THE HALL'S, NOT THE ARTIFACT'S. Random_Game's map carries a five
# by three pit of `0` cells, and a `0` is a hole the museum lays no floor on —
# which is why that room's own text could only say its support was unverified.
# The staging cuts that void into a crossing instead of papering it: the museum
# keeps its hole, and the artifact supplies the three things a hole needs before
# a body may be asked to cross it —
#
#   a BED       one metre down, the artifact's own slab, so the fall is a fall
#               and not a disappearance. A sunken stone comes to rest two
#               centimetres proud of it: the floor that left you is the floor
#               you land on.
#   a WAY OUT   a ramp up the pit's west side, back to the near lip. A fall
#               costs the walk back, nothing else.
#   a LIP       cut sides, kerbs broken where the stones cross, and the far
#               side worth reaching.
#
#   stand:none    SHIPPED. Builds nothing of this. The 7 existing placements
#                 take the identical path they always took.
#   stand:chasm   The bed, the way out, the cut sides and kerbs, the carved
#                 stele (the ORDER), the live tablet (the DRAWN waits and the
#                 time left of each), the controls, two braziers, and the idol
#                 at the far lip with the crossing's seed cut into it.
#
# This cube is the MIDDLE stone: the tile the token names is the tile you step
# on. The apron is its child and is held still while this cube sinks (_process
# cancels the sink out of the staging's own offset), because the floor betraying
# you must not take the room with it.
#
# THE DEADLINE IS STORED. The loop drew its wait and handed it straight to a
# timer, so the wait existed only inside that timer: nothing could say how long
# was left, and a countdown drawn fresh each frame is not a countdown but a new
# dice roll wearing a clock's face. _note_step records the kind, the draw and
# the millisecond it expires; the tablet and the cue both read THAT.
#
#   advance_seconds  0 = shipped (the beacon, lit only while the block moves).
#                    > 0 lights a crown ring this long before the STORED
#                    deadline, while the block still stands — the difference
#                    between being told and finding out.
#   hidden_*         0 = shipped (one band for both waits). Set, they give the
#                    gone-wait its own band, so a crossing can be crossable.
#   count            how many stones (odd, so this one stays the middle).
#   seed             the crossing's five-digit name; -1 names one and prints it.
@export_enum("none", "chasm") var stand: String = "none"
@export var crossing_seed: int = -1
@export var stone_count: int = 3
@export var advance_seconds: float = 0.0
@export var hidden_min_seconds: float = 0.0
@export var hidden_span_seconds: float = 0.0
@export var pit_width: float = 5.0

enum CycleState {
	IDLE,
	GOING_OUT,
	HIDDEN,
	COMING_IN
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _state: int = CycleState.IDLE
var _loop_ticket: int = 0
var _base_position: Vector3 = Vector3.ZERO

var _cube_mesh: MeshInstance3D = null
var _indicator_mesh: MeshInstance3D = null
var _collider_body: StaticBody3D = null
var _collision_shape: CollisionShape3D = null

var _cube_material: ShaderMaterial = null
var _indicator_material: StandardMaterial3D = null

# WARNING dressing. Built only for stain / cage, so `beacon` and `none` add no
# nodes and the shipped child order is untouched.
var _warn_root: Node3D = null
var _warn_material: StandardMaterial3D = null
var _built: bool = false

# The stored deadline: what was drawn, and when it runs out.
var _step_kind: String = ""
var _step_wait: float = 0.0
var _step_until_ms: int = 0
var _cycles_done: int = 0
var _crown: MeshInstance3D = null
var _crown_material: StandardMaterial3D = null

# The crossing (stand:chasm only).
var _crossing: Node3D = null
var _crossing_base_y: float = 0.0
var _stones: Array = []
var _tablet: Label3D = null
var _seed_cut: Label3D = null
var _idol_material: StandardMaterial3D = null
var _crossing_rng: RandomNumberGenerator = null
var _tablet_due: float = 0.0

func _ready() -> void:
	if cycle_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = cycle_seed
	if force_upright:
		rotation_degrees = Vector3.ZERO
	_ensure_nodes()
	_setup_materials()
	_base_position = position
	_build_warning()
	if posture == "cycle":
		_set_state(CycleState.IDLE)
		call_deferred("_begin_cycle_loop")
	else:
		_apply_posture()
	call_deferred("_anchor_warning")
	_built = true
	# Shipped placements do not tick: nothing below is asked of a bare cube.
	set_process(false)
	if stand == "chasm":
		_prepare_crossing()
		_apply_stand()

func _ensure_nodes() -> void:
	_cube_mesh = get_node_or_null("CubeMesh") as MeshInstance3D
	if _cube_mesh == null:
		_cube_mesh = MeshInstance3D.new()
		_cube_mesh.name = "CubeMesh"
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = Vector3.ONE
		_cube_mesh.mesh = box_mesh
		add_child(_cube_mesh)

	_indicator_mesh = get_node_or_null("StateIndicator") as MeshInstance3D
	if _indicator_mesh == null:
		_indicator_mesh = MeshInstance3D.new()
		_indicator_mesh.name = "StateIndicator"
		_indicator_mesh.position = Vector3(0.0, 0.72, 0.0)
		_indicator_mesh.visible = false
		add_child(_indicator_mesh)
	if _indicator_mesh.mesh == null:
		var sphere_mesh: SphereMesh = SphereMesh.new()
		sphere_mesh.radius = 0.09
		sphere_mesh.height = 0.18
		_indicator_mesh.mesh = sphere_mesh

	_collider_body = get_node_or_null("ColliderBody") as StaticBody3D
	if _collider_body == null:
		_collider_body = StaticBody3D.new()
		_collider_body.name = "ColliderBody"
		add_child(_collider_body)

	_collision_shape = _collider_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape == null:
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape3D"
		var box_shape: BoxShape3D = BoxShape3D.new()
		box_shape.size = Vector3.ONE
		_collision_shape.shape = box_shape
		_collider_body.add_child(_collision_shape)

func _setup_materials() -> void:
	_cube_material = ShaderMaterial.new()
	_cube_material.shader = GRID_SHADER
	_cube_material.set_shader_parameter("wireframeColor", wireframe_color)
	_cube_material.set_shader_parameter("width", wireframe_width)
	_cube_material.set_shader_parameter("blur", wireframe_blur)
	_cube_material.set_shader_parameter("emission_strength", wireframe_emission_strength)
	_cube_material.set_shader_parameter("show_interior", true)
	_cube_material.set_shader_parameter("wireframeOpacity", 1.0)
	_cube_material.set_shader_parameter("globalOpacity", 1.0)
	if _cube_mesh:
		_cube_mesh.material_override = _cube_material

	_indicator_material = StandardMaterial3D.new()
	_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_indicator_material.emission_enabled = true
	_indicator_material.emission_energy = 1.1
	_indicator_material.metallic = 0.0
	_indicator_material.roughness = 0.25
	if _indicator_mesh:
		_indicator_mesh.material_override = _indicator_material


## AXIS 1. Freeze the cube at one moment of the cycle. Never reached at the
## default `cycle`, which is guarded out in _ready so the loop keeps sole
## ownership of position, colour and collider exactly as it always has.
func _apply_posture() -> void:
	match posture:
		"seated":
			position.y = _base_position.y
			_set_collision_enabled(true)
			_set_state(CycleState.IDLE)
		"leaving":
			position.y = _base_position.y - sink_distance * 0.45
			_set_collision_enabled(true)
			_set_state(CycleState.GOING_OUT)
		"sunken":
			position.y = _base_position.y - sink_distance
			_set_collision_enabled(false)
			_set_state(CycleState.HIDDEN)
		"arriving":
			position.y = _base_position.y - sink_distance * 0.20
			_set_collision_enabled(true)
			_set_state(CycleState.COMING_IN)
		_:
			_set_state(CycleState.IDLE)


## AXIS 2. `beacon` and `none` build nothing — the shipped indicator sphere is
## already there and `_set_indicator_visual` decides whether it may show.
func _build_warning() -> void:
	if _warn_root != null and is_instance_valid(_warn_root):
		if _warn_root.get_parent() == self:
			remove_child(_warn_root)
		_warn_root.queue_free()
	_warn_root = null
	_warn_material = null

	match warning:
		"stain":
			_warn_material = _make_warn_material(0.30)
			_warn_root = Node3D.new()
			_warn_root.name = "WarnStain"
			_warn_root.top_level = true
			var patch: MeshInstance3D = MeshInstance3D.new()
			patch.name = "Patch"
			var quad: QuadMesh = QuadMesh.new()
			quad.size = Vector2(1.34, 1.34)
			patch.mesh = quad
			patch.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			patch.position = Vector3(0.0, -0.49, 0.0)
			patch.material_override = _warn_material
			_warn_root.add_child(patch)
			add_child(_warn_root)
		"cage":
			_warn_material = _make_warn_material(0.85)
			_warn_root = Node3D.new()
			_warn_root.name = "WarnCage"
			_warn_root.top_level = true
			var bar_mesh: BoxMesh = BoxMesh.new()
			bar_mesh.size = Vector3(0.07, 1.02, 0.07)
			var corners: Array[Vector2] = [
				Vector2(-0.58, -0.58), Vector2(0.58, -0.58),
				Vector2(-0.58, 0.58), Vector2(0.58, 0.58)]
			for c in corners:
				var bar: MeshInstance3D = MeshInstance3D.new()
				bar.mesh = bar_mesh
				bar.position = Vector3(c.x, 0.01, c.y)
				bar.material_override = _warn_material
				_warn_root.add_child(bar)
			add_child(_warn_root)
		_:
			pass


func _make_warn_material(alpha_value: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy = 1.0
	mat.metallic = 0.0
	mat.roughness = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(outgoing_color.r, outgoing_color.g, outgoing_color.b, alpha_value)
	mat.emission = outgoing_color
	mat.set_meta("warn_alpha", alpha_value)
	return mat


## A stain that sinks with the block is a skirt, not a stain. The dressing is
## top_level, so it is pinned to the cell once the map has finished placing us —
## deferred, because global_position is not final inside _ready.
func _anchor_warning() -> void:
	if _warn_root == null or not is_instance_valid(_warn_root):
		return
	_warn_root.global_position = global_position + Vector3(0.0, _base_position.y - position.y, 0.0)
	_warn_root.global_rotation = Vector3.ZERO


func _begin_cycle_loop() -> void:
	_loop_ticket += 1
	var ticket: int = _loop_ticket
	_run_cycle_loop(ticket)

func _restart_cycle_loop() -> void:
	call_deferred("_begin_cycle_loop")

func _run_cycle_loop(ticket: int) -> void:
	while is_inside_tree() and ticket == _loop_ticket:
		var visible_wait: float = _next_random_wait()
		_note_step("stands", visible_wait)
		await get_tree().create_timer(visible_wait).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_state(CycleState.GOING_OUT)
		await _animate_vertical(_base_position.y - sink_distance, sink_duration)
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		await get_tree().create_timer(max(0.0, disable_collider_delay)).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_collision_enabled(false)
		_set_state(CycleState.HIDDEN)

		var hidden_wait: float = _next_random_wait("gone")
		_note_step("gone", hidden_wait)
		await get_tree().create_timer(hidden_wait).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_state(CycleState.COMING_IN)
		await get_tree().create_timer(max(0.0, enable_collider_delay)).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_collision_enabled(true)
		await _animate_vertical(_base_position.y, rise_duration)
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_state(CycleState.IDLE)
		_cycles_done += 1

func _animate_vertical(target_y: float, duration_seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", target_y, max(0.01, duration_seconds))
	await tween.finished

func _set_collision_enabled(enabled: bool) -> void:
	if _collision_shape:
		_collision_shape.disabled = not enabled

func _set_state(next_state: int) -> void:
	_state = next_state
	match _state:
		CycleState.IDLE:
			_set_cube_visual(idle_color, 1.0)
			_set_indicator_visual(idle_color, false)
		CycleState.GOING_OUT:
			_set_cube_visual(outgoing_color, 1.0)
			_set_indicator_visual(outgoing_color, true)
		CycleState.HIDDEN:
			_set_cube_visual(hidden_color, hidden_color.a)
			_set_indicator_visual(outgoing_color, false)
		CycleState.COMING_IN:
			_set_cube_visual(incoming_color, 1.0)
			_set_indicator_visual(incoming_color, true)
		_:
			_set_cube_visual(idle_color, 1.0)
			_set_indicator_visual(idle_color, false)

func _set_cube_visual(color_value: Color, alpha_value: float) -> void:
	if _cube_material == null:
		return
	var albedo: Color = Color(color_value.r, color_value.g, color_value.b, clamp(alpha_value, 0.0, 1.0))
	var emission: Color = Color(color_value.r, color_value.g, color_value.b, 1.0)
	var edge_color: Color = color_value.lerp(wireframe_color, 0.55)
	var edge_alpha: float = clamp(max(0.2, albedo.a), 0.0, 1.0)
	_cube_material.set_shader_parameter("modelColor", albedo)
	_cube_material.set_shader_parameter("emissionColor", emission)
	_cube_material.set_shader_parameter("wireframeColor", edge_color)
	_cube_material.set_shader_parameter("modelOpacity", albedo.a)
	_cube_material.set_shader_parameter("wireframeOpacity", edge_alpha)

func _set_indicator_visual(color_value: Color, is_visible: bool) -> void:
	# At the default warning="beacon" this reads `is_visible and true`, which is
	# the shipped rule character for character.
	if _indicator_mesh:
		_indicator_mesh.visible = is_visible and warning == "beacon"
	if _indicator_material:
		_indicator_material.albedo_color = color_value
		_indicator_material.emission = color_value
	if _warn_material != null:
		var wa: float = 0.30
		if _warn_material.has_meta("warn_alpha"):
			wa = float(_warn_material.get_meta("warn_alpha"))
		_warn_material.albedo_color = Color(color_value.r, color_value.g, color_value.b, wa)
		_warn_material.emission = Color(color_value.r, color_value.g, color_value.b, 1.0)

## The draw. `kind` is "stands" or "gone"; the gone-wait takes its own band only
## when one was set (hidden_span_seconds > 0), so the shipped call — one band for
## both ends of the cycle — is unchanged.
func _next_random_wait(kind: String = "stands") -> float:
	var min_wait: float = max(0.1, wait_min_seconds)
	var max_wait: float = max(min_wait, wait_span_seconds)
	if kind == "gone" and hidden_span_seconds > 0.0:
		min_wait = max(0.1, hidden_min_seconds)
		max_wait = max(min_wait, hidden_span_seconds)
	if is_equal_approx(min_wait, max_wait):
		return min_wait
	return _rng.randf_range(min_wait, max_wait)


## The stored deadline. One draw, one expiry, read by everything that wants to
## know how long is left: the tablet's bar, the advance cue, a probe.
func _note_step(kind: String, wait_seconds: float) -> void:
	_step_kind = kind
	_step_wait = wait_seconds
	_step_until_ms = Time.get_ticks_msec() + int(round(wait_seconds * 1000.0))


## What this tile is doing, as the room can read it.
func step_state() -> Dictionary:
	var left: float = max(0.0, float(_step_until_ms - Time.get_ticks_msec()) / 1000.0)
	return {
		"step": _step_kind,
		"wait": snappedf(_step_wait, 0.01),
		"left": snappedf(left, 0.01),
		"cycles": _cycles_done,
		"standing": _state == CycleState.IDLE,
		"supports": _collision_shape != null and not _collision_shape.disabled,
		"crown": _crown != null and _crown.visible,
	}

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	# DNA axes, read first so the numeric shorthand below cannot swallow them.
	# Each is guarded: an unknown word, or the value already held, changes
	# nothing at all. `restate` is what licenses touching a built cube.
	var restate: bool = false

	if config_data.has("posture"):
		var p: String = str(config_data["posture"]).strip_edges().to_lower()
		if POSTURES.has(p) and p != posture:
			posture = p
			restate = true

	if config_data.has("warning"):
		var w: String = str(config_data["warning"]).strip_edges().to_lower()
		if WARNINGS.has(w) and w != warning:
			warning = w
			restate = true

	# The crossing: a word for the staging, its five-digit name, the stone count
	# and which cue it offers. Read before the numeric shorthand below, like the
	# axes above, and each guarded so a shipped token reaches none of it.
	var restage: bool = false

	if config_data.has("stand"):
		var sv: String = str(config_data["stand"]).strip_edges().to_lower()
		var want: String = "chasm" if sv in ["chasm", "crossing", "pit", "tomb"] else "none"
		if want != stand:
			stand = want
			restage = true

	if config_data.has("count"):
		var sc: int = int(config_data["count"])
		if sc >= 1 and sc != stone_count:
			stone_count = sc if sc % 2 == 1 else sc + 1
			restage = true

	if config_data.has("size"):
		var pw: float = _to_float(config_data["size"], pit_width)
		if not is_equal_approx(pw, pit_width):
			pit_width = max(3.0, pw)
			restage = true

	if config_data.has("seed"):
		var cs: int = int(config_data["seed"])
		if cs != crossing_seed:
			crossing_seed = cs
			restage = true

	if config_data.has("cue"):
		var cv: String = str(config_data["cue"]).strip_edges().to_lower()
		advance_seconds = CROSSING_ADVANCE if cv in ["advance", "notice", "countdown"] else 0.0
		if _built:
			_build_crown()

	if config_data.has("cycle_seed"):
		var sd: int = int(config_data["cycle_seed"])
		if sd != cycle_seed:
			cycle_seed = sd
			if cycle_seed != 0:
				_rng.seed = cycle_seed
			restate = true

	if config_data.has("span"):
		wait_span_seconds = _to_float(config_data["span"], wait_span_seconds)
	if config_data.has("random_span"):
		wait_span_seconds = _to_float(config_data["random_span"], wait_span_seconds)
	if config_data.has("wait_min"):
		wait_min_seconds = _to_float(config_data["wait_min"], wait_min_seconds)
	if config_data.has("wait_span"):
		wait_span_seconds = _to_float(config_data["wait_span"], wait_span_seconds)
	if config_data.has("down"):
		sink_duration = _to_float(config_data["down"], sink_duration)
	if config_data.has("up"):
		rise_duration = _to_float(config_data["up"], rise_duration)
	if config_data.has("hide"):
		sink_distance = _to_float(config_data["hide"], sink_distance)

	# Support shorthand syntax: r_c:90:0:1#8 (config key "8" => span 8 seconds)
	for key in config_data.keys():
		var key_text: String = str(key).strip_edges()
		if key_text.is_valid_float():
			wait_span_seconds = float(key_text)
			break

	wait_min_seconds = max(0.1, wait_min_seconds)
	wait_span_seconds = max(wait_min_seconds, wait_span_seconds)
	sink_duration = max(0.01, sink_duration)
	rise_duration = max(0.01, rise_duration)
	disable_collider_delay = max(0.0, disable_collider_delay)
	enable_collider_delay = max(0.0, enable_collider_delay)
	sink_distance = max(0.0, sink_distance)

	if force_upright:
		rotation_degrees = Vector3.ZERO

	# Rebuild the dressing only when an axis actually moved and only once
	# _ready has built something to rebuild. A shipped placement that sends
	# nothing but a span never reaches this.
	if restate and _built:
		_build_warning()
		call_deferred("_anchor_warning")

	if restage and _built:
		if stand == "chasm":
			if _crossing_rng == null:
				_prepare_crossing()
			_teardown_crossing()
		_apply_stand()

	if posture == "cycle":
		# Shipped path, unconditional and unchanged: the timing knobs above have
		# moved, so the loop is restarted exactly as it always was.
		_restart_cycle_loop()
	elif _built:
		# A pinned posture owns the cube. Burn the ticket so any loop still
		# awaiting a timer exits on its next resume instead of stepping on us.
		# If _ready has not run yet there is nothing to pin — _ready reads the
		# export we just set and pins it itself.
		_loop_ticket += 1
		_apply_posture()

func _to_float(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback

# ═════════════════════════════════════════════════════════════════════
# THE CROSSING — stand:chasm: the apron, the stones, the stele, the tablet,
# the rim, the braziers, the idol. Nothing below runs at stand:none.
# ═════════════════════════════════════════════════════════════════════

const CROSSING_ADVANCE: float = 1.2   # seconds of notice, when a cue is asked for
const CH_PROUD: float = 0.22          # how far a standing stone's top rises ABOVE the hall floor
const CH_FLOOR: float = 0.28          # the hall floor, root-local (this tile's top is CH_PROUD over it)
const CH_BED: float = -0.74           # the bed's top, one metre and two centimetres below the floor
const CH_PITCH: float = 1.12          # stone to stone; a 1 m stone leaves a 0.12 m gap
const CH_LAP: float = 0.12            # how far the end stones lap their lips
const CH_STANDS: Vector2 = Vector2(2.4, 4.6)   # the band a stone stands for
const CH_GONE: Vector2 = Vector2(1.1, 2.2)     # and the band it is gone for
const CH_SINK: float = 1.22           # gone: a stone comes to rest on the bed it drops you onto


## What the crossing needs before anything is built: a name a visitor can read
## and repeat. The seed is five digits so it can be said out loud; every stone's
## own cycle_seed is drawn from it, so one number replays the whole rhythm.
func _prepare_crossing() -> void:
	# The museum places a body's origin ON the deck (measured 2026-09-12: the token's
	# own y offset is not read in the map-authored lane), which would leave this cube
	# standing half proud of the floor and the whole crossing half a metre in the air.
	# So the staging takes the height itself. It does not take the whole half metre:
	# a row flush with the floor is invisible from a standing eye — the pit's own near
	# wall occludes it and a top face at eye-grazing angle has no thickness (measured,
	# third live capture) — so the stones stand CH_PROUD over it, as stepping stones,
	# with a threshold at each lip so the step onto them is never a wall.
	position.y -= (0.5 - CH_PROUD)
	_base_position = position
	if crossing_seed < 0:
		var namer := RandomNumberGenerator.new()
		namer.randomize()
		crossing_seed = namer.randi_range(10000, 99999)
	_crossing_rng = RandomNumberGenerator.new()
	_crossing_rng.seed = crossing_seed
	_adopt_crossing_timing(self)
	cycle_seed = _crossing_rng.randi_range(1, 1 << 30)
	_rng.seed = cycle_seed


## The timing a crossing needs: a stone stands longer than it is gone, or the
## rhythm is a coin toss with a one-metre penalty. Shipped bands are untouched
## at stand:none — this is only ever called by the staging.
func _adopt_crossing_timing(stone: Node) -> void:
	stone.set("wait_min_seconds", CH_STANDS.x)
	stone.set("wait_span_seconds", CH_STANDS.y)
	stone.set("hidden_min_seconds", CH_GONE.x)
	stone.set("hidden_span_seconds", CH_GONE.y)
	stone.set("advance_seconds", advance_seconds)
	stone.set("sink_distance", CH_SINK)


func _apply_stand() -> void:
	if stand == "chasm":
		if _crossing == null:
			_build_crossing()
		_build_crown()
		_update_tablet()
	else:
		_teardown_crossing()
	set_process(_crossing != null or _crown != null)


func _teardown_crossing() -> void:
	for s in _stones:
		if is_instance_valid(s):
			(s as Node).get_parent().remove_child(s)
			(s as Node).queue_free()
	_stones.clear()
	if _crossing != null and is_instance_valid(_crossing):
		remove_child(_crossing)
		_crossing.queue_free()
	_crossing = null
	_tablet = null
	_seed_cut = null
	_idol_material = null


## Half the pit, across and along, derived so the row and the hole agree: the
## stones lap each lip by CH_LAP, and the width is the room's to set (`size`).
func _pit_half() -> Vector2:
	var along: float = float(stone_count - 1) * CH_PITCH * 0.5 + 0.5 - CH_LAP
	return Vector2(max(1.5, pit_width * 0.5), along)


## What the museum leaves out. Sandstone the colour of a dry riverbed: the bed a
## metre down, the ramp back out of it, the cut sides, and kerbs at both lips
## broken where the stones cross — a gate, not a fence.
func _build_crossing() -> void:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var pit: Vector2 = _pit_half()
	_crossing = Node3D.new()
	_crossing.name = "Crossing"
	_crossing_base_y = 0.0
	add_child(_crossing)

	var stone_mat: StandardMaterial3D = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.55, 0.47, 0.36)
	stone_mat.roughness = 0.95
	var dark_mat: StandardMaterial3D = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.13, 0.12, 0.11)
	dark_mat.roughness = 0.9
	var sand_mat: StandardMaterial3D = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.40, 0.35, 0.27)
	sand_mat.roughness = 1.0

	# the bed: the only floor under the stones, and the whole of what a fall costs
	var bed_size := Vector3(pit.x * 2.0, 0.08, pit.y * 2.0)
	var bed_at := Vector3(0.0, CH_BED - 0.04, 0.0)
	var bed: MeshInstance3D = HangarKit.box(bed_at, bed_size, sand_mat)
	bed.name = "Bed"
	_crossing.add_child(bed)
	var bed_col: StaticBody3D = HangarKit.box_collider(bed_size, bed_at)
	bed_col.name = "BedCollider"
	_crossing.add_child(bed_col)

	# the cut sides. West and east run the pit's whole length; the near and far ones
	# are in two pieces, broken for the width the row needs — with those ends left
	# open a standing eye looked straight through the pit and out under the hall's
	# own floor, at the museum's sky (measured 2026-09-12, the first run's captures).
	var cut_h: float = CH_FLOOR - CH_BED
	for s in [-1.0, 1.0]:
		var wall_at := Vector3(s * (pit.x - 0.07), (CH_BED + CH_FLOOR) * 0.5, 0.0)
		var wall_size := Vector3(0.14, cut_h, pit.y * 2.0)
		var w: MeshInstance3D = HangarKit.box(wall_at, wall_size, stone_mat)
		w.name = "Side_%s" % ("west" if s < 0.0 else "east")
		_crossing.add_child(w)
		var wc: StaticBody3D = HangarKit.box_collider(wall_size, wall_at)
		wc.name = "%sCollider" % w.name
		_crossing.add_child(wc)
	# The near and far walls run the FULL width, their tops four centimetres under the
	# hall's floor: a gate left open for the row let a standing eye look straight
	# through both ends and out under the floor at the sky (two runs, 12 September).
	# The end stones lap these walls by CH_LAP with that clearance, which is also the
	# step a body takes from the floor onto the first stone.
	for s in [-1.0, 1.0]:
		var end_at := Vector3(0.0, (CH_BED + CH_FLOOR - 0.04) * 0.5, s * (pit.y - 0.07))
		var end_size := Vector3(pit.x * 2.0, cut_h - 0.04, 0.14)
		var e: MeshInstance3D = HangarKit.box(end_at, end_size, stone_mat)
		e.name = "End_%s" % ("near" if s < 0.0 else "far")
		_crossing.add_child(e)
		var ec: StaticBody3D = HangarKit.box_collider(end_size, end_at)
		ec.name = "%sCollider" % e.name
		_crossing.add_child(ec)

	# the way out: a ramp up the pit's west third, from the bed to the near lip
	_crossing.add_child(_ramp(Vector3(-pit.x * 0.66, CH_BED, pit.y - 0.4),
			Vector3(-pit.x * 0.66, CH_FLOOR, -pit.y - 0.2), 1.0, sand_mat, "WayOut"))

	# a worn threshold at each lip, so the step up onto the row is a slope and not a
	# wall for any body the engine will not lift
	for s in [-1.0, 1.0]:
		_crossing.add_child(_ramp(Vector3(0.0, CH_FLOOR, s * (pit.y + 0.34)),
				Vector3(0.0, CH_FLOOR + CH_PROUD, s * (pit.y - 0.04)), 1.0, stone_mat,
				"Threshold_%s" % ("near" if s < 0.0 else "far")))

	# kerbs on both lips, broken for the width of the row: a gate, not a fence
	for s in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			var run: float = (pit.x - 0.72) * 0.5
			var k: MeshInstance3D = HangarKit.box(
					Vector3(side * (0.72 + run), CH_FLOOR + 0.06, s * (pit.y + 0.09)),
					Vector3(run * 2.0, 0.12, 0.18), stone_mat)
			k.name = "Kerb_%s_%s" % [("n" if s < 0.0 else "s"), ("w" if side < 0.0 else "e")]
			_crossing.add_child(k)

	_build_stele(HangarKit, pit, stone_mat, dark_mat)
	_build_tablet(HangarKit, pit, dark_mat)
	_build_controls(pit)
	_build_idol(HangarKit, pit, stone_mat, dark_mat)
	for bz in [Vector3(-(pit.x - 0.30), CH_FLOOR, -pit.y - 0.78), Vector3(pit.x - 0.30, CH_FLOOR, pit.y + 0.78)]:
		_build_brazier(HangarKit, bz, dark_mat)
	_spawn_stones()


## A walkable slab from a to b, both points on its top surface, with a collider
## that matches. Godot's looking_at does the aiming, so a ramp is one call.
func _ramp(a: Vector3, b: Vector3, width: float, mat: Material, node_name: String) -> Node3D:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = (a + b) * 0.5
	holder.basis = Basis.looking_at(b - a, Vector3.UP)
	var run: float = (b - a).length()
	var size := Vector3(width, 0.14, run)
	holder.add_child(HangarKit.box(Vector3(0.0, -0.07, 0.0), size, mat))
	var col: StaticBody3D = HangarKit.box_collider(size, Vector3(0.0, -0.07, 0.0))
	holder.add_child(col)
	return holder


## THE ORDER, cut in stone on the watch ledge: four steps, fixed, public, and
## true of every stone in the row. Nothing here is drawn.
func _build_stele(HangarKit, pit: Vector2, stone_mat: Material, dark_mat: Material) -> void:
	var stele := Node3D.new()
	stele.name = "Stele"
	stele.position = Vector3(2.02, CH_FLOOR, -pit.y - 0.86)
	stele.rotation_degrees = Vector3(0, 122, 0)
	stele.set_meta("em_local_instrument", true)
	_crossing.add_child(stele)
	var slab: MeshInstance3D = HangarKit.box(Vector3(0, 0.66, 0), Vector3(1.16, 1.32, 0.13), stone_mat)
	slab.name = "Slab"
	stele.add_child(slab)
	var head: MeshInstance3D = HangarKit.stencil("THE ORDER IS CUT IN STONE", Vector2(0.90, 0.052), Color(0.16, 0.14, 0.12))
	if head:
		head.position = Vector3(0, 1.18, 0.068)
		stele.add_child(head)
	var steps := ["I   IT STANDS", "II  IT LEAVES", "III IT IS GONE", "IV  IT RETURNS"]
	for i in range(steps.size()):
		var line: MeshInstance3D = HangarKit.stencil(steps[i], Vector2(0.80, 0.080), Color(0.17, 0.15, 0.13))
		if line:
			line.position = Vector3(0, 0.99 - 0.175 * float(i), 0.068)
			stele.add_child(line)
	var foot: MeshInstance3D = HangarKit.stencil("ONLY THE WAITS ARE DRAWN", Vector2(0.86, 0.048), Color(0.21, 0.17, 0.14))
	if foot:
		foot.position = Vector3(0, 0.22, 0.068)
		stele.add_child(foot)


## THE DRAWN WAITS, live, on a lectern at the chasm's lip: a visitor standing on
## the ledge reads the tablet with the stones themselves right behind it.
func _build_tablet(HangarKit, pit: Vector2, dark_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "Tablet"
	root.position = Vector3(-1.38, CH_FLOOR + 0.94, -pit.y - 0.34)
	root.rotation_degrees = Vector3(-20, 155, 0)
	root.set_meta("em_local_instrument", true)
	_crossing.add_child(root)
	var plate: MeshInstance3D = HangarKit.box(Vector3.ZERO, Vector3(0.84, 0.40, 0.016), dark_mat)
	plate.name = "Plate"
	root.add_child(plate)
	var cap: MeshInstance3D = HangarKit.stencil("DRAWN, THIS CYCLE", Vector2(0.44, 0.030), Color(0.92, 0.74, 0.42))
	if cap:
		cap.position = Vector3(-0.18, 0.163, 0.012)
		root.add_child(cap)
	_tablet = Label3D.new()
	_tablet.name = "Text"
	_tablet.pixel_size = 0.0011
	_tablet.font_size = 20
	_tablet.line_spacing = 0.6
	_tablet.modulate = Color(0.88, 0.95, 1.0)
	_tablet.outline_size = 4
	_tablet.outline_modulate = Color(0, 0, 0, 1)
	_tablet.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tablet.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_tablet.position = Vector3(-0.395, 0.128, 0.011)
	root.add_child(_tablet)


## REPLAY the same rhythm, draw a NEW one, or change what the stones tell you
## before they go. On the watch ledge, where the planning happens.
func _build_controls(pit: Vector2) -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	var panel: Node3D = RackTpl.create_panel("", [
		[{"type": "button", "label": "REPLAY"}, {"type": "button", "label": "NEW SEED"}],
		[{"type": "button", "label": "CUE"}],
	], true)
	panel.name = "Controls"
	panel.set_meta("em_local_instrument", true)
	panel.position = Vector3(1.24, CH_FLOOR + 0.86, -pit.y - 0.50)
	panel.rotation_degrees = Vector3(-34, 180, 0)
	panel.scale = Vector3(1.5, 1.5, 1.5)
	_crossing.add_child(panel)
	var actions := {"Btn_0": func(): replay_crossing(), "Btn_1": func(): new_crossing(), "Btn_2": func(): toggle_cue()}
	for btn_name in actions.keys():
		var btn: Node = panel.find_child(btn_name, true, false)
		if btn == null:
			continue
		var area: Node = btn.get_node_or_null("InteractableAreaButton")
		if area != null and area.has_signal("button_pressed"):
			var action: Callable = actions[btn_name]
			area.button_pressed.connect(func(_b): action.call())


## The reason to cross: a plinth on the far platform with a lit form on it, and
## the crossing's five-digit name cut into the face that looks back at the row.
## What you carry out of a trap room is the ability to run it again.
func _build_idol(HangarKit, pit: Vector2, stone_mat: Material, dark_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "Idol"
	root.position = Vector3(0.0, CH_FLOOR, pit.y + 0.72)
	_crossing.add_child(root)
	var plinth: MeshInstance3D = HangarKit.box(Vector3(0, 0.40, 0), Vector3(0.54, 0.80, 0.54), stone_mat)
	plinth.name = "Plinth"
	root.add_child(plinth)
	_idol_material = HangarKit.emissive(Color(1.0, 0.78, 0.30), 2.2)
	var form := MeshInstance3D.new()
	form.name = "Form"
	var prism := PrismMesh.new()
	prism.size = Vector3(0.26, 0.34, 0.26)
	form.mesh = prism
	form.material_override = _idol_material
	form.position = Vector3(0, 0.98, 0)
	root.add_child(form)
	var glow := OmniLight3D.new()
	glow.name = "IdolLight"
	glow.light_color = Color(1.0, 0.82, 0.45)
	glow.light_energy = 1.5
	glow.omni_range = 4.0
	glow.shadow_enabled = false
	glow.position = Vector3(0, 1.10, 0)
	root.add_child(glow)
	var cut := Node3D.new()
	cut.name = "SeedCut"
	cut.position = Vector3(0.0, 0.52, -0.28)
	cut.rotation_degrees = Vector3(0, 180, 0)
	root.add_child(cut)
	_seed_cut = Label3D.new()
	_seed_cut.name = "Text"
	_seed_cut.pixel_size = 0.0014
	_seed_cut.font_size = 30
	_seed_cut.modulate = Color(0.96, 0.86, 0.62)
	_seed_cut.outline_size = 5
	_seed_cut.outline_modulate = Color(0.10, 0.08, 0.06, 1)
	_seed_cut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cut.add_child(_seed_cut)


func _build_brazier(HangarKit, at: Vector3, dark_mat: Material) -> void:
	var root := Node3D.new()
	root.name = "Brazier_%d" % _crossing.get_children().filter(func(c): return str(c.name).begins_with("Brazier")).size()
	root.position = at
	_crossing.add_child(root)
	var stem := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.10
	cyl.height = 0.86
	stem.mesh = cyl
	stem.material_override = dark_mat
	stem.position = Vector3(0, 0.43, 0)
	root.add_child(stem)
	var coals := MeshInstance3D.new()
	coals.name = "Coals"
	var bowl := SphereMesh.new()
	bowl.radius = 0.15
	bowl.height = 0.18
	coals.mesh = bowl
	coals.material_override = HangarKit.emissive(Color(1.0, 0.42, 0.12), 1.1)
	coals.position = Vector3(0, 0.90, 0)
	root.add_child(coals)
	var fire := OmniLight3D.new()
	fire.name = "Fire"
	fire.light_color = Color(1.0, 0.66, 0.34)
	fire.light_energy = 2.2
	fire.omni_range = 7.5
	fire.shadow_enabled = false
	fire.position = Vector3(0, 1.02, 0)
	root.add_child(fire)


## The other stones: this cube's own siblings, one scene each, every one of them
## seeded from the crossing's number so the row is a rhythm and not a mess. They
## are handed the crossing's bands before they enter the tree, so their own
## _ready reads them; their `stand` stays none, so none of them stages anything.
func _spawn_stones() -> void:
	_stones.clear()
	var scene: PackedScene = load("res://commons/primitives/cubes/random_cycle_cube.tscn")
	var half: int = int((stone_count - 1) / 2)
	for i in range(-half, half + 1):
		# near lip to far, this cube taking its place in the row at local z 0. It is
		# appended in order rather than sorted: its own position is the hall's,
		# while the siblings' are the crossing's, and the two do not compare.
		if i == 0:
			_stones.append(self)
			continue
		if scene == null:
			continue
		var stone: Node3D = scene.instantiate()
		stone.name = "Stone_%d" % (i + half)
		_adopt_crossing_timing(stone)
		stone.set("cycle_seed", _crossing_rng.randi_range(1, 1 << 30))
		stone.set("warning", "none")
		stone.position = Vector3(0.0, 0.0, CH_PITCH * float(i))
		_crossing.add_child(stone)
		_stones.append(stone)


## A crown ring, built only when a cue was asked for: lit while the stone still
## stands and the stored deadline is inside the notice window. The beacon says
## "I am leaving" as it leaves; this says "I am about to".
func _build_crown() -> void:
	if _crown != null and is_instance_valid(_crown):
		_crown.get_parent().remove_child(_crown)
		_crown.queue_free()
		_crown = null
		_crown_material = null
	if advance_seconds <= 0.0:
		set_process(_crossing != null)
		return
	set_process(true)
	_crown_material = StandardMaterial3D.new()
	_crown_material.albedo_color = Color(1.0, 0.86, 0.32, 0.95)
	_crown_material.emission_enabled = true
	_crown_material.emission = Color(1.0, 0.80, 0.26)
	_crown_material.emission_energy_multiplier = 3.2
	_crown_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_crown = MeshInstance3D.new()
	_crown.name = "Crown"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.40
	ring.outer_radius = 0.50
	ring.rings = 20
	ring.ring_segments = 8
	_crown.mesh = ring
	_crown.material_override = _crown_material
	_crown.position = Vector3(0, 0.54, 0)
	_crown.visible = false
	add_child(_crown)


## Two things a staged cube owes the room every frame: the apron must not sink
## when this stone does (it is the stone's child, so the sink is cancelled out of
## the staging's own offset), and the crown must answer the stored deadline.
func _process(_delta: float) -> void:
	if _crown != null and is_instance_valid(_crown):
		var left: float = float(_step_until_ms - Time.get_ticks_msec()) / 1000.0
		_crown.visible = advance_seconds > 0.0 and _step_kind == "stands" and left <= advance_seconds and left > -0.05
	if _crossing == null or not is_instance_valid(_crossing):
		return
	_crossing.position.y = _crossing_base_y - (position.y - _base_position.y)
	_tablet_due -= _delta
	if _tablet_due <= 0.0:
		_tablet_due = 0.12
		_update_tablet()


## The tablet: one line per stone, west to east — which step it is in, the wait
## that was DRAWN for this one, and how much of it is left. The bar is the same
## number twice: what the draw gave, and what the clock has taken from it.
func _update_tablet() -> void:
	if _tablet == null or not is_instance_valid(_tablet):
		return
	var lines: PackedStringArray = PackedStringArray()
	for i in range(_stones.size()):
		var st: Node = _stones[i]
		if not is_instance_valid(st):
			continue
		var s: Dictionary = st.call("step_state")
		var bars: int = 0
		if float(s["wait"]) > 0.0:
			bars = int(round(8.0 * clampf(float(s["left"]) / float(s["wait"]), 0.0, 1.0)))
		var mark: String = "|".repeat(bars) + ".".repeat(8 - bars)
		lines.append("%d  %-6s drawn %4.1f s  left %4.1f  %s%s" % [
			i + 1, ("STANDS" if str(s["step"]) == "stands" else "GONE"),
			float(s["wait"]), float(s["left"]), mark,
			"  <" if bool(s["crown"]) else "",
		])
	lines.append("seed %d · cue %s" % [crossing_seed, ("advance %.1f s" % advance_seconds) if advance_seconds > 0.0 else "beacon only"])
	_tablet.text = "\n".join(lines)
	if _seed_cut != null and is_instance_valid(_seed_cut):
		_seed_cut.text = "SEED\n%d" % crossing_seed


## The same rhythm again: every stone re-seeded from the crossing's number in the
## order it was dealt, every loop restarted. A crossing you can practise.
func replay_crossing() -> void:
	if stand != "chasm":
		return
	_crossing_rng = RandomNumberGenerator.new()
	_crossing_rng.seed = crossing_seed
	cycle_seed = _crossing_rng.randi_range(1, 1 << 30)
	_rng.seed = cycle_seed
	_cycles_done = 0
	_restart_cycle_loop()
	for s in _stones:
		if s == self or not is_instance_valid(s):
			continue
		s.set("cycle_seed", _crossing_rng.randi_range(1, 1 << 30))
		s.call("restart_from_seed")
	_update_tablet()


## Another rhythm, named: a new five-digit seed, the same room.
func new_crossing() -> void:
	if stand != "chasm":
		return
	var namer := RandomNumberGenerator.new()
	namer.randomize()
	crossing_seed = namer.randi_range(10000, 99999)
	replay_crossing()


## What the stones tell you before they go: the shipped beacon, or a crown timed
## from the stored deadline. Both, always, on every stone at once.
func toggle_cue() -> void:
	advance_seconds = 0.0 if advance_seconds > 0.0 else CROSSING_ADVANCE
	_build_crown()
	for s in _stones:
		if s == self or not is_instance_valid(s):
			continue
		s.set("advance_seconds", advance_seconds)
		s.call("_build_crown")
	_update_tablet()


## Re-seed and restart, for a stone the crossing owns.
func restart_from_seed() -> void:
	_rng.seed = cycle_seed
	_cycles_done = 0
	_restart_cycle_loop()


## The whole crossing as the room can read it: the seed, the cue, the geometry a
## body has to trust, and every stone's drawn wait and stored deadline.
func crossing_state() -> Dictionary:
	var pit: Vector2 = _pit_half()
	var stones: Array = []
	for i in range(_stones.size()):
		var st: Node = _stones[i]
		if not is_instance_valid(st):
			continue
		var s: Dictionary = st.call("step_state")
		s["z"] = 0.0 if st == self else snappedf((st as Node3D).position.z, 0.01)
		s["seed"] = int(st.get("cycle_seed"))
		stones.append(s)
	return {
		"seed": crossing_seed,
		"cue": "advance" if advance_seconds > 0.0 else "beacon",
		"advance_seconds": advance_seconds,
		"stones": stones,
		"stands_band": [CH_STANDS.x, CH_STANDS.y],
		"gone_band": [CH_GONE.x, CH_GONE.y],
		"geometry": {
			"floor": CH_FLOOR, "bed": CH_BED, "drop": snappedf(CH_FLOOR - CH_BED, 0.01), "proud": CH_PROUD,
			"pitch": CH_PITCH, "gap": snappedf(CH_PITCH - 1.0, 0.01), "lap": CH_LAP,
			"pit_across": snappedf(pit.x * 2.0, 0.01), "pit_along": snappedf(pit.y * 2.0, 0.01),
			"sink": CH_SINK, "stone_count": stone_count,
		},
	}
