extends SceneTree
## CAN A DESKTOP WALKER STOP A SILHOUETTE?
##
## 2026-09-02, Palle: "in desktop we can not stop the silhouettes".
##
## The whole chain, not just the signal: carry the gun -> LMB -> the pickable's
## action -> pink_gun.fire() -> a catalyst projectile -> hit_by_catalyst_mode ->
## the silhouette joins the "statue" group. Asserting only that action_pressed
## fired would prove the wiring and nothing about the outcome, and the outcome is
## the thing Palle asked for.
##
## FOUR CHECKS, TWO OF THEM NEGATIVES:
##   1. a carried gun fires on LMB               (the fix)
##   2. an EMPTY hand does not consume the click (or every button in the museum
##      stops working the moment this lands)
##   3. release goes to what the PRESS started, even after a drop
##   4. the silhouette actually becomes a statue (the point)

const POINTER := "res://commons/scenes/DesktopInteractionPointer.gd"
const FOE := "res://commons/hazards/catalyst_foe/catalyst_foe.tscn"


func _init() -> void:
	var fails := 0
	var ptr = load(POINTER).new()
	get_root().add_child(ptr)
	await process_frame

	# ── 2. THE NEGATIVE FIRST. Empty hand must not swallow the click. ──────
	var consumed_empty: bool = ptr.call("_try_held_action", true)
	print("empty hand consumes LMB: %s (must be false)" % consumed_empty)
	if consumed_empty:
		print("  FAIL a bare hand ate the click — every button in the museum"
			+ " would stop working"); fails += 1

	# ── 1. a carried thing fires ──────────────────────────────────────────
	var stub := _Trigger.new()
	get_root().add_child(stub)
	ptr.set("_held", stub)
	var consumed: bool = ptr.call("_try_held_action", true)
	print("")
	print("carried thing consumes LMB: %s   action() calls: %d"
		% [consumed, stub.pressed_count])
	if not consumed or stub.pressed_count != 1:
		print("  FAIL the trigger did not reach the held object"); fails += 1

	# ── 3. release follows the PRESS, not the hand ────────────────────────
	ptr.set("_held", null)                     # dropped mid-click
	ptr.call("_try_held_action", false)
	print("released after a drop: release() calls: %d (must be 1)" % stub.released_count)
	if stub.released_count != 1:
		print("  FAIL a click that began on an object never ended"); fails += 1

	# ── 4. THE POINT: a silhouette becomes a statue ───────────────────────
	var foe = load(FOE).instantiate()
	foe.set("body", "silhouette")
	get_root().add_child(foe)
	for i in range(4):
		await process_frame
	var was_statue: bool = foe.is_in_group("statue")
	foe.call("hit_by_catalyst_mode", Color(1, 0, 1), "primitives")
	await process_frame
	var now_statue: bool = foe.is_in_group("statue")
	print("")
	print("silhouette in group 'statue': before=%s  after being hit=%s"
		% [was_statue, now_statue])
	if was_statue:
		print("  FAIL it was already a statue, so this proves nothing"); fails += 1
	if not now_statue:
		print("  FAIL the silhouette kept coming"); fails += 1

	# ── 5. A CARRIED THING AIMS WHERE YOU LOOK ────────────────────────────
	# pink_gun.fire() sends its projectile along the GUN's -Z. Carrying by
	# position alone left it wearing whatever rotation it had on the shelf: the
	# trigger fires and the shot goes elsewhere, which reads as "it works" and
	# is not fixable by aiming better.
	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3.ZERO)
	ptr.set("_camera", cam)
	var thing := Node3D.new()
	get_root().add_child(thing)
	thing.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-140.0)), Vector3(9, 9, 9))
	ptr.set("_held", thing)
	var before_dot: float = (-thing.global_transform.basis.z).dot(-cam.global_transform.basis.z)
	for i in range(30):
		ptr.call("_process", 0.016)
	var after_dot: float = (-thing.global_transform.basis.z).dot(-cam.global_transform.basis.z)
	print("")
	print("carried thing aim vs view: before=%.3f  after=%.3f  (1.0 = same way)"
		% [before_dot, after_dot])
	if after_dot < 0.99:
		print("  FAIL a carried gun does not point where the player looks"); fails += 1
	if before_dot > 0.99:
		print("  FAIL it started aligned, so this proves nothing"); fails += 1

	# ── 6. THE VIEWMODEL. A weapon parks low-right, rigid to the view. ────
	# Palle: "can we have like in half life that the gun is placed at the bottom
	# of the screen and we can use from there after we pick it up?"
	ptr.call("_drop_held")
	var hall := Node3D.new()                      # stands in for a hall segment
	hall.name = "HallSegment"
	get_root().add_child(hall)
	var gun := _Trigger.new()
	hall.add_child(gun)
	gun.global_position = Vector3(3, 0, 3)
	ptr.call("_grab_held", gun)
	ptr.call("_process", 0.016)
	var holstered: bool = gun.get_parent() != hall
	var off: Vector3 = gun.transform.origin
	print("")
	print("weapon adopted out of the hall: %s   parked at %s" % [holstered, str(off)])
	if not holstered:
		print("  FAIL still parented to the hall"); fails += 1
	if off.y >= 0.0 or off.x <= 0.0:
		print("  FAIL not low and to the right — that is not a viewmodel"); fails += 1
	# and it must still point where you look, not down-right
	var aim: float = (-gun.global_transform.basis.z).dot(-cam.global_transform.basis.z)
	print("weapon aim vs view: %.3f (must be 1.0 — a tilted model fires tilted)" % aim)
	if aim < 0.999:
		print("  FAIL the viewmodel is angled, so every shot misses by that angle")
		fails += 1

	# ── 7. THE NEGATIVE THAT MATTERS: the hall is freed, gun survives ─────
	# In the museum a hall segment is freed at the next crossing. Held by
	# position alone the gun would vanish out of the player's hands — or leave a
	# freed reference behind, which is the failure this session fixed twice.
	hall.queue_free()
	await process_frame
	await process_frame
	var alive: bool = is_instance_valid(gun)
	print("")
	print("hall freed — weapon still alive: %s" % alive)
	if not alive:
		print("  FAIL the gun died with the hall it was picked up in"); fails += 1
	else:
		var still_fires: bool = ptr.call("_try_held_action", true)
		print("and it still fires after the crossing: %s" % still_fires)
		if not still_fires:
			print("  FAIL it survived but stopped working"); fails += 1

	# ── 8. a plain object is NOT holstered — it stays out in front ────────
	ptr.call("_drop_held")
	var plain := Node3D.new()
	get_root().add_child(plain)
	plain.global_position = Vector3(2, 0, 2)
	ptr.call("_grab_held", plain)
	for i in range(20):
		ptr.call("_process", 0.016)
	var d: float = plain.global_position.distance_to(cam.global_position)
	print("")
	print("plain object carried at %.2f m (must stay out in front, not holstered)" % d)
	if d < 0.9:
		print("  FAIL a carried box was treated as a weapon"); fails += 1

	# ── 9. THE SLEDGEHAMMER. It has no trigger; it is SWUNG. ─────────────
	# Palle: "can we also add the sledgehammer to the desktop inventory?"
	#
	# The real question is not whether it holsters — it is whether a scripted arc
	# produces head speed inside the band the hammer will act on: above
	# HEAD_SPEED_MIN (1.15 m/s, below which it is a lean) and below
	# HEAD_SPEED_MAX (45.0, above which the hammer reads a teleport and throws
	# the sample away). Miss the band either way and the swing is a mime.
	ptr.call("_drop_held")
	var sledge = load("res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn").instantiate()
	get_root().add_child(sledge)
	for i in range(4):
		await process_frame
	print("")
	print("sledgehammer is a weapon to the SHARED list: %s (it has no action(): %s)"
		% [ptr.call("_is_weapon_node", sledge), not sledge.has_method("action")])
	if not ptr.call("_is_weapon_node", sledge):
		print("  FAIL desktop and VR disagree about what a weapon is"); fails += 1

	ptr.call("_grab_held", sledge)
	ptr.call("_process", 0.016)
	var swung: bool = ptr.call("_try_held_action", true)
	print("LMB starts a swing: %s" % swung)
	if not swung:
		print("  FAIL nothing happens when you click with a hammer in hand"); fails += 1

	# Drive the arc and watch the HEAD, which is what the hammer measures.
	var head: Node3D = sledge.get_node_or_null("Head") as Node3D
	if head == null:
		for ch in sledge.get_children():
			if String(ch.name).to_lower().contains("head"):
				head = ch as Node3D
	var peak := 0.0
	if head != null:
		var prev: Vector3 = head.global_position
		for i in range(24):
			ptr.call("_process", 0.016)
			var now: Vector3 = head.global_position
			peak = maxf(peak, (now - prev).length() / 0.016)
			prev = now
	print("peak head speed through the arc: %.2f m/s   (need > 1.15 and < 45.0)" % peak)
	if head == null:
		print("  FAIL could not find the hammer head to measure"); fails += 1
	elif peak <= 1.15:
		print("  FAIL the swing is a lean — the hammer will ignore it"); fails += 1
	elif peak >= 20.0:
		# NOT "under 45". The first arc measured 42.56 against a 45.0 cutoff and
		# passed, and that pass was worthless: the peak was a discontinuity, not a
		# swing, and one slow frame would have tipped it into the band where the
		# hammer silently discards everything. Demand the human range its own
		# docstring names (5-14 m/s), with room either side.
		print("  FAIL %.2f m/s is a teleport, not a swing — no margin under the"
			% peak + " 45.0 cutoff, and the peak is a snap rather than the strike")
		fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


## Stands in for a GUN: a thing the shared weapon list recognises, whose
## action_pressed something is actually listening to.
##
## Both halves are load-bearing and both were missing at first. Without the token
## meta, HandInventory.is_weapon says no and it is carried instead of holstered —
## which silently turned the adoption and viewmodel checks into tests of nothing.
## Without a LISTENER on action_pressed the pointer now classes it as swingable,
## because "has an action()" turned out to be true of every pickable in the
## engine and therefore true of nothing in particular.
class _Trigger extends Node3D:
	signal action_pressed(who)

	var pressed_count := 0
	var released_count := 0

	func _init() -> void:
		set_meta("artifact_lookup_name", "pink_gun")
		action_pressed.connect(_heard)

	func _heard(_who) -> void:
		pass

	func action() -> void:
		pressed_count += 1
		action_pressed.emit(self)

	func action_release() -> void:
		released_count += 1
