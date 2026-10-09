extends SceneTree
const Score = preload("res://artifacts/score.gd")
var gallery: Node3D
var checks: Array = []
var views: Array = []

func _initialize() -> void:
	run.call_deferred()
	var watchdog := Timer.new()
	watchdog.wait_time = 55
	watchdog.one_shot = true
	watchdog.autostart = true
	watchdog.timeout.connect(func(): push_error("Signal room capture timeout"); quit(2))
	root.add_child(watchdog)

func check(title: String, passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	print("PASS " if passed else "FAIL ",title)

func shot(title: String) -> String:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	picture.save_png("res://captures/"+title+".png")
	views.append({"file":title+".png","state":gallery.room.evidence.duplicate(),"camera":str(gallery.camera.transform),"size":[picture.get_width(),picture.get_height()]})
	return picture.get_data().hex_encode().sha256_text()

func geometry_signature(node: Node) -> String:
	var record := ""
	for child in node.get_children():
		if child is MeshInstance3D:
			record += str(child.transform)+str(child.mesh.get_aabb())
	return record.sha256_text()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	root.size = Vector2i(1600,1000)
	root.content_scale_size = Vector2i(1600,1000)
	gallery = load("res://gallery.tscn").instantiate()
	root.add_child(gallery)
	for frame in 10:
		await process_frame
	gallery.panel.visible = false
	var geometry := geometry_signature(gallery.room)
	var initial := await shot("repeat")
	var first_pixels := root.get_texture().get_image()
	check("GPU displays complementary banks on opposite sides of the floor",first_pixels.get_pixel(500,840).r>0.8 and first_pixels.get_pixel(1100,840).r<0.1)
	var signatures := []
	for mode in 3:
		gallery.select(mode)
		var values: PackedByteArray = gallery.room.values.duplicate()
		check("mode %d: every address has a binary value"%mode,values.size()==4096 and values.count(0)+values.count(1)==4096)
		check("mode %d: inventory is exactly 2048 of each"%mode,values.count(0)==2048 and values.count(1)==2048)
		check("mode %d: geometry stays fixed"%mode,geometry_signature(gallery.room)==geometry)
		check("mode %d: same seed and procedure reproduce the array"%mode,Score.make_values(mode,2026)==values)
		if mode==1:
			var rows_preserved := true
			for row in 256:
				var chunk := values.slice(row*16,row*16+16)
				rows_preserved = rows_preserved and (chunk==Score.make_values(0,2026).slice(0,16) or chunk==Score.make_values(0,2026).slice(32,48))
			check("row shuffle preserves every complete original row",rows_preserved)
		if mode>0:
			check("mode %d: another seed chooses another permutation"%mode,Score.make_values(mode,2027)!=values)
		gallery.view(0)
		var pixels := await shot(["repeat","rows","cells"][mode])
		signatures.append(pixels)
		gallery.room.inspect_rows(91)
		var patch: Image = gallery.room.patch_texture.get_image()
		var exact := true
		for r in 4:
			for c in 4:
				exact = exact and (patch.get_pixel(c,3-r).r>0.5)==(values[(91+r)*16+c+6]==1)
		check("mode %d: 4x4 sample reads the same array addresses"%mode,exact)
		gallery.player.position = Vector3(0,0.06,8)
		await physics_frame
		await physics_frame
		var hit: KinematicCollision3D = gallery.player.move_and_collide(Vector3(0,0,-15))
		check("mode %d: visitor crosses entire display floor"%mode,hit==null and gallery.player.position.z<-6.9)
		var support: KinematicCollision3D = gallery.player.move_and_collide(Vector3(0,-0.5,0))
		check("mode %d: floor remains physically solid"%mode,support!=null)
	check("all three modes change native pixels",signatures[0]!=signatures[1] and signatures[1]!=signatures[2] and signatures[0]!=signatures[2])
	gallery.reset()
	check("reset restores seed, mode, inspected rows and offset",gallery.room.seed_value==2026 and gallery.room.mode==0 and gallery.room.row_offset==0 and gallery.room.sample_row==0)
	check("reset restores exact rendered image",await shot("reset")==initial)
	var saved: PackedByteArray = gallery.room.values.duplicate()
	gallery.room.step_rows()
	check("one row step shifts display without resampling",gallery.room.values==saved and gallery.room.display_values.slice(0,16)==saved.slice(16,32))
	for step in 255:
		gallery.room.step_rows()
	check("256 steps return the same displayed record",gallery.room.display_values==saved and gallery.room.row_offset==0)
	var floor_arrays: Array = gallery.room.get_node("FloorDisplay").mesh.surface_get_arrays(0)
	var wall_arrays: Array = gallery.room.get_node("FoldDisplay").mesh.surface_get_arrays(0)
	check("floor-to-wall fold joins positions and UVs exactly",floor_arrays[Mesh.ARRAY_VERTEX][2]==wall_arrays[Mesh.ARRAY_VERTEX][1] and floor_arrays[Mesh.ARRAY_TEX_UV][2]==wall_arrays[Mesh.ARRAY_TEX_UV][1] and floor_arrays[Mesh.ARRAY_VERTEX][3]==wall_arrays[Mesh.ARRAY_VERTEX][0] and floor_arrays[Mesh.ARRAY_TEX_UV][3]==wall_arrays[Mesh.ARRAY_TEX_UV][0])
	check("all room displays share one tiny texture",gallery.room.get_node("FloorDisplay").material_override==gallery.room.get_node("FoldDisplay").material_override and gallery.room.display_texture.get_size()==Vector2(16,256))
	check("the room uses fewer than 100 immediate children",gallery.room.get_child_count()<100)
	check("no automatic pattern process runs",not gallery.room.is_processing())
	gallery.player.position = Vector3(0,0.06,-7)
	await physics_frame
	await physics_frame
	check("back wall stops the visitor",gallery.player.move_and_collide(Vector3(0,0,-4))!=null)
	gallery.player.position = Vector3(5.6,0.06,3)
	await physics_frame
	await physics_frame
	check("side wall stops the visitor",gallery.player.move_and_collide(Vector3(3,0,0))!=null)
	gallery.start_walk()
	check("walk button selects eye camera and hides overlay",gallery.walking and gallery.eye.current and not gallery.panel.visible)
	gallery.stop_walk()
	check("exit walk restores review camera and controls",not gallery.walking and gallery.camera.current and gallery.panel.visible)
	gallery.select(1)
	gallery.new_seed()
	check("new seed control updates both display and readout",gallery.room.seed_value==2027 and gallery.caption.text.contains("2027"))
	gallery.reset()
	gallery.panel.visible = false
	gallery.view(1)
	await shot("inside")
	gallery.view(2)
	gallery.select(2)
	await shot("return")
	gallery.view(3)
	gallery.select(2)
	gallery.room.inspect_rows(90)
	await shot("sample")
	gallery.view(0)
	gallery.panel.visible = true
	await shot("controls")
	var failures := 0
	for item in checks:
		if not item.passed:
			failures+=1
	var report := {"checks":checks,"views":views,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"room_children":gallery.room.get_child_count()}
	FileAccess.open("res://captures/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SIGNAL ROOM: ",checks.size()," checks; ",failures," failures")
	quit(1 if failures else 0)
