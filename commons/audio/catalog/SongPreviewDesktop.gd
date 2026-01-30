# SongPreviewDesktop.gd
# Standalone desktop scene for previewing full interactive songs
# Now with timeline, annotations, and parameter display for discussing sounds

extends Control

var _player: AudioStreamPlayer
var _current_song: String = ""
var _is_playing: bool = false
var _current_stream: AudioStreamInteractive = null

var _title_label: Label
var _status_label: Label
var _song_buttons: Dictionary = {}
var _play_btn: Button
var _stop_btn: Button
var _section_label: Label

# Timeline component
var _timeline: SongTimeline
var _timeline_container: PanelContainer
var _show_timeline: bool = true

# Song metadata for timeline (maps song_id to metadata)
var _song_metadata: Dictionary = {}


func _ready():
	get_tree().root.title = "AdaResearch Song Preview"
	_setup_ui()
	_setup_audio()
	print("Song Preview ready - click a song to generate and play!")


func _setup_audio():
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.finished.connect(_on_song_finished)
	add_child(_player)


func _setup_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 40)
	add_child(vbox)
	
	# Title
	_title_label = Label.new()
	_title_label.text = "🎹 SONG PREVIEW"
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Full procedural songs with multiple sections"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 20
	vbox.add_child(spacer1)
	
	# Song buttons - 7 full songs!
	var songs = [
		["prog_synth_70s", "🎸 70s Prog Synth", "ELP, Kraftwerk, Yes - Moog bass, screaming leads, motorik drums"],
		["pop_generative", "🎤 Pop Generative", "Verse-Chorus structure with keys, bass, drums, lead"],
		["ambient_works", "🌊 Ambient Works", "Aphex Twin style - warm pads, lo-fi breakbeats, dreamy"],
		["moroder_disco", "🪩 Moroder Disco", "Giorgio Moroder 'I Feel Love' - hypnotic 16th sequencer, 4-on-floor"],
		["detroit_techno", "🔩 Detroit Techno", "Juan Atkins, Derrick May - cold machine funk, minimal, hypnotic"],
		["synthwave", "🌃 Synthwave", "The Weeknd, Kavinsky - 80s gated drums, detuned leads, arpeggios"],
		["rave", "⚡ 90s Rave", "The Prodigy, SL2 - aggressive breakbeats, hoover bass, stabs"]
	]
	
	for song in songs:
		var song_box = _create_song_box(song[0], song[1], song[2])
		vbox.add_child(song_box)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 20
	vbox.add_child(spacer2)
	
	# Control buttons
	var controls = HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 20)
	vbox.add_child(controls)
	
	_play_btn = Button.new()
	_play_btn.text = "  ⏸ PAUSE  "
	_play_btn.disabled = true
	_play_btn.pressed.connect(_toggle_pause)
	_style_button(_play_btn, Color(0.5, 0.4, 0.2))
	controls.add_child(_play_btn)
	
	_stop_btn = Button.new()
	_stop_btn.text = "  ⏹ STOP  "
	_stop_btn.disabled = true
	_stop_btn.pressed.connect(_stop_song)
	_style_button(_stop_btn, Color(0.6, 0.2, 0.2))
	controls.add_child(_stop_btn)
	
	# Status
	_status_label = Label.new()
	_status_label.text = "Select a song to generate..."
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)
	
	# Section label (shows current section)
	_section_label = Label.new()
	_section_label.text = ""
	_section_label.add_theme_font_size_override("font_size", 20)
	_section_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.4))
	_section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_section_label)
	
	# === TIMELINE PANEL ===
	_timeline_container = PanelContainer.new()
	var tl_style = StyleBoxFlat.new()
	tl_style.bg_color = Color(0.08, 0.08, 0.1)
	tl_style.border_color = Color(0.2, 0.2, 0.25)
	tl_style.set_border_width_all(1)
	tl_style.set_corner_radius_all(8)
	tl_style.content_margin_left = 16
	tl_style.content_margin_right = 16
	tl_style.content_margin_top = 12
	tl_style.content_margin_bottom = 12
	_timeline_container.add_theme_stylebox_override("panel", tl_style)
	_timeline_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_timeline_container.custom_minimum_size.y = 300
	_timeline_container.visible = false  # Hidden until song loads
	vbox.add_child(_timeline_container)
	
	_timeline = SongTimeline.new()
	_timeline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_timeline.seek_requested.connect(_on_timeline_seek)
	_timeline_container.add_child(_timeline)


