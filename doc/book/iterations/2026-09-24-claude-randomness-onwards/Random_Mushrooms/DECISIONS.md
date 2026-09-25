# Random_Mushrooms — targeted revision

Sequence `randomness`, hall 9 of 14. 24 September 2026.

**Verdict: targeted revision.** The inquiry, questions, code excerpts, footnote and voice stand. Nine sentences were corrected where they said more than the code does. Three short additions were made: one handover clause at the opening, one tagged paragraph for the unmentioned bubble dish, and one sentence at the closing that grounds the handover. Nothing in the repo was edited except the two files in this folder.

## Preserved

Every sentence on the audit's Preserve list. All five code excerpts, byte for byte. The footnote. The four existing anchors (`@mushrooms`, `@silhouette_arrivals`, `@couture_comparison`, `@`) and their order. The chapter's questions ("What did you think the button would remove?", "Which gaps seem intentional?", "How far can this wardrobe take the figure?" and the others).

## Changes (the audit and the second check agree)

1. **Console / walk.** "then move among the mushrooms" → "then walk round the mushroom bed inside the glass". The bed cannot be entered. `_lift_bed` raises the ground (mushrooms.gd:171-175). The kerb boards are `HangarKit.box` meshes (mushrooms.gd:1291-1310), and the source says "the boards have no collider" (mushrooms.gd:1226-1227). The re-checker also cites museum_exhibit_stage.gd:95-99 and field_notes.md:42. I used the re-checker's wording.
2. **SHOW highlight.** "rings with tall pins" → "magenta rings on the ground … each with a small bead floating high above it". The pin is a `SphereMesh` of radius 0.06 (mushrooms.gd:1435-1439). It sits at `pin_h` 0.75 above ground, with nothing beneath it (mushrooms.gd:1508, 1540). The ring is at +0.04 (1537). Both are magenta for the template kind (1483). I used the re-checker's wording.
3. **Puffball bumps.** "A new build can also change details inside a template, such as the puffball's bumps" → "A new seed can also change one detail inside a template: where the puffball's bumps sit." The bumps are the only template detail that draws (mushrooms.gd:512-521). No other template builder draws (321-468, 528-591). REGROW and SIZE both reseed with the same seed (1155-1166, 1264-1266), so they redraw the bumps identically. I used the re-checker's wording.
4. **Ring arc.** "Find its arc, then imagine…" → "Find it. Usually only an arc fits; imagine…". The ring is whole whenever its centre is at least one radius from every kerb (mushrooms.gd:719-740). That happens in about 15% of builds, and this token pins no seed (map_data.json:1271; `_prepare_stand` 129-133). The first half follows the re-checker. I kept the original's "imagine".

## Changes (audited, with no harness re-check; I made the second check myself in the code)

The re-check pass covered only five of the audit's ten claims. For the other five I read the code. I changed the sentences below only where the code settles the claim.

5. **Clusters.** "Two cluster routines choose their own centres, spreads and templates" → "Two clusters each choose their own centre, spread and template." There is one routine, `create_mushroom_cluster`, called `int(6/3)` = 2 times (mushrooms.gd:712-715). Each call draws its own centre, spread and template (766-778). The chapter's earlier "two other routines" (ring and cluster) now stays consistent.
6. **Edible mushrooms.** "Three larger red-capped mushrooms" → "Three spotted red-capped mushrooms on taller stems". Edible cap: r 0.06 × `mushroom_scale` 1.5 = 0.09 m (edible_mushroom.gd:187-194; mushrooms.gd:1220-1221). Red template cap: r 0.15 (mushrooms.gd:314, 344-346) at instance scales 0.5-1.3 (629, 754, 805). So the edible caps are narrower than almost every red copy. What does differ: the stem is 0.12 × 1.5 = 0.18 m against the template's 0.1 × scale (edible_mushroom.gd:164-172), and there are five white spots (219-244). The .tscn overrides none of these.
7. **Arrival stage.** "wait for a silhouette" → "press REPLAY: the places empty. Wait for a silhouette." The later "Press REPLAY" becomes "Press REPLAY again". AUTO is on from the start (silhouette_arrivals.gd:15). `_ready` calls `replay()` (30), and `_process` then places one arrival every 1.5-3.5 s (32-35, 43-53), so all six are placed within about 21 s. In the museum the stage processes whenever the eye is within 32 m (endless_museum.gd:959-960, 16622-16653). The stage stands at row 17 of this 25-row hall, so it is live from before the hall's entrance. REPLAY empties the places and reseeds with `run_seed` (silhouette_arrivals.gd:37-41), so a second REPLAY repeats the order.
8. **DRESS.** "A hem widens, a collar appears" → "A hem may widen or narrow, a collar may appear or go". DRESS redraws every figure (silhouette_arrivals.gd:64-67). The hem is redrawn in [0.32, 0.65], the collar with probability 0.6, and the accent and pleat count are redrawn too (silhouette_sprite.gd:37-47).

