## ui_theme_demo.gd — Showcase of all Ada-themed 2D controls
## Run this scene to preview the theme; tweak ada_theme.tres and see live updates.
extends Control

const _P = preload("res://commons/ui/ada_palette.gd")

func _ready():
	_build_demo()

func _build_demo():
	# ── Root scroll so everything fits ──
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root = VBoxContainer.new()
	root.size_flags_horizontal = SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 24)
	# Margins
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	margin.add_child(root)

	# ════════════════════════════════════════
	#  HEADER
	# ════════════════════════════════════════
	var header = Label.new()
	header.text = "Ada UI Design System"
	header.add_theme_font_size_override("font_size", 28)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(header)

	var subtitle = Label.new()
	subtitle.text = "Theme preview — all controls inherit from ada_theme.tres"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", _P.TEXT_SECONDARY)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	root.add_child(HSeparator.new())

	# ════════════════════════════════════════
	#  BUTTONS
	# ════════════════════════════════════════
	root.add_child(_section("Buttons"))

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	root.add_child(btn_row)

	var btn1 = Button.new(); btn1.text = "Normal Button"
	btn_row.add_child(btn1)

	var btn2 = Button.new(); btn2.text = "▶  Preview"; btn2.disabled = false
	_accent_button(btn2, _P.ACCENT_GREEN)
	btn_row.add_child(btn2)

	var btn3 = Button.new(); btn3.text = "■  Stop"
	_accent_button(btn3, _P.ACCENT_RED)
	btn_row.add_child(btn3)

	var btn4 = Button.new(); btn4.text = "Disabled"; btn4.disabled = true
	btn_row.add_child(btn4)

	var btn5 = Button.new(); btn5.text = "Primary Action"
	_accent_button(btn5, _P.ACCENT_ORANGE)
	btn_row.add_child(btn5)

	# ════════════════════════════════════════
	#  SLIDERS
	# ════════════════════════════════════════
	root.add_child(_section("Sliders"))

	var slider_grid = GridContainer.new()
	slider_grid.columns = 2
	slider_grid.add_theme_constant_override("h_separation", 24)
	slider_grid.add_theme_constant_override("v_separation", 12)
	root.add_child(slider_grid)

	for pair in [["Frequency", 440.0, 20.0, 2000.0], ["Amplitude", 0.5, 0.0, 1.0],
				 ["Decay Rate", 4.0, 0.1, 20.0], ["Mod Depth", 30.0, 0.0, 100.0]]:
		var lbl = Label.new()
		lbl.text = pair[0]
		lbl.custom_minimum_size.x = 100
		slider_grid.add_child(lbl)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.size_flags_horizontal = SIZE_EXPAND_FILL

		var sl = HSlider.new()
		sl.min_value = pair[2]; sl.max_value = pair[3]; sl.value = pair[1]
		sl.size_flags_horizontal = SIZE_EXPAND_FILL
		sl.custom_minimum_size.x = 200
		hbox.add_child(sl)

		var val = Label.new()
		val.text = "%.1f" % pair[1]
		val.add_theme_color_override("font_color", _P.ACCENT_ORANGE)
		val.custom_minimum_size.x = 60
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(val)

		sl.value_changed.connect(func(v): val.text = "%.1f" % v)
		slider_grid.add_child(hbox)

	# ════════════════════════════════════════
	#  INPUTS & DROPDOWNS
	# ════════════════════════════════════════
	root.add_child(_section("Inputs & Dropdowns"))

	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 16)
	root.add_child(input_row)

	var le = LineEdit.new()
	le.placeholder_text = "Enter value..."
	le.custom_minimum_size.x = 200
	input_row.add_child(le)

	var opt = OptionButton.new()
	for item in ["Sine", "Square", "Sawtooth", "Triangle", "Noise"]:
		opt.add_item(item)
	opt.custom_minimum_size.x = 160
	input_row.add_child(opt)

	var spin = SpinBox.new()
	spin.min_value = 20; spin.max_value = 20000; spin.value = 440; spin.step = 1
	spin.custom_minimum_size.x = 120
	input_row.add_child(spin)

	# ════════════════════════════════════════
	#  CHECKBOXES & TOGGLES
	# ════════════════════════════════════════
	root.add_child(_section("Checkboxes & Toggles"))

	var check_row = HBoxContainer.new()
	check_row.add_theme_constant_override("separation", 24)
	root.add_child(check_row)

	var cb1 = CheckBox.new(); cb1.text = "Real-time Updates"; cb1.button_pressed = true
	check_row.add_child(cb1)
	var cb2 = CheckBox.new(); cb2.text = "Tutorial Mode"
	check_row.add_child(cb2)
	var cb3 = CheckBox.new(); cb3.text = "Show Grid"; cb3.button_pressed = true
	check_row.add_child(cb3)
	var cb4 = CheckButton.new(); cb4.text = "Master Mute"
	check_row.add_child(cb4)

	# ════════════════════════════════════════
	#  PROGRESS BARS
	# ════════════════════════════════════════
	root.add_child(_section("Progress Bars"))

	var prog_col = VBoxContainer.new()
	prog_col.add_theme_constant_override("separation", 8)
	root.add_child(prog_col)

	for pair in [["Lesson Progress", 0.65], ["CPU Load", 0.23], ["Buffer Fill", 0.88]]:
		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var lbl = Label.new(); lbl.text = pair[0]; lbl.custom_minimum_size.x = 140
		hb.add_child(lbl)
		var pb = ProgressBar.new()
		pb.value = pair[1] * 100.0
		pb.size_flags_horizontal = SIZE_EXPAND_FILL
		pb.custom_minimum_size = Vector2(300, 20)
		hb.add_child(pb)
		var pct = Label.new(); pct.text = "%d%%" % int(pair[1] * 100)
		pct.add_theme_color_override("font_color", _P.ACCENT_ORANGE)
		hb.add_child(pct)
		prog_col.add_child(hb)

	# ════════════════════════════════════════
	#  TABS
	# ════════════════════════════════════════
	root.add_child(_section("Tab Container"))

	var tabs = TabContainer.new()
	tabs.custom_minimum_size.y = 120

	var tab1 = VBoxContainer.new(); tab1.name = "Parameters"
	var t1lbl = Label.new(); t1lbl.text = "Parameter controls go here"
	tab1.add_child(t1lbl)
	tabs.add_child(tab1)

	var tab2 = VBoxContainer.new(); tab2.name = "Visualization"
	var t2lbl = Label.new(); t2lbl.text = "Waveform / spectrum display"
	tab2.add_child(t2lbl)
	tabs.add_child(tab2)

	var tab3 = VBoxContainer.new(); tab3.name = "Tutorial"
	var t3lbl = Label.new(); t3lbl.text = "Educational content and exercises"
	tab3.add_child(t3lbl)
	tabs.add_child(tab3)

	root.add_child(tabs)

	# ════════════════════════════════════════
	#  PANEL CARDS (parameter card preview)
	# ════════════════════════════════════════
	root.add_child(_section("Parameter Cards (Rack Style)"))

	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 12)
	root.add_child(cards_row)

	for data in [["Frequency", "440.0", 0.5], ["Amplitude", "0.300", 0.3],
				  ["Decay Rate", "8.0", 0.65], ["Mod Depth", "30.0", 0.42]]:
		cards_row.add_child(_param_card(data[0], data[1], data[2]))

	# ════════════════════════════════════════
	#  COLOR PALETTE SWATCHES
	# ════════════════════════════════════════
	root.add_child(_section("Color Palette"))

	var swatch_row = HBoxContainer.new()
	swatch_row.add_theme_constant_override("separation", 8)
	root.add_child(swatch_row)

	var swatches = {
		"Orange": _P.ACCENT_ORANGE, "Blue": _P.ACCENT_BLUE, "Cyan": _P.ACCENT_CYAN,
		"Green": _P.ACCENT_GREEN, "Yellow": _P.ACCENT_YELLOW, "Red": _P.ACCENT_RED,
		"Panel White": _P.PANEL_WHITE, "Panel Light": _P.PANEL_LIGHT,
		"Panel Medium": _P.PANEL_MEDIUM, "Panel Dark": _P.PANEL_DARK,
		"Text Primary": _P.TEXT_PRIMARY,
	}
	for sname in swatches:
		swatch_row.add_child(_swatch(sname, swatches[sname]))

	# Footer
	root.add_child(HSeparator.new())
	var footer = Label.new()
	footer.text = "commons/ui/ada_theme.tres  ·  commons/ui/ada_palette.gd  ·  commons/ui/materials/"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", _P.TEXT_SECONDARY)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

