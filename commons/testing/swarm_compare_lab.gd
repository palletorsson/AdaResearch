extends SceneTree

## swarm_compare_lab.gd  —  Tier 3a measurement
##
## Render N=50 walker-kingdom critters two ways, side-by-side:
##
##   LEFT  — 50 individual CreatureMorphology trees (with Tier 2.5
##           batching applied per critter): expect 50 × ~10 = ~500 calls
##   RIGHT — 50 swarm impostors via SwarmRenderer.build():
##           expect 1 draw call regardless of N
##
## Output:
##   user://swarm_compare.png — side-by-side image
##   stdout — draw-call counts for each side, ratio, file paths
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/swarm_compare_lab.gd

const CritterDNAClass = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const CritterTraitMapperClass = preload(
	"res://algorithms/nature_system/dna/critter_trait_mapper.gd"
)
const CreatureMorphologyClass = preload(
	"res://algorithms/nature_system/morphology/creature_morphology.gd"
)
const CreatureBatcherClass = preload(
	"res://commons/testing/creature_batcher.gd"
)
const SwarmRendererClass = preload(
	"res://commons/testing/swarm_renderer.gd"
)

const N: int = 50
const SPREAD: float = 4.0
const OUT_PATH: String = "user://swarm_compare.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[swarm_compare] start, N=%d" % N)

	var root_3d := Node3D.new()
	get_root().add_child(root_3d)

	# Env + sun + camera
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	env.ambient_light_color = Color(0.95, 0.95, 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	root_3d.add_child(sun)

	var camera := Camera3D.new()
	camera.fov = 55.0
	root_3d.add_child(camera)

	# Generate N DNAs once — both sides use the same set, so we measure
	# rendering cost not DNA difference.
	var dnas: Array = []
	var positions_local: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in N:
		dnas.append(CritterDNAClass.random_kingdom(1, 1234 + i))  # walker kingdom
		positions_local.append(Vector3(
			rng.randf_range(-SPREAD, SPREAD),
			0.0,
			rng.randf_range(-SPREAD, SPREAD)
		))

	# ── LEFT side: full CreatureMorphology + Tier 2.5 batching ──
	var left_root := Node3D.new()
	left_root.name = "FullCritters"
	left_root.position = Vector3(-SPREAD - 2.0, 0.0, 0.0)
	root_3d.add_child(left_root)

	var trait_mapper := CritterTraitMapperClass.new()
	for i in N:
		var critter_root := Node3D.new()
		critter_root.position = positions_local[i]
		left_root.add_child(critter_root)
		CreatureMorphologyClass.build(dnas[i], critter_root, trait_mapper, 1)
		CreatureBatcherClass.batch_critter(critter_root)

	var left_calls: int = _count_draw_calls(left_root)
	print("[swarm_compare] LEFT  full critters: %d draw calls" % left_calls)

	# ── RIGHT side: swarm impostors ──
	var right_root := Node3D.new()
	right_root.name = "SwarmImpostors"
	right_root.position = Vector3(SPREAD + 2.0, 0.0, 0.0)
	root_3d.add_child(right_root)

	# Same positions, but offset onto right_root.
	SwarmRendererClass.build(dnas, positions_local, right_root)

	var right_calls: int = _count_draw_calls(right_root)
	print("[swarm_compare] RIGHT swarm:        %d draw calls" % right_calls)

	var ratio: float = float(left_calls) / maxf(float(right_calls), 1.0)
	print("[swarm_compare] reduction:          %.1f×  (left/right)" % ratio)
	print("─────────────────────────────────────────────────────────")

	# Settle, frame both
	await create_timer(0.5).timeout
	await process_frame
	await process_frame

	camera.global_position = Vector3(0.0, 8.0, 12.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[swarm_compare] image null"); quit(1); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK:
		push_error("[swarm_compare] save failed: %s" % save_err); quit(1); return

	print("[swarm_compare] DONE: %s" % ProjectSettings.globalize_path(OUT_PATH))
	quit(0)


func _count_draw_calls(root: Node) -> int:
	var n: int = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			n += 1
		elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
			n += 1
		for c in node.get_children():
			stack.push_back(c)
	return n
