extends SceneTree
const DIR:="res://doc/book/iterations/2026-10-09-evolution-what-the-score-reads/"
const GP=preload("res://algorithms/proceduralgeneration/growth_systems/genetic_programming/GeneticProgramming.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String,ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("EVOLUTION ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	for i in 3:await physics_frame
	await process_frame
func genome(record: Dictionary):
	var g=GP.Genome.new();g.id=record.id
	for gene in record.genes:g.genes.append(GP.Gene.new(gene.type,{"position":gene.position,"rotation":gene.rotation,"scale":gene.scale}))
	return g
func ids(records: Array) -> Array:return records.map(func(c):return c.id)
func nodes(study) -> Array:
	var result:Array=[]
	for i in 6:result.append([study.bodies[i].get_instance_id(),study.bodies[i].get_child(0).mesh.get_instance_id()])
	return result
func key(study,code: int) -> void:
	var e:=InputEventKey.new();e.pressed=true;e.keycode=code;study._unhandled_key_input(e)
func run() -> void:
	var Eval=load(DIR+"printed/evaluator.gd")
	var source=GP.new();source.genome_type=0;source.fitness_function=0
	var records:Array=Eval.opening();var saved:Array=records.duplicate(true)
	check("Six independent opening records with stable IDs",ids(records)==[0,1,2,3,4,5] and not is_same(records[0].genes,records[1].genes))
	check("Target8 chooses unit box; target16 chooses1.25; target32 chooses1.5",ids(Eval.rank(records,8))[0]==1 and ids(Eval.rank(records,16))[0]==2 and ids(Eval.rank(records,32))[0]==3)
	check("Ranking does not mutate input list or records",records==saved)
	check("Known score values and symmetric absolute difference",is_equal_approx(Eval.score(records[1],8),100) and is_equal_approx(Eval.score(records[1],7),50) and is_equal_approx(Eval.score(records[1],9),50) and is_equal_approx(Eval.score(records[2],16),100/1.375))
	var comparisons:=0;var agrees:=true
	for kind in ["box","sphere","cylinder","torus"]:
		for k in 3:
			var record:Dictionary={"id":0,"genes":[{"type":kind,"scale":Vector3(.5+k,.75+k,1+k),"position":Vector3(1,2,3),"rotation":Vector3(.1,.2,.3)}]}
			for target in [8.0,16.0,32.0]:
				var g=genome(record);source.target_volume=target
				agrees=agrees and is_equal_approx(Eval.estimate(record),source.estimate_volume(g)) and is_equal_approx(Eval.score(record,target),source.calculate_fitness(g));comparisons+=1
	check("Thirty-six source estimate and score comparisons agree",agrees and comparisons==36)
	var overlap:Dictionary=records[1].duplicate(true);overlap.genes.append(overlap.genes[0].duplicate(true))
	check("Overlapping parts are added not union-measured",is_equal_approx(Eval.estimate(overlap),16))
	var tie:Array=[{"id":20,"genes":[]},{"id":10,"genes":[]}]
	check("Declared equal-score tie break selects lower ID",ids(Eval.rank(tie,8))==[10,20] and ids(tie)==[20,10])
	var ringed:Dictionary=records[2].duplicate(true);var score:float=Eval.score(ringed,16);Eval.toggle_ring(ringed)
	check("Ring changes genes but neither estimate nor score",ringed.genes.size()==2 and is_equal_approx(Eval.score(ringed,16),score))
	Eval.toggle_ring(ringed);check("Ring removal restores complete candidate",ringed==records[2])
	var host:=Node3D.new();host.position=Vector3(4,0,3);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/selection.gd").new();host.add_child(study);await settle()
	check("Printed program builds six complete bodies and independent witness",study.bodies.size()==6 and study.held==records[1] and not is_same(study.held.genes,study.candidates[1].genes))
	var original_nodes:Array=nodes(study);key(study,KEY_T)
	check("Target changes ranking without rebuilding any meshes",study.target_index==1 and study.candidates==saved and nodes(study)==original_nodes and study.bodies[2].position==Vector3(-1.15,.6,0))
	key(study,KEY_H);var held:Dictionary=study.held.duplicate(true);var witness_id:int=study.witness.get_instance_id();key(study,KEY_G)
	var changed_nodes:Array=nodes(study);var only_one:=true
	for i in 6:only_one=only_one and ((changed_nodes[i]!=original_nodes[i]) if i==2 else (changed_nodes[i]==original_nodes[i]))
	check("Ring rebuilds only current leader",only_one and study.bodies[2].get_child_count()==2)
	check("Held record and body survive leader edit",study.held==held and study.witness.get_instance_id()==witness_id and study.witness.get_child_count()==1)
	var geometry_matches:=true
	var source_body=source.build_phenotype(genome(study.candidates[2]))
	for i in 2:
		var a=study.bodies[2].get_child(i);var b=source_body.get_child(i)
		geometry_matches=geometry_matches and a.transform.is_equal_approx(b.transform) and a.mesh.get_aabb().is_equal_approx(b.mesh.get_aabb())
	source_body.free()
	check("Unit box and torus dimensions/transforms match source before display scale",geometry_matches and study.bodies[2].scale.is_equal_approx(Vector3.ONE*.38))
	key(study,KEY_T);key(study,KEY_R)
	check("Reset restores opening but preserves held candidate",study.candidates==saved and study.target_index==0 and study.held==held and study.witness.get_instance_id()==witness_id)
	check("Bodies supply no collision or support",study.bodies.values().all(func(b):return b.find_children("*","CollisionObject3D",true,false).is_empty()))
	var variant=load(DIR+"variation/selection.gd").new();host.add_child(variant);await settle()
	var VE=load(DIR+"variation/evaluator.gd")
	check("Full student edit retains all original candidates and selects ID5",variant.candidates==saved and VE.rank(variant.candidates,8)[0].id==5 and is_equal_approx(VE.score(variant.candidates[5],8),100) and is_equal_approx(VE.score(variant.candidates[1],8),12.5))
	check("Student edit retains unit geometry and changes only box coefficient",variant.bodies[5].get_child(0).transform.is_equal_approx(study.bodies[5].get_child(0).transform) and VE.rank(variant.candidates,16)[0].id==5)
	var before_ring:float=VE.score(variant.candidates[5],8);variant.act("RING")
	check("Correction still omits torus",variant.candidates[5].genes.size()==2 and is_equal_approx(VE.score(variant.candidates[5],8),before_ring))
	var bad_score=load(DIR+"wrong_score/evaluator.gd")
	check("Test rejects signed-distance score fault",not is_equal_approx(bad_score.score(saved[1],9),50))
	var bad_rank=load(DIR+"wrong_rank/evaluator.gd");var wrong_records:Array=bad_rank.opening();bad_rank.rank(wrong_records,8)
	check("Test rejects input-list sorting fault",ids(wrong_records)!=[0,1,2,3,4,5])
	var bad=load(DIR+"wrong_hold/selection.gd").new();host.add_child(bad);await settle();bad.act("RING")
	check("Test rejects shallow witness fault",bad.held.genes.size()==2)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();controller.global_position+=Vector3(.2,.1,0);await settle()
	check("Pickup and hand motion do not alter candidates or target",study.point.is_picked_up() and study.target_index==0 and study.candidates==saved)
	study.point.action();await settle();check("Held action changes target on transformed host",study.target_index==1 and study.candidates==saved)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks carried point",study.point.position.is_equal_approx(Vector3(0,1.15,1.1)))
	origin.queue_free();host.queue_free();source.free();await settle()
	var receipt:Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_comparisons":comparisons,"scope":"Exact printed learner code, complete box-coefficient variation, three rejected faulty programs, source score/shape comparisons and supplied XRTools poses. Reproduction is supplied museum behaviour, not part of this learner program. No independent student or headset claim."}
	var f:=FileAccess.open(DIR+"checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(receipt,"  "));f.close();quit(0 if failures.is_empty() else 1)
