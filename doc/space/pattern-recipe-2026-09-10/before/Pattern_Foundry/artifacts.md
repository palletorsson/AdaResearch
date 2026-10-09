# Pattern Foundry — Artifacts
*Color and Composition · F_order · 4 artifacts*

> Four machines stand in a long hall, each one a different way of making a pattern. A loom pulls glowing warp threads through a weave bar. A print head extrudes a repeating motif. A mill drum spins kaleidoscope mirrors. A cast-iron press stamps an editable matrix into rows. Walk the aisle and watch structure get manufactured before any color touches it — pattern is the loom that color later threads through.

The map, read through what it holds — its artifacts in the order you meet them:

## Kaleidoscope Mill
![Kaleidoscope Mill](/scene-catalog/pattern_machine_c.png)

Dark industrial frame on a bolted plinth: gantry columns, a glowing mill drum with spinning kaleidoscope mirror-wedge rotors, a warp-thread cage with a pulsing weave bar, an editable hopper grid on the head, palette + control button rows, an emissive output chute, and a live wallpaper-group carpet milled onto the floor. Touch-paint the hopper to feed the mill; the carpet re-tiles instantly. DNA: group (p1..p6m), palette, motif_seed, hopper_size, carpet params, rotor_speed.

`pattern_machine_c`

## Pattern Machine A — Jacquard Punch-Card Loom
![Pattern Machine A — Jacquard Punch-Card Loom](/scene-catalog/pattern_machine_a.png)

Dark machine frame with side posts, top crossbeam, glowing amber warp threads, a pulsing weave bar and feed roller. On the head sits an interactive NxN punch card: touch a peg to toggle it (empty <-> punched color), PUNCH cycles the paint color, GROUP cycles the 17 symmetry programs, WEAVE re-rolls a fresh motif, CLEAR blanks it. Every edit re-weaves the live wallpaper carpet that scrolls out across the floor. DNA: group (p1..p6m), palette, motif_seed, card_size, density, carpet_repeats.

`pattern_machine_a`

## Pattern Printer (Holographic Press)
![Pattern Printer (Holographic Press)](/scene-catalog/pattern_machine_b.png)

Dark machine frame with emissive accent rails, a print head with a glowing extrusion slot + spinning feed roller, and a tilted holographic edit console. Touch the holo cells to paint; INK buttons pick the color, CYCLE advances the wallpaper group, SEED rerolls the motif, CLEAR blanks it, PRINT flashes the head. Output updates live as a vertical printed sheet scrolling up and a floor carpet scrolling forward. DNA: group (p1..p6m), palette, motif_seed, motif_size, density, machine dimensions.

`pattern_machine_b`

## Pattern Machine D — Tile-Stamp Press
![Pattern Machine D — Tile-Stamp Press](/scene-catalog/pattern_machine_d.png)

A cast-iron press chassis with side cheeks, a crown beam, an angled editable stamp matrix, a press head on guide rods + a pull lever, ink-well palette buttons, GROUP / PRESS / CLEAR controls, a PatternSim proof sheet on the crown, and a conveyor tray that feeds the printed carpet off the front. Touch-paint the bed; output updates live; pull the press to punch + re-stamp. DNA: group (p1..p6m), palette, motif_seed, matrix_size, carpet/feed params.

`pattern_machine_d`
