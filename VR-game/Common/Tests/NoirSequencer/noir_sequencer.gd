extends Control

# Constants
const ROWS = 8
const COLS = 16
const CELL_SIZE = Vector2(40, 40)
const CELL_MARGIN = Vector2(2, 2)

# Noir scale notes (with octaves)
var noir_notes = ["A#4", "G4", "F4", "D#4", "D4", "C4", "A#3", "G3"]
var note_frequencies = {
	"A#3": 233.08, "G3": 196.00,
	"C4": 261.63, "D4": 293.66, "D#4": 311.13, 
	"F4": 349.23, "G4": 392.00, "A#4": 466.16
}

# Sequencer variables
var grid = []
var current_step = -1
var is_playing = false
var bpm = 90
var step_time = 60.0 / bpm / 4.0  # Time per 16th note
var elapsed_time = 0.0

# Audio
var audio_streams = {}
var audio_players = []
var audio_initialized = false

# UI References
@onready var play_button = $ControlPanel/PlayButton
@onready var init_audio_button = $ControlPanel/InitAudioButton
@onready var clear_button = $ControlPanel/ClearButton
@onready var random_button = $ControlPanel/RandomButton
@onready var bpm_slider = $ControlPanel/VBoxContainer/BPMSlider
@onready var bpm_label = $ControlPanel/VBoxContainer/BPMLabel
@onready var status_label = $StatusPanel/StatusLabel
@onready var grid_container = $GridContainer
@onready var test_sound_button = $ControlPanel/TestSoundButton

