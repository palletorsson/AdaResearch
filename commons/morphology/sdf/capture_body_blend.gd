# capture_body_blend.gd
# Headless capture — spawns a FlowerBody, a FungusBody, blends them by the
# weighted operator through 5 t values, saves a transition strip. Proves
# DNA recipes compose into organisms and organisms transition smoothly.
#
# Usage:
#   godot --path . --xr-mode off --script res://commons/morphology/sdf/capture_body_blend.gd

extends SceneTree

const FlowerBodyClass = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBodyClass = preload("res://commons/morphology/sdf/fungus_body.gd")
const BlendedSDFClass = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFVoxelPreviewClass = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== BODY BLEND CAPTURE ===")

	var out_dir := "user://body_blend"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# Reuse the demo scene's camera/light/environment rig, replace the
	# preview SDF with our body blend.
	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK:
		push_error("Failed to load demo scene: %d" % err)
		quit(1)
		return
	await process_frame
	await process_frame

	var demo: Node = current_scene

	# Build the flower and fungus bodies from shared DNA
	var dna: Dictionary = {
		"scale": 1.2,
		"segments": 4.0,        # flower: leaf pairs; fungus: gill count
		"symmetry": 6.0,        # flower: petals; fungus: wart count
		"pattern_scale": 1.1,   # flower: petal length
		"pattern_density": 0.6, # fungus: warts on
	}

	var flower = FlowerBodyClass.new()
	flower.dna = dna
	flower.joint_k = 0.08
	flower.build()

	var fungus = FungusBodyClass.new()
	fungus.dna = dna
	fungus.joint_k = 0.1
	fungus.build()

	# Replace the demo's preview with a body-blend preview
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
	var blend = BlendedSDFClass.new()
	blend.a = flower
	blend.b = fungus
	blend.t = 0.0
	blend.mode = "weighted"
	blend.smoothness = 0.2
	blend.weighted_inflation = 0.25

	var preview = SDFVoxelPreviewClass.new()
	preview.sdf = blend
	preview.resolution = Vector3i(48, 54, 48)
	preview.surface_threshold = 0.05
	preview.auto_rebuild_on_ready = false
	preview.size_by_depth = false
	demo.add_child(preview)

	# Sweep t, rebuild, capture
	var ts: Array = [0.0, 0.25, 0.5, 0.75, 1.0]
	for tval in ts:
		blend.t = tval
		preview.rebuild()
		await process_frame
		await process_frame
		await process_frame
		await process_frame

		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/body_t%02d.png" % int(tval * 100)
			img.save_png(path)
			print("  Saved %s (t=%.2f)" % [path, tval])

	print("=== DONE — %d body captures written to %s ===" % [ts.size(), out_dir])
	quit(0)
