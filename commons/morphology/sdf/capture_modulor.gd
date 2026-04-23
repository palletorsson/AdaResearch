# capture_modulor.gd
# Proves self-similarity across Modulor fold levels. Renders:
#   1. An ARM FoldChain by itself — the φ-ladder visible: shoulder → upper
#      arm → forearm → hand → finger, each link 1/φ of its parent.
#   2. A walker at ladder_offset 0 (human-sized, ~1.4m)
#   3. The same walker at ladder_offset 2 (φ² smaller, ~0.53m — book-sized)
#   4. The same walker at ladder_offset 4 (φ⁴ smaller, ~0.20m — pen-sized)
#
# All four are the same RECIPE, same DNA, differing only in ladder_offset.
# Topology is identical; scale differs by φ at each rung. This is the
# Minecraft-world's opposite: recursive ratios, not uniform cubes.

extends SceneTree

const FoldChain = preload("res://commons/morphology/sdf/fold_chain.gd")
const ModulorWalker = preload("res://commons/morphology/sdf/modulor_walker.gd")
const SDFVoxelPreviewClass = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== MODULOR CAPTURE ===")
	var out_dir := "user://modulor"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	var preview = SDFVoxelPreviewClass.new()
	preview.resolution = Vector3i(50, 60, 50)
	preview.surface_threshold = 0.02
	preview.auto_rebuild_on_ready = false
	preview.size_by_depth = false
	demo.add_child(preview)

	# Helper to capture a given SDF at given filename
	var capture := func(sdf: Resource, name: String) -> void:
		preview.sdf = sdf
		preview.rebuild()
		await_frame()
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/%s.png" % name
			img.save_png(path)
			print("  Saved %s" % path)

	# 1. The arm alone — shows the four-link Modulor ladder clearly
	var arm: Resource = FoldChain.arm(Vector3(0, 1.0, 0), Vector3(1, -0.2, 0))
	arm.build()
	preview.sdf = arm
	preview.rebuild()
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img_arm := root.get_viewport().get_texture().get_image()
	if img_arm:
		img_arm.save_png(out_dir + "/arm_chain.png")
		print("  Saved arm_chain.png")

	# 2. Walker at three fold levels — same recipe, different ladder rung
	var dna_base: Dictionary = {
		"scale": 1.0,
		"segments": 4.0,
		"symmetry": 2.0,
	}
	var offsets: Array = [0, 2, 4]
	for offset in offsets:
		var dna: Dictionary = dna_base.duplicate()
		dna["ladder_offset"] = float(offset)
		var walker = ModulorWalker.new()
		walker.dna = dna
		walker.joint_k = 0.05
		walker.build()
		preview.sdf = walker
		preview.rebuild()
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var len_hint: float = walker.get_aabb().size.x
			var path: String = out_dir + "/walker_offset%d_len%0.2fm.png" % [offset, len_hint]
			img.save_png(path)
			print("  Saved walker_offset%d (body length ≈ %.2f m)" % [offset, len_hint])

	print("=== DONE — captures in %s ===" % out_dir)
	quit(0)


func await_frame() -> void:
	await process_frame
	await process_frame
	await process_frame
