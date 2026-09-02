extends SceneTree

## Does the hand inventory adopt the gun, survive the hall, flip on the
## thumbstick, and put the catalyst on and off the hand? (2026-08-29)
##
## No headset. A fake rig: an XROrigin3D with two XRController3D (trackers
## left_hand / right_hand registered on the XRServer, so XR Tools grab points
## can tell the hands apart), each carrying the addon's own FunctionPickup, and
## the HandInventory node beside them. The museum is stood in for by a "segment"
## Node3D holding the pink gun with the museum's metas. Then:
##
##   the right pickup takes the gun (the addon's own _pick_up_object) — the
##     inventory ADOPTS it: the gun's parent is the holster, not the segment; it
##     is still in the hand; the state is weapons; the museum metas are gone
##   the segment is freed — the gun is alive and still held (the failure this
##     exists for: in the museum the hall dies at the next crossing)
##   thumbstick click: weapons -> bare — gun out of the tree, hand empty
##   click: bare -> weapons — gun back in the hand
##   the visitor lets go — the gun is holstered, not dropped in the air
##   with a catalyst known: click, click: -> catalysts — a crystal under the
##     controller, the bracelet on it; click: -> bare — both gone
##
## The manager's save flags are snapshotted and restored, so the probe leaves
## user://capability_progression.json as it found it.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_hand_inventory.gd

