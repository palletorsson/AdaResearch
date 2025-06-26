# ExtendedSyncopatedTrackPlayer.gd
# 128-bar syncopated track with evolving patterns, breakdowns, and builds
# Focus on rhythmic journey with multiple sections and dynamic changes

extends Node

const SAMPLE_RATE = 44100
const BPM = 110.0
const BEAT_DURATION = 60.0 / BPM
const SIXTEENTH_DURATION = BEAT_DURATION / 4.0
const BARS_TOTAL = 128
const SIXTEENTHS_PER_BAR = 16
const TOTAL_SIXTEENTHS = BARS_TOTAL * SIXTEENTHS_PER_BAR

enum TrackSound {
	SPINE_KICK,
	SPINE_SNARE,
	SPINE_HIHAT,
	GHOST_SNARE,
	ACCENT_KICK,
	SYNCO_PERC,
	OFFBEAT_STAB,
	WEAK_TOM,
	CRASH_CYMBAL,
	RIDE_BELL,
	DEEP_SUB,
	ELECTRIC_SNAP,
	VINYL_CRACKLE,
	REVERSE_SNARE
}

# Audio players with different roles
var spine_player: AudioStreamPlayer
var ghost_player: AudioStreamPlayer
var accent_player: AudioStreamPlayer
var synco_player: AudioStreamPlayer
var offbeat_player: AudioStreamPlayer
var atmospheric_player: AudioStreamPlayer  # For textures
var breakdown_player: AudioStreamPlayer    # For special sections

# Advanced rhythm system
var sixteenth_timer: Timer
var current_sixteenth: int = 0
var current_bar: int = 0
var is_playing: bool = false

# Section definitions (each 16 bars)
enum Section {
	INTRO,       # Bars 1-16: Minimal, building
	GROOVE_A,    # Bars 17-32: Main groove established
	BUILD_1,     # Bars 33-48: First build with fills
	DROP_1,      # Bars 49-64: Full syncopation
	BREAKDOWN_1, # Bars 65-80: Stripped back
	GROOVE_B,    # Bars 81-96: Evolved groove
	BUILD_2,     # Bars 97-112: Final build
	OUTRO        # Bars 113-128: Resolution
}

# Dynamic pattern system - patterns evolve per section
var pattern_library: Dictionary = {}
var current_section: Section = Section.INTRO

# Enhanced swing and groove
@export var base_swing: float = 0.15
@export var swing_evolution: float = 0.02  # Swing changes over time
@export var groove_shuffle: float = 0.05   # Micro-timing variations
@export var humanization: float = 0.03     # Timing imperfection

# Sound cache
var sound_cache: Dictionary = {}

# Volume controls per section
@export var master_volume: float = 0.0
@export var spine_volume: float = -6.0
@export var ghost_volume: float = -18.0
@export var accent_volume: float = -3.0
@export var synco_volume: float = -9.0
@export var offbeat_volume: float = -12.0
@export var atmospheric_volume: float = -15.0

# Performance features
@export var auto_start: bool = true
@export var visual_feedback: bool = true
@export var section_transitions: bool = true

signal track_started()
signal section_changed(new_section: Section, bar: int)
signal syncopation_hit(pattern_name: String, intensity: int, swing_factor: float)
signal breakdown_moment(intensity: float)
signal build_peak(energy: float)

func _ready():
	print("🎵 EXTENDED SYNCOPATED TRACK PLAYER - 128 BARS 🎵")
	print("Epic rhythmic journey with evolving syncopation...")
	print("Total duration: %.1f minutes" % ((BARS_TOTAL * 4 * BEAT_DURATION) / 60.0))
	
	_setup_audio_players()
	_setup_advanced_rhythm_system()
	_initialize_pattern_library()
	_generate_all_sounds()
	
	if auto_start:
		call_deferred("start_epic_track")

