# The row, the rug and the network

Builds on arrays, binary state, bounded history, random initial conditions and sampled noise fields. Prepares for the 26-neighbour multistate specimen in CA_ElementaryRules. The historical room title is retained; the next specimen does not enumerate the 256 elementary rules.

## Elementary row

Source: `commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd`. The optional `study:neighbours` placement uses 32 Boolean cells, 24 history rows, a 1.6 m board, Rule 90 and a held initial state. Unconfigured instances retain their 64-cell, 50-row, 1 m defaults and keyboard controls.

The three bits index one of eight outputs stored in the rule integer. There are 256 possible assignments of these eight output bits.

```gdscript
func _apply_rule(left: bool, center: bool, right: bool) -> bool:
	var neighborhood = (int(left) << 2) | (int(center) << 1) | int(right)
	return (rule >> neighborhood) & 1 == 1
```

The exact update retains a bounded display history, newest row first:

```gdscript
func _advance() -> void:
	var new_row: Array[bool] = []
	new_row.resize(cells_x)

	for i in range(cells_x):
		var left = _current_row[(i - 1 + cells_x) % cells_x]
		var center = _current_row[i]
		var right = _current_row[(i + 1) % cells_x]
		new_row[i] = _apply_rule(left, center, right)

	_current_row = new_row
	generation += 1
	_grid.push_front(new_row.duplicate())

	while _grid.size() > rows_visible:
		_grid.pop_back()

	_update_display()
```

All neighbour reads use the old row. This is synchronous state updating implemented with a sequential loop and a separate output array. Parallel hardware is not required. Modulo wraps the ends. The visible rectangular history is not a 2D spatial automaton: one axis is cell index, the other is recorded time.

The study begins with one seed, or two adjacent seeds after SEED. Rule changes and RST reset to the selected seed; SEED and STEP hold the study. RUN toggles automatic updates. CELL advances the inspected index with wrapping. The readout predicts the next generation from the currently displayed row; after STEP it updates to predict the following generation. Its three marks do not replace the original on/off colours.

The shared reset repair clears unused MultiMesh rows and the partial clock interval. Without clearing the unused rows, an old pattern remained visible underneath a new seed. A generation counter counts advances since the most recent reset, independently of the number of retained history rows.

## Rug

Source: `algorithms/cellularautomata/persian_rug/persian_rug.gd`. A 256 by 384 PackedByteArray grid has wrapped eight-neighbour reads, distinct border/interior birth and survival lists, and four/five-state decay respectively. The active value used for neighbour comparison is selected by the receiving cell's region. No uniform-rule claim spans the frame and field.

After swapping buffers, `_enforce_symmetry()` calls `_enforce_quadrant()` for the configured default. Thus four-fold symmetry is actively imposed after every generation. Texture rows are uploaded incrementally; the display can briefly contain rows from different upload stages even though the state calculation uses buffers. The map retains the full-size flat rug and raises its plane to .025 m above the museum deck.

## Line network

Sources: `algorithms/cellularautomata/ca_showcase/LineNetworkCA.gd` and `base_ca.gd`. A 64-cubed occupancy grid starts with a bounded random walk. Growth attempts append cells to a persistent frontier; occupancy is changed while the frontier is scanned, so duplicate proposals in that scan can see prior writes. The visualizer selects a recorded adjacent position as a parent after the growth update. That record is a drawing choice, not a causal birth log. Growth attempts stop after twenty update frames. The base loop continues visualization scans afterwards; this is a remaining performance/restart review target.

## Placement and verification

All nine authored placements remain, and all structure/utility cells remain. The explorer moves from (10,12) to (10,4), rotates 180 degrees toward entry and rises 1.04 m onto local study furniture. The rug stays at (4,4). The museum placement row is regenerated from the current map. The converter still maps authored numeric tiers 3/4/5 to tile 4; distinct-height recovery remains a spatial review item.

GDScript grammar and data/source consistency can be checked without launching Godot. The prepared in-engine probe checks actual multimesh reset, rule updates, witness predictions, local ownership and desktop pointer actions. Its run status belongs in field_notes.md and the illustrated review. Source preparation is not a completed VR test.
