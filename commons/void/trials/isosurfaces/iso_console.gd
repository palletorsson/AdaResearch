extends "res://commons/artifacts/timing_machines/iso_workshop.gd"
## Only the host lookup changes; original actions and extraction stay inherited.
const Links = preload("res://commons/void/trials/isosurfaces/floor_links.gd")

func _bind() -> void:
	var hall: Node=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null:return
	for attempt in 100:
		field_root=Links.find_artifact(hall,"voxel_noise_demo")
		if field_root!=null:break
		await get_tree().create_timer(0.1).timeout
	if field_root==null:push_error("Introduction field is missing");return
	model=_script_node(field_root,"VoxelNoiseMarchingCubes.gd")
	model.noise_seed=1337;model.num_points_per_axis=24;model.iso_level=0.5
	model.setup_noise();model.regenerate()
	for camera in field_root.find_children("*","Camera3D",true,false):camera.current=false
	ids=["LEVEL","SAMPLES","HOLD","CLEAR","RESET","RULE"]
	_build_compact_console(ids,"WHERE DOES THE BOUNDARY BEGIN?")
	rule_card=label("density = (noise(x,y,z) + 1) / 2\nEach corner compares density < level.\nEight bits choose connections; edge values locate crossings.\nThe field, triangles and collision are different representations.",Vector3(0,2.1,0.5),0.001)
	rule_card.visible=false
	Links.light(self)
	held_label=Label3D.new();held_label.text="HOLD leaves a second specimen here";held_label.font_size=40;held_label.pixel_size=0.005;held_label.outline_size=8;hall.add_child(held_label)
	held_label.global_position=field_root.global_position+Vector3(8,-2.5,0)
	ready_for_input=true;refresh()

