extends SceneTree

## Headless smoke test for the friend→power hook.
##
## Verifies the chain: catalyst hits walk a CatalystFoe along the personality
## arc; the hit that lands on FRIEND calls
## CatalystCapabilityManager.grant_friend_power(_locked_mode_id), which
## registers the power once, emits friend_power_granted, and persists to disk.
##
## Checks:
##   1. Four "branching" hits: foe → wary → neutral → curious → friend
##   2. Manager now has_friend_power("bridger"); signal fired exactly once
##   3. Second foe converted on the same lineage → NO duplicate grant
##   4. grant_friend_power("voxel_editor") → no power (editor modes excluded)
##   5. Persistence: a fresh manager instance loads "bridger" from disk
## Prints PASS/FAIL. Cleans up the save file so real progression is untouched.

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const MGR_SCRIPT := preload("res://commons/managers/CatalystCapabilityManager.gd")
const SAVE_PATH := "user://capability_progression.json"

var _granted_count: int = 0
var _granted_last: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== friend→power hook smoke test ===")

	# Start from a clean slate (and never clobber real progression: the file
	# only exists if this feature wrote it; we restore emptiness at the end).
	_remove_save()

	# Manager — the project autoload IS loaded in --script runs, and it's the
	# node the foe resolves at /root/CatalystCapabilityManager. Test against
	# it directly (creating a duplicate would assert against the wrong node).
	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	if mgr == null:
		mgr = MGR_SCRIPT.new()
		mgr.name = "CatalystCapabilityManager"
		get_root().add_child(mgr)
	mgr.reset_progression()
	mgr.friend_power_granted.connect(_on_granted)

	var root := Node.new()
	root.name = "TestRoot"
	get_root().add_child(root)

	var player := Node3D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)

	# ── 1. Walk one foe along the full arc with "branching" hits ──
	var foe: Node = FOE_SCENE.instantiate()
	root.add_child(foe)
	if foe.get_script() == null or not foe.has_method("hit_by_catalyst_mode"):
		print("FAIL: foe scene is scriptless or missing hit_by_catalyst_mode")
		quit(1); return

	var expected_arc: Array = ["wary", "neutral", "curious", "friend"]
	for i in range(4):
		foe.call("hit_by_catalyst_mode", Color(0.4, 0.9, 0.3), "branching")
		var p: String = str(foe.call("get_personality"))
		print("- hit %d → personality '%s' (expect '%s')" % [i + 1, p, expected_arc[i]])
		if p != expected_arc[i]:
			print("FAIL: arc broke at hit %d" % (i + 1))
			quit(1); return

	# ── 2. Power granted exactly once ──
	if not mgr.has_friend_power("bridger"):
		print("FAIL: 'bridger' not granted after friend conversion")
		quit(1); return
	if _granted_count != 1:
		print("FAIL: friend_power_granted fired %d times (expected 1)" % _granted_count)
		quit(1); return
	print("- power 'bridger' granted, signal payload: %s" % [_granted_last])

	# ── 3. Second conversion on same lineage → no duplicate ──
	var foe2: Node = FOE_SCENE.instantiate()
	root.add_child(foe2)
	for i in range(4):
		foe2.call("hit_by_catalyst_mode", Color(0.4, 0.9, 0.3), "branching")
	if _granted_count != 1:
		print("FAIL: duplicate grant on second conversion (count=%d)" % _granted_count)
		quit(1); return
	print("- second conversion deduped correctly")

	# ── 4. Editor modes grant nothing ──
	mgr.grant_friend_power("voxel_editor")
	if mgr.get_friend_powers().size() != 1:
		print("FAIL: editor mode granted a power")
		quit(1); return
	print("- editor mode 'voxel_editor' correctly grants nothing")

	# ── 5. Persistence round-trip ──
	if not FileAccess.file_exists(SAVE_PATH):
		print("FAIL: save file not written")
		quit(1); return
	var mgr2: Node = MGR_SCRIPT.new()
	mgr2.name = "CapabilityManagerReload"
	get_root().add_child(mgr2)
	await process_frame  # let _ready run (_load_saved_progress)
	if not mgr2.has_friend_power("bridger"):
		print("FAIL: fresh manager did not load 'bridger' from disk")
		quit(1); return
	print("- persistence round-trip OK (fresh manager loaded 'bridger')")

	_remove_save()
	print("PASS: friend→power hook grants, dedupes, excludes tools, persists")
	quit(0)


func _on_granted(mode_id: String, power: String) -> void:
	_granted_count += 1
	_granted_last = [mode_id, power]


func _remove_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
