extends Node3D

class_name RegenerateCube

@export var rotation_speed: float = 1.4
@export var bob_height: float = 0.12
@export var bob_speed: float = 1.6
@export var respawn_time: float = 2.5
@export var target_scripts: PackedStringArray = PackedStringArray()
@export var target_scenes: PackedStringArray = PackedStringArray()
@export var status_message: String = "Regenerating example"

var original_y: float
var time_passed: float = 0.0
var has_been_activated: bool = false

signal regenerate_requested(origin: Vector3, targets: Array, metadata: Dictionary)

var activation_sound: AudioStreamPlayer3D

func _ready() -> void:
	original_y = global_position.y
	setup_activation_sound()
	add_to_group("regenerate_emitters")
	print("RegenerateCube: Ready at position %s" % global_position)

func _process(delta: float) -> void:
	if has_been_activated:
		return
	rotate_y(rotation_speed * delta)
	time_passed += delta
	var bob_offset = sin(time_passed * bob_speed) * bob_height
	global_position.y = original_y + bob_offset

func _is_player(body: Node3D) -> bool:
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body")

func setup_activation_sound() -> void:
	activation_sound = AudioStreamPlayer3D.new()
	add_child(activation_sound)
	activation_sound.unit_size = 2.0
	activation_sound.max_distance = 18.0
	activation_sound.volume_db = -4.0
	var sample_rate: int = 44100
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	var data: PackedByteArray = PackedByteArray()
	var length: float = 0.32
	var samples: int = int(length * sample_rate)
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = 0.6 * (1.0 - t / length)
		var sweep: float = lerp(340.0, 720.0, t / length)
		var sample_value: float = envelope * sin(TAU * sweep * t)
		var sample_int: int = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_int)
	stream.data = data
	activation_sound.stream = stream

func activate() -> void:
	if has_been_activated:
		return
	has_been_activated = true
	var scripts := Array(target_scripts)
	var metadata := {
		"source": "RegenerateCube",
		"cube_path": get_path()
	}
	if status_message.length() > 0:
		metadata["message"] = status_message
	if target_scenes.size() > 0:
		metadata["scenes"] = Array(target_scenes)
	print("RegenerateCube: Requesting regenerate for %d script targets" % scripts.size())
	regenerate_requested.emit(global_position, scripts, metadata)
	_play_activation_sound()
	_play_activation_effect()
	await get_tree().create_timer(0.2).timeout
	visible = false
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _play_activation_sound() -> void:
	var sound_clone: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound_clone)
	sound_clone.stream = activation_sound.stream
	sound_clone.global_position = global_position
	sound_clone.volume_db = activation_sound.volume_db
	sound_clone.pitch_scale = 1.05
	sound_clone.play()
	sound_clone.finished.connect(func(): sound_clone.queue_free())

func _play_activation_effect() -> void:
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		var tween = create_tween()
		tween.parallel().tween_property(mesh_instance, "scale", mesh_instance.scale * 1.6, 0.25)
		var material = mesh_instance.material_override
		if material and material is ShaderMaterial:
			var shader_material: ShaderMaterial = material
			var original_emission = shader_material.get_shader_parameter("emissionColor")
			var pulse_color = Color(1.0, 0.4, 0.7, 1.0) * 1.8
			tween.parallel().tween_method(func(color): shader_material.set_shader_parameter("emissionColor", color), original_emission, pulse_color, 0.12)
			tween.parallel().tween_method(func(color): shader_material.set_shader_parameter("emissionColor", color), pulse_color, original_emission, 0.18).set_delay(0.12)

func _respawn() -> void:
	has_been_activated = false
	visible = true
	global_position.y = original_y
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		mesh_instance.scale = Vector3(0.5, 0.5, 0.5)
	var material = mesh_instance and mesh_instance.material_override
	if material and material is ShaderMaterial:
		var shader_material: ShaderMaterial = material
		shader_material.set_shader_parameter("modelOpacity", 0.0)
		var tween = create_tween()
		tween.tween_method(func(opacity): shader_material.set_shader_parameter("modelOpacity", opacity), 0.0, 0.9, 0.4)
	print("RegenerateCube: Respawned at position %s" % global_position)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		activate()

func set_target_data(scenes: Array, scripts: Array) -> void:
	target_scenes = PackedStringArray(scenes)
	target_scripts = PackedStringArray(scripts)

func set_targets_from_parameters(parameters: Array) -> void:
	var scenes: Array = []
	var scripts: Array = []
	for param in parameters:
		var value: String = str(param).strip_edges()
		if value.is_empty():
			continue
		var parts: PackedStringArray = value.split("|")
		if parts.size() >= 2:
			if parts[0].length() > 0:
				scenes.append(parts[0])
			if parts[1].length() > 0:
				scripts.append(parts[1])
		else:
			if value.ends_with(".tscn"):
				scenes.append(value)
			else:
				scripts.append(value)
	target_scenes = PackedStringArray(scenes)
	target_scripts = PackedStringArray(scripts)
	print("RegenerateCube: Configured %d scene target(s) and %d script target(s)" % [target_scenes.size(), target_scripts.size()])

func set_status_message(value: String) -> void:
	status_message = value
