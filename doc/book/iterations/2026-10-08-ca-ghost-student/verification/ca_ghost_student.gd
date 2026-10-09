extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-ghost-student/"
const ATTEMPT := OUT + "attempt/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var world: Node3D
var hand: Node3D
var controller: XRController3D
var loaded: Array[Node] = []

func _initialize() -> void:
	run.call_deferred()

func check(hall: String, name_: String, ok: bool) -> void:
	checks.append({"hall": hall, "name": name_, "passed": ok})
	if not ok:
		failures.append(hall + ": " + name_)
	print("GHOST / ", hall, " / ", name_, " / ", ok)

func frames(n: int = 3) -> void:
	for i in n:
		await physics_frame

func build(hall: String, file: String, variant: String = "") -> Node3D:
	var path := ATTEMPT + "reconstructed/" + hall + "/" + file
	if not variant.is_empty():
		path = ATTEMPT + "variants/" + variant + "/" + file
	var study = load(path).new()
	study.position = Vector3(6 * loaded.size(), 0, -2)
	study.rotation.y = 0.37
	world.add_child(study)
	loaded.append(study)
	return study

func active(row: Array) -> Array:
	var indices := []
	for i in row.size():
		if row[i]: indices.append(i)
	return indices

func neighbours_ref(row: Array[bool], rule: Array[bool]) -> Array[bool]:
	var result: Array[bool] = []
	for i in row.size():
		result.append(rule[4 * int(row[posmod(i-1,row.size())]) + 2 * int(row[i]) + int(row[(i+1)%row.size()])])
	return result

func has_held_step(hall: String, s: Node3D, before: int, counter: String) -> void:
	controller.global_position = s.point.global_position
	s.point.pick_up(hand)
	await frames()
	check(hall, "Printed point accepts actual XRTools pickup with supplied pose", s.point.held())
	s.point.action()
	await frames()
	var after: int
	match counter:
		"history": after = s.history.size()
		"model": after = s.model.tick
		"ticks": after = s.ticks
		_: after = s.generation
	check(hall, "Existing held trigger advances exactly one update", after == before + 1)
	s.point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await frames()
	check(hall, "Release relinquishes pickup without losing the point", not s.point.held() and is_instance_valid(s.point))

func row_trial() -> void:
	var h := "CA_Introduction"
	var s = build(h,"row.gd")
	await frames()
	check(h,"Reconstruction creates its label, point, cells and seed",is_instance_valid(s.reading) and active(s.current)==[16] and s.tiles.visible_instance_count==32)
	await has_held_step(h,s,0,"generation")
	s.seeds.assign([15,16]);s.reset();s.step()
	check(h,"Adjacent-seed prediction",active(s.current)==[14,15,16,17])
	s.seeds.assign([0]);s.reset();s.step()
	check(h,"Wrapped boundary prediction",active(s.current)==[1,31])
	var reverse = build(h,"row.gd","row_reverse")
	s.seeds.assign([16]);s.reset()
	var matches := true
	for i in 32:
		s.step();reverse.step();matches = matches and s.current==reverse.current
	check(h,"Actual reversed-loop source agrees across32 updates",matches)
	check(h,"Display budget keeps24 rows while generation continues",s.history.size()==24 and s.generation==32)
	var seed: Array[bool] = [];seed.resize(32);seed.fill(false)
	for i in [0,3,9,16]:seed[i]=true
	var reflected: Array[bool] = [];reflected.resize(32)
	for i in 32:reflected[i]=seed[posmod(-i,32)]
	var a: Array = s.evolve(seed);var b: Array = s.evolve(reflected)
	var symmetric := true
	for i in 32:symmetric = symmetric and a[i]==b[posmod(-i,32)]
	check(h,"Unprinted transfer: reflecting a seed reflects the answer",symmetric)
	var snapshot: Array = s.history[0].duplicate();s.current[0]=not s.current[0]
	check(h,"History remains a separate record",s.history[0]==snapshot)

