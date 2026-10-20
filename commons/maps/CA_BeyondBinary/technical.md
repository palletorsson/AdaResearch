# Fixed cells, travelling relations, explicit outputs

The installed primary is `game_of_life_petri:0:0#study:addresses#plinth:0#floor:walk`. The placement opts into `address_study.gd`; other instances retain the original dish and controls. The original `game_of_life_petri.gd` supplies the Life solver. No new Life rule is introduced.

## State and update

The study uses a 24 × 24 array of booleans, a separate next buffer, eight surrounding neighbours, periodic boundaries and B3/S23. `_advance()` fills the whole next buffer before swapping references. The old state is then available in `_next_grid` for the changed-cell count. Population counts occupied cells; CHANGED counts addresses whose boolean changed in the last update. Neither number identifies a travelling body.

Life is outer-totalistic: it uses the central state separately from the occupied-neighbour count. There are two central states and nine possible counts, giving 18 input cases. Arrangements with the same count receive the same answer for a given central state. This does not imply smooth behaviour. The historical room ID “BeyondBinary” does not describe this primary's state alphabet.

## Prepared comparisons

- GLIDER: a five-cell glider, centred through the base pattern placement at (7,7). After four updates its arrangement is translated by (+1,+1).
- BLINKER: three horizontal cells centred at (10,10). It repeats after two updates. Its centre remains occupied in both phases.
- MEET: the same glider plus a stable 2 × 2 block at x=10..11, y=10..11. Both are cells in the same automaton, not a collision body placed over it. The tested meeting is empty by generation 6.

Choosing a preset clears both buffers and event counters. REPLAY restores the current preset. STEP performs one update. RUN performs at most one update per 0.5 seconds; it drops overdue catch-up steps, so a slow frame can lengthen the observed interval. All runs hold at generation 48. These controls do not pause the museum clock.

## The room receives occupancy

The small dish and the 9.6 m square floor array read the same present, with the same x/y orientation. This map opts into `floor:walk`, with 0.4 m pitch and a forward offset that fits the existing front bay. Other address studies retain the original 4.8 m display and 0.2 m pitch. Markers and wires follow the same addresses; lamps align along the enlarged edge. The floor's geometry and support remain fixed; state changes its colour. The dish is raised onto a table. Gold markers identify A=(10,10), B=(13,13), C=(16,16) in both views.

Each marker is connected visually to a lamp. `life_address_receiver.gd` receives occupancy and the LINK setting. A connected, occupied address sets the globe emission and OmniLight energy; otherwise both are off. ONSETS counts 0→1 transitions while connected. Seed occupancy and reconnecting are not counted as births. Unlinked receivers still track cell state. No receiver writes back into the automaton, and no lamp identifies a pattern type.

This separation makes the application reusable: one can keep the rule and choose another receiver. A door, wall panel or sound would require its own implemented mapping and review. None of those additional outputs is claimed here.

## Placement and retained work

The 15 × 27 map has a front study and, since 8 October, a level open rear gallery. Raised strips, pits and its short internal partition have been removed. The secondary works are spaced around the onward route. All six artifacts remain. The sole primary and book hero are the Life dish; the other works remain available for subsequent comparisons. The active sequence order is unchanged. The former technical draft is archived under `doc/space/ca-life-review-2026-09-13/before/`; its advertised live rule tables and multistate controls are not the installed dish.

Runtime evidence and actual images: `doc/space/ca-life-review-2026-09-13/`. Desktop tests cover rule cases, wrapping, travelling and repeating patterns, event coupling, controls, support and a margin walk. Headset reach, comfort, performance and the secondary works require later review.


## 25 September staging and verification

The rear hexagonal terrain's radius-20, 0.5 m hexagons originally spread roughly 35 m across, reaching into the primary floor. `display:table` now scales its complete simulation root uniformly to 0.12 and places it over a 4.5×4 m table at the rear (9,23). All 1,261 sites, eleven retained layers, transition rule, random-flip mechanism and colliders remain. The control stays full scale at 1.4 m local height; the status label compensates the specimen scale. This is a table-scale comparison, not a new full-size walkable terrain. Other placements keep the original staging.

TRACE-off now restores the base dish display before refreshing the floor. Neither buffer nor generation advances. The earlier code restored the floor but left the dish's red/blue wake until a later update.

41 native checks pass, including fourteen real desktop pointer events, four-step glider translation, TRACE colours/restoration, lamp onsets/LINK, the six-generation meeting, body approach to A, occupied/empty support, and retained default floor and hex state dimensions. See encounter-notes.md for evidence and limits.


## Complete learner reconstruction — 8 October 2026

`tutorial.md` prints `life.gd` and the unchanged `point_body.gd`, maintained in `doc/book/studies/cellular-automata-through-the-hands/CA_BeyondBinary`. The 24 × 24 Boolean present uses a flat array and the same seed, periodic neighbourhood and B3/S23 rule as the installed primary. It supplies a complete small table, fixed tile instances, one address frame, one lamp and PointBody STEP. It omits the installed RUN, TRACE and preset UI. The student changes seeds to a blinker, then moves the output binding while keeping cell evolution unchanged.

29 native checks of the exact printed blocks pass: eighteen rule cases; all offsets/wrapping; separate buffer and order independence; solver parity through 48 glider generations and eight random beginnings; two meaningful fault variants; both transfer tasks; rendered colours and fixed transforms; collision support for empty/occupied sites; actual XRTools pickup/action/release with supplied controller poses. The first probe used an incorrect production property name (`initial_culture`); corrected to `culture` before the successful run. This was a test-harness defect, not a learner-code failure.

Walk-floor address-study placements now add `life_hand.gd`: the established pickable point carries the existing `step_once` action and parks beside the console on release. Moving the point never edits a cell. The Life solver and `life_address_receiver.gd` are byte-identical to this turn's baseline. Other address-study placements do not add the hand control.

Rear staging: mould at source (2,20), scale 0.4; growth network at (3,24), height 1.3 and scale 0.35; dark sphere at (6,21); screen at (1,19), facing inward. The hex table keeps (9,23). All six authored artifacts remain; no secondary algorithm was changed. Incidental sculpture is reserved out of circulation. Entry/exit use (6,0)/(6,26), with no extra gate. Only this generated museum-plan row is rederived.

38 museum checks pass, including eight capture checks: installed point action, LINK and onset preservation, TRACE restoration, blinker/meeting, support at A through generations 0/8/12, RUN/limit, stable floor transforms, portal approaches, and five routes with 306 samples of 0.56 m wide/1.7 m high capsule clearance and level floor on collision layer 1. Initial route samples touched the console and readout stem: the final route stops at a reachable console approach and goes around its furniture. This does not establish all-layer walking, full portal transfer, physical headset comfort or secondary-work interaction acceptance.

Current full texts, before/after overhead and visitor captures, native receipts and ZIP: `doc/book/iterations/2026-10-08-ca-a-pattern-visits/index.html`.
