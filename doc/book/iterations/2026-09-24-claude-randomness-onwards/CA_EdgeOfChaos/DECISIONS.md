# CA_EdgeOfChaos: decisions

Cellular Automata, hall 8 of 8, and the last hall of the block. 24 September 2026. Verdict: **Targeted revision**. Four sentences changed and one clause added inside a changed sentence. No new sentence was added. This is a text-only revision: no code, map or repo file was touched, and Godot was not started.

## Preserved

Apart from the four sentences below, the chapter is unchanged word for word. That covers the title, the `<!-- @self_organization_ca -->` and `<!-- @ -->` anchors, both GDScript excerpts, every question, and the closing handover. It also covers everything the audit listed under Preserve:

- the matched-forcing paragraph;
- the uniform INTEGER/FRACTIONAL experiment (4.75 truncating to 4; twenty-seven addresses at 0.75);
- "More places carry it. Less of it remains at any one place.";
- the counter-tolerance sentence;
- the Edge of Chaos paragraph, which keeps the name as a question;
- "A wall is a slice through space. It is not the next generation.";
- the handover triad (resemble a neighbour, inherit an earlier state, be told to repeat).

The handover still matches the next hall. Its first desk's function calls itself (`algorithms/fractals/example_8_2_recursion_vr.gd:236`), and that is the excerpt Fractal_Recursion's final.md opens with. The chapter still makes no claims about topology, Turing completeness or circuits.

## Changes

**1. The readout is overhead, not underfoot.**
- Before: "Look down at the gain printed on the readout."
- After: "Look up at the gain printed on the readout above the console."
- The audit found this false and the re-check agreed. The reading does print the gain as its last line (`algorithms/cellularautomata/ca_showcase/difference_study.gd:75`).
- The Reading Label3D sits at local y 2.25 and z -0.70, inside a ReadoutCase that spans about 1.69–2.81 m (`:119-120`). The console panel is at y 1.15, z -1.7 (`:110`). The label is turned 180 degrees, so it faces the console side.
- The only other printed gain is the slice label at 4.25 m (`:76`, `:104`). The FloorNote is fixed text with no gain (`:105`).
- Nothing that carries the gain is below eye level. I used the re-checker's rewording.

**2. The fractional run spreads the memory; it does not lose it.**
- Before: "This stillness has kept a memory that the smoothing run lost."
- After: "This stillness keeps whole a memory that the smoothing run spread thin."
- The audit and the re-check agree this was overstated. With PULL 0 and DRIVE 0 the update reduces to `a[i]` (`difference_model.gd:53`), so the single +1 stays whole. PULL - resets the run (`difference_study.gd:31`).
- The fractional run does not lose the difference. The re-checker's port of `step()` found all 1,331 addresses still differing at update 100 (max 0.001172). The peak stays at CENTER, (5,5,5), at every sampled update, and the degree-weighted sum stays at 26.
- What that run loses is concentration. Only INTEGER storage erases the difference (`difference_model.gd:55`). I used the re-checker's rewording because it is more exact than the auditor's: the auditor said the run loses location, and the re-check showed it does not.

**3. The rear gallery, described as it runs.**
- Before: "The other works remain in the rear gallery: a screen, local transmission and recovery, a cellular fog field and growing cracks."
- After: "The other works remain in the rear gallery: a screen that keeps the successive states of a one-dimensional automaton as rows, local transmission and recovery, a fog field whose cell rule fills it solid within two updates, and cracks that finish spreading across their plate within a couple of seconds of the build."
- The audit and the re-check agree that "cellular fog field" and "growing cracks" describe states the visitor will not meet. The fog and crack clauses are the re-checker's wording, with "their whole plate" softened to "their plate". The outer ring of cells is never updated: the loops run 1..GRID_SIZE-2 (`crackpropagation_ca.gd:161, 175`).
- Fog: 40% initial density (`algorithms/cellularautomata/volumetric_fog/volumetric_fog_ca.gd:49-50`), survival at 4 or more neighbours and birth at 5 or more (`:94-103`), wrapped at the edges (`:120-122`). The map sets `preview_grid:12` (`commons/maps/CA_EdgeOfChaos/map_data.json:1892`, applied at `volumetric_fog_ca.gd:158-159`).
- I ported the rule myself for three seeds. The live counts were 708 → 1718 → 1728, 698 → 1726 → 1728 and 674 → 1717 → 1728, with 1728 of 1728 alive after two updates. That is a fixed point.
- Cracks: no state ever goes back. INTACT becomes STRESSED (`algorithms/proceduralgeneration/growth_systems/crackpropagation_ca/crackpropagation_ca.gd:179-184`) and STRESSED becomes CRACKED (`:186-193`). CRACKED only pushes stress outward (`:195-201`).
- `_ready` pre-runs 40 steps (`:69-70`) and `_process` takes one step per frame (`:73-74`). The re-checker's port saturated all 3,844 interior cells by step 116–117.
- Added clause: "a screen that keeps the successive states of a one-dimensional automaton as rows".
  - The audit names ca_screen as the hall's only stored history with a spatial body. That is the brief's "a record of states can acquire a spatial body", and it is the "stored history" the hand-off to Fractal_Recursion runs through. The chapter only said "a screen".
  - `ca_screen.tscn:8` sets `auto_play = true`. `cellular_automata.gd:91-93` appends each row to `history` and drops the oldest past `img_height` (128, `:19`). `:96-100` paints every stored row.
  - I wrote "automaton", not "rule", because the rule is swapped at random from a set of eight (`:21-22, 78-81`).

