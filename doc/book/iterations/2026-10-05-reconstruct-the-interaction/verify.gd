extends SceneTree
## Isolated engine checks. A synthetic controller drives the real XR Tools pickup
## library; no hardware input, museum integration or headset comfort is tested.

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks.append({"passed": ok, "description": description})
	if not ok:
		failures.append(description)

func frames(count: int = 6) -> void:
	for index in count:
		await physics_frame
		await process_frame

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	for case in [{"path": "res://point.gd", "radius": 0.07},
			{"path": "res://point_radius_variant.gd", "radius": 0.14}]:
		await verify_case(case)
	var report := {
		"passed": failures.is_empty(),
		"scope": "Native Godot; real XRToolsPickable and XRToolsFunctionPickup; synthetic XRController3D moved by code. Actual Area3D overlap, library pickup, driver motion and release. No headset or museum playthrough.",
		"checks": checks,
		"failures": failures,
	}
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("POINT RECONSTRUCTION: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func verify_case(case: Dictionary) -> void:
	var label: String = "radius %.2f: " % float(case["radius"])
	# Load at runtime after autoload initialization, as other XR Tools probes do.
	var lesson: Node3D = load(case["path"]).new()
	world.add_child(lesson)
	var body: RigidBody3D = lesson.point
	check(body != null and body.has_method("pick_up"), label + "constructed a real pickable body")
	check(body.get_child_count() == 2, label + "only the visible mesh and collider are required")
	var surface: MeshInstance3D
	var collider: CollisionShape3D
	for child in body.get_children():
		if child is MeshInstance3D:
			surface = child
		if child is CollisionShape3D:
			collider = child
	var radius: float = case["radius"]
	check(surface != null and surface.mesh is SphereMesh and is_equal_approx(surface.mesh.radius, radius) and is_equal_approx(surface.mesh.height, radius * 2.0), label + "mesh dimensions follow RADIUS")
	check(collider != null and collider.shape is SphereShape3D and is_equal_approx(collider.shape.radius, radius), label + "collider follows the same RADIUS")
	check(body.original_collision_layer == 4 and body.original_collision_mask == 196615, label + "ready cached the configured layers")
	check(body.freeze and not body.can_ranged_grab, label + "starts frozen and requires a near grab")

	var controller := XRController3D.new()
	controller.position = body.global_position + Vector3(0.8, 0, 0)
	world.add_child(controller)
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	pickup.hand_offset_mode = 4 # Disable automatic offset for the synthetic fixture.
	pickup.ranged_enable = false
	controller.add_child(pickup)
	await frames()
	check(not pickup._object_in_grab_area.has(body), label + "outside the real grab detector")
	controller.position = body.global_position
	await frames()
	pickup._update_closest_object()
	check(pickup._object_in_grab_area.has(body) and pickup.closest_object == body, label + "actual overlap makes the sphere eligible")
	body.enabled = false
	pickup._update_closest_object()
	check(not body.can_pick_up(pickup) and pickup.closest_object == null, label + "disabled body cannot be selected")
	body.enabled = true
	pickup._update_closest_object()
	# Invoke the real library at its pickup boundary, bypassing only hardware input.
	pickup._pick_up_object(pickup.closest_object)
	check(body.is_picked_up() and pickup.picked_up_object == body, label + "library pickup holds the sphere")
	check(body.collision_layer == 65536 and body.collision_mask == 0, label + "held body uses the XR Tools held layer")
	var old_position: Vector3 = body.global_position
	var movement := Vector3(0.4, 0.2, -0.3)
	controller.position += movement
	await frames()
	check(body.global_position.is_equal_approx(old_position + movement), label + "real grab driver follows controller movement")
	pickup.drop_object()
	await frames()
	check(not body.is_picked_up() and pickup.picked_up_object == null, label + "library release clears the grab")
	check(body.freeze and body.collision_layer == 4 and body.collision_mask == 196615, label + "release freezes and restores configured layers")
	var released_position: Vector3 = body.global_position
	controller.position += Vector3(1.0, 0.3, 0)
	await frames(12)
	check(body.global_position.is_equal_approx(released_position), label + "released sphere stays where it was left")
	controller.queue_free()
	lesson.queue_free()
	await frames(2)
