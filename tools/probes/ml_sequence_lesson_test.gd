extends SceneTree
const Learner:=preload("res://doc/book/iterations/2026-10-11-memory-both-hands/learner/printed/movement_learner.gd")
const Library=preload("res://doc/book/iterations/2026-10-11-memory-both-hands/learner/printed/phrase_library.gd")
const Fixture:=preload("res://tools/probes/movement_fixture.gd")
const FOLDER:="res://doc/book/iterations/2026-10-11-memory-both-hands/"
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
	var line:Array=[]
	for i in 81:
		var t:=i*0.05
		line.append({"t":t,"x":[t*0.5,t*0.2,-t*0.3,1-t*0.4,t*0.1,-0.5]})
	var between:Array=Learner.sample(line,1.237)
	check("interpolation matches independent linear trajectory between sample times",absf(between[0]-1.237*0.5)<1e-10 and absf(between[3]-(1-1.237*0.4))<1e-10)
	var reverse_take:=Fixture.take(0,true)
	var mean_gap:=0.0
	for j in 6:
		var first_mean:=0.0;var reverse_mean:=0.0
		for i in take.size():
			first_mean+=take[i].x[j]/take.size()
			reverse_mean+=reverse_take[i].x[j]/reverse_take.size()
		mean_gap=maxf(mean_gap,absf(first_mean-reverse_mean))
	check("forward and reverse fixtures have equal whole-pose means",mean_gap<1e-10)
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

	await library_checks()
	await scene_checks(model)
	FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Author-informed exact-print reconstruction; synthetic traces and supplied XR trackers, not human recognition accuracy."},"  "))
	quit(0 if failures.is_empty() else 1)

func perform(study: Node3D, take: Array) -> void:
	study.capturing=true;study.phrase_time=-0.05;study.pending.clear()
	study.sample_time=0;study.replay_time=-1
	for row:Dictionary in take: study.advance_phrase(0.05,row.x,true)
	study.draw_phrase();study.refresh()

func press(study: Node3D, index: int) -> void:
	var button=study.panel.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)

