extends SceneTree

## CAN A HAND STILL BE AIMING AT A WEAPON THAT IS NO LONGER IN THE TREE?
##
## 2026-09-08, Palle, in the headset, "when shooting with pink gun towards the
## spider":
##
##   E grab_point.gd:34 @ _weight(): Condition "!is_inside_tree()" is true.
##     grab_point_hand.gd:106 @ can_grab() / pickable.gd:429 @ _get_grab_point()
##     pickable.gd:316 @ pick_up() / function_pickup.gd:440 @ _pick_up_object()
##     function_pickup.gd:516 @ _on_grip_pressed() / function_pickup.gd:191 @ _process()
##   E create_snap: Cannot call method 'add_child' on a null value.
##     grab_driver.gd:211 @ create_snap()
##
## grab_driver.gd:211 is `p_target.get_parent().add_child(driver)`, so the null is
## get_parent(): the hand picked up a pickable WITH NO PARENT. Its grab points are
## out of the tree with it, which is the first error.
##
## Who parks a live pickable outside the tree? We do. hand_inventory._stow()
## drops the weapon and then `p.remove_child(w)` — "Stowed = out of the tree" is
## the holster's whole mechanism. Meanwhile XRToolsFunctionPickup keeps a
## `closest_object` that is cleared by nothing except the next
## _update_closest_object(), and _on_grip_pressed guards it with only
## is_instance_valid() — which is TRUE for a live node that has been unparented.
##
## THIS PROBE MEASURES RATHER THAN ARGUES. It stands up the real rig (the addon's
## own FunctionPickup on two fake-tracked controllers, the real HandInventory,
## the real pink_gun) and after every stow prints, for BOTH hands: closest_object,
## whether that object is in the tree, and the contents of _object_in_grab_area.
## A hand pointing at an unparented body is the bug, stated as a state rather
## than as a stack trace.
##
## IT MUST DRIVE THE GRIP AXIS, NOT CALL _pick_up_object. The first version of
## this file called the addon's _pick_up_object directly, the way
## probe_hand_inventory does, and reported PASS on every check — because
## function_pickup._process returns at its first line unless
## `_controller.get_is_active()`, and a fake XRControllerTracker with no POSE is
## not active. The grab AREAS still fired (grab_area=1 in the log) while
## closest_object stayed null through the whole run: a green report on a code
## path that never executed. So the trackers here carry a pose and a grip float,
## and every pickup and drop goes through _process the way the headset does.
##
## THE WINDOW IS ONE FRAME. SceneTree emits process_frame BEFORE it propagates
## _process to nodes, so the value read straight after `await process_frame` is
## exactly the value _on_grip_pressed will consume at line 516 later in that same
## frame — before _update_closest_object at line 202 gets to correct it.
##
## The last block then DEMONSTRATES it: if a stale reference is found, it calls
## the addon's own _pick_up_object with it, which is what a re-grip does. In a
## fixed build nothing stale is found and that call never happens, so a green run
## is silent.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_stowed_weapon_regrab.gd

