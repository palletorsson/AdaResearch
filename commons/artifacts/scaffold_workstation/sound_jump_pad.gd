extends Node3D
## Bauhaus Sound Jump Pad (Forces Sequence F45+):
## Launches the visitor upward when stepped on and plays a synthesized harmonic chime
## pitched to its grid column so players can compose musical jump courses in VR.

@export var up_velocity := 6.8
@export var forward_velocity := 2.4
@export var pitch_hz := 440.0
@export var cooldown_s := 0.45

var _cooldown := 0.0
var _player: AudioStreamPlayer3D
var _ring_mesh: MeshInstance3D
var _pulse := 0.0


func _ready() -> void:
	var area := Area3D.new()
	area.name = "TriggerArea"
	area.collision_layer = 0
	area.collision_mask = 7
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 0.55, 1.5)
	cs.shape = box
	cs.position = Vector3(0.0, 0.28, 0.0)
	area.add_child(cs)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

	_player = AudioStreamPlayer3D.new()
	_player.name = "ChimeVoice"
	_player.max_distance = 18.0
	_player.volume_db = -6.0
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	_player.stream = gen
	add_child(_player)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 2.6)
		if _ring_mesh != null and is_instance_valid(_ring_mesh):
			var s := 1.0 + _pulse * 0.22
			_ring_mesh.scale = Vector3(s, 1.0 + _pulse * 0.6, s)


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0:
		return
	if body is CharacterBody3D:
		var cb := body as CharacterBody3D
		var scale_f: float = float(cb.get_meta("ada_body_scale", 1.0))
		var fwd := -global_basis.z.normalized()
		cb.velocity.y = maxf(cb.velocity.y, up_velocity * scale_f)
		cb.velocity += fwd * (forward_velocity * scale_f)
		_trigger_chime()
	elif body is RigidBody3D:
		var rb := body as RigidBody3D
		rb.apply_central_impulse(Vector3.UP * 5.0 * rb.mass)
		_trigger_chime()


func _trigger_chime() -> void:
	_cooldown = cooldown_s
	_pulse = 1.0
	if _player == null or not is_inside_tree():
		return
	_player.play()
	var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var rate := 22050.0
	var frames: int = mini(pb.get_frames_available(), int(rate * 0.20))
	for i in frames:
		var t: float = float(i) / rate
		var env: float = exp(-t * 14.0)
		var sample: float = (sin(TAU * pitch_hz * t) * 0.65 + sin(TAU * pitch_hz * 2.0 * t) * 0.25) * env * 0.35
		pb.push_frame(Vector2(sample, sample))
