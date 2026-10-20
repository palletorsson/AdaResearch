extends SceneTree
var Model: Script
var code_root := "res://commons/artifacts/navigator_noise/"
var checks: Array=[]
var failures: Array=[]
var observations: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failures.append(label)
	print("[navigator] ","PASS " if passed else "FAIL ",label)
func complete(m) -> void:
	for i in Model.LAST_TICK: m.step()
func run() -> void:
	if OS.get_cmdline_user_args().size()>1: code_root=OS.get_cmdline_user_args()[1]
	Model=load(code_root+"navigation_pair.gd")
	var m=Model.new()
	check("forty saved error/dropout blocks",m.unit_noise.size()==40 and m.uniforms.size()==40)
	check("baseline surface clearance includes both radii",is_equal_approx(m.distance_at(Vector2(-1.65,0)),1.26))
	check("noise scales saved sample without changing true distance",is_equal_approx(float(m.reading(1,0,1.26))-1.26,m.sigma_m*m.unit_noise[0]) and m.reading(0,0,1.26)==1.26)
	check("sample block held for half second",m.reading(1,0,1.26)==m.reading(1,9,1.26))
	m.sigma_m=0; complete(m)
	check("zero error gives identical complete histories",m.history.all(func(r):return r.lanes[0]==r.lanes[1]))
	check("accurate observation reaches the goal without contact",m.outcomes==["GOAL","GOAL"] and m.positions[0].distance_to(Model.GOAL)<.001)
	observations.baseline={"elapsed":m.elapsed.duplicate(),"lengths":m.lengths.duplicate(),"ticks":m.tick}
	var history=m.history.duplicate(true); m.reset(); complete(m)
	check("replay restores all path state",m.history==history)
	m.start_y=.15; m.reset(); complete(m)
	check("independent release height still reaches goal",m.outcomes==["GOAL","GOAL"] and m.history[0].lanes[0].from==Vector2(-1.65,.15))
	var change=m.decision(Vector2(-.6,0),-1,.2,Vector2.RIGHT*.6)
	check("near range changes waypoint state",change.stage==0 and change.command.y>0)
	m.hold_command=false; change=m.decision(Vector2(-.6,0),-1,null,Vector2.RIGHT*.6)
	check("missing STOP preserves state and commands zero",change.stage==-1 and change.command==Vector2.ZERO)
	m.hold_command=true; change=m.decision(Vector2(-.6,0),-1,null,Vector2.RIGHT*.6)
	check("missing HOLD preserves last command",change.stage==-1 and change.command==Vector2.RIGHT*.6)
	check("swept collision detects crossing even with both endpoints outside",is_equal_approx(m.contact_fraction(Vector2(-1,0),Vector2(1,0)),.305))
	check("parallel clear segment does not contact",m.contact_fraction(Vector2(-1,.5),Vector2(1,.5))<0)
	check("touching and overlap are contact",m.contact_fraction(Vector2(.39,0),Vector2.ZERO)>=0 and m.contact_fraction(Vector2.ZERO,Vector2.ONE)==0)
	check("course boundary detects between-step exit",is_equal_approx(m.exit_fraction(Vector2(0,.7),Vector2(0,.9)),.5))
	m=Model.new(); m.missing_mode=true; m.dropout=1; complete(m)
	check("complete loss times out without claiming goal",m.outcomes==["GOAL","TIMEOUT"] and m.lengths[1]==0 and m.elapsed[1]==20)
	check("missing is represented as null",m.history[0].lanes[1].observed==null)
	m.dropout=0; m.reset(); complete(m)
	check("no dropout matches baseline",m.outcomes==["GOAL","GOAL"] and m.history.all(func(r):return r.lanes[0]==r.lanes[1]))
	m=Model.new(); m.missing_mode=true; m.dropout=.5; m.hold_command=true
	m.uniforms.fill(0.0); m.uniforms[0]=1.0; complete(m)
	check("one good reading then loss with HOLD causes genuine contact",m.outcomes[1]=="CONTACT" and absf(m.distance_at(m.positions[1]))<.00001)
	observations.hold_contact={"time":m.elapsed[1],"position":[m.positions[1].x,m.positions[1].y]}
	m.hold_command=false; m.reset(); complete(m)
	check("same missing record with STOP avoids contact but times out",m.outcomes[1]=="TIMEOUT" and m.lengths[1]<.31)
	m=Model.new(); m.sigma_m=.8; m.unit_noise.fill(3.0); complete(m)
	check("large positive distance error delays avoidance into contact",m.outcomes[1]=="CONTACT")
	m.unit_noise.fill(-3.0); m.reset(); complete(m)
	check("negative observed distance is retained and triggers early detour",float(m.history[0].lanes[1].observed)<0 and m.outcomes[1]=="GOAL")
	var batch: Array=[]
	for seed_value in range(1847,1857):
		m=Model.new(); m.resample(seed_value); m.reset(); complete(m)
		batch.append({"seed":seed_value,"mode":"noise","outcomes":m.outcomes.duplicate(),"time":m.elapsed.duplicate(),"distance":m.lengths.duplicate()})
		m.missing_mode=true; m.hold_command=true; m.reset(); complete(m)
		batch.append({"seed":seed_value,"mode":"dropout/hold","outcomes":m.outcomes.duplicate(),"time":m.elapsed.duplicate(),"distance":m.lengths.duplicate()})
	observations.batch=batch
	check("bounded batch terminates with finite data",batch.all(func(r):return r.time.all(func(t):return is_finite(t) and t<=20) and r.distance.all(func(d):return is_finite(d))))
	check("held commands can leave the declared course",batch.any(func(r):return r.outcomes[1]=="LEFT COURSE"))
	m=Model.new(); var saved=m.unit_noise.duplicate(); var drops=m.uniforms.duplicate()
	observations.saved_inputs={"seed":m.sample_seed,"unit_noise":Array(saved),"uniforms":Array(drops),"engine":Engine.get_version_info().string}
	m.resample(1848); check("next seed changes recorded inputs",saved!=m.unit_noise)
	m.resample(1847); check("seed replay restores both records",saved==m.unit_noise and drops==m.uniforms)
	seed(345); var expected=randf(); seed(345); m.resample(222)
	check("local sample generator leaves global RNG alone",randf()==expected)
	m.reset(); m.step(); var first=m.history[0].duplicate(true); complete(m)
	check("earlier rows remain immutable",m.history[0]==first and m.history.size()<=400)
	await scene_checks()
	var file:=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  ")); file.close()
	quit(0 if failures.is_empty() else 1)
