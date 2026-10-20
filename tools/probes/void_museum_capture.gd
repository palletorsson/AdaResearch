extends SceneTree
const Architecture=preload("res://commons/void/architecture.gd")
const Atmosphere=preload("res://commons/void/atmosphere.gd")
var out := "user://"
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	var sky := Atmosphere.new()
	sky.animate_sky=false;root.add_child(sky);sky.set_sky_time(180)
	var building := Architecture.new()
	building.stream_content=true;root.add_child(building)
	var camera := Camera3D.new();root.add_child(camera);camera.make_current()
	root.msaa_3d=Viewport.MSAA_4X
	for index in [1,3,7,8]:
		for old in building.content.roots.values(): old.hide();old.process_mode=Node.PROCESS_MODE_DISABLED
		var content: Node3D=building.content.load_floor(index,true)
		content.show();content.process_mode=Node.PROCESS_MODE_INHERIT
		var visible: Array[int]=[]
		for i in range(maxi(0,index-4),mini(14,index+5)): visible.append(i)
		building.show_floor_window(visible)
		for i in range(30): await physics_frame
		var y: float = -6.0*index
		if index==1:
			camera.position=Vector3(13.6,y+2.2,3.7);camera.look_at(Vector3(11.6,y-.3,1.7))
			await photo("corner-planks.png")
		else:
			camera.position=Vector3(19.5,y+2.4,7.9);camera.look_at(Vector3(0,y+1,-2))
			await photo("floor-%02d.png"%index)
			camera.position=Vector3(-12.9,y+1.8,7.8);camera.look_at(Vector3(-17,y+1,-2))
			await photo("floor-%02d-wing.png"%index)
		print("CAPTURED ",index)
	building.queue_free();camera.queue_free();sky.queue_free()
	for i in range(10): await process_frame
	quit()
func photo(filename: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
