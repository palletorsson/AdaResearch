extends SceneTree
## DOES THE BEAM HIT A VR PLAYER — AND ONLY WHEN YOU ARE IN IT?
##
## Palle: "The player dies by the laser in desktop but not in VR, can we also
## only deal damage when we hit the laser?"
##
## Six checks, and THREE are negatives, because "deals damage" is easy and
## "deals damage only when it should" is the actual request. A beam that kills
## whoever is nearest is worse than one that never fires.
##
## The stand-in is the real VR contract: CharacterBody3D, group "player_body",
## collision layer 20 — exactly what addons/godot-xr-tools/player/player_body.tscn
## ships as.

func _init() -> void:
	var fails := 0
	# The SCRIPT, not grab_laser_measure.tscn: that scene pulls in
	# XRToolsUserSettings, an autoload a SceneTree probe cannot NAME at compile
	# time, so the whole file fails to load. _beam_victim needs none of it — it
	# needs a position, the flags, and the tree, which is the point of testing
	# geometry instead of physics reporting.
	var laser = load("res://commons/primitives/laser_measure/laser_measure.gd").new()
	get_root().add_child(laser)
	await process_frame
	await process_frame
	laser.lethal = false
	laser.deals_damage = true
	laser.global_position = Vector3.ZERO

	var body := CharacterBody3D.new()
	body.name = "PlayerBody"
	body.add_to_group("player_body")
	body.collision_layer = 524288
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new(); cap.radius = 0.3; cap.height = 1.7
	col.shape = cap
	body.add_child(col)
	get_root().add_child(body)
	await process_frame

	var beam_end := Vector3(0, 0, -6.0)          # the beam runs 6 m along -Z

	# 1. STANDING IN IT, well past arm's length
	body.global_position = Vector3(0, 0, -3.0)
	await process_frame
	var v1 = laser._beam_victim(beam_end)
	print("1  standing in the beam at 3 m: victim=%s" % [v1.name if v1 else "none"])
	if v1 == null:
		print("   FAIL the VR body is invisible to the beam — the original bug"); fails += 1

	# 2. NEGATIVE: beside the beam
	body.global_position = Vector3(2.5, 0, -3.0)
	await process_frame
	var v2 = laser._beam_victim(beam_end)
	print("2  standing 2.5 m to the side: victim=%s (must be none)" % [v2.name if v2 else "none"])
	if v2 != null:
		print("   FAIL it hits people who are not in it"); fails += 1

	# 3. NEGATIVE: behind the emitter
	body.global_position = Vector3(0, 0, 3.0)
	await process_frame
	var v3 = laser._beam_victim(beam_end)
	print("3  standing BEHIND the laser: victim=%s (must be none)" % [v3.name if v3 else "none"])
	if v3 != null:
		print("   FAIL the beam fires backwards"); fails += 1

	# 4. NEGATIVE: at arm's length — you are holding it
	body.global_position = Vector3(0, 0, -0.4)
	await process_frame
	var v4 = laser._beam_victim(beam_end)
	print("4  at 0.4 m (arm's length, floor=%.1f): victim=%s (must be none)"
		% [laser.lethal_min_distance, v4.name if v4 else "none"])
	if v4 != null:
		print("   FAIL you are killed by the thing in your own hand"); fails += 1

	# 5. past the end of the beam
	body.global_position = Vector3(0, 0, -9.0)
	await process_frame
	var v5 = laser._beam_victim(beam_end)
	print("5  standing past the beam's end: victim=%s (must be none)" % [v5.name if v5 else "none"])
	if v5 != null:
		print("   FAIL the beam is longer than it looks"); fails += 1

	# 6. and it must go quiet when the laser is not armed
	laser.deals_damage = false
	laser.lethal = false
	body.global_position = Vector3(0, 0, -3.0)
	await process_frame
	var v6 = laser._beam_victim(beam_end)
	print("6  unarmed laser, body in the beam: victim=%s (must be none)" % [v6.name if v6 else "none"])
	if v6 != null:
		print("   FAIL every measuring beam in the corpus is now lethal"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
