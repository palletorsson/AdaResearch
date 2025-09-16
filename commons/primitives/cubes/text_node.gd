extends Node3D

# Queer manifesto text that emits letter by letter
@export_multiline var manifesto_text: String = """We are the spectrum of possibility, refusing the narrow confines of convention. Our existence is rebellion, our love is revolution. In a world that demands we choose binary boxes, we choose fluidity, multiplicity, the beautiful complexity of authentic being.

We claim space not as begged permission but as birthright. Every street corner, every workplace, every family dinner table becomes territory where we plant flags of visibility. Our very presence rewrites the rules, expands the definitions, makes room for futures yet unimagined.

Love is our weapon against hate. Joy is our resistance to oppression. We dance in the face of discrimination, we celebrate in spite of shame imposed by others. Our communities are chosen families, our chosen families are revolution in action.

We honor those who came before - the rebels, the bridge-builders, the ones who threw the first brick and the ones who built the first safe spaces. We carry their courage forward while writing new chapters of possibility.

Today we exist. Tomorrow we thrive. Always we love boldly, live authentically, and refuse to be erased."""

# Emission settings
@export var emission_rate: float = 10.0      # Letters per second (set to 10 as requested)
@export var letter_lifetime: float = 10.0    # How long letters stay visible
@export var fade_duration: float = 2.0       # How long fade-out takes
@export var auto_start: bool = true          # Start emitting automatically

# Positioning and movement - NO MOVEMENT
@export var emission_area: Vector3 = Vector3(10, 5, 10)  # Area to emit letters in
@export var center_position: Vector3 = Vector3(0, 2, 0)  # Center of emission area
@export var float_speed: float = 0.0         # NO MOVEMENT - letters stay exactly where they spawn

# Visual settings
@export var letter_font_size: int = 48
@export var use_dingbats: bool = true  # Enable dingbats font
@export var dingbats_font: FontFile  # Assign a dingbats font resource here
@export var letter_colors: Array[Color] = [
	Color.MAGENTA,
	Color.CYAN, 
	Color.YELLOW,
	Color.HOT_PINK,
	Color.LIME,
	Color.ORANGE
]

# Text emission control
var current_char_index: int = 0
var emitted_letters: Array[Dictionary] = []
var is_emitting: bool = false
var emission_timer: float = 0.0

# Movement tracking
var last_position: Vector3
var is_moving: bool = false
var movement_threshold: float = 0.1  # Minimum movement to trigger emission (adjusted for 0-6 range)
var y_movement: float = 0.0  # Track Y-axis movement for jazz modulation
var jazz_intensity: float = 0.0  # Current jazz intensity based on Y movement
var x_movement: float = 0.0  # Track X-axis movement for melody navigation
var z_movement: float = 0.0  # Track Z-axis movement for Moonlight Sonata navigation

# Für Elise melody tracking
var fur_elise_notes: Array[float] = []  # Für Elise melody notes (frequencies)
var fur_elise_durations: Array[float] = []  # Note durations
var fur_elise_current_note: int = 0  # Current note index
var fur_elise_note_timer: float = 0.0  # Timer for current note
var fur_elise_playing: bool = false  # Is melody currently playing
var fur_elise_manual_navigation: bool = false  # Track if user is manually navigating

# Moonlight Sonata melody tracking
var moonlight_notes: Array[float] = []  # Moonlight Sonata melody notes (frequencies)
var moonlight_durations: Array[float] = []  # Note durations
var moonlight_current_note: int = 0  # Current note index
var moonlight_note_timer: float = 0.0  # Timer for current note
var moonlight_playing: bool = false  # Is melody currently playing
var moonlight_manual_navigation: bool = false  # Track if user is manually navigating

# Audio settings
@export var bell_sound: AudioStream  # Assign a bell sound resource here
@export var bell_volume: float = 0.5  # Volume of the bell sound
@export var bell_pitch_range: Vector2 = Vector2(0.8, 1.2)  # Pitch variation range
var audio_player: AudioStreamPlayer3D

# Audio synthesis settings
@export var synthesize_bell: bool = true
@export var bell_frequency: float = 440.0    # A4 note for jazz foundation
@export var bell_decay: float = 1.5          # Longer decay for jazz feel
@export var bell_harmonics: int = 5          # More harmonics for jazz richness

