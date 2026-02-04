# LiveSession.gd
# The full live performance environment
# Combines: LiveRack (state/sequencing) + LiveDeck (UI) + LiveAudioEngine (sound)
#
# Open this scene to start performing.

extends Control
class_name LiveSession

const LiveRack = preload("res://commons/audio/live/LiveRack.gd")
const LiveAudioEngine = preload("res://commons/audio/live/LiveAudioEngine.gd")

var rack: LiveRack
var engine: LiveAudioEngine
var deck_ui: Control

# Keyboard shortcuts for live performance
var key_bindings: Dictionary = {
	KEY_SPACE: "toggle_play",
	KEY_T: "build_tension",
	KEY_D: "drop",
	KEY_B: "breakdown",
	KEY_R: "bring_it_back",
	KEY_N: "new_pattern",
	KEY_UP: "filter_up",
	KEY_DOWN: "filter_down",
	KEY_1: "mute_kick",
	KEY_2: "mute_hats",
	KEY_3: "mute_acid"
}


func _ready():
	get_tree().root.title = "AdaResearch Live Session"
	
	_setup_rack()
	_setup_engine()
	_build_ui()
	
	print("═══════════════════════════════════════════════════════")
	print("  LIVE SESSION READY")
	print("═══════════════════════════════════════════════════════")
	print("  SPACE  - Play/Stop")
	print("  T      - Build Tension")
	print("  D      - DROP")
	print("  B      - Breakdown")
	print("  R      - Bring It Back")
	print("  N      - New Acid Pattern")
	print("  ↑/↓    - Filter Sweep")
	print("  1/2/3  - Mute Kick/Hats/Acid")
	print("═══════════════════════════════════════════════════════")


func _setup_rack():
	rack = LiveRack.new()
	rack.name = "Rack"
	add_child(rack)
	
	# Set initial state
	rack.bpm = 132.0
	rack.channel_levels["acid"] = 0.7
	rack.acid_cutoff_target = 600.0


func _setup_engine():
	engine = LiveAudioEngine.new()
	engine.name = "Engine"
	add_child(engine)
	engine.set_rack(rack)


