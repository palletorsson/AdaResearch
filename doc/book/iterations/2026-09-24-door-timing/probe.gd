extends SceneTree
var checks: Array = []
var failures: Array = []
var artifact: Node3D
var walker: CharacterBody3D
var pointer: Node3D
var event_script
func _initialize() -> void: call_deferred("run")
func check(title: String, good: bool, data: Variant = null) -> void:
	checks.append({"name":title,"passed":good,"value":data})
	if not good: failures.append(title)
func button(trial: Node3D, index: int) -> void:
	var target: Node3D = trial.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]: target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
func place(trial: Node3D, pos: Vector3) -> void:
	walker.global_position = trial.to_global(pos)
	walker.velocity = Vector3.ZERO
	await physics_frame;await physics_frame;await physics_frame
func walk_to(trial: Node3D, pos: Vector3, max_frames: int = 300) -> float:
	var target := trial.to_global(pos)
	for i in range(max_frames):
		var delta := target-walker.global_position;delta.y = 0
		if delta.length()<0.065: break
		var direction := delta.normalized()
		walker.velocity = Vector3(direction.x*2.5,0 if walker.is_on_floor() else walker.velocity.y-9.8/60,direction.z*2.5)
		walker.move_and_slide()
		await physics_frame
	var error := target-walker.global_position;error.y=0
	return error.length()
func run() -> void:
	event_script = load("res://addons/godot-xr-tools/events/pointer_event.gd")
	artifact = load("res://commons/artifacts/door_timing_trials/door_timing_trials.tscn").instantiate()
	artifact.position=Vector3(17,0,-12);artifact.rotation.y=PI
	root.add_child(artifact)
	var floor_host:=Node3D.new();root.add_child(floor_host)
	load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").box(floor_host,Vector3(17,-0.1,-12),Vector3(30,0.2,30),Color.DIM_GRAY,true)
	pointer=Node3D.new();root.add_child(pointer)
	walker=CharacterBody3D.new();walker.name="TestWalker";walker.add_to_group("player");walker.collision_layer=1;walker.collision_mask=1
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.7;capsule.radius=0.28;shape.shape=capsule;shape.position.y=0.85;walker.add_child(shape);walker.position=Vector3(30,0,0);root.add_child(walker)
	await create_timer(0.2).timeout
	check("three matched trials built",artifact.trials.size()==3)
	var outsider:=RigidBody3D.new();root.add_child(outsider)
	for i in range(3):
		var t:Node3D=artifact.trials[i]
		check("initial draw timing %d"%i,t.draws==(0 if i==1 else 1) and t.revealed==(i==0),t.get_state())
		check("closed geometry conceals assignment %d"%i,t.entries[0].position.y==t.entries[1].position.y and t.shortcuts[0].position.y==t.shortcuts[1].position.y and not t.shortcut_locks[0].disabled and not t.shortcut_locks[1].disabled)
		t._on_choice_body(outsider,0);check("non-player ignored %d"%i,t.chosen==-1)
		var first_seed:int=t.run_seed
		t.choose(0);t.choose(1)
		var expected:Array=[ ["DRAW","REVEAL","CHOOSE A"], ["CHOOSE A","DRAW","REVEAL"], ["DRAW","CHOOSE A","REVEAL"] ][i]
		check("event order and one draw %d"%i,t.events==expected and t.draws==1 and t.chosen==0,t.get_state())
		var answer:int=t.short_door
		button(t,0)
		await create_timer(1).timeout
		check("pointer replay cancels stale opening %d"%i,t.chosen==-1 and not t.ready_to_walk and absf(t.entries[0].position.y-1.2)<0.0001 and not t.entry_locks[0].disabled)
		t.choose(0);check("same seed repeats answer %d"%i,t.short_door==answer)
		await create_timer(0.9).timeout;await physics_frame
		check("only chosen entry opens %d"%i,t.entry_locks[0].disabled and not t.entry_locks[1].disabled)
		check("shortcut collision agrees with answer %d"%i,t.shortcut_locks[0].disabled==(answer==0) and not t.shortcut_locks[1].disabled)
		button(t,1);check("new round changes seed, clears choice %d"%i,t.run_seed!=first_seed and t.chosen==-1)
		t.run_seed=first_seed;t.replay()
	# Actual Area3D choice and collision on a rotated translated host, each schedule.
	for i in range(3):
		var t:Node3D=artifact.trials[i]
		# Reveal an answer using the live trial then replay. This prepares a known direct-route test.
		t.choose(0);var direct:int=t.short_door;t.replay()
		var x:float=t.lane_x(direct)
		await place(t,Vector3(x,0.02,-4.4))
		var err:float=await walk_to(t,Vector3(x,0.02,-3.28))
		check("walking onto plate chooses %d"%i,err<0.1 and t.chosen==direct and t.draws==1,t.get_state())
		await create_timer(0.9).timeout;await physics_frame
		err=await walk_to(t,Vector3(x,0.02,-1.15))
		check("selected entrance admits body %d"%i,err<0.1)
		var round_before:int=t.round_id;var seed_before:int=t.run_seed
		button(t,0);button(t,1)
		check("occupied reset and new-round refused %d"%i,t.round_id==round_before and t.run_seed==seed_before and t.status.text.contains("LEAVE"))
		err=await walk_to(t,Vector3(x,0.02,3.2))
		check("direct route traversable %d"%i,err<0.1 and absf(walker.position.y)<0.08,err)
		await physics_frame;button(t,0)
		check("reset works after exit %d"%i,t.chosen==-1 and t.round_id>round_before)
		var wrong:int=1-direct;x=t.lane_x(wrong)
		await place(t,Vector3(x,0.02,-4.4));await walk_to(t,Vector3(x,0.02,-3.28));await create_timer(0.9).timeout;await physics_frame
		err=await walk_to(t,Vector3(x,0.02,0.6),140)
		check("detour choice cannot walk straight through %d"%i,err>0.6 and t.to_local(walker.global_position).z < -0.25,arr(t.to_local(walker.global_position)))
		var side:float=signf(x)
		for waypoint in [Vector3(x,0.02,-1.12),Vector3(side*1.90,0.02,-1.12),Vector3(side*1.90,0.02,1.35),Vector3(x,0.02,1.35),Vector3(x,0.02,3.2)]:
			err=await walk_to(t,waypoint)
			check("detour waypoint %d %s"%[i,str(waypoint)],err<0.1,err)
		await physics_frame;button(t,0)
	check("new reset leaves no pending opening",not artifact.trials[2].ready_to_walk)
	var vr:=CharacterBody3D.new();vr.add_to_group("vr_player");root.add_child(vr)
	check("VR group recognized without desktop museum",artifact.trials[0].is_player(vr))
	check("distinct starting seeds",artifact.trials[0].run_seed!=artifact.trials[1].run_seed and artifact.trials[1].run_seed!=artifact.trials[2].run_seed)
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"Native production pointer buttons and CharacterBody plate entry, collision, direct and detour traversal at translated rotated host. VR group detection only; no headset input or statistical test."}
	FileAccess.open("res://doc/book/iterations/2026-09-24-door-timing/native-checks.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("DOOR TIMING ",checks.size()," CHECKS; FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
func arr(v:Vector3)->Array:return [v.x,v.y,v.z]
