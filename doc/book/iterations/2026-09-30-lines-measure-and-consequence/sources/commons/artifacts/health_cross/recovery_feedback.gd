extends Node3D
## A short spatial chime and expanding strokes; no imported sound dependency.
var audio: AudioStreamPlayer3D
var bursts := 0

func _ready() -> void:
	audio = AudioStreamPlayer3D.new()
	audio.name = "RecoveryChime"
	audio.max_distance = 10.0
	audio.volume_db = -12.0
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(22050 * 0.55) * 2)
	for i in range(data.size() / 2):
		var t := float(i) / 22050.0
		var envelope := minf(t / 0.018, 1.0) * pow(maxf(0.0, 1.0-t/0.55),2)
		var frequency := 523.25 if t < 0.14 else (659.25 if t < 0.28 else 783.99)
		var sample := (sin(TAU*frequency*t)*0.65 + sin(TAU*frequency*2*t)*0.12)*envelope
		data.encode_s16(i*2,int(sample*32767))
	wave.data = data
	audio.stream = wave
	add_child(audio)

func play_at(at: Vector3, colour: Color) -> void:
	bursts += 1
	audio.position = at
	audio.play()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	for i in range(12):
		var stroke := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.014,0.1,0.014)
		stroke.mesh = box
		stroke.material_override = material
		add_child(stroke)
		stroke.position = at
		var angle := TAU * i / 12.0
		stroke.rotation.z = -angle
		var tween := create_tween().set_parallel(true)
		tween.tween_property(stroke,"position",at+Vector3(sin(angle),cos(angle),0)*0.65,0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(stroke,"scale",Vector3.ONE*0.01,0.45).set_delay(0.18)
		tween.chain().tween_callback(stroke.queue_free)
