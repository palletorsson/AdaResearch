# A branch carries a state

Growth builds on Grammar Lab's separation of rewriting, interpretation and fitting. It adds parameter inheritance and a last-in, first-out stack. The next hall, LSystems_Grammars_And_Curves, compares interpretations at the believing turtle.

## From sentence to travelling state

The installed primary is parametric_lsystem with the opt-in GrowthLesson. It uses the unchanged Bushy Tree production F -> F[+F]F[-F]F. One rewrite gives 11 symbols and 5 F segments; two give 61 symbols and 25 segments. The lesson starts after the first F, with base_length=0.8, base_angle=40, length_decay=0.72, angle_variation=0 and one rewriting generation.

F and G draw using the current length and heading. Lower-case f moves without drawing. Plus and minus turn; X draws nothing. The existing interpreter saves this record on branch entry:

```gdscript
stack.append({
    "pos": pos,
    "dir": dir,
    "right": right,
    "up": up,
    "depth": depth,
    "length": current_length,
    "angle": current_angle,
    "angle_rad": angle_rad
})
```

It then increments depth, multiplies current_length by length_decay and current_angle by 0.95, and recalculates angle_rad. Closing a branch pops the most recent record and restores every listed field. The segment list is not rolled back. In the first branch, length becomes 0.576 m and angle 38 degrees; after return they are 0.8 m and 40 degrees again. Branch nesting is not the same as rewriting generation: a sentence at one generation can contain several nested levels.

The lesson records the actual interpreter state after each symbol and an initial START frame, together with the number of segments already drawn. STEP exposes one more record and its segment prefix. This is trace replay, not a suspended GDScript interpreter. The source still interprets the whole accepted sentence when it is generated or reinterpreted.

## Hold, change and measure

HOLD deep-copies the displayed prefix, cursor state, sentence, ratio and generation. RATIO cycles 0.45 / 0.72 / 1.00 / 1.15 and reinterprets the same sentence; it does not rewrite or change the reference. Each interpretation starts the existing RNG at seed 42. The lesson sets variation to zero; the retained ordinary presets can have nonzero variation. A repeated seed only establishes repeatability for the same engine and call sequence.

At ratio one a child stride equals its parent. At 1.15 the first child stride is 0.92 m and a twice-nested stride is 1.058 m. The variable name length_decay does not limit the operation to shortening. TREE toggles one/two complete rewriting generations and reveals the full trace. The depth-zero trunk has three then nine strides, reaching 2.4 then 7.2 metres. RESET restores the opening configuration and held reference. RULE names save, multiply and restore.

Ordinary artifact placements retain their fitted display and all four existing preset dictionaries. GrowthLesson hides that small display and renders the raw segment endpoints using cylinder MultiMeshes in common metre units. Both view transforms have unit scale, each starts on a 0.35 m plinth and carries an eight-metre ruler. There are no segment colliders. The lesson desk does not offer preset switching or rule typing.

The complete short sentence is shown. For longer sentences the display declares a local window with ellipses and the current symbol index/total. That text window does not truncate the interpreted geometry. Rewriting separately preflights allocation and retains the last complete generation if the next would exceed max_symbols: 4096 in the lesson, 80000 ordinarily. Requested generations are clamped to 0–6; the desk only uses 1–2. The ordinary label reports an effective/requested difference. This is a resource bound, not a measured entropy value.

## Museum and retained collection

The hall is 19×28 metres with nine-metre perimeter walls and an open roof. The earlier 13×12 structure is carried at offset (3,16); the abandoned teleporter hole is filled. Side margins and the approach let the visitor pass around the two plinths, then use the retained central route. Compact six-button controls keep full-sized touch targets at 1.045 m; a single tilted transparent pane shows the state. Scoped lighting and smaller captions stage the older works without stopping their clocks.

All five artifacts remain. AnimatedTree advances automatically on its own timer and adds wind; its scene now explicitly points to algorithms/lsystems/Growth/AnimatedTree.gd. ContextSensitiveTree raycasts prospective segments against physics obstacles during interpretation and prunes blocked branches. Its source does not implement the neighbouring-symbol rewrite table printed in the old tutorial. The ordinary lsystem_tree and modulor_cypress are separate studies. They do not share one controlled genotype/phenotype comparison with the primary.

The former map, texts and source are archived under doc/space/lsystems-growth-2026-09-14/before, alongside two historical grid versions and a baseline run. Desktop acceptance exercises the real controls, exact saved-state return, geometry, metre scale, preset preservation, configuration timing, budget behavior and route through the exit. Headset reach, comfort, readability and Quest performance remain pending.
