# SpaceDystopiaPopMain.gd
# SPACE DYSTOPIA - A Procedural Sci-Fi Album
# 10 tracks exploring AI awakening, cyberpunk noir, and cosmic transcendence
# Each track tells a story through sound

extends Control
class_name SpaceDystopiaPopMain

const SAMPLE_RATE = 44100

var _player: AudioStreamPlayer
var _current_track: int = -1
var _is_generating: bool = false

var _title_label: Label
var _status_label: Label
var _track_buttons: Array[Button] = []
var _section_label: Label
var _stop_btn: Button
var _concept_label: RichTextLabel


func _ready() -> void:
	get_tree().root.title = "SPACE DYSTOPIA — A Procedural Album"
	_setup_audio()
	_setup_ui()


func _setup_audio() -> void:
	var bus_name = "SpaceReverb"
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
		
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.85
		reverb.damping = 0.25
		reverb.spread = 1.0
		reverb.wet = 0.4
		reverb.dry = 0.7
		AudioServer.add_bus_effect(idx, reverb)
		
		var limiter = AudioEffectLimiter.new()
		limiter.ceiling_db = -0.5
		AudioServer.add_bus_effect(idx, limiter)
	
	_player = AudioStreamPlayer.new()
	_player.bus = "SpaceReverb"
	_player.finished.connect(_on_track_finished)
	add_child(_player)


func _setup_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 30)
	add_child(main_hbox)
	
	# Left panel - track list
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size.x = 300
	left_panel.add_theme_constant_override("separation", 8)
	main_hbox.add_child(left_panel)
	
	_title_label = Label.new()
	_title_label.text = "S P A C E\nD Y S T O P I A"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.9))
	left_panel.add_child(_title_label)
	
	var subtitle = Label.new()
	subtitle.text = "A Procedural Album"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	left_panel.add_child(subtitle)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 15
	left_panel.add_child(spacer1)
	
	# Track buttons
	var tracks = [
		[1, "01 — Post-Singularity Drift"],
		[2, "02 — Interdimensional Gate"],
		[3, "03 — The Automated Foundry"],
		[4, "04 — Augmented Noir"],
		[5, "05 — Stellar Cathedral"],
		[6, "06 — Neon Rain"],
		[7, "07 — Elegiac Skyline"],
		[8, "08 — Martian Bazaar"],
		[9, "09 — Celestial Symphony"],
		[10, "10 — The Singularity Event"]
	]
	
	for t in tracks:
		var btn = Button.new()
		btn.text = t[1]
		btn.custom_minimum_size = Vector2(280, 32)
		btn.pressed.connect(_on_track_selected.bind(t[0]))
		_style_track_button(btn)
		left_panel.add_child(btn)
		_track_buttons.append(btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 10
	left_panel.add_child(spacer2)
	
	# Controls
	var controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	left_panel.add_child(controls)
	
	_stop_btn = Button.new()
	_stop_btn.text = "⏹ STOP"
	_stop_btn.disabled = true
	_stop_btn.pressed.connect(_stop_track)
	_style_button(_stop_btn, Color(0.5, 0.15, 0.15))
	controls.add_child(_stop_btn)
	
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	controls.add_child(_status_label)
	
	# Right panel - concept art / description
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 15)
	main_hbox.add_child(right_panel)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size.x = 40
	main_hbox.add_child(spacer3)
	main_hbox.move_child(spacer3, 1)
	
	_concept_label = RichTextLabel.new()
	_concept_label.bbcode_enabled = true
	_concept_label.fit_content = true
	_concept_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_concept_label.add_theme_color_override("default_color", Color(0.6, 0.6, 0.7))
	_concept_label.add_theme_font_size_override("normal_font_size", 14)
	_update_concept_text(0)
	right_panel.add_child(_concept_label)


func _style_track_button(btn: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.12, 0.15, 0.25)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.2, 0.3, 0.5)
	btn.add_theme_stylebox_override("pressed", pressed)


func _style_button(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)


