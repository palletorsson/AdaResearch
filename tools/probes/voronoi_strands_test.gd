extends SceneTree

var failures: Array[String] = []
var checks := 0
var dynamics_observations: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks += 1
	if not passed:
		failures.append(label)
		push_error(label)

func run() -> void:
	var preview = load("res://commons/context/cellular_spaces/voronoi_strands_preview.tscn").instantiate()
	root.add_child(preview)
	preview.walker.set_physics_process(false)
	var web = preview.web
	if web.generation_count == 0:
		await web.network_built
	check("requested seeded 3D sites", web.sites.size() == 150 and web.tetrahedra.size() > 100)
	check("volumetric edge skeleton", web.edges.size() > 200 and web.anchor_kinds.size() == 36)
	check("four batches with surface fixings and no supporting hoop", web.generated.get_child_count() == 4 and web.generated.has_node("SurfaceFixings") and not web.generated.has_node("SupportingHoop"))
	check_network(web)
	check_contact_cases()
	load("res://tools/probes/strand_dynamics_checks.gd").run(check)
	check("no filled faces or invisible colliders", web.find_children("*", "CollisionObject3D", true, false).is_empty())
	var duplicate: Dictionary = {}
	var lengths_ok := true
	var metric_ok := true
	# Every cell edge midpoint must be equidistant to at least three nearest
	# sites: the defining Voronoi edge property, not a random connection graph.
	for edge: Vector2i in web.edges:
		duplicate[edge] = true
		var a: Vector3 = web.vertices[edge.x] - Vector3.UP * web.centre_height
		var b: Vector3 = web.vertices[edge.y] - Vector3.UP * web.centre_height
		lengths_ok = lengths_ok and a.is_finite() and b.is_finite() and a.distance_to(b) > 0.00001
		var mid := (a+b)*0.5
		var distances: Array[float] = []
		for site: Vector3 in web.sites:
			distances.append(mid.distance_to(site))
		distances.sort()
		metric_ok = metric_ok and distances[2] - distances[0] < 0.005
	check("all edges finite, nonzero and deduplicated", lengths_ok and duplicate.size() == web.edges.size())
	check("edges belong to actual 3D Voronoi cells", metric_ok)
	var before: PackedVector3Array = web.vertices.duplicate()
	web.regenerate()
	check("same seed repeats geometry", web.vertices == before)
	web.seed_value += 1
	web.regenerate()
	check("different seed changes geometry", web.vertices != before)
	web.seed_value -= 1
	web.regenerate()
	var weaver = web.weaver
	weaver.set_process(false)
	check("spider starts at an anchor before laying silk", weaver.laid_count == 0 and web.generated.get_node("CellEdges").multimesh.visible_instance_count == 0 and weaver.spider.position.is_equal_approx(web.vertices[web.tethers[0].y]))
	var route_edges: Dictionary = {}
	var continuous := true
	var last_vertex: int = weaver.route[0].x
	for step: Vector3i in weaver.route:
		var edge: Vector2i = weaver.segments[step.z]
		continuous = continuous and last_vertex == step.x and (Vector2i(step.x, step.y) == edge or Vector2i(step.y, step.x) == edge)
		route_edges[step.z] = true
		last_vertex = step.y
	check("spider reaches every strand on a continuous graph route", continuous and route_edges.size() == weaver.segments.size())
	weaver.advance(0.15)
	var first_tip: Vector3 = weaver.spider.position
	check("fresh silk grows to the moving spider", first_tip.distance_to(web.vertices[weaver.route[0].x]) > 0.1 and weaver.get_node("FreshSilk").visible)
	weaver.paused = true
	weaver.advance(2)
	check("pause freezes construction and spider", first_tip.is_equal_approx(weaver.spider.position) and weaver.laid_count == 0)
	weaver.paused = false
	weaver.advance(20)
	check("construction reveals a partial connected structure", weaver.laid_count > 0 and weaver.laid_count < weaver.segments.size())
	web.advance_tension(1.0)
	check("unbuilt strands never support a physical load", not web.tension_active and web.dynamics.elapsed == 0)
	if DisplayServer.get_name() != "headless":
		preview.caption.hide()
		var camera: Camera3D = preview.walker.eyes
		camera.global_position = Vector3(8, 5.1, 12)
		camera.look_at(Vector3(0, 4.1, 0))
		camera.fov = 49
		weaver.advance(95)
		weaver.paused = true
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("voronoi-surface-building.png"))
		var spider_position: Vector3 = weaver.spider.global_position
		camera.global_position = spider_position + Vector3(1.4, 1.05, 2.2)
		camera.look_at(spider_position + weaver.spider.global_basis * Vector3(0, 0, -0.25))
		camera.fov = 45
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("voronoi-surface-spider-detail.png"))
	weaver.paused = false
	weaver.advance(10000)
	check("natural playback completes every strand", weaver.finished and weaver.laid_count == weaver.segments.size())
	if DisplayServer.get_name() != "headless":
		check("completed batches preserve exact Voronoi geometry", batch_matches(web.generated.get_node("CellEdges").multimesh, web.vertices, web.edges) and batch_matches(web.generated.get_node("AnchorCords").multimesh, web.vertices, web.tethers))
	weaver.restart()
	check("replay removes all previously laid silk", weaver.laid_count == 0 and not weaver.finished and web.generated.get_node("CellEdges").multimesh.visible_instance_count == 0 and web.generated.get_node("AnchorCords").multimesh.visible_instance_count == 0)
	weaver.finish()
	check("finish control restores every strand immediately", weaver.finished and weaver.laid_count == weaver.segments.size() and not weaver.is_processing())
	var knots: MultiMesh = web.generated.get_node("Knots").multimesh
	check("finish restores every silk junction", knots.visible_instance_count == knots.instance_count)
	if DisplayServer.get_name() != "headless":
		var camera: Camera3D = preview.walker.eyes
		camera.global_position = Vector3(7.5, 5.4, 12.8)
		camera.look_at(Vector3(0, 3.9, -1))
		camera.fov = 68
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("voronoi-room-surfaces.png"))
	check_live_tension(web)
	if DisplayServer.get_name() != "headless":
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("voronoi-tension.png"))
	web.weaver.restart()
	check("replay resets forces and restores original shared knots", not web.tension_active and web.vertices == web.dynamics.rest_positions and web.dynamics.metrics().kinetic_energy == 0)
	var routes_ok := true
	var networks_ok := true
	for seed in [0, 1, 19, 73, 75]:
		web.seed_value = seed
		web.site_count = 32 if seed < 2 else 150
		web.anchor_count = 12 if seed == 1 else 36
		web.regenerate()
		networks_ok = networks_ok and network_valid(web)
		web.weaver.advance(10000)
		routes_ok = routes_ok and web.weaver.laid_count == web.weaver.segments.size()
	check("alternate seeds and sparse cells stay attached and finish", routes_ok)
	check("alternate seeds preserve connected shared junctions", networks_ok)
	web.apply_grid_config({"weave": "false"})
	check("skipping construction releases complete geometry without spider", web.weaver == null and web.tension_active and web.generated.get_node("CellEdges").multimesh.visible_instance_count == -1)
	web.apply_grid_config({"tension": "false"})
	var static_vertices: PackedVector3Array = web.vertices.duplicate()
	web.advance_tension(1.0)
	check("force-free mode retains the static mathematical diagram", not web.tension_active and web.dynamics == null and web.vertices == static_vertices)
	web.seed_value = 74
	web.site_count = 150
	web.anchor_count = 36
	web.apply_grid_config({"weave": "true", "weave_speed": "3", "tension": "true"})
	check("grid config starts spider at requested speed", web.weaver != null and is_equal_approx(web.weaver.speed, 3.0))
	var at: Vector3 = web.position
	web.position = Vector3(1000, 0, 0)
	web.regenerate()
	check("empty space never creates a fake surface anchor or suspended net", web.anchor_kinds.is_empty() and web.weaver == null and not web.generated.visible)
	web.position = at
	web.regenerate()
	var report := {"checks": checks, "failures": failures, "sites": web.sites.size(), "edges": web.edges.size(), "vertices": web.vertices.size(), "tethers": web.tethers.size(), "surface_counts": surface_counts(web), "dynamics": dynamics_observations, "render_checks": DisplayServer.get_name() != "headless", "build_ms": web.build_msec}
	FileAccess.open(OS.get_cmdline_user_args()[0].path_join("strands-checks.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("VORONOI_STRANDS: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func batch_matches(batch: MultiMesh, points: PackedVector3Array, edges: Array) -> bool:
	if batch.visible_instance_count != edges.size():
		return false
	var expected: Dictionary = {}
	for edge: Vector2i in edges:
		expected[Vector3i(((points[edge.x] + points[edge.y]) * 5000.0).round())] = edge
	var observed: Dictionary = {}
	for i in range(batch.visible_instance_count):
		var transform := batch.get_instance_transform(i)
		var key := Vector3i((transform.origin * 10000.0).round())
		if not expected.has(key) or observed.has(key):
			return false
		observed[key] = true
		var edge: Vector2i = expected[key]
		var a := transform * Vector3(0, -0.5, 0)
		var b := transform * Vector3(0, 0.5, 0)
		if not ((a.distance_to(points[edge.x]) < 0.0001 and b.distance_to(points[edge.y]) < 0.0001) or (a.distance_to(points[edge.y]) < 0.0001 and b.distance_to(points[edge.x]) < 0.0001)):
			return false
	return true

func network_valid(web: Node3D) -> bool:
	var degree: Dictionary = {}
	var adjacency: Dictionary = {}
	var segments: Array = []
	segments.append_array(web.edges)
	segments.append_array(web.tethers)
	for edge: Vector2i in segments:
		for id in [edge.x, edge.y]:
			degree[id] = int(degree.get(id, 0)) + 1
			if not adjacency.has(id):
				adjacency[id] = []
		adjacency[edge.x].append(edge.y)
		adjacency[edge.y].append(edge.x)
	if degree.is_empty() or degree.size() != web.silk_vertex_count:
		return false
	for id: int in degree:
		if degree[id] < 2 and not web.anchor_kinds.has(id):
			return false
	var seen: Dictionary = {}
	var pending: Array = [degree.keys()[0]]
	while not pending.is_empty():
		var vertex: int = pending.pop_back()
		if seen.has(vertex):
			continue
		seen[vertex] = true
		pending.append_array(adjacency[vertex])
	return seen.size() == degree.size()

func check_network(web: Node3D) -> void:
	check("one connected net, no orphan junctions or unanchored free ends", network_valid(web))
	var anchors_real := true
	var plates_aligned := true
	var plates: MultiMesh = web.generated.get_node("SurfaceFixings").multimesh
	var plate_index := 0
	var state := web.get_world_3d().direct_space_state
	for id: int in web.anchor_kinds:
		var point: Vector3 = web.to_global(web.vertices[id])
		var normal: Vector3 = (web.global_basis * web.anchor_normals[id]).normalized()
		var hit: Dictionary = state.intersect_ray(PhysicsRayQueryParameters3D.create(point + normal * 0.08, point - normal * 0.08, 1))
		anchors_real = anchors_real and not hit.is_empty()
		if not hit.is_empty():
			var kind := "floor" if hit.normal.y > 0.6 else ("ceiling" if hit.normal.y < -0.6 else "wall")
			anchors_real = anchors_real and web.anchor_kinds[id] == kind and hit.position.distance_to(point) < 0.001 and hit.collider is StaticBody3D
		var plate := plates.get_instance_transform(plate_index)
		plates_aligned = plates_aligned and plate.is_finite() and plate.basis.z.dot(web.anchor_normals[id]) > 0.999 and (plate * Vector3(0, 0, -0.0125)).distance_to(web.vertices[id]) < 0.0001
		plate_index += 1
	anchors_real = anchors_real and plates.instance_count == web.anchor_kinds.size()
	check("every tether meets an actual room collision surface", anchors_real)
	# The headless dummy renderer does not retain MultiMesh transform readback.
	if DisplayServer.get_name() != "headless":
		check("fixing plates sit flush against floors, walls and ceilings", plates_aligned)
	var counts := surface_counts(web)
	check("closed room uses floor, walls and ceiling", counts.floor > 0 and counts.wall > 0 and counts.ceiling > 0)
	var cords_clear := true
	for tether: Vector2i in web.tethers:
		var from: Vector3 = web.to_global(web.vertices[tether.x])
		var to: Vector3 = web.to_global(web.vertices[tether.y])
		var hit: Dictionary = state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))
		cords_clear = cords_clear and (hit.is_empty() or hit.position.distance_to(to) < 0.001)
	check("cords never pass through intervening room geometry", cords_clear)
	var segments: Array = []
	segments.append_array(web.edges)
	segments.append_array(web.tethers)
	var contacts_real := true
	for i in range(segments.size()):
		var e: Vector2i = segments[i]
		var box := AABB(web.vertices[e.x].min(web.vertices[e.y]), (web.vertices[e.x] - web.vertices[e.y]).abs()).grow(0.00009)
		for j in range(i + 1, segments.size()):
			var f: Vector2i = segments[j]
			if e.x == f.x or e.x == f.y or e.y == f.x or e.y == f.y:
				continue
			var other := AABB(web.vertices[f.x].min(web.vertices[f.y]), (web.vertices[f.x] - web.vertices[f.y]).abs()).grow(0.00009)
			if not box.intersects(other):
				continue
			var closest := Geometry3D.get_closest_points_between_segments(web.vertices[e.x], web.vertices[e.y], web.vertices[f.x], web.vertices[f.y])
			contacts_real = contacts_real and closest[0].distance_to(closest[1]) > 0.00009
	check("no 3D centreline crossings without shared junction IDs", contacts_real)

