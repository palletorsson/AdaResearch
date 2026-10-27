extends "res://commons/artifacts/timing_machines/soft_workshop.gd"
## Void adapter for the soft-body workshop desk (soft_workshop_console).
##
## The original desk binds its partner artifacts through the Endless Museum's
## `_edit_records`, an ancestor the Void does not have, so in the Void it built
## nothing. Here the partners are found among the same content floor's mounts by
## the identity stamp the Void writes on every imported artifact
## (`artifact_lookup_name`), which is the token the museum record carried. Inside
## the Endless Museum the original path runs unchanged.
##
## Everything after binding is the original desk: same chapter rows from
## soft_workshop.json, same controls, same model calls (copied from
## soft_workshop.gd `_bind`). One omission: the museum hall fill lights, which are
## placed in museum-hall coordinates from VESTIBULE_H, are not created. The Void
## floor supplies light.

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var em: Node = hall
	while em != null and not "_edit_records" in em: em = em.get_parent()
	if em != null:
		super._bind()
		return
	lesson_hall = hall
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/timing_machines/soft_workshop.json"))
	for row: Dictionary in data:
		if row.slug == chapter: spec = row
	if spec == null or spec.is_empty(): return
	# The Void can build a floor's artifacts one per frame; wait as the museum did.
	for attempt in 100:
		_collect_floor_works(hall)
		var complete := true
		for key in spec.primary: complete = complete and works.has(key)
		if complete: break
		await get_tree().create_timer(0.1).timeout
	for key in spec.primary:
		if not works.has(key): push_error("Soft workshop (Void) missing " + key); return
	_finish_bind(hall)

## The same floor's imported artifacts, keyed by their source token.
func _collect_floor_works(hall: Node) -> void:
	for mount in hall.get_children():
		var artifact: Node = mount.get_node_or_null("Artifact")
		if artifact == null or artifact == self or not is_instance_valid(artifact): continue
		var token := str(artifact.get_meta("artifact_lookup_name", ""))
		if token != "" and token != "soft_workshop_console": works[token] = artifact

## Original soft_workshop.gd `_bind`, from the model assignment to ready_for_input.
func _finish_bind(hall: Node) -> void:
	model=works[spec.primary[0]]
	if spec.primary.size()>1:other=works[spec.primary[1]]
	match chapter:
		"affect": _install_affect_stage()
		"cloth": _cloth_pins(0)
		"contact":model.set_process(false)
		"sampling":model=works.rounded_softbody_test.get_node("RoundedSoftBody")
		"reaction":
			model.auto_run=false;model.set_process(false)
			if model._image.get_width()!=model.resolution:
				model._image=Image.create(model.resolution,model.resolution,false,Image.FORMAT_RGB8)
				model._texture=ImageTexture.create_from_image(model._image)
				model._material.albedo_texture=model._texture
			model._init_simulation();model._update_texture()
			_install_reaction_stage()
		"morphogenesis":model.regenerate_at_entropy=false
	for ui in hall.find_children("*","CanvasLayer",true,false):
		if ui.get_viewport()!=hall.get_viewport():continue
		ui.hide()
		for item in ui.find_children("*","Control",true,false):
			if item.get_viewport()==hall.get_viewport():item.hide()
	for camera in hall.find_children("*","Camera3D",true,false):
		if camera.get_viewport()==hall.get_viewport():camera.current=false
	ids=spec.controls
	_build_compact_console(ids,str(spec.title).to_upper())
	rule_card=label(spec.rule,Vector3(0,2.15,0.5),0.001)
	rule_card.visible=false
	ready_for_input=true;refresh()
