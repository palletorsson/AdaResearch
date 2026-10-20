extends SceneTree
var checks: Array=[]
var failures: Array=[]
var observations := {}
func _initialize() -> void: run.call_deferred()
func check(name: String, ok: bool) -> void:
	checks.append({"name":name,"passed":ok})
	if not ok: failures.append(name)
func near(a: Vector3,b: Vector3) -> bool: return a.distance_to(b)<.00002
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	var prefix: String=args[1] if args.size()>1 else "res://algorithms/forces/euler_drift/"
	var Model=load(prefix+"step_model.gd")
	var m=Model.new()
	check("starts at zero time with one saved position",m.tick==0 and m.history().size()==1 and m.position==m.start)
	check("reference at zero is starting position",m.reference_at(0)==m.start)
	var rows: Array=[]
	for n in [10,20,40]:
		m.choose_steps(n)
		var first: Dictionary=m.snapshot()
		m.step()
		check("first step uses old velocity "+str(n),near(m.position,m.start+m.initial_velocity/float(n)))
		for i in range(n-1): m.step()
		var expected:=Vector3(0,4.9/float(n),0)
		check("signed explicit Euler difference "+str(n),near(m.difference(),expected))
		check("one second, shared velocity "+str(n),is_equal_approx(m.time(),1) and near(m.velocity,m.initial_velocity+m.gravity))
		check("analytic endpoint "+str(n),near(m.reference_at(1),Vector3(2,.75,0)))
		check("bounded history "+str(n),m.history().size()==n+1 and not m.step())
		check("earlier snapshot untouched "+str(n),first.tick==0 and first.position==m.start)
		var saved: Array=m.history(); saved[0].position=Vector3.ONE*999
		check("caller cannot alter saved history "+str(n),m.history()[0].position==m.start)
		var end: Vector3=m.position
		m.reset(); m.advance(100000)
		check("long frame completes only bounded one second "+str(n),m.tick==n and near(m.position,end) and m.credit==0)
		m.reset()
		for i in 120: m.advance(1.0/120)
		check("120 Hz produces same result "+str(n),m.tick==n and near(m.position,end))
		m.reset()
		for d in [.013,.187,.004,.296,.071,.329,.1]: m.advance(d)
		check("uneven frame cadence produces same result "+str(n),m.tick==n and near(m.position,end))
		rows.append({"steps":n,"time":m.time(),"difference_y":m.difference().y,"samples":m.history().size()})
	observations.baseline=rows
	m.initial_velocity=Vector3(-3,7,0); m.gravity=Vector3(1,-6,0); m.start=Vector3(2,1,0)
	m.choose_steps(20); m.advance(1)
	check("independent launch reference",near(m.reference_at(1),Vector3(-.5,5,0)))
	check("independent launch signed difference",near(m.difference(),Vector3(-.025,.15,0)))
	check("unsupported count leaves state intact",not m.choose_steps(0) and m.tick==20)
	phase_checks(Model)
	m.reset(); m.advance(-1); m.advance(NAN)
	check("invalid elapsed input ignored",m.tick==0 and m.credit==0)
	m.advance(.01);m.reset();check("reset clears partial interval",m.credit==0 and m.tick==0)
	await scene_checks(prefix,args.size()==1)
	# A runtime error aborts a function without failing a check; these two make an abort a failure.
	check("phase checks ran to the end",observations.has("phases"))
	check("scene phase checks ran to the end",scene_phases_done)
	var f:=FileAccess.open(args[0],FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "));f.close()
	print("EULER STEP ",checks.size()-failures.size(),"/",checks.size()," ",failures)
	quit(0 if failures.is_empty() else 1)

func scene_checks(prefix: String, legacy: bool) -> void:
	var host:=Node3D.new();root.add_child(host)
	var stage=load(prefix+"step_study.tscn").instantiate();host.add_child(stage)
	await physics_frame;await process_frame;await physics_frame;await process_frame
	stage.set_physics_process(false)
	check("complete scene creates two carried spheres",stage.points.size()==2 and stage.points[0].get_child(0).mesh is SphereMesh and is_equal_approx(stage.points[0].get_child(0).mesh.radius,.14))
	check("scripted spheres do not participate in contacts",stage.points[0].collision_layer==0 and stage.points[1].collision_mask==0 and not stage.points[0].enabled)
	stage.act("ONE STEP");check("one step advances exactly one",stage.model.tick==1 and not stage.running)
	stage.act("FIRE / PAUSE");check("fire resumes",stage.running)
	stage.act("FIRE / PAUSE");stage._physics_process(.3);check("pause holds simulation time",stage.model.tick==1 and not stage.running)
	stage.act("REPLAY");check("replay rewinds and starts",stage.model.tick==0 and stage.running)
	stage.slider.set_normalized_value(1);stage.slider.slider_moved.emit(Vector3.ZERO)
	check("hand slider selects forty and resets",stage.model.count==40 and stage.model.tick==0 and not stage.running)
	stage.act("OTHER THROW");check("other throw changes only initial velocity",stage.model.initial_velocity==Vector3(3,6,0) and stage.model.count==40 and stage.model.gravity==Vector3(0,-9.8,0))
	stage.act("REPLAY");stage._physics_process(1)
	check("point transforms show model coordinates",near(stage.points[1].position,stage.display(stage.model.position,1)) and near(stage.points[0].position,stage.display(stage.model.reference_at(1),0)))
	check("display preserves the calculated difference vector",near(stage.points[1].position-stage.points[0].position,stage.model.difference()))
	check("trace geometry stays bounded",stage.trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()>80 and stage.trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<1000)
	check("flat trace readable from either side",stage.trace.mesh.surface_get_material(0).cull_mode==BaseMaterial3D.CULL_DISABLED)
	await physics_frame;await process_frame;await physics_frame;await process_frame
	check("paused display retains computed endpoint across frames",near(stage.points[1].position,stage.display(stage.model.position,1)))
	stage.act("RESET");check("reset returns initial fixture",stage.model.count==10 and stage.model.initial_velocity==Vector3(4,4.9,0) and not stage.running)
	await scene_phase_checks(stage)
	if legacy:
		var old=load("res://algorithms/forces/euler_drift/euler_drift.tscn").instantiate();host.add_child(old)
		check("default artifact retains legacy geometry",old.get_node_or_null("StepStudy")==null and old.get_child_count()>20)
		var selected=load("res://algorithms/forces/euler_drift/euler_drift.tscn").instantiate()
		selected.apply_grid_config({"lesson":"step_study"});host.add_child(selected)
		check("map configuration creates only new study",selected.get_child_count()==1 and selected.get_child(0).name=="StepStudy")
		await physics_frame; await process_frame
		selected.get_child(0).set_physics_process(false)
	for node in host.find_children("*","Node",true,false):node.set_physics_process(false)
	await physics_frame;await process_frame;host.queue_free();await physics_frame;await process_frame

## Independent throws checked at every saved tick, each check named by the phase the throw is in.
## Phase = sign of velocity . gravity: against gravity (rising), zero (peak), with it (falling).
## The first independent launch turns at t=45/37, after the window, so it only ever rises; and
## t=0 and t=1 are the two times where t*t == t, so endpoints cannot tell t from t*t.
const THROWS := [
	{"name":"peak on a tick","start":Vector3(1,.5,-1),"v0":Vector3(-.5,2.5,1.6),"g":Vector3(1,-6,2),"phases":["rising","peak","falling"]},
	{"name":"peak between ticks","start":Vector3(-1.5,.25,.5),"v0":Vector3(1.09375,3,-1.25),"g":Vector3(-2,-7,0),"phases":["rising","falling"]},
	{"name":"thrown downward","start":Vector3(0,3,0),"v0":Vector3(2,-1.5,.8),"g":Vector3(.5,-9,0),"phases":["falling"]},
	{"name":"launched at the peak","start":Vector3(-2,1.5,.3),"v0":Vector3(4,1,-.7),"g":Vector3(1,-4,0),"phases":["peak","falling"]},
	{"name":"first independent launch","start":Vector3(2,1,0),"v0":Vector3(-3,7,0),"g":Vector3(1,-6,0),"phases":["rising"]},
]
func phase_of(t: float, turn: float) -> String:
	return "peak" if absf(t-turn)<1e-6 else ("rising" if t<turn else "falling")
func phase_checks(Model) -> void:
	var table: Array=[]
	for throw in THROWS:
		var p0: Vector3=throw.start; var v0: Vector3=throw.v0; var g: Vector3=throw.g
		var turn:=-v0.dot(g)/g.length_squared()
		for n in [10,20,40]:
			var m=Model.new(); m.start=p0; m.initial_velocity=v0; m.gravity=g; m.choose_steps(n)
			while m.step(): pass
			var h: float=1.0/n; var seen:={}; var worst:=0.0
			for row in m.history():
				# The oracle is written here, not read from the model.
				var t: float=float(row.tick)/n
				var reference: Vector3=p0+v0*t+.5*g*t*t
				var expected: Vector3=-.5*g*t*h
				var phase: String=phase_of(t,turn)
				var s: float=row.velocity.dot(g)
				var moving:="peak" if absf(s)<1e-3 else ("rising" if s<0 else "falling")
				if not seen.has(phase): seen[phase]={"state":true,"difference":true,"ticks":0}
				var e: Dictionary=seen[phase]; e.ticks+=1
				e.state=e.state and moving==phase and is_equal_approx(row.time,t) and near(row.velocity,v0+g*t) and near(row.reference,reference)
				e.difference=e.difference and near(row.difference,expected) and near(row.position,reference+expected)
				worst=maxf(worst,(row.position-reference-expected).length())
			check(throw.name+" covers "+"/".join(throw.phases)+" "+str(n),seen.keys()==throw.phases and m.history().size()==n+1)
			for phase in seen:
				check(throw.name+" "+phase+": saved time, velocity, phase and formula "+str(n),seen[phase].state)
				check(throw.name+" "+phase+": signed explicit Euler difference "+str(n),seen[phase].difference)
			var ticks:={}
			for phase in seen: ticks[phase]=seen[phase].ticks
			table.append({"throw":throw.name,"steps":n,"turn":turn,"ticks":ticks,"worst_error":worst})
	observations.phases=table

## The hall's own display at the baseline throw's rise, peak (t=0.5, tick 5 of 10) and fall.
## Positions are compared with the display contract written here (one shared plane at z=.16),
## never with stage.display(), which is under test. Every vertex read is guarded by a count.
func baseline_reference(t: float) -> Vector3: return Vector3(-2+4*t,.75+4.9*t-4.9*t*t,0)
func on_plane(p: Vector3) -> Vector3: return Vector3(p.x,p.y,.16)
func stepped_on_plane(t: float) -> Vector3: return on_plane(baseline_reference(t)+Vector3(0,.49*t,0)) # -0.5*g*t*h, h=0.1
func path_checks(name: String, mesh: Mesh, segments: int, stride: int, sample: Callable) -> void:
	var verts:=PackedVector3Array()
	if mesh!=null and mesh.get_surface_count()>0: verts=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var whole: bool=verts.size()==segments*stride
	check(name+" has "+str(segments)+" segments",whole)
	var ok:={}
	for phase in ["rising","peak","falling"]: ok[phase]={"centre":whole,"width":whole,"mark":whole}
	if whole:
		for i in segments+1:
			var t: float=float(i)/segments
			var e: Dictionary=ok[phase_of(t,.5)]
			# A segment is a-side, b-side, b+side, a-side, b+side, a+side; with stride 12 a mark centred on b follows.
			var j: int=stride*mini(i,segments-1)
			var at: Vector3=(verts[j]+verts[j+5])/2 if i<segments else (verts[j+1]+verts[j+2])/2
			var side: Vector3=(verts[j+5]-verts[j])/2 if i<segments else (verts[j+2]-verts[j+1])/2
			var along: Vector3=verts[j+1]+verts[j+2]-verts[j]-verts[j+5]
			e.centre=e.centre and near(at,sample.call(t))
			e.width=e.width and absf(side.length()-.009)<1e-5 and absf(side.normalized().dot(along.normalized()))<1e-4
			if stride==12 and i>0:
				var k: int=stride*(i-1)
				e.mark=e.mark and near((verts[k+6]+verts[k+8])/2,sample.call(t))
	for phase in ok:
		check(name+" centre "+phase,ok[phase].centre)
		check(name+" width "+phase,ok[phase].width)
		if stride==12: check(name+" step mark "+phase,ok[phase].mark)
var scene_phases_done:=false
func scene_phase_checks(stage) -> void:
	path_checks("amber formula path",stage.reference_path.mesh,80,6,func(t: float) -> Vector3: return on_plane(baseline_reference(t)))
	for k in [2,5,8,10]:
		while stage.model.tick<k: stage.act("ONE STEP")
		if k==10: break
		var t: float=k/10.0
		var phase: String=phase_of(t,.5)
		stage._physics_process(0)
		check("display difference "+phase+" tick "+str(k),near(stage.points[0].position,on_plane(baseline_reference(t))) and near(stage.points[1].position,stepped_on_plane(t)) and near(stage.points[1].position-stage.points[0].position,Vector3(0,.49*t,0)))
		check("status prints the signed difference "+phase+" tick "+str(k),("Δy = +%.4f m"%(.49*t)) in stage.status.text)
		# Each sphere writes its own position every physics frame, after the stage.
		await physics_frame;await physics_frame
		check("spheres after physics frames "+phase+" tick "+str(k),stage.points[0].visible and near(stage.points[0].position,on_plane(baseline_reference(t))) and near(stage.points[1].position,stepped_on_plane(t)))
	path_checks("blue stepped trace",stage.trace.mesh,10,12,stepped_on_plane)
	scene_phases_done=true
