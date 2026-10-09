# Fixed cells, travelling relations, explicit outputs

The installed primary is `game_of_life_petri:0:0#study:addresses#plinth:0`. The placement opts into `address_study.gd`; other instances retain the original dish and controls. The original `game_of_life_petri.gd` supplies the Life solver. No new Life rule is introduced.

## State and update

The study uses a 24 × 24 array of booleans, a separate next buffer, eight surrounding neighbours, periodic boundaries and B3/S23. `_advance()` fills the whole next buffer before swapping references. The old state is then available in `_next_grid` for the changed-cell count. Population counts occupied cells; CHANGED counts addresses whose boolean changed in the last update. Neither number identifies a travelling body.

Life is outer-totalistic: it uses the central state separately from the occupied-neighbour count. There are two central states and nine possible counts, giving 18 input cases. Arrangements with the same count receive the same answer for a given central state. This does not imply smooth behaviour. The historical room ID “BeyondBinary” does not describe this primary's state alphabet.

## Prepared comparisons

- GLIDER: a five-cell glider, centred through the base pattern placement at (7,7). After four updates its arrangement is translated by (+1,+1).
- BLINKER: three horizontal cells centred at (10,10). It repeats after two updates. Its centre remains occupied in both phases.
- MEET: the same glider plus a stable 2 × 2 block at x=10..11, y=10..11. Both are cells in the same automaton, not a collision body placed over it. The tested meeting is empty by generation 24.

Choosing a preset clears both buffers and event counters. REPLAY restores the current preset. STEP performs one update. RUN performs at most one update per 0.5 seconds; it drops overdue catch-up steps, so a slow frame can lengthen the observed interval. All runs hold at generation 48. These controls do not pause the museum clock.

## The room receives occupancy

The small dish and the 4.8 m square floor array read the same present, with the same x/y orientation. Floor cells have a 0.2 m pitch. The floor's geometry and support remain fixed; state changes its colour. The dish is raised onto a table. Gold markers identify A=(10,10), B=(13,13), C=(16,16) in both views.

Each marker is connected visually to a lamp. `life_address_receiver.gd` receives occupancy and the LINK setting. A connected, occupied address sets the globe emission and OmniLight energy; otherwise both are off. ONSETS counts 0→1 transitions while connected. Seed occupancy and reconnecting are not counted as births. Unlinked receivers still track cell state. No receiver writes back into the automaton, and no lamp identifies a pattern type.

This separation makes the application reusable: one can keep the rule and choose another receiver. A door, wall panel or sound would require its own implemented mapping and review. None of those additional outputs is claimed here.

## Placement and retained work

The 15 × 27 map adds a front study and an eastern aisle around the retained rear configuration. All six artifacts remain. The sole primary and book hero are the Life dish; the other works remain available for subsequent comparisons. The active sequence order is unchanged. The former technical draft is archived under `doc/space/ca-life-review-2026-09-13/before/`; its advertised live rule tables and multistate controls are not the installed dish.

Runtime evidence and actual images: `doc/space/ca-life-review-2026-09-13/`. Desktop tests cover rule cases, wrapping, travelling and repeating patterns, event coupling, controls, support and a margin walk. Headset reach, comfort, performance and the secondary works require later review.
