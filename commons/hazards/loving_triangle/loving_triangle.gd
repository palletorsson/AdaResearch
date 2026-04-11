# @identity
# essence: triangle.respond(catalyst_mode) -> fold, tile, dance -- atom of 3D worlds responding to its tool
# desire: a triangle that folds and tiles in response to the Becoming Catalyst, dancing with its partner
# critical_parameter: catalyst mode / response type -- each curriculum stage evokes different triangle behavior
# triggers: proximity to becoming_catalyst; mode-dependent responses; folding, tiling, dance behaviors
# emerges: the simplest polygon becomes expressive through relational context -- same triangle, different dance
# needs: CharacterBody3D [has]; catalyst response system [has]; fold/tile behaviors [has]; VR interaction [missing]
# relationships: companion to becoming_catalyst (atom + tool pair); triangle is the irreducible geometric unit
# truth: three vertices, three edges, infinite possibility when given a relational partner.

# LovingTriangle.gd
# The Loving Triangle — a companion entity that dances with the
# Becoming Catalyst.  Triangles are the atom of all 3D worlds.
# This entity makes that visible.
#
# Not an enemy.  Not destructible.  Companion Cube energy:
# no dialogue, no text.  The bond forms through geometric response
# alone — presence and care expressed through folding and unfolding.
#
# State machine: DORMANT -> AWARE -> CURIOUS -> DANCING ->
#                RESONATING / HARMONIZED -> RESTING -> loop
#
# Evolution follows the folding journey:
#   flat -> folded -> colored -> breathing -> self-tiling -> space-filling
extends CharacterBody3D

# ── State Enum ───────────────────────────────────────────────────────────
enum State {
	DORMANT,     # Barely visible ghost.  The base unit, waiting.
	AWARE,       # Player detected.  Turns to face.  Glow increase.
	CURIOUS,     # Orbits player.  Sine-wave hover bob.
	DANCING,     # Responding to projectile hits.  Core gameplay loop.
	RESONATING,  # Extended response — same mode 3+ times.
	HARMONIZED,  # Rare reward — 3+ different modes quickly.
	RESTING,     # Post-interaction calm.  Folds down.
}

# ── Configuration ────────────────────────────────────────────────────────
const AWARENESS_RADIUS := 12.0
const ORBIT_RADIUS := 3.5
const ORBIT_SPEED := 0.8
const HOVER_HEIGHT := 1.5
const APPROACH_SPEED := 1.2

const AWARE_HOLD_TIME := 2.0
const DANCE_TIMEOUT := 8.0
const RESONANCE_DURATION := 3.0
const HARMONY_DURATION := 5.0
const REST_DURATION := 6.0
const FAR_RADIUS := 25.0

const RESONANCE_THRESHOLD := 3
const HARMONY_MODE_COUNT := 3
const HARMONY_TIME_WINDOW := 4.0

# ── Signals ──────────────────────────────────────────────────────────────
signal state_changed(new_state: int)
signal mode_response(mode_id: String)
signal tier_changed(new_tier: int)
signal harmonized()

# ── State ────────────────────────────────────────────────────────────────
var _state: int = State.DORMANT
var _state_time: float = 0.0
var _hover_time: float = 0.0
var _orbit_angle: float = 0.0

var _player_node: Node3D = null

var _current_tier: int = 0
var _completed_sequences: Array[String] = []
var _color_history: Array[Color] = []

# Hit tracking
var _recent_hits: Array[Dictionary] = []
var _consecutive_mode: String = ""
var _consecutive_count: int = 0

# Physics
var _collision_shape: CollisionShape3D = null
var _projectile_detector: Area3D = null

