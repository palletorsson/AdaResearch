extends "res://tools/probes/sine_yoke.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var Script: GDScript = load("res://commons/artifacts/matter_reference/knitter.gd")
	if Script.reload()!=OK:quit(1);return
	var rows: Array = []
	var direct := Node3D.new();direct.set_script(Script);direct.apply_grid_config({"rule":90,"width":7,"rows":3});scene.add_child(direct);await tick(3);direct.finish_computed()
	check("Rule90 direct knit matches the source's XOR neighbourhood",direct.grid==[[0,0,0,1,0,0,0],[0,0,1,0,1,0,0],[0,1,0,0,0,1,0],[1,0,1,0,1,0,1]] and direct.computed==21 and direct.stitched==0);direct.queue_free();await tick(3)
	for pattern in range(8):
		for wanted in [0,1]:
			var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"study":"gravity-knitter","rule":255 if wanted else 0,"width":3,"rows":1});work.position.y = -18;scene.add_child(work);await tick(3);work.grid[0] = [(pattern>>2)&1,(pattern>>1)&1,pattern&1];work.column = 1;work.command("STEP")
			for n in range(2700):
				if work.stitched==1 or work.jams>=3:break
				await tick()
			var got: int = work.grid[1][1];check("Gravity pattern "+str(pattern)+" actual output "+str(wanted),work.stitched==1 and got==wanted and work.computed==0);rows.append({"pattern":pattern,"wanted":wanted,"got":got,"physical":work.stitched,"jams":work.jams});work.queue_free();await tick(3)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows,"scope":"All 16 physical pattern/output combinations (rules 0 and 255); direct algorithm output explicitly separated from physical stitches. No mathematical fallback after jams. Registered-floor placement has a separate actual-player receipt."};FileAccess.open(out.path_join("knitter-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
