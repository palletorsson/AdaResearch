extends SceneTree
## The work hung on a wall, seen by a visitor — BOTH facings, so the map token
## can be chosen from evidence rather than from a guess about which way +Z runs.
##
## Shot from +Z (the known-good camera position from probe_wall_abstract_sheet),
## with the wall behind at -Z. Two copies: one unrotated, one turned 180. Only
## one of them can be facing the room, and the picture says which.
const OUT := "user://point_line_wall.png"

func _init() -> void:
	var S := load("res://commons/artifacts/wall_abstract/wall_abstract.tscn")
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.44, 0.43, 0.42)
	grey.roughness = 0.95

	for i in 2:
		var a = S.instantiate()
		a.work = "divide_horizontal"
		get_root().add_child(a)
		a.position = Vector3(-0.72 + 1.44 * i, 1.55, 0)
		a.rotation_degrees = Vector3(0, 180.0 * i, 0)

	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(6, 3.2, 0.3)
	wall.mesh = wm
	wall.position = Vector3(0, 1.6, -0.3)
	wall.material_override = grey
	get_root().add_child(wall)

	var flr := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(6, 0.1, 8)
	flr.mesh = fm
	flr.position = Vector3(0, -0.05, 3.5)
	flr.material_override = grey
	get_root().add_child(flr)

	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.position = Vector3(0, 1.60, 2.6)
	cam.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	cam.current = true

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34, 18, 0)
	key.light_energy = 1.6
	get_root().add_child(key)

	for i in 22:
		await process_frame
	get_root().get_texture().get_image().save_png(OUT)
	print("saved -> %s   LEFT = rotation 0, RIGHT = rotation 180"
		% ProjectSettings.globalize_path(OUT))
	quit(0)
