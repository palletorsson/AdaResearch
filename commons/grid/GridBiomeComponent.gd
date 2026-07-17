# GridBiomeComponent.gd — the living layer as part of the grid (additive).
#
# doc/plans/biome_grid_redesign.md. Reads the optional `layers.biome` grid
# (BiomeGridTokens grammar: kingdom:algo:role:mods:on=trigger:response),
# holds DECLARED state (from the map file, never mutated) and RUNTIME state
# (what play does — catalyst reactions, CA claims), and stages the cells.
#
# Discipline (walls-layer precedent):
#   - Maps WITHOUT layers.biome never construct any of this (GridSystem gates).
#   - Never touches structure or walkability; the pathfinder is unaffected.
#   - Pilot rendering = primitive kingdom-tinted markers on seed cells
#     (the dispatcher's crown-jewel substrates route in at biome-2;
#     ChunkManager routing is the biome-6 perf gate).
#
# Reactivity (pilot subset of the addendum):
#   react(col, row, trigger) applies the cell's matching responses to the
#   RUNTIME copy only: seed / step (generation counter) / claim (expand into
#   adjacent `field` cells) / mute / unmute. Play never rewrites the map file.

extends Node3D

const BiomeGridTokensScript = preload("res://commons/grid/BiomeGridTokens.gd")

const KINGDOM_COLORS: Dictionary = {
	"flora": Color(0.35, 0.75, 0.35),
	"fungus": Color(0.65, 0.45, 0.8),
	"fauna": Color(0.9, 0.6, 0.3),
	"mineral": Color(0.6, 0.6, 0.65),
	"water": Color(0.35, 0.55, 0.85),
	"meta": Color(0.9, 0.9, 0.9),
	"": Color(0.2, 0.2, 0.2),
}

var _grid_system: Node3D = null
var _cube_size: float = 1.0
var _gutter: float = 0.0
var _declared: Dictionary = {}   # "col,row" -> parsed cell (immutable after generate)
var _runtime: Dictionary = {}    # "col,row" -> {active, muted, generation, claimed_by}
var _structure: Array = []
var _stats: Dictionary = {"cells": 0, "seeds": 0, "fields": 0, "mutes": 0, "halos": 0, "invalid": 0, "reactive": 0}


func initialize(grid_sys: Node3D, cube_size: float, gutter: float) -> void:
	_grid_system = grid_sys
	_cube_size = cube_size
	_gutter = gutter


func generate(biome_layer: Array, structure_layer: Array) -> void:
	_structure = structure_layer
	for row in range(biome_layer.size()):
		var cells: Variant = biome_layer[row]
		if not (cells is Array):
			continue
		for col in range(cells.size()):
			var parsed: Dictionary = BiomeGridTokensScript.parse(cells[col])
			if parsed["empty"]:
				continue
			var key: String = "%d,%d" % [col, row]
			_stats["cells"] += 1
			if not parsed["valid"]:
				_stats["invalid"] += 1
				continue
			_declared[key] = parsed
			_runtime[key] = {
				"active": parsed["role"] == "seed",
				"muted": parsed["role"] == "mute",
				"generation": 0,
				"claimed_by": "",
			}
			match parsed["role"]:
				"seed": _stats["seeds"] += 1
				"field": _stats["fields"] += 1
				"mute": _stats["mutes"] += 1
				"halo": _stats["halos"] += 1
			if not (parsed["reactions"] as Array).is_empty():
				_stats["reactive"] += 1
			if parsed["role"] == "seed" or parsed["role"] == "halo":
				_spawn_marker(col, row, parsed)
	print("GridBiomeComponent: %d biome cells (%d seeds, %d fields, %d mutes, %d halos, %d reactive, %d invalid)" % [
		_stats["cells"], _stats["seeds"], _stats["fields"], _stats["mutes"],
		_stats["halos"], _stats["reactive"], _stats["invalid"]])


# ── reactivity (runtime only; the map file is never rewritten) ──

func react(col: int, row: int, trigger: String) -> Array:
	var key: String = "%d,%d" % [col, row]
	if not _declared.has(key):
		return []
	var applied: Array = []
	var cell: Dictionary = _declared[key]
	for reaction in cell["reactions"]:
		if not _trigger_matches(reaction["trigger"], trigger):
			continue
		for response in reaction["responses"]:
			_apply_response(key, col, row, cell, String(response))
			applied.append(response)
	return applied


func _trigger_matches(declared: String, fired: String) -> bool:
	if declared == fired:
		return true
	# "catalyst" matches any typed "catalyst.<mode>"
	return declared == "catalyst" and fired.begins_with("catalyst.")


func _apply_response(key: String, col: int, row: int, cell: Dictionary, response: String) -> void:
	var state: Dictionary = _runtime[key]
	match response:
		"seed":
			state["active"] = true
		"step":
			state["generation"] = int(state["generation"]) + 1
		"mute":
			state["muted"] = true
		"unmute":
			state["muted"] = false
		"claim":
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nkey: String = "%d,%d" % [col + offset.x, row + offset.y]
				if _declared.has(nkey) and _declared[nkey]["role"] == "field":
					var nstate: Dictionary = _runtime[nkey]
					if not bool(nstate["muted"]) and String(nstate["claimed_by"]).is_empty():
						nstate["claimed_by"] = key
						nstate["active"] = true
						_spawn_marker(col + offset.x, row + offset.y, cell)
		_:
			# mutate:<channel> routes into the mutator stack at biome-2.
			pass


# ── pilot rendering: one small kingdom-tinted marker per active cell ──

func _spawn_marker(col: int, row: int, cell: Dictionary) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	var d: float = BiomeGridTokensScript.density_of(cell)
	var s: float = 0.12 + 0.18 * d
	mesh.size = Vector3(s, s, s)
	marker.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var color: Color = KINGDOM_COLORS.get(cell["kingdom"], KINGDOM_COLORS[""])
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	marker.material_override = mat
	var h: float = _cell_height(col, row)
	var step: float = _cube_size + _gutter
	marker.position = Vector3(col * step, h * _cube_size + s * 0.5 + 0.02, row * step)
	add_child(marker)


func _cell_height(col: int, row: int) -> float:
	if row < _structure.size():
		var cells: Variant = _structure[row]
		if cells is Array and col < (cells as Array).size():
			var v: String = String((cells as Array)[col]).strip_edges()
			if v.is_valid_float():
				return v.to_float()
	return 1.0


# ── introspection (tests + editors) ──

func get_stats() -> Dictionary:
	return _stats.duplicate()


func get_runtime(col: int, row: int) -> Dictionary:
	return _runtime.get("%d,%d" % [col, row], {})