func scene_checks(fitted: RefCounted) -> void:
	var script=load("res://doc/book/iterations/2026-10-11-memory-both-hands/learner/printed/sequence_study.gd")
	var study=script.new();root.add_child(study)
	await process_frame;study.set_process(false)
	var sphere_id:int=study.sphere.get_instance_id()
	var carried:Dictionary=study.model.snapshot()
	check("one carried pickable point, two tips, eighty 3D rods and fourteen buttons",study.sphere.has_method("is_picked_up") and study.tips.size()==2 and study.rods.size()==80 and study.panel.find_children("Btn_*","Node",true,false).size()==14)
	check("ONE and A/B arrive without invented phrase teaching",study.one.examples.is_empty() and study.library.models.A.examples.is_empty() and not study.library.trained)
	press(study,3)
	check("no tracking cannot start capture",not study.capturing)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var head:=XRPositionalTracker.new();head.name=&"head";head.type=XRServer.TRACKER_HEAD
	var eye:=Vector3(0,1.6,1.4)
	head.set_pose(&"default",Transform3D(Basis.IDENTITY,eye),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(head)
	var camera:=XRCamera3D.new();origin.add_child(camera)
	var trackers:Array=[]
	for side in [&"left_hand",&"right_hand"]:
		var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
		tr.set_pose(&"default",Transform3D(Basis.IDENTITY,eye+Vector3(0,-0.3,-0.4)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(tr);trackers.append(tr)
		var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
	await process_frame;await process_frame
	press(study,3)
	check("native CAPTURE starts three-second count-in",study.capturing and study.phrase_time==-3)
	for i in 142:
		var x:=Fixture.coordinates(maxf(0,study.phrase_time+0.05),0)
		for hand in 2:
			var at:=eye+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2])*0.65
			trackers[hand].set_pose(&"default",Transform3D(Basis.IDENTITY,at),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await process_frame
		study._process(0.05)
	check("real supplied XR performance kept as one whole take",study.one.examples.size()==1 and not study.capturing)
	if not study.one.examples.is_empty():
		var take:Array=study.one.examples[0]
		check("capture preserves duration, depth and hand identity",take[-1].t==4 and absf(take[10].x[2]-Fixture.coordinates(take[10].t)[2])<0.02 and absf(take[10].x[5]-Fixture.coordinates(take[10].t)[5])<0.02)
	press(study,3);press(study,1)
	check("teaching class locked throughout capture",study.capturing and study.selected=="ONE")
	study.advance_phrase(0.2,Fixture.coordinates(0),true)
	check("long frame discards entire pending take",not study.capturing and study.pending.is_empty() and study.one.examples.size()==1)
	press(study,3)
	trackers[0].invalidate_pose(&"default");await process_frame;study._process(0.05)
	check("lost hand discards entire performance",not study.capturing and study.one.examples.size()==1)
	study.one=fitted
	press(study,6);var frozen:Dictionary=fitted.snapshot()
	perform(study,Fixture.take(11))
	check("fresh ONE TEST never fits or actuates",study.result.accepted and fitted.snapshot()==frozen and study.replay_time<0 and not study.rods[0].visible)
	study.mode="TRY";perform(study,Fixture.take(12))
	check("accepted ONE TRY starts learned replay",study.result.accepted and study.replay_time==0)
	study.replay_time=1;study.draw_phrase()
	var x:Array=fitted.target(1)
	var midpoint:Vector3=(study.miniature(x,0)+study.miniature(x,1))*0.5
	check("same point follows actual learned midpoint, both paths are visible",study.sphere.get_instance_id()==sphere_id and study.sphere.position.distance_to(midpoint)<0.00001 and study.rods[0].visible and study.rods[40].visible and study.tips[0].visible and study.tips[1].visible)
	perform(study,Fixture.take(12,true))
	check("reversal cannot trigger the ONE response",not study.result.accepted and study.replay_time<0)
	var tests_before_preview:int=fitted.tests.size()
	press(study,8)
	check("REPLAY is explicitly a preview and creates no test",study.message.begins_with("PREVIEW") and study.replay_time==0 and fitted.tests.size()==tests_before_preview)
	var one_before:Dictionary=study.one.snapshot()
	press(study,1)
	for v in 3:perform(study,Fixture.take(v))
	press(study,2)
	for v in 3:perform(study,Fixture.take(v,true))
	press(study,5)
	check("native A/B teaching and TRAIN fit both without replacing ONE",study.library.trained and study.one.snapshot()==one_before and study.mode=="TEST")
	var library_before:Dictionary=study.library.snapshot()
	press(study,6);perform(study,Fixture.take(11))
	check("TEST identifies A while B is selected, with no replay or fitting",study.selected=="B" and study.result.label=="A" and study.replay_time<0 and study.library.snapshot()==library_before)
	study.mode="TRY";perform(study,Fixture.take(11))
	check("TRY selects the predicted prototype, not selected teaching target",study.result.label=="A" and study.replay_model==study.library.models.A and study.replay_time==0)
	perform(study,offset_take(1))
	check("UNKNOWN withholds sphere action",study.result.label=="UNKNOWN" and study.replay_time<0)
	study.library=ambiguous_library()
	perform(study,offset_take(0.02))
	check("AMBIGUOUS withholds sphere action separately",study.result.label=="AMBIGUOUS" and study.replay_time<0)
	press(study,0)
	check("return to ONE preserves learned phrase and original point",study.one.snapshot()==one_before and study.sphere.get_instance_id()==sphere_id)
	study.capturing=true;study.pending=[{"t":0,"x":Fixture.coordinates(0)}]
	press(study,13)
	check("STOP discards partial recording without replacing learning",not study.capturing and study.pending.is_empty() and study.one.snapshot()==one_before)
	check("phrase work never mutates carried pose model",study.model.snapshot()==carried)
	for tr in trackers:XRServer.remove_tracker(tr)
	XRServer.remove_tracker(head);origin.queue_free();study.queue_free()
	await process_frame

func same_data(a:Variant,b:Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int): return absf(float(a)-float(b))<1e-10
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i in a.size():
			if not same_data(a[i],b[i]): return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for k in a:
			if not b.has(k) or not same_data(a[k],b[k]): return false
		return true
	return a==b
func taught(swapped:bool=false) -> RefCounted:
	var lib:=Library.new()
	for v in 3:
		lib.add_example("A",Fixture.take(v,swapped))
		lib.add_example("B",Fixture.take(v,not swapped))
	lib.fit();return lib
func offset_take(amount:float,variation:int=11) -> Array:
	var take:=Fixture.take(variation)
	for row:Dictionary in take: row.x[1]+=amount;row.x[4]+=amount
	return take
func ambiguous_library() -> RefCounted:
	var lib:=Library.new()
	for v in 3:
		lib.add_example("A",offset_take(0.0,v))
		lib.add_example("B",offset_take(0.04,v))
	lib.fit();return lib
func library_checks() -> void:
	var lib:=Library.new()
	check("empty library has no built-in labels or predictions",not lib.trained and lib.predict(Fixture.take()).is_empty())
	check("unknown training label is refused",not lib.add_example("C",Fixture.take()))
	for v in 3:lib.add_example("A",Fixture.take(v))
	check("one trained class cannot classify",not lib.fit() and not lib.trained and lib.predict(Fixture.take()).is_empty())
	for v in 2:lib.add_example("B",Fixture.take(v,true))
	check("both classes need three whole examples",not lib.fit())
	lib.add_example("B",Fixture.take(2,true))
	check("both timed prototypes fit",lib.fit() and lib.trained)
	var before:Dictionary=lib.snapshot()
	var a:Dictionary=lib.test_example(Fixture.take(11))
	var b:Dictionary=lib.test_example(Fixture.take(12,true))
	check("fresh A recognised independently of teaching data",a.label=="A" and a.accepted)
	check("reversed ordered path taught as B is recognised",b.label=="B" and b.accepted)
	var negative:Dictionary=lib.test_example(offset_take(1.0))
	check("unfamiliar complete performance becomes UNKNOWN",negative.label=="UNKNOWN" and not negative.accepted)
	var still:=Fixture.take(11)
	for row:Dictionary in still:
		for j in range(3,6):row.x[j]=still[0].x[j]
	check("one matching hand cannot carry a stationary other hand",lib.predict(still).label=="UNKNOWN")
	check("incomplete performance produces no classification",lib.test_example(Fixture.take().slice(0,20)).is_empty() and lib.tests.size()==3)
	check("testing changes no examples or fitted parameters",lib.snapshot()==before)
	a.clear()
	check("returned result cannot mutate evaluation evidence",lib.tests[0].label=="A")
	var expected_score:float=maxf(b.candidates.B.rms[0]/lib.models.B.limits[0],b.candidates.B.rms[1]/lib.models.B.limits[1])
	check("score is worst per-hand normalised distance",absf(b.scores[1]-expected_score)<1e-10)
	var swapped:=taught(true)
	check("swapping teaching labels swaps decisions",swapped.predict(Fixture.take(11)).label=="B" and swapped.predict(Fixture.take(12,true)).label=="A")
	var overlap:=ambiguous_library()
	var doubtful:Dictionary=overlap.predict(offset_take(0.02))
	check("similar taught phrases withhold an ambiguous choice",doubtful.label=="AMBIGUOUS" and not doubtful.accepted and doubtful.candidates.A.accepted and doubtful.candidates.B.accepted)
	var distinct:=Library.new()
	for v in 3:
		distinct.add_example("A",offset_take(0.0,v));distinct.add_example("B",offset_take(0.10,v))
	distinct.fit()
	var nearer:Dictionary=distinct.predict(offset_take(0.0))
	check("overlapping acceptance still allows clearly nearer prototype",nearer.label=="A" and nearer.candidates.A.accepted and nearer.candidates.B.accepted and nearer.margin>=Library.MARGIN)
	evidence={"fresh_A":lib.tests[0],"fresh_B":b,"unknown":negative,"ambiguous":doubtful,"nearer":nearer,"scope":"Whole synthetic fixture performances; not human recognition accuracy"}
	var path:="user://ada_phrase_library_test_fixture.json"
	var copy:=Library.new()
	check("real file roundtrip restores both labelled sets within JSON numeric precision",lib.save_file(path)==OK and copy.load_file(path) and same_data(copy.snapshot(),before))
	check("reload starts fresh tests and keeps decisions",copy.tests.is_empty() and copy.predict(Fixture.take(11)).label=="A" and copy.predict(Fixture.take(12,true)).label=="B")
	var invalid:=before.duplicate(true);invalid.B.prototype[2][1]+=0.5
	var loaded_before:Dictionary=copy.snapshot()
	check("corrupt second model cannot partially replace library",not copy.restore(invalid) and copy.snapshot()==loaded_before)
	invalid=before.duplicate(true);invalid.margin=0
	check("saved data cannot silently change ambiguity policy",not copy.restore(invalid))
	check("adding a new take invalidates joint recognition",copy.add_example("A",Fixture.take(5)) and not copy.trained and copy.predict(Fixture.take()).is_empty())
	check("other label examples survive revision",copy.models.B.examples.size()==3)
	check("undo removes selected whole take and clears evaluation",copy.undo("A") and copy.models.A.examples.size()==3 and copy.tests.is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