# ── Constants ────────────────────────────────────────────────────────────
const SAVE_PATH := "user://loving_triangle.save"


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_collision()
	_build_projectile_detector()
	_find_player()
	_load_state()
	_connect_progression_signals()
	_rebuild_visual()

	add_to_group("companion")
	add_to_group("loving_triangle")

	print("[LovingTriangle] Ready — tier %d" % _current_tier)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_hover_time += delta

	if not is_instance_valid(_player_node):
		_find_player()

	_prune_old_hits()

	match _state:
		State.DORMANT:    _process_dormant(delta)
		State.AWARE:      _process_aware(delta)
		State.CURIOUS:    _process_curious(delta)
		State.DANCING:    _process_dancing(delta)
		State.RESONATING: _process_resonating(delta)
		State.HARMONIZED: _process_harmonized(delta)
		State.RESTING:    _process_resting(delta)

	_apply_hover(delta)
	move_and_slide()


# ═════════════════════════════════════════════════════════════════════════
# STATE PROCESSORS
# ═════════════════════════════════════════════════════════════════════════

func _process_dormant(delta: float) -> void:
	# Gentle rotation
	rotation.y += delta * 0.2
	velocity = Vector3.ZERO

	var dist := _get_distance_to_player()
	if dist < AWARENESS_RADIUS:
		_set_state(State.AWARE)


func _process_aware(delta: float) -> void:
	velocity = Vector3.ZERO
	_face_player(delta)

	# Increase glow slightly each frame (visual root scale breathe)
	var visual := _get_visual_root()
	if visual:
		var breathe := 1.0 + sin(_state_time * 2.0) * 0.03
		visual.scale = Vector3.ONE * breathe

	var dist := _get_distance_to_player()
	if dist > AWARENESS_RADIUS * 1.2:
		_set_state(State.DORMANT)
	elif _state_time >= AWARE_HOLD_TIME:
		_set_state(State.CURIOUS)


func _process_curious(delta: float) -> void:
	if not is_instance_valid(_player_node):
		_set_state(State.DORMANT)
		return

	# Orbit player
	_orbit_angle += ORBIT_SPEED * delta
	var target_pos := _player_node.global_position
	target_pos.y += HOVER_HEIGHT
	var orbit_offset := Vector3(
		cos(_orbit_angle) * ORBIT_RADIUS,
		sin(_hover_time * 1.5) * 0.15,
		sin(_orbit_angle) * ORBIT_RADIUS
	)
	var desired := target_pos + orbit_offset
	var move_dir := (desired - global_position)
	if move_dir.length() > 0.05:
		velocity = move_dir.normalized() * APPROACH_SPEED * minf(move_dir.length(), 3.0)
	else:
		velocity = Vector3.ZERO

	_face_player(delta)

	var dist := _get_distance_to_player()
	if dist > FAR_RADIUS:
		_set_state(State.DORMANT)


func _process_dancing(delta: float) -> void:
	if not is_instance_valid(_player_node):
		_set_state(State.RESTING)
		return

	# Tighter, faster orbit
	_orbit_angle += ORBIT_SPEED * 1.4 * delta
	var target_pos := _player_node.global_position
	target_pos.y += HOVER_HEIGHT
	var tight_radius := ORBIT_RADIUS * 0.6
	var orbit_offset := Vector3(
		cos(_orbit_angle) * tight_radius,
		sin(_hover_time * 2.0) * 0.2,
		sin(_orbit_angle) * tight_radius
	)
	var desired := target_pos + orbit_offset
	var move_dir := desired - global_position
	if move_dir.length() > 0.05:
		velocity = move_dir.normalized() * APPROACH_SPEED * 1.5 * minf(move_dir.length(), 3.0)
	else:
		velocity = Vector3.ZERO

	_face_player(delta)

	# Timeout → resting
	if _state_time >= DANCE_TIMEOUT:
		_set_state(State.RESTING)


