class_name ContentValidatorUI
extends Control

## Dev tool with drill-down navigation:
## World Map (with descriptions) → Sequence Detail → Map Detail (with text tabs)

signal sequence_opened(seq_name: String)
signal map_opened(seq_name: String, map_name: String)

# Pages
@onready var pages: Control = $Pages
@onready var world_map_page: Control = $Pages/WorldMapPage
@onready var sequence_page: Control = $Pages/SequencePage
@onready var map_page: Control = $Pages/MapPage

# World Map
@onready var status_label: Label = $Pages/WorldMapPage/VBox/Header/StatusLabel
@onready var validate_btn: Button = $Pages/WorldMapPage/VBox/Header/ValidateButton
@onready var metro_map: ContentMapRenderer = $Pages/WorldMapPage/VBox/HSplit/MetroMapPanel/MetroMap
@onready var spine_container: VBoxContainer = $Pages/WorldMapPage/VBox/HSplit/Scroll/SpineContainer

# Sequence Page
@onready var seq_back_btn: Button = $Pages/SequencePage/VBox/Header/BackButton
@onready var seq_title: Label = $Pages/SequencePage/VBox/Header/Title
@onready var seq_info: RichTextLabel = $Pages/SequencePage/VBox/InfoPanel
@onready var maps_container: GridContainer = $Pages/SequencePage/VBox/Scroll/MapsContainer

# Map Page
@onready var map_back_btn: Button = $Pages/MapPage/VBox/Header/BackButton
@onready var map_title: Label = $Pages/MapPage/VBox/Header/Title
@onready var map_grid: Control = $Pages/MapPage/VBox/HSplit/LeftPanel/MapGrid
@onready var map_tabs: TabContainer = $Pages/MapPage/VBox/HSplit/RightPanel/MapTabs
@onready var artifacts_list: ItemList = $Pages/MapPage/VBox/HSplit/LeftPanel/ArtifactsList

var _report: ContentValidator.ValidationReport = null
var _current_sequence: String = ""
var _current_map: String = ""

const PHASE_COLORS := {
	"F_order": Color("#4A90D9"),
	"oscillation": Color("#9B59B6"),
	"E_entropy": Color("#E74C3C"),
	"lambda_edge": Color("#F39C12"),
	"integration": Color("#2ECC71"),
	"synthesis": Color("#E91E63")
}

func _ready():
	_connect_signals()
	call_deferred("_run_validation")
	_show_page("world_map")

func _connect_signals():
	if validate_btn:
		validate_btn.pressed.connect(_run_validation)
	if seq_back_btn:
		seq_back_btn.pressed.connect(func(): _show_page("world_map"))
	if map_back_btn:
		map_back_btn.pressed.connect(func(): _open_sequence(_current_sequence))
	if artifacts_list:
		artifacts_list.item_selected.connect(_on_artifact_selected)
	if metro_map:
		metro_map.sequence_clicked.connect(_open_sequence)

#region Validation

func _run_validation():
	if status_label:
		status_label.text = "Validating..."
	
	_report = ContentValidator.validate_all()
	_update_status()
	_rebuild_world_map()
	
	# Update metro map
	if metro_map:
		metro_map.set_report(_report)
	
	ContentValidator.print_report(_report)

func _update_status():
	if not status_label or not _report:
		return
	
	var errors = _report.issues.filter(func(i): return i.get("type") == "error").size()
	var warnings = _report.issues.size() - errors
	
	if errors == 0 and warnings == 0:
		status_label.text = "✅ %d sequences | %d maps" % [_report.total_sequences, _report.total_maps]
	else:
		status_label.text = "⚠️ %d seq | %d maps | %d errors" % [_report.total_sequences, _report.total_maps, errors]

#endregion

#region Page Navigation

