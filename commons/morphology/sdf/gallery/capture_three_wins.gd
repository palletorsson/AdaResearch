# capture_three_wins.gd
# Validates all three moves shipped today:
#   1. Raymarched operator/stacked rows in the gallery (look smooth)
#   2. A classical Doric column rendered as a mesh body with stone shader
#   3. A flower↔fungus BlendedSDF baked to an ArrayMesh via CPU marching
#      cubes — proves the production mesh path works for blends.

extends SceneTree

const Column           = preload("res://commons/morphology/objects/classical/column.gd")
const Amphora          = preload("res://commons/morphology/objects/classical/amphora.gd")
const Pedestal         = preload("res://commons/morphology/objects/classical/pedestal.gd")
const RuinWall         = preload("res://commons/morphology/objects/classical/ruin_wall.gd")
const FlowerBody       = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBody       = preload("res://commons/morphology/sdf/fungus_body.gd")
const BlendedSDF       = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFMarchingCubes = preload("res://commons/morphology/sdf/sdf_marching_cubes.gd")
const SHADER_BARK      = preload("res://commons/morphology/sdf/shaders/bark.gdshader")
const SHADER_FLESH     = preload("res://commons/morphology/sdf/shaders/flesh.gdshader")
const SHADER_PLANT     = preload("res://commons/morphology/sdf/shaders/plant.gdshader")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== THREE WINS CAPTURE ===")
	var out_dir := "user://three_wins"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	var cam: Camera3D = null
	for child in demo.get_children():
		if child is Camera3D:
			cam = child
			break

	# ─── 2. Classical objects — each rendered as a mesh body with stone shader ───
	# (We validate #1 raymarch swap via the existing sdf_gallery capture — see
	# capture_gallery.gd — and #2 MC below. This capture focuses on #3.)
	var stone_mat := ShaderMaterial.new()
	stone_mat.shader = SHADER_BARK
	stone_mat.set_shader_parameter("bark_color", Color(0.78, 0.72, 0.62))
	stone_mat.set_shader_parameter("crevice_color", Color(0.32, 0.28, 0.22))
	stone_mat.set_shader_parameter("crack_scale", 20.0)
	stone_mat.set_shader_parameter("crack_depth", 0.55)

	var stone_mats: Dictionary = {
		"default": stone_mat, "plinth": stone_mat, "shaft": stone_mat,
		"capital": stone_mat, "abacus": stone_mat, "base": stone_mat,
		"die": stone_mat, "cornice": stone_mat, "foot": stone_mat,
		"belly": stone_mat, "shoulder": stone_mat, "neck": stone_mat,
		"lip": stone_mat, "handle": stone_mat, "wall_block": stone_mat,
		"rubble": stone_mat, "base_course": stone_mat,
	}

	var ruins: Array = [
		{"name": "column",   "recipe": Column},
		{"name": "pedestal", "recipe": Pedestal},
		{"name": "amphora",  "recipe": Amphora},
		{"name": "ruin_wall","recipe": RuinWall},
	]

	# Place all four in a row for a group shot
	var group := Node3D.new()
	demo.add_child(group)
	for i in ruins.size():
		var r: Dictionary = ruins[i]
		var body = r.recipe.new()
		body.dna = {}
		body.joint_k = 0.03  # crisp joinery for architecture
		body.build()
		var mesh_body: Node3D = body.build_mesh_body(stone_mats)
		mesh_body.position = Vector3((float(i) - 1.5) * 1.5, 0, 0)
		group.add_child(mesh_body)

	if cam:
		cam.position = Vector3(0, 2.0, 4.0)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		cam.fov = 45.0

	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(out_dir + "/classical_quartet.png")
		print("  Saved classical_quartet.png (column + pedestal + amphora + ruin_wall)")

	group.queue_free()
	await process_frame

	# ─── #2 CPU Marching Cubes — bake a BlendedSDF as an ArrayMesh ───
	var dna: Dictionary = {"scale": 0.8, "segments": 4.0, "symmetry": 6.0, "pattern_scale": 1.0, "pattern_density": 0.6}
	var flower = FlowerBody.new(); flower.dna = dna; flower.build()
	var fungus = FungusBody.new(); fungus.dna = dna; fungus.build()
	var blend = BlendedSDF.new()
	blend.a = flower; blend.b = fungus; blend.t = 0.5; blend.mode = "weighted"
	blend.smoothness = 0.25; blend.weighted_inflation = 0.35

	var t0: int = Time.get_ticks_msec()
	var arr_mesh: ArrayMesh = SDFMarchingCubes.bake(blend, Vector3i(56, 72, 56))
	var dt: int = Time.get_ticks_msec() - t0
	if arr_mesh:
		print("  MC bake: %d ms, %d triangles" % [dt, arr_mesh.surface_get_array_len(0) / 3])
		var mi := MeshInstance3D.new()
		mi.mesh = arr_mesh
		# Apply a plant-ish shader to the blended form
		var plant_mat := ShaderMaterial.new()
		plant_mat.shader = SHADER_PLANT
		plant_mat.set_shader_parameter("base_color", Color(0.55, 0.4, 0.35))
		plant_mat.set_shader_parameter("edge_color", Color(1.0, 0.85, 0.6))
		plant_mat.set_shader_parameter("rim_strength", 1.0)
		mi.material_override = plant_mat
		mi.position = Vector3.ZERO
		demo.add_child(mi)

		if cam:
			cam.position = Vector3(2.5, 2.5, 2.5)
			cam.look_at(Vector3(0, 0.5, 0), Vector3.UP)

		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img2 := root.get_viewport().get_texture().get_image()
		if img2:
			img2.save_png(out_dir + "/mc_blended_kingdom.png")
			print("  Saved mc_blended_kingdom.png (flower↔fungus via marching cubes)")

	print("=== DONE — captures in %s ===" % out_dir)
	quit(0)
