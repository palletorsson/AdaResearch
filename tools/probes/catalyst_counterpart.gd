extends "res://tools/probes/transformation_encounters.gd"
## Real museum, real catalyst projectile and controlled target poses.
var trial: Node3D

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	trial = load("res://commons/hazards/catalyst_counterpart/counterpart_trial.gd").mount(museum, hall)
	check("trial mounts in the actual Trans_Pre hall", trial != null)
	if trial == null: return
	await tick()
	var skull: CharacterBody3D = trial.skull
	var point: RigidBody3D = trial.catalyst
	observations["trial_world"] = xyz(trial.global_position)
	check("existing cube encounters remain in the hall", find_scene("/pick_up_cube.gd") != null)
	check("counterpart receives existing catalyst collision layer", skull.collision_layer == 2)
	check("resting on arrival", not skull.active and skull.state == skull.State.WATCH)
	check("original resolution PointBody reused", str(point.get_script().resource_path).ends_with("/resolution_catalyst.gd"))
	check("floor supports control approach", not floor_at(trial.to_global(Vector3(0, 0, 0.75))).is_empty())
	var target := Node3D.new(); trial.add_child(target)
	target.position = Vector3(0, 1.65, -0.5)
	skull.target_override = target
	await snapshot("counterpart-in-the-museum", trial.to_global(Vector3(0.7, 1.7, 2.8)), trial.to_global(Vector3(0, 1.3, -2)), 65)
	# Freeze only advancement; inputs still enter the real control and receiver paths.
	skull.set_physics_process(false)
	skull.position = Vector3(0, 1.65, -3.5)
	skull.advance(0, target.global_position)
	await snapshot("skull-close", trial.to_global(Vector3(0.8, 1.85, -1.65)), skull.global_position, 46)
	trial.buttons[0].pressed.emit()
	check("MOVE control selects translation", skull.power == 1)
	trial.buttons[3].pressed.emit()
	check("START makes trial active", skull.active)
	skull.advance(2.05, target.global_position)
	check("dash starts with a visible warning", skull.state == skull.State.TELEGRAPH and skull.cue.visible)
	var locked: Vector3 = skull.destination
	target.position.x = 1.1
	skull.advance(0.1, target.global_position)
	check("warning locks the line; it cannot follow a dodge", skull.destination.is_equal_approx(locked))
	await snapshot("line-locked", trial.to_global(Vector3(1.5, 1.8, 0.7)), skull.global_position.lerp(trial.to_global(locked), 0.5), 62)
	skull.advance(1.2, target.global_position)
	check("warning precedes the dash", skull.state == skull.State.DASH and not skull.cue.visible)
	var before := skull.global_position
	skull.advance(0.1, target.global_position)
	check("whole flying collision body translates", skull.global_position.distance_to(before) > 0.1)
	for i in range(20): skull.advance(0.1, target.global_position)
	check("sidestepping the locked line avoids a tag", skull.tags == 0)
	# A physical projectile, fired by the inherited XRTools point, must interrupt.
	skull.set_active(false)
	skull.position = Vector3(0, 1.65, -3.5)
	var hand := SuppliedGrabber.new(); trial.add_child(hand)
	hand.position = Vector3(0, 1.65, -1.5)
	point.global_transform = hand.global_transform
	point.pick_up(hand)
	check("point uses XRTools pickup", point.is_picked_up())
	await create_timer(0.2).timeout
	var prior_rings: int = point.sphere.rings
	point.advance(0.3)
	check("held point keeps the earlier resolution behaviour", point.sphere.rings < prior_rings)
	var old_hits: int = skull.interruptions
	point.action_pressed.emit(point)
	check("trigger emits an actual form", point.projectiles.size() == 1)
	await create_timer(0.65).timeout
	check("flying form collides and interrupts through the receiver protocol", skull.interruptions == old_hits + 1 and skull.state == skull.State.INTERRUPTED)
	check("interruption preserves the counterpart", is_instance_valid(skull) and skull.is_inside_tree())
	await snapshot("interruption", trial.to_global(Vector3(-1.0, 1.75, -0.8)), skull.global_position, 48)
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO); hand.queue_free()
	trial.buttons[1].pressed.emit()
	check("TURN control grants orbit", skull.power == 2)
	skull.set_active(false); skull.position = Vector3(0, 1.65, -3.5)
	before = skull.position
	for i in range(25): skull.advance(0.1, target.global_position)
	check("orbit moves the collision body sideways", absf(skull.position.x - before.x) > 0.25)
	trial.buttons[2].pressed.emit()
	skull.advance(0.2, target.global_position)
	check("SCALE changes shape and collision together", skull.power == 3 and skull.size_factor > 1 and is_equal_approx(skull.boundary.radius, skull.RADIUS * skull.visual.scale.x))
	skull.position = Vector3(20, 20, 20); skull.advance(0.1, target.global_position)
	check("counterpart cannot chase beyond the trial bounds", skull.position.x <= 2.0001 and skull.position.y <= 2.4001 and skull.position.z <= 0.7001)
	skull.set_active(false)
	for i in range(80): skull.advance(0.1, skull.global_position)
	check("REST stays harmless even next to the visitor", skull.tags == 0 and skull.state == skull.State.WATCH)
	# Contact also has a bounded outcome; no player health or save mutation.
	skull.position = Vector3(0, 1.65, -1.0)
	target.position = Vector3(0, 1.65, -0.8)
	skull.set_active(true); skull.begin_telegraph(target.position)
	skull.advance(1.21, target.global_position); skull.advance(0.05, target.global_position)
	check("contact records one training tag", skull.tags == 1 and skull.state == skull.State.RECOVER)
	skull.advance(0.1, target.global_position)
	check("a contact does not count every frame", skull.tags == 1)
	skull.set_active(false)
	target.queue_free()
	observations["scope"] = "Opt-in Trans_Pre prototype. Supplied XRTools grab and trigger, native collisions; no headset or play-quality claim. Trace charging and spine placements remain proposals."
