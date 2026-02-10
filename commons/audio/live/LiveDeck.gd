# LiveDeck.gd
# The performance interface. See the signal flow. Feel the groove.
# 
# â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
# â”‚  â–¶ 132 BPM    Bar: 47    Phrase: 12                    [TENSION] [DROP] â”‚
# â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
# â”‚                                                                         â”‚
# â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
# â”‚  â”‚  STEP: â— â—‹ â—‹ â—‹ â”‚ â— â—‹ â—‹ â—‹ â”‚ â— â—‹ â—‹ â—‹ â”‚ â— â—‹ â—‹ â—‹                   â”‚   â”‚
# â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
# â”‚                                                                         â”‚
# â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                  â”‚
# â”‚  â”‚   909 KICK   â”‚  â”‚   909 HATS   â”‚  â”‚   303 ACID   â”‚                  â”‚
# â”‚  â”‚              â”‚  â”‚              â”‚  â”‚              â”‚                  â”‚
# â”‚  â”‚ PITCH [====] â”‚  â”‚ DECAY [==  ] â”‚  â”‚ CUTOFF â–“â–“â–“â–“â–‘â–‘â”‚ â† filter sweep   â”‚
# â”‚  â”‚ DECAY [===  ]â”‚  â”‚ PATTERN [8th]â”‚  â”‚ RESO   â–“â–“â–“â–“â–“â–‘â”‚                  â”‚
# â”‚  â”‚ PUNCH [==   ]â”‚  â”‚              â”‚  â”‚ ENV    â–“â–“â–“â–‘â–‘â–‘â”‚                  â”‚
# â”‚  â”‚              â”‚  â”‚              â”‚  â”‚ ACCENT â–“â–“â–“â–‘â–‘â–‘â”‚                  â”‚
# â”‚  â”‚ [â–“â–“â–“â–“â–“â–‘â–‘â–‘â–‘â–‘] â”‚  â”‚ [â–“â–“â–“â–‘â–‘â–‘â–‘â–‘â–‘â–‘] â”‚  â”‚ [â–“â–“â–“â–“â–“â–“â–“â–‘â–‘â–‘] â”‚ â† levels        â”‚
# â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                  â”‚
# â”‚                                                                         â”‚
# â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
# â”‚  â”‚  ACID PATTERN:                                                   â”‚   â”‚
# â”‚  â”‚  A1 Â·  A1 A2 â”‚ A1 Â·  A1 A1 â”‚ A2 Â·  A1 A1 â”‚ A1 A2 Â·  A1          â”‚   â”‚
# â”‚  â”‚  â—  â—‹  â—‹  â—  â”‚ â—  â—‹  â—‹  â—  â”‚ â—‹  â—‹  â—  â—‹  â”‚ â—  â—‹  â—  â—‹   accents â”‚   â”‚
# â”‚  â”‚  â—‹  â—‹  â—‹  â†—  â”‚ â—‹  â—‹  â—‹  â—‹  â”‚ â†—  â—‹  â—‹  â—‹  â”‚ â—‹  â†—  â—‹  â—‹   slides  â”‚   â”‚
# â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
# â”‚                                                                         â”‚
# â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
# â”‚  â”‚  MASTER: [â–“â–“â–“â–“â–“â–“â–“â–“â–‘â–‘] DRIVE [==] REVERB [=]    FILTER [â–“â–“â–“â–“â–“â–“â–“]â”‚   â”‚
# â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
# â”‚                                                                         â”‚
# â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜

extends Control
class_name LiveDeck

const LiveRack = preload("res://commons/audio/live/LiveRack.gd")

var rack: LiveRack
var audio_player: AudioStreamPlayer
var render_timer: Timer

# UI Elements
var step_display: Control
var kick_panel: Control
var hat_panel: Control  
var acid_panel: Control
var pattern_display: Control
var master_panel: Control
var status_label: Label

