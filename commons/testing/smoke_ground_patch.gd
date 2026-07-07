extends SceneTree

## Smoke test — render the living_ground shader on a small plane in
## headless mode. If this produces a recognisable warm-earth ground
## with the kingdom's tint at the centre, the shader works fine and
## NatureRenderer's "black rectangle in VR" comment points at a VR
## lighting / scale issue rather than the shader itself.

const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

const OUT_PATH := "user://ground_patch_smoke.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[gp_smoke] start")

	var root_3d := Node3D.new()
	get_root().add_child(root_3d)

	# Off-white BG, same as the gallery labs.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	env.ambient_light_color = Color(0.95, 0.95, 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	root_3d.add_child(sun)

	# Five patches arranged in a row, one per kingdom.
	var kingdoms := ["tree", "creature", "flower", "fungus", "alien"]
	for i in kingdoms.size():
		var anchor := Node3D.new()
		anchor.position = Vector3(float(i) * 2.5 - 5.0, 0.0, 0.0)
		root_3d.add_child(anchor)
		GroundPatchClass.attach(anchor, kingdoms[i], Vector2(2.0, 2.0))

	# Camera looking down + slightly forward.
	var camera := Camera3D.new()
	camera.fov = 50.0
	root_3d.add_child(camera)
	camera.global_position = Vector3(0.0, 6.0, 5.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true

	await create_timer(0.4).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[gp_smoke] image null"); quit(1); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK:
		push_error("[gp_smoke] save_png failed"); quit(1); return

	print("[gp_smoke] DONE: %s" % ProjectSettings.globalize_path(OUT_PATH))
	quit(0)
