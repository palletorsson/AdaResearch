extends HazardCreatureBase
class_name WaveRider
## A ribbon of 20 BoxMesh segments arranged in a sine wave.
## Oscillation teaches wave concepts: frequency, amplitude, wavelength.
## On DETECT frequency ramps up. On CHASE fires burst at resonance peak
## (when wave peak aligns with player Y). Color lerps blue-to-red by sine value.

@export_group("Wave")
@export var segment_count: int = 20
@export var segment_size: Vector3 = Vector3(0.1, 0.05, 0.15)
@export var segment_spacing: float = 0.12
@export var frequency: float = 2.0
@export var amplitude: float = 0.3
@export var max_frequency: float = 8.0
@export var burst_damage: float = 20.0
@export var burst_cooldown: float = 1.5

# ── Wave state ───────────────────────────────────────────────────────────

var _phase: float = 0.0
var _base_frequency: float = 2.0
var _burst_timer: float = 0.0
var _last_peak_y: float = 0.0

# ── Visual refs ──────────────────────────────────────────────────────────

var _segments: Array[MeshInstance3D] = []
var _segment_materials: Array[StandardMaterial3D] = []
var _label: Label3D = null
var _cold_color: Color = Color(0.1, 0.2, 0.95)
var _hot_color: Color = Color(0.95, 0.15, 0.05)


func _on_ready() -> void:
	_base_frequency = frequency
	max_health = 70.0
	_health = max_health
	chase_speed = 2.8
	patrol_speed = 1.5
	contact_damage = 10.0


func _create_materials() -> void:
	_segment_materials.clear()
	for i in range(segment_count):
		var mat := _make_material(_cold_color, _cold_color * 0.3)
		_segment_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	# Collision covers the full ribbon span
	var total_width: float = segment_count * segment_spacing
	shape.size = Vector3(total_width, amplitude * 2.0 + segment_size.y, segment_size.z)
	col.shape = shape
	col.position = Vector3(0, 0.5, 0)
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.5

	var half_count: float = segment_count * 0.5
	for i in range(segment_count):
		var box := BoxMesh.new()
		box.size = segment_size
		var x_pos: float = (i - half_count) * segment_spacing
		var sine_val: float = sin(frequency * float(i) * segment_spacing)
		var y_pos: float = amplitude * sine_val
		var mi := _add_mesh(box, _segment_materials[i], Vector3(x_pos, y_pos, 0))
		_segments.append(mi)

	# Info label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 40
	_label.pixel_size = 0.003
	_label.position = Vector3(0, amplitude + 0.25, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	_phase += delta * frequency
	_burst_timer = max(0.0, _burst_timer - delta)

	var half_count: float = segment_count * 0.5
	var peak_y: float = -999.0

	for i in range(segment_count):
		var sine_val: float = sin(frequency * float(i) * segment_spacing + _phase)
		var y_pos: float = amplitude * sine_val
		var x_pos: float = (i - half_count) * segment_spacing

		_segments[i].position = Vector3(x_pos, y_pos, 0)

		# Color: lerp from cold to hot based on sine value (range -1..1 mapped to 0..1)
		var t: float = (sine_val + 1.0) * 0.5
		var color: Color = _cold_color.lerp(_hot_color, t)
		_segment_materials[i].albedo_color = color
		_segment_materials[i].emission = color * 0.4
		_segment_materials[i].emission_energy_multiplier = 0.5 + t * 2.0

		if y_pos > peak_y:
			peak_y = y_pos

	_last_peak_y = peak_y

	# Update label
	var wavelength: float = TAU / max(frequency, 0.001) if frequency > 0.001 else 999.0
	if _label:
		_label.text = "f=%.1f Hz, A=%.2f, l=%.2f" % [frequency, amplitude, wavelength]


func _process_detect(delta: float) -> void:
	# Ramp up frequency
	frequency = min(max_frequency, frequency + delta * 1.5)
	velocity = velocity.move_toward(Vector3.ZERO, 0.2)
	if _state_time >= 0.6:
		_set_state(BaseState.CHASE)


func _process_chase(delta: float) -> void:
	var dist := _get_player_distance()
	if dist > disengage_radius:
		frequency = _base_frequency
		_set_state(BaseState.PATROL)
		return

	# Gradually increase frequency during chase
	frequency = min(max_frequency, frequency + delta * 0.5)

	# Move toward player
	if is_instance_valid(_player_node):
		var dir := _get_player_direction()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		velocity.y = 0.0
		_face_direction(dir, delta * 5.0)
	else:
		velocity = Vector3.ZERO

	# Resonance burst: when wave peak aligns near player Y
	if is_instance_valid(_player_node) and _burst_timer <= 0.0:
		var player_relative_y: float = _player_node.global_position.y - global_position.y
		var peak_world_y: float = _last_peak_y + _mesh_root.position.y
		if abs(peak_world_y - player_relative_y) < 0.15:
			_fire_burst()
			_burst_timer = burst_cooldown


func _fire_burst() -> void:
	# Fire a spread of small projectiles from the wave peaks
	var dir := _get_player_direction()
	for i in range(3):
		var proj := RigidBody3D.new()
		proj.gravity_scale = 0.2
		proj.freeze = false

		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		var mat := _make_material(_hot_color, _hot_color)
		mi.set_surface_override_material(0, mat)
		proj.add_child(mi)

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.04
		col.shape = shape
		proj.add_child(col)

		# Spread angle
		var angle_offset: float = (i - 1) * 0.3
		var spread_dir := dir.rotated(Vector3.UP, angle_offset)

		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + Vector3(0, 0.5, 0) + spread_dir * 0.3
		proj.linear_velocity = spread_dir * 6.0 + Vector3(0, 1.5, 0)

		# Auto-remove
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func(): if is_instance_valid(proj): proj.queue_free())


func _on_damaged(_amount: float) -> void:
	# Amplitude spikes on damage then recovers
	amplitude = min(0.6, amplitude + 0.1)
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.PATROL:
		frequency = _base_frequency
		amplitude = 0.3
	elif new_state == BaseState.STUNNED:
		velocity = Vector3.ZERO
