extends SceneTree
var checks: Array = []
var failed: Array = []
var observations := {}
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failed.append(label)
	print("[pendulum noise] ","PASS " if passed else "FAIL ",label)
func near(a: float,b: float,tolerance:=0.0000001) -> bool: return absf(a-b)<tolerance
func complete(m: RefCounted) -> void:
	while m.step(): pass
func run() -> void:
	var script=load("res://commons/artifacts/pendulum_noise/pendulum_pair.gd")
	var m=script.new()
	var stream:PackedFloat64Array=m.unit_forces.duplicate()
	check("forty finite Gaussian draws saved locally",stream.size()==40 and Array(stream).all(func(x):return is_finite(x)))
	check("piecewise force holds twelve ticks, then switches",m.force_at(0,1)==m.force_at(11,1) and m.force_at(12,1)==stream[1]*2)
	check("force ends exactly at four seconds",m.force_at(479,1)==stream[39]*2 and m.force_at(480,1)==0 and m.force_at(-1,1)==0)
	check("off/on isolates force and matches drag",m.force_at(0,0)==0 and m.drag_for(0)==m.drag_for(1))
	check("vertical release horizontal force gives F/mL",near(m.acceleration(0,0,2,0),2/1.1))
	check("horizontal force has no tangent component at ninety degrees",near(m.acceleration(PI/2,0,20,0),-9.8/1.1))
	check("damping acceleration opposes angular velocity",near(m.acceleration(0,2,0,.5),-1))
	m.sigma_n=0;complete(m)
	check("zero disturbance yields identical trajectories",m.angle[0]==m.angle[1] and m.omega[0]==m.omega[1] and m.history.all(func(p):return p.angles[0]==p.angles[1]))
	check("finite experiment retains exactly601 snapshots and stops",m.history.size()==601 and m.tick==2400 and not m.step())
	m.sigma_n=2;m.reset();complete(m)
	var original: Array=m.history.duplicate(true)
	check("nonzero disturbance separates responding states",absf(original[120].angles[0]-original[120].angles[1])>.01)
	check("history snapshots retain earlier states",near(original[0].angles[0],.6) and original[0].speeds[0]==0)
	var max_deviation:=0.0
	var peaks:=PackedFloat64Array([0,0]);var last:=PackedFloat64Array([4,4])
	# Re-measure every fixed update independently of core peak/settling bookkeeping.
	m.reset()
	while m.step():
		for lane in 2:
			peaks[lane]=maxf(peaks[lane],absf(m.angle[lane]))
			max_deviation=maxf(max_deviation,absf(m.offset(lane).length()-1.1))
			if m.tick>=480 and (absf(m.angle[lane])>PI/90 or absf(m.omega[lane])>.05):last[lane]=m.tick/120.0
	check("rigid analytic attachment retains1.1m length",max_deviation<.000001)
	check("replay preserves every sample",m.history==original and m.unit_forces==stream)
	check("peaks include initial state and every tick",near(m.peak[0],maxf(.6,peaks[0])) and near(m.peak[1],maxf(.6,peaks[1])))
	check("terminal tolerance measured after forcing, not first crossing",near(m.last_outside[0],last[0]) and near(m.last_outside[1],last[1]))
	observations.off_on={"peaks":m.peak,"settled_at":[m.settled_at(0),m.settled_at(1)],"end_angles":m.angle}
	m.compare_damping=true;m.changed_drag=.35;m.reset();complete(m)
	check("same input and same drag yield identical states",m.angle[0]==m.angle[1] and m.history.all(func(p):return p.angles[0]==p.angles[1]))
	m.changed_drag=1.2;m.reset();complete(m)
	check("same-input mode gives both lanes exactly the same forcing",m.force_at(50,0)==m.force_at(50,1) and m.drag_for(0)!=m.drag_for(1))
	check("changed damping alters the response without resampling",absf(m.history[120].angles[0]-m.history[120].angles[1])>.01 and m.unit_forces==stream)
	observations.damping={"peaks":m.peak,"settled_at":[m.settled_at(0),m.settled_at(1)],"end_angles":m.angle}
	var prior_force:float=m.force_at(0,1);m.sigma_n=4
	check("force amplitude scales saved input exactly",m.force_at(0,1)==2*prior_force and m.unit_forces==stream)
	m.resample(1848);check("new seed changes input and clears state/history",m.unit_forces!=stream and m.tick==0 and m.history.size()==1)
	m.resample(1847);check("seed restores input on this engine",m.unit_forces==stream)
	seed(823);var expected:=randf();seed(823);m.resample(52)
	check("local stream leaves global RNG unchanged",randf()==expected)
	# Independent one-step calculation: velocity-first integration, full nonlinear sin/cos.
	m.reset();var a:float=m.angle[1];var f:float=m.force_at(0,1)
	var w:=(-9.8/1.1*sin(a)+f*cos(a)/1.1)/120.0
	m.step();check("update matches independent velocity-first step",near(m.omega[1],w) and near(m.angle[1],a+w/120))
	# Student transfer: zero-angle, zero-force release must remain at rest.
	m.initial_angle=0;m.sigma_n=0;m.reset();complete(m)
	check("independent zero-release case stays at rest",m.angle==PackedFloat64Array([0,0]) and m.omega==PackedFloat64Array([0,0]) and near(m.energy(0),0))
	check("settling not claimed before completed window",m.settled_at(0)>4);m.reset();check("running settling result stays pending",m.settled_at(0)==-1)
	var envelope_valid:=true
	for s in [1847,1848,90210]:
		m.resample(s);m.sigma_n=6;m.initial_angle=PI/3;m.changed_drag=0;m.compare_damping=true;m.reset();complete(m)
		envelope_valid=envelope_valid and m.history.size()==601 and m.history.all(func(p):return is_finite(p.angles[0]) and is_finite(p.angles[1]) and is_finite(p.speeds[1]))
	check("maximum controls remain finite across three recorded samples",envelope_valid)
	m.sigma_n=0;m.initial_angle=.4;m.reset();complete(m);var positive:float=m.angle[1]
	m.initial_angle=-.4;m.reset();complete(m)
	check("opposite unforced release gives mirrored response",near(m.angle[1],-positive))
	# Compare low-amplitude period to the independently derived small-angle reference.
	m.initial_angle=.0001;m.reset()
	var first_cross:=-1.0;var previous:float=m.angle[1];var error_max:=0.0
	var e0:float=m.energy(1)
	while m.step():
		error_max=maxf(error_max,absf(m.energy(1)-e0)/e0)
		if first_cross<0 and previous>0 and m.angle[1]<=0:first_cross=(m.tick-1+previous/(previous-m.angle[1]))/120.0
		previous=m.angle[1]
	var expected_period:=TAU*sqrt(1.1/9.8)
	check("small-angle quarter period agrees within one tick",absf(first_cross-expected_period/4)<1.0/120)
	check("undamped numerical energy error stays below two percent",error_max<.02)
	observations.numerical_reference={"period_s":expected_period,"first_cross_s":first_cross,"max_relative_energy_error":error_max}
	var host:=Node3D.new();root.add_child(host)
	var work=load("res://commons/artifacts/pendulum_noise/PendulumNoise.tscn").instantiate();host.add_child(work)
	await physics_frame;await process_frame
	check("two carried points and all nearby controls built",work.points.size()==2 and work.buttons.size()==5 and work.sliders.size()==2)
	check("point geometry and constrained frozen release preserved",near(work.points[0].get_child(0).mesh.radius,.14) and work.points[0].freeze and work.points[0].collision_mask==0)
	work.set_physics_process(false);work.set_process(false)
	work.act("RUN / PAUSE");work._physics_process(1.0/60)
	check("model advances two fixed ticks per60Hz callback",work.model.tick==2)
	work.act("RUN / PAUSE");work._physics_process(.1)
	check("pause preserves full state",work.model.tick==2)
	work.act("REPLAY");check("replay restores release and starts",work.model.tick==0 and work.running and near(work.model.angle[0],.6))
	work._physics_process(1)
	check("stall budget exposes discarded time",work.model.tick<=12 and near(work.discarded_wall_seconds,.9))
	work.act("MODE");check("mode restarts comparison and pauses",work.model.compare_damping and work.model.tick==0 and not work.running)
	work.sliders.drag.set_normalized_value(.5);work.sliders.drag.slider_moved.emit(Vector3.ZERO)
	check("damping control selects same-input mode",near(work.model.changed_drag,1.5,.0001) and work.model.compare_damping)
	work.act("RESET");check("reset restores seed,release,mode,parameters",work.model.noise_seed==1847 and near(work.model.sigma_n,2) and near(work.model.changed_drag,1.2) and not work.model.compare_damping and not work.running)
	work._picked(work.points[0],0)
	work.set_release_from_hand(0,work.to_global(work.anchor(0)+Vector3(2,-2,5)))
	check("hand projects onto angle and resets both releases",near(work.model.angle[0],PI/4,.000001) and work.model.angle[0]==work.model.angle[1] and not work.points[1].enabled)
	work.set_release_from_hand(0,work.to_global(work.anchor(0)+Vector3(1,1,0)))
	check("release input bounded at60degrees",near(work.model.initial_angle,PI/3,.000001))
	work._dropped(work.points[0],0)
	check("drop starts zero-speed paired release",work.running and work.points[1].enabled and work.model.omega==PackedFloat64Array([0,0]))
	for i in 70:work.act("RESET")
	check("event receipt bound enforced",work.log_entries.size()==64)
	# Stop child physics before freeing a manually driven, constrained pickable rig.
	for point in work.points: point.set_physics_process(false)
	await physics_frame;await process_frame
	host.queue_free();await physics_frame;await process_frame
	var dest:=OS.get_cmdline_user_args()[0]
	var file:=FileAccess.open(dest,FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failures":failed,"observations":observations},"\t"));file.close()
	quit(0 if failed.is_empty() else 1)
