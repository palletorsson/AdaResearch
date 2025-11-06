# hit_target_cube.gd
# Target cube that reacts when hit by throwable balls
extends StaticBody3D

signal target_hit(target: Node3D, impact_velocity: Vector3)

@export_group("Target Properties")
@export var cube_size: float = 0.3
@export var target_color: Color = Color(1.0, 0.3, 0.3, 1.0)  # Red
@export var hit_color: Color = Color(0.3, 1.0, 0.3, 1.0)  # Green
@export var points_value: int = 10

@export_group("Feedback")
@export var enable_hit_animation: bool = true
@export var enable_hit_sound: bool = true
@export var destroy_on_hit: bool = false
@export var respawn_time: float = 3.0
@export var show_hit_label: bool = true

@export_group("Visual Effects")
@export var pulse_scale: float = 1.3
@export var pulse_duration: float = 0.3
@export var color_change_duration: float = 0.5

# State
var is_hit: bool = false
var hit_count: int = 0
var original_position: Vector3 = Vector3.ZERO
var original_scale: Vector3 = Vector3.ONE

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null
var original_material: StandardMaterial3D = null
var hit_label: Label3D = null

func _ready() -> void:
	original_position = global_position
	original_scale = scale
	_setup_visual()
	_setup_collision()
	_setup_hit_detection()
	_setup_hit_label()

func _setup_visual() -> void:
	"""Create the cube mesh"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	# Create box mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(cube_size, cube_size, cube_size)
	mesh_instance.mesh = box_mesh

	# Create material
	original_material = StandardMaterial3D.new()
	original_material.albedo_color = target_color
	original_material.emission_enabled = true
	original_material.emission = target_color
	original_material.emission_energy = 0.2
	original_material.metallic = 0.4
	original_material.roughness = 0.6

	mesh_instance.material_override = original_material

func _setup_collision() -> void:
	"""Create collision shape for the cube"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size, cube_size)
	collision_shape.shape = box_shape
	add_child(collision_shape)

func _setup_hit_detection() -> void:
	"""Create Area3D for detecting ball impacts"""
	area = Area3D.new()
	area.name = "HitDetectionArea"
	area.monitoring = true
	area.monitorable = true

	# Set collision layers - only detect layer 2 (throwable balls)
	area.collision_layer = 0  # Area doesn't exist on any layer
	area.collision_mask = 2   # Only detect objects on layer 2

	add_child(area)

	# Create slightly larger collision shape for area
	var area_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size * 1.1, cube_size * 1.1, cube_size * 1.1)
	area_collision.shape = box_shape
	area.add_child(area_collision)

	# Connect signals
	area.body_entered.connect(_on_body_entered)

func _setup_hit_label() -> void:
	"""Create floating score label"""
	if not show_hit_label:
		return

	hit_label = Label3D.new()
	hit_label.name = "HitLabel"
	hit_label.text = "+%d" % points_value
	hit_label.font_size = 32
	hit_label.outline_size = 4
	hit_label.outline_modulate = Color.BLACK
	hit_label.modulate = Color.YELLOW
	hit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hit_label.position = Vector3(0, cube_size, 0)
	hit_label.visible = false
	add_child(hit_label)

func _on_body_entered(body: Node) -> void:
	"""Handle collision with throwable objects"""
	print("[HitTarget] Body entered: ", body.name, " Groups: ", body.get_groups())

	# Ignore self-detection (shouldn't happen with proper collision layers, but safety check)
	if body == self:
		print("[HitTarget] Ignoring self-detection")
		return

	if not body.is_in_group("throwable"):
		print("[HitTarget] Body not in 'throwable' group, ignoring")
		return

	if is_hit and not destroy_on_hit:
		print("[HitTarget] Already hit and destroy_on_hit=false, ignoring")
		return  # Already hit, ignore

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity
		print("[HitTarget] Impact velocity: ", impact_velocity.length(), " m/s")

	_trigger_hit(impact_velocity)

func _trigger_hit(impact_velocity: Vector3) -> void:
	"""Trigger hit effects and emit signal"""
	is_hit = true
	hit_count += 1

	print("[HitTarget] HIT! Count: ", hit_count, " Velocity: ", impact_velocity.length())

	# Emit signal for scoring
	target_hit.emit(self, impact_velocity)

	# Visual feedback
	if enable_hit_animation:
		_play_hit_animation()

	# Audio feedback
	if enable_hit_sound:
		_play_hit_sound(impact_velocity.length())

	# Show score label
	if show_hit_label and hit_label:
		_show_hit_label()

	# Handle destruction
	if destroy_on_hit:
		_schedule_respawn()

