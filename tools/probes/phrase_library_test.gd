extends SceneTree
const Library:=preload("res://commons/artifacts/vogue_timeline/phrase_library.gd")
const Fixture:=preload("res://tools/probes/movement_fixture.gd")
const FOLDER:="res://doc/book/iterations/2026-10-11-teach-a-sphere-two-phrases/"
var checks:Array=[]
var failures:Array=[]
var evidence:Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(label:String,passed:bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failures.append(label)
	print("PHRASE ","PASS " if passed else "FAIL ",label)
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
func run() -> void:
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
	await scene_checks()
	FileAccess.open(FOLDER+"tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence},"  "))
	quit(0 if failures.is_empty() else 1)
func press(station:Node3D,index:int) -> void:
	var button=station.controls.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
func perform(lesson:RefCounted,take:Array) -> void:
	lesson.capturing=true;lesson.clock=-0.05;lesson.pending.clear();lesson.sample_clock=0;lesson.replay_time=-1
	for row:Dictionary in take:lesson.advance_capture(0.05,row.x,true)
	lesson.refresh();lesson.draw()
func scene_checks() -> void:
	var stage=load("res://commons/artifacts/vogue_timeline/vogue_timeline.tscn").instantiate()
	root.add_child(stage);await process_frame;stage.set_process(false)
	var station=stage.get_node("PoseLearningStation");station.set_process(false)
	station.model.add_example([0,0,0,1,0,0],0);station.height_lesson.model.add_example(0,0.5)
	var pose_before:Dictionary=station.model.snapshot();var height_before:Dictionary=station.height_lesson.model.snapshot()
	var sphere_id:int=station.sphere.get_instance_id()
	station.command("PHRASE")
	var lesson=station.movement_lesson
	for v in 3:lesson.model.add_example(Fixture.take(v))
	lesson.model.fit()
	var one_before:Dictionary=lesson.model.snapshot()
	press(station,15)
	check("native A button opens separate empty teaching class",lesson.two_phrases and lesson.selected=="A" and lesson.model.examples.is_empty() and lesson.mode=="TEACH")
	for v in 3:perform(lesson,Fixture.take(v))
	press(station,16)
	check("native B button keeps A and switches teaching target",lesson.selected=="B" and lesson.library.models.A.examples.size()==3 and lesson.model.examples.is_empty())
	for v in 3:perform(lesson,Fixture.take(v,true))
	press(station,4)
	check("native TRAIN fits both captured whole performances",lesson.library.trained and lesson.mode=="TEST")
	var frozen:Dictionary=lesson.library.snapshot()
	# B is selected, but inference must identify A without being told the answer.
	press(station,2);perform(lesson,Fixture.take(11))
	check("TEST recognises A despite B selected and never replays",lesson.result.label=="A" and lesson.replay_time<0 and lesson.library.snapshot()==frozen)
	lesson.mode="TRY";perform(lesson,Fixture.take(12,true))
	check("TRY selects recognised B prototype without preselection",lesson.result.label=="B" and lesson.selected=="B" and lesson.model==lesson.library.models.B and lesson.replay_time==0)
	lesson.replay_time=1.0;lesson.draw()
	var row:Array=lesson.library.models.B.target(1.0)
	var expected:Vector3=(lesson.mini_position(row,0)+lesson.mini_position(row,1))*0.5
	check("same sphere replays the classified path",station.sphere.get_instance_id()==sphere_id and station.sphere.position.distance_to(expected)<0.0001 and station.response_label.text.contains("B REPLAY"))
	perform(lesson,offset_take(1.0))
	check("UNKNOWN leaves original sphere waiting",lesson.result.label=="UNKNOWN" and lesson.replay_time<0 and station.response_label.text.contains("WAITING"))
	var original:RefCounted=lesson.library
	lesson.library=ambiguous_library();lesson.selected="A";lesson.model=lesson.library.models.A
	perform(lesson,offset_take(0.02))
	check("AMBIGUOUS cannot trigger sphere response",lesson.result.label=="AMBIGUOUS" and lesson.replay_time<0 and lesson.message.contains("Too close"))
	lesson.library=original;lesson.model=original.models[lesson.selected]
	press(station,5)
	check("manual replay remains explicitly a preview",lesson.message.begins_with("PREVIEW") and lesson.replay_time==0)
	press(station,14)
	check("ONE restores exact earlier single-phrase model",not lesson.two_phrases and lesson.model.snapshot()==one_before)
	press(station,15)
	station.command("HEIGHT");station.command("PHRASE")
	check("lesson changes retain both sets and same sphere",lesson.library.snapshot()==frozen and lesson.two_phrases and lesson.mode=="TEST" and station.sphere.get_instance_id()==sphere_id)
	press(station,10)
	check("first RESET press preserves both sets",lesson.library.trained)
	press(station,10)
	check("confirmed reset clears A + B only",not lesson.library.trained and lesson.library.models.A.examples.is_empty() and lesson.library.models.B.examples.is_empty() and lesson.single_model.snapshot()==one_before)
	check("pose and height teaching remain untouched",station.model.snapshot()==pose_before and station.height_lesson.model.snapshot()==height_before)
	stage.queue_free();await process_frame
