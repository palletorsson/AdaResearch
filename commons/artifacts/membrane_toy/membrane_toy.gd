extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MembraneToy

## @identity
## name: "The membrane"
## tier: small
## lineage: A held patch of lipid bilayer — two rows of phospholipid heads, tails facing
##   inward, the oldest boundary life ever drew. A single particle slips across to show the
##   membrane is a gate, not a wall.
## truth: "THE BOUNDARY THAT MAKES AN INSIDE WHILE LETTING THE WORLD ACROSS"
## applications: cell membranes, liposomes, drug carriers, the Markov blanket — surfaces that
##   separate a self from its world without sealing it off.

const HEADS: int = 9        # phospholipids per row

@export var span: float = 0.34
@export var head_r: float = 0.022
@export var head_col: Color = Color(0.95, 0.72, 0.30)
@export var tail_col: Color = Color(0.45, 0.55, 0.92)
@export var cross_col: Color = Color(0.40, 0.95, 0.70)
@export var label_col: Color = Color(0.95, 0.92, 0.80)

var _t: float = 0.0
var _crosser: MeshInstance3D = null
var _mid_y: float = 0.18


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("span"):
		span = clampf(float(config["span"]), 0.22, 0.5)
	if config.has("head_col"):
		head_col = _parse_color(config["head_col"], head_col)
	if config.has("tail_col"):
		tail_col = _parse_color(config["tail_col"], tail_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_crosser = null
	_build()


func _build() -> void:
	var head_mat := _glow_mat(head_col, 0.4)
	var tail_mat := _matte_mat(tail_col, 0.5)
	var gap: float = span / float(HEADS - 1)
	var tail_len: float = 0.05

	# Two leaflets, heads out, tails meeting in the middle.
	# Upper leaflet: heads at top, tails point down.
	# Lower leaflet: heads at bottom, tails point up.
	for i in range(HEADS):
		var x: float = (float(i) - float(HEADS - 1) * 0.5) * gap
		var sway: float = 0.0
		var top_head := Vector3(x, _mid_y + tail_len, sway)
		var top_tail := Vector3(x, _mid_y, sway)
		var bot_head := Vector3(x, _mid_y - tail_len * 2.0, sway)
		var bot_tail := Vector3(x, _mid_y - tail_len, sway)
		add_child(_sphere(top_head, head_r, head_mat))
		add_child(_sphere(bot_head, head_r, head_mat))
		add_child(_cylinder_between(top_head, top_tail, head_r * 0.35, tail_mat))
		add_child(_cylinder_between(bot_head, bot_tail, head_r * 0.35, tail_mat))

	# Frame ring so it reads as a held patch.
	add_child(_torus(Vector3(0.0, _mid_y - tail_len * 0.5, 0.0), span * 0.62, 0.008, _steel_mat(Color(0.5, 0.5, 0.55))))

	# A lone particle crossing the bilayer — the gate in action.
	_crosser = _sphere(Vector3(0.0, _mid_y, 0.0), head_r * 0.7, _glow_mat(cross_col, 0.9))
	add_child(_crosser)

	add_child(_billboard_label("THE BOUNDARY THAT MAKES AN INSIDE,\nWHILE LETTING THE WORLD ACROSS", Vector3(0.0, _mid_y + 0.22, 0.0), 13, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Particle migrates up and down through the bilayer.
	if _crosser != null:
		var phase: float = sin(_t * 1.1) * 0.5 + 0.5
		_crosser.position.y = _mid_y - 0.075 + phase * 0.15
		_crosser.position.x = sin(_t * 0.7) * 0.04
	# Gentle whole-patch breathing sway.
	rotation.z = sin(_t * 0.8) * 0.025
