extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-architecture-a-place-to-pass/"
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(title:String,ok:bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("ARCH ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	for i in 3:await physics_frame
	await process_frame
func measured(cells:Dictionary,pitch:float) -> float:
	var low:=100.0;var high:=-100.0
	for cell in cells:
		if cell.y==roundi(-2.0/pitch):low=minf(low,cell.x*pitch);high=maxf(high,(cell.x+1)*pitch)
	return high-low
func traverse(study:Node3D,from:Vector3,to:Vector3,radius:float=.3) -> Vector3:
	var body:=CharacterBody3D.new();body.collision_layer=2;body.collision_mask=1
	var collision:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=radius;shape.height=1.8;collision.shape=shape;body.add_child(collision);root.add_child(body)
	body.global_position=study.to_global(from);await settle()
	for i in 120:
		body.move_and_collide(study.global_basis*((to-from)/120))
		await physics_frame
	var end:=study.to_local(body.global_position);body.queue_free();await settle();return end
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(4,0,-2);host.rotation.y=.65;root.add_child(host)
	var study=load(DIR+"printed/architecture.gd").new();host.add_child(study);await settle()
	var grammar=load(DIR+"printed/grammar.gd").new()
	check("Printed program starts as four-move plan with carried point",study.records.segments.size()==4 and not study.built and study.width_index==1 and study.point.has_method("pick_up"))
	check("Replacement still reads old sentence with whole-generation budget",grammar.rewrite("AB",{"A":"B","B":"AA"}).text=="BAA" and not grammar.rewrite("F".repeat(2049),{"F":"FF"}).accepted)
	check("Two room records share one retained address",study.records.rooms==[Vector2(0,-4),Vector2(0,-4)] and study.layout.addresses.size()==1 and study.layout.rooms.is_empty())
	check("Invalid brackets refuse before making geometry",not grammar.read("F]R").accepted and not grammar.read("F[RF").accepted)
	var empty:Dictionary=grammar.read("");check("Empty sentence has no footprints",study.floor_model.make(empty,1.4,false).occupied.is_empty())
	var records:Dictionary=study.records.duplicate(true)
	var widths_ok:=true;var coverage_ok:=true;var source_agrees:=true;var comparisons:=0
	var source=load("res://commons/artifacts/lsystem_dungeon/lsystem_dungeon.gd").new();source.lesson_enabled=true;source.position=Vector3(40,0,0);root.add_child(source);await settle()
	var desk=source.get_node("ArchitectureLesson")
	var raw:Dictionary=source.plan_records("branch",1)
	var records_match:bool=raw.sentence=="F[+RF][-RF]F" and raw.segments.size()==4
	for i in 4:
		for j in 2:records_match=records_match and desk.plan_point(raw.segments[i][j]).is_equal_approx(study.records.segments[i][j])
	for i in 2:records_match=records_match and desk.plan_point(raw.rooms[i]).is_equal_approx(study.records.rooms[i])
	check("Printed records equal actual dungeon after declared horizontal mapping",records_match)
	for i in 3:
		for rooms_on in [false,true]:
			desk.width_index=i;desk.rooms_enabled=rooms_on;desk.built=true;desk.rebuild()
			var layout:Dictionary=study.floor_model.make(records,study.WIDTHS[i],rooms_on)
			widths_ok=widths_ok and is_equal_approx(measured(layout.occupied,.1),study.WIDTHS[i])
			var cover:Dictionary={};var overlaps:=false
			for rect in layout.floors:
				for y in range(rect.position.y,rect.end.y):
					for x in range(rect.position.x,rect.end.x):
						var key:=Vector2i(x,y);overlaps=overlaps or cover.has(key);cover[key]=true
			coverage_ok=coverage_ok and not overlaps and cover==layout.occupied
			source_agrees=source_agrees and desk.occupied==layout.occupied and desk.room_cells==layout.rooms and desk.wall_count==layout.walls.size()
			comparisons+=1
	check("All three named widths measure exactly at the stem",widths_ok)
	check("Rectangle grouping covers every cell once without filling holes",coverage_ok)
	check("Six width-room combinations equal installed footprints and wall counts",source_agrees)
	study.act("ROOMS");check("Room square occupies 28 by28 cells once",study.layout.rooms.size()==784 and study.records==records and study.revealed)
	study.act("RESET");check("RESET removes room and answer while retaining path",not study.rooms_on and not study.revealed and study.records==records)
	study.act("BUILD");await settle()
	var wide_end:Vector3=await traverse(study,Vector3(0,.99,1.5),Vector3(0,.99,-7.5))
	check("Actual0.6m capsule traverses wide entrance and junction",wide_end.distance_to(Vector3(0,.99,-7.5))<.03)
	var side_end:Vector3=await traverse(study,Vector3(0,.99,-4),Vector3(5,.99,-4))
	check("Side branch is internally open but its far end stops capsule",side_end.x>4.3 and side_end.x<4.45)
	study.act("WIDTH",0);await settle()
	var narrow_end:Vector3=await traverse(study,Vector3(0,.99,1.5),Vector3(0,.99,-2))
	check("Same capsule is stopped by0.4m entrance",narrow_end.z>0.2)
	study.act("PLAN");await settle()
	var plan_end:Vector3=await traverse(study,Vector3(0,.99,1.5),Vector3(0,.99,-2))
	check("PLAN removes construction collision",plan_end.distance_to(Vector3(0,.99,-2))<.03)
	var visitor:=Node3D.new();root.add_child(visitor);visitor.add_to_group("player_body");visitor.global_position=study.to_global(Vector3(0,1,-4))
	var before:Dictionary=study.layout.duplicate(true)
	study.act("BUILD");study.act("WIDTH");study.act("ROOMS");study.act("RESET")
	check("Occupied frame refuses all four construction changes",study.layout==before and not study.built and study.width_index==0 and not study.rooms_on)
	visitor.global_position=study.to_global(Vector3(0,1,4));await settle()
	check("Leaving does not apply a refused operation",not study.built and study.width_index==0)
	visitor.queue_free();source.queue_free();await settle()
	var variant=load(DIR+"variation/architecture.gd").new();variant.position=Vector3(25,0,0);host.add_child(variant)
	variant.act("ROOMS")
	check("Actual edited rule preserves four segments but yields two new addresses",variant.records.segments==records.segments and variant.layout.addresses.size()==2 and variant.records.rooms==[Vector2(4,-4),Vector2(-4,-4)])
	check("Edited rooms produce two separate squares without widening entrance",variant.layout.rooms.size()==1568 and is_equal_approx(measured(variant.layout.occupied,.1),1.4))
	var wrong=load(DIR+"mutations/internal_walls.gd").new().make(records,1.4,false)
	check("Tests detect internal partitions when shared-edge exclusion is removed",wrong.walls.size()>before.walls.size() and wrong.occupied==study.floor_model.make(records,1.4,false).occupied)
	var coarse=load(DIR+"mutations/coarse_grid.gd").new().make(records,1.4,false)
	check("Width test rejects coarse grid which silently widens passage",not is_equal_approx(measured(coarse.occupied,.2),1.4))
	study.act("RESET");await settle()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle()
	controller.global_position=study.to_global(Vector3(.35,1.18,2.55));await settle()
	check("XR point chooses2.2m in rotated translated host",study.point.is_picked_up() and study.width_index==2 and is_equal_approx(measured(study.layout.occupied,.1),2.2))
	study.point.action();await settle();check("Held trigger builds",study.built)
	visitor=Node3D.new();root.add_child(visitor);visitor.add_to_group("player_body");visitor.global_position=study.to_global(Vector3(0,1,-4))
	controller.global_position=study.to_global(Vector3(-.35,1.18,2.55));await settle()
	check("Held width change refuses while occupied",study.width_index==2)
	visitor.global_position=study.to_global(Vector3(0,1,4));await settle()
	check("Refused held choice does not apply on visitor exit",study.width_index==2)
	controller.global_position=study.to_global(Vector3(0,1.18,2.55));await settle()
	check("New hand choice applies after exit",study.width_index==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks same point at selected width",not study.point.held() and study.point.position.is_equal_approx(Vector3(0,1.18,2.55)))
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"production_comparisons":comparisons,"scope":"Author-led exact printed program, actual rule edit, CharacterBody collision tests and XRTools supplied poses. No independent student or headset."},"  "))
	quit(0 if failures.is_empty() else 1)
