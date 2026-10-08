extends SceneTree
## Independent rendered-geometry, physical-control and analytic sweep checks.
const SCENE := "res://commons/artifacts/axial_sweep/axial_sweep.tscn"
const SCRIPT := "res://commons/artifacts/axial_sweep/axial_sweep.gd"
const OUT := "res://doc/space/zoetrope-encounter-2026-09-17/axial-test-results.json"
var checks:Array=[]
var failures:Array[String]=[]
var observations:Dictionary={}
var world:Node3D
var study:Node3D
var pointer:Camera3D
var source_hash:String

func _initialize()->void: run.call_deferred()
func check(title:String,passed:bool,detail:Variant=null)->void:
	checks.append({"name":title,"passed":passed,"detail":detail})
	if not passed:failures.append(title)
	print("[axial-test] ","PASS " if passed else "FAIL ",title," ",str(detail) if detail!=null else "")
func tick()->void:
	await physics_frame
	await process_frame
func press(index:int)->void:
	var area:Node3D=study.buttons[index].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	await tick()
func vertices(mesh:Mesh)->PackedVector3Array:
	var points:=PackedVector3Array()
	for surface in mesh.get_surface_count():
		var arrays:Array=mesh.surface_get_arrays(surface)
		if arrays.size()>Mesh.ARRAY_VERTEX:points.append_array(arrays[Mesh.ARRAY_VERTEX])
	return points
func analytic_radius(shape:String,y:float)->float:
	if shape=="cube":return sqrt(0.18) if absf(y)<=0.300001 else 0.0
	return 0.45*(0.35-y)/0.7 if y>=-0.350001 and y<=0.350001 else 0.0
func contains(points:PackedVector3Array,shape:String)->float:
	var excess:=0.0
	for point in points:
		excess=maxf(excess,Vector2(point.x,point.z).length()-analytic_radius(shape,point.y))
	return excess
func surface_samples(shape:String)->PackedVector3Array:
	var result:=PackedVector3Array()
	if shape=="cube":
		for face in 3:
			for side in [-1.0,1.0]:
				for i in 11:
					for j in 11:
						var p:=Vector3.ZERO
						p[face]=side*0.3
						p[(face+1)%3]=-0.3+0.06*i
						p[(face+2)%3]=-0.3+0.06*j
						result.append(p)
	else:
		var a:=Vector3(0,-0.35,0)
		var b:=Vector3(0.45,-0.35,0)
		var c:=Vector3(0,0.35,0)
		for i in 21:
			for j in range(21-i):
				var u:=i/20.0
				var v:=j/20.0
				result.append(a*(1.0-u-v)+b*u+c*v)
	return result
func geometry_contract(shape:String)->void:
	study.set_shape(shape)
	study.seek(0.0)
	var original:=vertices(study.body_mesh.mesh)
	var mesh_id:int=study.body_mesh.mesh.get_instance_id()
	var samples:=surface_samples(shape)
	var max_excess:=0.0
	var max_local_change:=0.0
	for k in 80:
		study.seek(k*0.25)
		var changed:=vertices(study.body_mesh.mesh)
		for i in original.size():max_local_change=maxf(max_local_change,original[i].distance_to(changed[i]))
		var pose:Basis=study.meshspin.basis
		var turned:=PackedVector3Array()
		for point in samples:turned.append(pose*point)
		max_excess=maxf(max_excess,contains(turned,shape))
	check(shape+": actual body mesh stays locally unchanged throughout full turn",mesh_id==study.body_mesh.mesh.get_instance_id() and max_local_change<0.000001,{"vertices":original.size(),"maximum_local_change_m":max_local_change})
	check(shape+": analytical swept volume contains rotated surface samples",max_excess<0.000001,{"sample_count":samples.size()*80,"maximum_radial_excess_m":max_excess})
	var half:float=0.3 if shape=="cube" else 0.35
	var radius_errors:=0.0
	for k in 21:
		var y:float=lerpf(-half,half,k/20.0)
		radius_errors=maxf(radius_errors,absf(study.envelope_radius_at(y)-analytic_radius(shape,y)))
	check(shape+": radius query matches independent cross-section formula",radius_errors<0.000001,radius_errors)
	check(shape+": radius query ends outside vertical body range",study.envelope_radius_at(-half-0.01)==0.0 and study.envelope_radius_at(half+0.01)==0.0)
	var contour:=vertices(study.contour_mesh.mesh)
	var radius_max:=0.0
	for p in contour:radius_max=maxf(radius_max,Vector2(p.x,p.z).length())
	var expected:float=sqrt(0.18) if shape=="cube" else 0.45
	check(shape+": rendered outer contours reach expected maximum radius",absf(radius_max-expected)<0.000001,{"measured_radius_m":radius_max,"expected_radius_m":expected,"vertices":contour.size()})
	check(shape+": rendered contour endpoints stay inside analytical boundary",contains(contour,shape)<0.000001,contains(contour,shape))
	study.seek(0)
	var start:Transform3D=study.body_mesh.global_transform
	study.seek(5)
	check(shape+": five seconds gives a true indexed quarter-turn",(study.meshspin.basis*Vector3.RIGHT-Vector3.FORWARD).length()<0.000001 and not study.body_mesh.global_transform.is_equal_approx(start))
	study.seek(20)
	check(shape+": twenty seconds returns body to full-turn pose",study.body_mesh.global_transform.is_equal_approx(start))
	observations[shape]={"surface_sample_count":samples.size()*80,"max_radial_excess_m":max_excess,"contour_max_radius_m":radius_max,"finite_contour_chord_sagitta_bound_m":expected*(1.0-cos(PI/128.0))}

