extends Node3D
class_name StepSequencer

## 3D Step Sequencer
## Wraps SequencerUI in Viewport2Din3D for VR/3D interaction
## Handles audio playback

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
		AudioSynthesizer.SoundType.DARK_808_KICK,
		AudioSynthesizer.SoundType.TR909_KICK,
		AudioSynthesizer.SoundType.ACID_606_HIHAT,
		AudioSynthesizer.SoundType.DARK_808_SUB_BASS
	],
	"trap_beats": [
		AudioSynthesizer.SoundType.DARK_808_KICK,
		AudioSynthesizer.SoundType.EXPLOSION,
		AudioSynthesizer.SoundType.ACID_606_HIHAT,
		AudioSynthesizer.SoundType.SHIELD_HIT
	],
	"synth_kit": [
		AudioSynthesizer.SoundType.TB303_ACID_BASS,
		AudioSynthesizer.SoundType.MOOG_BASS_LEAD,
		AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,
		AudioSynthesizer.SoundType.PPG_WAVE_PAD
	],
	"tech_noir": [
		AudioSynthesizer.SoundType.MELODIC_DRONE,
		AudioSynthesizer.SoundType.GHOST_DRONE,
		AudioSynthesizer.SoundType.AMBIENT_WIND,
		AudioSynthesizer.SoundType.TELEPORT_DRONE
	],
	"retro": [
		AudioSynthesizer.SoundType.C64_SID_LEAD,
		AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,
		AudioSynthesizer.SoundType.RETRO_JUMP,
		AudioSynthesizer.SoundType.PICKUP_MARIO
	],
	"90s_house": [
		# Gypsy Woman / Crystal Waters style - Basement Boys production
		AudioSynthesizer.SoundType.TR909_KICK,        # Punchy house kick
		AudioSynthesizer.SoundType.KORG_M1_PIANO,     # The iconic M1 piano stab
		AudioSynthesizer.SoundType.ACID_606_HIHAT,    # Crisp hi-hats
		AudioSynthesizer.SoundType.TB303_ACID_BASS    # Squelchy acid bassline
	],
	"juno_pads": [
		# Lush analog pad sounds - slow builds, atmospheric
		AudioSynthesizer.SoundType.POP_JUNO_CHORUS_PAD,  # Roland Juno-106 lush pad
		AudioSynthesizer.SoundType.JUPITER_8_STRINGS,    # Jupiter string ensemble
		AudioSynthesizer.SoundType.PPG_WAVE_PAD,         # PPG wavetable warmth
		AudioSynthesizer.SoundType.CINEMATIC_432HZ_PAD   # Deep cinematic pad
	],
	"kraftwerk": [
		# 1970s Germany - Birth of electronic music, sequencers as instruments
		AudioSynthesizer.SoundType.MOOG_KRAFTWERK_SEQUENCER,  # The iconic sequencer pulse
		AudioSynthesizer.SoundType.TR909_KICK,                # Clean electronic kick
		AudioSynthesizer.SoundType.ACID_606_HIHAT,            # Precise hi-hats
		AudioSynthesizer.SoundType.MOOG_BASS_LEAD             # Analog bass
	],
	"disco": [
		# 1970s - Groove, four-on-floor, funky percussion
		AudioSynthesizer.SoundType.TR909_KICK,           # Punchy disco kick
		AudioSynthesizer.SoundType.SYNARE_3_DISCO_TOM,   # Classic disco tom
		AudioSynthesizer.SoundType.ACID_606_HIHAT,       # Crisp hi-hats
		AudioSynthesizer.SoundType.POP_FUNK_BASS         # Funky bass
	],
	"ambient_works": [
		# 1990s Aphex Twin style - Texture, space, less-is-more
		AudioSynthesizer.SoundType.APHEX_TWIN_MODULAR,   # Complex modular textures
		AudioSynthesizer.SoundType.PPG_WAVE_PAD,         # Wavetable warmth
		AudioSynthesizer.SoundType.GHOST_DRONE,          # Ethereal atmosphere
		AudioSynthesizer.SoundType.MELODIC_DRONE         # Melodic background
	],
	"jazz_fusion": [
		# 1970s Herbie Hancock - Jazz meets electronics
		AudioSynthesizer.SoundType.HERBIE_HANCOCK_MOOG_FUSION,  # Jazz-funk Moog
		AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,          # Rhodes-like FM piano
		AudioSynthesizer.SoundType.POP_FUNK_BASS,               # Walking/funk bass
		AudioSynthesizer.SoundType.TR909_KICK                   # Light percussion
	],
	"chiptune": [
		# 1980s - Constraints breed creativity, 8-bit aesthetics
		AudioSynthesizer.SoundType.C64_SID_LEAD,         # Commodore 64 lead
		AudioSynthesizer.SoundType.AMIGA_MOD_SAMPLE,     # Amiga tracker
		AudioSynthesizer.SoundType.RETRO_JUMP,           # Classic jump sound
		AudioSynthesizer.SoundType.PICKUP_MARIO          # Iconic pickup
	],
	"sci_fi_lab": [
		# Timeless - Sound design, atmosphere, world-building
		AudioSynthesizer.SoundType.SCI_FI_LAB_HUM_CLEAN,     # Sterile lab hum
		AudioSynthesizer.SoundType.SCI_FI_DATA_CHIRPS,       # Computer activity
		AudioSynthesizer.SoundType.SCI_FI_ELECTROMAGNETIC,   # Tech interference
		AudioSynthesizer.SoundType.SCI_FI_VENTILATION        # Air texture
	],
	"cinematic": [
		# 1980s+ Blade Runner - Film scoring, Vangelis influence
		AudioSynthesizer.SoundType.CS80_BRASS_LEAD,          # Blade Runner brass
		AudioSynthesizer.SoundType.CINEMATIC_432HZ_PAD,      # Deep cinematic pad
		AudioSynthesizer.SoundType.JUPITER_8_STRINGS,        # Lush strings
		AudioSynthesizer.SoundType.MELODIC_DRONE             # Tension drone
	],
	"breakbeat": [
		# 1990s - Syncopation, sampling culture, jungle/DnB
		AudioSynthesizer.SoundType.DARK_808_KICK,        # Punchy kick
		AudioSynthesizer.SoundType.TR909_KICK,           # Snare-like hit
		AudioSynthesizer.SoundType.ACID_606_HIHAT,       # Fast hi-hats
		AudioSynthesizer.SoundType.FLYING_LOTUS_SAMPLER  # Chopped samples
	],
	"cosmic": [
		# 1970s-80s Space disco - Jean-Michel Jarre, Tangerine Dream
		AudioSynthesizer.SoundType.SYNARE_3_COSMIC_FX,   # Cosmic percussion FX
		AudioSynthesizer.SoundType.ARP_2600_LEAD,        # Classic ARP lead
		AudioSynthesizer.SoundType.TELEPORT_DRONE,       # Space drone
		AudioSynthesizer.SoundType.PPG_WAVE_PAD          # Wavetable pad
	],
	"lo_fi": [
		# 2010s+ - Nostalgia, imperfection as aesthetic
		AudioSynthesizer.SoundType.DX7_ELECTRIC_PIANO,   # Warm FM piano
		AudioSynthesizer.SoundType.DARK_808_KICK,        # Mellow kick
		AudioSynthesizer.SoundType.AMBIENT_WIND,         # Vinyl crackle feel
		AudioSynthesizer.SoundType.POP_JUNO_CHORUS_PAD   # Warm pad
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


func _load_sound_preset(preset_name: String) -> void:
	if preset_name in SOUND_PRESETS:
		_track_sounds = SOUND_PRESETS[preset_name].duplicate()
	else:
		_track_sounds = SOUND_PRESETS["808_kit"].duplicate()

	# Pad if needed
	while _track_sounds.size() < num_tracks:
		_track_sounds.append(_track_sounds[0] if _track_sounds.size() > 0 else AudioSynthesizer.SoundType.BASIC_SINE_WAVE)


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
