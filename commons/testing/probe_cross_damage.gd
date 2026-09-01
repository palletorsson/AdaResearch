extends SceneTree
## DOES THE CROSS ACTUALLY TAKE HEALTH?
##
## Palle: "the cross does not deal damage or?"
##
## The earlier probe checked the zone EXISTS and is configured, which is not the
## same question and is exactly the kind of check that passes on a broken thing.
## This puts a real player body inside it and watches the number.
##
## DangerZone accepts a body only if _is_player(): group "player"/"player_body",
## or a name containing "Player"/"XR". And its Area3D masks layer 20 (524288)
## only. Both have to be right or the zone sits there politely doing nothing —
## which is how the museum walker has been ignored by every player-detector in
## this repo without a single warning.

func _init() -> void:
	var fails := 0
	var X := load("res://commons/artifacts/anamorphic_cross/anamorphic_cross.tscn")
	var x = X.instantiate()
	get_root().add_child(x)
	await process_frame
	await process_frame

	var dz: Node = x.get_node_or_null("DangerZone")
	print("1  zone: mask=%d monitoring=%s tick=%.2f dmg=%.1f"
		% [dz.collision_mask, dz.monitoring, dz.tick_interval, dz.damage_per_tick])
	if dz.collision_mask != 524288:
		print("   FAIL not masking the player layer"); fails += 1

	var gm: Node = x.get_node_or_null("/root/GameManager")
	print("2  GameManager: %s  apply_health_damage=%s"
		% [gm != null, gm != null and gm.has_method("apply_health_damage")])
	if gm == null or not gm.has_method("apply_health_damage"):
		print("   FAIL nothing to take health from"); fails += 1
		print("PROBE FAILED (%d)" % fails); quit(fails); return
	gm.set_health(100.0)

	# A REAL PLAYER BODY: right group, right layer, standing in the X.
	var body := CharacterBody3D.new()
	body.name = "XRPlayerBody"
	body.add_to_group("player")
	body.collision_layer = 524288                # layer 20
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	col.shape = cap
	body.add_child(col)
	get_root().add_child(body)
	body.global_position = dz.global_position
	print("3  player placed at the crossing: %s" % body.global_position)

	for i in 6:
		await physics_frame
	print("4  entered? player_inside=%s  health=%.1f" % [dz.player_inside, gm.get_health()])
	if not dz.player_inside:
		print("   FAIL the zone never noticed the body"); fails += 1

	# let several ticks pass
	var before: float = gm.get_health()
	for i in 220:
		await physics_frame
	var after: float = gm.get_health()
	print("5  after standing in it: %.1f -> %.1f (must fall)" % [before, after])
	if after >= before:
		print("   FAIL standing in the danger X costs nothing"); fails += 1

	# AND IT MUST STOP WHEN WE LEAVE — Palle: "rest when we are out"
	body.global_position = dz.global_position + Vector3(60, 0, 0)
	for i in 10:
		await physics_frame
	var out0: float = gm.get_health()
	for i in 200:
		await physics_frame
	var out1: float = gm.get_health()
	print("6  after walking out: inside=%s  %.1f -> %.1f (must NOT fall)"
		% [dz.player_inside, out0, out1])
	if dz.player_inside or out1 < out0:
		print("   FAIL it keeps taking health after you leave"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