# Jazz-specific settings
@export var jazz_swing: float = 0.7          # Swing feel (0.5 = straight, 0.7 = swing)
@export var jazz_blue_notes: bool = true     # Add blue note intervals
@export var jazz_vibrato: float = 0.1        # Vibrato depth
@export var y_movement_sensitivity: float = 1.0  # How much Y movement affects jazziness (range 0-3)
@export var play_fur_elise: bool = true          # Play Für Elise melody
@export var fur_elise_speed: float = 1.0         # Melody playback speed
@export var x_movement_sensitivity: float = 5.0  # How much X movement affects melody position (range 0-6)
@export var z_movement_sensitivity: float = 5.0  # How much Z movement affects Moonlight Sonata position (range 0-6)
@export var play_moonlight_sonata: bool = true   # Play Moonlight Sonata melody
@export var moonlight_speed: float = 0.8         # Moonlight Sonata playback speed (slower, more contemplative)

# Pre-generated audio cache
var bell_sound_cache: Array[AudioStreamWAV] = []
var cache_size: int = 10  # Pre-generate 10 different bell sounds

# Performance optimization
@export var max_visible_letters: int = 100  # Reduced for better performance
@export var cleanup_frequency: float = 0.5  # More frequent cleanup
@export var emission_batch_size: int = 3  # Process multiple letters at once
var cleanup_timer: float = 0.0
var emission_batch_timer: float = 0.0
var pending_emissions: int = 0

func _ready():
	# Clean up the manifesto text
	manifesto_text = manifesto_text.strip_edges()
	
	# Initialize movement tracking
	last_position = global_position
	
	# Setup audio player
	setup_audio()
	
	# Initialize melodies
	initialize_fur_elise()
	initialize_moonlight_sonata()
	
	if auto_start:
		start_emission()
	
	print("Text emission system ready!")
	print("Emission rate: Set to 10 letters per second")
	print("Movement-based emission: Only emits letters when $" + "." + " moves")
	print("Bell sound: Plays when movement starts (with pitch variation)")
	print("Dingbats font: Characters converted to only dots (.) and circles (o)")
	print("No movement: Letters stay exactly where they spawn (at the $" + "." + " location)")
	print("Global scene: Letters are added to the global scene, so they don't follow the emitter if it moves")
	print("Static letters: No rotation or position changes - they just fade in and out")
	print("Press SPACE to toggle emission")
	print("Press R to reset to beginning")
	print("Press C to clear all letters")

func _process(delta):
	# Check for movement
	check_movement()
	
	# Update melodies
	update_fur_elise(delta)
	update_moonlight_sonata(delta)
	
	if is_emitting and is_moving:
		handle_letter_emission(delta)
	
	update_existing_letters(delta)
	cleanup_old_letters(delta)

func setup_audio():
	# Create 3D audio player for bell sound
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "BellAudioPlayer"
	audio_player.volume_db = linear_to_db(bell_volume)
	audio_player.max_distance = 20.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(audio_player)
	
	# Pre-generate bell sound cache for better performance
	if synthesize_bell:
		generate_bell_cache()
		bell_sound = bell_sound_cache[0]  # Use first cached sound as default
		audio_player.stream = bell_sound
	elif bell_sound:
		audio_player.stream = bell_sound

func generate_bell_cache():
	# Pre-generate multiple jazz bell sounds with different intensities
	print("Pre-generating jazzy bell sound cache...")
	bell_sound_cache.clear()
	
	for i in range(cache_size):
		# Vary both pitch and jazz intensity
		var pitch_variation = lerp(bell_pitch_range.x, bell_pitch_range.y, float(i) / float(cache_size - 1))
		var jazz_variation = float(i) / float(cache_size - 1)  # 0.0 to 1.0
		
		var original_freq = bell_frequency
		var original_jazz = jazz_intensity
		
		bell_frequency = 440.0 * pitch_variation  # A4 base note
		jazz_intensity = jazz_variation  # Set jazz intensity for this cache entry
		
		var cached_sound = generate_bell_sound()
		bell_sound_cache.append(cached_sound)
		
		# Restore original values
		bell_frequency = original_freq
		jazz_intensity = original_jazz
	
	print("Jazzy bell sound cache generated: ", bell_sound_cache.size(), " sounds")

