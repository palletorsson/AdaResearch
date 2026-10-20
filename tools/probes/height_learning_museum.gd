extends "res://tools/probes/transformation_encounters.gd"
const Learner := preload("res://commons/artifacts/vogue_timeline/height_learner.gd")
func landing_checks() -> void:
	var stage := find_scene("/vogue_timeline.gd")
	check("actual Perception hall contains dance",stage!=null)
	if stage==null: return
	stage.set_process(false);stage.render_pose(8.0)
	stage.status.text="DANCE / REFERENCE PATHS"
	stage.detail.text="Teach the same sphere: a category, then an amount"
	var station=stage.get_node_or_null("PoseLearningStation")
	check("learning station exists in museum",station!=null)
	if station==null: return
	station.set_process(false)
	var sphere_id:int=station.sphere.get_instance_id()
	station.command("HEIGHT")
	var lesson=station.height_lesson
	check("height mode arrives empty",lesson.model.examples.is_empty() and not lesson.model.trained)
	for offset in [Vector3(0,0,0.9),Vector3(-0.5,0,1.15),Vector3(0.5,0,1.15)]:
		check("standing floor "+str(offset),not floor_at(station.to_global(offset)).is_empty())
	await snapshot("museum",stage.to_global(Vector3(1.0,2.3,3.5)),stage.to_global(Vector3(-0.4,1.35,-0.45)),70)
	await snapshot("empty",station.to_global(Vector3(0.25,1.7,3.1)),station.to_global(Vector3(0.15,1.40,0)),50)
	for x in [-1.0,-0.75,-0.5,-0.25,0.0,0.25,0.5]: lesson.model.add_example(x,0.25+0.5*(x+1.0))
	lesson.model.begin_training()
	for i in Learner.EPOCHS: lesson.model.train_epoch()
	lesson.mode="LIVE"
	for pair in [["low",-0.9],["high",0.4]]:
		lesson.input=pair[1];lesson.prediction=lesson.model.predict(pair[1])
		lesson.message="SYNTHETIC REHEARSAL / real fitted line\nIn VR, supply your own hand-height pairs."
		lesson.refresh();lesson.animate(0.0)
		check("same sphere follows fitted height "+pair[0],station.sphere.get_instance_id()==sphere_id and absf(station.sphere.position.y-(0.95+lesson.prediction.value))<0.001)
		await snapshot(pair[0],station.to_global(Vector3(0.25,1.7,3.1)),station.to_global(Vector3(0.15,1.40,0)),50)
	lesson.model=Learner.new()
	for x in [-1.0,-0.75,-0.5,-0.25,0.0,0.25,0.5]: lesson.model.add_example(x,1.0-(0.25+0.5*(x+1.0)))
	lesson.model.begin_training()
	for i in Learner.EPOCHS: lesson.model.train_epoch()
	lesson.input=0.4;lesson.prediction=lesson.model.predict(0.4)
	lesson.message="SYNTHETIC REHEARSAL / reversed examples\nHands rise; the same sphere descends."
	lesson.refresh();lesson.animate(0.0)
	check("reversed pairs reverse actual museum response",station.sphere.position.y<1.1)
	await snapshot("reverse",station.to_global(Vector3(0.25,1.7,3.1)),station.to_global(Vector3(0.15,1.40,0)),50)
	station.command("POSE")
	check("original pose lesson still empty and available",station.lesson=="POSE" and station.model.examples.is_empty() and station.sphere.get_instance_id()==sphere_id)
	observations.scope="Actual museum; empty arrival plus synthetic regression rehearsals. Visitor files untouched. No human/headset performance claim."
	observations.training_mse=lesson.model.loss()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
