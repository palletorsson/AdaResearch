extends SceneTree
const BASE = "res://doc/book/iterations/2026-10-11-swarm-fresh-ghost-student/student/"
var results: Dictionary = {"learner":"experienced coding AI; fresh context", "checks":[], "measurements":{}, "limitations":["Headless synthetic interactions, no physical XR or rendered-layout judgment", "Prepared project and declared dependencies supplied"]}
var failures := 0
var pointer: Node3D

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, name: String, actual = null) -> void:
	results.checks.append({"name":name,"pass":condition,"actual":actual})
	if not condition:
		failures += 1
		print("FAILED: ",name," ",actual)

func near(a: float,b: float,tol: float = 0.00001) -> bool:
	return absf(a-b) < tol

func vec(v: Vector2) -> Array:
	return [v.x,v.y]

func sum_values(a) -> float:
	var total := 0.0
	for x in a: total += x
	return total

func model(hall: String, file: String):
	var script = load(BASE+"reconstructed/"+hall+"/"+file+".gd")
	expect(script != null and script.can_instantiate(),hall+" model loads")
	return script.new()

func key(host,code: int) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.keycode = code
	host._unhandled_key_input(e)

func button(host,name: String) -> void:
	var b = host.get_node_or_null(name)
	expect(b != null,"button exists "+name)
	if b != null: b.pressed.emit()

func host(hall: String):
	var scene = load(BASE+"reconstructed/"+hall+"/study.tscn")
	var h = scene.instantiate()
	h.position = Vector3(3,0,-2)
	h.rotation.y = 0.37
	root.add_child(h)
	h.set_process(false)
	expect(h.get_script() != null,hall+" full host loads and enters tree")
	return h

func grab(h,p,at) -> void:
	p.on_desktop_grab(pointer)
	p.reparent(pointer,true)
	p.global_position = h.to_global(h.place(at)) + Vector3.UP*0.2
	h._process(0.0)

func drop(h,p) -> void:
	p.reparent(h,true)
	p.on_desktop_drop(pointer)
	h._process(0.0)

func dispose(h) -> void:
	h.free()

func physarum() -> void:
	var m = model("physarum","trail")
	m.step()
	expect(near(sum_values(m.values),6),"Physarum first deposits total six",sum_values(m.values))
	m.reset()
	m.deposit(m.sensor_position(0,m.TURN))
	m.step()
	expect(near(m.headings[0],PI/4),"Physarum left mark changes heading")
	m.reset()
	m.deposit(m.sensor_position(0,m.TURN))
	m.deposit(m.sensor_position(0,-m.TURN))
	m.step()
	expect(near(m.headings[0],0),"Physarum side tie keeps heading")
	m.reset(); m.values[0] = 4; m.step()
	expect(near(m.values[0],4*.92),"Physarum untouched mark fades")
	var totals := []
	for retention in [.92,.55]:
		m.reset(); m.retention = retention
		for n in range(40): m.step()
		totals.append(sum_values(m.values))
	results.measurements.physarum_tick40_totals = totals
	expect(totals[0]>totals[1],"Physarum lower retention leaves smaller total at tick40",totals)
	var h = host("physarum")
	expect(h.points.size()==6 and h.tiles.size()==256,"Physarum display built")
	button(h,"Run"); h._process(.15)
	expect(h.trail.steps==1,"Physarum physical run signal advances")
	key(h,KEY_R)
	grab(h,h.points[1],Vector2(7.25,2.25))
	var before = sum_values(h.trail.values)
	h._process(.5)
	expect(h.trail.steps==0 and near(sum_values(h.trail.values),before),"Physarum held movement pauses without drawing")
	h.points[1].action_pressed.emit(pointer)
	expect(near(h.trail.values[h.trail.index_at(Vector2(7.25,2.25))],1),"Physarum action signal stamps transformed cell")
	drop(h,h.points[1]); h._process(.15)
	expect(h.trail.steps==1,"Physarum release resumes")
	button(h,"Retention")
	expect(h.playing and h.trail.steps==0 and near(h.trail.retention,.55),"Physarum retention resets and keeps run")
	dispose(h)

