# capture_mesh_body.gd
# Builds a FlowerBody as an actual mesh scene (not a voxel preview), assigns
# per-slot shader materials, captures the result. Proves the SDF → Mesh
# pipeline with per-part shading.

extends SceneTree

const FlowerBodyClass = preload("res://commons/morphology/sdf/flower_body.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"

const SHADER_PLANT := preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_FLESH := preload("res://commons/morphology/sdf/shaders/flesh.gdshader")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== MESH BODY CAPTURE ===")
	var out_dir := "user://mesh_body"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	# Build per-slot materials — each slot gets its own shader instance so
	# parameters can differ (petal color ≠ leaf color even though both are plant).
	var stem_mat := ShaderMaterial.new()
	stem_mat.shader = SHADER_PLANT
	stem_mat.set_shader_parameter("base_color", Color(0.25, 0.48, 0.18))
	stem_mat.set_shader_parameter("edge_color", Color(0.7, 0.85, 0.35))
	stem_mat.set_shader_parameter("rim_strength", 0.8)

	var leaf_mat := ShaderMaterial.new()
	leaf_mat.shader = SHADER_PLANT
	leaf_mat.set_shader_parameter("base_color", Color(0.3, 0.55, 0.2))
	leaf_mat.set_shader_parameter("edge_color", Color(0.85, 0.95, 0.45))
	leaf_mat.set_shader_parameter("rim_strength", 1.3)
	leaf_mat.set_shader_parameter("vein_strength", 0.25)

	var petal_mat := ShaderMaterial.new()
	petal_mat.shader = SHADER_PLANT
	petal_mat.set_shader_parameter("base_color", Color(0.95, 0.45, 0.65))  # pink
	petal_mat.set_shader_parameter("edge_color", Color(1.0, 0.85, 0.9))
	petal_mat.set_shader_parameter("rim_strength", 1.6)
	petal_mat.set_shader_parameter("rim_power", 1.8)
	petal_mat.set_shader_parameter("vein_strength", 0.1)
	petal_mat.set_shader_parameter("roughness_val", 0.3)

	var stamen_mat := ShaderMaterial.new()
	stamen_mat.shader = SHADER_FLESH
	stamen_mat.set_shader_parameter("skin_color", Color(1.0, 0.85, 0.3))  # yellow pollen
	stamen_mat.set_shader_parameter("interior_color", Color(1.0, 0.5, 0.1))
	stamen_mat.set_shader_parameter("sss_strength", 0.5)

	var materials: Dictionary = {
		"stem": stem_mat,
		"leaf": leaf_mat,
		"petal": petal_mat,
		"stamen": stamen_mat,
	}

	# Build flower SDF, then bake to mesh body
	var flower = FlowerBodyClass.new()
	flower.dna = {
		"scale": 1.2,
		"segments": 4.0,
		"symmetry": 6.0,
		"pattern_scale": 1.0,
	}
	flower.build()
	var mesh_body: Node3D = flower.build_mesh_body(materials)
	mesh_body.position = Vector3.ZERO
	demo.add_child(mesh_body)
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(out_dir + "/flower_shaded.png")
		print("  Saved flower_shaded.png")

	# Count the mesh children so we can report
	var count: int = mesh_body.get_child_count()
	print("  Flower built from %d MeshInstance3D nodes" % count)

	print("=== DONE — captures in %s ===" % out_dir)
	quit(0)
