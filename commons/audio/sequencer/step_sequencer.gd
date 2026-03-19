extends Node3D
class_name StepSequencer

# @identity
# essence: 2D boolean array[track][step] where each 1 triggers a sound at BPM-derived intervals — a physical 16-step × 4-track drum machine rendered in 3D, where toggling a cell means "play this sound at this beat"
# desire: to feel rhythm as a 2D array — to toggle cells on a physical 16-step grid and hear your pattern play back, discovering that a drum pattern is just a boolean matrix traversed column by column at a fixed tempo
# critical_parameter: sound_preset — determines which 4 sounds fill the tracks; "house" gives TR909 kick + M1 piano + hi-hat + TB303 acid bass, turning the array into a culturally specific musical grammar
# triggers: BPM controls the column-advance rate; step_triggered(track, step) fires on every active cell; the "house" preset carries the cultural memory of 1990s house music into the abstract array demonstration
# emerges: students discover that musical style is a distribution over the boolean array — house music has kick on beats 1&3, and this pattern emerges from which cells are toggled; the array encodes cultural knowledge
# needs: SequencerUI [has via SubViewport2Din3D]; AudioSynthesizer [has]; CustomSoundGenerator [has]; VR interaction for toggling cells [has]; BPM control [has]; no VR slider_horizontal [missing — uses internal UI]
# relationships: paired with StandaloneDiscoFloor in Tutorial_Disco for the full arrays-as-music synthesis; house preset references Gypsy Woman/Crystal Waters production style; connects to step sequencer in audio rack
# truth: a step sequencer is a for-loop over time — the array of steps is executed rhythmically, and music is what happens when a boolean array runs at 120 BPM

## 3D Step Sequencer
## Wraps SequencerUI in Viewport2Din3D for VR/3D interaction
## Handles audio playback

const AudioSynthesizer := preload("res://commons/audio/generators/AudioSynthesizer.gd")
const CustomSoundGenerator := preload("res://commons/audio/generators/CustomSoundGenerator.gd")

@export var num_tracks: int = 4
@export var num_steps: int = 16
@export var bpm: float = 120.0
@export var sound_preset: String = "808_kit"
@export var auto_play: bool = false

## Signals
signal step_triggered(track: int, step: int)
signal playback_started()
signal playback_stopped()

