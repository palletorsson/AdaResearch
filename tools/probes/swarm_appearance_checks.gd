extends SceneTree
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
class TestGrabber extends Node3D:
	var picked_up_ranged:=false
	var held:Node3D
	func drop_object()->void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO);held=null
func _initialize()->void:run.call_deferred()
func check(words:String,ok:bool)->void:
	checks.append({"name":words,"passed":ok});print("APPEARANCE ","PASS " if ok else "FAIL ",words)
	if not ok:failures.append(words)
func settle()->void:
	for i in range(6):await process_frame;await physics_frame
func state(h)->Array:
	var result:Array=[]
	for f in h.flights:
		for d in f.drones:result.append([d.get_instance_id(),d.transform,d.velocity,d.acceleration,d.destination()])
	return result
func choose(control:Node3D,mode:int,pointer:Node3D)->void:
	var at:=control.to_global(Vector3(0,0,.03))
	var end:Vector3=at+control.global_basis*Vector3(0,(mode/2.0-control.get_normalized_value())*control.TRAVEL,0)
	var face:Node3D=control.get_node("Face")
	XRToolsPointerEvent.pressed(pointer,face,at)
	XRToolsPointerEvent.moved(pointer,face,end,at)
	XRToolsPointerEvent.released(pointer,face,end)
func run()->void:
	var host:=Node3D.new();root.add_child(host);host.position=Vector3(30,4,-20);host.rotation.y=.7
	var packed=load("res://commons/artifacts/drone_comparison/drone_comparison.tscn")
	var baseline=packed.instantiate();baseline.playing=false;host.add_child(baseline);baseline._physics_process(0)
	var changed=packed.instantiate();changed.playing=false;host.add_child(changed);changed._physics_process(0)
	check("Twenty-four existing agents each own three prebuilt views",changed.body_views.size()==24 and changed.body_views[0].size()==3)
	check("Initial appearance is the original drone",changed.appearance==0 and changed.body_views[0][0].visible)
	var before:=state(changed)
	var views_valid:=true
	for mode in [1,2,0,2,1]:
		changed.set_appearance(mode)
		for views in changed.body_views:
			for i in range(3):views_valid=views_valid and views[i].visible==(i==mode)
	check("One and only one view is active for each body",views_valid)
	check("Switching appearance preserves identities, transforms, velocities, accelerations and targets",state(changed)==before)
	check("Appearance does not alter the selected guidance display",changed.guides)
	var pointer:=Node3D.new();root.add_child(pointer)
	var control:Node3D=changed.display_selector
	for mode in [0,1,2]:
		choose(control,mode,pointer)
		check("Real pointer events select appearance "+str(mode),changed.appearance==mode and control.get_normalized_value()==mode/2.0)
	check("Pointer release retains the selection",not control.is_processing() and changed.appearance==2)
	choose(control,0,pointer)
	var hand:=TestGrabber.new();root.add_child(hand);hand.held=control._handle
	hand.global_transform=hand.held.global_transform;hand.held.pick_up(hand)
	hand.global_position+=control.global_basis*Vector3(0,control.TRAVEL,0)
	await settle()
	check("Synthetic near grab moves the physical slider to light",changed.appearance==2)
	hand.drop_object();await settle()
	check("Releasing near grab retains light without resetting agents",changed.appearance==2 and state(changed)==before)
	# Independent trajectories: only one copy changes appearance. Targets are
	# the same nonstationary input on every tick; both use the real Boid solver.
	var max_position_error:=0.0;var max_velocity_error:=0.0;var max_acceleration_error:=0.0
	for step in range(720):
		var target:=Vector3(sin(step*.011)*1.4,sin(step*.013)*.3,cos(step*.009)*.55)
		baseline.target_offset=target;changed.target_offset=target
		if step%30==0:changed.set_appearance((step/30)%3)
		for group in range(2):
			for i in range(12):
				var a=baseline.flights[group].drones[i];var b=changed.flights[group].drones[i]
				a._physics_process(1.0/60);b._physics_process(1.0/60)
				max_position_error=maxf(max_position_error,a.position.distance_to(b.position))
				max_velocity_error=maxf(max_velocity_error,a.velocity.distance_to(b.velocity))
				max_acceleration_error=maxf(max_acceleration_error,a.acceleration.distance_to(b.acceleration))
	check("720 moving-target ticks have identical trajectories across appearance changes",max_position_error==0 and max_velocity_error==0 and max_acceleration_error==0)
	observations={"ticks":720,"appearance_changes_during_run":24,"max_position_error_m":max_position_error,"max_velocity_error":max_velocity_error,"max_acceleration_error":max_acceleration_error}
	var after:=state(changed);changed.set_appearance(-10);check("Invalid low mode clamps to drone",changed.appearance==0)
	changed.set_appearance(90);check("Invalid high mode clamps to light",changed.appearance==2)
	check("Clamping also preserves the moving state",state(changed)==after)
	check("View roots are nonphysical children of the original agents",changed.body_views[0][0].get_parent()==changed.flights[0].drones[0] and changed.body_views[0][1].find_children("*","CollisionObject3D",true,false).is_empty())
	check("Light representation needs no per-agent dynamic lights",changed.body_views[0][2].find_children("*","Light3D",true,false).is_empty())
	FileAccess.open("res://ada_run/swarm_appearance_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Production artifact; paired motion trajectories; synthetic pointer and XRTools near grab under translated and rotated parent. Physical headset untested."},"  "))
	quit(0 if failures.is_empty() else 1)