# ═══════════════════════════════════════════
#  UI HELPERS
# ═══════════════════════════════════════════

func _section(title: String) -> Label:
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", _P.TEXT_PRIMARY)
	return lbl

func _accent_button(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = _P.CORNER_RADIUS
	style.corner_radius_top_right = _P.CORNER_RADIUS
	style.corner_radius_bottom_left = _P.CORNER_RADIUS
	style.corner_radius_bottom_right = _P.CORNER_RADIUS
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	# White text on colored bg
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	# Hover: slightly lighter
	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)
	# Pressed: slightly darker
	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

func _param_card(pname: String, value: String, slider_pct: float) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = _P.PANEL_LIGHT
	style.corner_radius_top_left = _P.CORNER_RADIUS
	style.corner_radius_top_right = _P.CORNER_RADIUS
	style.corner_radius_bottom_left = _P.CORNER_RADIUS
	style.corner_radius_bottom_right = _P.CORNER_RADIUS
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size.x = 160

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var lbl = Label.new()
	lbl.text = pname
	lbl.add_theme_font_size_override("font_size", _P.FONT_SIZE_SMALL)
	lbl.add_theme_color_override("font_color", _P.TEXT_SECONDARY)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)

	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", _P.FONT_SIZE_LABEL)
	val.add_theme_color_override("font_color", _P.ACCENT_ORANGE)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(val)

	var sl = HSlider.new()
	sl.value = slider_pct * 100
	sl.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(sl)

	return card

func _swatch(sname: String, color: Color) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)

	var rect = ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(56, 36)
	col.add_child(rect)

	var lbl = Label.new()
	lbl.text = sname
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", _P.TEXT_SECONDARY)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)

	return col
