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

	var cam := Camera3D.new()
	cam.fov = 62.0
	root.add_child(cam)
	cam.make_current()

	# View 1 — IDLE: white door closed, scanner resting ("PLACE HAND").
	# South wall at z=+3.5; door at x≈2.6; podium scanner at (1.6,0,2.65).
	var eye := Vector3(0.2, 1.65, -0.6)
	var look := Vector3(2.0, 1.35, 3.4)
	await _shoot(cam, eye, look, "lab_door_idle")

	# View 2 — GRANTED: force the scanner to grant (which opens the white
	# door via the wired palm_scanned signal) and shoot the same framing.
	var scanner: Node = _find_by_signal(lab, "palm_scanned")
	if scanner != null and scanner.has_method("_grant_access"):
		scanner.call("_grant_access")
	await _frames(45)   # let the door slide open + plate flash settle
	await _shoot(cam, eye, look, "lab_door_granted")

	# View 3 — close on the scanner in its granted state.
	await _shoot(cam, Vector3(1.62, 1.45, 1.5), Vector3(1.6, 1.12, 2.66), "scanner_granted_closeup")

	print("[door] DONE -> %s" % OUT)
	quit(0)
