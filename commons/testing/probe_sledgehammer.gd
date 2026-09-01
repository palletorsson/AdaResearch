extends SceneTree
## DOES THE LINE BREAK THE BARRIER — AND DOES IT REFUSE TO WHEN IT SHOULD?
##
## 2026-09-01, Palle: "After two seconds the line is turned into a big
## sledgehammer ... You can use the sledgehammer to break the cross barrier."
##
## Seven checks, and FOUR are negatives, because every interesting failure here
## is a false positive: a hammer that breaks things it is merely resting against
## is a wand, and a wand makes the opposite argument to the one the room is for.
##
##   1  the barrier starts solid and unbroken
##   2  a SLOW touch does nothing                       <- negative
##   3  a swung strike breaks it
##   4  the collider is actually gone (you can cross)
##   5  a SECOND strike is refused                      <- negative
##   6  the laser's contract reaches the same barrier
##   7  line_demo does NOT transform by default         <- negative, 3 other maps

func _init() -> void:
	var fails := 0
	var Barrier := load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn")
	var Hammer := load("res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn")

	# ---- 1. a barrier stands, solid -------------------------------------
	var b = Barrier.instantiate()
	get_root().add_child(b)
	await process_frame
	await process_frame
	var body0 := _find_static(b)
	print("1  barrier built: body=%s broken=%s" % [body0 != null, b.is_broken()])
	if body0 == null:
		print("   FAIL a barrier with no collider forbids nothing"); fails += 1
	if b.is_broken():
		print("   FAIL born broken"); fails += 1
	if body0 != null and (body0.collision_layer & 1048576) == 0:
		print("   FAIL not on the laser's layer — the beam cannot reach it"); fails += 1

	# ---- 2. THE NEGATIVE THAT MATTERS: a slow lean does nothing ---------
	var h = Hammer.instantiate()
	get_root().add_child(h)
	await process_frame
	await process_frame
	# Park the head inside the barrier and let two frames pass WITHOUT moving it:
	# overlapping is not striking.
	h.global_position = b.global_position + Vector3(0, -0.4, 0)
	await process_frame
	await process_frame
	await process_frame
	print("2  resting against it, barrier broken = %s (must be false)" % b.is_broken())
	if b.is_broken():
		print("   FAIL the hammer is a wand: contact alone destroyed it"); fails += 1

	# ---- 3 + 4. a swung strike --------------------------------------
	# Speed is measured at the head per physics frame, so a real displacement
	# between frames is what a swing IS as far as this artifact is concerned.
	# A pickable is a RigidBody3D, and the physics server fights a teleport: the
	# body is put back where IT thinks it belongs on the next step, so the head
	# never accumulates the displacement the strike test is looking for. Freezing
	# makes the transform authoritative, which is what a hand holding it does too.
	h.freeze = true
	h.global_position = b.global_position + Vector3(0, -0.4, 0.6)
	await physics_frame
	await physics_frame
	print("   [where] hammer=%s head=%s barrier=%s body=%s"
		% [h.global_position, h._head.global_position, b.global_position,
		   body0.global_position if body0 else "-"])
	print("   [masks] strike radius=%.2f body.layer=%d"
		% [h._strike_shape.radius, body0.collision_layer if body0 else -1])
	# Ask the SPACE, not the Area3D. If the space knows the barrier is at the
	# head's position and the Area3D does not, the fault is the Area; if neither
	# does, the barrier's collider is not where its node says it is.
	var st: PhysicsDirectSpaceState3D = h.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var probe_shape := SphereShape3D.new()
	probe_shape.radius = 0.2
	q.shape = probe_shape
	q.collision_mask = 1048577
	q.transform = Transform3D(Basis(), b.global_position + Vector3(0, 0.46, 0.0))
	var hits: Array = st.intersect_shape(q, 8)
	print("   [space] direct query at the barrier centre found %d collider(s)" % hits.size())
	for hit in hits:
		print("           %s  layer=%d" % [hit.collider, hit.collider.collision_layer])
	# ONE SWING IS ONE BLOW, not one kill. The barrier carries hit_points now,
	# so this loop asks whether a swing LANDS -- it cannot ask whether it breaks,
	# because STRIKE_COOLDOWN deliberately rations one hit per 0.45 s and this
	# sweep lasts a fraction of that. probe_three_blows.gd owns the kill.
	var hp_before: int = b.hit_points_left()
	var ok := false
	for i in 14:
		h.global_position = b.global_position + Vector3(0, -0.4, 0.9 - 0.14 * i)
		await physics_frame
		print("      z=%+.2f head_y=%.2f speed=%.2f recent=%.2f"
			% [0.9 - 0.14 * i, h._head.global_position.y, h._head_speed, h._recent_speed])
		await physics_frame
		if b.hit_points_left() < hp_before:
			ok = true
			break
	print("3  swung: hp %d -> %d   (head %.2f m/s)"
		% [hp_before, b.hit_points_left(), h._head_speed])
	if not ok:
		print("   FAIL the hammer never landed"); fails += 1

	# and now take it down, so the collider check below has something to check.
	# BOUNDED: an unbounded drain loop here hung the probe for five minutes.
	for _i in 4:
		if not is_instance_valid(b) or b.is_broken():
			break
		b.strike(Vector3.ZERO, h)
	await process_frame
	await process_frame
	var body1 := _find_static(b)
	print("4  collider after the break: %s (must be null — you can cross)" % [body1])
	if body1 != null:
		print("   FAIL it broke but still blocks the way"); fails += 1

	# ---- 5. NEGATIVE: one barrier is one event --------------------------
	var again: bool = b.strike(Vector3.ZERO, null)
	print("5  second strike returns %s (must be false)" % again)
	if again:
		print("   FAIL a broken barrier broke again"); fails += 1

	# ---- 6. the laser's contract reaches the same target ----------------
	var b2 = Barrier.instantiate()
	get_root().add_child(b2)
	await process_frame
	await process_frame
	b2.trigger_explosion()
	print("6  via trigger_explosion (the laser's own entry): broken = %s" % b2.is_broken())
	if not b2.is_broken():
		print("   FAIL the beam and the head do not reach the same target"); fails += 1

	# ---- 7. NEGATIVE: the transform is OFF by default -------------------
	var LineDemo := load("res://commons/primitives/snappoint/demos/line_demo.tscn")
	var ld = LineDemo.instantiate()
	print("7  line_demo becomes_hammer_after default = %.1f (must be 0.0)"
		% ld.becomes_hammer_after)
	if ld.becomes_hammer_after != 0.0:
		print("   FAIL three other maps place this and would sprout hammers"); fails += 1
	ld.free()

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


func _find_static(n: Node) -> StaticBody3D:
	if n is StaticBody3D:
		return n
	for c in n.get_children():
		var r := _find_static(c)
		if r != null:
			return r
	return null
