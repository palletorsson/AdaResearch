# ===========================================================================
# NOC Example 8.4: Cantor Set
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.4: Cantor Set
## Recursive division creating the Cantor set fractal
## Chapter 08: Fractals

# @identity
# essence: cantor(start, width, d) = line(start, width) + cantor(left_third, d+1) + cantor(right_third, d+1)
# desire: To be read like a poem — each row shorter, the gaps widening, pink lines fading downward into infinity
# critical_parameter: vertical_spacing — the gap between rows makes the fractal readable; too close and it blurs, too far and the pattern disconnects
# triggers: Recursion descends row by row; emission intensity fades with depth; width shrinks by 1/3 per level
# emerges: The visual rhythm of removal — the eye learns to see what is missing, not what remains
# needs: VR depth control [missing], animation mode [missing]
# relationships: Classic NOC translation; the 2D visualization that precedes the physical cantor_set (RigidBody) and cantor_pagoda (walkable)
# truth: The Cantor set teaches subtraction as a creative act — what you remove defines what remains.

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_depth: int = 6
@export var initial_width: float = 0.8
@export var vertical_spacing: float = 0.08

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — hand promotion 2026-08-05. The runner refused this token
#  for NO TURNABLE KNOBS: the three exports above are a count and two
#  sizes, apply_grid_config's whole body was `pass`, and so no map has
#  ever been able to say anything to this artifact at all.
#
#  tick     — how many removals the record carries. Taken from
#             cantor_set / zeno_staircase character for character, and
#             the levels table is cantor_set's own, copied rung for rung.
#  removal  — what the drawing does with the middle third it deleted.
#             cantor_set's word, and the question this file's @identity
#             already claims to be about ("the eye learns to see what is
#             missing, not what remains") while drawing nothing at all
#             where the middle used to be.
#
#  THE SHIPPED DEPTH IS A LIE AND `tick` HAD TO BE BUILT AROUND IT.
#  max_depth = 6 has never been reached: the recursion also stops when a
#  segment falls under MIN_SEGMENT_WIDTH, and 0.8 / 3^4 = 0.0099 is under
#  0.01, so every placement since this file was written has drawn FOUR
#  rows — three removals — and stopped. `fine` = 3 is therefore the
#  shipped rung and the default, and it SHORT-CIRCUITS: max_depth stays 6,
#  the width floor stays 0.01, and the stop happens for the same reason at
#  the same row. Nothing above `fine` is reachable without relaxing that
#  floor, which is why _min_width() relaxes it exactly as far as the
#  requested rung needs and not one step further.
#
#  max_depth is deliberately NOT re-derived from tick: it is also the
#  denominator of the per-row fade (intensity = 1 - depth/max_depth), so
#  writing the rung into it would repaint every surviving row on a sweep
#  that is supposed to be about how far the record goes.
# ─────────────────────────────────────────────────────────────────────

const MIN_SEGMENT_WIDTH := 0.01
const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 3, "dense": 4, "limit": 5}
const REMOVALS := ["gone", "ghost", "scar"]

@export_enum("once", "coarse", "fine", "dense", "limit") var tick: String = "fine"
@export_enum("gone", "ghost", "scar") var removal: String = "gone"

var _sim_root: Node3D
var _status_label: Label3D
var _built: bool = false

func _ready() -> void:
	_build()
	set_process(false)
	_built = true

func _build() -> void:
	_setup_environment()
	_draw_cantor(Vector3(-initial_width/2, 0.3, 0), initial_width, 0)

# How many removals this record carries. Default "fine" = 3, which is what the
# shipped width floor has always allowed through.
func _levels() -> int:
	return int(TICK_LEVELS.get(tick, 3))

# The smallest segment the recursion will draw. "fine" hands back the shipped
# literal verbatim rather than deriving it, so the default cannot drift; the other
# rungs relax it only as far as their own deepest row needs. `once` and `coarse`
# are capped by _levels() long before the floor matters, so this returns 0.01 for
# them too — only `dense` and `limit` ever move it.
func _min_width() -> float:
	if tick == "fine":
		return MIN_SEGMENT_WIDTH
	var reach: float = initial_width / pow(3.0, float(_levels()))
	return minf(MIN_SEGMENT_WIDTH, reach * 0.5)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_status_label.text = "Cantor Set | Depth: %d" % max_depth
	# The shipped line is kept byte for byte at the default; a non-default rung says
	# so rather than letting the readout claim a depth the recursion is not running.
	if tick != "fine":
		_status_label.text += "  ·  %s (%d)" % [tick, _levels()]
	_sim_root.add_child(_status_label)

