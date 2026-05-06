# composition_artifact.gd
# A thin wrapper that loads a JSON composition config and instantiates it
# in the scene via the appropriate grammar loader. The registry can hold
# many entries that all point at this same scene with different
# (config_path, grammar) parameters — one wrapper, infinite curated
# compositions from the gallery best-of pipeline.
#
# @identity
# essence: a slot that any curated grammar config can pour into — the
#          last-mile bridge from auto-research to a placed map artifact
# desire: walking past a Bauhaus totem, a Vignelli plate, a wallpaper
#         tiling, a Buren column — knowing each was researched, ranked,
#         and chosen, not authored once and forgotten
# critical_parameter: config_path — points at the curated JSON
# triggers: instantiation; apply_grid_config rebuilds with new config
# emerges: composition becomes vocabulary — the sequence's lesson is
#          embodied in the curated arrangement, not just told
# needs: a grammar loader that exposes a build(cfg) -> Node3D function
# relationships: dna_workstation uses the same loaders for VR-side preview
# truth: the lift came from already-curated research, not new generation

extends Node3D
class_name CompositionArtifact

const PrimStack = preload("res://commons/primitive_grammar/primitive_stack.gd")
# Other grammars added as their build() integrations stabilize:
# const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")

## Path to the JSON config (e.g. res://commons/generated/gallery_best_of/configs/...)
@export var config_path: String = ""

## Grammar loader to use. Currently: primitive_stack.
## Future: pattern, lsystem, trajectory, rd, soft_body.
@export var grammar: String = "primitive_stack"

## Override the inline config (Dictionary) — used when bake script has
## already inlined the config and doesn't want a file lookup.
var inline_config: Dictionary = {}


func _ready() -> void:
	_build()


func _build() -> void:
	var cfg: Dictionary
	if not inline_config.is_empty():
		cfg = inline_config
	elif not config_path.is_empty():
		cfg = _load_config(config_path)
	else:
		push_warning("[composition_artifact] No config_path or inline_config set.")
		return
	if cfg.is_empty():
		return
	var node: Node = null
	match grammar:
		"primitive_stack":
			node = PrimStack.build(cfg)
		_:
			push_warning("[composition_artifact] Grammar '%s' not yet wired." % grammar)
			return
	if node:
		add_child(node)


func _load_config(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[composition_artifact] Config not found: %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[composition_artifact] Bad JSON: %s" % path)
		return {}
	return parsed


## Map_data.json hook — registered artifacts get apply_grid_config called
## with the parameters dict from the registry entry.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("config_path"):
		config_path = config["config_path"]
	if config.has("grammar"):
		grammar = config["grammar"]
	if config.has("inline_config") and config["inline_config"] is Dictionary:
		inline_config = config["inline_config"]
	# Rebuild with the new parameters.
	for child in get_children():
		child.queue_free()
	_build()
