extends HazardCreatureBase
class_name BricoleurGolem
## Asymmetric body assembled from mismatched primitive parts.
## Each body slot picks a random mesh type and color. On damage,
## parts fly off and new random parts snap back (rebuild).
## After 3 rebuilds, enters EXHAUSTED state (slower, no more rebuilds).

enum BodySlot { HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG }

@export_group("Bricolage")
@export var rebuild_time: float = 1.5
@export var rebuild_heal_pct: float = 0.2
@export var max_rebuilds: int = 3
@export var part_scatter_distance: float = 1.5
@export var exhausted_speed_mult: float = 0.4

# ── Slot positions ───────────────────────────────────────────────────────

const SLOT_POSITIONS: Array[Vector3] = [
	Vector3(0, 0.55, 0),       # HEAD
	Vector3(0, 0.3, 0),        # TORSO
	Vector3(-0.2, 0.35, 0),    # LEFT_ARM
	Vector3(0.2, 0.35, 0),     # RIGHT_ARM
	Vector3(-0.08, 0.0, 0),    # LEFT_LEG
	Vector3(0.08, 0.0, 0),     # RIGHT_LEG
]

const SLOT_BASE_SIZES: Array[float] = [
	0.08,  # HEAD
	0.12,  # TORSO
	0.05,  # LEFT_ARM
	0.05,  # RIGHT_ARM
	0.05,  # LEFT_LEG
	0.05,  # RIGHT_LEG
]

const SLOT_NAMES: Array[String] = [
	"HEAD", "TORSO", "LEFT_ARM", "RIGHT_ARM", "LEFT_LEG", "RIGHT_LEG"
]

# ── State ────────────────────────────────────────────────────────────────

var _rebuild_count: int = 0
var _is_rebuilding: bool = false
var _rebuild_timer: float = 0.0
var _is_exhausted: bool = false
var _walk_phase: float = 0.0

# ── Visual refs ──────────────────────────────────────────────────────────

var _part_meshes: Array[MeshInstance3D] = []
var _part_materials: Array[StandardMaterial3D] = []
var _part_original_pos: Array[Vector3] = []
var _scattered_targets: Array[Vector3] = []


func _on_ready() -> void:
	_mesh_root.position.y = 0.15
	max_health = 100.0
	_health = max_health
	chase_speed = 2.8
	patrol_speed = 1.2
	contact_damage = 15.0


func _create_materials() -> void:
	_part_materials.clear()
	for i in range(6):
		var hue: float = randf()
		var color := Color.from_hsv(hue, 0.6, 0.7)
		var mat := _make_material(color, color * 0.3)
		_part_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.15
	shape.height = 0.6
	col.shape = shape
	col.position.y = 0.45
	add_child(col)


func _build_mesh() -> void:
	_part_meshes.clear()
	_part_original_pos.clear()
	for i in range(6):
		_build_random_part(i)


func _build_random_part(slot_index: int) -> void:
	# Remove old mesh if it exists
	if slot_index < _part_meshes.size() and is_instance_valid(_part_meshes[slot_index]):
		_part_meshes[slot_index].queue_free()

	var base_size: float = SLOT_BASE_SIZES[slot_index]
	var size_variation: float = base_size * randf_range(0.8, 1.2)
	var mesh: Mesh = _random_mesh(size_variation)

	# New material with random hue
	var hue: float = randf()
	var color := Color.from_hsv(hue, 0.6, 0.7)
	var mat := _make_material(color, color * 0.3)

	if slot_index < _part_materials.size():
		_part_materials[slot_index] = mat
	else:
		_part_materials.append(mat)

	var pos := SLOT_POSITIONS[slot_index]
	var mi := _add_mesh(mesh, mat, pos)
	mi.name = "Part_%s" % SLOT_NAMES[slot_index]

	if slot_index < _part_meshes.size():
		_part_meshes[slot_index] = mi
	else:
		_part_meshes.append(mi)

	if slot_index < _part_original_pos.size():
		_part_original_pos[slot_index] = pos
	else:
		_part_original_pos.append(pos)


func _random_mesh(size: float) -> Mesh:
	var choice: int = randi_range(0, 3)
	match choice:
		0:
			var m := BoxMesh.new()
			m.size = Vector3(size, size, size)
			return m
		1:
			var m := SphereMesh.new()
			m.radius = size
			m.height = size * 2.0
			return m
		2:
			var m := CylinderMesh.new()
			m.height = size * 2.0
			m.top_radius = size * 0.5
			m.bottom_radius = size * 0.5
			return m
		3:
			var m := PrismMesh.new()
			m.size = Vector3(size, size, size)
			return m
	# Fallback
	var m := BoxMesh.new()
	m.size = Vector3(size, size, size)
	return m


