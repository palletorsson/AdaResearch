extends "res://tools/probes/transformation_encounters.gd"

func press(panel: Node,index: int) -> void:
	var area: Node = panel.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	area.button_pressed.emit(area)

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var after: bool = spec.get("after",false)
	if map_id=="CA_Introduction":
		var work := find_scene("/ca_rule_explorer.gd")
		var study := find_scene("/neighbour_study.gd")
		var stand := find_scene("/synthesis_stand.gd")
		var runner := find_scene("/grid_substrate_runner.gd")
		check("rule explorer and study loaded",work!=null and study!=null)
		check("stand retains its sphere subject",stand!=null and stand.subject=="dark_sphere")
		if work==null or study==null: return
		if after:check("inactive runner placement removed",runner==null)
		else:
			check("runner present before change",runner!=null)
			var target: Node = root.find_child("GridMultiMesh",true,false)
			observations["runner"]={"target_present":target!=null,"children":runner.get_child_count() if runner else -1,"meshes":runner.find_children("*","GeometryInstance3D",true,false).size() if runner else -1}
			check("museum contains no runner target",target==null)
		check("body-sized ring retained",study.room_ring!=null)
		check("two distinct control panels retained",work._control_panel!=null and study.get_node_or_null("StudyControls")!=null)
		press(work._control_panel,1)
		check("90 button selects Rule 90",work.rule==90)
		var answers: Array=[]
		for n in range(7,-1,-1):answers.append(int(work._apply_rule(bool(n&4),bool(n&2),bool(n&1))))
		check("all eight Rule 90 answers",answers==[0,1,0,1,1,0,1,0])
		observations["rule90_answers_111_to_000"]=answers
		press(work._control_panel,4)
		check("RST returns to generation zero",work.neighbourhood_readback().generation==0)
		press(study.get_node("StudyControls"),0)
		check("STEP produces a held generation",work.neighbourhood_readback().generation==1 and not work.neighbourhood_readback().running)
		press(work._control_panel,0)
		check("30 button selects Rule 30",work.rule==30)
		press(work._control_panel,1)
		for i in range(10):press(study.get_node("StudyControls"),0)
		await snapshot("board-and-rule-panels",work.to_global(Vector3(0,0.85,2.5)),work.to_global(Vector3(0,-0.03,0)),72)
		var ring: Node3D = study.room_ring
		await snapshot("inside-history-ring",ring.to_global(Vector3(0,1.65,0)),ring.to_global(Vector3(1.8,3.2,-0.8)),95)
		var texts: Array=[]
		for n in stand.find_children("*","Label3D",true,false):texts.append(n.text)
		observations["stand_labels"]=texts
		observations["stand_meshes"]=stand.find_children("*","GeometryInstance3D",true,false).size()
	else:
		var lab := find_scene("/lab_room.gd")
		var apparatus := find_scene("/turing_apparatus.gd")
		check("lab and mounted apparatus remain",lab!=null and apparatus!=null)
		if lab==null:return
		var actual: Array=[]
		for n in lab.find_children("*","Label3D",true,false):
			if n.name in ["SignageTop","SignageSub","AnnotationEast","AnnotationWest"]:actual.append({"name":str(n.name),"text":n.text})
		observations["lab_labels"]=actual
		if after:
			check("lab title asks what counts as computation",lab.signage_top=="WHAT COUNTS AS COMPUTATION?")
			check("subtitle names the present model",lab.signage_sub=="A tape, a head, a set of states")
			check("crowded annotations are disabled",not lab.show_wall_annotations and lab.get_node_or_null("WallAnnotations")==null)
			check("question is placed on the rear wall",lab.signage_wall=="back")
			check("title is below the exit light",is_equal_approx(lab.get_node("Signage").position.y,lab.room_height*.62-.55))
			var default_lab: Node3D = load("res://commons/artifacts/lab_room/lab_room.gd").new()
			check("other labs retain their default sign height",is_zero_approx(default_lab.signage_height_offset))
			default_lab.free()
			check("title and subtitle are actually built",actual.size()==2 and actual.any(func(d):return d.text==lab.signage_top) and actual.any(func(d):return d.text==lab.signage_sub))
			check("old unsupported claim absent from rendered signs",actual.all(func(d):return "Turing complete" not in d.text and "universal computation" not in d.text))
		await snapshot("lab-sign",lab.to_global(Vector3(0,1.65,2.3)),lab.to_global(Vector3(0,2.0,-3.3)),83)
		if after: await snapshot("lab-question",lab.to_global(Vector3(0,1.65,-1.1)),lab.to_global(Vector3(0,2.1,3.2)),80)
		await snapshot("lab-annotation",lab.to_global(Vector3(-1.4,1.65,1.8)),lab.to_global(Vector3(3.7,1.5,0)),78)
		var origin: Vector3=hall.global_position+Vector3(0,0,4)
		await snapshot("history-and-rear-gallery",origin+Vector3(12.7,1.65,18.0),origin+Vector3(9.0,1.8,26.0),85)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Current isolated museum, supplied control signals and cameras; no headset or performance acceptance."},"  "))
	print("CA OPENING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
