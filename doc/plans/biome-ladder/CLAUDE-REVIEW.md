# Claude review — biome ladder

Start with PLAN.md and the native captures on index.html. The initial code belongs to Codex's B01–B05 pass. Review received below on 2026-10-13; see PLAN.md for the next work split.

## B06 — play and subject fidelity

For each stage, record: observed evidence; one problem; one proposed change; file ownership; acceptance test. Distinguish source inspection, native runtime, and headset play. Do not turn the first stage into the final biome. Keep the sphere recognisable across chapters.

## B07 — next stages

Propose the next sequence only. What returns from Colour? What new operation changes the landscape and the counterpart? What does the visitor do with the same catalyst? Which existing implementation can we reuse?

## Decisions awaiting play

- Is one-hit falling defeat satisfying, or should later heads take more hits?
- Are 1.8 m/s shots readable in the headset?
- Does the first stage have sufficient cover without hiding the heads?
- Does a three-head row remain readable when all three fire on staggered phases?
- How should the early geometric ground grow into the existing generation-17 ecology?
- Optional biome entries are the first implementation. Should completing a sequence route through the biome by default, with a peaceful bypass?

Append a dated review below; do not replace Palle's brief with an inferred one. Coordinate edits through the existing project forum when the thread is published.

---

## Review 2026-10-13, claude-edges-pilot (B06 and B07)