## Additions (facts verified in code)

9. **Opening handover:** ", and the sizes are drawn under the last room's UNIFORM law, not GAUSS." Gaussian closes on "Before carrying this shape onto a body", which invites a bell curve. But every scale here is `k + _rf() * w`, with `_rf` = `randf` (mushrooms.gd:160-161, 629, 754, 805). UNIFORM and GAUSS are the buttons the last room named (Random_Gaussian/final.md:9, 17).
10. **Bubble dish**, as a new `<!-- @bubbles_random -->` region between the edible paragraph and `@silhouette_arrivals` (three sentences). The dish is placed at row 5, col 3 (map_data.json:1152). The glass spans rows 7-15 and cols 4-12 (mushrooms token at row 11, col 8, glass 8×8). `bubble_seed` is -1 (BubblesRandom.gd:91), so every draw falls through to the global `randf`/`randf_range` (312-327). Each bubble draws its place, size and rise speed (330-355). The scene sets `spawn_rate` 10 and `bubble_lifetime` 4 (bubbles_random.tscn), and bubbles are freed at their lifetime (BubblesRandom.gd:186-194). There is no plate or control. I gave it its own tag rather than leaving it inside `@mushrooms`, because regions are pushed onto wall labels (tools/final_tags.py:18 and the note at 188-190). `final_tags.parse` round-trips the file, and `stale_tags` against the map is empty.
11. **Closing handover:** "The bed has already shown you both: each height of its jagged ground was drawn on its own, and its clearings came from a noise field in which nearby positions receive related values." Each ground vertex height is `ground_rng.randf_range(...)`, and the source comments "no coherent noise field" (mushrooms.gd:236-238; `use_random_ground` is true by default, line 20). The clearings read a `FastNoiseLite` at each candidate (650-652, 662-667).

## Left alone, and why

- **KIND order** ("Continue to 'rejected'", "Keep pressing KIND until it says 'rings'"). The re-checker showed that every instruction works and nothing in it is false (KINDS at mushrooms.gd:86; cycle at 1280-1287). What the auditor found is a detour, not an overclaim. The brief says to leave such sentences.
- **Footnote on *10 PRINT*, pp. 125-127.** It was flagged as unsupported only because the repo holds no copy of the book. No fix was proposed, and I cannot check it.
- **"the cage" (the glass) beside "the cage interlude" (Biome_Cage).** The audit asks that the two be kept distinct. They are two different phrases and neither is false, so I did not change them.
- **"a place you can enter"**: true. Visitors do enter the glass. Only the bed is closed to them.

## Limits

- Godot was not run. The claims about the arrival stage (full on arrival) and the bubble rate come from reading code; I did not observe them. The rate is "about" ten a second because the spawn timer resets to zero on each frame.
- "Near the entrance, off to one side of the glass" comes from grid cells, not from a capture of the museum's placement.
- Not addressed, because it is outside this folder: the stray default `PrismMesh` at the centre of the bed (mushrooms.tscn:5, 25-26), with the scene's spare Camera3D and 24 m FillLight; the stale companion docs (artifacts.md, intent.md, summary.md, critical.md, technical.md); and the audit's proposed `_prepare_stand` fix that would hide the prism.

## Installed

`after.md` was installed to `commons/maps/Random_Mushrooms/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `48de2a7ffa53…`, after `673ef28041b7…`. No runtime or learner status changes, because the text changed and nothing new was walked.
