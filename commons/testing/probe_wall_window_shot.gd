extends SceneTree
## Photograph cube_isometric with a REAL settle.
##
## build_dna_gallery's bench waits ~3 frames, and a nested SubViewport has not
## drawn by then — it photographed a flat grey panel while probe_wall_window
## proved 15 distinct colours in the render target. So the artifact was fine and
## the shutter was early. This waits 20 frames and saves the picture.
const OUT := "user://wall_abstract_window.png"

func _init() -> void:
	var S := load("res://commons/artifacts/wall_abstract/wall_abstract.tscn")
	var a = S.instantiate()
	a.work = "cube_isometric"
	get_root().add_child(a)

	var cam := Camera3D.new()
	get_root().add_child(cam)
	cam.position = Vector3(0.35, 0.12, 1.15)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	cam.current = true

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -30, 0)
	key.light_energy = 1.2
	get_root().add_child(key)

	for i in 20:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(OUT)
	print("saved -> %s  (%dx%d)" % [ProjectSettings.globalize_path(OUT),
			img.get_width(), img.get_height()])
	quit(0)
