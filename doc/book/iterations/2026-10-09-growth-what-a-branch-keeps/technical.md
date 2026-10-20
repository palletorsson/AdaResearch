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


## Complete Growth reconstruction — 9 October 2026

The canonical tutorial now contains four complete files. `grammar.gd` preserves the prior rewrite function and adds copied state dictionaries, balanced-bracket preflight, a stack, raw endpoints and post-symbol records. Its planar zero-variation reader matches the valid installed lesson at all four ratios and both generations: eight comparisons, 296 states. `growth.gd` constructs the point, two metre-scale readings and their controls; PointBody and LineSkin are byte-identical to Grammar Lab. A separate edited file executes the nested F[+F[-F]F]F exercise. Mutants replacing the state copy with an alias or pop_back with pop_front fail that exercise as expected. The compact reader rejects malformed brackets; production's permissive invalid-input behavior is not claimed equivalent.

GrowthHand adds the familiar sphere in front of the existing six-button desk. Local X selects 0.45/0.72/1/1.15 and calls the existing reinterpret function. Held action calls STEP. Release parks the sphere. The core parametric_lsystem.gd is byte-unchanged. GrowthLesson's cylinder renderer now scales its rotated local Y column, not the world Y row: the earlier Basis.scaled call made oblique cylinders miss the recorded endpoints. The native test now checks both rendered ends of all 25 second-generation cylinders.

The live museum had no onward token: the fresh baseline portal record was empty. Added t at source cell (9,26) inside the existing rear opening. Structure and all five authored placements remain unchanged. The first route probe turned at z=16.4 inside the existing cross-wall; the correct route passes its doorway before turning at z=17.5. Final 241 capsule/floor samples and nonempty entry/exit approach validation pass. This is not a complete player portal traversal.

28 exact printed-code and 29 museum assertions pass. Four baseline and eight final native images include the overhead arrangement. The temporary desktop pointer rig is removed before final images because it brings a competing environment; no production lighting was changed. The learner photograph temporarily hides the original primary to avoid duplicate labels, then restores it; that reconstruction is not permanently added to the hall. Logs contain no SCRIPT ERROR or Parse Error; a pre-existing unresolved UID diagnostic remains. No physical headset, Quest performance, blind ghost student or whole-sequence acceptance is claimed. Report: doc/book/iterations/2026-10-09-growth-what-a-branch-keeps/index.html.
