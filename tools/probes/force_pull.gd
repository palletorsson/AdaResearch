extends SceneTree
## Native Void hand adapters with mouse events and a synthetic XR controller.
class World extends Node3D:
	var ready_for_play := true
	var recovering := false
	var returning := false
	var throwable_tools := false
var checks: Array = []
var failed: Array = []
var out := ""
var world: Node3D
func _initialize() -> void:run.call_deferred()
func frames(n := 1) -> void:
	for i in n:await physics_frame;await process_frame
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok});print("PULL_CHECK ",label," ",ok)
	if not ok:failed.append(label)
func mouse() -> void:
	for down in [true,false]:
		var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_RIGHT;e.pressed=down;Input.parse_input_event(e)
		await frames(1)
func panel(at:Vector3) -> Node3D:
	# Resolve XRTools after autoload startup, not while this SceneTree parses.
	var body:Node3D=load("res://commons/artifacts/primitive_encounters/piece.gd").new()
	body.set_meta("desktop_preserve_orientation",true)
	var mesh:=MeshInstance3D.new();mesh.mesh=BoxMesh.new();mesh.mesh.size=Vector3(.32,.32,.018);body.add_child(mesh)
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=mesh.mesh.size;body.add_child(shape)
	world.add_child(body);body.global_position=at;return body
func wall(at:Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();body.collision_layer=1
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(.8,.8,.10);body.add_child(shape)
	world.add_child(body);body.global_position=at;return body
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	world=World.new();root.add_child(world);current_scene=world
	var camera:=Camera3D.new();camera.name="Camera3D";world.add_child(camera);camera.position=Vector3(0,1.6,0);camera.make_current()
	var pointer:Node3D=load("res://commons/void/desktop_hand.gd").new();pointer.cam=camera;pointer.world=world;world.add_child(pointer)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var piece:=panel(Vector3(0,1.6,-1.8));await frames(10)
	check("Desktop: visible target at 1.8m is selected",pointer._find_grabbable()==piece)
	await mouse();await frames(2)
	check("Desktop: actual RMB begins a visible pull, not teleport",piece.is_picked_up() and piece.position.z < -1.25 and piece.position.z > -1.8)
	check("Desktop: moving force sparks appear only during pull",pointer.grip.has_node("ForcePull"))
	await frames(45)
	check("Desktop: object arrives at comfortable 1m hold",piece.is_picked_up() and absf(piece.position.z+1)<.02 and not pointer.grip.has_node("ForcePull"))
	var basis:Basis=piece.global_basis
	for key in [KEY_E,KEY_R]:
		var event:=InputEventKey.new();event.physical_keycode=key;event.pressed=true;Input.parse_input_event(event);await frames(5)
	check("Desktop: face roll and tilt survive the shared grab driver",not piece.global_basis.is_equal_approx(basis))
	await mouse();await frames(3)
	check("Desktop: second RMB releases frozen construction piece",not piece.is_picked_up() and piece.freeze)
	piece.global_transform=Transform3D(Basis.IDENTITY,Vector3(0,1.6,-2.3));await frames(4)
	await mouse();check("Desktop: cannot pull beyond 2m",not piece.is_picked_up())
	piece.position=Vector3(0,1.6,-1.8);var block:=wall(Vector3(0,1.6,-1.3));await frames(4)
	await mouse();check("Desktop: solid wall blocks selection and pickup",pointer._find_grabbable()==null and not piece.is_picked_up())
	block.free();await frames(4);await mouse();await mouse();await frames(4)
	check("Desktop: cancel during travel releases and clears effect",not piece.is_picked_up() and not pointer.grip.has_node("ForcePull"))
	piece.free();pointer.set_enabled(false)
	var tracker:=XRControllerTracker.new();tracker.type=XRServer.TRACKER_CONTROLLER;tracker.name="right_hand"
	tracker.set_pose("aim",Transform3D(Basis.IDENTITY,Vector3(0,1.4,0)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	tracker.set_input("grip",0.0);tracker.set_input("trigger_click",false);XRServer.add_tracker(tracker)
	var origin:=XROrigin3D.new();world.add_child(origin);origin.position.x=4
	var controller:=XRController3D.new();controller.tracker=&"right_hand";controller.pose=&"aim";origin.add_child(controller)
	var pickup:Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate()
	pickup.set_script(load("res://commons/void/force_pickup.gd"));pickup.ranged_distance=2;controller.add_child(pickup);await frames(8)
	var home:Vector3=pickup.global_position
	piece=panel(home+Vector3(0,0,-1.8));await frames(12)
	check("XR: real ranged area selects visible face",pickup.closest_object==piece)
	tracker.set_input("grip",1.0);await frames(4)
	check("XR: grip pulls gradually through native XRTools driver",piece.is_picked_up() and piece.global_position.distance_to(home)>.4 and piece.global_position.distance_to(home)<1.8)
	check("XR: native pull has visible force cue",pickup.has_node("ForcePull"))
	await frames(60)
	check("XR: reaches the hand without moving the player",piece.global_position.distance_to(home)<.025 and origin.position==Vector3(4,0,0))
	tracker.set_input("grip",0.0);await frames(5)
	check("XR: release drops piece and clears effect",not piece.is_picked_up() and not pickup.has_node("ForcePull"))
	piece.global_position=home+Vector3(0,0,-2.3);await frames(10);tracker.set_input("grip",1.0);await frames(4)
	check("XR: cannot pull beyond 2m",not piece.is_picked_up())
	tracker.set_input("grip",0.0);await frames(4)
	piece.global_position=home+Vector3(0,0,-1.8);block=wall(home+Vector3(0,0,-1.3));await frames(10)
	tracker.set_input("grip",1.0);await frames(4)
	check("XR: wall blocks remote targeting",not piece.is_picked_up() and pickup.closest_object==null)
	tracker.set_input("grip",0.0);block.free();await frames(10)
	tracker.set_input("grip",1.0);await frames(3);tracker.set_input("grip",0.0);await frames(5)
	check("XR: early release cancels attraction",not piece.is_picked_up() and not pickup.has_node("ForcePull"))
	piece.free();origin.free();XRServer.remove_tracker(tracker)
	var report:Dictionary={"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Production Void desktop and XR hand adapters in a minimal collision fixture. Actual mouse events, synthetic tracker grip. No physical-headset acceptance."}
	FileAccess.open(out.path_join("pull-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FORCE_PULL_RESULT ",failed.size());quit(0 if failed.is_empty() else 1)