func _ready():
	# Initialize the grid
	initialize_grid()
	
	# Create grid UI
	create_grid_ui()
	
	# Connect signals
	play_button.pressed.connect(_on_play_button_pressed)
	init_audio_button.pressed.connect(_on_init_audio_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	random_button.pressed.connect(_on_random_button_pressed)
	test_sound_button.pressed.connect(_on_test_sound_button_pressed)
	bpm_slider.value_changed.connect(_on_bpm_slider_changed)
	
	# Create simple tone generator (ultimate fallback)
	create_tone_generator()
	
	# Initial UI state
	play_button.disabled = true
	test_sound_button.disabled = true
	update_bpm_label()
	set_status("Click 'Initialize Audio' to start")
	
# Simple tone generator as ultimate fallback
var tone_generator = null

func create_tone_generator():
	# Create a simple AudioStreamPlayer
	tone_generator = AudioStreamPlayer.new()
	add_child(tone_generator)
	
	# We'll create the stream on demand when needed

func initialize_grid():
	grid = []
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			row.append(false)
		grid.append(row)

func create_grid_ui():
	# Create note labels
	var label_container = HBoxContainer.new()
	grid_container.add_child(label_container)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(80, CELL_SIZE.y)
	label_container.add_child(spacer)
	
	var step_labels = HBoxContainer.new()
	#step_labels.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
	label_container.add_child(step_labels)
	
	for c in range(COLS):
		var label = Label.new()
		label.text = str(c + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		#label.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		step_labels.add_child(label)
	
	# Create grid cells
	for r in range(ROWS):
		var row_container = HBoxContainer.new()
		grid_container.add_child(row_container)
		
		# Note label
		var note_label = Button.new()
		note_label.text = noir_notes[r]
		note_label.custom_minimum_size = Vector2(80, CELL_SIZE.y)
		note_label.pressed.connect(_on_note_label_pressed.bind(r))
		note_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		note_label.add_theme_font_size_override("font_size", 14)
		row_container.add_child(note_label)
		
		# Cell container
		var cells = HBoxContainer.new()
		#cells.size_flags_horizontal = Control.SIZE_FLAGS_EXPAND_FILL
		row_container.add_child(cells)
		
		for c in range(COLS):
			var cell = Button.new()
			cell.toggle_mode = true
			cell.custom_minimum_size = CELL_SIZE
			cell.pressed.connect(_on_cell_toggled.bind(r, c))
			cell.add_theme_stylebox_override("normal", create_cell_style(false, false))
			cell.add_theme_stylebox_override("pressed", create_cell_style(true, false))
			cell.add_theme_stylebox_override("hover", create_cell_style(false, true))
			cell.add_theme_stylebox_override("pressed_hover", create_cell_style(true, true))
			cells.add_child(cell)

func create_cell_style(active, hover):
	var style = StyleBoxFlat.new()
	
	if active:
		style.bg_color = Color(0.8, 0.8, 0.8)
		if hover:
			style.bg_color = Color(0.9, 0.9, 0.9)
	else:
		style.bg_color = Color(0.2, 0.2, 0.2)
		if hover:
			style.bg_color = Color(0.3, 0.3, 0.3)
	
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	
	return style

func initialize_audio():
	# Print audio diagnostic information
	print("=== AUDIO DIAGNOSTIC INFO ===")
	print("Default bus count: ", AudioServer.get_bus_count())
	print("Speaker mode: ", AudioServer.get_speaker_mode())
	print("Mix rate: ", AudioServer.get_mix_rate())
	print("Output device count: ", AudioServer.get_output_device_list().size())
	print("Output devices: ", AudioServer.get_output_device_list())
	print("Current device: ", AudioServer.get_output_device())
	print("============================")
	
	# Make sure we clean up any previous audio players
	for player in audio_players:
		if is_instance_valid(player):
			player.queue_free()
	audio_players.clear()
	audio_streams.clear()
	
	# Create audio players with longer buffer for stability
	for i in range(16):  # Create a pool of players
		# Create a sin wave oscillator
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = 44100
		stream.buffer_length = 0.5  # Increase buffer length for stability
		
		# Create audio player with higher volume
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = 0.0  # Increase volume to maximum
		add_child(player)
		audio_players.append(player)
		
		# Ensure stream is ready
		await get_tree().process_frame
	
	# Add some reverb effect with less wet mix
	var reverb = AudioEffectReverb.new()
	reverb.wet = 0.3  # Reduce wet mix to make dry signal louder
	reverb.room_size = 0.6
	reverb.damping = 0.2
	
	# Check if bus already exists
	var reverb_bus_idx = -1
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.get_bus_name(i) == "ReverbBus":
			reverb_bus_idx = i
			break
	
	# Create bus if needed
	if reverb_bus_idx == -1:
		reverb_bus_idx = AudioServer.get_bus_count()
		AudioServer.add_bus(reverb_bus_idx)
		AudioServer.set_bus_name(reverb_bus_idx, "ReverbBus")
		AudioServer.add_bus_effect(reverb_bus_idx, reverb)
	
	for player in audio_players:
		player.bus = "ReverbBus"
		
		# Try to pre-initialize playback
		var playback = player.get_stream_playback()
		if playback != null:
			var buffer = playback.get_buffer(1024)
			for i in range(buffer.size()):
				buffer[i] = Vector2.ZERO
			playback.push_buffer(buffer)
	
	# Map all notes to frequencies
	for note in noir_notes:
		if not note in note_frequencies:
			# Calculate frequency if not already in dictionary
			var base_note = note.substr(0, note.length() - 1)
			var octave = int(note.substr(note.length() - 1, 1))
			# This is a simplified calculation - in a real app, use a proper formula
			var base_freq = 440.0  # A4
			note_frequencies[note] = base_freq  # This is simplified
	
	audio_initialized = true
	play_button.disabled = false
	test_sound_button.disabled = false
	set_status("Audio initialized! Now click 'Play'")
	
	# Wait a moment before testing sound
	await get_tree().create_timer(0.5).timeout
	
	# Test sound
	play_note("C4")

# Fallback audio system
var fallback_audio_players = {}
var using_fallback = false

func setup_fallback_audio():
	# Create fallback audio players using AudioStreamGeneratorPlayback
	for note in noir_notes:
		# Create a new AudioStreamPlayer for each note
		var player = AudioStreamPlayer.new()
		
		# Create a simple OscillatorAudioStream (no envelope, just a basic tone)
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = 44100
		stream.buffer_length = 0.2
		
		player.stream = stream
		player.volume_db = -15
		add_child(player)
		
		fallback_audio_players[note] = player
	
	print("Fallback audio system initialized")

func play_note(note_name):
	if not audio_initialized:
		return
	
	# Check if note exists in frequency table
	if not note_name in note_frequencies:
		print("Note not found in frequency table: ", note_name)
		return
	
	var freq = note_frequencies[note_name]
	
	# Try primary audio system first
	if not using_fallback:
		if try_play_note_primary(note_name, freq) == false:
			# If primary fails, switch to fallback
			print("Primary audio system failed, switching to fallback")
			using_fallback = true
	
	# If using fallback or primary failed
	if using_fallback:
		play_note_fallback(note_name, freq)

func try_play_note_primary(note_name, freq):
	var amp = 0.5
	var attack = 0.05
	var release = 0.7
	
	# Find an available player
	var player = null
	for p in audio_players:
		if not p.playing:
			player = p
			break
	
	if player == null:
		print("No available audio players")
		return false
	
	# Generate audio data - with null check
	var playback = player.get_stream_playback()
	if playback == null:
		print("Error: Audio playback is null")
		return false
	
	var buffer_size = int(44100 * 0.2)  # 0.2 seconds of audio
	var buffer = playback.get_buffer(buffer_size)
	
	if buffer.size() == 0:
		print("Error: Audio buffer size is 0")
		return false
	
	var phase = 0.0
	var sample_rate = 44100.0
	var samples = buffer.size()
	
	# Attack-release envelope
	var envelope = 0.0
	var release_start = int(samples * 0.3)  # Start release at 30% of the note
	
	for i in range(samples):
		# Calculate envelope (simple AR envelope)
		if i < attack * sample_rate:
			envelope = float(i) / (attack * sample_rate)
		elif i > release_start:
			var release_phase = float(i - release_start) / ((samples - release_start))
			envelope = max(0.0, 1.0 - release_phase)
		else:
			envelope = 1.0
		
		# Calculate sine wave
		var sample = sin(phase) * amp * envelope
		
		# Stereo output (left, right)
		buffer[i] = Vector2(sample, sample)
		
		# Advance phase
		phase += 2.0 * PI * freq / sample_rate
		while phase > 2.0 * PI:
			phase -= 2.0 * PI
	
	# Try/catch to handle any potential errors

	playback.push_buffer(buffer)
	player.play()
	return true


func play_note_fallback(note_name, freq):
	# Use the fallback system
	if not note_name in fallback_audio_players:
		print("Note not found in fallback players: ", note_name)
		return
	
	var player = fallback_audio_players[note_name]
	
	# Create a simple sine wave in the buffer
	var playback = player.get_stream_playback()
	if playback == null:
		print("Fallback playback is null for note: ", note_name)
		return
	
	var buffer = playback.get_buffer(2048)
	var phase = 0.0
	
	for i in range(buffer.size()):
		var sample = sin(phase) * 0.5
		buffer[i] = Vector2(sample, sample)
		phase += TAU * freq / 44100.0
		if phase > TAU:
			phase -= TAU
	
	playback.push_buffer(buffer)
	
	# Start playing
	if player.playing:
		player.stop()
	player.play()

func _process(delta):
	if is_playing:
		elapsed_time += delta
		
		if elapsed_time >= step_time:
			elapsed_time -= step_time
			advance_step()



func update_step_indicator():
	# Update visual indicator for current step
	for r in range(ROWS):
		var row_container = grid_container.get_child(r + 1)  # +1 because first child is the label row
		var cells = row_container.get_child(1)
		
		for c in range(COLS):
			var cell = cells.get_child(c)
			var style = null
			
			if c == current_step and is_playing:
				if grid[r][c]:
					style = create_active_cell_style(true)
				else:
					style = create_active_cell_style(false)
				cell.add_theme_stylebox_override("normal", style)
				cell.add_theme_stylebox_override("pressed", style)
			else:
				cell.add_theme_stylebox_override("normal", create_cell_style(false, false))
				cell.add_theme_stylebox_override("pressed", create_cell_style(true, false))

func create_active_cell_style(active):
	var style = StyleBoxFlat.new()
	
	if active:
		style.bg_color = Color(0.9, 0.3, 0.3)
	else:
		style.bg_color = Color(0.4, 0.2, 0.2)
	
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	
	return style

func update_bpm_label():
	bpm_label.text = str(bpm)
	step_time = 60.0 / bpm / 4.0  # Time per 16th note

func set_status(message):
	status_label.text = message

func _on_cell_toggled(row, col):
	grid[row][col] = not grid[row][col]
	
	# If active and sequencer is stopped, play the note for feedback
	if grid[row][col] and not is_playing and audio_initialized:
		play_note(noir_notes[row])




func _on_init_audio_button_pressed():
	if not audio_initialized:
		set_status("Initializing audio...")
		
		# First, test if basic audio works at all
		test_basic_audio()
		
		# Then initialize the main system
		initialize_audio()
		init_audio_button.disabled = true
		
		# Add a fallback method
		setup_fallback_audio()

# Simple test to see if any audio works
func test_basic_audio():
	# Create a simple AudioStreamPlayer with a standard sound
	var test_player = AudioStreamPlayer.new()
	add_child(test_player)
	
	# Create a simple sine wave sound
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 1.0  # 1 second
	
	test_player.stream = stream
	test_player.volume_db = 0.0  # Full volume
	test_player.autoplay = true
	
	# Get stream playback
	await get_tree().process_frame
	var playback = test_player.get_stream_playback()
	
	if playback != null:
		# Fill buffer with a simple tone
		var buffer = playback.get_buffer(44100)
		for i in range(buffer.size()):
			var sample = sin(i * 0.1) * 0.8  # Very audible tone
			buffer[i] = Vector2(sample, sample)
		
		playback.push_buffer(buffer)
		
		print("Basic audio test started - you should hear a 1-second tone")
		set_status("Testing basic audio...")
	
	# Clean up after 2 seconds
	await get_tree().create_timer(2.0).timeout
	test_player.queue_free()

func _on_clear_button_pressed():
	initialize_grid()
	
	# Update UI
	for r in range(ROWS):
		var row_container = grid_container.get_child(r + 1)
		var cells = row_container.get_child(1)
		
		for c in range(COLS):
			var cell = cells.get_child(c)
			cell.button_pressed = false

func _on_random_button_pressed():
	for r in range(ROWS):
		for c in range(COLS):
			# 20% chance of a cell being active
			grid[r][c] = randf() < 0.2
	
	# Update UI
	for r in range(ROWS):
		var row_container = grid_container.get_child(r + 1)
		var cells = row_container.get_child(1)
		
		for c in range(COLS):
			var cell = cells.get_child(c)
			cell.button_pressed = grid[r][c]

func _on_bpm_slider_changed(value):
	bpm = value
	update_bpm_label()

func _on_test_sound_button_pressed():
	# First test direct audio output
	test_direct_output()
	
	# Then try the normal methods
	if audio_initialized:
		play_note("C4") 
		set_status("Testing normal sound...")
	else:
		# Use simple tone as fallback
		play_simple_tone(440) # A4
		set_status("Testing simple tone...")

# Direct audio test bypassing all systems
func test_direct_output():
	# Create a simple AudioStreamPlayer
	var direct_player = AudioStreamPlayer.new()
	add_child(direct_player)
	
	# Create a simple tone using AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = 44100
	
	# Generate 1 second of a loud 440Hz tone
	var sample_rate = 44100
	var sample_count = sample_rate
	var data = PackedByteArray()
	data.resize(sample_count * 4)  # 16-bit stereo
	
	for i in range(sample_count):
		var sample = sin(i * 0.1) * 0.9  # Very loud tone
		var sample_int = int(sample * 32767)
		
		var position = i * 4
		data[position] = sample_int & 0xFF
		data[position + 1] = (sample_int >> 8) & 0xFF
		data[position + 2] = sample_int & 0xFF
		data[position + 3] = (sample_int >> 8) & 0xFF
	
	stream.data = data
	
	# Set up player and play
	direct_player.stream = stream
	direct_player.volume_db = 6.0  # Extra loud
	direct_player.bus = "Master"  # Use Master bus directly
	direct_player.play()
	
	print("Direct audio test playing - 1 second tone")
	set_status("Testing direct audio output...")
	
	# Clean up after 2 seconds
	await get_tree().create_timer(2.0).timeout
	direct_player.queue_free()

# Ultimate fallback - use a simple tone
func play_simple_tone(frequency):
	# Create a simple sine wave tone
	var sample_rate = 44100.0
	var sample_count = int(sample_rate * 0.5) # 0.5 seconds
	
	# Create PCM data for the tone
	var pcm_data = PackedByteArray()
	pcm_data.resize(sample_count * 4) # 16-bit stereo = 4 bytes per sample
	
	var amplitude = 0.5
	var phase = 0.0
	var phase_increment = frequency / sample_rate * TAU
	
	for i in range(sample_count):
		var sample = sin(phase) * amplitude
		
		# Apply a simple envelope
		if i < sample_rate * 0.05:  # Attack: first 0.05 seconds
			sample *= i / (sample_rate * 0.05)
		elif i > sample_count - sample_rate * 0.1:  # Release: last 0.1 seconds
			sample *= (sample_count - i) / (sample_rate * 0.1)
		
		# Convert to 16-bit and add to PCM data (stereo)
		var sample_int = int(sample * 32767.0)
		
		# Write sample to left and right channels (little endian)
		var position = i * 4
		pcm_data[position] = sample_int & 0xFF
		pcm_data[position + 1] = (sample_int >> 8) & 0xFF
		pcm_data[position + 2] = sample_int & 0xFF
		pcm_data[position + 3] = (sample_int >> 8) & 0xFF
		
		phase += phase_increment
		if phase > TAU:
			phase -= TAU
	
	# Create audio stream from PCM data
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = sample_rate
	stream.data = pcm_data
	
	# Play the tone
	if tone_generator.playing:
		tone_generator.stop()
	
	tone_generator.stream = stream
	tone_generator.play()

func _on_note_label_pressed(row):
	if audio_initialized:
		play_note(noir_notes[row])
		set_status("Playing note: " + noir_notes[row])


func advance_step():
	current_step = (current_step + 1) % COLS
	update_step_indicator()
	
	# Debug information
	print("Step: ", current_step)
	
	# Play active notes for this step with enhanced error handling
	for r in range(ROWS):
		if grid[r][current_step]:
			print("Playing note: ", noir_notes[r], " at step ", current_step)
			
			# Try multiple sound generation methods
			# 1. First try direct audio for this step
			test_direct_output_for_note(noir_notes[r])
			
			# 2. Then try the regular method
			if audio_initialized:
				play_note(noir_notes[r])

# Add this new function
func test_direct_output_for_note(note_name):
	# Get frequency for the note
	var freq = note_frequencies[note_name]
	
	# Create a simple AudioStreamPlayer
	var direct_player = AudioStreamPlayer.new()
	add_child(direct_player)
	
	# Create a simple tone using AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = 44100
	
	# Generate 0.2 seconds of the note
	var sample_rate = 44100
	var sample_count = int(sample_rate * 0.2)
	var data = PackedByteArray()
	data.resize(sample_count * 4)  # 16-bit stereo
	
	var phase = 0.0
	
	for i in range(sample_count):
		# Apply simple envelope
		var envelope = 1.0
		if i < sample_rate * 0.01:  # Attack: first 0.01 seconds
			envelope = i / (sample_rate * 0.01)
		elif i > sample_count - sample_rate * 0.05:  # Release: last 0.05 seconds
			envelope = (sample_count - i) / (sample_rate * 0.05)
		
		var sample = sin(phase) * 0.9 * envelope  # Loud tone with envelope
		var sample_int = int(sample * 32767)
		
		var position = i * 4
		data[position] = sample_int & 0xFF
		data[position + 1] = (sample_int >> 8) & 0xFF
		data[position + 2] = sample_int & 0xFF
		data[position + 3] = (sample_int >> 8) & 0xFF
		
		phase += TAU * freq / sample_rate
		if phase > TAU:
			phase -= TAU
	
	stream.data = data
	
	# Set up player and play
	direct_player.stream = stream
	direct_player.volume_db = 0.0  # Normal volume
	direct_player.bus = "Master"  # Use Master bus directly
	direct_player.play()
	
	# Set up automatic cleanup
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	direct_player.queue_free()

# Also modify _on_play_button_pressed to reset the sequencer more effectively
func _on_play_button_pressed():
	if not audio_initialized:
		set_status("Please initialize audio first")
		return
	
	is_playing = not is_playing
	
	if is_playing:
		play_button.text = "Stop"
		set_status("Sequencer playing")
		
		# Play a test sound to kickstart audio
		test_direct_output()
		
		# Reset timing
		elapsed_time = 0.0
		current_step = -1  # Start from beginning
		
		# Force first step immediately
		advance_step()
	else:
		play_button.text = "Play"
		set_status("Sequencer stopped")
		current_step = -1
		update_step_indicator()
