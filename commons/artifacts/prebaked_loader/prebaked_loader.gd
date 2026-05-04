# prebaked_loader.gd
# Loads a pre-baked PackedScene of a DNA finding and instantiates it as a child.
# Replaces the live-render artifact wrappers (rd_artifact, lsystem_artifact,
# mesh_grammar_artifact, etc.) for placements that don't need fresh
# randomness — the geometry was computed once at curation time, saved to
# disk, and now loads in milliseconds instead of recomputing.
#
# This is the VR-friendly path. Use this for everything by default; fall
# back to the live wrappers only when per-placement parameters need to
# vary at runtime.
#
# @identity
# essence: load a pre-rendered finding instead of regenerating it
# desire: maps with 20+ DNA findings open in <1s instead of 30s
# critical_parameter: scene_path — res:// path to the .tscn
# triggers: instantiation; apply_grid_config swaps to a different scene
# emerges: VR-scale curation density — every map can carry many findings
# needs: bake pipeline to have produced the .tscn beforehand
# relationships: the federation's "static" path; live wrappers are the
#   "dynamic" path for fresh-randomness placements
# truth: a snapshot is enough when the snapshot is what was curated

extends Node3D
class_name PrebakedLoader

@export var scene_path: String = ""
## Uniform scale applied to the loaded scene. The composition's intrinsic
## base_scale is set at bake time; this multiplies it at placement time.
## Useful for primitive_stack findings (typical base_scale=0.25) that read
## small at map scale — pass scale=4 for furniture-readable size.
@export var scale_factor: float = 1.0
@export var y_offset: float = 0.0   # lift above the host cell

var _current: Node = null


func _ready() -> void:
	if scene_path.strip_edges().is_empty(): return
	_load()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("scene_path"):   scene_path = String(cfg["scene_path"])
	if cfg.has("scale_factor"): scale_factor = float(cfg["scale_factor"])
	if cfg.has("scale"):        scale_factor = float(cfg["scale"])  # alias
	if cfg.has("y_offset"):     y_offset = float(cfg["y_offset"])
	_clear()
	_load()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


func _load() -> void:
	if scene_path.is_empty(): return
	if not ResourceLoader.exists(scene_path):
		push_warning("[prebaked_loader] scene not found: %s" % scene_path)
		return
	var ps := load(scene_path)
	if not (ps is PackedScene):
		push_warning("[prebaked_loader] not a PackedScene: %s" % scene_path)
		return
	var node := (ps as PackedScene).instantiate()
	if node:
		add_child(node)
		_current = node
		# Apply per-instance scale + lift after the scene's own transform
		# is in place. Wrapping in a parent Node3D keeps original transforms
		# intact while scaling the whole subtree visually.
		if node is Node3D and (scale_factor != 1.0 or y_offset != 0.0):
			(node as Node3D).scale = Vector3.ONE * scale_factor
			(node as Node3D).position += Vector3(0, y_offset, 0)
