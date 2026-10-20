extends SceneTree
var checks: Array=[]
var failures: Array=[]
var observations: Dictionary={}
var report_path="res://ada_run/entropy_ruin_checks.json"
func _initialize() -> void:run.call_deferred()
func check(title: String,passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	if not passed:failures.append(title);print("FAIL ",title)
func run() -> void:
	await verify_ruin()
	finish()
func verify_ruin() -> void:
	var ruin=load("res://commons/artifacts/randomness_space/entropy_ruin.tscn").instantiate();ruin.autostart=false;root.add_child(ruin)
	check("116 rigid stones",ruin.pieces.size()==116 and ruin.pieces.all(func(p):return p.body is RigidBody3D))
	check("32 foundations fixed, 84 loose",ruin.pieces.filter(func(p):return p.anchor).size()==32 and ruin.pieces.filter(func(p):return not p.anchor and not p.body.freeze).size()==84)
	var mesh: ArrayMesh=ruin._drum(0.3,0.31,0);var arrays: Array=mesh.surface_get_arrays(0)
	var outward:=true;var caps:=true
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		var p: Vector3=arrays[Mesh.ARRAY_VERTEX][i];var n: Vector3=arrays[Mesh.ARRAY_NORMAL][i]
		if absf(n.y)>0.99:caps=caps and n.y*p.y>0
		else:outward=outward and n.dot(Vector3(p.x,0,p.z).normalized())>0.5
	check("stone side faces point outward",outward);check("stone end caps point outward",caps)
	await create_timer(3.0).timeout
	var upper: RigidBody3D=ruin.pieces[86].body
	var before:=upper.position
	check("column stands before intervention",ruin.pieces[93].body.position.y>3.0)
	check("support can be extracted",ruin.pull_and_drop(85))
	await create_timer(0.25).timeout
	check("support moves outward before release",ruin.pieces[85].body.position.z< -0.3 and ruin.pieces[85].body.freeze)
	check("supported stone is a live colliding body",not upper.freeze and upper.collision_layer==4 and upper.collision_mask==5)
	await create_timer(3.5).timeout
	check("released support falls under gravity",ruin.extracting==-1 and not ruin.pieces[85].body.freeze and ruin.pieces[85].body.position.y<0.55)
	check("unselected upper stone falls when support is removed",upper.position.y<before.y-0.18)
	check("one extraction, multiple moved stones",ruin.history==[85] and ruin.pieces.filter(func(p):return p.body.position.distance_to(p.home.origin)>0.18).size()>1)
	check("all stones retained after contact",ruin.pieces.size()==116)
	observations.upper_before_y=before.y;observations.upper_after_y=upper.position.y
	observations.removed_after_y=ruin.pieces[85].body.position.y
	ruin.restore()
	check("restore returns authored transforms",ruin.pieces.all(func(p):return p.body.transform.is_equal_approx(p.home)))
	check("restore clears extraction and selection",ruin.history.is_empty() and ruin.extracting==-1 and not ruin.running)
	await create_timer(0.1).timeout
	ruin.weather_one()
	var first: int=ruin.history[0]
	observations.first_choice=first
	check("seeded first action removes a supporting drum",first>=72 and (first-72)%11==2)
	ruin.restore();await create_timer(0.1).timeout;ruin.weather_one()
	observations.repeat_choice=ruin.history.duplicate()
	observations.repeat_candidates=ruin._candidates(12,16)
	observations.drum_positions=[]
	for id in [74,85,96,107]:observations.drum_positions.append(str(ruin.pieces[id].body.position))
	check("restore repeats the choice without promising an identical landing",ruin.history==[first])
	ruin.free()

func finish() -> void:
	var file:=FileAccess.open(report_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"\t"));file.close()
	print("Checks: ",checks.size()," failures: ",failures.size());quit(0 if failures.is_empty() else 1)