func _update_concept_text(track_id: int) -> void:
	var concepts = {
		0: "[color=#4080cc]SPACE DYSTOPIA[/color]\n\nA journey through post-human consciousness.\n\n[i]Select a track to begin...[/i]",
		1: "[color=#6090dd]01 — POST-SINGULARITY DRIFT[/color]\n\n[i]\"The machines have awakened. In the silence that follows, something new begins to dream.\"[/i]\n\n• Deep sub-bass foundation\n• Sparse piano notes floating in void\n• Ghostly choir emerging from static\n• Progression: Cm → Ab → Eb → Bb",
		2: "[color=#8060cc]02 — INTERDIMENSIONAL GATE[/color]\n\n[i]\"Reality folds. What was solid becomes probability. The gate opens.\"[/i]\n\n• Morphing wavetables (sine→saw→square)\n• Digital artifacts and glitches\n• Crystalline arpeggios\n• Non-linear time signatures",
		3: "[color=#cc6040]03 — THE AUTOMATED FOUNDRY[/color]\n\n[i]\"Steel shapes steel. No human hands. The rhythm of creation without creator.\"[/i]\n\n• Industrial percussion as heartbeat\n• Dissonant string drones\n• Mechanical sequences\n• 70 BPM — slow, heavy, inevitable",
		4: "[color=#40ccaa]04 — AUGMENTED NOIR[/color]\n\n[i]\"Rain on chrome. A saxophone cries in a language the city forgot.\"[/i]\n\n• Breathy jazz saxophone phrases\n• Urban rain atmosphere\n• Warm analog pads\n• Cm7 → Fm9 → G7alt → Cm progression",
		5: "[color=#cc80dd]05 — STELLAR CATHEDRAL[/color]\n\n[i]\"Between the stars, we built a temple. The choir sings equations.\"[/i]\n\n• Sacred choir vowel morphing\n• Cinematic string swells\n• Bell-like piano\n• D Dorian mode — ancient yet futuristic",
		6: "[color=#40aacc]06 — NEON RAIN[/color]\n\n[i]\"Every droplet a pixel. Every reflection a memory. The city weeps data.\"[/i]\n\n• Constant rain texture\n• Noir sax over jazz piano\n• Pulsing bass underneath\n• Blade Runner meets Blue Note",
		7: "[color=#ddaa60]07 — ELEGIAC SKYLINE[/color]\n\n[i]\"The last sunset. Steel towers become tombstones. Beauty in the ending.\"[/i]\n\n• Pedal steel swells\n• Emotional piano\n• Strings building to catharsis\n• Am → F → C → G — simple, devastating",
		8: "[color=#cc4080]08 — MARTIAN BAZAAR[/color]\n\n[i]\"A market where no human trades. Algorithms haggle in frequencies we cannot hear.\"[/i]\n\n• Exotic scale (Phrygian dominant)\n• Polyrhythmic sequences\n• Metallic percussion\n• 125 BPM — alien commerce",
		9: "[color=#60ccdd]09 — CELESTIAL SYMPHONY[/color]\n\n[i]\"The universe composes itself. We are merely the audience.\"[/i]\n\n• Full orchestral simulation\n• Choir + Strings + Piano\n• Expanding harmonic space\n• G major → cosmic resolution",
		10: "[color=#ff6060]10 — THE SINGULARITY EVENT[/color]\n\n[i]\"All patterns converge. All frequencies align. And then—\"[/i]\n\n• Chaos builds from all elements\n• Glitch and noise crescendo\n• Everything collapses to a single tone\n• The loop begins again..."
	}
	_concept_label.text = concepts.get(track_id, concepts[0])


func _on_track_selected(track_id: int) -> void:
	if _is_generating:
		return
	
	_stop_track()
	_current_track = track_id
	_is_generating = true
	
	_update_concept_text(track_id)
	_status_label.text = "Generating..."
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	
	for btn in _track_buttons:
		btn.disabled = true
	
	call_deferred("_generate_and_play", track_id)


func _generate_and_play(track_id: int) -> void:
	var stream: AudioStreamInteractive = null
	
	match track_id:
		1: stream = _gen_01_drift()
		2: stream = _gen_02_interdimensional()
		3: stream = _gen_03_foundry()
		4: stream = _gen_04_noir()
		5: stream = _gen_05_cathedral()
		6: stream = _gen_06_neon_rain()
		7: stream = _gen_07_skyline()
		8: stream = _gen_08_bazaar()
		9: stream = _gen_09_symphony()
		10: stream = _gen_10_singularity()
	
	_is_generating = false
	
	if stream:
		_player.stream = stream
		_player.play()
		_status_label.text = "▶ Playing"
		_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		_stop_btn.disabled = false
	
	for i in range(_track_buttons.size()):
		_track_buttons[i].disabled = false
		_track_buttons[i].modulate = Color(0.5, 0.5, 0.5) if (i + 1) != track_id else Color(1.0, 1.0, 1.0)


func _stop_track() -> void:
	_player.stop()
	_stop_btn.disabled = true
	_status_label.text = ""
	for btn in _track_buttons:
		btn.modulate = Color(1.0, 1.0, 1.0)


func _on_track_finished() -> void:
	_status_label.text = "Finished"
	_stop_btn.disabled = true


# =============================================================================
# TRACK 01: POST-SINGULARITY DRIFT
# Deep space ambient after AI awakening
# =============================================================================
func _gen_01_drift() -> AudioStreamInteractive:
	var bpm = 50.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(48)  # C minor
	var prog = [0, 5, 2, 6]  # i - VI - III - VII
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	# Awakening: Just sub drone emerging from silence
	p.set_clip_stream(0, _render_01(prog, scale, ["sub"], bar, 0.3))
	p.set_clip_name(0, "Awakening")
	
	# Dreaming: Add ghostly piano notes
	p.set_clip_stream(1, _render_01(prog, scale, ["sub", "piano"], bar, 0.6))
	p.set_clip_name(1, "Dreaming")
	
	# Ascending: Choir emerges
	p.set_clip_stream(2, _render_01(prog, scale, ["sub", "piano", "choir"], bar, 0.9))
	p.set_clip_name(2, "Ascending")
	
	# Dissolving: Return to drone
	p.set_clip_stream(3, _render_01(prog, scale, ["sub", "choir_fade"], bar, 0.4))
	p.set_clip_name(3, "Dissolving")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 6.0)
	return p


