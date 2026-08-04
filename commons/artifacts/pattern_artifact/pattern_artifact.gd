# pattern_artifact.gd
# Placeable wrapper around PatternSim. Renders a wallpaper-group pattern
# config to a 2D image, then displays it on a quad facing up — readable
# as a tile/floor/banner in 3D space.
#
# Mirrors dna_workstation._build_pattern. Same image, same orientation.
#
# --- DNA (stage 2, promoted 2026-08-03) -----------------------------------
# STAGE-2 DNA. One axis: `group`, the wallpaper group.
#
# The seventeen are a CLOSED set — Fedorov: there are exactly seventeen ways a
# pattern can repeat in the plane and there is no eighteenth — so naming one is
# not a style choice, it is the whole claim the tile makes about what its
# symmetry group IS. The names are NOT invented here: they are PatternSim.GROUPS,
# in PatternSim's own IUC order, and PatternSim.group_enum() is the code that
# resolves each of them.
#
# `unset` is the eighteenth value and it is the DEFAULT, because it is what every
# existing placement already does: with no config_path and no group named, this
# artifact has always returned from _ready() without building anything. Keeping
# that as the default is the only way the ten bare `pattern_artifact` tokens
# standing in maps today are left exactly as they are.

extends Node3D
class_name PatternArtifact

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")

## The seventeen wallpaper groups, taken from PatternSim.GROUPS in its own order.
## "unset" is not a group — it means "say nothing; let the config decide, and if
## there is no config, build nothing" — which is what this artifact shipped doing.
const GROUP_NAMES: PackedStringArray = ["unset", "p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm", "p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m"]

## The rest of the DNA when a group is named but no config file is supplied.
## These are PatternSim's own defaults (tile 32, seed 7, bauhaus) with the ONE
## departure the staged corpus already made: a dot motif rather than a random
## one, because a random motif at density 0.5 buries the symmetry in noise and
## the symmetry is the only thing this axis is about.
const DEFAULT_DNA: Dictionary = {
	"tile_size": 32,
	"motif_seed": 7,
	"motif": "dot",
	"radius_factor": 0.38,
	"palette": "bauhaus",
	"canvas_size": 512,
}

@export var config_path: String = ""
@export var quad_size: float = 2.0
@export var face_up: bool = true   # rotate -90° on X to lay flat as tile
@export var vr_preview: bool = true

## AXIS — WHICH OF THE SEVENTEEN THIS TILE OBEYS. p1 is bare translation, the
## weakest statement a repeat can make; p4m is four-fold rotation with mirrors
## (the Alhambra's most common); p6m is the densest, six-fold with reflections.
## Named here, the group overrides whatever a config file says, so a map can
## stand the same motif under two different symmetries side by side.
## "unset" keeps the shipped silence: the config decides, and with no config the
## artifact builds nothing at all.
@export_enum("unset", "p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm", "p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m") var group: String = "unset"

var _current: MeshInstance3D = null


func _ready() -> void:
	# UNCHANGED for every placement that names neither a config nor a group.
	if config_path.strip_edges().is_empty() and group == "unset":
		return
	_build()


func apply_grid_config(cfg: Dictionary) -> void:
	var touched: bool = false
	if cfg.has("config_path"):
		config_path = str(cfg["config_path"])
		touched = true
	if cfg.has("quad_size"):
		quad_size = float(cfg["quad_size"])
		touched = true
	if cfg.has("face_up"):
		face_up = bool(cfg["face_up"])
		touched = true
	if cfg.has("group"):
		# An unrecognised name is IGNORED rather than assigned, so a typo falls
		# back to whatever this placement already had instead of silently
		# rendering p1.
		var g: String = str(cfg["group"]).strip_edges().to_lower()
		if GROUP_NAMES.has(g):
			group = g
			touched = true
	if not touched:
		return
	# Never rebuild before _ready has built once — assigning is enough, _ready
	# picks the values up. Only a live change past that point needs the clear.
	if not is_node_ready():
		return
	_clear()
	_build()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


## The DNA this artifact will render: the config file if there is one, the
## built-in default set if a group was named without one, empty if neither.
func _resolve_dna() -> Dictionary:
	var cfg: Dictionary = {}
	var path: String = config_path.strip_edges()
	if not path.is_empty():
		var txt: String = FileAccess.get_file_as_string(path)
		if not txt.is_empty():
			var j := JSON.new()
			if j.parse(txt) == OK and j.data is Dictionary:
				cfg = j.data
	if cfg.is_empty():
		if group == "unset":
			return {}
		cfg = DEFAULT_DNA.duplicate(true)
	if group != "unset":
		cfg["group"] = group
	return cfg


func _build() -> void:
	var cfg: Dictionary = _resolve_dna()
	if cfg.is_empty(): return
	if vr_preview:
		cfg["canvas_size"] = mini(int(cfg.get("canvas_size", 512)), 256)

	var img: Image = PatternSim.render_to_image(cfg)
	if img == null: return
	var tex := ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(quad_size, quad_size)
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	if face_up:
		mi.rotation_degrees = Vector3(-90, 0, 0)   # face upward — tile read
		mi.position = Vector3(0, 0.05, 0)            # just above the floor
	else:
		mi.position = Vector3(0, quad_size * 0.5, 0)  # billboarded vertical
	add_child(mi)
	_current = mi
