extends Node3D
var failures: Array[String] = []
var checks := 0
class TestHand extends Node3D:
	var picked_up_ranged := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[line-camera] ", "PASS " if ok else "FAIL ", message)
func _ready() -> void: run.call_deferred()
func render_films(work: Node3D) -> void:
	for study in work.studies:
		study.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	var work = load("res://commons/artifacts/line_space_workshop/line_space_workshop.tscn").instantiate()
	work.position = Vector3(5,0,8)
	work.rotation_degrees.y = 180
	add_child(work)
	work.set_process(false)
	for study in work.studies: study.set_process(false)
	var main := Camera3D.new()
	add_child(main)
	main.global_position = work.to_global(Vector3(0,1.65,3.4))
	main.look_at(work.to_global(Vector3(0,1.15,0)))
	main.keep_aspect = Camera3D.KEEP_WIDTH
	main.fov = 78
	main.make_current()
	check(work.studies.size()==4,"Four live camera studies")
	for bay in 4:
		var study = work.studies[bay]
		check(study.viewport.world_3d == work.get_world_3d(),"Study %d films the actual museum world" % bay)
		check((study.screen.layers & study.camera.cull_mask)==0,"Study %d excludes screens from its feed" % bay)
		check(study.viewport.size==Vector2i(384,288),"Study %d has bounded render resolution" % bay)
		for other in 4:
			var mesh: MeshInstance3D = work.rods[other][0].find_children("*","MeshInstance3D",false,false)[0]
			check(bool(mesh.layers & study.camera.cull_mask)==(other==bay),"Camera %d isolates rods of bay %d" % [bay,other])
	await render_films(work)
	var before: Array[PackedByteArray] = []
	for bay in 4:
		var image: Image = work.studies[bay].viewport.get_texture().get_image()
		image.save_png("res://ada_run/line-camera-%d.png" % bay)
		before.append(image.get_data())
		var lit := 0
		for y in range(0,image.get_height(),2):
			for x in range(0,image.get_width(),2):
				if image.get_pixel(x,y).get_luminance()>0.15: lit += 1
		check(lit>15,"Study %d renders visible geometry" % bay)
	get_viewport().get_texture().get_image().save_png("res://ada_run/line-camera-studies.png")
	check(work.studies[0].visibility.is_on_screen(),"A visible monitor enables its live refresh")
	work.studies[0].set_process(true)
	var rod = work.rods[0][0]
	var hand := TestHand.new()
	add_child(hand)
	hand.global_position = rod.global_position
	rod.pick_up(hand)
	hand.position.y += 0.22
	for i in 10: await get_tree().physics_frame
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	for bay in 4:
		var after: PackedByteArray = work.studies[bay].viewport.get_texture().get_image().get_data()
		check((after != before[bay])==(bay==0),"Moving a real grabbed rod changes only its own camera (%d)" % bay)
	rod.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	var orbit_start: Transform3D = work.studies[2].camera.global_transform
	work.studies[2]._elapsed = 9.0
	work.studies[2].update_camera()
	check(not orbit_start.is_equal_approx(work.studies[2].camera.global_transform),"Four-line camera changes viewpoint in its slow orbit")
	main.rotate_y(PI)
	for i in 5: await get_tree().process_frame
	work.studies[0].viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	work.studies[0]._process(0.1)
	check(not work.studies[0].visibility.is_on_screen() and work.studies[0].viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Off-screen monitor stops requesting renders")
	var report := FileAccess.open("res://ada_run/line-camera-report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"headset_verified":false},"  "))
	report.close()
	get_tree().quit(0 if failures.is_empty() else 1)
