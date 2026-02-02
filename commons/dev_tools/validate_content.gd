@tool
extends EditorScript

## Quick content validation from Editor > Run Script
## Or run from command line: godot --script res://commons/dev_tools/validate_content.gd

func _run():
	print("")
	print("╔════════════════════════════════════════╗")
	print("║  AdaResearch Content Validator         ║")
	print("╚════════════════════════════════════════╝")
	print("")
	
	var report = ContentValidator.validate_all()
	ContentValidator.print_report(report)
	
	print("")
	print("───────────────────────────────────────────")
	print("")
	
	# Print spine sequence overview
	print("SPINE PROGRESSION:")
	for seq_name in report.spine_order:
		if report.sequences.has(seq_name):
			var seq = report.sequences[seq_name] as ContentValidator.SequenceInfo
			var status = "✓" if _seq_is_valid(seq) else "⚠"
			print("  %d. %s %s (%d maps)" % [seq.spine_order, status, seq.display_name, seq.maps.size()])
	
	print("")
	print("Run ContentValidatorDesktop.tscn for interactive UI")
	print("")

func _seq_is_valid(seq: ContentValidator.SequenceInfo) -> bool:
	for map_name in seq.maps:
		if seq.map_status.has(map_name):
			var map_info = seq.map_status[map_name] as ContentValidator.MapInfo
			if not map_info.exists:
				return false
			for art_key in map_info.artifact_status.keys():
				var art_status = map_info.artifact_status[art_key] as ContentValidator.ArtifactStatus
				if not art_status.in_registry or not art_status.scene_exists:
					return false
	return true
