# capture_primitives.gd
# Renders the new primitive library side-by-side. Each primitive shown
# both as its voxel SDF (from the bus) AND as its actual mesh (from
# build_mesh_parts) — two captures per primitive so we can verify both
# paths agree.

extends SceneTree

const FormSDF = preload("res://commons/morphology/sdf/form_sdf.gd")
const BoxSDF = preload("res://commons/morphology/sdf/box_sdf.gd")
const RoundedBoxSDF = preload("res://commons/morphology/sdf/rounded_box_sdf.gd")
const ConeSDF = preload("res://commons/morphology/sdf/cone_sdf.gd")
const CapsuleSDF = preload("res://commons/morphology/sdf/capsule_sdf.gd")
const EllipsoidSDF = preload("res://commons/morphology/sdf/ellipsoid_sdf.gd")
const SDFVoxelPreview = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== PRIMITIVES CAPTURE ===")
	var out_dir := "user://primitives"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	# Bring the camera closer so primitives fill the frame. Default demo
	# camera is at (10, 8, 10) looking at origin — fine for large biomes
	# but primitives get lost in dark void.
	var cam: Camera3D = null
	for child in demo.get_children():
		if child is Camera3D:
			cam = child
			break
	if cam != null:
		cam.position = Vector3(3.5, 2.8, 3.5)
		cam.look_at(Vector3.ZERO, Vector3.UP)
		cam.fov = 40.0

	# Each entry: { name, sdf }
	var subjects: Array = [
		# Old primitives (for comparison)
		{"name": "01_capsule", "sdf": CapsuleSDF.make(Vector3(0, -0.6, 0), Vector3(0, 0.6, 0), 0.35)},
		{"name": "02_ellipsoid", "sdf": EllipsoidSDF.make(Vector3.ZERO, Vector3(0.6, 0.9, 0.6))},
		# New primitives
		{"name": "03_box", "sdf": BoxSDF.make(Vector3.ZERO, Vector3(0.6, 0.6, 0.6))},
		{"name": "04_rounded_box", "sdf": RoundedBoxSDF.make(Vector3.ZERO, Vector3(0.7, 0.5, 0.7), 0.18)},
		{"name": "05_cone", "sdf": ConeSDF.make(Vector3(0, 1.0, 0), Vector3(0, -0.3, 0), 0.55)},
		# Rotated box to show basis works
		{"name": "06_rotated_box", "sdf": BoxSDF.make(Vector3.ZERO, Vector3(0.5, 0.5, 0.5),
			Basis(Vector3.UP, deg_to_rad(30)) * Basis(Vector3.RIGHT, deg_to_rad(20)))},
	]

	# SDF voxel preview path
	var preview = SDFVoxelPreview.new()
	preview.resolution = Vector3i(40, 40, 40)
	preview.surface_threshold = 0.04
	preview.auto_rebuild_on_ready = false
	preview.size_by_depth = false
	demo.add_child(preview)

	for s in subjects:
		preview.sdf = s.sdf
		preview.rebuild()
		await process_frame
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(out_dir + "/%s_sdf.png" % s.name)
			print("  Saved %s_sdf.png" % s.name)

	preview.queue_free()
	await process_frame

	# Mesh path — build a MeshInstance3D directly from build_mesh_parts()
	for s in subjects:
		var parts: Array = (s.sdf as Resource).build_mesh_parts()
		var container := Node3D.new()
		demo.add_child(container)
		for p in parts:
			var mi := MeshInstance3D.new()
			mi.mesh = p["mesh"]
			mi.transform = p["transform"]
			# Simple material so it's visible
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.8, 0.7)
			mat.roughness = 0.6
			mi.material_override = mat
			container.add_child(mi)
		await process_frame
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(out_dir + "/%s_mesh.png" % s.name)
			print("  Saved %s_mesh.png" % s.name)
		container.queue_free()
		await process_frame

	print("=== DONE — captures in %s ===" % out_dir)
	quit(0)
