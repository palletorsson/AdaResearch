# lsystem_artifact.gd
# Placeable wrapper around LSystemSim + LSystemTurtle. Drop in a map with
# config_path pointing at any lsystem-gallery best-of config and the
# turtle walks; tubes render in 3D. Same build path as dna_workstation
# and the research render — packaged here as a placeable artifact.
#
# @identity
# essence: a curated lsystem composition placed in a VR scene
# desire: every starred lsystem finding becomes a walkable tree, not a flat snapshot
# critical_parameter: config_path — the JSON config that drives the rewrite + walk
# triggers: instantiation; apply_grid_config rebuilds with new config
# emerges: gallery-curated branching forms inhabit maps
# needs: a config at config_path, lsystem_grammar scripts present
# relationships: same build code as dna_workstation._build_lsystem and render_lsystem.gd
# truth: the build function is the truth; everything else is wrapping

extends Node3D
class_name LSystemArtifact

const LSystemSim    = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtle = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var config_path: String = ""
@export var vr_preview: bool = true

var _current: Node3D = null


func _ready() -> void:
	if config_path.strip_edges().is_empty(): return
	_build()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("config_path"): config_path = str(cfg["config_path"])
	_clear()
	_build()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


func _build() -> void:
	if config_path.is_empty(): return
	var txt := FileAccess.get_file_as_string(config_path)
	if txt.is_empty():
		push_warning("[lsystem_artifact] config not found: %s" % config_path)
		return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_warning("[lsystem_artifact] bad JSON: %s" % config_path)
		return
	var cfg: Dictionary = j.data
	if vr_preview:
		cfg["iterations"] = mini(int(cfg.get("iterations", 4)), 4)

	var axiom: String = str(cfg.get("axiom", "F"))
	var rules: Dictionary = cfg.get("rules", {})
	var iters: int = int(cfg.get("iterations", 4))
	var seed_val: int = int(cfg.get("seed", 0))
	var has_stoch := false
	for k in rules.keys():
		if rules[k] is Array: has_stoch = true; break
	var s: String
	if has_stoch:
		s = LSystemSim.rewrite_stochastic(axiom, rules, iters, seed_val)
	else:
		s = LSystemSim.rewrite(axiom, rules, iters)
	var walk: Dictionary = LSystemTurtle.walk(s, {
		"angle_deg":    float(cfg.get("angle_deg", 25.7)),
		"step_len":     float(cfg.get("step_len", 0.1)),
		"step_shrink":  float(cfg.get("step_shrink", 0.72)),
		"base_width":   float(cfg.get("base_width", 0.02)),
		"width_shrink": float(cfg.get("width_shrink", 0.75)),
	})
	var ct := _color_or(cfg.get("color_trunk", null), Color(0.45, 0.28, 0.12))
	var cp := _color_or(cfg.get("color_tip", null), Color(0.2, 0.65, 0.15))
	var node := LSystemTurtle.to_tubes(walk, ct, cp, int(cfg.get("tube_sides", 6)))
	if node:
		_current = node
		add_child(node)


func _color_or(v, fallback: Color) -> Color:
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]),
		             float(a[3]) if a.size() >= 4 else 1.0)
	return fallback
