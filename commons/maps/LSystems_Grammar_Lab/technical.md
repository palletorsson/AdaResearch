# Rewriting, interpretation and display fitting

LSystems_Grammar_Lab follows Fractal_Synthesis and precedes LSystems_Growth. The primary is `lsystem_editor:180#lesson:true#grammar:koch#depth:1`. Lesson startup deliberately resets the actual generation to zero; the existing DNA value depth=0 still means the preset's default generation count elsewhere.

## Installed interaction

The opt-in GrammarLesson attaches to the existing editor. Its compact three-by-two desk uses full-sized push buttons at 1.045 m with a small tilted transparent readout. NEXT requests generations 0–4; TURN cycles 30/60/90/120 degrees; HOLD copies the current sentence, angle and fitted geometry; PRESET cycles eight grammars, including Cantor and returns to generation zero; RESET returns both views to the initial Koch F at 90 degrees; RULE displays the actual replacement dictionary. PRESET may change both grammar and angle, so it is not a single-variable angle comparison.

The held snapshot contains copies of the sentence and the exact segment endpoints produced by the editor. It is not regenerated when the live angle changes. Rendering uses thin cylinder instances, without segment colliders. Each view is independently fitted to a 3.4 m display, so comparisons show shape and correspondence, not an absolute common segment-length scale. The relation label states this fitting. Only the first 120 text symbols are printed for long strings, explicitly labelled; the full accepted sentence still generates the geometry.

## Actual source and corrections

`lsystem_editor.gd` first rewrites each old symbol once into a new string. `_rules.get(c, c)` preserves symbols without productions. It then interprets F/G as drawing, f as travel without drawing, +/- as turns, and brackets as push/pop of position, direction and right. Other symbols such as X do not draw. This is a planar turtle embedded in the 3D museum; no extra pitch or roll instructions have been added.

The preset dictionaries are unchanged. Its named Koch Curve uses F -> F+F-F-F+F, not the earlier hall's equilateral snowflake. After n rewrites it draws 5^n segments; total string length is 2*5^n-1. At generation four that is 625 segments and 1249 symbols. Plant starts with X and rewrites first to F+[[X]-X]-F[-FX]+X, drawing three F segments. Sierpinski starts F-G-G and retains its declared 120-degree angle.

Angle changes now redraw without invoking rewriting. The former 90-degree ceiling clipped the Sierpinski preset; the supported range is now 5–180 degrees. The missing deferred slider sync method is implemented. `set_rules()` now selects Custom (index 8) without overwriting the supplied dictionary with Binary Tree. Ordinary placements retain their sliders and eight presets. Empty and non-drawing sentences produce no invalid mesh surface; bounds include both segment endpoints.

Before constructing the next sentence, the editor sums replacement lengths. A generation that would exceed max_symbols is refused in its entirety, preserving the last complete sentence and balanced branches supplied by the presets. The lesson budget is 4096 symbols; the ordinary editor retains a 100000-symbol budget. An over-budget axiom is rejected and flagged. Requested/effective generation counts differ when capped; this count is not entropy or a frame-rate measurement. Unbalanced custom productions are not automatically repaired.

## Museum and preservation

The former 13×12 layout is embedded at offset (3,14) in a 19×26 enclosure. Its raised teaching platform and central passage remain. The unused teleporter floor hole is filled. The editor moves to the approach, the oversized science screen is reduced, and local lights support the comparison. All eight original tokens remain, with their other placements carried into the retained layout. The visitor goes around the plinths, then through the former central platform gap to the rear exit. The drawings themselves provide neither walkable branches nor a new collision topology.

Earlier map, texts, editor and historical grid configurations are archived under doc/space/grammar-lab-2026-09-14. Existing critical themes are retained as questions while unsupported claims that a final string always contains its entire history, that presets prove a biological complexity threshold, and that the visitor can type rules have been corrected. Desktop acceptance tests exercise the real pointer path, all desk operations, ordinary presets, the custom API, budget behavior and the walk to the exit. Human headset reach, readability, comfort and Quest frame time remain pending.


## Complete opening lesson — 9 October 2026

The tutorial now prints four complete files under `doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab`. `grammar.gd` owns parallel replacement and the planar F/G/f/+/- reader. `sentence.gd` constructs both readings and all input/labels. PointBody and LineSkin are byte-identical to their previous Fractals lessons. The prepared museum remains the host. The compact reader rejects brackets; the full editor retains its existing stack. In the compact program R resets live only; the installed RESET resets the whole comparison. These controls are declared separately in the tutorial.

`grammar_hand.gd` adds the carried point to the current six-button desk. Local X chooses 30/60/90/120; held action calls NEXT. Angle edits invoke the existing setter without rewriting. Release parks the point. Preset-native angles remain until the visitor picks up the point, when it selects the nearest offered angle; no unheld quantization. Cantor, already preset7 in the generator, is now reachable by the lesson button; the cycle changes7 to8 and its label names Cantor. No editor algorithm change.

The onward token moves from blocked source(8,23) to the rear opening(9,25). Structure and all eight authored placements are unchanged. Actual route checks use source map coordinates: the museum hall transform also includes a four-metre lobby offset and cannot be treated as the source map origin.

31 native printed-file checks and 28 museum checks pass. Forty rule/depth/angle combinations agree with production after normalizing the fitted endpoints; the changed FplusF file is executed independently. Both bypasses and the rear route pass188 capsule/floor samples; entry/exit approaches validate. A full player crossing, physical headset reach, Quest performance and an independent ghost-student assessment are not claimed. The preserved first code run had an early test-harness XRTools type-load diagnostic; runtime assertions passed, and removing that eager type dependency gave a clean rerun. The first museum run miscounted generic fixtures as authored works and used the lobby-shifted frame for routes; both test assumptions are corrected and archived.

Report: doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading/index.html. Existing blank wall frames and rear collection label density remain visible follow-up items, not hidden by this tutorial pass.
