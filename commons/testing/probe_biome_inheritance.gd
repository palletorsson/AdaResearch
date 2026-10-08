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
	root.add_child(early)
	var old_body: int = early._form_bodies[0].get_instance_id()
	early.model.move_point(Vector3(2,.05,3))
	early.model.advance(.12)
	var archive: Dictionary = early.get_state()
	var bridge = Bridge.new()
	bridge.automatic = false
	bridge.sculpture = early
	root.add_child(bridge)
	check(bridge.sculpture._form_bodies[0].get_instance_id() == old_body, "The actual early body survives into the later world")
	check(bridge.inherited_record.samples == archive.samples and bridge.inherited_record.clock == archive.clock, "The encounter's archive and clock survive the handoff")
	check(bridge.inherited_record.forms == archive.forms, "The source form record reaches the later process unchanged")
	var field = bridge.habitat._field.duplicate()
	var cells: Dictionary = bridge.habitat._cells.duplicate(true)
	var baseline: int = int(bridge.habitat.get_state().counts.cover)
	check(bridge.accepted.size()+bridge.excluded.size()==baseline, "Every original cover candidate is accounted for")
	var narrow: Dictionary = bridge.get_state()
	bridge.apply_width(1.25)
	var wide: Dictionary = bridge.get_state()
	check(wide.standing_cover < narrow.standing_cover, "Wider inherited forms exclude more actual later-biome cover")
	check(bridge.habitat._field == field and bridge.habitat._cells == cells, "Width change leaves habitat field and ecological layout unchanged")
	check(wide.candidate_cover == narrow.candidate_cover, "Width does not reroll candidates or replenish the budget")
	for id in wide.accepted_ids:
		check(id in narrow.accepted_ids, "Wide clearance never invents a new member")
	for member in bridge.excluded:
		check(member.by in ["form_0","form_1","form_2","form_3","form_4"], "Each exclusion names its inherited cause")
	for source in bridge.cover_sources:
		for member in source.items:
			if member.id in bridge.accepted:
				check(Clearance.blocked_by(member.point,member.radius,bridge.inherited_record.forms,bridge.clearance_m).is_empty(), "Every standing cover envelope clears the forms")
	for i in range(5):
		check(wide.inherited_encounter.forms[i].pivot == narrow.inherited_encounter.forms[i].pivot, "Hinge identity/position is retained")
		check(wide.foundations_y[i] == narrow.foundations_y[i], "Terrain support does not move as width changes")
		check(bridge.sculpture._form_bodies[i].scale == Vector3.ONE, "Physics bodies keep unit scale")
	bridge.apply_width(.6)
	check(bridge.accepted == narrow.accepted_ids, "Returning width restores exactly the same candidates")
	bridge.apply_clearance([])
	check(bridge.accepted.size() == baseline and bridge.excluded.is_empty(), "Removing the inherited constraint restores all original cover")
	var actual := 0
	for source in bridge.cover_sources: actual += source.node.multimesh.instance_count
	check(actual == baseline, "Rendered instance counts agree with the unmasked plan")
	bridge.apply_width(1.25)
	actual = 0
	for source in bridge.cover_sources: actual += source.node.multimesh.instance_count
	check(actual == wide.standing_cover, "Rendered instance counts agree with the masked plan")
	var output := {"checks":checks,"failures":failed,"narrow":narrow,"wide":wide}
	DirAccess.make_dir_recursive_absolute("res://ada_run/biome_inheritance")
	var file := FileAccess.open("res://ada_run/biome_inheritance/probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	print("[biome_inheritance] %d checks, %d failed; cover narrow %d, wide %d / %d" % [checks,failed,narrow.standing_cover,wide.standing_cover,baseline])
	bridge.free()
	quit(1 if failed else 0)
