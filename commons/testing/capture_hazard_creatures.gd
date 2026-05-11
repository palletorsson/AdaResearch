@tool
extends SceneTree
# Capture a representative slice of HazardCreatureBase subclasses at 3
# personality stages each (foe / curious / friend). The 43 hazard
# creatures all share the same personality machinery; this gallery row
# shows the visual + behavioural range across the project's foes.
#
# Usage:
#   godot --no-window --xr-mode off --script res://commons/testing/capture_hazard_creatures.gd
#
# Output:
#   user://catalyst_runs/creatures/<creature>/<personality>.png

const CREATURES: Array = [
	{"id": "branching_vine",     "scene": "res://commons/hazards/branching_vine/branching_vine.tscn",         "label": "Branching vine — organic L-system growth"},
	{"id": "bricoleur_golem",    "scene": "res://commons/hazards/bricoleur_golem/bricoleur_golem.tscn",       "label": "Bricoleur golem — assembled from parts"},
	{"id": "data_tree_walker",   "scene": "res://commons/hazards/data_tree_walker/data_tree_walker.tscn",     "label": "Data tree walker — BST traversal threat"},
	{"id": "escher_stairwalker", "scene": "res://commons/hazards/escher_stairwalker/escher_stairwalker.tscn", "label": "Escher stairwalker — impossible architecture"},
	{"id": "fractal_hydra",      "scene": "res://commons/hazards/fractal_hydra/fractal_hydra.tscn",           "label": "Fractal hydra — self-similar branching threat"},
	{"id": "gradient_hunter",    "scene": "res://commons/hazards/gradient_hunter/gradient_hunter.tscn",       "label": "Gradient hunter — climbs the value gradient"},
	{"id": "mesh_morpher",       "scene": "res://commons/hazards/mesh_morpher/mesh_morpher.tscn",             "label": "Mesh morpher — topology-shifting form"},
	{"id": "wave_rider",         "scene": "res://commons/hazards/wave_rider/wave_rider.tscn",                 "label": "Wave rider — surface-wave-driven motion"},
	{"id": "collision_crasher",  "scene": "res://commons/hazards/collision_crasher/collision_crasher.tscn",   "label": "Collision crasher — physics impact threat"},
	{"id": "grammar_markov",     "scene": "res://commons/hazards/grammar_markov/grammar_markov.tscn",         "label": "Grammar markov — Markov-chain pattern threat"},
	{"id": "graph_weaver",       "scene": "res://commons/hazards/graph_weaver/graph_weaver.tscn",             "label": "Graph weaver — graph traversal threat"},
	{"id": "hull_crusher",       "scene": "res://commons/hazards/hull_crusher/hull_crusher.tscn",             "label": "Hull crusher — convex hull deformer"},
	{"id": "index_sentinel",     "scene": "res://commons/hazards/index_sentinel/index_sentinel.tscn",         "label": "Index sentinel — array indexing visualization"},
	{"id": "joint_articulator",  "scene": "res://commons/hazards/joint_articulator/joint_articulator.tscn",   "label": "Joint articulator — IK chain demonstration"},
	{"id": "lifeform_walker",    "scene": "res://commons/hazards/lifeform_walker/lifeform_walker.tscn",       "label": "Lifeform walker — Karl Sims-style evolved gait"},
	{"id": "maze_spinner",       "scene": "res://commons/hazards/maze_spinner/maze_spinner.tscn",             "label": "Maze spinner — procedural maze traversal"},
	{"id": "paradox_stalker",    "scene": "res://commons/hazards/paradox_stalker/paradox_stalker.tscn",       "label": "Paradox stalker — self-referential pursuit"},
	{"id": "qfep_calibrator",    "scene": "res://commons/hazards/qfep_calibrator/qfep_calibrator.tscn",       "label": "QFEP calibrator — final-arc theory creature"},
	{"id": "spring_mass_bouncer","scene": "res://commons/hazards/spring_mass_bouncer/spring_mass_bouncer.tscn","label": "Spring mass bouncer — Hooke's-law locomotion"},
	{"id": "tesseract_phaser",   "scene": "res://commons/hazards/tesseract_phaser/tesseract_phaser.tscn",     "label": "Tesseract phaser — 4D rotation hazard"},
	{"id": "catalyst_foe",       "scene": "res://commons/hazards/catalyst_foe/catalyst_foe.tscn",             "label": "Catalyst foe — unifying enemy with foe_mode dispatch"},
]

const PERSONALITIES: Array = ["foe", "curious", "friend"]


func _init() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/creatures")

	for creature in CREATURES:
		for p in PERSONALITIES:
			await _capture_creature(creature["id"], creature["scene"], p)
	print("[hazard_creatures] complete")
	quit()


