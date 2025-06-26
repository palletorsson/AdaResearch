# DarkBladeRunner128TrackPlayer.gd
# Epic 128-bar dark cyberpunk track with evolving Blade Runner atmosphere
# Features dynamic sections, complex patterns, and cinematic sound design

extends Node

const SAMPLE_RATE = 44100
var BPM = 300.0  # High-energy cyberpunk BPM
var BEAT_DURATION = 60.0 / BPM
var STEP_DURATION = BEAT_DURATION / 4.0  # 16th note precision
const BARS_TOTAL = 128
const STEPS_PER_BAR = 16
const TOTAL_STEPS = BARS_TOTAL * STEPS_PER_BAR

enum TrackSound {
	DARK_808_KICK,
	ACID_606_HIHAT,
	DARK_808_SUB_BASS,
	AMBIENT_DRONE,
	ACID_606_SNARE,
	GLITCH_STAB,
	DEEP_RUMBLE,
	BLADE_RUNNER_HIT,
	CYBERPUNK_SWEEP,
	NEON_PULSE,
	RAIN_TEXTURE,
	DIGITAL_ECHO,
	SYNTHETIC_VOICE,
	CITYSCAPE_WASH
}

# Enhanced audio system for 128-bar epic
var kick_player: AudioStreamPlayer
var hihat_player: AudioStreamPlayer
var bass_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer
var snare_player: AudioStreamPlayer
var blade_runner_player: AudioStreamPlayer
var atmosphere_player: AudioStreamPlayer
var cityscape_player: AudioStreamPlayer

# Epic rhythm system
var step_timer: Timer
var section_timer: Timer
var current_step: int = 0
var current_bar: int = 0
var current_section: int = 0
var is_playing: bool = false

# Section structure (8 sections of 16 bars each)
enum Section {
	INTRO,        # Bars 1-16: Minimal dark atmosphere
	EMERGENCE,    # Bars 17-32: Beats emerge from the void
	NEON_PULSE,   # Bars 33-48: Full cyberpunk energy
	DIGITAL_RAIN, # Bars 49-64: Complex patterns with rain texture
	VOID_BREAK,   # Bars 65-80: Breakdown with atmospheric focus
	BLADE_STORM,  # Bars 81-96: Maximum intensity with Blade Runner themes
	CLIMAX,       # Bars 97-112: Peak energy with all elements
	FADE_OUT      # Bars 113-128: Dystopian resolution
}

# Dynamic pattern system - patterns evolve per section
var pattern_library: Dictionary = {}
var current_patterns: Dictionary = {}

# Sound cache
var sound_cache: Dictionary = {}

# Enhanced volume system
@export var master_volume: float = -6.0
@export var kick_volume: float = 0.0
@export var hihat_volume: float = 0.0
@export var bass_volume: float = 0.0
@export var snare_volume: float = -3.0
@export var ambient_volume: float = -9.0
@export var effect_volume: float = -12.0
@export var blade_runner_volume: float = -1.0
@export var atmosphere_volume: float = -6.0
@export var cityscape_volume: float = -12.0

# Advanced rhythm features
@export var swing_amount: float = 0.08
@export var cyberpunk_intensity: float = 0.5  # Controls atmospheric density
@export var rain_density: float = 0.3  # Digital rain effect intensity
@export var neon_pulse_rate: float = 2.0  # Neon pulsing speed

@export var auto_start: bool = true

# Signals
signal track_started()
signal section_changed(section: Section, bar: int)
signal blade_runner_moment(intensity: float)
signal cyberpunk_pulse(energy: float)

func _ready():
	print("🎬 BLADE RUNNER 128-BAR EPIC TRACK 🎬")
	print("Loading dark cyberpunk atmosphere...")
	print("Total duration: %.1f minutes of dystopian soundscape" % ((BARS_TOTAL * 4 * BEAT_DURATION) / 60.0))
	
	_setup_epic_audio_system()
	_setup_advanced_rhythm_system()
	_initialize_section_patterns()
	_generate_cyberpunk_sounds()
	
	if auto_start:
		call_deferred("start_epic_blade_runner_track")

