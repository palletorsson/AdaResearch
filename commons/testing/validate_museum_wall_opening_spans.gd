# validate_museum_wall_opening_spans.gd
# Direct smoke/contract test for the window, vitrine, and portal helper.

extends SceneTree

const OPENINGS := preload("res://commons/artifacts/museum/museum_wall_opening_spans.gd")

const EXPECTED_SURFACES := {
	"stone": {"friction": 0.82, "bounce": 0.02, "impact": "stone_dense", "decal": "mineral_chip", "breakability": "none"},
	"bronze": {"friction": 0.48, "bounce": 0.04, "impact": "metal_resonant", "decal": "metal_scuff", "breakability": "none"},
	"painted_metal": {"friction": 0.55, "bounce": 0.03, "impact": "metal_hollow", "decal": "paint_chip", "breakability": "service_only"},
	"glass_laminated": {"friction": 0.22, "bounce": 0.06, "impact": "glass_laminated", "decal": "glass_mark", "breakability": "authored_only"},
	"rubber": {"friction": 0.9, "bounce": 0.12, "impact": "rubber_soft", "decal": "none", "breakability": "none"},
}

const EXPECTED_COLLISION_SHAPES := {
	"window": {"stone": 4, "painted_metal": 8, "glass_laminated": 1, "rubber": 4},
	"vitrine": {"stone": 5, "bronze": 5, "glass_laminated": 2, "rubber": 4},
	"portal": {"stone": 3, "bronze": 3, "rubber": 3},
}

