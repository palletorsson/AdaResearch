@tool
class_name TrackScorecard
extends PanelContainer
## Visual display of track analysis using the 10-point rubric
## Based on TRACK_THEORY.md framework

signal analysis_complete(results: Dictionary)

var _analysis_results: Dictionary = {}

# UI references
var _overall_label: Label
var _lambda_label: Label
var _genre_fit_label: Label
var _rubric_container: VBoxContainer
var _frequency_bars: Dictionary = {}
var _energy_curve_display: Control
var _warnings_container: VBoxContainer
var _details_container: VBoxContainer


func _ready():
	_build_ui()


func _build_ui():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.10)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(main_vbox)
	
	# === HEADER ===
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "📊 TRACK SCORECARD"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	header.add_child(title)
	
	header.add_child(_create_spacer())
	
	_overall_label = Label.new()
	_overall_label.text = "—/5"
	_overall_label.add_theme_font_size_override("font_size", 20)
	_overall_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.6))
	header.add_child(_overall_label)
	
	_lambda_label = Label.new()
	_lambda_label.text = "λ=—"
	_lambda_label.add_theme_font_size_override("font_size", 14)
	_lambda_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	header.add_child(_lambda_label)
	
	_genre_fit_label = Label.new()
	_genre_fit_label.text = ""
	_genre_fit_label.add_theme_font_size_override("font_size", 12)
	_genre_fit_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	header.add_child(_genre_fit_label)
	
	main_vbox.add_child(HSeparator.new())
	
	# === 10-POINT RUBRIC ===
	var rubric_label = Label.new()
	rubric_label.text = "📋 10-POINT RUBRIC"
	rubric_label.add_theme_font_size_override("font_size", 13)
	rubric_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	main_vbox.add_child(rubric_label)
	
	_rubric_container = VBoxContainer.new()
	_rubric_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(_rubric_container)
	
	main_vbox.add_child(HSeparator.new())
	
	# === WARNINGS ===
	var warn_label = Label.new()
	warn_label.text = "⚠️ WARNINGS"
	warn_label.add_theme_font_size_override("font_size", 13)
	warn_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	main_vbox.add_child(warn_label)
	
	_warnings_container = VBoxContainer.new()
	_warnings_container.add_theme_constant_override("separation", 2)
	main_vbox.add_child(_warnings_container)
	
	main_vbox.add_child(HSeparator.new())
	
	# === FREQUENCY BALANCE ===
	var freq_label = Label.new()
	freq_label.text = "🎚️ FREQUENCY ALLOCATION"
	freq_label.add_theme_font_size_override("font_size", 13)
	freq_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	main_vbox.add_child(freq_label)
	
	var freq_display = _create_frequency_display()
	main_vbox.add_child(freq_display)
	
	main_vbox.add_child(HSeparator.new())
	
	# === ENERGY ARC ===
	var arc_label = Label.new()
	arc_label.text = "⚡ ENERGY ARC"
	arc_label.add_theme_font_size_override("font_size", 13)
	arc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	main_vbox.add_child(arc_label)
	
	_energy_curve_display = EnergyCurveDisplay.new()
	_energy_curve_display.custom_minimum_size = Vector2(0, 60)
	main_vbox.add_child(_energy_curve_display)
	
	main_vbox.add_child(HSeparator.new())
	
	# === DETAILS ===
	var detail_label = Label.new()
	detail_label.text = "🔍 DETAILS"
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	main_vbox.add_child(detail_label)
	
	_details_container = VBoxContainer.new()
	_details_container.add_theme_constant_override("separation", 2)
	main_vbox.add_child(_details_container)


func _create_frequency_display() -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	
	var band_names = ["sub", "bass", "low_mid", "mid", "presence", "air"]
	var band_labels = ["Sub", "Bass", "Lo-Mid", "Mid", "Pres", "Air"]
	var band_colors = [
		Color(0.8, 0.3, 0.3),
		Color(0.8, 0.5, 0.3),
		Color(0.7, 0.7, 0.3),
		Color(0.3, 0.8, 0.3),
		Color(0.3, 0.7, 0.8),
		Color(0.5, 0.3, 0.8)
	]
	
	for i in range(band_names.size()):
		var band_box = VBoxContainer.new()
		band_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		band_box.add_theme_constant_override("separation", 1)
		container.add_child(band_box)
		
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 40)
		bar.min_value = 0.0
		bar.max_value = 0.4
		bar.value = 0.0
		bar.show_percentage = false
		
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = Color(0.12, 0.12, 0.15)
		bar_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", bar_style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = band_colors[i]
		fill_style.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill", fill_style)
		
		band_box.add_child(bar)
		_frequency_bars[band_names[i]] = bar
		
		var lbl = Label.new()
		lbl.text = band_labels[i]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		band_box.add_child(lbl)
	
	return container


