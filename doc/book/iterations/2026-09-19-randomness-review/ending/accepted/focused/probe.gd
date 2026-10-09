extends SceneTree
var out:=""
var checks:Array=[]
var measurements:Dictionary={}
func _initialize()->void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out=a.trim_prefix("--out=")
	run.call_deferred()
func check(ok:bool,message:String)->void:
	checks.append({"ok":ok,"message":message});print("RANDOM-END ","PASS " if ok else "FAIL ",message)
func sig(p:Node)->String:
	return JSON.stringify({"vertices":p.vertex_grid,"pheromone":p.pheromone_grid,"walkers":p.walkers,"rng":str(p._rng.state)}).sha256_text()
func press(p:Node,i:int)->void:
	var area=p._comparison_panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton");area.button_pressed.emit(area)
func run()->void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var p=load("res://algorithms/randomness/pheromone_terrain/pheromone_terrain.tscn").instantiate()
	p.apply_grid_config({"comparison":true,"walk_seed":190919});world.add_child(p)
	for i in 4:await process_frame
	check(p._terrain_ready and p._comparison_steps==0,"pre-tree comparison configuration starts paused at zero")
	check(p._comparison_panel.find_children("InteractableAreaButton","Area3D",true,false).size()==5,"five existing-style button areas built once")
	check(p._walker_markers.size()==4,"four current-position markers built")
	var initial=sig(p);var starts=p.walkers.duplicate(true)
	p._process(3.0);check(sig(p)==initial,"wall time does not advance comparison history")
	press(p,2);check(p._comparison_steps==1 and sig(p)!=initial,"one STEP signal advances exactly one source step")
	press(p,4);check(p._comparison_steps==0 and sig(p)==initial,"REPLAY resets heights scent walkers and RNG")
	press(p,3);var batch=sig(p)
	check(p._comparison_steps==20,"batch signal advances20steps")
	press(p,4)
	for i in 20:press(p,2)
	check(sig(p)==batch,"twenty single steps equal one batch")
	press(p,4)
	for i in 15:press(p,3)
	var attract=sig(p);measurements.attract_signature=attract
	check(attract=="81625733333439f185d7b8084120884571e122325f4e6c5bac84da37ba9039c2","controlled ATTRACT exactly matches pre-change source fixture")
	press(p,1);check(p.rule=="avoid" and p.walkers==starts and p._comparison_steps==0,"AVOID selects existing law and same starting walkers")
	for i in 15:press(p,3)
	var avoid=sig(p);measurements.avoid_signature=avoid
	check(avoid=="b075a12c93e9ce4d0353cf1e89b05bd7b23598f1521cd44790405ee89d51d051","controlled AVOID exactly matches pre-change source fixture")
	check(avoid!=attract,"law change changes history after same300steps")
	var marker_ok:=true
	for i in 4:
		var w=p.walkers[i];marker_ok=marker_ok and p._walker_markers[i].position.is_equal_approx(p.vertex_grid[w.y][w.x]+Vector3(0,.15,0))
	check(marker_ok,"every marker reports actual current walker position")
	p.apply_grid_config({"comparison":true,"walk_seed":190919})
	check(sig(p)==avoid and p._comparison_steps==300,"repeated unchanged config neither duplicates nor resets history")
	check(p.find_children("StepComparison","Node3D",true,false).size()==1 and p._walker_markers.size()==4,"one panel and four markers survive repeated controls")
	press(p,4);check(p.rule=="avoid" and p._comparison_steps==0,"REPLAY preserves selected law")
	var legacy=load("res://algorithms/randomness/pheromone_terrain/pheromone_terrain.tscn").instantiate();legacy.walk_seed=190919;world.add_child(legacy)
	for i in 4:await process_frame
	legacy.set_process(false);var old=sig(legacy);legacy._process(.2)
	check(not legacy.comparison and legacy._comparison_panel==null and legacy._walker_markers.is_empty(),"legacy live placement adds no controls or markers")
	check(sig(legacy)!=old,"legacy process still advances live simulation")
	var mixer=load("res://commons/artifacts/noise_mixer/noise_mixer.tscn").instantiate();world.add_child(mixer)
	var offsets=mixer._octave_offsets.duplicate();mixer.octaves=1;mixer.lacunarity=1.5;var one=mixer._fbm(.31,.49);mixer.lacunarity=3.0
	check(is_equal_approx(one,mixer._fbm(.31,.49)),"one octave ignores spacing of absent later layers")
	mixer.octaves=4;var many=mixer._fbm(.31,.49);mixer.persistence=.3
	check(not is_equal_approx(many,mixer._fbm(.31,.49)),"persistence changes finite layered value")
	mixer._octaves_slider.set_normalized_value(0);mixer._on_octaves_changed(0)
	check(mixer.octaves==1 and mixer._material.albedo_texture!=null,"OCT callback regenerates current texture")
	check(mixer._octave_offsets==offsets,"OCT/PER changes retain seeded offsets")
	var projectile=load("res://commons/primitives/cubes/projectile_cube.tscn").instantiate();projectile.freeze=true;world.add_child(projectile);projectile.set_physics_process(false)
	projectile.set_falling_field_profile(Vector3(0,-2,0),.25,.45,.2);projectile._rng.seed=101;projectile._physics_process(.45)
	var vel=projectile.velocity;var timer=projectile._jitter_timer
	check(absf(vel.x)<=.25 and absf(vel.z)<=.25 and vel.y>=-2.2 and vel.y<=-1.8,"projectile independently jitters inside configured velocity bands")
	check(timer>=.315 and timer<=.585,"projectile also varies its own jitter interval")
	projectile.set_falling_field_profile(Vector3(0,-2,0),.25,.45,.2);projectile._rng.seed=102;projectile._physics_process(.45)
	check(projectile.velocity!=vel,"same launch velocity with another projectile RNG gives another later velocity")
	projectile.lifetime_timer.stop()
	var f=FileAccess.open(out+"focused.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"measurements":measurements,"headset_tested":false,"collision_playthrough":false},"  "));f.close();quit(0 if checks.all(func(c):return c.ok) else 1)
