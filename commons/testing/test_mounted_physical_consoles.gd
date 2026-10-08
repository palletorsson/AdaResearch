extends SceneTree
## Real furniture + artifact fixtures. These are not complete hall/Quest tests.
const OUT := "res://doc/reports/interfaces-2026-09-21/mounted-consoles/"
const TOKENS := ["grammar_provenance", "fitness_landscape_politics", "edge_of_chaos_unlocked"]
var checks: Array = []
var failures: Array = []
var measurements: Array = []
var world: Node3D
var camera: Camera3D
var pointer: Node3D

class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self, Vector3.ZERO, Vector3.ZERO)
		held = null

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"passed":ok, "message":message})
	if not ok: failures.append(message)
	print("MOUNT_UI ", "PASS " if ok else "FAIL ", message)
func settle() -> void:
	for frame in 5:
		await physics_frame
		await process_frame

func make_host(index: int, enabled: bool, scale_value: float = 1.0, protection: String = "none") -> Node3D:
	var host: Node3D = load("res://commons/artifacts/exhibits/exhibit_furniture.tscn").instantiate()
	host.kind = "floor_work" if index == 0 else "platform"
	host.size_class = "l"
	host.mount = TOKENS[index]
	host.floor_controls = enabled
	host.guard = protection
	host.scale = Vector3.ONE * scale_value
	world.add_child(host)
	return host

