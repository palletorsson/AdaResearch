# Rewriting, interpretation and display fitting

LSystems_Grammar_Lab follows Fractal_Synthesis and precedes LSystems_Growth. The primary is `lsystem_editor:180#lesson:true#grammar:koch#depth:1`. Lesson startup deliberately resets the actual generation to zero; the existing DNA value depth=0 still means the preset's default generation count elsewhere.

## Installed interaction

The opt-in GrammarLesson attaches to the existing editor. Its compact three-by-two desk uses full-sized push buttons at 1.045 m with a small tilted transparent readout. NEXT requests generations 0–4; TURN cycles 30/60/90/120 degrees; HOLD copies the current sentence, angle and fitted geometry; PRESET cycles the seven existing grammars and returns to generation zero; RESET returns both views to the initial Koch F at 90 degrees; RULE displays the actual replacement dictionary. PRESET may change both grammar and angle, so it is not a single-variable angle comparison.

The held snapshot contains copies of the sentence and the exact segment endpoints produced by the editor. It is not regenerated when the live angle changes. Rendering uses thin cylinder instances, without segment colliders. Each view is independently fitted to a 3.4 m display, so comparisons show shape and correspondence, not an absolute common segment-length scale. The relation label states this fitting. Only the first 120 text symbols are printed for long strings, explicitly labelled; the full accepted sentence still generates the geometry.

## Actual source and corrections

`lsystem_editor.gd` first rewrites each old symbol once into a new string. `_rules.get(c, c)` preserves symbols without productions. It then interprets F/G as drawing, f as travel without drawing, +/- as turns, and brackets as push/pop of position, direction and right. Other symbols such as X do not draw. This is a planar turtle embedded in the 3D museum; no extra pitch or roll instructions have been added.

The preset dictionaries are unchanged. Its named Koch Curve uses F -> F+F-F-F+F, not the earlier hall's equilateral snowflake. After n rewrites it draws 5^n segments; total string length is 2*5^n-1. At generation four that is 625 segments and 1249 symbols. Plant starts with X and rewrites first to F+[[X]-X]-F[-FX]+X, drawing three F segments. Sierpinski starts F-G-G and retains its declared 120-degree angle.

Angle changes now redraw without invoking rewriting. The former 90-degree ceiling clipped the Sierpinski preset; the supported range is now 5–180 degrees. The missing deferred slider sync method is implemented. `set_rules()` now selects Custom (index 7) without overwriting the supplied dictionary with Binary Tree. Ordinary placements retain their sliders and seven presets. Empty and non-drawing sentences produce no invalid mesh surface; bounds include both segment endpoints.

Before constructing the next sentence, the editor sums replacement lengths. A generation that would exceed max_symbols is refused in its entirety, preserving the last complete sentence and balanced branches supplied by the presets. The lesson budget is 4096 symbols; the ordinary editor retains a 100000-symbol budget. An over-budget axiom is rejected and flagged. Requested/effective generation counts differ when capped; this count is not entropy or a frame-rate measurement. Unbalanced custom productions are not automatically repaired.

## Museum and preservation

The former 13×12 layout is embedded at offset (3,14) in a 19×26 enclosure. Its raised teaching platform and central passage remain. The unused teleporter floor hole is filled. The editor moves to the approach, the oversized science screen is reduced, and local lights support the comparison. All eight original tokens remain, with their other placements carried into the retained layout. The visitor goes around the plinths, then through the former central platform gap to the rear exit. The drawings themselves provide neither walkable branches nor a new collision topology.

Earlier map, texts, editor and historical grid configurations are archived under doc/space/grammar-lab-2026-09-14. Existing critical themes are retained as questions while unsupported claims that a final string always contains its entire history, that presets prove a biological complexity threshold, and that the visitor can type rules have been corrected. Desktop acceptance tests exercise the real pointer path, all desk operations, ordinary presets, the custom API, budget behavior and the walk to the exit. Human headset reach, readability, comfort and Quest frame time remain pending.
