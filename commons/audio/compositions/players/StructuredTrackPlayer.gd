# StructuredTrackPlayer.gd
# Demonstrates ABAC/AABD phrasing with fills and empties
# Shows how rhythm supports song structure over 4, 8, and 16 bars

extends Node

const SAMPLE_RATE = 44100
const BPM = 124.0
const BEAT_DURATION = 60.0 / BPM
const BAR_DURATION = BEAT_DURATION * 4.0

enum TrackSound {
	CORE_KICK,
	CORE_SNARE,
	CORE_HIHAT,
	VARIATION_KICK,
	FILL_SNARE,
	FILL_TOM_HIGH,
	FILL_TOM_MID,
	FILL_TOM_LOW,
	ACCENT_CRASH,
	EMPTY_SPACE
}

enum SectionType {
	A_CORE,        # Core rhythm pattern
	B_VARIATION,   # Small variation
	C_BIGGER_VAR,  # Bigger variation
	D_FILL,        # Fill (increase energy)
	E_EMPTY        # Empty (decrease energy)
}

# Audio players for each instrument type
var kick_player: AudioStreamPlayer       # All kick drums
var snare_player: AudioStreamPlayer      # All snare drums  
var hihat_player: AudioStreamPlayer      # All hi-hats
var tom_player: AudioStreamPlayer        # All toms
var crash_player: AudioStreamPlayer      # All crashes/accents

# Structure system
var beat_timer: Timer
var bar_timer: Timer
var current_beat: int = 0
var current_bar: int = 0
var phrase_bar: int = 0  # Position within 8-bar phrase
var is_playing: bool = false

# 8-bar phrase structure: A-B-A-C-A-B-A-D
var phrase_structure: Array = [
	SectionType.A_CORE,        # Bar 1
	SectionType.B_VARIATION,   # Bar 2
	SectionType.A_CORE,        # Bar 3
	SectionType.C_BIGGER_VAR,  # Bar 4
	SectionType.A_CORE,        # Bar 5
	SectionType.B_VARIATION,   # Bar 6
	SectionType.A_CORE,        # Bar 7
	SectionType.D_FILL         # Bar 8 (or E_EMPTY)
]

# Different beat patterns for each section type
var core_pattern: Array = [1, 0, 1, 0]              # Basic four-on-the-floor
var variation_b_pattern: Array = [1, 0, 1, 1]       # Extra kick on beat 4
var variation_c_pattern: Array = [1, 1, 1, 0]       # Different kick pattern
var fill_pattern: Array = [1, 1, 1, 1]              # All beats for fills

var snare_core: Array = [0, 1, 0, 1]                # Basic backbeat
var snare_variation: Array = [0, 1, 1, 1]           # Extra snares
var snare_fill: Array = [1, 1, 1, 1]                # Fill snares

# Sound cache
var sound_cache: Dictionary = {}

# Structure state
var current_section: SectionType = SectionType.A_CORE
var next_section_type: SectionType = SectionType.A_CORE
var section_change_pending: bool = false

# Track settings
@export var master_volume: float = -6.0
@export var core_volume: float = 0.0
@export var variation_volume: float = -3.0
@export var fill_volume: float = 3.0
@export var accent_volume: float = 6.0

@export var auto_start: bool = true
@export var use_empties: bool = false  # Toggle between fills and empties

signal track_started()
signal section_changed(section_type: SectionType, bar_number: int)
signal phrase_completed(phrase_number: int)

func _ready():
	print("🎵 STRUCTURED TRACK PLAYER 🎵")
	print("Demonstrating ABAC/AABD phrasing structure...")
	
	_setup_audio_players()
	_setup_rhythm_system()
	_generate_all_sounds()
	
	if auto_start:
		call_deferred("start_track")