func states_trial() -> void:
	var h := "CA_ElementaryRules"
	var s = build(h,"volume.gd");await frames()
	var i: int = s.index(s.CENTRE)
	check(h,"Prepared centre is active with11 neighbours",s.current[i]==1 and s.active_neighbours(s.current,s.CENTRE)==11)
	await has_held_step(h,s,0,"generation")
	observations['compact_centre_after_one']={"state":s.current[i],"active_neighbours":s.active_neighbours(s.current,s.CENTRE),"installed_specimen_count_in_text":7}
	check(h,"First compact centre fades with14 active neighbours",s.current[i]==2 and s.active_neighbours(s.current,s.CENTRE)==14)
	s.step();check(h,"Second centre empties",s.current[i]==0)
	var v = build(h,"volume.gd","states_two")
	v.step();check(h,"Two-cell source edit leaves exactly two fading cells",v.current.count(2)==2 and v.current.count(1)==0)
	v.step();check(h,"Next generation of edited seed is wholly empty",v.current.count(0)==343)
	check(h,"State versus count transfer",s.next_state(2,26)==0 and s.next_state(2,7)==0 and s.next_state(0,7)==1)
	var shell := true
	for z in 7:
		for y in 7:
			for x in 7:
				if x==0 or y==0 or z==0 or x==6 or y==6 or z==6:shell = shell and s.current[s.index(Vector3i(x,y,z))]==0
	check(h,"Outer shell remains empty",shell)

func history_trial() -> void:
	var h := "CA_GameOfLife"
	var s = build(h,"history.gd");await frames()
	await has_held_step(h,s,1,"history")
	s.seeds.assign([5,9]);s.replay();s.step()
	check(h,"Edited beginning gives predicted six sites",active(s.current)==[4,5,6,8,9,10])
	var v = build(h,"history.gd","history_flip")
	v.seeds.assign([5,9]);v.replay();v.step()
	check(h,"Flipped screen mapping preserves record and deck",s.history==v.history and s.deck_position(4,1)==v.deck_position(4,1) and not s.screen_position(4,1).is_equal_approx(v.screen_position(4,1)))
	for j in 4:s.step()
	var latest: Array[bool] = [];latest.assign(s.current)
	var wanted := neighbours_ref(latest,[false,true,true,true,true,false,false,false])
	s.select_row(1);s.step()
	check(h,"STEP after old-row selection evolves latest row",s.current==wanted and s.history.size()==7)
	var snap: Array = s.history[0].duplicate();s.current[0]=not s.current[0]
	check(h,"Current edit cannot rewrite generation zero",s.history[0]==snap)
	for j in 40:s.step()
	check(h,"History stops at24 including beginning",s.history.size()==24)
	await frames()
	var support_ok := true
	for g in 24:
		for x in 15:support_ok = support_ok and s.shapes[g*15+x].disabled==not s.history[g][x]
	check(h,"Native collision flags follow recorded occupancy",support_ok)

func life_trial() -> void:
	var h := "CA_BeyondBinary"
	var s = build(h,"life.gd");await frames()
	await has_held_step(h,s,0,"generation")
	for j in 3:s.step()
	var translated: Array[int] = []
	for p in s.seeds:translated.append(s.index(p.x+1,p.y+1))
	translated.sort()
	check(h,"Four-step glider is a translated arrangement",active(s.current)==translated)
	for j in 4:s.step()
	check(h,"Lamp A receives occupied address at generation8",s.current[s.index(10,10)] and s.lamp.light_energy>0)
	s.seeds.assign([Vector2i(9,10),Vector2i(10,10),Vector2i(11,10)]);s.replay();s.step()
	check(h,"Blinker changes orientation with fixed occupied centre",s.current[s.index(10,9)] and s.current[s.index(10,10)] and s.current[s.index(10,11)] and active(s.current).size()==3 and s.lamp.light_energy>0)
	var copy: Array = s.current.duplicate();s.toggle_link()
	check(h,"Unlinking lamp changes output without changing cells",s.current==copy and s.lamp.light_energy==0)
	var v = build(h,"life.gd","life_site")
	v.seeds.assign(s.seeds);v.replay()
	var on: bool = v.lamp.light_energy>0;v.step()
	check(h,"Edited SITE makes off-centre lamp alternate",on and v.lamp.light_energy==0)
	s.seeds.assign([Vector2i(0,0),Vector2i(23,0),Vector2i(0,23),Vector2i(23,23)]);s.replay()
	copy=s.current.duplicate();s.step()
	check(h,"Unprinted transfer: block is stable across periodic corner",s.current==copy)