func mounted(host: Node3D) -> Node3D:
	for child in host.get_children():
		if child.has_method("exhibit_control_parts"):
			child.set_process(false)
			# Show seeded particles even while integration is frozen for measurement.
			if child.has_method("_update_multimesh"): child._update_multimesh()
			return child
	return null

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.10, .12, .15)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.94, .96, 1)
	env.environment.ambient_light_energy = .8
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-25,0)
	world.add_child(light)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = BoxShape3D.new()
	floor_shape.shape.size = Vector3(30,.1,30)
	floor_body.position.y = -.05
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	var mesh := MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	mesh.mesh.size = Vector2(30,30)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.25,.28,.31)
	mesh.material_override = mat
	world.add_child(mesh)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.current = true
	pointer = Node3D.new()
	world.add_child(pointer)
	root.msaa_3d = Viewport.MSAA_4X
	for index in 3:
		for enabled in [false, true]:
			var host := make_host(index, enabled)
			var artifact := mounted(host)
			check(artifact != null, TOKENS[index]+" loads through the registry and furniture")
			if artifact == null: host.queue_free(); await settle(); continue
			await settle()
			var console: Node3D = artifact._controls
			measurements.append({"artifact":TOKENS[index], "floor_controls":enabled, "height":console.global_position.y, "distance":console.global_position.z, "scale":console.global_basis.get_scale().x})
			if enabled:
				await inspect_station(host, artifact, index, "metre scale")
			else:
				check(not artifact.has_node("ExhibitControlMount"), "Explicit opt-out preserves the old mounting behaviour")
			await capture_pair(index, "after" if enabled else "before", artifact)
			host.queue_free()
			await settle()
		# Change a live ancestor: no re-instantiation, no per-frame mount loop.
		var host := make_host(index, true, .6)
		var artifact := mounted(host)
		await settle()
		for scale_value in [.6, 1.4]:
			host.scale = Vector3.ONE * scale_value
			host.rotation_degrees.y = 90 if scale_value < 1 else 270
			host.position = Vector3(2, .35, -1)
			await settle()
			await inspect_station(host, artifact, index, "scaled %.1f, rotated, elevated floor reference" % scale_value)
			var stable: Transform3D = artifact._controls.global_transform
			for repeat in 8: artifact.get_node("ExhibitControlMount").sync_now()
			check(artifact._controls.global_transform.is_equal_approx(stable), "Repeated mount synchronization does not drift")
			check(not artifact.get_node("ExhibitControlMount").is_processing(), "Mount adapter does not run an idle frame loop")
		# Existing live rebuilds must preserve the boundary and input restrictions.
		if index == 1:
			artifact.apply_grid_config({"arena_size":4.0})
			await settle()
			await inspect_station(host, artifact, index, "after landscape rebuild")
		elif index == 2:
			artifact.apply_grid_config({"tenure":"withheld", "comparison_study":"on"})
			await settle()
			check(artifact._controls.sliders[0] == null, "Mounted rebuild keeps the withheld handle absent")
			await inspect_station(host, artifact, index, "after withheld paired rebuild")
			artifact.apply_grid_config({"tenure":"clamped"})
			await settle()
			var grabber := TestGrabber.new()
			world.add_child(grabber)
			check(not artifact._controls.sliders[0]._handle.can_pick_up(grabber), "Mounted clamped rebuild retains the access restriction")
			grabber.queue_free()
			artifact.apply_grid_config({"tenure":"unlocked"})
			await settle()
			await inspect_station(host, artifact, index, "after unlocked paired rebuild")
		check(artifact.find_children("ExhibitControlMount", "", false, false).size() == 1, "One mount adapter survives all changes")
		host.hide()
		check(not artifact._controls.is_visible_in_tree(), "Culling furniture hides its console too")
		var console: Node3D = artifact._controls
		host.queue_free()
		await settle()
		check(not is_instance_valid(console), "Unloading furniture frees its controls")
	# Do not bypass deliberate glass/protected display restrictions.
	var guarded := make_host(2, true, 1, "hood")
	var guarded_artifact := mounted(guarded)
	await settle()
	check(not guarded_artifact.has_node("ExhibitControlMount"), "Guarded display keeps authored enclosure instead of moving controls outside")
	guarded.queue_free()
	await settle()
	var configured: Node3D = load("res://commons/artifacts/exhibits/exhibit_furniture.tscn").instantiate()
	configured.apply_grid_config({"kind":"platform", "size":"l", "mount":TOKENS[2], "floor_controls":"false"})
	world.add_child(configured)
	var configured_artifact := mounted(configured)
	check(not configured_artifact.has_node("ExhibitControlMount"), "Token configuration supports an explicit false before tree entry")
	configured.queue_free()
	await settle()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"measurements":measurements,"headset_tested":false,"scope":"Real furniture and artifact fixtures; synthetic scale/rotation/floor-reference stress cases. Not complete hall reach or Quest performance validation."},"\t"))
	print("MOUNT_UI_RESULT ",checks.size()," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func inspect_station(host: Node3D, artifact: Node3D, index: int, variant: String) -> void:
	var prefix: String = TOKENS[index]+" / "+variant+": "
	var console: Node3D = artifact._controls
	var stand: Node3D = artifact.get_node("ConsoleStand")
	var height: float = [.86,.76,.88][index]
	var front := host.global_basis.z.normalized()
	var expected_surface: Vector3 = host.to_global(Vector3(0, host._surface_y(), 0))
	check(artifact.global_position.is_equal_approx(expected_surface), prefix+"specimen stays on the furniture surface")
	check(console.global_basis.get_scale().is_equal_approx(Vector3.ONE) and stand.global_basis.get_scale().is_equal_approx(Vector3.ONE), prefix+"hardware and support keep metre scale")
	check(is_equal_approx(console.global_position.y-host.global_position.y,height), prefix+"console keeps its authored working height above the floor reference")
	check(is_equal_approx(stand.global_position.y,host.global_position.y), prefix+"stand returns to the floor reference")
	var back := INF
	# Check actual mesh extents against the furniture's conservative front lip.
	for parent in [console,stand]:
		for node in parent.find_children("*","MeshInstance3D",true,false):
			var box: AABB = node.get_aabb()
			for corner in 8:
				var p: Vector3 = node.to_global(box.get_endpoint(corner))-host.global_position
				back = minf(back,p.dot(front))
	var lip: float = (host._bed_extent()+.04)*host.global_basis.z.length()
	check(back >= lip-.001, prefix+"console casing and support clear the furniture lip")
	check(artifact.find_children("*","Label3D",true,false).is_empty(), prefix+"text remains flat on surfaces")
	for node in console.find_children("*","Node3D",true,false):
		if node.get_script() != load("res://commons/interactables/physical_stepped_slider.gd") or not node.input_enabled: continue
		var original: float = node.get_normalized_value()
		var target := .2 if index == 0 else .43
		# Speed is discrete; 3/7 maps to the fourth integration request.
		if index == 2 and node == console.sliders[1]: target = 3.0/7.0
		var grabber := TestGrabber.new()
		world.add_child(grabber)
		grabber.global_transform = node._handle.global_transform
		grabber.held = node._handle
		node._handle.pick_up(grabber)
		grabber.global_position = node._track.get_parent().to_global(Vector3(.18*target,0,0))
		await settle()
		check(is_equal_approx(node.get_normalized_value(),target), prefix+"actual grab moves "+str(node.param_name))
		var model_ok: bool = artifact.generation_depth == 2 if index == 0 else (is_equal_approx(artifact.inertia,.43) if index == 1 else (artifact.sim_steps == 4 if node == console.sliders[1] else is_equal_approx(artifact.lambda,.43)))
		check(model_ok,prefix+"grab updates the artifact model")
		grabber.drop_object()
		grabber.queue_free()
		# Pointer input after global-to-local compensation must still agree.
		var ray := PhysicsRayQueryParameters3D.create(node.to_global(Vector3(0,(target-.5)*.18,.3)),node.to_global(Vector3(0,(target-.5)*.18,-.02)),(1<<20)|(1<<22))
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty(),prefix+"pointer reaches physical rail")
		if not hit.is_empty():
			XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
			var finish: Vector3 = hit.position+node.global_basis.y*((original-target)*.18)
			XRToolsPointerEvent.moved(pointer,hit.collider,finish,hit.position)
			XRToolsPointerEvent.released(pointer,hit.collider,finish)
		await settle()
		check(is_equal_approx(node.get_normalized_value(),original),prefix+"pointer restores chosen value")
	if index == 1:
		await click(console.buttons[1])
		check(int(artifact.current_landscape) == 1,prefix+"mounted button changes the scoring rule")
		await click(console.buttons[0])
	elif index == 2:
		artifact._advance_tick()
		await click(console.buttons[0])
		check(is_zero_approx(artifact.model_time),prefix+"mounted restart button resets model time")