**4. Motion is not shared.**
- Before: "A shared visual restlessness does not make their rules equivalent."
- After: "Similar-looking motion, where there is any, does not make their rules equivalent."
- The audit marked this overstated and proposed this wording. There is no separate re-check entry for this sentence, which is a judgement I made and flag here.
- The re-check of the previous sentence confirmed the facts the change rests on: the fog becomes a uniform block or slice and the plate becomes a static sheet. I checked the disease myself. Under `museum_budget:true` (`map_data.json:1774`) it computes four rows per frame and redraws only when a whole generation commits (`disease_spread_ca.gd:38-53`). Its own label says "one update over 1024 display frames" (`:36`).
- Left unchanged, the sentence would claim a shared restlessness for works that sentence 3 now says are still. The screen is the only work that moves continuously. The reworded sentence keeps the sentence's point: appearance does not establish equivalence.

## Left alone, and why

- **"Their colours almost agree. ... Can you find it without the instrument telling you where to look?"** The auditor called this overstated because of the museum's pier colonnade and the default slice that lights the address. The re-check showed the auditor wrong on the sentence:
  - The two colours are 1/9 of the tint ramp apart (`difference_study.gd:54-55`; `difference_model.gd:43`), and the readout says HELD at update 0.
  - The question admits there is an instrument, and COAT hides it (`difference_study.gd:38, 70-71`).
  - The piers are a build defect, not a text defect.
- **"The floor carries a section of their difference; the cases ahead show A, B and the difference separately."** The re-check showed this is true. The floor uses the difference texture (`:103`), the three cases carry A, B and |A-B| (`:96-102`), and column 5 stays visible even with the piers in the museum. The possible left-right mirroring of the cases against the volumes is a claim the sentence does not make.
- The console paragraph, the code excerpts, the uniform experiment and the Edge of Chaos paragraph all check out against `difference_model.gd:39-57` and were not touched.

## Limits

- **The piers are not fixed.** The museum plan row stamps a 28-pier colonnade into this hall. One pier encloses the changed address inside volume B, and three stand against the slice cases. `map_info.museum` has no `"piers": false` (`map_data.json:27-40`). The fix is structural: add the opt-out and re-run `tools/em_map_halls.py --apply`, after a forum post. It was outside this task's write scope, so in the museum the chapter's core encounter stays damaged until someone makes it.
- The hall's working parts are uncommitted working-tree edits: the `#study:difference` token, the mount in `self_organization_ca.gd`, disease `museum_budget` and fog `preview_grid`. The revised sentences describe that working tree, not HEAD.
- "Within a couple of seconds" assumes the headset frame rate. About 76 frames after the build is roughly 1 s at 72 fps. A slower build frame rate stretches this, but the plate is still finished long before a visitor walks the roughly 24 m to it.
- On a Mobile-renderer export the fog may show nothing, and on Compatibility it shows a slice (`volumetric_fog_ca.gd:53-59`). "Fills it solid" describes the cell field, which holds under either renderer.
- The review log records an em-art statue dealt into this hall. Its position was not verified, so the chapter does not mention it.

## Performance repair in the rear gallery (added after the text pass)

**What was wrong.** The crack plate (`crackpropagation_ca`, token `crackpropagation_ca:0:0.9:0.8#plinth:0`) fills its whole plate within about 75 frames of being built, and it never stopped computing afterwards. The step keeps re-marking border cells as STRESSED, but the loops never update those cells and the mesh never draws them. That re-marking kept `changed` true, so the plate re-ran its full step and rebuilt an identical crack mesh every frame. Measured script cost after settling, desktop, headless: **67-76 ms a frame**, while this hall is loaded. The 90 Hz headset budget for everything is 11.1 ms.

**What changed** (`crackpropagation_ca.diff`; the shipped script is `crackpropagation_ca.gd.before.txt`):

- `_process` now ends with `if _interior_settled(): set_process(false)`.
- `_interior_settled()` is true once every interior cell is CRACKED with stress at 1.0.
- `add_stress_point` and `reset_simulation` turn processing back on.

**Why the picture cannot differ.**

- The mesh reads only CRACKED cells and their stress.
- Border cells are never cracked.
- A cracked interior cell's stress is clamped at 1.0 on every later step: decay takes 0.02, diffusion at most a few hundredths more, and its cracked neighbours push at least 0.18.

**Gate** (`commons/testing/probe_ca_stop_and_fit.gd`, C1-C3, three seeds):

- The plate stops at frames 74, 77 and 78.
- The shipped script, run 120 frames longer from the same seed, still holds the same cracked set (3,844 cells) and the same stress on every cracked cell.
- `add_stress_point` resumes processing.
- Cost after settling: shipped 75,932 µs, repaired 1 µs.

The chapter's sentence ("cracks that finish spreading across their plate within a couple of seconds of being built") stays true; the only difference is that the plate stops paying for a picture that has stopped changing. Two maps place this token.

**Remaining cost in this hall:** `disease_spread_ca#museum_budget:true` measured 7.9 ms of script a frame. Its script carries another session's uncommitted edits and was not changed here (INTEGRATION.md, section 7).

## Installed

`after.md` was installed to `commons/maps/CA_EdgeOfChaos/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and one fix applied: 'within a couple of seconds of being built', not 'of the build'. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `5851c73fa78f…`, after `992937ab3cda…`. No runtime or learner status changes.

## Piers (added at the end of the block)

Under Limits, this record said a colonnade pier encloses the changed address inside volume B, which damages the chapter's core encounter. `map_info.museum.piers` is now `false` (`map.diff`, one line). The museum reads piers from the plan row, not the map, so this takes effect only when `tools/em_map_halls.py --apply` is re-run. That writes the baked plan, which belongs to Astra (INTEGRATION.md, section 7). Until then the museum still builds the piers. Not verified in a museum boot, because the plan has not been re-run.
