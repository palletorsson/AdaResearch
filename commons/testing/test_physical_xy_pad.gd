extends SceneTree
const OUT := "res://doc/reports/interfaces-2026-09-21/xy-pad/"
var checks: Array = []
var failures: Array = []
var world: Node3D
var camera: Camera3D
var pointer: Node3D
var variant := "after"
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
	print("PAD ","PASS " if ok else "FAIL ",message)
func settle() -> void:
	for f in 6:
		await process_frame
		await physics_frame
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty(): variant=OS.get_cmdline_user_args()[0]
	world=Node3D.new()
	root.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(.09,.11,.14)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color(.9,.93,1)
	env.environment.ambient_light_energy=.8
	world.add_child(env)
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
	var pad:Node3D=load("res://commons/interactables/slider_plane.tscn").instantiate()
	pad.position=Vector3(0,1,0)
	pad.rotation_degrees.x=-50
	world.add_child(pad)
	await settle()
	var joint:Node3D=pad.get_node("SliderOrigin/InteractableSlider")
	var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
	var grip:Node3D=joint.get_node("SliderBody/HandleMesh")
	check(handle.global_position.distance_to(grip.global_position)<.001,"Visible grip and grab target coincide")
	var before:Vector3=pad.to_local(grip.global_position)
	joint.move_slider(Vector2(.035,-.025))
	var displacement:Vector3=pad.to_local(grip.global_position)-before
	check(displacement.distance_to(Vector3(.035,-.025,0))<.001,"Both values move across the face, never into it")
	check(pad.find_children("*","Label3D",true,false).is_empty(),"Pad text is mounted flat on its face")
	if variant!="before": await exercise_pad(pad)
	await capture("pad",Vector3(.25,1.48,.66),Vector3(0,1,0),48)
	pad.queue_free()
	await settle()
	load("res://commons/artifacts/_toy_console/toy_console.gd")
	var toy:Node3D
	if variant=="before":
		toy=load("res://commons/artifacts/vector_op_console/vector_op_console.tscn").instantiate()
		world.add_child(toy)
	else:
		var demo:Node3D=load("res://commons/interactables/interactable_xy_demo.tscn").instantiate()
		world.add_child(demo)
		toy=demo.get_node("XYReference")
	await settle()
	if variant!="before": await exercise_console(toy)
	await capture("console",Vector3(1.45,1.95,2.7),Vector3(0,1.04,0),52)
	await capture("operating",Vector3(.15,1.6,1.20),Vector3(.12,1.10,0),70)
	if variant!="before": await regress_toys()
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"baseline":variant=="before","headset_tested":false},"\t"))
	quit(0 if variant=="before" or failures.is_empty() else 1)
func capture(tag:String,at:Vector3,target:Vector3,fov:float)->void:
	camera.position=at
	camera.fov=fov
	camera.look_at(target)
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+tag+".png")

func near(a:Vector2,b:Vector2)->bool: return a.distance_to(b)<.001
func hit_face(pad:Node3D)->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(pad.to_global(Vector3(.085,.02,.25)),pad.to_global(Vector3(.085,.02,-.04)),(1<<20)|(1<<22))
	return world.get_world_3d().direct_space_state.intersect_ray(query)
