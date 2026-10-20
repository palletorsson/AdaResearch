extends SceneTree
var checks: Array = []
var failed: Array = []
var results: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failed.append(label)
	print("[geometry noise] ", "PASS " if passed else "FAIL ", label)
func near(a: float,b: float) -> bool: return absf(a-b)<0.000002
func run() -> void:
	var core=load("res://commons/artifacts/geometry_noise/surface_sample.gd").new()
	var base: PackedVector3Array=core.base.duplicate()
	var indices: PackedInt32Array=core.indices.duplicate()
	var noise: PackedVector3Array=core.unit_noise.duplicate()
	check("289 unique logical vertices / 512 triangles",base.size()==289 and indices.size()==1536)
	check("Plane corners and spacing are in metres",base[0]==Vector3(-1,0,-1) and base[288]==Vector3(1,0,1) and near(base[1].x-base[0].x,.125))
	var edge_counts: Dictionary={};var valid:=true
	for i in range(0,indices.size(),3):
		var a:=indices[i];var b:=indices[i+1];var c:=indices[i+2]
		valid=valid and a>=0 and c<289 and a!=b and b!=c and a!=c
		valid=valid and (base[c]-base[a]).cross(base[b]-base[a]).y>0
		for pair in [Vector2i(a,b),Vector2i(b,c),Vector2i(c,a)]:
			var key:=Vector2i(mini(pair.x,pair.y),maxi(pair.x,pair.y))
			edge_counts[key]=int(edge_counts.get(key,0))+1
	check("Clockwise nondegenerate triangles and valid indices",valid)
	check("64 boundary edges; all interior edges have two faces",edge_counts.values().count(1)==64 and edge_counts.values().all(func(v):return v==1 or v==2))
	var zero: Dictionary=core.evaluate(0)
	check("Zero strength restores exact coordinates and zero metrics",zero.positions==base and zero.rms_m==0 and zero.maximum_m==0 and zero.centroid_drift_m==0)
	var opening: Dictionary=core.evaluate(.18)
	check("Default per-axis sigma 4.5cm; population RMS sqrt(3)*sigma",near(opening.sigma_m,.045) and near(opening.population_rms_m,sqrt(3)*.045))
	# Independent observation from stored points, not the implementation's metrics.
	var sums:=0.0;var largest:=0.0;var average:=Vector3.ZERO
	for i in 289:
		var delta:Vector3=opening.positions[i]-base[i]
		sums+=delta.dot(delta);largest=maxf(largest,delta.length());average+=delta/289.0
	check("Readouts agree with independent vertex measurement",near(opening.rms_m,sqrt(sums/289)) and near(opening.maximum_m,largest) and near(opening.centroid_drift_m,average.length()))
	var twice: Dictionary=core.evaluate(.36)
	check("Fixed-sample strength doubles RMS / maximum / centroid",near(twice.rms_m,2*opening.rms_m) and near(twice.maximum_m,2*opening.maximum_m) and near(twice.centroid_drift_m,2*opening.centroid_drift_m))
	check("Strength changes consume no RNG and preserve baseline",core.unit_noise==noise and core.base==base and core.indices==indices and core.evaluate(.18).positions==opening.positions)
	core.resample(1848)
	check("New seed changes finite sample but not zero baseline",core.evaluate(.18).positions!=opening.positions and core.evaluate(0).positions==base)
	core.resample(1847)
	check("Seed1847 replays exactly on this engine build",core.unit_noise==noise and core.evaluate(.18).positions==opening.positions)
	var max_sample: Dictionary=core.evaluate(1)
	var mesh: ArrayMesh=core.mesh_for(max_sample.positions)
	var arr:=mesh.surface_get_arrays(0)
	check("Rendered mesh has indexed289 vertices,1536 indices",arr[Mesh.ARRAY_VERTEX].size()==289 and arr[Mesh.ARRAY_INDEX]==indices)
	check("Normal recomputation finite and unit length",arr[Mesh.ARRAY_NORMAL].size()==289 and Array(arr[Mesh.ARRAY_NORMAL]).all(func(n):return n.is_finite() and absf(n.length()-1)<.0001))
	var flat: Array=core.mesh_for(base).surface_get_arrays(0)
	check("Undeformed normals face upward (packed-mesh tolerance)",Array(flat[Mesh.ARRAY_NORMAL]).all(func(n):return n.distance_to(Vector3.UP)<.0001))
	check("Finite amplitude bounds and invalid input fallback",core.evaluate(-1).strength==0 and core.evaluate(10).strength==1 and core.evaluate(NAN).positions==base)
	# Existing global stream must be unaffected by this local generator.
	seed(723);var expected:=randf();seed(723);core.resample(50)
	check("Resampling never reseeds or consumes global RNG",randf()==expected)
	core.resample(1847)
	results.default={"rms_m":opening.rms_m,"maximum_m":opening.maximum_m,"centroid_drift_m":opening.centroid_drift_m,"sigma_m":opening.sigma_m,"population_rms_m":opening.population_rms_m}
	# Load after autoload initialization, not as a typed XR dependency in this probe.
	var art=load("res://commons/artifacts/geometry_noise/GeometryNoiseTest.tscn").instantiate()
	var holder:=Node3D.new();root.add_child(holder);holder.add_child(art)
	await process_frame;await physics_frame;await process_frame
	check("Artifact creates both surfaces and own controls",art.reference.mesh!=null and art.perturbed.mesh!=null and art.buttons.size()==4 and art.slider!=null)
	check("Both surfaces share exactly one material",art.reference.material_override==art.perturbed.material_override)
	check("Perturbed and reference surfaces have no collision children",art.reference.find_children("*","CollisionObject3D",true,false).is_empty() and art.perturbed.find_children("*","CollisionObject3D",true,false).is_empty())
	var original_reference: ArrayMesh=art.reference.mesh
	art.slider.set_normalized_value(.36);art.slider.slider_moved.emit(Vector3.ZERO)
	check("Canonical slider signal scales saved sample",near(art.measurements.rms_m,2*opening.rms_m))
	art.buttons["NEXT SEED"].pressed.emit()
	check("Canonical NEXT SEED action changes sample",art.experiment_seed==1848)
	art.buttons["ZERO"].pressed.emit()
	check("Canonical ZERO clears deviation keeping seed",art.normalized_strength==0 and art.experiment_seed==1848 and art.measurements.rms_m==0)
	art.buttons["RESET"].pressed.emit()
	check("RESET restores exact initial sample and control",art.measurements.positions==opening.positions and near(art.slider.get_normalized_value(),.18))
	art.buttons["EDGES"].pressed.emit()
	check("EDGES changes only overlay visibility",not art.changed_edges.visible and not art.reference_edges.visible and art.measurements.positions==opening.positions)
	var count:int=art.rebuild_count
	for i in 10:await process_frame
	check("No mesh regeneration on idle frames",art.rebuild_count==count)
	art.set_noise_strength(INF);art.set_noise_strength(NAN)
	check("Invalid parameter is rejected without changing current experiment",art.rebuild_count==count and art.measurements.positions==opening.positions)
	for i in 70:art.set_noise_strength(float(i%2))
	check("History bounded and original reference mesh unchanged",art.log_entries.size()==64 and art.reference.mesh==original_reference and art.sample.base==base)
	art.reset_experiment()
	check("Independent variation half strength halves displacement",near(art.sample.evaluate(.09).rms_m,.5*opening.rms_m))
	results.rebuild_usec=art.last_rebuild_usec
	results.engine=Engine.get_version_info()
	results.scope="Native core and scene assertions, supplied control signals. Not tracked VR or actual desktop pointer."
	holder.queue_free();await process_frame
	var out:=OS.get_cmdline_user_args()[0]
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failures":failed,"observations":results},"  "))
	quit(0 if failed.is_empty() else 1)
