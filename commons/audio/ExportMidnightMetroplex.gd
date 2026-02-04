# ExportMidnightMetroplex.gd
# Run this script to export the Midnight Metroplex track to WAV
#
# Usage in Godot:
#   1. Open this script
#   2. Click "Run" (Ctrl+Shift+X) or attach to a node and run the scene
#   3. Check res://exports/ for the WAV file

extends Node

func _ready():
	print("=== EXPORTING MIDNIGHT METROPLEX ===")
	print("")
	
	# Create exports directory
	if not DirAccess.dir_exists_absolute("res://exports"):
		DirAccess.make_dir_absolute("res://exports")
	
	# Export the track
	var output_path = "res://exports/midnight_metroplex.wav"
	var success = SongExporter.export_song("detroit_techno", output_path)
	
	if success:
		print("")
		print("✅ SUCCESS!")
		print("   Output: " + output_path)
		print("")
		print("   The file is in your project's exports/ folder.")
		print("   Full path: " + ProjectSettings.globalize_path(output_path))
	else:
		print("")
		print("❌ EXPORT FAILED - check console for errors")
	
	print("")
	print("=== DONE ===")
	
	# Quit after export (comment out if you want to keep running)
	# get_tree().quit()
