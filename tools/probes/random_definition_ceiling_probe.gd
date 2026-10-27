extends SceneTree
## Native construction check for the thirteen Random Definition instruments.

const Hardware := preload("res://commons/void/randomness_interface_hardware.gd")
var checks: Array[Dictionary] = []
var failed: Array[String] = []
var controls: Dictionary = {}
var out := "user://random-definition-ceiling"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var scene := Node3D.new()
	scene.name = "RandomDefinitionCeilingProbe"
	root.add_child(scene)
	current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true
	scene.add_child(building)
	building.content.load_floor(71)
	for frame in range(120):
		await physics_frame

	var floor_root: Node3D = building.floors[71]
	var record: Dictionary = building.content.data.floors[71]
	var expected_slab: float = building.global_position.y + float(building.spec.levels[70]) - float(building.spec.slab_thickness)
	check("Random Definition remains floor 71", str(record.map) == "Random_Definition")
	check("all thirteen original placements remain", record.artifacts.size() == 13 and record.artifacts.all(func(item): return building.content.exhibits.has("71/" + str(item.id))))
	for item in record.artifacts:
		var prefix := str(item.id) + ": "
		var mount: Node3D = building.content.exhibits["71/" + str(item.id)]
		var source: Node3D = mount.get_node("Artifact")
		var hardware: Node3D = source.get_node_or_null("ArchitecturalHardware")
		if item.id == "page": print("PAGE_BOUNDS ", source.global_position, " ", content_bounds(source,hardware))
		controls[str(item.id)] = source.find_children("InteractableAreaButton", "Area3D", true, false).map(func(node): return {
			"path": str(source.get_path_to(node)),
			"position": [node.global_position.x, node.global_position.y, node.global_position.z]
		})
		check(prefix + "retains its source identity", str(source.get_meta("artifact_lookup_name", "")) == str(item.artifact))
		check(prefix + "has an architectural carrier", hardware != null)
		if hardware == null:
			continue
		check(prefix + "has a readable two-line face", hardware.has_node("InterfaceTitle") and hardware.has_node("InterfaceAction") and hardware.has_node("InstrumentCassette") and hardware.has_node("SignalKey"))
		check(prefix + "uses the shared overhead supply", hardware.has_node("HardwareSupply"))
		var contact := hardware.get_node_or_null("PillarContact" if item.interface.style == "pillar_instrument" else "SlabContact")
		check(prefix + "has a structural fixing", contact != null)
		if contact != null and item.interface.style != "pillar_instrument":
			check(prefix + "meets the real upper slab", absf(contact.global_position.y - expected_slab) < 0.006)
		var clearance := float(item.interface.get("clearance", 0.28))
		var bounds := content_bounds(source, hardware)
		if item.id != "ride":
			check(prefix + "hangs clear of the floor", bounds.size != Vector3.ZERO and bounds.position.y >= floor_root.global_position.y + clearance - 0.012)
			check(prefix + "clears the upper slab", bounds.end.y < expected_slab - 0.06)
		var original_collisions := source.find_children("*", "CollisionObject3D", true, false).filter(func(node): return not hardware.is_ancestor_of(node))
		check(prefix + "keeps its original interaction bodies", not original_collisions.is_empty())
		Hardware.attach(source, item.interface)
		check(prefix + "cannot duplicate its carrier", source.get_node("ArchitecturalHardware") == hardware)

	var report := {
		"passed": failed.is_empty(),
		"checks": checks,
		"failed": failed,
		"controls": controls,
		"scope": "Native floor 71 construction and source interaction-body retention. No physical headset test."
	}
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("RANDOM_DEFINITION_CEILING_RESULT ", checks.size(), " checks; failures: ", failed)
	building.queue_free()
	await process_frame
	quit(0 if failed.is_empty() else 1)

func content_bounds(source: Node3D, hardware: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for node in source.find_children("*", "GeometryInstance3D", true, false):
		if hardware.is_ancestor_of(node) or inside_private_viewport(node, source) or node.find_parent("ArchitecturalHardware") != null:
			continue
		var local := AABB()
		if node is MeshInstance3D and node.mesh != null:
			local = node.mesh.get_aabb()
		elif node is MultiMeshInstance3D and node.multimesh != null:
			local = node.multimesh.get_aabb()
		if local.size == Vector3.ZERO:
			continue
		var world: AABB = node.global_transform * local
		result = world if first else result.merge(world)
		first = false
	return result

func inside_private_viewport(node: Node, source: Node3D) -> bool:
	var parent := node.get_parent()
	while parent != null and parent != source:
		if parent is Viewport:
			return true
		parent = parent.get_parent()
	return false

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed:
		failed.append(label)
