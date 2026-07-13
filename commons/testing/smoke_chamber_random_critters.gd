extends SceneTree

## Headless VR-by-proxy test of the Chamber_Random critter loop — every
## step of the in-headset test except the hands:
##   1. Read the REAL Chamber_Random utilities layer; run CatalystVentScanner
##      exactly as GridSystem does → vent spawns (e:2:5:5:swarm:7)
##   2. Fake an armed catalyst (group "catalyst", _absorbed=true) → vent
##      warms up (5s) and emits
##   3. Emitted foes are OCTAPOD-stage critters: swarm lineage, 8 gait legs
##   4. Four catalyst hits walk one to FRIEND → escort power granted
## Prints PASS/FAIL, quit(0/1). Scrubs the progression save afterwards.

const SCANNER := preload("res://commons/managers/CatalystVentScanner.gd")
const SAVE_PATH := "user://capability_progression.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Chamber_Random critter loop (headless VR-by-proxy) ===")
	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	if mgr and mgr.has_method("reset_progression"):
		mgr.reset_progression()

	var root := Node3D.new()
	root.name = "ChamberProxy"
	get_root().add_child(root)

	var player := Node3D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	player.global_position = Vector3(0, 0, 0)

	# ── 1. Real map data → scanner (GridSystem's exact path) ──
	var f := FileAccess.open("res://commons/maps/Chamber_Random/map_data.json", FileAccess.READ)
	if f == null:
		print("FAIL: Chamber_Random map missing"); quit(1); return
	var json := JSON.new()
	json.parse(f.get_as_text())
	var md: Dictionary = json.data as Dictionary
	var utilities: Array = md.get("layers", {}).get("utilities", []) as Array
	var spawned: int = SCANNER.scan_utilities(utilities, 1.0, Vector3.ZERO, root, {"cell_inset": 0.0})
	print("- scanner spawned %d vent(s) from the real utilities layer" % spawned)
	if spawned != 1:
		print("FAIL: expected 1 vent"); quit(1); return
	var vent: Node = get_first_node_in_group("catalyst_vent")
	if vent == null:
		print("FAIL: no vent in group"); quit(1); return
	# Shorten the warmup so the test runs fast, keep everything else real.
	vent.set("start_delay_s", 0.5)
	vent.set("emit_interval_s", 0.4)

	# ── 2. Arm: fake absorbed catalyst. The vent reads n.get("_absorbed")
	# from group "catalyst", so the stand-in needs a script var — Node3D.set
	# on a missing property is a silent no-op.
	var stub := GDScript.new()
	stub.source_code = "extends Node3D\nvar _absorbed: bool = true\n"
	stub.reload()
	var armed := Node3D.new()
	armed.set_script(stub)
	armed.name = "ArmedCatalyst"
	armed.add_to_group("catalyst")
	root.add_child(armed)

	print("- catalyst armed, waiting for warmup + emissions...")
	await create_timer(2.5).timeout

	# ── 3. Emitted foes are octapod-stage swarm critters ──
	var foes: Array = get_nodes_in_group("catalyst_foe")
	print("- foes emitted: %d" % foes.size())
	if foes.size() < 2:
		print("FAIL: vent did not emit"); quit(1); return
	var foe: Node = foes[0]
	var lineage: String = str(foe.get("_locked_mode_id"))
	var stage_name: String = str(foe.call("_critter_stage").get("name", "?"))
	var mesh_root: Node = foe.get("_mesh_root")
	var legs: int = 0
	if mesh_root != null:
		legs = mesh_root.find_children("Leg?", "", true, false).size()
	print("- foe[0]: lineage='%s' stage='%s' legs=%d (expect swarm/octapod/8)" % [lineage, stage_name, legs])
	if lineage != "swarm" or stage_name != "octapod" or legs != 8:
		print("FAIL: wrong critter"); quit(1); return

	# ── 4. Four hits → friend → escort power ──
	for i in range(4):
		foe.call("hit_by_catalyst_mode", Color(0.95, 0.5, 0.2), "swarm")
	await process_frame
	var p: String = str(foe.call("get_personality"))
	var has_escort: bool = mgr != null and bool(mgr.call("has_friend_power", "escort"))
	print("- after 4 hits: personality='%s', escort power=%s" % [p, has_escort])
	if p != "friend" or not has_escort:
		print("FAIL: conversion or power"); quit(1); return

	# Scrub the save this test just wrote.
	if mgr and mgr.has_method("reset_progression"):
		mgr.reset_progression()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	print("PASS: real map → vent → octapod critters → friend → escort power")
	quit(0)