const GUN := "res://commons/artifacts/pink_gun/pink_gun.tscn"
const PICKUP := "res://addons/godot-xr-tools/functions/function_pickup.tscn"
const INV := "res://commons/player/hand_inventory.gd"
const REPORT := "res://ada_run/stowed_weapon_regrab_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _pickups: Dictionary = {}
var _ctrls: Dictionary = {}
var _trackers: Dictionary = {}
var _inv: Node = null
var _gun: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for h in [["left", "left_hand", XRPositionalTracker.TRACKER_HAND_LEFT], ["right", "right_hand", XRPositionalTracker.TRACKER_HAND_RIGHT]]:
		var t := XRControllerTracker.new()
		t.name = StringName(h[1])
		t.type = XRServer.TRACKER_CONTROLLER
		t.hand = h[2]
		# A POSE, or XRNode3D.get_is_active() is false and function_pickup._process
		# returns at its first line. The pose also POSITIONS the hand: XRNode3D
		# overwrites its own transform from it every frame, so setting
		# c.position here would be discarded. Both hands sit near the same spot,
		# so the bare hand also has the gun inside its grab sphere.
		t.set_pose(&"aim", Transform3D(Basis(), Vector3(-0.1 if h[0] == "left" else 0.1, 1.2, -0.3)),
			Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		t.set_input(&"grip", 0.0)
		XRServer.add_tracker(t)
		_trackers[h[0]] = t

	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	origin.current = true
	var cam := XRCamera3D.new()
	cam.position = Vector3(0, 1.65, 0)
	origin.add_child(cam)
	for h in ["left", "right"]:
		var c := XRController3D.new()
		c.name = "LeftHand" if h == "left" else "RightHand"
		c.tracker = &"left_hand" if h == "left" else &"right_hand"
		c.pose = &"aim"
		origin.add_child(c)
		var pk: Node = (load(PICKUP) as PackedScene).instantiate()
		c.add_child(pk)
		_ctrls[h] = c
		_pickups[h] = pk
	_inv = Node.new()
	_inv.name = "HandInventory"
	_inv.set_script(load(INV))
	origin.add_child(_inv)
	get_root().add_child(origin)
	await process_frame
	await process_frame

	var seg := Node3D.new()
	seg.name = "Seg0_test"
	get_root().add_child(seg)
	_gun = (load(GUN) as PackedScene).instantiate() as Node3D
	_gun.set_meta("artifact_lookup_name", "pink_gun")
	_gun.set("freeze", true)
	_gun.position = Vector3(0.0, 1.2, -0.3)
	seg.add_child(_gun)
	# let the grab areas actually register it before anyone grabs
	await _settle(6)
	_say("A. the gun stands in the hall, nobody holding it")
	_report()
	_check(_who(_pickups["right"].get("closest_object")) != "null",
		"   the harness works: the right hand elects the gun as closest",
		"the hand never saw the gun — _process is not running, and every check below would be meaningless")

	# ── the grab, by the grip, the way the headset does it ────────────
	_grip("right", 1.0)
	await _settle(6)
	_say("B. grip pressed: the right hand took it (the inventory adopts it)")
	_report()
	_check(bool(_gun.call("is_picked_up")), "   the gun is held: %s" % str(bool(_gun.call("is_picked_up"))), "the grip did not pick the gun up")

	# ── the release: drop -> the inventory holsters -> OUT OF THE TREE ─
	#
	# The next line is the whole report. Palle's grip dipped below threshold for
	# a frame while firing, and came straight back.
	# TWO awaits, and the count is the measurement. process_frame is emitted
	# BEFORE _process propagates, so the first await only puts us at the head of
	# the frame that will CARRY the release; the second puts us at the head of
	# the frame after it, which is where _on_grip_pressed reads closest_object.
	# The first version awaited once, measured before the release had happened at
	# all, and reported the hand still holding the gun.
	_grip("right", 0.0)
	await process_frame
	await process_frame
	_say("C. grip released — one frame later, before any hand's _process has run.")
	_say("   the gun is unparented: %s" % str(is_instance_valid(_gun) and _gun.get_parent() == null))
	_report()
	_judge("one frame after the grip released")

	# ── the re-grip. this is function_pickup.gd:191 -> :516 ────────────
	_grip("right", 1.0)
	await process_frame
	_say("D. grip pressed again")
	_report()
	_judge("after the re-grip")

	await _settle(6)
	_say("E. six frames later — has anything healed it?")
	_report()
	_judge("six frames after the re-grip")
	# The half-state the bad pickup leaves behind, and the reason the engine dies
	# on the way out: picked_up_object points at the gun while the gun itself
	# says it is not held, and no let_go will ever reconcile them.
	var half := false
	for h in ["right", "left"]:
		var po: Variant = _pickups[h].get("picked_up_object")
		if po != null and is_instance_valid(po) and (po as Node).get_parent() == null:
			half = true
	_check(not half, "   no hand claims to hold an unparented body: %s" % str(not half),
		"a hand's picked_up_object is an unparented body — pick_up() half-succeeded and no drop will undo it")

	_demonstrate()
	_finish()


func _grip(hand: String, v: float) -> void:
	(_trackers[hand] as XRControllerTracker).set_input(&"grip", v)


func _settle(n: int) -> void:
	for i in range(n):
		await process_frame
		await physics_frame


# ── the measurement ───────────────────────────────────────────────────────

func _report() -> void:
	for h in ["right", "left"]:
		var pk: Node = _pickups[h]
		var co: Variant = pk.get("closest_object")
		var area: Array = pk.get("_object_in_grab_area") as Array
		var ranged: Array = pk.get("_object_in_ranged_area") as Array
		_say("   %-5s closest=%-14s in_tree=%-5s | grab_area=%d%s ranged=%d%s | holding=%s" % [
			h,
			_who(co),
			(str(co.is_inside_tree()) if (co != null and is_instance_valid(co)) else "-"),
			area.size(), _stale(area), ranged.size(), _stale(ranged),
			_who(pk.get("picked_up_object")),
		])


## Is any member of one of the hand's lists a live node with no parent?
func _stale(a: Array) -> String:
	var n := 0
	for o in a:
		if o != null and is_instance_valid(o) and (o as Node).get_parent() == null:
			n += 1
	return "" if n == 0 else " (%d UNPARENTED)" % n


func _who(o: Variant) -> String:
	if o == null:
		return "null"
	if not is_instance_valid(o):
		return "FREED"
	return String((o as Node).name)


## THE CONTRACT. A hand may point at nothing, or at something standing in the
## world. It may never point at a body that has been taken out of the tree,
## because _on_grip_pressed will hand exactly that to pick_up() without ever
## asking whether it has a parent.
func _judge(when: String) -> void:
	for h in ["right", "left"]:
		var pk: Node = _pickups[h]
		var co: Variant = pk.get("closest_object")
		var stale: bool = co != null and is_instance_valid(co) and (co as Node).get_parent() == null
		_check(not stale, "%s: the %s hand's closest_object is %s" % [when, h, "STALE — an unparented body" if stale else _who(co)],
			"the %s hand is aiming at an unparented body %s — a grip press would call pick_up() on it" % [h, when])


## Only runs in a broken build: reproduce the two error lines Palle saw.
func _demonstrate() -> void:
	if _fails.is_empty():
		_say("G. nothing stale was found, so there is nothing to re-grip. (In a broken")
		_say("   build this block calls _pick_up_object with the stale reference and")
		_say("   the engine prints the two errors from the report.)")
		return
	for h in ["right", "left"]:
		var pk: Node = _pickups[h]
		var co: Variant = pk.get("closest_object")
		if co == null or not is_instance_valid(co) or (co as Node).get_parent() != null:
			continue
		_say("G. re-gripping with the %s hand — this is function_pickup.gd:516." % h)
		_say("   Expect: grab_point.gd _weight !is_inside_tree, then create_snap add_child on null.")
		pk.call("_pick_up_object", co)
		return


# ── plumbing ──────────────────────────────────────────────────────────────

func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