func _setup_audio_players():
	"""Setup players for each instrument type"""
	
	kick_player = AudioStreamPlayer.new()
	kick_player.name = "KickPlayer"
	kick_player.volume_db = core_volume + master_volume
	add_child(kick_player)
	
	snare_player = AudioStreamPlayer.new()
	snare_player.name = "SnarePlayer"
	snare_player.volume_db = core_volume + master_volume
	add_child(snare_player)
	
	hihat_player = AudioStreamPlayer.new()
	hihat_player.name = "HihatPlayer"
	hihat_player.volume_db = core_volume + master_volume - 6  # Quieter hi-hats
	add_child(hihat_player)
	
	tom_player = AudioStreamPlayer.new()
	tom_player.name = "TomPlayer"
	tom_player.volume_db = fill_volume + master_volume
	add_child(tom_player)
	
	crash_player = AudioStreamPlayer.new()
	crash_player.name = "CrashPlayer"
	crash_player.volume_db = accent_volume + master_volume
	add_child(crash_player)
	
	print("   ✅ Instrument audio players configured")

func _setup_rhythm_system():
	"""Setup beat and bar timers for structure"""
	
	# Beat timer for individual beats
	beat_timer = Timer.new()
	beat_timer.name = "BeatTimer"
	beat_timer.wait_time = BEAT_DURATION
	beat_timer.one_shot = false
	beat_timer.timeout.connect(_on_beat)
	add_child(beat_timer)
	
	# Bar timer for structure changes
	bar_timer = Timer.new()
	bar_timer.name = "BarTimer"
	bar_timer.wait_time = BAR_DURATION
	bar_timer.one_shot = false
	bar_timer.timeout.connect(_on_bar)
	add_child(bar_timer)
	
	print("   ✅ Structured rhythm system ready at %d BPM" % BPM)

func _generate_all_sounds():
	"""Generate sounds for structured composition"""
	print("   🔧 Generating structured sounds...")
	
	sound_cache[TrackSound.CORE_KICK] = _generate_sound(TrackSound.CORE_KICK, 0.8)
	sound_cache[TrackSound.CORE_SNARE] = _generate_sound(TrackSound.CORE_SNARE, 0.6)
	sound_cache[TrackSound.CORE_HIHAT] = _generate_sound(TrackSound.CORE_HIHAT, 0.2)
	sound_cache[TrackSound.VARIATION_KICK] = _generate_sound(TrackSound.VARIATION_KICK, 0.7)
	sound_cache[TrackSound.FILL_SNARE] = _generate_sound(TrackSound.FILL_SNARE, 0.4)
	sound_cache[TrackSound.FILL_TOM_HIGH] = _generate_sound(TrackSound.FILL_TOM_HIGH, 0.5)
	sound_cache[TrackSound.FILL_TOM_MID] = _generate_sound(TrackSound.FILL_TOM_MID, 0.6)
	sound_cache[TrackSound.FILL_TOM_LOW] = _generate_sound(TrackSound.FILL_TOM_LOW, 0.7)
	sound_cache[TrackSound.ACCENT_CRASH] = _generate_sound(TrackSound.ACCENT_CRASH, 2.0)
	
	print("   ✅ All structured sounds generated")

func start_track():
	"""Start the structured track"""
	if is_playing:
		return
	
	print("🎵 Starting structured track...")
	print("   • 8-bar phrases: A-B-A-C-A-B-A-D")
	print("   • A = Core rhythm")
	print("   • B = Small variation") 
	print("   • C = Bigger variation")
	print("   • D = Fill (or Empty if toggled)")
	print("   • Watch how rhythm supports song structure!")
	
	is_playing = true
	current_beat = 0
	current_bar = 0
	phrase_bar = 0
	current_section = SectionType.A_CORE
	
	# Start rhythm
	beat_timer.start()
	bar_timer.start()
	track_started.emit()

