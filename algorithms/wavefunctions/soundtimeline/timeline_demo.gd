# timeline_demo.gd
extends Control

# Demo audio sources
var audio_generators: Array[AudioStreamPlayer] = []
var demo_sounds: Array[Dictionary] = []

@onready var timeline_scene = preload("res://algorithms/wavefunctions/soundtimeline/sound_timeline.tscn")
var timeline_instance: Control

func _ready():
	setup_demo_sounds()
	create_timeline()
	setup_demo_ui()

func setup_demo_sounds():
	# Define some demo sound patterns
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

func create_timeline():
	timeline_instance = timeline_scene.instantiate()
	add_child(timeline_instance)
	
	# Position the timeline
	timeline_instance.position = Vector2(0, 100)

func setup_demo_ui():
	# Create demo control buttons
	var demo_panel = VBoxContainer.new()
	demo_panel.position = Vector2(20, 20)
	add_child(demo_panel)
	
	var title = Label.new()
	title.text = "Sound Timeline Demo"
	title.add_theme_font_size_override("font_size", 24)
	demo_panel.add_child(title)
	
	var instructions = RichTextLabel.new()
	instructions.custom_minimum_size = Vector2(400, 60)
	instructions.bbcode_enabled = true
	instructions.text = "[color=yellow]Demo Sounds:[/color] Click buttons to generate different audio patterns and see them visualized in real-time!"
	demo_panel.add_child(instructions)
	
	var button_container = HBoxContainer.new()
	demo_panel.add_child(button_container)
	
	# Create buttons for each demo sound
	for i in range(demo_sounds.size()):
		var button = Button.new()
		button.text = demo_sounds[i]["name"]
		button.pressed.connect(_on_demo_button_pressed.bind(i))
		button_container.add_child(button)

func _on_demo_button_pressed(demo_index: int):
	if demo_index < demo_sounds.size():
		generate_demo_sound(demo_sounds[demo_index])

func generate_demo_sound(sound_config: Dictionary):
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

func generate_frequency_sweep(config: Dictionary):
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = config["duration"]
	player.stream = stream
	
	player.play()
	
	# Get the playback object after starting playback
	var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if generator:
		# Generate sweep samples
		var sample_rate = 44100
		var duration = config["duration"]
		var samples_count = int(sample_rate * duration)
		
		var freq_start = config["freq_start"]
		var freq_end = config["freq_end"]
		
		# Generate audio in chunks
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
			
			# Push chunk to generator
			generator.push_buffer(chunk)
	
	# Clean up after duration
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration + 0.5
	timer.one_shot = true
	timer.timeout.connect(_cleanup_player.bind(player, timer))
	timer.start()

func generate_drum_pattern(config: Dictionary):
	var pattern = config["pattern"]
	var tempo = config["tempo"]
	var beat_duration = 60.0 / tempo / 4.0  # 16th notes
	
	for i in range(pattern.size()):
		if pattern[i] == 1:
			var delay = i * beat_duration
			call_deferred("_play_drum_hit", delay)

func _play_drum_hit(delay: float):
	await get_tree().create_timer(delay).timeout
	
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	# Create a simple drum sound (noise burst with envelope)
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.1
	player.stream = stream
	
	player.play()
	
	# Generate drum hit sound
	var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if generator:
		var chunk = PackedFloat32Array()
		var samples = int(4410)  # 0.1 seconds at 44100 Hz
		
		for i in range(samples):
			var t = float(i) / 44100.0
			var envelope = exp(-t * 20.0)  # Exponential decay
			var noise = (randf() * 2.0 - 1.0) * envelope * 0.3
			chunk.append(noise)
		
		generator.push_buffer(chunk)
	
	# Clean up
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(_cleanup_player.bind(player, timer))
	timer.start()

func generate_chord_progression(config: Dictionary):
	var frequencies = config["frequencies"]
	var duration = config["duration"]
	
	for i in range(frequencies.size()):
		var chord_delay = i * duration
		call_deferred("_play_chord", frequencies[i], duration, chord_delay)

func _play_chord(freqs: Array, duration: float, delay: float):
	await get_tree().create_timer(delay).timeout
	
	# Play multiple frequencies simultaneously
	var players = []
	for freq in freqs:
		var player = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
		
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = 44100.0
		stream.buffer_length = duration
		player.stream = stream
		player.volume_db = -10  # Quieter for multiple tones
		
		player.play()
		
		# Generate tone
		var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
		if generator:
			var chunk = PackedFloat32Array()
			var samples = int(44100 * duration)
			
			for i in range(samples):
				var t = float(i) / 44100.0
				var sample = sin(2.0 * PI * freq * t) * 0.3
				chunk.append(sample)
			
			generator.push_buffer(chunk)
	
	# Clean up all players
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration + 0.1
	timer.one_shot = true
	timer.timeout.connect(_cleanup_players.bind(players, timer))
	timer.start()

func generate_noise_burst(config: Dictionary):
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = config["duration"]
	player.stream = stream
	player.volume_db = -15  # Quieter for noise
	
	player.play()
	
	# Generate white noise
	var generator = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if generator:
		var chunk = PackedFloat32Array()
		var samples = int(44100 * config["duration"])
		var amplitude = config.get("amplitude", 0.3)
		
		for i in range(samples):
			var noise = (randf() * 2.0 - 1.0) * amplitude
			chunk.append(noise)
		
		generator.push_buffer(chunk)
	
	# Clean up
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = config["duration"] + 0.1
	timer.one_shot = true
	timer.timeout.connect(_cleanup_player.bind(player, timer))
	timer.start()

func _cleanup_player(player: AudioStreamPlayer, timer: Timer):
	if player:
		player.stop()
		player.queue_free()
	if timer:
		timer.queue_free()

func _cleanup_players(players: Array, timer: Timer):
	for player in players:
		if player:
			player.stop()
			player.queue_free()
	if timer:
		timer.queue_free()

# Keyboard shortcuts for quick testing
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_demo_button_pressed(0)
			KEY_2:
				_on_demo_button_pressed(1)
			KEY_3:
				_on_demo_button_pressed(2)
			KEY_4:
				_on_demo_button_pressed(3)
