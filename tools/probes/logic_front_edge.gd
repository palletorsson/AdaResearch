extends "res://tools/probes/logic_object_controls.gd"
## Layout change only: verify board-edge placement, shared rear signage and
## representative real contacts on each relocated route, then take new images.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1440,900)
	OS.set_environment("VOID_INVENTORY_PATH",out.path_join("layout-test-inventory.json"))
	await start(false)
	for i in [21,22]:
		await visit_logic_floor(i)
		for a in game.building.content.data.floors[i].artifacts:
			if not str(a.artifact).begins_with("matter_spring_"):continue
			var work: Node3D=station(a.id)
			work.rest_reset.set_physics_process(false)
			var offset: float=work.front_offset()
			check(work.operator+" / launcher and impact target moved together",is_equal_approx(work.launcher.position.z,offset) and is_equal_approx(work.get_node("ImpactTarget").position.z,offset))
			var front_input: float=work.gates[-1].position.z+work.UNIT*.5
			check(work.operator+" / input cubes within 20 cm of front edge",front_input>.60 and front_input<.804)
			check(work.operator+" / title shares rear binary board",work.get_node("Controls").position.is_equal_approx(work.get_node("Readout").position) and work.get_node("Controls").position.z<0)
			check(work.operator+" / no plate obstructs front of mechanism",not work.has_node("Controls/ObjectInstructions") and work.get_node("Controls").find_children("*","MeshInstance3D",true,false).is_empty())
			check(work.operator+" / all current part paths remain editable",work.part_defaults.has("Controls") and work.part_defaults.has("Readout") and work.part_defaults.has("InputX") and work.part_defaults.Controls.bounds[3]>1)
			for bits in (["11"] if work.operator=="AND" else ["10","01"] if work.operator=="OR" else ["0","1"]):await case_object(work,bits)
			work.reset_gate();await frames(20)
		var work: Node3D=station(game.building.content.data.floors[i].artifacts[0].id)
		var cam := Camera3D.new();cam.fov=55;game.add_child(cam)
		cam.global_position=work.to_global(Vector3(2.7,2.15,4.8));cam.look_at(work.to_global(Vector3(0,1.25,0)));cam.make_current()
		var shown: Array[int]=[i];game.building.show_floor_window(shown)
		await frames(3);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("front-edge-"+str(i)+".png"))
		cam.queue_free();game.camera.make_current()
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Native main-floor placement, five Jolt route cases via object controls and current source member paths. No physical headset test."}
	FileAccess.open(out.path_join("layout-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