func _setup_epic_audio_system():
	"""Setup enhanced multi-layer audio system"""
	
	# Core rhythm section
	kick_player = AudioStreamPlayer.new()
	kick_player.name = "DarkKickPlayer"
	add_child(kick_player)
	
	hihat_player = AudioStreamPlayer.new()
	hihat_player.name = "CyberpunkHiHatPlayer"
	add_child(hihat_player)
	
	snare_player = AudioStreamPlayer.new()
	snare_player.name = "AcidSnarePlayer"
	add_child(snare_player)
	
	# Bass and ambient layers
	bass_player = AudioStreamPlayer.new()
	bass_player.name = "SubBassPlayer"
	add_child(bass_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientDronePlayer"
	add_child(ambient_player)
	
	# Effects and atmosphere
	effect_player = AudioStreamPlayer.new()
	effect_player.name = "GlitchEffectPlayer"
	add_child(effect_player)
	
	blade_runner_player = AudioStreamPlayer.new()
	blade_runner_player.name = "BladeRunnerPlayer"
	add_child(blade_runner_player)
	
	atmosphere_player = AudioStreamPlayer.new()
	atmosphere_player.name = "CyberpunkAtmospherePlayer"
	add_child(atmosphere_player)
	
	cityscape_player = AudioStreamPlayer.new()
	cityscape_player.name = "CityscapePlayer"
	add_child(cityscape_player)
	
	_update_all_volumes()
	print("   ✅ Epic multi-layer audio system ready")

func _setup_advanced_rhythm_system():
	"""Setup precision timing for 128-bar epic"""
	
	# Step timer for 16th note precision
	step_timer = Timer.new()
	step_timer.name = "EpicStepTimer"
	step_timer.wait_time = STEP_DURATION
	step_timer.one_shot = false
	step_timer.timeout.connect(_on_epic_step)
	add_child(step_timer)
	
	# Section timer for structure tracking
	section_timer = Timer.new()
	section_timer.name = "SectionTimer"
	section_timer.wait_time = BEAT_DURATION * 4.0 * 16.0  # 16 bars per section
	section_timer.one_shot = false
	section_timer.timeout.connect(_on_section_change)
	add_child(section_timer)
	
	print("   ✅ Advanced 128-bar rhythm system ready at %.0f BPM" % BPM)

func _initialize_section_patterns():
	"""Create evolving patterns for each of 8 sections"""
	print("   🎬 Building 128-bar Blade Runner pattern library...")
	
	# INTRO Section (Bars 1-16) - Dark atmospheric emergence
	pattern_library[Section.INTRO] = {
		"kick":         [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
		"hihat":        [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
		"snare":        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"effect":       [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
		"cityscape":    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# EMERGENCE Section (Bars 17-32) - Beats emerge from darkness
	pattern_library[Section.EMERGENCE] = {
		"kick":         [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
		"hihat":        [0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0],
		"snare":        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"effect":       [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
		"cityscape":    [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# NEON_PULSE Section (Bars 33-48) - Full cyberpunk energy
	pattern_library[Section.NEON_PULSE] = {
		"kick":         [0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1],
		"hihat":        [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0],
		"snare":        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
		"effect":       [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],
		"cityscape":    [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]
	}
	
	# DIGITAL_RAIN Section (Bars 49-64) - Complex patterns with rain texture
	pattern_library[Section.DIGITAL_RAIN] = {
		"kick":         [0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1],
		"hihat":        [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0],
		"snare":        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
		"effect":       [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1],
		"cityscape":    [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
	}
	
	# VOID_BREAK Section (Bars 65-80) - Atmospheric breakdown
	pattern_library[Section.VOID_BREAK] = {
		"kick":         [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"hihat":        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
		"snare":        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"effect":       [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],
		"cityscape":    [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# BLADE_STORM Section (Bars 81-96) - Maximum Blade Runner intensity
	pattern_library[Section.BLADE_STORM] = {
		"kick":         [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1],
		"hihat":        [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0],
		"snare":        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
		"effect":       [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		"cityscape":    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
	}
	
	# CLIMAX Section (Bars 97-112) - Peak intensity with all elements
	pattern_library[Section.CLIMAX] = {
		"kick":         [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1],
		"hihat":        [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0],
		"snare":        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
		"effect":       [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		"cityscape":    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
	}
	
	# FADE_OUT Section (Bars 113-128) - Dystopian resolution
	pattern_library[Section.FADE_OUT] = {
		"kick":         [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"hihat":        [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
		"snare":        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"effect":       [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmosphere":   [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cityscape":    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# Set initial patterns
	current_patterns = pattern_library[Section.INTRO]
	print("   ✅ 8-section Blade Runner pattern library complete")

func _generate_cyberpunk_sounds():
	"""Generate enhanced cyberpunk and Blade Runner sounds"""
	print("   🔧 Generating cyberpunk sound palette...")
	
	# Core rhythm sounds
	sound_cache[TrackSound.DARK_808_KICK] = _generate_sound(TrackSound.DARK_808_KICK, 1.5)
	sound_cache[TrackSound.ACID_606_HIHAT] = _generate_sound(TrackSound.ACID_606_HIHAT, 0.3)
	sound_cache[TrackSound.ACID_606_SNARE] = _generate_sound(TrackSound.ACID_606_SNARE, 0.8)
	sound_cache[TrackSound.GLITCH_STAB] = _generate_sound(TrackSound.GLITCH_STAB, 0.4)
	
	# Bass and ambient layers
	sound_cache[TrackSound.DARK_808_SUB_BASS] = _generate_sound(TrackSound.DARK_808_SUB_BASS, 8.0)
	sound_cache[TrackSound.AMBIENT_DRONE] = _generate_sound(TrackSound.AMBIENT_DRONE, 16.0)
	sound_cache[TrackSound.DEEP_RUMBLE] = _generate_sound(TrackSound.DEEP_RUMBLE, 12.0)
	
	# Enhanced Blade Runner atmospheric sounds
	sound_cache[TrackSound.BLADE_RUNNER_HIT] = _generate_sound(TrackSound.BLADE_RUNNER_HIT, 6.0)
	sound_cache[TrackSound.CYBERPUNK_SWEEP] = _generate_sound(TrackSound.CYBERPUNK_SWEEP, 4.0)
	sound_cache[TrackSound.NEON_PULSE] = _generate_sound(TrackSound.NEON_PULSE, 2.0)
	sound_cache[TrackSound.RAIN_TEXTURE] = _generate_sound(TrackSound.RAIN_TEXTURE, 8.0)
	sound_cache[TrackSound.DIGITAL_ECHO] = _generate_sound(TrackSound.DIGITAL_ECHO, 3.0)
	sound_cache[TrackSound.SYNTHETIC_VOICE] = _generate_sound(TrackSound.SYNTHETIC_VOICE, 4.0)
	sound_cache[TrackSound.CITYSCAPE_WASH] = _generate_sound(TrackSound.CITYSCAPE_WASH, 12.0)
	
	print("   ✅ Complete cyberpunk sound palette ready - 14 unique sounds")

func start_epic_blade_runner_track():
	"""Start the epic 128-bar Blade Runner journey"""
	if is_playing:
		return
	
	print("🎬 STARTING BLADE RUNNER 128-BAR EPIC...")
	print("   🌆 Dystopian cityscape emerging...")
	print("   ⚡ Total duration: %.1f minutes of cyberpunk atmosphere" % ((BARS_TOTAL * 4 * BEAT_DURATION) / 60.0))
	print("   🎵 8 evolving sections with Blade Runner themes")
	
	is_playing = true
	current_step = 0
	current_bar = 0
	current_section = Section.INTRO
	current_patterns = pattern_library[Section.INTRO]
	
	# Start atmospheric layers
	_start_cyberpunk_atmosphere()
	
	# Start rhythm system
	step_timer.start()
	section_timer.start()
	
	_announce_section_change()
	track_started.emit()

func stop_epic_blade_runner_track():
	"""Stop the epic track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping Blade Runner epic at bar %d..." % (current_bar + 1))
	is_playing = false
	step_timer.stop()
	section_timer.stop()
	_stop_all_players()

func _start_cyberpunk_atmosphere():
	"""Start the continuous atmospheric layers"""
	
	# Deep cyberpunk drone
	ambient_player.stream = sound_cache[TrackSound.AMBIENT_DRONE]
	ambient_player.play()
	
	# Cityscape wash (very quiet background)
	await get_tree().create_timer(1.0).timeout
	cityscape_player.stream = sound_cache[TrackSound.CITYSCAPE_WASH]
	cityscape_player.play()
	
	# Sub bass foundation
	await get_tree().create_timer(2.0).timeout
	bass_player.stream = sound_cache[TrackSound.DARK_808_SUB_BASS]
	bass_player.play()

func _on_epic_step():
	"""Handle each 16th note step of the epic track"""
	if not is_playing:
		return
	
	var pattern_pos = current_step % STEPS_PER_BAR
	var bar_pos = current_step % (STEPS_PER_BAR * BARS_TOTAL)
	current_bar = current_step / STEPS_PER_BAR
	
	# Apply swing to odd positions
	var swing_delay = 0.0
	if pattern_pos % 2 == 1:
		swing_delay = STEP_DURATION * swing_amount
		if swing_delay > 0:
			await get_tree().create_timer(swing_delay).timeout
	
	# Play current patterns with section-based intensity
	_play_epic_pattern_element("kick", current_patterns["kick"][pattern_pos], kick_player, TrackSound.DARK_808_KICK)
	_play_epic_pattern_element("hihat", current_patterns["hihat"][pattern_pos], hihat_player, TrackSound.ACID_606_HIHAT)
	_play_epic_pattern_element("snare", current_patterns["snare"][pattern_pos], snare_player, TrackSound.ACID_606_SNARE)
	_play_epic_pattern_element("effect", current_patterns["effect"][pattern_pos], effect_player, TrackSound.GLITCH_STAB)
	_play_epic_pattern_element("blade_runner", current_patterns["blade_runner"][pattern_pos], blade_runner_player, TrackSound.BLADE_RUNNER_HIT)
	_play_epic_pattern_element("atmosphere", current_patterns["atmosphere"][pattern_pos], atmosphere_player, TrackSound.CYBERPUNK_SWEEP)
	_play_epic_pattern_element("cityscape", current_patterns["cityscape"][pattern_pos], cityscape_player, TrackSound.NEON_PULSE)
	
	# Special section-based events
	_handle_section_specials(pattern_pos)
	
	current_step += 1
	
	# End of epic track
	if current_step >= TOTAL_STEPS:
		print("🎬 Epic 128-bar Blade Runner track complete! 🎬")
		stop_epic_blade_runner_track()

func _play_epic_pattern_element(name: String, intensity: int, player: AudioStreamPlayer, sound: TrackSound):
	"""Play pattern element with section-based intensity scaling"""
	if intensity > 0:
		player.stream = sound_cache[sound]
		
		# Calculate volume based on section and intensity
		var base_volume = _get_base_volume_for_epic_player(player)
		var section_modifier = _get_section_volume_modifier()
		var intensity_modifier = (intensity - 1) * 3.0  # 0, 3, 6 dB boost for intensity 1, 2, 3
		
		player.volume_db = base_volume + section_modifier + intensity_modifier + master_volume
		player.play()
		
		# Special handling for Blade Runner moments
		if name == "blade_runner":
			blade_runner_moment.emit(float(current_section) / 7.0)
		elif name == "atmosphere":
			cyberpunk_pulse.emit(cyberpunk_intensity * (float(current_section) / 7.0))

func _handle_section_specials(pattern_pos: int):
	"""Handle special events per section"""
	match current_section:
		Section.DIGITAL_RAIN:
			# Add digital rain texture
			if pattern_pos % 4 == 0 and randf() < rain_density:
				atmosphere_player.stream = sound_cache[TrackSound.RAIN_TEXTURE]
				atmosphere_player.volume_db = atmosphere_volume + master_volume - 6.0
				atmosphere_player.play()
		
		Section.BLADE_STORM, Section.CLIMAX:
			# Enhanced Blade Runner atmospheric hits
			if pattern_pos == 0 and (current_bar % 8) == 0:
				blade_runner_player.stream = sound_cache[TrackSound.SYNTHETIC_VOICE]
				blade_runner_player.volume_db = blade_runner_volume + master_volume + 3.0
				blade_runner_player.play()
				print("   🎬 Synthetic voice moment at bar %d" % (current_bar + 1))
		
		Section.NEON_PULSE:
			# Neon pulse effects
			if pattern_pos % 8 == 0:
				atmosphere_player.stream = sound_cache[TrackSound.NEON_PULSE]
				atmosphere_player.play()
		
		Section.VOID_BREAK:
			# Digital echoes in the void
			if pattern_pos == 0 and (current_bar % 4) == 0:
				effect_player.stream = sound_cache[TrackSound.DIGITAL_ECHO]
				effect_player.volume_db = effect_volume + master_volume - 3.0
				effect_player.play()

func _on_section_change():
	"""Handle section transitions"""
	if not is_playing:
		return
	
	var new_section = _get_section_for_bar(current_bar)
	if new_section != current_section:
		current_section = new_section
		current_patterns = pattern_library[current_section]
		_announce_section_change()
		section_changed.emit(current_section, current_bar)

func _get_section_for_bar(bar: int) -> Section:
	"""Determine section based on bar number"""
	if bar < 16: return Section.INTRO
	elif bar < 32: return Section.EMERGENCE
	elif bar < 48: return Section.NEON_PULSE
	elif bar < 64: return Section.DIGITAL_RAIN
	elif bar < 80: return Section.VOID_BREAK
	elif bar < 96: return Section.BLADE_STORM
	elif bar < 112: return Section.CLIMAX
	else: return Section.FADE_OUT

func _announce_section_change():
	"""Announce the current section with Blade Runner flavor"""
	var section_names = [
		"INTRO - The city awakens in darkness...",
		"EMERGENCE - Neon signs flicker to life",
		"NEON PULSE - Electric dreams take form",
		"DIGITAL RAIN - Data streams through the void",
		"VOID BREAK - Silence between the towers",
		"BLADE STORM - Replicant heartbeats intensify",
		"CLIMAX - The city's electric soul revealed",
		"FADE OUT - Return to the endless night"
	]
	
	print("🎬 Section %d: %s (Bar %d)" % [current_section + 1, section_names[current_section], current_bar + 1])

func _get_base_volume_for_epic_player(player: AudioStreamPlayer) -> float:
	"""Get base volume for player type"""
	match player.name:
		"DarkKickPlayer": return kick_volume
		"CyberpunkHiHatPlayer": return hihat_volume
		"AcidSnarePlayer": return snare_volume
		"SubBassPlayer": return bass_volume
		"AmbientDronePlayer": return ambient_volume
		"GlitchEffectPlayer": return effect_volume
		"BladeRunnerPlayer": return blade_runner_volume
		"CyberpunkAtmospherePlayer": return atmosphere_volume
		"CityscapePlayer": return cityscape_volume
		_: return master_volume

func _get_section_volume_modifier() -> float:
	"""Get volume modifier based on current section for cinematic dynamics"""
	match current_section:
		Section.INTRO: return -12.0          # Very quiet, mysterious
		Section.EMERGENCE: return -6.0       # Building
		Section.NEON_PULSE: return 0.0       # Full energy
		Section.DIGITAL_RAIN: return 2.0     # Enhanced presence
		Section.VOID_BREAK: return -9.0      # Pulled back
		Section.BLADE_STORM: return 4.0      # Maximum intensity
		Section.CLIMAX: return 6.0           # Peak energy
		Section.FADE_OUT: return -15.0       # Fading to darkness
		_: return 0.0

func _update_all_volumes():
	"""Update all player volumes"""
	kick_player.volume_db = kick_volume + master_volume
	hihat_player.volume_db = hihat_volume + master_volume
	snare_player.volume_db = snare_volume + master_volume
	bass_player.volume_db = bass_volume + master_volume
	ambient_player.volume_db = ambient_volume + master_volume
	effect_player.volume_db = effect_volume + master_volume
	blade_runner_player.volume_db = blade_runner_volume + master_volume
	atmosphere_player.volume_db = atmosphere_volume + master_volume
	cityscape_player.volume_db = cityscape_volume + master_volume

func _stop_all_players():
	"""Stop all audio players"""
	kick_player.stop()
	hihat_player.stop()
	snare_player.stop()
	bass_player.stop()
	ambient_player.stop()
	effect_player.stop()
	blade_runner_player.stop()
	atmosphere_player.stop()
	cityscape_player.stop()

# ===== ENHANCED SOUND GENERATION =====

func _generate_sound(sound_type: TrackSound, duration: float) -> AudioStreamWAV:
	"""Generate cyberpunk and Blade Runner sounds"""
	
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	match sound_type:
		TrackSound.DARK_808_KICK:
			_generate_dark_808_kick(data, sample_count)
		TrackSound.ACID_606_HIHAT:
			_generate_acid_606_hihat(data, sample_count)
		TrackSound.ACID_606_SNARE:
			_generate_acid_606_snare(data, sample_count)
		TrackSound.DARK_808_SUB_BASS:
			_generate_dark_808_sub_bass(data, sample_count)
		TrackSound.AMBIENT_DRONE:
			_generate_ambient_drone(data, sample_count)
		TrackSound.GLITCH_STAB:
			_generate_glitch_stab(data, sample_count)
		TrackSound.DEEP_RUMBLE:
			_generate_deep_rumble(data, sample_count)
		TrackSound.BLADE_RUNNER_HIT:
			_generate_blade_runner_hit(data, sample_count)
		TrackSound.CYBERPUNK_SWEEP:
			_generate_cyberpunk_sweep(data, sample_count)
		TrackSound.NEON_PULSE:
			_generate_neon_pulse(data, sample_count)
		TrackSound.RAIN_TEXTURE:
			_generate_rain_texture(data, sample_count)
		TrackSound.DIGITAL_ECHO:
			_generate_digital_echo(data, sample_count)
		TrackSound.SYNTHETIC_VOICE:
			_generate_synthetic_voice(data, sample_count)
		TrackSound.CITYSCAPE_WASH:
			_generate_cityscape_wash(data, sample_count)
	
	stream.data = data
	return stream

# Core drum sounds (enhanced for cyberpunk feel)

func _generate_dark_808_kick(data: PackedByteArray, sample_count: int):
	"""Enhanced dark 808 kick with more cyberpunk character"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 65.0 - (30.0 * pow(progress, 0.25))
		var sine = sin(2.0 * PI * freq * t)
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.5  # Deep sub harmonic
		var click = sin(2.0 * PI * 1800.0 * t) * exp(-progress * 60.0) * 0.25
		var distortion = tanh(sine * 2.5) * 0.3  # Cyberpunk grit
		var envelope = exp(-progress * 4.2)
		var sample = tanh((sine + sub + click + distortion) * envelope * 1.4) * 0.8
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_acid_606_hihat(data: PackedByteArray, sample_count: int):
	"""Acid-style 606 hi-hat with metallic edge"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 2.2
		var filter_freq = 9000.0 - (4000.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var metallic = sin(2.0 * PI * 14000.0 * t) * exp(-progress * 25.0) * 0.3
		var envelope = exp(-progress * 18.0)
		var sample = (filtered + metallic) * envelope * 0.28
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_acid_606_snare(data: PackedByteArray, sample_count: int):
	"""Acid 606 snare with cyberpunk snap"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.6
		var tone = sin(2.0 * PI * 210.0 * t) * 0.45
		var snap = sin(2.0 * PI * 3800.0 * t) * exp(-progress * 30.0) * 0.35
		var body = sin(2.0 * PI * 180.0 * t) * exp(-progress * 7.0) * 0.25
		var envelope = exp(-progress * 9.5)
		var sample = (noise + tone + snap + body) * envelope * 0.65
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_dark_808_sub_bass(data: PackedByteArray, sample_count: int):
	"""Dark 808 sub bass with cyberpunk modulation"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 38.0 + sin(2.0 * PI * 0.25 * t) * 6.0  # Slow modulation
		var sub = sin(2.0 * PI * freq * t)
		var sub_harmonic = sin(2.0 * PI * freq * 0.5 * t) * 0.7
		var harmonic2 = sin(2.0 * PI * freq * 1.5 * t) * 0.15
		var dystopian_mod = sin(2.0 * PI * 0.13 * t) * 0.4 + 0.6
		var envelope = (1.0 - exp(-progress * 10.0)) * exp(-progress * 0.4)
		var sample = (sub + sub_harmonic + harmonic2) * envelope * dystopian_mod * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_ambient_drone(data: PackedByteArray, sample_count: int):
	"""Dark cyberpunk ambient drone"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var freq1 = 42.0   # Deep fundamental
		var freq2 = 84.0   # Octave
		var freq3 = 63.0   # Perfect fifth
		var freq4 = 126.0  # Higher octave
		var mod = sin(2.0 * PI * 0.11 * t) * 0.4 + 0.6
		var dystopian_sweep = sin(2.0 * PI * 0.03 * t) * 0.2 + 0.8
		
		var layer1 = sin(2.0 * PI * freq1 * t) * 0.6
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.35
		var layer3 = sin(2.0 * PI * freq3 * t) * 0.25
		var layer4 = sin(2.0 * PI * freq4 * t) * 0.15
		var detune = sin(2.0 * PI * (freq1 + 0.8) * t) * 0.12
		var sample = (layer1 + layer2 + layer3 + layer4 + detune) * mod * dystopian_sweep * 0.25
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_glitch_stab(data: PackedByteArray, sample_count: int):
	"""Cyberpunk glitch stab with digital artifacts"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 380.0 * (1.0 + sin(2.0 * PI * 60.0 * t) * 0.4)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0.15 else -1.0
		var digital_noise = 1.0 if randf() > 0.7 else -1.0
		var envelope = exp(-progress * 12.0)
		
		# Heavy bit crushing for cyberpunk feel
		var bit_depth = 5.0
		var crushed = floor(square * pow(2, bit_depth)) / pow(2, bit_depth)
		var glitched = crushed + (digital_noise * 0.2)
		var sample = glitched * envelope * 0.45
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_deep_rumble(data: PackedByteArray, sample_count: int):
	"""Deep cyberpunk city rumble"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var freq = 28.0 + sin(2.0 * PI * 0.08 * t) * 4.0
		var fundamental = sin(2.0 * PI * freq * t)
		var sub_harmonic = sin(2.0 * PI * freq * 0.5 * t) * 0.4
		var industrial_mod = sin(2.0 * PI * 0.3 * t) * 0.3 + 0.7
		var cityscape_pulse = sin(2.0 * PI * 0.05 * t) * 0.2 + 0.8
		var envelope = sin(2.0 * PI * 0.4 * t) * 0.5 + 0.5
		var sample = (fundamental + sub_harmonic) * envelope * industrial_mod * cityscape_pulse * 0.7
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# Enhanced Blade Runner atmospheric sounds

func _generate_blade_runner_hit(data: PackedByteArray, sample_count: int):
	"""Enhanced cinematic Blade Runner atmospheric hit"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Complex harmonic structure for deep cinematic feel
		var freq = 95.0 - (25.0 * pow(progress, 0.3))
		var fundamental = sin(2.0 * PI * freq * t)
		var fifth = sin(2.0 * PI * freq * 1.5 * t) * 0.7
		var octave = sin(2.0 * PI * freq * 2.0 * t) * 0.4
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.6
		var high_harmonic = sin(2.0 * PI * freq * 3.2 * t) * 0.25
		
		# Blade Runner style atmospheric modulation
		var replicant_lfo = sin(2.0 * PI * 0.4 * t) * 0.4 + 0.6
		var dystopian_sweep = sin(2.0 * PI * 0.07 * t) * 0.3 + 0.7
		var reverb_sim = sin(2.0 * PI * freq * 6.0 * t) * exp(-progress * 2.5) * 0.15
		
		# Extended cinematic envelope
		var envelope = exp(-progress * 0.6) * (1.0 - exp(-progress * 20.0))
		var sample = (fundamental + fifth + octave + sub + high_harmonic + reverb_sim) * envelope * replicant_lfo * dystopian_sweep * 0.5
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_cyberpunk_sweep(data: PackedByteArray, sample_count: int):
	"""Cyberpunk frequency sweep for atmosphere"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var start_freq = 200.0
		var end_freq = 800.0
		var freq = start_freq + (end_freq - start_freq) * pow(progress, 0.7)
		
		var saw = 2.0 * (freq * t - floor(freq * t)) - 1.0
		var filter_mod = sin(2.0 * PI * 3.0 * t) * 0.3 + 0.7
		var neon_pulse = sin(2.0 * PI * neon_pulse_rate * t) * 0.2 + 0.8
		var envelope = (1.0 - pow(progress, 2.0)) * exp(-progress * 1.5)
		var sample = saw * filter_mod * neon_pulse * envelope * 0.35
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_neon_pulse(data: PackedByteArray, sample_count: int):
	"""Neon sign pulse effect"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 1200.0 + sin(2.0 * PI * 8.0 * t) * 200.0
		var electric_buzz = sin(2.0 * PI * freq * t)
		var neon_flicker = 1.0 if sin(2.0 * PI * neon_pulse_rate * t) > -0.3 else 0.3
		var voltage_sag = sin(2.0 * PI * 0.5 * t) * 0.15 + 0.85
		var envelope = exp(-progress * 3.0)
		var sample = electric_buzz * neon_flicker * voltage_sag * envelope * 0.25
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_rain_texture(data: PackedByteArray, sample_count: int):
	"""Digital rain texture for cyberpunk atmosphere"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var digital_rain = 0.0
		if randf() < rain_density * 0.1:  # Sparse digital droplets
			digital_rain = (randf() - 0.5) * 2.0
		
		var high_freq_hiss = (randf() - 0.5) * 0.4
		var data_stream = sin(2.0 * PI * 15000.0 * t) * exp(-progress * 8.0) * 0.1
		var matrix_echo = sin(2.0 * PI * 8000.0 * t) * (randf() * 0.2)
		var envelope = 1.0 - (progress * 0.3)
		var sample = (digital_rain + high_freq_hiss + data_stream + matrix_echo) * envelope * 0.2
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_digital_echo(data: PackedByteArray, sample_count: int):
	"""Digital echo effect"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 440.0 * pow(2.0, -progress * 2.0)  # Pitch descending
		var digital_tone = sin(2.0 * PI * freq * t)
		var bit_reduction = floor(digital_tone * 32.0) / 32.0  # Digital artifacts
		var echo_decay = exp(-progress * 6.0)
		var reverb_tail = sin(2.0 * PI * freq * 4.0 * t) * exp(-progress * 4.0) * 0.3
		var sample = (bit_reduction + reverb_tail) * echo_decay * 0.3
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_synthetic_voice(data: PackedByteArray, sample_count: int):
	"""Synthetic replicant voice texture"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Formant-like structure for voice synthesis
		var formant1 = sin(2.0 * PI * 800.0 * t) * 0.6
		var formant2 = sin(2.0 * PI * 1200.0 * t) * 0.4
		var formant3 = sin(2.0 * PI * 2400.0 * t) * 0.2
		var vocal_noise = (randf() - 0.5) * 0.3
		
		var robotic_mod = sin(2.0 * PI * 15.0 * t) * 0.2 + 0.8  # Robotic tremolo
		var synthetic_artifact = sin(2.0 * PI * 50.0 * t) * 0.1
		var envelope = exp(-progress * 1.2) * (1.0 - exp(-progress * 30.0))
		var sample = (formant1 + formant2 + formant3 + vocal_noise + synthetic_artifact) * robotic_mod * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_cityscape_wash(data: PackedByteArray, sample_count: int):
	"""Distant cityscape atmospheric wash"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Multiple layers of distant city sounds
		var traffic_rumble = sin(2.0 * PI * 35.0 * t) * 0.3
		var distant_hum = sin(2.0 * PI * 60.0 * t) * 0.4
		var wind_sweep = sin(2.0 * PI * 0.2 * t) * sin(2.0 * PI * 200.0 * t) * 0.2
		var electrical_buzz = (randf() - 0.5) * 0.15
		
		var urban_pulse = sin(2.0 * PI * 0.1 * t) * 0.3 + 0.7
		var atmospheric_filter = sin(2.0 * PI * 0.05 * t) * 0.2 + 0.8
		var sample = (traffic_rumble + distant_hum + wind_sweep + electrical_buzz) * urban_pulse * atmospheric_filter * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# ===== PUBLIC API =====

func jump_to_section(section: Section):
	"""Jump to a specific section"""
	if not is_playing:
		return
	
	current_section = section
	current_bar = section * 16  # 16 bars per section
	current_step = current_bar * 16
	current_patterns = pattern_library[current_section]
	
	_announce_section_change()
	section_changed.emit(current_section, current_bar)

func set_cyberpunk_parameters(intensity: float, rain: float, neon_rate: float):
	"""Adjust cyberpunk atmosphere parameters"""
	cyberpunk_intensity = clamp(intensity, 0.0, 1.0)
	rain_density = clamp(rain, 0.0, 1.0)
	neon_pulse_rate = clamp(neon_rate, 0.5, 5.0)
	print("🎬 Cyberpunk params: intensity=%.1f%%, rain=%.1f%%, neon_rate=%.1f Hz" % [cyberpunk_intensity * 100, rain_density * 100, neon_pulse_rate])

func get_blade_runner_track_info() -> Dictionary:
	"""Get comprehensive track information"""
	return {
		"is_playing": is_playing,
		"current_bar": current_bar + 1,
		"total_bars": BARS_TOTAL,
		"current_section": current_section,
		"section_name": ["INTRO", "EMERGENCE", "NEON_PULSE", "DIGITAL_RAIN", "VOID_BREAK", "BLADE_STORM", "CLIMAX", "FADE_OUT"][current_section],
		"progress_percent": float(current_bar) / BARS_TOTAL * 100.0,
		"current_step": current_step,
		"total_steps": TOTAL_STEPS,
		"bpm": BPM,
		"cyberpunk_intensity": cyberpunk_intensity,
		"rain_density": rain_density,
		"neon_pulse_rate": neon_pulse_rate,
		"estimated_time_remaining": (TOTAL_STEPS - current_step) * STEP_DURATION
	}

func print_blade_runner_status():
	"""Print detailed track status"""
	var info = get_blade_runner_track_info()
	print("🎬 === BLADE RUNNER 128-BAR EPIC STATUS === 🎬")
	print("   📍 Bar %d of %d (%.1f%% complete)" % [info.current_bar, info.total_bars, info.progress_percent])
	print("   🎭 Section: %s" % info.section_name)
	print("   ⏱️  Time remaining: %.1f minutes" % (info.estimated_time_remaining / 60.0))
	print("   🌆 Cyberpunk intensity: %.1f%%" % (cyberpunk_intensity * 100))
	print("   🌧️  Digital rain density: %.1f%%" % (rain_density * 100))
	print("   💡 Neon pulse rate: %.1f Hz" % neon_pulse_rate)
	print("   🎯 Step: %d / %d" % [info.current_step, info.total_steps])
	print("=======================================")

# Enhanced Input Controls
func _input(event):
	"""Enhanced hotkey controls for Blade Runner epic"""
	if event.is_action_pressed("ui_accept"):  # Space
		if is_playing:
			stop_epic_blade_runner_track()
		else:
			start_epic_blade_runner_track()
	
	elif event.is_action_pressed("ui_select"):  # Enter
		print_blade_runner_status()
	
	elif event.is_action_pressed("ui_cancel"):  # Escape
		if is_playing:
			stop_epic_blade_runner_track()
	
	# Section jumping (1-8 keys)
	elif event.is_action_pressed("ui_1"):
		jump_to_section(Section.INTRO)
	elif event.is_action_pressed("ui_2"):
		jump_to_section(Section.EMERGENCE)
	elif event.is_action_pressed("ui_3"):
		jump_to_section(Section.NEON_PULSE)
	elif event.is_action_pressed("ui_4"):
		jump_to_section(Section.DIGITAL_RAIN)
	elif event.is_action_pressed("ui_5"):
		jump_to_section(Section.VOID_BREAK)
	elif event.is_action_pressed("ui_6"):
		jump_to_section(Section.BLADE_STORM)
	elif event.is_action_pressed("ui_7"):
		jump_to_section(Section.CLIMAX)
	elif event.is_action_pressed("ui_8"):
		jump_to_section(Section.FADE_OUT)
	
	# Cyberpunk parameter controls
	elif event.is_action_pressed("ui_right"):  # Increase cyberpunk intensity
		set_cyberpunk_parameters(cyberpunk_intensity + 0.1, rain_density, neon_pulse_rate)
	elif event.is_action_pressed("ui_left"):   # Decrease cyberpunk intensity
		set_cyberpunk_parameters(cyberpunk_intensity - 0.1, rain_density, neon_pulse_rate)
	elif event.is_action_pressed("ui_up"):     # Increase rain density
		set_cyberpunk_parameters(cyberpunk_intensity, rain_density + 0.1, neon_pulse_rate)
	elif event.is_action_pressed("ui_down"):   # Decrease rain density
		set_cyberpunk_parameters(cyberpunk_intensity, rain_density - 0.1, neon_pulse_rate)
	
	# Handle keyboard input for additional controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R: # R = Increase rain
				set_cyberpunk_parameters(cyberpunk_intensity, rain_density + 0.2, neon_pulse_rate)
			KEY_N: # N = Neon pulse rate
				set_cyberpunk_parameters(cyberpunk_intensity, rain_density, neon_pulse_rate + 0.5)
			KEY_B: # B = Blade Runner mode (max atmosphere)
				set_cyberpunk_parameters(1.0, 0.8, 3.0)
				print("🎬 BLADE RUNNER MODE ACTIVATED")
			KEY_C: # C = Clear atmosphere (minimal)
				set_cyberpunk_parameters(0.2, 0.1, 1.0)
				print("🌆 Minimal atmosphere mode")
			KEY_M: # M = Matrix rain mode
				set_cyberpunk_parameters(0.7, 1.0, 2.5)
				print("💊 MATRIX RAIN MODE")

# ===== JSON CONFIGURATION SYSTEM =====

func load_from_json(json_path: String):
	"""Load enhanced patterns and settings from JSON file"""
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("⚠️ Could not load JSON file: %s" % json_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("⚠️ JSON parse error")
		return
	
	var data = json.data
	
	# Load BPM
	if "bpm" in data:
		BPM = data.bpm
		BEAT_DURATION = 60.0 / BPM
		STEP_DURATION = BEAT_DURATION / 4.0
		if step_timer:
			step_timer.wait_time = STEP_DURATION
		print("   🎵 BPM set to %.0f" % BPM)
	
	# Load 128-bar patterns (expand from 64-step base patterns)
	if "patterns" in data:
		var patterns = data.patterns
		_load_expanded_patterns(patterns)
	
	# Load volumes
	if "volumes" in data:
		var volumes = data.volumes
		_load_volume_settings(volumes)
	
	# Load cyberpunk settings
	if "cyberpunk" in data:
		var cyberpunk = data.cyberpunk
		if "intensity" in cyberpunk:
			cyberpunk_intensity = cyberpunk.intensity
		if "rain_density" in cyberpunk:
			rain_density = cyberpunk.rain_density
		if "neon_pulse_rate" in cyberpunk:
			neon_pulse_rate = cyberpunk.neon_pulse_rate
		print("   🎬 Cyberpunk settings loaded")
	
	# Load track metadata
	if "name" in data:
		print("   📛 Track: %s" % data.name)
	
	print("✅ Loaded complete Blade Runner configuration from %s" % json_path)

func _load_expanded_patterns(patterns: Dictionary):
	"""Load and expand patterns for 128-bar structure"""
	print("   🎵 Loading and expanding patterns for 128-bar structure...")
	
	# Take base patterns and create variations for each section
	var base_kick = patterns.get("kick", [])
	var base_hihat = patterns.get("hihat", [])
	var base_snare = patterns.get("snare", [])
	var base_effect = patterns.get("effect", [])
	var base_blade_runner = patterns.get("blade_runner", [])
	
	if base_kick.size() >= 16:  # Ensure we have at least 16 steps
		# Extract first 16 steps as base pattern and create section variations
		var kick_base = base_kick.slice(0, 16)
		var hihat_base = base_hihat.slice(0, 16) if base_hihat.size() >= 16 else [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0]
		var snare_base = base_snare.slice(0, 16) if base_snare.size() >= 16 else [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0]
		var effect_base = base_effect.slice(0, 16) if base_effect.size() >= 16 else [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		var blade_base = base_blade_runner.slice(0, 16) if base_blade_runner.size() >= 16 else [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		
		# Update patterns in library with base patterns
		_update_section_patterns_from_base(kick_base, hihat_base, snare_base, effect_base, blade_base)
		
		print("   ✅ Patterns expanded and loaded into 8 sections")

func _update_section_patterns_from_base(kick_base: Array, hihat_base: Array, snare_base: Array, effect_base: Array, blade_base: Array):
	"""Update section patterns using base patterns as foundation"""
	
	# INTRO - Use minimal version of base patterns
	pattern_library[Section.INTRO]["kick"] = _reduce_pattern_density(kick_base, 0.3)
	pattern_library[Section.INTRO]["hihat"] = _reduce_pattern_density(hihat_base, 0.4)
	pattern_library[Section.INTRO]["snare"] = _reduce_pattern_density(snare_base, 0.2)
	
	# EMERGENCE - Gradual introduction
	pattern_library[Section.EMERGENCE]["kick"] = _reduce_pattern_density(kick_base, 0.6)
	pattern_library[Section.EMERGENCE]["hihat"] = _reduce_pattern_density(hihat_base, 0.7)
	pattern_library[Section.EMERGENCE]["snare"] = _reduce_pattern_density(snare_base, 0.5)
	
	# NEON_PULSE - Full base patterns
	pattern_library[Section.NEON_PULSE]["kick"] = kick_base.duplicate()
	pattern_library[Section.NEON_PULSE]["hihat"] = hihat_base.duplicate()
	pattern_library[Section.NEON_PULSE]["snare"] = snare_base.duplicate()
	pattern_library[Section.NEON_PULSE]["effect"] = effect_base.duplicate()
	
	# DIGITAL_RAIN - Enhanced patterns
	pattern_library[Section.DIGITAL_RAIN]["kick"] = kick_base.duplicate()
	pattern_library[Section.DIGITAL_RAIN]["hihat"] = _enhance_pattern_density(hihat_base, 1.2)
	pattern_library[Section.DIGITAL_RAIN]["snare"] = snare_base.duplicate()
	pattern_library[Section.DIGITAL_RAIN]["effect"] = _enhance_pattern_density(effect_base, 1.5)
	
	# BLADE_STORM & CLIMAX - Maximum intensity
	pattern_library[Section.BLADE_STORM]["kick"] = _enhance_pattern_density(kick_base, 1.3)
	pattern_library[Section.BLADE_STORM]["hihat"] = hihat_base.duplicate()
	pattern_library[Section.BLADE_STORM]["snare"] = snare_base.duplicate()
	pattern_library[Section.BLADE_STORM]["blade_runner"] = _enhance_pattern_density(blade_base, 2.0)
	
	pattern_library[Section.CLIMAX]["kick"] = _enhance_pattern_density(kick_base, 1.4)
	pattern_library[Section.CLIMAX]["hihat"] = hihat_base.duplicate()
	pattern_library[Section.CLIMAX]["snare"] = _enhance_pattern_density(snare_base, 1.2)
	pattern_library[Section.CLIMAX]["blade_runner"] = _enhance_pattern_density(blade_base, 2.5)

func _reduce_pattern_density(pattern: Array, factor: float) -> Array:
	"""Reduce pattern density for intro/breakdown sections"""
	var reduced = []
	for i in range(pattern.size()):
		if pattern[i] > 0 and randf() < factor:
			reduced.append(pattern[i])
		else:
			reduced.append(0)
	return reduced

func _enhance_pattern_density(pattern: Array, factor: float) -> Array:
	"""Enhance pattern density for climax sections"""
	var enhanced = pattern.duplicate()
	for i in range(enhanced.size()):
		if enhanced[i] == 0 and randf() < (factor - 1.0):
			enhanced[i] = 1
		elif enhanced[i] > 0:
			enhanced[i] = min(enhanced[i] * int(factor), 3)  # Cap at intensity 3
	return enhanced

func _load_volume_settings(volumes: Dictionary):
	"""Load volume settings from JSON"""
	if "kick" in volumes:
		kick_volume = volumes.kick
	if "hihat" in volumes:
		hihat_volume = volumes.hihat
	if "bass" in volumes:
		bass_volume = volumes.bass
	if "ambient" in volumes:
		ambient_volume = volumes.ambient
	if "effect" in volumes:
		effect_volume = volumes.effect
	if "blade_runner" in volumes:
		blade_runner_volume = volumes.blade_runner
	if "atmosphere" in volumes:
		atmosphere_volume = volumes.atmosphere
	if "cityscape" in volumes:
		cityscape_volume = volumes.cityscape
	
	_update_all_volumes()
	print("   🔊 Volume settings applied")

# ===== CONSOLE COMMANDS =====

func play():
	"""Console command: start epic track"""
	start_epic_blade_runner_track()

func stop():
	"""Console command: stop epic track"""
	stop_epic_blade_runner_track()

func status():
	"""Console command: show detailed status"""
	print_blade_runner_status()

func blade_mode():
	"""Console command: activate full Blade Runner atmosphere"""
	set_cyberpunk_parameters(1.0, 0.8, 3.0)
	print("🎬 BLADE RUNNER MODE ACTIVATED - Full cyberpunk atmosphere")

func rain_mode():
	"""Console command: activate digital rain mode"""
	set_cyberpunk_parameters(0.7, 1.0, 2.5)
	print("🌧️ DIGITAL RAIN MODE - Matrix-style atmosphere")

func minimal_mode():
	"""Console command: minimal atmosphere"""
	set_cyberpunk_parameters(0.2, 0.1, 1.0)
	print("🌆 MINIMAL MODE - Sparse cyberpunk elements")

func section_info():
	"""Console command: show section information"""
	var info = get_blade_runner_track_info()
	print("🎬 SECTION INFO 🎬")
	print("   Current: %s (Section %d/8)" % [info.section_name, current_section + 1])
	print("   Bar: %d of %d in this section" % [(current_bar % 16) + 1, 16])
	print("   Total progress: %.1f%%" % info.progress_percent)
	print("   Time in section: %.1f minutes" % (((current_bar % 16) * 4 * BEAT_DURATION) / 60.0))

# ===== ACHIEVEMENT SYSTEM =====

func check_achievements():
	"""Check for various achievements"""
	var info = get_blade_runner_track_info()
	
	if info.progress_percent >= 25.0 and info.progress_percent < 25.1:
		print("🏆 ACHIEVEMENT: Quarter Replicant - 25% complete!")
	elif info.progress_percent >= 50.0 and info.progress_percent < 50.1:
		print("🏆 ACHIEVEMENT: Half Electric Sheep - 50% complete!")
	elif info.progress_percent >= 75.0 and info.progress_percent < 75.1:
		print("🏆 ACHIEVEMENT: Three-Quarter Nexus - 75% complete!")
	elif info.progress_percent >= 100.0:
		print("🏆 ACHIEVEMENT: Full Blade Runner - Epic journey complete!")
		
	if current_section == Section.BLADE_STORM:
		print("🎬 ACHIEVEMENT: Eye of the Storm - Reached maximum Blade Runner intensity!")
	
	if cyberpunk_intensity >= 0.9 and rain_density >= 0.9:
		print("🌧️ ACHIEVEMENT: Digital Monsoon - Maximum cyberpunk atmosphere!")

# ===== AUTO-CONFIG SYSTEM =====

func create_enhanced_json_config() -> String:
	"""Create an enhanced JSON config for 128-bar Blade Runner track"""
	var config = {
		"name": "Dark Blade Runner Epic - 128 Bars",
		"bpm": BPM,
		"description": "Epic cyberpunk journey through 8 evolving sections with Blade Runner atmosphere",
		"total_bars": BARS_TOTAL,
		"sections": 8,
		
		"patterns": {
			"kick":         [0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1],
			"hihat":        [0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0], 
			"snare":        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
			"effect":       [1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"blade_runner": [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		},
		
		"volumes": {
			"kick": kick_volume,
			"hihat": hihat_volume,
			"bass": bass_volume,
			"ambient": ambient_volume,
			"effect": effect_volume,
			"blade_runner": blade_runner_volume,
			"atmosphere": atmosphere_volume,
			"cityscape": cityscape_volume
		},
		
		"cyberpunk": {
			"intensity": cyberpunk_intensity,
			"rain_density": rain_density,
			"neon_pulse_rate": neon_pulse_rate
		},
		
	
	}
	
	var json_string = JSON.stringify(config, "\t")
	print("📄 Enhanced JSON config generated")
	return json_string

func save_current_config(file_path: String):
	"""Save current configuration to JSON file"""
	var json_content = create_enhanced_json_config()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_content)
		file.close()
		print("💾 Configuration saved to: %s" % file_path)
	else:
		print("❌ Failed to save configuration to: %s" % file_path)

# Add automatic achievement checking to step function
func _on_epic_step_with_achievements():
	"""Enhanced step function with achievement checking"""
	_on_epic_step()
	
	# Check achievements every bar
	if current_step % STEPS_PER_BAR == 0:
		check_achievements()
