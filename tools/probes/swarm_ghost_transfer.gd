extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-swarm-ghost-student/"
const HALLS := ["SwarmIntelligence_PhysarumColony", "SwarmIntelligence_FlowFields", "SwarmIntelligence_Boids_Algorithm", "SwarmIntelligence_Agent_Based_Modeling_ABM", "SwarmIntelligence_Ant_Colony_Optimization", "SwarmIntelligence_Particle_Swarm_Optimization", "SwarmIntelligence_Swarm_Intelligence_Algorithms"]
var checks: Array = []
var failures: Array = []
var hosts: Array = []
var observations: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("GHOST ", "PASS " if ok else "FAIL ", title)

func fresh(index: int, file: String):
	return load(OUT+"halls/"+HALLS[index]+"/code/"+file).new()

func xy(p: Vector2) -> Array:
	return [p.x,p.y]

func run() -> void:
	var trail = fresh(0,"trail.gd")
	trail.positions.clear(); trail.headings.clear(); trail.values.fill(0.0)
	trail.retention = 0.8; trail.values[0] = 2.0
	trail.step(); trail.step()
	check("Physarum: abandoned mark 2 retains 1.28 after two 80-percent ticks",is_equal_approx(trail.values[0],1.28))
	check("Physarum: memory exists without any remaining agent",trail.positions.is_empty() and trail.values[0]>0)
	trail.reset()
	var sensor: Vector2 = trail.sensor_position(0,trail.TURN)
	trail.deposit(sensor); trail.deposit(sensor)
	observations.physarum_recipe = {"without_reset_after_prior_deposit":trail.sense(0,trail.TURN),"printed_expected":1.0}
	check("Physarum: exact-one recipe requires a clean cell",is_equal_approx(trail.sense(0,trail.TURN),2.0))
	trail.reset(); trail.deposit(trail.sensor_position(0,trail.TURN))
	check("Physarum: reset then one deposit supplies the stated value",is_equal_approx(trail.sense(0,trail.TURN),1.0))

	var field = fresh(1,"field.gd")
	field.positions.assign([Vector2(8,8)]); field.velocities.assign([Vector2(1,0)])
	field.vectors.fill(Vector2.ZERO)
	var before: PackedVector2Array = field.vectors.duplicate()
	field.step()
	check("Flow: a zero direction brakes velocity to0.9",field.velocities[0].is_equal_approx(Vector2(.9,0)))
	check("Flow: reading a zero field does not change its contents",field.vectors==before)
	var flock = fresh(2,"flock.gd")
	flock.positions.assign([Vector2(8,8)]); flock.velocities.assign([Vector2(1,0)])
	flock.mode=1; flock.step()
	check("Boids: an empty neighbourhood coasts at velocity1",flock.velocities[0].is_equal_approx(Vector2(1,0)))
	check("Flow-to-Boids: identical initial motion has different missing-input responses",not flock.velocities[0].is_equal_approx(field.velocities[0]))
	flock.positions.assign([Vector2(8,8),Vector2(9,8),Vector2(7,8)])
	flock.velocities.assign([Vector2(1,0),Vector2(0,2),Vector2(0,-2)])
	flock.step()
	check("Boids: present neighbours with cancelling velocities request braking",flock.velocities[0].is_equal_approx(Vector2(.9,0)))
	flock.positions.assign([Vector2(8,8),Vector2(10,8)]); flock.radius=2.0
	check("Boids: exactly on radius is excluded",flock.neighbours(0).is_empty())
	flock.radius=2.001
	check("Boids: a small radius increase includes the same neighbour",flock.neighbours(0)==[1])

	var foragers = fresh(3,"foragers.gd")
	foragers.positions.assign([Vector2(8,8)]); foragers.velocities.assign([Vector2.ZERO]); foragers.carrying.assign([true])
	foragers.return_speed=2.0
	foragers.values[foragers.index_at(foragers.sensor_position(0,foragers.TURN))]=8.0
	foragers.step()
	check("ABM: speed2 return ignores a strong side trace",foragers.velocities[0].is_equal_approx(Vector2(-.2,0)))
	check("ABM: independent speed2 edit moves to7.99,8",foragers.positions[0].is_equal_approx(Vector2(7.99,8)))
	var retained: PackedFloat32Array = foragers.values.duplicate()
	foragers.replace_agents()
	check("ABM: replacement preserves inherited field",foragers.values==retained and foragers.steps==1)
	foragers.reset()
	check("ABM: reset clears field and retains chosen speed",foragers.values.count(0.0)==256 and foragers.return_speed==2.0)

	var colony = fresh(4,"colony.gd")
	colony.positions.assign([Vector2(8,8)]); colony.velocities.assign([Vector2.RIGHT]); colony.carrying.assign([true]); colony.energy.assign([1.0])
	colony.home.fill(0.0); colony.food.fill(0.0)
	colony.home[colony.index_at(colony.sensor_position(0,colony.TURN))]=8.0
	check("ACO: returner follows side home sample instead of direct home coordinate",colony.desired_velocity(0).is_equal_approx(Vector2.RIGHT.rotated(PI/4)*3.0))
	colony.carrying[0]=false
	check("ACO: same body searching ignores that home sample",colony.desired_velocity(0).is_equal_approx(Vector2(3,0)))
	colony.deposit_amount=.4; colony.deposit(0)
	var address: int = colony.index_at(Vector2(8,8))
	check("ACO: independent deposit0.4 writes home only when searching",is_equal_approx(colony.home[address],.4) and is_zero_approx(colony.food[address]))
	colony.carrying[0]=true; colony.deposit(0)
	check("ACO: changed state writes food without erasing home",is_equal_approx(colony.home[address],.4) and is_equal_approx(colony.food[address],.4))

	var swarm = fresh(5,"swarm.gd")
	for i in range(10): swarm.step()
	var positions: Array = swarm.positions.duplicate()
	var velocities: Array = swarm.velocities.duplicate()
	swarm.change_objective(2)
	check("PSO: changed objective retains current positions and movement",swarm.positions==positions and swarm.velocities==velocities)
	var scored := true
	for i in range(positions.size()):
		scored = scored and swarm.best_positions[i]==positions[i] and is_equal_approx(swarm.best_scores[i],-pow(positions[i].x-positions[i].y,2)/2)
	check("PSO: all personal records are rebuilt under RIDGE",scored)
	check("PSO: different diagonal positions have the same zero score",is_zero_approx(swarm.score(Vector2(-2,-2))) and is_zero_approx(swarm.score(Vector2(3,3))))
	var memories: Array = swarm.best_positions.duplicate()
	swarm.social_pull=0
	var terms: Array = swarm.terms(0,.5,.25,Vector2(5,5))
	check("PSO: removing social pull leaves memory present",terms[2].is_zero_approx() and swarm.best_positions==memories)

	var account = fresh(6,"account.gd")
	account.begin(8,2)
	var event: Dictionary = {"kind":"birth","species":"prey","amount":3}
	account.record(event); event.amount=300
	account.record({"kind":"loss","species":"prey","amount":2})
	account.record({"kind":"supplied","species":"prey","amount":4})
	check("Account: altered caller record does not rewrite birth history",account.total("prey","birth")==3)
	check("Account: novel8plus3minus2plus4 fixture reconciles at13",account.expected("prey")==13 and account.difference("prey",13)==0)
	var history: Array = account.events.duplicate(true)
	check("Account: hiding supply exposes gap4",account.expected("prey",false)==9 and account.difference("prey",13,false)==4)
	check("Account: filtered reading does not delete events",account.events==history)
	account.record({"kind":"food","species":"support","amount":100})
	check("Account: food support does not add creatures",account.expected("prey")==13 and account.expected("predator")==2)

	for i in range(HALLS.size()): await host_check(i)
	investigation()
	var result: Dictionary = {"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"host_halls":hosts,"observations":observations,"scope":"Author-operated ghost rehearsal from ZIP-extracted printed scripts. New transfer fixtures, complete host instantiation, synthetic desktop grip and optional RIDGE investigation. No physical headset or independent reader."}
	FileAccess.open(OUT+"transfer-checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)

func tick() -> void:
	await physics_frame
	await process_frame

func host_check(index: int) -> void:
	var host = load(OUT+"halls/"+HALLS[index]+"/code/study.tscn").instantiate()
	host.position=Vector3(5,.3,-4); host.rotation.y=.65
	root.add_child(host); host.set_process(false); host.playing=false
	await tick()
	var key: String = ["trail","field","flock","model","model","model","model"][index]
	var model = host.get(key)
	var clock_name: String = "tick" if index==6 else "steps"
	var expected_count: int = [6,6,6,6,24,24,55][index]
	check(HALLS[index]+": complete printed host creates expected bodies",host.points.size()==expected_count)
	var point = host.points.values()[0] if index==6 else host.points[0]
	check(HALLS[index]+": host uses reconstructed PointBody",point.get_script().resource_path==OUT+"halls/"+HALLS[index]+"/code/point_body.gd")
	if index==2:
		observations.boids_recipe={"has_one_step_method":host.has_method("single_step"),"controls":["Run","Rule","Radius","Reset"],"numerical_checks_need_model_step":true}
		check("Boids reading audit: printed host has no single-step control",not host.has_method("single_step"))
	var pointer := Node3D.new(); root.add_child(pointer)
	var count_before: int = model.get(clock_name)
	point.on_desktop_grab(pointer)
	point.global_position=host.to_global(Vector3(.24,1.1,.32))
	host.playing=true; host._process(.2)
	check(HALLS[index]+": synthetic held point pauses model",point.held() and model.get(clock_name)==count_before)
	var local: Vector3 = host.to_local(point.global_position)
	var recorded = host.record(local)
	if index<6:
		check(HALLS[index]+": moved/rotated host records local coordinates",model.positions[0].distance_to(recorded)<.001)
	else:
		var body = host.bodies()[0]
		check(HALLS[index]+": population body records local coordinates",body.position.distance_to(recorded)<.001)
	host.playing=false; point.on_desktop_drop(pointer); host._process(0.0)
	check(HALLS[index]+": paused release stays paused",not point.held() and not host.playing and model.get(clock_name)==count_before)
	host.playing=true; host._process(.31)
	check(HALLS[index]+": complete model advances after release",model.get(clock_name)>count_before)
	host.playing=false
	if index==6:
		var count: int = host.bodies().size()
		var events: Array = host.account.events.duplicate(true)
		host.toggle_supply()
		check("Account host: filtering preserves body population and event history",host.bodies().size()==count and host.account.events==events)
	hosts.append(HALLS[index])
	host.queue_free(); pointer.queue_free(); await tick()

func measurement(swarm) -> Dictionary:
	var largest := 0.0
	var mean := 0.0
	var first: Array = []
	var positions: Array = []
	for i in range(swarm.positions.size()):
		var p: Vector2 = swarm.positions[i]
		positions.append(xy(p))
		mean+=swarm.score(p)
		if i<3: first.append(swarm.score(p))
		for j in range(i+1,swarm.positions.size()): largest=maxf(largest,p.distance_to(swarm.positions[j]))
	return {"step":swarm.steps,"spread":largest,"mean_current_score":mean/swarm.positions.size(),"current_scores_0_1_2":first,"shared_best_score":swarm.shared_score,"positions":positions}

func sample_run(path: String) -> Array:
	var swarm=load(path).new()
	swarm.change_objective(2); swarm.reset()
	var samples: Array = [measurement(swarm)]
	for i in range(100):
		swarm.step()
		if swarm.steps in [20,100]:samples.append(measurement(swarm))
	return samples

func investigation() -> void:
	var outcomes: Array = []
	for seed in [101006,101007]:
		var starts: Array = []
		for pull in [1.5,0.3]:
			var path: String = OUT+"investigation/seed-%d-pull-%.1f/swarm.gd" % [seed,pull]
			var samples: Array = sample_run(path)
			var repeat: Array = sample_run(path)
			check("RIDGE: seed%d pull%.1f repeats exactly" % [seed,pull],samples==repeat)
			starts.append(samples[0].positions)
			outcomes.append({"seed":seed,"social_pull":pull,"samples":samples})
		check("RIDGE: seed%d starts matched across both pulls" % seed,starts[0]==starts[1])
	observations.ridge=outcomes
	observations.ridge_hypothesis="Weaker shared pull0.3 will leave a wider current population at step100 than1.5, potentially with worse current scores; hypothesis is not a pass condition."
