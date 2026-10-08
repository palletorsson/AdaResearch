extends SceneTree
const OUT := "res://doc/reports/interfaces-2026-09-21/joystick-console/"
var checks: Array = []
var failures: Array = []
var world: Node3D
var camera: Camera3D
var pointer: Node3D
var variant := "after"
var reference: Node3D
class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO)
		held=null
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"passed":ok,"message":message})
	if not ok: failures.append(message)
	print("JOYSTICK ","PASS " if ok else "FAIL ",message)
func settle() -> void:
	for f in 6:
		await process_frame
		await physics_frame
func angles(joint: Node3D) -> Vector2:
	return Vector2(joint.joystick_x_position,joint.joystick_y_position)
func close(a: Vector2,b: Vector2) -> bool: return a.distance_to(b)<.05
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty(): variant=OS.get_cmdline_user_args()[0]
	world=Node3D.new()
	root.add_child(world)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(.09,.11,.14)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color(.9,.93,1)
	environment.environment.ambient_light_energy=.8
	world.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-40,-25,0)
	world.add_child(light)
	var floor_mesh:=MeshInstance3D.new()
	floor_mesh.mesh=PlaneMesh.new()
	floor_mesh.mesh.size=Vector2(12,12)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(.23,.26,.29)
	floor_mesh.material_override=mat
	world.add_child(floor_mesh)
	camera=Camera3D.new()
	world.add_child(camera)
	camera.current=true
	root.msaa_3d=Viewport.MSAA_4X
	pointer=Node3D.new()
	world.add_child(pointer)
	if variant=="before":
		reference=load("res://commons/ui/interface_joystick_reference.gd").new()
		reference.scene_root=OUT+"before/"
		world.add_child(reference)
		for i in 3:
			var control:Node3D=reference.controls[i]
			var joint:Node3D=control.get_node("JoystickOrigin/InteractableJoystick")
			var visible_grip:Node3D=joint.get_node("JoystickBody/HandleMesh")
			var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
			check(visible_grip.global_position.distance_to(handle.global_position)<.001,"variant %d: grip and grab centre coincide" % i)
			check(joint.default_on_release==(i==2),"variant %d: declared release rule matches scene configuration" % i)
		await capture("overview")
		await capture("controls")
		finish(true)
		return
	var demo:Node3D=load("res://commons/interactables/interactable_joystick_demo.tscn").instantiate()
	world.add_child(demo)
	reference=demo.get_node("JoystickReference")
	await settle()
	check(reference.controls.size()==3,"Focused interactable demo builds three actual joystick scenes")
	check(reference.find_children("*","Label3D",true,false).is_empty(),"All reference lettering is on flat surfaces")
	check(reference.station.position.z>reference.receivers[0].global_position.z,"Controls stand in front of the visible consequences")
	for rotation_y in [0,90]:
		demo.rotation_degrees.y=rotation_y
		await settle()
		for index in 3:
			var control:Node3D=reference.controls[index]
			var joint:Node3D=control.get_node("JoystickOrigin/InteractableJoystick")
			var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
			var grip:Node3D=joint.get_node("JoystickBody/HandleMesh")
			var tag: String=["continuous","detented","returning"][index]+" yaw "+str(rotation_y)
			check(control.global_basis.get_scale().is_equal_approx(Vector3.ONE),tag+": physics control keeps metre scale")
			check(grip.global_position.distance_to(handle.global_position)<.001,tag+": grip coincides with grab target")
			for side in ["Left","Right"]:
				check(handle.get_node("GrabPointRedirect"+side).target!=null,tag+": "+side+" grab-pose redirect resolves")
			var bar:Node3D=joint.get_node("JoystickBody/BarMesh")
			var hit_bar:Node3D=joint.get_node("JoystickBody/BarCollision")
			check(bar.global_transform.is_equal_approx(hit_bar.global_transform),tag+": shaft and collision align")
			var grabber:=TestGrabber.new()
			world.add_child(grabber)
			grabber.global_transform=handle.global_transform
			grabber.held=handle
			handle.pick_up(grabber)
			var requested:=Vector2(23,-17)
			grabber.global_position=joint.get_parent().to_global(Basis.from_euler(Vector3(deg_to_rad(requested.y),deg_to_rad(requested.x),0))*Vector3(0,0,.1))
			await settle()
			var expected:=Vector2(25,-15) if index==1 else requested
			check(close(angles(joint),expected),tag+": actual XR grab sets both axes")
			await settle()
			check(close(angles(joint),expected),tag+": a stationary hand does not accumulate rotation")
			check(reference.receivers[index].position.distance_to(Vector3(expected.x/45*.10,-expected.y/45*.10-.011,.016))<.001,tag+": visible point follows the actual angles")
			check(control._reading.label.text.contains("%+.1f°" % expected.x),tag+": printed reading follows the joint")
			grabber.drop_object()
			await settle()
			check(close(angles(joint),Vector2.ZERO if index==2 else expected),tag+": release preserves its declared rule")
			check(not joint.is_processing() and not handle.is_processing(),tag+": grab processing stops after release")
			grabber.queue_free()
			control.set_angles_degrees(Vector2(200,-200))
			check(close(angles(joint),Vector2(45,-45)),tag+": both axes clamp at the original limits")
			control.set_angles_degrees(Vector2.ZERO)
			var hit:=pointer_hit(control)
			check(not hit.is_empty(),tag+": physical face receives the ray")
			if not hit.is_empty():
				XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
				var end:Vector3=hit.position+control.global_basis*Vector3(.06,-.04,0)
				XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
				expected=Vector2(25,20) if index==1 else Vector2(27,18)
				check(close(angles(joint),expected),tag+": pointer uses the tilted control's local axes")
				XRToolsPointerEvent.released(pointer,hit.collider,end)
				check(close(angles(joint),Vector2.ZERO if index==2 else expected),tag+": pointer release matches physical release")
			control.set_angles_degrees(Vector2.ZERO)
	# Cancellation restores a spring control; another pointer cannot steal it.
	var returning:Node3D=reference.controls[2]
	var returning_joint:Node3D=returning.get_node("JoystickOrigin/InteractableJoystick")
	var hit:=pointer_hit(returning)
	var stranger:=Node3D.new()
	world.add_child(stranger)
	XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
	XRToolsPointerEvent.pressed(stranger,hit.collider,hit.position)
	XRToolsPointerEvent.moved(stranger,hit.collider,hit.position+returning.global_basis.x*.08,hit.position)
	check(close(angles(returning_joint),Vector2.ZERO),"Second pointer cannot steal an active control")
	XRToolsPointerEvent.moved(pointer,hit.collider,hit.position+returning.global_basis.x*.08,hit.position)
	check(close(angles(returning_joint),Vector2(36,0)),"Owner pointer remains active")
	XRToolsPointerEvent.exited(pointer,hit.collider,hit.position)
	check(close(angles(returning_joint),Vector2.ZERO) and not returning.is_processing(),"Pointer exit returns to zero and ends processing")
	XRToolsPointerEvent.pressed(stranger,hit.collider,hit.position)
	XRToolsPointerEvent.moved(stranger,hit.collider,hit.position+returning.global_basis.x*.08,hit.position)
	stranger.queue_free()
	await settle()
	check(close(angles(returning_joint),Vector2.ZERO) and not returning.is_processing(),"A removed pointer cannot leave a spring control held")
	demo.rotation_degrees.y=0
	await capture("overview")
	await capture("controls")
	# Same physical action before/after letting go: two positions remain, one returns.
	var held:Array=[]
	for control in reference.controls:
		var joint:Node3D=control.get_node("JoystickOrigin/InteractableJoystick")
		var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
		var grabber:=TestGrabber.new()
		world.add_child(grabber)
		grabber.global_transform=handle.global_transform
		grabber.held=handle
		handle.pick_up(grabber)
		grabber.global_position=joint.get_parent().to_global(Basis.from_euler(Vector3(deg_to_rad(-17),deg_to_rad(23),0))*Vector3(0,0,.1))
		held.append(grabber)
	await settle()
	await capture("held")
	for grabber in held: grabber.drop_object(); grabber.queue_free()
	await settle()
	await capture("released")
	finish(false)

func pointer_hit(control:Node3D)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(control.to_global(Vector3(.075,.02,.3)),control.to_global(Vector3(.075,.02,-.04)),(1<<20)|(1<<22))
	return world.get_world_3d().direct_space_state.intersect_ray(query)

func capture(tag:String)->void:
	if tag=="controls":
		camera.position=Vector3(.14,1.55,1.26)
		camera.fov=65
		camera.look_at(reference.station.global_position)
	else:
		camera.position=Vector3(.9,1.8,2.9)
		camera.fov=58
		camera.look_at(Vector3(0,1.15,.18))
	await settle()
	camera.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+tag+".png")

func finish(baseline:bool)->void:
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"baseline":baseline,"headset_tested":false},"\t"))
	print("JOYSTICK_RESULT ",checks.size()," checks, ",failures.size()," failures")
	quit(0 if baseline or failures.is_empty() else 1)