func _play_hit_animation() -> void:
	"""Animate the cube when hit"""
	var tween = create_tween()
	tween.set_parallel(true)

	# Color change
	tween.tween_method(_set_cube_color, target_color, hit_color, color_change_duration * 0.5)
	var color_back = tween.tween_method(_set_cube_color, hit_color, target_color, color_change_duration * 0.5)
	if color_back:
		color_back.set_delay(color_change_duration * 0.5)

	# Scale pulse
	tween.tween_property(mesh_instance, "scale", Vector3.ONE * pulse_scale, pulse_duration * 0.5)
	var scale_back = tween.tween_property(mesh_instance, "scale", Vector3.ONE, pulse_duration * 0.5)
	if scale_back:
		scale_back.set_delay(pulse_duration * 0.5)

	# Increase emission on hit
	if mesh_instance and mesh_instance.material_override:
		tween.tween_property(mesh_instance.material_override, "emission_energy", 1.5, 0.1)
		var emission_down = tween.tween_property(mesh_instance.material_override, "emission_energy", 0.2, 0.4)
		if emission_down:
			emission_down.set_delay(0.1)

	# Reset hit state after animation
	if not destroy_on_hit:
		tween.chain()  # Switch to sequential for callback
		var callback_tweener = tween.tween_callback(func(): is_hit = false)
		if callback_tweener:
			callback_tweener.set_delay(color_change_duration)

func _set_cube_color(color: Color) -> void:
	"""Update cube color"""
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color
		mesh_instance.material_override.emission = color

func _play_hit_sound(impact_speed: float) -> void:
	"""Generate procedural hit sound"""
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "HitSound"
	audio_player.bus = "Master"
	add_child(audio_player)

	# Create impact sound (higher pitch for faster impacts)
	var base_frequency = 200.0 + (impact_speed * 20.0)
	base_frequency = clamp(base_frequency, 200.0, 800.0)

	var stream = _generate_impact_sound(base_frequency)
	audio_player.stream = stream
	audio_player.play()

	# Remove after playing
	await audio_player.finished
	audio_player.queue_free()

func _generate_impact_sound(frequency: float) -> AudioStreamWAV:
	"""Generate procedural impact sound effect"""
	var sample_rate = 22050
	var duration = 0.15
	var sample_count = int(sample_rate * duration)

	var samples = PackedByteArray()
	samples.resize(sample_count * 2)  # 16-bit = 2 bytes per sample

	for i in range(sample_count):
		var t = float(i) / sample_rate
		# Sine wave with exponential decay
		var envelope = exp(-t * 15.0)  # Fast decay
		var value = sin(TAU * frequency * t) * envelope
		# Add some noise for impact texture
		value += randf_range(-0.1, 0.1) * envelope

		var sample_value = int(value * 16384.0)  # 50% amplitude
		sample_value = clampi(sample_value, -32768, 32767)

		# Convert to bytes (little-endian)
		samples[i * 2] = sample_value & 0xFF
		samples[i * 2 + 1] = (sample_value >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.data = samples
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false

	return stream

func _show_hit_label() -> void:
	"""Animate floating score label"""
	if not hit_label:
		return

	hit_label.visible = true
	hit_label.position = Vector3(0, cube_size, 0)
	hit_label.modulate.a = 1.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hit_label, "position:y", cube_size + 0.5, 1.0)
	tween.tween_property(hit_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(func(): hit_label.visible = false)

func _schedule_respawn() -> void:
	"""Hide target and respawn after delay"""
	visible = false
	collision_layer = 0
	collision_mask = 0

	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn() -> void:
	"""Restore target to original state"""
	global_position = original_position
	scale = original_scale
	visible = true
	collision_layer = 1
	collision_mask = 1
	is_hit = false

	# Spawn animation
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE * 1.2, 0.2)
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 0.2)

func get_hit_count() -> int:
	"""Return total number of hits"""
	return hit_count

func get_points_value() -> int:
	"""Return point value of this target"""
	return points_value

func reset() -> void:
	"""Reset target to initial state"""
	is_hit = false
	hit_count = 0
	global_position = original_position
	visible = true
	collision_layer = 1
	collision_mask = 1
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = target_color
		mesh_instance.material_override.emission = target_color
