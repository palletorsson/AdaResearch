extends SceneTree
const Learner:=preload("res://commons/artifacts/vogue_timeline/movement_learner.gd")
const Fixture:=preload("res://tools/probes/movement_fixture.gd")
const FOLDER:="res://doc/book/iterations/2026-10-11-teach-a-sphere-phrase/"
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(label:String,result:bool) -> void:
	checks.append({"name":label,"passed":result})
	if not result: failures.append(label)
	print("PHRASE ","PASS " if result else "FAIL ",label)

func run() -> void:
	var model:=Learner.new()
	check("empty arrival has no phrase predictions",model.predict(Fixture.take()).is_empty() and not model.fit())
	var take:=Fixture.take()
	check("complete timestamped two-hand take validates",Learner.valid_take(take))
	var bad:=take.duplicate(true);bad[20].x=[0,0,0]
	check("missing hand rejected",not model.add_example(bad))
	bad=take.duplicate(true);bad[20].x[3]=NAN
	check("nonfinite tracking rejected",not model.add_example(bad))
	bad=take.duplicate(true);bad[20].t=bad[19].t
	check("out-of-order timestamps rejected",not model.add_example(bad))
	bad=take.slice(0,40)
	check("truncated performance cannot become training data",not model.add_example(bad))
	bad=take.duplicate(true)
	for i in range(20,27): bad.remove_at(20)
	check("tracking gap is not interpolated into invented movement",not model.add_example(bad))
	bad=take.duplicate(true)
	for row:Dictionary in bad:
		for j in range(3,6):row.x[j]=take[0].x[j]
	check("teaching requires movement from both hands",not model.add_example(bad))
	for v in 2:model.add_example(Fixture.take(v))
	check("two takes cannot fit yet",not model.fit())
	model.add_example(Fixture.take(2))
	check("three whole performances fit two timed paths",model.fit() and model.prototype.size()==41 and model.limits.size()==2)
	var mean_error:=0.0
	for i in 41:
		for j in 6:
			var expected:=0.0
			for v in 3:expected+=Fixture.coordinates(i*0.1,v)[j]/3.0
			mean_error=maxf(mean_error,absf(model.prototype[i][j]-expected))
	check("fitted path equals independently computed phase-wise average",mean_error<1e-8)
	evidence.prototype_max_error=mean_error;evidence.fit_mse=model.fit_error;evidence.limits=model.limits.duplicate()
	var frozen:=model.snapshot()
	var positive:=model.test_example(Fixture.take(11))
	check("unseen complete performance matches",positive.accepted)
	var reversed:=model.test_example(Fixture.take(11,true))
	check("same positions in reverse order are rejected",not reversed.accepted)
	bad=Fixture.take(11)
	for row:Dictionary in bad:
		var x:Array=row.x
		row.x=[x[3],x[4],x[5],x[0],x[1],x[2]]
	check("swapping left and right changes the phrase",not model.test_example(bad).accepted)
	bad=Fixture.take(11)
	for row:Dictionary in bad:
		for j in range(3,6):row.x[j]=take[0].x[j]
	check("correct left hand cannot compensate for stationary right hand",not model.test_example(bad).accepted)
	bad=Fixture.take(11)
	for row:Dictionary in bad: row.x=Fixture.coordinates(4.0*pow(float(row.t)/4.0,4),11)
	check("large timing change is detected without time warping",not model.test_example(bad).accepted)
	bad=Fixture.take(11)
	for row:Dictionary in bad:
		for j in 6:row.x[j]+=1.0
	check("unfamiliar displaced movement is withheld",not model.test_example(bad).accepted)
	check("fresh tests leave fitted data and parameters untouched",model.snapshot()==frozen)
	positive.clear()
	check("returned result cannot erase stored test evidence",model.tests[0].has("accepted"))
	evidence.heldout={"fresh_match":model.tests[0],"reversed":reversed,"negative_variants":5,"scope":"Synthetic fixture performances; not human accuracy"}
	var shifted:=Learner.new()
	for v in 3:
		var row_take:=Fixture.take(v)
		for row:Dictionary in row_take:row.x[1]+=0.35;row.x[4]+=0.35
		shifted.add_example(row_take)
	shifted.fit()
	check("changing demonstrations changes the learned path",absf(shifted.prototype[10][1]-model.prototype[10][1]-0.35)<1e-8)
	var incoherent:=Learner.new()
	incoherent.add_example(Fixture.take(0));incoherent.add_example(Fixture.take(1));incoherent.add_example(Fixture.take(2,true))
	check("inconsistent teaching does not silently widen tolerance forever",not incoherent.fit())
	var path:="user://ada_phrase_test_fixture.json"
	var copy:=Learner.new()
	check("real file saves and reloads fitted phrase",model.save_file(path)==OK and copy.load_file(path))
	check("reload preserves recognition and resets evaluation",copy.predict(Fixture.take(11)).accepted and not copy.predict(Fixture.take(11,true)).accepted and copy.tests.is_empty())
	var invalid:=model.snapshot();invalid.examples[0][0].t=2
	check("malformed saved take rejected atomically",not copy.restore(invalid) and copy.trained)
	invalid=model.snapshot();invalid.prototype[0][0]+=0.5
	check("saved prototype must agree with its demonstrations",not copy.restore(invalid))
	check("UNDO removes last whole take and invalidates fitted model",copy.undo() and copy.examples.size()==2 and not copy.trained and copy.tests.is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await scene_checks(model)
	FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Native Godot prototype fitting, independent mean oracle, ordered negatives, local save, actual buttons and supplied XR trackers. Human performance untested."},"  "))
	quit(0 if failures.is_empty() else 1)

func scene_checks(model:RefCounted) -> void:
	var stage=load("res://commons/artifacts/vogue_timeline/vogue_timeline.tscn").instantiate()
	root.add_child(stage);await process_frame;stage.set_process(false)
	var station=stage.get_node("PoseLearningStation");station.set_process(false)
	var sphere_id:int=station.sphere.get_instance_id()
	station.model.add_example([0,0,0,1,0,0],0)
	station.height_lesson.model.add_example(0,0.5)
	var pose_before:Dictionary=station.model.snapshot();var height_before:Dictionary=station.height_lesson.model.snapshot()
	var button=station.controls.find_child("Btn_13",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	var lesson=station.movement_lesson
	check("PHRASE button reaches empty mode on the same sphere",station.lesson=="PHRASE" and lesson.model.examples.is_empty() and station.sphere.get_instance_id()==sphere_id)
	check("phrase study hides the competing airborne dance preview",not stage.hand_space.visible)
	station.command("CAPTURE");check("capture without XR tracking is refused",not lesson.capturing)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var head:=XRPositionalTracker.new();head.name=&"head";head.type=XRServer.TRACKER_HEAD
	head.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-1.65,1.6,0.9)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(head)
	var camera:=XRCamera3D.new();origin.add_child(camera);camera.make_current()
	var trackers:Array=[]
	for side in [&"left_hand",&"right_hand"]:
		var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
		tr.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-1.65,1.3,0.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(tr);trackers.append(tr)
		var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
	await process_frame;await process_frame;stage._resolve_rig()
	button=station.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	check("native capture begins a three-second count-in",lesson.capturing and lesson.clock==-3.0)
	for i in 142:
		var x:=Fixture.coordinates(maxf(0,lesson.clock+0.05),0)
		for hand in 2:
			var at:=Vector3(-1.65,1.6,0.9)+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2])*0.65
			trackers[hand].set_pose(&"default",Transform3D(Basis.IDENTITY,at),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await process_frame
		station._process(0.05)
	check("live XR capture yields one whole timestamped performance",lesson.model.examples.size()==1 and not lesson.capturing)
	if not lesson.model.examples.is_empty():
		var kept:Array=lesson.model.examples[0]
		check("recorded path keeps duration, depth and both hand coordinates",kept[-1].t==4.0 and absf(kept[10].x[2]-Fixture.coordinates(kept[10].t,0)[2])<0.02 and absf(kept[10].x[5]-Fixture.coordinates(kept[10].t,0)[5])<0.02)
	station.command("CAPTURE");lesson.advance_capture(0.2,Fixture.coordinates(0),true)
	check("long frame discards the complete pending performance",not lesson.capturing and lesson.pending.is_empty() and lesson.model.examples.size()==1)
	station.command("CAPTURE");trackers[0].invalidate_pose(&"default");await process_frame;station._process(0.05)
	check("lost hand discards pending performance",not lesson.capturing and lesson.model.examples.size()==1)
	lesson.model=model
	station.command("TEST")
	lesson.capturing=true;lesson.clock=-0.05
	var before:Dictionary=model.snapshot()
	for i in 81:lesson.advance_capture(0.05,Fixture.coordinates(i*0.05,11),true)
	check("held-out scene performance evaluates without fitting",lesson.result.get("accepted",false) and model.snapshot()==before and lesson.replay_time<0)
	lesson.mode="TRY";lesson.capturing=true;lesson.clock=-0.05
	for i in 81:lesson.advance_capture(0.05,Fixture.coordinates(i*0.05,12),true)
	check("TRY recognises a fresh phrase and triggers response",lesson.result.get("accepted",false) and lesson.replay_time==0)
	lesson.replay_time=1.0;lesson.draw()
	check("both learned airborne hand paths and tips are drawn",lesson.paths.size()==80 and lesson.paths[0].visible and lesson.paths[40].visible and lesson.tips[0].visible and lesson.tips[1].visible)
	var first:Vector3=station.sphere.position
	lesson.replay_time=3.0;lesson.draw()
	check("original sphere moves along learned two-hand midpoint",station.sphere.get_instance_id()==sphere_id and first.distance_to(station.sphere.position)>0.01)
	lesson.mode="TRY";lesson.capturing=true;lesson.clock=-0.05;lesson.replay_time=-1
	for i in 81:lesson.advance_capture(0.05,Fixture.coordinates(4-i*0.05,12),true)
	check("reversed TRY cannot trigger sphere replay",not lesson.result.get("accepted",true) and lesson.replay_time<0)
	station.command("REPLAY");check("manual replay is labelled preview",lesson.replay_time==0 and lesson.message.begins_with("PREVIEW"))
	station.command("HEIGHT")
	check("leaving phrase restores the dance preview",stage.hand_space.visible)
	check("changing lesson stops phrase replay and preserves carried models",lesson.replay_time<0 and station.model.snapshot()==pose_before and station.height_lesson.model.snapshot()==height_before and station.sphere.get_instance_id()==sphere_id)
	station.command("PHRASE");check("returning opens TEST with fitted phrase retained",lesson.model.trained and lesson.mode=="TEST" and lesson.replay_time<0)
	station.command("RESET");check("single reset press preserves phrase",lesson.model.trained)
	station.command("RESET");check("confirmed reset only clears phrase session",lesson.model.examples.is_empty() and station.model.snapshot()==pose_before and station.height_lesson.model.snapshot()==height_before)
	station.command("POSE")
	for tracker in trackers:XRServer.remove_tracker(tracker)
	XRServer.remove_tracker(head);origin.queue_free();stage.queue_free();await process_frame