const EXPECTED_COLLISION_BODIES := {"window": 4, "vitrine": 4, "portal": 3}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: PackedStringArray = []
	var palette: Dictionary = OPENINGS.default_palette("uffizi_stone")
	var first_box_mesh: Mesh = null
	var shared_glass_shader: Shader = (palette["glass"] as ShaderMaterial).shader
	var glass_tint: Color = (palette["glass"] as ShaderMaterial).get_shader_parameter("base_tint")
	if glass_tint.a > 0.025 or glass_tint.r < 0.9 or glass_tint.b - glass_tint.r > 0.08:
		failures.append("fallback glass is not neutral, low-opacity transmission")
	if (palette["glass_inner"] as ShaderMaterial).shader != shared_glass_shader or (palette["glass_edge"] as ShaderMaterial).shader != shared_glass_shader:
		failures.append("glass layers duplicate shader resources")
	if shared_glass_shader.code.contains("instance uniform"):
		failures.append("glass shader consumes instance-uniform buffer")
	for kind in [&"window", &"vitrine", &"portal"]:
		for cells in range(2, 5):
			var host := Node3D.new()
			host.name = "%s_%dm_TestHost" % [str(kind), cells]
			root.add_child(host)
			var result: Dictionary = OPENINGS.build(host, kind, cells, 4.0, palette, {
				"enable_collision": true,
				"enable_interaction_hooks": true,
				"seed": 7000 + cells,
			})
			if not bool(result.get("ok", false)):
				failures.append("%s_%dm failed to build" % [kind, cells])
				continue
			var assembly: Node3D = result["assembly"]
			var contract: Dictionary = result["contract"]
			var metrics: Dictionary = result["metrics"]
			print("MUSEUM_OPENING_SPAN_METRICS %s_%dm meshes=%d batches=%d batch_instances=%d tris_lod0=%d bodies=%d collisions=%d hooks=%d zones=%s" % [
				kind, cells, int(metrics["mesh_instances"]), int(metrics["multimesh_draws"]),
				int(metrics["multimesh_instances"]), int(metrics["estimated_triangles_lod0"]),
				int(metrics["collision_bodies"]), int(metrics["collision_shapes"]), int(metrics["interaction_areas"]),
				JSON.stringify(metrics["collision_shapes_by_surface"]),
			])
			if not is_equal_approx(float(contract["width_m"]), float(cells)):
				failures.append("%s_%dm width contract drift" % [kind, cells])
			if float(contract["construction_depth_m"]) <= 0.15:
				failures.append("%s_%dm lacks construction depth" % [kind, cells])
			if int(metrics["mesh_instances"]) < 12:
				failures.append("%s_%dm detail build unexpectedly thin" % [kind, cells])
			if int(metrics["multimesh_draws"]) < 2:
				failures.append("%s_%dm hardware was not batched" % [kind, cells])
			var expected_shapes: Dictionary = EXPECTED_COLLISION_SHAPES[str(kind)]
			var expected_shape_total := 0
			for surface_value in expected_shapes.values():
				expected_shape_total += int(surface_value)
			if int(metrics["collision_bodies"]) != int(EXPECTED_COLLISION_BODIES[str(kind)]) or int(metrics["collision_shapes"]) != expected_shape_total:
				failures.append("%s_%dm collision body/shape count mismatch" % [kind, cells])
			if not _same_int_dictionary(metrics["collision_shapes_by_surface"], expected_shapes):
				failures.append("%s_%dm collision surface manifest mismatch %s" % [kind, cells, JSON.stringify(metrics["collision_shapes_by_surface"])])
			for body in _static_bodies(assembly):
				var surface_id := str(body.get_meta("physics_surface_id", ""))
				var expected_surface: Dictionary = EXPECTED_SURFACES.get(surface_id, {})
				if expected_surface.is_empty():
					failures.append("%s_%dm body %s has unknown surface %s" % [kind, cells, body.name, surface_id])
					continue
				var physics := body.physics_material_override
				if physics == null or absf(physics.friction - float(expected_surface["friction"])) > 0.001 or absf(physics.bounce - float(expected_surface["bounce"])) > 0.001:
					failures.append("%s_%dm body %s physics differs from %s contract" % [kind, cells, body.name, surface_id])
				for tag in ["impact", "decal", "breakability"]:
					if str(body.get_meta(tag, "")) != str(expected_surface[tag]):
						failures.append("%s_%dm body %s %s tag differs from contract" % [kind, cells, body.name, tag])
			if int(metrics["interaction_areas"]) != 1:
				failures.append("%s_%dm interaction hook missing" % [kind, cells])
			_audit_visual_collision_roles(assembly, "%s_%dm" % [kind, cells], failures)
			_audit_collision_ownership(assembly, "%s_%dm" % [kind, cells], failures)
			if bool(assembly.get_meta("instance_uniforms_used", true)):
				failures.append("%s_%dm declares instance-uniform use" % [kind, cells])
			if int(metrics.get("tertiary_elements", 0)) < 10:
				failures.append("%s_%dm lacks family-specific tertiary construction" % [kind, cells])
			var max_meshes := 56 if kind == &"vitrine" else (53 if kind == &"window" else 30)
			if int(metrics["mesh_instances"]) > max_meshes or int(metrics["multimesh_draws"]) > 5 or int(metrics["estimated_triangles_lod0"]) > 3200:
				failures.append("%s_%dm exceeds Quest-aware helper budget" % [kind, cells])
			var bounds_x := _geometry_bounds_x(assembly)
			if bounds_x.x < -float(cells) * 0.5 - 0.0005 or bounds_x.y > float(cells) * 0.5 + 0.0005:
				failures.append("%s_%dm visible envelope exceeds exact width: %s" % [kind, cells, bounds_x])
			if kind == &"portal" and Vector2(contract["clear_opening_m"]).x < 1.2:
				failures.append("portal_%dm clear width below accessibility minimum" % cells)
			if kind != &"portal":
				var glass_body := assembly.get_node_or_null("%sGlassCollision" % str(kind).capitalize()) as StaticBody3D
				if glass_body == null or str(glass_body.get_meta("surface_type", "")) != "laminated_glass":
					failures.append("%s_%dm lacks distinct laminated glass surface" % [kind, cells])
				elif str(glass_body.get_meta("surface_id", "")) != "glass_laminated" or str(glass_body.get_meta("physics_surface_id", "")) != "glass_laminated":
					failures.append("%s_%dm glass surface id is not canonical" % [kind, cells])
				else:
					var physics := glass_body.physics_material_override
					if physics == null or absf(physics.friction - 0.22) > 0.001 or absf(physics.bounce - 0.06) > 0.001:
						failures.append("%s_%dm glass physics differs from contract" % [kind, cells])
					var visible_name := "WindowOuterLamination" if kind == &"window" else "VitrineLaminatedDoor"
					var visible := assembly.find_child(visible_name, true, false) as MeshInstance3D
					var shape := _first_collision_shape(glass_body)
					if visible == null or shape == null or not shape.shape is BoxShape3D:
						failures.append("%s_%dm glass visual/collision thickness unavailable" % [kind, cells])
					else:
						var visible_thickness := (visible.global_transform * visible.get_aabb()).size.z
						var collision_thickness := (shape.shape as BoxShape3D).size.z
						if absf(visible_thickness - collision_thickness) > 0.004 or visible_thickness < 0.008 or visible_thickness > 0.03:
							failures.append("%s_%dm glass thickness mismatch %.4f/%.4f" % [kind, cells, visible_thickness, collision_thickness])
				var residue_count := int(metrics.get("glass_residue_instances", 0))
				if residue_count < 4 or residue_count > 5 or assembly.find_child("*FingerprintResidue", true, false) == null:
					failures.append("%s_%dm residue pool count invalid" % [kind, cells])
				if kind == &"window" and (assembly.find_child("WindowGlazingSettingBlocks", true, false) == null or assembly.find_child("WindowPaintedMetalCollision", true, false) == null or assembly.find_child("WindowRubberCollision", true, false) == null):
					failures.append("window_%dm lacks setting-block or material-zone construction" % cells)
				if kind == &"vitrine" and (assembly.find_child("VitrineBaseGlassShelf", true, false) == null or assembly.find_child("VitrineDoorMeetingStile", true, false) == null or assembly.find_child("VitrineBronzeCollision", true, false) == null):
					failures.append("vitrine_%dm lacks base shelf, meeting stile, or bronze collision route" % cells)
			elif str(assembly.get_meta("interaction", "")) != "walkthrough":
				failures.append("portal_%dm lacks walkthrough interaction" % cells)
			elif assembly.find_child("PortalContinuationLight", true, false) == null or assembly.find_child("PortalRouteRails", true, false) == null:
				failures.append("portal_%dm lacks continuation construction" % cells)
			else:
				if assembly.find_child("PortalExitDirectionGlyph", true, false) == null or assembly.find_child("PortalBronzeCollision", true, false) == null or assembly.find_child("PortalRubberCollision", true, false) == null:
					failures.append("portal_%dm lacks directional sign or material-zone collision" % cells)
				var threshold := assembly.find_child("PortalFlushThreshold", true, false) as MeshInstance3D
				var threshold_top := (threshold.global_transform * threshold.get_aabb()).end.y if threshold != null else 99.0
				if threshold_top > 0.012 or absf(threshold_top - float(assembly.get_meta("accessible_threshold_m", -1.0))) > 0.005:
					failures.append("portal_%dm threshold exceeds accessible contract" % cells)
			if int(metrics.get("profile_mesh_instances", 0)) < 4:
				failures.append("%s_%dm lacks chamfered primary profiles" % [kind, cells])
			if assembly.has_method("_process"):
				failures.append("%s_%dm unexpectedly owns a process callback" % [kind, cells])
			var baseline_signature := _collision_signature(assembly, false)
			var baseline_resource_signature := _collision_signature(assembly, true)
			for lod in [1, 2]:
				var replica_host := Node3D.new()
				replica_host.name = "%s_%dm_L%d_ReplicaHost" % [str(kind), cells, lod]
				root.add_child(replica_host)
				var replica_result: Dictionary = OPENINGS.build(replica_host, kind, cells, 4.0, palette, {
					"enable_collision": true,
					"enable_interaction_hooks": true,
					"detail_tier": lod,
					"seed": 9700 + lod * 100 + cells,
				})
				var replica := replica_result.get("assembly") as Node3D
				if replica == null or _collision_signature(replica, false) != baseline_signature:
					failures.append("%s_%dm L%d changed collision behavior signature" % [kind, cells, lod])
				elif _collision_signature(replica, true) != baseline_resource_signature:
					failures.append("%s_%dm L%d allocated different collision resources after warmup" % [kind, cells, lod])
				replica_host.queue_free()
				await process_frame
			if kind == &"portal":
				await physics_frame
				_audit_portal_sweeps(assembly, Vector2(contract["clear_opening_m"]), cells, failures)
			var box := _first_box(assembly)
			if box == null:
				failures.append("%s_%dm contains no coarse mesh" % [kind, cells])
			elif first_box_mesh == null:
				first_box_mesh = box.mesh
			elif box.mesh != first_box_mesh:
				failures.append("%s_%dm did not share the unit box mesh" % [kind, cells])
			host.queue_free()
			await process_frame

	var cached_again: Dictionary = OPENINGS.default_palette("uffizi_stone")
	if palette["stone"] != cached_again["stone"] or palette["bronze"] != cached_again["bronze"]:
		failures.append("fallback palette resources were duplicated")
	var cache: Dictionary = OPENINGS.cache_report()
	if not bool(cache.get("unit_box_ready", false)) or not bool(cache.get("glass_shader_ready", false)) or int(cache.get("palette_count", 0)) != 1:
		failures.append("shared resource cache telemetry is incomplete: %s" % JSON.stringify(cache))
	var physics_ready: Dictionary = cache.get("surface_physics_ready", {})
	for surface_id in EXPECTED_SURFACES:
		if not bool(physics_ready.get(surface_id, false)):
			failures.append("surface physics cache did not initialize %s" % surface_id)

	for failure in failures:
		push_error("MUSEUM_OPENING_SPAN_FAIL: %s" % failure)
	print("MUSEUM_OPENING_SPAN_VARIANTS=9")
	print("MUSEUM_OPENING_SPAN_SHARED_MESH=%s" % (first_box_mesh != null))
	print("MUSEUM_OPENING_SPAN_GLASS_SHADER_SHARED=%s" % ((palette["glass_inner"] as ShaderMaterial).shader == shared_glass_shader))
	print("MUSEUM_OPENING_SPAN_INSTANCE_UNIFORMS=false")
	print("MUSEUM_OPENING_SPAN_CACHE=%s" % JSON.stringify(cache))
	print("MUSEUM_OPENING_SPAN_CERTIFIED=%s" % failures.is_empty())
	quit(0 if failures.is_empty() else 1)


