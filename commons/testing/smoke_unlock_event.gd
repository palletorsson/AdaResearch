extends SceneTree

## Headless smoke test for theme-event capability unlocks.
##
## soft_stages.json may declare capability.unlock_event per stage:
##   { "type": "map_completed", "map": "Trans_Pit" }  — variant A
##   { "type": "theme" }                              — variant B (world calls
##                                     notify_theme_event(sequence) directly)
## Checks:
##   1. Completing the declared map unlocks the stage EARLY (transformation
##      verbs + mode land on Trans_Pit completion, no sequence_completed)
##   2. An undeclared map completion unlocks nothing
##   3. notify_theme_event is data-gated: ignored for stages without a
##      "theme" unlock_event, honoured for stages that declare one
## Prints PASS/FAIL. Restores a clean save state afterwards.

const SAVE_PATH := "user://capability_progression.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== theme-event unlock smoke test ===")
	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	if mgr == null:
		print("FAIL: CatalystCapabilityManager autoload not found")
		quit(1); return
	mgr.reset_progression()

	# ── 1. Declared map completion → early unlock ──
	if mgr.is_catalyst_mode_unlocked("transformation"):
		print("FAIL: transformation already unlocked after reset")
		quit(1); return
	mgr._on_map_completed("Trans_Pit")
	if not mgr.is_catalyst_mode_unlocked("transformation"):
		print("FAIL: Trans_Pit completion did not unlock transformation mode")
		quit(1); return
	if not mgr.is_hand_verb_available("rotate_object"):
		print("FAIL: transformation hand verbs not granted on theme event")
		quit(1); return
	print("- Trans_Pit completion unlocked transformation early (mode + verbs)")

	# ── 2. Undeclared map completion → nothing ──
	var modes_before: int = mgr.get_unlocked_catalyst_modes().size()
	mgr._on_map_completed("Some_Map_Nobody_Declared")
	if mgr.get_unlocked_catalyst_modes().size() != modes_before:
		print("FAIL: undeclared map completion changed unlocks")
		quit(1); return
	print("- undeclared map completion correctly inert")

	# ── 3. notify_theme_event is data-gated ──
	mgr.notify_theme_event("color")  # color declares no unlock_event
	if mgr.is_catalyst_mode_unlocked("chromatic"):
		print("FAIL: notify_theme_event unlocked a stage that never opted in")
		quit(1); return
	# Opt color in (in-memory only) and retry.
	var color_stage: Dictionary = mgr._all_stages.get("color", {})
	var color_cap: Dictionary = color_stage.get("capability", {})
	color_cap["unlock_event"] = {"type": "theme"}
	mgr.notify_theme_event("color")
	if not mgr.is_catalyst_mode_unlocked("chromatic"):
		print("FAIL: notify_theme_event did not unlock an opted-in stage")
		quit(1); return
	print("- notify_theme_event gated correctly (ignored w/o opt-in, fires with)")

	# Clean up: reset and remove the save file so real progression is untouched.
	mgr.reset_progression()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("PASS: theme-event unlocks fire early, stay data-gated")
	quit(0)
