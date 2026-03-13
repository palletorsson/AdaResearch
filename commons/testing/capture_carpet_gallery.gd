## Capture PixelCarpetGallery — walking through the corridor
extends SceneTree

var _frame := 0
var _cam: Camera3D
var _out_dir := "user://carpet_gallery_shots"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)

	var scene := load("res://algorithms/shaders/pixel_carpet_gallery/pixel_carpet_gallery.tscn") as PackedScene
	var gallery := scene.instantiate()
	root.add_child(gallery)

	_cam = Camera3D.new()
	_cam.current = true
	root.add_child(_cam)
	print("capture_gallery: Scene loaded")

func _process(_delta: float) -> bool:
	_frame += 1

	# 1. Standing at entrance looking down the corridor — eye height
	if _frame == 100:
		_cam.fov = 75
		_cam.position = Vector3(0, 1.65, -13)
		_cam.look_at(Vector3(0, 1.4, 5))
		return false
	if _frame == 105:
		_save("walk_entrance.png")
		return false

	# 2. A few steps in — surrounded by carpets
	if _frame == 120:
		_cam.fov = 80
		_cam.position = Vector3(0.3, 1.65, -6)
		_cam.look_at(Vector3(-0.5, 1.2, 3))
		return false
	if _frame == 125:
		_save("walk_mid.png")
		return false

	# 3. Looking down at feet — carpets on floor
	if _frame == 140:
		_cam.fov = 70
		_cam.position = Vector3(0, 1.65, -2)
		_cam.look_at(Vector3(0.3, 0, -1))
		return false
	if _frame == 145:
		_save("look_down.png")
		return false

	# 4. Looking up at wall — carpets floor to ceiling
	if _frame == 160:
		_cam.fov = 70
		_cam.position = Vector3(-1.0, 1.65, 2)
		_cam.look_at(Vector3(-3.0, 2.5, 4))
		return false
	if _frame == 165:
		_save("left_wall.png")
		return false

	# 5. Low angle corridor shot
	if _frame == 180:
		_cam.fov = 85
		_cam.position = Vector3(0.5, 0.5, -10)
		_cam.look_at(Vector3(-0.3, 1.5, 5))
		return false
	if _frame == 185:
		_save("low_angle.png")
		return false

	# 6. Top-down bird's eye
	if _frame == 200:
		_cam.fov = 50
		_cam.position = Vector3(0, 12, 0)
		_cam.look_at(Vector3(0, 0, 1))
		return false
	if _frame == 205:
		_save("birds_eye.png")
		return false

	if _frame == 210:
		print("capture_gallery: Done — 6 shots saved")
		quit()
		return true
	return false

func _save(filename: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(filename)
	img.save_png(path)
	print("capture_gallery: ✅ %s" % filename)