# Sliders
var acid_cutoff_slider: HSlider
var acid_reso_slider: HSlider
var acid_env_slider: HSlider
var acid_accent_slider: HSlider
var acid_level_slider: HSlider

var kick_pitch_slider: HSlider
var kick_decay_slider: HSlider
var kick_punch_slider: HSlider
var kick_level_slider: HSlider

var hat_decay_slider: HSlider
var hat_level_slider: HSlider

var master_filter_slider: HSlider
var master_drive_slider: HSlider

# Visual state
var current_step: int = 0
var filter_display_value: float = 0.0


func _ready():
	# Create the rack
	rack = LiveRack.new()
	add_child(rack)
	
	# Connect signals
	rack.step_hit.connect(_on_step)
	rack.bar_hit.connect(_on_bar)
	rack.phrase_hit.connect(_on_phrase)
	rack.parameter_changed.connect(_on_param_changed)
	rack.pattern_changed.connect(_on_pattern_changed)
	
	# Build UI
	_build_ui()
	
	# Audio output
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	
	# Render timer (simulated for now - real impl needs AudioStreamGenerator)
	render_timer = Timer.new()
	render_timer.wait_time = 0.01  # ~100fps update
	render_timer.timeout.connect(_on_render_tick)
	add_child(render_timer)


func _build_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)
	
	# Header / Transport
	var header = _build_header()
	main_vbox.add_child(header)
	
	# Step display
	step_display = _build_step_display()
	main_vbox.add_child(step_display)
	
	# Channel strips
	var channels_hbox = HBoxContainer.new()
	channels_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(channels_hbox)
	
	kick_panel = _build_kick_panel()
	channels_hbox.add_child(kick_panel)
	
	hat_panel = _build_hat_panel()
	channels_hbox.add_child(hat_panel)
	
	acid_panel = _build_acid_panel()
	channels_hbox.add_child(acid_panel)
	
	# Pattern display
	pattern_display = _build_pattern_display()
	main_vbox.add_child(pattern_display)
	
	# Master section
	master_panel = _build_master_panel()
	main_vbox.add_child(master_panel)


func _build_header() -> Control:
	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)
	
	# Play button
	var play_btn = Button.new()
	play_btn.text = "â–¶ PLAY"
	play_btn.pressed.connect(_on_play_pressed)
	hbox.add_child(play_btn)
	
	# Stop button
	var stop_btn = Button.new()
	stop_btn.text = "â¹ STOP"
	stop_btn.pressed.connect(_on_stop_pressed)
	hbox.add_child(stop_btn)
	
	# BPM
	var bpm_label = Label.new()
	bpm_label.text = "BPM:"
	hbox.add_child(bpm_label)
	
	var bpm_spin = SpinBox.new()
	bpm_spin.min_value = 80
	bpm_spin.max_value = 180
	bpm_spin.value = 132
	bpm_spin.value_changed.connect(_on_bpm_changed)
	hbox.add_child(bpm_spin)
	
	hbox.add_child(VSeparator.new())
	
	# Status
	status_label = Label.new()
	status_label.text = "Stopped"
	status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hbox.add_child(status_label)
	
	hbox.add_child(Control.new())  # Spacer
	
	# DJ Moves
	var tension_btn = Button.new()
	tension_btn.text = "âš¡ TENSION"
	tension_btn.pressed.connect(func(): rack.build_tension())
	hbox.add_child(tension_btn)
	
	var drop_btn = Button.new()
	drop_btn.text = "ðŸ’¥ DROP"
	drop_btn.pressed.connect(func(): rack.drop())
	hbox.add_child(drop_btn)
	
	var breakdown_btn = Button.new()
	breakdown_btn.text = "ðŸŒŠ BREAKDOWN"
	breakdown_btn.pressed.connect(func(): rack.breakdown())
	hbox.add_child(breakdown_btn)
	
	var back_btn = Button.new()
	back_btn.text = "ðŸ”¥ BRING IT"
	back_btn.pressed.connect(func(): rack.bring_it_back())
	hbox.add_child(back_btn)
	
	return panel