func check_movement():
	# Check if the node has moved since last frame
	var current_position = global_position
	var distance_moved = current_position.distance_to(last_position)
	
	# Track Y-axis movement for jazz modulation (range 0-3)
	var y_delta = current_position.y - last_position.y
	y_movement += abs(y_delta) * y_movement_sensitivity
	y_movement = clamp(y_movement, 0.0, 1.0)  # Clamp to 0-1 range
	
	# Track X-axis movement for melody navigation (range 0-6)
	var x_delta = current_position.x - last_position.x
	x_movement += x_delta * x_movement_sensitivity
	
	# Track Z-axis movement for Moonlight Sonata navigation (range 0-6)
	var z_delta = current_position.z - last_position.z
	z_movement += z_delta * z_movement_sensitivity
	
	# Calculate jazz intensity based on Y movement
	jazz_intensity = y_movement
	
	# Decay Y movement over time
	y_movement *= 0.95
	
	# Update melody position based on X movement
	update_melody_position_from_x_movement()
	
	# Update Moonlight Sonata position based on Z movement
	update_moonlight_position_from_z_movement()
	
	# Check if movement state changed
	var was_moving = is_moving
	is_moving = distance_moved > movement_threshold
	
	# Debug movement detection
	if distance_moved > 0.001:  # Only print if there's any movement
		print("DEBUG: Distance moved: ", distance_moved, " Y(0-3): ", y_delta, " X(0-6): ", x_delta, " Z(0-6): ", z_delta, " Jazz intensity: ", jazz_intensity)
	
	# Play bell sound and start melodies when starting to move
	if not was_moving and is_moving:
		print("DEBUG: Movement started - playing jazzy bell sound, Für Elise, and Moonlight Sonata")
		play_bell_sound()
		start_fur_elise()
		start_moonlight_sonata()
	
	# Update last position
	last_position = current_position

func generate_bell_sound() -> AudioStreamWAV:
	# Use lower sample rate for better performance
	var sample_rate = 22050
	var duration = bell_decay
	var sample_count = int(sample_rate * duration)
	
	# Generate 16-bit samples
	var samples = PackedByteArray()
	samples.resize(sample_count * 2)  # 2 bytes per 16-bit sample
	
	# Pre-calculate values for better performance
	var t_step = 1.0 / float(sample_rate)
	var decay_factor = 1.5  # Slower decay for jazz feel
	
	# Jazz chord progression (major 7th, minor 7th, dominant 7th)
	var jazz_chords = [
		[1.0, 1.25, 1.5, 1.875],  # Cmaj7: C-E-G-B
		[1.0, 1.2, 1.5, 1.8],     # Cm7: C-Eb-G-Bb  
		[1.0, 1.25, 1.5, 1.75],   # C7: C-E-G-Bb
		[1.0, 1.2, 1.4, 1.8]      # Cm6: C-Eb-G-A
	]
	
	# Select chord based on jazz intensity
	var chord_index = int(jazz_intensity * (jazz_chords.size() - 1))
	var current_chord = jazz_chords[chord_index]
	
	for i in range(sample_count):
		var t = float(i) * t_step
		var amplitude = exp(-t * decay_factor)  # Exponential decay
		
		var sample_value = 0.0
		
		# Generate jazz chord tones
		for chord_tone in current_chord:
			var freq = bell_frequency * chord_tone
			var harmonic_amplitude = amplitude * 0.3
			
			# Add swing feel (off-beat emphasis)
			var swing_factor = 1.0
			if int(t * 4) % 2 == 1:  # Off-beats
				swing_factor = jazz_swing
			
			# Add vibrato for jazz expression
			var vibrato = sin(t * 6.0 * TAU) * jazz_vibrato * jazz_intensity
			freq *= (1.0 + vibrato)
			
			sample_value += sin(t * freq * TAU) * harmonic_amplitude * swing_factor
		
		# Add blue notes for jazz flavor
		if jazz_blue_notes and jazz_intensity > 0.3:
			var blue_note_freq = bell_frequency * 1.4  # Minor 3rd (blue note)
			sample_value += sin(t * blue_note_freq * TAU) * amplitude * 0.2 * jazz_intensity
		
		# Add jazz "crunch" (slight distortion)
		if jazz_intensity > 0.5:
			sample_value = tanh(sample_value * (1.0 + jazz_intensity * 0.5))
		
		# Add swing rhythm pattern
		var rhythm_factor = 1.0
		var beat_position = fmod(t * 2.0, 1.0)  # 2 beats per second
		if beat_position > jazz_swing:
			rhythm_factor = 0.3  # Quieter on off-beats
		
		# Normalize and apply envelope
		sample_value *= 0.4 * rhythm_factor  # Overall volume
		sample_value = clamp(sample_value, -1.0, 1.0)
		
		# Convert to 16-bit integer
		var sample_16bit = int(sample_value * 32767)
		
		# Pack as little-endian 16-bit
		samples[i * 2] = sample_16bit & 0xFF
		samples[i * 2 + 1] = (sample_16bit >> 8) & 0xFF
	
	# Create AudioStreamWAV
	var audio_stream = AudioStreamWAV.new()
	audio_stream.data = samples
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = sample_rate
	audio_stream.stereo = false
	
	return audio_stream

