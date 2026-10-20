extends "res://tools/probes/transformation_encounters.gd"
## Real hall and production artifact. Screenshots use the clearly labelled guide.
func landing_checks() -> void:
	var stage := find_scene("/vogue_timeline.gd")
	check("new dance artifact loads from museum registry and placement",stage != null)
	check("existing perception artifact retained",find_scene("/ComputerVision_VR.gd") != null or hall.find_children("*Vision*","Node3D",true,false).size()>0)
	if stage == null: return
	stage.set_process(false)
	stage.preview_only=true
	stage.render_pose(2.0)
	stage.status.text="FRAME / LIFT / GUIDE PREVIEW"
	stage.detail.text="32 beats / next eight shown\nFollow both hands through the air"
	observations["stage_world"]=xyz(stage.global_position)
	check("artifact uses metres, no museum scaling",stage.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	for offset in [Vector3(0,0,0.6),Vector3(-1,0,0.6),Vector3(1,0,0.6),Vector3(0,0,1.9)]:
		var hit:=floor_at(stage.to_global(offset))
		check("dance area has support "+str(offset),not hit.is_empty())
	await snapshot("museum-wide",stage.to_global(Vector3(2.4,3.5,3.0)),stage.to_global(Vector3(-0.2,1.1,-1.3)),76)
	await snapshot("dance-timeline",stage.to_global(Vector3(0,1.65,2.8)),stage.to_global(Vector3(0,1.4,-2)),68)
	await snapshot("airborne-hands",stage.to_global(Vector3(1.5,2.0,1.8)),stage.to_global(Vector3(0,1.65,-0.15)),55)
	stage.render_pose(8.0);stage.status.text="SWEEP / OPEN / GUIDE PREVIEW"
	await snapshot("open-phrase",stage.to_global(Vector3(2.6,2.0,1.3)),stage.to_global(Vector3(-0.1,1.5,-2.3)),72)
	await snapshot("nearby-controls",stage.to_global(Vector3(0,1.65,2.2)),stage.to_global(Vector3(0,1.05,1.15)),52)
	for part in 4:
		stage.render_pose(float(part)*8.0)
		stage.status.text=stage.phrase.section_name(float(part)*8.0)+" / GUIDE PREVIEW"
		await snapshot("phrase-%d" % (part+1),stage.to_global(Vector3(0.7,2.0,2.3)),stage.to_global(Vector3(0,1.6,-0.2)),58)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual museum artifact placement, floor raycasts and rendered guide preview. No human or headset dance test."},"  "))
	quit(0 if failures.is_empty() else 1)
