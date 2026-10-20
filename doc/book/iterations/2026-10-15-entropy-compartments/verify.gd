extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-15-entropy-compartments/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var bench: Node3D

func _initialize() -> void: run.call_deferred()
func check(name_text: String, ok: bool) -> void:
	checks.append({"name":name_text,"passed":ok})
	if not ok: failures.append(name_text)
func press(name_text: String) -> void:
	var area: Node = bench.buttons[name_text].get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
func same_sites(a: Array, b: Array) -> bool:
	if a.size()!=b.size(): return false
	for i in a.size():
		if a[i]!=b[i]: return false
	return true
func shot(name_text: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR + name_text + ".png")

func run() -> void:
	root.size=Vector2i(1400,900)
	var preview=load("res://commons/artifacts/entropy_compartments/preview.tscn").instantiate()
	root.add_child(preview)
	bench=preview.get_node("Bench")
	bench.pointer_path="user://entropy-compartments-test-latest.json"
	for frame in 4: await process_frame
	check("sixteen occupants and eight rectangular controls",bench.cells.size()==16 and bench.buttons.size()==8)
	check("initial colour entropy one, multiplicity one, Boltzmann zero",bench.model.shannon_colour()==1 and bench.model.multiplicity()==1 and bench.model.boltzmann_over_kb()==0)
	await shot("separated")
	var rng_before: int=bench.rng.state
	var sweep: Array=[]
	for k in range(8,-1,-1):
		sweep.append({"k":bench.model.a_left(),"H_bits":bench.model.shannon_colour(),"Omega":bench.model.multiplicity(),"S_over_kb":bench.model.boltzmann_over_kb()})
		check("controlled exchange reaches k=%d" % k,bench.model.a_left()==k)
		if k==4: await shot("four-and-four")
		if k>0: press("A LEFT -")
	observations.controlled_sweep=sweep
	check("manual exchanges consume no RNG draws",bench.rng.state==rng_before)
	var end_cursor: int=bench.cursor
	press("A LEFT -")
	check("lower limit neither deletes nor appends event",bench.model.sites.count(1)==8 and bench.cursor==end_cursor)
	for i in 4: press("A LEFT +")
	var before: Array=bench.model.sites.duplicate()
	press("SAME k")
	check("same k changes arrangement while both measurements stay",bench.model.sites!=before and bench.model.a_left()==4 and bench.model.multiplicity()==4900 and bench.model.shannon_colour()==1)
	check("same k consumes no RNG draws",bench.rng.state==rng_before)
	await shot("same-macrostate")
	bench.observation="Both readings stayed while the site arrangement changed."
	bench.next_change="Compare a path that crosses k=4 with same-k permutations."
	press("KEEP")
	var kept: Dictionary=bench.capture()
	check("KEEP writes a file and stops",FileAccess.file_exists(bench.last_saved_path) and not bench.running)
	var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string(bench.last_saved_path))
	check("saved JSON preserves integer values exactly",bench.valid_record(saved) and same_sites(saved.states[-1].sites,kept.states[-1].sites) and saved.states[-1].rng_state==kept.states[-1].rng_state)
	FileAccess.open(DIR+"kept-trial.json",FileAccess.WRITE).store_string(JSON.stringify(saved,"  "))
	press("RESET")
	press("REPLAY")
	check("REPLAY starts from the kept baseline",bench.model.a_left()==8 and bench.replaying)
	while bench.replaying: bench.replay_step()
	check("REPLAY reaches the exact kept configuration and RNG state",bench.model.sites==kept.states[-1].sites and str(bench.rng.state)==kept.states[-1].rng_state)
	check("notes survive reopening",bench.observation==kept.observation and bench.next_change==kept.next_change)
	press("REPLAY");bench.replay_step();bench.replay_step();press("KEEP")
	check("KEEP during replay preserves only the visited prefix",bench.capture().states.size()==3 and bench.cursor==2)
	press("RESET");press("REPLAY")
	while bench.replaying: bench.replay_step()
	check("partial replay reopens at its kept endpoint",bench.cursor==2 and bench.model.a_left()==6)
	bench.restore(saved)
	var original: Dictionary=bench.capture()
	var bad: Dictionary=original.duplicate(true);bad.states[0].sites[0]=0
	check("reject changed inventory",not bench.restore(bad))
	bad=original.duplicate(true);bad.states[0].sites[0]=0.5
	check("reject fractional occupants",not bench.restore(bad))
	bad=original.duplicate(true);bad.states[0].rng_state="9223372036854775808"
	check("reject overflowing RNG state",not bench.restore(bad))
	bad=original.duplicate(true);bad.schema="unknown"
	check("reject incompatible model without mutation",not bench.restore(bad) and bench.capture()==original)
	var fresh=load("res://commons/artifacts/entropy_compartments/entropy_compartments.tscn").instantiate()
	check("fresh apparatus restores serialized state",fresh.restore(saved) and same_sites(fresh.model.sites,original.states[-1].sites))
	fresh.free()
	press("RESET")
	for i in 64: press("ONE SWAP")
	var first: Dictionary=bench.capture()
	observations.random_trajectory=first.states.map(func(s): return {"k":s.sites.slice(0,8).count(1),"action":s.action})
	press("RESET")
	for i in 64: press("ONE SWAP")
	check("same seed and requests reproduce 64 swap states",bench.capture().states==first.states)
	var down := false
	for i in range(1,first.states.size()):
		var k0: int=first.states[i-1].sites.slice(0,8).count(1)
		var k1: int=first.states[i].sites.slice(0,8).count(1)
		if abs(k1-4)>abs(k0-4): down=true
	check("seeded trajectory includes a decrease in multiplicity",down)
	press("RUN / PAUSE");check("RUN starts",bench.running)
	var cursor_before: int=bench.cursor
	bench._process(1.0);check("RUN advances an event",bench.cursor==cursor_before+1)
	press("RUN / PAUSE");check("PAUSE stops",not bench.running)
	cursor_before=bench.cursor;bench._process(5.0)
	check("paused time changes no state",bench.cursor==cursor_before)
	var counts: Array[int]=[0,0,0,0,0,0,0,0,0]
	var model=load("res://commons/artifacts/entropy_compartments/compartment_model.gd").new()
	var consistent := true
	for mask in 65536:
		var sites: Array[int]=[]
		for bit in 16: sites.append((mask>>bit)&1)
		if sites.count(1)!=8: continue
		model.sites=sites;counts[model.a_left()]+=1
		consistent=consistent and is_equal_approx(model.shannon_colour(),1.0)
	var expected: Array[int]=[1,64,784,3136,4900,3136,784,64,1]
	check("all 12870 configurations have one-bit colour entropy",consistent and counts.reduce(func(a,b): return a+b,0)==12870)
	check("enumeration independently confirms every multiplicity",counts==expected)
	for k in 9:
		check("formula agrees with enumerated macrostate %d" % k,model.choose(8,k)*model.choose(8,8-k)==counts[k])
	var jar=load("res://algorithms/randomness/entropy_jar/entropy_jar.tscn").instantiate()
	root.add_child(jar);jar.set_physics_process(false)
	for body in jar._particles_a+jar._particles_b: body.freeze=true
	for body in jar._particles_a: body.position.y=-jar.jar_height*0.25
	for body in jar._particles_b: body.position.y=jar.jar_height*0.25
	check("jar's separated height bands give zero",is_zero_approx(jar._measure_entropy()))
	for body in jar._particles_a+jar._particles_b: body.position.y=0.0
	check("jar's shared band gives one",is_equal_approx(jar._measure_entropy(),1.0))
	var truthful := true
	for mode in ["figures","number","verdict","none"]:
		jar.readout=mode;jar._current_entropy=0.9;jar._update_display()
		truthful=truthful and not jar._stats_label.text.contains("Cannot unmix") and not jar._stats_label.text.contains("MAXIMUM")
		check("jar disclosure preserved: "+mode,jar._entropy_label.visible==(mode in ["figures","number"]) and jar._stats_label.visible==(mode in ["figures","verdict"]))
	check("jar labels name quantity and range without irreversible claim",truthful and jar._stats_label.text.contains("6 height bands") and jar._entropy_label.text.contains("H(C|Y)"))
	jar._reset_jar();check("jar reset retains all 80 beads",jar._particles_a.size()==40 and jar._particles_b.size()==40)
	jar.queue_free()
	press("RESET")
	for i in 4: press("A LEFT -")
	var receipt: Dictionary={"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native scripted controls and mathematical/state checks; no physical headset or independent learner trial."}
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify(receipt,"  "))
	print("ENTROPY COMPARTMENTS: ",checks.size()," checks, failures=",failures)
	quit(0 if failures.is_empty() else 1)