func _show_page(page_name: String):
	if not pages:
		return
	for child in pages.get_children():
		child.visible = false
	
	match page_name:
		"world_map": world_map_page.visible = true if world_map_page else false
		"sequence": sequence_page.visible = true if sequence_page else false
		"map": map_page.visible = true if map_page else false

#endregion

#region World Map Page

func _rebuild_world_map():
	if not spine_container or not _report:
		return
	
	for child in spine_container.get_children():
		child.queue_free()
	
	var phase_order = ["F_order", "oscillation", "E_entropy", "lambda_edge", "integration", "synthesis"]
	var by_phase: Dictionary = {}
	for phase in phase_order:
		by_phase[phase] = []
	by_phase["branch"] = []
	
	for seq_name in _report.sequences.keys():
		var seq = _report.sequences[seq_name] as ContentValidator.SequenceInfo
		var phase = seq.phase if seq.phase != "" else "branch"
		if by_phase.has(phase):
			by_phase[phase].append(seq_name)
	
	for phase in by_phase.keys():
		by_phase[phase].sort_custom(func(a, b):
			var sa = _report.sequences[a] as ContentValidator.SequenceInfo
			var sb = _report.sequences[b] as ContentValidator.SequenceInfo
			if sa.is_spine and sb.is_spine:
				return sa.spine_order < sb.spine_order
			return a < b
		)
	
	for phase in phase_order + ["branch"]:
		if by_phase[phase].is_empty():
			continue
		_add_phase_section(phase, by_phase[phase])

func _add_phase_section(phase: String, seq_names: Array):
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	# Phase header with margin
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 8)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	var header = Label.new()
	header.text = _get_phase_display_name(phase)
	header.add_theme_font_size_override("font_size", 20)
	if PHASE_COLORS.has(phase):
		header.add_theme_color_override("font_color", PHASE_COLORS[phase])
	header_margin.add_child(header)
	section.add_child(header_margin)
	
	# Sequence cards
	for seq_name in seq_names:
		var card = _create_sequence_card_with_description(seq_name)
		section.add_child(card)
	
	# Separator with margin
	var sep_margin = MarginContainer.new()
	sep_margin.add_theme_constant_override("margin_top", 12)
	var sep = HSeparator.new()
	sep_margin.add_child(sep)
	section.add_child(sep_margin)
	
	spine_container.add_child(section)

func _create_sequence_card_with_description(seq_name: String) -> Control:
	var seq = _report.sequences[seq_name] as ContentValidator.SequenceInfo
	
	# Use PanelContainer as the clickable card
	var card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Style
	var style = StyleBoxFlat.new()
	var base_color = PHASE_COLORS.get(seq.phase, Color(0.2, 0.2, 0.2))
	style.bg_color = base_color.darkened(0.75)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	# Title row
	var title_row = HBoxContainer.new()
	
	var icon = "🚇 " if seq.is_spine else "↳ "
	var status = _get_sequence_status(seq)
	
	var title_label = Label.new()
	title_label.text = "%s%s %s" % [icon, seq.display_name, status]
	title_label.add_theme_font_size_override("font_size", 16)
	title_row.add_child(title_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	
	var maps_label = Label.new()
	var existing = _count_existing_maps(seq)
	maps_label.text = "%d/%d maps" % [existing, seq.maps.size()]
	maps_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	title_row.add_child(maps_label)
	
	vbox.add_child(title_row)
	
	# Description (truth or description)
	if seq.description != "" or seq.truth != "":
		var desc_label = Label.new()
		var desc_text = seq.truth if seq.truth != "" else seq.description
		# Truncate if too long
		if desc_text.length() > 150:
			desc_text = desc_text.substr(0, 147) + "..."
		desc_label.text = desc_text
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size = Vector2(0, 0)
		vbox.add_child(desc_label)
	
	# Difficulty + time
	if seq.difficulty != "" or seq.estimated_time != "":
		var meta_label = Label.new()
		var meta_parts = []
		if seq.difficulty != "":
			meta_parts.append(seq.difficulty.capitalize())
		if seq.estimated_time != "":
			meta_parts.append(seq.estimated_time)
		meta_label.text = " • ".join(meta_parts)
		meta_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		meta_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(meta_label)
	
	card.add_child(vbox)
	
	# Make it clickable with hover effect
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_sequence(seq_name)
	)
	card.mouse_entered.connect(func():
		var hover_style = style.duplicate()
		hover_style.bg_color = base_color.darkened(0.6)
		card.add_theme_stylebox_override("panel", hover_style)
	)
	card.mouse_exited.connect(func():
		card.add_theme_stylebox_override("panel", style)
	)
	
	return card

