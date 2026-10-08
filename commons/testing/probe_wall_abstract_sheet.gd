extends SceneTree
## All four works, shot with a REAL settle.
##
## The DNA bench waits ~3 frames and a nested SubViewport has not drawn by then,
## so its cube_isometric tile is a false negative. This waits 20 and overwrites
## the gallery tiles, so the page you can open is the page that is true.

const WORKS := ["divide_horizontal", "divide_vertical", "divide_diagonal",
	"divide_off_centre", "horizon_soft", "point_one", "two_points",
	"segment_drawn", "grid_regular", "trace_once", "corner_square",
	"cube_isometric", "cube_wire", "sphere_raking", "chalk"]
const OUT := "user://wall_abstract_sheet/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var S := load("res://commons/artifacts/wall_abstract/wall_abstract.tscn")

	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.position = Vector3(0.0, 0.06, 1.05)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	cam.current = true
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34, -26, 0)
	key.light_energy = 1.35
	get_root().add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 150, 0)
	fill.light_energy = 0.35
	get_root().add_child(fill)

	for w in WORKS:
		var a = S.instantiate()
		a.work = w
		get_root().add_child(a)
		for i in 22:
			await process_frame
		var img := get_root().get_texture().get_image()
		var path: String = OUT + w + ".png"
		img.save_png(path)
		print("  %-20s -> %s" % [w, ProjectSettings.globalize_path(path)])
		a.queue_free()
		await process_frame
		await process_frame
	print("done")
	quit(0)