func ray(at:Vector3,to:Vector3)->Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(study.to_global(at),study.to_global(to),1))
func physical_contract()->void:
	var plate:MeshInstance3D=study.get_node("ViewingPlate").get_child(0)
	var top:Vector3=study.to_local(plate.to_global(Vector3(0,plate.mesh.get_aabb().end.y,0)))
	check("viewing plate top is 1.7 metres",absf(top.y-1.7)<0.000001,top.y)
	var below:=INF
	for shape in ["cube","triangle"]:
		study.set_shape(shape)
		for p in vertices(study.body_mesh.mesh):
			below=minf(below,study.to_local(study.body_mesh.to_global(p)).y-1.7)
	check("both rotating bodies stay on or above platform plane",below>=-0.000001,below)
	for shape in ["cube","triangle"]:
		study.set_shape(shape)
		study.set_envelope(true)
		study.set_history(true)
		var children: Array=study.meshspin.find_children("*","CollisionObject3D",true,false)
		children.append_array(study.envelope.find_children("*","CollisionObject3D",true,false))
		check(shape+": body and analytical boundary add no physical collider",children.is_empty())
		await tick()
		var hit:=ray(Vector3(-2,2.05,0),Vector3(2,2.05,0))
		check(shape+": physics ray passes through rotating body and revealed boundary",hit.is_empty())
	check("pedestal remains physically solid",not ray(Vector3(-2,0.5,0),Vector3(2,0.5,0)).is_empty())
	study.set_history(false)
	study.set_envelope(false)
	study.set_shape("cube")
	study.seek(0)

func controls_contract()->void:
	check("three real buttons exist",study.buttons.size()==3)
	if study.buttons.size()!=3:return
	await press(0)
	check("SHAPE pointer button builds triangle profile",study.shape_id=="triangle" and vertices(study.body_mesh.mesh).size()==3)
	await press(0)
	check("SHAPE pointer button returns cube",study.shape_id=="cube" and study.body_mesh.mesh is BoxMesh)
	await press(2)
	check("BOUNDARY pointer button reveals analytical contour",study.show_envelope and study.envelope.visible)
	await press(2)
	check("BOUNDARY pointer button hides analytical contour",not study.show_envelope and not study.envelope.visible)
	study.playing=false
	var before:Transform3D=study.body_mesh.global_transform
	var before_time:float=study.elapsed
	await press(1)
	await create_timer(0.32).timeout
	check("PLAY advances actual body under real elapsed time",study.playing and study.elapsed-before_time>0.2 and not study.body_mesh.global_transform.is_equal_approx(before))
	await press(1)
	before=study.body_mesh.global_transform
	before_time=study.elapsed
	await create_timer(0.16).timeout
	check("PAUSE holds actual body and elapsed clock",not study.playing and study.elapsed==before_time and study.body_mesh.global_transform.is_equal_approx(before))

func history_contract()->void:
	# Drive the actual process entrypoint deterministically to cover two revolutions
	# without waiting forty seconds. Real-clock behavior is tested independently.
	study.set_process(false)
	study.playing=true
	study.seek(0)
	study.set_history(true)
	var maximum:=0
	for k in 481:
		study._process(1.0/12.0)
		maximum=maxi(maximum,study.history_angles.size())
	check("history remains capped at 24 poses across two turns",maximum==24 and study.history_angles.size()==24,maximum)
	check("bounded history has finite rendered geometry",vertices(study.history.mesh).size()==24*24,vertices(study.history.mesh).size())
	study.set_shape("triangle")
	check("shape changes discard old cube history",study.history_angles.size()==1 and vertices(study.history.mesh).size()==6)
	study.set_history(false)
	check("history OFF clears memory and hides history",study.history_angles.is_empty() and not study.history.visible and study.history.mesh==null)
	study.playing=false
	study.seek(-1)
	check("negative seek clamps to start",study.elapsed==0.0)
	study.seek(INF)
	check("nonfinite seek leaves valid state intact",study.elapsed==0.0 and study.meshspin.transform.is_finite())
	study.set_shape("nonsense")
	check("unknown shape keeps current profile",study.shape_id=="triangle")

func run()->void:
	source_hash=FileAccess.get_sha256(SCRIPT)
	world=Node3D.new()
	root.add_child(world)
	current_scene=world
	study=load(SCENE).instantiate()
	study.position=Vector3(12,1.25,-8)
	study.rotation.y=PI
	study.playing=false
	world.add_child(study)
	pointer=Camera3D.new()
	world.add_child(pointer)
	for i in 5:await tick()
	check("analytical boundary and history start hidden",not study.envelope.visible and not study.history.visible)
	geometry_contract("cube")
	geometry_contract("triangle")
	await physical_contract()
	await controls_contract()
	history_contract()
	var output:=FileAccess.open(OUT,FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"source_sha256":source_hash,"source_sha256_at_finish":FileAccess.get_sha256(SCRIPT),"limits":["Tests actual scene under translated and yaw180 parent, not full museum route or human headset use.","Swept volume is analytical union over a complete turn; rendered cyan lines are finite-resolution boundary samples, not a new solid.","History capacity test advances the real process function deterministically; live timing and real button wiring are tested separately.","Triangle is a flat profile; its rotating union occupies a cone although each individual profile has zero volume."]},"\t"))
	output.close()
	print("[axial-test] RESULT ",checks.size()," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
