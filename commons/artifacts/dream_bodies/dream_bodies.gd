extends Node3D
class_name DreamBodies

## THE DREAM BODIES (2026-08-29, Palle: "any chance you can recreate some of
## these bodies in godot?" — six AI-generated panoramas of sculptural groups
## from his Stable Diffusion runs: glazed Rocaille figurines with patterned
## skins, two families of De Stijl robots, a Frank Stella wall tangle, pastel
## ceramic dragons, and Haeckel sea forms intertwined).
##
## One artifact, one DNA axis: `figure` picks which body the plinth carries,
## and `seed` picks which individual — every builder draws its proportions,
## lean and palette from a seeded generator, so a seed IS a statue and the same
## seed is the same statue on every machine. Each builder is its own file under
## bodies/, holds nothing but static functions, and reproduces the reference's
## shape language with primitives and SurfaceTool alone: no meshes from disk,
## no shaders, patterns painted into ImageTextures in code.
##
## A dream body is a statue. It has no collider of its own beyond the plinth
## the museum gives it; it is looked at.

const BODY_DIR := "res://commons/artifacts/dream_bodies/bodies/"
const FIGURES: Array[String] = ["rocaille", "stijl_robot", "panel_robot", "stella_wall", "dragon", "sea_forms"]

@export_enum("rocaille", "stijl_robot", "panel_robot", "stella_wall", "dragon", "sea_forms") var figure: String = "rocaille"
@export var seed: int = 1

var _built_figure: String = ""
var _built_seed: int = -1


func apply_grid_config(config: Dictionary) -> void:
	if config.has("figure"):
		var f := String(config.get("figure", "")).to_lower()
		if FIGURES.has(f):
			figure = f
	if config.has("seed"):
		seed = int(config.get("seed", 1))
	if is_inside_tree():
		_build()


func _ready() -> void:
	_build()


## The sentence the builder gives for itself, for a card or a caption.
static func describe(fig: String) -> String:
	var s: Script = load(BODY_DIR + fig + ".gd") as Script
	if s == null or not s.has_method("describe"):
		return ""
	return String(s.call("describe"))


func _build() -> void:
	if _built_figure == figure and _built_seed == seed:
		return
	for c in get_children():
		c.queue_free()
	var path: String = BODY_DIR + figure + ".gd"
	if not ResourceLoader.exists(path):
		push_warning("[dream_bodies] no builder for %s" % figure)
		return
	var s: Script = load(path) as Script
	if s == null or not s.has_method("build"):
		push_warning("[dream_bodies] %s has no build()" % figure)
		return
	var root := Node3D.new()
	root.name = "Body_" + figure
	add_child(root)
	s.call("build", root, seed)
	_built_figure = figure
	_built_seed = seed