func _build_step_display() -> Control:
	var container = HBoxContainer.new()
	container.custom_minimum_size.y = 40
	
	var label = Label.new()
	label.text = "STEP: "
	container.add_child(label)
	
	# 16 step indicators
	for i in range(16):
		var step_indicator = Panel.new()
		step_indicator.custom_minimum_size = Vector2(20, 20)
		step_indicator.name = "step_%d" % i
		container.add_child(step_indicator)
		
		# Bar separators
		if i % 4 == 3 and i < 15:
			var sep = VSeparator.new()
			container.add_child(sep)
	
	return container


func _build_kick_panel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 180
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "ðŸ¥ 909 KICK"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Pitch
	vbox.add_child(_make_slider_row("PITCH", 40, 100, 55, func(v): rack.kick_pitch = v))
	kick_pitch_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("slider")
	
	# Decay
	vbox.add_child(_make_slider_row("DECAY", 0.1, 0.5, 0.25, func(v): rack.kick_decay = v))
	kick_decay_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("slider")
	
	# Punch
	vbox.add_child(_make_slider_row("PUNCH", 0, 1, 0.5, func(v): rack.kick_punch = v))
	kick_punch_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("slider")
	
	vbox.add_child(HSeparator.new())
	
	# Level
	vbox.add_child(_make_slider_row("LEVEL", 0, 1, 1.0, func(v): rack.set_channel_level("kick", v)))
	kick_level_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("slider")
	
	# Mute
	var mute_btn = CheckButton.new()
	mute_btn.text = "MUTE"
	mute_btn.toggled.connect(func(m): rack.mute_channel("kick", m))
	vbox.add_child(mute_btn)
	
	return panel


func _build_hat_panel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 180
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "ðŸŽ© 909 HATS"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Decay
	vbox.add_child(_make_slider_row("DECAY", 0.02, 0.3, 0.05, func(v): rack.hat_decay = v))
	hat_decay_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("slider")
	
	# Pattern selector
	var pattern_label = Label.new()
	pattern_label.text = "PATTERN:"
	vbox.add_child(pattern_label)
	
	var pattern_opt = OptionButton.new()
	pattern_opt.add_item("8th Notes")
	pattern_opt.add_item("Offbeat")
	pattern_opt.add_item("16th Notes")
	pattern_opt.item_selected.connect(func(idx): rack.hat_pattern = idx)
	vbox.add_child(pattern_opt)
	
	vbox.add_child(HSeparator.new())
	
	# Level
	vbox.add_child(_make_slider_row("LEVEL", 0, 1, 0.7, func(v): rack.set_channel_level("hats", v)))
	hat_level_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("slider")
	
	# Mute
	var mute_btn = CheckButton.new()
	mute_btn.text = "MUTE"
	mute_btn.toggled.connect(func(m): rack.mute_channel("hats", m))
	vbox.add_child(mute_btn)
	
	return panel