## Sound presets mapping
const SOUND_PRESETS: Dictionary = {
	"808_kit": [
		"DARK_808_KICK",
		"TR909_KICK",
		"ACID_606_HIHAT",
		"DARK_808_SUB_BASS"
	],
	"trap_beats": [
		"DARK_808_KICK",
		"EXPLOSION",
		"ACID_606_HIHAT",
		"SHIELD_HIT"
	],
	"synth_kit": [
		"TB303_ACID_BASS",
		"MOOG_BASS_LEAD",
		"DX7_ELECTRIC_PIANO",
		"PPG_WAVE_PAD"
	],
	"tech_noir": [
		"MELODIC_DRONE",
		"GHOST_DRONE",
		"AMBIENT_WIND",
		"TELEPORT_DRONE"
	],
	"retro": [
		"C64_SID_LEAD",
		"AMIGA_MOD_SAMPLE",
		"RETRO_JUMP",
		"PICKUP_MARIO"
	],
	"90s_house": [
		# Gypsy Woman / Crystal Waters style - Basement Boys production
		"TR909_KICK",        # Punchy house kick
		"KORG_M1_PIANO",     # The iconic M1 piano stab
		"ACID_606_HIHAT",    # Crisp hi-hats
		"TB303_ACID_BASS"    # Squelchy acid bassline
	],
	"juno_pads": [
		# Lush analog pad sounds - slow builds, atmospheric
		"POP_JUNO_CHORUS_PAD",  # Roland Juno-106 lush pad
		"JUPITER_8_STRINGS",    # Jupiter string ensemble
		"PPG_WAVE_PAD",         # PPG wavetable warmth
		"CINEMATIC_432HZ_PAD"   # Deep cinematic pad
	],
	"kraftwerk": [
		# 1970s Germany - Birth of electronic music, sequencers as instruments
		"MOOG_KRAFTWERK_SEQUENCER",  # The iconic sequencer pulse
		"TR909_KICK",                # Clean electronic kick
		"ACID_606_HIHAT",            # Precise hi-hats
		"MOOG_BASS_LEAD"             # Analog bass
	],
	"disco": [
		# 1970s - Groove, four-on-floor, funky percussion
		"TR909_KICK",           # Punchy disco kick
		"SYNARE_3_DISCO_TOM",   # Classic disco tom
		"ACID_606_HIHAT",       # Crisp hi-hats
		"POP_FUNK_BASS"         # Funky bass
	],
	"ambient_works": [
		# 1990s Aphex Twin style - Texture, space, less-is-more
		"APHEX_TWIN_MODULAR",   # Complex modular textures
		"PPG_WAVE_PAD",         # Wavetable warmth
		"GHOST_DRONE",          # Ethereal atmosphere
		"MELODIC_DRONE"         # Melodic background
	],
	"jazz_fusion": [
		# 1970s Herbie Hancock - Jazz meets electronics
		"HERBIE_HANCOCK_MOOG_FUSION",  # Jazz-funk Moog
		"DX7_ELECTRIC_PIANO",          # Rhodes-like FM piano
		"POP_FUNK_BASS",               # Walking/funk bass
		"TR909_KICK"                   # Light percussion
	],
	"chiptune": [
		# 1980s - Constraints breed creativity, 8-bit aesthetics
		"C64_SID_LEAD",         # Commodore 64 lead
		"AMIGA_MOD_SAMPLE",     # Amiga tracker
		"RETRO_JUMP",           # Classic jump sound
		"PICKUP_MARIO"          # Iconic pickup
	],
	"sci_fi_lab": [
		# Timeless - Sound design, atmosphere, world-building
		"SCI_FI_LAB_HUM_CLEAN",     # Sterile lab hum
		"SCI_FI_DATA_CHIRPS",       # Computer activity
		"SCI_FI_ELECTROMAGNETIC",   # Tech interference
		"SCI_FI_VENTILATION"        # Air texture
	],
	"cinematic": [
		# 1980s+ Blade Runner - Film scoring, Vangelis influence
		"CS80_BRASS_LEAD",          # Blade Runner brass
		"CINEMATIC_432HZ_PAD",      # Deep cinematic pad
		"JUPITER_8_STRINGS",        # Lush strings
		"MELODIC_DRONE"             # Tension drone
	],
	"breakbeat": [
		# 1990s - Syncopation, sampling culture, jungle/DnB
		"DARK_808_KICK",        # Punchy kick
		"TR909_KICK",           # Snare-like hit
		"ACID_606_HIHAT",       # Fast hi-hats
		"FLYING_LOTUS_SAMPLER"  # Chopped samples
	],
	"cosmic": [
		# 1970s-80s Space disco - Jean-Michel Jarre, Tangerine Dream
		"SYNARE_3_COSMIC_FX",   # Cosmic percussion FX
		"ARP_2600_LEAD",        # Classic ARP lead
		"TELEPORT_DRONE",       # Space drone
		"PPG_WAVE_PAD"          # Wavetable pad
	],
	"lo_fi": [
		# 2010s+ - Nostalgia, imperfection as aesthetic
		"DX7_ELECTRIC_PIANO",   # Warm FM piano
		"DARK_808_KICK",        # Mellow kick
		"AMBIENT_WIND",         # Vinyl crackle feel
		"POP_JUNO_CHORUS_PAD"   # Warm pad
	]
}

