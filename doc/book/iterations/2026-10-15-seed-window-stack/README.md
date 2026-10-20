# Seeing a seed through three windows

Palle asked for two windows above the existing seed display, so the role of the seed could be observed. Random Definition now uses `comparison:seed_witness`. Three full-size 4 × 4 glass windows share one vertical frame:

- Bottom: **START**, seed 435.
- Middle: **REPLAY**, independently restarted from seed 435.
- Top: **SEED + 1**, seed 436.

Each pane consumes three successive draws for RGB. The bottom and middle therefore match all sixteen panes under the same procedure. The top changes only the starting seed. Each window displays its actual seed, first draw values (rounded on the label), a strip of up to 24 draws and an exact matching-pane count. Those readouts inspect a separate generator and never consume the exhibit's stream.

Colour mapping, range and +1 DRAW act only on the middle window. The bottom and top retain the baseline procedure. This preserves two separate comparisons: changing a seed with procedure fixed, and changing a procedure with seed fixed. Replay repeats the current settings; it does not silently undo a deliberate mapping or offset. RESET MAP resets the mapping, and +1 DRAW toggles the offset back off.

The seed is an initialising integer, not a property that can be identified by looking at one colourful image. Agreement between independently restarted runs is the evidence here. It establishes repeatability for this generator and procedure, not physical randomness, cryptographic security or guaranteed output identity across future engine versions. The top comparison does not select a new hall seed; changing the actual seed control still propagates through the hall as before.

The square windows retain their 1.225 m footprint, stacked with gaps. The upper window ends below 5 m, within this open-roof hall; controls remain on the 1.10 m compact console. No controls were moved to the upper windows. Other placements retain their previous comparison modes and solid finish unless explicitly configured.

## Experiment and evidence

Start with matching bottom/middle panes. Press REPLAY; record whether the agreement remains. Compare bottom/top with both RGB rules fixed. Toggle +1 DRAW on the middle and observe the shifted strip and changed panes. Toggle it off, then change only the colour mapping: the two same-seed strips still agree while the panes differ. Preserve seed, matrix side, mapping, range and offset; replay that record. The optional tutorial reconstructs the pair and asks for the independent third window as its next variation.

[Instrument tests](test.log): PASS for the actual authored token, independent expected RGB samples, stacked bounds, explicit seeds, non-consuming inspection, offset, mapping, capture/restore, replay, resolution and all five legacy comparison modes. [Hall integration](hall-test.log) verifies shared-seed propagation and retained-gesture replay with the new stack. Native previews: [opening](windows.png), [one draw later](one-draw-later.png), [same draws / changed mapping](same-draws-new-mapping.png), [standing view](standing.png).

The physically experienced comparison and independent learner reconstruction remain unobserved. The new encounter stays optional; the main room/final route and 48-value first pilot are retained.