func click(button: Node3D) -> void:
	var at: Vector3 = button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	var normal := button.global_basis.y.normalized()
	var ray := PhysicsRayQueryParameters3D.create(at+normal*.25,at-normal*.04,1<<20)
	ray.collide_with_areas = true
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider == button.get_node("InteractableAreaButton"),"Pointer reaches mounted button "+str(button.name))
	if hit.is_empty(): return
	XRToolsPointerEvent.pressed(pointer,hit.collider,hit.position)
	XRToolsPointerEvent.released(pointer,hit.collider,hit.position)
	await settle()

func capture_pair(index: int, variant: String, artifact: Node3D) -> void:
	# Fixed matched cameras for both mounting paths, independent of their console positions.
	var name: String = ["grammar","fitness","edge"][index]
	camera.position = Vector3(3.7,2.8,5.3)
	camera.fov = 56
	camera.look_at(Vector3(0, .85, .25))
	await capture(name+"-"+variant+"-overview")
	var depth: float = [2.54,2.34,2.14][index]
	camera.position = Vector3(0,1.65,depth)
	camera.fov = 84
	camera.look_at(Vector3(0,1.0,.45))
	await capture(name+"-"+variant+"-operating")
	# A downward gaze from the same standing position: all controls in frame.
	camera.fov = 55
	camera.look_at(artifact._controls.global_position)
	await capture(name+"-"+variant+"-controls")

func capture(name: String) -> void:
	await settle()
	camera.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
