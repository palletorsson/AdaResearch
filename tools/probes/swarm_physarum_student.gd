extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-swarm-a-trace-outside/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("SWARM ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder: String = "printed"):
	return load(OUT+folder+"/trail.gd").new()
func one(model, p: Vector2 = Vector2(8,8)) -> void:
	model.positions.assign([p]);model.headings.assign([0.0]);model.values.fill(0)
func equal_values(a, b) -> bool:
	if a.size()!=b.size():return false
	for i in range(a.size()):
		if not is_equal_approx(a[i],b[i]):return false
	return true
func run() -> void:
	var model = fresh()
	check("Complete model creates six positions and six headings",model.positions.size()==6 and model.headings.size()==6)
	check("Grid has 256 initially empty cells",model.values.size()==256 and model.values.count(0.0)==256)
	check("Periodic lookup wraps negative and upper boundaries",model.index_at(Vector2(-.1,16.1))==15 and model.index_at(Vector2(16,16))==0)
	one(model)
	check("Three sensors read three distinct cells",model.index_at(model.sensor_position(0,model.TURN))==153 and model.index_at(model.sensor_position(0,0))==137 and model.index_at(model.sensor_position(0,-model.TURN))==105)
	model.deposit(model.sensor_position(0,model.TURN))
	check("A deposited mark can be sensed before moving",model.sense(0,model.TURN)==1 and model.sense(0,0)==0)
	var mark:int=model.index_at(model.sensor_position(0,model.TURN));model.step()
	check("Strictly strongest left turns +45 degrees",is_equal_approx(model.headings[0],PI/4))
	check("Move has the declared length in cells",model.positions[0].distance_to(Vector2(8,8))>.4499 and model.positions[0].distance_to(Vector2(8,8))<.4501)
	check("Unvisited mark retains 92 percent",is_equal_approx(model.values[mark],.92))
	one(model);model.deposit(model.sensor_position(0,-model.TURN));model.step()
	check("Strictly strongest right turns -45 degrees",is_equal_approx(model.headings[0],-PI/4))
	one(model);model.deposit(model.sensor_position(0,0));model.step()
	check("Strongest ahead keeps the heading",is_zero_approx(model.headings[0]))
	one(model);model.deposit(model.sensor_position(0,model.TURN));model.deposit(model.sensor_position(0,-model.TURN));model.step()
	check("Equal sides keep heading under the declared tie rule",is_zero_approx(model.headings[0]))
	one(model,Vector2(15.9,8));model.step()
	check("Motion wraps at boundary",is_equal_approx(model.positions[0].x,.35))
	for i in range(20):model.deposit(Vector2.ZERO)
	check("Repeated deposits saturate at eight",is_equal_approx(model.values[0],8))
	model=fresh();var second=fresh()
	second.positions.reverse();second.headings.reverse()
	for i in range(40):model.step();second.step()
	second.positions.reverse();second.headings.reverse()
	check("Forty steps are independent of agent iteration order",equal_values(model.values,second.values) and model.positions==second.positions and model.headings==second.headings)
	var saved:PackedFloat32Array=model.values.duplicate();model.reset()
	for i in range(40):model.step()
	check("Reset reproduces the tick40 field exactly",saved==model.values and model.steps==40)
	one(model);model.positions.clear();model.headings.clear();model.values[0]=1
	model.retention=.55
	for i in range(5):model.step()
	check("An abandoned trace follows retention to the fifth power",is_equal_approx(model.values[0],pow(.55,5)))
	model.reset();check("Reset keeps chosen retention while clearing memory",model.retention==.55 and model.values.count(0.0)==256 and model.steps==0)
	var variation=fresh("variation")
	check("Independent first-position edit changes its addressed sensors",variation.positions[0]==Vector2(6,8) and variation.index_at(variation.sensor_position(0,0))==135)
	for i in range(1500):variation.step()
	var bounded:=true
	for p:Vector2 in variation.positions:bounded=bounded and p.x>=0 and p.y>=0 and p.x<16 and p.y<16
	for value:float in variation.values:bounded=bounded and is_finite(value) and value>=0 and value<=8
	check("1500-step variation stays finite and within declared bounds",bounded)
	var fault=fresh("fault-turn");one(fault);fault.deposit(fault.sensor_position(0,fault.TURN));fault.step()
	check("Checker rejects reversed left turn",not is_equal_approx(fault.headings[0],PI/4))
	fault=fresh("fault-decay");fault.positions.clear();fault.headings.clear();fault.values[0]=1;fault.step()
	check("Checker rejects omitted decay",not is_equal_approx(fault.values[0],.92))
	fault=fresh("fault-wrap")
	check("Checker rejects clamped boundary substituted for periodic",fault.index_at(Vector2(-.1,16.1))!=15)
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed Godot code, deterministic assertions, independent edit, three executed faults and synthetic XRTools interaction. Not a headset or independent learner test."},"  "))
	quit(0 if failures.is_empty() else 1)

func host_checks() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks();study.set_process(false)
	check("Printed host creates table, six carried points and three sensors",study.points.size()==6 and study.tiles.size()==256 and study.sensors.size()==3)
	var ids:Array=[]
	for point in study.points:ids.append(point.get_instance_id())
	study.get_node("Run").emit_signal("pressed");study._process(.30)
	check("Real button signal advances two fixed model ticks",study.playing and study.trail.steps==2)
	study.get_node("Retention").emit_signal("pressed")
	check("Retention button starts a comparable blank run at55percent",study.trail.retention==.55 and study.trail.steps==0 and study.playing)
	study.get_node("Reset").emit_signal("pressed");var unchanged:=true
	for i in range(ids.size()):unchanged=unchanged and study.points[i].get_instance_id()==ids[i]
	check("Controls retain all six PointBody instances",unchanged)
	study.position=Vector3(4,.2,-3);study.rotation.y=.7
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var point=study.points[1];hand.global_position=point.global_position;point.pick_up(pickup);await ticks()
	check("Inherited point attaches to real XRTools grab driver",point.held())
	var target:Vector2=study.trail.sensor_position(0,study.trail.TURN)
	hand.global_position=study.to_global(study.place(target));await ticks();study._process(.3)
	check("Holding any point pauses model and reads the transformed local position",study.trail.steps==0 and study.trail.positions[1].distance_to(target)<.001)
	point.action();await ticks()
	check("Held point1 trigger writes its own position into shared memory",is_equal_approx(study.trail.sense(0,study.trail.TURN),1.0))
	hand.global_position=study.to_global(study.place(Vector2(2,2)));await ticks();study._process(.1)
	check("Moving author away retains its earlier mark",is_equal_approx(study.trail.sense(0,study.trail.TURN),1.0))
	point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	study._process(0)
	check("Release returns carried sphere to the field plane",not point.held() and point.position.is_equal_approx(study.place(study.trail.positions[1])))
	study._process(.15)
	check("Another point turns toward the absent author's trace",is_equal_approx(study.trail.headings[0],PI/4))
	check("Numeric label reports point0 and current retention","Point 0:" in study.caption.text and "55%" in study.caption.text)
	study.queue_free();xr.queue_free();await ticks()