func get_harmonic_ratio(harmonic: int) -> float:
	# Bell harmonics are not perfect integer multiples
	# This creates the characteristic bell sound
	match harmonic:
		1: return 1.0      # Fundamental
		2: return 2.76     # First overtone
		3: return 5.40     # Second overtone  
		4: return 8.93     # Third overtone
		5: return 13.34    # Fourth overtone
		_: return float(harmonic) * 2.5

func play_bell_sound():
	if audio_player and (bell_sound or synthesize_bell):
		if synthesize_bell and bell_sound_cache.size() > 0:
			# Select sound based on jazz intensity (Y movement)
			var jazz_index = int(jazz_intensity * (bell_sound_cache.size() - 1))
			jazz_index = clamp(jazz_index, 0, bell_sound_cache.size() - 1)
			audio_player.stream = bell_sound_cache[jazz_index]
			
			print("DEBUG: Playing jazzy bell - intensity: ", jazz_intensity, " index: ", jazz_index)
		elif bell_sound:
			# Use pitch scaling for pre-recorded sound
			var pitch = randf_range(bell_pitch_range.x, bell_pitch_range.y)
			audio_player.pitch_scale = pitch
		
		# Play the bell sound
		audio_player.play()
		print("DEBUG: Jazzy bell sound played!")

func initialize_fur_elise():
	# Für Elise melody in frequencies (A4 = 440Hz as reference)
	# The famous opening: E-D#-E-D#-E-B-D-C-A
	fur_elise_notes = [
		659.25,  # E5
		622.25,  # D#5
		659.25,  # E5
		622.25,  # D#5
		659.25,  # E5
		493.88,  # B4
		523.25,  # C5
		440.00,  # A4
		659.25,  # E5
		622.25,  # D#5
		659.25,  # E5
		622.25,  # D#5
		659.25,  # E5
		493.88,  # B4
		523.25,  # C5
		440.00,  # A4
		523.25,  # C5
		493.88,  # B4
		440.00,  # A4
		392.00,  # G4
		440.00,  # A4
		493.88,  # B4
		523.25,  # C5
		587.33,  # D5
		659.25,  # E5
		622.25,  # D#5
		659.25,  # E5
		622.25,  # D#5
		659.25,  # E5
		493.88,  # B4
		523.25,  # C5
		440.00   # A4
	]
	
	# Note durations (in beats, will be scaled by speed)
	fur_elise_durations = [
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,  # First phrase
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,  # Second phrase
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,  # Third phrase
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5   # Fourth phrase
	]
	
	print("Für Elise melody initialized with ", fur_elise_notes.size(), " notes")

func start_fur_elise():
	if not play_fur_elise:
		return
		
	fur_elise_playing = true
	fur_elise_current_note = 0
	fur_elise_note_timer = 0.0
	print("Started Für Elise melody!")

func stop_fur_elise():
	fur_elise_playing = false
	print("Stopped Für Elise melody")

func update_fur_elise(delta: float):
	if not fur_elise_playing or fur_elise_notes.size() == 0:
		return
	
	# Only auto-advance if not manually navigating
	if not fur_elise_manual_navigation:
		fur_elise_note_timer += delta
		
		# Calculate note duration based on speed
		var note_duration = fur_elise_durations[fur_elise_current_note] / fur_elise_speed
		
		if fur_elise_note_timer >= note_duration:
			# Move to next note
			fur_elise_current_note += 1
			fur_elise_note_timer = 0.0
			
			# Check if melody is complete
			if fur_elise_current_note >= fur_elise_notes.size():
				fur_elise_playing = false
				print("Für Elise melody completed!")
				return
			
			# Play current note with jazz effects
			play_fur_elise_note()
	else:
		# Reset manual navigation flag after a short delay
		fur_elise_manual_navigation = false

