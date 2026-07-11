# @identity
# essence: scan(utilities_layer) -> spawn(CatalystVent...) -- bridges editor's e:N tokens to the VR catalyst system
# desire: editor's enemy brush writes to utilities; the registry-based interactables system can't read those tokens; this scanner translates one to the other at map load
# critical_parameter: token "e" / "e:RATE" / "e:RATE:WAVE:DELAY:KIND" -- parsed identically to /editor scanVents (KIND is the VR-side extension)
# triggers: scan_utilities() called by GridSystem._scan_catalyst_vents after the utilities layer builds; one CatalystVent instantiated per matching cell
# emerges: editor → save → Godot map → vents spawn -- the same painting works in both surfaces without per-map manual JSON edits
# needs: GridDataComponent for cell→world transform [has via parameter]; CatalystVent scene [has at known path]; utilities array of strings [has]
# relationships: glue between editor's e: tokens and the catalyst_foe/catalyst_vent system; reads grid_data, calls apply_grid_config
# truth: the editor and the VR runtime speak the same token grammar; this scanner is the translator.

# CatalystVentScanner.gd
# Translates editor-painted `e:N:M` utility tokens into CatalystVent
# instances at runtime. Run once after the map's GridDataComponent has
# hydrated.
#
# Usage: GridSystem._scan_catalyst_vents (or any post-load coordinator) calls
#        CatalystVentScanner.scan_utilities(layout, cell_size, origin, parent, opts)
extends Node
class_name CatalystVentScanner

const VENT_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_vent.tscn")

# Foe kinds accepted as the optional 5th token segment. Mirrors
# CatalystFoe.FoeMode (apply_grid_config's foe_mode key).
const FOE_KINDS: Array[String] = ["goo", "transport", "swarm", "drainfriend", "chroma", "wave", "fractal", "branch"]


## Scan a utilities layer for catalyst-vent tokens and instantiate one
## CatalystVent per match under `parent_node`. Returns the count.
##
## utilities: 2D Array of String tokens
## cell_size: world units per cell (typically 1.0)
## origin:    world position of cell (0, 0) — usually the grid's origin
## opts:      optional caller adaptations (all default to /editor behaviour):
##   "cell_inset" (float, default 0.5) — fraction of a cell added to x/z.
##       The /editor convention centres cells at (c + 0.5) * cell_size;
##       GridSystem centres them at c * cell_size, so it passes 0.0.
##   "y_lookup" (Callable(col, row) -> float, default none) — per-cell floor
##       height relative to origin. GridSystem passes the structure surface
##       height so vents seat on the cube top; absent = flat y 0.
##
## Token grammar (matches /editor scanVents):
##   "e"               → emit_interval_s = 2.0, wave_size = 5, start_delay_s = 3
##   "e:RATE"          → emit_interval_s = RATE
##   "e:RATE:M"        → emit_interval_s = RATE, wave_size = M
##   "e:RATE:M:D"      → also start_delay_s = D
##   "e:RATE:M:D:KIND" → also seed each spawned foe's foe_mode (see FOE_KINDS)
static func scan_utilities(
	utilities: Array,
	cell_size: float,
	origin: Vector3,
	parent_node: Node,
	opts: Dictionary = {},
) -> int:
	var cell_inset: float = float(opts.get("cell_inset", 0.5))
	var y_lookup: Callable = opts.get("y_lookup", Callable())
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
			var foe_kind: String = ""
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
			if parts.size() > 4:
				var k: String = parts[4].strip_edges().to_lower()
				if k in FOE_KINDS:
					foe_kind = k
			var inst: Node = VENT_SCENE.instantiate()
			if inst == null:
				continue
			parent_node.add_child(inst)
			var p3: Node3D = inst as Node3D
			if p3 != null:
				var wy: float = 0.0
				if y_lookup.is_valid():
					wy = float(y_lookup.call(c, r))
				p3.global_position = origin + Vector3(
					float(c) * cell_size + cell_size * cell_inset,
					wy,
					float(r) * cell_size + cell_size * cell_inset,
				)
			if inst.has_method("apply_grid_config"):
				var cfg: Dictionary = {
					"emit_interval_s": rate_s,
					"wave_size": wave_size,
					"start_delay_s": start_delay_s,
				}
				if not foe_kind.is_empty():
					cfg["foe_mode"] = foe_kind
				inst.call("apply_grid_config", cfg)
			spawned += 1
	return spawned
