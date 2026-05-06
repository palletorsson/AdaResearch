## Capture CarpetCoveGallery
extends SceneTree

var _frame := 0
var _cam: Camera3D
var _out_dir := "user://cove_gallery_shots"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var scene := load("res://algorithms/shaders/carpet_cove_gallery/carpet_cove_gallery.tscn") as PackedScene
	var gallery := scene.instantiate()
	root.add_child(gallery)
	_cam = Camera3D.new()
	_cam.current = true
	root.add_child(_cam)
	print("capture_cove: Scene loaded")

func _process(_delta: float) -> bool:
	_frame += 1

	# 1. Eye-level corridor view
	if _frame == 120:
		_cam.fov = 70
		_cam.position = Vector3(0, 1.65, -10)
		_cam.look_at(Vector3(0, 1.2, 2))
		return false
	if _frame == 125:
		_save("corridor.png")
		return false

	# 2. Close-up of a single cove — the curve
	if _frame == 140:
		_cam.fov = 50
		_cam.position = Vector3(0, 1.2, -12)
		_cam.look_at(Vector3(0, 0.8, -14))
		return false
	if _frame == 145:
		_save("cove_closeup.png")
		return false

	# 3. Low angle showing cove curves
	if _frame == 160:
		_cam.fov = 65
		_cam.position = Vector3(2.0, 0.4, -8)
		_cam.look_at(Vector3(-1.0, 1.0, -12))
		return false
	if _frame == 165:
		_save("low_angle.png")
		return false

	# 4. Bird's eye
	if _frame == 180:
		_cam.fov = 50
		_cam.position = Vector3(0, 10, 0)
		_cam.look_at(Vector3(0, 0, 1))
		return false
	if _frame == 185:
		_save("birds_eye.png")
		return false

	if _frame == 190:
		print("capture_cove: Done — 4 shots")
		quit()
		return true
	return false

func _save(filename: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(_out_dir.path_join(filename))
	print("capture_cove: ✅ %s" % filename)
