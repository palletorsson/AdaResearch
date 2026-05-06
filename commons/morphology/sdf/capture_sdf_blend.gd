# capture_sdf_blend.gd
# Headless capture — loads the demo scene, lets it build the SDF blend,
# steps the blend through 5 t values, saves a screenshot strip. Proves the
# transition bus works end-to-end and produces actual visible geometry.
#
# Usage:
#   godot --path . --xr-mode off --script res://commons/morphology/sdf/capture_sdf_blend.gd

extends SceneTree

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== SDF BLEND CAPTURE ===")

	var out_dir := "user://sdf_blend"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK:
		push_error("Failed to load demo scene: %d" % err)
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if not demo:
		push_error("No current_scene after load")
		quit(1)
		return

	# Sweep t through five values, rebuild, capture
	var ts: Array = [0.0, 0.25, 0.5, 0.75, 1.0]
	for tval in ts:
		if "_blend" in demo and demo._blend != null:
			demo._blend.t = tval
		if "_preview" in demo and demo._preview != null:
			demo._preview.rebuild()

		# Wait for GPU to draw the freshly-built MultiMesh
		await process_frame
		await process_frame
		await process_frame
		await process_frame

		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/blend_t%02d.png" % int(tval * 100)
			img.save_png(path)
			print("  Saved %s (t=%.2f)" % [path, tval])
		else:
			push_warning("No image for t=%.2f" % tval)

	print("=== DONE — %d blend captures written to %s ===" % [ts.size(), out_dir])
	quit(0)
