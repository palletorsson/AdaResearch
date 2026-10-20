extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	for suffix in ["/vogue_timeline.gd", "/computer_vision_vr.gd", "/convolutional_neural_networks_cnns_vr.gd"]:
		var art:=find_scene(suffix)
		if art==null:continue
		var bounds:=AABB();var first:=true
		for mesh in art.find_children("*","MeshInstance3D",true,false):
			var box:AABB=hall.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		observations[suffix]={"position":xyz(hall.to_local(art.global_position)),"bounds_min":xyz(bounds.position),"bounds_size":xyz(bounds.size)}
	var stage:=find_scene("/vogue_timeline.gd")
	stage.set_process(false);stage.render_pose(8.0)
	stage.get_node("PoseLearningStation").set_process(false)
	observations.hall=xyz(hall.global_position)
	await snapshot("before",stage.to_global(Vector3(1,2.3,3.5)),stage.to_global(Vector3(-0.4,1.35,-0.45)),70)
	await snapshot("overhead",stage.to_global(Vector3(-4,14,12)),stage.to_global(Vector3(-4,0,-1)),65)
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
