@tool
extends SceneTree
# Smoke-test the orb slice: load each script and instantiate the rig.
# Verifies parse correctness + that base/subclass PERSONALITY_ARC don't
# collide at load time.
func _init() -> void:
	var paths := [
		"res://commons/hazards/hazard_creature_base.gd",
		"res://commons/hazards/catalyst_foe/catalyst_foe.gd",
		"res://commons/hazards/becoming_catalyst/orb_gesture_detector.gd",
		"res://commons/hazards/becoming_catalyst/catalyst_orb.gd",
		"res://commons/hazards/becoming_catalyst/orb_test_rig.gd",
	]
	for p in paths:
		var s = load(p)
		if s == null:
			push_error("[smoke_orb_slice] FAILED to load %s" % p)
			quit(1)
			return
		print("[smoke_orb_slice] loaded %s" % p)

	# Instantiate the detector and orb procedurally to confirm constructors.
	var det_scene: PackedScene = load("res://commons/hazards/becoming_catalyst/orb_gesture_detector.tscn")
	var orb_scene: PackedScene = load("res://commons/hazards/becoming_catalyst/catalyst_orb.tscn")
	var rig_scene: PackedScene = load("res://commons/hazards/becoming_catalyst/orb_test_rig.tscn")
	if det_scene == null or orb_scene == null or rig_scene == null:
		push_error("[smoke_orb_slice] scene load FAILED")
		quit(1)
		return

	var det: Node = det_scene.instantiate()
	var orb: Node = orb_scene.instantiate()
	var rig: Node = rig_scene.instantiate()
	get_root().add_child(det)
	get_root().add_child(orb)
	get_root().add_child(rig)
	await process_frame
	print("[smoke_orb_slice] detector class: ", det.get_class(), " script: ", det.get_script())
	print("[smoke_orb_slice] orb class: ", orb.get_class(), " script: ", orb.get_script())
	print("[smoke_orb_slice] rig class: ", rig.get_class(), " script: ", rig.get_script())
	print("[smoke_orb_slice] PASS")
	quit()
