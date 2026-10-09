extends SceneTree
var gallery: Node3D
var checks: Array = []
var views: Array = []

func _initialize() -> void:
	run.call_deferred()
	var watchdog := Timer.new()
	watchdog.wait_time = 90.0
	watchdog.one_shot = true
	watchdog.autostart = true
	watchdog.timeout.connect(func(): push_error("Capture exceeded 90 seconds"); quit(2))
	root.add_child(watchdog)

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("PASS " if passed else "FAIL ",label)

func capture(name: String) -> Image:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.save_png("res://captures/"+name+".png")
	views.append({"file":name+".png","study":gallery.IDS[gallery.mode],"amount":gallery.artifact.amount,"size":[result.get_width(),result.get_height()]})
	return result

func image_hash(value: Image) -> String:
	return value.get_data().hex_encode().sha256_text()

func image_mean_difference(a: Image, b: Image) -> float:
	var first := a.get_data()
	var second := b.get_data()
	var total := 0.0
	for i in first.size():
		total += abs(int(first[i])-int(second[i]))
	return total / float(first.size())

func geometry_signature(root_node: Node) -> String:
	var data := ""
	for child in root_node.get_children():
		if child is MeshInstance3D:
			data += str(child.transform)+str(child.mesh.get_aabb())
	return data.sha256_text()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	root.content_scale_size = Vector2i(1600,1000)
	root.size = Vector2i(1600,1000)
	gallery = load("res://gallery.tscn").instantiate()
	root.add_child(gallery)
	# Allow the procedural sky's reflected radiance to finish its first update.
	for i in 45:
		await process_frame
	for room in 5:
		gallery.select_room(room)
		gallery.panel.visible = false
		await process_frame
		var name: String = gallery.IDS[room]
		var original_evidence: Dictionary = gallery.artifact.evidence.duplicate(true)
		var camera_transform: Transform3D = gallery.camera.transform
		var original_geometry := geometry_signature(gallery.artifact)
		var hero := await capture(name+"-hero")
		check(name+": native capture has requested proportions",hero.get_size()==Vector2i(1600,1000))
		gallery.change_amount(0.0)
		var before_geometry := geometry_signature(gallery.artifact)
		var before_evidence: Dictionary = gallery.artifact.evidence.duplicate(true)
		var before := await capture(name+"-before")
		gallery.change_amount(1.0)
		var after := await capture(name+"-after")
		var after_evidence: Dictionary = gallery.artifact.evidence.duplicate(true)
		check(name+": parameter changes native pixels",image_hash(before)!=image_hash(after))
		check(name+": comparisons retain the same camera",gallery.camera.transform==camera_transform)
		match room:
			0:
				check("75 fragments retain every address",before_evidence.positions==after_evidence.positions and after_evidence.fragment_count==75)
				var after_mesh: ArrayMesh = gallery.artifact.get_child(1).mesh
				var vertices: PackedVector3Array = after_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				check("fragment geometry contains 12 triangles",vertices.size()==36)
			1:
				check("opening changes while headroom and visitor width stay fixed",before_evidence.opening_width<0.56 and after_evidence.opening_width>0.56 and before_evidence.opening_height==after_evidence.opening_height)
				gallery.player.position = Vector3(0,0.06,2)
				await physics_frame
				await physics_frame
				var wide_collision: KinematicCollision3D = gallery.player.move_and_collide(Vector3(0,0,-4))
				check("visitor capsule can cross the wide opening",wide_collision==null and gallery.player.position.z < -1.8)
				gallery.change_amount(0.0)
				gallery.player.position = Vector3(0,0.06,2)
				await physics_frame
				await physics_frame
				var narrow_collision: KinematicCollision3D = gallery.player.move_and_collide(Vector3(0,0,-4))
				check("narrow opening physically stops the same capsule",narrow_collision!=null and gallery.player.position.z>0)
			2:
				check("forest keeps 48 seeded sites and three cones each",before_evidence.tree_positions==after_evidence.tree_positions and after_evidence.tree_count==48 and after_evidence.cones_per_tree==3)
				check("height increases without changing the site selection",after_evidence.height_factor>before_evidence.height_factor)
			3:
				check("pattern moves without rebuilding geometry differently",before_geometry==geometry_signature(gallery.artifact))
				check("shared coordinates reach all four pattern materials",gallery.artifact.animated_materials.size()==4 and after_evidence.mapping=="world triplanar")
				gallery.artifact.set_clock(3.0)
				var drift := await capture(name+"-drift")
				check("controlled clock moves the pattern",image_hash(drift)!=image_hash(after))
			4:
				check("unfold preserves six arms and three heads",before_evidence.limbs==after_evidence.limbs and after_evidence.limbs==6 and after_evidence.heads==3)
				check("unfold extends the limb tips",absf(after_evidence.tips[0].x)>absf(before_evidence.tips[0].x))
		gallery.change_amount(gallery.DEFAULTS[room])
		gallery.artifact.set_clock(0.0)
		check(name+": restoring the score restores geometry and evidence",geometry_signature(gallery.artifact)==original_geometry and gallery.artifact.evidence==original_evidence)
		var returned := await capture(name+"-returned")
		# Resource recreation can change a few shadow-edge pixels on this GPU.
		# Geometry/evidence are exact; mean image error must be < .01 in 8-bit units.
		var error := image_mean_difference(hero,returned)
		check(name+": restored image differs by <0.01 mean 8-bit units",error < 0.01)
		checks[-1]["mean_absolute_error_8bit"] = error
		gallery.panel.visible = true
		await capture(name+"-controls")
	gallery.select_room(0)
	gallery.start_walk()
	check("walk mode selects the visitor camera",gallery.walking and gallery.eye.current and not gallery.panel.visible)
	gallery.stop_walk()
	check("leaving walk restores the comparison camera and controls",not gallery.walking and gallery.camera.current and gallery.panel.visible)
	var passed := true
	for result in checks:
		passed = passed and result.passed
	FileAccess.open("res://captures/report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"views":views,"engine":Engine.get_version_info(),"scope":"Native desktop study rooms. No installed spine placements, XR interaction or learner trial."},"  "))
	quit(0 if passed else 1)
