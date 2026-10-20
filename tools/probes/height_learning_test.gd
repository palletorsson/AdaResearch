extends SceneTree
const Learner := preload("res://commons/artifacts/vogue_timeline/height_learner.gd")
var checks: Array=[]
var failures: Array=[]
var evidence: Dictionary={}
const FOLDER := "res://doc/book/iterations/2026-10-11-teach-a-sphere-height/"
func _initialize() -> void: run.call_deferred()
func check(label: String, result: bool) -> void:
	checks.append({"name":label,"passed":result})
	if not result: failures.append(label)
	print("HEIGHT ","PASS " if result else "FAIL ",label)

static func fixture(reverse: bool=false) -> RefCounted:
	var model := Learner.new()
	for x in [-1.0,-0.75,-0.5,-0.25,0.0,0.25,0.5]:
		var y:float=0.25+0.5*(x+1.0)
		model.add_example(x,1.0-y if reverse else y)
	model.begin_training()
	return model

func run() -> void:
	var m := Learner.new()
	check("no examples, no prediction and no training on arrival",m.examples.is_empty() and m.predict(0).is_empty() and not m.begin_training())
	check("invalid training numbers rejected",not m.add_example(NAN,0.5) and not m.add_example(0,INF) and not m.add_example(0,1.1))
	for i in 3: m.add_example(0,0.1*i)
	check("same hand height repeated cannot establish an input range",not m.can_train())
	m=fixture()
	var derivative:=m.gradient()
	var error:=0.0
	for key in ["slope","intercept"]:
		var old:float=m.get(key)
		m.set(key,old+0.0001);var plus:=m.loss()
		m.set(key,old-0.0001);var minus:=m.loss()
		m.set(key,old)
		error=maxf(error,absf((plus-minus)/0.0002-(derivative.x if key=="slope" else derivative.y)))
	check("both MSE derivatives agree with finite differences",error<1e-6)
	evidence.gradient_max_error=error
	var before:=m.loss()
	for i in Learner.EPOCHS: m.train_epoch()
	check("real fit changes both parameters and completes",m.trained and m.epoch==Learner.EPOCHS and m.slope>0.1 and m.intercept>0.1)
	check("linear fixture training error falls",m.loss()<1e-10 and m.loss()<before*0.01)
	evidence.loss_before=before;evidence.loss_after=m.loss()
	# Independent closed-form oracle, not a second gradient-descent implementation.
	var mean_x:float=-0.25
	var mean_y:float=0.625
	var cov:=0.0;var variance:=0.0
	for row:Dictionary in m.examples:
		cov+=(float(row.x)-mean_x)*(float(row.target)-mean_y)
		variance+=pow(float(row.x)-mean_x,2)
	var expected_slope:=cov/variance
	check("learned coefficients match independent least-squares solution",absf(m.slope/m.spread-expected_slope)<1e-6 and absf(m.intercept-m.slope*m.centre/m.spread-(mean_y-expected_slope*mean_x))<1e-6)
	var saved:=m.snapshot()
	var max_error:=0.0
	for x in [-0.9,-0.6,-0.1,0.1,0.4]:
		var result:=m.test_example(x,0.25+0.5*(x+1.0))
		max_error=maxf(max_error,absf(result.error))
	check("five fresh intermediate inputs are predicted continuously",max_error<1e-6 and m.tests.size()==5)
	check("testing leaves learned parameters and training pairs untouched",m.snapshot()==saved)
	var returned:=m.test_example(-0.1,0.7)
	returned.clear()
	check("caller cannot erase stored evaluation by clearing returned prediction",m.tests.back().has("error"))
	evidence.heldout_max_error_m=max_error
	check("out-of-range input is withheld and output bounded",not m.predict(1.8).accepted and m.predict(1.8).clamped and m.predict(1.8).value==1.0)
	check("invalid inference rejected",m.predict(NAN).is_empty() and m.predict(3).is_empty())
	var reverse:=fixture(true)
	for i in Learner.EPOCHS: reverse.train_epoch()
	check("reverse examples teach downward motion as hands rise",reverse.predict(-0.5).value>reverse.predict(0.0).value and absf(reverse.raw(-0.1)-(1.0-m.raw(-0.1)))<1e-6)
	var impossible:=Learner.new()
	for x in [-1.0,0.0,1.0]: impossible.add_example(x,x*x)
	impossible.begin_training()
	for i in Learner.EPOCHS: impossible.train_epoch()
	check("a straight-line model exposes error on a curved target",impossible.loss()>0.2)
	evidence.curved_fixture_mse=impossible.loss()
	var path:="user://ada_height_test_fixture.json"
	var copy:=Learner.new()
	check("real local save and reload succeed",m.save_file(path)==OK and copy.load_file(path))
	check("reload preserves continuous predictions and starts fresh tests",absf(copy.raw(-0.1)-m.raw(-0.1))<1e-12 and copy.tests.is_empty())
	var bad:=m.snapshot();bad.spread=0
	check("malformed load is atomic",not copy.restore(bad) and absf(copy.raw(-0.1)-m.raw(-0.1))<1e-12)
	bad=m.snapshot();bad.centre=1.5
	check("saved normalisation must match saved examples",not copy.restore(bad))
	bad=m.snapshot();bad.epoch=10
	check("trained flag cannot bypass completed fit",not copy.restore(bad))
	check("adding a pair invalidates fit and evaluation",copy.add_example(0.4,0.8) and not copy.trained and copy.tests.is_empty() and copy.predict(0).is_empty())
	var limited:=Learner.new()
	for i in Learner.LIMIT: limited.add_example(i/30.0,0.5)
	check("dataset bounded at 30 takes",not limited.add_example(0,0.5))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var stage=load("res://commons/artifacts/vogue_timeline/vogue_timeline.tscn").instantiate()
	root.add_child(stage);await process_frame;stage.set_process(false)
	var station=stage.get_node("PoseLearningStation");station.set_process(false)
	var sphere_id:int=station.sphere.get_instance_id()
	station.model.add_example([0,0,0,1,0,0],0)
	var pose_snapshot:Dictionary=station.model.snapshot()
	var switch_button=station.controls.find_child("Btn_12",true,false).get_node("InteractableAreaButton")
	switch_button.button_pressed.emit(switch_button)
	var lesson=station.height_lesson
	check("native HEIGHT button selects regression with same sphere",station.lesson=="HEIGHT" and station.sphere.get_instance_id()==sphere_id and lesson.model.examples.is_empty())
	station.command("CAPTURE")
	check("capture requires real tracking",not lesson.capturing)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var ht:=XRPositionalTracker.new();ht.name=&"head";ht.type=XRServer.TRACKER_HEAD
	ht.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-1.65,1.6,0.9)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(ht)
	var camera:=XRCamera3D.new();origin.add_child(camera);camera.make_current()
	var trackers:Array=[]
	for side in [&"left_hand",&"right_hand"]:
		var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
		tr.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-1.65+(-0.4 if side==&"left_hand" else 0.4),1.3,0.3)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(tr);trackers.append(tr)
		var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
	await process_frame;await process_frame;stage._resolve_rig()
	lesson.slider.set_normalized_value(0.7)
	lesson.slider.slider_moved.emit(0.0)
	check("native slider chooses the desired sphere height",absf(lesson.target-0.7)<0.001 and absf(station.sphere.position.y-1.65)<0.001)
	var button=station.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	check("native CAPTURE button begins a timed paired take",lesson.capturing and lesson.capture_time==-3.0 and absf(lesson.capture_target-0.7)<0.001)
	lesson.set_target(0.1)
	check("target is locked throughout capture",absf(lesson.target-0.7)<0.001)
	for i in 76: station._process(0.05)
	check("one held gesture saves one actual input-target pair",lesson.model.examples.size()==1 and absf(lesson.model.examples[0].x-(-0.3/0.65))<0.001 and absf(lesson.model.examples[0].target-0.7)<0.001)
	station.command("CAPTURE");lesson.advance_capture(0.05,0,false)
	check("lost tracking discards unfinished pair",not lesson.capturing and lesson.model.examples.size()==1)
	station.command("CAPTURE");lesson.advance_capture(0.5,0,true)
	check("long frame discards unfinished pair",not lesson.capturing and lesson.model.examples.size()==1)
	station.command("CAPTURE");lesson.capture_time=0.0
	for i in 14: lesson.advance_capture(0.05,0.0 if i%2==0 else 1.0,true)
	check("unstable height capture is rejected",not lesson.capturing and lesson.model.examples.size()==1)
	lesson.model=fixture()
	station.command("TRAIN")
	station.command("POSE")
	check("training runs incrementally and cannot switch halfway",lesson.training and lesson.model.epoch==0 and station.lesson=="HEIGHT")
	for i in 120: station._process(0.0)
	check("real station fit completes into fresh-test mode",lesson.model.trained and not lesson.training and lesson.mode=="TEST")
	saved=lesson.model.snapshot()
	station.command("CAPTURE")
	for i in 76: station._process(0.05)
	check("fresh test capture never trains",lesson.model.tests.size()==1 and lesson.model.snapshot()==saved)
	station.command("LIVE")
	check("switching to LIVE keeps fresh-test evidence intact",lesson.model.tests[0].has("error"))
	for i in 90: station._process(0.05)
	var predicted:float=lesson.model.predict(-0.3/0.65).value
	check("live measured hands drive the original sphere via fitted weights",absf(station.sphere.position.y-(0.95+predicted))<0.001 and station.sphere.get_instance_id()==sphere_id)
	trackers[0].invalidate_pose(&"default");station._process(0.05)
	check("tracking loss immediately clears learned output",lesson.prediction.is_empty() and not lesson.cursor.visible)
	for i in 90: station._process(0.05)
	check("idle sphere returns within its bounded rail",absf(station.sphere.position.y-1.45)<0.001)
	station.command("POSE")
	check("return to pose preserves both datasets and same sphere",station.model.snapshot()==pose_snapshot and lesson.model.trained and station.sphere.get_instance_id()==sphere_id and station.controls.find_children("Btn_*","Node",true,false).size()==14)
	station.command("HEIGHT")
	check("returning to height starts TEST, never stale live actuation",lesson.mode=="TEST" and lesson.prediction.is_empty())
	station.command("RESET");check("one reset press keeps height model",lesson.model.trained)
	station.command("RESET")
	check("confirmed height reset does not erase pose lesson",lesson.model.examples.is_empty() and station.model.snapshot()==pose_snapshot)
	station.command("POSE")
	for tr in trackers: XRServer.remove_tracker(tr)
	XRServer.remove_tracker(ht);origin.queue_free();stage.queue_free();await process_frame
	FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Native Godot model, independent least-squares oracle, synthetic held-out inputs, real slider/buttons and supplied XR trackers. Human performance untested."},"  "))
	quit(0 if failures.is_empty() else 1)
