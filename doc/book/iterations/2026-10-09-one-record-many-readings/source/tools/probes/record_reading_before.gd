extends "res://tools/probes/transformation_encounters.gd"
var work: Node3D
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	work=find_scene("/camera_glitch_study/CameraGlitchStudy.gd")
	check("existing camera study in museum",work!=null)
	if work==null:return
	await snapshot("visitor",work.to_global(Vector3(-1.6,1.65,4.8)),work.to_global(Vector3(-.3,2,0)),74)
	await snapshot("raised",work.to_global(Vector3(-4,5.5,5.5)),work.to_global(Vector3(-.3,1.8,0)),68)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=36
	var origin:=work.global_position-hall.global_basis*Vector3(17.5,0,13.5)
	camera.global_position=origin+hall.global_basis*Vector3(10,42,15)
	camera.look_at(origin+hall.global_basis*Vector3(10,0,15),Vector3.FORWARD);camera.current=true
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
