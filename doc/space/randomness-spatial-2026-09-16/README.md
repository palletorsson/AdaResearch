# Randomness: instrument and spatial encounter

Second staging pass, 16 September 2026. User requested larger grid simulations in glass enclosures, a larger 1955 number page, a walking-triggered removal floor over fire, random fire/pass doors, and controls reachable from one standing position.

The seven active halls and their order remain. This pass retains all 25 placements from the preceding compact pass and adds three placements: the removal arena in Remove, its deliberate reprise in Game, and the random doors. There are 28 placements, 27 distinct lookup names. The earlier, more populated layouts remain archived under `../randomness-staging-2026-09-16/before/`; this pass's immediate inputs are under `before/`.

| Hall | Source grid | Change |
|---|---|---|
| Definition | 13 × 16 | 1955 page enlarged from 1.6 × 2.4 to 3.2 × 4.8 m; compact seed controls |
| Entropy | 17 × 23 | Square 16 × 5 × 16 displacement field in a 10 × 10 m glass enclosure; compact ledger controls |
| Remove | 17 × 26 | Existing 64-cell bench plus 99-cell physical removal floor and fire basin |
| Walk | 19 × 26 | Existing terrarium plus native ten-metre field inside a 12 × 12 m enclosure |
| Gaussian | 11 × 13 | Distribution and sampling panels on one console |
| Mushrooms | 17 × 20 | Six-metre bed inside an 8 × 8 m enclosure; four-metre openings beside the table |
| Game | 19 × 45 | Existing crossing and falling field, 81-cell removal arena, and three seeded doors |

## Runtime implementation

- `commons/artifacts/randomness_space/museum_exhibit_stage.gd`: opt-in furnishing installed by the museum's artifact stamp. `glass_width/depth/height/entry` define a collidable glass boundary with open front and rear. Grid strokes have no collision. `controls:compact` moves existing Rack panels into an 80 cm control group; original buttons and callbacks survive. The standing mark is 57 cm in front. `control_front/facing/height/floor` handle different native orientations and root heights. `control_fixed:true` keeps the cycling cube's console on the bank while its root moves.
- `removal_arena.gd`: reuses `RemoveRandom.gd` and its owned MultiMesh selection. One collider belongs to each floor cell. Entry requests one draw; another 60 cm of accumulated horizontal walking requests the next when no draw is pending. A 0.8 second red warning precedes deletion. The permanent apron is not eligible. Replay cancels pending work and restores both rendering and collision.
- `random_doors.gd`: one safe index per seeded round. All choices have a physical lifting door. Two choices announce fire for one second, then extend a 2.7 m jet, with mesh and hazard volume changing together. The pulse ends and the unsafe door closes. The safe passage stays open. Replay cancels pending actions; a new seed can select the same passage. Fire uses the existing museum death/respawn method.
- `entropy_axiom_multimesh.gd`: square configuration centers a 16 × 16 plan with five vertical layers and larger points. Enables the already-authored instance colours. This is explicitly random displacement, not a measurement of Shannon entropy.
- The museum accepts an optional `basin.fire_top` so the burning surface stays at the base. Arena tokens explicitly compensate for the museum placing an artifact on a basin floor.
- The Shannon display rebuild and board-lifting routines preserve `em_exhibit_stage` children. This prevents DISCLOSE from destroying or lifting its console.

Book markers, roles, artifact inventories, book captions, both museum plans and derived spine data accompany the map changes. The new primary encounters have concrete prose in `final.md`; existing stronger passages remain.

## Verification and review

`probe.gd` builds each actual endless-museum hall. It captures arrival, overview, instrument, and spatial views, checks measured control reach and floor support, and emits every button on the moved panels. It checks that the console survives rebuilds at the same height. The two new interactions are exercised through entry, walking, replay, actual VR-button signals, fire collision and museum respawn. `verify.py` adds data, role, placement, bounds and live-book checks; its full result is `verification.json`.

The removal capture uses twelve sequential draws at the normal warning duration. The fire capture shows a live jet. These are engine captures, not mockups.

Run from repository root:

```powershell
python doc/space/randomness-spatial-2026-09-16/run_probe.py
python doc/space/randomness-spatial-2026-09-16/verify.py
python doc/space/randomness-spatial-2026-09-16/build_review.py
```

`stage.py` and `text.py` are the reproducible curation scripts; they are not needed to launch the museum. Re-running them intentionally reapplies this pass's layouts.

Review source: `doc/research/possible-bodies/randomness-spatial.html`.
Local encyclopedia: `http://localhost:3003/research/possible-bodies/randomness-spatial.html`.

Headset reach, comfort, traversal and performance are not yet verified. The desktop probe measures reach from a fixed mark; it cannot establish comfort for every body. Baseline environment warnings about the certificate store, an unrelated UID and shader-cache access remain in the logs. The whole-spine builder also retains pre-existing layer-size warnings in Tutorial_Disco and Noise_Inside_Noise; these are outside this revision.
