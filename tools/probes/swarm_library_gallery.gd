extends "res://commons/testing/capture_artifact_shot.gd"
## Isolated scene photography. No changes to artifact geometry or behavior.
func _run_capture() -> void:
	root.size=Vector2i(1800,1200)
	var stage:=Node3D.new()
	root.add_child(stage)
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(.13,.14,.18)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.65,.65,.72)
	env.ambient_light_energy=.7
	var world:=WorldEnvironment.new()
	world.environment=env
	stage.add_child(world)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-45,-30,0)
	sun.light_energy=1.2
	stage.add_child(sun)
	var info:Dictionary=_find_artifact(_artifact_name)
	if info.is_empty(): quit(1);return
	var packed:PackedScene=load(info.scene)
	var artifact:Node3D=packed.instantiate()
	stage.add_child(artifact)
	await create_timer(_wait_seconds).timeout
	var bounds:=AABB()
	var found:=false
	for n in artifact.find_children("*","VisualInstance3D",true,false):
		if n is Label3D or not n.is_visible_in_tree() or n.get_world_3d()!=artifact.get_world_3d():continue
		var b:AABB=n.global_transform*n.get_aabb()
		if b.size.length_squared()<.00001:continue
		bounds=bounds.merge(b) if found else b
		found=true
	var cam:=Camera3D.new()
	stage.add_child(cam)
	var target:Vector3=bounds.get_center() if found else artifact.global_position
	var span:float=maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z)) if found else 3.0
	cam.position=target+Vector3(.35,.7,1).normalized()*maxf(.7,span*1.5)
	cam.look_at(target)
	cam.fov=55
	cam.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	var err:int=root.get_texture().get_image().save_png(_output_path)
	print("GALLERY ",_artifact_name," bounds ",bounds," camera ",cam.position," retained ",root.get_camera_3d()==cam)
	quit(0 if err==OK and root.get_camera_3d()==cam else 1)
