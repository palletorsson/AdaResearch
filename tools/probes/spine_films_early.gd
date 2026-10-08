extends SceneTree
var failures:Array[String]=[]
var reports:Array=[]
var checks:=0

func _initialize()->void:call_deferred("run")

func require(condition:bool,message:String)->void:
	checks+=1
	if not condition:failures.append(message);push_error(message)

func run()->void:
	var manifest:Array=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/early/manifest.json"))
	for entry:Dictionary in manifest:
		var packed:PackedScene=load(entry.scene)
		require(packed!=null,entry.id+" scene loads")
		if packed==null:continue
		seed(73931)
		var expected_random:=randi()
		seed(73931)
		var stage:Node3D=packed.instantiate()
		root.add_child(stage)
		require(randi()==expected_random,entry.id+" construction preserves global RNG")
		await process_frame
		require(stage.get("phases").size()==4,entry.id+" has four phases")
		require(stage.get("duration")>=20 and stage.get("duration")<=30,entry.id+" has bounded duration")
		require(not stage.get("evidence").is_empty(),entry.id+" has source evidence")
		var records:Array=[]
		for phase in range(4):
			for fraction in [0.001,0.5,0.999]:
				var t:float=(phase+fraction)*float(stage.get("duration"))/4.0
				seed(73931)
				stage.set("playhead",t);stage.call("refresh")
				require(randi()==expected_random,entry.id+" playback preserves global RNG")
				var stats:Dictionary=inspect(stage.get("display"))
				require(stats.finite,entry.id+" finite phase %d at %.3f"%[phase,fraction])
				require(stats.nodes<2500,entry.id+" bounded node count")
				require(stats.meshes>0,entry.id+" has geometry")
				records.append({"time":t,"nodes":stats.nodes,"meshes":stats.meshes,"visible":stats.visible})
		var e:Dictionary=stage.get("evidence")
		match str(entry.id):
			"transformation_order":require(e.different_outcomes,"transforms do not commute")
			"array_address":
				require(e.sites==64 and e.frames==256,"array counts match source")
				require(e.addresses.size()==64,"array preserves addresses")
			"tiling_rule":require(e.get("rule_before",-1)==0 and e.get("rule_after",-1)==2,"tiling uses single -> quarter-turn rule")
			"colour_edge":require(not e.get("volumetric_fog",true),"colour film does not claim fog")
			"pattern_symmetry":require(e.changed_output_cells>1 and e.changed_output_cells<400,"single motif edit propagates selectively")
			"directional_slope":require(e.opposite_signs,"source partial slopes oppose")
			"force_motion":require(e.cancelled.length()<0.00001,"opposing actual forces cancel")
			"form_relaxation":
				require(e.particles==48 and e.cached_states==81,"bench has exact particle and step counts")
				require(e.start!=e.finish,"source solver actually relaxes")
			"wave_neighbours":
				require(e.neighbours.size()==8,"source includes eight neighbours")
				require(e.coupled_neighbor_peak>0.01 and e.independent_neighbor_peak==0.0,"coupling alone transmits pulse")
		reports.append({"id":entry.id,"evidence":e,"frames":records})
		root.remove_child(stage);stage.free()
		await process_frame
	var report:Dictionary={"checks":checks,"failures":failures,"films":reports,"pass":failures.is_empty()}
	DirAccess.make_dir_recursive_absolute("res://ada_run/spine_films_early")
	var f:=FileAccess.open("res://ada_run/spine_films_early/report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	print("EARLY FILMS: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func inspect(n:Node)->Dictionary:
	var result:Dictionary={"nodes":1,"meshes":0,"visible":0,"finite":true}
	if n is Node3D:
		result.finite=n.transform.origin.is_finite() and n.transform.basis.x.is_finite() and n.transform.basis.y.is_finite() and n.transform.basis.z.is_finite()
		result.finite=result.finite and n.position.length()<100
	if n is MeshInstance3D or n is MultiMeshInstance3D:
		result.meshes=1;result.visible=1 if n.is_visible_in_tree() else 0
		if n is MultiMeshInstance3D:
			for i in range(n.multimesh.instance_count):
				var t:Transform3D=n.multimesh.get_instance_transform(i)
				result.finite=result.finite and t.origin.is_finite() and t.basis.x.is_finite() and t.basis.y.is_finite() and t.basis.z.is_finite()
	for child in n.get_children():
		var r:Dictionary=inspect(child)
		result.nodes+=r.nodes;result.meshes+=r.meshes;result.visible+=r.visible;result.finite=result.finite and r.finite
	return result
