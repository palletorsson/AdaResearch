extends SceneTree

## Render the real Point One lab to the ENCYCLOPEDIA public folder (never
## the Godot repo): the white sliding door + the podium palm scanner in its
## new IDLE ("PLACE HAND") and GRANTED ("ACCESS GRANTED", door open) states.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_lab_door.gd

const LAB_ROOM := "res://commons/artifacts/lab_room/lab_room.tscn"
const LAB_JSON := "res://commons/labs/point_one.lab.json"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner"


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _find_by_signal(node: Node, sig: String) -> Node:
	if node.has_signal(sig):
		return node
	for c in node.get_children():
		var f := _find_by_signal(c, sig)
		if f != null:
			return f
	return null


func _shoot(cam: Camera3D, eye: Vector3, look: Vector3, name: String) -> void:
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	await _frames(6)
	var img: Image = root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name]
	img.save_png(path)
	print("[door] saved %s" % path)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var world := Node3D.new()
	root.add_child(world)

	var lab: Node3D = load(LAB_ROOM).instantiate()
	lab.set_meta("config_mounted_lab_json", LAB_JSON)
	world.add_child(lab)
	await _frames(60)

	# Backdrop OUTSIDE the door (south wall is +Z) so an open doorway reveals
	# a bright contrasting field instead of grey-on-grey void. Without this,
	# an open door is nearly invisible in an isolated lab render.
	var backdrop := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(10.0, 6.0, 0.2)
	backdrop.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.05, 0.55, 0.85)
	bmat.emission_enabled = true
	bmat.emission = Color(0.10, 0.65, 1.0)
	bmat.emission_energy_multiplier = 0.8
	backdrop.material_override = bmat
	backdrop.position = Vector3(2.6, 2.0, 5.2)   # behind south wall, beyond the door
	world.add_child(backdrop)
	await _frames(4)

	var cam := Camera3D.new()
	cam.fov = 64.0
	root.add_child(cam)
	cam.make_current()

	# Head-on to the door so an open panel is unmistakable. The door sits on
	# the south wall (z≈+3.4) at x≈2.6; stand back inside the room on its axis
	# and look straight at it. Closed = grey panel fills the frame; open = the
	# panel has slid left, leaving a dark opening to the exterior.
	var eye := Vector3(2.6, 1.6, 0.2)
	var look := Vector3(2.6, 1.5, 3.5)

	# View 1 — IDLE: white door closed, scanner resting ("PLACE HAND").
	await _shoot(cam, eye, look, "lab_door_idle")

	# View 2 — GRANTED: force the scanner to grant (which opens the white
	# door via the wired palm_scanned signal) and shoot the same framing.
	var scanner: Node = _find_by_signal(lab, "palm_scanned")
	var door: Node = get_first_node_in_group("lab_door_sensors")
	var panel: Node3D = null
	if door != null:
		panel = door.get("left_panel")
	var wired: bool = false
	if scanner != null and door != null:
		wired = scanner.palm_scanned.is_connected(Callable(door, "_open_door"))
	print("[door] scanner=%s door=%s wired=%s panel_x_before=%s open_before=%s" % [
		scanner != null, door != null, wired,
		(panel.position.x if panel else "n/a"),
		(door.get("_open") if door else "n/a")])
	if scanner != null and scanner.has_method("_grant_access"):
		scanner.call("_grant_access")
	await _frames(45)   # let the door slide open + plate flash settle
	print("[door] AFTER grant: open=%s panel_x_after=%s (open_offset=%s)" % [
		(door.get("_open") if door else "n/a"),
		(panel.position.x if panel else "n/a"),
		(door.get("open_offset") if door else "n/a")])
	await _shoot(cam, eye, look, "lab_door_granted")

	# View 2b — 3/4 angle from the RIGHT (the panel slides LEFT/−X, away from
	# this camera), so the cleared opening + blue exterior are unmistakable and
	# the panel is seen tucked to the far side.
	await _shoot(cam, Vector3(4.6, 1.7, 1.2), Vector3(2.4, 1.3, 3.6), "lab_door_granted_angle")

	# View 3 — close on the scanner in its granted state.
	await _shoot(cam, Vector3(1.62, 1.45, 1.5), Vector3(1.6, 1.12, 2.66), "scanner_granted_closeup")

	print("[door] DONE -> %s" % OUT)
	quit(0)