func presence_trial() -> void:
	var h := "CA_ExpandingSpace"
	var s = build(h,"presence.gd");await frames()
	await has_held_step(h,s,0,"ticks")
	s.reset();s.point.on_desktop_grab(world)
	s.point.global_position=s.to_global(s.view_position(s.W)+Vector3.UP*0.05)
	for j in 21:s.step()
	await frames()
	check(h,"21 nearby commits produce.16 and disable support",absf(s.current[s.W]-0.16)<1e-9 and s.supports[s.W].disabled)
	check(h,"Conversion back to simulation units retains height",s.input_position().distance_to(s.cell_position(s.W)+Vector3.UP*0.25)<0.0001)
	s.reset();s.point.global_position=s.to_global(s.view_position(s.W)+Vector3.UP*0.30);s.step()
	check(h,"Vertical separation alone excludes the point",s.current[s.W]==1.0)
	s.point.on_desktop_drop(world)
	var v = build(h,"presence.gd","presence_threshold")
	v.chain=true;v.synchronous=false;v.backwards=false;v.reset();v.step()
	check(h,"Edited.49 threshold cannot feed next cell in SCAN",is_equal_approx(v.current[v.W],0.5) and v.current[Vector2i(3,6)]==0.0)
	s.chain=true;s.synchronous=true;s.reset();var initial: Dictionary = s.current.duplicate()
	var f: Dictionary=s.evolve(initial,Vector3.ZERO,false);s.backwards=true
	check(h,"Reverse SYNC keeps the same field",f==s.evolve(initial,Vector3.ZERO,false))
	for site in initial:initial[site]=0.0
	check(h,"Unprinted transfer: withdrawal cannot repair empty field",s.evolve(initial,Vector3.ZERO,false)==initial)

func exchange_trial() -> void:
	var h := "CA_SoftRules"
	var s = build(h,"exchange.gd");await frames()
	var w: int=s.left.index(12,15);s.advance(1)
	check(h,"First neighbour exchange prediction",absf(s.left.u[w]-0.92)<1e-6 and absf(s.left.v[w]-0.02)<1e-6 and s.right.u[w]==1.0 and s.right.v[w]==0.0)
	var copy_u: PackedFloat32Array=s.left.u.duplicate();var copy_v: PackedFloat32Array=s.left.v.duplicate()
	s.show_u=true;s.paint()
	check(h,"Palette switch leaves fields and tick alone",s.left.u==copy_u and s.left.v==copy_v and s.left.ticks==1)
	s.change_exchange();s.advance(100)
	check(h,"Matching exchanges agree after100 updates",s.left.u==s.right.u and s.left.v==s.right.v)
	controller.global_position=s.point.global_position;s.point.pick_up(hand);await frames()
	controller.global_position=s.to_global(Vector3(-0.85+(-12+0.5)*0.04,1.15,0.5+(-12+0.5)*0.04));await frames(6)
	var target: Vector2i=s.target_site();s.point.action();await frames()
	check(h,"Held XR trigger seeds chosen address without advancing",s.point.held() and target==Vector2i(4,4) and s.injections==1 and s.left.v[s.left.index(4,4)]==0.25 and s.right.v[s.right.index(4,4)]==0.25 and s.left.ticks==100)
	s.point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames();s.point.action()
	check(h,"Released point cannot plant",s.injections==1 and not s.point.held())
	var v = build(h,"exchange.gd","exchange_corner")
	var corner := true
	for y in [31,0,1]:
		for x in [31,0,1]:corner = corner and v.left.v[v.left.index(x,y)]==0.25 and v.right.v[v.right.index(x,y)]==0.25
	check(h,"Source edit seeds all nine wrapped corner addresses",corner)
	v.advance(1)
	check(h,"Unprinted transfer: first V arrives outside corner seed only by exchange",v.left.v[v.left.index(2,0)]>0 and v.right.v[v.right.index(2,0)]==0)

func comparison_trial() -> void:
	var h := "CA_AgentsCircuits"
	var s = build(h,"comparison.gd");await frames()
	await has_held_step(h,s,1,"history")
	check(h,"Compact copying recipe produces216 entries",s.positions.size()==216 and s.copies.instance_count==216)
	for j in 15:s.step()
	check(h,"Single seed reaches empty row at generation16",s.history.size()==17 and active(s.history.back()).is_empty())
	var v = build(h,"comparison.gd","comparison_seed")
	var positions: Array = v.positions.duplicate();v.step()
	check(h,"Three-seed source edit leaves only13 and19",active(v.history.back())==[13,19])
	check(h,"Cellular edit leaves all copy transforms intact",v.positions==positions and v.positions==s.positions)
	var shifted: Array = s.methods.copy_positions(Vector3(2,3,-1),4,3)
	var invariant := shifted.size()==216
	for i in 216:invariant = invariant and shifted[i].is_equal_approx(s.positions[i]+Vector3(2,3,-1))
	check(h,"Unprinted transfer: translating recipe origin translates every leaf",invariant)

