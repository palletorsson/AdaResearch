extends Control

## Standalone desktop wrapper for ContentValidatorUI
## Run: godot --path . res://commons/dev_tools/ContentValidatorDesktop.tscn

@onready var validator_ui: ContentValidatorUI = $MarginContainer/VBoxContainer/ContentValidatorUI
@onready var export_btn: Button = $MarginContainer/VBoxContainer/TitleBar/ExportButton
@onready var close_btn: Button = $MarginContainer/VBoxContainer/TitleBar/CloseButton

func _ready():
	print("")
	print("╔══════════════════════════════════════════╗")
	print("║   AdaResearch Content Validator          ║")
	print("║   F5 = Refresh | Esc = Close             ║")
	print("╚══════════════════════════════════════════╝")
	print("")
	
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	if export_btn:
		export_btn.pressed.connect(_on_export_pressed)
	
	if validator_ui:
		validator_ui.sequence_opened.connect(_on_sequence_opened)
		validator_ui.map_opened.connect(_on_map_opened)

func _on_sequence_opened(seq_name: String):
	print("→ Sequence: %s" % seq_name)

func _on_map_opened(seq_name: String, map_name: String):
	print("→ Map: %s/%s" % [seq_name, map_name])

func _on_export_pressed():
	if not validator_ui:
		return
	
	var report = validator_ui.get_report()
	if not report:
		print("No report available")
		return
	
	var md = _generate_markdown(report)
	var path = "res://commons/dev_tools/validation_report.md"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(md)
		file.close()
		print("✅ Exported to: %s" % path)
	else:
		print("❌ Failed to write report")

func _generate_markdown(report: ContentValidator.ValidationReport) -> String:
	var lines: PackedStringArray = []
	
	lines.append("# AdaResearch Content Validation Report")
	lines.append("")
	lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	lines.append("")
	
	lines.append("## Summary")
	lines.append("")
	lines.append("| Metric | Count |")
	lines.append("|--------|-------|")
	lines.append("| Sequences | %d |" % report.total_sequences)
	lines.append("| Spine | %d |" % report.spine_order.size())
	lines.append("| Branch | %d |" % (report.total_sequences - report.spine_order.size()))
	lines.append("| Maps | %d |" % report.total_maps)
	lines.append("| Missing Maps | %d |" % report.missing_maps)
	lines.append("| Orphaned Maps | %d |" % report.orphaned_maps)
	lines.append("| Artifacts | %d |" % report.total_artifacts)
	lines.append("| Undefined Artifacts | %d |" % report.missing_artifacts)
	lines.append("| Missing Scenes | %d |" % report.missing_scenes)
	lines.append("")
	
	if report.issues.size() > 0:
		lines.append("## Issues")
		lines.append("")
		for issue in report.issues:
			var icon = "❌" if issue.get("type", "") == "error" else "⚠️"
			var loc = ""
			if issue.has("sequence"):
				loc = issue["sequence"]
			if issue.has("map"):
				loc += "/" + issue["map"]
			if issue.has("artifact"):
				loc += "/" + issue["artifact"]
			lines.append("- %s **%s**: %s" % [icon, loc.trim_prefix("/"), issue.get("message", "")])
		lines.append("")
	
	lines.append("## Spine Sequences")
	lines.append("")
	for seq_name in report.spine_order:
		if report.sequences.has(seq_name):
			var seq = report.sequences[seq_name] as ContentValidator.SequenceInfo
			var existing = 0
			for map_name in seq.maps:
				if seq.map_status.has(map_name):
					var mi = seq.map_status[map_name] as ContentValidator.MapInfo
					if mi.exists:
						existing += 1
			lines.append("- **%s** (%s) — %d/%d maps" % [seq.display_name, seq.phase, existing, seq.maps.size()])
	
	return "\n".join(lines)

func _on_close_pressed():
	get_tree().quit()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		if validator_ui:
			validator_ui.refresh()
			print("🔄 Refreshed")