func _draw_cantor(start: Vector3, width: float, depth: int) -> void:
	if depth > max_depth or depth > _levels() or width < _min_width():
		return

	# Draw line segment
	_create_line(start, width, depth)

	# Recurse: divide into thirds, keep first and last third
	var new_width := width / 3.0
	var next_y := start.y - vertical_spacing

	# The middle third — the thing the rule DELETES, and until now the only part of
	# this drawing with no representation at all. Drawn only when `removal` asks for
	# it, and only when the row it belongs to is itself drawn: the record's extent
	# (and therefore the capture's AABB) is identical at all three values.
	if removal != "gone" and _row_is_drawn(depth + 1, new_width):
		_create_removed(Vector3(start.x + new_width * 1.5, next_y, start.z), new_width)

	# Left third
	_draw_cantor(Vector3(start.x, next_y, start.z), new_width, depth + 1)

	# Right third (skip middle third)
	_draw_cantor(Vector3(start.x + 2.0 * new_width, next_y, start.z), new_width, depth + 1)

# The same three tests _draw_cantor opens with, asked ahead of the recursion.
func _row_is_drawn(depth: int, width: float) -> bool:
	return depth <= max_depth and depth <= _levels() and width >= _min_width()

func _create_line(start: Vector3, width: float, depth: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.015, 0.02)
	mesh_instance.mesh = box
	mesh_instance.position = start + Vector3(width/2, 0, 0)

	var material := StandardMaterial3D.new()
	var intensity := 1.0 - (float(depth) / float(max_depth)) * 0.4
	material.albedo_color = Color(1.0, 0.5 + intensity * 0.4, 0.9)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.6
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)

# The middles the rule threw away. `gone` never reaches here and draws nothing at
# all, which is what this file has always done; `ghost` restores each removed third
# as a pale full-thickness volume, so a row reads as the whole interval with its
# holes marked and the eye can watch measure leaving; `scar` leaves a thin dark rod
# at 22 percent of the bar's section where the third used to be, so the row reads as
# a comb rather than as scattered dust. Colours, alpha and the 0.22 are cantor_set's,
# reused unchanged so the two Cantors photograph alike.
func _create_removed(center: Vector3, width: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	var thin: float = 1.0 if removal == "ghost" else 0.22
	box.size = Vector3(width, 0.015 * thin, 0.02 * thin)
	mesh_instance.mesh = box
	mesh_instance.position = center

	var material := StandardMaterial3D.new()
	if removal == "ghost":
		material.albedo_color = Color(0.86, 0.88, 0.96, 0.16)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		material.albedo_color = Color(0.09, 0.09, 0.11)
		material.metallic = 0.0
		material.roughness = 1.0
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# Tear the drawing down and lay it out again. remove_child is immediate, so the old
# root is out of the tree before the new one goes in and no frame ever shows two.
func _rebuild() -> void:
	if _sim_root != null and is_instance_valid(_sim_root):
		remove_child(_sim_root)
		_sim_root.queue_free()
	_sim_root = null
	_status_label = null
	_build()


## Reads the two declared axes, and the three sizes that were exported but
## unreachable because this function's whole body used to be `pass`.
##
## GUARDED TWICE ON PURPOSE. A value is taken only when it validates AND differs,
## and the rebuild fires only after the first build has happened. All six existing
## placements carry the bare token with no config keys at all, so they never reach
## _rebuild() and are byte-identical to before this promotion.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return

	var changed: bool = false

	if config.has("tick"):
		var t: String = str(config["tick"]).strip_edges().to_lower()
		if TICK_LEVELS.has(t) and t != tick:
			tick = t
			changed = true

	if config.has("removal"):
		var r: String = str(config["removal"]).strip_edges().to_lower()
		if REMOVALS.has(r) and r != removal:
			removal = r
			changed = true

	if config.has("max_depth"):
		var d: int = int(config["max_depth"])
		if d != max_depth:
			max_depth = d
			changed = true

	if config.has("initial_width"):
		var w: float = float(config["initial_width"])
		if not is_equal_approx(w, initial_width):
			initial_width = w
			changed = true

	if config.has("vertical_spacing"):
		var s: float = float(config["vertical_spacing"])
		if not is_equal_approx(s, vertical_spacing):
			vertical_spacing = s
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to tear down — _ready() will pick the
	# new values up when it runs.
	if not _built:
		return
	_rebuild()
