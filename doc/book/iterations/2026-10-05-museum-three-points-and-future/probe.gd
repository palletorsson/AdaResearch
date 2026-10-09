extends "res://tools/probes/transformation_encounters.gd"
## Production museum placement and render checks. No headset acceptance claim.

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.5).timeout
	await identity_checks()
	if map_id == "Point_One": await point_checks()

func identity_checks() -> void:
	var signs: Array[Node3D] = []
	for node in hall.find_children("*", "Node3D", true, false):
		if bool(node.get_meta("em_museum_identity", false)): signs.append(node)
	check("one shared wall identity in this hall", signs.size() == 1)
	if signs.size() != 1: return
	var sign: Node3D = signs[0]
	var title := sign.get_node_or_null("Title") as Label3D
	var tagline := sign.get_node_or_null("Tagline") as Label3D
	check("identity has both requested labels", title != null and tagline != null)
	if title == null or tagline == null: return
	check("wall title is ENDLESS MUSEUM", title.text == "ENDLESS MUSEUM")
	check("wall subtitle is always another room", tagline.text == "always another room")
	check("shared identity has no collision objects", sign.find_children("*", "CollisionObject3D", true, false).is_empty())
	var face: Font = title.font.base_font if title.font is FontVariation else title.font
	check("lettering uses a bundled font", face != null and face.resource_path.begins_with("res://commons/font/"))
	check("wall face can contain the lettering", float(sign.get_meta("wall_width", 0.0)) >= 3.0)
	var normal: Vector3 = sign.get_meta("wall_normal", Vector3.ZERO)
	check("identity records a unit wall normal", is_equal_approx(normal.length(), 1.0))
	if normal.length() < 0.5: return
	check("lettering faces into the room", title.global_basis.z.normalized().dot(normal) > 0.999)
	var ray := PhysicsRayQueryParameters3D.create(title.global_position + normal * 0.25, title.global_position - normal * 0.16, 1)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check("lettering has a real wall immediately behind it", not hit.is_empty() and title.global_position.distance_to(hit.position) < 0.08)
	observations["identity"] = {"position": xyz(sign.global_position), "wall_normal": xyz(normal), "wall_width": sign.get_meta("wall_width", 0.0), "font": face.resource_path}
	var approach := sign.global_position + normal * 3.6
	approach.y = hall.global_position.y
	check("identity can be approached on the hall floor", not floor_at(approach).is_empty())
	for label in [title, tagline]:
		var sight := PhysicsRayQueryParameters3D.create(approach + Vector3.UP * 1.7, label.global_position, 1)
		var obstruction := hall.get_world_3d().direct_space_state.intersect_ray(sight)
		check(str(label.name) + " is visible from supported visitor approach", obstruction.is_empty() or label.global_position.distance_to(obstruction.position) < 0.04)
		if not obstruction.is_empty(): observations[str(label.name) + "_sight_hit"] = {"position": xyz(obstruction.position), "collider": str(obstruction.collider.get_path())}
	await snapshot("museum-lettering", approach + Vector3.UP * 1.7, sign.global_position + Vector3.UP * 0.05, 63)

