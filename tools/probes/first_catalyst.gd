extends "res://tools/probes/transformation_encounters.gd"
## Actual hall, actual pickable point and XRServer poses. No headset claim.
var capability: Node
var grants := 0

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	capability = root.get_node("CatalystCapabilityManager")
	capability.progression_file = spec.run + "test-capabilities.json"
	capability.reset_progression()
	capability.capability_unlocked.connect(func(id):
		if id == "first_catalyst": grants += 1)
	await super.run()

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var target := find_scene("/drag_point_target.gd")
	var station := find_scene("/point_held.gd")
	check("existing target uses the first-catalyst field", target != null and target.encounter == "catalyst")
	check("first grabbable point remains in its existing hall", station != null)
	if target == null or station == null: return
	var field: Node3D = target.get_node("FirstCatalystField")
	var point: Node3D = station.point
	check("red arrow and falling-ball emitter removed from this placement", target.get_node_or_null("Arrow") == null and target.get_node_or_null("Balls") == null)
	check("seed is the coordinate instrument's original point", point.is_in_group("first_catalyst_seed") and point.get_meta("coordinate_id") == "point_one_main")
	check("hollow field has no solid collision", field.field.find_children("*", "CollisionShape3D", true, false).is_empty())
	check("field centre remains at hand height", is_equal_approx(field.field.global_position.y - target.global_position.y, 1.24))
	var ability: Node3D = capability.first_catalyst
	check("no ability at arrival", not capability.has_first_catalyst() and not ability.unlocked and not ability.sphere.visible and not ability.left_glow.visible)
	var decoy := Node3D.new()
	root.add_child(decoy)
	decoy.add_to_group("ada_coordinate_point")
	decoy.set_meta("coordinate_id", "point_one_main")
	decoy.global_position = field.field.global_position
	await create_timer(0.3).timeout
	check("another sphere cannot grant this unlock", not capability.has_first_catalyst() and not field.accepts(decoy))
	decoy.queue_free()
	await snapshot("field-in-the-hall", target.to_global(Vector3(1.9,1.65,2.7)), target.to_global(Vector3(0,1.1,0)), 65)
	var approach := target.to_global(Vector3(0,0,0.95))
	check("solid floor at the podium approach", not floor_at(approach).is_empty())
	var hand := SuppliedGrabber.new()
	root.add_child(hand)
	hand.global_transform = point.global_transform
	point.pick_up(hand)
	check("existing point is picked up through XRTools", point.is_picked_up())
	hand.global_position = field.field.global_position + Vector3(0,0,0.30)
	await create_timer(0.4).timeout
	check("nearby point outside the volume does not unlock", not capability.has_first_catalyst())
	hand.global_position = field.field.global_position
	await create_timer(0.45).timeout
	check("carrying the actual point into the field grants the ability", capability.has_first_catalyst() and field.activated and ability.unlocked)
	check("field grants once", grants == 1)
	check("activated indicator brightens and stays bright", float(field.field.material_override.get_shader_parameter("strength")) > 1.0)
	check("point survives with its coordinate identity and grab", is_instance_valid(point) and point.is_picked_up() and point.get_meta("coordinate_id") == "point_one_main")
	check("first unlock does not grant firing modes or absorb a bracelet", capability.get_unlocked_catalyst_modes().is_empty() and not capability._bracelet_activated)
	await snapshot("point-in-the-field", target.to_global(Vector3(1.0,1.55,1.65)), target.to_global(Vector3(0,1.0,0)), 58)
	hand.global_position += Vector3(0.0,0.0,0.5)
	await create_timer(0.25).timeout
	hand.global_position = field.field.global_position
	await create_timer(0.3).timeout
	check("returning to the field does not grant twice", grants == 1)
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	hand.queue_free()
	check("point remains usable after release", not point.is_picked_up())
	# Controlled hand poses test the full formation boundary independently of tracking.
	ability.set_physics_process(false)
	var middle: Vector3 = target.to_global(Vector3(0,1.23,1.35))
	var left := Transform3D(Basis.IDENTITY, middle + Vector3(-0.1,0,0))
	var right := Transform3D(Basis.IDENTITY, middle + Vector3(0.1,0,0))
	ability.update_hands(left,right,true,true,0.10)
	check("brief contact does not flash the sphere", not ability.formed and ability.left_glow.visible)
	ability.update_hands(left,right,true,true,0.10)
	check("near empty hands form the sphere", ability.formed and ability.sphere.visible)
	var bright: float = ability.left_glow.material_override.get_shader_parameter("strength")
	check("sourcing intensifies both hand glows", bright > 0.9)
	check("sphere appears at the exact midpoint", ability.sphere.global_position.is_equal_approx(middle))
	check("ability has no collider or receiver field", ability.find_children("*","CollisionObject3D",true,false).is_empty())
	await snapshot("form-between-hands", middle + Vector3(0,0.24,0.62), middle, 62)
	right.origin.x += 0.08
	ability.update_hands(left,right,true,true,0.1)
	check("small threshold jitter retains the form", ability.formed)
	right.origin.x += 0.12
	ability.update_hands(left,right,true,true,0.1)
	check("separating hands dismisses form and keeps hand glow", not ability.formed and not ability.sphere.visible and ability.left_glow.visible)
	check("separated hands return to a softer glow", float(ability.left_glow.material_override.get_shader_parameter("strength")) < bright)
	check("separated hands cannot shoot", ability.send_form(Vector3.FORWARD) == null)
	await snapshot("hands-apart", middle + Vector3(0,0.24,0.62), middle, 62)
	right.origin = middle + Vector3(0.1,0,0)
	ability.update_hands(left,right,true,false,0.4)
	check("occupied hands do not call another point", not ability.formed)
	ability.update_hands(left,right,true,true,0.2)
	ability.update_hands(left,right,false,true,0.1)
	check("tracking loss hides sphere and both glows immediately", not ability.formed and not ability.left_glow.visible and not ability.right_glow.visible)
	# Real XRServer adapter, including hand discovery and rig replacement.
	await check_xr_adapter(ability, middle)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(capability.progression_file))
	check("unlock written to isolated save", saved.get("first_catalyst_unlocked",false))
	capability._first_catalyst_unlocked = false
	ability.set_unlocked(false)
	capability._load_saved_progress()
	check("reload restores ability", capability.has_first_catalyst() and ability.unlocked)
	var old := FileAccess.open(capability.progression_file,FileAccess.WRITE)
	old.store_string("{}"); old.close()
	capability._load_saved_progress()
	check("older saves begin without the new ability", not capability.has_first_catalyst() and not ability.unlocked)
	capability.unlock_first_catalyst()
	# Removing the hall's gate must not remove the capacity.
	field.queue_free()
	await process_frame
	check("ability outlives its originating artifact", is_instance_valid(ability) and ability.get_parent()==capability and ability.unlocked)
	capability.reset_progression()
	check("explicit progression reset removes the ability", not capability.has_first_catalyst() and not ability.unlocked and not ability.sphere.visible)
	var legacy: Node3D = load("res://commons/artifacts/drag_point_target/drag_point_target.tscn").instantiate()
	root.add_child(legacy)
	check("other maps keep the legacy arrow unless configured", legacy.get_node_or_null("Arrow") != null)
	legacy.apply_grid_config({"encounter":"catalyst"})
	await process_frame
	check("late configuration also removes arrow and fall emitter", legacy.get_node_or_null("Arrow") == null and legacy.get_node_or_null("Balls") == null and legacy.get_node_or_null("FirstCatalystField") != null)
	legacy.queue_free()

