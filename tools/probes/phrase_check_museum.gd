extends "res://tools/probes/transformation_encounters.gd"
const Fixture:=preload("res://tools/probes/movement_fixture.gd")
func offset_take(shift:float,variation:int) -> Array:
	var take:=Fixture.take(variation)
	for row:Dictionary in take:row.x[1]+=shift;row.x[4]+=shift
	return take
func perform(lesson:RefCounted,intent:String,take:Array) -> void:
	lesson.command("EXPECT_"+intent)
	lesson.capturing=true;lesson.clock=-0.05;lesson.pending.clear();lesson.sample_clock=0
	for row:Dictionary in take:lesson.advance_capture(0.05,row.x,true)
	lesson.message="SYNTHETIC REHEARSAL / "+lesson.message
	lesson.refresh();lesson.draw()
func shot(name:String,station:Node3D) -> void:
	await snapshot(name,station.to_global(Vector3(0.30,1.70,3.2)),station.to_global(Vector3(0.25,1.40,0)),50)
func landing_checks() -> void:
	var stage:=find_scene("/vogue_timeline.gd")
	check("actual museum has the carried dance station",stage!=null)
	if stage==null:return
	stage.set_process(false);stage.render_pose(8.0)
	stage.status.text="DANCE / REFERENCE PATHS";stage.detail.text="Teach the sphere; investigate its decisions"
	var station=stage.get_node("PoseLearningStation");station.set_process(false)
	var sphere_id:int=station.sphere.get_instance_id()
	station.command("PHRASE");station.command("A")
	var lesson=station.movement_lesson
	for v in 3:lesson.library.add_example("A",Fixture.take(v));lesson.library.add_example("B",Fixture.take(v,true))
	station.command("TRAIN");station.command("CHECK")
	check("CHECK opens in real museum after both prototypes fit",lesson.check_lesson.active)
	for offset in [Vector3(0,0,0.9),Vector3(-0.5,0,1.15),Vector3(0.5,0,1.15)]:
		check("standing floor "+str(offset),not floor_at(station.to_global(offset)).is_empty())
	await snapshot("museum",stage.to_global(Vector3(1,2.3,3.5)),stage.to_global(Vector3(-0.4,1.35,-0.45)),70)
	await shot("empty",station)
	var frozen:Dictionary=lesson.library.snapshot()
	perform(lesson,"A",Fixture.take(11))
	perform(lesson,"B",Fixture.take(12,true))
	perform(lesson,"A",Fixture.take(13,true))
	perform(lesson,"OTHER",offset_take(1.0,14))
	perform(lesson,"OTHER",Fixture.take(15))
	perform(lesson,"B",offset_take(1.0,16))
	var ui=lesson.check_lesson
	check("actual table separates six declared intentions and outcomes",ui.totals.matrix==[[1,1,0,0],[0,1,1,0],[1,0,1,0]])
	check("counts never change learned paths or activate the sphere",lesson.library.snapshot()==frozen and lesson.replay_time<0 and station.sphere.get_instance_id()==sphere_id)
	check("twelve count cells and footer visible without beat overlap",ui.cells.size()==12 and ui.cells[4].visible and ui.footer.visible and not lesson.beat_caption.visible)
	await shot("six-checks",station)
	station.command("BACK");lesson.library.add_example("A",offset_take(0.08,21));station.command("TRAIN");station.command("CHECK")
	check("changed model begins fresh counts while earlier evidence remains",ui.totals.total==0 and ui.totals.previous==6)
	lesson.message="SYNTHETIC REHEARSAL / revised demonstrations\nNew model: test again. Six earlier checks remain."
	lesson.refresh();lesson.draw();await shot("retrained",station)
	perform(lesson,"A",Fixture.take(22))
	check("fresh revised-model check stays separate",ui.totals.total==1 and ui.totals.previous==6)
	await shot("new-check",station)
	station.command("POSE")
	check("leaving check restores shared station and same sphere",not ui.active and ui.labels.is_empty() and station.metrics.visible and station.sphere.get_instance_id()==sphere_id)
	observations.scope="Actual Godot museum. Synthetic labelled performances deliberately include disagreements. No visitor files touched; not human accuracy."
	observations.counts=[[1,1,0,0],[0,1,1,0],[1,0,1,0]]
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