func _build_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)
	
	# Title bar
	var title_panel = PanelContainer.new()
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0.1, 0.08, 0.12)
	title_panel.add_theme_stylebox_override("panel", title_style)
	main_vbox.add_child(title_panel)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 30)
	title_panel.add_child(title_hbox)
	
	var title = Label.new()
	title.text = "🎛️ LIVE SESSION"
	title.add_theme_font_size_override("font_size", 28)
	title_hbox.add_child(title)
	
	# Transport
	var play_btn = Button.new()
	play_btn.text = "▶ PLAY"
	play_btn.custom_minimum_size = Vector2(100, 40)
	play_btn.pressed.connect(_toggle_play)
	title_hbox.add_child(play_btn)
	
	var stop_btn = Button.new()
	stop_btn.text = "⏹ STOP"
	stop_btn.custom_minimum_size = Vector2(100, 40)
	stop_btn.pressed.connect(_stop)
	title_hbox.add_child(stop_btn)
	
	# BPM
	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	bpm_label.add_theme_font_size_override("font_size", 18)
	title_hbox.add_child(bpm_label)
	
	var bpm_spin = SpinBox.new()
	bpm_spin.min_value = 80
	bpm_spin.max_value = 180
	bpm_spin.value = 132
	bpm_spin.custom_minimum_size = Vector2(80, 0)
	bpm_spin.value_changed.connect(func(v): rack.set_bpm(v); engine._update_timing())
	title_hbox.add_child(bpm_spin)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(spacer)
	
	# Status
	var status = Label.new()
	status.name = "status"
	status.text = "Ready - Press SPACE to start"
	status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	title_hbox.add_child(status)
	
	rack.bar_hit.connect(func(b): status.text = "Bar %d | Phrase %d" % [b, rack.phrase])
	rack.step_hit.connect(func(_s): _update_step_display())
	
	# Step display
	var step_panel = PanelContainer.new()
	main_vbox.add_child(step_panel)
	
	var step_hbox = HBoxContainer.new()
	step_hbox.name = "steps"
	step_panel.add_child(step_hbox)
	
	var step_label = Label.new()
	step_label.text = "STEP: "
	step_hbox.add_child(step_label)
	
	for i in range(16):
		var indicator = Panel.new()
		indicator.name = "step_%d" % i
		indicator.custom_minimum_size = Vector2(30, 30)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2)
		indicator.add_theme_stylebox_override("panel", style)
		step_hbox.add_child(indicator)
		
		if i % 4 == 3 and i < 15:
			step_hbox.add_child(VSeparator.new())
	
	# Main content - channels
	var channels_hbox = HBoxContainer.new()
	channels_hbox.add_theme_constant_override("separation", 20)
	channels_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(channels_hbox)
	
	# Kick channel
	channels_hbox.add_child(_build_channel("KICK", "kick", [
		{"name": "PITCH", "param": "kick_pitch", "min": 40, "max": 100, "default": 55},
		{"name": "DECAY", "param": "kick_decay", "min": 0.1, "max": 0.5, "default": 0.25},
		{"name": "PUNCH", "param": "kick_punch", "min": 0, "max": 1, "default": 0.5}
	], "🥁"))
	
	# Hat channel
	channels_hbox.add_child(_build_channel("HATS", "hats", [
		{"name": "DECAY", "param": "hat_decay", "min": 0.02, "max": 0.3, "default": 0.05}
	], "🎩", true))
	
	# Acid channel (special styling)
	var acid_channel = _build_acid_channel()
	channels_hbox.add_child(acid_channel)
	
	# Pattern display
	var pattern_panel = PanelContainer.new()
	pattern_panel.custom_minimum_size.y = 80
	main_vbox.add_child(pattern_panel)
	
	var pattern_vbox = VBoxContainer.new()
	pattern_panel.add_child(pattern_vbox)
	
	var pattern_label = Label.new()
	pattern_label.text = "ACID PATTERN (N = new pattern)"
	pattern_vbox.add_child(pattern_label)
	
	var pattern_viz = Control.new()
	pattern_viz.name = "pattern_viz"
	pattern_viz.custom_minimum_size.y = 50
	pattern_viz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pattern_viz.draw.connect(_draw_pattern.bind(pattern_viz))
	pattern_vbox.add_child(pattern_viz)
	
	rack.pattern_changed.connect(func(_c): pattern_viz.queue_redraw())
	rack.step_hit.connect(func(_s): pattern_viz.queue_redraw())
	
	# Master section
	var master_panel = PanelContainer.new()
	main_vbox.add_child(master_panel)
	
	var master_hbox = HBoxContainer.new()
	master_hbox.add_theme_constant_override("separation", 40)
	master_panel.add_child(master_hbox)
	
	var master_label = Label.new()
	master_label.text = "MASTER"
	master_label.add_theme_font_size_override("font_size", 18)
	master_hbox.add_child(master_label)
	
	master_hbox.add_child(_make_slider("FILTER (↑/↓)", 0, 1, 1.0, 
		func(v): rack.set_master_filter(v), 300))
	
	master_hbox.add_child(_make_slider("DRIVE", 0, 1, 0.1,
		func(v): rack.master_drive = v, 150))
	
	# DJ moves
	master_hbox.add_child(VSeparator.new())
	
	var tension_btn = Button.new()
	tension_btn.text = "⚡ TENSION (T)"
	tension_btn.pressed.connect(func(): rack.build_tension())
	master_hbox.add_child(tension_btn)
	
	var drop_btn = Button.new()
	drop_btn.text = "💥 DROP (D)"
	drop_btn.pressed.connect(func(): rack.drop())
	master_hbox.add_child(drop_btn)
	
	var breakdown_btn = Button.new()
	breakdown_btn.text = "🌊 BREAKDOWN (B)"
	breakdown_btn.pressed.connect(func(): rack.breakdown())
	master_hbox.add_child(breakdown_btn)
	
	var back_btn = Button.new()
	back_btn.text = "🔥 BRING IT (R)"
	back_btn.pressed.connect(func(): rack.bring_it_back())
	master_hbox.add_child(back_btn)


func _build_channel(title: String, channel_id: String, params: Array, icon: String, has_pattern: bool = false) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 200
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var header = Label.new()
	header.text = "%s %s" % [icon, title]
	header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	for p in params:
		vbox.add_child(_make_slider(p.name, p.min, p.max, p.default,
			func(v): rack.set(p.param, v)))
	
	if has_pattern:
		var pattern_opt = OptionButton.new()
		pattern_opt.add_item("8th Notes")
		pattern_opt.add_item("Offbeat")  
		pattern_opt.add_item("16th Notes")
		pattern_opt.item_selected.connect(func(idx): rack.hat_pattern = idx)
		vbox.add_child(pattern_opt)
	
	vbox.add_child(HSeparator.new())
	
	vbox.add_child(_make_slider("LEVEL", 0, 1, rack.channel_levels.get(channel_id, 1.0),
		func(v): rack.set_channel_level(channel_id, v)))
	
	var mute_btn = CheckButton.new()
	mute_btn.text = "MUTE"
	mute_btn.toggled.connect(func(m): rack.mute_channel(channel_id, m))
	vbox.add_child(mute_btn)
	
	return panel


