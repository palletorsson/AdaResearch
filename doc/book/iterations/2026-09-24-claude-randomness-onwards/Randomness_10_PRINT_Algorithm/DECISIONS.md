# Randomness_10_PRINT_Algorithm — first delivery

Sequence `randomness`, hall 4 of 14. 24 September 2026. Verdict: **Development.**

---

## 1. What the hall had, and what the chapter used

The chapter anchored one work, `ten_print_maze_3d`: three upright ten-metre fields with an ant. It gave repeated looking instructions and never mentioned the two works that actually do the argument's work. Both were already placed.

- **The printer** (`ten_print`) runs `10 PRINT CHR$(205.5+RND(1)); : GOTO 10` on a seeded coin. Its console shows the line and carries BIAS −/+, SEMICOLON, RESEED, STEP and RUN. BIAS rewrites the constant in the displayed line (K = 206 − bias). SEMICOLON removes the `;` and every character starts its own row, which is what the semicolon does in Commodore BASIC.
- **The floor** (`ten_print_structure#form:floor`) finds the printer on `#channel:hall` and lays every printed character down as a low ridge in the same cell.

What the chapter promised and the hall did not do: the upright fields cannot be entered. They have no collider and stand in the Y–Z plane. They were flat on the floor before 27 November 2025 (commit 3e73f6f6b) and were never collidable in either form.

## 2. The encounter added: a walkable printed maze

One token, one cell, in this hall only:

```
ten_print_structure:180#form:wall#size:1.1#cols:4#rows:3#solid:on#seed:1982#count:12#plate:none
```

It stands the printer's first twelve characters, same seed, up as solid slabs four to a row. No artifact source changed; every key already existed. A first try at four rows (sixteen characters) was sealed by the museum as a severed pocket and was cut to three.

What twelve coin flips made, measured on the museum lane:

| | |
|---|---|
| slabs | 12, solid, 2.40 m high |
| channel between parallel slabs | 0.72 m, from the code's formula (size / √2 − slab); not measured by a probe |
| coin results | 12 of 12 identical to the printer's first twelve |
| regions | 8: seven open to the outside, one sealed |
| corridors | each open region has exactly two mouths, so none forks; four are V-shaped bays two triangles deep, two are single corner triangles, one runs ten triangles through |
| way through | yes, from the side facing the printed floor to the side facing the way in |
| museum seal | no severance |

The sealed region is the chapter's best image: a room made by the rule that nobody can stand in. The second is structural and was found by the review: a 10 PRINT field has no forks, because every triangle between the slabs opens on two sides only. Here that means four shallow V-shaped bays, two cut-off corners and one corridor through. The maze-reading on the screen belongs to the lines; the passages never branch.

**The crop is a decision.** The way through depends on where the block stops. Wrapped three to a row, the same twelve characters give no way through and no sealed room; four rows deep, they give a sealed room and no way through. The chapter says so: "The rule did not choose where to stop. Whoever placed the block did."

## 3. The revision

Original at `before.md`, candidate at `after.md`, installed as canonical `final.md`. `text.diff` alongside.

**Preserved:** the question; the distinction between a drawn connection and a passage connection, now placed at the sealed room where it bites; the ant as a separate procedure; the textile and passage readings, now named as the two the visitor has just had.

**Changed:** the chapter now takes the line apart before it looks at any maze. The coin and the semicolon's wrap are the two things the look of a maze needs; removing each gives stripes or a zigzag column that can enclose nothing. The breathing coin is read before BIAS is pressed, because the first press ends it for good and the console shows 205.5 throughout. The floor is the screen's last seven rows, a window that forgets. The slabs are the same coin stood up: no forks, mostly shallow bays, one sealed room, one way through that depends on the crop. The Molnar grids set a fixed count against a free coin. The upright fields are pictures of passages a body walks through, and the ant is a separate procedure boxed in by its own map. The closing contrasts the floor's forgetting with the next room's tally.

**Preserved, but moved or cut:** "Neither reading changes the original two-choice rule" and "which promises your interpretation adds" survive in a closing paragraph that now names the two readings the body has just had. "There is no need to treat the larger structure as either secretly planned or entirely meaningless" was cut: four reviewers found the abstract comparison redundant after the walk. "One local replacement can alter a much longer-looking contour" is restored in the ant section.

**Anchors:** `@ten_print_maze_3d` covered the whole chapter before; it now covers only its section. `@ten_print_structure` covers two placements of one token, the floor and the walkable block, because the tag grammar is token-only. `@ten_print` and `@composition_stochastique` are new.

**Companions:** `blurb.md` and `intent.md` rewritten. The old intent said `pickup_cube_placer` and `remove_random` modify the maze and `nature_system_demo` overlays it. None of that happens. Before-copies are in this folder.

## 4. Evidence

Two headless gates, both exit non-zero on failure and carry a completion sentinel.

**`commons/testing/probe_ten_print_hall.gd`**, 11 checks, all pass.