func flow() -> void:
	var m = model("flow","field")
	var field_before = m.vectors.duplicate()
	m.step()
	expect(m.velocities[0].is_equal_approx(Vector2(.3,0)) and near(m.positions[0].x,4.015),"Flow first integration",vec(m.positions[0]))
	for n in range(50): m.step()
	expect(m.vectors==field_before,"Flow agents never write vectors")
	m.reset(); m.patch_mode=1; m.set_patch(); m.positions[0]=Vector2(9,8); m.velocities[0]=Vector2(3,0); m.step()
	expect(near(m.velocities[0].x,2.7),"Flow zero brakes")
	var h = host("flow")
	expect(h.points.size()==6 and h.arrows.size()==256,"Flow full display built")
	key(h,KEY_1); h._process(.05)
	var other_velocity = h.field.velocities[1]
	grab(h,h.points[0],Vector2(2.25,2.25)); h._process(.5)
	expect(h.field.steps==1 and h.field.velocities[0]==Vector2.ZERO and h.field.velocities[1]==other_velocity,"Flow held pause clears selected velocity only")
	h.points[0].action_pressed.emit(pointer)
	expect(h.field.sample(Vector2(2.25,2.25))==Vector2(0,1),"Flow trigger cycles shared cell")
	drop(h,h.points[0]); h._process(.05)
	expect(h.field.velocities[0].y>0,"Flow released point reads edited north field")
	var pos = h.field.positions.duplicate(); var vel = h.field.velocities.duplicate()
	button(h,"Patch")
	expect(pos==h.field.positions and vel==h.field.velocities,"Flow patch preserves moving state")
	button(h,"Reset")
	expect(not h.playing and h.field.steps==0 and h.field.sample(Vector2(2.25,2.25))==Vector2.RIGHT,"Flow reset clears edits and pauses")
	dispose(h)

func boids() -> void:
	var m = model("boids","flock")
	expect(m.neighbours(0)==[1,2],"Boids initial neighbour membership")
	m.step(); expect(m.velocities[0].is_equal_approx(Vector2(.7,0)),"Boids separation slows before reversing")
	m.reset(); m.mode=1; m.step()
	expect(m.velocities[0].is_equal_approx(Vector2(.9,.2)),"Boids alignment step")
	m.positions.assign([Vector2(0,8),Vector2(15.9,8)]); m.velocities.assign([Vector2(1,0),Vector2.ZERO])
	expect(m.neighbours(0).is_empty(),"Boids wrap seam is not periodic neighbourhood")
	m.step(); expect(m.velocities[0]==Vector2(1,0),"Boids isolated point coasts")
	m.positions.assign([Vector2(8,8),Vector2(8,9),Vector2(8,7)]); m.velocities.assign([Vector2(1,0),Vector2(0,2),Vector2(0,-2)])
	m.step(); expect(near(m.velocities[0].x,.9),"Boids zero average requests braking")
	var a = model("boids","flock"); var b = model("boids","flock")
	a.mode=3; b.mode=3; b.positions.reverse(); b.velocities.reverse(); a.step(); b.step(); b.positions.reverse(); b.velocities.reverse()
	var error := 0.0
	for i in range(6): error=maxf(error,a.positions[i].distance_to(b.positions[i]))
	expect(error<.00001,"Boids snapshot order independence",error)
	var h = host("boids")
	button(h,"Run"); h._process(.05)
	grab(h,h.points[2],Vector2(8,8)); h.points[2].action_pressed.emit(pointer); h._process(.3)
	expect(h.witness==2 and h.flock.steps==1 and h.flock.velocities[2]==Vector2.ZERO,"Boids hold/select pauses whole model")
	key(h,KEY_2); key(h,KEY_3)
	drop(h,h.points[2]); key(h,KEY_R)
	expect(not h.playing and h.flock.mode==1 and near(h.flock.radius,2),"Boids reset preserves selected rule/radius")
	expect(h.halos.size()==6 and h.arrows.size()==4,"Boids rings and request arrows constructed")
	dispose(h)

