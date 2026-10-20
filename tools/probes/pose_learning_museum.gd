extends "res://tools/probes/transformation_encounters.gd"
const Learner := preload("res://commons/artifacts/vogue_timeline/pose_learner.gd")
const CENTRES := [
	[-0.60,0.15,-0.45,0.60,0.15,-0.45],
	[-0.22,0.85,-0.40,0.22,0.85,-0.40],
	[-0.25,-0.65,-0.75,0.25,-0.65,-0.75]]
func landing_checks() -> void:
	var stage := find_scene("/vogue_timeline.gd")
	check("real Perception hall includes dance",stage!=null)
	if stage==null:return
	stage.set_process(false)
	stage.render_pose(8.0)
	stage.status.text="DANCE / REFERENCE PATHS"
	stage.detail.text="Next to the dance: teach your own pose classifier"
	var station=stage.get_node_or_null("PoseLearningStation")
	check("real museum includes trainable station",station!=null)
	if station==null:return
	station.set_process(false)
	check("station starts empty and untrained in museum",station.model.examples.is_empty() and not station.model.trained)
	for offset in [Vector3(0,0,0.9),Vector3(-0.5,0,1.15),Vector3(0.5,0,1.15)]:
		check("station standing position has museum floor "+str(offset),not floor_at(station.to_global(offset)).is_empty())
	await snapshot("museum",stage.to_global(Vector3(1.0,2.3,3.5)),stage.to_global(Vector3(-0.4,1.35,-0.45)),70)
	await snapshot("teach-empty",station.to_global(Vector3(0,1.7,2.8)),station.to_global(Vector3(0,1.44,0)),50)
	for label in 3:
		for take in 5:
			var x:Array=CENTRES[label].duplicate()
			for i in 6:x[i]+=sin(float(take*7+i*3))*0.045
			station.model.add_example(x,label)
	station.model.initialize(417)
	for _i in Learner.EPOCHS:station.model.train_epoch()
	station.mode="LIVE"
	for label in 3:
		for i in 8:station.observe(0.05,CENTRES[label],true)
		station.clock=1.0
		station.animate_response()
		station.message="SYNTHETIC REHEARSAL / real trained weights\nIn VR, record your own poses."
		station._refresh()
		check("learned museum response %d" % label,station.response==label)
		await snapshot("learned-%s" % ["a","b","c"][label],station.to_global(Vector3(0.2,1.7,2.8)),station.to_global(Vector3(0,1.44,0)),50)
	observations.training_loss=station.model.loss()
	observations.station_world=xyz(station.global_position)
	observations.scope="Empty museum station plus clearly labelled synthetic classifier rehearsal. No user data, no saved user file."

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
