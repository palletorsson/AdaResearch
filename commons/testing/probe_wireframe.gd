extends SceneTree

## DOES GODOT'S WIREFRAME DRAW ACTUALLY WORK IN THIS BUILD?
##
## 2026-08-31. Palle asked for an artifact you step into that blinks the museum
## to wireframe. Before designing anything, this settles three questions that
## decide whether the idea is buildable at all — and they are questions about the
## ENGINE, not about the artifact, so they get answered by rendering, not by
## reading the docs:
##
##   1. Does `viewport.debug_draw = DEBUG_DRAW_WIREFRAME` change the picture on
##      its own?
##   2. Does it need `RenderingServer.set_debug_generate_wireframes(true)`?
##   3. If it does — must that flag be set BEFORE the meshes are created? The
##      docs say wireframe index buffers are generated at mesh load, which if
##      true means an artifact cannot switch this on at runtime for a museum
##      whose meshes are already in memory, and the flag has to go somewhere at
##      boot instead.
##
## Each case renders the same scene and writes a PNG; the report is the pixel
## difference from the solid render. A case that changes nothing prints 0.00%,
## which is the whole point — a wireframe mode that silently does nothing looks
## exactly like a working one until you photograph it.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_wireframe.gd

const OUT := "user://wireframe_probe"

var _root: Window
var _scene: Node3D


func _initialize() -> void:
	_run()


func _run() -> void:
	_root = get_root()
	DirAccess.make_dir_recursive_absolute(OUT)

	# CASE A — debug_draw alone, meshes built before anything is asked for.
	_build("a")
	await _settle()
	var solid: Image = await _shot("0_solid")
	_root.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	var a: Image = await _shot("a_debug_draw_only")

	# CASE B — the generate flag turned on AFTER those meshes already exist.
	RenderingServer.set_debug_generate_wireframes(true)
	var b: Image = await _shot("b_flag_after_meshes")

	# CASE C — the flag was on before these meshes were made.
	_root.debug_draw = Viewport.DEBUG_DRAW_DISABLED
	_build("c")
	await _settle()
	_root.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	var c: Image = await _shot("c_flag_before_meshes")

	print("")
	print("WIREFRAME PROBE — %s" % Engine.get_version_info().get("string", "?"))
	print("  renderer: %s" % str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "(default)")))
	print("")
	print("  %-26s %s" % ["case", "pixels changed vs the solid render"])
	print("  %-26s %6.2f %%   debug_draw alone" % ["A debug_draw only", _diff(solid, a)])
	print("  %-26s %6.2f %%   flag set after the meshes existed" % ["B flag after meshes", _diff(solid, b)])
	print("  %-26s %6.2f %%   flag set before the meshes were made" % ["C flag before meshes", _diff(solid, c)])
	print("")
	print("  PNGs in %s" % ProjectSettings.globalize_path(OUT))
	quit(0)


## A handful of boxes and a camera. Boxes, because a wireframe is only visible on
## something with interior edges to draw.
func _build(tag: String) -> void:
	if _scene and is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
	_scene = Node3D.new()
	_scene.name = "Probe_" + tag
	_root.add_child(_scene)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.07, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.7)
	e.ambient_light_energy = 1.0
	env.environment = e
	_scene.add_child(env)

	for i in range(5):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 1.2, 1.2)
		mi.mesh = bm
		mi.position = Vector3(float(i) * 1.9 - 3.8, 0.0, float(i % 2) * -1.4)
		mi.rotation = Vector3(0.3, float(i) * 0.5, 0.1)
		_scene.add_child(mi)

	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 2.2, 7.0)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	cam.current = true
	_scene.add_child(cam)


func _settle() -> void:
	for i in range(6):
		await process_frame


func _shot(name: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = _root.get_texture().get_image()
	img.save_png(OUT + "/" + name + ".png")
	return img


## Share of pixels that differ at all. Not a perceptual measure — the question
## here is only "did the picture change", and a threshold of 8 levels keeps
## dithering and tonemap noise out of the answer.
func _diff(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return -1.0
	var w: int = a.get_width()
	var h: int = a.get_height()
	var step: int = maxi(1, int(w / 320.0))
	var seen: int = 0
	var moved: int = 0
	var x: int = 0
	while x < w:
		var y: int = 0
		while y < h:
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			seen += 1
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.03:
				moved += 1
			y += step
		x += step
	return 0.0 if seen == 0 else 100.0 * float(moved) / float(seen)