func scene_checks() -> void:
	var host:=Node3D.new(); root.add_child(host)
	var work=load(code_root+"NavigatorNoise.tscn").instantiate(); host.add_child(work)
	await physics_frame; await process_frame
	work.set_physics_process(false); work.set_process(false); work.points[0].set_physics_process(false)
	check("complete stage creates two inherited sphere points",work.points.size()==2 and is_equal_approx(work.points[0].get_child(0).mesh.radius,.14))
	check("one reachable release handle, paired agent not freely grabbed",work.points[0].enabled and not work.points[1].enabled)
	work.act("REPLAY"); work._physics_process(.1)
	check("real clock advances two fixed steps",work.model.tick==2)
	work.act("RUN / PAUSE"); work._physics_process(.1); check("pause freezes model clock",work.model.tick==2)
	work.act("REPLAY"); work._physics_process(.5)
	check("stall budget records omitted wall time",work.model.tick==2 and is_equal_approx(work.omitted_wall_seconds,.4))
	work.act("MODE"); check("mode resets and pauses",work.model.missing_mode and work.model.tick==0 and not work.running)
	work.act("FALLBACK"); check("fallback explicitly chooses dropout mode",work.model.hold_command and work.model.missing_mode)
	work.slider.set_normalized_value(.9); work.slider.slider_moved.emit(Vector3.ZERO)
	check("real slider edits dropout fraction",is_equal_approx(work.model.dropout,.9))
	work.act("RESET"); check("reset restores all settings and seed",work.model.sample_seed==1847 and not work.model.missing_mode and not work.model.hold_command and work.model.start_y==0)
	work._picked(work.points[0]); work.start_from_hand(work.to_global(Vector3(10,9,5)))
	check("hand input clamps one shared start coordinate",work.model.start_y==.15 and work.model.positions[0]==work.model.positions[1])
	work._dropped(work.points[0]); check("release starts same pair at rest",work.running and not work.held and work.model.commands==[Vector2.ZERO,Vector2.ZERO])
	work.act("NEXT SEED"); check("next seed control is deterministic",work.model.sample_seed==1848 and work.model.tick==0)
	for point in work.points: point.set_physics_process(false)
	await physics_frame; await process_frame; host.queue_free(); await physics_frame; await process_frame
