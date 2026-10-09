extends SceneTree
var checks: Array=[]
var failures: Array=[]
var measurements: Dictionary={}
var world: Node3D
func _initialize() -> void:run.call_deferred()
func check(text: String,ok: bool) -> void:
	checks.append(text)
	if not ok:failures.append(text);push_error(text)
func wait(t: float) -> void:await create_timer(t).timeout
func run() -> void:
	await process_frame
	world=Node3D.new();root.add_child(world);current_scene=world
	var origin=XROrigin3D.new();world.add_child(origin)
	var controller=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	var e=load("res://commons/artifacts/force_play/encounter.gd").new();e.kind="swings";world.add_child(e)
	await wait(0.25)
	var body: RigidBody3D=e.bodies[0];var grip=e.grips[0]
	var pivot: Vector3=e.joints[0].global_position
	var local_pivot: Vector3=body.to_local(pivot)
	check("Joint body refuses XR direct pickup",not body.can_pick_up(hand))
	body.pick_up(hand)
	check("Direct XR pickup leaves body dynamic and attached",not body.is_picked_up() and not body.freeze)
	var pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new();world.add_child(pointer)
	pointer.set_process(false);pointer.set_physics_process(false)
	pointer._grab_held(body)
	check("Desktop carry also refuses constrained body",not pointer.is_holding() and not body.freeze)
	controller.global_position=grip.global_position;grip.pick_up(hand)
	check("Actual XRTools pickup holds the separate grip",grip.is_picked_up())
	var start: Vector3=controller.global_position
	var maximum_error:=0.0
	for i in range(90):
		controller.global_position=start+Vector3(1,0.4,-2)*float(i+1)/90
		await physics_frame
		maximum_error=maxf(maximum_error,body.to_global(local_pivot).distance_to(pivot))
	measurements.hinge_error_during_pull=maximum_error
	check("Two-metre hand pull leaves hinge within 8 cm",maximum_error<0.08)
	check("Pulling the grip actually swings the seat",absf(body.rotation.x)>0.1)
	grip.let_go(hand,Vector3.ZERO,Vector3.ZERO);await wait(0.1)
	e.reset();await wait(0.3)
	var stick=e.push_stick.stick
	check("Resting stick is discoverable on the pickup layer",stick.collision_layer==4 and stick.can_pick_up(hand))
	controller.rotation=Vector3(0,PI,0)
	controller.global_position=Vector3(body.global_position.x,1.45,-2.4)
	stick.global_transform=controller.global_transform;stick.pick_up(hand)
	check("Long stick is held through XRTools",stick.is_picked_up())
	check("A held stick cannot be recalled",not e.push_stick.return_stick())
	var max_turn:=0.0
	for i in range(100):
		controller.position.z=-2.4+0.9*float(i+1)/100
		await physics_frame
		max_turn=maxf(max_turn,absf(body.rotation.x))
	measurements.stick_push_angle=max_turn
	check("Held stick contacts and turns the hinged seat",max_turn>0.1)
	check("Stick contact leaves the hinge attached",body.to_global(local_pivot).distance_to(pivot)<0.08)
	stick.let_go(hand,Vector3.ZERO,Vector3.ZERO);await wait(0.2)
	check("Released stick is a dynamic body",not stick.freeze)
	check("Local RETURN STICK restores the tool",e.push_stick.return_stick())
	await wait(0.15)
	check("Returned stick remains on rack",stick.global_position.distance_to(e.push_stick.home.origin)<0.01)
	pointer._grab_held(stick);await physics_frame;await physics_frame
	check("Desktop-held stick retains physical contact",pointer.is_holding() and stick.collision_layer==4 and stick.collision_mask==5)
	pointer._drop_held();await physics_frame
	check("Desktop release restores dynamic stick",not pointer.is_holding() and not stick.freeze)
	var temporary=load("res://commons/hazards/becoming_catalyst/modes/forces_projectile.gd").new()
	var normal_damping: float=body.linear_damp
	temporary._apply_calming(body)
	check("Catalyst can temporarily calm a hinged receiver",body.linear_damp>normal_damping)
	e.reset();await wait(0.1)
	check("Experiment reset clears temporary catalyst damping",is_equal_approx(body.linear_damp,normal_damping) and not body.has_meta("forces_calm_state"))
	temporary.free()
	e.queue_free();await process_frame
	# Test real projectile contact and the reused catalyst effect on a PointBody.
	var point=load("res://commons/artifacts/force_capability_lab/loose_point.gd").new()
	point.position=Vector3(0,4,0);world.add_child(point);point.freeze=false;point.gravity_scale=0
	point.linear_damp=0.12;point.angular_damp=0.23;point.linear_velocity=Vector3(0,0,0.2)
	var shot=load("res://commons/hazards/becoming_catalyst/modes/mode_forces.gd").create_projectile(Vector3.ZERO,Vector3.FORWARD)
	shot.position=Vector3(0,4,1.5);world.add_child(shot)
	await wait(0.35)
	check("Real Forces projectile hits the PointBody layer",point.has_meta("forces_calm_state"))
	check("Catalyst increases damping on the existing sphere",point.linear_damp>3)
	var effect=load("res://commons/hazards/becoming_catalyst/modes/forces_projectile.gd").new()
	effect._apply_calming(point);effect._apply_calming(point)
	check("Repeated shots refresh rather than accumulate damping",is_equal_approx(point.linear_damp,3.12))
	await wait(3.1)
	check("Damping returns to original after repeated shots",is_equal_approx(point.linear_damp,0.12) and is_equal_approx(point.angular_damp,0.23))
	effect.free();point.queue_free();origin.queue_free();pointer.queue_free()
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"physics":"Jolt","scope":"Actual joints, XRTools grabs, desktop carry refusal, held-stick contact and projectile contact; supplied controller motion, no headset claim."}
	FileAccess.open("res://ada_run/forces_hand_tools.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("HAND TOOLS ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
