# One history, three mappings

This hall returns to the ordered row from CA_Introduction after the current route's three-state volume. It prepares for the binary Life dish in CA_BeyondBinary by distinguishing a two-dimensional history image from a two-dimensional current state.

## Actual implementation

`algorithms/cellularautomata/ca_bridge/ca_bridge.gd` retains its standalone bridge. Only `#study:history` installs `history_study.gd`. The module sets width 15, record length 24 and Rule 30. Its call to the parent's `_calculate_next_row` uses periodic left/right neighbours and a separate next row. All three views read one `history` array; no independently seeded approximation is used for the wall.

```gdscript
var index = (a << 2) | (b << 1) | c
```

This excerpt is from the base `_apply_rule`. Bit `index` of `rule` supplies the result. The eight answers for indices 0 through 7 are 0,1,1,1,1,0,0,0. On a fifteen-site ring a single centre cell produces occupied sites 6,7,8 after one update.

From the study's `_advance`:

```gdscript
var next_row: Array = work._calculate_next_row(history.back())
history.append(next_row)
```

## Walking through the record — 25 September

The map opts into `#follow:walk`. `history_study.gd` reads CharacterBody3D roots from `em_walker` and `player_body`, in the study's local coordinates. Within the recorded bay and its margins, `floor(z / CELL + 0.5)` selects the nearest retained generation. The deck, screen and record witnesses move together. Their contents and support shapes do not change. No body measurement is written into the automaton.

The selection region excludes the desk, neighbouring halls, future rows and bodies above the display. Leaving it retains the selected row; ROW at the desk remains available. Walking does not pause RUN. The floor witness extends to 8.8 m across the margin; it is a visual marker, not support. A ground inscription introduces this use without another control panel. Unconfigured history studies keep their 6.1 m witness and manual selection.

Current native results and limitations: [encounter-notes.md](encounter-notes.md).

## State and controls

The specimen arrives held with generations 0–11. REPLAY resets to generation 0. STEP appends one generation and holds; RUN appends at most one row per 0.5-second timer interval, stopping at generation 23. ROW pauses RUN and selects an earlier recorded row without changing history. SEED cycles SINGLE, PAIR and a local RNG seeded with 23090 at density 0.45. FLIP X9 toggles only site nine of that beginning; both seed controls replay. The museum clock is unaffected.

The current model does not accept a continuous stream of visitor proximity or object contact. Its input is the initial row selected at the desk. A contact-driven extension would be a new intervention rule and must declare when it writes state.

## From data to space

For site x and generation g, deck centre = `((x-7)*0.4, -0.11, g*0.4)`. A tile measures 0.4×0.22×0.4 metres and supports at y=0. Only occupied recorded cells enable their pooled collision shape. Empty sites reveal the basin floor at y=-0.60. The basin covers the complete seven-by-ten-metre source-grid opening. End ramps return to rim height; the side passage offers a separate route.

The flat record uses the same entries, with future rows darker than recorded zeroes. In the ornamental screen, site address becomes height (`0.5+x*0.17`) and generation remains depth (`g*0.4`). Colours are a fixed mint-to-lilac mapping of generation, not another state variable. Bronze framing has collision; coloured lattice infill is visual. Material emission is a finish, not implemented projected illumination. A gold witness identifies one selected generation across the three mappings.

Three MultiMeshes and 360 pooled support shapes bound the study's work. Reset does not spawn another collection of nodes. Collision toggles are deferred to the physics-safe boundary, so read physical support after the next physics frame.

## Verification scope

See `doc/space/ca-history-review-2026-09-13` for exact runtime receipts, source hashes and screenshots. Tests exercise the inherited rule, wrap, replay, one-bit intervention, history limit, all three mappings, collision rays and six controls through the project's real desktop pointer. The pointer rig is placed in the actual museum; it is distinct from the museum's ordinary desktop walker. A walked stretch of margin is not a headset traversal acceptance or proof of a continuous route over generated cells. Retained secondary artifacts need further individual review.


## Complete learner reconstruction — 8 October 2026

`tutorial.md` now prints the entire `history.gd` and unchanged `point_body.gd`, maintained under `doc/book/studies/cellular-automata-through-the-hands/CA_GameOfLife`. The smaller study reserves 360 slots in each of two views, copies Boolean rows, uses a held point's local Z to read history and its action to append. Its 24-row limit includes the seed. It does not reproduce the basin, desk controls or RUN timer. The installed Rule30 solver and history study are unchanged.

Native test tools: `tools/test_ca_history_lesson.py`, `tools/probes/ca_history_lesson.gd`. The exact printed files pass 30 checks, including eight deterministic seeds through all 24 rows versus the installed solver, rejected aliasing mutation, independent seed/mapping exercises, renderer/collision agreement and actual XRTools with supplied poses.

The rear gallery is levelled; the east passage opens around the lab. The orb moves to source cell (4,28), columns to (8,28). All six authored works remain. Incidental generated sculptures are reserved out of this narrow circulation. Entry (6,0) and exit (6,36) use the thresholds; no extra gate. Only this generated museum plan row is rederived. The front basin and its ramps stay intact.

35 native museum checks include cameras, walking selection, preserved state/support, replay/seed/capacity, surface and lower-floor rays, portal approaches and five routes with 451 samples. The capsule is 0.56 m wide and 1.7 m tall, tested on layer 1; this is not dynamic all-layer walking, a portal transfer, physical headset or Quest acceptance. The rear lab apparatus remains a secondary encounter rather than a tested lesson.

Current report, before/after native views and receipts: `doc/book/iterations/2026-10-08-ca-history-three-bodies/index.html`.