func _build_acid_channel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 280
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08)
	style.border_color = Color(0.9, 0.5, 0.2)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var header = Label.new()
	header.text = "🧪 TB-303 ACID"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# Main controls
	vbox.add_child(_make_slider("CUTOFF", 100, 4000, 600,
		func(v): rack.set_acid_cutoff(v)))
	
	vbox.add_child(_make_slider("RESONANCE", 0, 0.98, 0.7,
		func(v): rack.set_acid_resonance(v)))
	
	vbox.add_child(_make_slider("ENV MOD", 0, 1, 0.6,
		func(v): rack.set_acid_env_mod(v)))
	
	vbox.add_child(_make_slider("ACCENT", 0, 1, 0.5,
		func(v): rack.set_acid_accent(v)))
	
	vbox.add_child(HSeparator.new())
	
	# Pattern controls
	var pattern_hbox = HBoxContainer.new()
	vbox.add_child(pattern_hbox)
	
	var new_pattern_btn = Button.new()
	new_pattern_btn.text = "🎲 NEW PATTERN (N)"
	new_pattern_btn.pressed.connect(func(): rack.generate_acid_pattern(rack.acid_pattern_intensity))
	pattern_hbox.add_child(new_pattern_btn)
	
	vbox.add_child(_make_slider("WILDNESS", 0, 1, 0.5,
		func(v): rack.acid_pattern_intensity = v))
	
	vbox.add_child(HSeparator.new())
	
	vbox.add_child(_make_slider("LEVEL", 0, 1, 0.7,
		func(v): rack.set_channel_level("acid", v)))
	
	var mute_btn = CheckButton.new()
	mute_btn.text = "MUTE (3)"
	mute_btn.toggled.connect(func(m): rack.mute_channel("acid", m))
	vbox.add_child(mute_btn)
	
	return panel


func _make_slider(label_text: String, min_val: float, max_val: float, default: float, callback: Callable, width: int = 0) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	if width > 0:
		hbox.custom_minimum_size.x = width
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default
	slider.step = (max_val - min_val) / 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	hbox.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = "%.2f" % default
	value_label.custom_minimum_size.x = 50
	slider.value_changed.connect(func(v): value_label.text = "%.2f" % v)
	hbox.add_child(value_label)
	
	return hbox


func _update_step_display():
	var steps_container = get_node_or_null("VBoxContainer/PanelContainer/steps")
	if not steps_container:
		return
	
	for i in range(16):
		var indicator = steps_container.get_node_or_null("step_%d" % i)
		if indicator:
			var style = StyleBoxFlat.new()
			if i == rack.step:
				style.bg_color = Color(1.0, 0.5, 0.2)
			elif i % 4 == 0:
				style.bg_color = Color(0.25, 0.25, 0.3)
			else:
				style.bg_color = Color(0.15, 0.15, 0.2)
			indicator.add_theme_stylebox_override("panel", style)


func _draw_pattern(viz: Control):
	var rect = viz.get_rect()
	var w = rect.size.x
	var h = rect.size.y
	var step_w = w / 16.0
	
	viz.draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.08, 0.1))
	
	for i in range(16):
		var x = i * step_w
		
		# Highlight current step
		if i == rack.step:
			viz.draw_rect(Rect2(x, 0, step_w, h), Color(0.25, 0.15, 0.1))
		
		# Bar lines
		if i % 4 == 0:
			viz.draw_line(Vector2(x, 0), Vector2(x, h), Color(0.3, 0.3, 0.3))
		
		var note = rack.acid_pattern[i] if i < rack.acid_pattern.size() else -1
		
		if note != -1:
			var note_h = h * 0.5
			var note_y = h * 0.25
			var color = Color(0.9, 0.5, 0.2) if note >= rack.root_note + 12 else Color(0.6, 0.4, 0.2)
			viz.draw_rect(Rect2(x + 2, note_y, step_w - 4, note_h), color)
			
			# Accent
			if i < rack.acid_accents.size() and rack.acid_accents[i]:
				viz.draw_circle(Vector2(x + step_w/2, 8), 4, Color(1.0, 0.3, 0.3))
			
			# Slide
			if i < rack.acid_slides.size() and rack.acid_slides[i]:
				viz.draw_line(Vector2(x, note_y + note_h/2), Vector2(x + step_w/2, note_y), Color(0.3, 0.8, 1.0), 2)


func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_toggle_play()
			KEY_T:
				rack.build_tension()
			KEY_D:
				rack.drop()
			KEY_B:
				rack.breakdown()
			KEY_R:
				rack.bring_it_back()
			KEY_N:
				rack.generate_acid_pattern(rack.acid_pattern_intensity)
			KEY_UP:
				rack.sweep_filter_up()
			KEY_DOWN:
				rack.sweep_filter_down()
			KEY_1:
				rack.mute_channel("kick", not rack.channel_mutes.get("kick", false))
			KEY_2:
				rack.mute_channel("hats", not rack.channel_mutes.get("hats", false))
			KEY_3:
				rack.mute_channel("acid", not rack.channel_mutes.get("acid", false))


func _toggle_play():
	if rack.playing:
		_stop()
	else:
		_start()


func _start():
	rack.start()
	engine.start()


func _stop():
	rack.stop()
	engine.stop()