func _same_int_dictionary(actual_value: Variant, expected: Dictionary) -> bool:
	if not actual_value is Dictionary:
		return false
	var actual: Dictionary = actual_value
	if actual.size() != expected.size():
		return false
	for key in expected:
		if int(actual.get(key, -1)) != int(expected[key]):
			return false
	return true


func _static_bodies(node: Node) -> Array[StaticBody3D]:
	var result: Array[StaticBody3D] = []
	for child in _all_descendants(node):
		if child is StaticBody3D:
			result.append(child as StaticBody3D)
	return result


func _first_box(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_box(child)
		if found != null:
			return found
	return null


func _first_collision_shape(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node as CollisionShape3D
	for child in node.get_children():
		var found := _first_collision_shape(child)
		if found != null:
			return found
	return null


func _geometry_bounds_x(node: Node) -> Vector2:
	var min_x := INF
	var max_x := -INF
	for child in _all_descendants(node):
		var bounds := AABB()
		var has_bounds := false
		if child is MeshInstance3D:
			bounds = (child as MeshInstance3D).global_transform * (child as MeshInstance3D).get_aabb()
			has_bounds = true
		elif child is MultiMeshInstance3D:
			bounds = (child as MultiMeshInstance3D).global_transform * (child as MultiMeshInstance3D).get_aabb()
			has_bounds = true
		if has_bounds:
			min_x = minf(min_x, bounds.position.x)
			max_x = maxf(max_x, bounds.end.x)
	return Vector2(min_x, max_x)


func _audit_visual_collision_roles(assembly: Node3D, label: String, failures: PackedStringArray) -> void:
	var solid_count := 0
	for child in _all_descendants(assembly):
		if not child is MeshInstance3D:
			continue
		var mesh_instance := child as MeshInstance3D
		var role := str(mesh_instance.get_meta("collision_role", ""))
		var surface_id := str(mesh_instance.get_meta("physics_surface_id", ""))
		var target := str(mesh_instance.get_meta("collision_target", ""))
		if role == "visual_only":
			if surface_id != "" or target != "":
				failures.append("%s mesh %s visual_only role retains solid metadata" % [label, mesh_instance.name])
			continue
		if role != "solid":
			failures.append("%s mesh %s has missing/unknown collision_role '%s'" % [label, mesh_instance.name, role])
			continue
		if not EXPECTED_SURFACES.has(surface_id) or target == "":
			failures.append("%s solid mesh %s has invalid surface/target" % [label, mesh_instance.name])
			continue
		var body := assembly.find_child(target, true, false) as StaticBody3D
		if body == null or str(body.get_meta("physics_surface_id", "")) != surface_id:
			failures.append("%s solid mesh %s target %s does not own surface %s" % [label, mesh_instance.name, target, surface_id])
			continue
		solid_count += 1
	if solid_count == 0:
		failures.append("%s declares no solid visual/collision ownership" % label)


func _audit_collision_ownership(assembly: Node3D, label: String, failures: PackedStringArray) -> void:
	for child in _all_descendants(assembly):
		if not child is CollisionShape3D:
			continue
		var collision := child as CollisionShape3D
		var owner := collision.get_parent()
		if collision.disabled or collision.shape == null:
			failures.append("%s contains disabled or empty collider %s" % [label, collision.name])
		elif owner is StaticBody3D:
			if not bool(owner.get_meta("blocks_motion", false)) or not EXPECTED_SURFACES.has(str(owner.get_meta("physics_surface_id", ""))):
				failures.append("%s collider %s has undeclared solid ownership" % [label, collision.name])
		elif owner is Area3D:
			if str(owner.get_meta("interaction", "")) == "":
				failures.append("%s Area3D collider %s lacks an interaction contract" % [label, collision.name])
		else:
			failures.append("%s collider %s has unsupported owner %s" % [label, collision.name, owner.get_class() if owner != null else "null"])
		var lower := "%s/%s" % [str(owner.name).to_lower() if owner != null else "", str(collision.name).to_lower()]
		if lower.contains("hidden") or lower.contains("diagnostic") or lower.contains("test"):
			failures.append("%s contains hidden/diagnostic collider %s" % [label, lower])


func _audit_portal_sweeps(assembly: Node3D, clear: Vector2, cells: int, failures: PackedStringArray) -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = 0.1
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	for spec in [[sphere, 1.2, "hand"], [capsule, 0.9, "player"]]:
		for from_z in [-1.0, 1.0]:
			var motion := Vector3(0, 0, -from_z * 2.0)
			if _cast_motion_hit(assembly, spec[0] as Shape3D, Vector3(0, float(spec[1]), from_z), motion):
				failures.append("portal_%dm %s clear-path sweep hit structure" % [cells, str(spec[2])])
			var edge_x := clear.x * 0.5 + 0.13
			if not _cast_motion_hit(assembly, spec[0] as Shape3D, Vector3(edge_x, float(spec[1]), from_z), motion):
				failures.append("portal_%dm %s edge-path sweep missed structure" % [cells, str(spec[2])])


func _cast_motion_hit(assembly: Node3D, shape: Shape3D, origin: Vector3, motion: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, origin)
	query.motion = motion
	query.margin = 0.0005
	query.collision_mask = 0x7FFFFFFF
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var fractions := assembly.get_world_3d().direct_space_state.cast_motion(query)
	return fractions.size() >= 2 and float(fractions[0]) < 0.999999


func _collision_signature(node: Node, include_rids: bool) -> String:
	var records: Array[Dictionary] = []
	for child in _all_descendants(node):
		if not child is CollisionShape3D:
			continue
		var collision := child as CollisionShape3D
		if collision.shape == null:
			continue
		var owner := collision.get_parent()
		var record := {
			"owner": str(owner.name),
			"owner_type": owner.get_class(),
			"shape": str(collision.name),
			"shape_type": collision.shape.get_class(),
			"transform": str(collision.transform),
			"size": str((collision.shape as BoxShape3D).size) if collision.shape is BoxShape3D else "",
		}
		if include_rids:
			record["rid"] = collision.shape.get_rid().get_id()
		records.append(record)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return JSON.stringify(a) < JSON.stringify(b))
	return JSON.stringify(records)


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result
