extends "res://tools/probes/sine_yoke.gd"
## Physical witnesses at negative height and rotated placements, no output nudges.
func fixture(study: String,config: Dictionary = {}) -> Node3D:
	var work: Node3D = load("res://commons/artifacts/matter_experiments/friction_studies.tscn").instantiate();var c := config.duplicate(true);c.study = study;work.apply_grid_config(c);work.position = Vector3(0,-18,0);work.rotation.y = .37;scene.add_child(work);return work

func observe(work: Node3D) -> void:
	await tick(5);work.release_take()
	for n in 700:
		if not work.running:break
		await tick()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	# The pull fixture overhangs a real void; the weight must not hit a hidden floor.
	var ground := StaticBody3D.new();ground.position = Vector3(-3.5,-18.1,0);scene.add_child(ground);var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(10,.2,30);ground.add_child(shape)
	var rows: Array = []
	for setting in [12,34]:
		var work := fixture("ramp",{"angle":setting});await observe(work);check("ramp "+str(setting)+" degrees has actual contact reading",work.result>=0 and work.reading.seconds>1)
		check("ramp "+str(setting)+" degree contrast",work.travelled.Crate<.04 if setting==12 else work.travelled.Crate>.3 and work.travelled.Crate<3);rows.append(work.reading.duplicate(true));work.queue_free();await tick(5)
	var coast := fixture("coast");await observe(coast)
	check("equal-push contact comparison separates stopping distances",coast.travelled.Smooth>coast.travelled.Rough*2 and coast.travelled.Rough>.015)
	check("coast waits for both actual bodies to settle",coast.reading.finished and coast.bodies.Smooth.linear_velocity.length()<.03 and coast.bodies.Rough.linear_velocity.length()<.03)
	rows.append(coast.reading.duplicate(true));coast.reset_take();check("reset retains measured comparison and restores original cube pose",coast.history.size()==1 and coast.bodies.Smooth.transform.is_equal_approx(coast.homes.Smooth));coast.queue_free();await tick(5)
	for mass in [.2,1.2]:
		var work := fixture("pull",{"pull_mass":mass});await observe(work)
		check("pull "+str(mass)+" kg is actual cable-force motion",work.result>=0 and work.reading.cable_tension>0)
		check("pull "+str(mass)+" kg contrast",work.travelled.Crate<.05 if mass<.5 else work.travelled.Crate>.3)
		check("pull "+str(mass)+" kg actual vertical weight travel",work.travelled.Weight<.05 if mass<.5 else work.travelled.Weight>.3)
		check("pull cable never applies compression",work.cable_tension>=0);rows.append(work.reading.duplicate(true));work.queue_free();await tick(5)
	var edited := fixture("pull",{"parts":{"Controls":{"position":[-.3,.9,1.8],"rotation":[0,10,0]},"Crate":{"position":[-.7,.823,0]}}});await tick(4);edited.reset_take()
	check("edited parts survive reset",edited.bodies.Crate.position.distance_to(Vector3(-.7,.823,0))<.001 and edited.get_node("Controls").position.distance_to(Vector3(-.3,.9,1.8))<.001)
	edited.command("MORE");await tick(3);check("mass control preserves edited member placement",absf(edited.pull_mass-.65)<.001 and edited.bodies.Crate.position.distance_to(Vector3(-.7,.823,0))<.001);edited.queue_free();await tick(5)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows,"scope":"New Jolt friction studies at negative elevation and a rotated assembly. Actual low/high slope, equal impulse on two contact surfaces, low/high hanging weight with explicit elastic cable, authored part reset. No native pulley-joint or physical-headset claim."}
	FileAccess.open(out.path_join("friction-studies-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
