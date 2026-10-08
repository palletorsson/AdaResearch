extends SceneTree
var failures:Array[String]=[]
var reports:Array=[]
var checks:=0

func _initialize()->void:call_deferred("run")

func require(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);push_error(message)

func run()->void:
	var manifest:Array=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/more_early/manifest.json"))
	for entry:Dictionary in manifest:
		var packed:PackedScene=load(entry.scene)
		require(packed!=null,entry.id+" loads")
		if packed==null:continue
		seed(134815);var expected:=randi();seed(134815)
		var stage:Node3D=packed.instantiate();root.add_child(stage)
		require(randi()==expected,entry.id+" preserves global random state on construction")
		await process_frame
		if stage.get("phases")==null:
			require(false,entry.id+" script initializes");stage.free();continue
		require(stage.phases.size()==4,entry.id+" has four phases")
		for phase in range(4):
			for u in [.001,.5,.999]:
				seed(134815);stage.playhead=(phase+u)*stage.duration/4.0;stage.refresh()
				require(randi()==expected,entry.id+" frame preserves global random stream")
				var info:=inspect(stage.display)
				require(info.finite and info.nodes<2000 and info.meshes>0,entry.id+" finite bounded geometry phase %d"%phase)
				if entry.id=="body_aperture":
					for i in stage.slats.size():
						require(stage.slats[i].transform.is_equal_approx(stage.source._slats[i].transform),"Each wall copy retains actual source hinge target")
		var camera_before:Transform3D=stage.camera.transform
		stage.next_route();stage.refresh()
		require(not stage.camera.transform.is_equal_approx(camera_before),entry.id+" turn view survives redraw")
		require(stage.validation().passed,entry.id+" source validation")
		match str(entry.id):
			"cube_corner":
				stage.playhead=stage.duration*.98;stage.refresh()
				var src:Node3D=stage.source
				require(src.vertices[6].is_equal_approx(stage.initial[6]+Vector3(0,0,.55)),"Cube corner moves exact source displacement")
				require(src.vertices[5]==stage.initial[5] and src.vertices[7]==stage.initial[7],"Cube diagonal endpoints stay fixed")
				for i in 12:
					var a:Array=src.triangle_meshes[i].mesh.surface_get_arrays(0)
					require(a[Mesh.ARRAY_VERTEX].size()==6,"Cube uses the source's doubled triangle mesh")
			"door_routes":
				require(stage.paths[0].back().is_equal_approx(stage.paths[1].back()),"Door destinations match")
				require(stage.paths[0][1]==Vector3(0,.25,0),"Lift is the first source leg")
				for p in range(4):
					stage.playhead=(float(p)+.999)*6.0;stage.refresh()
					var left:Vector3=(stage.doors[0].position-stage.origins[0])/stage.MAG
					var right:Vector3=(stage.doors[1].position-stage.origins[1])/stage.MAG
					require(left.is_equal_approx(Vector3.ZERO if p==0 else Vector3(.5,.25,0)),"Ordered door phase %d endpoint follows source plan"%p)
					require(right.is_equal_approx(Vector3.ZERO if p<2 else Vector3(.5,.25,0)),"Free door phase %d endpoint follows source plan"%p)
			"scale_children":
				stage.playhead=1;stage.refresh();var before:Transform3D=stage.witness_copy.transform
				stage.playhead=15;stage.refresh()
				require(stage.room_copy.scale==Vector3.ONE*4 and stage.witness_copy.transform.is_equal_approx(before),"Scale inherits through room only")
			"body_aperture":
				stage.playhead=1;stage.refresh();require(stage.evidence.current_max_target==0,"Wall is closed outside source reach")
				stage.playhead=11.5;stage.refresh();require(stage.evidence.current_max_target>.99,"Wall clearance core fully opens near visitor")
				stage.playhead=23.99;stage.refresh();require(stage.evidence.current_max_target==0,"Wall closes after visitor leaves")
			"gradient_paths":
				require(stage.colours[0][0]==Color.RED and stage.colours[0][-1]==Color.CYAN,"Gradient retains exact endpoints")
				require(stage.colours[1][8].g>.95 and stage.colours[0][8].g<.6,"HSV and RGB intermediate colours genuinely differ")
			"rainbow_partitions":
				for i in 4:
					require(stage.groups[i].get_child_count()==stage.counts[i],"Rainbow group matches authored count")
					var first:MeshInstance3D=stage.groups[i].get_child(0)
					require(first.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==130,"Rainbow retains source's 65 vertex pairs")
			"disco_phase":
				var src:Node3D=stage.source
				for phase in [0,7,8,63,64,71]:
					src.phase=phase;var active:=0
					for z in 8:
						for x in 8:active+=src.value_at(x,z,8,8)
					require(active==8,"Disco phase %d keeps eight active cells"%phase)
		reports.append({"id":entry.id,"evidence":stage.evidence})
		stage.free();await process_frame
	var out:="res://ada_run/spine_films_more_early/"
	DirAccess.make_dir_recursive_absolute(out)
	var file:=FileAccess.open(out+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"films":reports},"\t"));file.close()
	print("MORE EARLY: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func inspect(node:Node)->Dictionary:
	var out:Dictionary={"nodes":1,"meshes":0,"finite":true}
	if node is Node3D:out.finite=node.transform.origin.is_finite() and node.transform.basis.x.is_finite() and node.transform.basis.y.is_finite() and node.transform.basis.z.is_finite() and node.position.length()<100
	if node is MeshInstance3D:
		out.meshes=1;out.finite=out.finite and node.get_aabb().position.is_finite() and node.get_aabb().size.is_finite()
	for child in node.get_children():
		var data:=inspect(child);out.nodes+=data.nodes;out.meshes+=data.meshes;out.finite=out.finite and data.finite
	return out
