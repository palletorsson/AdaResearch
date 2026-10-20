extends "res://tools/probes/transformation_encounters.gd"
## Read-only shots of installed encounters; no material or physics substitutions.

func comparison(kind: int) -> Node3D:
	for node in hall.find_children("*","Node3D",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/ordinary_entropies/comparison.gd") and node.kind==kind:return node
	return null

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.call("flush_stamps");await create_timer(0.5).timeout
	if map_id=="Random_Entropies":await types_views()
	else:await workshop_views()
	observations["scope"]="Installed desktop renderer, supplied camera viewpoints. No claim about headset comfort, human recognition, reader response or literary necessity."

func types_views() -> void:
	var glass=comparison(5)
	check("five installed frosted-chair versions",glass!=null and glass.versions.size()==5)
	if glass!=null:
		var records: Array=[]
		for i in glass.versions.size():
			var version=glass.versions[i]
			var pane=version.visuals.get_node("GlassPane")
			records.append({"version":"ABCDE"[i],"obscurity":version.glass_obscurity,"record_channel":version.setting,"chair_identity":version.selected,"material":pane.material_override.get_class(),"viewpoint":xyz(version.to_global(Vector3(0,1.55,2.8)))})
			await snapshot("glass-"+"ABCDE"[i],version.to_global(Vector3(0,1.55,2.8)),version.to_global(Vector3(0,0.83,0.6)),48)
		observations["glass_versions"]=records
		var version=glass.versions[3]
		await snapshot("glass-D-oblique",version.to_global(Vector3(1.1,1.55,2.8)),version.to_global(Vector3(0,0.83,0.6)),48)
	var guesses=find_scene("/ordinary_entropies/one_guess.gd")
	check("three-type chair table installed",guesses!=null and guesses.versions.size()==4)
	if guesses!=null:
		var table=guesses.versions[1]
		await snapshot("chair-types",table.to_global(Vector3(0,1.50,1.8)),table.to_global(Vector3(0,0.87,0)),65)
	var cups=comparison(4)
	check("five cooling cups installed",cups!=null and cups.versions.size()==5)
	if cups!=null:
		await snapshot("coffee-approach",cups.to_global(Vector3(0,1.65,2.3)),cups.to_global(Vector3(0,0.85,0.22)),83)
	var doors=find_scene("/ordinary_entropies/door_study.gd")
	check("door study installed",doors!=null)
	if doors!=null:await snapshot("doors-approach",doors.to_global(Vector3(0,1.65,6.8)),doors.to_global(Vector3(0,1.15,0)),95)

func workshop_views() -> void:
	var cabinet=find_scene("/entropy_compartments/entropy_compartments.gd")
	check("compartment cabinet installed",cabinet!=null)
	if cabinet!=null:
		await snapshot("cabinet-front",cabinet.to_global(Vector3(0,1.65,3.0)),cabinet.to_global(Vector3(0,1.0,0)),65)
		await snapshot("cabinet-oblique",cabinet.to_global(Vector3(1.7,1.65,2.8)),cabinet.to_global(Vector3(0,1.0,0)),65)
	var points=find_scene("/entropy_axiom/entropy_axiom_multimesh.gd")
	check("point enclosure installed",points!=null)
	if points!=null:
		observations["points_transform"]=str(points.global_transform)
		await snapshot("points-aligned",points.to_global(Vector3(0,1.65,-4.3)),points.to_global(Vector3(0,1.65,2)),75)
		await snapshot("points-offset",points.to_global(Vector3(1,1.65,-4.3)),points.to_global(Vector3(1,1.65,2)),75)
