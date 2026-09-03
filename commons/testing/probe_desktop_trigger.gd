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

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


## Stands in for a pickable. The real chain is checked in step 4; here the
## question is only whether the pointer reaches an object's trigger at all, and a
## stub answers that without a physics projectile's travel time.
class _Trigger extends Node3D:
	var pressed_count := 0
	var released_count := 0

	func action() -> void:
		pressed_count += 1

	func action_release() -> void:
		released_count += 1