func difference_trial() -> void:
	var h := "CA_EdgeOfChaos"
	var s = build(h,"difference.gd");await frames()
	check(h,"Both volumes and all three images constructed",s.volumes.size()==2 and s.textures.size()==3 and s.model.report().count==1)
	await has_held_step(h,s,0,"model")
	check(h,"Integer storage removes the one-cell difference",s.model.a==s.model.b and s.model.report().count==0)
	s.model.integer_storage=false;s.model.reset();s.step()
	check(h,"Fractional first step has27 differences and peak.75",s.model.report().count==27 and is_equal_approx(s.model.report().maximum,0.75))
	var original: PackedFloat64Array=s.model.b.duplicate();var gen: int=s.model.tick;s.select_slice(0)
	check(h,"Slice choice leaves arrays and update counter intact",s.model.b==original and s.model.tick==gen)
	for j in 19:s.step()
	check(h,"Growing affected count accompanies falling peak and rising gain",s.model.report().count>27 and s.model.report().maximum<0.75 and s.gain>1.0/0.75)
	s.model.pull=0;s.model.reset();s.step()
	check(h,"Zero pull retains one full difference",s.model.report().count==1 and s.model.report().maximum==1.0)
	var v = build(h,"difference.gd","difference_corner")
	v.model.integer_storage=false;v.model.reset();v.step()
	var edge: int=v.model.index(Vector3i(1,0,0));var inside: int=v.model.index(Vector3i(1,1,1))
	check(h,"Corner source edit gives8 and correct receiving denominators",v.model.report().count==8 and absf(v.model.b[edge]-v.model.a[edge]-0.25/11)<1e-12 and absf(v.model.b[inside]-v.model.a[inside]-0.25/26)<1e-12)
	s.model.changed=false;s.model.drive=1;s.model.scattered=true;s.model.reset()
	for j in 40:s.model.step()
	check(h,"Unprinted transfer: shared drive cannot split identical beginnings",s.model.a==s.model.b)

func composition_trial() -> void:
	var h := "Optional composition"
	var s=load(ATTEMPT+"recorded_presence.gd").new();world.add_child(s);loaded.append(s);await frames()
	s.begin_record();s.point.on_desktop_grab(world)
	for site in [Vector2i(2,6),Vector2i(3,8)]:
		s.point.global_position=s.to_global(s.view_position(site)+Vector3.UP*0.05)
		for j in 22:s.step()
	s.point.on_desktop_drop(world)
	for j in 22:s.step()
	var recorded_end: Dictionary=s.current.duplicate()
	s.point.global_position=Vector3(100,100,100)
	var replayed: Array=s.play_record()
	check(h,"Fresh student response replays all5280 values from recorded inputs",replayed==s.expected_fields and replayed.size()==66)
	check(h,"Repeated positions and absence are present in record",s.inputs.size()==66 and s.inputs[0]==s.inputs[1] and not s.inputs.back().present)
	var backwards: Array=s.play_record(true)
	check(h,"Reversing input history changes final field",s.current!=recorded_end and backwards.size()==66)
	var differing := 0
	for site in recorded_end:
		if not is_equal_approx(recorded_end[site],s.current[site]):differing+=1
	observations['optional']={"updates":66,"values_compared":5280,"reverse_input_final_sites_differing":differing,"first_question":"Where did my hand go?","revised_question":"When did each place receive it?","scope":"Prescribed simulated gesture; no physical VR walk or independent novice."}

func run() -> void:
	world=Node3D.new();root.add_child(world);current_scene=world
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,3,5);camera.look_at(Vector3(0,1,0));camera.current=true
	var sun:=DirectionalLight3D.new();world.add_child(sun);sun.rotation_degrees=Vector3(-40,-30,0)
	var origin:=XROrigin3D.new();world.add_child(origin)
	controller=XRController3D.new();origin.add_child(controller)
	hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	await row_trial();await states_trial();await history_trial();await life_trial()
	await presence_trial();await exchange_trial();await comparison_trial();await difference_trial()
	await composition_trial()
	var out:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty(),"observations":observations},"\t"));out.close()
	for s in loaded:s.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