func _render_01(prog: Array, scale: Array, inst: Array, bar: float, intensity: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "sub" in inst:
			# Deep sub with slow drift
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var drift = sin(t * 0.03) * 2.0
				var sub = sin(2.0 * PI * (root * 0.25 + drift) * t)
				sub += sin(2.0 * PI * root * 0.25 * 1.002 * t) * 0.5
				chunk[j] += sub * 0.4 * intensity
		
		if "piano" in inst:
			# Sparse, reverberant piano
			var note_times = [0.0, 0.35, 0.6, 0.85]
			for nt in note_times:
				if randf() < 0.4:  # Random sparse
					var start = int(nt * spc)
					var pf = freqs[randi() % freqs.size()] * (2.0 if randf() > 0.6 else 1.0)
					for j in range(min(int(SAMPLE_RATE * 3.0), spc - start)):
						var pt = float(j) / SAMPLE_RATE
						var piano = sin(2.0 * PI * pf * pt) * exp(-pt * 0.8)
						piano += sin(2.0 * PI * pf * 2.0 * pt) * exp(-pt * 1.5) * 0.3
						if start + j < spc: chunk[start + j] += piano * 0.2 * intensity
		
		if "choir" in inst:
			# Ethereal choir pad
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var choir = 0.0
				var vib = sin(2.0 * PI * 5.0 * t) * 0.008
				for freq in freqs:
					var f = freq * (1.0 + vib)
					choir += sin(2.0 * PI * f * t)
					choir += sin(2.0 * PI * f * 2.0 * t) * 0.3
				choir /= freqs.size()
				var env = sin(PI * progress)
				chunk[j] += choir * env * 0.25 * intensity
		
		if "choir_fade" in inst:
			# Fading choir
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var choir = 0.0
				for freq in freqs:
					choir += sin(2.0 * PI * freq * t)
				choir /= freqs.size()
				var env = 1.0 - progress  # Fade out
				chunk[j] += choir * env * 0.15 * intensity
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 02: INTERDIMENSIONAL GATE
# Reality-bending wavetable morphing
# =============================================================================
func _gen_02_interdimensional() -> AudioStreamInteractive:
	var bpm = 90.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(45)  # A minor
	var prog = [0, 6, 3, 4]  # i - VII - iv - v (unsettling)
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_02(prog, scale, ["morph"], bar))
	p.set_clip_name(0, "Approach")
	
	p.set_clip_stream(1, _render_02(prog, scale, ["morph", "glitch", "arp"], bar))
	p.set_clip_name(1, "Threshold")
	
	p.set_clip_stream(2, _render_02(prog, scale, ["morph", "glitch", "arp", "bass"], bar))
	p.set_clip_name(2, "Crossing")
	
	p.set_clip_stream(3, _render_02(prog, scale, ["morph"], bar))
	p.set_clip_name(3, "Beyond")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 4.0)
	return p


func _render_02(prog: Array, scale: Array, inst: Array, bar: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "morph" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var morph = fmod(t * 0.15, 1.0) * 4.0
				var phase = fmod(root * t, 1.0)
				
				var sine_w = sin(2.0 * PI * phase)
				var tri = abs(4.0 * phase - 2.0) - 1.0
				var saw = 2.0 * phase - 1.0
				var sq = 1.0 if phase < 0.5 else -1.0
				
				var wave = 0.0
				if morph < 1.0: wave = sine_w * (1.0 - morph) + tri * morph
				elif morph < 2.0: wave = tri * (2.0 - morph) + saw * (morph - 1.0)
				elif morph < 3.0: wave = saw * (3.0 - morph) + sq * (morph - 2.0)
				else: wave = sq * (4.0 - morph) + sine_w * (morph - 3.0)
				
				var env = sin(PI * progress)
				chunk[j] += wave * env * 0.25
		
		if "glitch" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				if randf() < 0.003:
					for k in range(min(int(SAMPLE_RATE * 0.02), spc - j)):
						if j + k < spc:
							chunk[j + k] += (randf() - 0.5) * 0.3
		
		if "arp" in inst:
			var sixteenth = int(60.0 / 90.0 / 4.0 * SAMPLE_RATE)
			var pattern = [0, 7, 12, 19, 12, 7]
			for step in range(int(spc / sixteenth)):
				var start = step * sixteenth
				var note_offset = pattern[step % pattern.size()]
				var freq = root * pow(2.0, note_offset / 12.0)
				for j in range(min(sixteenth / 2, spc - start)):
					var at = float(j) / SAMPLE_RATE
					var arp = sin(2.0 * PI * freq * at) * exp(-at * 15.0) * 0.15
					if start + j < spc: chunk[start + j] += arp
		
		if "bass" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				chunk[j] += sin(2.0 * PI * root * 0.5 * t) * 0.3
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 03: THE AUTOMATED FOUNDRY
# Industrial machinery, no humans
# =============================================================================
func _gen_03_foundry() -> AudioStreamInteractive:
	var bpm = 70.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(40)  # E minor (dark)
	var prog = [0, 0, 6, 5]  # Heavy on root, dissonant movement
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_03(prog, scale, ["drone"], bar, bpm))
	p.set_clip_name(0, "Power On")
	
	p.set_clip_stream(1, _render_03(prog, scale, ["drone", "clank"], bar, bpm))
	p.set_clip_name(1, "Assembly")
	
	p.set_clip_stream(2, _render_03(prog, scale, ["drone", "clank", "strings", "seq"], bar, bpm))
	p.set_clip_name(2, "Full Production")
	
	p.set_clip_stream(3, _render_03(prog, scale, ["drone", "strings"], bar, bpm))
	p.set_clip_name(3, "Shutdown")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 2.5)
	return p


