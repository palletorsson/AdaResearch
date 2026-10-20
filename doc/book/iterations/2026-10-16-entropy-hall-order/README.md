# Entropy Workshop: a route for every artifact

Requested 16 October 2026: order the whole hall for all artifacts. Ten map artifacts and the separate architectural weathering wall are retained. Experimental parameters, seeds, gallery records, butterfly count and apparatus implementations are unchanged by this layout pass.

## Layout

Both bays are now 25 m wide. The first bay ends at row 33 with a three-metre doorway at columns 11–13. Main order: Shannon ledger (8,5), four jars (5,8), live jar (12,8), four-cube sorting table (5,14), two-compartment apparatus (11,14), point enclosure (17,21), ruin (8,29), signal room (12,48). Optional: hybrids (19,10), hardware wear (3,19). West weathering wall starts at row 26 for six metres. The map, this map's generated museum-plan row and writing wall agree. Current final anchors now include the four jars separately before the hand jar. Tutorial, plan, inventory, summary, intent, technical overview and research brief reflect the route.

The old museum arrival at grid s=(8,0) intersected threshold collision. A museum-specific sp=(8,2) puts the portal frame at z1.35 and the landing at z2.5, before the ledger. The legacy grid s remains. The exit t=(12,64) keeps the grid's void contract; museum.floor_cells supplies its supported floor. Grid pathfinding now passes without the earlier exit-height warning. Production portal checks confirm entry and exit without fallback.

## Evidence

`museum-report.json`: 96 native checks pass. All ten artifacts plus weathering wall are found in the actual museum. Visible mesh envelopes (excluding text labels) fit their room and do not overlap. A 0.6 m diameter, 1.8 m tall capsule with floor-support rays checks every named approach. A 0.5 m path grid finds routes, then every segment including endpoint connections is checked at intervals no larger than 0.1 m. The ordered route crosses the doorway and reaches the exit. Wall/plinth negative controls fail clearance as intended. The optional ghost's existing path planner still reaches the ledger. Native captures were inspected.

Earlier debug runs found a probe coordinate error: segment-local space includes a four-metre vestibule; map coordinates require that offset. The final probe uses map_world for all support/collision positions and room cameras. An early arrival assertion also defaulted a missing invalid flag incorrectly; the final test requires a nonempty authored sp entry with invalid=false, plus the production support check. These were probe errors, not hidden layout exemptions.

The route tests apply to the settled starting state. Moved stones and human activity can change it. Headset comfort, Quest performance, human understanding and whether one encounter creates a need for the next remain untested. The 48-value seed bench remains the first research pilot. No commit or push requested.

## Repeat

Run `python tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag hall-order-walk --probe doc/book/iterations/2026-10-16-entropy-hall-order/walk_probe.gd`, then `python tools/map_pathfinder.py check Random_Entropy --verbose`, then this folder's `publish.py`. `arrange.py` is the layout migration; `update_texts.py` is the one-time editorial migration, with final copy edits applied afterward. Do not rerun the editorial migration on a later edition.