func _process_visual(delta: float) -> void:
	if _is_rebuilding:
		_process_rebuild(delta)
		return

	# Walk animation (swing legs)
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 4.0
		_animate_legs()

	# Exhausted visual: slight droop
	if _is_exhausted:
		_mesh_root.rotation.x = sin(_state_time) * 0.05 + 0.1


func _animate_legs() -> void:
	# LEFT_LEG (index 4) and RIGHT_LEG (index 5)
	if _part_meshes.size() > 5:
		if is_instance_valid(_part_meshes[4]):
			_part_meshes[4].position.z = SLOT_POSITIONS[4].z + sin(_walk_phase) * 0.06
			_part_meshes[4].position.y = SLOT_POSITIONS[4].y + abs(sin(_walk_phase)) * 0.03
		if is_instance_valid(_part_meshes[5]):
			_part_meshes[5].position.z = SLOT_POSITIONS[5].z + sin(_walk_phase + PI) * 0.06
			_part_meshes[5].position.y = SLOT_POSITIONS[5].y + abs(sin(_walk_phase + PI)) * 0.03


func _on_damaged(amount: float) -> void:
	if _is_rebuilding:
		return

	if _is_exhausted or _rebuild_count >= max_rebuilds:
		# No more rebuilds, just stun
		_is_exhausted = true
		chase_speed = chase_speed * exhausted_speed_mult
		patrol_speed = patrol_speed * exhausted_speed_mult
		_set_state(BaseState.STUNNED)
		return

	# Start rebuild: scatter parts outward
	_is_rebuilding = true
	_rebuild_timer = 0.0
	_rebuild_count += 1
	velocity = Vector3.ZERO

	_scattered_targets.clear()
	for i in range(_part_meshes.size()):
		var scatter_dir := Vector3(randf_range(-1, 1), randf_range(0.5, 1.5), randf_range(-1, 1)).normalized()
		_scattered_targets.append(_part_original_pos[i] + scatter_dir * part_scatter_distance)


func _process_rebuild(delta: float) -> void:
	_rebuild_timer += delta
	var t: float = _rebuild_timer / rebuild_time

	if t < 0.5:
		# First half: parts fly outward
		var scatter_t: float = t * 2.0
		for i in range(_part_meshes.size()):
			if is_instance_valid(_part_meshes[i]) and i < _scattered_targets.size():
				_part_meshes[i].position = _part_original_pos[i].lerp(_scattered_targets[i], scatter_t)
	elif t < 0.6:
		# Brief pause at scattered positions — regenerate part types
		pass
	else:
		# Second half: new parts snap back
		if t >= 0.6 and _rebuild_timer - delta < rebuild_time * 0.6:
			# Regenerate parts at the transition point
			for i in range(6):
				_build_random_part(i)
				if i < _scattered_targets.size():
					_part_meshes[i].position = _scattered_targets[i]

		var snap_t: float = (t - 0.6) / 0.4
		snap_t = clamp(snap_t, 0.0, 1.0)
		for i in range(_part_meshes.size()):
			if is_instance_valid(_part_meshes[i]) and i < _scattered_targets.size():
				_part_meshes[i].position = _scattered_targets[i].lerp(_part_original_pos[i], snap_t)

	if t >= 1.0:
		_is_rebuilding = false
		# Heal partially
		_health = min(max_health, _health + max_health * rebuild_heal_pct)
		# Snap all parts to final positions
		for i in range(_part_meshes.size()):
			if is_instance_valid(_part_meshes[i]) and i < _part_original_pos.size():
				_part_meshes[i].position = _part_original_pos[i]
		_set_state(BaseState.PATROL)


func _process_chase(delta: float) -> void:
	if _is_rebuilding:
		velocity = Vector3.ZERO
		return

	var dist := _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	var spd: float = chase_speed
	if _is_exhausted:
		spd *= exhausted_speed_mult

	if is_instance_valid(_player_node):
		var dir := _get_player_direction()
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		velocity.y = 0.0
		_face_direction(dir, delta * 5.0)
	else:
		velocity = Vector3.ZERO


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.DEAD:
		_is_rebuilding = false
