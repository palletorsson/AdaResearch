extends "res://commons/artifacts/timing_machines/pg_workshop.gd"
## One field, multiple decisions. Existing marching-cubes code owns extraction.
var actions_taken := 0
var level_index := 0
var held_triangles := 0
var held_label: Label3D
var field_root: Node3D

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
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token=="voxel_noise_demo":field_root=n
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
	for at in [Vector3(7,8,10),Vector3(15,8,10),Vector3(11,8,23)]:
		var light:=OmniLight3D.new();light.position=at+Vector3(0,0,int(em.get("VESTIBULE_H")));light.omni_range=19;light.light_energy=5;hall.add_child(light)
	held_label=Label3D.new();held_label.text="HOLD leaves a second specimen here";held_label.font_size=40;held_label.pixel_size=0.005;held_label.outline_size=8;hall.add_child(held_label)
	held_label.global_position=field_root.global_position+Vector3(8,-2.5,0)
	ready_for_input=true;refresh()

func act(id: String) -> void:
	if not ready_for_input or busy:return
	busy=true;actions_taken+=1
	match id:
		"LEVEL":level_index=(level_index+1)%3;model.iso_level=[0.5,0.45,0.55][level_index];model.regenerate()
		"SAMPLES":sample_index=(sample_index+1)%3;model.num_points_per_axis=[24,16,32][sample_index];model.regenerate()
		"HOLD":
			_clear_held()
			held=MeshInstance3D.new();held.mesh=model.mesh_instance.mesh.duplicate(true)
			model.get_parent().get_parent().add_child(held)
			held.global_transform=model.mesh_instance.global_transform;held.global_position+=Vector3(8,0,0)
			held.material_override=material("e3a8bf")
			held_triangles=held.mesh.surface_get_array_len(0)/3
			held_label.text="HELD · level %.2f · %d³ samples\n%d triangles · display copy, no collision" % [model.iso_level,model.num_points_per_axis,held_triangles]
		"CLEAR":_clear_held();held_label.text="HOLD leaves a second specimen here"
		"RESET":level_index=0;sample_index=0;model.iso_level=0.5;model.num_points_per_axis=24;model.regenerate()
		"RULE":rule_card.visible=not rule_card.visible
	busy=false;refresh()

func _clear_held() -> void:
	if is_instance_valid(held):held.get_parent().remove_child(held);held.queue_free()
	held=null;held_triangles=0

func refresh() -> void:
	if readout==null or model==null:return
	var count: int=model.mesh_instance.mesh.surface_get_array_len(0)/3 if model.mesh_instance.mesh!=null else 0
	readout.text="LEVEL %.2f | %d³ = %d samples\n%d triangles | seed 1337 stays fixed\nHOLD copies the mesh; RESET keeps that copy" % [model.iso_level,model.num_points_per_axis,model.num_points_per_axis**3,count]
