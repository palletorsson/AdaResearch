# Pattern_Disco — shared values, separate clocks

The placement reuses Tutorial_Disco's twelve-by-twelve floor with 0.8 m tiles. `disco_controls#mode:colour` enables a fifth physical button, COLOUR, and begins with palette 1: navy/pink. Four pairs are available: black/white, navy/pink, teal/yellow and violet/mint.

`commons/artifacts/regularity/disco_controls.gd` computes square-cell values through `value_at(x,z,width,depth)` and uses `PALETTES[palette][value]` to colour each fixed instance. `cycle_palette()` advances the palette and calls `paint()` without changing phase, elapsed time or triangle motion. `cycle_pattern()` resets phase, elapsed time and triangle motion to zero. `cycle_speed()` retains the fractional progress through the current interval.

Five modes: CHECKER, ROWS, DIAGONALS, SNAKE and SUPER TRIANGLE. The first four colour whole tiles. SUPER TRIANGLE draws a continuous two-colour image through `super_triangle_surface.gd` and `super_triangle.gdshader`, without new collision. Holding preserves its current intermediate pose; palette changes reach the shader's ink and paper uniforms.

The step sequencer has an independent clock. Its `step_triggered` events address columns through the existing bridge. The console tracks short pulse lifetimes and restores the current pattern colour after expiry, including while the visual clock holds. Footsteps are not inputs to the score.

Native review evidence: `doc/book/iterations/2026-09-28-disco-colour-in-step/`. Controls receive actual pointer callbacks; selected walks use the ordinary museum controller. Musical event checks run with the audio bus muted, so listening quality and headset acceptance remain untested. This pass changes the writing, not the production artifacts or placement.
