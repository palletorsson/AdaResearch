extends SceneTree

## Visual check of the five lab changes (renders to encyclopedia, never the
## Godot repo): ceiling lamps fill tiles, sprinklers/sensors hang BELOW the
## ceiling, fire extinguisher stands proud of the wall, chalkboard mounted on
## the wall opposite the door, lab shifted −2m in Z.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_lab_changes.gd

const LAB_ROOM := "res://commons/artifacts/lab_room/lab_room.tscn"
const LAB_JSON := "res://commons/labs/point_one.lab.json"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner"


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _collect_chalkboards(n: Node, out: Array) -> void:
	var scr = n.get_script()
	if scr != null and str(scr.resource_path).find("chalkboard") != -1:
		out.append(n)
	for c in n.get_children():
		_collect_chalkboards(c, out)


func _shoot(cam: Camera3D, eye: Vector3, look: Vector3, name: String) -> void:
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	await _frames(6)
	var img: Image = root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	print("[lab] saved %s.png" % name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var world := Node3D.new()
	root.add_child(world)

	var lab: Node3D = load(LAB_ROOM).instantiate()
	lab.set_meta("config_mounted_lab_json", LAB_JSON)
	world.add_child(lab)
	await _frames(80)

	print("[lab] lab.position=%s (expect z≈−2)" % lab.position)
	# Count chalkboards: there must be EXACTLY ONE (the author-placed point
	# board), not two (author + a spurious auto-mounted fallback).
	var boards: Array = []
	_collect_chalkboards(lab, boards)
	print("[lab] chalkboards found=%d (expect 1)" % boards.size())
	for b in boards:
		print("[lab]   board '%s' local_pos=%s world_pos=%s" %
			[b.name, b.position, (b.global_position if b.is_inside_tree() else Vector3.ZERO)])
	var board: Node = boards[0] if boards.size() > 0 else null
	var fixtures := lab.find_child("CeilingFixtures", true, false)
	print("[lab] ceiling fixtures present=%s children=%s" %
		[fixtures != null, (fixtures.get_child_count() if fixtures else 0)])

	var cam := Camera3D.new()
	cam.fov = 70.0
	root.add_child(cam)
	cam.make_current()
	# Lab is centred at (0,*,−2) after offset. Stand inside, look up + around.
	var c := Vector3(0, 0, -2)   # lab centre after offset

	# 1. Up at the ceiling — lamps should fill tiles, sprinklers hang below.
	await _shoot(cam, c + Vector3(0, 1.2, 1.5), c + Vector3(0, 3.6, -0.5), "lab_ceiling")
	# 2. The chalkboard wall (north, −Z side of the lab).
	await _shoot(cam, c + Vector3(0, 1.5, 2.2), c + Vector3(0, 1.6, -3.5), "lab_chalkboard")
	# 3. The extinguisher corner (it sits near +X / +Z by the door wall).
	await _shoot(cam, c + Vector3(1.4, 1.4, 1.0), c + Vector3(3.6, 0.5, 3.4), "lab_extinguisher")
	# 4. Wide interior establishing shot.
	await _shoot(cam, c + Vector3(-3.0, 1.6, -2.4), c + Vector3(1.5, 1.3, 2.0), "lab_interior")
	# 5. The WEST wall (−X): title signage + chalkboard should both be here,
	#    read from the room interior looking toward −X.
	await _shoot(cam, c + Vector3(2.5, 1.6, 0.5), c + Vector3(-3.9, 1.5, 0.3), "lab_west_wall")
	# 6. The EAST wall (+X): the gadget wall should now be here.
	await _shoot(cam, c + Vector3(-2.5, 1.6, 0.5), c + Vector3(3.9, 1.4, 0.0), "lab_east_wall")

	print("[lab] DONE -> %s" % OUT)
	quit(0)