func abm() -> void:
	var m = model("abm","foragers")
	m.positions[0]=Vector2(13,8); m.velocities[0]=Vector2(-3,0)
	m.step(); expect(not m.carrying[0],"ABM exact contact boundary excluded before move")
	m.step(); expect(m.carrying[0],"ABM movement arrival detected next tick")
	m.positions[0]=m.HOME; m.velocities[0]=Vector2.ZERO; m.step()
	expect(not m.carrying[0] and m.delivered==1,"ABM delivers once")
	m.step(); expect(m.delivered==1,"ABM second home tick does not redeliver")
	m.values[0]=3; var ticks=m.steps; m.replace_agents()
	expect(m.values[0]==3 and m.steps==ticks and m.delivered==1,"ABM replace retains shared records")
	var h = host("abm")
	grab(h,h.points[0],Vector2(12,8)); h.points[0].action_pressed.emit(pointer)
	button(h,"Step"); button(h,"Replace"); button(h,"Reset")
	expect(h.model.steps==0 and not h.model.carrying[0],"ABM held step/reset/replace blocked and no pickup")
	drop(h,h.points[0]); button(h,"Step")
	expect(h.model.carrying[0] and h.cargo[0].visible and not h.sensors[0].visible,"ABM host contact and cargo display")
	grab(h,h.points[0],Vector2(3,8)); drop(h,h.points[0]); key(h,KEY_2)
	expect(h.model.delivered==1 and not h.cargo[0].visible and h.sensors[0].visible,"ABM host delivery and sensors restored")
	button(h,"Replace"); expect(h.model.delivered==1 and h.model.steps==2,"ABM host replace scope")
	key(h,KEY_R); expect(h.model.delivered==0 and h.model.steps==0 and near(sum_values(h.model.values),0),"ABM host clear scope")
	dispose(h)

func ant() -> void:
	var m = model("ant","colony")
	m.positions.assign([Vector2(8,2)]); m.velocities.assign([Vector2(3,0)]); m.carrying.assign([false]); m.energy.assign([1.0])
	m.step(); var address=m.index_at(m.positions[0])
	expect(near(m.home[address],.49875) and m.food[address]==0,"Ant first search writes home only",[m.home[address],m.food[address]])
	m.reset(); m.positions[0]=m.FOOD; m.velocities[0]=Vector2(3,0); m.step()
	expect(m.carrying[0] and m.velocities[0].x<0 and near(m.energy[0],.9975),"Ant contact reverses, renews and switches flag")
	m.positions[0]=m.HOME; m.step(); m.step()
	expect(m.delivered==1 and not m.carrying[0],"Ant home counts once")
	m.reset(); m.deposit_amount=0; m.step()
	expect(near(sum_values(m.home),8) and near(sum_values(m.food),8),"Ant zero agent deposits still leaves source emissions")
	m.positions.assign([Vector2(8,2)]); m.velocities.assign([Vector2(3,0)]); m.carrying.assign([false]); m.energy.assign([1.0]); m.home.fill(0); m.food.fill(0)
	for n in range(400): m.step()
	expect(m.energy[0]<.00001,"Ant isolated no-contact energy expires",m.energy[0])
	var h = host("ant")
	expect(h.points.size()==24 and h.home_tiles.multimesh.instance_count==256,"Ant full room and multimeshes built")
	key(h,KEY_1)
	grab(h,h.points[3],Vector2(12,8)); h.points[3].action_pressed.emit(pointer)
	var energy=h.model.energy[3]; button(h,"Step1")
	expect(h.witness==3 and h.model.steps==0 and h.model.energy[3]==energy,"Ant hold/select keeps state and blocks step")
	drop(h,h.points[3]); button(h,"Step-1")
	expect(h.model.carrying[3] and h.cargo[3].visible and h.captions[0].text.contains("READ HOME"),"Ant other bank updates shared model and readout")
	button(h,"Replace1"); expect(h.model.steps==1 and sum_values(h.model.food)>0 and not h.model.carrying[3],"Ant replace keeps channels")
	button(h,"Reset-1"); expect(h.model.steps==0 and near(sum_values(h.model.home),0),"Ant clear empties source before next tick")
	dispose(h)

