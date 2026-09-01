extends SceneTree
## DOES THE LINE BREAK THE BARRIER — AND DOES IT REFUSE TO WHEN IT SHOULD?
##
## 2026-09-01, Palle: "After two seconds the line is turned into a big
## sledgehammer ... You can use the sledgehammer to break the cross barrier."
##
## NINE checks, FIVE of them negatives, because every interesting failure here
## is a false positive: a hammer that breaks things it is merely resting against
## is a wand, and a wand makes the opposite argument to the one the room is for.
##
##   1   the barrier starts solid and unbroken
##   2a  the swing memory decays after the probe moves the hammer into place
##   2b  RESTING against it for 12 frames does nothing   <- negative
##   3   ONE swing takes exactly ONE hit point
##   3b  the very next frames are rationed by cooldown   <- negative
##   4   the collider is actually gone (you can cross)
##   5   a SECOND strike is refused                      <- negative
##   6   the laser's contract reaches the same barrier
##   7   line_demo does NOT transform by default         <- negative, 3 other maps
##
## Two things this file learned the hard way, 2026-09-01:
##
## The barrier carries hit_points now, so ONE SWING IS ONE BLOW, not one kill.
## The old check 3 swept the head through and waited for is_broken(), which
## STRIKE_COOLDOWN makes impossible inside one sweep. probe_three_blows.gd owns
## the three-blow kill; this file owns the per-swing contract.
##
## And the old check 2 passed by ACCIDENT. Moving the hammer into position is a
## 0.4 m jump in one frame -- about 24 m/s -- which the old HEAD_SPEED_MAX of 14
## discarded as a teleport. Raising that cap to 45 (a real VR swing clears 14)
## turned the probe's own setup into a landed blow, and the resting negative was
## scoring a hit before the swing test began. It now waits for the memory to
## decay and checks hp across a still interval, which is what it always claimed.

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
	#
	# NO TELEPORT NEAR THE BARRIER. Getting the hammer into place is itself a
	# movement and the artifact can only tell it from a swing by speed -- and
	# `freeze` does NOT guarantee a jump lands in a single frame. If physics
	# splits a 0.4 m hop across two, one frame reads ~12 m/s, which is a
	# perfectly good swing, and this check scores a hit while claiming to prove
	# the opposite. It did exactly that, intermittently, which is worse than
	# failing: the same file passed and then failed with only comments changed.
	#
	# So the hammer is parked FAR (nothing to hit there, whatever the jump reads)
	# and then CREEPS in at 0.01 m per physics frame -- 0.6 m/s, below
	# HEAD_SPEED_MIN 1.15. That is a slow lean, which is the thing being tested.
	var h = Hammer.instantiate()
	get_root().add_child(h)
	await process_frame
	await process_frame
	h.freeze = true
	var rest_y := Vector3(0, -0.4, 0)
	h.global_position = b.global_position + rest_y + Vector3(0, 0, 1.2)
	for _i in 30:
		await physics_frame
	print("2a parked clear: recent=%.2f m/s cool=%.2f hp=%d"
		% [h._recent_speed, h._cool, b.hit_points_left()])
	if b.hit_points_left() != 3:
		print("   FAIL parking the hammer already damaged it"); fails += 1

	var hp_rest: int = b.hit_points_left()
	var creep_peak := 0.0
	for i in 130:
		h.global_position = b.global_position + rest_y + Vector3(0, 0, 1.2 - 0.01 * i)
		await physics_frame
		creep_peak = maxf(creep_peak, h._head_speed)
	print("2b crept in at %.2f m/s peak and rested: hp %d -> %d, broken = %s"
		% [creep_peak, hp_rest, b.hit_points_left(), b.is_broken()])
	if creep_peak >= 1.15:
		print("   FAIL the creep was not slow — this is not testing a lean"); fails += 1
	if b.hit_points_left() != hp_rest or b.is_broken():
		print("   FAIL the hammer is a wand: a slow lean damaged it"); fails += 1

	# ---- 3. ONE SWING IS ONE BLOW ---------------------------------------
	# Back out slowly (still under the threshold), then come in at 0.10 m per
	# frame: ~6 m/s at 60 Hz, well over HEAD_SPEED_MIN and nowhere near
	# HEAD_SPEED_MAX 45, so it reads as a swing rather than a jump.
	for i in 100:
		h.global_position = b.global_position + rest_y + Vector3(0, 0, -0.1 + 0.01 * i)
		await physics_frame
	var hp_before: int = b.hit_points_left()
	var landed := false
	for i in 16:
		h.global_position = b.global_position + rest_y + Vector3(0, 0, 0.9 - 0.10 * i)
		await physics_frame
		if b.hit_points_left() < hp_before:
			landed = true
			break
	print("3  swung: hp %d -> %d  (head %.2f m/s)"
		% [hp_before, b.hit_points_left(), h._head_speed])
	if not landed:
		print("   FAIL the hammer never landed"); fails += 1
	elif b.hit_points_left() != hp_before - 1:
		print("   FAIL one swing took %d hp, not 1"
			% (hp_before - b.hit_points_left())); fails += 1

	# ---- 3b. NEGATIVE: the cooldown rations the very next frames --------
	var hp_after: int = b.hit_points_left()
	for i in 6:
		h.global_position = b.global_position + Vector3(0, -0.4, 0.3 - 0.10 * i)
		await physics_frame
	print("3b immediately swinging again: hp %d -> %d (cooldown must hold)"
		% [hp_after, b.hit_points_left()])
	if b.hit_points_left() != hp_after:
		print("   FAIL STRIKE_COOLDOWN did not ration the swing"); fails += 1

	# ---- 4. take it down, and the way must open -------------------------
	# Hold the collider NOW: the barrier queue_free()s itself when it breaks, so
	# walking its children afterwards reads a freed node -- which is what used to
	# stall this probe for five minutes at exactly this line.
	var body_ref := body0
	for _i in 4:
		if not is_instance_valid(b) or b.is_broken():
			break
		b.strike(Vector3.ZERO, h)
	await process_frame
	await process_frame
	var still_there: bool = is_instance_valid(body_ref)
	print("4  collider after the break: %s (must be false — you can cross)"
		% still_there)
	if still_there:
		print("   FAIL it broke but still blocks the way"); fails += 1

	# ---- 5. NEGATIVE: one barrier is one event --------------------------
	var again: bool = false
	if is_instance_valid(b):
		again = b.strike(Vector3.ZERO, null)
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