func play_fur_elise_note():
	if fur_elise_current_note >= fur_elise_notes.size():
		return
	
	var base_frequency = fur_elise_notes[fur_elise_current_note]
	
	# Apply jazz modulation based on Y movement
	var jazz_frequency = base_frequency
	
	# Add vibrato
	if jazz_vibrato > 0:
		var vibrato_amount = sin(Time.get_ticks_msec() * 0.01) * jazz_vibrato * jazz_intensity
		jazz_frequency *= (1.0 + vibrato_amount)
	
	# Add blue note intervals occasionally
	if jazz_blue_notes and randf() < jazz_intensity * 0.3:
		jazz_frequency *= 1.4  # Minor 3rd (blue note)
	
	# Generate and play the note
	var note_sound = generate_fur_elise_note(jazz_frequency)
	if audio_player:
		audio_player.stream = note_sound
		audio_player.pitch_scale = 1.0  # No additional pitch scaling
		audio_player.play()
	
	print("Playing Für Elise note ", fur_elise_current_note + 1, "/", fur_elise_notes.size(), " - Frequency: ", jazz_frequency)

func generate_fur_elise_note(frequency: float) -> AudioStreamWAV:
	# Generate a single note with jazz characteristics
	var sample_rate = 22050
	var duration = 0.3  # Shorter duration for melody notes
	var sample_count = int(sample_rate * duration)
	
	var samples = PackedByteArray()
	samples.resize(sample_count * 2)
	
	var t_step = 1.0 / float(sample_rate)
	var decay_factor = 3.0  # Quick decay for melody notes
	
	for i in range(sample_count):
		var t = float(i) * t_step
		var amplitude = exp(-t * decay_factor)
		
		# Generate the note with jazz characteristics
		var sample_value = 0.0
		
		# Main frequency
		sample_value += sin(t * frequency * TAU) * amplitude * 0.6
		
		# Add harmonics for richness
		sample_value += sin(t * frequency * 2.0 * TAU) * amplitude * 0.2
		sample_value += sin(t * frequency * 3.0 * TAU) * amplitude * 0.1
		
		# Add jazz swing feel
		var swing_factor = 1.0
		if int(t * 4) % 2 == 1:  # Off-beats
			swing_factor = jazz_swing
		
		# Add jazz "crunch" based on intensity
		if jazz_intensity > 0.5:
			sample_value = tanh(sample_value * (1.0 + jazz_intensity * 0.3))
		
		sample_value *= swing_factor * 0.4
		sample_value = clamp(sample_value, -1.0, 1.0)
		
		# Convert to 16-bit integer
		var sample_16bit = int(sample_value * 32767)
		samples[i * 2] = sample_16bit & 0xFF
		samples[i * 2 + 1] = (sample_16bit >> 8) & 0xFF
	
	var audio_stream = AudioStreamWAV.new()
	audio_stream.data = samples
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = sample_rate
	audio_stream.stereo = false
	
	return audio_stream

func update_melody_position_from_x_movement():
	if not play_fur_elise or fur_elise_notes.size() == 0:
		return
	
	# Convert X movement to note position change
	# Positive X movement goes forward in melody, negative goes backward
	var note_change = int(x_movement)
	
	if note_change != 0:
		# Update current note position
		fur_elise_current_note += note_change
		
		# Clamp to valid range
		fur_elise_current_note = clamp(fur_elise_current_note, 0, fur_elise_notes.size() - 1)
		
		# Reset note timer when jumping to new position
		fur_elise_note_timer = 0.0
		
		# Set manual navigation flag
		fur_elise_manual_navigation = true
		
		# Play the note at the new position
		play_fur_elise_note()
		
		print("DEBUG: Melody position changed by ", note_change, " - Now at note ", fur_elise_current_note + 1, "/", fur_elise_notes.size())
		
		# Reset X movement accumulation
		x_movement = 0.0

