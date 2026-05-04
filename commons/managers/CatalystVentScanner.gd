# @identity
# essence: scan(utilities_layer) -> spawn(CatalystVent...) -- bridges editor's e:N tokens to the VR catalyst system
# desire: editor's enemy brush writes to utilities; the registry-based interactables system can't read those tokens; this scanner translates one to the other at map load
# critical_parameter: token "e" or "e:RATE" or "e:RATE:WAVE" -- parsed identically to /editor scanVents
# triggers: scan_after_load() called by GridSystem after components hydrate; one CatalystVent instantiated per matching cell
# emerges: editor → save → Godot map → vents spawn -- the same painting works in both surfaces without per-map manual JSON edits
# needs: GridDataComponent for cell→world transform [has via parameter]; CatalystVent scene [has at known path]; utilities array of strings [has]
# relationships: glue between editor's e: tokens and the catalyst_foe/catalyst_vent system; reads grid_data, calls apply_grid_config
# truth: the editor and the VR runtime speak the same token grammar; this scanner is the translator.

# CatalystVentScanner.gd
# Translates editor-painted `e:N:M` utility tokens into CatalystVent
# instances at runtime. Run once after the map's GridDataComponent has
# hydrated.
#
# Usage: GridSystem (or any post-load coordinator) calls
#        CatalystVentScanner.scan_after_load(grid_data, parent_node)
extends Node
class_name CatalystVentScanner

const VENT_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_vent.tscn")


## Scan a utilities layer for catalyst-vent tokens and instantiate one
## CatalystVent per match under `parent_node`. Returns the count.
##
## utilities: 2D Array of String tokens
## cell_size: world units per cell (typically 1.0)
## origin:    world position of cell (0, 0) — usually the grid's origin
##
## Token grammar (matches /editor scanVents):
##   "e"          → emit_interval_s = 2.0, wave_size = 5, start_delay_s = 3
##   "e:RATE"     → emit_interval_s = RATE
##   "e:RATE:M"   → emit_interval_s = RATE, wave_size = M
##   "e:RATE:M:D" → also start_delay_s = D
static func scan_utilities(
	utilities: Array,
	cell_size: float,
	origin: Vector3,
	parent_node: Node,
) -> int:
	var spawned: int = 0
	for r in utilities.size():
		var row: Array = utilities[r]
		if row == null:
			continue
		for c in row.size():
			var tok: String = String(row[c]).strip_edges()
			if tok.is_empty():
				continue
			if not (tok == "e" or tok.begins_with("e:")):
				continue
			var parts: PackedStringArray = tok.split(":")
			var rate_s: float = 2.0
			var wave_size: int = 5
			var start_delay_s: float = 3.0
			if parts.size() > 1:
				var f: float = parts[1].to_float()
				if f > 0.0:
					rate_s = f
			if parts.size() > 2:
				var w: int = parts[2].to_int()
				if w > 0:
					wave_size = w
			if parts.size() > 3:
				var d: float = parts[3].to_float()
				if d >= 0.0:
					start_delay_s = d
			var inst: Node = VENT_SCENE.instantiate()
			if inst == null:
				continue
			parent_node.add_child(inst)
			var p3: Node3D = inst as Node3D
			if p3 != null:
				p3.global_position = origin + Vector3(
					float(c) * cell_size + cell_size * 0.5,
					0.0,
					float(r) * cell_size + cell_size * 0.5,
				)
			if inst.has_method("apply_grid_config"):
				inst.call("apply_grid_config", {
					"emit_interval_s": rate_s,
					"wave_size": wave_size,
					"start_delay_s": start_delay_s,
				})
			spawned += 1
	return spawned
