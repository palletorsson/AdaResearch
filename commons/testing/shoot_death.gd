extends SceneTree
## THE DEATH, PHOTOGRAPHED (2026-08-25). The loop probe proves the numbers;
## this proves the picture — one frame at peak splatter, one in the end scene.
## Needs a window: a headless viewport has no texture to save.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_death.gd -- --kind=fire

func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _shoot(path: String) -> void:
	await process_frame
	await process_frame
	var img: Image = get_root().get_texture().get_image()
	img.save_png(path.replace("res://", ""))


func _run() -> void:
	var kind := _arg("kind", "fire")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_ds_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_ds_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_ds_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_ds_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(2.0).timeout
	# stand in the hall, looking down the walk, so the splatter has a room
	var player: Node3D = inst.get("_player") as Node3D
	if player != null:
		player.position = Vector3(5.5, player.position.y, 6.0)
	await create_timer(0.8).timeout
	inst.call("on_lethal_touch", kind, Vector3.ZERO)
	await create_timer(0.55).timeout          # splatter full, the black not yet
	# MEASURE the overlay before believing the picture: a Control that draws
	# with size() and reports (0,0) paints nothing and errors about nothing
	var sp: Variant = inst.get("_death_splat")
	if sp != null:
		var c := sp as Control
		print("[death-shot] splatter size=%s pos=%s visible=%s progress=%s blobs=%d modulate=%s" % [
			str(c.size), str(c.position), str(c.visible), str(c.get("progress")),
			(c.get("_blobs") as Array).size(), str(c.modulate)])
		print("[death-shot] viewport=%s  layer visible=%s" % [str(get_root().size),
			str((inst.get("_death_layer") as CanvasLayer).visible)])
	await _shoot("res://ada_run/death_1_splatter.png")
	await create_timer(1.05).timeout          # the end scene
	await _shoot("res://ada_run/death_2_endscene.png")
	print("[death-shot] %s -> ada_run/death_1_splatter.png, ada_run/death_2_endscene.png" % kind)
	quit(0)