func _setup_audio_players():
	"""Setup enhanced player system"""
	
	spine_player = AudioStreamPlayer.new()
	spine_player.name = "SpinePlayer"
	spine_player.bus = "Spine"
	add_child(spine_player)
	
	ghost_player = AudioStreamPlayer.new()
	ghost_player.name = "GhostPlayer"
	ghost_player.bus = "Ghost"
	add_child(ghost_player)
	
	accent_player = AudioStreamPlayer.new()
	accent_player.name = "AccentPlayer"
	accent_player.bus = "Accent"
	add_child(accent_player)
	
	synco_player = AudioStreamPlayer.new()
	synco_player.name = "SyncoPlayer"
	synco_player.bus = "Synco"
	add_child(synco_player)
	
	offbeat_player = AudioStreamPlayer.new()
	offbeat_player.name = "OffbeatPlayer"
	offbeat_player.bus = "Offbeat"
	add_child(offbeat_player)
	
	atmospheric_player = AudioStreamPlayer.new()
	atmospheric_player.name = "AtmosphericPlayer"
	atmospheric_player.bus = "Atmospheric"
	add_child(atmospheric_player)
	
	breakdown_player = AudioStreamPlayer.new()
	breakdown_player.name = "BreakdownPlayer"
	breakdown_player.bus = "Breakdown"
	add_child(breakdown_player)
	
	_update_all_volumes()
	print("   ✅ Enhanced multi-layer audio system ready")

func _setup_advanced_rhythm_system():
	"""Setup precision timing with humanization"""
	
	sixteenth_timer = Timer.new()
	sixteenth_timer.name = "AdvancedSixteenthTimer"
	sixteenth_timer.wait_time = SIXTEENTH_DURATION
	sixteenth_timer.one_shot = false
	sixteenth_timer.timeout.connect(_on_advanced_sixteenth)
	add_child(sixteenth_timer)
	
	print("   ✅ Advanced rhythm system with %.1f%% humanization" % (humanization * 100))

