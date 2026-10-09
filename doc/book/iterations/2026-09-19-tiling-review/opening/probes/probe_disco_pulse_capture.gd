extends "res://doc/book/iterations/2026-09-19-tiling-review/opening/probes/capture_opening.gd"
## Both images use the current assembled hall and the same held checker.
## The before image runs the snapshotted original controller at its authored placement.

func test_disco() -> void:
	var n:Node3D=artifacts.disco_controls
	var seq:Node3D=artifacts.step_sequencer
	seq.stop();seq.set_process(false)
	if "--snapshot-before" in OS.get_cmdline_user_args():
		var placement:=n.transform
		var parent:=n.get_parent()
		parent.remove_child(n);n.queue_free()
		n=load("res://doc/book/iterations/2026-09-19-tiling-review/opening/before/commons/artifacts/regularity/disco_controls.gd").new()
		n.set_meta("config_mode","colour")
		parent.add_child(n);n.transform=placement
		artifacts.disco_controls=n
		await process_frame;await process_frame
	check(is_instance_valid(n.floor_node),"chosen original or current controller finds actual floor")
	n.running=false;n.pattern=0;n.palette=1;n.phase=0;n.paint()
	var baseline:Array=n.floor_node.tile_colors.duplicate()
	await process_frame
	for column in [3,7]:
		for event in 4:seq.emit_signal("step_triggered",1,column)
	check(n.floor_node.tile_colors!=baseline,"both runs receive identical musical column events")
	await create_timer(0.8).timeout
	var original:bool="--snapshot-before" in OS.get_cmdline_user_args()
	check((n.floor_node.tile_colors!=baseline)==original,"original retains the flash; repaired controller expires it")
	check(n.phase==0 and not n.running,"held pattern phase remains zero")

func capture_views(_data:Dictionary) -> void:
	root.size=Vector2i(1400,900)
	var cam:=Camera3D.new();current_scene.add_child(cam);cam.fov=74
	cam.global_position=grid.to_global(Vector3(14.5,5,7.59))
	cam.look_at(grid.to_global(Vector3(9.5,2,14.26)))
	for frame in 45:cam.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"Pattern_Disco-held-pulse.png")
