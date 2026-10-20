extends SceneTree
const Learner := preload("res://commons/artifacts/vogue_timeline/pose_learner.gd")
const CENTRES := [
	[-0.60,0.15,-0.45,0.60,0.15,-0.45],
	[-0.22,0.85,-0.40,0.22,0.85,-0.40],
	[-0.25,-0.65,-0.75,0.25,-0.65,-0.75]]
var checks: Array = []
var failures: Array = []
var evidence: Dictionary = {}
var folder := "res://doc/book/iterations/2026-10-11-teach-a-sphere/"
func _initialize() -> void: run.call_deferred()
func check(label: String, result: bool) -> void:
	checks.append({"name":label,"passed":result})
	if not result: failures.append(label)
	print("POSE ", "PASS " if result else "FAIL ", label)

static func example(label: int, take: int) -> Array:
	var x: Array = CENTRES[label].duplicate()
	for i in 6: x[i] += sin(float(take*7+i*3))*0.045
	return x

static func fixture() -> RefCounted:
	var m := Learner.new()
	for label in 3:
		for take in 5: m.add_example(example(label,take),label)
	m.initialize(417)
	return m

func run() -> void:
	var m := Learner.new()
	check("starts empty, no guide examples or predictions",m.examples.is_empty() and m.predict(CENTRES[0]).is_empty())
	check("minimum examples required for every class",not m.can_train())
	check("invalid dimensions, numbers and labels rejected",not m.add_example([1,2],0) and not m.add_example([NAN,0,0,0,0,0],0) and not m.add_example(CENTRES[0],3))
	var analytic := m.gradient(CENTRES[1],1)
	var gradient_error := 0.0
	for i in Learner.PARAMETERS:
		var old := m.weights[i]
		m.weights[i] = old+0.0001
		var plus := m.example_loss(CENTRES[1],1)
		m.weights[i] = old-0.0001
		var minus := m.example_loss(CENTRES[1],1)
		m.weights[i] = old
		gradient_error = maxf(gradient_error,absf(analytic[i]-(plus-minus)/0.0002))
	check("all 83 analytic derivatives match independent finite differences",gradient_error<0.00001)
	evidence.gradient_max_error = gradient_error
	m = fixture()
	var before_weights := m.weights.duplicate()
	var before_loss := m.loss()
	for _epoch in Learner.EPOCHS: m.train_epoch()
	check("training changes actual weights",m.weights!=before_weights)
	check("training reaches fixed completion",m.trained and m.epoch==Learner.EPOCHS)
	check("cross entropy falls substantially",m.loss()<0.05 and m.loss()<before_loss*0.1)
	evidence.loss_before=before_loss
	evidence.loss_after=m.loss()
	var heldout_correct := 0
	var heldout_accepted := 0
	before_weights=m.weights.duplicate()
	var before_count:=m.examples.size()
	for label in 3:
		for take in range(20,25):
			var result:=m.test_example(example(label,take),label)
			if result.correct: heldout_correct+=1
			if result.accepted: heldout_accepted+=1
	check("15 distinct held-out synthetic takes classified correctly",heldout_correct==15 and heldout_accepted==15)
	check("testing changes neither weights nor training dataset",m.weights==before_weights and m.examples.size()==before_count and m.tests.size()==15)
	check("distant pose withheld even if classifier has a favourite",not m.predict([3,3,3,3,3,3]).accepted)
	check("input validation also applies at inference",m.predict([1,2]).is_empty())
	evidence.heldout={"correct":heldout_correct,"total":15,"kind":"synthetic independent fixture takes, not headset performances"}
	var permuted:=Learner.new()
	for label in 3:
		for take in 5: permuted.add_example(example(label,take),(label+1)%3)
	permuted.initialize(417)
	for _epoch in Learner.EPOCHS: permuted.train_epoch()
	var changed:=true
	for label in 3: changed=changed and permuted.predict(example(label,24)).label==(label+1)%3
	check("changing supplied labels changes learned answers",changed)
	var clone:=Learner.new()
	var saved_path:="user://ada_pose_test_fixture.json"
	check("real file save and reload succeed",m.save_file(saved_path)==OK and clone.load_file(saved_path))
	var reload_error := 0.0
	for i in Learner.PARAMETERS: reload_error = maxf(reload_error, absf(clone.weights[i]-m.weights[i]))
	evidence.reload_max_parameter_error=reload_error
	check("reloaded parameters and predictions preserved within numerical precision",reload_error<1e-12 and clone.predict(example(1,21)).label==1)
	check("load starts a fresh evaluation session",clone.tests.is_empty())
	var bad:=m.snapshot()
	bad.weights=[1,2]
	var saved_weights:=clone.weights.duplicate()
	check("malformed load rejected without replacing active model",not clone.restore(bad) and clone.weights==saved_weights)
	bad=m.snapshot();bad.examples[0].label=1.5
	check("fractional class labels rejected",not clone.restore(bad))
	check("new examples invalidate old evaluation and live predictions",clone.add_example(example(0,99),0) and not clone.trained and clone.tests.is_empty() and clone.predict(example(0,99)).is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
	var packed:=load("res://commons/artifacts/vogue_timeline/vogue_timeline.tscn") as PackedScene
	var stage=packed.instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	var station=stage.get_node("PoseLearningStation")
	station.set_process(false)
	check("learning station retains 11 pose controls plus three lesson selectors",station!=null and station.controls.find_children("Btn_*","Node",true,false).size()==14)
	check("dance retains its nine original controls",stage.controls.find_children("Btn_*","Node",true,false).size()==9)
	station.command("A")
	check("absent tracking cannot create examples",station.capture_label==-1 and station.model.examples.is_empty())
	station.command("TEST")
	check("untrained session cannot enter test mode",station.mode=="TEACH")
	var origin:=XROrigin3D.new();root.add_child(origin)
	var ht:=XRPositionalTracker.new();ht.name=&"head";ht.type=XRServer.TRACKER_HEAD
	ht.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-1.65,1.6,0.9)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(ht)
	var camera:=XRCamera3D.new();origin.add_child(camera);camera.make_current()
	var trackers:Array=[]
	for side in [&"left_hand",&"right_hand"]:
		var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
		tr.set_pose(&"default",Transform3D(Basis.IDENTITY,Vector3(-1.65+(-0.4 if side==&"left_hand" else 0.4),1.5,0.3)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(tr);trackers.append(tr)
		var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
	await process_frame;await process_frame
	stage._resolve_rig()
	var button=station.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	check("real XR button starts a timed pose capture",station.capture_label==0 and station.capture_time==-3.0)
	for i in 76: station._process(0.05)
	check("a held pose becomes exactly one training take",station.model.examples.size()==1 and station.capture_label==-1)
	var row:Array=station.model.examples[0].x
	check("capture contains measured head-relative coordinates",absf(row[0]-(-0.4/0.65))<0.001 and absf(row[2]-(-0.6/0.65))<0.001)
	station.command("B")
	for i in 20: station._process(0.05)
	trackers[0].invalidate_pose(&"default")
	station._process(0.05)
	check("tracking loss discards entire unfinished take",station.capture_label==-1 and station.model.examples.size()==1 and station.samples.is_empty())
	station.capture_label=1;station.capture_time=0.0;station.sample_time=0.0
	for i in 14: station.advance_capture(0.05,example(1,i) if i%2==0 else example(2,i),true)
	check("unstable pose is rejected instead of averaging two gestures",station.model.examples.size()==1)
	station.capture_label=1;station.capture_time=-1.0
	station.advance_capture(0.5,CENTRES[1],true)
	check("long frame cancels capture",station.capture_label==-1 and station.model.examples.size()==1)
	station.model=m
	station.mode="TEST"
	station.capture_label=2;station.capture_time=0.0;station.samples.clear()
	for i in 14: station.advance_capture(0.05,example(2,22),true)
	check("held-out capture adds a test only",station.model.tests.size()==16 and station.model.examples.size()==15 and station.model.weights==before_weights)
	station.command("LIVE")
	station.observe(0.05,example(0,22),true)
	check("one prediction frame cannot activate sphere",station.response==-1)
	for i in 8: station.observe(0.05,example(0,22),true)
	station.animate_response()
	check("learned A raises the actual sphere",station.response==0 and station.sphere.position.y>1.2)
	station.observe(0.01,[],false);station.animate_response()
	check("lost tracking immediately idles response",station.response==-1 and is_equal_approx(station.sphere.position.y,1.2) and station.last_prediction.is_empty())
	for label in [1,2]:
		for i in 8: station.observe(0.05,example(label,22),true)
		station.clock=1.0;station.animate_response()
		check("learned class %d selects its real response" % label,station.response==label and (station.sphere.rotation.length()>0.1 if label==1 else station.sphere.scale.y>1.0))
	station.command("RESET")
	check("one reset press preserves learned session",station.model.trained)
	station.command("RESET")
	check("confirmed reset clears examples and weights readiness",station.model.examples.is_empty() and not station.model.trained and station.mode=="TEACH")
	station.model=fixture()
	station.command("TRAIN")
	check("train control begins incremental work",station.training and station.model.epoch==0)
	station.command("TEACH")
	check("training cannot silently change dataset midway",station.training and station.mode=="TRAIN")
	for i in 150: station._process(0.0)
	check("incremental scene training completes and requests fresh tests",station.model.trained and not station.training and station.mode=="TEST")
	for tr in trackers: XRServer.remove_tracker(tr)
	XRServer.remove_tracker(ht)
	origin.queue_free();stage.queue_free();await process_frame
	FileAccess.open(folder+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Real Godot training, finite-difference gradients, file persistence, scene buttons and supplied XR trackers. No human/headset accuracy claim."},"  "))
	quit(0 if failures.is_empty() else 1)
