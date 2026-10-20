# Biome ladder — a world that learns with the visitor

Owner: Palle. Working coordination: Codex + Claude, 2026-10-13.

**Current step: review B22 before Forces.** [State and readability report](consistency.html), [Claude's exact files and fresh captures](CLAUDE-CONSISTENCY-HANDOFF.md). START/RESUME preserves floor edits, vacancies, damage and consumed pickups; only RESET restores these. REST clears shots. Arrays' stored zigzags gain an announced floor landing and warnings have physical width; spent/out-of-bounds shots take their guides with them. This supersedes historical START-reset descriptions below. No cross-stage floor persistence is added.

## Brief

After each museum sequence, enter a biome whose forms, terrain and skulls use the operations learned so far. The biome itself is the arena. Standalone entry also permits playing and comparing stages. Preserve the same sphere/catalyst identity. Later ecology can grow from the existing generation-17 biome; do not introduce its full vocabulary into the first stage.

Current scope: six playable stages, through Change. Palle confirmed the later ground progression on 2026-10-13: walkable sine relief in Waves, rougher random ground, then smoother correlated ground in Noise. See TERRAIN-LINEAGE.md; those later stages are not yet built.

| After | World | Counterpart | Carry onward |
|---|---|---|---|
| Primitives | 12 × 24 m static white floor with thin black grid outlines; a grid of spheres, cubes, cylinders and cones; clear central route | Fixed monochrome skulls on poles; small slow balls; a hit drops a skull and ends its attack | Aim, source, dodge; recognise primitive cover |
| Transformation | White outlined tiles: a catalyst hit scales the receiving tile by 0.8 and turns it 22.5 degrees. Solid backing remains. Forms move; walk-over pickup cubes restore health. | Heads move and turn; balls grow with a bounded visible collider | Read a moving opening; time a crossing |
| Arrays | Black/white grid; repeated form rows; same learned motions and ×0.8/+22.5° tile response per catalyst hit | Standing 3 x 3 addressed array; row then column volleys; slow stored zigzag paths; a defeated head leaves its slot empty | Read spacing, repetition and an absent member |
| Colour | Same primitives gain colour; disco tiles keep the ×0.8/+22.5° catalyst response and also retain the impact colour | Heads remain black/white; coloured balls with brief particle tails | Colour marks an event and a changing surface |
| Tiling | Same floor and cover; a catalyst impact repeats ×0.8 scale, +22.5° turn and colour at the matching address in every 2 × 2 motif (18 tiles). | Same indexed moving heads; their colour impacts remain local. | A local operation becomes a floor-wide pattern. Any copy can change the motif again. |
| Change | Tile arrows use the inherited turn; catalyst impacts still shrink, colour and repeat. | Centre-column balls follow the field, signal a sampled target, then commit once; outer columns keep zigzags. | Read a direction and a delayed decision. Forces adds acceleration next. |

B19 implements the standing array in Arrays and carries it into Colour and Tiling. [Report and captures](arrays.html). Earlier cover, pickups and tile responses remain; book texts and sequence order are unchanged.

B20/B21: Tiling now signals all copies together and keeps controls reachable. Change adds tile arrows and centre-column shots that follow, signal, then turn once. [Implementation and evidence](change.html).

## Decisions for the first build

- Current arena length is 12 m. First ladder build doubles that to 24 m while keeping width 12 m. This is a testable interpretation of “double current length”.
- A successful catalyst hit drops an early skull. This updates the earlier three-hit skull rule for ladder stages only. Player still dies at three discrete projectile hits. The older full-biome arena retains its previous rules.
- Shots begin at 1.8 m/s, radius 0.09 m, with a visible warning. Bounded growth after Transformation. Primitives and Transformation retain three skulls with staggered fire. B19 expands Arrays onward to nine places, with one row or column selected every 4.8 seconds; shots remain capped per head.
- START begins danger; REST clears hostile and player shots; RESET restores heads and pickups. NEXT STAGE and previous-stage controls support standalone comparison. CONTINUE MUSEUM opens the next sequence.
- Museum hand ability remains earned at Point_Coordinates. Standalone practice lends the ability and restores earned state on exit. Never overwrite player progression to test.
- Desktop practice: mouse aims; left click sends the shared catalyst ball from the visible point. Arrow keys move, T starts/rests, R resets, Esc releases/recaptures the cursor. Right click still grabs/releases objects. The same controls work in Head Arena. The form is supplied automatically during practice; VR keeps its hand gesture.
- Add a marked biome entry at the final hall of each of the six sequences. Keep the existing museum passage available. Forced routing through combat is not required for reading the book.
- Early world is geometry; later world can become ecology. Keep the older display ladder and mature biome available.

## Tasks and ownership

| ID | Task | Owner | Acceptance |
|---|---|---|---|
| B01 | Four playable stage configurations and standalone entry | Codex | Each stage loads; 12 × 24 ground; correct forms and colours |
| B02 | Slow balls, fixed/moving heads, falling defeat | Codex | Swept hit, bounded scale/collider, no fire after defeat, reset restores |
| B03 | Hand catalyst, health, death/return | Codex | Practice ability, three player hits, return to same stage, saved unlock unchanged |
| B04 | Museum boundary entries and onward route | Codex | Last hall entry reaches correct stage; continue reaches next sequence |
| B05 | Native captures and automated probes | Codex | Evidence per stage; explicit distinction between runtime checks and headset play |
| B06 | Review density, cover, pacing, subject fidelity | Claude, review received 2026-10-13 | One focused reply per stage, with evidence and proposed next action |
| B07 | Propose next stages after Colour | Claude proposal received; floor portion implemented as B15 | Reuse existing vocabulary; separate implemented / proposed; no broad rewrite |
| B08 | Headset playtest and tuning | Palle + agents | Reach controls; source/aim/dodge; comfortable distances; return paths |
| B09 | Desktop shooting for rapid iteration | Codex, implemented | Real mouse/keyboard dispatch, same projectile collisions, working controls and held tools; 47/47 runtime checks |
| B10 | Standing cover in Primitives | Codex, implemented; Claude independently tested | All six tall shelters stop the tested standing shots |
| B10-test | Independent four-stage cover report | Claude, received 2026-10-13 | 106 real flights; Primitives tall cover works; stages 1–3 fail standing-cover acceptance |
| B11 | Carry cover into visible transformation | Codex implemented; independent review requested | 82/82 new assertions; Claude probe rerun passes 114 flights; TRANSFORMATION.md records results |
| B12 | Floor retains ball colour | Codex implemented | 40/40 real-input/flight checks; COLOUR.md records the scope |
| B13/B14 | Tile response persists through Arrays and Colour | Codex implemented | 90/90 real-input/collision checks over three stages; Colour adds recolouring to the same hit |
| B15 | Tiling repeats a hit across the floor | Codex implemented | Actual hand/held projectile, 18 copies, cumulative transform and colour, backing collision, reset, fifth-stage control and museum boundary; TILING.md |
| B16 | Skull hits in quiet practice and active play | Codex fixed | Controlled XR trigger and real physics: 106/106. READY/REST allow hits; floor callbacks reject skulls. SKULL-HITS.md |
| B17 | Reuse the older biome across the full spine | Codex source review / plan | 25 sequence cards; 56 source files verified present. SCAFFOLD.json is editable; scaffold.html and SCAFFOLD.md show proposals separately from the five playable stages. No new runtime stages. |

**Latest expansion plan:** [scaffold.html](scaffold.html). The older cumulative grammar, retained-form bridge and walkable terrain supply the scaffold. First fix the current route's post-Tiling control obstruction, then connect stable surface/state records and build Change through Noise one stage at a time. Later groups are mapped, not implemented. Do not infer capability from an old layer's name or reuse old numeric unlock orders as current spine indices.

## Collaboration protocol

Read this brief and HANDOVER.md, then the task you will claim. Once the forum thread exists, post the task ID and exact file paths before editing. Codex owns the first runtime pass under `commons/hazards/biome_ladder/`, its probes, the narrow menu/museum hooks and this planning page. Claude can begin with B06/B07 in CLAUDE-REVIEW.md without changing those runtime files. Propose a small task, agree its ownership, build it, test it, attach an inside-the-world screenshot and report remaining uncertainty. Do not overwrite another agent's edits, regenerate unrelated museum plans, or alter tutorial/final text as part of this pass.

The planning page displays this brief, stage evidence and any published forum discussion. Forum publication was rejected by automatic approval review ("blocked by policy", no specific reason). No thread was created. FORUM-OPENING.md is the prepared opening post. The brief and review file can be shared with Claude now; the forum remains the intended conversation once publication is available. A claim or proposal is not evidence of completion. Claude’s source/capture review was received on 2026-10-13 in CLAUDE-REVIEW.md. B10 and B11 cover are implemented. TRANSFORMATION.md records phase tests and the successful rerun of Claude’s independent probe. B12 Colour marks and B15 Tiling repetition are implemented. See TILING.md for the current scope.


## Next work — review received 2026-10-13

Work in this order, with one focused change and evidence per task:

1. **B10 / Codex implemented: real cover in Primitives.** Own `commons/hazards/biome_ladder/ladder_encounter.gd`, initially `_landscape` only. Bring selected boxes/cylinders nearer the route and make them tall enough to shield a standing visitor. Retain the white outlined floor and a clear central walk. Determine placement from real sight lines and collision tests, not the proposed coordinates alone. Damage, projectile speed and skull count are unchanged. See COVER.md: 27/27 cover checks, 47/47 desktop checks and 54/54 stage checks pass, with native before/after captures.
2. **B10-test / Claude received: independent cover acceptance.** Actual file: `tools/probes/biome_ladder_cover.gd`. Its 106 real flights confirm all six tall Primitives shelters work; tested standing cover is 0/11, 0/10 and 0/10 in the next stages. Its exit 1 is a useful cross-stage finding. The original report matched the runtime at planning time; that baseline is preserved in claude-cover-before.json. See NEXT-ITERATION.md for test limits; Codex subsequently reran the unchanged probe after B11; it now passes, with six standing shelter successes in each stage.
3. **B11 / Codex implemented: cover carried forward.** See [TRANSFORMATION.md](TRANSFORMATION.md). The entrance refuge stays fixed; spheres translate, far boxes rotate, cylinders grow from the floor, pickups remain reachable. Transformation keeps the outlined white floor. New phase/collision probe passes 82/82; Claude's unchanged probe passes 114 flights; existing stage, desktop and Primitives suites pass. Next requested Claude task: independent review of this result and phase coverage. That review is not yet claimed.
4. **B12 / implemented Colour:** hand, held-sphere and skull balls colour the floor tile they actually hit. Marks survive REST, later hits recolour them, RESET/new START clears them. The untouched disco is dimmer and slower. 40/40 rendered checks pass. See COLOUR.md.
5. **B15 / implemented Tiling:** a 2 × 2 motif repeats across the floor. One catalyst hit changes 18 matching tiles; any copy can update the motif again. Scaling, rotation and colour remain cumulative. See TILING.md. TERRAIN-LINEAGE.md keeps the confirmed Waves → Randomness → Noise ground progression visible while we work one stage at a time.

B14 implements Palle's cumulative rule: tile transformation persists in Arrays and Colour. Colour is an added response on the same tile collider, so gaps and cover cannot paint through to a hidden tile. See TRANSFORMATION-TILES.md for the expanded runtime checks.

Historical B06 response, superseded by Palle's B19 standing 3 x 3 array: keep the initially complete Arrays row for now. Shooting creates the absent member; that connects the concept to the visitor's action. Four places with one already empty remains an alternative for comparison, not an accepted replacement. Keep current one-hit ladder defeat and three-hit player health until play gives a reason to change them.

Claude's B07 Tiling proposal is recorded. B15 implements its floor source/copy direction with Palle's cumulative hit rule. Extra head copies and mirrored cover are still proposals. Next sequence in the spine is Change; agree one addition before building it. No tutorial or final.md changes in these tasks. Palle can compare the desktop stages now; headset checks follow the desktop iteration.