func pso() -> void:
	var m = model("pso","swarm")
	var valid := true
	for i in range(24): valid = valid and near(m.score(m.best_positions[i]),m.best_scores[i])
	expect(valid,"PSO startup remembers matching positions/scores")
	m.positions[0]=Vector2(.2,.1); m.velocities[0]=Vector2(.1,0); m.best_positions[0]=Vector2(.1,.1)
	var parts=m.terms(0,.5,.25,Vector2.ZERO)
	expect((parts[0]+parts[1]+parts[2]).is_equal_approx(Vector2(-.09,-.0375)),"PSO controlled three contributions")
	m.reset(); var monotonic := true; var previous=m.shared_score
	for n in range(200):
		m.step(); monotonic = monotonic and m.shared_score>=previous; previous=m.shared_score
	expect(monotonic,"PSO fixed-objective best nondecreasing",m.shared_score)
	results.measurements.pso_center_after200={"score":m.shared_score,"shared":vec(m.shared_position)}
	var pos=m.positions.duplicate(); var vel=m.velocities.duplicate(); m.change_objective(1)
	valid=true
	for i in range(24): valid=valid and near(m.best_scores[i],m.score(pos[i])) and m.best_positions[i]==pos[i]
	expect(valid and pos==m.positions and vel==m.velocities,"PSO objective switch rescores while preserving motion")
	m.positions.assign([Vector2(6,6),Vector2(-6,-6)]); m.velocities.assign([Vector2.ZERO,Vector2.ZERO]); m.reset_memories()
	var first=m.shared_position; m.positions.reverse(); m.reset_memories()
	expect(first==Vector2(6,6) and m.shared_position==Vector2(-6,-6) and near(m.shared_score,72),"PSO tied corners select first stored record",[vec(first),vec(m.shared_position)])
	var h = host("pso")
	expect(h.points.size()==24 and h.field.multimesh.instance_count==256,"PSO full room built")
	var remembered=h.model.best_positions[0]
	grab(h,h.points[0],Vector2(6,6)); h.points[0].action_pressed.emit(pointer)
	button(h,"Step1"); button(h,"Edge-1"); button(h,"Reset1")
	expect(h.model.steps==0 and h.model.objective==0 and h.model.best_positions[0]==remembered,"PSO holding preserves memory and blocks step/objective/reset")
	drop(h,h.points[0]); button(h,"Step-1")
	expect(h.model.best_positions[0]==remembered,"PSO worse released placement retains old best")
	button(h,"Edge1"); expect(h.model.objective==1 and not h.playing,"PSO edge button changes and pauses")
	key(h,KEY_5); expect(h.model.objective==2,"PSO RIDGE key")
	key(h,KEY_3); expect(h.model.objective==0,"PSO CENTER key")
	key(h,KEY_R); button(h,"Run-1"); h._process(.1)
	expect(h.model.steps==1,"PSO run uses iteration period")
	dispose(h)

func population() -> void:
	var account = model("population","account")
	account.begin(10,2)
	var event={"species":"prey","kind":"birth","amount":2,"nested":{"value":1}}
	account.record(event); event.amount=99; event.nested.value=9
	account.record({"species":"prey","kind":"loss","amount":3})
	account.record({"species":"prey","kind":"supplied","amount":5})
	expect(account.expected("prey")==14 and account.events[0].nested.value==1,"Account deep-copy history and arithmetic")
	account.record({"species":"support","kind":"food","amount":100})
	expect(account.expected("predator")==2 and account.difference("prey",14,false)==5,"Account species/support/filter distinction")
	account.record({"species":"prey","kind":"birth","amount":1}); account.record({"species":"prey","kind":"loss","amount":1})
	expect(account.difference("prey",14)==0,"Account invented birth/loss can cancel without truth")
	var h = host("population")
	expect(h.points.size()==55 and h.model.prey_list.size()==50 and h.account.events.is_empty(),"Population actual ecosystem startup baseline")
	var id=h.model.prey_list[0].get_instance_id(); var p=h.points[id]; var origin=h.model.prey_list[0].get_meta("arrival")
	grab(h,p,Vector3(.1,.1,-.1)); p.action_pressed.emit(pointer)
	button(h,"Step1"); button(h,"Restart-1"); button(h,"Record1")
	expect(h.witness==id and h.model.tick==0 and not h.show_supply and h.model.prey_list[0].get_meta("arrival")==origin,"Population held select/step/restart/filter/origin")
	expect(h.model.prey_list[0].position.distance_to(Vector3(.1,.16666667,-.1))<.0001,"Population transformed three-dimensional recording")
	drop(h,p); key(h,KEY_2); expect(h.model.tick==1,"Population release allows one update")
	button(h,"Restart1")
	# Controlled real birth: make two actual prey eligible and co-located; invoke supplied mating.
	var pa=h.model.prey_list[0]; var pb=h.model.prey_list[1]
	pa.position=Vector3.ZERO; pb.position=Vector3.ZERO; pa.age=pa.lifespan*.5; pb.age=pb.lifespan*.5; pa.health=1; pb.health=1
	h.model.check_for_mate(pa)
	h.paint()
	expect(h.account.total("prey","birth")==1 and h.account.difference("prey",h.model.prey_list.size())==0,"Population observer classifies actual mating birth")
	h.restart()
	var trace := []; var reconciled := true
	for n in range(1800):
		h.model.advance(h.PERIOD)
		var np=h.model.prey_list.size(); var nr=h.model.predator_list.size()
		var gp=h.account.difference("prey",np); var gr=h.account.difference("predator",nr)
		reconciled=reconciled and gp==0 and gr==0
		trace.append([n+1,np,nr,gp,gr,h.account.total("prey","birth"),h.account.total("prey","loss"),h.account.total("prey","supplied")])
	h.paint()
	var supplied=h.account.total("prey","supplied")
	expect(reconciled,"Population both real arrays reconcile all 1800 updates")
	expect(supplied>0,"Population real run exercises support",supplied)
	h.toggle_supply()
	var gap=h.account.difference("prey",h.model.prey_list.size(),h.show_supply)
	expect(gap==supplied,"Population omitted row gap equals cumulative supplies",gap)
	var live_gold:=0
	for body in h.bodies():
		if body.get_meta("arrival")=="supplied": live_gold+=1
	results.measurements.population={"prey":h.model.prey_list.size(),"predators":h.model.predator_list.size(),"supplied_prey":supplied,"supplied_predators":h.account.total("predator","supplied"),"births_prey":h.account.total("prey","birth"),"losses_prey":h.account.total("prey","loss"),"live_supplied_all_species":live_gold,"omitted_prey_gap":gap,"event_count":h.account.events.size()}
	var output=FileAccess.open(BASE+"population_trace.json",FileAccess.WRITE); output.store_string(JSON.stringify({"columns":["tick","prey","predators","prey_gap","predator_gap","prey_births","prey_losses","prey_supplied"],"rows":trace},"\t")); output.close()
	output=FileAccess.open(BASE+"population_events.json",FileAccess.WRITE); output.store_string(JSON.stringify(h.account.events,"\t")); output.close()
	h.restart(); expect(h.account.events.is_empty() and h.points.size()==55 and h.show_supply,"Population restart resets model and account")
	dispose(h)