func _get_sequence_status(seq: ContentValidator.SequenceInfo) -> String:
	var missing = 0
	var broken = 0
	for map_name in seq.maps:
		if seq.map_status.has(map_name):
			var mi = seq.map_status[map_name] as ContentValidator.MapInfo
			if not mi.exists:
				missing += 1
			else:
				for art_key in mi.artifact_status.keys():
					var art = mi.artifact_status[art_key] as ContentValidator.ArtifactStatus
					if not art.in_registry or not art.scene_exists:
						broken += 1
	
	if missing > 0:
		return "❌%d" % missing
	elif broken > 0:
		return "⚠️%d" % broken
	elif seq.maps.size() > 0:
		return "✓"
	return ""

func _count_existing_maps(seq: ContentValidator.SequenceInfo) -> int:
	var count = 0
	for map_name in seq.maps:
		if seq.map_status.has(map_name):
			var mi = seq.map_status[map_name] as ContentValidator.MapInfo
			if mi.exists:
				count += 1
	return count

#endregion

#region Sequence Page

func _open_sequence(seq_name: String):
	if not _report or not _report.sequences.has(seq_name):
		return
	
	_current_sequence = seq_name
	var seq = _report.sequences[seq_name] as ContentValidator.SequenceInfo
	
	if seq_title:
		var icon = "🚇 " if seq.is_spine else "↳ "
		seq_title.text = icon + seq.display_name
	
	if seq_info:
		var lines: Array[String] = []
		
		if seq.is_spine:
			lines.append("[b]Spine #%d[/b] • %s" % [seq.spine_order, _get_phase_display_name(seq.phase)])
		else:
			lines.append("[b]Branch sequence[/b]")
		
		if seq.description != "":
			lines.append("")
			lines.append(seq.description)
		
		if seq.qfep_connection != "":
			lines.append("")
			lines.append("[color=#888]QFEP: %s[/color]" % seq.qfep_connection)
		
		if seq.formula != "":
			lines.append("")
			lines.append("[code]%s[/code]" % seq.formula)
		
		var existing = _count_existing_maps(seq)
		lines.append("")
		lines.append("[b]Maps:[/b] %d/%d exist" % [existing, seq.maps.size()])
		
		seq_info.bbcode_enabled = true
		seq_info.text = "\n".join(lines)
	
	if maps_container:
		for child in maps_container.get_children():
			child.queue_free()
		
		for i in range(seq.maps.size()):
			var card = _create_map_card(seq, seq.maps[i], i + 1)
			maps_container.add_child(card)
	
	_show_page("sequence")
	emit_signal("sequence_opened", seq_name)

