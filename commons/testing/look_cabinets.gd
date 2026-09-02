extends Node3D

## A look at the two wall boxes, to a PNG. (2026-08-29) Not a probe: it asserts
## nothing. A plaster wall, the red EMERGENCY cabinet with the sledgehammer and
## the velvet pistol case with the pink gun, side by side; a fake hand stands
## within reach of the pistol case so its door is caught swinging open. Runs
## WINDOWED — a headless run has no renderer and writes a black frame.
##
##   godot --path . --xr-mode off res://commons/testing/look_cabinets.tscn -- --out=<png>

const CABINET := preload("res://commons/artifacts/weapon_cabinet/weapon_cabinet.tscn")

var _out: String = "user://look_cabinets.png"
var _t: float = 0.0
var _shot: bool = false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.86, 0.85, 0.82)
	wall_mat.roughness = 0.92
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.40, 0.38, 0.36)
	floor_mat.roughness = 0.85
	_slab(Vector3(0, -0.1, 0), Vector3(12, 0.2, 12), floor_mat)
	_slab(Vector3(0, 1.6, -1.6), Vector3(12, 3.2, 0.2), wall_mat)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 28, 0)
	sun.light_energy = 1.5
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.4, 2.2, 1.4)
	fill.light_energy = 1.4
	fill.omni_range = 6.0
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

	# the two boxes, backs to the wall, fronts to the camera (+z)
	var specs := [["emergency", "line_sledgehammer", -0.75, 1.22], ["velvet", "pink_gun", 0.75, 1.42]]
	for sp in specs:
		var c: Node3D = CABINET.instantiate() as Node3D
		c.set("style", sp[0])
		c.set("weapon", sp[1])
		c.position = Vector3(sp[2], sp[3], -1.5 + 0.01)
		c.rotation_degrees = Vector3(0, 180, 0)
		add_child(c)
	# a hand within reach of the pistol case: its door opens for the picture
	var hand := XRController3D.new()
	hand.name = "RightHand"
	hand.position = Vector3(0.75, 1.3, -0.9)
	add_child(hand)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.45, 1.75)
	cam.look_at(Vector3(0.0, 1.3, -1.5))
	cam.fov = 58.0
	for a in OS.get_cmdline_user_args():
		if a == "--close":
			# the pistol case alone, from a metre off, the door caught opening
			cam.position = Vector3(0.55, 1.5, -0.45)
			cam.look_at(Vector3(0.75, 1.42, -1.5))
			cam.fov = 50.0
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
	if _t < 2.2 or _shot:
		return
	_shot = true
	var img: Image = get_viewport().get_texture().get_image()
	var err := img.save_png(_out)
	print("[look] %s -> %s" % [_out, "written" if err == OK else "FAILED %d" % err])
	get_tree().quit(0 if err == OK else 1)