func surface_counts(web: Node3D) -> Dictionary:
	var counts := {"floor": 0, "wall": 0, "ceiling": 0}
	for kind: String in web.anchor_kinds.values():
		counts[kind] += 1
	return counts

func check_live_tension(web: Node3D) -> void:
	web.weaver.restart()
	web.weaver.finish()
	web.set_physics_process(false) # Probe advances the exact same path explicitly.
	var initial: PackedVector3Array = web.vertices.duplicate()
	var original_edges: Array = web.edges.duplicate()
	var original_tethers: Array = web.tethers.duplicate()
	var time_sum := 0.0
	for i in range(360):
		web.advance_tension(1.0 / 60.0)
		time_sum += web.physics_msec
	var anchors_fixed := true
	var finite := true
	var drop := 0.0
	for i in range(initial.size()):
		finite = finite and web.vertices[i].is_finite()
		if web.anchor_kinds.has(i):
			anchors_fixed = anchors_fixed and initial[i] == web.vertices[i]
		else:
			drop += initial[i].y - web.vertices[i].y
	drop /= float(initial.size() - web.anchor_kinds.size())
	var metrics: Dictionary = web.dynamics.metrics()
	check("gravity deforms the completed net and creates cable tension", drop > 0.005 and metrics.peak_tension > 0.1)
	check("floor, wall and ceiling anchors remain exactly fixed under load", anchors_fixed)
	check("shared graph stays finite and connected under gravity", finite and network_valid(web) and web.edges == original_edges and web.tethers == original_tethers)
	check("stiff cables bound extension under sustained gravity", metrics.max_extension < 0.1)
	if DisplayServer.get_name() != "headless":
		check("every rendered strand ends at its moving shared knots", batch_matches(web.generated.get_node("CellEdges").multimesh, web.vertices, web.edges) and batch_matches(web.generated.get_node("AnchorCords").multimesh, web.vertices, web.tethers))
		var knots: MultiMesh = web.generated.get_node("Knots").multimesh
		var knots_match := true
		for i in range(web.vertices.size()):
			knots_match = knots_match and knots.get_instance_transform(i).origin.distance_to(web.vertices[i]) < 0.0001
		check("junction spheres remain at the simulated connection points", knots_match)
	var snapshot: PackedVector3Array = web.vertices.duplicate()
	web.tension_paused = true
	web.advance_tension(0.05)
	check("pause freezes all physical knots", web.vertices == snapshot)
	web.tension_paused = false
	# Compare a tug against an otherwise identical untugged model, so gravity
	# alone cannot satisfy the test that force propagates to a neighbouring knot.
	var control = load("res://commons/context/cellular_spaces/strand_dynamics.gd").new()
	control.setup(web.dynamics.rest_positions, web.dynamics.segments, web.anchor_kinds)
	control.positions = web.dynamics.positions.duplicate()
	control.velocities = web.dynamics.velocities.duplicate()
	control.contact_resolver = web.dynamics.contact_resolver
	var chosen := 0
	var nearest := INF
	for i in range(web.vertices.size()):
		if web.anchor_kinds.has(i):
			continue
		var distance: float = web.vertices[i].distance_squared_to(Vector3(0, web.centre_height, 0))
		if distance < nearest:
			nearest = distance
			chosen = i
	var neighbour := -1
	for edge: Vector2i in web.edges:
		if edge.x == chosen or edge.y == chosen:
			neighbour = edge.y if edge.x == chosen else edge.x
			break
	check("free knots accept a tug while room fixings reject it", web.tug_knot(chosen, Vector3(0.12, 0, 0)) and not web.tug_knot(web.anchor_kinds.keys()[0], Vector3.ONE))
	for i in range(24):
		web.advance_tension(1.0 / 60.0)
		control.advance(1.0 / 60.0)
	var propagated: float = web.vertices[neighbour].distance_to(control.positions[neighbour])
	check("a tug transmits force through a shared knot to its neighbour", propagated > 0.0001)
	# Exercise a real room collision independently of small normal deflections.
	var grounded: Vector3 = web._sweep_knot(Vector3(0, 0.1, 0), Vector3(0, -0.1, 0))
	check("falling knots stop on the actual floor collision", grounded.y >= 0 and grounded.y < 0.03)
	dynamics_observations = {"mean_drop_m": drop, "max_extension_m": metrics.max_extension, "peak_tension_n": metrics.peak_tension, "kinetic_energy_j": metrics.kinetic_energy, "neighbour_tug_response_m": propagated, "mean_physics_ms": time_sum / 360.0}

func check_contact_cases() -> void:
	var network = load("res://commons/context/cellular_spaces/strand_network.gd")
	var points := PackedVector3Array([Vector3(-1,0,0), Vector3(1,0,0), Vector3(0,-1,0), Vector3(0,1,0)])
	var result: Dictionary = network.join_contacts(points, [[Vector2i(0,1)], [Vector2i(2,3)]])
	check("a true 3D crossing splits both strands at one common junction", result.vertices.size() == 5 and result.groups[0].size() == 2 and result.groups[1].size() == 2)
	points[2].z = 0.1
	points[3].z = 0.1
	result = network.join_contacts(points, [[Vector2i(0,1)], [Vector2i(2,3)]])
	check("over-under strands remain separate despite screen-space crossing", result.vertices.size() == 4 and result.groups[0].size() == 1 and result.groups[1].size() == 1)
	points[2] = Vector3.ZERO
	points[3] = Vector3.UP
	result = network.join_contacts(points, [[Vector2i(0,1)], [Vector2i(2,3)]])
	check("a T connection uses the arriving strand endpoint", result.vertices.size() == 4 and result.groups[0].size() == 2 and result.groups[0][0].y == 2 and result.groups[0][1].y == 2)
