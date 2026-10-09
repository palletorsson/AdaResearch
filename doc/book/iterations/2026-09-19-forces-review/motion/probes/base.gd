extends SceneTree
var OUT := ""
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): OUT=arg.trim_prefix("--out=")
	run.call_deferred()
func run() -> void: pass
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[forces-motion] ", "PASS " if ok else "FAIL ",message)
func capture(cam:Camera3D,pos:Vector3,target:Vector3,suffix:String) -> void:
	if DisplayServer.get_name()=="headless":return
	cam.global_position=pos;cam.look_at(target)
	for i in range(20):await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+suffix+".png")
	var f:=FileAccess.open(OUT+suffix+"-camera.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":[pos.x,pos.y,pos.z],"target":[target.x,target.y,target.z],"fov":cam.fov,"viewport":[root.size.x,root.size.y]},"  "));f.close()