| | check | measured |
|---|---|---|
| A | floor links and fills | 122 floor cells from a 382-cell screen |
| B | floor matches the screen | 0 of 122 disagree, window offset 13 rows |
| C | the console line | `10 PRINT CHR$(205.5+RND(1)); : GOTO 10` |
| D | SEMICOLON off | `;` leaves the line; floor 20 columns → 1, seven ridges in column 0 |
| E | SEMICOLON on | the plane returns, 20 columns |
| F | BIAS | 205.1 → 0.87 forward; 205.9 → 0.07 forward |
| G | the coin breathes | characters 0–269: 0.70 forward; 270–399: 0.29 |
| H | next-cell tile | visible |
| I | floor collider | none |
| J | upright maze | 0 collision shapes, 0 bodies; 101 meshes, x 0.60 m, y 10 m, z 10 m |

**`commons/testing/probe_ten_print_walkable.gd`**, boots the real endless museum at the hall. All pass.

| | check | measured |
|---|---|---|
| A | kept | 12 verbatim of 13 placements; `nature_system_demo` left behind |
| B | solid | 12 shapes, 2.40 m |
| C | floor still a venue | 0 shapes |
| D | same coin | 12 / 12 match `coin_is_forward(r*COLS+c)` |
| E | regions | 8; 7 open, 1 closed; way through true |
| F | a body gets in | 7 of 8 far and near edge openings admit a 0.5 m capsule |
| G | museum walk | no severance; walk cells connect entry (4,0) to exit (6,7) |
| E2 | corridors | 7 open regions with 2 mouths each; 14 boundary edges; triangles per open region 1, 1, 2, 2, 2, 2, 10 |
| H | the route | far to near through 10 triangles, 22 segments |
| I | wrap width | same 12 characters: 3 to a row 7 regions, 0 sealed, no way through; 4 to a row 8 / 1 / way through; 6 to a row 8 / 0 / way through; one line 13 / 0; 16 characters 4 to a row 9 / 1 / no way through |

`python tools/map_pathfinder.py check Randomness_10_PRINT_Algorithm`: 182 of 182 reachable.

## 5. Limits

- **No headset walk.** The channel width is computed, not felt. Seventy centimetres is passable in a body; whether it reads as a corridor or a squeeze is unknown.
- **Book page citations are unverified.** The artifact source cites page 68 of the 10 PRINT book for the semicolon. The chapter's footnote cites the book, not pages. Downloading the 50 MB PDF from 10print.org awaits permission.
- **The clipboard and the science screen still say wrong things.** They sit in shared or out-of-scope files. See INTEGRATION.md §2 and §3.
- **The walkable maze is fixed by seed 1982.** RESEED on the printer changes the screen and the floor, not the walls. The chapter says the walls are a still cut from the start of the stream, which stays true.
- **Probe F tried only the far and near openings,** and one of those eight did not admit the test capsule; the cause was not traced. The six side openings were not tried.
- **The museum's walk map seals the block's footprint.** A body walks the channels by physics (probe H); the museum's own walker and its reachability map treat the block as solid ground it cannot enter. No severance results.
- **Several checks re-evaluate the coin rather than read the screen.** Hall probe F and G and walkable probe D compare formulas with themselves, so they could not fail on a display fault. Hall probe B compares cell values, not which way a ridge leans; the lean is taken from the structure's own orientation contract.
- **The ant was not probed.** Its confinement follows from its navigation grid (4-connected moves on 2×2 sub-cells in which every diagonal fills two of four, so the free sub-cells around one grid corner form a closed group) and from the wipe in `_on_wall_timer_timeout`. Reviewers' simulations agree; they are not repository probes.
- **The tile's speed is read from code,** 0.2 / (1 + 2 sin 0.2t) seconds per character, one per frame while that term is negative. A reviewer's live run measured 5–14 characters a second and a 90-per-second phase.

## 6. Shared patches

INTEGRATION.md §1 (room record), §2 (clipboard text), §3 (science screen), §4 (leftover placements).

## 7. Hashes

| file | before | after |
|---|---|---|
| `final.md` | `259612018d5721a305e97399d9c5652c5db6917fe019651bca5774c8f4fd8535` | `56990ed63307386d326e6462b1dbce436bafc726d44514c0d27a62d272e51d4f` |
| `map_data.json` | `0e379f864cf05ac6e6dc9e83775c4a6682a4979669d7ce64f21c994fd0ec2a77` | `e1fc0befa3a25392a31d57855d1a7db4b1090a57636ddee3c691e7e4dca6a77d` |
| `blurb.md` | see `blurb.before.md` | `077957f759b188d685d93671dfcf77fcb94a88b5a65c40885c5d44416190765b` |
| `intent.md` | see `intent.before.md` | `4578577ec39a29aa17167a5f3ad40ddcc3903f8811720535278b267d0c09c84a` |

The map's only change is one cell (`map.diff`). Its working-tree copy already carried another session's uncommitted reformat before this block began; the before hash is that reformatted file, which is also what `museum_core_encounters.json` records.

## 8. Review

Six reviewers (fact-check, spatial, blind beginner, voice, loss against the original, sequence continuity), each contested claim re-checked by a second agent, and an editor judge. Verdict: ship with fixes. The five mandatory replacements are applied. Optional replacements taken: "where the coin balances" and "the side that faces the way you came in". Not taken: naming in the chapter that a four-row block was tried first; the reason it was cut was the museum's walk seal, and the sentence would invite a wrong reading of why.

Evidence images: `hall_plan.png` (plan, yaw 0, top of frame toward the door), `hall_tp_eye.png` (standing beside the slabs, the ridged floor and the Molnar board beyond), `hall_tp_vest.png` (from the vestibule).