func _create_spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _create_rubric_row(name: String, score: float, description: String = "") -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	var name_label = Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	name_label.custom_minimum_size.x = 130
	row.add_child(name_label)
	
	# Score dots (1-5)
	var dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 2)
	for i in range(5):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		if i < int(score):
			dot.color = _score_to_color(score / 5.0)
		elif i < score:
			dot.color = _score_to_color(score / 5.0).darkened(0.3)
		else:
			dot.color = Color(0.2, 0.2, 0.25)
		dots.add_child(dot)
	row.add_child(dots)
	
	var score_label = Label.new()
	score_label.text = "%.1f" % score
	score_label.add_theme_font_size_override("font_size", 11)
	score_label.add_theme_color_override("font_color", _score_to_color(score / 5.0))
	score_label.custom_minimum_size.x = 30
	row.add_child(score_label)
	
	if description != "":
		var desc = Label.new()
		desc.text = description
		desc.add_theme_font_size_override("font_size", 10)
		desc.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		row.add_child(desc)
	
	return row


func _create_warning_row(text: String, severity: String = "warning") -> Label:
	var label = Label.new()
	var icon = "⚠️" if severity == "warning" else "❌" if severity == "error" else "ℹ️"
	label.text = "%s %s" % [icon, text]
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3) if severity == "warning" else Color(0.9, 0.4, 0.4))
	return label


func _create_detail_row(key: String, value: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	
	var k = Label.new()
	k.text = key + ":"
	k.add_theme_font_size_override("font_size", 10)
	k.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	k.custom_minimum_size.x = 120
	row.add_child(k)
	
	var v = Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 10)
	v.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	row.add_child(v)
	
	return row


func _score_to_color(score: float) -> Color:
	if score >= 0.8:
		return Color(0.3, 0.9, 0.4)
	elif score >= 0.6:
		return Color(0.8, 0.8, 0.3)
	elif score >= 0.4:
		return Color(0.9, 0.6, 0.3)
	else:
		return Color(0.9, 0.35, 0.35)


## Analyze audio and display results
func analyze(audio: PackedFloat32Array, bpm: float = 120.0, genre: String = "neutral"):
	_analysis_results = TrackAnalyzer.analyze_track(audio, bpm, genre)
	_update_display()
	analysis_complete.emit(_analysis_results)


