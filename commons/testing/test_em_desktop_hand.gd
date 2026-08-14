extends SceneTree
## The desktop hand, proven both ways in one boot.
##
## desktop build → the walker carries a DesktopHand whose ray and camera are
## wired (the adapter mirrors the museum camera), plus the crosshair dot.
## VR build → NO DesktopHand exists: in a headset the XR rig's own pointers
## do this job, and a second ray fighting them is exactly the class of fault
## the VR wrapper exists to prevent.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_desktop_hand.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []

	# ── desktop ──────────────────────────────────────────────────────────────
	var inst: Node3D = await _museum(false)
	var hand: Node = inst.find_child("DesktopHand", true, false)
	var cam: Camera3D = inst.get("_cam")
	if hand == null:
		fails.append("desktop build has no DesktopHand")
	else:
		if hand.get("_raycast") == null:
			fails.append("DesktopHand built no raycast — parent _ready did not run")
		if hand.get("_camera") != cam:
			fails.append("DesktopHand._camera is not the museum walker's camera")
		var hits_layers: int = int(hand.get("collision_mask_value"))
		if hits_layers != (hand.get("_raycast") as RayCast3D).collision_mask:
			fails.append("raycast mask %d != exported mask %d"
				% [(hand.get("_raycast") as RayCast3D).collision_mask, hits_layers])
	if inst.find_child("Crosshair", true, false) == null:
		fails.append("desktop build has no crosshair dot")
	get_root().remove_child(inst)
	inst.queue_free()
	await create_timer(0.2).timeout

	# ── VR ───────────────────────────────────────────────────────────────────
	var rig := XROrigin3D.new()
	var eye := XRCamera3D.new()
	rig.add_child(eye)
	get_root().add_child(rig)
	var vr_inst: Node3D = await _museum(true)
	if vr_inst.find_child("DesktopHand", true, false) != null:
		fails.append("VR build carries a DesktopHand — it would fight the XR rig's pointers")
	get_root().remove_child(vr_inst)
	vr_inst.queue_free()
	get_root().remove_child(rig)
	rig.queue_free()

	if fails.is_empty():
		print("DESKTOP HAND: PASS — wired on desktop, absent in VR")
	else:
		print("DESKTOP HAND: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)


func _museum(vr: bool) -> Node3D:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_force_vr", vr)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(4):
		await create_timer(0.2).timeout
	return inst
