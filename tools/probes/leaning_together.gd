extends "res://tools/probes/sine_yoke.gd"
class FixtureHand extends Node3D:
	var picked_up_ranged := false

func fixture(config := {}) -> Node3D:
	var work: Node3D = load("res://commons/artifacts/matter_experiments/leaning_together.tscn").instantiate();work.apply_grid_config(config);work.position = Vector3(0,-18,0);work.rotation.y = .37;scene.add_child(work);return work

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var floor_body := StaticBody3D.new();floor_body.position.y = -18.1;scene.add_child(floor_body);var floor_shape := CollisionShape3D.new();floor_shape.shape = BoxShape3D.new();floor_shape.shape.size = Vector3(20,.2,20);floor_body.add_child(floor_shape)
	var work := fixture();await tick(240);var states: Dictionary = {"settled":work.observations()};print("LEANING_SETTLED ",states.settled)
	check("six loose bodies use real unconstrained 3D contact",work.bodies.size()==6 and work.find_children("*","Joint3D",true,false).is_empty() and work.bodies.values().all(func(body):return not body.freeze and body.enabled and body.continuous_cd))
	check("authored planks maintain a shared leaning posture",states.settled.angles.LeftPlank>35 and states.settled.angles.RightPlank>35 and states.settled.contacts.has("LeftPlank + RightPlank"))
	check("both movable wedges actually contact and hold the plank feet",states.settled.contacts.has("LeftPlank + LeftWedge") and states.settled.contacts.has("RightPlank + RightWedge"))
	var hand := FixtureHand.new();scene.add_child(hand);hand.global_transform = work.bodies.LeftPlank.global_transform;work.bodies.LeftPlank.pick_up(hand);await tick(120);states.held = work.observations();print("LEANING_HELD ",states.held)
	check("a held plank remains a physical support for its loose neighbour",work.bodies.LeftPlank.is_picked_up() and states.held.contacts.has("LeftPlank + RightPlank") and states.held.angles.RightPlank>35)
	var before: Vector3 = work.bodies.RightPlank.global_position
	hand.position += work.global_basis.x*-1.0+Vector3.UP*.3;await tick(180);states.withdrawn = work.observations();print("LEANING_WITHDRAWN ",states.withdrawn)
	check("withdrawing the held support changes the other body's posture",work.bodies.RightPlank.global_position.distance_to(before)>.1 and states.withdrawn.angles.RightPlank<25)
	work.reset_take();await tick(2);check("reset releases the actual grip and returns live authored parts",not work.bodies.LeftPlank.is_picked_up() and work.bodies.values().all(func(body):return not body.freeze) and work.bodies.Cube.position.distance_to(work.homes.Cube.origin)<.01)
	await tick(240);hand.global_transform = work.bodies.LeftWedge.global_transform;work.bodies.LeftWedge.pick_up(hand);hand.position += work.global_basis.x*-1.0+Vector3.UP*.3;await tick(240);states.unchocked = work.observations();print("LEANING_UNCHOCKED ",states.unchocked)
	check("removing a foot wedge changes the leaning arrangement",states.unchocked.angles.LeftPlank<30 or states.unchocked.angles.RightPlank<30)
	work.reset_take()
	work.queue_free();hand.queue_free();await tick(8)
	var edited := fixture({"parts":{"Ball":{"position":[.2,.9,.35]},"Controls":{"position":[.1,.64,.8],"rotation":[0,5,0]}}});await tick(20);edited.reset_take();check("edited starting poses are retained by reset",edited.bodies.Ball.position.distance_to(Vector3(.2,.9,.35))<.001 and absf(edited.get_node("Controls").rotation_degrees.y-5)<.001)
	edited.queue_free();await tick(8)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"states":states,"scope":"Six unconstrained Jolt bodies at a rotated negative-floor placement. Actual native pickup keeps contact support, withdrawal changes the neighbouring plank, reset releases the holder and respects editor starting poses. No physical-headset acceptance."}
	FileAccess.open(out.path_join("leaning-physics-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