func _render_03(prog: Array, scale: Array, inst: Array, bar: float, bpm: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "drone" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var drone = sin(2.0 * PI * root * 0.5 * t) * 0.3
				drone += sin(2.0 * PI * root * 0.5 * 1.02 * t) * 0.2  # Beating
				drone += sin(2.0 * PI * root * 0.25 * t) * 0.15
				chunk[j] += drone
		
		if "clank" in inst:
			var beat = int(60.0 / bpm * SAMPLE_RATE)
			var pattern = [1, 0, 1, 0, 1, 0, 1, 1]  # Industrial rhythm
			for b in range(8):
				if pattern[b] == 1:
					var start = b * beat / 2
					var pitch = 120.0 + (b % 3) * 30.0
					for j in range(min(int(SAMPLE_RATE * 0.25), spc - start)):
						var ct = float(j) / SAMPLE_RATE
						var mod = sin(2.0 * PI * pitch * 1.414 * ct) * 6.0
						var clank = sin(2.0 * PI * pitch * ct + mod) * exp(-ct * 8.0)
						if start + j < spc: chunk[start + j] += clank * 0.4
		
		if "strings" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var strings = 0.0
				for freq in freqs:
					var detunes = [0.997, 1.0, 1.003]
					for d in detunes:
						strings += (fmod(freq * d * t, 1.0) * 2.0 - 1.0)
				strings /= freqs.size() * 3.0
				var env = progress * progress if progress < 0.5 else 1.0
				if progress > 0.85: env *= (1.0 - progress) / 0.15
				chunk[j] += strings * env * 0.2
		
		if "seq" in inst:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			for step in range(16):
				var start = step * sixteenth
				var sf = root * pow(2.0, ([0, 0, 12, 0, 7, 0, 12, 7][step % 8]) / 12.0)
				for j in range(min(sixteenth / 3, spc - start)):
					var st = float(j) / SAMPLE_RATE
					var seq = (fmod(sf * st, 1.0) * 2.0 - 1.0) * exp(-st * 20.0) * 0.15
					if start + j < spc: chunk[start + j] += seq
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 04: AUGMENTED NOIR
# Cyberpunk jazz detective story
# =============================================================================
func _gen_04_noir() -> AudioStreamInteractive:
	var bpm = 72.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(48)  # C minor jazz
	var prog = [0, 3, 4, 0]  # Cm7 - Fm9 - Galt - Cm
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_04(prog, scale, ["rain", "pad"], bar))
	p.set_clip_name(0, "Midnight")
	
	p.set_clip_stream(1, _render_04(prog, scale, ["rain", "pad", "bass", "sax"], bar))
	p.set_clip_name(1, "The Case")
	
	p.set_clip_stream(2, _render_04(prog, scale, ["rain", "pad", "bass", "sax", "piano"], bar))
	p.set_clip_name(2, "Pursuit")
	
	p.set_clip_stream(3, _render_04(prog, scale, ["rain", "pad", "sax"], bar))
	p.set_clip_name(3, "Resolution")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 4.0)
	return p


func _render_04(prog: Array, scale: Array, inst: Array, bar: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "rain" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var rain = sin(t * 9000.0 + randf() * 5.0) * 0.02
				rain += sin(t * 13000.0 + randf() * 5.0) * 0.015
				rain += sin(t * 5000.0 + randf() * 5.0) * 0.01
				var gust = sin(t * 0.15) * 0.3 + 0.7
				chunk[j] += rain * gust
		
		if "pad" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var pad = 0.0
				for freq in freqs:
					pad += sin(2.0 * PI * freq * t)
					pad += sin(2.0 * PI * freq * 1.003 * t) * 0.7
				pad /= freqs.size() * 2.0
				var env = 1.0
				if progress < 0.1: env = progress / 0.1
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				chunk[j] += pad * env * 0.2
		
		if "bass" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var bass = sin(2.0 * PI * root * 0.25 * t) * 0.35
				chunk[j] += bass
		
		if "sax" in inst:
			var phrase_start = int(spc * 0.15)
			var phrase_len = int(spc * 0.55)
			var sax_notes = [freqs[0] * 2.0, freqs[1] * 2.0 if freqs.size() > 1 else freqs[0] * 2.0]
			var current_note = sax_notes[i % sax_notes.size()]
			
			for j in range(phrase_len):
				if phrase_start + j < spc:
					var st = float(j) / SAMPLE_RATE
					var progress = float(j) / phrase_len
					var vib = sin(2.0 * PI * 5.5 * st) * 0.012 * min(1.0, progress * 3.0)
					var freq = current_note * (1.0 + vib)
					
					var sax = sin(2.0 * PI * freq * st) * 0.4
					sax += sin(2.0 * PI * freq * 2.0 * st) * 0.2
					sax += sin(2.0 * PI * freq * 3.0 * st) * 0.25
					sax += (randf() - 0.5) * 0.08  # Breath
					
					var env = sin(PI * progress)
					chunk[phrase_start + j] += sax * env * 0.35
		
		if "piano" in inst:
			var times = [0.0, 0.25, 0.5, 0.75]
			for ti in range(times.size()):
				if randf() < 0.6:
					var start = int(times[ti] * spc)
					var pf = freqs[randi() % freqs.size()] * (2.0 if randf() > 0.5 else 1.0)
					for j in range(min(int(SAMPLE_RATE * 1.2), spc - start)):
						var pt = float(j) / SAMPLE_RATE
						var piano = sin(2.0 * PI * pf * pt) * exp(-pt * 2.5) * 0.18
						if start + j < spc: chunk[start + j] += piano
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 05: STELLAR CATHEDRAL
# Sacred space between stars
# =============================================================================
func _gen_05_cathedral() -> AudioStreamInteractive:
	var bpm = 55.0
	var bar = 240.0 / bpm
	var scale = _dorian_scale(50)  # D Dorian - ancient/modal
	var prog = [0, 3, 5, 2]
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_05(prog, scale, ["choir"], bar, 0.4))
	p.set_clip_name(0, "Entering")
	
	p.set_clip_stream(1, _render_05(prog, scale, ["choir", "strings"], bar, 0.7))
	p.set_clip_name(1, "Reverence")
	
	p.set_clip_stream(2, _render_05(prog, scale, ["choir", "strings", "bells"], bar, 1.0))
	p.set_clip_name(2, "Transcendence")
	
	p.set_clip_stream(3, _render_05(prog, scale, ["choir"], bar, 0.5))
	p.set_clip_name(3, "Departure")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 6.0)
	return p


