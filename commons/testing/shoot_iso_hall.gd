extends SceneTree
## THE ISOMETRIC HALL SHOT (2026-08-24, Palle: "to understand plan structure
## a screen shot from the isometric view inside the museum could be very
## useful"). The proof camera composes toward artifacts and has stood inside
## a column twice; this one is told exactly where to stand: the doll house's
## own cut (walls at 2.4 m, high pieces hidden) seen from 45 degrees above
## the named hall, framed to its whole tile.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/shoot_iso_hall.gd \
##       -- --chapter=color --map=Array --out=res://ada_run/iso_Array.png [--top]
##
## --top swaps the 45-degree perch for straight down (the plan proper).

func _initialize() -> void:
	call_deferred("_run")


func _arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % name):
			return String(a).substr(name.length() + 3)
	return fallback


func _run() -> void:
	var chapter := _arg("chapter", "transformation")
	var map_name := _arg("map", "Trans_Introduction")
	var out := _arg("out", "res://ada_run/iso_hall.png")
	var top := OS.get_cmdline_user_args().has("--top")
	# --eye=<map row>: stand IN the hall at walking height and look down the
	# walk, instead of the doll perch. The proof camera composes toward
	# artifacts and has stood inside a column; this one is told where to be.
	var eye_row := float(_arg("eye", "-1"))

	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_iso_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_iso_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_iso_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", map_name)
	var ctl := FileAccess.open("res://ada_run/_trial_iso_control.json", FileAccess.WRITE)
	# dollhouse ON: the walls cut to 2.4 m is exactly what makes a plan legible
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "first_map": map_name,
		"dollhouse": 1, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(2.0).timeout

	# the hall's own extent, from the segment record the museum keeps
	var segs: Array = inst.get("_segments")
	var z0 := 0.0
	var z1 := 24.0
	var w := 20.0
	# the segment for THIS map, not merely the first one built — the first
	# framing shot a third of the wrong hall
	var want := map_name.replace("_", " ").to_lower()
	var chosen := false
	for s_v in segs:
		var s: Dictionary = s_v
		var sn: Node3D = s.get("node")
		if sn == null or not is_instance_valid(sn):
			continue
		if String(s.get("pearl", "")).to_lower() == want:
			z0 = float(s.get("z0", 0.0)); z1 = float(s.get("z1", 24.0))
			w = float(s.get("w", 20)); chosen = true
			break
	if not chosen and not segs.is_empty():
		var s0: Dictionary = segs[0]
		z0 = float(s0.get("z0", 0.0)); z1 = float(s0.get("z1", 24.0)); w = float(s0.get("w", 20))
		print("[iso] no segment named %s — framing the first hall instead" % want)
	var cx := w * 0.5
	var cz := (z0 + z1) * 0.5
	var span: float = maxf(z1 - z0, w)

	# THE DOLL CAMERA OWNS ITSELF: it re-aims every frame at the PLAYER with
	# _doll_zoom as the frame (endless_museum.gd:8815), so setting the camera
	# transform here is overwritten before the next draw — the first two
	# attempts framed a third of the wrong hall for exactly that reason. Move
	# the doll and set the zoom instead, and let the museum aim.
	var player: Node3D = inst.get("_player") as Node3D
	if player != null:
		player.position = Vector3(cx, player.position.y, cz)
	if eye_row >= 0.0:
		# leave the doll house entirely: a walker's eye, 1.65 m, two metres
		# back from the named row, looking along the walk
		inst.set("_dollhouse", false)
		var ecam: Camera3D = inst.get("_cam") as Camera3D
		if ecam != null:
			ecam.projection = Camera3D.PROJECTION_PERSPECTIVE
			ecam.fov = 70.0
			ecam.global_position = Vector3(cx, 1.65, z0 + 4.0 + eye_row - 3.0)
			ecam.look_at(Vector3(cx, 1.0, z0 + 4.0 + eye_row + 4.0), Vector3.UP)
			ecam.current = true
	inst.set("_doll_zoom", clampf(span * 0.62, 6.0, 60.0))
	inst.set("_doll_top", top)
	inst.set("_doll_cam_pos", Vector3.ZERO)      # let it re-seat, no lerp trail
	var cam: Camera3D = inst.get("_cam") as Camera3D
	if cam == null:
		print("no camera"); quit(1); return
	await create_timer(1.4).timeout      # the doll camera flies to the hall
	# THE FOG WASHES THE TOY WHITE from a 46 m perch. The museum kills it for
	# its own doll camera, but the env tier swap reinstalls an Environment,
	# so: stop the swap, then kill fog on every frame up to the capture.
	inst.set("_env_ab_s", 0.0)
	if cam.attributes is CameraAttributesPractical:
		(cam.attributes as CameraAttributesPractical).auto_exposure_enabled = false
	for _i in range(14):
		for we in get_root().find_children("*", "WorldEnvironment", true, false):
			var denv: Environment = (we as WorldEnvironment).environment
			if denv != null:
				denv.fog_enabled = false
				denv.volumetric_fog_enabled = false
		await process_frame
	await create_timer(0.4).timeout
	await process_frame

	var img: Image = get_root().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(out) if out.begins_with("user://") else out.replace("res://", ""))
	print("[iso] %s · %s -> %s (span %.0f, %s)" % [chapter, map_name, out, span,
		"plan" if top else "iso 45"])
	quit(0)