func _build_acid_panel() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 220
	
	# Highlight color for the 303
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.1)
	style.border_color = Color(0.8, 0.5, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "ðŸ§ª TB-303 ACID"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Cutoff - THE knob
	var cutoff_row = _make_slider_row("CUTOFF", 100, 4000, 400, func(v): rack.set_acid_cutoff(v))
	vbox.add_child(cutoff_row)
	acid_cutoff_slider = cutoff_row.get_node("slider")
	
	# Resonance
	var reso_row = _make_slider_row("RESO", 0, 0.98, 0.7, func(v): rack.set_acid_resonance(v))
	vbox.add_child(reso_row)
	acid_reso_slider = reso_row.get_node("slider")
	
	# Env Mod
	var env_row = _make_slider_row("ENV MOD", 0, 1, 0.6, func(v): rack.set_acid_env_mod(v))
	vbox.add_child(env_row)
	acid_env_slider = env_row.get_node("slider")
	
	# Accent
	var accent_row = _make_slider_row("ACCENT", 0, 1, 0.5, func(v): rack.set_acid_accent(v))
	vbox.add_child(accent_row)
	acid_accent_slider = accent_row.get_node("slider")
	
	vbox.add_child(HSeparator.new())
	
	# Pattern controls
	var pattern_hbox = HBoxContainer.new()
	vbox.add_child(pattern_hbox)
	
	var regen_btn = Button.new()
	regen_btn.text = "ðŸŽ² NEW PATTERN"
	regen_btn.pressed.connect(func(): rack.generate_acid_pattern(rack.acid_pattern_intensity))
	pattern_hbox.add_child(regen_btn)
	
	# Intensity slider
	var intensity_row = _make_slider_row("WILDNESS", 0, 1, 0.5, func(v): rack.acid_pattern_intensity = v)
	vbox.add_child(intensity_row)
	
	vbox.add_child(HSeparator.new())
	
	# Level
	var level_row = _make_slider_row("LEVEL", 0, 1, 0.8, func(v): rack.set_channel_level("acid", v))
	vbox.add_child(level_row)
	acid_level_slider = level_row.get_node("slider")
	
	# Mute
	var mute_btn = CheckButton.new()
	mute_btn.text = "MUTE"
	mute_btn.toggled.connect(func(m): rack.mute_channel("acid", m))
	vbox.add_child(mute_btn)
	
	return panel


func _build_pattern_display() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 100
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "ACID PATTERN"
	vbox.add_child(title)
	
	# Pattern visualization will be drawn here
	var pattern_viz = Control.new()
	pattern_viz.custom_minimum_size = Vector2(0, 60)
	pattern_viz.name = "pattern_viz"
	pattern_viz.draw.connect(_draw_pattern.bind(pattern_viz))
	vbox.add_child(pattern_viz)
	
	return panel


func _build_master_panel() -> Control:
	var panel = PanelContainer.new()
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	panel.add_child(hbox)
	
	var title = Label.new()
	title.text = "MASTER"
	title.add_theme_font_size_override("font_size", 16)
	hbox.add_child(title)
	
	# Master filter
	var filter_row = _make_slider_row("FILTER", 0, 1, 1.0, func(v): rack.set_master_filter(v))
	filter_row.custom_minimum_size.x = 300
	hbox.add_child(filter_row)
	master_filter_slider = filter_row.get_node("slider")
	
	# Drive
	var drive_row = _make_slider_row("DRIVE", 0, 1, 0.1, func(v): rack.master_drive = v)
	drive_row.custom_minimum_size.x = 200
	hbox.add_child(drive_row)
	master_drive_slider = drive_row.get_node("slider")
	
	# Reverb
	var reverb_row = _make_slider_row("REVERB", 0, 1, 0.2, func(v): rack.reverb_send = v)
	reverb_row.custom_minimum_size.x = 200
	hbox.add_child(reverb_row)
	
	return panel


func _make_slider_row(label_text: String, min_val: float, max_val: float, default: float, callback: Callable) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 70
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.name = "slider"
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default
	slider.step = (max_val - min_val) / 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	hbox.add_child(slider)
	
	var value_label = Label.new()
	value_label.name = "value"
	value_label.text = "%.2f" % default
	value_label.custom_minimum_size.x = 50
	slider.value_changed.connect(func(v): value_label.text = "%.2f" % v)
	hbox.add_child(value_label)
	
	return hbox


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# CALLBACKS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _on_play_pressed():
	rack.start()
	render_timer.start()
	status_label.text = "Playing"
	status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))


func _on_stop_pressed():
	rack.stop()
	render_timer.stop()
	status_label.text = "Stopped"
	status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))


func _on_bpm_changed(value: float):
	rack.set_bpm(value)


func _on_step(step_num: int):
	current_step = step_num
	_update_step_display()


