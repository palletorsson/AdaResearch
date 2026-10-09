extends SceneTree
class FixedAnneal:
	extends "res://algorithms/optimization/simulatedannealing/simulated_annealing_visualization.gd"
	var offered := Vector2.ZERO
	func _generate_neighbor() -> Vector2:return offered
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
var out := ""
var checks:Array=[]
var observations:Dictionary={}
func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("SEARCH FOCUSED ","PASS " if ok else "FAIL ",message)
func run()->void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var a=FixedAnneal.new();world.add_child(a);a.set_process(false);await process_frame
	a.basin_hop_enabled=false;a.adaptive_enabled=false;a.equilibrium_steps=999999;a.problem_type="sphere"
	var counts:Array=[]
	for temp in [0.2,0.002]:
		seed(20260919);var accepted:=0
		for i in 2000:
			a.current_solution=Vector2.ZERO;a.current_energy=0;a.current_temperature=temp;a.offered=Vector2(sqrt(.05),0)
			a._perform_annealing_step()
			if a.current_solution!=Vector2.ZERO:accepted+=1
		counts.append(accepted)
	observations["uphill_trials"]={"delta_energy":.05,"trials":2000,"warm_temperature":.2,"warm_accepted":counts[0],"cold_temperature":.002,"cold_accepted":counts[1],"warm_probability":exp(-.05/.2),"cold_probability":exp(-.05/.002)}
	check(counts[0]>1480 and counts[0]<1650,"actual acceptance branch samples expected warm probability")
	check(counts[1]==0 and exp(-.05/.002)>0,"zero observed cold acceptances does not make the probability zero")
	a.current_solution=Vector2(.5,0);a.current_energy=.25;a.offered=Vector2.ZERO;a.current_temperature=.002;a._perform_annealing_step()
	check(a.current_solution==Vector2.ZERO,"a downhill proposal is accepted at cold temperature")
	a.current_temperature=100;a.cooling_rate=.95;a.effective_cooling_rate=.95;a.adaptive_enabled=true;a._recent_accepts.assign([true,true,true]);a._update_temperature()
	check(is_equal_approx(a.current_temperature,93) and is_equal_approx(a.effective_cooling_rate,.93),"high recent acceptance accelerates adaptive cooling")
	a.current_temperature=100;a.effective_cooling_rate=.95;a._recent_accepts.assign([false,false,false]);a._update_temperature()
	check(is_equal_approx(a.current_temperature,97),"low recent acceptance slows adaptive cooling")
	a.adaptive_enabled=false;a.cooling_schedule="exponential";a.current_temperature=100;a._update_temperature()
	check(is_equal_approx(a.current_temperature,95),"nonadaptive exponential schedule uses configured rate")
	a.current_temperature=10;a.initial_temperature=100
	a._temp_slider.set_normalized_value(.5);a._temp_slider.emit_signal("slider_moved",.5)
	check(is_equal_approx(a.initial_temperature,101) and is_equal_approx(a.current_temperature,10),"START T slider changes initial setting without replacing current temperature")
	a._reset_optimization();check(is_equal_approx(a.current_temperature,101),"RESET applies the initial-temperature setting")
	a.initial_temperature=100;a.current_temperature=.1;a.current_solution=Vector2.ZERO;a.current_energy=0;a.best_energy=0;a.accepted_moves=0;a.basin_hops_performed=0;seed(42);a._perform_basin_hop()
	check(a.current_energy>0 and a.current_solution!=Vector2.ZERO and a.accepted_moves==0,"manual basin hop takes an uphill relocation without acceptance trial")
	check(is_equal_approx(a.current_temperature,30) and a.basin_hops_performed==1,"hop reheats to at least thirty percent of initial temperature")
	a.basin_hop_enabled=true;a.stagnation_threshold=80;a.steps_since_improvement=79;a.current_temperature=.1;a.current_solution=Vector2.ZERO;a.current_energy=0;a.offered=Vector2(3,0);var hops=a.basin_hops_performed;a._perform_annealing_step()
	check(a.basin_hops_performed==hops+1,"eightieth non-downhill proposal triggers separate automatic hop")
	a.queue_free();await process_frame
	var native=load("res://algorithms/optimization/simulatedannealing/simulated_annealing_visualization.gd").new();world.add_child(native);native.set_process(false);await process_frame
	var runs:Array=[]
	for run_seed in [11,29,47]:
		native.anneal_seed=run_seed;native._reset_optimization();native._is_running=true
		for i in 1100:
			native._process(native.step_interval)
			if native._is_complete:break
		runs.append({"seed":run_seed,"steps":native.current_iteration,"temperature":native.current_temperature,"hops":native.basin_hops_performed,"best_energy":native.best_energy,"complete":native._is_complete})
		check(native._is_complete and (native.current_temperature<=native.final_temperature or native.current_iteration>=native.max_iterations),"default hybrid run respects declared stopping disjunction seed"+str(run_seed))
	observations["default_runs"]=runs
	native.queue_free();await process_frame
	var q=load("res://commons/artifacts/max_q_basin_room/max_q_basin_room.tscn").instantiate();q.apply_grid_config({"reveal_on_request":true});world.add_child(q);q.set_process(false);await process_frame
	check(q.find_children("InterpretationConsole","",true,false).size()==1,"configured Q build makes one interpretation control")
	check(not q._interpretation_visible and q._deep_label.text=="DEEP / NARROW" and q._shallow_label.text=="SHALLOW / WIDE","Q starts with neutral geometric labels")
	var p=q._sim.positions.duplicate();var tick=q._t;q._toggle_interpretation()
	check(q._interpretation_title.text.contains("not a test of life") and q._interpretation_visible,"Q reveal retains proposition and names interpretive limit")
	check(p==q._sim.positions and tick==q._t,"Q reveal preserves live simulation state")
	q._toggle_interpretation();check(not q._interpretation_visible,"Q comparison can hide interpretation again")
	q._t=2.49;q._process(.02);check(q._sim.positions!=p,"periodic driven lattice keeps changing independently of interpretation")
	q.queue_free();await process_frame
	var f=FileAccess.open(out+"focused.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"observations":observations,"headset_tested":false,"scope":"isolated annealing branches and configured Q control"},"  "));f.close()
	print("SEARCH ANNEALING Q COMPLETE ",checks.size());quit(0 if checks.all(func(x):return x.ok) else 1)