func _render_05(prog: Array, scale: Array, inst: Array, bar: float, intensity: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "choir" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				
				var morph = sin(t * 0.3) * 0.5 + 0.5
				var f1 = 300.0 + morph * 430.0
				var f2 = 870.0 + morph * 220.0
				
				var choir = 0.0
				var vib = sin(2.0 * PI * 5.0 * t) * 0.006
				for freq in freqs:
					var f = freq * (1.0 + vib)
					for h in range(1, 10):
						var hf = f * h
						var amp = 1.0 / h
						var f1_g = exp(-pow((hf - f1) / 80.0, 2.0))
						var f2_g = exp(-pow((hf - f2) / 120.0, 2.0))
						amp *= (f1_g * 0.5 + f2_g * 0.4 + 0.15)
						choir += sin(2.0 * PI * hf * t) * amp
				
				choir /= freqs.size()
				var env = 1.0
				if progress < 0.2: env = progress / 0.2
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				chunk[j] += choir * env * 0.25 * intensity
		
		if "strings" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var strings = 0.0
				for freq in freqs:
					for d in [-0.01, 0.0, 0.008]:
						strings += (fmod(freq * (1.0 + d) * t, 1.0) * 2.0 - 1.0)
				strings /= freqs.size() * 3.0
				strings = tanh(strings * 0.7)
				var env = min(1.0, progress * 2.0)
				if progress > 0.85: env *= (1.0 - progress) / 0.15
				chunk[j] += strings * env * 0.2 * intensity
		
		if "bells" in inst:
			var bell_times = [0.0, 0.4, 0.7]
			for bt in bell_times:
				var start = int(bt * spc)
				var bell_freq = freqs[0] * 4.0
				for j in range(min(int(SAMPLE_RATE * 2.5), spc - start)):
					var pt = float(j) / SAMPLE_RATE
					var bell = sin(2.0 * PI * bell_freq * pt) * exp(-pt * 1.5)
					bell += sin(2.0 * PI * bell_freq * 2.0 * pt) * exp(-pt * 2.0) * 0.4
					bell += sin(2.0 * PI * bell_freq * 3.0 * pt) * exp(-pt * 2.5) * 0.2
					if start + j < spc: chunk[start + j] += bell * 0.12 * intensity
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 06: NEON RAIN
# Blade Runner meets Blue Note
# =============================================================================
func _gen_06_neon_rain() -> AudioStreamInteractive:
	var bpm = 78.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(48)
	var prog = [0, 5, 3, 4]
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_06(prog, scale, ["rain_heavy"], bar))
	p.set_clip_name(0, "Downpour")
	
	p.set_clip_stream(1, _render_06(prog, scale, ["rain", "bass", "piano"], bar))
	p.set_clip_name(1, "Streets")
	
	p.set_clip_stream(2, _render_06(prog, scale, ["rain", "bass", "piano", "sax"], bar))
	p.set_clip_name(2, "Reflection")
	
	p.set_clip_stream(3, _render_06(prog, scale, ["rain_light", "piano"], bar))
	p.set_clip_name(3, "Clearing")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 3.5)
	return p