func _capture_creature(cid: String, scene_path: String, personality: String) -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("catalyst_runs/creatures/%s" % cid)

	if not ResourceLoader.exists(scene_path):
		print("[hazard_creatures] FAIL: scene not found %s" % scene_path)
		return
	var scene_pack: PackedScene = load(scene_path)
	if scene_pack == null:
		print("[hazard_creatures] FAIL: load returned null %s" % scene_path)
		return

	var root := Node3D.new()
	root.name = "HazardCreatureCapture_%s_%s" % [cid, personality]

	# Floor
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.0, 4.0)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.92, 0.88, 0.78)
	floor_mat.roughness = 0.7
	floor.material_override = floor_mat
	root.add_child(floor)

	# Lights
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.96, 0.86)
	key.light_energy = 1.2
	key.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.78, 0.86, 1.0)
	fill.light_energy = 0.5
	fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(-120), 0)
	root.add_child(fill)

	# Environment
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.66, 0.50)
	environment.ambient_light_color = Color(0.85, 0.85, 0.90)
	environment.ambient_light_energy = 0.55
	env.environment = environment
	root.add_child(env)

	# Spawn the creature
	var creature: Node3D = scene_pack.instantiate() as Node3D
	if creature == null:
		print("[hazard_creatures] FAIL: instantiate returned null %s" % cid)
		return
	root.add_child(creature)
	creature.position = Vector3(0, 0.2, 0)

	# Camera — moderate 3/4 view. Initial aim is the spawn point; after
	# the settle pass we recompute the camera using the creature's actual
	# mesh AABB so each capture is properly framed.
	var cam := Camera3D.new()
	cam.position = Vector3(2.0, 1.6, 2.6)
	cam.fov = 42.0
	root.add_child(cam)

	# Replace any existing scene
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()
	cam.look_at(Vector3(0, 0.5, 0), Vector3.UP)

	# Let _ready fire (builds geometry, creates _custom_mat etc.) BEFORE
	# we touch personality. catalyst_foe's set_personality override
	# repaints _custom_mat — if we set personality pre-_ready, the mat
	# is null and the paint silently no-ops.
	await process_frame
	await process_frame
	if creature.has_method("set_personality"):
		creature.call("set_personality", personality)
	# Zero out movement so the creature builds geometry in place
	# (without patrolling out of camera frame). HazardCreatureBase's
	# configure() accepts speed/chase_speed/detection_radius via apply_grid_config.
	if creature.has_method("apply_grid_config"):
		creature.call("apply_grid_config", {
			"speed": 0.0,
			"chase_speed": 0.0,
			"detection_radius": 0.0,
		})

	# Settle frames — speed=0 means the creature builds geometry in place
	# without wandering. ~3s gives time for L-system iterations,
	# fractal subdivisions, animated rig settling.
	for _i in range(180):
		await process_frame

	# After settle: compute the creature's mesh AABB so we can frame it.
	# Many creatures build their visible geometry as descendants offset
	# from the root, so creature.position alone doesn't reflect where
	# the body actually is.
	var aabb := _compute_visual_aabb(creature)
	var center := Vector3(0, 0.5, 0)
	var radius := 1.0
	if aabb.size.length() > 0.001:
		center = aabb.position + aabb.size * 0.5
		radius = max(aabb.size.x, max(aabb.size.y, aabb.size.z)) * 0.6
		radius = clamp(radius, 0.6, 4.0)
	# Re-aim the camera at the AABB centre, pulling back proportional to size.
	var cam_dir := Vector3(1.0, 0.7, 1.3).normalized()
	cam.position = center + cam_dir * (radius * 2.4 + 1.2)
	cam.look_at(center, Vector3.UP)

	var vp: Viewport = root.get_viewport()
	vp.size = Vector2i(800, 800)
	await process_frame

	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[hazard_creatures] FAIL: viewport null %s_%s" % [cid, personality])
		return
	var out_path: String = "user://catalyst_runs/creatures/%s/%s.png" % [cid, personality]
	img.save_png(out_path)
	print("[hazard_creatures] saved %s_%s" % [cid, personality])


func _compute_visual_aabb(node: Node3D) -> AABB:
	# Walk the subtree, union the world-space AABBs of every visible
	# MeshInstance3D. Floor + lights are siblings so we only walk inside
	# the creature node.
	var aabb := AABB()
	var has_any := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var local := mi.get_aabb()
			var xf := mi.global_transform
			var world_aabb := xf * local
			if not has_any:
				aabb = world_aabb
				has_any = true
			else:
				aabb = aabb.merge(world_aabb)
		for c in n.get_children():
			if c is Node3D:
				stack.append(c)
	return aabb if has_any else AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
