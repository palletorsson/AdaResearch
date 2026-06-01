extends SceneTree

## Render you_are_here over a reference floor at a low angle, so we can SEE
## whether it lies flat ON the floor or floats / stands up. Also prints the
## text mesh's world AABB (min/max Y) — for a flat floor decal min Y should
## be ~0 and the vertical extent tiny.
##   godot --path . --xr-mode off --script res://commons/testing/shoot_you_are_here.gd

const ART := "res://commons/primitives/you_are_here/you_are_here.tscn"
const OUT := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/artifact-gallery/captures/palm_scanner/you_are_here_check.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.15, 0.16, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.1
	env.environment = e
	world.add_child(env)

	# Reference floor at y=0 (a tile), like the grid the decal is placed on.
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4, 4)
	floor.mesh = pm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.85, 0.86, 0.9)
	floor.material_override = fmat
	world.add_child(floor)

	var art: Node3D = load(ART).instantiate()
	art.global_position = Vector3.ZERO   # origin at floor level
	world.add_child(art)
	for i in range(20):
		await process_frame

	# World AABB of the text mesh.
	var txt := art.find_child("FloorText", true, false)
	if txt is VisualInstance3D:
		var ab: AABB = (txt as VisualInstance3D).get_aabb()
		var xf := (txt as Node3D).global_transform
		var lo := xf * ab.position
		var hi := xf * (ab.position + ab.size)
		print("[yah] FloorText world Y span: %.3f .. %.3f (flat decal => ~0, tiny span)" %
			[minf(lo.y, hi.y), maxf(lo.y, hi.y)])

	var cam := Camera3D.new()
	cam.fov = 55.0
	world.add_child(cam)
	cam.make_current()
	# Low oblique angle — a flat decal reads as flat; a standing one is obvious.
	cam.global_position = Vector3(0.0, 1.1, 2.2)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)
	for i in range(6):
		await process_frame

	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	root.get_texture().get_image().save_png(OUT)
	print("[yah] saved %s" % OUT)
	quit(0)