func _render_06(prog: Array, scale: Array, inst: Array, bar: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		var rain_intensity = 0.5
		if "rain_heavy" in inst: rain_intensity = 0.8
		if "rain_light" in inst: rain_intensity = 0.25
		if "rain" in inst or "rain_heavy" in inst or "rain_light" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var rain = sin(t * 10000.0 + randf() * 3.0) * 0.025
				rain += sin(t * 14000.0 + randf() * 3.0) * 0.018
				rain += sin(t * 4000.0 + randf() * 3.0) * 0.01
				chunk[j] += rain * rain_intensity
		
		if "bass" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				chunk[j] += sin(2.0 * PI * root * 0.25 * t) * 0.35
		
		if "piano" in inst:
			var jazz_voicings = [
				[0, 4, 7, 10],  # m7
				[0, 3, 7, 10],  # m7
				[0, 4, 7, 11],  # maj7
			]
			var voicing = jazz_voicings[i % jazz_voicings.size()]
			var times = [0.1, 0.4, 0.65]
			for ti in range(times.size()):
				if randf() < 0.7:
					var start = int(times[ti] * spc)
					for v in voicing:
						var pf = root * pow(2.0, v / 12.0)
						for j in range(min(int(SAMPLE_RATE * 1.5), spc - start)):
							var pt = float(j) / SAMPLE_RATE
							var piano = sin(2.0 * PI * pf * pt) * exp(-pt * 2.0) * 0.08
							if start + j < spc: chunk[start + j] += piano
		
		if "sax" in inst:
			var phrase_start = int(spc * 0.2)
			var phrase_len = int(spc * 0.5)
			var sax_freq = freqs[0] * 2.0
			for j in range(phrase_len):
				if phrase_start + j < spc:
					var st = float(j) / SAMPLE_RATE
					var progress = float(j) / phrase_len
					var vib = sin(2.0 * PI * 5.0 * st) * 0.01 * min(1.0, progress * 4.0)
					var sax = sin(2.0 * PI * sax_freq * (1.0 + vib) * st) * 0.3
					sax += sin(2.0 * PI * sax_freq * 2.0 * st) * 0.15
					sax += sin(2.0 * PI * sax_freq * 3.0 * st) * 0.2
					sax += (randf() - 0.5) * 0.06
					var env = sin(PI * progress)
					chunk[phrase_start + j] += sax * env * 0.3
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 07: ELEGIAC SKYLINE
# Watching a dying city - emotional climax
# =============================================================================
func _gen_07_skyline() -> AudioStreamInteractive:
	var bpm = 65.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(57)  # A minor
	var prog = [0, 5, 3, 4]  # Am - F - Dm - E (emotional)
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_07(prog, scale, ["steel"], bar, 0.4))
	p.set_clip_name(0, "Twilight")
	
	p.set_clip_stream(1, _render_07(prog, scale, ["steel", "piano"], bar, 0.6))
	p.set_clip_name(1, "Memory")
	
	p.set_clip_stream(2, _render_07(prog, scale, ["steel", "piano", "strings"], bar, 1.0))
	p.set_clip_name(2, "Elegy")
	
	p.set_clip_stream(3, _render_07(prog, scale, ["steel", "strings_fade"], bar, 0.5))
	p.set_clip_name(3, "Darkness")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 5.0)
	return p


func _render_07(prog: Array, scale: Array, inst: Array, bar: float, intensity: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "steel" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var steel = 0.0
				for d in [-0.006, 0.0, 0.005]:
					var freq = freqs[0] * (1.0 + d)
					freq *= 1.0 + sin(2.0 * PI * 0.4 * t) * 0.008
					steel += sin(2.0 * PI * freq * t)
					steel += sin(2.0 * PI * freq * 2.0 * t) * 0.4
					steel += sin(2.0 * PI * freq * 3.0 * t) * 0.2
				steel /= 9.0
				var swell = progress * progress if progress < 0.6 else 1.0
				if progress > 0.85: swell *= (1.0 - progress) / 0.15
				chunk[j] += steel * swell * 0.3 * intensity
		
		if "piano" in inst:
			var times = [0.0, 0.3, 0.55, 0.8]
			for ti in range(times.size()):
				var start = int(times[ti] * spc)
				var pf = freqs[ti % freqs.size()] * (2.0 if ti > 1 else 1.0)
				for j in range(min(int(SAMPLE_RATE * 2.5), spc - start)):
					var pt = float(j) / SAMPLE_RATE
					var piano = sin(2.0 * PI * pf * pt) * exp(-pt * 1.2)
					piano += sin(2.0 * PI * pf * 2.0 * pt) * exp(-pt * 1.8) * 0.3
					if start + j < spc: chunk[start + j] += piano * 0.2 * intensity
		
		if "strings" in inst or "strings_fade" in inst:
			var fade_out = "strings_fade" in inst
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var strings = 0.0
				for freq in freqs:
					for d in [-0.008, 0.0, 0.006]:
						strings += (fmod(freq * (1.0 + d) * t, 1.0) * 2.0 - 1.0)
				strings /= freqs.size() * 3.0
				strings = tanh(strings * 0.6)
				var env = min(1.0, progress * 3.0)
				if fade_out: env *= (1.0 - progress)
				elif progress > 0.85: env *= (1.0 - progress) / 0.15
				chunk[j] += strings * env * 0.25 * intensity
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 08: MARTIAN BAZAAR
# Alien marketplace - exotic and rhythmic
# =============================================================================
func _gen_08_bazaar() -> AudioStreamInteractive:
	var bpm = 125.0
	var bar = 240.0 / bpm
	var scale = _phrygian_scale(45)  # Phrygian dominant - exotic
	var prog = [0, 1, 4, 0]  # Exotic movement
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_08(prog, scale, ["seq"], bar, bpm))
	p.set_clip_name(0, "Arrival")
	
	p.set_clip_stream(1, _render_08(prog, scale, ["seq", "perc", "bass"], bar, bpm))
	p.set_clip_name(1, "Trading")
	
	p.set_clip_stream(2, _render_08(prog, scale, ["seq", "perc", "bass", "lead"], bar, bpm))
	p.set_clip_name(2, "Haggling")
	
	p.set_clip_stream(3, _render_08(prog, scale, ["seq", "bass"], bar, bpm))
	p.set_clip_name(3, "Departure")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 2.0)
	return p


