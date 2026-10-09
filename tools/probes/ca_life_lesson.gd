extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-a-pattern-visits/"
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CA LIFE ",label," ",ok)
func frames(n:int=3) -> void:
	for i in n:await physics_frame
func flatten(rows:Array) -> Array[bool]:
	var result:Array[bool]=[]
	for row in rows:
		for value in row:result.append(value)
	return result
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var study=load(OUT+"printed/life.gd").new();world.add_child(study);await frames()
	check("Printed construction creates 576 cells, point, label and unlit lamp",study.cells.instance_count==576 and study.current.count(true)==5 and study.reading.text.contains("GEN 0") and study.point!=null and study.lamp.light_energy==0)
	var truth:=true
	for alive in [false,true]:
		for count in 9:truth=truth and study.next_state(alive,count)==(count==3 or (alive and count==2))
	check("All eighteen birth and survival cases",truth)
	var offsets:=true
	var row:Array[bool]=[];row.resize(576);row.fill(false);row[study.index(10,10)]=true
	offsets=study.neighbours(row,10,10)==0
	for dy in range(-1,2):
		for dx in range(-1,2):
			if dx==0 and dy==0:continue
			row.fill(false);row[study.index(10+dx,10+dy)]=true;offsets=offsets and study.neighbours(row,10,10)==1
	check("Every surrounding offset counts once; centre excluded",offsets)
	row.fill(false)
	for site in [Vector2i(23,23),Vector2i(0,23),Vector2i(23,0)]:row[study.index(site.x,site.y)]=true
	check("Both boundaries wrap; corner births from three neighbours",study.neighbours(row,0,0)==3 and study.evolve(row)[0])
	var start:Array[bool]=study.current.duplicate();var evolved:Array[bool]=study.evolve(study.current)
	check("Evolve writes a new buffer and leaves old state intact",study.current==start and not is_same(evolved,study.current))
	var reverse:Array[bool]=[];reverse.resize(576)
	for y in range(23,-1,-1):
		for x in range(23,-1,-1):reverse[study.index(x,y)]=study.next_state(start[study.index(x,y)],study.neighbours(start,x,y))
	check("Reversing iteration preserves the synchronous answer",reverse==evolved)
	var production=load("res://commons/artifacts/game_of_life_petri/game_of_life_petri.gd").new()
	production.grid_size=24;production.auto_run=false;production.culture="none";world.add_child(production);await frames()
	production.set_process(false);production.set_process_unhandled_input(false)
	production._clear_grid();production._spawn_pattern("glider",7,7)
	check("Printed seed equals installed glider beginning",flatten(production._grid)==study.current)
	var parity:=true
	for g in 48:
		study.step();production._advance();parity=parity and study.current==flatten(production._grid)
	check("Every glider generation through limit agrees with installed solver",parity)
	var last:Array=study.current.duplicate();study.step()
	check("Capacity holds the current state at generation 48",study.generation==48 and study.current==last)
	var rng:=RandomNumberGenerator.new();rng.seed=48612;parity=true
	for trial in 8:
		for y in 24:
			for x in 24:
				var value:=rng.randf()<.3;study.current[study.index(x,y)]=value;production._grid[y][x]=value
		study.generation=0
		for g in 12:
			study.step();production._advance();parity=parity and study.current==flatten(production._grid)
	check("Eight deterministic random beginnings agree for twelve updates",parity)
	study.replay()
	for i in 4:study.step()
	var shifted:Array[bool]=[];shifted.resize(576);shifted.fill(false)
	for site in study.seeds:shifted[study.index(site.x+1,site.y+1)]=true
	check("Four phases reproduce seed shifted one address on each axis",study.current==shifted)
	for i in 4:study.step()
	check("Fixed A occupied and lamp lit at generation eight",study.current[study.index(10,10)] and study.lamp.light_energy>0)
	var transforms:Array=[]
	for i in 576:transforms.append(study.cells.get_instance_transform(i))
	var before:Array=study.current.duplicate();study.toggle_link()
	check("Disconnect changes lamp without advancing or editing cells",not study.linked and study.lamp.light_energy==0 and study.generation==8 and study.current==before)
	study.toggle_link();check("Reconnect reads current state without stepping",study.generation==8 and study.current==before and study.lamp.light_energy>0)
	study.toggle_link();evolved=study.evolve(study.current);study.step()
	check("Unlinked automaton still evolves normally",study.current==evolved and study.lamp.light_energy==0)
	for i in 3:study.step()
	study.toggle_link();check("A empty again at generation twelve",not study.current[study.index(10,10)] and study.lamp.light_energy==0)
	await frames();var stable:=true;var colours:=true
	for i in 576:
		stable=stable and transforms[i]==study.cells.get_instance_transform(i)
		var got:Color=study.cells.get_instance_color(i);var want:=Color("90ebca") if study.current[i] else Color("273e49")
		colours=colours and absf(got.r-want.r)<.004 and absf(got.g-want.g)<.004 and absf(got.b-want.b)<.004
	check("All tile transforms stay fixed as the pattern travels",stable)
	check("All rendered tile colours match current state",colours)
	var space=world.get_world_3d().direct_space_state;var support:=true
	for occupied in [false,true]:
		study.current[study.index(10,10)]=occupied;study.redraw();await frames()
		var at:Vector3=study.cell_position(10,10)
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.3,1))
		support=support and not hit.is_empty() and absf(hit.position.y-1.05)<.002
	check("Native collision supports both empty and occupied site",support)
	study.seeds.assign([Vector2i(9,10),Vector2i(10,10),Vector2i(11,10)]);study.replay();start=study.current.duplicate();study.step()
	check("Independent blinker exercise has predicted vertical phase",study.current.count(true)==3 and study.current[study.index(10,9)] and study.current[study.index(10,10)] and study.current[study.index(10,11)])
	study.step();check("Blinker returns in two phases with centre lamp continuously lit",study.current==start and study.lamp.light_energy>0)
	var other=load(OUT+"variants/other-address/life.gd").new();world.add_child(other);other.seeds.assign(study.seeds);other.replay()
	var switched:bool=other.lamp.light_energy>0;other.step();study.step();switched=switched and other.lamp.light_energy==0 and other.current==study.current
	other.step();study.step();switched=switched and other.lamp.light_energy>0 and other.current==study.current
	check("Independent other-address lamp alternates without changing cells",switched)
	var self_fault=load(OUT+"variants/self-count/life.gd").new();world.add_child(self_fault)
	self_fault.seeds.assign(study.seeds);self_fault.replay();self_fault.step()
	check("Counting centre fault fails predicted blinker phase",self_fault.current!=study.evolve(start))
	var alias_fault=load(OUT+"variants/in-place/life.gd").new();world.add_child(alias_fault)
	var alias_before:Array=alias_fault.current.duplicate();alias_fault.step()
	check("In-place update fault fails synchronous answer",alias_fault.current!=study.evolve(alias_before))
	other.queue_free();self_fault.queue_free();alias_fault.queue_free();production.queue_free();await frames()
	study.position=Vector3(3,0,-2);study.rotation.y=.9
	var origin:=XROrigin3D.new();world.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=study.point.global_position;study.point.pick_up(hand);await frames()
	before=study.current.duplicate();var gen:int=study.generation
	controller.global_position+=Vector3(1,.2,2);await frames(6)
	check("Actual XRTools carries point without editing automaton",study.point.held() and study.current==before and study.generation==gen)
	study.point.action();await frames()
	check("Held trigger advances exactly once",study.generation==gen+1 and study.current==study.evolve(before))
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames()
	check("Release parks at local position in rotated study",not study.point.held() and study.point.position.is_equal_approx(Vector3(-1.2,1.12,.75)))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER;gen=study.generation
	study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key)
	check("Enter steps once and ignores repeat",study.generation==gen+1)
	key.echo=false;key.keycode=KEY_L;study._unhandled_key_input(key);key.keycode=KEY_R;study._unhandled_key_input(key)
	check("Keyboard replay restores edited seed and preserves disconnected link",study.generation==0 and study.current==start and not study.linked and study.lamp.light_energy==0)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code, native renderer/collision; installed-solver parity; independent blinker/address changes; two deliberately faulty variants; actual XRTools with supplied poses. No physical headset or human learner."},"  "))
	world.queue_free();await frames();quit(0 if failures.is_empty() else 1)
