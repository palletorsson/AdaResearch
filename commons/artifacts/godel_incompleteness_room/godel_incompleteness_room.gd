extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GodelIncompletenessRoom

## @identity
## name: Godel's Incompleteness — The Gap That Cannot Be Filled
## lineage: Godel, 1931. Any consistent formal system rich enough for arithmetic
##   contains a true statement it cannot prove. You can add the missing sentence
##   as a new axiom — but the larger system has its own unprovable gap.
## essence: a hall whose walls are formal systems, each a tidy lattice of proven
##   theorems with one glowing gold GAP — its Godel sentence — that cannot be
##   filled. Patch one gap and a fresh gap opens elsewhere on the wall.
## truth: every system has a true sentence it cannot prove. Completeness and
##   consistency cannot both hold — there is no final, closed book of mathematics.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var gold: Color = Color(0.98, 0.80, 0.32)
@export var room_size: float = 7.0
@export var patch_period: float = 2.6

var _walls: Array = []  # each entry: { "gaps": Array[MeshInstance3D], "cells": Array[Vector3], "active": int }
var _t: float = 0.0
var _patch_node: MeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_walls = []
	var purple_mat := _glow_mat(wire_purple, 0.5)
	var floor_mat := _matte_mat(Color(0.07, 0.08, 0.13), 0.9)

	# --- floor ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.06, room_size), floor_mat))
	var hs: float = room_size * 0.5
	# chalk border
	add_child(_box(Vector3(0.0, 0.01, hs - 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))
	add_child(_box(Vector3(0.0, 0.01, -hs + 0.1), Vector3(room_size - 0.2, 0.01, 0.02), purple_mat))

	# --- three walls, each a formal system (a lattice of theorem cells) ---
	_build_system_wall(Vector3(0.0, 0.0, -hs + 0.25), 0.0, "ARITHMETIC")
	_build_system_wall(Vector3(-hs + 0.25, 0.0, 0.0), PI * 0.5, "SET THEORY")
	_build_system_wall(Vector3(hs - 0.25, 0.0, 0.0), -PI * 0.5, "LOGIC")

	# the patch token — a gold block that flies in to fill a gap, then a new gap opens
	_patch_node = _box(Vector3(0.0, 1.5, 0.0), Vector3(0.26, 0.26, 0.08), _glow_mat(gold, 1.6))
	add_child(_patch_node)

	# --- overhead title ---
	add_child(_billboard_label("EVERY SYSTEM HAS A TRUE SENTENCE", Vector3(0.0, 3.7, 0.0), 32, cool_white))
	add_child(_billboard_label("IT CANNOT PROVE", Vector3(0.0, 3.4, 0.0), 32, gold))
	add_child(_billboard_label("Godel 1931 — incompleteness", Vector3(0.0, 3.12, 0.0), 16, wire_purple))


func _build_system_wall(base: Vector3, rot_y: float, sys_name: String) -> void:
	var holder := Node3D.new()
	holder.position = base
	holder.rotation.y = rot_y
	add_child(holder)

	var theorem_mat := _glow_mat(cool_white, 0.5)
	var frame_mat := _steel_mat(Color(0.30, 0.32, 0.40))
	var cols: int = 6
	var rows: int = 4
	var cw: float = 0.6
	var ch: float = 0.6
	var x0: float = -float(cols - 1) * 0.5 * cw
	var y0: float = 0.7

	# backing slab
	holder.add_child(_box(Vector3(0.0, y0 + float(rows - 1) * 0.5 * ch, -0.06), Vector3(float(cols) * cw + 0.2, float(rows) * ch + 0.2, 0.04), frame_mat))

	var cells: Array = []
	# pick which cells are the perpetually-empty gap candidates
	var gap_indices: Array = []
	for g in range(3):
		gap_indices.append(_rng.randi_range(0, cols * rows - 1))

	var gaps: Array = []
	for r in range(rows):
		for c in range(cols):
			var idx: int = r * cols + c
			var pos := Vector3(x0 + float(c) * cw, y0 + float(r) * ch, 0.0)
			cells.append(pos)
			if gap_indices.has(idx):
				# a glowing gold-rimmed empty socket (the Godel sentence)
				var rim := _glow_mat(gold, 1.3)
				holder.add_child(_box(pos + Vector3(0.0, 0.0, 0.0), Vector3(cw * 0.86, ch * 0.86, 0.02), _glass_mat(gold, 0.10)))
				var socket: MeshInstance3D = _box(pos + Vector3(0.0, 0.0, 0.015), Vector3(cw * 0.86, ch * 0.06, 0.03), rim)
				holder.add_child(socket)
				holder.add_child(_box(pos + Vector3(0.0, ch * 0.43, 0.015), Vector3(cw * 0.86, ch * 0.06, 0.03), rim))
				holder.add_child(_box(pos + Vector3(0.0, -ch * 0.43, 0.015), Vector3(cw * 0.86, ch * 0.06, 0.03), rim))
				gaps.append(socket)
			else:
				# a proven theorem: a solid white cell with a tiny purple symbol
				holder.add_child(_box(pos, Vector3(cw * 0.82, ch * 0.82, 0.05), theorem_mat))
				holder.add_child(_box(pos + Vector3(0.0, 0.0, 0.03), Vector3(cw * 0.4, 0.02, 0.06), _glow_mat(wire_purple, 0.8)))

	holder.add_child(_billboard_label(sys_name, Vector3(0.0, y0 + float(rows) * ch + 0.1, 0.0), 18, cool_white))
	_walls.append({ "gaps": gaps, "cells": cells, "node": holder })


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# all gold gaps pulse — they cannot be filled
	var pulse: float = 0.5 + 0.5 * sin(_t * 2.5)
	for w in _walls:
		var gaps: Array = w["gaps"]
		for g in gaps:
			var gi: MeshInstance3D = g as MeshInstance3D
			if is_instance_valid(gi):
				var m: StandardMaterial3D = gi.material_override as StandardMaterial3D
				if m != null:
					m.emission_energy_multiplier = (1.3 if emissive else 0.4) * (0.6 + pulse)

	# the patch token flies toward a gap, lands, then a NEW gap "opens" (it leaves)
	if is_instance_valid(_patch_node):
		var phase: float = fmod(_t, patch_period) / patch_period
		# choose a target gap on the front wall deterministically per cycle
		var cycle: int = int(_t / patch_period)
		var wall: Dictionary = _walls[cycle % maxi(_walls.size(), 1)] if _walls.size() > 0 else {}
		var target := Vector3(0.0, 1.5, 0.0)
		if wall.has("gaps") and (wall["gaps"] as Array).size() > 0:
			var gaps: Array = wall["gaps"]
			var node: Node3D = wall["node"]
			var pick: MeshInstance3D = gaps[cycle % gaps.size()] as MeshInstance3D
			if is_instance_valid(pick) and is_instance_valid(node):
				target = node.to_global(pick.position)
		var start := Vector3(0.0, 2.6, 0.0)
		# fly in (0..0.5), hold (0.5..0.8), fly out as the new gap opens (0.8..1.0)
		var here: Vector3
		if phase < 0.5:
			var f: float = phase / 0.5
			here = start.lerp(target, f * f * (3.0 - 2.0 * f))
			_patch_node.visible = true
		elif phase < 0.8:
			here = target
			_patch_node.visible = true
		else:
			var f2: float = (phase - 0.8) / 0.2
			here = target.lerp(start, f2)
			_patch_node.visible = f2 < 0.6  # vanishes — the gap reopens elsewhere
		_patch_node.global_position = here
		_patch_node.rotation.y = _t * 1.5
