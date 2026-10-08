extends SceneTree
## Independent geometry, sampling and actual pointer-control checks for the research bench.
const Motion = preload("res://commons/artifacts/transformation_sampling/motion.gd")
const SCENE := "res://commons/artifacts/transformation_sampling/transformation_sampling.tscn"
const SCRIPT := "res://commons/artifacts/transformation_sampling/transformation_sampling.gd"
const MOTION_SCRIPT := "res://commons/artifacts/transformation_sampling/motion.gd"
const OUT := "res://doc/space/transformation-sampling-2026-09-17/test-results.json"
var checks: Array = []
var failures: Array[String] = []
var observations: Dictionary = {}
var world: Node3D
var bench: Node3D
var pointer: Camera3D
var buttons: Array[Node3D] = []
var hashes: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(title: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"name":title,"passed":passed,"detail":detail})
	if not passed: failures.append(title)
	print("[sampling-test] ","PASS " if passed else "FAIL ",title," ",str(detail) if detail != null else "")
func tick() -> void:
	await physics_frame
	await process_frame
func xyz(v: Vector3) -> Array: return [v.x,v.y,v.z]
func close(a: float,b: float,tolerance: float = 0.00001) -> bool: return absf(a-b)<tolerance
func moved(points: PackedVector3Array, pose: Transform3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in points: out.append(pose*p)
	return out
func set_distance(a: PackedVector3Array,b: PackedVector3Array) -> float:
	var maximum := 0.0
	for p in a:
		var nearest := INF
		for q in b: nearest=minf(nearest,p.distance_to(q))
		maximum=maxf(maximum,nearest)
	return maximum
func centroid(points: PackedVector3Array) -> Vector3:
	var mean := Vector3.ZERO
	for p in points: mean+=p
	return mean/points.size()
func lengths(points: PackedVector3Array) -> Array[float]:
	var out: Array[float] = []
	for i in points.size():
		for j in range(i+1,points.size()):out.append(points[i].distance_to(points[j]))
	return out
func area(points: PackedVector3Array) -> float: return (points[1]-points[0]).cross(points[2]-points[0]).length()*0.5
func volume(points: PackedVector3Array) -> float: return absf((points[1]-points[0]).dot((points[2]-points[0]).cross(points[3]-points[0])))/6.0
func edge_error(original: PackedVector3Array,transformed: PackedVector3Array,ratio: float) -> float:
	var first:=lengths(original)
	var second:=lengths(transformed)
	var error:=0.0
	for i in first.size():error=maxf(error,absf(second[i]/first[i]-ratio))
	return error

func mathematical_contract() -> void:
	var cube := Motion.cube_points()
	var asymmetric := Motion.asymmetric_points()
	var quarter := Motion.pose("rotate",1.0)
	var rotated := moved(cube,quarter)
	check("cube quarter-turn preserves its unlabelled vertex set",set_distance(rotated,cube)<0.00001,set_distance(rotated,cube))
	check("that same quarter-turn moves an indexed corner by one edge length",close(cube[0].distance_to(rotated[0]),0.55),cube[0].distance_to(rotated[0]))
	check("eighth-turn does not preserve the cube vertex set",set_distance(moved(cube,Motion.pose("rotate",0.5)),cube)>0.1)
	check("asymmetric body differs after quarter-turn",set_distance(moved(asymmetric,quarter),asymmetric)>0.2)
	check("full turn returns every indexed vertex",set_distance(moved(asymmetric,Motion.pose("rotate",4.0)),asymmetric)<0.00001)
	var marker := Motion.mark_point("sphere")
	check("sphere material mark reveals rotation despite radial symmetry",marker.distance_to(quarter*marker)>0.3,marker.distance_to(quarter*marker))
	var max_radius_error:=0.0
	for k in 31:
		var direction:=Vector3(sin(k*1.7),cos(k*0.61),sin(k*0.83+0.4)).normalized()*0.32
		max_radius_error=maxf(max_radius_error,absf((Motion.pose("rotate",k*0.173)*direction).length()-0.32))
	check("rotation preserves radial distance for an ideal sphere",max_radius_error<0.00001,max_radius_error)
	check("asymmetric volume matches independent tetrahedron calculation",close(volume(asymmetric),0.68*0.53*0.7/6.0),volume(asymmetric))
	var measurements: Array = []
	for time in [0.0,0.25,1.0,2.0,3.0,4.0]:
		var t: float = time
		var translated:=moved(asymmetric,Motion.pose("translate",t))
		var turned:=moved(asymmetric,Motion.pose("rotate",t))
		check("rigid operations preserve all six distances at %.2fs"%t,edge_error(asymmetric,translated,1.0)<0.00001 and edge_error(asymmetric,turned,1.0)<0.00001)
		check("rigid operations preserve area and volume at %.2fs"%t,close(area(translated),area(asymmetric)) and close(area(turned),area(asymmetric)) and close(volume(translated),volume(asymmetric)) and close(volume(turned),volume(asymmetric)))
		var scale_factor:=1.0+0.3*sin(TAU*t/4.0)
		var scaled:=moved(asymmetric,Motion.pose("scale",t))
		var combined:=moved(asymmetric,Motion.pose("combine",t))
		var ar:=area(scaled)/area(asymmetric)
		var vr:=volume(scaled)/volume(asymmetric)
		check("uniform scale has length s, area s², volume s³ at %.2fs"%t,edge_error(asymmetric,scaled,scale_factor)<0.00001 and close(ar,scale_factor*scale_factor) and close(vr,pow(scale_factor,3)),{"s":scale_factor,"area_ratio":ar,"volume_ratio":vr})
		check("combined rigid motion retains those scaled distances at %.2fs"%t,edge_error(asymmetric,combined,scale_factor)<0.00001 and close(volume(combined)/volume(asymmetric),pow(scale_factor,3)))
		measurements.append({"time":t,"scale":scale_factor,"scaled_area_ratio":ar,"scaled_volume_ratio":vr})
	var at_quarter: Transform3D=Motion.pose("combine",1.0)
	var point:=Vector3(1,0,0)
	# Godot's positive Y quarter-turn maps +X to -Z. T*R*S gives (.6,0,-1.3).
	var expected:=Vector3(0.6,0,-1.3)
	var actual:=at_quarter*point
	var reversed:=Basis(Vector3.UP,PI*0.5)*(point*1.3+Vector3(0.6,0,0))
	check("combined pose applies scale, then rotate, then translate",actual.distance_to(expected)<0.00001,{"actual":xyz(actual),"expected":xyz(expected)})
	check("moving translation before rotation changes the result",actual.distance_to(reversed)>0.8,{"TRS":xyz(actual),"RTS":xyz(reversed)})
	var r:=Basis(Vector3.UP,0.73)
	check("uniform scale and rotation about the same origin commute",((r*(point*1.3))-(r*point)*1.3).length()<0.00001)
	var period_error:=0.0
	for mode in Motion.MODES:
		for time in [0.0,0.23,1.3,3.91]:
			period_error=maxf(period_error,set_distance(moved(asymmetric,Motion.pose(mode,time)),moved(asymmetric,Motion.pose(mode,time+4.0))))
	check("all four scores close continuously after four seconds",period_error<0.00001,period_error)
	observations["scale_measurements"]=measurements
	observations["ideal_sphere_limit"]="Radial distance is an analytic invariance test. The displayed SphereMesh is finite triangulation, so exact arbitrary-angle mesh symmetry is not claimed."

func sampling_contract() -> void:
	for test in [[-1.0,1.0,0.0],[0.0,1.0,0.0],[0.999999,1.0,0.0],[1.0,1.0,1.0],[1.000001,1.0,1.0],[3.999999,1.0,3.0],[4.0,1.0,4.0],[0.999999,1.0/3.0,2.0/3.0],[1.0,1.0/3.0,1.0],[4.0,1.0/3.0,4.0]]:
		var actual: float=Motion.sample_time(test[0],test[1])
		check("sample boundary t=%.6f interval=%.6f"%[test[0],test[1]],close(actual,test[2],0.0000001),{"actual":actual,"expected":test[2]})
	var monotonic:=true
	var no_future:=true
	for interval in [1.0/12.0,1.0/3.0,1.0,4.0,8.0]:
		var previous:=-1.0
		for k in 801:
			var time:=k*0.017
			var sampled:float=Motion.sample_time(time,interval)
			monotonic=monotonic and sampled>=previous
			no_future=no_future and sampled<=time+0.00000001 and time-sampled<interval+0.00000001
			previous=sampled
	check("4005 sampled times are monotonic and never jump into the future",monotonic and no_future)
	check("nonpositive low-level intervals remain finite",is_finite(Motion.sample_time(0.5,0.0)) and is_finite(Motion.sample_time(0.5,-1.0)))

func press(index: int) -> void:
	var area: Node3D=buttons[index].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	await tick()

func poses(which: String) -> Array:
	var out: Array=[]
	for station in bench.stations: out.append(station[which].transform)
	return out
func same_poses(a: Array,b: Array) -> bool:
	for i in a.size():
		if not (a[i] as Transform3D).is_equal_approx(b[i]):return false
	return true
func all_different(a: Array,b: Array) -> bool:
	for i in a.size():
		if (a[i] as Transform3D).is_equal_approx(b[i]):return false
	return true
func frame_poses() -> Array:
	var result: Array=[]
	for station in bench.stations:
		for frame in station.frames:result.append(frame.global_transform)
	return result
func bodies() -> Array:
	var result: Array=[]
	for station in bench.stations:
		result.append(station.live)
		result.append(station.sample)
		result.append_array(station.frames)
	return result

func build_contract() -> void:
	check("four operations each have live, sampled and twelve fixed bodies",bench.stations.size()==4 and bodies().size()==56)
	for child in bench.get_children():
		if child is Node3D and child.has_signal("pressed"):buttons.append(child)
	check("five real controls are present",buttons.size()==5)
	if buttons.size()!=5:return
	bench.seek(0.1)
	bench.set_interval(1.0)
	var first_live:=poses("live")
	var first_sample:=poses("sample")
	var fixed:=frame_poses()
	bench.seek(0.8)
	check("live bodies change between sample instants",all_different(first_live,poses("live")))
	check("held samples remain fixed between sample instants",same_poses(first_sample,poses("sample")))
	bench.seek(1.0)
	check("sample boundary catches the exact displayed live pose",same_poses(poses("live"),poses("sample")))
	check("all twelve frames per station remain fixed after seeking",same_poses(fixed,frame_poses()))
	bench.set_interval(4.0)
	bench.seek(0.1)
	var frozen:=poses("sample")
	var live_before:=poses("live")
	bench.seek(0.8)
	check("four-second sampling freezes all sampled modes while live modes differ",same_poses(frozen,poses("sample")) and all_different(live_before,poses("live")))
	bench.seek(4.2)
	check("next four-second sample still aliases the initial pose",same_poses(frozen,poses("sample")))
	bench.seek(0.0)
	await press(3)
	var started:=Time.get_ticks_msec()
	var clock_before:float=bench.elapsed
	var actual_before:=poses("live")
	await create_timer(0.4).timeout
	var clock_delta:float=bench.elapsed-clock_before
	var wall_delta:float=(Time.get_ticks_msec()-started)/1000.0
	check("PLAY advances elapsed time and actual live geometry",bench.playing and clock_delta>0.25 and all_different(actual_before,poses("live")),{"elapsed_advance":clock_delta,"wall_seconds":wall_delta})
	check("live elapsed clock follows real elapsed time",absf(clock_delta-wall_delta)<0.12)
	check("fixed frames stay fixed during actual animation",same_poses(fixed,frame_poses()))
	await press(3)
	var paused_clock:float=bench.elapsed
	var paused_pose:=poses("live")
	await create_timer(0.2).timeout
	check("PAUSE freezes clock and actual geometry",not bench.playing and close(bench.elapsed,paused_clock) and same_poses(paused_pose,poses("live")))
	await press(4)
	check("RESET returns the clock to zero while paused",close(bench.elapsed,0.0) and not bench.playing)
	bench.set_interval(1.0)
	await press(2)
	check("interval control selects four-second sampling",close(bench.interval,4.0))
	await press(2)
	check("interval control cycles to twelve samples per cycle",close(bench.interval,1.0/3.0))
	await press(2)
	check("interval control returns to quarter-turn sampling",close(bench.interval,1.0))
	bench.set_interval(0.0)
	check("interval API bounds nonpositive input",close(bench.interval,1.0/12.0))
	bench.set_interval(99.0)
	check("interval API bounds excessive input",close(bench.interval,8.0))
	bench.set_interval(1.0)
	check("markers begin hidden",bodies().all(func(body):return not body.get_node("WitnessMark").visible))
	await press(1)
	check("ADD MARK reveals marks on all 56 bodies",bench.marked and bodies().all(func(body):return body.get_node("WitnessMark").visible))
	for shape in ["sphere","asymmetric","cube"]:
		await press(0)
		var typed:=true
		for body in bodies():
			var geometry: MeshInstance3D=body.get_node("BodyGeometry")
			typed=typed and ((geometry.mesh is SphereMesh) if shape=="sphere" else (geometry.mesh is ArrayMesh) if shape=="asymmetric" else (geometry.mesh is BoxMesh))
		check("body control builds %s across live, sample and frames"%shape,bench.shape_name==shape and typed)
		check("shape change retains visible witness marks for %s"%shape,bodies().all(func(body):return body.get_node("WitnessMark").visible))
		check("shape change retains all fixed pose transforms for %s"%shape,same_poses(fixed,frame_poses()))
	await press(1)
	check("MARK OFF hides all witness marks",not bench.marked and bodies().all(func(body):return not body.get_node("WitnessMark").visible))
	bench.set_shape("invalid")
	check("unknown body name leaves current model intact",bench.shape_name=="cube")
	bench.seek(-1)
	check("negative seek returns to cycle start",bench.elapsed==0.0)
	observations["frame_count"]=fixed.size()
	observations["model_count"]=bodies().size()

func run() -> void:
	for source in [SCRIPT,MOTION_SCRIPT]:hashes[source]=FileAccess.get_sha256(source)
	mathematical_contract()
	sampling_contract()
	world=Node3D.new()
	root.add_child(world)
	current_scene=world
	bench=load(SCENE).instantiate()
	bench.playing=false
	world.add_child(bench)
	pointer=Camera3D.new()
	world.add_child(pointer)
	for i in 5:await tick()
	await build_contract()
	var end_hashes: Dictionary={}
	for source in [SCRIPT,MOTION_SCRIPT]:end_hashes[source]=FileAccess.get_sha256(source)
	var output:=FileAccess.open(OUT,FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures,"source_sha256":hashes,"source_sha256_at_finish":end_hashes,"observations":observations,"limits":["Standalone research bench, not installed museum-route verification.","Pointer events exercise real area-button wiring; no tracked hands or human headset test.","Ideal sphere rotational invariance is analytic; finite render mesh and lighting need visual interpretation.","These tests establish sample-and-hold behavior, not perceptual proof of a physical zoetrope illusion."]},"\t"))
	output.close()
	print("[sampling-test] RESULT ",checks.size()," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
