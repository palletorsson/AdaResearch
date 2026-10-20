# Nine structural levels and four each way

User asks for four structural levels up/down, about nine levels to feel height, fog active; suggests transparent quads 2/3/4 floors away if fog fails.

- Interpreted as nine levels total, announced in commentary. `layout.json` extends from roof to −48 m at six-metre spacing. `rooms.json` appends four empty records (map empty) after Trace, preserving the original five records and all user positions. No future curriculum invented.
- `floor_stream.gd`: LEVELS_ABOVE/BELOW=4, clipped window up to nine. Current full artifacts / next shaft preview / sleeping visited state unchanged. At Trace index 4, all nine structures visible. At roof/bottom, five.
- `game.gd`: explicit standard fog enabled, depth 6→30 m, curve 1.5, density 1; same animated pink/violet colour. Native Mobile captures show clear nearest slabs and fading far ones. No transparent quads added because this fog works in the rendered evidence; headset appearance still to verify.
- Architectural balcony construction and shared validator only iterate supplied balcony sides; empty floors have no unbuilt landing assumed. Signage marks unfinished route below Trace. Hard landings/retry unchanged; four added floors are a spatial study, not a completed descent course.
- Web top-down editor guards missing balcony entries. Lab editor reads nine records; fresh floor mesh exports required and performed with `tools/export_void_editor.py`.
- Export completed: 141 GLBs, no failures; nine floor models and nine API records verified. Lab editor floor 08 visually checked with its real slab/two shafts/pillars. Empty-map titles use "Open structure" instead of blank labels. No live user editor tab was reloaded or saved.
- New captures: `four-below.png`, `four-above.png`, and same-camera `four-below-clear.png` (fog disabled only for comparison; restored immediately). Camera leans over Trace shaft A. No generated concept images.
- 30 native streaming assertions passed, including actual nine slabs, four each way, open shaft, bottom checkpoint, existing object/trace retention. Old Trace regression now waits for fall recovery instead of assuming the old shorter tower's fall duration.
- Final Trace regression passed 48/48 with the real nine-level layout (78 total focused checks). Schema validation and report HTTP 200 passed.

Report: http://localhost:3003/book-review/doc/book/iterations/2026-10-18-void-nine-levels/index.html

If needed later: shaft-only two-sided haze quads at ±2, ±3, ±4 storeys, alpha increasing with distance and interpolated with head height; collision off and next landing clear. Avoid sudden snapped sheets and whole-floor transparent surfaces. Not implemented/active now.

Performance limits from previous change remain: visited content cached in RAM; a heavy assembly `_ready()` is still one main-thread call. This capture measured ~103 ms for its largest queued build while another user scene was running; no Quest benchmark or hitch-free claim.
