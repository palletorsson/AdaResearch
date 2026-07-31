extends SceneTree

## Verifies the timed catalyst lease.
##
## 1. Manager clock: begin_lease -> running; _tick_lease past zero ->
##    lease ends, bracelet state deactivated (so map transitions stop
##    respawning the crystal), progression retained.
## 2. Config plumbing: pedestal takes lease_s, forwards it to the crystal,
##    and remembers the crystal config for the respawn.
##
## Part 1 (manager clock) runs synchronously; part 2 (pedestal plumbing)
## awaits two frames because the pedestal's _ready and the crystal config
## land on the first frames after add_child. quit() still forces exit.
## Bracelet activation state is snapshotted and restored so the smoke
## doesn't mutate the player save.

const PEDESTAL_SCENE := preload("res://commons/hazards/becoming_catalyst/catalyst_pedestal.tscn")
const VENT_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_vent.tscn")
const BOX_SCENE := preload("res://commons/hazards/becoming_catalyst/catalyst_prompter_box.tscn")

var _fails: int = 0

func _check(label: String, ok: bool) -> void:
	print("  %s [%s]" % [label, "PASS" if ok else "FAIL"])
	if not ok:
		_fails += 1

func _initialize() -> void:
	print("=== catalyst timed lease ===")

	var mgr: Node = get_root().get_node_or_null("CatalystCapabilityManager")
	if mgr == null:
		mgr = get_root().get_node_or_null("CatalystCapability")
	if mgr == null:
		print("FAIL: CatalystCapabilityManager autoload not found")
		quit(1)
		return

	# Snapshot save-relevant state so the smoke leaves no trace.
	var was_activated: bool = mgr.get("_bracelet_activated")
	var was_tracker: String = mgr.get("_bracelet_tracker")

	# 1 — manager clock
	mgr.call("begin_lease", 5.0)
	_check("begin_lease(5) -> running", bool(mgr.call("is_lease_running")))
	_check("remaining > 0", float(mgr.call("get_lease_remaining")) > 4.0)
	var modes_before: int = (mgr.get("_catalyst_modes") as Array).size()
	mgr.call("_tick_lease", 6.0)  # simulate 6 seconds passing
	_check("tick past zero -> lease ended", not bool(mgr.call("is_lease_running")))
	_check("bracelet deactivated on lease end", not bool(mgr.call("is_bracelet_activated")))
	var modes_after: int = (mgr.get("_catalyst_modes") as Array).size()
	_check("progression retained (modes untouched)", modes_after == modes_before)

	# begin_lease(0) must be a no-op
	mgr.call("begin_lease", 0.0)
	_check("begin_lease(0) is a no-op", not bool(mgr.call("is_lease_running")))

	# Restore player save state.
	mgr.set("_bracelet_activated", was_activated)
	mgr.set("_bracelet_tracker", was_tracker)
	mgr.call("save_state")

	# 2 — pedestal config plumbing (needs frames: _ready spawns the crystal
	# on the first frame after add_child in SceneTree-script context)
	var ped: Node = PEDESTAL_SCENE.instantiate()
	get_root().add_child(ped)
	await process_frame
	ped.call("apply_grid_config", {"lease_s": "20", "sequence": "primitives"})
	await process_frame
	_check("pedestal keeps lease_s", float(ped.get("_lease_s")) == 20.0)
	var remembered: Dictionary = ped.get("_last_crystal_cfg")
	_check("pedestal remembers crystal cfg for respawn",
		remembered.has("lease_s") and remembered.has("sequence"))
	var crystal: Node = ped.get("_crystal")
	if crystal == null:
		_check("crystal spawned on pedestal", false)
	else:
		_check("crystal received lease_s", float(crystal.get("lease_s")) == 20.0)
		_check("crystal received sequence binding",
			String(crystal.call("get_home_sequence")) == "primitives")

	# 3 — vent wind-down: the counterpart goes quiet when the lease returns
	# the catalyst, resumes on re-lease, and vents that never saw a lease
	# are untouched by lease_ended (the negative case).
	var was_activated_3: bool = mgr.get("_bracelet_activated")
	var vent: Node = VENT_SCENE.instantiate()
	get_root().add_child(vent)
	await process_frame
	mgr.call("begin_lease", 5.0)
	_check("vent sees the lease start", bool(vent.get("_lease_seen")))
	mgr.call("_tick_lease", 6.0)  # expire -> end_lease_now -> lease_ended
	_check("lease end pauses the vent", bool(vent.get("_lease_paused")))
	mgr.call("begin_lease", 5.0)
	_check("re-lease resumes the vent", not bool(vent.get("_lease_paused")))
	mgr.call("_tick_lease", 6.0)
	# negative: a vent born after the lease ended must ignore lease_ended
	var vent2: Node = VENT_SCENE.instantiate()
	get_root().add_child(vent2)
	await process_frame
	mgr.call("end_lease_now")  # emits lease_ended with no lease running
	_check("lease-naive vent ignores lease_ended", not bool(vent2.get("_lease_paused")))
	vent.queue_free()
	vent2.queue_free()
	mgr.set("_bracelet_activated", was_activated_3)
	mgr.set("_bracelet_tracker", was_tracker)
	mgr.call("save_state")

	# 4 — prompter box (floor-hatch pedestal subclass): shape config
	# rebuilds the body, and the pedestal lease plumbing is inherited.
	var box: Node = BOX_SCENE.instantiate()
	get_root().add_child(box)
	await process_frame
	box.call("apply_grid_config", {"shape": "plinth", "lease_s": "20", "sequence": "primitives"})
	await process_frame
	_check("prompter box takes plinth shape", String(box.get("shape")) == "plinth")
	_check("prompter box keeps lease_s", float(box.get("_lease_s")) == 20.0)
	_check("prompter box built a lid hinge", box.get("_hinge") != null)
	var box_crystal: Node = box.get("_crystal")
	if box_crystal == null:
		_check("prompter box spawned a crystal", false)
	else:
		_check("prompter box crystal received lease_s", float(box_crystal.get("lease_s")) == 20.0)
		# no camera in headless -> the proximity fallback shows the offer
		_check("prompter box opens without a camera", bool(box.get("_lid_open")))
	box.queue_free()

	if _fails == 0:
		print("PASS: catalyst timed lease")
		quit(0)
	else:
		print("FAIL: %d checks failed" % _fails)
		quit(1)
