extends Node3D

## A look at the six dream bodies on six plinths, to a PNG. (2026-08-29) Not a
## probe: it asserts nothing. It exists because a builder that passes every
## count can still look like nothing, and the only instrument for that is an
## eye. Runs WINDOWED.
##
##   godot --path . --xr-mode off res://commons/testing/look_dream_bodies.tscn -- --out=<png> [--figure=<key>] [--seed=N]

const BODIES := preload("res://commons/artifacts/dream_bodies/dream_bodies.tscn")
const FIGURES := ["rocaille", "stijl_robot", "panel_robot", "dragon", "sea_forms", "stella_wall"]

var _out: String = "user://look_dream_bodies.png"
var _only: String = ""
var _seed: int = 1
var _t: float = 0.0
var _shot: bool = false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--figure="):
			_only = a.substr(9)
		elif a.begins_with("--seed="):
			_seed = int(a.substr(7))
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.86, 0.85, 0.82)
	wall_mat.roughness = 0.92
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.36, 0.35, 0.34)
	floor_mat.roughness = 0.85
	var plinth_mat := StandardMaterial3D.new()
	plinth_mat.albedo_color = Color(0.93, 0.93, 0.91)
	plinth_mat.roughness = 0.7
	_slab(Vector3(0, -0.1, 0), Vector3(30, 0.2, 30), floor_mat)
	_slab(Vector3(0, 2.4, -3.0), Vector3(30, 4.8, 0.3), wall_mat)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.5
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.85, 0.9, 1.0)
	add_child(fill)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.70, 0.72, 0.76)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.62)
	e.ambient_light_energy = 0.9
	env.environment = e
	add_child(env)

	var keys: Array = FIGURES if _only == "" else [_only]
	var n: int = keys.size()
	var pitch: float = 1.45
	for i in range(n):
		var key: String = String(keys[i])
		var x: float = (float(i) - float(n - 1) * 0.5) * pitch
		var b: Node3D = BODIES.instantiate() as Node3D
		b.set("figure", key)
		b.set("seed", _seed)
		if key == "stella_wall":
			# a relief: against the wall, no plinth. Turned 180 so its shapes come
			# OFF the wall toward the camera — its own frame projects to -z.
			b.position = Vector3(x, 0.4, -2.85)
			b.rotation_degrees = Vector3(0, 180, 0)
		else:
			_slab(Vector3(x, 0.2, 0.0), Vector3(0.9, 0.4, 0.9), plinth_mat)
			b.position = Vector3(x, 0.4, 0.0)
			b.rotation_degrees = Vector3(0, 15.0 * (1 if i % 2 == 0 else -1), 0)
		add_child(b)

	var cam := Camera3D.new()
	if _only == "":
		cam.position = Vector3(0.0, 1.45, 4.3)
		cam.look_at(Vector3(0.0, 1.05, -0.3))
		cam.fov = 68.0
	else:
		# a whole 1.7 m body on a 0.4 m plinth, three-quarters on, with air around it
		cam.position = Vector3(1.35, 1.45, 3.4)
		cam.look_at(Vector3(0.0, 1.05, 0.0))
		cam.fov = 46.0
	cam.current = true
	add_child(cam)


func _slab(at: Vector3, size: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = at
	add_child(mi)


func _process(delta: float) -> void:
	_t += delta
	if _t < 1.6 or _shot:
		return
	_shot = true
	var img: Image = get_viewport().get_texture().get_image()
	var err := img.save_png(_out)
	print("[look] %s -> %s" % [_out, "written" if err == OK else "FAILED %d" % err])
	get_tree().quit(0 if err == OK else 1)
