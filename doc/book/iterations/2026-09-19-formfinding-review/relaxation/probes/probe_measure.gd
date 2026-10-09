extends SceneTree
var OUT := ""
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):OUT=a.trim_prefix("--out=")
	run.call_deferred()
func run() -> void:
	var rows:Array=[]
	var shapes=load("res://commons/soft_body/soft_body_shapes.gd")
	for passes in [1,4,8,12]:
		var sim=shapes.make_cloth(10,8,0.085,"top_corners",0.75)
		sim.constraint_passes=passes;sim.gravity=Vector3(0,-3,0);sim.damping=0.99;sim.floor_y=-10
		for i in range(2400):
			sim.step()
			if i+1 in [60,420,2400]:
				var signed_sum=0.0;var abs_sum=0.0;var worst=0.0;var worst_index=-1;var low=100.0
				for j in sim.springs.size():
					var s=sim.springs[j];var err=(sim.positions[s[0]].distance_to(sim.positions[s[1]])-s[2])/s[2]
					signed_sum+=err;abs_sum+=absf(err)
					if absf(err)>worst:worst=absf(err);worst_index=j
				for p in sim.positions:low=minf(low,p.y)
				rows.append({"passes":passes,"steps":i+1,"particles":sim.positions.size(),"springs":sim.springs.size(),"signed_mean_percent":signed_sum/sim.springs.size()*100,"mean_absolute_percent":abs_sum/sim.springs.size()*100,"worst_absolute_percent":worst*100,"worst_spring_index":worst_index,"lowest_y":low})
	var f=FileAccess.open(OUT+"measurement.json",FileAccess.WRITE);f.store_string(JSON.stringify({"description":"Godot source solver, undriven cloth, default step0.0166667. Measurements relative to authored rest lengths; no renderer.","rows":rows},"  "));f.close();print(JSON.stringify(rows));quit()