func variation() -> void:
	var rows := {}
	for name in ["coarse","fine"]:
		var script=load(BASE+"variants/"+name+"/field.gd")
		var m=script.new()
		var dt: float=m.DT
		var first_exit:= -1
		var samples := []
		var max_analytic_error:=0.0
		for n in range(int(round(10.0/dt))):
			m.step()
			if first_exit<0:
				var expected_x=7.6+3.0*dt*(1.0-dt/.5)/(dt/.5)*(1.0-pow(1.0-dt/.5,n+1))
				max_analytic_error=maxf(max_analytic_error,absf(m.positions[0].x-expected_x))
				if m.positions[0].x>=9: first_exit=n+1
			samples.append([n+1,(n+1)*dt,m.positions[0].x,m.velocities[0].x])
		rows[name]={"dt":dt,"steps":m.steps,"first_exit_step":first_exit,"first_exit_time":first_exit*dt if first_exit>=0 else null,"final_position":vec(m.positions[0]),"final_velocity":vec(m.velocities[0]),"max_preexit_geometric_error":max_analytic_error,"trace":samples}
		expect(max_analytic_error<.0001,"Variation "+name+" matches preexit geometric prediction",max_analytic_error)
		var scene=load(BASE+"variants/"+name+"/study.tscn")
		var h=scene.instantiate(); root.add_child(h); h.set_process(false)
		h.playing=true
		for n in range(int(round(10.0/dt))): h._process(dt)
		expect(h.field.steps==m.steps and h.field.positions[0].distance_to(m.positions[0])<.0001,"Variation "+name+" full host matches model",vec(h.field.positions[0]))
		dispose(h)
	expect(rows.coarse.first_exit_step==-1 and near(rows.coarse.final_position[0],8.95,.0001),"Variation coarse remains trapped",rows.coarse.final_position)
	expect(rows.fine.first_exit_step==79,"Variation fine escapes at predicted step79",rows.fine.first_exit_step)
	results.measurements.independent_variation=rows

func run() -> void:
	print("FRESH_STUDENT_PROBE_BEGIN")
	pointer=Node3D.new(); root.add_child(pointer)
	physarum(); print("Completed Physarum")
	flow(); print("Completed Flow")
	boids(); print("Completed Boids")
	abm(); print("Completed ABM")
	ant(); print("Completed Ant")
	pso(); print("Completed PSO")
	population(); print("Completed Population")
	variation(); print("Completed independent Flow variation")
	results["failures"]=failures
	results["check_count"]=results.checks.size()
	results["completed_utc"]=Time.get_datetime_string_from_system(true)
	var file=FileAccess.open(BASE+"results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t")); file.close()
	print("FRESH_STUDENT_PROBE_DONE checks=",results.checks.size()," failures=",failures)
	pointer.free()
	quit(1 if failures else 0)
