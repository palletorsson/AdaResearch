@tool
extends SceneTree
# Captures the evolving pink critter's stages for review.
#
# Output (user://multi_shots/critter_stages/):
#   0_lineup.png    — all five stages in a row, front 3/4
#   1_cube.png      — legacy grey cube (pre-color world)
#   2_mote.png      — hovering legless pink mote (pops on contact)
#   3_serpent.png   — wavefunctions: snake-weave in flight (captured moving)
#   4_octapod.png   — randomness: landed, 8 legs, spider silhouette
#   5_grand.png     — fractals+: the grand critter
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/capture_critter_stages.gd

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

const OUT_DIR := "multi_shots/critter_stages"

const STAGES := [
	{"file": "1_cube",    "order": 2.0,  "label": "cube"},
	{"file": "2_mote",    "order": 4.5,  "label": "mote"},
	{"file": "3_serpent", "order": 6.0,  "label": "serpent"},
	{"file": "4_octapod", "order": 7.0,  "label": "octapod"},
	{"file": "5_grand",   "order": 10.0, "label": "grand"},
]


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive(OUT_DIR)

	for stage in STAGES:
		await _capture_solo(stage)
	await _capture_lineup()
	print("[critter_stages] complete")
	quit()


func _spawn_critter(parent: Node3D, order: float, pos: Vector3, moving: bool) -> Node3D:
	var foe: Node3D = FOE_SCENE.instantiate() as Node3D
	var cfg: Dictionary = {
		"critter_stage": order,
		"initial_state": "foe",
		"speed": 0.6 if moving else 0.0,
		"chase_speed": 0.6 if moving else 0.0,
		"detection_radius": 10.0 if moving else 0.0,
	}
	if foe.has_method("apply_grid_config"):
		foe.call("apply_grid_config", cfg)
	if not moving:
		# Kill the default patrol loop so the pose (and facing) holds still.
		foe.set("patrol_width", 0.01)
		foe.set("patrol_depth", 0.01)
	foe.position = pos
	parent.add_child(foe)
	return foe


func _capture_solo(stage: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "CritterCapture_%s" % String(stage["file"])
	VRCaptureRig.build_environment(root)

	var moving: bool = String(stage["label"]) == "serpent"
	var foe := _spawn_critter(root, float(stage["order"]), Vector3(0, 0.35, 0), moving)

	if moving:
		# A target to swim toward so the snake-weave actually shows.
		var bait := Node3D.new()
		bait.name = "Player"
		bait.add_to_group("player")
		bait.position = Vector3(0, 0.35, -6.0)
		root.add_child(bait)

	# Frame the body center: flying stages hover ~0.55 above the body node.
	var is_flying: bool = float(stage["order"]) > 4.0 and float(stage["order"]) < 7.0
	var focus_y: float = 0.95 if is_flying else 0.55
	var big: bool = float(stage["order"]) >= 10.0
	var cam_dist: float = 1.7 if not big else 2.6
	var cam_pos := Vector3(cam_dist * 0.62, focus_y + 0.35, cam_dist * 0.82)
	if moving:
		# Profile view — the serpent swims toward -Z; catch the weave side-on.
		cam_pos = Vector3(2.3, focus_y + 0.3, -1.4)
	var cam := VRCaptureRig.build_camera(cam_pos, Vector3(0, focus_y * 0.9, -1.4 if moving else 0.0), 45.0)
	root.add_child(cam)

	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	# Settle: hover bob + gait + (for serpent) enough motion for the weave.
	for _i in range(100):
		await process_frame

	if not moving:
		# Face the camera so the eyes and blush read.
		foe.rotation.y = atan2(cam_pos.x, cam_pos.z)
		for _i in range(3):
			await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1024, 1024)
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[critter_stages] FAIL viewport null (%s)" % String(stage["file"]))
		return
	var out_path: String = "user://%s/%s.png" % [OUT_DIR, String(stage["file"])]
	img.save_png(out_path)
	print("[critter_stages] saved %s" % String(stage["file"]))


func _capture_lineup() -> void:
	var root := Node3D.new()
	root.name = "CritterCapture_lineup"
	VRCaptureRig.build_environment(root)

	var cam_pos := Vector3(0, 1.6, 3.6)
	var x: float = -2.0
	var crew: Array = []
	for stage in STAGES:
		crew.append(_spawn_critter(root, float(stage["order"]), Vector3(x, 0.35, 0), false))
		x += 1.0

	var cam := VRCaptureRig.build_camera(cam_pos, Vector3(0, 0.7, 0), 55.0)
	root.add_child(cam)

	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	for _i in range(100):
		await process_frame

	for c in crew:
		if c is Node3D and is_instance_valid(c):
			var d: Vector3 = cam_pos - (c as Node3D).position
			(c as Node3D).rotation.y = atan2(d.x, d.z)
	for _i in range(3):
		await process_frame

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(1600, 900)
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[critter_stages] FAIL viewport null (lineup)")
		return
	img.save_png("user://%s/0_lineup.png" % OUT_DIR)
	print("[critter_stages] saved lineup")
