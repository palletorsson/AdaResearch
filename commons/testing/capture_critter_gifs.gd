@tool
extends SceneTree
# Captures frame sequences of the critter's two motion behaviors:
#   serpent/frame_###.png — the wavefunctions-stage air-snake weaving in flight
#   pop/frame_###.png     — a mote landing its kamikaze hit and bursting
# A python step assembles the PNGs into GIFs (tools side).
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/capture_critter_gifs.gd

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const VRCaptureRig := preload("res://commons/testing/vr_capture_rig.gd")

const OUT_DIR := "multi_shots/critter_gifs"
const FRAME_SIZE := Vector2i(640, 360)


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive(OUT_DIR + "/serpent")
		dir.make_dir_recursive(OUT_DIR + "/pop")
		dir.make_dir_recursive(OUT_DIR + "/walk")
		dir.make_dir_recursive(OUT_DIR + "/hitpop")

	await _capture_serpent()
	await _capture_pop()
	await _capture_walk()
	await _capture_hitpop()
	print("[critter_gifs] complete")
	quit()


## The octapod walking — plant-and-step gait in profile.
func _capture_walk() -> void:
	var root := Node3D.new()
	root.name = "WalkGif"
	VRCaptureRig.build_environment(root)

	var foe: Node3D = FOE_SCENE.instantiate() as Node3D
	foe.call("apply_grid_config", {
		"critter_stage": 7.0, "initial_state": "foe",
		"speed": 1.1, "chase_speed": 1.1, "detection_radius": 14.0,
	})
	foe.position = Vector3(0, 0.35, 1.8)
	root.add_child(foe)

	var bait := Node3D.new()
	bait.name = "Player"
	bait.add_to_group("player")
	bait.position = Vector3(0, 0.35, -9.0)
	root.add_child(bait)

	# Low profile camera on the flight lane so the legs read against the sky.
	var cam := VRCaptureRig.build_camera(Vector3(2.6, 0.85, -0.5), Vector3(0, 0.55, -0.5), 45.0)
	root.add_child(cam)

	_swap_scene(root)
	var vp: Viewport = root.get_viewport()
	if vp != null:
		vp.size = FRAME_SIZE
	for _i in range(30):
		await process_frame

	for f in range(90):
		await process_frame
		await process_frame
		_grab(root, "walk", f)
	print("[critter_gifs] walk frames done")


## The molt-pop: two catalyst-projectile hits — each pops the balloon,
## the critter reforms one personality step warmer.
func _capture_hitpop() -> void:
	var root := Node3D.new()
	root.name = "HitPopGif"
	VRCaptureRig.build_environment(root)

	var foe: Node3D = FOE_SCENE.instantiate() as Node3D
	foe.call("apply_grid_config", {
		"critter_stage": 4.5, "initial_state": "foe",
		"speed": 0.0, "chase_speed": 0.0, "detection_radius": 0.0,
	})
	foe.set("patrol_width", 0.01)
	foe.set("patrol_depth", 0.01)
	foe.position = Vector3(0, 0.35, 0)
	root.add_child(foe)

	# A player stand-in off to the side gives the eyes something to track.
	var watcher := Node3D.new()
	watcher.name = "Player"
	watcher.add_to_group("player")
	watcher.position = Vector3(1.4, 0.4, 1.6)
	root.add_child(watcher)

	var cam := VRCaptureRig.build_camera(Vector3(1.05, 1.35, 1.4), Vector3(0, 0.85, 0), 45.0)
	root.add_child(cam)

	_swap_scene(root)
	var vp: Viewport = root.get_viewport()
	if vp != null:
		vp.size = FRAME_SIZE
	for _i in range(20):
		await process_frame

	# ~3s: hit at frames 15 and 55 — molt pop, retint, reform.
	for f in range(90):
		await process_frame
		await process_frame
		if f == 15 or f == 55:
			foe.call("hit_by_catalyst_mode", Color(0.9, 0.95, 1.0), "primitives")
		_grab(root, "hitpop", f)
	print("[critter_gifs] hitpop frames done")


func _swap_scene(root: Node3D) -> void:
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()


func _grab(root: Node3D, path: String, index: int) -> void:
	var vp: Viewport = root.get_viewport()
	if vp == null:
		return
	var img: Image = vp.get_texture().get_image()
	if img != null:
		img.save_png("user://%s/%s/frame_%03d.png" % [OUT_DIR, path, index])


func _capture_serpent() -> void:
	var root := Node3D.new()
	root.name = "SerpentGif"
	VRCaptureRig.build_environment(root)

	var foe: Node3D = FOE_SCENE.instantiate() as Node3D
	foe.call("apply_grid_config", {
		"critter_stage": 6.0, "initial_state": "foe",
		"speed": 0.7, "chase_speed": 0.7, "detection_radius": 12.0,
	})
	foe.position = Vector3(0, 0.35, 1.6)
	root.add_child(foe)

	var bait := Node3D.new()
	bait.name = "Player"
	bait.add_to_group("player")
	bait.position = Vector3(0, 0.35, -8.0)
	root.add_child(bait)

	# Profile camera watching the flight lane from the side.
	var cam := VRCaptureRig.build_camera(Vector3(2.6, 1.25, -0.4), Vector3(0, 0.95, -0.4), 45.0)
	root.add_child(cam)

	_swap_scene(root)
	var vp: Viewport = root.get_viewport()
	if vp != null:
		vp.size = FRAME_SIZE
	# Let it start flying before the tape rolls.
	for _i in range(30):
		await process_frame

	# ~3s of flight at 30fps: 90 frames, one grab every 2 sim frames.
	for f in range(90):
		await process_frame
		await process_frame
		_grab(root, "serpent", f)
	print("[critter_gifs] serpent frames done")


func _capture_pop() -> void:
	var root := Node3D.new()
	root.name = "PopGif"
	VRCaptureRig.build_environment(root)
	VRCaptureRig.build_player_figure(root)

	var foe: Node3D = FOE_SCENE.instantiate() as Node3D
	foe.call("apply_grid_config", {
		"critter_stage": 4.5, "initial_state": "foe",
		"speed": 0.9, "chase_speed": 0.9, "detection_radius": 12.0,
	})
	foe.position = Vector3(0, 0.35, -2.0)
	root.add_child(foe)

	# The player figure stands at origin; a damage sink in group "player"
	# makes the mote home in on it.
	var sink := Node3D.new()
	sink.name = "Player"
	sink.add_to_group("player")
	sink.position = Vector3(0, 0.35, 0)
	root.add_child(sink)

	var cam := VRCaptureRig.build_camera(Vector3(2.2, 1.35, -1.9), Vector3(0, 0.9, -0.9), 45.0)
	root.add_child(cam)

	_swap_scene(root)
	var vp: Viewport = root.get_viewport()
	if vp != null:
		vp.size = FRAME_SIZE
	for _i in range(20):
		await process_frame

	# ~2.7s at 30fps: approach until close, pop on proximity, burst tail.
	for f in range(80):
		await process_frame
		await process_frame
		if not bool(foe.get("_blown_up")):
			var close: bool = foe.global_position.distance_to(sink.global_position) < 0.9
			if close or f == 60:
				foe.call("_try_damage_target", sink)  # the kamikaze hit → _blow_up
		_grab(root, "pop", f)
	print("[critter_gifs] pop frames done")
