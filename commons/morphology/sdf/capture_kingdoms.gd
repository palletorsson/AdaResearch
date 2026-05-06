# capture_kingdoms.gd
# Headless capture — renders each of the four body recipes (tree, walker,
# flower, fungus) from the SAME DNA dictionary, then captures a 4-stop
# transition walking body_type from 0 → 3 (tree → walker → flower → fungus).
# Proves every kingdom is a function of DNA and all transitions compose.
#
# Usage:
#   godot --path . --xr-mode off --script res://commons/morphology/sdf/capture_kingdoms.gd

extends SceneTree

const TreeBodyClass = preload("res://commons/morphology/sdf/tree_body.gd")
const WalkerBodyClass = preload("res://commons/morphology/sdf/walker_body.gd")
const FlowerBodyClass = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBodyClass = preload("res://commons/morphology/sdf/fungus_body.gd")
const BlendedSDFClass = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFVoxelPreviewClass = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== KINGDOM CAPTURE ===")
	var out_dir := "user://kingdoms"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	# Shared DNA across all four kingdoms. Same numbers, different expressions.
	var dna: Dictionary = {
		"scale": 1.1,
		"segments": 4.0,
		"symmetry": 6.0,
		"pattern_scale": 1.0,
		"pattern_density": 0.6,
	}

	# Build the four bodies from this shared DNA
	var bodies: Array = []
	var tree = TreeBodyClass.new(); tree.dna = dna; tree.joint_k = 0.12; tree.build()
	var walker = WalkerBodyClass.new(); walker.dna = dna; walker.joint_k = 0.1; walker.build()
	var flower = FlowerBodyClass.new(); flower.dna = dna; flower.joint_k = 0.08; flower.build()
	var fungus = FungusBodyClass.new(); fungus.dna = dna; fungus.joint_k = 0.1; fungus.build()
	bodies = [
		{name="tree",   body=tree},
		{name="walker", body=walker},
		{name="flower", body=flower},
		{name="fungus", body=fungus},
	]

	# A fresh preview we swap contents on per capture
	var preview = SDFVoxelPreviewClass.new()
	preview.sdf = null
	preview.resolution = Vector3i(48, 56, 48)
	preview.surface_threshold = 0.05
	preview.auto_rebuild_on_ready = false
	preview.size_by_depth = false
	demo.add_child(preview)

	# 1) Each kingdom alone
	for entry in bodies:
		preview.sdf = entry.body
		preview.rebuild()
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/kingdom_%s.png" % entry.name
			img.save_png(path)
			print("  Saved %s" % path)

	# 2) Cross-kingdom transitions — chain blends
	var pairs: Array = [
		{from="tree",   to="walker", a=tree,   b=walker},
		{from="walker", to="flower", a=walker, b=flower},
		{from="flower", to="fungus", a=flower, b=fungus},
	]
	for pair in pairs:
		for tval in [0.25, 0.5, 0.75]:
			var blend = BlendedSDFClass.new()
			blend.a = pair.a
			blend.b = pair.b
			blend.t = tval
			blend.mode = "weighted"
			blend.smoothness = 0.2
			blend.weighted_inflation = 0.25
			preview.sdf = blend
			preview.rebuild()
			await process_frame
			await process_frame
			await process_frame
			await process_frame
			var img2 := root.get_viewport().get_texture().get_image()
			if img2:
				var path2: String = out_dir + "/blend_%s_to_%s_t%02d.png" % [pair.from, pair.to, int(tval * 100)]
				img2.save_png(path2)
				print("  Saved %s" % path2)

	print("=== DONE — captures written to %s ===" % out_dir)
	quit(0)