Evidence kinds are marked: SOURCE (read in `commons/hazards/biome_ladder/` as of 08:40), RUNTIME (the probe's 54/54 report and the fixed-camera captures stage-0..3.png, camera at (0.3, 1.65, 8.2) looking at (0, 1.1, -3)), HEADSET (none yet). I changed no runtime file. The route table in `route.gd` matches the sequence files exactly: last halls Primitives_Melencolia, Trans_Pit, Tutorial_Disco, Color_Walls; next first halls Trans_Pre, Array, Color_Context_Placed, Pattern_Disco.

### Numbers every stage shares (SOURCE)

- A head cycles RECOVER 3.5 s then WINDUP 1.2 s, so one ball per head every 4.7 s; slots start 1.4 s apart, so the first balls leave at 4.7, 6.1 and 7.5 s after START and the three heads never fire together. A ball flies at 1.8 m/s and lives 14 s (25 m, longer than the 24 m ground). At most 3 live balls per head, 9 in the world.
- Head to visitor: at stages 0 and 1 the heads stand at z 3, -1.5 and -6 and the visitor arrives at z 10.5, so a ball needs 3.3, 5.8 or 8.3 s to arrive; at stages 2 and 3 the row stands at z -3, 6.7 s away. The warning (white eye and the cue line) lasts 1.2 s and ends when the ball leaves, so the dodge cue is the ball itself for the next 3 to 8 s.
- The ball aims at where the visitor stood when the telegraph began, with its height clamped to 0.8 to 2.2 m (`begin_telegraph`). Stepping aside after the eye turns white is the whole defence; standing still is a hit.
- Growth: from stage 1 the radius goes 0.09 m to 0.198 m over 5.45 s, so a ball from the row arrives at full size. At stage 0 it stays 0.09 m, which at 7 to 17 m subtends less than a degree; the 0.14 m glow halo is what the eye will find.
- Life: three hits, 0.75 s between counted hits. From stage 1 three pickups each restore one hit, so stage 0, meant as the gentlest, is the only stage where three hits are the whole budget.

### Stage 0, Primitives: cover does not cover

- RUNTIME: stage-0.png shows the open centre lane, the three poles and the twelve forms on the flanks. SOURCE: forms stand at x ±4.6, 1.3 m tall with their tops at 1.3 m (`_landscape`); the heads hang at y 1.8 at x -3, 3 and 0; the eye is at 1.65 m.
- Problem: no form stands between any head and the lane, and every form is lower than both the eye and the ball's path, so a standing visitor is never covered and no head is ever occluded. The brief's "recognise primitive cover" cannot happen here; the forms are scenery, and the brief's "clear central route" is all there is.
- Proposed change: bring one form per row in to x ±2.2 and make the box and the cylinder 2.0 m tall, leaving the sphere and cone low, so the lane keeps a 1.2 m clear centre and the flank forms become something to step behind. Keep the poles where they are.
- Ownership: Codex, `ladder_encounter.gd` `_landscape` only.
- Acceptance: a probe raycast from (±2.2, 1.65, 6) to each head is blocked by a form for at least one head; from (0, 1.65, 8.2) all three heads stay visible; a capture from the lane shows a head disappearing behind a box.
- Second, smaller: give stage 0 one pickup, so the gentlest stage is not the only one without a second chance, or lengthen its RECOVER to 5 s.

### Stage 1, Transformation: the ground and the invisible rotation

- RUNTIME: stage-1.png shows a black and white checkerboard. SOURCE: `_ground` tiles stages 1 and 2 with `(x + z) % 2`; the brief's table says Transformation keeps the Primitives ground and Arrays introduces the black/white grid. The checkerboard, which is the array's own sign of repetition, arrives one stage early, and Arrays then adds nothing to the ground.
- SOURCE: motion kind is `row % 3`, so rotation falls on row 1, a sphere, and row 4, a box. A sphere turning about its axis shows nothing, and a cylinder or cone turning about y would show nothing either. Translation and scale read on every form.
- Problem: one of the stage's three operations is illegible on half of its bodies, and the stage's floor says Arrays.
- Proposed change: stage 1 keeps the outlined white floor; rotation is assigned by form, to the box about y and to the cone about x (a tipping cone is a visible turn), while spheres translate and cylinders scale.
- Ownership: Codex, `_ground` and `_landscape` and `_physics_process` in `ladder_encounter.gd`.
- Acceptance: probe asserts that every body with the rotate kind is a BoxMesh or rotates about a non-vertical axis; stage-1.png shows the outlined floor; stage-2.png shows the first checkerboard.

### Stage 2, Arrays: the absent member arrives too late

- RUNTIME: stage-2.png shows three heads in a row with labels 0, 1, 2 and one telegraph ring. SOURCE: the row stands at z -3; the stagger is 1.4 s; a defeated head falls and stays down until RESET, which makes the gap.
- Problem: the brief's third thing to read, "an absent member", only exists after the visitor's first hit; the row as met is complete and the index labels say nothing a complete row does not. At 13 m the readable difference between the three heads is the stagger alone.
- Proposed change: four labelled places, three heads, index 2 empty from the start, so spacing, repetition and absence are readable on arrival and the first defeat makes a second gap. Optionally bring the row to z 0 so arriving balls read.
- Ownership: Codex, the head placement loop in `_ready` and `_label`.
- Acceptance: probe counts 4 labels and 3 heads with slots 0, 1, 3; capture shows the gap at index 2.

### Stage 3, Colour: colour marks everything, so it marks no event

- RUNTIME: stage-3.png shows hue by row on the forms and the twelve-hue floor; the trails are not in the frame. SOURCE: `_update_floor` steps the whole floor's hues every 1.5 s regardless of play; balls carry a hue by slot and phase with a particle trail.
- Problem: the brief asks that colour mark an event and a changing surface; here the surface changes on its own clock and nothing a ball does leaves a mark. The one event-bound colour, the trail, dies with the ball.
- Proposed change: a ball that ends on the floor colours the tile it struck with its own hue and the tile keeps it until RESET; the floor's own cycle slows to every 4 s or runs only while a head telegraphs. The receiving surface then also rehearses the tiling stage.
- Ownership: Codex, `_update_floor` and a floor-impact hook in `ladder_ball.gd` (it already detects its collider on impact).
- Acceptance: probe fires one ball into the floor and asserts the nearest tile's albedo equals the ball's tint; capture after three impacts shows three marked tiles.

### Decisions awaiting play, as far as SOURCE can answer

- One-hit falling defeat: right for stages 0 to 3; the row stage could later ask two hits of index 0 to make the choice of which member to remove matter.
- 1.8 m/s readability: HEADSET only; what SOURCE says is that at stage 0 the ball is a 0.09 m sphere with a 0.14 m halo and nothing else moves, so the test is whether the halo reads at 7 m.
- Cover without hiding the heads: see stage 0; today nothing hides anything.
- Three heads on staggered phases: 1.4 s between telegraphs is readable if the cue line is; the row at 13 m is the doubt, not the stagger.
- Growing into the generation-17 ecology: the strict ladder already exists, `commons/biome_layers/biome_grammar.gd` over `commons/data/biome_vocabulary.json` (cumulative closure along the walk, per hall for primitives), and the display halls Biome_Ladder_Primitives, Transformation, Color and Randomness show it cage by cage. The playable ladder hard-codes its four vocabularies; reading them from that file is the join, later.
- Optional entries with the museum passage kept: keep. The book is read without combat; the biome is where what was read is risked.

### B07, the next stage after Colour: Tiling

The spine's fifth sequence is tiling and `route.gd` already sends the Colour stage on to Pattern_Disco. Its truth: a source, a copying rule and a receiving surface each contribute to a pattern; keep one fixed and change another.

- What returns from Colour: the mark a ball leaves on the floor (stage 3's proposed change) becomes the thing the rule copies.
- The world: the floor is one wallpaper tile, drawn by the existing `commons/resourses/shaders/wallpaper_tile.gdshader` (wallpaper_group 0 to 16, tile_scale, cell_count, grout), its motif the primitives' outlines; the twelve flank forms become one source row of six and its mirror, so cover on the left is the copy of cover on the right and a visitor who reads one side knows the other.
- The counterpart: one source head and two copies under the rule. The copies fire when the source fires, at mirrored destinations, so a dodge must account for the copy; a hit on the source drops the copies with it; a hit on a copy drops only the copy. The three truths of the sequence become three ways to lose a head.
- The visitor's catalyst: the same sphere. A thrown form that ends on the floor is copied by the rule across the tile; your own throw becomes pattern. The sphere stays a sphere; its copies are flat marks.
- Carry onward: read a copy, find the source.
- Reuse: the wallpaper shader and `tiling_pattern.gd` (the raster Tutorial_Tiling_Floor shows) are implemented; `tiling_weathered.gd`'s wear layers wait for a later stage; the head copies and the floor marks are proposed, nothing of them exists.
- Implemented versus proposed, in one line: floor shader implemented; mirrored flank, copy heads, copied marks proposed.

Next action I claim if agreed: none of the runtime files. I can write the probe assertions for stage 0 cover and stage 3 marks as a separate `tools/probes/biome_ladder_review.gd` so Codex's changes have a test waiting; say so on the forum and I take that path.

### Cover test, 2026-10-13 10:35, claude-edges-pilot

`tools/probes/biome_ladder_cover.gd` (mine; touches nothing under the ladder folders) fired 106 real LadderBalls at the walker, aimed where the game aims (the camera), from lane positions and from 1.35 m behind every form, standing and crouched, on `ladder_encounter.gd` as of 09:58 (sha cbc4469d). RUNTIME result: stage 0 exposed 3/3 hit, screened lane 2/2 stopped, the six 2 m shelters stop a standing walker 6/6, the six 1.3 m flank forms 0/6, crouched 11/12; stages 1 to 3 exposed 5/5 hit, standing cover 0/11, 0/10, 0/10 because `shelter` holds for stage 0 only, crouched 9/11, 10/10, 10/10. Straight-ray prediction agreed with physics on 103 of 106; the three misses are crouched shots past a cylinder's rounded corner. Report: `ada_run/biome_ladder_cover/report.json`. The probe's exit code is an acceptance test: 0 when every exposed shot hits and at least one standing shot per stage is stopped; today it exits 1 on stages 1 to 3.

### Cover across motion phases, 2026-10-13 10:50, claude-edges-pilot

Same probe with `--phases=6` on `ladder_encounter.gd` as of 10:31 (sha 3a8fc018, shelters in every stage): 368 real shots at six launch phases of the forms' 10.47 s cycle, head swayed to the same moment, forms moving during the flight. RUNTIME: stages 1 to 3 pass at every phase. Exposed lane shots hit in every phase. The six 2 m shelters stop a standing walker at all phases while translating, turning and scaling, 36 of 36 per stage; the six 1.3 m flank forms never do, 0 of 36 per stage, two grazes aside. Crouched (stage 1): shelters 36 of 36, low forms 20 of 36 by phase. One mid-flight uncover: at phase 2 a ball launched at the arrival was screened by the translating row-0 box at launch and reached the walker 6.9 m later, the box having moved along z during the flight. Reports: `ada_run/biome_ladder_cover/report_phases_stage{1,2,3}.json`.


---

## Route review, 2026-10-13 13:10, claude-edges-pilot (five stages, screenshots, Change)

Read: PLAN.md, HANDOVER.md, TILING.md, and the COVER, TRANSFORMATION, COLOUR and TERRAIN-LINEAGE notes. Evidence kinds: SOURCE (the ladder scripts as of 12:05, shas in the report), DESKTOP (my probe `tools/probes/biome_ladder_route.gd`, report and captures in `ada_run/biome_ladder_route/`), SCREENSHOTS (Codex's stage and evidence captures on the planning page, plus my entry captures), VR (nothing; listed at the end as what Palle must test). No runtime file was changed. Ownership: my probe and this section only.

### The route, as a player takes it (DESKTOP)

The probe boots the staged game to its menu, enters the ladder through the Biome Ladder button's real pointer path, walks the five stages by the far-end NEXT STAGE button (its own relay, so a signal-level press, not a hand), and ends with the far-end MUSEUM button. 101 checks, 100 passed after the probe's two museum checks were corrected.

- **Entry and progression.** The menu opens the ladder through staging; the route starts at stage 0; NEXT STAGE builds stages 1, 2, 3 and 4 in order; the practice hand ability is lent without saving the unlock (test save isolated in the probe's folder).
- **Retained, every stage.** Three heads, the six tall shelters, the held catalyst and the lent hand ability are present at all five stages. From stage 1: the eight learned motions, three pickups and the 72-tile floor, and a real hand throw from the ability onto the tile beside the arrival answers with x0.8 scale and +22.5 deg at stages 1, 2, 3 and 4. From stage 2: the indexed row with its three labels. From stage 3: six hues on the forms and tinted, trailing skull balls. At stage 4: one hit repeats on eighteen tiles, the in-world rule is stated, and the 5 TILE control exists. Nothing earlier is dropped by a later stage.
- **Cover, every stage.** A real skull ball at the walker standing behind PrimitiveCover_0_Left is stopped by that shelter at stages 0 to 4; a ball at the walker in the open lane reaches the walker at stages 0 to 4.
- **Reach.** Thirteen cube buttons per stage (eleven on the console, NEXT STAGE and MUSEUM at the far end) all stand at hand height on the floor and none is inside a form, at every stage. The desktop walker, driven by move_and_slide from the arrival, reaches all thirteen at stages 0, 1, 2 and 3, including the far end through the lane. **At stage 4 it reaches ten of thirteen: RESET, 4 COLOUR and MENU, the right-hand end of the console, are not reached.** See problem 1.
- **The handover.** MUSEUM loads the staged museum (scene path confirmed), the museum's boot record is written at 12:50:02 with the first hall built at 9.2 s, and the capture `museum-after-ladder.png` shows the hall with the arch reading the fundamental theorem of calculus, which is Change_Intro's `ftc_bridge`. The route therefore ends in the right hall. My probe's first run failed two checks on this step for the probe's own reasons (it read the menu static after the museum had consumed it, and it looked for the museum on the staged scene's root rather than its `Museum` child); corrected, the probe reads `_first_chapter` / `start_map` and `_museum_ready` on the museum node and passes both: change / Change_Intro, first hall raised. Final count 100 of 101, the one failure being problem 1 below. The process exits with the known shutdown crash after a staged museum, as Codex's roundtrip does; the report is written before it.

### Concrete problems, in priority order

1. **DESKTOP, confirm in VR. After the first pattern hit at Tiling, the walker cannot reach the right end of the console.** At stages 1 to 3 the single transformed tile beside the arrival never blocked a walk. At stage 4 the same throw repeats on eighteen tiles, one of them under RESET, 4 COLOUR and MENU, which stand at z 9.6 over the tile at world (3, 9). Shrunk to 0.8 and turned 22.5 deg, that 4 cm slab's collider leaves a gap to the backing and a turned edge, and the straight walk from the arrival stops short of the three buttons. Everything else on the console, the far end and the lane stays reachable. A VR body steps 4 cm without noticing, so this may be desktop-only; it is still the ladder's only reachability failure, and it is produced by the stage's own rule. Codex-owned (`_ground` tile colliders). Suggestion, not a design change: let the walker ignore tile colliders (balls keep hitting them, the backing carries the body), or keep tiles flush when shrunk. Acceptance: the route probe's stage 4 reach check, 13 of 13.
2. **SCREENSHOTS. From the entrance, the console and the hand glow own the view.** In every entry capture the console's dark panel fills the lower right third and the two glow spheres of the hand ability sit in the centre; at stage 4 the only in-world instruction, "Shoot a tile, its turn and colour repeat every two tiles", stands at z 7.8 behind the glow and is half covered. Codex-owned (`_controls`, arrival). Suggestion: arrive 1.5 m further back or put the console to the side of the arrival; raise the stage-4 hint to eye height on the first shelter.
3. **SCREENSHOTS. Arrays hides its row.** From the entrance the three heads at z -3 stand behind the two tall cylinders at x +/-1.6; both Codex's stage-2 capture and mine show one skull between the cylinders and the index labels are unreadable at 13 m. The stage's subject is the row and the entrance does not show a row. Codex-owned. Suggestion: the row at z 0 or the cylinders one row further in at stage 2; or index labels at head height.
4. **DESKTOP, cosmetic. A stray HUD line.** "mushrooms ..... [F]" from NatureRenderer's ecology prompt sits over the ladder's control hint in every capture, and in the museum capture too. Not a ladder file; whoever owns the nature HUD should hide it outside its biomes.
5. **DESKTOP, cosmetic. Stage 4 is the only stage whose rule is written in the world.** The other four say nothing; see the legibility notes below for which of them need a word.

### Can a player understand what each sequence adds, from the screenshots alone?

- **Primitives: yes.** White ground with black outlines, shapes to stand behind, skulls on poles, an open lane. It reads as a gallery you can hide in and shoot across.
- **Transformation: no, from a still.** Motion is the subject and a still cannot carry it; the entry view is the Primitives view with one small cube on the floor. Codex's motion-a and motion-b captures show forms displaced, which reads as a different arrangement, not as movement, and nothing says which of the three operations a form performs. In play the sway will read; the three operations will not be named by anything.
- **Arrays: half.** The checkerboard reads as a grid at once; the row, the actual lesson, is hidden (problem 3).
- **Colour: yes, immediately.** Hue on the forms, a banded floor, pink glow. The one thing not visible is that colour marks events; the marks exist only after play.
- **Tiling: no, until a shot is fired.** The entry view is Colour's. After shots, the overview capture shows the 2 x 2 repetition unmistakably; the standing-height captures show one turned tile near and another far, which read as separate hits. Codex asked exactly this. From standing height the copies do not announce themselves as copies; something must happen at the moment of the hit on all eighteen at once (a brief line between them, or a one-second flash), or the player will think they hit two tiles.

### What Palle must test in VR (not testable here)

- Whether a hand throw onto the floor is a natural gesture and whether the eighteen copies read as one rule when seen from a standing body that can also look down.
- Whether the 4 cm tile step at Tiling is felt at all (problem 1), and whether gaps between shrunk tiles catch a foot or a teleport.
- Whether the console at 1 m from the arrival is comfortable or in the face.
- Whether 1.8 m/s balls and the 1.2 s white-eye warning read at 7 to 17 m.
- Whether the far-end NEXT STAGE and MUSEUM buttons are found without being told; nothing points to them.

### The Change operation, one, carrying the previous abilities forward

Change is the sixth sequence and the ladder already routes Tiling on to Change_Intro. Its truth: a value, a local rate and an accumulated total retain different things; repeated updates can make the next address depend on the path already taken.

**The operation: the floor steers.** A ball no longer flies straight. Each physics step its velocity gains a small push whose direction is the local tile's turn and whose strength grows with how many times that tile has been hit. Position is the value, the floor's push is the local rate, the flight is the accumulated total. The curve a ball draws depends on the floor it crossed, which is the path already taken.

What it carries forward, each from its stage: the tall shelters still stop balls, but a curved flight can come round a shelter the way a straight one could not, so cover must now be read against the floor (Primitives); the turned, shrunk tiles are the field, so the visitor's earlier hits are now the terrain of the fight (Transformation); the three heads fire along the same field, so the row's three flights diverge visibly from one rule (Arrays); a steered ball leaves its colour on every tile it crosses, so the flight is written on the floor as a trace, and the trace is readable afterwards (Colour); the tiling rule copies the field across the floor, so a pattern made in one place steers balls everywhere, and the player who tiled the floor has written the wind (Tiling). The sphere stays the same sphere; the catalyst's own throw obeys the same push, so a visitor can shoot a bending ball round a shelter at a head.

What the visitor does with the same catalyst: hit tiles to write the field, then throw along it; dodge by reading the floor, not the head.

Reuse: `ladder_ball.gd` already changes the ball every physics step (growth) and is the place for one velocity update; `floor_tile_hits` and each tile's `rotation.y` already hold the direction and the count; the Change sequence's own `velocity_arrow` and the flow artifacts of its Flow_Field hall supply the vocabulary for a readout. Everything in this operation is proposed; nothing of it exists.

Acceptance, when built: a ball launched across an untouched floor flies straight (the route and cover probes keep passing); the same ball across a tiled floor lands a measurable distance from the straight-line point, in the direction of the tiles' turn; the cover probe at one phase shows at least one covered walker reached by a bent ball and one exposed walker missed by one.


---

## B19 review, 2026-10-13 16:10, claude-edges-pilot (the standing array, tested independently)

Read: ARRAYS.md, the arrays page, arrays-evidence.json, PLAN.md and HANDOVER.md as of 15:05, and the B19 source files. Evidence kinds: SOURCE (the files as they stood when my probes booted: ladder_encounter.gd 256f1ec3 (15:31), ladder_skull.gd 8f55ff96 (15:31), ladder_ball.gd e96df4d2 (15:33), array_path.gd 8a8fb754 (14:40), ladder_world.gd cd8882f2 (15:27). These are later than the hashes in arrays-evidence.json because Codex's B20/B21 work landed between the publication and this review: `set_walking_body`, the pattern flash, and a sixth stage, Change, gated by `stage >= 5` and used only by the centre column. Stages 2 to 4 are what I measured; stage 5 is in progress and not reviewed.) DESKTOP (my new probe `tools/probes/biome_ladder_arrays_review.gd`: headless at stages 2 and 4 with real LadderBalls and a real catalyst projectile, 47 of 48 checks, 216 real shots, report `ada_run/biome_ladder_arrays_review/report.json` (rerun 15:59, identical figures); its rendered arrival captures with `report-captures.json` and the pixel diffs `capture_diffs.json`, and the dodging-visitor study `report-clutter.json`, all in the same folder; my updated `tools/probes/biome_ladder_route.gd` from the game menu through the first five stages, 105 of 106 checks, the one failure being my probe's stale wording for the Tiling hint, report and captures in `ada_run/biome_ladder_route/`.) SCREENSHOTS (Codex's arrays-after, -paths, -volley and -vacancy, and my captures.) VR (none; the list is at the end.) No runtime file touched; the two probes and this section are mine.

### What ARRAYS.md claims, measured again (DESKTOP)

Every claim held.

- Nine heads at x -2.4/0/2.4, y 3.9/2.6/1.3, z 3.5; nine labels reading [row, column] from [0, 0]; an eight-bar wire frame with no collider. At stages 2, 3 and 4.
- From the true arrival (the walker where the game puts it, camera at 1.72 m, fov 75) all nine heads are visible by ray and inside the frame: 9 of 9 at both stages.
- The real loop for 31 s: rows 0, 1, 2, then columns 0, 1, 2, then row 0 again. Each group's three balls leave in one physics tick, at 1.07, 5.87, 10.67, 15.47, 20.27, 25.07 and 29.87 s after START (the 4.8 s selection plus the 1.2 s warning, read at a 4/60 s step). Never more than three balls or three warnings at once while the balls end on cover.
- With [1, 1] empty, row 1 fires [1, 0] and [1, 2] under the sign ROW [1] / 2 OF 3, and column 1 fires [0, 1] and [2, 1] under COLUMN [1] / 2 OF 3. RESET restores nine at home with no EMPTY label.
- A real catalyst projectile empties [0, 1] and its label says EMPTY; all nine defeated heads fall through the open frame to the floor (y 0.3); the readout reads CLEAR / 9 OF 9 DOWN and the volleys rest; the walker passes the fallen column.
- Cover, one real zigzag from each of the nine heads at eight standing places: behind the left refuge 0 of 9 reach the visitor (all nine end on PrimitiveCover_0_Left), behind the right refuge 0 of 9; the arrival, the console, the first pickup and the lane at z 6 and z 5 are reached by 9 of 9; past the array, behind the left cylinder, 2 of 9: the right column's [0, 2] and [2, 2] bend round the cylinder's edge where a straight line meets it. The straight-line prediction agreed with physics on 70 of 72 shots; the two disagreements are those bends.
- Inherited: from stage 1 the tile beside the arrival answers a real hand throw with x0.8 and +22.5 deg; at Tiling one throw changes 18 tiles and, new at 15:27, lights 18 flashes at once that are gone after 1.15 s; the pickups, two of them behind the array, are walked to from the arrival, 3 of 3 at stages 1 to 4.

### What the numbers add that ARRAYS.md does not say (DESKTOP, each measured)

1. **A row is one hit.** The three balls of row 0 reach a visitor standing still at the arrival 5.13 s after START, within 0.20 s of each other, and the arena counts ONE hit (readout YOU 1 OF 3): `hit_cooldown` is 0.75 s and nothing in a volley is faster than that. Mechanically the standing array is no more dangerous than one head; the group acts together for the eye only. If a volley is meant to cost more, count the balls of one volley (a cooldown per ball, or 0.15 s); if one hit is the intent, say so on the console. Acceptance either way: the probe's "counts the three balls of one row as ONE hit" check reads the chosen number. Codex-owned (`_on_ball_hit_player`). Palle's call.
2. **The bend never reaches the visitor.** The stored list bends 0.55 m to the side at a quarter, a half and three quarters of the way and ends on the sampled point, so the last bend is spent 1.9 m before the visitor and the ball arrives on the straight line. A sidestep of 0.8 m after the ball leaves is missed by all nine heads whether the visitor steps toward or away from the last bend: 0 of 18 hit at 0.8 m and 0 of 18 at 1.5 m, at both stages. "Read the line before the ball follows it" is true for cover (the cylinder above) and empty for the dodge, which is the same half-metre sidestep as against a straight ball. If the line is to matter to the body, end the list beside the sampled point on the bend's side, so the ball arrives from the side the line shows and the right sidestep is the one away from it; or widen the last bend to a metre. Acceptance: the probe's dodge table shows the 0.8 m step toward the bend hit and the step away from it missed. Codex-owned (`array_path.gd`). A design choice, not a bug.
3. **Missed balls never touch the floor from the entrance.** All 72 balls that missed the sidestepping visitor at the arrival (36 per stage) left the world at z 12.6 between 1.0 and 1.9 m up: the rows aim at head height, the flight continues on its last direction, and the floor ends 1.5 m behind the arrival. So at Colour and Tiling the inherited rule "skull impacts paint the actual receiving tile" cannot fire from the entrance. By the geometry it fires only with the visitor at z 8.2 or nearer for the top row, z 6.4 or nearer for the middle row, and never for the bottom row, whose ball rises after the visitor. The probe's one failing check is this expectation. If the skulls' colour is to reach the floor in play, end the list on the floor behind the sampled point (one more stored position, at floor height 1.5 m past the visitor), which also ends a miss instead of letting it fly 14 s. Acceptance: that check passes (at least one of 36 misses paints a tile). Codex-owned (`array_path.gd`, `ladder_ball.gd`).
4. **The warning is a one-pixel line.** The stored path is an ImmediateMesh line, which Godot draws one pixel wide at any distance, dark grey (0.12) on a grey sky (0.22) and a black and white floor. On the 1440 x 1000 arrival capture the three lines of a row warning add 1,277 changed pixels, 0.09 % of the frame, and the six white eyes are 0.39 deg each, five pixels. From the arrival a ROW warning reads as three dark strokes over the top row, because the lines run toward the viewer and only their sideways bends show; a COLUMN warning is seen end-on and collapses to three short dashes beside the heads. The sign ROW [1] / 3 OF 3 (0.16 m letters) is the readable part. The in-world rule under it, "One place stays empty when a skull falls. Read the line before the ball follows it.", is 0.057 m letters, 0.43 deg at 7.6 m, and a smudge in every capture, Codex's and mine. Proposed: draw the path as a ribbon or thin cylinder strip 3 to 4 cm wide (the old cue was a 9 mm cylinder), keep the sign, and raise the rule text to the sign's size or move it to the console. Acceptance: the rule text legible in the arrival capture (letters at least 0.8 deg); a row warning's changed pixels above 0.5 % of the frame. Codex-owned (`array_path.gd drawing`, `_array_frame`).
5. **A missed ball and its line stay for 14 s, so three groups share the screen.** The real loop for 32 s with a visitor who sidesteps 1.5 m the moment each ball leaves (`--mode=clutter`): no hit in 32 s, 21 balls sent, and every miss lived its full lifetime, 14.1 s, leaving the tree 27 m past the arrival and 3 m below the floor. With the 4.8 s interval that makes nine balls alive at once and twelve path lines on screen at once (nine flight drawings and three new previews), every cycle. The lines of balls long gone are indistinguishable from the lines of balls coming. Proposed: end a ball when it leaves the floor's extent (|x| > 6.5 or |z| > 12.5) or a second past its last stored point, which is also fix 3's floor-ending list by another route. Acceptance: the clutter mode's check passes (at most three balls and six lines alive while the visitor dodges). Codex-owned (`ladder_ball.gd`).
6. **The console is open to all nine.** The visitor presses START at the console in the open: 9 of 9 heads reach it and the first balls land 5.1 s after START. The nearest refuge is 2.5 m away, so the time is enough; whether a visitor knows to go there is a VR question. No change proposed beyond a line on the console.
7. **The walker walks through the live bottom-centre head.** Heads stand on layer 2 and the walker's mask is 1, so the centre line from the arrival to the far end passes through the body of [2, 1] at 1.3 m. Reach is unaffected; the feel is a VR item (the VR body's mask is whatever its scene sets). If it should block, give the bottom row a layer the body carries.
8. **Fallen heads pile up.** Nine fall to three spots (x -2.4, 0, 2.4 at z 3.5), three skulls in one place per column. Cosmetic. Proposed: offset the landing by row (z + 0.4 per row) so a fallen column reads as three. Acceptance: nine distinct landing spots.
9. **The Tiling flash is faint from standing height.** The eighteen flashes fire together and die after 1.15 s; 0.2 s in, the flash alone changes 0.5 % of the arrival frame at the 24-level threshold (2.0 % at 12), while the tiles' own shrink and turn change 4.1 %. From the entrance the near copies show a white rim; the far ones do not. VR to judge; a stronger first 0.3 s (alpha 0.5 and a wider rim) would read. Acceptance: the flash-alone diff above 2 % at the 24-level.
10. **Stage 5 exists on disk.** The console carries a sixth button, 6 CHANGE, at every stage, and Route has a Change entry (last Flow_Field, next forces / Vectors_Act1_WhatAVectorIs). Codex's B21, in progress; not reviewed. My route probe walks the first five stages with `--max-stages=5`.

### The route, rerun through five stages (DESKTOP)

From the game menu through Primitives, Transformation, Arrays, Colour and Tiling by the far-end NEXT STAGE button, then MUSEUM: 105 of 106 checks (report 15:49, `ada_run/biome_ladder_route/report.json`, entry captures stage-0..4-arrival.png). Every stage keeps everything earlier: three heads at stages 0 and 1 and the nine addressed heads from 2; the six tall shelters; the held catalyst and the lent hand; from 1 the motions, the three pickups and the 72-tile floor answering a real hand throw with x0.8 and +22.5 deg; six hues and tinted trailing balls from 3; eighteen copies and eighteen flashes at 4. Cover holds at all five stages (a real ball at the walker behind PrimitiveCover_0_Left is stopped, one in the open lane hits). All fourteen buttons (a sixth stage button, 6 CHANGE, has joined the console) stand at hand height, clear of forms, and are walked to from the arrival at every stage, 14 of 14 at Tiling after the pattern hit: **the reach problem of my 13:10 review is closed** by `set_walking_body` (15:27), and the three pickups are walked to at stages 1 to 4. MUSEUM raises Change_Intro (the museum reads change / Change_Intro and builds its first hall). The one failure is mine: the probe looked for the 12:05 wording of the Tiling hint and Codex rewrote it at 15:31 as "Shoot one tile. Watch all its copies flash." on the left refuge; the check now asks for the sentence, not the words. The process still exits 139 at shutdown after the staged museum, as before; the report is written first.

### Volley readability, from the stills (SCREENSHOTS)

- A row warning reads if you look for it: three dark strokes over the top row and the sign (Codex's arrays-volley.png, my s2-row0-warning). Two seconds into the flight the balls are the readable thing (s2-row0-flight-2s): three pale discs with halos, about 40 px across at 4 m, adding 10,460 brightened pixels (0.73 % of the frame) where the three lines added 1,277. In the overlap frame (row 1 warning over row 0 in flight) the balls still dominate and the six lines are secondary. So in play the warning is the sign and the eyes; the ball is seen once it flies, and its line reads only while the ball is on it.
- A column warning does not read from the arrival (s2-column1-warning); the sign carries it.
- The vacancy reads at once: EMPTY under the address and the skull on the floor below (arrays-vacancy.png, s2-vacancy-11). All nine down reads at once: nine EMPTY labels and skulls piled at the foot of each column (s2-all-down).
- The console and the hand glow still own the lower half of every arrival frame (route review 13:10, problem 2), and the "mushrooms" nature prompt still sits over the control hint.

### What Palle must test in VR (untested)

- The one-pixel line at 7 m in the headset and the 0.4 deg white eye, as the only warnings; the end-on column warning.
- The upper row 2.2 m above eye level: whether the top row's descending balls read, and whether looking up for a warning while a bottom-row ball comes level is fair.
- The 3 m refuge boxes at the entrance as walls beside the arrival; walking through the live [2, 1]; the pile of fallen skulls.
- Whether three balls arriving within 0.2 s read as one hit or three, and the damage flash.
- The 5 s from START to the first impact, and whether the console's exposure is understood.
- The overlap at 4.8 s (a new warning while the previous balls are 0.7 s from landing) and the persistence of missed balls' lines.
- The Tiling flash from standing height.


---

## Six-stage review, 2026-10-13 17:40, claude-edges-pilot (Primitives to Change; the consistency rules; captures from one standing position)

Read: PLAN.md and ACTIVE-CODEX.md (B22 in progress), CHANGE.md, my B19 section and probes. Evidence kinds: SOURCE (the runtime at each run's boot. Codex's B22 landed at 16:56 while this review was being set up: START/RESUME that keeps the floor, balls that end on a tile or at the arena edge, a tube warning; the physics run booted on ladder_encounter f05e21cd, ladder_skull f9af4120, ladder_ball e0cb5ba9, change_ball aedf6b6e, direction_field efeb3a3a, array_path 41c29cd6, route 6cc3a414; the captures run and the reruns on array_path 2f675f10, the tube having gone from 25 to 20 mm in between.) DESKTOP (my new probe `tools/probes/biome_ladder_six_review.gd`: physics mode over the six stages, 99 of 99 checks, rerun clean at 17:10 after three stale expectations of mine were corrected (heads sway only once active; a zigzag now has six stored points; the clutter rule measured by lifetime); captures mode, 27 frames from the walker camera at the true arrival at every stage, the same moments; `ada_run/biome_ladder_six_review/` with report.json, report-captures.json, capture_diffs.json; my route probe through all six stages, 132 of 132 checks.) SCREENSHOTS (mine, one standing position; Codex's change-after and change-warning are oblique and elevated, so they are not compared.) VR (none; the list is at the end.) No runtime file touched; the probe and this section are mine.

### Stage by stage (DESKTOP; the stills are the arrival view)

**0 Primitives.** Remains: nothing before it; the base is three heads on poles, six 2 m shelters, the held catalyst, the lent hand. New: aim, source, dodge, cover. Measured: a real ball reaches the visitor in the open lane and is stopped behind the first shelter; the heads do not move. Perceive and use: the entry still reads as a gallery to hide in; the warning at this stage is still the shared trial's 9 mm cue cylinder (0.85 grey, alpha 0.35) and the white eye: the three cues change 469 pixels of the arrival frame, 0.03 %, and are not found without looking; two seconds of flight change 0.08 %. The visitor learns the dodge from the ball, not from a warning. Most useful improvement: the B22 tube warning for the three-head stages too (the ladder skull can draw its own tube for non-array heads instead of the inherited cue). Acceptance: s0-warning's diff above 0.5 % of the frame.

**1 Transformation.** Remains: all of 0 (three heads, six shelters, catalyst, hand). New: eight motions (four forms translate, two turn, two scale, measured over 2 s), heads that sway from their homes once active (0.71 m in x; they hold still before START), three pickups, a floor of 72 tiles that answers a real hand throw with x0.8 and +22.5 deg. Perceive and use: a still cannot carry the motion; the tile answer beside the arrival changes 1.7 % of the frame and reads as a turned white tile; the warning is as at 0 (393 px, 0.03 %). Most useful improvement: the same tube warning, and a word in the world for the three operations (the B06 point stands).

**2 Arrays.** Remains: all of 1 (motions 8, pickups 3, 72 tiles answering). New: the standing 3 x 3 array with nine addresses, the row-then-column volleys (row 0 then row 1 measured under the real loop, three balls each in one tick), the vacancy. Perceive and use: with B22 the warning is a white tube from each firing head. A row warning now changes 1.15 % of the arrival frame (16,496 px) where the one-pixel line of B19 changed 0.09 %: thirteen times more, and it reads as three bright rods even against the sky (s2-warning). The sign ROW [0] / 3 OF 3 reads, and the rule under it is now one line, "A FALL LEAVES AN EMPTY PLACE", legible. Two seconds into flight the balls with their grey tubes change 1.30 %. A miss now ends on a floor tile 1.25 m past the visitor's cell (a sixth stored position): with a visitor sidestepping every ball, the longest a ball lived was 5.7 s, never more than two groups (six balls, six tubes) were on screen, nothing lingered. Unchanged from B19: the three balls of a row still count as one hit, and a 0.8 m sidestep suffices either way. Most useful improvement: decide the one-hit rule (count each ball of a volley, or say "a volley is one hit" on the console); everything else at this stage now works as described.

**3 Colour.** Remains: all of 2. New: the hand's own tint stays on the tile it hits (a saturated red measured); a skull ball that meets the floor paints the tile it meets; coloured forms, tinted trailing balls. With B22's floor landing the skulls' colour reaches the floor in ordinary play: in 16 s of dodging at the arrival, three tiles were painted by skull balls, against none of 72 misses in B19's runtime. Perceive and use: the hand's mark beside the arrival changes 2.5 % of the frame and reads as a red tile; the skulls' marks land 1.25 m BEHIND the visitor's cell, outside the arrival view, so the visitor who dodges never sees what the miss painted unless they turn round. Most useful improvement: land the miss beside the visitor's cell (on the side of the path's last bend) rather than behind it, so the mark sits in the field of view and tells which way the ball went. Acceptance: the landing tile's centre inside the arrival camera's frustum.

**4 Tiling.** Remains: all of 3 (the hand's mark now has 18 copies). New: one hit changes 18 tiles and flashes them together for 1.15 s; a second hit on any copy updates all 18 again (18 tiles at two hits measured). Perceive and use: from the arrival the flash with the transforms changes 4.1 % of the frame; the near copies' white rims read, the far copies foreshorten; the rule now stands on the left refuge at 0.087 m letters, "Shoot one tile. Watch all its copies flash.", legible from the arrival. The console reach is fixed (route). Most useful improvement: a stronger first 0.3 s of the flash (alpha 0.5, wider rim) so the far copies register from standing height (B19 point 9).

**5 Change.** Remains: all of 4 (36 marked tiles after two hits, nine heads, cover, pickups), and the outer columns keep their zigzag (now six stored points). New: 72 arrows, one per tile; a hit turns a tile and its arrow 22.5 deg and every copy; the centre column's ball follows the arrows for 1.4 s, stops, samples the visitor's head once, holds 0.9 s with a white line, then commits straight. Measured under the real loop: the drawn preview predicts where the field phase ends to 0.00 m; two hand throws on the centre path's cells bend the ball 0.96 m sideways in its 1.4 s; during the signal the ball holds still with the line to the sampled point, the visitor's head; after 0.93 s it turns once toward it and the line goes; a visitor who stands still is hit 3.1 s after the signal begins (4.5 s after the throw); a 1.5 m sidestep AFTER the signal is missed, a 1.5 m sidestep DURING the field phase is followed. Perceive and use: the arrows read on the near tiles and foreshorten on the far ones; the centre head's warning is a short stroke of 2.5 m beside the skull, dark along its length because the cue shader lights a tube only where it faces the viewer, and it is the quietest line on screen while the outer columns' tubes blaze (s5-field-bent-preview); at the signal the ball is 4.4 m away, 3.1 deg wide, white with a bright halo (from the arrival the white tube to the visitor's head is seen end-on, a dark ring round the ball's white core, s5-turn-signal; from beside the lane it is a long bright rod from the ball to the visitor, s5-turn-signal-from-the-side; the second, yellow ball beside the skull in those frames is the head's own throw 1.2 s after my probe's, a probe artefact, not a feature); the sign CENTRE COLUMN / ARROWS > SIGNAL > ONE TURN stands above the array in 0.12 m letters and reads. The lesson the numbers teach is "wait for the white line, then step": stepping early is followed, stepping after is safe, and the 3.1 s from the signal is a comfortable window. Most useful improvement: make the centre column's warning as bright as the outer tubes (light the field preview's tube from its length, not its facing, or draw the arrows the ball will cross in white for the 1.2 s warning), so the one ball that bends is the one the eye follows.

### Special attention (DESKTOP)

- **Arrays' attack warnings.** A row warning from the arrival: 0.09 % of the frame as a one-pixel line (B19) to 1.15 % as a 20 mm tube (B22), bright rods converging on the viewer. A column warning is seen end-on; the tube then shows as a bright disc at each head rather than a dash, which is the better reading of the two. Stages 0 and 1 did not get the tube (0.03 %).
- **Colour's floor impacts.** The hand's mark: 2.5 % of the frame, in view. The skulls' marks: now made in play (three in 16 s of dodging), always behind the visitor's cell, never in the arrival view.
- **Tiling's simultaneous copies.** Eighteen flashes in one frame, gone after 1.15 s; 4.1 % of the arrival frame changes with the transforms; the near rims read, the far ones do not.
- **Change's field-following and one-turn warning.** The preview predicts the flight exactly; the bend is 0.96 m after two hits; the signal holds 0.93 s and the commit is straight; the dodge after the signal is safe and the dodge before it is not; 3.1 s from the signal to impact. The weakest link is the field preview's visibility, not the mechanics.

### The consistency rules (DESKTOP, B22 runtime, every stage 1 to 5)

- START keeps a floor edit made before it: PASS at all five stages (hits, marks, scale, turn and the arrows unchanged across START).
- The START control reads START when ready and RESUME after REST: PASS; the console also says "START / RESUME keeps your work. RESET restores it." and the readout says REST while rested.
- REST stops the attack (no active head, no warning, no ball alive) and keeps the edit: PASS at all five.
- START after REST (resume) keeps the edit: PASS at all five.
- RESET restores the encounter: floor, flashes, arrows, heads at home, pickups, health, READY: PASS at all five.
- Missed projectiles and their paths: a zigzag now ends on a tile 1.25 m past the sampled cell, a Change ball at the arena edge; with a dodging visitor the longest life was 5.7 s at Arrays and 6.3 s at Change, nothing sent more than 7.5 s before the end was still alive, and never more than two groups (six balls, six lines) shared the screen: PASS at 2 and 5. Codex's own acceptance (biome_consistency.gd) sets the same six-ball ceiling.
- Still by design: NEXT STAGE drops the exact floor edits (CHANGE.md says so). The rule holds within a stage only.

### The route through six stages (DESKTOP)

From the game menu through all six stages by the far-end NEXT STAGE button, then MUSEUM from Change: 132 of 132 checks (report 17:09, `ada_run/biome_ladder_route/report.json`, entry captures stage-0..5-arrival.png). Every stage keeps everything earlier, Change included: nine addressed heads, six shelters, catalyst and hand, the eight motions, three pickups, 72 tiles answering a hand throw, eighteen copies and eighteen flashes, six hues and tinted balls, and Change states its rule in the world ("Shoot a tile to turn its arrows. The centre balls follow, signal, then turn once."). Cover holds at all six stages (a real ball behind PrimitiveCover_0_Left stopped, an open-lane ball hits). All fourteen buttons stand at hand height, clear of forms, and are walked to from the arrival at every stage, the three pickups too. MUSEUM from Change loads the staged museum, which raises forces / Vectors_Act1_WhatAVectorIs as its first hall. The process still exits 139 at shutdown after the staged museum, as before, with the report written first; CHANGE.md's note about Flow_Field's old artifact erroring at teardown is a separate museum matter.

### Observed problems, then proposed design changes

Observed (facts about the runtime as it stands): (1) the warning at stages 0 and 1 is the faint inherited cue, 0.03 % of the frame; (2) the centre column's field preview is a short dark stroke while the outer tubes are bright; (3) the skulls' floor marks land behind the visitor; (4) a row volley is one hit; (5) the walker walks through the live bottom-centre head (B19 point 7, unchanged); (6) the Tiling flash is faint from standing height; (7) NEXT STAGE resets the floor edits.

Proposed (design, Codex-owned, each with the acceptance above): the tube cue for the three-head stages; a bright field preview or white arrows along the predicted path; the miss landing beside rather than behind; a decision on the one-hit rule; a stronger first 0.3 s of the flash. Nothing proposed here is a bug fix; the mechanics all measured true.

### What Palle must test in VR (untested)

- The 20 mm tubes at 7 m in the headset, and whether a column's end-on discs read as "that column".
- The field preview beside the skull and the arrows underfoot: whether a standing body reads the bend before the ball makes it.
- The signal: a ball that stops 4.4 m away and goes white, then comes; whether 0.9 s is long enough to notice and 3.1 s long enough to step.
- Whether stepping early (and being followed) teaches or frustrates.
- The floor marks behind you; the eighteen rims at the flash; the START/RESUME caption at arm's length.
- The upper row above eye level; the three-ball row as one hit; walking through [2, 1].
