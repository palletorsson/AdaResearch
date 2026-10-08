extends SceneTree

## Exercise the original gallery scenes with a real renderer, including the
## SubViewport that used to remain blank after the painter's 3D conversion.
const OUT := "res://doc/space/random-gallery-2026-09-16"
const POLLOCK := "res://algorithms/randomness/proceduralrandomness/movementbased/scenes/pollock2d/PollockPaintingIn3d.tscn"
const PARTICLES := "res://algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.tscn"

var failures: Array[String] = []
var checks: Array[Dictionary] = []
var stroke_events: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks.append({"label": label, "passed": ok})
	print("GALLERY CHECK: ", label, " = ", ok)
	if not ok:
		failures.append(label)


func image_colors(img: Image) -> int:
	if img == null or img.is_empty():
		return 0
	var colors: Dictionary = {}
	for y in range(0, img.get_height(), 6):
		for x in range(0, img.get_width(), 6):
			colors[img.get_pixel(x, y).to_html()] = true
	return colors.size()


func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280, 800)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0, 5.5, 4.5)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var scene: Node3D = load(POLLOCK).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var painter = scene.get_node("SubViewport/PollockPainting2D")
	var display: TextureRect = painter.get_node("CanvasLayer/TextureRect")
	var canvas_view: SubViewport = scene.get_node("SubViewport")
	check(display.texture != null, "Pollock's TextureRect receives the paint texture")
	check(image_colors(painter.canvas) > 4, "Initial image contains paint and background")
	var rendered: Image = canvas_view.get_texture().get_image()
	check(image_colors(rendered) > 4, "SubViewport renders a visible multicolour painting")
	rendered.save_png(ProjectSettings.globalize_path(OUT + "/pollock-initial-canvas.png"))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/pollock-initial-scene.png"))
	check(scene.find_children("*", "Camera3D", true, false).is_empty(), "Pollock adds no camera")
	check(root.get_camera_3d() == camera, "Pollock preserves the visitor camera")
	check(painter.find_children("*", "MeshInstance3D", true, false).is_empty(), "2D painter contains no unrendered 3D canvas")
	check(is_equal_approx(painter.painting_timer.wait_time, 4.0), "Original four-second painting interval remains")
	var initial_hash: int = hash(painter.canvas.get_data())
	painter.stroke_path_generated.connect(func(_path, _color, _width, _duration): stroke_events += 1)
	await create_timer(4.25).timeout
	await RenderingServer.frame_post_draw
	check(painter._paint_elapsed_time >= 4.0, "Automatic timer advances the paint buildup")
	check(hash(painter.canvas.get_data()) != initial_hash, "Automatic drips change the painted image")
	check(stroke_events > 0, "Automatic strokes still drive the 3D brush")
	check(image_colors(canvas_view.get_texture().get_image()) > 4, "Updated painting remains visible through the viewport")
	canvas_view.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/pollock-grown-canvas.png"))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/pollock-grown-scene.png"))
	painter.painting_timer.stop()
	painter.repaint_with_seed(20260916)
	var seed_hash: int = hash(painter.canvas.get_data())
	painter.repaint_with_seed(20260916)
	check(seed_hash == hash(painter.canvas.get_data()), "Seeded repaint still reproduces the same marks")
	for support in ["table", "easel", "wall", "floor"]:
		scene.apply_grid_config({"support": support})
		check(scene.support == support and scene.get_node_or_null("FramePanel") != null,
			"Support restaging retains the frame: " + support)
	scene.queue_free()
	await process_frame
	var particles: Node3D = load(PARTICLES).instantiate()
	root.add_child(particles)
	check(particles.particles.size() == 100, "Original particle population remains 100")
	check(root.get_camera_3d() == camera, "Particle scene preserves the visitor camera")
	check(is_equal_approx(particles.display_time, 10.0), "Original ten-second mode interval remains")
	# Accelerate only this probe's timer; the scene's default remains ten seconds.
	particles.display_time = 0.20
	var observed: Array[int] = [particles.current_demo]
	var began: int = Time.get_ticks_msec()
	while observed.size() < 6 and Time.get_ticks_msec() - began < 5000:
		await process_frame
		if particles.current_demo != observed[-1]:
			observed.append(particles.current_demo)
	check(observed == [0, 1, 2, 3, 4, 0], "Automatic particle cycle visits all five modes and wraps")
	particles.set_process(false)
	var all_finite: bool = true
	for particle in particles.particles:
		all_finite = all_finite and particle.position.is_finite()
	check(all_finite, "Particle positions remain finite after every mode")
	particles.current_demo = 4
	particles.start_demo(4)
	particles._process(1.0 / 60.0)
	var winners: int = 0
	var followers: int = 0
	for particle in particles.particles:
		var mat: StandardMaterial3D = particle.material
		if is_equal_approx(mat.emission_energy_multiplier, 0.5):
			winners += 1
		elif is_zero_approx(mat.emission_energy_multiplier):
			followers += 1
	check(winners == 10 and followers == 90, "Evolution updates emission for all ten winners and ninety followers")
	particles.queue_free()
	camera.queue_free()
	await process_frame
	var file := FileAccess.open(OUT + "/artifact-probe.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "stroke_events": stroke_events, "particle_cycle": observed}, "  "))
	file.close()
	print("RANDOM GALLERY ARTIFACT FAILURES: ", failures)
	quit(0 if failures.is_empty() else 1)
