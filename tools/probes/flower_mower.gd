extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(label: String,passed: bool) -> void:
	checks.append({"label":label,"passed":passed})
	if not passed:failures.append(label);push_error(label)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	await process_frame
	var world:=Node3D.new();root.add_child(world)
	var mower=load("res://commons/artifacts/force_mower/force_mower.tscn").instantiate()
	mower.set_meta("config_lesson","flower_garden");world.add_child(mower)
	var deadline:=Time.get_ticks_msec()+10000
	while (mower.garden==null or not mower.garden.ready_to_push) and Time.get_ticks_msec()<deadline:await process_frame
	var g=mower.garden
	check("large garden is a fixed sibling of the moving mower",g!=null and g.get_parent()==mower.get_parent() and g.ready_to_push)
	if g==null or not g.ready_to_push:quit(1);return
	check("lawn offers 560 square metres",is_equal_approx(g.lawn_width*g.lawn_length,560))
	check("thousands of grass tufts use bounded instance batches",g.points.size()>3500 and g.grass.multimesh.instance_count==g.points.size()*3 and g.flowers.multimesh.instance_count==g.points.size())
	check("mower is a grounded fourteen kilogram rigid body",is_equal_approx(mower.mass,14) and not mower.freeze and mower.axis_lock_linear_y and mower.axis_lock_angular_x)
	check("only the handle can be picked up",not mower.enabled and g.handle.enabled)
	check("grass starts uncut with no planted flowers",g.cut_count==0 and g.flower_count==0)
	var lawn_pose: Transform3D=g.lawn.global_transform
	var rig:=XROrigin3D.new();rig.current=true
	var head:=XRCamera3D.new();head.name="Camera";head.position.y=1.7;rig.add_child(head)
	var hand:=XRController3D.new();rig.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	world.add_child(rig);await frames(3)
	hand.global_position=g.anchor();g.handle.pick_up(pickup);await frames(3)
	check("actual XR pickup takes the handle",g.handle.is_picked_up() and g.handle.held())
	var start: Vector3=mower.global_position
	for i in range(100):
		hand.global_position=g.anchor()+mower.global_basis.x*0.45
		await physics_frame
	check("pushing the hand moves the actual mower forward",mower.global_position.x>start.x+1.0)
	check("mower motion stays on its ground plane",absf(mower.global_position.y-start.y)<0.001)
	check("lawn does not move with the mower",g.lawn.global_transform.is_equal_approx(lawn_pose))
	check("actual deck travel cuts grass and leaves flowers",g.cut_count>10 and g.flower_count>2)
	check("work is accumulated from applied model push and displacement",g.work>10 and g.distance>1)
	var before_count: int=g.flower_count
	g._cut_at(mower.global_position);g._cut_at(mower.global_position)
	check("revisiting the same cut cannot add duplicate flowers",g.flower_count==before_count)
	var before: Transform3D=mower.global_transform
	g.reset_garden();check("reset refuses to steal a held handle",mower.global_transform.is_equal_approx(before) and g.flower_count>0)
	for i in range(45):
		hand.global_position=g.anchor()+mower.global_basis.x*0.35+mower.global_basis.z*0.35
		await physics_frame
	check("right hand displacement steers right instead of strafing",mower.global_basis.x.z>0.12)
	for i in range(75):
		hand.global_position=g.anchor()+mower.global_basis.x*0.35-mower.global_basis.z*0.45
		await physics_frame
	check("left hand displacement turns back left",mower.angular_velocity.y>0.1)
	g.handle.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await frames(3)
	var speed: float=mower.linear_velocity.length()
	check("release removes drive but keeps inertia",g.push.is_zero_approx() and speed>0.1)
	await create_timer(2.2).timeout
	check("drag slows released mower",mower.linear_velocity.length()<speed*0.3)
	check("released handle remains at the mower grip",g.handle.global_position.distance_to(g.anchor())<0.03)
	g.buttons.RESET.pressed.emit()
	while g.resetting:await process_frame
	await frames(3)
	print("RESET distance=",mower.global_position.distance_to(g.home.origin)," cut=",g.cut_count," flowers=",g.flower_count," held=",g.handle.held())
	check("nearby reset returns mower and restores the whole lawn",mower.global_position.distance_to(g.home.origin)<0.02 and g.cut_count==0 and g.flower_count==0)
	# The museum's actual desktop carry path uses the same held handle.
	var player:=CharacterBody3D.new();world.add_child(player)
	var camera:=Camera3D.new();player.add_child(camera)
	var pointer=load("res://commons/scenes/em/em_desktop_pointer.gd").new();pointer.cam=camera;player.add_child(pointer)
	pointer.set_process(false);pointer.set_physics_process(false);pointer._grab_held(g.handle)
	check("desktop grab reaches the same steering handle",g.handle.held())
	for i in range(45):
		g.handle.global_position=g.anchor()+Vector3(0.4,0,0);await physics_frame
	check("desktop hand displacement pushes the same rigid body",mower.global_position.x>g.home.origin.x+0.25)
	pointer._drop_held();await frames(3);check("desktop release clears drive",not g.handle.held() and g.push.is_zero_approx())
	var lawn=g.lawn;mower.queue_free();await frames(4)
	check("unloading mower removes its independent garden and handle",not is_instance_valid(g) and not is_instance_valid(lawn))
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"physics":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"Actual rigid body, XRTools pickup and desktop hand delivery; supplied hand poses, no headset claim."}
	FileAccess.open("res://ada_run/flower_mower.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FLOWER MOWER ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
