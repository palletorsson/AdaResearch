extends SceneTree

## Round-trip test: build a mesh-grammar config, run it, export the
## resulting tagged mesh as a CritterDNA Resource, save to .tres so
## the nature_system spawner / pokemon_studio breeding lab can consume
## it as a real phenotype seed.
##
## This is the first end-to-end design-time → runtime bridge for the
## morphology pipeline. Run:
##   godot --path . --xr-mode off --no-window --headless \
##     --script res://commons/testing/export_critter_from_mesh_grammar.gd -- \
##     --config=res://commons/mesh_grammar/_staging/gen08_stamped_flower.json \
##     --out=user://critter_dna/gen08_flower.tres
##
## The .tres can then be loaded by any system that consumes CritterDNA:
##     var dna = load("user://critter_dna/gen08_flower.tres") as CritterDNA
##     spawner.spawn(dna)

const RenderScript = preload("res://commons/testing/render_mesh_grammar.gd")
const MeshGrammarExporter = preload("res://commons/mesh_grammar/mesh_grammar_exporter.gd")

var _config_path: String = ""
var _output_path: String = "user://critter_dna/out.tres"


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("export_critter_from_mesh_grammar: --config=<path> required")
		quit(1); return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"): continue
		var eq := a.find("=")
		if eq <= 2: continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"config": _config_path = val
			"out":    _output_path = val


func _run() -> void:
	# Load the same config the renderer would.
	var abs_config := ProjectSettings.globalize_path(_config_path)
	var path_to_use: String = _config_path if FileAccess.file_exists(_config_path) else abs_config
	if not FileAccess.file_exists(path_to_use):
		push_error("export_critter: config not found: %s" % _config_path)
		quit(1); return
	var txt := FileAccess.get_file_as_string(path_to_use)
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_error("export_critter: invalid JSON")
		quit(1); return
	var cfg: Dictionary = json.data

	# Build a minimal scene + run the grammar pipeline. We re-use the
	# render script by instantiating its mesh-grammar building logic
	# inline — only the parts that don't need a viewport.
	var mg = await _build_mesh_grammar_from_config(cfg)
	if mg == null or mg.current_mesh == null:
		push_error("export_critter: grammar produced no mesh")
		quit(1); return
	var mesh = mg.current_mesh

	# Apply hints from the config's optional "critter_hints" dict so the
	# author can guide the export (kingdom, body_type override, etc).
	var hints: Dictionary = cfg.get("critter_hints", {})
	var dna = MeshGrammarExporter.to_critter_dna(mesh, hints)
	if dna == null:
		push_error("export_critter: exporter returned null")
		quit(1); return

	# Save the .tres.
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := ResourceSaver.save(dna, abs_out)
	if err != OK:
		push_error("export_critter: save failed (%d)" % err)
		quit(1); return

	# Print a summary so the user can sanity-check the round-trip.
	print("[export_critter] saved %s" % abs_out)
	print("  body_type     = %.2f" % dna.body_type)
	print("  symmetry      = %.2f" % dna.symmetry)
	print("  segments      = %.2f" % dna.segments)
	print("  primary_color = %s" % dna.primary_color)
	print("  secondary     = %s" % dna.secondary_color)
	print("  tertiary      = %s" % dna.tertiary_color)
	print("  faces in src  = %d" % mesh.faces.size())
	quit(0)


# Minimal headless mesh-grammar runner. Builds the same MeshGrammarNode
# the renderer builds, but doesn't add it to a viewport scene — we just
# want the final tagged MeshData.
func _build_mesh_grammar_from_config(cfg: Dictionary):
	var renderer = RenderScript.new()
	# Inject a Node3D so any await-based seed (scene loading) has a tree
	# to lean on.
	var holder := Node3D.new()
	root.add_child(holder)
	# Build seed.
	var MeshDataClass = load("res://commons/mesh_grammar/mesh_data.gd")
	var seed_val = cfg.get("seed", "icosahedron")
	var custom_seed = null
	if seed_val is Dictionary:
		if seed_val.has("graph") and seed_val["graph"] is Dictionary:
			custom_seed = renderer._build_graph_seed_mesh(seed_val["graph"])
		elif seed_val.has("graph_grammar") and seed_val["graph_grammar"] is Dictionary:
			custom_seed = renderer._build_graph_grammar_seed_mesh(seed_val["graph_grammar"])
		elif seed_val.has("compose") and seed_val["compose"] is Array:
			custom_seed = await renderer._build_composed_seed_mesh(seed_val["compose"])
	# Fallback: simple primitive name.
	if custom_seed == null:
		var s := str(seed_val)
		match s:
			"flower_disk": custom_seed = MeshDataClass.create_flower_disk(
				float(cfg.get("seed_scale", 1.0)), 5, 24)
			"disk": custom_seed = MeshDataClass.create_disk(float(cfg.get("seed_scale", 1.0)), 24)
			"icosahedron": custom_seed = MeshDataClass.create_icosahedron(float(cfg.get("seed_scale", 0.6)))
			"cube": custom_seed = MeshDataClass.create_cube(float(cfg.get("seed_scale", 0.6)))
			"sphere": custom_seed = MeshDataClass.create_sphere(float(cfg.get("seed_scale", 0.6)), 12, 16)
			_:
				custom_seed = MeshDataClass.create_icosahedron(float(cfg.get("seed_scale", 0.6)))
	if custom_seed == null:
		return null

	var MeshGrammarNodeCls = load("res://commons/mesh_grammar/mesh_grammar_node.gd")
	var mg_node = MeshGrammarNodeCls.new()
	mg_node.seed_type = "custom"
	mg_node.generations = int(cfg.get("generations", 1))
	mg_node.auto_generate = false
	holder.add_child(mg_node)
	mg_node.set_seed_mesh(custom_seed)

	for rdef in cfg.get("rules", []):
		var rule = renderer._build_rule(rdef)
		if rule != null:
			mg_node.add_rule(rule)
	mg_node.generate()
	return mg_node.grammar