func _create_map_card(seq: ContentValidator.SequenceInfo, map_name: String, order: int) -> Control:
	var mi: ContentValidator.MapInfo = null
	if seq.map_status.has(map_name):
		mi = seq.map_status[map_name] as ContentValidator.MapInfo
	
	# Use PanelContainer for proper clipping
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 110)
	card.clip_contents = true
	
	# Style
	var style = StyleBoxFlat.new()
	if mi and not mi.exists:
		style.bg_color = Color(0.35, 0.1, 0.1)
	elif mi and _count_broken_artifacts(mi) > 0:
		style.bg_color = Color(0.35, 0.25, 0.1)
	else:
		style.bg_color = Color(0.15, 0.15, 0.18)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	# Title
	var status = "?"
	if mi:
		if mi.exists:
			var broken = _count_broken_artifacts(mi)
			status = "⚠️" if broken > 0 else "✓" if mi.artifacts.size() > 0 else "○"
		else:
			status = "❌"
	
	var title = Label.new()
	title.text = "%d. %s %s" % [order, map_name, status]
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	# Blurb preview (2 lines max)
	if mi and mi.has_blurb:
		var blurb = Label.new()
		var text = mi.blurb.replace("\n", " ").strip_edges()
		# Remove markdown header if present
		if text.begins_with("# "):
			var space_idx = text.find(" ", 2)
			if space_idx > 0:
				text = text.substr(space_idx + 1).strip_edges()
		# Shorter truncation for 2 lines
		if text.length() > 60:
			text = text.substr(0, 57) + "..."
		blurb.text = text
		blurb.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		blurb.add_theme_font_size_override("font_size", 11)
		blurb.max_lines_visible = 2
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(blurb)
	
	# Artifacts count + text indicators
	if mi and mi.exists:
		var meta = Label.new()
		var parts = ["%d artifacts" % mi.artifacts.size()]
		var text_count = 0
		if mi.has_blurb: text_count += 1
		if mi.has_technical: text_count += 1
		if mi.has_summary: text_count += 1
		if mi.has_critical: text_count += 1
		if text_count > 0:
			parts.append("%d texts" % text_count)
		meta.text = " • ".join(parts)
		meta.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		meta.add_theme_font_size_override("font_size", 11)
		vbox.add_child(meta)
	
	card.add_child(vbox)
	
	# Click + hover
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_map(map_name)
	)
	card.mouse_entered.connect(func():
		var hover = style.duplicate()
		hover.bg_color = style.bg_color.lightened(0.15)
		card.add_theme_stylebox_override("panel", hover)
	)
	card.mouse_exited.connect(func():
		card.add_theme_stylebox_override("panel", style)
	)
	
	return card

func _count_broken_artifacts(mi: ContentValidator.MapInfo) -> int:
	var count = 0
	for art_key in mi.artifact_status.keys():
		var art = mi.artifact_status[art_key] as ContentValidator.ArtifactStatus
		if not art.in_registry or not art.scene_exists:
			count += 1
	return count

#endregion

#region Map Page

func _open_map(map_name: String):
	if not _report or _current_sequence == "":
		return
	
	var seq = _report.sequences.get(_current_sequence) as ContentValidator.SequenceInfo
	if not seq or not seq.map_status.has(map_name):
		return
	
	_current_map = map_name
	var mi = seq.map_status[map_name] as ContentValidator.MapInfo
	
	if map_title:
		map_title.text = map_name
	
	# Update artifacts list
	if artifacts_list:
		artifacts_list.clear()
		for art_key in mi.artifacts:
			var status = mi.artifact_status.get(art_key) as ContentValidator.ArtifactStatus
			var icon = "✓"
			if status:
				if not status.in_registry:
					icon = "❌"
				elif not status.scene_exists:
					icon = "⚠️"
			artifacts_list.add_item("%s %s" % [icon, art_key])
	
	# Draw 2D grid
	if map_grid and mi.exists:
		_draw_map_grid(mi)
	
	# Update tabs with text content
	if map_tabs:
		_populate_map_tabs(mi)
	
	_show_page("map")
	emit_signal("map_opened", _current_sequence, map_name)

