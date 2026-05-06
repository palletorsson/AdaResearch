# timeline_demo.gd - Demo controller for audio timeline (VR/3D)
extends Control

# Demo audio sources
var audio_generators: Array[AudioStreamPlayer] = []
var demo_sounds: Array[Dictionary] = []

@onready var timeline_scene = preload("res://algorithms/wavefunctions/soundtimeline/sound_timeline.tscn")
var timeline_instance: Node3D


# Label3D nodes
var _title_label: Label3D
var _instructions_label: Label3D
var _demo_buttons: Array[Node3D] = []

func _ready() -> void:
	setup_demo_sounds()
	create_timeline()
	setup_demo_ui()

func setup_demo_sounds() -> void:
	demo_sounds = [
		{
			"name": "Sine Wave Sweep",
			"type": "sweep",
			"freq_start": 220.0,
			"freq_end": 880.0,
			"duration": 3.0
		},
		{
			"name": "Drumbeat Pattern",
			"type": "drums",
			"pattern": [1, 0, 1, 0, 1, 1, 0, 1],
			"tempo": 120.0
		},
		{
			"name": "Chord Progression",
			"type": "chords",
			"frequencies": [[261.63, 329.63, 392.0], [293.66, 369.99, 440.0], [329.63, 415.30, 493.88]],
			"duration": 2.0
		},
		{
			"name": "White Noise Burst",
			"type": "noise",
			"duration": 1.0,
			"amplitude": 0.3
		}
	]

func create_timeline() -> void:
	timeline_instance = timeline_scene.instantiate()
	add_child(timeline_instance)
	timeline_instance.position = Vector3(0, -0.15, 0)

func setup_demo_ui() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")

	# Instructions label above panel
	_instructions_label = Label3D.new()
	_instructions_label.text = "Press buttons to generate audio patterns."
	_instructions_label.font_size = 20
	_instructions_label.modulate = Color.YELLOW
	_instructions_label.position = Vector3(0, 0.12, 0)
	add_child(_instructions_label)

	# Build button row from demo sound names
	var btn_row: Array = []
	for i in range(demo_sounds.size()):
		btn_row.append({"type": "button", "label": demo_sounds[i]["name"].substr(0, 8).to_upper()})

	var panel: Node3D = RackTpl.create_panel("TIMELINE DEMO", [btn_row])
	panel.position = Vector3(0, 0, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Connect demo buttons
	for i in range(demo_sounds.size()):
		var btn: Node = panel.find_child("Btn_%d" % i, true, false)
		if btn:
			_demo_buttons.append(btn)
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(_on_demo_button_pressed.bind(i))

func _on_demo_button_pressed(demo_index: int) -> void:
	if demo_index < demo_sounds.size():
		generate_demo_sound(demo_sounds[demo_index])

func generate_demo_sound(sound_config: Dictionary) -> void:
	print("Generating demo sound: ", sound_config["name"])

	match sound_config["type"]:
		"sweep":
			generate_frequency_sweep(sound_config)
		"drums":
			generate_drum_pattern(sound_config)
		"chords":
			generate_chord_progression(sound_config)
		"noise":
			generate_noise_burst(sound_config)

func generate_frequency_sweep(config: Dictionary) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)

	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = config["duration"]
	player.stream = stream

	player.play()

	var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
	var duration = config["duration"]

	if generator:
		var sample_rate = 44100
		var samples_count = int(sample_rate * duration)

		var freq_start = config["freq_start"]
		var freq_end = config["freq_end"]

		var chunk_size = 1024
		for chunk_start in range(0, samples_count, chunk_size):
			var chunk_end = min(chunk_start + chunk_size, samples_count)
			var chunk = PackedFloat32Array()

			for i in range(chunk_start, chunk_end):
				var t = float(i) / sample_rate
				var progress = t / duration
				var freq = lerp(freq_start, freq_end, progress)
				var sample = sin(2.0 * PI * freq * t) * 0.5
				chunk.append(sample)

			generator.push_buffer(chunk)

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration + 0.5
	timer.one_shot = true
	timer.timeout.connect(_cleanup_player.bind(player, timer))
	timer.start()

func generate_drum_pattern(config: Dictionary) -> void:
	var pattern = config["pattern"]
	var tempo = config["tempo"]
	var beat_duration = 60.0 / tempo / 4.0

	for i in range(pattern.size()):
		if pattern[i] == 1:
			var delay = i * beat_duration
			call_deferred("_play_drum_hit", delay)

func _play_drum_hit(delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	var player = AudioStreamPlayer.new()
	add_child(player)

	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.1
	player.stream = stream

	player.play()

	var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if generator:
		var chunk = PackedFloat32Array()
		var samples = int(4410)

		for i in range(samples):
			var t = float(i) / 44100.0
			var envelope = exp(-t * 20.0)
			var noise = (randf() * 2.0 - 1.0) * envelope * 0.3
			chunk.append(noise)

		generator.push_buffer(chunk)

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(_cleanup_player.bind(player, timer))
	timer.start()

func generate_chord_progression(config: Dictionary) -> void:
	var frequencies = config["frequencies"]
	var duration = config["duration"]

	for i in range(frequencies.size()):
		var chord_delay = i * duration
		call_deferred("_play_chord", frequencies[i], duration, chord_delay)

func _play_chord(freqs: Array, duration: float, delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	var players = []
	for freq in freqs:
		var player = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

		var stream = AudioStreamGenerator.new()
		stream.mix_rate = 44100.0
		stream.buffer_length = duration
		player.stream = stream
		player.volume_db = -10

		player.play()

		var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
		if generator:
			var chunk = PackedFloat32Array()
			var samples = int(44100 * duration)

			for i in range(samples):
				var t = float(i) / 44100.0
				var sample = sin(2.0 * PI * freq * t) * 0.3
				chunk.append(sample)

			generator.push_buffer(chunk)

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration + 0.1
	timer.one_shot = true
	timer.timeout.connect(_cleanup_players.bind(players, timer))
	timer.start()

func generate_noise_burst(config: Dictionary) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)

	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = config["duration"]
	player.stream = stream
	player.volume_db = -15

	player.play()

	var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if generator:
		var chunk = PackedFloat32Array()
		var samples = int(44100 * config["duration"])
		var amplitude = config.get("amplitude", 0.3)

		for i in range(samples):
			var noise = (randf() * 2.0 - 1.0) * amplitude
			chunk.append(noise)

		generator.push_buffer(chunk)

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = config["duration"] + 0.1
	timer.one_shot = true
	timer.timeout.connect(_cleanup_player.bind(player, timer))
	timer.start()

func _cleanup_player(player: AudioStreamPlayer, timer: Timer) -> void:
	if player:
		player.stop()
		player.queue_free()
	if timer:
		timer.queue_free()

func _cleanup_players(players: Array, timer: Timer) -> void:
	for player in players:
		if player:
			player.stop()
			player.queue_free()
	if timer:
		timer.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
