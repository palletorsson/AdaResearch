extends "res://tools/probes/transformation_encounters.gd"
const Fixture:=preload("res://tools/probes/movement_fixture.gd")
func landing_checks() -> void:
	var stage:=find_scene("/vogue_timeline.gd")
	check("real Perception hall contains carried dance",stage!=null)
	if stage==null:return
	stage.set_process(false);stage.render_pose(8.0)
	stage.status.text="DANCE / REFERENCE PATHS"
	stage.detail.text="The same sphere can learn a short two-hand phrase"
	var station=stage.get_node_or_null("PoseLearningStation")
	check("same learning station exists in museum",station!=null)
	if station==null:return
	station.set_process(false)
	var sphere_id:int=station.sphere.get_instance_id()
	station.command("PHRASE")
	var lesson=station.movement_lesson
	check("phrase station starts empty",lesson.model.examples.is_empty() and not lesson.model.trained)
	for offset in [Vector3(0,0,0.9),Vector3(-0.5,0,1.15),Vector3(0.5,0,1.15)]:
		check("standing floor "+str(offset),not floor_at(station.to_global(offset)).is_empty())
	await snapshot("museum",stage.to_global(Vector3(1.0,2.3,3.5)),stage.to_global(Vector3(-0.4,1.35,-0.45)),70)
	await snapshot("empty",station.to_global(Vector3(0.30,1.7,3.2)),station.to_global(Vector3(0.25,1.44,0)),50)
	for variation in 3:lesson.model.add_example(Fixture.take(variation))
	check("actual museum model fits complete demonstrations",lesson.model.fit())
	lesson.mode="TRY";lesson.result=lesson.model.test_example(Fixture.take(11))
	check("fresh synthetic performance recognised in museum",lesson.result.accepted)
	for phase in [1.0,3.0]:
		lesson.replay_time=phase
		lesson.message="SYNTHETIC REHEARSAL / fresh take matched\nBoth learned paths; the SAME sphere responds."
		lesson.refresh();lesson.draw()
		check("both hand paths drawn at %.1f"%phase,lesson.paths[0].visible and lesson.paths[40].visible and station.sphere.get_instance_id()==sphere_id)
		await snapshot("phrase-%d"%int(phase),station.to_global(Vector3(0.30,1.7,3.2)),station.to_global(Vector3(0.25,1.44,0)),50)
	lesson.replay_time=-1;lesson.result=lesson.model.test_example(Fixture.take(11,true))
	lesson.message="SYNTHETIC REHEARSAL / order reversed\nNOT THIS PHRASE / sphere waits."
	lesson.refresh();lesson.draw()
	check("reversal withheld in museum",not lesson.result.accepted and lesson.replay_time<0)
	await snapshot("reversed",station.to_global(Vector3(0.30,1.7,3.2)),station.to_global(Vector3(0.25,1.44,0)),50)
	station.command("POSE")
	check("pose lesson returns with same object",station.lesson=="POSE" and station.sphere.get_instance_id()==sphere_id)
	observations.scope="Actual museum captures with explicitly labelled synthetic teaching and test performances. No visitor files touched, no human accuracy claim."
	observations.fit_mse=lesson.model.fit_error
	observations.limits=lesson.model.limits.duplicate()
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
