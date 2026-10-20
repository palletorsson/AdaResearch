extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-entropy-reading/"
const Model=preload("res://commons/artifacts/ordinary_entropies/model.gd")
const Best=preload("res://commons/artifacts/ordinary_entropies/best_guess.gd")
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String,passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	if not passed:failures.append(title);print("FAIL ",title)
func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var expected: Array=[1.0,-log(0.75)/log(2.0),0.0]
	for i in 3:
		var tray:=Best.new();tray.pink_count=[8,12,16][i];stage.add_child(tray)
		var balls:=tray.visuals.find_children("Ball*","MeshInstance3D",true,false)
		var count:=0
		for ball in balls:
			count+=int(ball.get_meta("pink"))
			check("same radius %d/%s" % [i,ball.name],is_equal_approx(ball.mesh.radius,0.18))
		check("sixteen visible chances "+str(i),balls.size()==16)
		check("visible counts drive probabilities "+str(i),count==tray.pink_count and is_equal_approx(tray.probabilities()[0],count/16.0))
		check("best guess entropy "+str(i),is_equal_approx(Model.min_entropy(tray.probabilities()),expected[i]))
		var record:=tray.capture();tray.pink_count=3;tray.rebuild()
		check("reconstruct counts "+str(i),tray.restore(record) and tray.capture()==record)
		var bad:=record.duplicate();bad.pink=17
		check("reject invalid inventory atomically "+str(i),not tray.restore(bad) and tray.capture()==record)
		tray.free()
	var jars=load("res://commons/artifacts/ordinary_entropies/jar_states.gd").new();stage.add_child(jars);await process_frame
	check("four prepared jar states",jars.jars.size()==4)
	for i in 4:
		var jar: Node3D=jars.jars[i]
		check("same eighty beads "+str(i),jar._particles_a.size()==40 and jar._particles_b.size()==40)
		check("jar rests on shared tabletop "+str(i),is_equal_approx(jar._jar_body.global_position.y-jar.jar_height/2.0,0.75))
		check("comparison cannot be picked up "+str(i),not jar._jar_body.enabled)
		var before: Array=jar.positions();await create_timer(0.12).timeout
		check("prepared state remains fixed "+str(i),before==jar.positions())
		var repeat=load("res://commons/artifacts/ordinary_entropies/jar_snapshot.gd").new();repeat.found_state=jar.found_state;repeat.position.x=10
		stage.add_child(repeat)
		check("seed reproduces actual positions "+str(i),repeat.positions()==before);repeat.queue_free();await process_frame
	check("height reveals layers",jars.jars[0]._measure_entropy()<0.01)
	check("height misses core-shell order",jars.jars[3]._measure_entropy()>0.8)
	check("radius reveals core-shell order",jars.jars[3].radial_entropy()<0.01)
	check("mixed jar retains uncertainty in both readings",jars.jars[2]._measure_entropy()>0.8 and jars.jars[2].radial_entropy()>0.8)
	check("no new interaction controls",jars.find_children("*","Area3D",true,false).is_empty())
	jars.queue_free();await process_frame
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"\t"));file.close()
	print("Checks: ",checks.size()," failures: ",failures.size());quit(0 if failures.is_empty() else 1)
