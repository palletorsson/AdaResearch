extends SceneTree
## Real collision/pointer/near-grab paths, plus artifact state and geometry.
const OUT := "res://doc/reports/interfaces-2026-09-21/edge-console/regression/fitness/"
var checks := 0
var failures: Array[String] = []
var world: Node3D
var camera: Camera3D
var pointer: Node3D
var activations := 0

class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self, Vector3.ZERO, Vector3.ZERO)
		held = null

func _initialize() -> void: run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks += 1
	print("FITNESS_UI ", "PASS " if ok else "FAIL ", description)
	if not ok: failures.append(description)
func settle() -> void:
	for frame in 8:
		await physics_frame
		await process_frame
func cap_settle() -> void:
	await create_timer(.13).timeout
	await settle()

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.10, .12, .14)
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
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(.21, .24, .27)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)
	camera = Camera3D.new()
	camera.current = true
	world.add_child(camera)
	pointer = Node3D.new()
	world.add_child(pointer)
	root.msaa_3d = Viewport.MSAA_4X
	# Snapshot the pre-migration source without re-registering its class name.
	var before_script := GDScript.new()
	before_script.source_code = FileAccess.get_file_as_string(OUT + "before/fitness_landscape_politics.gd.txt").replace("class_name FitnessLandscapePolitics", "")
	check(before_script.reload() == OK, "Before source compiles for matched evidence")
	var before: Node3D = before_script.new()
	world.add_child(before)
	before.set_process(false)
	before._update_multimesh()
	var start_particles: Array = before._particles.duplicate(true)
	var start_terrain: PackedColorArray = before._terrain_im.surface_get_arrays(0)[Mesh.ARRAY_COLOR].duplicate()
	await settle()
	await capture_pair("before")
	before.queue_free()
	await settle()
	var artifact: Node3D = load("res://commons/artifacts/fitness_landscape_politics/fitness_landscape_politics.tscn").instantiate()
	world.add_child(artifact)
	artifact.set_process(false)
	artifact._update_multimesh()
	await settle()
	var controls: Node3D = artifact._controls
	check(artifact._particles == start_particles, "Same seeded agents, positions, velocities and fitness memories")
	check(artifact._terrain_im.surface_get_arrays(0)[Mesh.ARRAY_COLOR] == start_terrain, "Same original terrain scoring colours")
	check(controls.buttons.size() == 4, "All four rules have a return path on the default artifact")
	check(controls.buttons[0].is_selected(), "Initial converge selection is visible")
	check(controls.buttons[1]._button_material.albedo_color.is_equal_approx(controls.buttons[1].released_color), "Unselected caps initialize with their configured colour")
	check(artifact.find_children("*", "Label3D", true, false).is_empty(), "Artifact text uses flat surfaces, with no floating Label3D")
	check(controls.position.z > artifact.arena_size * .5, "Controls sit in front of the actual terrain extent")
	check(controls.slider.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Physical controls retain unit world scale")
	check(controls.slider.continuous and controls.slider._track.slider_steps == 0, "Inertia is continuous rather than six artificial stops")
	check(is_equal_approx(controls.slider.get_normalized_value(), .6), "Initial inertia agrees with handle")
	var panel := controls.get_node("Choices")
	var back: MeshInstance3D = panel.get_node("Tilt/Chrome/BackPanel")
	var covered := true
	for corner in 8:
		var point: Vector3 = controls.to_local(back.to_global(back.get_aabb().get_endpoint(corner)))
		covered = covered and absf(point.x) < .38 and point.y > -.295 and point.y < .385
	check(covered, "Shared choice plate is fully supported by its casing")
	# Pause swarm integration while checking that a mode choice does not move agents.
	for index in [1, 2, 3, 0]:
		await click(controls.buttons[index])
		var chosen := 0
		for button in controls.buttons:
			if button.is_selected(): chosen += 1
		check(chosen == 1 and controls.buttons[index].is_selected() and int(artifact.current_landscape) == index, "Rule %d selects and retains exactly one cap" % index)
		check(controls._display.label.text.begins_with(artifact.mandate.to_upper()) and artifact._landscape_label.text.begins_with(artifact.mandate.to_upper()), "Rule %d agrees with both flat displays" % index)
	var positions_unchanged := true
	for i in start_particles.size():
		positions_unchanged = positions_unchanged and artifact._particles[i].pos == start_particles[i].pos
	check(positions_unchanged, "Changing the reward preserves particle positions")
	# Real physics body enters the same Area3D the VR hands use.
	var button: Node3D = controls.buttons[1]
	button.pressed.connect(func(): activations += 1)
	var probe := AnimatableBody3D.new()
	probe.sync_to_physics = false
	probe.collision_layer = 1 << 17
	probe.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = .009
	probe.add_child(shape)
	probe.position = Vector3(0, 5, 0)
	world.add_child(probe)
	await settle()
	var area: Area3D = button.get_node("InteractableAreaButton")
	var cap: Node3D = button.get_node("Button")
	var up := cap.position
	probe.global_position = button.to_global(Vector3(0, .024, 0))
	await cap_settle()
	check(area.pressed and activations == 1 and artifact.mandate == "spread", "Near-touch physics overlap selects the actual reward")
	check(is_equal_approx(cap.position.y, up.y - .02), "Physical cap visibly depresses twenty millimetres")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	XRToolsPointerEvent.released(pointer, area, area.global_position)
	check(area.pressed and activations == 1, "Pointer release does not release a hand still touching the cap")
	probe.position = Vector3(0, 5, 0)
	await cap_settle()
	check(not area.pressed and cap.position.is_equal_approx(up) and button.is_selected(), "Cap rises after touch, while chosen rule stays selected")
	probe.queue_free()
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	area.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await cap_settle()
	check(not area.pressed and cap.position.is_equal_approx(up), "Focus loss clears pointer press and raises cap")
	var disposable := Node3D.new()
	world.add_child(disposable)
	XRToolsPointerEvent.pressed(disposable, area, area.global_position)
	disposable.queue_free()
	await cap_settle()
	check(not area.pressed, "Freed pointer cannot leave a button held down")
	# The continuous fader uses actual XR Tools pickup and a moving grab driver.
	var slider: Node3D = controls.slider
	var grabber := TestGrabber.new()
	world.add_child(grabber)
	grabber.global_transform = slider._handle.global_transform
	grabber.held = slider._handle
	slider._handle.pick_up(grabber)
	for value in [.37, .81, .13]:
		grabber.global_position = slider._track.get_parent().to_global(Vector3(value * .18, 0, 0))
		await settle()
		check(is_equal_approx(artifact.inertia, value), "Near-grab sets continuous inertia %.2f without drift" % value)
	grabber.drop_object()
	await settle()
	check(is_equal_approx(artifact.inertia, .13) and controls._display.label.text.contains("0.13"), "Release retains inertia and updates its number")
	var start: Vector3 = slider.to_global(Vector3(0, -.09 + .13 * .18, .03))
	XRToolsPointerEvent.pressed(pointer, slider, start)
	XRToolsPointerEvent.moved(pointer, slider, start + slider.global_basis.y * (.22 * .18), start)
	XRToolsPointerEvent.released(pointer, slider, start)
	check(is_equal_approx(artifact.inertia, .35), "Pointer drag also drives the same continuous parameter")
	var identity: int = controls.get_instance_id()
	artifact.apply_grid_config({"inertia": .73})
	check(artifact._controls.get_instance_id() == identity and is_equal_approx(slider.get_normalized_value(), .73) and controls._display.label.text.contains("0.73"), "External inertia updates handle and readout without rebuilding")
	artifact._process(.2)
	await click(controls.reset_button)
	var reset_positions := true
	for i in start_particles.size(): reset_positions = reset_positions and artifact._particles[i].pos == start_particles[i].pos
	check(reset_positions and artifact.mandate == "spread" and is_equal_approx(artifact.inertia, .73), "RESET restores the seeded population and keeps the chosen rule and inertia")
	check(not controls.reset_button.is_selected(), "RESET remains momentary")
	var external := Node3D.new()
	external.name = "ExternalPlacement"
	artifact.add_child(external)
	artifact.apply_grid_config({"mandate": "ridge", "arena_size": 4.0})
	await settle()
	check(is_instance_valid(external) and artifact._controls.buttons[3].is_selected(), "Reconfiguration preserves external children and selects ridge")
	check(is_equal_approx(artifact._controls.position.z, 2.34) and artifact.get_node("ConsoleStand").position.z == artifact._controls.position.z, "Resized terrain moves console and its support together")
	check(artifact.find_children("Controls", "", false, false).size() == 1 and artifact.find_children("Caption", "", false, false).size() == 1, "Rebuild leaves one console and one caption")
	artifact.apply_grid_config({"arena_size": 3.0, "mandate": "converge", "inertia": .6})
	artifact._update_multimesh()
	await settle()
	# Same initial simulation and cameras as the before source.
	await capture_pair("after")
	# Demonstrate the live algorithm responds after control changes.
	await click(artifact._controls.buttons[3])
	for tick in 120: artifact._process(1.0 / 60.0)
	await capture_pair("ridge")
	check(artifact._particles != start_particles, "Swarm still evolves after physical rule selection")
	FileAccess.open(OUT + "checks.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "headset_tested": false, "method": "Physics hand overlap and ray hits; XR Tools pickup, grab driver and release; live artifact, state synchronization and seeded before comparison"}, "\t"))
	print("FITNESS_UI_RESULT ", checks, " checks, ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func click(button: Node3D) -> void:
	await physics_frame
	var area: Area3D = button.get_node("InteractableAreaButton")
	var at := button.to_global(Vector3(0, .024, 0))
	var normal := button.global_basis.y
	var query := PhysicsRayQueryParameters3D.create(at + normal * .25, at - normal * .04, 1 << 20)
	query.collide_with_areas = true
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == area, "Ray can reach %s through its physical casing" % button.name)
	if not hit.is_empty():
		XRToolsPointerEvent.pressed(pointer, hit.collider, hit.position)
		XRToolsPointerEvent.released(pointer, hit.collider, hit.position)
	await cap_settle()

func capture_pair(prefix: String) -> void:
	camera.position = Vector3(0, 1.65, 2.5)
	camera.fov = 90
	camera.look_at(Vector3(0, .42, .35))
	await capture(prefix + "-front")
	camera.position = Vector3(.42, 1.38, 2.52)
	camera.fov = 57
	camera.look_at(Vector3(0, .80, 1.84))
	await capture(prefix + "-close")
	camera.position = Vector3(3.9, 3.2, 4.8)
	camera.fov = 53
	camera.look_at(Vector3(0, .55, .2))
	await capture(prefix + "-overview")

func capture(tag: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + tag + ".png")
