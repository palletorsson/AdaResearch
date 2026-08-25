extends SceneTree
## CARRIED, OR MERELY STOOD ON (2026-08-25, Palle: "in the endless museum 3d we
## want to be able to be transported by transport cube like in VR"). The cube
## moves whatever _is_player() recognises; the museum's walker is named
## "Walker" and joined nothing, so on the desktop it has always been furniture.
## Stand the walker on the cube, wait for the cube to travel, and compare how
## far each of them moved.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_transport_ride.gd

const OUT := "res://ada_run/transport_ride.txt"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_tr_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_tr_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var rep := "THE RIDE\n"
	var player: Node3D = inst.get("_player") as Node3D
	rep += "  walker groups: %s\n" % str(player.get_groups())
	var seg: Node3D = null
	for s_v in inst.get("_segments"):
		var sd: Dictionary = s_v
		if String(sd.get("pearl", "")) == "trans introduction":
			seg = sd.get("node")
	var cube: Node3D = null
	for n in seg.find_children("Utility_tc_*", "Node3D", true, false):
		cube = n as Node3D
		break
	if cube == null:
		rep += "  FAIL no transport cube\n"
	else:
		# the cube's own reach, so the test knows what "carried" should look like
		var tgt: Variant = cube.get("target_position")
		var ini: Variant = cube.get("initial_position")
		rep += "  cube %s at %s\n" % [cube.name, str(cube.global_position)]
		rep += "  its run: %s -> %s\n" % [str(ini), str(tgt)]
		# stand on the lid: the cube's top, plus a hair
		var box := AABB()
		var first := true
		for vi_v in cube.find_children("*", "VisualInstance3D", true, false):
			var vi := vi_v as VisualInstance3D
			var ab: AABB = vi.global_transform * vi.get_aabb()
			box = ab if first else box.merge(ab)
			first = false
		var top: float = box.position.y + box.size.y
		player.position = Vector3(cube.global_position.x, top + 0.05, cube.global_position.z)
		rep += "  walker set down at %s (cube top %.2f)\n" % [str(player.position), top]
		# WHAT IS SOLID HERE, and what can see the walker
		rep += "  walker layer=%d mask=%d
" % [player.get("collision_layer"), player.get("collision_mask")]
		for b_v in cube.find_children("*", "CollisionObject3D", true, false):
			var b := b_v as CollisionObject3D
			var shp := ""
			for c_v in b.get_children():
				var csx := c_v as CollisionShape3D
				if csx != null and csx.shape != null:
					shp += " shape=%s at %s" % [csx.shape.get_class(), str(csx.global_position)]
			rep += "  body %-22s layer=%d mask=%d%s
" % [b.name, b.collision_layer, b.collision_mask, shp]
		var p0: Vector3 = player.position
		var c0: Vector3 = cube.global_position
		# long enough for a full cycle: the cube pauses 3 s at each end
		for i in range(28):
			await create_timer(0.5).timeout
			if i % 7 == 0:
				rep += "    %4.1fs  cube z %6.2f   walker %s  floor=%s
" % [float(i) * 0.5,
					cube.global_position.z, str(player.position.round()),
					str((player as CharacterBody3D).is_on_floor())]
		var pd: Vector3 = player.position - p0
		var cd: Vector3 = cube.global_position - c0
		rep += "  cube moved   %s (%.2f m)\n" % [str(cd.round()), cd.length()]
		rep += "  walker moved %s (%.2f m)\n" % [str(pd.round()), pd.length()]
		var carried: bool = cd.length() > 0.5 and absf(pd.z - cd.z) < 0.6 and absf(pd.x - cd.x) < 0.6
		rep += "  %s\n" % ("CARRIED" if carried else ("FAIL left behind" if cd.length() > 0.5
			else "INCONCLUSIVE — the cube never travelled"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
