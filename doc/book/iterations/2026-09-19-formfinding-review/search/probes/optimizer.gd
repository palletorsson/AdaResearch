extends SceneTree
var out:=""
var checks:Array=[]
var histories:Array=[]
func _initialize()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("OPTIMIZER ","PASS " if ok else "FAIL ",message)
func run()->void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var opt=load("res://commons/artifacts/gradient_descent_optimizer/gradient_descent_optimizer.tscn").instantiate();world.add_child(opt);opt.set_process(false);opt._rng.seed=190926
	for pass_index in 2:
		var begin=opt._p;var previous=opt._step;var restarted:=false;var last_point=begin;var path:Array=[]
		for i in 1500:
			last_point=opt._p;path.append(str(last_point));opt._process(.12)
			if opt._step<previous:restarted=true;break
			previous=opt._step
		check(restarted,"bounded default history reaches a new start "+str(pass_index))
		check(opt._trail.is_empty(),"restart clears path samples "+str(pass_index))
		# Dummy rendering does not retain MultiMesh transforms; the museum GPU probe
		# checks the rendered transform after this array-level reset separately.
		histories.append({"start":str(begin),"last_point":str(last_point),"last_raw_gradient":str(opt._grad(last_point.x,last_point.y)),"steps_before_restart":previous,"reason":opt._last_stop,"next_start":str(opt._p),"history":path})
	check(histories[0].reason=="BOUNDARY","default restart explicitly reports boundary, not convergence")
	check(histories[0].start!=histories[1].start,"second history begins from another seeded position")
	opt._p=Vector2(.4,.4);opt._step=29;opt._t=0;opt._process(.12)
	check(opt._step==30,"boundary restart preserves more-than-thirty-step minimum")
	opt._process(.12);check(opt._step==0 and opt._last_stop=="BOUNDARY","next boundary-blocked step receives boundary restart")
	var lo:=-.22;var hi:=-.19
	for i in 40:
		var mid=(lo+hi)*.5
		if opt._grad(mid,0).x>0:hi=mid
		else:lo=mid
	opt._p=Vector2((lo+hi)*.5,0);opt._step=30;opt._t=0;opt._process(.12)
	check(opt._step==0 and opt._last_stop=="SMALL SLOPE","interior small-gradient stop remains distinct and unchanged")
	check(opt._readout_text().contains("SMALL SLOPE") and not opt._readout_text().contains("net training"),"readout states actual stop without network claim")
	var f=FileAccess.open(out+"optimizer.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"histories":histories,"headset_tested":false},"  "));f.close()
	print("OPTIMIZER COMPLETE ",checks.size());quit(0 if checks.all(func(x):return x.ok) else 1)
