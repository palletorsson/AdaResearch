extends "res://tools/probes/movable_pivot_probe.gd"
## Additional focused concern: Void's own mouse hand, plus clearer floor-slice
## photographs. Earlier successful physics/XR/export checks are not repeated.
class ReviewWorld extends Node3D:
	var ready_for_play := true
	var recovering := false
	var returning := false
	var throwable_tools := false

func aim(visitor: Node3D, at: Vector3) -> void:
	visitor.camera.look_at(at)

func mouse(down: bool) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
	event.position=root.get_visible_rect().size*.5;event.global_position=event.position
	Input.parse_input_event(event)

func drag_grip(visitor: Node3D, grip: Node3D, offset: Vector3) -> bool:
	var from: Vector3=grip.global_position
	for i in 8:aim(visitor,from);await ticks(1)
	visitor.desktop_pointer._raycast.force_raycast_update();visitor.desktop_pointer._process(0)
	var seen: bool=visitor.desktop_pointer._last_target==grip
	mouse(true);await ticks(2)
	for i in range(1,41):aim(visitor,from+offset*float(i)/40.0);await ticks(1)
	mouse(false);await ticks(60)
	return seen

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures)
	host=ReviewWorld.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a8a7b4")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d5cddd");env.ambient_light_energy=.35
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-15,0);sun.light_energy=.85;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://tools/probes/pivot_floor_slice.gd").new();host.add_child(building)
	artifact=building.content.exhibits["15/movable-pivot"].get_node("Artifact");mechanism=artifact.mechanism
	var visitor: Node3D=load("res://commons/void/walker.gd").new();host.add_child(visitor);visitor.scripted_input=true
	visitor.global_position=artifact.to_global(Vector3(0,.06,2.4));await ticks(15)
	var seen:=await drag_grip(visitor,mechanism.pivot_grip,artifact.global_basis.x*.9)
	check("Void desktop hand targets, drags and releases the actual pivot",seen and mechanism.pivot_x>.6 and mechanism.pivot_grip.pointer_owner==null)
	visitor.global_position=artifact.to_global(Vector3(2.5,.06,2.4));await ticks(10)
	seen=await drag_grip(visitor,mechanism.turn_grip,artifact.global_basis.z*.6)
	check("Void desktop hand turns the walkway through actual mouse input",seen and mechanism.angle_degrees < -8 and mechanism.turn_grip.pointer_owner==null)
	# Ground-level entry is part of the artifact, not a teleport onto the deck.
	mechanism.configure(0,0);visitor.global_position=artifact.to_global(Vector3(-6.7,.06,0));visitor.velocity=Vector3.ZERO;visitor.rotation.y=-PI/2
	visitor.drive=Vector2(0,-1)
	for i in 85:await ticks(1)
	visitor.drive=Vector2.ZERO;await ticks(12)
	print("PIVOT_RAMP_VISITOR ",artifact.to_local(visitor.global_position))
	check("Void visitor walks from the slab up the wooden ramp",visitor.is_on_floor() and artifact.to_local(visitor.global_position).y>.65)
	visitor.queue_free();await ticks(5)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.fov=54;host.add_child(camera)
	mechanism.configure(0,18)
	await shot("05-central-pivot",Vector3(5.7,5.2,-5.7),Vector3(-.45,.4,0))
	mechanism.configure(1.5,18)
	await shot("06-offset-pivot",Vector3(5.7,5.2,-5.7),Vector3(-.45,.4,0))
	await shot("07-pink-bearing",Vector3(2.8,2.1,3.4),Vector3(1.2,.60,.3))
	mechanism.configure(0,0)
	await shot("08-player-approach",Vector3(-1,1.6,2.9),Vector3(0,.65,0))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("final-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Void walker and desktop hand on actual saved floor 15 slice; native Godot photos with review lighting. No whole tower or headset claim."},"  "))
	host.queue_free();await ticks(5);quit(0 if failed.is_empty() else 1)
