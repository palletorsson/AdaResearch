extends SceneTree
## Offline bake of the web gallery's real Gray–Scott fields. No simulation on hall entry.
const SOURCE := "res://commons/rd_grammar/research_configs.json"
const OUT := "res://commons/artifacts/rd_museum_gallery/"
const Simulator = preload("res://commons/rd_grammar/rd_sim.gd")
const Builder = preload("res://commons/artifacts/gallery_winner_showcase/gallery_winner_showcase.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	assert(DisplayServer.get_name() != "headless", "Bake with --no-window --rendering-method gl_compatibility; the dummy renderer drops MultiMesh buffers.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var configs: Array = JSON.parse_string(FileAccess.get_file_as_string(SOURCE)).configs
	var builder := Builder.new()
	var gallery := Node3D.new()
	gallery.name = "RDGallery"
	gallery.set_meta("source", SOURCE)
	gallery.set_meta("snapshot", true)
	# Read from the side wall; leave the central sightline and aisle open.
	var heading := label(gallery, "Title", "REACTION / DIFFUSION", Vector3(6.35, 2.25, 1.3), 48)
	var introduction := label(gallery, "Introduction", "18 fields, kept at different moments\nColour / relief / pillars", Vector3(6.35, 1.72, 1.3), 24)
	heading.rotation.y = -PI * 0.5
	introduction.rotation.y = -PI * 0.5
	var receipts: Array = []
	for i in configs.size():
		var cfg: Dictionary = configs[i]
		var id: String = cfg.id
		var filename := OUT + id + ".scn"
		var study: Node3D
		# Explicit --rebuild refreshes all simulations; ordinary rebakes reuse completed ones.
		if FileAccess.file_exists(filename) and not "--rebuild" in OS.get_cmdline_user_args():
			study = load(filename).instantiate()
			assert(study.get_meta("config") == cfg, "Source changed: run with --rebuild")
			if cfg.render_mode == "pillars":
				var cached: MultiMesh = study.get_node("Field").multimesh
				assert(cached.buffer.size() == cached.instance_count * 16, "Pillar cache is incomplete: run with --rebuild using the real renderer")
		else:
			print("[rd bake] simulating ", id)
			var before := Time.get_ticks_msec()
			study = Node3D.new()
			study.name = id
			study.set_meta("config", cfg)
			var form: Node3D = builder._build_live_rd(cfg)
			form.name = "Field"
			# Uniform display scale: preserve the source's relief proportions.
			form.scale = Vector3.ONE * (1.2 / float(cfg.get("world_size", 3.0)))
			form.position.y = 0.91
			# The shared legacy heightmap builder calculates downward normals.
			# Correct this baked display only; leave all existing artifacts untouched.
			if form is MeshInstance3D and cfg.render_mode == "heightmap":
				var arrays: Array = form.mesh.surface_get_arrays(0)
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for j in normals.size(): normals[j] = -normals[j]
				arrays[Mesh.ARRAY_NORMAL] = normals
				var corrected := ArrayMesh.new()
				corrected.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				form.mesh = corrected
			study.add_child(form)
			box(study, "Plinth", Vector3(2.62, 0.9, 2.62), Vector3(0, 0.45, 0), Color(0.86, 0.85, 0.81), true)
			box(study, "Rim", Vector3(2.46, 0.012, 2.46), Vector3(0, 0.902, 0), Color(0.04, 0.045, 0.05), false)
			var title := id.substr(5).replace("_heightmap", "").replace("_plate", "").replace("_pillars", "").replace("_", " ").capitalize()
			var defaults: Dictionary = Simulator.PRESETS.get(cfg.get("preset", "spots"), Simulator.PRESETS.spots)
			var feed := float(cfg.get("F", defaults.F))
			var kill := float(cfg.get("K", defaults.K))
			label(study, "Name", "%02d  %s" % [i + 1, title], Vector3(0, 0.64, -1.318), 32)
			label(study, "Parameters", "F %.4f   K %.4f\n%s / %d steps / seed %d\nSaved simulation" % [feed, kill, cfg.render_mode, cfg.iterations, cfg.seed], Vector3(0, 0.34, -1.318), 21)
			own(study, study)
			await RenderingServer.frame_post_draw
			if form is MultiMeshInstance3D:
				assert(form.multimesh.buffer.size() == form.multimesh.instance_count * 16)
			var packed := PackedScene.new()
			assert(packed.pack(study) == OK)
			assert(ResourceSaver.save(packed, filename, ResourceSaver.FLAG_COMPRESS) == OK)
			print("[rd bake] saved ", id, " in ", Time.get_ticks_msec() - before, " ms")
		# Flatten cached instances before assigning their descendants to this scene.
		# Otherwise packing records both inherited children and replacements, leaking
		# the inherited geometry and collision bodies when the gallery is loaded.
		study.scene_file_path = ""
		study.position = Vector3(-2.2 if i % 2 == 0 else 2.2, 0, floori(float(i) / 2.0) * 3.4)
		gallery.add_child(study)
		receipts.append({"id":id, "scene":filename, "config":cfg, "position":[study.position.x, study.position.y, study.position.z]})
		await process_frame
	own(gallery, gallery)
	var packed := PackedScene.new()
	assert(packed.pack(gallery) == OK)
	assert(ResourceSaver.save(packed, OUT + "rd_museum_gallery.scn", ResourceSaver.FLAG_COMPRESS) == OK)
	var f := FileAccess.open(OUT + "manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"source":SOURCE, "source_sha256":FileAccess.get_sha256(SOURCE), "snapshot":true, "display_scale":"uniform: 1.2 / world_size", "items":receipts}, "\t") + "\n")
	f.close()
	gallery.free()
	builder.free()
	print("[rd bake] COMPLETE: ", configs.size(), " studies")
	quit()

func own(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		own(child, owner_root)

func box(parent: Node3D, title: String, size: Vector3, at: Vector3, colour: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.82
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Support"
		mesh.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)

func label(parent: Node3D, title: String, words: String, at: Vector3, font_size: int) -> Label3D:
	var text := Label3D.new()
	text.name = title
	text.text = words
	text.font_size = font_size
	text.pixel_size = 0.003
	text.outline_size = 0
	text.modulate = Color(0.12, 0.13, 0.14)
	text.no_depth_test = false
	text.position = at
	text.rotation.y = PI
	parent.add_child(text)
	return text
