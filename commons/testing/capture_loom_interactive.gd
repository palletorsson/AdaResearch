extends SceneTree
var _n := 0
func _initialize() -> void:
	var root := get_root()
	var loom = load("res://commons/artifacts/pattern_loom/pattern_loom.tscn").instantiate()
	loom.interactive = true
	loom.group = "p4m"
	loom.palette = "bauhaus"
	loom.loom_style = "drum"
	loom.motif_seed = 7
	root.add_child(loom)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.08, 0.11)
	e.ambient_light_color = Color(0.45, 0.45, 0.5)
	e.ambient_light_energy = 0.7
	env.environment = e
	root.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -35, 0)
	root.add_child(light)
	var cam := Camera3D.new()
	cam.position = Vector3(2.3, 1.7, 2.8)
	cam.look_at(Vector3(0.4, 0.7, 0.2), Vector3.UP)
	root.add_child(cam)
	cam.current = true
func _process(_delta: float) -> bool:
	_n += 1
	if _n >= 70:
		get_root().get_texture().get_image().save_png("user://loom_interactive.png")
		return true
	return false