func _initialize_pattern_library():
	"""Create evolving patterns for each section"""
	print("   🎵 Building 128-bar pattern library...")
	
	# INTRO Section (Bars 1-16) - Minimal, building anticipation
	pattern_library[Section.INTRO] = {
		"spine_kick": [3, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0],
		"spine_snare": [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0],
		"ghost_snare": [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1],
		"accent": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"synco_perc": [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0],
		"offbeat_stab": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmospheric": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# GROOVE_A Section (Bars 17-32) - Main groove established
	pattern_library[Section.GROOVE_A] = {
		"spine_kick": [3, 0, 0, 0, 3, 0, 2, 0, 3, 0, 0, 0, 3, 0, 1, 0],
		"spine_snare": [0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0],
		"ghost_snare": [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
		"accent": [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0],
		"synco_perc": [0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
		"offbeat_stab": [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
		"atmospheric": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# BUILD_1 Section (Bars 33-48) - Adding tension and fills
	pattern_library[Section.BUILD_1] = {
		"spine_kick": [3, 0, 0, 1, 3, 0, 2, 0, 3, 0, 1, 0, 3, 1, 2, 0],
		"spine_snare": [0, 0, 0, 0, 3, 0, 0, 1, 0, 0, 1, 0, 3, 0, 1, 0],
		"ghost_snare": [0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0, 1, 0, 2],
		"accent": [0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 2],
		"synco_perc": [0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0],
		"offbeat_stab": [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 3],
		"atmospheric": [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
	}
	
	# DROP_1 Section (Bars 49-64) - Full syncopated power
	pattern_library[Section.DROP_1] = {
		"spine_kick": [3, 0, 1, 0, 3, 0, 3, 0, 3, 1, 0, 1, 3, 0, 2, 1],
		"spine_snare": [0, 0, 0, 1, 3, 0, 0, 2, 0, 0, 1, 0, 3, 1, 0, 0],
		"ghost_snare": [0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2],
		"accent": [0, 0, 2, 3, 0, 0, 0, 2, 0, 0, 3, 0, 0, 0, 2, 3],
		"synco_perc": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		"offbeat_stab": [0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 2, 0, 0, 0, 3],
		"atmospheric": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# BREAKDOWN_1 Section (Bars 65-80) - Stripped back, focus on ghost notes
	pattern_library[Section.BREAKDOWN_1] = {
		"spine_kick": [2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0],
		"spine_snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"ghost_snare": [0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2],
		"accent": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"synco_perc": [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
		"offbeat_stab": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmospheric": [2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# GROOVE_B Section (Bars 81-96) - Evolved groove with new patterns
	pattern_library[Section.GROOVE_B] = {
		"spine_kick": [3, 0, 2, 0, 3, 1, 2, 0, 3, 0, 1, 0, 3, 2, 1, 0],
		"spine_snare": [0, 1, 0, 0, 3, 0, 0, 1, 0, 1, 0, 0, 3, 0, 1, 0],
		"ghost_snare": [0, 1, 0, 2, 0, 1, 0, 1, 0, 1, 0, 2, 0, 1, 0, 1],
		"accent": [0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 2, 0],
		"synco_perc": [0, 1, 2, 0, 0, 1, 2, 0, 0, 1, 2, 0, 0, 1, 2, 0],
		"offbeat_stab": [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2],
		"atmospheric": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	}
	
	# BUILD_2 Section (Bars 97-112) - Final massive build
	pattern_library[Section.BUILD_2] = {
		"spine_kick": [3, 1, 1, 1, 3, 1, 3, 1, 3, 2, 1, 2, 3, 2, 3, 2],
		"spine_snare": [0, 1, 1, 1, 3, 1, 1, 2, 0, 1, 2, 1, 3, 2, 2, 1],
		"ghost_snare": [1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2],
		"accent": [0, 2, 2, 3, 0, 2, 3, 2, 0, 3, 2, 3, 0, 3, 3, 3],
		"synco_perc": [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
		"offbeat_stab": [0, 1, 0, 2, 0, 1, 0, 3, 0, 2, 0, 2, 0, 2, 0, 3],
		"atmospheric": [2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0]
	}
	
	# OUTRO Section (Bars 113-128) - Resolution and fade
	pattern_library[Section.OUTRO] = {
		"spine_kick": [3, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
		"spine_snare": [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
		"ghost_snare": [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0],
		"accent": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"synco_perc": [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"offbeat_stab": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"atmospheric": [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
	}
	
	print("   ✅ Pattern library complete - 8 sections x 16 patterns each")

func _generate_all_sounds():
	"""Generate enhanced sound palette"""
	print("   🔧 Generating enhanced 128-bar sound palette...")
	
	# Core sounds
	sound_cache[TrackSound.SPINE_KICK] = _generate_sound(TrackSound.SPINE_KICK, 0.6)
	sound_cache[TrackSound.SPINE_SNARE] = _generate_sound(TrackSound.SPINE_SNARE, 0.5)
	sound_cache[TrackSound.SPINE_HIHAT] = _generate_sound(TrackSound.SPINE_HIHAT, 0.15)
	sound_cache[TrackSound.GHOST_SNARE] = _generate_sound(TrackSound.GHOST_SNARE, 0.3)
	sound_cache[TrackSound.ACCENT_KICK] = _generate_sound(TrackSound.ACCENT_KICK, 0.8)
	sound_cache[TrackSound.SYNCO_PERC] = _generate_sound(TrackSound.SYNCO_PERC, 0.4)
	sound_cache[TrackSound.OFFBEAT_STAB] = _generate_sound(TrackSound.OFFBEAT_STAB, 0.3)
	sound_cache[TrackSound.WEAK_TOM] = _generate_sound(TrackSound.WEAK_TOM, 0.5)
	
	# Extended sounds for 128-bar journey
	sound_cache[TrackSound.CRASH_CYMBAL] = _generate_sound(TrackSound.CRASH_CYMBAL, 2.0)
	sound_cache[TrackSound.RIDE_BELL] = _generate_sound(TrackSound.RIDE_BELL, 0.4)
	sound_cache[TrackSound.DEEP_SUB] = _generate_sound(TrackSound.DEEP_SUB, 1.0)
	sound_cache[TrackSound.ELECTRIC_SNAP] = _generate_sound(TrackSound.ELECTRIC_SNAP, 0.2)
	sound_cache[TrackSound.VINYL_CRACKLE] = _generate_sound(TrackSound.VINYL_CRACKLE, 0.8)
	sound_cache[TrackSound.REVERSE_SNARE] = _generate_sound(TrackSound.REVERSE_SNARE, 0.7)
	
	print("   ✅ Enhanced sound palette ready - 14 unique sounds")

func start_epic_track():
	"""Start the epic 128-bar journey"""
	if is_playing:
		return
	
	print("🎵 STARTING 128-BAR SYNCOPATED EPIC...")
	print("   💫 Journey through 8 unique sections")
	print("   🎯 Total duration: %.1f minutes" % ((BARS_TOTAL * 4 * BEAT_DURATION) / 60.0))
	print("   🎵 Dynamic swing evolution and humanization")
	
	is_playing = true
	current_sixteenth = 0
	current_bar = 0
	current_section = Section.INTRO
	
	_announce_section_change()
	sixteenth_timer.start()
	track_started.emit()

func stop_epic_track():
	"""Stop the epic track"""
	if not is_playing:
		return
	
	print("⏸️ Stopping epic track at bar %d..." % (current_bar + 1))
	is_playing = false
	sixteenth_timer.stop()
	_stop_all_players()

func _on_advanced_sixteenth():
	"""Advanced sixteenth note handler with evolution"""
	if not is_playing:
		return
	
	# Calculate positions
	var pattern_pos = current_sixteenth % 16
	var bar_pos = current_sixteenth % (16 * BARS_TOTAL)
	current_bar = current_sixteenth / 16
	
	# Check for section changes
	_check_section_transition()
	
	# Calculate dynamic swing with evolution
	var section_progress = float(current_bar % 16) / 16.0
	var current_swing = base_swing + (swing_evolution * section_progress)
	current_swing += sin(current_bar * 0.1) * groove_shuffle  # Groove variation
	
	# Apply humanization (slight timing variation)
	var timing_variation = (randf() - 0.5) * humanization * SIXTEENTH_DURATION
	if pattern_pos % 2 == 1:  # Swing on offbeats
		timing_variation += SIXTEENTH_DURATION * current_swing
	
	if timing_variation > 0:
		await get_tree().create_timer(timing_variation).timeout
	
	# Get current patterns
	var patterns = pattern_library[current_section]
	
	# Play patterns with dynamic intensity based on section
	_play_pattern_element("spine_kick", patterns["spine_kick"][pattern_pos], current_swing, spine_player, TrackSound.SPINE_KICK)
	_play_pattern_element("spine_snare", patterns["spine_snare"][pattern_pos], current_swing, spine_player, TrackSound.SPINE_SNARE)
	_play_pattern_element("ghost_snare", patterns["ghost_snare"][pattern_pos], current_swing, ghost_player, TrackSound.GHOST_SNARE)
	_play_pattern_element("accent", patterns["accent"][pattern_pos], current_swing, accent_player, TrackSound.ACCENT_KICK)
	_play_pattern_element("synco_perc", patterns["synco_perc"][pattern_pos], current_swing, synco_player, TrackSound.SYNCO_PERC)
	_play_pattern_element("offbeat_stab", patterns["offbeat_stab"][pattern_pos], current_swing, offbeat_player, TrackSound.OFFBEAT_STAB)
	_play_pattern_element("atmospheric", patterns["atmospheric"][pattern_pos], current_swing, atmospheric_player, TrackSound.VINYL_CRACKLE)
	
	# Special section-based events
	_handle_section_specials(pattern_pos)
	
	# Progress tracking
	current_sixteenth += 1
	
	# End of track
	if current_sixteenth >= TOTAL_SIXTEENTHS:
		print("🎵 Epic 128-bar track complete! 🎵")
		stop_epic_track()

func _play_pattern_element(name: String, intensity: int, swing_factor: float, player: AudioStreamPlayer, sound: TrackSound):
	"""Play a pattern element with intensity and swing"""
	if intensity > 0:
		player.stream = sound_cache[sound]
		
		# Adjust volume based on intensity and section
		var base_volume = _get_base_volume_for_player(player)
		var intensity_modifier = -((3 - intensity) * 4)  # More intense = louder
		var section_modifier = _get_section_volume_modifier()
		
		player.volume_db = base_volume + intensity_modifier + section_modifier
		player.pitch_scale = 1.0 + (randf() - 0.5) * humanization * 0.1  # Slight pitch variation
		player.play()
		
		syncopation_hit.emit(name, intensity, swing_factor)

func _check_section_transition():
	"""Check if we need to transition to a new section"""
	var new_section = _get_section_for_bar(current_bar)
	
	if new_section != current_section:
		current_section = new_section
		_announce_section_change()
		section_changed.emit(current_section, current_bar)

func _get_section_for_bar(bar: int) -> Section:
	"""Determine section based on bar number"""
	if bar < 16: return Section.INTRO
	elif bar < 32: return Section.GROOVE_A
	elif bar < 48: return Section.BUILD_1
	elif bar < 64: return Section.DROP_1
	elif bar < 80: return Section.BREAKDOWN_1
	elif bar < 96: return Section.GROOVE_B
	elif bar < 112: return Section.BUILD_2
	else: return Section.OUTRO

func _announce_section_change():
	"""Announce the current section"""
	var section_names = [
		"INTRO - Building tension...",
		"GROOVE A - Main pattern established",
		"BUILD 1 - Adding complexity...",
		"DROP 1 - Full syncopated power!",
		"BREAKDOWN 1 - Stripped back focus",
		"GROOVE B - Evolved patterns",
		"BUILD 2 - Final massive build...",
		"OUTRO - Resolution and fade"
	]
	
	print("🎵 Section %d: %s (Bar %d)" % [current_section + 1, section_names[current_section], current_bar + 1])

func _handle_section_specials(pattern_pos: int):
	"""Handle special events per section"""
	match current_section:
		Section.BUILD_1, Section.BUILD_2:
			# Build tension with additional elements
			if pattern_pos == 0 and (current_bar % 4) == 3:  # Every 4th bar
				accent_player.stream = sound_cache[TrackSound.CRASH_CYMBAL]
				accent_player.volume_db = accent_volume
				accent_player.play()
				build_peak.emit(float(current_section) / 7.0)
		
		Section.BREAKDOWN_1:
			# Add atmospheric texture
			if pattern_pos == 0 and (current_bar % 8) == 0:
				atmospheric_player.stream = sound_cache[TrackSound.REVERSE_SNARE]
				atmospheric_player.volume_db = atmospheric_volume
				atmospheric_player.play()
				breakdown_moment.emit(0.3)
		
		Section.DROP_1:
			# Add deep sub hits
			if pattern_pos % 4 == 0 and randf() < 0.3:
				breakdown_player.stream = sound_cache[TrackSound.DEEP_SUB]
				breakdown_player.volume_db = master_volume
				breakdown_player.play()

func _get_base_volume_for_player(player: AudioStreamPlayer) -> float:
	"""Get base volume for player type"""
	match player.name:
		"SpinePlayer": return spine_volume
		"GhostPlayer": return ghost_volume
		"AccentPlayer": return accent_volume
		"SyncoPlayer": return synco_volume
		"OffbeatPlayer": return offbeat_volume
		"AtmosphericPlayer": return atmospheric_volume
		"BreakdownPlayer": return master_volume
		_: return master_volume

func _get_section_volume_modifier() -> float:
	"""Get volume modifier based on current section"""
	match current_section:
		Section.INTRO: return -6.0
		Section.GROOVE_A: return 0.0
		Section.BUILD_1: return 2.0
		Section.DROP_1: return 4.0
		Section.BREAKDOWN_1: return -8.0
		Section.GROOVE_B: return 1.0
		Section.BUILD_2: return 6.0
		Section.OUTRO: return -12.0
		_: return 0.0

func _update_all_volumes():
	"""Update all player volumes"""
	spine_player.volume_db = spine_volume + master_volume
	ghost_player.volume_db = ghost_volume + master_volume
	accent_player.volume_db = accent_volume + master_volume
	synco_player.volume_db = synco_volume + master_volume
	offbeat_player.volume_db = offbeat_volume + master_volume
	atmospheric_player.volume_db = atmospheric_volume + master_volume
	breakdown_player.volume_db = master_volume

func _stop_all_players():
	"""Stop all audio players"""
	spine_player.stop()
	ghost_player.stop()
	accent_player.stop()
	synco_player.stop()
	offbeat_player.stop()
	atmospheric_player.stop()
	breakdown_player.stop()

func _generate_sound(sound_type: TrackSound, duration: float) -> AudioStreamWAV:
	"""Generate enhanced sounds for 128-bar epic"""
	
	var sample_count = int(SAMPLE_RATE * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	match sound_type:
		TrackSound.SPINE_KICK:
			_generate_spine_kick(data, sample_count)
		TrackSound.SPINE_SNARE:
			_generate_spine_snare(data, sample_count)
		TrackSound.SPINE_HIHAT:
			_generate_spine_hihat(data, sample_count)
		TrackSound.GHOST_SNARE:
			_generate_ghost_snare(data, sample_count)
		TrackSound.ACCENT_KICK:
			_generate_accent_kick(data, sample_count)
		TrackSound.SYNCO_PERC:
			_generate_synco_perc(data, sample_count)
		TrackSound.OFFBEAT_STAB:
			_generate_offbeat_stab(data, sample_count)
		TrackSound.WEAK_TOM:
			_generate_weak_tom(data, sample_count)
		TrackSound.CRASH_CYMBAL:
			_generate_crash_cymbal(data, sample_count)
		TrackSound.RIDE_BELL:
			_generate_ride_bell(data, sample_count)
		TrackSound.DEEP_SUB:
			_generate_deep_sub(data, sample_count)
		TrackSound.ELECTRIC_SNAP:
			_generate_electric_snap(data, sample_count)
		TrackSound.VINYL_CRACKLE:
			_generate_vinyl_crackle(data, sample_count)
		TrackSound.REVERSE_SNARE:
			_generate_reverse_snare(data, sample_count)
	
	stream.data = data
	return stream

# Enhanced sound generators for epic track

func _generate_spine_kick(data: PackedByteArray, sample_count: int):
	"""Enhanced spine kick with more body"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 75.0 - (35.0 * pow(progress, 0.25))
		var sine = sin(2.0 * PI * freq * t)
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.4  # Sub harmonic
		var click = sin(2.0 * PI * 2000.0 * t) * exp(-progress * 45.0) * 0.2
		var punch = sin(2.0 * PI * 120.0 * t) * exp(-progress * 8.0) * 0.3
		var envelope = exp(-progress * 4.5)
		var sample = tanh((sine + sub + click + punch) * envelope * 1.3) * 0.8
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_spine_snare(data: PackedByteArray, sample_count: int):
	"""Enhanced spine snare with more crack"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 1.8
		var tone = sin(2.0 * PI * 220.0 * t) * 0.5
		var snap = sin(2.0 * PI * 4000.0 * t) * exp(-progress * 35.0) * 0.4
		var body = sin(2.0 * PI * 180.0 * t) * exp(-progress * 6.0) * 0.3
		var envelope = exp(-progress * 9.0)
		var sample = (noise + tone + snap + body) * envelope * 0.7
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_spine_hihat(data: PackedByteArray, sample_count: int):
	"""Crisp hi-hat for spine beat"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 2.0
		var filter_freq = 12000.0 - (4000.0 * progress)
		var filtered = noise * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var envelope = exp(-progress * 20.0)
		var sample = filtered * envelope * 0.25
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_ghost_snare(data: PackedByteArray, sample_count: int):
	"""Subtle ghost snare for texture"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 0.9
		var tone = sin(2.0 * PI * 190.0 * t) * 0.25
		var envelope = exp(-progress * 15.0)
		var sample = (noise + tone) * envelope * 0.35
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_accent_kick(data: PackedByteArray, sample_count: int):
	"""Powerful accent kick with more impact"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 85.0 - (40.0 * pow(progress, 0.2))
		var sine = sin(2.0 * PI * freq * t)
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.5
		var click = sin(2.0 * PI * 2500.0 * t) * exp(-progress * 50.0) * 0.3
		var distortion = tanh(sine * 2.0) * 0.4
		var envelope = exp(-progress * 3.5)
		var sample = tanh((sine + sub + click + distortion) * envelope * 2.2) * 0.95
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_synco_perc(data: PackedByteArray, sample_count: int):
	"""Syncopated percussion with metallic character"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 700.0 - (250.0 * progress)
		var triangle = (2.0 / PI) * asin(sin(2.0 * PI * freq * t))
		var metallic = sin(2.0 * PI * freq * 2.1 * t) * 0.3  # Slightly detuned
		var noise = (randf() - 0.5) * 0.4
		var envelope = exp(-progress * 10.0)
		var sample = (triangle + metallic + noise) * envelope * 0.5
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_offbeat_stab(data: PackedByteArray, sample_count: int):
	"""Sharp offbeat stab with analog character"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 350.0 * (1.0 + sin(2.0 * PI * 50.0 * t) * 0.3)
		var saw = 2.0 * (freq * t - floor(freq * t)) - 1.0  # Sawtooth wave
		var filter_cutoff = 800.0 - (400.0 * progress)
		var filtered = saw * sin(2.0 * PI * filter_cutoff * t / SAMPLE_RATE)
		var envelope = exp(-progress * 15.0)
		var sample = filtered * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_weak_tom(data: PackedByteArray, sample_count: int):
	"""Weak tom for subtle fills"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 160.0 - (60.0 * progress)
		var sine = sin(2.0 * PI * freq * t)
		var noise = (randf() - 0.5) * 0.5
		var body = sin(2.0 * PI * freq * 0.8 * t) * 0.3
		var envelope = exp(-progress * 7.0)
		var sample = (sine + noise + body) * envelope * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# New enhanced sounds for 128-bar epic

func _generate_crash_cymbal(data: PackedByteArray, sample_count: int):
	"""Epic crash cymbal for section transitions"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var noise = (randf() - 0.5) * 2.5
		var shimmer = sin(2.0 * PI * 8000.0 * t) * exp(-progress * 2.0) * 0.4
		var body = sin(2.0 * PI * 400.0 * t) * exp(-progress * 5.0) * 0.3
		var sizzle = noise * sin(2.0 * PI * 15000.0 * t / SAMPLE_RATE) * 0.6
		var envelope = exp(-progress * 1.5)
		var sample = (noise + shimmer + body + sizzle) * envelope * 0.8
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_ride_bell(data: PackedByteArray, sample_count: int):
	"""Bright ride bell for accents"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 1800.0
		var bell = sin(2.0 * PI * freq * t)
		var harmonics = sin(2.0 * PI * freq * 2.3 * t) * 0.4 + sin(2.0 * PI * freq * 3.7 * t) * 0.2
		var ring = sin(2.0 * PI * freq * 5.1 * t) * 0.15
		var envelope = exp(-progress * 8.0)
		var sample = (bell + harmonics + ring) * envelope * 0.5
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_deep_sub(data: PackedByteArray, sample_count: int):
	"""Deep sub-bass for power moments"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 45.0 - (15.0 * pow(progress, 0.5))
		var sine = sin(2.0 * PI * freq * t)
		var sub_harmonics = sin(2.0 * PI * freq * 0.5 * t) * 0.6
		var rumble = sin(2.0 * PI * freq * 1.5 * t) * 0.3
		var envelope = exp(-progress * 2.0)
		var sample = tanh((sine + sub_harmonics + rumble) * envelope * 1.8) * 0.9
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_electric_snap(data: PackedByteArray, sample_count: int):
	"""Electric snap for modern flavor"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 2200.0 + sin(2.0 * PI * 80.0 * t) * 400.0
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0.2 else -1.0
		var noise = (randf() - 0.5) * 0.8
		var electric = square * (1.0 + noise * 0.5)
		var envelope = exp(-progress * 25.0)
		var sample = electric * envelope * 0.4
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_vinyl_crackle(data: PackedByteArray, sample_count: int):
	"""Atmospheric vinyl crackle texture"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var crackle = 0.0
		if randf() < 0.02:  # Random pops
			crackle = (randf() - 0.5) * 2.0
		
		var hiss = (randf() - 0.5) * 0.3
		var filter_freq = 8000.0 - (2000.0 * progress)
		var filtered = hiss * sin(2.0 * PI * filter_freq * t / SAMPLE_RATE)
		var envelope = 1.0 - (progress * 0.5)
		var sample = (crackle + filtered) * envelope * 0.15
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

func _generate_reverse_snare(data: PackedByteArray, sample_count: int):
	"""Reverse snare for breakdown atmosphere"""
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var reverse_progress = 1.0 - progress  # Reverse the envelope
		
		var noise = (randf() - 0.5) * 1.5
		var tone = sin(2.0 * PI * 240.0 * t) * 0.4
		var sweep = sin(2.0 * PI * (500.0 + progress * 1000.0) * t) * 0.3
		var envelope = exp(-reverse_progress * 6.0)  # Build up instead of decay
		var sample = (noise + tone + sweep) * envelope * 0.6
		
		var int_sample = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_sample & 0xFF
		data[i * 2 + 1] = (int_sample >> 8) & 0xFF

# Public API and Controls

func jump_to_section(section: Section):
	"""Jump to a specific section"""
	if not is_playing:
		return
	
	current_section = section
	current_bar = section * 16  # 16 bars per section
	current_sixteenth = current_bar * 16
	
	_announce_section_change()
	section_changed.emit(current_section, current_bar)

func set_dynamic_swing(base: float, evolution: float, shuffle: float):
	"""Adjust swing parameters"""
	base_swing = clamp(base, 0.0, 0.5)
	swing_evolution = clamp(evolution, 0.0, 0.1)
	groove_shuffle = clamp(shuffle, 0.0, 0.1)
	print("🎵 Swing updated: base=%.1f%%, evolution=%.1f%%, shuffle=%.1f%%" % [base_swing * 100, swing_evolution * 100, groove_shuffle * 100])

func set_humanization(amount: float):
	"""Adjust humanization amount"""
	humanization = clamp(amount, 0.0, 0.1)
	print("🎵 Humanization set to %.1f%%" % (humanization * 100))

func get_epic_track_info() -> Dictionary:
	"""Get comprehensive track information"""
	return {
		"is_playing": is_playing,
		"current_bar": current_bar + 1,
		"total_bars": BARS_TOTAL,
		"current_section": current_section,
		"section_name": ["INTRO", "GROOVE_A", "BUILD_1", "DROP_1", "BREAKDOWN_1", "GROOVE_B", "BUILD_2", "OUTRO"][current_section],
		"progress_percent": float(current_bar) / BARS_TOTAL * 100.0,
		"current_sixteenth": current_sixteenth,
		"total_sixteenths": TOTAL_SIXTEENTHS,
		"swing_settings": {
			"base_swing": base_swing,
			"swing_evolution": swing_evolution,
			"groove_shuffle": groove_shuffle,
			"humanization": humanization
		},
		"estimated_time_remaining": (TOTAL_SIXTEENTHS - current_sixteenth) * SIXTEENTH_DURATION
	}

func print_epic_status():
	"""Print detailed track status"""
	var info = get_epic_track_info()
	print("🎵 === EPIC 128-BAR TRACK STATUS === 🎵")
	print("   📍 Bar %d of %d (%.1f%% complete)" % [info.current_bar, info.total_bars, info.progress_percent])
	print("   🎭 Section: %s" % info.section_name)
	print("   ⏱️  Time remaining: %.1f minutes" % (info.estimated_time_remaining / 60.0))
	print("   🎵 Swing: %.1f%% + %.1f%% evolution + %.1f%% shuffle" % [base_swing * 100, swing_evolution * 100, groove_shuffle * 100])
	print("   🤖 Humanization: %.1f%%" % (humanization * 100))
	print("   🎯 16th note: %d / %d" % [info.current_sixteenth, info.total_sixteenths])
	print("================================")

# Enhanced Input Controls
func _input(event):
	"""Enhanced hotkey controls for epic track"""
	if event.is_action_pressed("ui_accept"):  # Space
		if is_playing:
			stop_epic_track()
		else:
			start_epic_track()
	
	elif event.is_action_pressed("ui_select"):  # Enter
		print_epic_status()
	
	elif event.is_action_pressed("ui_cancel"):  # Escape
		if is_playing:
			stop_epic_track()
	
	# Section jumping (1-8 keys)
	elif event.is_action_pressed("ui_1"):
		jump_to_section(Section.INTRO)
	elif event.is_action_pressed("ui_2"):
		jump_to_section(Section.GROOVE_A)
	elif event.is_action_pressed("ui_3"):
		jump_to_section(Section.BUILD_1)
	elif event.is_action_pressed("ui_4"):
		jump_to_section(Section.DROP_1)
	elif event.is_action_pressed("ui_5"):
		jump_to_section(Section.BREAKDOWN_1)
	elif event.is_action_pressed("ui_6"):
		jump_to_section(Section.GROOVE_B)
	elif event.is_action_pressed("ui_7"):
		jump_to_section(Section.BUILD_2)
	elif event.is_action_pressed("ui_8"):
		jump_to_section(Section.OUTRO)
	
	# Swing controls
	elif event.is_action_pressed("ui_right"):  # Increase swing
		set_dynamic_swing(base_swing + 0.02, swing_evolution, groove_shuffle)
	elif event.is_action_pressed("ui_left"):   # Decrease swing
		set_dynamic_swing(base_swing - 0.02, swing_evolution, groove_shuffle)
	elif event.is_action_pressed("ui_up"):     # More humanization
		set_humanization(humanization + 0.01)
	elif event.is_action_pressed("ui_down"):   # Less humanization
		set_humanization(humanization - 0.01)