func _create_song_box(id: String, title: String, desc: String) -> Control:
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.border_color = Color(0.2, 0.2, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	box.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	box.add_child(hbox)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	text_vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	text_vbox.add_child(desc_lbl)
	
	var play_btn = Button.new()
	play_btn.text = "  ▶ PLAY  "
	play_btn.pressed.connect(_on_song_selected.bind(id))
	_style_button(play_btn, Color(0.2, 0.5, 0.3))
	hbox.add_child(play_btn)
	
	_song_buttons[id] = play_btn
	
	return box


func _style_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var disabled = style.duplicate()
	disabled.bg_color = Color(0.2, 0.2, 0.2)
	btn.add_theme_stylebox_override("disabled", disabled)


func _on_song_selected(song_id: String):
	_stop_song()
	_current_song = song_id
	_status_label.text = "Generating " + song_id + "... (this may take a moment)"
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	
	# Disable all play buttons during generation
	for btn in _song_buttons.values():
		btn.disabled = true
	
	# Generate async
	call_deferred("_generate_and_play", song_id)


func _generate_and_play(song_id: String):
	var stream: AudioStream = null
	
	match song_id:
		"prog_synth_70s":
			stream = AudioSynthesizer.generate_prog_synth_song({})
		"pop_generative":
			stream = AudioSynthesizer.generate_pop_interactive_song({})
		"ambient_works":
			stream = AudioSynthesizer.generate_ambient_works_song({})
		"moroder_disco":
			stream = AudioSynthesizer.generate_moroder_disco_song({})
		"detroit_techno":
			stream = AudioSynthesizer.generate_detroit_techno_song({})
		"synthwave":
			stream = AudioSynthesizer.generate_synthwave_song({})
		"rave":
			stream = AudioSynthesizer.generate_rave_song({})
	
	if stream == null:
		_status_label.text = "Failed to generate song!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_enable_buttons()
		_timeline_container.visible = false
		return
	
	_current_stream = stream as AudioStreamInteractive
	_player.stream = stream
	_player.play()
	_is_playing = true
	
	_status_label.text = "Now playing: " + song_id
	_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_play_btn.disabled = false
	_play_btn.text = "  ⏸ PAUSE  "
	_stop_btn.disabled = false
	_enable_buttons()
	
	# Load timeline with song metadata
	_load_timeline_for_song(song_id, stream)
	_timeline_container.visible = true


func _toggle_pause():
	if _player.stream_paused:
		# Resume
		_player.stream_paused = false
		_play_btn.text = "  ⏸ PAUSE  "
		_status_label.text = "Playing: " + _current_song
		_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		_timeline.set_playing(true)
	else:
		# Pause
		_player.stream_paused = true
		_play_btn.text = "  ▶ RESUME  "
		_status_label.text = "Paused: " + _current_song
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		_timeline.set_playing(false)


func _stop_song():
	_player.stop()
	_player.stream_paused = false
	_is_playing = false
	_current_stream = null
	_status_label.text = "Stopped"
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_play_btn.text = "  ⏸ PAUSE  "
	_play_btn.disabled = true
	_stop_btn.disabled = true
	_section_label.text = ""
	_timeline.set_current_time(0.0)
	_timeline.set_playing(false)


func _on_song_finished():
	_is_playing = false
	_status_label.text = "Finished"
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_play_btn.disabled = true
	_play_btn.text = "  ⏸ PAUSE  "
	_stop_btn.disabled = true
	_section_label.text = ""
	_timeline.set_playing(false)


func _enable_buttons():
	for btn in _song_buttons.values():
		btn.disabled = false


func _process(_delta):
	if _is_playing and _player.playing:
		# Update timeline playhead
		var pos = _player.get_playback_position()
		_timeline.set_current_time(pos)


func _on_timeline_seek(time: float):
	"""Handle seek from timeline click"""
	if _player.stream:
		_player.seek(time)
		_timeline.set_current_time(time)


func _load_timeline_for_song(song_id: String, stream: AudioStream):
	"""Load detailed metadata for the timeline"""
	
	# If it's an interactive stream, extract sections automatically
	if stream is AudioStreamInteractive:
		var metadata = _get_song_metadata(song_id, stream as AudioStreamInteractive)
		_timeline.load_song_metadata(metadata)
	else:
		# Simple stream - just show duration
		_timeline.load_song_metadata({
			"name": song_id,
			"sections": [{"name": "Full Track", "start": 0.0, "end": stream.get_length(), "layers": []}],
			"total_duration": stream.get_length()
		})


func _get_song_metadata(song_id: String, stream: AudioStreamInteractive) -> Dictionary:
	"""Build detailed metadata for a song including layers and parameters"""
	
	var metadata = {
		"name": song_id,
		"sections": [],
		"total_duration": 0.0
	}
	
	var clip_count = stream.clip_count
	var time_offset = 0.0
	
	# Get detailed layer info based on song type
	var song_layers = _get_layers_for_song(song_id)
	
	for i in range(clip_count):
		var clip_name = stream.get_clip_name(i)
		var clip_stream = stream.get_clip_stream(i)
		var duration = 8.0
		
		if clip_stream:
			duration = clip_stream.get_length()
		
		# Get layers for this section
		var section_layers = song_layers.get(clip_name.to_lower(), song_layers.get("default", []))
		
		metadata["sections"].append({
			"name": clip_name if clip_name else "Section %d" % (i + 1),
			"start": time_offset,
			"end": time_offset + duration,
			"index": i,
			"layers": section_layers
		})
		
		time_offset += duration
	
	metadata["total_duration"] = time_offset
	return metadata


func _get_layers_for_song(song_id: String) -> Dictionary:
	"""Return detailed layer/parameter info per section for each song type"""
	
	match song_id:
		"prog_synth_70s":
			return {
				"intro": [
					{"name": "Moog Pad", "type": "pad", "params": "voices: 7 | detune: ±10 cents | filter: LPF 2kHz | attack: 2s"},
				],
				"verse": [
					{"name": "Moog Pad", "type": "pad", "params": "filter: LPF sweep 500-2kHz"},
					{"name": "Minimoog Bass", "type": "bass", "params": "osc: saw+square | glide: 50ms | filter: 24dB LPF"},
					{"name": "Motorik Drums", "type": "drums", "params": "pattern: 4/4 NEU! style | tempo: 110 BPM"},
				],
				"build": [
					{"name": "Moog Pad", "type": "pad", "params": "filter: opening"},
					{"name": "Minimoog Bass", "type": "bass", "params": "filter: resonant sweep"},
					{"name": "Kraftwerk Seq", "type": "seq", "params": "16th notes | filter: LPF+resonance | pattern: arpeggiated"},
					{"name": "Motorik Drums", "type": "drums", "params": "pattern: driving"},
				],
				"solo": [
					{"name": "ELP Lead", "type": "lead", "params": "osc: saw | portamento: 80ms | vibrato: 5Hz ±20 cents | filter: bandpass"},
					{"name": "Moog Pad", "type": "pad", "params": "sustained bed"},
					{"name": "Minimoog Bass", "type": "bass", "params": "following root"},
					{"name": "Motorik Drums", "type": "drums", "params": "fills | driving"},
				],
				"outro": [
					{"name": "Moog Pad", "type": "pad", "params": "fade out | filter closing"},
					{"name": "Kraftwerk Seq", "type": "seq", "params": "fading | filter closing"},
				],
				"default": [{"name": "Mix", "type": "mix", "params": ""}]
			}
		
		"ambient_works":
			return {
				"intro": [
					{"name": "Tape Keys", "type": "keys", "params": "FM piano | lo-fi tape saturation | wow/flutter"},
					{"name": "Tape Noise", "type": "noise", "params": "pink noise | filtered | subtle crackle"},
				],
				"build": [
					{"name": "Tape Keys", "type": "keys", "params": "sustained chords"},
					{"name": "Warm Pad", "type": "pad", "params": "voices: 5 | detuned | slow attack | chorus"},
					{"name": "Acid Bass", "type": "bass", "params": "303 style | resonant filter | accent"},
					{"name": "Breakbeat", "type": "drums", "params": "Amen break | lo-fi | timestretched"},
					{"name": "Tape Hiss", "type": "noise", "params": "constant bed"},
				],
				"main": [
					{"name": "Tape Keys", "type": "keys", "params": "melodic phrases"},
					{"name": "Warm Pad", "type": "pad", "params": "evolving | filter sweep"},
					{"name": "Acid Bass", "type": "bass", "params": "squelchy | 16th patterns"},
					{"name": "Breakbeat", "type": "drums", "params": "full groove | chopped"},
					{"name": "Atmosphere", "type": "noise", "params": "vinyl crackle | room tone"},
				],
				"outro": [
					{"name": "Warm Pad", "type": "pad", "params": "fade | long release"},
					{"name": "Tape Noise", "type": "noise", "params": "fading"},
				],
				"default": [{"name": "Ambient Texture", "type": "pad", "params": ""}]
			}
		
		"moroder_disco":
			return {
				"intro": [
					{"name": "Hi-Hat Pattern", "type": "drums", "params": "16th notes | 909 open/closed"},
					{"name": "Filter Sweep", "type": "pad", "params": "rising | resonant"},
				],
				"verse": [
					{"name": "Sequencer", "type": "seq", "params": "16th Moog | hypnotic pattern | filter modulation"},
					{"name": "Four-on-Floor", "type": "drums", "params": "kick every beat | hi-hat 16ths | clap on 2&4"},
					{"name": "Disco Bass", "type": "bass", "params": "octave jumps | Moog style"},
				],
				"chorus": [
					{"name": "Sequencer", "type": "seq", "params": "filter fully open"},
					{"name": "Disco Strings", "type": "pad", "params": "lush | string machine | sustained"},
					{"name": "Bass", "type": "bass", "params": "driving octaves"},
					{"name": "Full Drums", "type": "drums", "params": "fills | tom rolls"},
				],
				"breakdown": [
					{"name": "Sequencer Solo", "type": "seq", "params": "exposed | filter sweep"},
					{"name": "Hi-Hats Only", "type": "drums", "params": "16ths building"},
				],
				"default": [{"name": "Disco Mix", "type": "mix", "params": ""}]
			}
		
		"detroit_techno":
			return {
				"intro": [
					{"name": "Machine Pad", "type": "pad", "params": "cold | digital | slow attack"},
					{"name": "Hi-Hats", "type": "drums", "params": "909 | offbeat open hats"},
				],
				"verse": [
					{"name": "Techno Stab", "type": "lead", "params": "short decay | filtered | rhythmic"},
					{"name": "Sub Bass", "type": "bass", "params": "sine sub | 808 style"},
					{"name": "909 Kit", "type": "drums", "params": "kick | snare | hats | ride"},
					{"name": "Machine Pad", "type": "pad", "params": "background texture"},
				],
				"main": [
					{"name": "Strings", "type": "pad", "params": "Detroit strings | lush but cold"},
					{"name": "Bass Sequence", "type": "bass", "params": "funky | syncopated"},
					{"name": "Full Drums", "type": "drums", "params": "driving | machine funk"},
					{"name": "Stabs", "type": "lead", "params": "chord stabs | gated"},
				],
				"breakdown": [
					{"name": "Strings", "type": "pad", "params": "exposed | emotional"},
					{"name": "Minimal Drums", "type": "drums", "params": "kick + ride only"},
				],
				"default": [{"name": "Detroit Mix", "type": "mix", "params": ""}]
			}
		
		"synthwave":
			return {
				"intro": [
					{"name": "Arpeggio", "type": "seq", "params": "Juno-style | 16th notes | chorus"},
					{"name": "Gated Reverb", "type": "drums", "params": "snare only | 80s gated reverb"},
				],
				"verse": [
					{"name": "Arpeggio", "type": "seq", "params": "driving pattern"},
					{"name": "Bass", "type": "bass", "params": "saw bass | sidechained | pumping"},
					{"name": "80s Drums", "type": "drums", "params": "LinnDrum style | gated snare | electronic toms"},
					{"name": "Pad", "type": "pad", "params": "lush | detuned | slow filter"},
				],
				"chorus": [
					{"name": "Lead", "type": "lead", "params": "detuned saw | vibrato | delay"},
					{"name": "Power Chords", "type": "pad", "params": "stacked fifths | distorted"},
					{"name": "Bass", "type": "bass", "params": "octave pattern"},
					{"name": "Full Drums", "type": "drums", "params": "tom fills | crash cymbals"},
				],
				"bridge": [
					{"name": "Pad Only", "type": "pad", "params": "atmospheric | reverb wash"},
					{"name": "Arpeggio", "type": "seq", "params": "filtered down"},
				],
				"default": [{"name": "Synthwave Mix", "type": "mix", "params": ""}]
			}
		
		"rave":
			return {
				"intro": [
					{"name": "Build Noise", "type": "noise", "params": "white noise sweep | rising"},
					{"name": "Kick Teaser", "type": "drums", "params": "sparse kicks | building"},
				],
				"verse": [
					{"name": "Breakbeat", "type": "drums", "params": "chopped breaks | Amen/Think | 140+ BPM"},
					{"name": "Hoover Bass", "type": "bass", "params": "saw stack | PWM | pitch bend | MASSIVE"},
					{"name": "Stabs", "type": "lead", "params": "short | filtered | rhythmic"},
				],
				"drop": [
					{"name": "Breakbeat", "type": "drums", "params": "full force | fills | rolls"},
					{"name": "Hoover", "type": "bass", "params": "screaming | filter open"},
					{"name": "Rave Stab", "type": "lead", "params": "classic Mentasm | chord stabs"},
					{"name": "Vocal Chop", "type": "vocal", "params": "chopped 'yeah' | pitched"},
				],
				"breakdown": [
					{"name": "Pad", "type": "pad", "params": "dreamy | reverb"},
					{"name": "Vocal", "type": "vocal", "params": "pitched sample | ethereal"},
					{"name": "Build Noise", "type": "noise", "params": "rising for next drop"},
				],
				"default": [{"name": "Rave Mix", "type": "mix", "params": ""}]
			}
		
		"pop_generative":
			return {
				"intro": [
					{"name": "Pad", "type": "pad", "params": "soft | filtered | establishing key"},
				],
				"verse": [
					{"name": "Bass", "type": "bass", "params": "synth bass | root notes | simple pattern"},
					{"name": "Keys", "type": "keys", "params": "electric piano | chord stabs"},
					{"name": "Drums", "type": "drums", "params": "basic pattern | kick-snare"},
				],
				"chorus": [
					{"name": "Bass", "type": "bass", "params": "busier pattern | octaves"},
					{"name": "Keys", "type": "keys", "params": "fuller voicings"},
					{"name": "Pad", "type": "pad", "params": "lush | supporting"},
					{"name": "Lead", "type": "lead", "params": "melodic hook | catchy"},
					{"name": "Drums", "type": "drums", "params": "full kit | energy"},
				],
				"default": [{"name": "Pop Mix", "type": "mix", "params": ""}]
			}
		
		_:
			return {"default": [{"name": "Audio", "type": "mix", "params": ""}]}
