# capture_raymarch_ab.gd
# A/B comparison — five SDFs rendered with BOTH voxel preview and
# raymarch preview, captured side by side. Proves the raymarch path
# produces smoother surfaces with far fewer draw calls.

extends SceneTree

const BoxSDF           = preload("res://commons/morphology/sdf/box_sdf.gd")
const RoundedBoxSDF    = preload("res://commons/morphology/sdf/rounded_box_sdf.gd")
const ConeSDF          = preload("res://commons/morphology/sdf/cone_sdf.gd")
const FlowerBody       = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBody       = preload("res://commons/morphology/sdf/fungus_body.gd")
const BlendedSDF       = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFVoxelPreview  = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")
const SDFRaymarchPreview = preload("res://commons/morphology/sdf/sdf_raymarch_preview.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== RAYMARCH A/B CAPTURE ===")
	var out_dir := "user://raymarch_ab"
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
	if cam:
		cam.position = Vector3(3.0, 2.5, 3.0)
		cam.look_at(Vector3.ZERO, Vector3.UP)
		cam.fov = 40.0

	# Subjects: spans analytical (box, cone) through compound (flower) and
	# blended (flower↔fungus t=0.5) so we can see raymarch handle each class.
	var dna: Dictionary = {"scale": 0.8, "segments": 4.0, "symmetry": 6.0, "pattern_scale": 1.0, "pattern_density": 0.6}
	var flower = FlowerBody.new(); flower.dna = dna; flower.build()
	var fungus = FungusBody.new(); fungus.dna = dna; fungus.build()
	var blend = BlendedSDF.new()
	blend.a = flower; blend.b = fungus; blend.t = 0.5; blend.mode = "weighted"
	blend.smoothness = 0.25; blend.weighted_inflation = 0.35

	var flower2 = FlowerBody.new(); flower2.dna = dna; flower2.build()

	var subjects: Array = [
		{"name": "01_box",           "sdf": BoxSDF.make(Vector3.ZERO, Vector3(0.6, 0.6, 0.6))},
		{"name": "02_rounded_box",   "sdf": RoundedBoxSDF.make(Vector3.ZERO, Vector3(0.65, 0.45, 0.65), 0.18)},
		{"name": "03_cone",          "sdf": ConeSDF.make(Vector3(0, 1.0, 0), Vector3.ZERO, 0.55)},
		{"name": "04_flower",        "sdf": flower2},
		{"name": "05_flower_fungus", "sdf": blend},
	]

	for s in subjects:
		# Voxel version (left)
		var voxel = SDFVoxelPreview.new()
		voxel.sdf = s.sdf
		voxel.resolution = Vector3i(40, 40, 40)
		voxel.surface_threshold = 0.05
		voxel.auto_rebuild_on_ready = false
		voxel.size_by_depth = false
		voxel.surface_only = true
		demo.add_child(voxel)
		voxel.rebuild()
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img_v := root.get_viewport().get_texture().get_image()
		if img_v:
			img_v.save_png(out_dir + "/%s_voxel.png" % s.name)
			print("  Saved %s_voxel.png" % s.name)
		voxel.queue_free()
		await process_frame

		# Raymarch version (right)
		var ray = SDFRaymarchPreview.new()
		ray.sdf = s.sdf
		ray.resolution = Vector3i(64, 64, 64)
		ray.base_color = Color(0.9, 0.85, 0.75)
		ray.edge_color = Color(1.0, 0.95, 0.8)
		ray.rim_strength = 0.8
		ray.auto_rebuild_on_ready = false
		demo.add_child(ray)
		ray.rebuild()
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img_r := root.get_viewport().get_texture().get_image()
		if img_r:
			img_r.save_png(out_dir + "/%s_raymarch.png" % s.name)
			print("  Saved %s_raymarch.png" % s.name)
		ray.queue_free()
		await process_frame

	print("=== DONE — A/B captures in %s ===" % out_dir)
	quit(0)
