extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-percolation-a-contact-rule/"
const SOURCE = preload("res://algorithms/proceduralgeneration/growth_systems/percolationnetwork_ca/percolationnetwork_ca.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("PERCOLATION ","PASS " if ok else "FAIL ",title)
func settle()->void:
	for i in 3:await physics_frame
	await process_frame
func chain(m)->void:
	m.occupied={};m.sources={Vector3i.ZERO:true}
	for x in 4:m.occupied[Vector3i(x,0,0)]=true
	m.restart()
func source_for(m):
	var s=SOURCE.new();s.setup_percolation_system();s._rng.seed=1337
	for c:Vector3i in m.occupied:s.grid[c.x][c.y][c.z]=1
	for c:Vector3i in m.sources:s.grid[c.x][c.y][c.z]=4;s.flow_grid[c.x][c.y][c.z]=1
	return s
func same_reached(m,s)->bool:
	for x in 18:
		for y in 18:
			for z in 18:
				if m.reached.has(Vector3i(x,y,z)) != (s.grid[x][y][z] in [2,3,4]):return false
	return true
func distances(m)->Dictionary:
	var d:Dictionary={};var queue:Array=m.sources.keys();var cursor:=0
	for c in queue:d[c]=0
	while cursor<queue.size():
		var c:Vector3i=queue[cursor];cursor+=1
		for axis in [Vector3i.RIGHT,Vector3i.UP,Vector3i.BACK]:
			for sign in [-1,1]:
				var v:Vector3i=c+axis*sign
				if m.occupied.has(v) and not d.has(v):d[v]=d[c]+1;queue.append(v)
	return d
func geometry_ok(study)->bool:
	if study.cells.get_child_count()!=study.model.occupied.size():return false
	var i:=0
	for c:Vector3i in study.model.occupied:
		var body:MeshInstance3D=study.cells.get_child(i);i+=1
		var colour:=Color("8b345b") if study.model.sources.has(c) else (Color("ec9ebd") if study.model.reached.has(c) else Color("faf6ee"))
		if not body.mesh.size.is_equal_approx(Vector3.ONE*.3) or not body.material_override.albedo_color.is_equal_approx(colour):return false
		if not body.position.is_equal_approx((Vector3(c)-Vector3(2.5,0,2.5))*.3+Vector3(0,.55,0)):return false
	return true
func run()->void:
	var G=load(DIR+"printed/reach.gd");var m=G.new();m.contact(false)
	check("Face contact reaches exactly one new cell",m.step()==1 and m.reached.size()==2)
	m.contact(true);check("Corner contact stays unreached",m.step()==0 and m.reached.size()==1)
	chain(m);var kept:Dictionary=m.occupied.duplicate();var original:Dictionary=m.reached
	check("One generation crosses one face only",m.step()==1 and m.reached.size()==2 and not m.reached.has(Vector3i(2,0,0)))
	check("Old buffer and sources remain intact",original=={Vector3i.ZERO:true} and m.sources=={Vector3i.ZERO:true} and m.occupied==kept)
	m.step();m.step();check("Four-cell chain needs three generations",m.generation==3 and m.reached.has(Vector3i(3,0,0)))
	m.occupied.erase(Vector3i(1,0,0));m.restart();for i in 10:m.step()
	check("An empty gap prevents transmission",m.reached.size()==1 and not m.reached.has(Vector3i(1,0,0)))
	m.occupied={Vector3i(0,0,0):true,Vector3i(5,0,0):true};m.sources={Vector3i.ZERO:true};m.restart();m.step()
	check("Boundary does not wrap",m.reached.size()==1)
	var axes_ok:=true
	for offset in G.OFFSETS:
		m.occupied={Vector3i(2,2,2):true,Vector3i(2,2,2)+offset:true};m.sources={Vector3i(2,2,2):true};m.restart();axes_ok=axes_ok and m.step()==1
	check("All six face orientations transmit",axes_ok and G.OFFSETS.size()==6)
	m.contact(true);for i in 65:m.step()
	check("Sixty-four-step budget stops generation",m.generation==64)
	m.lattice(.2);var sparse:Dictionary=m.occupied.duplicate();var sources:Dictionary=m.sources.duplicate();m.lattice(.4);var medium:Dictionary=m.occupied.duplicate();m.lattice(.6)
	check("Seeded density cutoffs produce nested occupied sets",sparse.keys().all(func(c):return medium.has(c)) and medium.keys().all(func(c):return m.occupied.has(c)) and sparse.size()<medium.size() and medium.size()<m.occupied.size())
	check("All thirty-six source-face sites forced occupied",sources.size()==36 and sources==m.sources and sources.keys().all(func(c):return c.z==5 and m.occupied.has(c)))
	var dense:Dictionary=m.occupied.duplicate();var state:Dictionary=m.reached.duplicate();for i in 8:m.step()
	m.restart();check("Restart retains lattice and only supplied sources",m.occupied==dense and m.reached==state and m.generation==0 and not is_same(m.reached,m.sources))
	m.lattice(.2);check("Local seed replays exact occupancy",m.occupied==sparse)
	var counts:Array=[];var bfs_ok:=true
	for p in [.2,.4,.6]:
		m.lattice(p);var expected:Dictionary=distances(m)
		for step in 20:
			bfs_ok=bfs_ok and m.reached.size()==expected.values().filter(func(d):return d<=step).size()
			for c in m.reached:bfs_ok=bfs_ok and expected.has(c) and expected[c]<=step
			m.step()
		counts.append({"p":p,"occupied":m.occupied.size(),"reached_without_sources":m.reached.size()-m.sources.size(),"far":m.far_count()})
	check("Independent breadth-first distances match each wave front",bfs_ok)
	var comparisons:=0;var source_ok:=true
	for fixture in 6:
		match fixture:
			0:m.contact(false)
			1:m.contact(true)
			2:chain(m)
			_:m.lattice([.2,.4,.6][fixture-3])
		var s=source_for(m)
		for i in 12:
			m.step();s.update_percolation_automata();source_ok=source_ok and same_reached(m,s);comparisons+=1
		s.free()
	check("Seventy-two source steps agree on reached sites",source_ok and comparisons==72)
	var host:=Node3D.new();host.position=Vector3(4,0,3);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/lattice.gd").new();host.add_child(study);await settle()
	check("Complete program builds two cells and inherited point",geometry_ok(study) and study.cells.get_child_count()==2 and study.point!=null)
	study.act("STEP");check("Reached colour comes from the state record",geometry_ok(study) and study.model.reached.size()==2)
	study.act("LATTICE");study.act("TEN");check("Whole lattice geometry matches addresses and colours",geometry_ok(study))
	check("Display supplies no obstacle collision",study.cells.find_children("*","CollisionObject3D",true,false).is_empty())
	var key:=InputEventKey.new();key.keycode=KEY_D;key.pressed=true;study._unhandled_key_input(key)
	check("Keyboard density changes cutoff and resets flow",study.density==1 and study.model.occupied==medium and study.model.generation==0)
	study.act("RESTART")
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();controller.global_position+=Vector3(.2,.1,0);await settle()
	check("Moving held point does not advance",study.point.is_picked_up() and study.model.generation==0)
	study.point.action();await settle();check("Held action advances one generation",study.model.generation==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle();check("Point parks under translated rotated host",study.point.position.is_equal_approx(Vector3(0,1.1,1.5)))
	var edited=load(DIR+"variation/lattice.gd").new();host.add_child(edited);await settle();edited.act("CONTACT");edited.act("STEP")
	check("Complete student edit transmits the selected corner",edited.model.reached.size()==2 and geometry_ok(edited))
	var e=edited.model;e.occupied={Vector3i(2,2,2):true,Vector3i(3,3,1):true};e.sources={Vector3i(2,2,2):true};e.restart();e.step()
	check("Edit does not silently enable every diagonal",e.reached.size()==1)
	e.occupied={Vector3i(2,2,2):true,Vector3i(3,3,3):true};e.sources={Vector3i(3,3,3):true};e.restart();e.step();check("Added corner relation works in reverse",e.reached.size()==2)
	study.act("LATTICE");edited.density=study.density;edited.act("LATTICE");var same_cells:bool=e.occupied==study.model.occupied
	study.act("TEN");edited.act("TEN")
	check("Full edited lattice preserves occupancy and expands allowed reach",same_cells and study.model.reached.keys().all(func(c):return e.reached.has(c)))
	var bad=load(DIR+"wrong_buffer/reach.gd").new();chain(bad);bad.step();check("Oracle rejects in-place wave avalanche",bad.reached.size()!=2)
	bad=load(DIR+"wrong_contact/reach.gd").new();bad.contact(true);bad.step();check("Oracle rejects unrequested diagonal transmission",bad.reached.size()!=1)
	bad=load(DIR+"wrong_empty/reach.gd").new();bad.contact(false);bad.step();check("Oracle rejects transmission through empty cells",bad.reached.keys().any(func(c):return not bad.occupied.has(c)))
	origin.queue_free();host.queue_free();await settle()
	var f:=FileAccess.open(DIR+"checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_steps":comparisons,"density_counts":counts,"scope":"Exact printed complete programs, Boolean reached projection compared with source amplitudes, independent graph-distance oracle, full student edit, rejected faults, supplied XRTools poses. No physical headset or independent student acceptance."},"  "));f.close();quit(0 if failures.is_empty() else 1)