func initialize_moonlight_sonata():
	# Moonlight Sonata 1st movement opening melody in frequencies
	# The famous arpeggiated C# minor theme
	moonlight_notes = [
		277.18,  # C#3
		311.13,  # D#3
		369.99,  # F#3
		415.30,  # G#3
		277.18,  # C#3
		311.13,  # D#3
		369.99,  # F#3
		415.30,  # G#3
		277.18,  # C#3
		311.13,  # D#3
		369.99,  # F#3
		415.30,  # G#3
		277.18,  # C#3
		311.13,  # D#3
		369.99,  # F#3
		415.30,  # G#3
		220.00,  # A2
		246.94,  # B2
		277.18,  # C#3
		311.13,  # D#3
		220.00,  # A2
		246.94,  # B2
		277.18,  # C#3
		311.13,  # D#3
		220.00,  # A2
		246.94,  # B2
		277.18,  # C#3
		311.13,  # D#3
		220.00,  # A2
		246.94,  # B2
		277.18,  # C#3
		311.13   # D#3
	]
	
	# Note durations (longer, more contemplative)
	moonlight_durations = [
		1.0, 1.0, 1.0, 1.0,  # First arpeggio
		1.0, 1.0, 1.0, 1.0,  # Second arpeggio
		1.0, 1.0, 1.0, 1.0,  # Third arpeggio
		1.0, 1.0, 1.0, 1.0,  # Fourth arpeggio
		1.0, 1.0, 1.0, 1.0,  # Fifth arpeggio
		1.0, 1.0, 1.0, 1.0,  # Sixth arpeggio
		1.0, 1.0, 1.0, 1.0,  # Seventh arpeggio
		1.0, 1.0, 1.0, 1.0   # Eighth arpeggio
	]
	
	print("Moonlight Sonata melody initialized with ", moonlight_notes.size(), " notes")

func start_moonlight_sonata():
	if not play_moonlight_sonata:
		return
		
	moonlight_playing = true
	moonlight_current_note = 0
	moonlight_note_timer = 0.0
	print("Started Moonlight Sonata melody!")

func stop_moonlight_sonata():
	moonlight_playing = false
	print("Stopped Moonlight Sonata melody")

func update_moonlight_sonata(delta: float):
	if not moonlight_playing or moonlight_notes.size() == 0:
		return
	
	# Only auto-advance if not manually navigating
	if not moonlight_manual_navigation:
		moonlight_note_timer += delta
		
		# Calculate note duration based on speed
		var note_duration = moonlight_durations[moonlight_current_note] / moonlight_speed
		
		if moonlight_note_timer >= note_duration:
			# Move to next note
			moonlight_current_note += 1
			moonlight_note_timer = 0.0
			
			# Check if melody is complete
			if moonlight_current_note >= moonlight_notes.size():
				moonlight_playing = false
				print("Moonlight Sonata melody completed!")
				return
			
			# Play current note with jazz effects
			play_moonlight_note()
	else:
		# Reset manual navigation flag after a short delay
		moonlight_manual_navigation = false

func play_moonlight_note():
	if moonlight_current_note >= moonlight_notes.size():
		return
	
	var base_frequency = moonlight_notes[moonlight_current_note]
	
	# Apply jazz modulation based on Y movement
	var jazz_frequency = base_frequency
	
	# Add vibrato
	if jazz_vibrato > 0:
		var vibrato_amount = sin(Time.get_ticks_msec() * 0.01) * jazz_vibrato * jazz_intensity
		jazz_frequency *= (1.0 + vibrato_amount)
	
	# Add blue note intervals occasionally
	if jazz_blue_notes and randf() < jazz_intensity * 0.3:
		jazz_frequency *= 1.4  # Minor 3rd (blue note)
	
	# Generate and play the note
	var note_sound = generate_moonlight_note(jazz_frequency)
	if audio_player:
		audio_player.stream = note_sound
		audio_player.pitch_scale = 1.0  # No additional pitch scaling
		audio_player.play()
	
	print("Playing Moonlight note ", moonlight_current_note + 1, "/", moonlight_notes.size(), " - Frequency: ", jazz_frequency)

