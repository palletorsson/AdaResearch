@tool
extends SceneTree
# Attempt to render the REAL capacity_bracelet.tscn — not the rig's
# torus stand-in. If this works, future captures use the production
# bracelet visual.
#
# Output: user://catalyst_runs/real_bracelet/test.png

const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")
const BRACELET_SCENE := preload("res://commons/hazards/becoming_catalyst/capacity_bracelet/capacity_bracelet.tscn")

const UNLOCKED_MODES := [
	"voxel_editor",
	"primitives",
	"transformation",
	"chromatic",
	"forces",
]

const ALL_MODES := [
	"voxel_editor", "wedge_placer",
	"primitives", "transformation", "chromatic", "forces",
	"waveform", "chaos", "fractal", "cellular", "branching", "swarm",
]


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/real_bracelet")

	await _capture("test")
	print("[real_bracelet] complete")
	quit()


func _capture(id: String) -> void:
	var root := Node3D.new()
	root.name = "RealBracelet_%s" % id

	VRCaptureRig.build_environment(root)

	# Left hand wearing the bracelet.
	var left_pos := Vector3(-0.10, 1.32, -0.40)
	var left_basis := VRCaptureRig.hand_basis(Vector3(0.4, 0, -1), 0.0, true)
	VRCaptureRig.pose_hand(root, VRCaptureRig.LEFT_HAND_GLTF, left_pos,
		left_basis, "Default pose", true)

	# Bracelet — instantiate the real scene.
	var bracelet: Node3D = BRACELET_SCENE.instantiate()
	var wrist_pos := left_pos + Vector3(0.03, -0.01, 0.05)
	bracelet.position = wrist_pos
	# Orient bracelet root so its +Y aligns with forearm direction.
	var forearm_dir := Vector3(0.5, -0.1, 0.85).normalized()
	var ref_v := Vector3.UP if abs(forearm_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := forearm_dir.cross(ref_v).normalized()
	var rz := rx.cross(forearm_dir).normalized()
	bracelet.transform.basis = Basis(rx, forearm_dir, rz)
	root.add_child(bracelet)

	# FPV camera
	var cam := VRCaptureRig.first_person_camera(1.62, Vector3(-0.05, 1.10, -0.65), 80.0)
	root.add_child(cam)

	# Add to tree
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	await process_frame
	await process_frame

	# Activate the bracelet with mode list + null controller.
	if bracelet.has_method("activate"):
		bracelet.call("activate", UNLOCKED_MODES, null, false, ALL_MODES)
		bracelet.visible = true
		bracelet.scale = Vector3.ONE

	# Hide the mode label (Label3D) — it renders oversized in capture
	# without the proper Viewport2Din3D the in-game version uses.
	_hide_label3d(bracelet)

	for _i in range(60):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[real_bracelet] FAIL %s" % id)
		return
	img.save_png("user://catalyst_runs/real_bracelet/%s.png" % id)
	print("[real_bracelet] saved %s" % id)


func _hide_label3d(node: Node) -> void:
	if node is Label3D:
		(node as Label3D).visible = false
	# Also hide hinge/handle visuals which can render as oversized boxes
	# in capture without their normal XR controller-driven proportions.
	var n := node.name as String
	if "Label" in n or "Hinge" in n or "Handle" in n:
		if node is Node3D:
			(node as Node3D).visible = false
		else:
			node.queue_free()
	for c in node.get_children():
		_hide_label3d(c)