func _process_resonating(_delta: float) -> void:
	# Slow spin, elevated
	rotation.y += _delta * 0.5
	velocity.y = lerpf(velocity.y, 0.0, 0.1)
	velocity.x = move_toward(velocity.x, 0.0, _delta * 2.0)
	velocity.z = move_toward(velocity.z, 0.0, _delta * 2.0)

	if _state_time >= RESONANCE_DURATION:
		_set_state(State.DANCING)


func _process_harmonized(_delta: float) -> void:
	# Slow multi-axis rotation, fully elevated
	rotation.y += _delta * 0.3
	rotation.x += _delta * 0.2
	velocity = Vector3.ZERO

	# Scale pulse
	var visual := _get_visual_root()
	if visual:
		var pulse := 1.0 + sin(_state_time * 3.0) * 0.08
		visual.scale = Vector3.ONE * pulse

	if _state_time >= HARMONY_DURATION:
		_set_state(State.RESTING)
		if visual:
			visual.scale = Vector3.ONE
		rotation.x = 0.0


func _process_resting(delta: float) -> void:
	# Drift away gently
	if is_instance_valid(_player_node):
		var away := (global_position - _player_node.global_position)
		away.y = 0.0
		if away.length() > 0.1 and away.length() < ORBIT_RADIUS * 1.3:
			velocity = away.normalized() * 0.4
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta)
			velocity.z = move_toward(velocity.z, 0.0, delta)
	else:
		velocity = Vector3.ZERO

	if _state_time >= REST_DURATION:
		var dist := _get_distance_to_player()
		if dist < AWARENESS_RADIUS:
			_set_state(State.CURIOUS)
		else:
			_set_state(State.DORMANT)


# ═════════════════════════════════════════════════════════════════════════
# HOVER
# ═════════════════════════════════════════════════════════════════════════

func _apply_hover(_delta: float) -> void:
	var hover := sin(_hover_time * 1.2) * 0.06
	velocity.y += hover


# ═════════════════════════════════════════════════════════════════════════
# PROJECTILE DETECTION
# ═════════════════════════════════════════════════════════════════════════

func _on_projectile_entered(body: Node3D) -> void:
	# Check if it's a catalyst projectile
	if not body is RigidBody3D:
		return
	var script: Script = body.get_script() as Script
	if script == null:
		return
	# Must be a CatalystProjectile or subclass
	if (not "CatalystProjectile" in script.resource_path
			and not "catalyst_projectile" in script.resource_path.to_lower()):
		# Check by class chain: the base class resource_path
		var base: Script = script.get_base_script()
		if base == null or not "catalyst_projectile" in base.resource_path.to_lower():
			return

	var mode_id := _identify_mode(body)
	if mode_id.is_empty():
		return

	var hit_pos := body.global_position
	_record_hit(mode_id)

	# Apply response
	var TriResp = load("res://commons/hazards/loving_triangle/triangle_responses.gd")
	TriResp.respond(self, mode_id, hit_pos)
	mode_response.emit(mode_id)

	# State transitions
	if _state == State.CURIOUS or _state == State.RESTING or _state == State.AWARE:
		_set_state(State.DANCING)
	elif _state == State.DANCING:
		_check_resonance_or_harmony()

	_state_time = 0.0


func _identify_mode(projectile: Node3D) -> String:
	var TriResp = load("res://commons/hazards/loving_triangle/triangle_responses.gd")
	return TriResp.identify_mode(projectile)


# ═════════════════════════════════════════════════════════════════════════
# HIT TRACKING (RESONANCE / HARMONY)
# ═════════════════════════════════════════════════════════════════════════

