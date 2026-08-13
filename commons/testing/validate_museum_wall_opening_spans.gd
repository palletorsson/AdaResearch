# validate_museum_wall_opening_spans.gd
# Direct smoke/contract test for the window, vitrine, and portal helper.

extends SceneTree

const OPENINGS := preload("res://commons/artifacts/museum/museum_wall_opening_spans.gd")


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
			print("MUSEUM_OPENING_SPAN_METRICS %s_%dm meshes=%d batches=%d batch_instances=%d tris_lod0=%d collisions=%d hooks=%d" % [
				kind, cells, int(metrics["mesh_instances"]), int(metrics["multimesh_draws"]),
				int(metrics["multimesh_instances"]), int(metrics["estimated_triangles_lod0"]),
				int(metrics["collision_shapes"]), int(metrics["interaction_areas"]),
			])
			if not is_equal_approx(float(contract["width_m"]), float(cells)):
				failures.append("%s_%dm width contract drift" % [kind, cells])
			if float(contract["construction_depth_m"]) <= 0.15:
				failures.append("%s_%dm lacks construction depth" % [kind, cells])
			if int(metrics["mesh_instances"]) < 12:
				failures.append("%s_%dm detail build unexpectedly thin" % [kind, cells])
			if int(metrics["multimesh_draws"]) < 2:
				failures.append("%s_%dm hardware was not batched" % [kind, cells])
			if int(metrics["collision_shapes"]) != (3 if kind == &"portal" else 5):
				failures.append("%s_%dm collision truth mismatch" % [kind, cells])
			if int(metrics["interaction_areas"]) != 1:
				failures.append("%s_%dm interaction hook missing" % [kind, cells])
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
			elif str(assembly.get_meta("interaction", "")) != "walkthrough":
				failures.append("portal_%dm lacks walkthrough interaction" % cells)
			elif assembly.find_child("PortalContinuationLight", true, false) == null or assembly.find_child("PortalRouteRails", true, false) == null:
				failures.append("portal_%dm lacks continuation construction" % cells)
			else:
				var threshold := assembly.find_child("PortalFlushThreshold", true, false) as MeshInstance3D
				var threshold_top := (threshold.global_transform * threshold.get_aabb()).end.y if threshold != null else 99.0
				if threshold_top > 0.012 or absf(threshold_top - float(assembly.get_meta("accessible_threshold_m", -1.0))) > 0.005:
					failures.append("portal_%dm threshold exceeds accessible contract" % cells)
			if int(metrics.get("profile_mesh_instances", 0)) < 4:
				failures.append("%s_%dm lacks chamfered primary profiles" % [kind, cells])
			if assembly.has_method("_process"):
				failures.append("%s_%dm unexpectedly owns a process callback" % [kind, cells])
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

	for failure in failures:
		push_error("MUSEUM_OPENING_SPAN_FAIL: %s" % failure)
	print("MUSEUM_OPENING_SPAN_VARIANTS=9")
	print("MUSEUM_OPENING_SPAN_SHARED_MESH=%s" % (first_box_mesh != null))
	print("MUSEUM_OPENING_SPAN_GLASS_SHADER_SHARED=%s" % ((palette["glass_inner"] as ShaderMaterial).shader == shared_glass_shader))
	print("MUSEUM_OPENING_SPAN_INSTANCE_UNIFORMS=false")
	print("MUSEUM_OPENING_SPAN_CERTIFIED=%s" % failures.is_empty())
	quit(0 if failures.is_empty() else 1)


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


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result