const GUN := "res://commons/artifacts/pink_gun/pink_gun.tscn"
const HAMMER := "res://commons/artifacts/line_sledgehammer/line_sledgehammer.tscn"
const PICKUP := "res://addons/godot-xr-tools/functions/function_pickup.tscn"
const INV := "res://commons/player/hand_inventory.gd"
const REPORT := "res://ada_run/hand_inventory_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# trackers, so a grab point can ask which hand a controller is
	for h in [["left_hand", XRPositionalTracker.TRACKER_HAND_LEFT], ["right_hand", XRPositionalTracker.TRACKER_HAND_RIGHT]]:
		var t := XRControllerTracker.new()
		t.name = h[0]
		t.type = XRServer.TRACKER_CONTROLLER
		t.hand = h[1]
		XRServer.add_tracker(t)

	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	origin.current = true
	var cam := XRCamera3D.new()
	cam.position = Vector3(0, 1.65, 0)
	origin.add_child(cam)
	var ctrls: Dictionary = {}
	var pickups: Dictionary = {}
	for h in ["left", "right"]:
		var c := XRController3D.new()
		c.name = "LeftHand" if h == "left" else "RightHand"
		c.tracker = &"left_hand" if h == "left" else &"right_hand"
		c.pose = &"aim"
		c.position = Vector3(-0.2 if h == "left" else 0.2, 1.2, -0.3)
		origin.add_child(c)
		var pk: Node = (load(PICKUP) as PackedScene).instantiate()
		c.add_child(pk)
		ctrls[h] = c
		pickups[h] = pk
	var inv := Node.new()
	inv.name = "HandInventory"
	inv.set_script(load(INV))
	origin.add_child(inv)
	get_root().add_child(origin)
	await process_frame
	await process_frame
	_check(int((inv.get("_pickups") as Dictionary).size()) == 2, "inventory wired %d pickup(s)" % (inv.get("_pickups") as Dictionary).size(), "pickups not found")

	# the museum's gun, in a segment that will die
	var seg := Node3D.new()
	seg.name = "Seg0_test"
	get_root().add_child(seg)
	var gun: Node3D = (load(GUN) as PackedScene).instantiate() as Node3D
	gun.set_meta("artifact_lookup_name", "pink_gun")
	gun.set_meta("em_foe_gun", true)
	gun.set_meta("em_cartridge_deferred", true)
	gun.set("freeze", true)
	gun.position = Vector3(0.3, 1.0, -0.3)
	seg.add_child(gun)
	await process_frame

	# ── the grab ─────────────────────────────────────────────────────
	pickups["right"].call("_pick_up_object", gun)
	await process_frame
	await process_frame
	var holster: Node = inv.get_node_or_null("Holster")
	_check(is_instance_valid(gun) and gun.get_parent() == holster, "after the grab the gun's parent is %s" % ((gun.get_parent().name if gun.get_parent() != null else "null") if is_instance_valid(gun) else "FREED"), "not adopted")
	if not is_instance_valid(gun) or gun.get_parent() != holster:
		_finish()
		return
	_check(bool(gun.call("is_picked_up")) and pickups["right"].get("picked_up_object") == gun, "the right hand holds it: %s" % str(bool(gun.call("is_picked_up"))), "the hand let go")
	_check(String(inv.call("get_state", "right")) == "weapons", "right state %s" % String(inv.call("get_state", "right")), "state not weapons")
	_check(not gun.has_meta("em_cartridge_deferred") and not gun.has_meta("em_foe_gun"), "museum metas stripped: %s" % str(not gun.has_meta("em_cartridge_deferred")), "the museum would still free it")

	# ── the hall dies ─────────────────────────────────────────────────
	seg.queue_free()
	await process_frame
	await process_frame
	_check(is_instance_valid(gun) and bool(gun.call("is_picked_up")), "segment freed: gun alive and held: %s" % str(is_instance_valid(gun) and bool(gun.call("is_picked_up"))), "the gun died with its hall")

	# ── the flip: weapons -> bare (no catalyst known yet) ─────────────
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")
	await process_frame
	await process_frame
	_check(String(inv.call("get_state", "right")) == "bare", "click: right state %s" % String(inv.call("get_state", "right")), "did not flip to bare")
	_check(is_instance_valid(gun) and gun.get_parent() == null, "gun stowed out of the tree: %s" % str(is_instance_valid(gun) and gun.get_parent() == null), "gun still in the world")
	_check(pickups["right"].get("picked_up_object") == null, "right hand empty: %s" % str(pickups["right"].get("picked_up_object") == null), "hand still holds")

	# ── bare -> weapons ───────────────────────────────────────────────
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")
	await process_frame
	await process_frame
	_check(String(inv.call("get_state", "right")) == "weapons", "click: right state %s" % String(inv.call("get_state", "right")), "did not draw")
	_check(is_instance_valid(gun) and gun.is_inside_tree() and bool(gun.call("is_picked_up")) and pickups["right"].get("picked_up_object") == gun,
		"gun drawn and held: %s" % str(is_instance_valid(gun) and gun.is_inside_tree() and bool(gun.call("is_picked_up"))), "gun not back in the hand")

	# ── letting go holsters ───────────────────────────────────────────
	pickups["right"].call("drop_object")
	await process_frame
	await process_frame
	_check(String(inv.call("get_state", "right")) == "bare" and gun.get_parent() == null, "let go: state %s, gun %s" % [String(inv.call("get_state", "right")), "holstered" if gun.get_parent() == null else "IN THE AIR"], "a released gun litters")

	# ── the sledgehammer, taken with the LEFT hand from a second hall ──
	var seg2 := Node3D.new()
	seg2.name = "Seg1_test"
	get_root().add_child(seg2)
	var hammer: Node3D = (load(HAMMER) as PackedScene).instantiate() as Node3D
	hammer.set_meta("artifact_lookup_name", "line_sledgehammer")
	hammer.set_meta("em_cabinet_weapon", true)
	hammer.set("freeze", true)
	hammer.position = Vector3(-0.3, 1.0, -0.3)
	seg2.add_child(hammer)
	await process_frame
	pickups["left"].call("_pick_up_object", hammer)
	await process_frame
	await process_frame
	_check(is_instance_valid(hammer) and hammer.get_parent() == holster and bool(hammer.call("is_picked_up")),
		"the hammer is adopted into the left hand: %s" % str(is_instance_valid(hammer) and hammer.get_parent() == holster), "hammer not adopted")
	_check(String(inv.call("get_state", "left")) == "weapons" and (inv.call("get_weapons") as Array).size() == 2,
		"left state %s, %d weapon(s) in the inventory" % [String(inv.call("get_state", "left")), (inv.call("get_weapons") as Array).size()], "two weapons expected")
	seg2.queue_free()
	await process_frame
	# the right hand cycles: bare -> gun -> hammer (taken from the left) -> bare
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")
	await process_frame
	await process_frame
	_check(inv.call("get_weapon", "right") == gun, "right click: holds %s" % ("the gun" if inv.call("get_weapon", "right") == gun else "SOMETHING ELSE"), "slot order wrong")
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")
	await process_frame
	await process_frame
	_check(inv.call("get_weapon", "right") == hammer and String(inv.call("get_state", "left")) == "bare",
		"right click: holds the hammer %s, left went bare %s" % [str(inv.call("get_weapon", "right") == hammer), str(String(inv.call("get_state", "left")) == "bare")], "the hammer did not change hands")
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")
	await process_frame
	await process_frame
	_check(String(inv.call("get_state", "right")) == "bare" and gun.get_parent() == null and hammer.get_parent() == null,
		"right click: bare, both weapons holstered: %s" % str(gun.get_parent() == null and hammer.get_parent() == null), "a weapon left out")

	# ── catalysts ─────────────────────────────────────────────────────
	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	var snap_act: Variant = null
	var snap_trk: Variant = null
	if mgr != null:
		snap_act = mgr.get("_bracelet_activated")
		snap_trk = mgr.get("_bracelet_tracker")
	inv.set("_has_catalyst", true)
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")   # bare -> gun
	await process_frame
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")   # gun -> hammer
	await process_frame
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")   # hammer -> catalysts
	await create_timer(0.6).timeout
	_check(String(inv.call("get_state", "right")) == "catalysts", "click, click: right state %s" % String(inv.call("get_state", "right")), "did not reach catalysts")
	var cat_on: bool = false
	for cat in get_nodes_in_group("catalyst"):
		if cat.get_parent() == ctrls["right"]:
			cat_on = true
	_check(cat_on, "a crystal sits on the right controller: %s" % str(cat_on), "no catalyst on the hand")
	var br: Node = mgr.call("get_bracelet") if mgr != null and mgr.has_method("get_bracelet") else null
	_check(br != null and is_instance_valid(br) and br.get_parent() == ctrls["right"], "the bracelet is on the right controller: %s" % str(br != null and is_instance_valid(br) and br.get_parent() == ctrls["right"]), "no bracelet")
	_check(gun.get_parent() == null, "the gun is holstered while the catalyst is out: %s" % str(gun.get_parent() == null), "gun and catalyst share a hand")
	(ctrls["right"] as XRController3D).button_pressed.emit("primary_click")   # catalysts -> bare
	await create_timer(0.3).timeout
	var br2: Node = mgr.call("get_bracelet") if mgr != null and mgr.has_method("get_bracelet") else null
	var cat_left: bool = false
	for cat in get_nodes_in_group("catalyst"):
		if is_instance_valid(cat) and cat.get_parent() == ctrls["right"]:
			cat_left = true
	_check(String(inv.call("get_state", "right")) == "bare" and (br2 == null or not is_instance_valid(br2)) and not cat_left,
		"click: right state %s, bracelet %s, crystal %s" % [String(inv.call("get_state", "right")), "gone" if (br2 == null or not is_instance_valid(br2)) else "STILL ON", "gone" if not cat_left else "STILL ON"], "the catalyst state did not come off")
	_check(bool(inv.call("has_catalyst")), "the inventory still knows the catalyst: %s" % str(bool(inv.call("has_catalyst"))), "forgot the catalyst")
	# restore the manager's saved flags, so the visitor's own progression is untouched
	if mgr != null:
		mgr.set("_bracelet_activated", snap_act)
		mgr.set("_bracelet_tracker", snap_trk)
		if mgr.has_method("save_state"):
			mgr.call("save_state")

	_finish()


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
