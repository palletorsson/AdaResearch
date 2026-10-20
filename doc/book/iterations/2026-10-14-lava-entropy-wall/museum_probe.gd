extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	var wall := find_scene("/lava_entropy_wall.gd")
	check("lava wall installed in Random_Definition",wall != null)
	if wall == null: return
	check("existing seed bench retained",find_scene("/seed_replay_demo.gd") != null)
	check("48-value first pilot retained",find_scene("/museum_seed_study.gd") != null)
	check("journey retained",find_scene("/random_return.gd") != null)
	wall.running = false
	wall.reset_model()
	observations["position"] = xyz(wall.global_position)
	observations["rotation"] = xyz(wall.rotation_degrees)
	var approach := wall.to_global(Vector3(0,0.02,1.65))
	var hit := floor_at(approach)
	check("control approach has floor",not hit.is_empty())
	var button: Node3D = wall._board.find_child("Btn_2",true,false)
	check("controls are reachable",button.global_position.y-wall.global_position.y>0.85 and button.global_position.y-wall.global_position.y<1.55)
	var area: Node = button.get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	check("actual interaction event changes heat",wall.current.heat==110 and wall.current.tick==wall.baseline.tick)
	check("visible sensor image changes",wall.current.sha256!=wall.baseline.sha256)
	check("48 output bars on both comparison cards",wall._bars[0].size()==48 and wall._bars[1].size()==48)
	wall.record_directory = "res://ada_run/lava_entropy_wall_museum_probe"
	check("museum keep succeeds",wall.keep_current())
	var expected: String = wall.current.sha256
	wall.reset_model()
	check("museum load restores comparison",wall.load_latest() and wall.current.sha256==expected and wall.current.heat!=wall.baseline.heat)
	observations["baseline_hash"] = wall.baseline.sha256
	observations["changed_hash"] = wall.current.sha256
	observations["receipt"] = wall.save_path
	await snapshot("lava-wall",wall.to_global(Vector3(0,2.1,4.6)),wall.to_global(Vector3(0,1.72,0)),51)
	await snapshot("lava-controls",wall.to_global(Vector3(0.0,1.70,2.25)),wall.to_global(Vector3(0,1.22,0.4)),64)
	wall.toggle_run()
	var before: int = wall.frame
	await create_timer(1.2).timeout
	check("lamps animate after replay",wall.frame>before)
	check("animation does not mutate kept capture",wall.kept.sha256==expected)
	wall.running=false
	observations["limitations"] = ["Automated pointer events and rendered desktop views; headset reach and comfort not tested.","No automatic transfer to seed bench or another hall; records are local to this artifact."]