func generate_moonlight_note(frequency: float) -> AudioStreamWAV:
	# Generate a single note with jazz characteristics for Moonlight Sonata
	var sample_rate = 22050
	var duration = 0.8  # Longer duration for contemplative feel
	var sample_count = int(sample_rate * duration)
	
	var samples = PackedByteArray()
	samples.resize(sample_count * 2)
	
	var t_step = 1.0 / float(sample_rate)
	var decay_factor = 1.5  # Slower decay for sustained notes
	
	for i in range(sample_count):
		var t = float(i) * t_step
		var amplitude = exp(-t * decay_factor)
		
		# Generate the note with jazz characteristics
		var sample_value = 0.0
		
		# Main frequency
		sample_value += sin(t * frequency * TAU) * amplitude * 0.7
		
		# Add harmonics for richness
		sample_value += sin(t * frequency * 2.0 * TAU) * amplitude * 0.3
		sample_value += sin(t * frequency * 3.0 * TAU) * amplitude * 0.15
		sample_value += sin(t * frequency * 4.0 * TAU) * amplitude * 0.05
		
		# Add jazz swing feel
		var swing_factor = 1.0
		if int(t * 2) % 2 == 1:  # Off-beats (slower for Moonlight)
			swing_factor = jazz_swing
		
		# Add jazz "crunch" based on intensity
		if jazz_intensity > 0.5:
			sample_value = tanh(sample_value * (1.0 + jazz_intensity * 0.2))
		
		sample_value *= swing_factor * 0.5
		sample_value = clamp(sample_value, -1.0, 1.0)
		
		# Convert to 16-bit integer
		var sample_16bit = int(sample_value * 32767)
		samples[i * 2] = sample_16bit & 0xFF
		samples[i * 2 + 1] = (sample_16bit >> 8) & 0xFF
	
	var audio_stream = AudioStreamWAV.new()
	audio_stream.data = samples
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = sample_rate
	audio_stream.stereo = false
	
	return audio_stream

func update_moonlight_position_from_z_movement():
	if not play_moonlight_sonata or moonlight_notes.size() == 0:
		return
	
	# Convert Z movement to note position change
	# Positive Z movement goes forward in melody, negative goes backward
	var note_change = int(z_movement)
	
	if note_change != 0:
		# Update current note position
		moonlight_current_note += note_change
		
		# Clamp to valid range
		moonlight_current_note = clamp(moonlight_current_note, 0, moonlight_notes.size() - 1)
		
		# Reset note timer when jumping to new position
		moonlight_note_timer = 0.0
		
		# Set manual navigation flag
		moonlight_manual_navigation = true
		
		# Play the note at the new position
		play_moonlight_note()
		
		print("DEBUG: Moonlight position changed by ", note_change, " - Now at note ", moonlight_current_note + 1, "/", moonlight_notes.size())
		
		# Reset Z movement accumulation
		z_movement = 0.0

func toggle_emission():
	if is_emitting:
		stop_emission()
	else:
		start_emission()

func start_emission():
	is_emitting = true
	print("Started text emission")

func stop_emission():
	is_emitting = false
	print("Stopped emission")

func handle_letter_emission(delta: float):
	emission_timer += delta
	var time_per_letter = 1.0 / emission_rate
	
	# Calculate how many letters should be emitted this frame
	var letters_to_emit = int(emission_timer / time_per_letter)
	if letters_to_emit > 0:
		emission_timer = fmod(emission_timer, time_per_letter)
		
		# Emit letters in batches to reduce frame drops
		var batch_size = min(letters_to_emit, emission_batch_size)
		for i in range(batch_size):
			emit_next_letter()

func emit_next_letter():
	# Check if we've reached the end of the text
	if current_char_index >= manifesto_text.length():
		current_char_index = 0  # Loop back to beginning
		print("Manifesto complete! Starting over...")
	
	var character = manifesto_text[current_char_index]
	
	# Skip certain characters or handle them specially
	if character == '\n':
		current_char_index += 1
		return
	
	# Letters spawn at this node's position ($".")
	var spawn_position = global_position
	
	# Create the letter label
	var letter_label = Label3D.new()
	
	# Convert character to dingbats if enabled
	if use_dingbats and dingbats_font:
		letter_label.text = convert_to_dingbats(character)
		letter_label.font = dingbats_font
	else:
		letter_label.text = character
	
	letter_label.font_size = letter_font_size
	letter_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letter_label.position = spawn_position
	
	# Assign color based on character type or randomly
	var color_index = current_char_index % letter_colors.size()
	letter_label.modulate = letter_colors[color_index]
	
	# Add special effects for certain characters
	if character == ' ':
		letter_label.modulate.a = 0.3  # Make spaces more transparent
		letter_label.text = "•"        # Use bullet for visibility
	elif character in "!.?":
		letter_label.modulate *= 1.5   # Make punctuation brighter
		letter_label.font_size = int(letter_font_size * 1.2)  # Bigger punctuation
	elif character in "AEIOU":
		# Make vowels glow more
		letter_label.modulate *= 1.3
	
	# NO MOVEMENT - letters stay exactly where they spawn
	var drift_direction = Vector3.ZERO
	
	# Store letter data for management
	var letter_data = {
		"label": letter_label,
		"birth_time": Time.get_ticks_msec() / 1000.0,
		"position": spawn_position,
		"character": character,
		"index": current_char_index,
		"drift_direction": drift_direction,
		"original_color": letter_label.modulate
	}
	
	emitted_letters.append(letter_data)
	
	# Add to global scene (scene tree root)
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(letter_label)
	else:
		# Fallback to this node if no scene root exists
		add_child(letter_label)
	
	# Add subtle spawn animation
	animate_letter_spawn(letter_label)
	
	current_char_index += 1
	
	# Performance management
	if emitted_letters.size() > max_visible_letters:
		remove_oldest_letter()

