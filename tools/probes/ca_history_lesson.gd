extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-history-three-bodies/"
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CA HISTORY ",label," ",ok)
func frames(n: int=3) -> void:
	for i in n:await physics_frame
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var study=load(OUT+"printed/history.gd").new();world.add_child(study);await frames()
	check("Printed construction creates point, label, two views and 360 support slots",study.point!=null and study.reading.text.contains("GEN 0..0") and study.deck.instance_count==360 and study.screen.instance_count==360 and study.shapes.size()==360)
	check("Generation zero is a single occupied centre",study.current.count(true)==1 and study.history[0][7])
	check("Current row and saved row are independent",not is_same(study.current,study.history[0]))
	study.current[0]=true
	check("In-place current edit cannot rewrite saved past",not study.history[0][0])
	study.replay();var zero: Array=study.history[0].duplicate();study.step()
	check("First generation occupies 6, 7 and 8",study.current.count(true)==3 and study.current[6] and study.current[7] and study.current[8])
	check("Step preserves seed and stores an independent next row",study.history[0]==zero and not is_same(study.current,study.history[1]) and not is_same(study.history[0],study.history[1]))
	var production=load("res://algorithms/cellularautomata/ca_bridge/ca_bridge.gd").new()
	production.width=15;production.rule=30
	var all_cases:=true
	for index in 8:
		var old: Array[bool]=[];old.resize(15);old.fill(false)
		old[6]=bool(index&4);old[7]=bool(index&2);old[8]=bool(index&1)
		all_cases=all_cases and study.next_row(old)[7]==bool((30>>index)&1)
	check("All eight ordered neighbourhood cases implement Rule 30",all_cases)
	study.seeds.assign([0]);study.replay();study.step()
	check("Wrapped left boundary gives sites 14, 0 and 1",study.current.count(true)==3 and study.current[14] and study.current[0] and study.current[1])
	var parity:=true;var rng:=RandomNumberGenerator.new();rng.seed=23090
	for trial in 8:
		study.seeds.clear()
		for x in 15:
			if rng.randf()<.45:study.seeds.append(x)
		study.replay()
		var prod: Array=[]
		for value in study.current:prod.append(int(value))
		for generation in 23:
			study.step();prod=production._calculate_next_row(prod)
			for x in 15:parity=parity and int(study.current[x])==prod[x]
	check("Eight seeded histories through all 24 rows agree with installed solver",parity)
	var past: Array=study.history.duplicate(true);study.step()
	check("Full record stops without discarding earliest rows",study.history.size()==24 and study.history==past)
	study.seeds.assign([5,9]);study.replay();study.step()
	var pair_ok: bool=study.current.count(true)==6
	for x in [4,5,6,8,9,10]:pair_ok=pair_ok and study.current[x]
	check("Independent two-site exercise has predicted six occupied sites",pair_ok)
	for i in 4:study.step()
	await frames()
	var displayed: Array=[];var supports: Array=[]
	for i in 360:displayed.append(study.deck.get_instance_transform(i));supports.append(study.shapes[i].disabled)
	past=study.history.duplicate(true);var latest: Array=study.current.duplicate()
	study.select_row(1)
	check("Reading an old row leaves latest state and full history intact",study.selected==1 and study.history==past and study.current==latest)
	var stable:=true
	for i in 360:stable=stable and displayed[i]==study.deck.get_instance_transform(i) and supports[i]==study.shapes[i].disabled
	check("Reading leaves geometry and support intact",stable)
	check("Both gold markers agree on selected generation",is_equal_approx(study.deck_mark.position.z,.08) and is_equal_approx(study.screen_mark.position.z,.08))
	study.select_row(20);study.select_row(-1)
	check("Unrecorded and negative selections are ignored",study.selected==1)
	var expected: Array=study.next_row(study.current);study.step()
	check("Step after looking back evolves latest state, not selected past",study.current==expected and study.history.size()==7 and study.selected==6)
	await frames()
	var visibility:=true;var support_ok:=true;var positions:=true;var colours:=true
	for g in 24:
		for x in 15:
			var i:=g*15+x;var active: bool=g<study.history.size() and study.history[g][x]
			var a: Transform3D=study.deck.get_instance_transform(i);var b: Transform3D=study.screen.get_instance_transform(i)
			visibility=visibility and (absf(a.basis.determinant())>.5)==active and (absf(b.basis.determinant())>.5)==active
			positions=positions and a.origin.is_equal_approx(Vector3((x-7)*.08,1,g*.08)) and b.origin.is_equal_approx(Vector3(.85,1.05+x*.055,g*.08))
			support_ok=support_ok and study.shapes[i].disabled==not active
			var c: Color=study.deck.get_instance_color(i);var want:=Color("78d9bd").lerp(Color("e2a4de"),float(g)/23)
			colours=colours and absf(c.r-want.r)<.004 and absf(c.g-want.g)<.004 and absf(c.b-want.b)<.004
	check("All 360 slots in both views show only occupied recorded cells",visibility)
	check("All view coordinates separate site from generation",positions)
	check("Only occupied deck slots enable collision",support_ok)
	check("Generation selects intended rendered colour",colours)
	var space=world.get_world_3d().direct_space_state
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-.16,1.3,0),Vector3(-.16,.8,0),1))
	check("Physics ray lands on occupied seed tile",not hit.is_empty() and absf(hit.position.y-1.011)<.002)
	hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1.3,0),Vector3(0,.8,0),1))
	check("Recorded empty site offers no support",hit.is_empty())
	hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(.5,1.325,0),Vector3(1.1,1.325,0),1))
	check("Occupied wall cell has no collision",hit.is_empty())
	var fault=load(OUT+"variants/alias/history.gd").new();world.add_child(fault);fault.current[0]=true
	check("Deliberately shared snapshot is rejected",fault.history[0][0] and not zero[0])
	var flipped=load(OUT+"variants/flipped-view/history.gd").new();world.add_child(flipped)
	flipped.seeds.assign([5,9]);flipped.replay()
	for i in 6:flipped.step()
	check("Independent wall-flip task changes mapping without changing history",flipped.history==study.history and flipped.screen_position(5,1)!=study.screen_position(5,1) and flipped.deck_position(5,1)==study.deck_position(5,1))
	fault.queue_free();flipped.queue_free();production.free();await frames()
	study.position=Vector3(3,0,-2);study.rotation.y=.9
	var origin:=XROrigin3D.new();world.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=study.point.global_position;study.point.pick_up(hand);await frames()
	controller.global_position+=study.global_basis*Vector3(0,0,(2-study.selected)*.08);await frames(6)
	check("Actual XRTools held point reads row 2 in rotated local frame",study.point.held() and study.selected==2)
	past=study.history.duplicate(true);study.point.action();await frames()
	check("Held trigger appends one generation without replacing earlier rows",study.history.size()==past.size()+1 and study.history.slice(0,past.size())==past)
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames()
	check("Release parks reader at its selected local row",not study.point.held() and study.point.position.is_equal_approx(Vector3(-.85,1.05,study.selected*.08)))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER
	var count: int=study.history.size();study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key)
	check("Enter appends once and ignores repeat",study.history.size()==count+1)
	key.echo=false;key.keycode=KEY_R;study._unhandled_key_input(key)
	check("Replay restores edited seed and removes all later generations",study.history.size()==1 and study.selected==0 and study.current.count(true)==2)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code in native renderer; installed Rule30 parity; independent seed/view tasks; fault rejection; physics rays; XRTools with supplied controller poses. No tracked headset or human learner."},"  "))
	world.queue_free();await frames();quit(0 if failures.is_empty() else 1)