func _on_bar(bar_num: int):
	status_label.text = "Bar %d | Phrase %d" % [bar_num, rack.phrase]


func _on_phrase(_phrase_num: int):
	pass


func _on_param_changed(param: String, value: float):
	# Update UI to reflect parameter changes (from DJ moves, etc.)
	match param:
		"acid_cutoff":
			if acid_cutoff_slider:
				acid_cutoff_slider.value = value
		"master_filter":
			if master_filter_slider:
				master_filter_slider.value = value


func _on_pattern_changed(channel: String):
	if channel == "acid":
		pattern_display.get_node("VBoxContainer/pattern_viz").queue_redraw()


func _on_render_tick():
	rack.advance(render_timer.wait_time)
	
	# Generate audio for this frame
	# In real implementation, this would feed an AudioStreamGenerator
	# For now, just update visuals
	_update_visuals()


func _update_step_display():
	for i in range(16):
		var indicator = step_display.get_node_or_null("step_%d" % i)
		if indicator:
			var style = StyleBoxFlat.new()
			if i == current_step:
				style.bg_color = Color(1.0, 0.5, 0.2)  # Active step
			elif i % 4 == 0:
				style.bg_color = Color(0.3, 0.3, 0.4)  # Downbeat
			else:
				style.bg_color = Color(0.15, 0.15, 0.2)  # Other steps
			indicator.add_theme_stylebox_override("panel", style)


func _update_visuals():
	# Smooth filter visualization
	filter_display_value = lerp(filter_display_value, rack.acid_cutoff, 0.1)
	
	# Redraw pattern
	var viz = pattern_display.get_node_or_null("VBoxContainer/pattern_viz")
	if viz:
		viz.queue_redraw()


func _draw_pattern(viz: Control):
	var rect = viz.get_rect()
	var w = rect.size.x
	var h = rect.size.y
	var step_w = w / 16.0
	
	var state = rack.get_state()
	var pattern = state.acid_pattern
	var accents = state.acid_accents
	var slides = state.acid_slides
	var cur_step = state.step
	
	# Draw background
	viz.draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.08, 0.1))
	
	# Draw steps
	for i in range(16):
		var x = i * step_w
		var note = pattern[i] if i < pattern.size() else -1
		
		# Current step highlight
		if i == cur_step:
			viz.draw_rect(Rect2(x, 0, step_w, h), Color(0.3, 0.2, 0.1))
		
		# Bar lines
		if i % 4 == 0:
			viz.draw_line(Vector2(x, 0), Vector2(x, h), Color(0.3, 0.3, 0.3))
		
		if note != -1:
			# Note indicator
			var note_height = h * 0.4
			var note_y = h * 0.3
			
			# Color by pitch
			var pitch_color = Color(0.8, 0.5, 0.2) if note >= rack.root_note + 12 else Color(0.5, 0.4, 0.3)
			viz.draw_rect(Rect2(x + 2, note_y, step_w - 4, note_height), pitch_color)
			
			# Accent dot
			if i < accents.size() and accents[i]:
				viz.draw_circle(Vector2(x + step_w/2, h * 0.15), 4, Color(1.0, 0.3, 0.3))
			
			# Slide arrow
			if i < slides.size() and slides[i]:
				viz.draw_line(
					Vector2(x, note_y + note_height/2),
					Vector2(x + step_w/2, note_y),
					Color(0.3, 0.8, 1.0),
					2.0
				)
		else:
			# Rest indicator
			viz.draw_line(
				Vector2(x + step_w/2 - 3, h/2),
				Vector2(x + step_w/2 + 3, h/2),
				Color(0.3, 0.3, 0.3),
				2.0
			)
	
	# Filter position indicator
	var filter_x = (rack.acid_cutoff - 100) / 3900.0 * w
	viz.draw_line(Vector2(filter_x, h - 5), Vector2(filter_x, h), Color(0.2, 0.8, 1.0), 3.0)