func convert_to_dingbats(character: String) -> String:
	# Convert all characters to only dots and circles
	match character:
		"o", "O": return "o"  # Keep o as circle
		".": return "."       # Keep . as dot
		_: return "."         # Everything else becomes a dot

func animate_letter_spawn(letter_label: Label3D):
	# Simplified animation for better performance
	letter_label.scale = Vector3(0.1, 0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(letter_label, "scale", Vector3.ONE, 0.2)

func update_existing_letters(delta: float):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Only update every few frames to reduce CPU load
	if int(current_time * 10) % 3 != 0:  # Update every 3rd frame
		return
	
	for letter_data in emitted_letters:
		var age = current_time - letter_data.birth_time
		var letter_label = letter_data.label
		
		# NO MOVEMENT - letters stay exactly where they spawn
		# NO ROTATION - letters remain static
		
		# Start fading when approaching lifetime (simplified)
		if age > (letter_lifetime - fade_duration):
			var fade_progress = (age - (letter_lifetime - fade_duration)) / fade_duration
			fade_progress = clamp(fade_progress, 0.0, 1.0)
			
			var original_color = letter_data.original_color
			letter_label.modulate = original_color.lerp(Color.TRANSPARENT, fade_progress)

func cleanup_old_letters(delta: float):
	cleanup_timer += delta
	if cleanup_timer < cleanup_frequency:
		return
	
	cleanup_timer = 0.0
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Remove letters that have exceeded their lifetime
	for i in range(emitted_letters.size() - 1, -1, -1):
		var letter_data = emitted_letters[i]
		var age = current_time - letter_data.birth_time
		
		if age > letter_lifetime:
			letter_data.label.queue_free()
			emitted_letters.remove_at(i)

func remove_oldest_letter():
	if emitted_letters.size() > 0:
		var oldest = emitted_letters[0]
		oldest.label.queue_free()
		emitted_letters.remove_at(0)

# Utility functions
func reset_emission():
	current_char_index = 0
	print("Reset to beginning of manifesto")

func clear_all_letters():
	for letter_data in emitted_letters:
		letter_data.label.queue_free()
	emitted_letters.clear()
	print("Cleared all letters")

func set_emission_rate(new_rate: float):
	emission_rate = new_rate
	print("Emission rate set to: ", new_rate, " letters per second")

func print_progress():
	var progress = (float(current_char_index) / float(manifesto_text.length())) * 100.0
	var current_char = manifesto_text[current_char_index] if current_char_index < manifesto_text.length() else "END"
	print("Progress: %.1f%% - Current character: '%s' - Active letters: %d" % [progress, current_char, emitted_letters.size()])

# Function to change emission pattern
func set_emission_pattern(pattern: String):
	match pattern:
		"fountain":
			float_speed = 3.0
 
		"gentle":
			float_speed = 1.0
 
		"explosive":
			float_speed = 5.0
 
	print("Emission pattern set to: ", pattern)

# Alternative: Generate different bell types
func generate_bell_type(bell_type: String) -> AudioStreamWAV:
	match bell_type:
		"church":
			bell_frequency = 400.0
			bell_decay = 4.0
			bell_harmonics = 7
		"wind_chime":
			bell_frequency = 1200.0
			bell_decay = 1.5
			bell_harmonics = 3
		"tibetan":
			bell_frequency = 600.0
			bell_decay = 6.0
			bell_harmonics = 8
		"digital":
			bell_frequency = 800.0
			bell_decay = 1.0
			bell_harmonics = 4
	
	return generate_bell_sound()

# Call this to change bell types during runtime
func set_bell_type(type: String):
	bell_sound = generate_bell_type(type)
	if audio_player:
		audio_player.stream = bell_sound
	print("Bell type changed to: ", type)

# Test function to verify script is working
func test_script():
	print("Script is working correctly!")
