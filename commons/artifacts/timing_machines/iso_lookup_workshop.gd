extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## Exposes the original fifteen-case display's existing comparison axes.
var actions_taken := 0
var margin_index := 0

func _bind() -> void:
	var hall: Node=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null:return
	var em: Node=hall
	while em!=null and not "_edit_records" in em:em=em.get_parent()
	if em==null:return
	for attempt in 100:
		for rec: Dictionary in em.get("_edit_records"):
			var n=rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token=="fifteen_cases_demo":model=n
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
	for at in [Vector3(6,7,10),Vector3(16,7,10),Vector3(11,8,25)]:
		var light:=OmniLight3D.new();light.position=at+Vector3(0,0,int(em.get("VESTIBULE_H")));light.omni_range=18;light.light_energy=5;hall.add_child(light)
	ready_for_input=true;refresh()

func act(id: String) -> void:
	if not ready_for_input or busy:return
	busy=true;actions_taken+=1
	match id:
		"MARGIN":margin_index=(margin_index+1)%4;model.apply_grid_config({"margin":model.MARGINS[margin_index]})
		"TRACE":model.apply_grid_config({"workings":"trace"})
		"OPERANDS":model.apply_grid_config({"workings":"operands"})
		"SURFACE":model.apply_grid_config({"workings":"outcome"})
		"RESET":margin_index=0;model.apply_grid_config({"workings":"expression","margin":"even"})
		"RULE":rule_card.visible=not rule_card.visible
	busy=false;refresh()

func masks() -> Array:
	var result: Array=[]
	for item in model.fifteen_cases:
		var densities: Array=model._densities_for(item)
		var mask:=0
		for i in 8:
			if densities[i]<0.5:mask|=1<<i
		result.append(mask)
	return result

func refresh() -> void:
	if readout==null or model==null:return
	var pair: Array=model.MARGIN_PAIRS[model.margin]
	readout.text="Values %.2f / %.2f | level 0.50\nCrossing %.2f from high toward low\n%s | masks stay fixed across MARGIN" % [pair[0],pair[1],model._crossing_t(model.margin),model.workings]
	# Scope corrected labels to this lesson; preserve ordinary display placements.
	var table_masks:=masks()
	for i in model.labels.size():
		model.labels[i].text="Arrangement %d\nHigh-value mask %d | table mask %d" % [i,model.fifteen_cases[i].config,table_masks[i]]
		model.labels[i].font_size=30;model.labels[i].pixel_size=0.004
