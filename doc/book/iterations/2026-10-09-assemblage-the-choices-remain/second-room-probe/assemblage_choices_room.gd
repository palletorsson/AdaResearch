extends "res://tools/probes/transformation_encounters.gd"
const DIR:="res://doc/book/iterations/2026-10-09-assemblage-the-choices-remain/"
var map_origin: Vector3
func map_at(p: Vector3) -> Vector3:return map_origin+hall.global_basis*p
func clear_body(at: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func count_a(bits: Array) -> int:
	var total:=0
	for row in bits:
		for a in row:if a:total+=1
	return total
func samples(d: Dictionary) -> Array:
	var result:Array=[]
	for row in d.rows:result.append(row.map(func(c):return c.sample))
	return result
func geometry(n: Node) -> String:
	var result:=""
	if n is Node3D:result+=str(n.transform)
	if n is MeshInstance3D and n.mesh is BoxMesh:result+=str(n.mesh.size)+str(n.material_override.albedo_color)
	for child in n.get_children():result+=geometry(child)
	return result
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/ten_print_textile/ten_print_textile.gd")
	check("Existing textile comparison loaded",source!=null and source.lesson_node!=null)
	if source==null or source.lesson_node==null:return
	source.set_process(false);var desk=source.lesson_node
	map_origin=source.global_position-hall.global_basis*Vector3(9.5,0,8.5)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	var expected:=["ten_print_textile","grid_substrate_runner","synthesis_stand","panel_bridge_loom","pattern_atlas_gallery","dragon_bench","mamma_monster_gallery","godel_statement_plaque","incompleteness_scale"]
	check("All nine authored works retained",expected.all(func(t):return works.count(t)==1));observations.works=works
	desk.act("RESET");desk.act("HOLD")
	var opening:Array=desk.model.samples().duplicate(true);var choices:Array=desk.model.choices().duplicate(true)
	var witness:=geometry(desk.held)
	check("Initial installed count agrees with printed83",count_a(choices)==83)
	await snapshot("opening",source.to_global(Vector3(5,4,5)),source.to_global(Vector3(0,2,-3)),68)
	var approach:Vector3=source.to_global(Vector3(0,.01,2.9))
	check("Console approach supported and clear",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["ALPHABET","ODDS","HOLD","STEP","SEED","RESET"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);var effect:=false
		match id:
			"ALPHABET":effect=desk.model.alphabet=="orthogonals" and desk.model.samples()==opening and desk.model.choices()==choices
			"ODDS":effect=is_equal_approx(desk.model.odds,.75) and desk.model.samples()==opening and count_a(desk.model.choices())>83
			"HOLD":effect=desk.held_alphabet=="orthogonals" and desk.held_choices==desk.model.choices()
			"STEP":effect=desk.steps==1 and desk.model.samples().slice(0,11)==opening.slice(1,12)
			"SEED":effect=desk.seed_value==1011 and desk.model.samples()!=opening and desk.steps==0
			"RESET":effect=desk.model.samples()==opening and desk.model.alphabet=="diagonals" and desk.held_alphabet=="orthogonals"
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
		check("Actual desktop control "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
	await driver.teardown();driver.queue_free();await tick()
	desk.act("HOLD");witness=geometry(desk.held);desk.act("ALPHABET")
	check("Installed alphabet retains choices and held geometry",desk.model.choices()==choices and geometry(desk.held)==witness)
	await snapshot("alphabet",source.to_global(Vector3(0,1.7,3)),source.to_global(Vector3(0,1.8,-3)),72)
	desk.act("ODDS")
	observations.threshold_A=count_a(desk.model.choices())
	check("Installed threshold changes decisions while holding samples",desk.model.samples()==opening and count_a(desk.model.choices())>83 and geometry(desk.held)==witness)
	await snapshot("threshold",source.to_global(Vector3(0,1.7,3)),source.to_global(Vector3(0,1.8,-3)),72)
	var floor_clear:=true;var floor_samples:=0
	for alphabet in desk.model.ALPHABETS:
		desk.model.reinterpret(alphabet,.5);await tick()
		for i in 17:
			var at:Vector3=source.to_global(Vector3(-2+float(i)*.25,.01,-8))
			floor_clear=floor_clear and clear_body(at) and not floor_at(at).is_empty();floor_samples+=1
	check("Three floor alphabets retain51 supported body samples",floor_clear and desk.floor_marks.find_children("*","CollisionObject3D",true,false).is_empty())
	observations.floor_samples=floor_samples
	await snapshot("floor",source.to_global(Vector3(3,4.8,-4)),source.to_global(Vector3(0,0,-8)),65)
	desk.act("RESET");desk.act("HOLD")
	var route_ok:=true;var route_samples:=0
	# Open outer aisles pass the retained internal partitions.
	for route in [[Vector3(9.5,0,1.5),Vector3(2.4,0,3.5),Vector3(2.4,0,18.8),Vector3(1.5,0,18.8),Vector3(1.5,0,21.2),Vector3(2.4,0,21.2),Vector3(2.4,0,31.8),Vector3(1.5,0,31.8),Vector3(1.5,0,34.2),Vector3(9.5,0,34.2),Vector3(9.5,0,36.5)], [Vector3(9.5,0,1.5),Vector3(16.9,0,3.5),Vector3(16.9,0,35),Vector3(9.5,0,35),Vector3(9.5,0,36.5)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;route_samples+=1
	check("Supported outer routes cross both partitions",route_ok);observations.route_samples=route_samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Entry and onward records valid",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	var at:=map_at(Vector3(3.2,.01,7.5));var learner_approach:=map_at(Vector3(3.2,.01,5.7))
	check("Learner bay and approach supported and clear",clear_body(at) and clear_body(learner_approach) and not floor_at(at).is_empty() and not floor_at(learner_approach).is_empty())
	var study=load(DIR+"printed/assemblage.gd").new();study.transform=Transform3D(source.global_basis,map_at(Vector3(3.2,0,7.5)));root.add_child(study);await tick();await tick()
	check("Printed program starts with installed full sample record",samples(study.model.data)==opening and study.model.choices(study.model.data)==choices)
	check("Study point is reachable from bay approach",study.point.global_position.distance_to(learner_approach+Vector3.UP*1.2)<.9)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();controller.global_position+=Vector3(.2,.15,0);await tick();await tick()
	check("Picking up and moving does not edit record",study.point.is_picked_up() and study.model.data.alphabet=="diagonals" and samples(study.model.data)==opening)
	study.point.action();await tick()
	check("Supplied held action changes only alphabet",study.model.data.alphabet=="orthogonals" and samples(study.model.data)==opening and study.model.choices(study.model.data)==choices)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks familiar point in actual museum host",study.point.position.is_equal_approx(Vector3(0,1.15,1.1)))
	origin.queue_free();await tick()
	await snapshot("student",study.to_global(Vector3(0,2,3.4)),study.to_global(Vector3(0,1.8,0)),60)
	study.act("ALPHABET")
	await snapshot("student-blocks",study.to_global(Vector3(0,2,3.4)),study.to_global(Vector3(0,1.8,0)),60)
	await snapshot("student-floor",study.to_global(Vector3(2,4,-1.5)),study.to_global(Vector3(0,.1,-4)),63)
	await snapshot("above",source.to_global(Vector3(0,34,-6)),source.to_global(Vector3(0,0,-10)),72)
	var record:Dictionary=study.model.keep();study.queue_free();await tick()
	var variant=load(DIR+"variation/assemblage.gd").new();variant.transform=Transform3D(source.global_basis,map_at(Vector3(3.2,0,7.5)));root.add_child(variant);variant.act("ALPHABET");variant.act("ALPHABET")
	check("Complete block-size variation preserves all recorded data",variant.model.data==record and variant.model.choices(variant.model.data)==choices)
	await snapshot("student-reversed-blocks",variant.to_global(Vector3(0,2,3.4)),variant.to_global(Vector3(0,1.8,0)),60)
	variant.queue_free();await tick()
	await snapshot("collection",source.to_global(Vector3(4,6,-13)),source.to_global(Vector3(0,1.6,-23)),74)
	observations.scope="Actual Assemblage hall: six desktop button effects, exact learner samples, supplied XRTools poses, fixed/held choices, floor/route capsule samples and portal records. Student program and full variation temporarily in side bay. No production changes, headset, independent student, full portal traversal or secondary-artifact acceptance."
