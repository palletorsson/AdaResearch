extends SceneTree
## Render production components at their actual stops. No substitute geometry.
const OUT := "res://doc/reports/interfaces-2026-09-21/scalar-controls/after/"
func _initialize()->void:run.call_deferred()
func run()->void:
	var world:=Node3D.new();root.add_child(world)
	var library:Node3D=load("res://commons/ui/demo/vr_component_demo.tscn").instantiate();world.add_child(library)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-25,0);world.add_child(light)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8;world.add_child(env)
	var camera:=Camera3D.new();world.add_child(camera);camera.current=true
	camera.position=Vector3(.08,1.65,1.1);camera.look_at(Vector3(0,1.16,0));camera.fov=59
	root.msaa_3d=Viewport.MSAA_4X
	for page in [0,2,7,8]:
		library.show_page(page)
		for end in [0,1]:
			for control in library.controls:
				if control.has_method("set_normalized_value"):control.set_normalized_value(end)
				var joint:Node3D=control.get_node_or_null("SliderOrigin/InteractableSlider")
				if joint and joint.get("auto_drive")!=null:
					joint.auto_drive=false;joint.move_slider(joint.limit_min if end==0 else joint.limit_max)
			for i in 15:await process_frame;await physics_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"stops-%d-%d.png" % [page,end])
	quit()