func exercise_pad(pad:Node3D)->void:
	var joint:Node3D=pad.get_node("SliderOrigin/InteractableSlider")
	var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
	for yaw in [0,90]:
		pad.rotation_degrees.y=yaw
		pad.set_normalized_position(Vector2.ZERO)
		await settle()
		var tag:="tilted pad yaw %d: " % yaw
		var grabber:=TestGrabber.new()
		world.add_child(grabber)
		grabber.global_transform=handle.global_transform
		grabber.held=handle
		handle.pick_up(grabber)
		grabber.global_position+=pad.global_basis*Vector3(.04,-.03,.02)
		await settle()
		check(near(joint.slider_position,Vector2(.04,-.03)),tag+"actual grab updates both axes, ignores depth")
		await settle()
		check(near(joint.slider_position,Vector2(.04,-.03)),tag+"stationary hand does not accumulate movement")
		grabber.drop_object()
		await settle()
		check(near(joint.slider_position,Vector2(.04,-.03)),tag+"release retains the position")
		check(not joint.is_processing() and not handle.is_processing(),tag+"grab processing stops after release")
		var grip:Node3D=joint.get_node("SliderBody/HandleMesh")
		check(grip.global_position.distance_to(handle.global_position)<.001,tag+"grab target rejoins visible grip on release")
		grabber.queue_free()
		pad.set_normalized_position(Vector2.ZERO)
		var hit:=hit_face(pad)
		check(not hit.is_empty(),tag+"physical plate receives a ray")
		if hit.is_empty(): continue
		XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
		var end:Vector3=hit.position+pad.global_basis*Vector3(-.05,.04,0)
		XRToolsPointerEvent.moved(pointer,hit.collider,end,hit.position)
		check(near(joint.slider_position,Vector2(-.05,.04)),tag+"pointer agrees with hand axes")
		XRToolsPointerEvent.released(pointer,hit.collider,end)
		check(near(joint.slider_position,Vector2(-.05,.04)) and not pad.is_processing(),tag+"pointer release retains position and stops processing")
		pad.set_normalized_position(Vector2(3,-3))
		check(near(joint.slider_position,Vector2(.07,-.07)),tag+"both values stop at plate limits")
		var gp:=pad.to_local(grip.global_position)
		check(absf(gp.x)+.02<=.095 and absf(gp.y)+.02<=.095 and absf(gp.z-.029)<.001,tag+"full knob remains over the working surface")
	pad.rotation_degrees.y=0
	joint.step_y=.02
	joint.step_z=.02
	joint.move_slider(Vector2(.029,-.051))
	check(near(joint.slider_position,Vector2(.02,-.06)),"Per-axis detents remain available in metres")
	joint.step_y=0
	joint.step_z=0
	joint.default_on_release=true
	joint.default_position=Vector2.ZERO
	pad.set_normalized_position(Vector2.ZERO)
	await settle()
	var hit:=hit_face(pad)
	var other:=Node3D.new()
	world.add_child(other)
	XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
	XRToolsPointerEvent.pressed(other,hit.collider,hit.position)
	XRToolsPointerEvent.moved(other,hit.collider,hit.position+pad.global_basis.x*.03,hit.position)
	check(near(joint.slider_position,Vector2.ZERO),"Second pointer cannot steal the pad")
	XRToolsPointerEvent.moved(pointer,hit.collider,hit.position+pad.global_basis.x*.03,hit.position)
	XRToolsPointerEvent.exited(pointer,hit.collider,hit.position)
	check(near(joint.slider_position,Vector2.ZERO),"Optional spring return applies on pointer exit")
	XRToolsPointerEvent.pressed(other,hit.collider,hit.position)
	XRToolsPointerEvent.moved(other,hit.collider,hit.position+pad.global_basis.x*.03,hit.position)
	other.queue_free()
	await settle()
	check(near(joint.slider_position,Vector2.ZERO) and not pad.is_processing(),"Lost pointer releases and returns the pad")
	var grabber:=TestGrabber.new()
	world.add_child(grabber)
	grabber.global_transform=handle.global_transform
	grabber.held=handle
	handle.pick_up(grabber)
	grabber.global_position+=pad.global_basis.x*.03
	await settle()
	grabber.drop_object()
	await settle()
	check(near(joint.slider_position,Vector2.ZERO),"Optional spring return applies on actual XR release")
	grabber.queue_free()
	joint.default_on_release=false
	joint.move_slider(Vector2(.035,-.025))
	check(pad._reading.label.text=="X +0.50   Y -0.36","Flat value screen reports both normalized coordinates")

