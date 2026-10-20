extends "res://tools/probes/transformation_encounters.gd"
const Fixture:=preload("res://tools/probes/movement_fixture.gd")
const Library:=preload("res://commons/artifacts/vogue_timeline/phrase_library.gd")
func offset_take(amount:float,variation:int=11) -> Array:
	var take:=Fixture.take(variation)
	for row:Dictionary in take:row.x[1]+=amount;row.x[4]+=amount
	return take
func perform(lesson:RefCounted,take:Array) -> void:
	lesson.mode="TRY";lesson.capturing=true;lesson.clock=-0.05;lesson.pending.clear();lesson.sample_clock=0;lesson.replay_time=-1
	for row:Dictionary in take:lesson.advance_capture(0.05,row.x,true)
	lesson.message="SYNTHETIC REHEARSAL / "+lesson.message
	lesson.refresh();lesson.draw()
func shot(name:String,station:Node3D) -> void:
	await snapshot(name,station.to_global(Vector3(0.30,1.70,3.2)),station.to_global(Vector3(0.25,1.40,0)),50)
func landing_checks() -> void:
	var stage:=find_scene("/vogue_timeline.gd")
	check("real Perception museum contains the carried dance",stage!=null)
	if stage==null:return
	stage.set_process(false);stage.render_pose(8.0)
	stage.status.text="DANCE / REFERENCE PATHS"
	stage.detail.text="Teach the same sphere two phrases of your own"
	var station=stage.get_node("PoseLearningStation");station.set_process(false)
	var sphere_id:int=station.sphere.get_instance_id()
	station.command("PHRASE");station.command("A")
	var lesson=station.movement_lesson
	check("both label sets arrive empty",lesson.library.models.A.examples.is_empty() and lesson.library.models.B.examples.is_empty())
	for offset in [Vector3(0,0,0.9),Vector3(-0.5,0,1.15),Vector3(0.5,0,1.15)]:
		check("standing floor "+str(offset),not floor_at(station.to_global(offset)).is_empty())
	await snapshot("museum",stage.to_global(Vector3(1.0,2.3,3.5)),stage.to_global(Vector3(-0.4,1.35,-0.45)),70)
	await shot("empty",station)
	for v in 3:
		lesson.library.add_example("A",Fixture.take(v));lesson.library.add_example("B",Fixture.take(v,true))
	station.command("TRAIN")
	check("both prototypes fit inside actual museum",lesson.library.trained)
	var unchanged:Dictionary=lesson.library.snapshot()
	for label in ["A","B"]:
		perform(lesson,Fixture.take(11,label=="B"))
		check("museum fresh performance selects "+label,lesson.result.label==label and lesson.replay_time==0)
		lesson.replay_time=1.0;lesson.refresh();lesson.draw()
		check("same sphere responds to "+label,station.sphere.get_instance_id()==sphere_id and lesson.paths[0].visible and lesson.paths[40].visible)
		await shot("phrase-"+label.to_lower(),station)
	perform(lesson,offset_take(1.0))
	check("unfamiliar performance stays unknown",lesson.result.label=="UNKNOWN" and lesson.replay_time<0)
	await shot("unknown",station)
	check("all recognition leaves examples and fitted paths fixed",lesson.library.snapshot()==unchanged)
	lesson.library=Library.new()
	for v in 3:
		lesson.library.add_example("A",offset_take(0.0,v));lesson.library.add_example("B",offset_take(0.04,v))
	lesson.library.fit();lesson.selected="A";lesson.model=lesson.library.models.A
	perform(lesson,offset_take(0.02))
	check("overlapping examples produce AMBIGUOUS without replay",lesson.result.label=="AMBIGUOUS" and lesson.replay_time<0)
	await shot("ambiguous",station)
	station.command("ONE")
	check("single phrase remains empty and separate",lesson.model.examples.is_empty() and not lesson.two_phrases)
	station.command("POSE")
	check("other lessons return on original sphere",station.sphere.get_instance_id()==sphere_id and stage.hand_space.visible)
	observations.scope="Real Godot museum, synthetic whole teaching and test takes. No visitor data saved. No human accuracy claim."
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
