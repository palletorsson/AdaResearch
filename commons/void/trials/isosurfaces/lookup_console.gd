extends "res://commons/artifacts/timing_machines/iso_lookup_workshop.gd"
## Only the host lookup changes; original actions and extraction stay inherited.
const Links = preload("res://commons/void/trials/isosurfaces/floor_links.gd")

func _bind() -> void:
	var hall: Node=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null:return
	for attempt in 100:
		model=Links.find_artifact(hall,"fifteen_cases_demo")
		if model!=null:break
		await get_tree().create_timer(0.1).timeout
	if model==null:push_error("Lookup display missing");return
	model.set_process_input(false);model.animate_threshold=false
	model.apply_grid_config({"workings":"expression","margin":"even","case_spacing":2.5,"case_scale":1.2})
	for camera in model.find_children("*","Camera3D",true,false):camera.current=false
	ids=["MARGIN","TRACE","OPERANDS","SURFACE","RESET","RULE"]
	_build_compact_console(ids,"EIGHT VALUES / ONE LOCAL DECISION")
	rule_card=label("mask |= 1 << i when density[i] < 0.5\nt = (0.5 - d0) / (d1 - d0)\nSame comparisons can place crossings differently.\nThese fifteen arrangements are not a proof of all ambiguities.\nThe miniatures also include neighbouring sampled cells.",Vector3(0,2.15,0.5),0.001)
	rule_card.visible=false
	Links.light(self)
	ready_for_input=true;refresh()