func _record_hit(mode_id: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_recent_hits.append({"mode_id": mode_id, "time": now})

	if mode_id == _consecutive_mode:
		_consecutive_count += 1
	else:
		_consecutive_mode = mode_id
		_consecutive_count = 1


func _check_resonance_or_harmony() -> void:
	# Resonance: same mode N times
	if _consecutive_count >= RESONANCE_THRESHOLD:
		_set_state(State.RESONATING)
		_consecutive_count = 0
		return

	# Harmony: N different modes in time window
	var now := Time.get_ticks_msec() / 1000.0
	var recent_modes: Array[String] = []
	for hit in _recent_hits:
		if now - hit["time"] <= HARMONY_TIME_WINDOW:
			if not hit["mode_id"] in recent_modes:
				recent_modes.append(hit["mode_id"])

	if recent_modes.size() >= HARMONY_MODE_COUNT:
		_set_state(State.HARMONIZED)
		harmonized.emit()
		_recent_hits.clear()


func _prune_old_hits() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var cutoff := now - HARMONY_TIME_WINDOW * 2.0
	var new_hits: Array[Dictionary] = []
	for hit in _recent_hits:
		if hit["time"] >= cutoff:
			new_hits.append(hit)
	_recent_hits = new_hits


# ═════════════════════════════════════════════════════════════════════════
# CHROMATIC COLOR ACCUMULATION
# ═════════════════════════════════════════════════════════════════════════

func _add_color(color: Color) -> void:
	_color_history.append(color)
	if _color_history.size() > 12:
		_color_history = _color_history.slice(-12)
	# Rebuild visual to show new colors if at tier 2+
	if _current_tier >= 2:
		_rebuild_visual()
	_save_state()


# ═════════════════════════════════════════════════════════════════════════
# PROGRESSION
# ═════════════════════════════════════════════════════════════════════════

func _find_lab_manager() -> Node:
	var mgr := get_node_or_null("/root/LabManager")
	if mgr:
		return mgr
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("lab_manager"):
			return node
	return null


func _connect_progression_signals() -> void:
	var lab_mgr := _find_lab_manager()
	if lab_mgr and lab_mgr.has_method("is_sequence_completed"):
		var all_seqs := _get_all_tier_sequences()
		for seq in all_seqs:
			if lab_mgr.is_sequence_completed(seq):
				_mark_sequence_completed(seq, false)

	var scene_mgr := get_node_or_null("/root/AdaSceneManager")
	if scene_mgr and scene_mgr.has_signal("sequence_completed"):
		if not scene_mgr.sequence_completed.is_connected(_on_sequence_completed):
			scene_mgr.sequence_completed.connect(_on_sequence_completed)

	var map_prog := get_node_or_null("/root/MapProgressionManager")
	if map_prog and map_prog.has_signal("sequence_completed"):
		if not map_prog.sequence_completed.is_connected(_on_map_sequence_completed):
			map_prog.sequence_completed.connect(_on_map_sequence_completed)


func _on_sequence_completed(sequence_name: String, _data: Dictionary) -> void:
	_mark_sequence_completed(sequence_name, true)

func _on_map_sequence_completed(sequence_name: String) -> void:
	_mark_sequence_completed(sequence_name, true)

func _mark_sequence_completed(sequence_name: String, notify: bool) -> void:
	if sequence_name in _completed_sequences:
		return
	_completed_sequences.append(sequence_name)
	var TriVis = load("res://commons/hazards/loving_triangle/triangle_visual.gd")
	var new_tier: int = TriVis.get_tier_from_sequences(_completed_sequences)
	if new_tier > _current_tier:
		_current_tier = new_tier
		_rebuild_visual()
		_save_state()
		if notify:
			tier_changed.emit(_current_tier)
			print("[LovingTriangle] Evolved to tier %d" % _current_tier)


func _get_all_tier_sequences() -> Array[String]:
	var result: Array[String] = []
	var TriVis = load("res://commons/hazards/loving_triangle/triangle_visual.gd")
	for tier_seqs in TriVis.TIER_SEQUENCES:
		for seq in tier_seqs:
			if not seq in result:
				result.append(seq)
	return result


# ═════════════════════════════════════════════════════════════════════════
# VISUAL
# ═════════════════════════════════════════════════════════════════════════

func _rebuild_visual() -> void:
	var TriVis = load("res://commons/hazards/loving_triangle/triangle_visual.gd")
	# Collect completed mode IDs from sequences
	var completed_modes: Array[String] = []
	# Map sequences to mode IDs
	var seq_to_mode := {
		"primitives": "primitives",
		"transformation": "transformation",
		"color": "chromatic",
		"forces": "forces",
		"wavefunctions": "waveform",
		"randomness": "chaos",
		"fractals": "fractal",
		"cellularautomata": "cellular",
		"lsystems": "branching",
		"swarmintelligence": "swarm",
	}
	for seq in _completed_sequences:
		if seq_to_mode.has(seq):
			completed_modes.append(seq_to_mode[seq])
	TriVis.build(self, _current_tier, completed_modes)


func _get_visual_root() -> Node3D:
	for child in get_children():
		if child.is_in_group("tri_visual"):
			return child
	return null


# ═════════════════════════════════════════════════════════════════════════
# PHYSICS & COLLISION
# ═════════════════════════════════════════════════════════════════════════

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "BodyCollision"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	_collision_shape.shape = sphere
	add_child(_collision_shape)

	# Layer 2 so catalyst projectiles (mask=1|2) can detect us
	collision_layer = 2
	collision_mask = 1  # Collide with world for movement


func _build_projectile_detector() -> void:
	_projectile_detector = Area3D.new()
	_projectile_detector.name = "ProjectileDetector"
	_projectile_detector.collision_layer = 0
	_projectile_detector.collision_mask = 16  # Hazard layer (catalyst projectiles)
	_projectile_detector.monitoring = true
	_projectile_detector.monitorable = false

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5  # Slightly larger for generous detection
	shape.shape = sphere
	_projectile_detector.add_child(shape)
	add_child(_projectile_detector)

	_projectile_detector.body_entered.connect(_on_projectile_entered)


# ═════════════════════════════════════════════════════════════════════════
# MOVEMENT HELPERS
# ═════════════════════════════════════════════════════════════════════════

func _face_player(delta: float) -> void:
	if not is_instance_valid(_player_node):
		return
	var to_player := _player_node.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.001:
		return
	var target_yaw := atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(4.0 * delta, 0.0, 1.0))