func exercise_console(toy:Node3D)->void:
	check(toy._controls_built.size()==2,"Focused demo uses the real two-pad vector console")
	check(toy.find_children("*","Label3D",true,false).is_empty(),"Vector console has flat text throughout")
	for i in 2:
		var pad:Node3D=toy._controls_built[i]
		var value:Vector2=toy.a if i==0 else toy.b
		check(near(pad.get_normalized_position()*toy.SPAN,value),"Pad %d starts at its actual vector" % i)
		check(pad.global_basis.get_scale().is_equal_approx(Vector3.ONE),"Pad %d retains metre scale" % i)
		check(pad.position.z>toy.demo_root.position.z,"Pad %d sits in front of the receiver" % i)
	check(absf(toy._controls_built[0].position.x-toy._controls_built[1].position.x)<.31,"Paired pad centres are grouped within 31 cm")
	var ids:=[toy._controls_built[0].get_instance_id(),toy._controls_built[1].get_instance_id()]
	for yaw in [0,180]:
		toy.rotation_degrees.y=yaw
		await settle()
		for i in 2:
			var pad:Node3D=toy._controls_built[i]
			pad.set_normalized_position(Vector2.ZERO)
			var joint:Node3D=pad.get_node("SliderOrigin/InteractableSlider")
			var h:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
			var grabber:=TestGrabber.new()
			world.add_child(grabber)
			grabber.global_transform=h.global_transform
			grabber.held=h
			h.pick_up(grabber)
			var target:=Vector2(.035,.028) if i==0 else Vector2(-.021,.042)
			grabber.global_position+=pad.global_basis*Vector3(target.x,target.y,0)
			await settle()
			grabber.drop_object()
			await settle()
			var value:Vector2=toy.a if i==0 else toy.b
			check(near(value,target/.07*toy.SPAN),"Vector %d yaw %d: actual grab drives the correct operand" % [i,yaw])
			check(pad._reading.label.text=="X %+.2f   Y %+.2f" % [value.x,value.y],"Pad reading matches vector coordinates")
			grabber.queue_free()
		var result:Vector2=toy.a+toy.b
		check(toy.demo_root.get_node("VectorOpRig/ResultTip").position.distance_to(Vector3(result.x,result.y,0))<.001,"Visible sum endpoint matches the two operated vectors")
		check(toy.monitor_label.text.contains("a + b = (%+.2f, %+.2f)" % [result.x,result.y]),"Monitor reports the operated sum")
	toy.rotation_degrees.y=0
	toy.apply_grid_config({"seed":17,"op":"sub","workings":"expression"})
	await settle()
	for i in 2:
		var pad:Node3D=toy._controls_built[i]
		check(pad.get_instance_id()==ids[i],"Reconfiguration keeps the graspable control alive")
		check(near(pad.get_normalized_position()*toy.SPAN,toy.a if i==0 else toy.b),"Reconfiguration resynchronizes pad and operand")
	check(toy._title_plate.get_meta("printed_text")=="VECTOR  a − b","Reconfiguration updates the mounted operation title")
	check(toy.find_children("*","Label3D",true,false).is_empty(),"Expression variant also uses flat surface text")
	var result:Vector2=toy.a-toy.b
	check(toy.demo_root.get_node("VectorOpRig/ResultTip").position.distance_to(Vector3(result.x,result.y,0))<.001,"Subtraction variant retains its arithmetic")
	await capture("subtraction",Vector3(.15,1.6,1.25),Vector3(.12,1.25,0),70)
	toy.apply_grid_config({"seed":0,"op":"add","workings":"trace"})
	await settle()
	var pad:Node3D=toy._controls_built[0]
	pad.set_normalized_position(Vector2.ZERO)
	var hit:=hit_face(pad)
	check(not hit.is_empty(),"Mounted pad is reachable by a physical ray from in front")
	if not hit.is_empty():
		XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
		XRToolsPointerEvent.moved(pointer,hit.collider,hit.position+pad.global_basis*Vector3(.028,-.028,0),hit.position)
		XRToolsPointerEvent.released(pointer,hit.collider,hit.position)
		check(near(toy.a,Vector2(.5,-.5)),"Mounted pointer drag changes the actual vector")
	await capture("changed",Vector3(.15,1.6,1.2),Vector3(.12,1.10,0),70)
	toy.apply_grid_config({"seed":0,"op":"add"})
	await settle()

func regress_toys()->void:
	for path in ["wedge_slide","dot_aligner","projection_shadow","circle_train"]:
		var scene:PackedScene=load("res://commons/artifacts/"+path+"/"+path+".tscn")
		check(scene!=null,"Sibling scene loads: "+path)
		if scene==null: continue
		var toy:Node3D=scene.instantiate()
		toy.position.x=5
		world.add_child(toy)
		await settle()
		check(toy.monitor_label is Label3D,"Sibling retains its legacy text contract: "+path)
		check(toy.demo_root.get_child_count()>0,"Sibling receiver builds: "+path)
		toy.queue_free()
		await settle()