func check_xr_adapter(ability: Node3D, middle: Vector3) -> void:
	var trackers: Array[XRPositionalTracker] = []
	for id in ["left_hand", "right_hand"]:
		var tracker := XRControllerTracker.new()
		tracker.type = XRServer.TRACKER_CONTROLLER
		tracker.name = id
		tracker.set_pose("default", Transform3D(Basis.IDENTITY, middle + Vector3(-0.1 if id == "left_hand" else 0.1,0,0)), Vector3.ZERO, Vector3.ZERO, 2)
		XRServer.add_tracker(tracker)
		trackers.append(tracker)
	# Reproduce XR staging: a visible, tracked menu rig stays earlier in the tree.
	var menu_rig := XROrigin3D.new()
	menu_rig.name = "StillLoadedMenuRig"
	menu_rig.position = Vector3(40, 0, 40)
	for id in ["left_hand", "right_hand"]:
		var controller := XRController3D.new(); controller.tracker = id; menu_rig.add_child(controller)
	root.add_child(menu_rig)
	menu_rig.current = true
	var rig := XROrigin3D.new()
	rig.name = "ControlledXRTestRig"
	for id in ["left_hand", "right_hand"]:
		var controller := XRController3D.new()
		controller.tracker = id
		rig.add_child(controller)
	root.add_child(rig)
	rig.current = true
	for controller in rig.get_children():
		var side := "left" if "left" in str(controller.tracker) else "right"
		var model: Node3D = load("res://addons/godot-xr-tools/hands/scenes/lowpoly/" + side + "_hand_low.tscn").instantiate()
		controller.add_child(model)
	ability._seek_left = 0.0
	ability.set_physics_process(true)
	await create_timer(0.5).timeout
	check("XRServer tracked controllers drive the actual adapter", ability.formed and ability._left != null and ability._right != null)
	check("active gameplay rig wins over a still-visible tracked menu rig", ability._origin == rig and ability.sphere.global_position.distance_to(middle) < 0.001)
	menu_rig.current = true
	await create_timer(0.65).timeout
	check("changing current origin rebinds hands even when the old rig survives", ability._origin == menu_rig and ability.sphere.global_position.distance_to(middle + menu_rig.position) < 0.001)
	rig.current = true
	await create_timer(0.65).timeout
	check("returning to the gameplay origin restores the sphere at the real hands", ability._origin == rig and ability.sphere.global_position.distance_to(middle) < 0.001)
	menu_rig.queue_free()
	ability.clear_shots()
	trackers[1].set_input("trigger_click", true)
	await create_timer(0.1).timeout
	check("real tracked trigger sends the formed ball", ability.projectiles.size() == 1)
	check("trigger cooldown prevents duplicate shots", ability.send_form(Vector3.FORWARD) == null)
	trackers[1].set_input("trigger_click", false)
	ability.clear_shots()
	await snapshot("tracked-hands-together", middle + Vector3(0,0.28,0.62), middle, 62)
	trackers[1].set_pose("default",Transform3D(Basis.IDENTITY,middle+Vector3(0.34,0,0)),Vector3.ZERO,Vector3.ZERO,2)
	await create_timer(0.2).timeout
	check("tracked separation dismisses sphere", not ability.formed)
	await snapshot("tracked-hands-apart", middle + Vector3(0,0.28,0.72), middle+Vector3(0.10,0,0), 66)
	trackers[1].set_pose("default",Transform3D(Basis.IDENTITY,middle+Vector3(0.1,0,0)),Vector3.ZERO,Vector3.ZERO,2)
	await create_timer(0.2).timeout
	# Exercise the real pickup-function property read by the adapter.
	var pickup: Node = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	pickup.enabled = false
	ability._left.add_child(pickup)
	var held := Node3D.new();root.add_child(held)
	pickup.picked_up_object = held
	await create_timer(0.2).timeout
	check("XRTools occupied-hand state suppresses form", not ability.formed)
	pickup.picked_up_object = null
	held.queue_free()
	await create_timer(0.25).timeout
	check("freeing the hand restores the gesture", ability.formed)
	rig.queue_free()
	await create_timer(0.1).timeout
	check("old rig removal hides form without losing capacity", not ability.formed and ability.unlocked)
	var next_rig := XROrigin3D.new()
	for id in ["left_hand", "right_hand"]:
		var controller := XRController3D.new();controller.tracker=id;next_rig.add_child(controller)
	root.add_child(next_rig)
	next_rig.current = true
	await create_timer(0.7).timeout
	check("a replacement rig reacquires the earned ability", ability.formed)
	for tracker in trackers: XRServer.remove_tracker(tracker)
	await create_timer(0.1).timeout
	check("XR tracking removal hides the form", not ability.formed and not ability.left_glow.visible)
	next_rig.queue_free()
	ability.set_physics_process(false)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual museum placement, XRTools pickup, controlled XRServer poses, native render and isolated progression save. Headset comfort and controller alignment remain untested."},"  "))
	quit(0 if failures.is_empty() else 1)
