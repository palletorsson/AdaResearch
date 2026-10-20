extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-pso-a-place-remembered/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("PSO ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder: String = "printed"):
	return load(OUT+folder+"/swarm.gd").new()
func correct_records(m) -> bool:
	var maximum:float=-INF
	for i in range(m.positions.size()):
		if not is_equal_approx(m.best_scores[i],m.score(m.best_positions[i])):return false
		maximum=maxf(maximum,m.best_scores[i])
	return is_equal_approx(maximum,m.shared_score) and is_equal_approx(m.shared_score,m.score(m.shared_position))
func setup_terms(m) -> void:
	m.positions.assign([Vector2(.2,.1)]);m.velocities.assign([Vector2(.1,0)])
	m.best_positions.assign([Vector2(.1,.1)]);m.best_scores.assign([-.02])
func expected_step(m) -> Array[Vector2]:
	# Independent numerical oracle: fixed prior group record for all points.
	var rng:=RandomNumberGenerator.new();rng.state=m.random.state
	var output:Array[Vector2]=[]
	for i in range(m.positions.size()):
		var v:Vector2=(m.inertia*m.velocities[i]+m.personal_pull*rng.randf()*(m.best_positions[i]-m.positions[i])+m.social_pull*rng.randf()*(m.shared_position-m.positions[i])).limit_length(.35)
		var p:Vector2=m.positions[i]+v
		output.append(Vector2(clampf(p.x,-6,6),clampf(p.y,-6,6)))
	return output
func close(a,b) -> bool:
	for i in range(a.size()):
		if a[i].distance_to(b[i])>.00001:return false
	return true
func run() -> void:
	var m=fresh()
	check("24 initial positions evaluated before movement",m.positions.size()==24 and m.best_positions==m.positions and m.steps==0 and correct_records(m))
	check("Initial group record belongs to evaluated population",m.positions.has(m.shared_position) and m.shared_score<0)
	check("CENTER exact score:3,4 gives minus25",m.score(Vector2(3,4))==-25)
	m.change_objective(1);check("EDGE exact score:3,4 gives25",m.score(Vector2(3,4))==25)
	m.change_objective(2);check("RIDGE uses squared perpendicular distance",m.score(Vector2(3,1))==-2 and m.score(Vector2(4,4))==0)
	m=fresh();setup_terms(m);var t=m.terms(0,.5,.25,Vector2.ZERO)
	check("Three taught vectors match independent numbers",t[0].is_equal_approx(Vector2(.06,0)) and t[1].is_equal_approx(Vector2(-.075,0)) and t[2].is_equal_approx(Vector2(-.075,-.0375)))
	check("Taught next position is0.11,0.0625",(m.positions[0]+t[0]+t[1]+t[2]).is_equal_approx(Vector2(.11,.0625)))
	m=fresh();var expected=expected_step(m);m.step()
	check("Every point uses one old shared record",close(m.positions,expected))
	check("Scores and their source positions stay paired",correct_records(m))
	var prior:float=m.best_scores[0];var where:Vector2=m.best_positions[0]
	m.positions[0]=Vector2(6,6);m.remember()
	check("Worse hand placement preserves remembered answer",m.best_scores[0]==prior and m.best_positions[0]==where)
	m.positions[0]=Vector2.ZERO;m.remember()
	check("Better candidate updates personal and group answer",m.best_positions[0]==Vector2.ZERO and m.best_scores[0]==0 and m.shared_position==Vector2.ZERO and m.shared_score==0)
	m.change_objective(2);m.positions[0]=Vector2(3,3);m.remember()
	check("Equal best retains earlier personal location",m.best_positions[0]==Vector2.ZERO)
	var pos=m.positions.duplicate();var vel=m.velocities.duplicate();var step_count:int=m.steps
	m.change_objective(1)
	check("New objective keeps positions, velocities and clock",m.positions==pos and m.velocities==vel and m.steps==step_count)
	check("New objective resets all memories to current candidates",m.best_positions==pos and correct_records(m))
	m.inertia=.3;m.social_pull=.4;m.reset()
	check("Restart keeps objective and coefficients",m.objective==1 and m.inertia==.3 and m.social_pull==.4 and m.steps==0 and correct_records(m))
	m=fresh();var n=fresh()
	for i in range(120):m.step();n.step()
	check("Seeded repeats match positions and memories",m.positions==n.positions and m.best_scores==n.best_scores)
	check("This seeded CENTER run improves its best score",m.shared_score>-.001)
	m.reset();n.reset();m.step();n.step()
	check("Restart replays random stream",m.positions==n.positions)
	m=fresh();m.positions.assign([Vector2(5.99,5.99)]);m.velocities.assign([Vector2(1,1)]);m.reset_memories();m.personal_pull=0;m.social_pull=0;m.step()
	check("Boundary clamps position and stops outward velocity",m.positions[0]==Vector2(6,6) and m.velocities[0]==Vector2.ZERO)
	m=fresh();var finite:=true;var monotonic:=true
	for mode in range(3):
		m.change_objective(mode)
		for tick in range(600):
			var old:float=m.shared_score;m.step();monotonic=monotonic and m.shared_score>=old
			for i in range(24):finite=finite and m.positions[i].is_finite() and absf(m.positions[i].x)<=6 and absf(m.positions[i].y)<=6 and m.velocities[i].length()<=.350001
	check("1800 iterations across objectives stay bounded",finite)
	check("Best does not decrease within one fixed objective",monotonic and correct_records(m))
	var v=fresh("variation");setup_terms(v);t=v.terms(0,.5,.25,Vector2.ZERO)
	check("Independent zero-social edit removes only shared term",t[2]==Vector2.ZERO and (v.positions[0]+t[0]+t[1]+t[2]).is_equal_approx(Vector2(.185,.1)))
	var f=fresh("fault-initial");check("Executed unevaluated-initial-memory fault detected",not correct_records(f))
	f=fresh("fault-objective");f.change_objective(1);check("Executed stale-objective-memory fault detected",not correct_records(f))
	f=fresh("fault-shared");f.positions.assign([Vector2(.2,0),Vector2(1,1)]);f.velocities.assign([Vector2(-.2,0),Vector2.ZERO]);f.inertia=1.0;f.reset_memories()
	n=fresh();n.positions=f.positions.duplicate();n.velocities=f.velocities.duplicate();n.inertia=1.0;n.reset_memories();expected=expected_step(n);n.step()
	check("First particle improvement is deferred for later particles",close(n.positions,expected))
	expected=expected_step(f);f.step();check("Executed within-iteration shared-update fault detected",not close(f.positions,expected))
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code, independent edit, three executed faults and synthetic XR. Author-operated; no physical headset or independent learner claim."},"  "))
	quit(0 if failures.is_empty() else 1)
func host_checks() -> void:
	var s=load(OUT+"printed/study.tscn").instantiate();root.add_child(s);s.playing=false;await ticks();s.set_process(false);s.restart()
	check("Host builds24 carried points and256 floor cells",s.points.size()==24 and s.field.multimesh.instance_count==256)
	check("Matching51cm body and grab shape, unscaled root",s.points[0].get_child(0).scale==Vector3.ONE*3 and is_equal_approx(s.points[0].get_child(1).shape.radius,.255) and s.points[0].scale==Vector3.ONE)
	s.connect_positions(s.connections[0],Vector3(1,.09,2),Vector3(4,.11,-2))
	check("Thin cylinder endpoints coincide with remembered positions",(s.connections[0].transform*Vector3(0,-.5,0)).distance_to(Vector3(1,.09,2))<.001 and (s.connections[0].transform*Vector3(0,.5,0)).distance_to(Vector3(4,.11,-2))<.001)
	s.get_node("Run1").emit_signal("pressed");s._process(.3)
	check("Playback advances three discrete iterations",s.model.steps==3)
	var pos=s.model.positions.duplicate();var vel=s.model.velocities.duplicate();var id:int=s.points[0].get_instance_id()
	s.get_node("Edge-1").emit_signal("pressed")
	check("Opposite control bank changes score while keeping bodies",s.model.objective==1 and s.model.positions==pos and s.model.velocities==vel and s.points[0].get_instance_id()==id and not s.playing)
	check("Caption names new objective and larger-is-better rule","EDGE" in s.captions[0].text and "larger wins" in s.captions[0].text)
	s.change(0);s.restart();s.position=Vector3(4,.2,-3);s.rotation.y=.7
	var old_best:Vector2=s.model.best_positions[0]
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var p=s.points[0];hand.global_position=p.global_position;p.pick_up(pickup);await ticks()
	check("Same point attaches through real XRTools",p.held())
	s.playing=true;hand.global_position=s.to_global(s.place(Vector2(5,5)));await ticks();s._process(.3)
	check("Hold pauses and records correct local coordinate",s.model.steps==0 and s.model.positions[0].distance_to(Vector2(5,5))<.001 and s.model.velocities[0]==Vector2.ZERO)
	check("Hand movement does not overwrite personal memory",s.model.best_positions[0]==old_best and s.personal.position.distance_to(Vector3(old_best.x,.11,-old_best.y))<.001)
	p.action();await ticks();check("Held trigger selects witness",s.witness==0)
	s.get_node("Step1").emit_signal("pressed");s.get_node("Reset1").emit_signal("pressed");s.get_node("Ridge1").emit_signal("pressed")
	check("Hold blocks step, reset and objective mutation",s.model.steps==0 and s.model.objective==0 and s.model.positions[0].distance_to(Vector2(5,5))<.001)
	hand.global_position=s.to_global(s.place(Vector2.ZERO));await ticks();s._process(0)
	p.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0);s.single_step()
	check("Release evaluates hand candidate before movement",s.model.best_scores[0]==0 and s.model.shared_score==0 and s.model.best_positions[0].length()<.001)
	check("Markers show actual stored coordinates",s.shared.position.distance_to(Vector3(0,.16,0))<.001 and s.personal.position.distance_to(Vector3(0,.11,0))<.001)
	s.queue_free();xr.queue_free();await ticks()
