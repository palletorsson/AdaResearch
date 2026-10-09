# Tutorial Pattern — Artifacts
*Tiling and Symmetry · second room*

> Arrays hold data. Patterns are data that rhymes. A checkerboard — two values alternating: `grid[y][x] = (x + y) % 2`. A wave — one function swept across indices. Every pattern is an equation the eye solves before the mind catches up.

Primary encounter: `pattern_maker_station` in the east comparison bay, with one editable source, fixed P1/PM reference panels and selectable floor. The book follows this encounter. The other artifacts below remain supporting experiments; this catalogue is not the teaching order.

## Grid Model
![Grid Model](/scene-catalog/grid_model.png)

Miniature interactive model of the map grid — grab cubes to reshape terrain. Teaches layout_data[z][x] = height as a physical 2D array.

`grid_model`

## Pattern Studio Plate
![Pattern Studio Plate](/scene-catalog/pattern_studio_plate.png)

Full pattern design studio ported from Three.js PatternMaker3D. Cream plate with 4x4 paint grid, 3x3 palette, 6 sliders (motif, group, period, size, zone, site), control buttons, and real-time carpet output using all 17 wallpaper symmetry groups. 10 Italian motifs and 5 historical period palettes.

`pattern_studio_plate`

## Pattern Tile Plate
![Pattern Tile Plate](/scene-catalog/pattern_tile_plate.png)

Dieter Rams-styled pattern studio. Paint a 4x4 grid, see it tile into a carpet using 17 wallpaper symmetry groups. Integrated cream plate with palette, preview, and symmetry controls.

`pattern_tile_plate`

## Dark Sphere
![Dark Sphere](/scene-catalog/dark_sphere.png)

USE a neutral sphere as a reference for scale, silhouette, and atmospheric change.

`dark_sphere`

## Mirror Pattern Tile
![Mirror Pattern Tile](/scene-catalog/pattern_tile_mirror.png)

4x4 tile with mirror symmetry (kaleidoscope effect).

`pattern_tile_mirror`

## Pattern Tile Puzzle
![Pattern Tile Puzzle](/scene-catalog/pattern_tile_puzzle.png)

Create patterns on a small tile grid. Watch them repeat across a carpet. Handmade meets computational - from textile traditions to pixel art.

`pattern_tile_puzzle`

## Pattern Maker Station
![Pattern Maker Station](/scene-catalog/pattern_maker_station.png)

Primary in this map. The fixed-motif configuration provides sixteen pointer-capable source cells, eight paints, P1/PM floor selection, source flip/rotation, undo and reset. Two framed panels retain their respective P1 and PM rules. The standard seventeen-group station remains available in other maps.

`pattern_maker_station`

## Panel Bridge — Loom Simulator
![Panel Bridge — Loom Simulator](/scene-catalog/panel_bridge_loom.png)

Three interactive VR panels displaying a weaving draft: threading, tie-up, treadling, and computed drawdown grids. Loaded from Panel Layout JSON exported by the web loom simulator. Click cells to edit the draft; drawdown recomputes in real-time.

`panel_bridge_loom`

## Script Runner
![Script Runner](/scene-catalog/script_runner.png)

Live code display with real Expression evaluation! Shows code executing line-by-line with actual results. Scripts: #point, #vector_math, #array, #pattern, #loop. Example: script_runner#point:90:1

`script_runner`

## Pulsar Compact
![Pulsar Compact](/scene-catalog/pulsar_compact.png)

Smaller pulsar visualization. 20 rows of glass tubes.

`pulsar_compact`
