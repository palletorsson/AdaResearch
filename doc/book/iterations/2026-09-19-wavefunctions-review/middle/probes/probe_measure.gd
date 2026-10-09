extends SceneTree
var OUT:=""
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):OUT=a.trim_prefix("--out=")
	run.call_deferred()
func run() -> void:
	var rows:Array=[]
	for mode in ["Sine","Pulse"]:
		for k in [1.5,0.0]:
			var grid=load("res://algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.tscn").instantiate()
			grid.excitation_mode=mode;grid.coupling_strength=k;root.add_child(grid);grid.set_process(false)
			var peaks:Dictionary={};var final:Dictionary={}
			for frame in 960:
				grid.time+=1.0/120;grid._apply_excitation(1.0/120);grid._update_oscillators(1.0/120)
				for p in [Vector2i(6,6),Vector2i(6,7),Vector2i(6,8),Vector2i(6,10),Vector2i(1,1)]:
					var d=absf(grid.get_displacement_at(p.x,p.y));peaks[str(p)]=maxf(peaks.get(str(p),0.0),d);final[str(p)]=d
			rows.append({"mode":mode,"coupling":k,"dt":1.0/120,"duration":8,"peaks_m":peaks,"last_absolute_m":final});root.remove_child(grid);grid.queue_free()
	var f=FileAccess.open(OUT+"measurements.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close();print(JSON.stringify(rows));quit()
