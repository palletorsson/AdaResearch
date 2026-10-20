extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/form_grammar_family/form_grammar_family.gd");check("Existing family present",source!=null)
	if source==null:return
	await snapshot("family",source.to_global(Vector3(8,7,10)),source.to_global(Vector3(0,1,0)),70)
	await snapshot("first-three",source.to_global(Vector3(0,2.7,8)),source.to_global(Vector3(0,1,3.2)),80)
	await snapshot("above",source.to_global(Vector3(0,38,-4)),source.to_global(Vector3(0,0,-9)),73)
	var canopy=find_scene("/form_grammar_canopy/form_grammar_canopy.gd")
	if canopy!=null:await snapshot("beneath",canopy.to_global(Vector3(1,1.7,-.3)),canopy.to_global(Vector3(0,4,-4)),80)
