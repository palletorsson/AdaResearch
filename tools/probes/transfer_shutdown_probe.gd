extends SceneTree
## Focused diagnostic: isolate an original artifact's initialization/teardown.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path:String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):path=arg.trim_prefix("--scene=")
	var world:=Node3D.new();root.add_child(world)
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,2,4);camera.look_at(Vector3.UP)
	for pass_index in 2:
		var node:Node3D=load(path).instantiate()
		if "--no-particles" in OS.get_cmdline_user_args():node.set("show_particles",false)
		if "force_xr" in node:node.set("force_xr",false)
		world.add_child(node)
		if node.has_method("scene_loaded"):node.scene_loaded();node.scene_visible();node.body.scripted_input=true
		for frame in 90:await process_frame
		node.queue_free()
		for frame in 15:await process_frame
	world.queue_free()
	for frame in 15:await process_frame
	print("TEARDOWN_DONE ",path)
	quit()
