extends SceneTree
const Bridge := preload("res://commons/artifacts/biome_inheritance/biome_inheritance.gd")
const Clearance := preload("res://commons/biome_layers/inherited_form_clearance.gd")
var checks := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(message)

func run() -> void:
	var early = load("res://commons/artifacts/biome_primitives/biome_primitives.tscn").instantiate()
	early.stage = "Trans_Scale"
	early.demo = true
	early.hinge_preview_degrees = 45
	early.scale_preview_factor = .6
	root.add_child(early)
	var ids: Array = []
	for body in early._form_bodies: ids.append(body.get_instance_id())
	var archive: Dictionary = early.get_state()
	var bridge := Bridge.new()
	bridge.banners = true
	bridge.automatic = false
	bridge.sculpture = early
	root.add_child(bridge)
	var low: Dictionary = bridge.get_state()
	var field = bridge.habitat._field.duplicate()
	var nodes_before := bridge.get_child_count()
	bridge.apply_banner_time(8.0)
	var high: Dictionary = bridge.get_state()
	check(high.standing_cover > low.standing_cover,"Raising the same panels permits more of the existing cover")
	check(high.candidate_cover == low.candidate_cover,"Raising does not regenerate plant candidates")
	check(bridge.habitat._field == field,"Raising preserves the terrain")
	for i in range(5):
		var body: Node3D = early._form_bodies[i]
		var raised: Dictionary = high.banners.poses[i]
		var original: Dictionary = low.banners.poses[i]
		check(body.get_instance_id()==ids[i],"The live door body becomes the banner")
		check(is_equal_approx(float(raised.center[1])-float(original.center[1]),2.35),"The panel lifts 2.35 metres")
		check(raised.center[0]==original.center[0] and raised.center[2]==original.center[2],"Raising retains x/z and hinge direction")
		check(raised.size==original.size,"The same quad keeps its dimensions")
		check(body.scale==Vector3.ONE and body.get_child(0) is CollisionShape3D,"Collision follows the translated body at unit scale")
		check(early._form_bodies[i].get_node("TwoTriangles").mesh.get_surface_count()==2,"The banner retains its original two triangles")
		check(bridge.banner_study.materials[i].get_shader_parameter("motif")==i,"Each face carries a distinct pattern")
	check(bridge.inherited_record.samples==archive.samples and bridge.inherited_record.clock==archive.clock,"Walking archive and clock survive")
	for id in low.accepted_ids:
		check(id in high.accepted_ids,"Lifting cannot remove an already standing member in this fixture")
	for source in bridge.cover_sources:
		for member in source.items:
			if member.id in bridge.accepted:
				check(Clearance.blocked_by(member.point,member.radius,bridge.occupancy_forms,bridge.clearance_m,member.height).is_empty(),"Standing cover clears the elevated panels and their poles")
	var rendered := 0
	for source in bridge.cover_sources: rendered += source.node.multimesh.instance_count
	check(rendered==high.standing_cover,"Rendered cover matches the record")
	bridge.apply_banner_time(4.0)
	check(bridge.banner_study.poses[0].lift_m > bridge.banner_study.poses[4].lift_m,"The poles rise in a staggered sequence")
	bridge.apply_banner_time(20.0)
	check(bridge.accepted==low.accepted_ids,"Returning to doors restores exactly the original membership")
	check(bridge.get_child_count()==nodes_before,"Motion adds no new scene nodes")
	var test_form := [{"id":"raised","center":[0,3,0],"size":[1,2,.04],"vertical":[2,4]}]
	check(Clearance.blocked_by(Vector2.ZERO,.1,test_form,.35,Vector2(0,1)).is_empty(),"A short plant fits under a banner")
	check(Clearance.blocked_by(Vector2.ZERO,.1,test_form,.35,Vector2(0,2))=="raised","A tall plant does not fit under the same banner")
	check(Clearance.blocked_by(Vector2.ZERO,.1,test_form,.35,Vector2(0,1.65))=="raised","Touching the reserved margin remains excluded")
	var output := {"checks":checks,"failures":failed,"lowered":low,"raised":high}
	DirAccess.make_dir_recursive_absolute("res://ada_run/biome_inheritance/banners")
	var file := FileAccess.open("res://ada_run/biome_inheritance/banners/probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print("[biome_banners] %d checks, %d failed; cover below doors %d, below banners %d" % [checks,failed,low.standing_cover,high.standing_cover])
	bridge.free()
	quit(1 if failed else 0)
