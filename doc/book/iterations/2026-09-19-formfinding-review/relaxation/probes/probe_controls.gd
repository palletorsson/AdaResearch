extends SceneTree
var OUT := ""
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):OUT=a.trim_prefix("--out=")
	run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message)
	print("CONTROLS ","PASS " if ok else "FAIL ",message)
func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var cam=Camera3D.new();root.add_child(cam)
	var scene=load("res://commons/artifacts/verlet_workbench/verlet_workbench.tscn")
	var configured=scene.instantiate();configured.apply_grid_config({"comparison":true})
	var built_count=configured.get_child_count();root.add_child(configured);configured.set_process(false);configured.set_physics_process(false)
	check(configured.get_child_count()==built_count,"pre-tree config followed by ready builds one console only")
	check(configured.find_children("PASSES*","Node3D",true,false).size()==1,"one PASSES input in preconfigured scene")
	var ui=scene.instantiate();root.add_child(ui);ui.set_process(false);ui.set_physics_process(false)
	check(not ui.comparison and ui._dial!=null and ui.buttons.is_empty(),"default legacy dial and ambient mode preserved")
	var before=ui._sim.positions.duplicate();ui._process(.1)
	check(ui._sim.positions!=before and ui._sim.gravity.x>0,"legacy frame still drives gust and cloth")
	var old=load("res://doc/book/iterations/2026-09-19-formfinding-review/relaxation/probes/legacy_verlet_workbench.gd").new()
	root.add_child(old);old.set_process(false);old._process(.1)
	check(old._sim.positions==ui._sim.positions and old._sway.rotation==ui._sway.rotation,"legacy positions and sway match frozen source exactly")
	old.apply_grid_config({"stiffness":.6});ui.apply_grid_config({"stiffness":.6})
	old._process(.2);ui._process(.2)
	check(old._sim.positions==ui._sim.positions and old._t==ui._t,"legacy reconfiguration retains the original gust phase")
	ui.apply_grid_config({"stiffness":.75});old.queue_free()

	var foreign=Node3D.new();foreign.name="GridAttachment";ui.add_child(foreign)
	ui.apply_grid_config({"comparison":true});ui.set_process(false);ui.set_physics_process(false)
	check(ui.comparison and ui.buttons.size()==3 and ui._dial==null,"comparison replaces furniture with three controls")
	check(is_instance_valid(foreign) and foreign.get_parent()==ui,"grid attachment survives opt-in rebuild")
	check(ui.wind_enabled and ui.simulation_steps==60,"initial wind on and sixty setup steps")
	var sim_id=ui._sim.get_instance_id();var children=ui.get_child_count();ui.apply_grid_config({"comparison":true})
	check(sim_id==ui._sim.get_instance_id() and children==ui.get_child_count(),"repeated config does not rebuild")
	ui.set_physics_process(false)
	for i in 3:await process_frame
	for passes in [8,12,1,4]:
		press(ui,"PASSES",cam)
		check(ui._sim.constraint_passes==passes and ui.simulation_steps==60 and ui._t==0,"pointer selects and resets passes "+str(passes))
	press(ui,"WIND",cam)
	check(not ui.wind_enabled and ui._sim.gravity==Vector3(0,-3,0),"pointer disables drive with gravity retained")
	var initial=ui._sim.positions.duplicate()
	for i in 360:ui._physics_process(1.0/60)
	var m=ui.comparison_metrics()
	check(ui.simulation_steps==420,"360 fixed updates plus60 setup")
	check(absf(m.mean_absolute_percent-.35918)<.001 and absf(m.worst_absolute_percent-8.9355)<.01,"display measures actual mean and worst absolute error")
	check(absf(m.drop-.607081)<.00001,"drop measured below the pins")
	check(ui._readout.text.contains("WIND OFF") and ui._readout.text.contains("step 420"),"panel identifies drive and integration count")
	check(ui._sway.rotation==Vector3.ZERO,"comparison frame does not add cosmetic motion")
	press(ui,"RESET",cam)
	check(ui._sim.positions==initial and ui.simulation_steps==60 and not ui.wind_enabled,"reset repeats starting pose and preserves selected condition")
	for i in 60:ui._physics_process(1.0/60)
	var sixty=ui._sim.positions.duplicate();press(ui,"RESET",cam)
	for i in 30:ui._physics_process(1.0/30)
	check(ui._sim.positions==sixty and ui.simulation_steps==120,"30Hz and60Hz drive same fixed steps")
	before=ui._sim.positions.duplicate();ui._process(1)
	check(ui._sim.positions==before,"render update does not advance comparison")
	press(ui,"WIND",cam)
	for i in 60:ui._physics_process(1.0/60)
	check(ui._sim.gravity.x>0 and ui._sim.positions!=sixty,"wind produces a different trajectory")
	check(ui.buttons.values().all(func(b):return b.position.y>.9 and b.position.y<1.1),"reachable authored button heights")
	ui.apply_grid_config({"constraint_passes":3,"comparison":false});ui.set_process(false);ui.set_physics_process(false)
	check(ui._sim.constraint_passes==3 and ui._dial!=null and ui.buttons.is_empty(),"numeric legacy budget and disabling lesson both supported")
	for i in 3:await process_frame
	var f=FileAccess.open(OUT+"controls-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("CONTROLS COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