func point_checks() -> void:
	var points := {}
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/point_condition.gd"):
			points[node.condition] = node
	check("four authored point conditions loaded", points.size() == 4 and points.has("absent") and points.has("visible") and points.has("solid") and points.has("pedestal"))
	if points.size() != 4 or not points.has("pedestal"): return
	var plinths := hall.find_children("PointPlinth", "MeshInstance3D", true, false)
	check("corridor contains exactly three PointPlinths", plinths.size() == 3)
	for kind in ["absent", "visible", "solid"]:
		var station: Node3D = points[kind]
		var plinth := station.get_node_or_null("PointPlinth") as MeshInstance3D
		check(kind + " point has its own off-white podium", plinth != null and plinth.material_override.albedo_color.r > 0.85)
		check(kind + " point keeps its label", station.get_node("PointOneLabel").text == "Point one")
	check("first podium remains empty", points.absent.point == null)
	check("two white points retain matching radius", is_equal_approx(points.visible.point.mesh.radius, 0.14) and is_equal_approx(points.solid.point.mesh.radius, 0.14))
	check("white point remains visually white", points.visible.point.material_override.albedo_color.r > 0.9)
	for kind in ["visible", "solid"]:
		var centre: Vector3 = points[kind].point.global_position
		var sphere_ray := PhysicsRayQueryParameters3D.create(centre + Vector3(0,0,-0.4), centre + Vector3(0,0,0.4), 1)
		var sphere_hit := hall.get_world_3d().direct_space_state.intersect_ray(sphere_ray)
		check(kind + " sphere preserves its collision condition", sphere_hit.is_empty() if kind == "visible" else not sphere_hit.is_empty())
	var future: MeshInstance3D = points.pedestal.point
	var finish: StandardMaterial3D = future.material_override
	check("future sphere remains 1.3 metres in diameter", is_equal_approx(future.mesh.radius * 2.0, 1.3))
	check("future sphere is black and glossy", finish.albedo_color.r < 0.02 and finish.albedo_color.g < 0.02 and finish.albedo_color.b < 0.02 and finish.roughness < 0.1 and finish.clearcoat_enabled)
	check("future sphere retains physical boundary", points.pedestal.get_node_or_null("PointCollision") != null)
	check("corridor door retained", find_scene("/point_corridor_door.gd") != null)
	var sun_switch := find_scene("/point_sun_switch.gd")
	check("point sun switch retained", sun_switch != null)
	if sun_switch != null:
		check("plinths stay in the normal museum lighting", plinths.all(func(p): return (p.layers & sun_switch.STUDY_LAYER) == 0))
		var pointer := Node3D.new()
		root.add_child(pointer)
		var at: Vector3 = sun_switch.button.global_position
		XRToolsPointerEvent.pressed(pointer, sun_switch.button, at)
		XRToolsPointerEvent.released(pointer, sun_switch.button, at)
		await tick()
		check("sun switch still removes its directional light", not sun_switch.enabled and not sun_switch.sun.visible)
		check("removing sun keeps both point surfaces and solid boundary", points.visible.point.visible and points.solid.point.visible and points.solid.get_node("PointCollision").collision_layer == 1)
		XRToolsPointerEvent.pressed(pointer, sun_switch.button, at)
		XRToolsPointerEvent.released(pointer, sun_switch.button, at)
		await tick()
		check("sun switch restores the directional light", sun_switch.enabled and sun_switch.sun.visible)
		pointer.queue_free()
	var lane_a: Vector3 = points.absent.global_position + Vector3(1.4,0,0)
	var lane_b: Vector3 = points.solid.global_position + Vector3(1.4,0,0)
	check("walkway beside first and last podium has floor", not floor_at(lane_a).is_empty() and not floor_at(lane_b).is_empty())
	var lane_ray := PhysicsRayQueryParameters3D.create(lane_a + Vector3.UP, lane_b + Vector3.UP, 1)
	check("three podiums leave the corridor walking lane open", hall.get_world_3d().direct_space_state.intersect_ray(lane_ray).is_empty())
	observations["points"] = {}
	for kind in points: observations["points"][kind] = xyz(points[kind].global_position)
	await snapshot("three-podiums", points.absent.global_position + Vector3(2.7,1.9,-1.15), points.visible.global_position + Vector3(0,0.78,-1.4), 74)
	await snapshot("future-sphere", points.pedestal.global_position + Vector3(1.5,1.65,-2.9), points.pedestal.global_position + Vector3(0,1.10,0), 55)

func finish() -> void:
	var result := {"room": map_id, "checks": checks, "failures": failures, "observations": observations, "passed": failures.is_empty(),
		"scope": "Real Endless Museum scenes; object geometry/materials, wall lettering and camera captures. No headset playtest or learner acceptance claimed."}
	FileAccess.open(folder + "report.json", FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	print("MUSEUM IDENTITY ", map_id, " ", checks.size() - failures.size(), "/", checks.size())
	quit(0 if failures.is_empty() else 1)