## Update display with current results
func _update_display():
	if _analysis_results.is_empty():
		return
	
	var rubric = _analysis_results.get("rubric", {})
	var comp = _analysis_results.get("composition", {})
	var prod = _analysis_results.get("production", {})
	var game = _analysis_results.get("game_ready", {})
	
	# Header
	var overall = _analysis_results.get("overall_score", 2.5)
	_overall_label.text = "%.1f/5" % overall
	_overall_label.add_theme_color_override("font_color", _score_to_color(overall / 5.0))
	
	var lambda = _analysis_results.get("estimated_lambda", 0.5)
	_lambda_label.text = "λ=%.2f" % lambda
	
	var genre_fit = _analysis_results.get("genre_fit", 0.5)
	_genre_fit_label.text = "Genre fit: %d%%" % int(genre_fit * 100)
	
	# Clear and rebuild rubric
	for child in _rubric_container.get_children():
		child.queue_free()
	
	var rubric_items = [
		["1. Identity Token", rubric.get("identity_token", 3.0), ""],
		["2. Cohesion", rubric.get("cohesion", 3.0), ""],
		["3. Controlled Variation", rubric.get("controlled_variation", 3.0), ""],
		["4. Energy Arc", rubric.get("energy_arc", 3.0), comp.get("arc_shape", "")],
		["5. Frequency Allocation", rubric.get("frequency_allocation", 3.0), ""],
		["6. Dynamic Contrast", rubric.get("dynamic_contrast", 3.0), ""],
		["7. Spatial Clarity", rubric.get("spatial_clarity", 3.0), ""],
		["8. Loop Durability", rubric.get("loop_durability", 3.0), ""],
		["9. Implementation Ready", rubric.get("implementation_ready", 3.0), ""],
		["10. Emotional Truth", rubric.get("emotional_truth", 3.0), "(context needed)"]
	]
	
	for item in rubric_items:
		_rubric_container.add_child(_create_rubric_row(item[0], item[1], item[2]))
	
	# Clear and rebuild warnings
	for child in _warnings_container.get_children():
		child.queue_free()
	
	var warnings = []
	if prod.get("low_mid_warning", false):
		warnings.append(["Low-mid buildup (mud risk)", "warning"])
	if prod.get("presence_vo_conflict", false):
		warnings.append(["High presence energy (VO conflict)", "warning"])
	if comp.get("tension_risk", false):
		warnings.append([">3 tension channels active (trailer cliché)", "warning"])
	if game.get("fatigue_risk", 0.0) > 0.5:
		var culprits = game.get("fatigue_culprits", [])
		var culprit_str = ", ".join(culprits) if culprits.size() > 0 else "high-freq transients"
		warnings.append(["Loop fatigue risk: " + culprit_str, "warning"])
	if game.get("vo_recommendation", "OK") != "OK":
		warnings.append([game.get("vo_recommendation", ""), "info"])
	
	if warnings.size() == 0:
		var ok_label = Label.new()
		ok_label.text = "✅ No major issues detected"
		ok_label.add_theme_font_size_override("font_size", 10)
		ok_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		_warnings_container.add_child(ok_label)
	else:
		for w in warnings:
			_warnings_container.add_child(_create_warning_row(w[0], w[1]))
	
	# Update frequency bars
	var bands = prod.get("band_energies", {})
	for band in _frequency_bars.keys():
		_frequency_bars[band].value = bands.get(band, 0.0)
	
	# Update energy curve
	var energy_curve = comp.get("energy_curve", [])
	if _energy_curve_display is EnergyCurveDisplay:
		_energy_curve_display.set_curve(energy_curve)
	
	# Clear and rebuild details
	for child in _details_container.get_children():
		child.queue_free()
	
	_details_container.add_child(_create_detail_row("Signature consistency", "%.0f%%" % (comp.get("signature_consistency", 0.5) * 100)))
	_details_container.add_child(_create_detail_row("Motif recurrence", "%d times" % comp.get("motif_recurrence_count", 0)))
	_details_container.add_child(_create_detail_row("Tension channels", "%d active" % comp.get("tension_channels_active", 0)))
	_details_container.add_child(_create_detail_row("Palette families", "%d" % prod.get("palette_family_count", 0)))
	_details_container.add_child(_create_detail_row("Micro contrast", "%.0f%%" % (prod.get("micro_contrast", 0.5) * 100)))
	_details_container.add_child(_create_detail_row("Macro contrast", "%.0f%%" % (prod.get("macro_contrast", 0.5) * 100)))
	_details_container.add_child(_create_detail_row("Crest factor", "%.1f" % prod.get("crest_factor", 1.0)))
	_details_container.add_child(_create_detail_row("Loop seam", "%.0f%%" % (game.get("loop_seam_score", 0.5) * 100)))
	_details_container.add_child(_create_detail_row("VO safety", "%.0f%%" % (game.get("vo_safety_score", 0.5) * 100)))


func get_results() -> Dictionary:
	return _analysis_results


# === Energy Curve Display ===

class EnergyCurveDisplay extends Control:
	var _curve: Array = []
	var _shape: String = ""
	
	func set_curve(curve: Array, shape: String = ""):
		_curve = curve
		_shape = shape
		queue_redraw()
	
	func _draw():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.08, 0.1))
		
		if _curve.is_empty():
			return
		
		# Grid
		for i in range(5):
			var y = size.y * i / 4.0
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.15, 0.15, 0.18), 1.0)
		
		# Curve
		var points = PackedVector2Array()
		var max_val = 0.001
		for v in _curve:
			max_val = max(max_val, v)
		
		for i in range(_curve.size()):
			var x = float(i) / max(_curve.size() - 1, 1) * size.x
			var y = size.y - (_curve[i] / max_val) * size.y * 0.85
			points.append(Vector2(x, y))
		
		if points.size() > 1:
			var fill = points.duplicate()
			fill.append(Vector2(size.x, size.y))
			fill.append(Vector2(0, size.y))
			draw_colored_polygon(fill, Color(0.3, 0.5, 0.7, 0.25))
			
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], Color(0.4, 0.65, 0.85), 2.0)