func stop_track():
	"""Stop the structured track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping structured track...")
	is_playing = false
	beat_timer.stop()
	bar_timer.stop()
	
	# Stop all players
	kick_player.stop()
	snare_player.stop()
	hihat_player.stop()
	tom_player.stop()
	crash_player.stop()

func _on_bar():
	"""Handle bar transitions for structure"""
	if not is_playing:
		return
	
	current_bar += 1
	phrase_bar = (phrase_bar + 1) % 8
	
	# Determine next section based on phrase structure
	var next_section = phrase_structure[phrase_bar]
	
	# Handle D section toggle between fill and empty
	if next_section == SectionType.D_FILL and use_empties:
		next_section = SectionType.E_EMPTY
	
	# Change section
	current_section = next_section
	section_changed.emit(current_section, current_bar)
	
	# Log section changes
	var section_name = _get_section_name(current_section)
	print("🎵 Bar %d: Section %s (%s)" % [current_bar, section_name, _get_section_description(current_section)])
	
	# Handle phrase completion
	if phrase_bar == 0:
		var phrase_num = current_bar / 8
		phrase_completed.emit(phrase_num)
		print("✨ Phrase %d completed! Starting new 8-bar phrase..." % phrase_num)

func _on_beat():
	"""Handle individual beats within current section"""
	if not is_playing:
		return
	
	var beat_in_bar = current_beat % 4
	
	# Play sounds based on current section type
	match current_section:
		SectionType.A_CORE:
			_play_core_section(beat_in_bar)
		SectionType.B_VARIATION:
			_play_variation_b_section(beat_in_bar)
		SectionType.C_BIGGER_VAR:
			_play_variation_c_section(beat_in_bar)
		SectionType.D_FILL:
			_play_fill_section(beat_in_bar)
		SectionType.E_EMPTY:
			_play_empty_section(beat_in_bar)
	
	current_beat += 1

func _play_core_section(beat: int):
	"""Play A section - core rhythm"""
	
	# Core kick pattern
	if core_pattern[beat] == 1:
		kick_player.stream = sound_cache[TrackSound.CORE_KICK]
		kick_player.play()
	
	# Core snare pattern
	if snare_core[beat] == 1:
		snare_player.stream = sound_cache[TrackSound.CORE_SNARE]
		snare_player.play()
	
	# Steady hi-hats (every beat)
	hihat_player.stream = sound_cache[TrackSound.CORE_HIHAT]
	hihat_player.play()

func _play_variation_b_section(beat: int):
	"""Play B section - small variation"""
	
	# Variation kick pattern (extra kick on beat 4)
	if variation_b_pattern[beat] == 1:
		kick_player.stream = sound_cache[TrackSound.VARIATION_KICK]
		kick_player.play()
	
	# Core snare (same as A)
	if snare_core[beat] == 1:
		snare_player.stream = sound_cache[TrackSound.CORE_SNARE]
		snare_player.play()
	
	# Hi-hats (every beat)
	hihat_player.stream = sound_cache[TrackSound.CORE_HIHAT]
	hihat_player.play()

func _play_variation_c_section(beat: int):
	"""Play C section - bigger variation"""
	
	# Different kick pattern
	if variation_c_pattern[beat] == 1:
		kick_player.stream = sound_cache[TrackSound.VARIATION_KICK]
		kick_player.play()
	
	# Variation snare (extra snares)
	if snare_variation[beat] == 1:
		snare_player.stream = sound_cache[TrackSound.CORE_SNARE]
		snare_player.play()
	
	# Hi-hats with accent crash on beat 1
	if beat == 0:
		crash_player.stream = sound_cache[TrackSound.ACCENT_CRASH]
		crash_player.volume_db = accent_volume + master_volume - 9
		crash_player.play()
	
	# Hi-hats (every beat)
	hihat_player.stream = sound_cache[TrackSound.CORE_HIHAT]
	hihat_player.play()

func _play_fill_section(beat: int):
	"""Play D section - fill (increase energy)"""
	
	# Fill kicks on all beats
	if fill_pattern[beat] == 1:
		kick_player.stream = sound_cache[TrackSound.CORE_KICK]
		kick_player.play()
	
	# Fill snares (lots of them)
	if snare_fill[beat] == 1:
		snare_player.stream = sound_cache[TrackSound.FILL_SNARE]
		snare_player.play()
	
	# Tom fills based on beat
	match beat:
		0:
			tom_player.stream = sound_cache[TrackSound.FILL_TOM_HIGH]
			tom_player.play()
		1:
			tom_player.stream = sound_cache[TrackSound.FILL_TOM_MID]
			tom_player.play()
		2:
			tom_player.stream = sound_cache[TrackSound.FILL_TOM_LOW]
			tom_player.play()
		3:
			# Crash to anticipate next phrase
			crash_player.stream = sound_cache[TrackSound.ACCENT_CRASH]
			crash_player.play()
	
	# Hi-hats continue
	hihat_player.stream = sound_cache[TrackSound.CORE_HIHAT]
	hihat_player.play()

func _play_empty_section(beat: int):
	"""Play E section - empty (decrease energy, create vacuum)"""
	
	# Only hi-hats, no kick or snare
	if beat == 1 or beat == 3:  # Just backbeat hi-hats
		hihat_player.stream = sound_cache[TrackSound.CORE_HIHAT]
		hihat_player.volume_db = core_volume + master_volume - 18  # Very quiet
		hihat_player.play()
		hihat_player.volume_db = core_volume + master_volume - 6  # Reset to normal quiet level
	
	# Crash on beat 4 to anticipate return
	if beat == 3:
		crash_player.stream = sound_cache[TrackSound.ACCENT_CRASH]
		crash_player.volume_db = accent_volume + master_volume - 6
		crash_player.play()

func _generate_sound(sound_type: TrackSound, duration: float) -> AudioStreamWAV:
	"""Generate structured composition sounds"""
	
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	match sound_type:
		TrackSound.CORE_KICK:
			_generate_core_kick(data, sample_count)
		TrackSound.CORE_SNARE:
			_generate_core_snare(data, sample_count)
		TrackSound.CORE_HIHAT:
			_generate_core_hihat(data, sample_count)
		TrackSound.VARIATION_KICK:
			_generate_variation_kick(data, sample_count)
		TrackSound.FILL_SNARE:
			_generate_fill_snare(data, sample_count)
		TrackSound.FILL_TOM_HIGH:
			_generate_fill_tom_high(data, sample_count)
		TrackSound.FILL_TOM_MID:
			_generate_fill_tom_mid(data, sample_count)
		TrackSound.FILL_TOM_LOW:
			_generate_fill_tom_low(data, sample_count)
		TrackSound.ACCENT_CRASH:
			_generate_accent_crash(data, sample_count)
	
	stream.data = data
	return stream

func _generate_core_kick(data: PackedByteArray, sample_count: int):
	"""Generate core kick drum"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 65.0 - (25.0 * pow(progress, 0.3))
		var sine = sin(2.0 * PI * freq * t)
		var click = sin(2.0 * PI * 1500.0 * t) * exp(-progress * 45.0) * 0.2
		var envelope = exp(-progress * 3.8)
		var sample = tanh((sine + click) * envelope * 1.3) * 0.75
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_core_snare(data: PackedByteArray, sample_count: int):
	"""Generate core snare drum"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.5
		var tone = sin(2.0 * PI * 240.0 * t) * 0.4
		var snap = sin(2.0 * PI * 3200.0 * t) * exp(-progress * 28.0) * 0.3
		var envelope = exp(-progress * 9.0)
		var sample = (noise + tone + snap) * envelope * 0.65
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_core_hihat(data: PackedByteArray, sample_count: int):
	"""Generate core hi-hat"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.8
		var filter_freq = 9000.0 - (2500.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var envelope = exp(-progress * 16.0)
		var sample = filtered * envelope * 0.3
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_variation_kick(data: PackedByteArray, sample_count: int):
	"""Generate variation kick (slightly different tone)"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 70.0 - (30.0 * pow(progress, 0.35))
		var sine = sin(2.0 * PI * freq * t)
		var sub = sin(2.0 * PI * freq * 0.6 * t) * 0.2
		var click = sin(2.0 * PI * 1700.0 * t) * exp(-progress * 50.0) * 0.15
		var envelope = exp(-progress * 4.2)
		var sample = tanh((sine + sub + click) * envelope * 1.1) * 0.7
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_fill_snare(data: PackedByteArray, sample_count: int):
	"""Generate fill snare (tighter, snappier)"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.8
		var tone = sin(2.0 * PI * 280.0 * t) * 0.3
		var snap = sin(2.0 * PI * 4000.0 * t) * exp(-progress * 35.0) * 0.4
		var envelope = exp(-progress * 12.0)
		var sample = (noise + tone + snap) * envelope * 0.55
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_fill_tom_high(data: PackedByteArray, sample_count: int):
	"""Generate high tom for fills"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 220.0 - (60.0 * progress)
		var sine = sin(2.0 * PI * freq * t)
		var harmonic = sin(2.0 * PI * freq * 1.5 * t) * 0.3
		var envelope = exp(-progress * 5.5)
		var sample = (sine + harmonic) * envelope * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_fill_tom_mid(data: PackedByteArray, sample_count: int):
	"""Generate mid tom for fills"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 165.0 - (45.0 * progress)
		var sine = sin(2.0 * PI * freq * t)
		var harmonic = sin(2.0 * PI * freq * 1.4 * t) * 0.25
		var envelope = exp(-progress * 5.0)
		var sample = (sine + harmonic) * envelope * 0.65
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_fill_tom_low(data: PackedByteArray, sample_count: int):
	"""Generate low tom for fills"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 110.0 - (35.0 * progress)
		var sine = sin(2.0 * PI * freq * t)
		var harmonic = sin(2.0 * PI * freq * 1.3 * t) * 0.2
		var envelope = exp(-progress * 4.5)
		var sample = (sine + harmonic) * envelope * 0.7
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_accent_crash(data: PackedByteArray, sample_count: int):
	"""Generate crash cymbal for accents"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 2.0
		var shimmer = sin(2.0 * PI * 15000.0 * t) * 0.3
		var ring = sin(2.0 * PI * 8000.0 * t) * 0.2
		var envelope = exp(-progress * 1.5)  # Long decay
		var sample = (noise + shimmer + ring) * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# Helper functions
func _get_section_name(section: SectionType) -> String:
	match section:
		SectionType.A_CORE: return "A"
		SectionType.B_VARIATION: return "B"
		SectionType.C_BIGGER_VAR: return "C"
		SectionType.D_FILL: return "D"
		SectionType.E_EMPTY: return "E"
		_: return "?"

func _get_section_description(section: SectionType) -> String:
	match section:
		SectionType.A_CORE: return "Core rhythm"
		SectionType.B_VARIATION: return "Small variation"
		SectionType.C_BIGGER_VAR: return "Bigger variation"
		SectionType.D_FILL: return "Fill - increase energy"
		SectionType.E_EMPTY: return "Empty - decrease energy"
		_: return "Unknown"

# Public API
func toggle_empties():
	"""Toggle between fills and empties for D sections"""
	use_empties = !use_empties
	var mode = "Empties" if use_empties else "Fills"
	print("🎵 Switched to %s mode for D sections" % mode)

func get_structure_info() -> Dictionary:
	"""Get current structure state"""
	return {
		"is_playing": is_playing,
		"current_bar": current_bar,
		"phrase_bar": phrase_bar,
		"current_section": current_section,
		"section_name": _get_section_name(current_section),
		"use_empties": use_empties,
		"phrase_structure": phrase_structure
	}

func _input(event):
	"""Hotkey controls"""
	if event.is_action_pressed("ui_accept"):
		if is_playing:
			stop_track()
		else:
			start_track()
	elif event.is_action_pressed("ui_select"):
		var info = get_structure_info()
		print("🎵 STRUCTURE INFO 🎵")
		print("   Bar: %d, Phrase Bar: %d" % [info.current_bar, info.phrase_bar])
		print("   Section: %s (%s)" % [info.section_name, _get_section_description(info.current_section)])
		print("   Mode: %s" % ("Empties" if use_empties else "Fills"))
	elif event.is_action_pressed("ui_up"):
		toggle_empties() 