# capture_operators.gd
# Demonstrates the operator library by layering each op on top of a
# kingdom body. Each capture is a side-by-side proof that operators
# compose with recipes without breaking geometry.
#
# Captures:
#   1. walker_plain.png        — bare walker
#   2. walker_noise.png        — walker + PatternOp("noise") skin
#   3. walker_scales.png       — walker + PatternOp("scales") skin
#   4. fungus_plain.png        — bare fungus
#   5. fungus_stripes.png      — fungus + PatternOp("stripes") gills pattern
#   6. flower_folded.png       — flower + FoldOp on petals (curled)
#   7. tree_tapered.png        — tree + TaperOp on trunk

extends SceneTree

const TreeBodyClass = preload("res://commons/morphology/sdf/tree_body.gd")
const WalkerBodyClass = preload("res://commons/morphology/sdf/walker_body.gd")
const FlowerBodyClass = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBodyClass = preload("res://commons/morphology/sdf/fungus_body.gd")
const TaperOpClass = preload("res://commons/morphology/sdf/taper_op.gd")
const PatternOpClass = preload("res://commons/morphology/sdf/pattern_op.gd")
const FoldOpClass = preload("res://commons/morphology/sdf/fold_op.gd")
const SDFVoxelPreviewClass = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== OPERATOR CAPTURE ===")
	var out_dir := "user://operators"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	var dna: Dictionary = {
		"scale": 1.1,
		"segments": 4.0,
		"symmetry": 6.0,
		"pattern_scale": 1.0,
		"pattern_density": 0.6,
	}

	var preview = SDFVoxelPreviewClass.new()
	preview.resolution = Vector3i(48, 56, 48)
	preview.surface_threshold = 0.05
	preview.auto_rebuild_on_ready = false
	preview.size_by_depth = false
	demo.add_child(preview)

	# Build each subject SDF and snap it
	var subjects: Array = []

	# Walker plain
	var walker_plain = WalkerBodyClass.new(); walker_plain.dna = dna; walker_plain.build()
	subjects.append({name="walker_plain", sdf=walker_plain})

	# Walker + noise skin — rocky/organic bumps
	var walker_n = WalkerBodyClass.new(); walker_n.dna = dna; walker_n.build()
	subjects.append({
		name="walker_noise",
		sdf=PatternOpClass.make(walker_n, "noise", 0.8, 4.0, 0.06)
	})

	# Walker + scales pattern — reptilian
	var walker_s = WalkerBodyClass.new(); walker_s.dna = dna; walker_s.build()
	subjects.append({
		name="walker_scales",
		sdf=PatternOpClass.make(walker_s, "scales", 0.9, 3.0, 0.05)
	})

	# Fungus plain
	var fungus_plain = FungusBodyClass.new(); fungus_plain.dna = dna; fungus_plain.build()
	subjects.append({name="fungus_plain", sdf=fungus_plain})

	# Fungus + stripes pattern — gill-ridge effect on cap
	var fungus_s = FungusBodyClass.new(); fungus_s.dna = dna; fungus_s.build()
	subjects.append({
		name="fungus_stripes",
		sdf=PatternOpClass.make(fungus_s, "stripes", 0.8, 6.0, 0.04)
	})

	# Flower + FoldOp — curls the top half of the flower (petals wrap inward)
	var flower_f = FlowerBodyClass.new(); flower_f.dna = dna; flower_f.build()
	# Fold the upper half of the flower around a horizontal hinge at stem top
	subjects.append({
		name="flower_folded",
		sdf=FoldOpClass.make(flower_f, Vector3(0, 1.5, 0), Vector3.FORWARD, Vector3.UP, 0.8)
	})

	# Tree + TaperOp — stronger taper on trunk
	var tree_t = TreeBodyClass.new(); tree_t.dna = dna; tree_t.build()
	subjects.append({
		name="tree_tapered",
		sdf=TaperOpClass.make(tree_t, Vector3.UP, 0.0, 1.8, 0.35)
	})

	for s in subjects:
		preview.sdf = s.sdf
		preview.rebuild()
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/%s.png" % s.name
			img.save_png(path)
			print("  Saved %s" % path)

	print("=== DONE — operator captures in %s ===" % out_dir)
	quit(0)
