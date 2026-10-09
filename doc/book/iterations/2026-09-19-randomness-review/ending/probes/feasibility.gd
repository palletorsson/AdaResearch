extends SceneTree
var out:=""
var checks:Array=[]
var runs:Array=[]
func _initialize()->void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out=a.trim_prefix("--out=")
	run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("PHEROMONE ","PASS " if ok else "FAIL ",message)
func experiment(law:String)->Dictionary:
	var p=load("res://algorithms/randomness/pheromone_terrain/pheromone_terrain.tscn").instantiate()
	p.rule=law;p.walk_seed=190919;p._init_rng()
	p.mesh_instance=p.get_node("Plane/MeshInstance3D")
	p.x_segments=p.mesh_instance.mesh.subdivide_width;p.y_segments=p.mesh_instance.mesh.subdivide_depth
	p.mesh_instance.set_meta("plane_width",20.0);p.mesh_instance.set_meta("plane_height",20.0)
	p._initialize_grids();p._create_walkers()
	var initial=p.walkers.duplicate(true)
	for i in 300:
		p._decay_pheromones(1.0/p.walk_speed);p._walk_step()
	var visited:=0;var high:=0;var sum_height:=0.0;var sum_signal:=0.0;var peak:=0.0
	for y in p.vertex_grid.size():
		for x in p.vertex_grid[y].size():
			var h:float=p.vertex_grid[y][x].y
			if h>0:visited+=1
			if h>1:high+=1
			sum_height+=h;sum_signal+=p.pheromone_grid[y][x];peak=maxf(peak,h)
	var signature=JSON.stringify({"vertices":p.vertex_grid,"pheromone":p.pheromone_grid,"walkers":p.walkers,"rng":str(p._rng.state)}).sha256_text()
	var result={"rule":law,"steps":300,"initial":initial,"signature":signature,"visited":visited,"above_one":high,"sum_height":sum_height,"sum_signal":sum_signal,"peak":peak,"rng_state":str(p._rng.state)}
	p.free();return result
func run()->void:
	for law in ["trail","avoid","trail","avoid"]:runs.append(experiment(law))
	check(runs[0].initial==runs[1].initial,"both laws start with the same seeded walkers")
	check(runs[0].signature==runs[2].signature,"fixed-step attraction replays exactly")
	check(runs[1].signature==runs[3].signature,"fixed-step avoidance replays exactly")
	check(runs[0].signature!=runs[1].signature,"existing law change produces different histories")
	check(runs[0].visited!=runs[1].visited,"same-count runs produce measurably different coverage")
	var f=FileAccess.open(out+"feasibility.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"runs":runs,"scope":"source algorithms in isolated node, no renderer or continuous live timing"},"  "));f.close()
	quit(0 if checks.all(func(c):return c.ok) else 1)
