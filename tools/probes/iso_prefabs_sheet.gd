extends SceneTree
## THE TWENTY ISOSURFACE PREFABS IN A STUDIO (the boolean floor, 2026-11-13)
## One picture of each form from two sides, with its plaque, in a plain room with one sun: what the bake made of
## tools/iso_prefabs.py's expressions, before any of it stands in the tower. Needs a window (headless draws no frames).
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/iso_prefabs_sheet.gd -- --out=<dir> [--finish=cast]
##
## <dir>/<form>_a.png (from the south-west, above), <form>_b.png (from the north-east, low); sheet.json.
const Prefab := preload("res://commons/artifacts/iso_prefabs/iso_prefab.gd")

var eye: SubViewport
var cam: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _shot(at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func run() -> void:
	var folder := ""
	var finish := "provenance"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--finish="): finish = arg.trim_prefix("--finish=")
	DirAccess.make_dir_recursive_absolute(folder)
	eye = SubViewport.new()
	eye.size = Vector2i(960, 720)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	eye.msaa_3d = Viewport.MSAA_4X
	root.add_child(eye)
	var world := Node3D.new()
	eye.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.17, 0.18, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.64, 0.7)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.42, 0.43, 0.45)
	grey.roughness = 0.95
	ground.material_override = grey
	world.add_child(ground)
	cam = Camera3D.new()
	cam.fov = 50
	world.add_child(cam)
	cam.current = true
	var rows := []
	for form in Prefab.FORMS:
		var piece: Node3D = Prefab.new()
		piece.form = form
		piece.finish = finish
		piece.plaque = true
		piece.frozen = true
		world.add_child(piece)
		var mesh: ArrayMesh = (piece.get_node("IsoBody/IsoMesh") as MeshInstance3D).mesh
		var box: AABB = mesh.get_aabb()
		var mid := box.get_center()
		var reach := maxf(box.size.length(), 1.2)
		await _shot(mid + Vector3(-0.62, 0.55, 0.78).normalized() * reach * 1.25, mid, folder.path_join(form + "_a.png"))
		await _shot(mid + Vector3(0.75, 0.22, -0.66).normalized() * reach * 1.15 + Vector3(0, 0.3, 0), mid, folder.path_join(form + "_b.png"))
		rows.append({"form": form, "aabb": [box.position, box.end], "state": piece.state()})
		piece.queue_free()
		await process_frame
	var file := FileAccess.open(folder.path_join("sheet.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"forms": rows.size(), "rows": rows}, "\t"))
	file.close()
	print("[iso_prefabs_sheet] ", rows.size(), " forms")
	quit()
