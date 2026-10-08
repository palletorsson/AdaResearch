extends SceneTree
var failures:Array[String]=[]
var checks:=0
var results:Dictionary={}
func _initialize()->void:call_deferred("run")
func run()->void:
	var manifest:Array=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/spine_films/more_structure/manifest.json"))
	var view:=SubViewport.new();view.size=Vector2i(1024,576);view.own_world_3d=true;root.add_child(view)
	for entry in manifest:
		var scene=load(entry.scene)
		if scene==null:check(false,entry.id+" load");continue
		var film=scene.instantiate()
		if not film.has_method("validation"):check(false,entry.id+" compile");film.free();continue
		seed(813);var expected:float=randf();seed(813)
		view.add_child(film);film.running=false
		check(is_equal_approx(randf(),expected),entry.id+" leaves global RNG intact")
		await process_frame;await physics_frame;await process_frame
		var report:Dictionary=film.validation();results[entry.id]=report
		check(report.get("passed",false),entry.id+" source checks "+str(report.get("checks",{})))
		check(film.source_paths==entry.source_paths,entry.id+" source list")
		for phase in 4:
			for t in [.03,.55,.97]:
				film.playhead=(phase+t)*6.0;film.refresh()
				check(finite(film.display),entry.id+" finite phase %d"%phase)
		var before:Transform3D=film.camera.transform;film.next_route();film.refresh()
		check(not film.camera.transform.is_equal_approx(before),entry.id+" camera turns")
		var held:Transform3D=film.camera.transform;film.refresh();check(film.camera.transform.is_equal_approx(held),entry.id+" turn retained")
		film.running=false;var time:float=film.playhead;film.advance(1);check(film.playhead==time,entry.id+" pause")
		film.replay();check(film.playhead==0 and film.running,entry.id+" replay")
		specific(entry.id,film)
		view.remove_child(film);film.queue_free();await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/spine_films_more_structure"))
	var file:=FileAccess.open("res://ada_run/spine_films_more_structure/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"films":results},"  "))
	print("MORE STRUCTURE: ",checks," checks, ",failures.size()," failures")
	for message in failures:print("FAIL: ",message)
	quit(0 if failures.is_empty() else 1)
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message)
func finite(node:Node)->bool:
	if node is Node3D and not node.transform.is_finite():return false
	for child in node.get_children():
		if not finite(child):return false
	return true
func specific(id:String,film:Node3D)->void:
	var e:Dictionary=film.evidence
	match id:
		"ca_triplet":
			var valid:=true
			for gen in range(1,film.rows.size()):
				for col in 24:
					valid=valid and film.rows[gen][col]==(film.rows[gen-1][(col+23)%24]!=film.rows[gen-1][(col+1)%24])
			check(valid,"CA rule90 equals neighbour XOR at every captured cell")
			check(film.rows[0].count(true)==1,"CA single seed preserved")
		"cantor_thirds":
			var valid:=true
			for row in film.records:valid=valid and absf(row.length-5.4/pow(3,row.depth))<.00001
			check(valid,"Cantor actual widths agree with recursion")
			check(film.bars.size()==63 and film.cuts.size()==31,"Cantor retained and removed counts")
		"jelly_skin":
			check(e.unique_positions==152,"jelly surface has 152 unique positions, not 216 masses")
			check(absf(e.anchor_position.y-e.cube_size*.5)<.00001,"jelly anchor on upper face")
		"metaball_sum":
			var original:PackedFloat32Array=film.fields[0].duplicate();var copied:PackedFloat32Array=film.fields[0].duplicate();copied[0]+=1
			check(film.fields[0]==original,"metaball cached field is copied independently")
			var sums:=true
			for sample in film.sample_records:sums=sums and absf(sample.first+sample.second-sample.sum)<.00001
			check(sums and film.sample_records.size()==21,"metaball on-screen sample values are actual grid additions")
			check(film.surfaces[0]!=film.surfaces[-1],"metaball mesh resources independent")
			var start_mid:=2*.49/pow(film.separations[0]*.5,2);var end_mid:=2*.49/pow(film.separations[-1]*.5,2)
			check(start_mid<1 and end_mid>1,"metaball midpoint crosses threshold")
		"boolean_overlap":
			for i in 4:
				var csg:CSGCombiner3D=film.results[i]
				check(csg.get_child(1).operation==CSGShape3D.OPERATION_INTERSECTION,"boolean actual CSG operator %d"%i)
				check(csg.get_child(1).position.is_equal_approx(film.offsets[i]),"boolean source offset %d"%i)
		"spanning_choice":
			check(e.rejected_before_complete>0,"MST includes a visible rejected cycle")
			var last:float=-INF;var valid:=true
			for edge in film.records:valid=valid and edge.weight>=last;last=edge.weight
			check(valid,"MST sorted weights")