## Pattern presets - pre-filled drum patterns by genre
const PATTERN_PRESETS: Dictionary = {
	"four_on_floor": {
		# Classic house/techno kick pattern
		"kick":  [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0],
		"snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0],
		"hihat": [0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0],
		"bass":  [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1]
	},
	"techno": {
		"kick":  [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0],
		"snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0],
		"hihat": [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
		"bass":  [1,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0]
	},
	"house": {
		"kick":  [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0],
		"snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0],
		"hihat": [0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0],
		"bass":  [1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0]
	},
	"trap": {
		# Syncopated kick, rapid hi-hats
		"kick":  [1,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0],
		"snare": [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0],
		"hihat": [1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1],
		"bass":  [1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0]
	},
	"breakbeat": {
		# Broken, syncopated rhythm
		"kick":  [1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0],
		"snare": [0,0,0,0,1,0,0,0,0,1,0,0,1,0,0,0],
		"hihat": [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
		"bass":  [1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0]
	},
	"minimal": {
		# Sparse, space-focused
		"kick":  [1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0],
		"snare": [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0],
		"hihat": [0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1],
		"bass":  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
	},
	"disco": {
		# Funky four-on-floor with offbeat hi-hats
		"kick":  [1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0],
		"snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0],
		"hihat": [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
		"bass":  [1,0,0,1,0,0,1,0,1,0,0,1,0,0,1,0]
	},
	"dnb": {
		# Fast, two-step pattern (160+ BPM feel)
		"kick":  [1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0],
		"snare": [0,0,0,0,1,0,0,0,0,0,0,0,1,0,1,0],
		"hihat": [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
		"bass":  [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0]
	},
	"ambient": {
		# Very sparse, textural
		"kick":  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		"snare": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		"hihat": [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
		"bass":  [1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0]
	},
	"empty": {
		# Blank slate
		"kick":  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		"snare": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		"hihat": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		"bass":  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
	}
}

## Internal state
var _sequencer_ui: SequencerUI
var _is_playing: bool = false
var _playhead_position: int = 0
var _step_timer: float = 0.0
var _step_interval: float = 0.5
var _track_sounds: Array = []
var _audio_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_load_sound_preset(sound_preset)
	_create_audio_players()
	_update_step_interval()

	# Find the SequencerUI in viewport
	_find_sequencer_ui()

	if auto_play:
		play()


func _find_sequencer_ui() -> void:
	# Look for Viewport2Din3D child and get its scene
	for child in get_children():
		if child.name == "Viewport2Din3D":
			var viewport = child.get_node_or_null("Viewport")
			if viewport:
				for vp_child in viewport.get_children():
					if vp_child is SequencerUI:
						_sequencer_ui = vp_child
						_connect_ui_signals()
						return

	# Also check for direct SequencerUI (testing)
	var direct_ui = get_node_or_null("SequencerUI")
	if direct_ui is SequencerUI:
		_sequencer_ui = direct_ui
		_connect_ui_signals()


func _connect_ui_signals() -> void:
	if not _sequencer_ui:
		return

	_sequencer_ui.cell_toggled.connect(_on_cell_toggled)
	_sequencer_ui.playback_toggled.connect(_on_playback_toggled)
	_sequencer_ui.bpm_changed.connect(_on_bpm_changed)
	_sequencer_ui.preset_changed.connect(_on_preset_changed)
	_sequencer_ui.pattern_preset_changed.connect(_on_pattern_preset_changed)


func _on_cell_toggled(track: int, step: int, active: bool) -> void:
	# Play preview sound when activating
	if active:
		_play_sound(track)


func _on_playback_toggled(playing: bool) -> void:
	if playing:
		play()
	else:
		stop()


func _on_bpm_changed(new_bpm: float) -> void:
	bpm = new_bpm
	_update_step_interval()


func _on_preset_changed(preset_name: String) -> void:
	sound_preset = preset_name
	_load_sound_preset(preset_name)


func _on_pattern_preset_changed(preset_name: String) -> void:
	load_pattern_preset(preset_name)


func _process(delta: float) -> void:
	if not _is_playing:
		return

	_step_timer += delta

	if _step_timer >= _step_interval:
		_step_timer -= _step_interval
		_advance_playhead()


func _resolve_sound_type(sound_name: String) -> int:
	if sound_name in AudioSynthesizer.SoundType:
		return AudioSynthesizer.SoundType[sound_name]
	return AudioSynthesizer.SoundType.BASIC_SINE_WAVE


func _load_sound_preset(preset_name: String) -> void:
	var preset_sound_names: Array = SOUND_PRESETS.get(preset_name, SOUND_PRESETS["808_kit"])
	_track_sounds.clear()

	for sound_name in preset_sound_names:
		_track_sounds.append(_resolve_sound_type(str(sound_name)))

	# Pad if needed
	while _track_sounds.size() < num_tracks:
		_track_sounds.append(_track_sounds[0] if _track_sounds.size() > 0 else _resolve_sound_type("BASIC_SINE_WAVE"))


func _create_audio_players() -> void:
	for i in range(num_tracks):
		var player = AudioStreamPlayer.new()
		player.name = "TrackPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_audio_players.append(player)


func _update_step_interval() -> void:
	var beats_per_second = bpm / 60.0
	var steps_per_second = beats_per_second * 4.0  # 16th notes
	_step_interval = 1.0 / steps_per_second


func _advance_playhead() -> void:
	# Trigger sounds for current step
	if _sequencer_ui:
		var active_tracks = _sequencer_ui.get_active_tracks(_playhead_position)
		for track in active_tracks:
			_play_sound(track)
			step_triggered.emit(track, _playhead_position)

	# Move playhead
	_playhead_position = (_playhead_position + 1) % num_steps

	# Update UI
	if _sequencer_ui:
		_sequencer_ui.set_playhead(_playhead_position)


func _play_sound(track: int) -> void:
	if track >= _audio_players.size() or track >= _track_sounds.size():
		return

	var player = _audio_players[track]
	var sound_type = _track_sounds[track]

	var params = {"duration": 0.2}
	var audio_stream = CustomSoundGenerator.generate_custom_sound(sound_type, params)

	if audio_stream:
		player.stream = audio_stream
		player.play()


## Public API

func play() -> void:
	_is_playing = true
	_step_timer = 0.0
	_playhead_position = 0
	if _sequencer_ui:
		_sequencer_ui.set_playing(true)
		_sequencer_ui.set_playhead(0)
	playback_started.emit()


func stop() -> void:
	_is_playing = false
	if _sequencer_ui:
		_sequencer_ui.set_playing(false)
	playback_stopped.emit()


func toggle_playback() -> void:
	if _is_playing:
		stop()
	else:
		play()


## Load a pattern preset onto the grid
func load_pattern_preset(preset_name: String) -> void:
	if not preset_name in PATTERN_PRESETS:
		return

	var pattern = PATTERN_PRESETS[preset_name]
	var track_names = ["kick", "snare", "hihat", "bass"]

	if _sequencer_ui:
		# Clear existing pattern first
		_sequencer_ui.clear_pattern()

		# Load new pattern
		for track_idx in range(mini(track_names.size(), num_tracks)):
			var track_name = track_names[track_idx]
			if track_name in pattern:
				for step in range(mini(pattern[track_name].size(), num_steps)):
					var active = pattern[track_name][step] == 1
					_sequencer_ui.set_cell(track_idx, step, active)


## Config system for grid artifact

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_tracks"):
		num_tracks = int(config_data["num_tracks"])

	if config_data.has("num_steps"):
		num_steps = int(config_data["num_steps"])

	if config_data.has("bpm"):
		bpm = float(config_data["bpm"])
		_update_step_interval()

	if config_data.has("sound_preset"):
		sound_preset = str(config_data["sound_preset"])
		_load_sound_preset(sound_preset)

	if config_data.has("auto_play"):
		auto_play = _to_bool(config_data["auto_play"])

	if config_data.has("pattern_preset"):
		# Defer pattern loading until after UI is ready
		call_deferred("load_pattern_preset", str(config_data["pattern_preset"]))

	# Shorthand parsing
	for key in config_data.keys():
		var parsed = _parse_shorthand(key)
		if parsed.has("num_tracks"):
			num_tracks = parsed["num_tracks"]
		if parsed.has("num_steps"):
			num_steps = parsed["num_steps"]
		if parsed.has("bpm"):
			bpm = parsed["bpm"]
			_update_step_interval()
		if parsed.has("sound_preset"):
			sound_preset = parsed["sound_preset"]
			_load_sound_preset(sound_preset)
		if parsed.has("pattern_preset"):
			call_deferred("load_pattern_preset", parsed["pattern_preset"])


func _parse_shorthand(key: String) -> Dictionary:
	var result := {}
	var k = key.to_lower().strip_edges()

	# Grid size: 4x8, 4x16
	var size_re = RegEx.new()
	size_re.compile("^(\\d+)x(\\d+)$")
	var m = size_re.search(k)
	if m:
		result["num_tracks"] = int(m.get_string(1))
		result["num_steps"] = int(m.get_string(2))

	# BPM: 120bpm
	var bpm_re = RegEx.new()
	bpm_re.compile("^(\\d+)bpm$")
	var bpm_m = bpm_re.search(k)
	if bpm_m:
		result["bpm"] = float(bpm_m.get_string(1))

	# Preset aliases
	if k in SOUND_PRESETS:
		result["sound_preset"] = k
	elif k == "trap":
		result["sound_preset"] = "trap_beats"
	elif k == "808":
		result["sound_preset"] = "808_kit"
	elif k == "synth":
		result["sound_preset"] = "synth_kit"
	elif k == "noir":
		result["sound_preset"] = "tech_noir"
	elif k == "house" or k == "gypsy" or k == "90s":
		result["sound_preset"] = "90s_house"
	elif k == "juno" or k == "pads":
		result["sound_preset"] = "juno_pads"
	# New preset aliases
	elif k == "kraftwerk" or k == "autobahn" or k == "robots":
		result["sound_preset"] = "kraftwerk"
	elif k == "disco" or k == "funky" or k == "70s":
		result["sound_preset"] = "disco"
	elif k == "ambient_works" or k == "aphex" or k == "idm":
		result["sound_preset"] = "ambient_works"
	elif k == "jazz_fusion" or k == "herbie" or k == "fusion" or k == "jazz":
		result["sound_preset"] = "jazz_fusion"
	elif k == "chiptune" or k == "8bit" or k == "c64" or k == "gameboy":
		result["sound_preset"] = "chiptune"
	elif k == "sci_fi_lab" or k == "lab" or k == "scifi" or k == "computer":
		result["sound_preset"] = "sci_fi_lab"
	elif k == "cinematic" or k == "bladerunner" or k == "vangelis" or k == "film":
		result["sound_preset"] = "cinematic"
	elif k == "breakbeat" or k == "dnb" or k == "jungle" or k == "amen":
		result["sound_preset"] = "breakbeat"
	elif k == "cosmic" or k == "space" or k == "jarre" or k == "tangerine":
		result["sound_preset"] = "cosmic"
	elif k == "lo_fi" or k == "lofi" or k == "chill" or k == "study":
		result["sound_preset"] = "lo_fi"

	# Pattern preset aliases (rhythm patterns)
	if k in PATTERN_PRESETS:
		result["pattern_preset"] = k
	elif k == "4otf" or k == "four_on_floor" or k == "4onthefloor":
		result["pattern_preset"] = "four_on_floor"
	elif k == "pattern:techno":
		result["pattern_preset"] = "techno"
	elif k == "pattern:house":
		result["pattern_preset"] = "house"
	elif k == "pattern:trap":
		result["pattern_preset"] = "trap"
	elif k == "pattern:breakbeat" or k == "pattern:breaks":
		result["pattern_preset"] = "breakbeat"
	elif k == "pattern:minimal":
		result["pattern_preset"] = "minimal"
	elif k == "pattern:disco":
		result["pattern_preset"] = "disco"
	elif k == "pattern:dnb" or k == "pattern:drum_and_bass":
		result["pattern_preset"] = "dnb"
	elif k == "pattern:ambient":
		result["pattern_preset"] = "ambient"
	elif k == "pattern:empty" or k == "clear":
		result["pattern_preset"] = "empty"

	return result


func _to_bool(value) -> bool:
	if value is bool:
		return value
	var s = str(value).to_lower().strip_edges()
	return s == "true" or s == "1" or s == "yes"