func _draw_map_grid(mi: ContentValidator.MapInfo):
	var file = FileAccess.open(mi.path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	
	var layers = json.data.get("layers", {})
	map_grid.set_meta("structure", layers.get("structure", []))
	map_grid.set_meta("interactables", layers.get("interactables", []))
	map_grid.set_meta("utilities", layers.get("utilities", []))
	map_grid.set_meta("artifact_status", mi.artifact_status)
	map_grid.queue_redraw()

func _populate_map_tabs(mi: ContentValidator.MapInfo):
	# Clear existing tabs
	for child in map_tabs.get_children():
		child.queue_free()
	
	# Overview tab (always present)
	var overview = _create_tab_content("Overview")
	
	var overview_lines: Array[String] = []
	overview_lines.append("[b]%s[/b]" % mi.name)
	overview_lines.append("")
	
	if mi.exists:
		overview_lines.append("Status: [color=green]✓ EXISTS[/color]")
		overview_lines.append("Path: [code]%s[/code]" % mi.path)
		if mi.dimensions.size() > 0:
			overview_lines.append("Size: %dx%d" % [mi.dimensions.get("width", 0), mi.dimensions.get("depth", 0)])
		if mi.difficulty != "":
			overview_lines.append("Difficulty: %s" % mi.difficulty)
		if mi.estimated_time != "":
			overview_lines.append("Time: %s" % mi.estimated_time)
		overview_lines.append("")
		overview_lines.append("[b]Artifacts:[/b] %d" % mi.artifacts.size())
		
		# Blurb at bottom
		if mi.has_blurb:
			overview_lines.append("")
			overview_lines.append("[i]%s[/i]" % mi.blurb.strip_edges())
	else:
		overview_lines.append("Status: [color=red]❌ MISSING[/color]")
	
	overview.text = "\n".join(overview_lines)
	map_tabs.add_child(overview)
	map_tabs.set_tab_title(0, "Overview")
	
	var tab_idx = 1
	
	# Technical tab
	if mi.has_technical:
		var tech = _create_tab_content("Technical")
		tech.text = _markdown_to_bbcode(mi.technical)
		map_tabs.add_child(tech)
		map_tabs.set_tab_title(tab_idx, "Technical")
		tab_idx += 1
	
	# Summary tab
	if mi.has_summary:
		var summary = _create_tab_content("Summary")
		summary.text = _markdown_to_bbcode(mi.summary_text)
		map_tabs.add_child(summary)
		map_tabs.set_tab_title(tab_idx, "Summary")
		tab_idx += 1
	
	# Critical tab
	if mi.has_critical:
		var critical = _create_tab_content("Critical")
		critical.text = _markdown_to_bbcode(mi.critical)
		map_tabs.add_child(critical)
		map_tabs.set_tab_title(tab_idx, "Critical")

func _create_tab_content(tab_name: String) -> RichTextLabel:
	var rtl = RichTextLabel.new()
	rtl.name = tab_name
	rtl.bbcode_enabled = true
	rtl.selection_enabled = true
	rtl.scroll_active = true
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.custom_minimum_size = Vector2(0, 350)
	return rtl

func _on_artifact_selected(idx: int):
	if not artifacts_list or not _report or _current_sequence == "" or _current_map == "":
		return
	
	var seq = _report.sequences.get(_current_sequence) as ContentValidator.SequenceInfo
	if not seq or not seq.map_status.has(_current_map):
		return
	
	var mi = seq.map_status[_current_map] as ContentValidator.MapInfo
	var artifact_key = mi.artifacts[idx] if idx < mi.artifacts.size() else ""
	if artifact_key == "":
		return
	
	var status = mi.artifact_status.get(artifact_key) as ContentValidator.ArtifactStatus
	
	# Show artifact details in a popup or update first tab
	_show_artifact_details(artifact_key, status)

func _show_artifact_details(artifact_key: String, status: ContentValidator.ArtifactStatus):
	if not map_tabs or map_tabs.get_child_count() == 0:
		return
	
	# Get or create Artifact tab
	var artifact_tab: RichTextLabel = null
	var artifact_tab_idx = -1
	
	for i in range(map_tabs.get_child_count()):
		if map_tabs.get_tab_title(i) == "Artifact":
			artifact_tab = map_tabs.get_child(i) as RichTextLabel
			artifact_tab_idx = i
			break
	
	if not artifact_tab:
		artifact_tab = _create_tab_content("Artifact")
		map_tabs.add_child(artifact_tab)
		artifact_tab_idx = map_tabs.get_child_count() - 1
		map_tabs.set_tab_title(artifact_tab_idx, "Artifact")
	
	# Build artifact info
	var lines: Array[String] = []
	lines.append("[font_size=18][b]%s[/b][/font_size]" % artifact_key)
	lines.append("")
	
	if status:
		if status.in_registry:
			lines.append("Registry: [color=green]✓ Found[/color]")
		else:
			lines.append("Registry: [color=red]❌ NOT FOUND[/color]")
			lines.append("")
			lines.append("[color=gray]This artifact key is used in the map but has no entry in the artifact registry.[/color]")
			lines.append("")
			lines.append("To fix, add an entry to:")
			lines.append("[code]res://commons/artifacts/grid_artifacts.json[/code]")
			lines.append("or a file in:")
			lines.append("[code]res://commons/artifacts/registry/[/code]")
		
		if status.scene_path != "":
			lines.append("")
			lines.append("[b]Scene Path:[/b]")
			lines.append("[code]%s[/code]" % status.scene_path)
			
			if status.scene_exists:
				lines.append("Status: [color=green]✓ Scene exists[/color]")
			else:
				lines.append("Status: [color=red]❌ Scene file not found[/color]")
		
		if status.error != "":
			lines.append("")
			lines.append("[color=orange]Error: %s[/color]" % status.error)
	else:
		lines.append("[color=gray]No status information available[/color]")
	
	# Add usage info
	lines.append("")
	lines.append("[b]Usage in map:[/b]")
	lines.append("Map: %s" % _current_map)
	lines.append("Sequence: %s" % _current_sequence)
	
	artifact_tab.text = "\n".join(lines)
	
	# Switch to artifact tab
	map_tabs.current_tab = artifact_tab_idx

func _markdown_to_bbcode(md: String) -> String:
	# Simple markdown to BBCode conversion
	var text = md
	
	# Headers
	var lines = text.split("\n")
	var result: Array[String] = []
	for line in lines:
		if line.begins_with("### "):
			result.append("[b]%s[/b]" % line.substr(4))
		elif line.begins_with("## "):
			result.append("[font_size=16][b]%s[/b][/font_size]" % line.substr(3))
		elif line.begins_with("# "):
			result.append("[font_size=18][b]%s[/b][/font_size]" % line.substr(2))
		else:
			result.append(line)
	text = "\n".join(result)
	
	# Bold
	var regex = RegEx.new()
	regex.compile("\\*\\*(.+?)\\*\\*")
	text = regex.sub(text, "[b]$1[/b]", true)
	
	# Italic
	regex.compile("\\*(.+?)\\*")
	text = regex.sub(text, "[i]$1[/i]", true)
	
	# Code blocks
	regex.compile("```[a-z]*\\n([\\s\\S]*?)```")
	text = regex.sub(text, "[code]$1[/code]", true)
	
	# Inline code
	regex.compile("`(.+?)`")
	text = regex.sub(text, "[code]$1[/code]", true)
	
	return text

#endregion

#region Helpers

func _get_phase_display_name(phase: String) -> String:
	match phase:
		"F_order": return "🔵 Order (F)"
		"oscillation": return "🟣 Oscillation"
		"E_entropy": return "🔴 Entropy (E)"
		"lambda_edge": return "🟠 Edge of Chaos (λ)"
		"integration": return "🟢 Integration (φΔE)"
		"synthesis": return "🩷 Synthesis"
		"branch": return "↳ Branches"
		_: return phase

#endregion

#region Public API

func get_report() -> ContentValidator.ValidationReport:
	return _report

func refresh():
	_run_validation()

#endregion
