extends "res://tools/probes/tape_rolls.gd"
var world: Node3D
var camera: Camera3D
var work: Node3D
var hand: Node3D
var roll: Node3D

func target(at: Vector3) -> void:camera.look_at(at);await frames(3)

func box(title: String,at: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new();body.name = title;body.position = at;body.gravity_scale = 0;world.add_child(body)
	var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(.4,.4,.4);body.add_child(shape);return body

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	world = Node3D.new();root.add_child(world);current_scene = world
	work = load("res://commons/artifacts/tape_roll/station.tscn").instantiate();work.position.x = 10;world.add_child(work)
	camera = Camera3D.new();camera.position = Vector3(0,1.5,3);world.add_child(camera);camera.make_current()
	hand = Hand.new();world.add_child(hand);roll = work.rolls[1];roll.freehand_draw=true;roll.pick_up(hand)
	var surface := StaticBody3D.new();surface.position = Vector3(0,1.5,0);world.add_child(surface)
	var shape := CollisionShape3D.new();shape.shape = SphereShape3D.new();shape.shape.radius = .7;surface.add_child(shape);await frames(8)
	await target(Vector3(-.42,1.5,.55));roll.action();await frames(12)
	for i in 31:await target(Vector3(-.42+float(i)*.028,1.5+.11*sin(float(i)/30*PI),.55))
	check("Held action previews a sampled curve before release",roll.drag_points.size()>15 and roll.segments.is_empty() and roll.preview.visible)
	roll.action_release();await frames(5)
	check("Release commits one curved stripe for the whole gesture",roll.segments.size()==1 and roll.segments[0].anchors.size()>15)
	if not roll.segments.is_empty():
		var stripe: Node3D = roll.segments[0];var exact_surface := true
		for record in stripe.anchors:
			var p: Dictionary = stripe.resolve(record)
			exact_surface = exact_surface and absf(p.position.distance_to(surface.global_position)-.7)<.002
		check("Stripe points follow the real sphere collider",exact_surface)
		check("Curve length is paid once, not its endpoint chord",stripe.paid_length>.8 and absf(roll.remaining+stripe.paid_length-30)<.001)
		check("Marking one object creates no physical joint",stripe.get_child_count()==0)
		var before: Vector3 = stripe.resolve(stripe.anchors[0]).position;surface.position.x += .2;await frames(5)
		check("Every curved sample follows a moved object",stripe.resolve(stripe.anchors[0]).position.distance_to(before+Vector3(.2,0,0))<.001)
	work.undo();await frames(4);check("Undo removes a whole stripe and refunds all sampled length",is_equal_approx(roll.remaining,30))
	surface.position.x = 0;await target(Vector3(-.4,1.5,.55));roll.action();await frames(12)
	await target(Vector3(-.3,1.5,.55));await target(Vector3(0,4,0));await target(Vector3(.2,1.5,.55));await target(Vector3(.35,1.5,.55));roll.action_release();await frames(4)
	check("Dragging through air leaves a break instead of a phantom stripe",roll.segments.size()==1 and roll.segments[0].anchors.any(func(a):return a.get("break_before",false)))
	work.tidy();await frames(5);surface.free();await frames(4)
	var a := box("A",Vector3(-.5,1.5,0));var b := box("B",Vector3(.5,1.5,0));await frames(5)
	await target(a.position+Vector3(0,0,.2));await fire(roll);await target(b.position+Vector3(0,0,.2));await fire(roll)
	check("Two-body span creates a native fixed joint",roll.segments.size()==1 and roll.segments[0].get_child_count()==1 and roll.segments[0].get_child(0).joint is Generic6DOFJoint3D)
	var initial: Transform3D = a.global_transform.affine_inverse()*b.global_transform
	a.gravity_scale = 1;b.gravity_scale = 1;a.apply_central_impulse(Vector3(2,1,0));a.apply_torque_impulse(Vector3(0,.5,.2));await frames(100)
	var expected := a.global_transform*initial
	check("Joint carries two free bodies together under gravity and impulse",a.position.y<0 and expected.origin.distance_to(b.global_position)<.025 and expected.basis.get_rotation_quaternion().angle_to(b.global_basis.get_rotation_quaternion())<.08)
	work.undo();await frames(5);a.gravity_scale = 0;b.gravity_scale = 0
	a.linear_velocity = Vector3.ZERO;b.linear_velocity = Vector3.ZERO;a.angular_velocity = Vector3.ZERO;b.angular_velocity = Vector3.ZERO;a.apply_central_impulse(Vector3(2,0,0));var apart := a.position.distance_to(b.position);await frames(35)
	check("Undo removes the constraint so bodies move independently",absf(a.position.distance_to(b.position)-apart)>.15 and not a.has_meta("tape_physics_lease") and not b.has_meta("tape_physics_lease"))
	a.free();b.free();await frames(4)
	# Frozen source utility pieces become real physics while bound, with a
	# reference-counted lease so a second strip is not invalidated by one undo.
	var board := StaticBody3D.new();board.position = Vector3(-.6,1.5,0);world.add_child(board)
	var c := CollisionShape3D.new();c.shape = BoxShape3D.new();c.shape.size = Vector3(.4,.6,.4);board.add_child(c)
	var plank: Node3D = load("res://commons/artifacts/primitive_encounters/timber_plank_1m.tscn").instantiate();plank.position = Vector3(.4,1.5,0);world.add_child(plank);await frames(5)
	for i in 2:
		await target(board.position+Vector3(0,.05*i,.2));await fire(roll);await target(plank.position+Vector3(.2,0,.125));await fire(roll)
	check("Taping a stored plank activates its real gravity body",not plank.freeze and plank.gravity_scale==1 and roll.segments.size()==2)
	var held_at: Vector3 = plank.position;await frames(60)
	check("A wall-bound plank is physically held up",plank.position.distance_to(held_at)<.025)
	work.undo();await frames(5);check("Removing one of two strips keeps the remaining joint alive",plank.has_meta("tape_physics_lease") and plank.get_meta("tape_physics_lease").count==1 and not plank.freeze)
	var remaining_strip: Node3D = roll.segments.filter(func(s):return is_instance_valid(s) and not s.is_queued_for_deletion())[0]
	plank.pick_up(hand);await frames(5);hand.position += Vector3(1,0,0);await frames(12)
	check("A hand pull peels the joint and visibly splits the tape",remaining_strip.peeled and remaining_strip.get_child(0).torn and not plank.has_meta("tape_physics_lease"))
	plank.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames(4)
	work.tidy();await frames(5);check("Tidy removes all joints and restores original utility physics",not plank.has_meta("tape_physics_lease") and plank.freeze and plank.gravity_scale==0 and plank.release_mode==1)
	roll.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Actual held-action surface sampling, sphere collision, native Jolt joint response to gravity/impulse and reversible multi-strip body state. Real player input is separate."}
	FileAccess.open(out.path_join("tape-stripes-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
