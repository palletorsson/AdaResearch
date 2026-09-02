extends Node3D

## A look at the silhouettes and the pink gun, from one standpoint, to a PNG.
## (2026-08-29) Not a probe: it asserts nothing. It exists because a sprite that
## passes every count can still look wrong, and the only instrument for that is
## an eye. Runs WINDOWED — a headless run has no renderer and writes a black frame.
##
##   godot --path . --xr-mode off res://commons/testing/look_silhouettes.tscn -- --out=<png>

const FOE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const GUN := preload("res://commons/artifacts/pink_gun/pink_gun.tscn")

var _out: String = "user://look_silhouettes.png"
var _t: float = 0.0
var _shot: bool = false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)

	# a floor and a back wall, plaster, so the sprites have something to stand on
	# and their shadows have somewhere to fall
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.86, 0.85, 0.82)
	wall_mat.roughness = 0.92
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.42, 0.40, 0.37)
	floor_mat.roughness = 0.85
	_slab(Vector3(0, -0.1, 0), Vector3(24, 0.2, 24), floor_mat, 1)
	_slab(Vector3(0, 2.25, -6.0), Vector3(24, 4.5, 0.3), wall_mat, 1)

	# light: one warm key from high left, and a little fill, so the flat things
	# read as flat things in a lit room rather than as cut-outs on a website
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.6
	sun.light_color = Color(1.0, 0.93, 0.85)
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.72, 0.74, 0.78)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.57, 0.62)
	e.ambient_light_energy = 0.9
	env.environment = e
	add_child(env)

	# five silhouettes in a loose rank, mid-step, one already a friend (pink)
	var seeds := [7919, 15838, 23757, 31676, 39595]
	var xs := [-4.5, -2.5, -0.5, 1.5, 3.5]
	var zs := [-3.5, -2.5, -3.5, -2.5, -3.5]
	for i in range(5):
		var f: Node3D = FOE.instantiate() as Node3D
		f.set("body", "silhouette")
		f.set("silhouette_seed", seeds[i])
		f.set("phase", "friend" if i == 3 else "foe")
		f.position = Vector3(xs[i], 0.0, zs[i])
		add_child(f)

	# the gun, three forms, on plinths in the foreground
	var plinth_mat := StandardMaterial3D.new()
	plinth_mat.albedo_color = Color(0.93, 0.93, 0.91)
	var forms := ["stub", "long", "cluster"]
	for i in range(3):
		var px: float = -1.6 + i * 1.6
		_slab(Vector3(px, 0.45, 1.2), Vector3(0.5, 0.9, 0.5), plinth_mat, 0)
		var g: Node3D = GUN.instantiate() as Node3D
		g.position = Vector3(px, 1.05, 1.2)
		g.rotation_degrees = Vector3(0, 35, 0)
		add_child(g)
		g.set("freeze", true)   # parked, not dropped: it is a rigid body and the plinth is not a floor to it
		var inner: Node = g.find_child("PinkGun", true, false)
		if inner != null:
			inner.set("form", forms[i])
			if inner.has_method("apply_grid_config"):
				inner.call("apply_grid_config", {"form": forms[i]})

	# the eye
	var cam := Camera3D.new()
	cam.position = Vector3(0.3, 1.45, 4.6)
	cam.look_at(Vector3(-0.2, 1.0, -2.0))
	cam.fov = 58.0
	cam.current = true
	add_child(cam)


func _slab(at: Vector3, size: Vector3, m: Material, layer: int) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	body.add_child(mi)
	body.position = at
	add_child(body)


func _process(delta: float) -> void:
	_t += delta
	if _t < 1.4 or _shot:
		return
	_shot = true
	var img: Image = get_viewport().get_texture().get_image()
	var err := img.save_png(_out)
	print("[look] %s -> %s" % [_out, "written" if err == OK else "FAILED %d" % err])
	get_tree().quit(0 if err == OK else 1)
