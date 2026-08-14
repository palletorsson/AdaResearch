extends SceneTree
## Movement-only hands, proven both ways in one boot.
##
## Applied: every gadget on the strip list is GONE and every locomotion
## piece SURVIVES — both hands' MovementDirect, turn, jump, flight, the
## collision hands they ride on, PlayerBody, and the deadzone calibrator.
## Not applied: every strip-list name is still present (the mode is opt-in;
## a default boot's rig must be byte-for-byte the rig it always was).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_bare_hands.gd

const BareHandsLib := preload("res://commons/scenes/bare_hands.gd")
const KEEP := ["MovementDirect", "MovementTurn", "MovementJump", "MovementFlight",
	"XRToolsCollisionHand", "PlayerBody", "JoystickDeadzoneFix", "MovementWallWalk"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []

	# ── control: no strip — everything present ───────────────────────────────
	var rig_off: Node3D = await _rig()
	for name in BareHandsLib.STRIP:
		if rig_off.find_child(name, true, false) == null:
			fails.append("control rig lacks %s — strip list names a node base.tscn no longer has" % name)
	get_root().remove_child(rig_off)
	rig_off.queue_free()
	await create_timer(0.2).timeout

	# ── stripped ─────────────────────────────────────────────────────────────
	var rig: Node3D = await _rig()
	var origin: Node = rig.find_child("XROrigin3D", true, false)
	var gone: int = BareHandsLib.apply(origin)
	await create_timer(0.3).timeout
	if gone < BareHandsLib.STRIP.size():
		fails.append("only %d removals for %d strip names (duplicates should push it higher)"
			% [gone, BareHandsLib.STRIP.size()])
	for name in BareHandsLib.STRIP:
		if rig.find_child(name, true, false) != null:
			fails.append("%s survived the strip" % name)
	for name in KEEP:
		if rig.find_child(name, true, false) == null:
			fails.append("%s did NOT survive — locomotion was harmed" % name)
	get_root().remove_child(rig)
	rig.queue_free()

	if fails.is_empty():
		print("BARE HANDS: PASS — %d gadgets stripped, locomotion intact, off-mode untouched" % gone)
	else:
		print("BARE HANDS: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)


func _rig() -> Node3D:
	var ps: PackedScene = load("res://commons/scenes/base.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	get_root().add_child(inst)
	for i in range(3):
		await create_timer(0.2).timeout
	return inst