func _find_player() -> void:
	_player_node = null
	var candidates := [
		get_tree().get_first_node_in_group("player"),
	]
	var scene_root := get_tree().current_scene
	if scene_root:
		candidates.append(scene_root.find_child("XROrigin3D", true, false))
		candidates.append(scene_root.find_child("Player", true, false))
	for c in candidates:
		if c is Node3D:
			_player_node = c
			break


func _get_distance_to_player() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


# ═════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═════════════════════════════════════════════════════════════════════════

func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)


# ═════════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ═════════════════════════════════════════════════════════════════════════

func _save_state() -> void:
	var data := {
		"tier": _current_tier,
		"completed_sequences": _completed_sequences.duplicate(),
		"color_history": _color_history.map(func(c: Color): return [c.r, c.g, c.b, c.a]),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if not data is Dictionary:
		return
	if data.has("tier"):
		_current_tier = clampi(int(data["tier"]), 0, 5)
	if data.has("completed_sequences"):
		_completed_sequences.clear()
		for seq in data["completed_sequences"]:
			_completed_sequences.append(str(seq))
	if data.has("color_history"):
		_color_history.clear()
		for arr in data["color_history"]:
			if arr is Array and arr.size() >= 4:
				_color_history.append(Color(arr[0], arr[1], arr[2], arr[3]))


# ═════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	if config_data.has("tier"):
		_current_tier = clampi(int(config_data["tier"]), 0, 5)
		_rebuild_visual()
	if config_data.has("start_state"):
		var state_str: String = str(config_data["start_state"]).to_lower()
		match state_str:
			"aware": _set_state(State.AWARE)
			"curious": _set_state(State.CURIOUS)

func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