func _render_08(prog: Array, scale: Array, inst: Array, bar: float, bpm: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "seq" in inst:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			var pattern = [0, 0, 5, 0, 3, 0, 7, 5, 0, 3, 5, 0, 7, 0, 5, 3]
			for step in range(16):
				var start = step * sixteenth
				var note = pattern[step]
				var freq = root * pow(2.0, note / 12.0)
				for j in range(min(sixteenth * 2 / 3, spc - start)):
					var st = float(j) / SAMPLE_RATE
					var seq = (fmod(freq * st, 1.0) * 2.0 - 1.0) * exp(-st * 18.0) * 0.2
					if start + j < spc: chunk[start + j] += seq
		
		if "perc" in inst:
			var beat = int(60.0 / bpm * SAMPLE_RATE)
			var kick_pattern = [1, 0, 0, 1, 0, 0, 1, 0]
			var clank_pattern = [0, 0, 1, 0, 1, 0, 0, 1]
			for b in range(8):
				var start = b * beat / 2
				if kick_pattern[b] == 1:
					for j in range(min(int(SAMPLE_RATE * 0.1), spc - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick = sin(2.0 * PI * (60.0 + exp(-kt * 40.0) * 80.0) * kt) * exp(-kt * 12.0) * 0.5
						if start + j < spc: chunk[start + j] += kick
				if clank_pattern[b] == 1:
					var pitch = 300.0 + (b % 3) * 100.0
					for j in range(min(int(SAMPLE_RATE * 0.12), spc - start)):
						var ct = float(j) / SAMPLE_RATE
						var mod = sin(2.0 * PI * pitch * 2.2 * ct) * 4.0
						var clank = sin(2.0 * PI * pitch * ct + mod) * exp(-ct * 15.0) * 0.25
						if start + j < spc: chunk[start + j] += clank
		
		if "bass" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				chunk[j] += sin(2.0 * PI * root * 0.5 * t) * 0.35
		
		if "lead" in inst:
			var phrase_start = int(spc * 0.1)
			var phrase_len = int(spc * 0.4)
			var lead_freq = root * 2.0
			for j in range(phrase_len):
				if phrase_start + j < spc:
					var lt = float(j) / SAMPLE_RATE
					var progress = float(j) / phrase_len
					var lead = (fmod(lead_freq * lt, 1.0) * 2.0 - 1.0) * 0.15
					lead += (fmod(lead_freq * 1.005 * lt, 1.0) * 2.0 - 1.0) * 0.1
					var env = sin(PI * progress)
					chunk[phrase_start + j] += lead * env
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 09: CELESTIAL SYMPHONY
# The universe composes itself
# =============================================================================
func _gen_09_symphony() -> AudioStreamInteractive:
	var bpm = 60.0
	var bar = 240.0 / bpm
	var scale = _major_scale(55)  # G major - hopeful
	var prog = [0, 4, 5, 3]  # I - V - vi - IV (epic)
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_09(prog, scale, ["strings"], bar, 0.4))
	p.set_clip_name(0, "Overture")
	
	p.set_clip_stream(1, _render_09(prog, scale, ["strings", "choir"], bar, 0.6))
	p.set_clip_name(1, "Movement I")
	
	p.set_clip_stream(2, _render_09(prog, scale, ["strings", "choir", "bells", "bass"], bar, 1.0))
	p.set_clip_name(2, "Crescendo")
	
	p.set_clip_stream(3, _render_09(prog, scale, ["strings", "bells"], bar, 0.5))
	p.set_clip_name(3, "Coda")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 5.0)
	return p


func _render_09(prog: Array, scale: Array, inst: Array, bar: float, intensity: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "strings" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var strings = 0.0
				for freq in freqs:
					for d in [-0.012, -0.004, 0.0, 0.005, 0.01]:
						strings += (fmod(freq * (1.0 + d) * t, 1.0) * 2.0 - 1.0)
				strings /= freqs.size() * 5.0
				strings = tanh(strings * 0.5)
				var env = min(1.0, progress * 2.5)
				if progress > 0.9: env *= (1.0 - progress) / 0.1
				chunk[j] += strings * env * 0.3 * intensity
		
		if "choir" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var choir = 0.0
				var vib = sin(2.0 * PI * 5.0 * t) * 0.005
				for freq in freqs:
					var f = freq * (1.0 + vib)
					choir += sin(2.0 * PI * f * t)
					choir += sin(2.0 * PI * f * 2.0 * t) * 0.25
				choir /= freqs.size()
				var env = sin(PI * progress)
				chunk[j] += choir * env * 0.2 * intensity
		
		if "bells" in inst:
			var bell_times = [0.0, 0.35, 0.65]
			for bt in bell_times:
				var start = int(bt * spc)
				var bell_freq = freqs[0] * 4.0
				for j in range(min(int(SAMPLE_RATE * 3.0), spc - start)):
					var pt = float(j) / SAMPLE_RATE
					var bell = sin(2.0 * PI * bell_freq * pt) * exp(-pt * 1.2)
					bell += sin(2.0 * PI * bell_freq * 2.0 * pt) * exp(-pt * 1.8) * 0.35
					if start + j < spc: chunk[start + j] += bell * 0.1 * intensity
		
		if "bass" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				chunk[j] += sin(2.0 * PI * root * 0.25 * t) * 0.3 * intensity
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# TRACK 10: THE SINGULARITY EVENT
# Everything converges and collapses
# =============================================================================
func _gen_10_singularity() -> AudioStreamInteractive:
	var bpm = 100.0
	var bar = 240.0 / bpm
	var scale = _minor_scale(40)
	var prog = [0, 6, 5, 0]
	
	var p = AudioStreamInteractive.new()
	p.clip_count = 4
	p.initial_clip = 0
	
	p.set_clip_stream(0, _render_10(prog, scale, ["drone"], bar, 0.3))
	p.set_clip_name(0, "Convergence")
	
	p.set_clip_stream(1, _render_10(prog, scale, ["drone", "chaos_light"], bar, 0.6))
	p.set_clip_name(1, "Acceleration")
	
	p.set_clip_stream(2, _render_10(prog, scale, ["drone", "chaos", "all"], bar, 1.0))
	p.set_clip_name(2, "Event Horizon")
	
	p.set_clip_stream(3, _render_10(prog, scale, ["silence", "tone"], bar, 0.2))
	p.set_clip_name(3, "After")
	
	_set_auto_advance(p, 4)
	_add_xfades(p, 4, 3.0)
	return p


func _render_10(prog: Array, scale: Array, inst: Array, bar: float, intensity: float) -> AudioStreamWAV:
	var samples = int(prog.size() * bar * 2 * SAMPLE_RATE)
	var mix = PackedFloat32Array(); mix.resize(samples); mix.fill(0.0)
	var spc = int(bar * 2 * SAMPLE_RATE)
	
	for i in range(prog.size()):
		var freqs = _chord_freqs(scale, prog[i])
		var root = freqs[0]
		var chunk = PackedFloat32Array(); chunk.resize(spc); chunk.fill(0.0)
		
		if "drone" in inst:
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var drone = sin(2.0 * PI * root * 0.5 * t) * 0.3
				drone += sin(2.0 * PI * root * 0.5 * 1.01 * t) * 0.2
				chunk[j] += drone * intensity
		
		if "chaos_light" in inst or "chaos" in inst:
			var chaos_amt = 0.4 if "chaos_light" in inst else 0.8
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var chaos = sin(t * 7.0 + sin(t * 13.0) * 3.0) * 0.2
				chaos += sin(t * 23.0 + sin(t * 7.0) * 5.0) * 0.15
				if randf() < 0.005 * chaos_amt:
					chaos += (randf() - 0.5) * 0.5
				var crush = 4.0 + (1.0 - chaos_amt) * 12.0
				chaos = floor(chaos * crush) / crush
				chunk[j] += chaos * chaos_amt * intensity * (1.0 + progress)
		
		if "all" in inst:
			# Everything at once - strings, choir fragments, glitches
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var all = 0.0
				for freq in freqs:
					all += sin(2.0 * PI * freq * t)
					all += (fmod(freq * t, 1.0) * 2.0 - 1.0) * 0.5
				all /= freqs.size() * 2.0
				var pulse = abs(sin(2.0 * PI * 4.0 * t))
				chunk[j] += all * pulse * 0.25 * intensity * (1.0 + progress)
		
		if "silence" in inst:
			# Near silence with occasional crackle
			for j in range(spc):
				if randf() < 0.0005:
					chunk[j] += (randf() - 0.5) * 0.1
		
		if "tone" in inst:
			# Single pure tone emerging
			for j in range(spc):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / spc
				var tone = sin(2.0 * PI * 440.0 * t) * progress * 0.3
				chunk[j] += tone
		
		_mix_chunk(mix, chunk, i * spc)
	
	return _create_wav(mix)


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _minor_scale(root: int) -> Array:
	return [root, root+2, root+3, root+5, root+7, root+8, root+10]

func _major_scale(root: int) -> Array:
	return [root, root+2, root+4, root+5, root+7, root+9, root+11]

func _dorian_scale(root: int) -> Array:
	return [root, root+2, root+3, root+5, root+7, root+9, root+10]

func _phrygian_scale(root: int) -> Array:
	# Phrygian dominant for exotic feel
	return [root, root+1, root+4, root+5, root+7, root+8, root+10]


func _chord_freqs(scale: Array, degree: int) -> Array:
	var idx = degree % scale.size()
	var r = scale[idx]
	var t = scale[(idx + 2) % scale.size()]
	var f = scale[(idx + 4) % scale.size()]
	if t < r: t += 12
	if f < t: f += 12
	return [
		440.0 * pow(2.0, (r - 69.0) / 12.0),
		440.0 * pow(2.0, (t - 69.0) / 12.0),
		440.0 * pow(2.0, (f - 69.0) / 12.0)
	]


func _mix_chunk(mix: PackedFloat32Array, chunk: PackedFloat32Array, offset: int) -> void:
	for j in range(chunk.size()):
		if offset + j < mix.size():
			mix[offset + j] = clampf(mix[offset + j] + chunk[j], -1.0, 1.0)


func _set_auto_advance(p: AudioStreamInteractive, count: int) -> void:
	for i in range(count):
		p.set_clip_auto_advance(i, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
		p.set_clip_auto_advance_next_clip(i, (i + 1) % count)


func _add_xfades(p: AudioStreamInteractive, count: int, dur: float) -> void:
	for i in range(count):
		var next = (i + 1) % count
		p.add_transition(i, next,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS, dur)


func _create_wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var fade = int(SAMPLE_RATE * 0.015)
	var size = data.size()
	for i in range(min(fade, size)):
		var t = float(i) / fade
		data[i] *= t
		data[size - 1 - i] *= t
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	var bytes = PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in range(data.size()):
		var s = int(clampf(data[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	
	stream.data = bytes
	return stream

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

