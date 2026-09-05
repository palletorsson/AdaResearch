extends SceneTree

## PROBE: the comment box (2026-09-05). Three things, each with its negative:
##  1. FeedbackWriter writes the SAME BYTES as DesktopMapSwitcherOverlay for an
##     entry without the additive keys - a gate must compare ACROSS implementations.
##  2. A placed box with a typed comment writes one entry, with its box and source,
##     to the path its `out` config names; an empty comment writes nothing and the
##     screen says so.
##  3. Focused text puts the box in group `ada_typing`; released text takes it out.
## Run:  godot --path . --xr-mode off --no-window --script res://commons/testing/probe_comment_box.gd
## Writes only under user://probe_cb_*, and deletes them.

const OVERLAY := "res://commons/maps/catalog/DesktopMapSwitcherOverlay.gd"
# preloaded, not by class_name: a new global class is unknown to the class cache until the editor rebuilds it
const Feedback := preload("res://commons/bridge/feedback_writer.gd")
const A := "user://probe_cb_overlay.md"
const B := "user://probe_cb_writer.md"
const AJ := "user://probe_cb_overlay.json"
const BJ := "user://probe_cb_writer.json"
const OUT := "user://probe_cb_box.md"

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)


func _read(p: String) -> String:
	return FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else ""


func _rm(p: String) -> void:
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _run() -> void:
	print("[probe_comment_box]")
	for p in [A, B, AJ, BJ, OUT]:
		_rm(p)

	# 1. parity with the overlay's writer
	var entry := {
		"timestamp": "2026-09-05T12:00:00",
		"sequence_name": "transformation",
		"map_name": "Trans_Pit",
		"artifacts": ["grower_block", "pusher_block"],
		"artifact_scene_paths": {"pusher_block": "res://x/pusher_block.tscn", "grower_block": "res://x/grower_block.tscn"},
		"comment": "the pit needs a rail\nand a second line",
	}
	var ov = load(OVERLAY).new()
	ov.call("_append_comment_markdown", A, entry)
	ov.call("_append_comment_markdown", A, entry)
	Feedback.append_markdown(B, entry)
	Feedback.append_markdown(B, entry)
	var ta := _read(A)
	var tb := _read(B)
	_check(ta.length() > 80 and ta == tb, "markdown: FeedbackWriter matches the overlay byte for byte (%d bytes)" % ta.length())
	ov.call("_append_comment_json", AJ, entry)
	ov.call("_append_comment_json", AJ, entry)
	Feedback.append_json(BJ, entry)
	Feedback.append_json(BJ, entry)
	var ja := _read(AJ)
	_check(ja.length() > 80 and ja == _read(BJ), "json: FeedbackWriter matches the overlay byte for byte (%d bytes)" % ja.length())
	# the negative: the additive keys DO change the bytes, in the one place they should
	var with_box := entry.duplicate(true)
	with_box["source"] = "comment_box"
	with_box["box"] = "probe"
	_rm(B)
	Feedback.append_markdown(B, with_box)
	var tbb := _read(B)
	_check(tbb.find("- Source: `comment_box`\n- Box: `probe`\n\nthe pit") >= 0, "the additive lines stand between the bullets and the comment")
	ov.free()

	# 2. the box
	var scene: PackedScene = load("res://commons/artifacts/comment_box/comment_box.tscn")
	var box: Node3D = scene.instantiate()
	root.add_child(box)
	box.call("apply_grid_config", {"label": "Say it", "box": "probe", "out": OUT})
	for i in range(10):
		await process_frame
	var ui = box.call("get_ui")
	_check(ui != null, "the screen's UI exists after ten frames")
	_check(box.get("label") == "Say it" and box.get("box") == "probe", "config reached the box (label, box)")
	if ui == null:
		_finish()
		return
	ui.call("set_text", "hello from the probe")
	ui.call("submit")
	for i in range(3):
		await process_frame
	var t := _read(OUT)
	_check(t.find("\n## ") == 0, "the entry starts with the bridge's header")
	_check(t.find("- Source: `comment_box`") >= 0 and t.find("- Box: `probe`") >= 0, "the entry names its source and its box")
	_check(t.find("\nhello from the probe\n") >= 0 and t.ends_with("---"), "the comment is in it, and the block ends in ---")
	_check(str(ui.call("status_text")).begins_with("Sent."), "the screen says it was sent")
	_check(str(ui.call("get_text")).is_empty(), "and the text is cleared")
	# the negative: nothing for an empty comment
	var before := t
	ui.call("set_text", "   ")
	ui.call("submit")
	for i in range(3):
		await process_frame
	_check(_read(OUT) == before, "an empty comment writes nothing")
	_check(str(ui.call("status_text")).find("Write a comment") >= 0, "and the screen says so")
	# the recent count reads back what was written
	box.call("_refresh_recent")
	await process_frame

	# 3. the typing group
	ui.call("focus_text")
	await process_frame
	_check(box.is_in_group("ada_typing"), "focused text puts the box in ada_typing")
	ui.call("release")
	await process_frame
	_check(not box.is_in_group("ada_typing"), "released text takes it out")

	box.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	for p in [A, B, AJ, BJ, OUT]:
		_rm(p)
	print("[probe_comment_box] %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)
