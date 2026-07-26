@tool
extends SceneTree
# Captures the timed-lease cycle of the catalyst pedestal as a frame
# sequence: crystal taken -> cage fades -> absence -> cage re-materializes
# with a fresh crystal. A python step assembles the PNGs into a GIF.
#
# The pickup is simulated (headless has no XR hands): we fire the
# pedestal's _on_crystal_taken and free the crystal, exactly what a real
# grab-and-absorb does to the pedestal. The return runs on the pedestal's
# own countdown — the thing this capture demonstrates. The manager's
# lease clock is deliberately NOT started so the capture never touches
# the player's capability save.
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/capture_lease_cycle.gd

const PEDESTAL_SCENE := preload("res://commons/hazards/becoming_catalyst/catalyst_pedestal.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

const OUT_DIR := "multi_shots/lease_cycle"
const FRAME_SIZE := Vector2i(640, 360)
const LEASE_S := 4.0        # short lease so the gif stays tight
const FRAMES := 130         # x4 engine frames each ≈ 8.5s of sim
const TAKE_AT := 12         # frame index where the "pickup" happens


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive(OUT_DIR)

	var root := Node3D.new()
	root.name = "LeaseCycle"
	VRCaptureRig.build_environment(root)

	var ped: Node3D = PEDESTAL_SCENE.instantiate() as Node3D
	root.add_child(ped)
	ped.call("apply_grid_config", {"lease_s": LEASE_S, "sequence": "primitives"})

	var cam := VRCaptureRig.build_camera(Vector3(1.9, 1.35, 1.9), Vector3(0, 0.5, 0), 42.0)
	root.add_child(cam)

	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	for _i in range(30):
		await process_frame
	# Fetch the viewport AFTER the warmup — it resolves null before the
	# scene has run a frame (the coroutine would die on the null call and
	# quit() would never fire).
	var vp: Viewport = root.get_viewport()
	if vp != null:
		vp.size = FRAME_SIZE

	for f in range(FRAMES):
		for _j in range(4):
			await process_frame
		if f == TAKE_AT:
			# Simulated grab-and-absorb: the crystal leaves with the hand.
			var crystal: Node = ped.get("_crystal")
			ped.call("_on_crystal_taken", crystal)
			if is_instance_valid(crystal):
				crystal.queue_free()
			print("[lease_cycle] crystal taken at frame %d" % f)
		if vp == null:
			vp = root.get_viewport()
			if vp != null:
				vp.size = FRAME_SIZE
		if vp == null:
			continue
		var img: Image = vp.get_texture().get_image()
		if img != null:
			img.save_png("user://%s/frame_%03d.png" % [OUT_DIR, f])

	print("[lease_cycle] %d frames done" % FRAMES)
	quit()
