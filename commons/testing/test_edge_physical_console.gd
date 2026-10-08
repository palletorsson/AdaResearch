extends SceneTree
const OUT := "res://doc/reports/interfaces-2026-09-21/edge-console/"
var checks := 0
var failures: Array[String] = []
var world: Node3D
var camera: Camera3D
var pointer: Node3D
var before_script: GDScript

class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		if held: held.let_go(self, Vector3.ZERO, Vector3.ZERO)
		held = null

func _initialize() -> void: run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks += 1
	print("EDGE_UI ", "PASS " if ok else "FAIL ", description)
	if not ok: failures.append(description)
func settle() -> void:
	for frame in 6:
		await physics_frame
		await process_frame

func make_artifact(mode: String, paired: bool, size: int = 24) -> Node3D:
	var artifact: Node3D = load("res://commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.tscn").instantiate()
	artifact.grid_size = size
	artifact.tenure = mode
	artifact.comparison_study = paired
	world.add_child(artifact)
	artifact.set_process(false)
	return artifact

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.1, .12, .14)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.90, .93, 1)
	env.environment.ambient_light_energy = .8
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(12, 12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.21, .24, .27)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)
	camera = Camera3D.new()
	camera.current = true
	world.add_child(camera)
	pointer = Node3D.new()
	world.add_child(pointer)
	root.msaa_3d = Viewport.MSAA_4X
	before_script = GDScript.new()
	before_script.source_code = FileAccess.get_file_as_string(OUT + "before/edge_of_chaos_unlocked.gd.txt").replace("class_name EdgeOfChaosUnlocked", "")
	check(before_script.reload() == OK, "Before snapshot compiles")
	var before: Node3D = before_script.new()
	before.comparison_study = true
	world.add_child(before)
	before.set_process(false)
	var seed_a: PackedFloat32Array = before._grid_a.duplicate()
	var seed_b: PackedFloat32Array = before._grid_b.duplicate()
	for tick in 200: before._advance_tick()
	before._update_texture()
	var evolved_a: PackedFloat32Array = before._grid_a.duplicate()
	var evolved_b: PackedFloat32Array = before._grid_b.duplicate()
	var fine_b: PackedFloat32Array = before._fine_b.duplicate()
	var model_time: float = before.model_time
	await settle()
	await capture_pair("before")
	before.queue_free()
	await settle()
	var artifact := make_artifact("unlocked", true, 64)
	await settle()
	check(artifact._grid_a == seed_a and artifact._grid_b == seed_b, "Seeded concentrations match the prior implementation")
	for tick in 200: artifact._advance_tick()
	artifact._update_texture()
	check(artifact._grid_a == evolved_a and artifact._grid_b == evolved_b and artifact._fine_b == fine_b and is_equal_approx(artifact.model_time, model_time), "Both numerical fields and model time match after 200 ticks")
	check(artifact.find_children("*", "Label3D", true, false).is_empty(), "Paired artifact text is flat on surfaces")
	check(artifact._controls.buttons.size() == 4 and artifact._controls.sliders.size() == 2, "Both rails and four study actions are grouped in one console")
	check(artifact._controls.position.z > artifact._display_quad.position.z and artifact._controls.position.y < artifact._display_quad.position.y, "Console is in front of and below the two fields")
	await capture_pair("after")
	var panel: Node3D = artifact._controls
	var slider: Node3D = panel.sliders[0]
	var grabber := TestGrabber.new()
	world.add_child(grabber)
	grabber.global_transform = slider._handle.global_transform
	grabber.held = slider._handle
	slider._handle.pick_up(grabber)
	grabber.global_position = slider._track.get_parent().to_global(Vector3(.37 * .18, 0, 0))
	await settle()
	check(is_equal_approx(artifact.lambda, .37), "Real XR grab changes the unlocked parameter without quantization")
	grabber.drop_object()
	await pointer_drag(slider, .37, .62)
	check(is_equal_approx(artifact.lambda, .62) and panel._readout.label.text.contains("0.62"), "Ray drag changes lambda and the flat readout")
	artifact.apply_grid_config({"lambda": .46})
	check(is_equal_approx(slider.get_normalized_value(), .46), "External lambda moves the physical cap silently")
	slider = panel.sliders[1]
	grabber.global_transform = slider._handle.global_transform
	grabber.held = slider._handle
	slider._handle.pick_up(grabber)
	for step in [0, 7, 2]:
		grabber.global_position = slider._track.get_parent().to_global(Vector3(step / 7.0 * .18, 0, 0))
		await settle()
		check(artifact.sim_steps == step + 1 and is_equal_approx(slider.get_normalized_value(), step / 7.0), "Speed cap and model request agree at step %d" % (step + 1))
	grabber.drop_object()
	await click(panel.buttons[3])
	var held_time: float = artifact.model_time
	artifact._process(.5)
	check(artifact._paused and panel.buttons[3].is_selected() and artifact.model_time == held_time and panel._readout.label.text.contains("HOLD"), "HOLD freezes integration and retains visible feedback")
	var current_seed: int = artifact.seed_value
	await click(panel.buttons[0])
	check(artifact.model_time == 0 and artifact.seed_value == current_seed and artifact._grid_b == seed_b and artifact._paused, "RESTART restores the same numbered seed, keeping HOLD")
	await click(panel.buttons[1])
	check(artifact.seed_value == current_seed + 1 and artifact._grid_b != seed_b and artifact.model_time == 0, "NEW SEED changes only the start and resets model time")
	var new_start: PackedFloat32Array = artifact._grid_b.duplicate()
	await click(panel.buttons[2])
	check(is_equal_approx(artifact.time_step, .15) and artifact._grid_b == new_start and panel.buttons[2].is_selected(), "DT toggle restarts the same seed at a smaller step and shows selection")
	check(artifact._dt_labels[0].label.text == "DT 0.150" and artifact._dt_labels[1].label.text == "DT 0.075", "Both timestep labels follow the real solver")
	await click(panel.buttons[3])
	artifact._process(.1)
	artifact._update_texture()
	check(not artifact._paused and not panel.buttons[3].is_selected() and artifact.model_time > 0, "RUN resumes the actual integration")
	check(panel._readout.label.text.contains("B difference"), "Paired numerical difference remains available")
	# Restriction is about access, not an alternate numerical engine.
	artifact.queue_free()
	await settle()
	for paired in [false, true]:
		for mode in ["unlocked", "clamped", "withheld", "frozen", "chaos"]:
			artifact = make_artifact(mode, paired)
			await settle()
			panel = artifact._controls
			var value: float = artifact.lambda
			check(panel.sliders[1].input_enabled and panel.buttons.size() == (4 if paired else 2), "%s / paired=%s retains speed and the applicable actions" % [mode, paired])
			if mode == "withheld":
				check(panel.sliders[0] == null and panel.has_node("Blank_0") and panel._readout.label.text.contains("NO FADER"), "Withheld has a riveted blank, no hidden interactive fader")
			else:
				slider = panel.sliders[0]
				var allowed: bool = mode == "unlocked"
				check(slider._handle.can_pick_up(grabber) == allowed, "%s grants exactly its authored grab permission" % mode)
				if not allowed:
					slider._handle.pick_up(grabber)
					await pointer_drag(slider, value, .65 if value < .5 else .35)
					check(not slider._handle.is_picked_up() and not slider._handle.is_processing() and is_equal_approx(artifact.lambda, value) and is_equal_approx(slider.get_normalized_value(), value), "%s blocks both grab and pointer without a false handle position" % mode)
					check(slider.has_node("Clamp_0"), "%s has a visible clamp over the actual cap" % mode)
					artifact.apply_grid_config({"lambda": .27})
					check(is_equal_approx(slider.get_normalized_value(), .27) and is_equal_approx(slider.get_node("Clamp_0").position.y, (.27 - .5) * .18), "Authored value moves held cap and clamp together")
			check(artifact.find_children("*", "Label3D", true, false).is_empty(), "%s / paired=%s has only flat text" % [mode, paired])
			if not paired and mode in ["unlocked", "clamped", "withheld"]:
				artifact.apply_grid_config({"lambda": .4})
				for tick in 120: artifact._advance_tick()
				artifact._update_texture()
				await capture_pair(mode)
			artifact.queue_free()
			await settle()
	artifact = make_artifact("unlocked", true)
	var external := Node3D.new()
	external.name = "ExternalPlacement"
	artifact.add_child(external)
	artifact.apply_grid_config({"tenure": "withheld", "lambda": .33})
	await settle()
	check(is_instance_valid(external) and artifact._controls.sliders[0] == null and is_equal_approx(artifact.lambda, .33), "Live tenure rebuild preserves placement children and explicit lambda")
	artifact.apply_grid_config({"tenure": "unlocked", "comparison_study": "off"})
	await settle()
	check(artifact._controls.buttons.size() == 2 and artifact._controls.sliders[0].input_enabled and artifact.find_children("Controls", "", false, false).size() == 1, "Returning from withheld restores one working console")
	FileAccess.open(OUT + "checks.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "headset_tested": false, "method": "Actual XR Tools grab and physics ray input; ten access/comparison combinations; before/after numerical fields; restart, seed, pause, timestep and live configuration"}, "\t"))
	print("EDGE_UI_RESULT ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func pointer_drag(slider: Node3D, start: float, finish: float) -> void:
	await physics_frame
	var from := slider.to_global(Vector3(0, (start - .5) * .18, .30))
	var to := slider.to_global(Vector3(0, (start - .5) * .18, -.02))
	var query := PhysicsRayQueryParameters3D.create(from, to, (1 << 20) | (1 << 22))
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty(), "Ray reaches parameter hardware")
	if hit.is_empty(): return
	XRToolsPointerEvent.pressed(pointer, hit.collider, hit.position)
	var end: Vector3 = hit.position + slider.global_basis.y * ((finish - start) * .18)
	XRToolsPointerEvent.moved(pointer, hit.collider, end, hit.position)
	XRToolsPointerEvent.released(pointer, hit.collider, end)
	await settle()

func click(button: Node3D) -> void:
	await physics_frame
	var at := button.to_global(Vector3(0, .024, 0))
	var normal := button.global_basis.y
	var query := PhysicsRayQueryParameters3D.create(at + normal * .25, at - normal * .04, 1 << 20)
	query.collide_with_areas = true
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == button.get_node("InteractableAreaButton"), "Ray reaches %s" % button.name)
	if not hit.is_empty():
		XRToolsPointerEvent.pressed(pointer, hit.collider, hit.position)
		XRToolsPointerEvent.released(pointer, hit.collider, hit.position)
	await settle()

func capture_pair(prefix: String) -> void:
	camera.position = Vector3(0, 1.65, 1.85)
	camera.fov = 98
	camera.look_at(Vector3(0, 1.33, 0))
	await capture(prefix + "-front")
	camera.position = Vector3(.34, 1.49, 1.69)
	camera.fov = 61
	camera.look_at(Vector3(0, .94, 1.0))
	await capture(prefix + "-close")
	camera.position = Vector3(3.2, 2.7, 4.5)
	camera.fov = 55
	camera.look_at(Vector3(0, 1.3, .3))
	await capture(prefix + "-overview")

func capture(tag: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + tag + ".png")
