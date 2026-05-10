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
	{"id": "branching_vine",   "scene": "res://commons/hazards/branching_vine/branching_vine.tscn",   "label": "Branching vine — organic L-system growth"},
	{"id": "bricoleur_golem",  "scene": "res://commons/hazards/bricoleur_golem/bricoleur_golem.tscn", "label": "Bricoleur golem — assembled from parts"},
	{"id": "data_tree_walker", "scene": "res://commons/hazards/data_tree_walker/data_tree_walker.tscn","label": "Data tree walker — BST traversal threat"},
	{"id": "escher_stairwalker","scene": "res://commons/hazards/escher_stairwalker/escher_stairwalker.tscn","label": "Escher stairwalker — impossible architecture"},
	{"id": "fractal_hydra",    "scene": "res://commons/hazards/fractal_hydra/fractal_hydra.tscn",     "label": "Fractal hydra — self-similar branching threat"},
	{"id": "gradient_hunter",  "scene": "res://commons/hazards/gradient_hunter/gradient_hunter.tscn", "label": "Gradient hunter — climbs the value gradient"},
	{"id": "mesh_morpher",     "scene": "res://commons/hazards/mesh_morpher/mesh_morpher.tscn",       "label": "Mesh morpher — topology-shifting form"},
	{"id": "wave_rider",       "scene": "res://commons/hazards/wave_rider/wave_rider.tscn",           "label": "Wave rider — surface-wave-driven motion"},
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
	# Set personality. HazardCreatureBase subclasses expose set_personality.
	if creature.has_method("set_personality"):
		creature.call("set_personality", personality)
	# Some creatures build geometry over physics ticks — leave physics on
	# but use a wider camera so wandering doesn't take them out of frame.

	# Camera — wide 3/4 view that frames a 6m volume around the spawn
	var cam := Camera3D.new()
	cam.position = Vector3(3.5, 2.8, 4.5)
	cam.look_at(Vector3(0, 0.6, 0), Vector3.UP)
	cam.fov = 50.0
	root.add_child(cam)

	# Replace any existing scene
	var prev := current_scene
	get_root().add_child(root)
	current_scene = root
	if prev != null and prev != root:
		prev.queue_free()

	# Settle frames — some creatures build geometry across many ticks
	# (L-system iterations, fractal subdivisions, etc.). Wait ~3s.
	for _i in range(180):
		await process_frame

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
