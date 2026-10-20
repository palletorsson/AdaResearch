extends SceneTree
var work:Node3D
var camera:Camera3D
func _initialize()->void:run.call_deferred()
func shot(id:String,eye:Vector3,target:Vector3)->void:
	camera.global_position=eye;camera.look_at(target);camera.current=true
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://ada_run/pivot_body/"+id+".png"))
func run()->void:
	var preview=load("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/preview.tscn").instantiate();root.add_child(preview);current_scene=preview
	work=preview.work;work.set_process(false);work.act("RESET")
	camera=Camera3D.new();camera.fov=54;root.add_child(camera)
	await create_timer(.5).timeout
	await shot("preview-rest",Vector3(-3.1,2.55,6.4),Vector3(0,2.15,-.35))
	work.clock=2.7;work.turn=-.15;work.limbs=.75;work.set_pivot(Vector3(.35,.2,0));work.update_body()
	await shot("preview-creature",Vector3(-3.1,2.55,6.4),Vector3(0,2.15,-.35))
	work.act("BONES")
	await shot("preview-bones",Vector3(-1.8,2.8,4.4),Vector3(0,2.3,-.4))
	work.act("BONES")
	await shot("preview-console",Vector3(.4,1.9,3.3),Vector3(0,1.1,1.6))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=12
	camera.global_position=Vector3(0,18,0);camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://ada_run/pivot_body/preview-overhead.png"))
	quit()
