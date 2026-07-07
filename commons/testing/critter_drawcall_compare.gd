extends SceneTree

## critter_drawcall_compare.gd
##
## Build the SAME critter twice — once raw (CreatureMorphology output),
## once batched via CreatureBatcher — and capture both side-by-side
## with draw-call counts overlaid in the printed log. Proves the Tier
## 2 per-critter MultiMesh win is real and measurable.
##
## Output:
##   user://critter_compare.png — both critters side by side
##   stdout — before/after draw call counts
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/critter_drawcall_compare.gd

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

# Sweep one config per archetype so we know the win holds across the
# full DNA space (bug → larva → walker → flier → alien).
const CONFIG_PATHS := [
	"C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery/cd_bug_beetle_03.json",
	"C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery/cd_larva_worm_05.json",
	"C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery/cd_walker_quad_03.json",
	"C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery/cd_flier_wing_02.json",
	"C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/critter-dna-gallery/cd_alien_crab_05.json",
]
const OUT_PATH := "user://critter_compare.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("─────────────────────────────────────────────────────────")
	print("[compare] Critter draw-call sweep across 5 archetypes")
	print("[compare]   raw = MeshInstance3D count")
	print("[compare]   bat = MeshInstance3D + MultiMeshInstance3D count")
	print("─────────────────────────────────────────────────────────")
	print("%-22s %5s %5s %6s %7s" % ["archetype", "raw", "bat", "saved", "%cut"])
	print("%-22s %5s %5s %6s %7s" % ["----------", "---", "---", "-----", "----"])

	var trait_mapper := CritterTraitMapperClass.new()
	var totals_raw: int = 0
	var totals_bat: int = 0

	for cfg_path in CONFIG_PATHS:
		var sample: Dictionary = _measure_one(cfg_path, trait_mapper)
		var arch: String = (cfg_path.get_file().replace(".json", "")
			.replace("cd_", "").substr(0, 22))
		var saved: int = sample.raw - sample.bat
		var pct: float = 100.0 * float(saved) / maxf(float(sample.raw), 1.0)
		print("%-22s %5d %5d %6d %6.1f%%"
			% [arch, sample.raw, sample.bat, saved, pct])
		totals_raw += sample.raw
		totals_bat += sample.bat

	var grand_saved: int = totals_raw - totals_bat
	var grand_pct: float = 100.0 * float(grand_saved) / maxf(float(totals_raw), 1.0)
	print("%-22s %5s %5s %6s %7s" % ["----------", "---", "---", "-----", "----"])
	print("%-22s %5d %5d %6d %6.1f%%"
		% ["TOTAL (5 critters)", totals_raw, totals_bat, grand_saved, grand_pct])
	print("─────────────────────────────────────────────────────────")

	# Render the last sweep config as the side-by-side image so we
	# have something visual to attach.
	_render_compare(CONFIG_PATHS[CONFIG_PATHS.size() - 1], trait_mapper)

	quit(0)


## Build raw + batched once for one config and return their draw counts.
## Doesn't keep anything in the scene — just measures.
func _measure_one(cfg_path: String, trait_mapper: CritterTraitMapper) -> Dictionary:
	var dna: CritterDNA = _load_dna(cfg_path)

	var raw_root := Node3D.new()
	get_root().add_child(raw_root)
	CreatureMorphologyClass.build(dna, raw_root, trait_mapper, 3)
	var raw_count: int = _count_draw_calls(raw_root)

	var batched_root := Node3D.new()
	get_root().add_child(batched_root)
	CreatureMorphologyClass.build(dna, batched_root, trait_mapper, 3)
	CreatureBatcherClass.batch_critter(batched_root)
	var bat_count: int = _count_draw_calls(batched_root)

	raw_root.queue_free()
	batched_root.queue_free()

	return {"raw": raw_count, "bat": bat_count}


func _load_dna(cfg_path: String) -> CritterDNA:
	var f := FileAccess.open(cfg_path, FileAccess.READ)
	var raw := f.get_as_text()
	f.close()
	var cfg: Dictionary = JSON.parse_string(raw)
	cfg.erase("_cluster"); cfg.erase("_id")
	for k in ["primary_color", "secondary_color", "tertiary_color"]:
		if cfg.has(k):
			var v = cfg[k]
			if v is Array and v.size() >= 3:
				cfg[k] = Color(float(v[0]), float(v[1]), float(v[2]))
	var dna: CritterDNA = CritterDNAClass.new()
	dna.from_dict(cfg)
	dna.body_type = 1.0
	return dna


## Render the side-by-side PNG for a single config (final visual).
func _render_compare(cfg_path: String, trait_mapper: CritterTraitMapper) -> void:
	print("[compare] rendering side-by-side image: %s" % cfg_path.get_file())

	var root_3d := Node3D.new()
	get_root().add_child(root_3d)

	# Environment + sun (same as gallery lab).
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	root_3d.add_child(sun)

	# Camera frames both critters horizontally.
	var camera := Camera3D.new()
	camera.fov = 45.0
	root_3d.add_child(camera)
	camera.current = true

	var dna: CritterDNA = _load_dna(cfg_path)

	# ── A: raw critter ──
	var raw_root := Node3D.new()
	raw_root.name = "Raw"
	root_3d.add_child(raw_root)
	CreatureMorphologyClass.build(dna, raw_root, trait_mapper, 3)
	# Suppress shader transparency hiding (same fix the fungus lab uses).
	_zero_transparency(raw_root)
	raw_root.position = Vector3(-1.5, 0.0, 0.0)
	raw_root.rotation.y = deg_to_rad(-25.0)
	var raw_calls: int = _count_draw_calls(raw_root)

	# ── B: batched critter (separate DNA build to keep them independent) ──
	var batched_root := Node3D.new()
	batched_root.name = "Batched"
	root_3d.add_child(batched_root)
	CreatureMorphologyClass.build(dna, batched_root, trait_mapper, 3)
	_zero_transparency(batched_root)
	# Run the post-process batcher.
	var stats: Dictionary = CreatureBatcherClass.batch_critter(batched_root)
	batched_root.position = Vector3(1.5, 0.0, 0.0)
	batched_root.rotation.y = deg_to_rad(-25.0)
	var batched_calls: int = _count_draw_calls(batched_root)

	print("[compare]   side-by-side: raw=%d  bat=%d  saved=%d (%.1f%%)"
		% [raw_calls, batched_calls, raw_calls - batched_calls,
		   100.0 * float(raw_calls - batched_calls) / float(raw_calls)])
	print("[compare]   batcher stats: %s" % stats)

	# Frame the camera around both.
	await create_timer(0.4).timeout
	await process_frame

	camera.global_position = Vector3(0.0, 0.6, 4.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null: push_error("[compare] image null"); return
	var save_err := img.save_png(OUT_PATH)
	if save_err != OK:
		push_error("[compare] save_png failed: %s" % save_err); return

	print("[compare] PNG written: %s" % ProjectSettings.globalize_path(OUT_PATH))


func _zero_transparency(node: Node) -> void:
	for child in node.get_children():
		var mat = null
		if child is MeshInstance3D:
			mat = (child as MeshInstance3D).material_override
		elif child is MultiMeshInstance3D:
			mat = (child as MultiMeshInstance3D).material_override
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("transparency", 0.0)
		_zero_transparency(child)


func _count_draw_calls(root: Node) -> int:
	var n: int = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			if (node as MeshInstance3D).mesh != null: n += 1
		elif node is MultiMeshInstance3D:
			if (node as MultiMeshInstance3D).multimesh != null: n += 1
		for c in node.get_children():
			stack.push_back(c)
	return n
