# Randomness: rooms with a centre

16 September 2026. Implemented Palle's request to fit the seven active Randomness halls to their artifacts, consolidate repeated exhibits, and stage a central hero with relevant supports facing −Z.

Review: http://localhost:3003/research/possible-bodies/randomness-staging.html

The active order remains Definition → Entropy → Remove → Walk → Gaussian → Mushrooms → Game. The larger fourteen-map catalog remains available; this pass does not remove its extension maps.

## The floor and its encounters

| Hall | Source footprint before → after | Placements before → after | Central hero |
|---|---|---|---|
| Random_Definition | 13×22 → 11×13 m | 15 → 6 | `seed_replay_demo` |
| Random_Entropy | 18×12 → 13×13 m | 9 → 5 | `shannon_entropy_meter` |
| Random_Remove | 13×18 → 9×10 m | 3 → 1 | `remove_random` |
| Random_Walk | 13×14 → 11×13 m | 12 → 5 | `random_walk_terrarium` |
| Random_Gaussian | 14×22 → 11×13 m | 9 → 4 | `distribution_sampler` |
| Random_Mushrooms | 13×13 → 13×14 m | 6 → 2 | `mushrooms` |
| Random_Game | 15×18 → 15×20 m | 9 → 2 | `r_c` |

Total source-grid area changes from 1,665 to 1,170 m², about 30% less, excluding museum vestibules. The 63 placements become 25 distinct artifact lookups. Remove's bench already contains its supporting operations. Game keeps two primary book encounters: the crossing is the spatial hero; the emitter occupies a separate eight-metre field behind it.

## Curatorial decisions

- Definition holds the replay table, crank, slot machine, TRNG/PRNG comparison, historical number page and one catalyst. Entropy owns the jar/cloud/butterfly group, together with the central ledger and a compact hardware decay study.
- Remove keeps its complete experiment. The generic hazard and repeated dark sphere were not doing explanatory work here.
- Walk retains five different studies: terrarium, sheets, leash, low floor trace and one pixel cloud. The three identical cloud placements become one. The Monte Carlo pavilion and repeated progression devices leave this route.
- Gaussian retains its cabinet, comparator, Galton board and paint application. Blurring and sampling are different operations; the blur works remain available for a later lesson.
- Mushrooms keeps the six-metre bed, specimen controls and edible objects inside the artifact, plus one small bubble dish. Its footprint grows slightly to protect the margins.
- Game separates unpredictable waits from unpredictable launches. The unrelated creatures and incomplete Monte Carlo display are archived from this room. The pit retains its own floor opening, bed and recovery ramp; the side route remains supported.

The 38 retired placements, including the two extra cloud copies, are recorded individually in manifest.json. Original map files, role buckets, plan rows, changed prose and captions are under before/. No artifact scenes were deleted.

## Orientation and fitting

Most native displays face +Z and receive 180° yaw. The historical number page, crossing and emitter already present toward −Z and keep their native orientation. The round catalyst is turned so its label is readable from the same approach. A floor trace or free-flying butterfly has no single reading face.

Runtime inspection exposed old submerged apparatus, an over-height pixel cloud and a painting at the exit. The crank, TRNG comparison, Galton board and comparator now stand at usable heights. The six paper sheets use their existing bare-rack option and a 0.75 m plinth. The page is scaled to a 1.6×2.4 m panel. The hardware study is reduced to 60%; the pixel cloud is 18% of native scale. The painting now occupies a side bay. Final runs required no automatic artifact movement or route repair.

`museum.props_deny: [dream_bodies]` reserves these rooms for the authored inventory. A four-line guard makes the automatic sculpture pass honour that existing per-map exclusion, just as the other furniture passes do. Other halls retain their existing dressing. Museum wall texts, benches and infrastructure remain.

## Registers and evidence

- Source maps, primary/secondary roles, per-room inventories, current intent records and sequence artifact groups are synchronized.
- Only obsolete spatial directions in final.md were revised (Entropy, Gaussian and Game). Definition's tutorial now points to its central table. The prose's discoveries and code remain.
- Both museum plans were updated only for these seven rows. The book captions, generated artifact order, effective order and long-museum strip were refreshed. Changes to downstream strip coordinates follow the shorter Randomness chapter; other source halls were not edited.
- All seven actual endless-museum segments loaded, with all 25 intended scenes present. There were no runtime script errors or automatic walk repairs in the final captures. Doorway and side-bypass support was sampled at four points per room, 28 checks in total.
- verification.json records 115 passing focused checks covering dimensions, plan parity, primary/book agreement, instance presence, visual footprints and live book/inventory responses.
- The full strip consistency check passes against 112 engine-measured halls. It still reports pre-existing layer-size warnings in Tutorial_Disco and Noise_Inside_Noise; this task did not repair those unrelated maps.
- Screenshots are actual desktop Godot renders. No headset reach, comfort or Quest frame-rate claim is made. Floor samples and route bookkeeping do not replace a person walking each encounter.
- The review page and fourteen images are published to the local encyclopedia. Publication checks record HTTP results and JavaScript syntax. Automated browser interaction was unavailable because the browser tool could not create its kernel assets.

## Repeatable workflow

`stage.py` applies the scoped map/role/plan changes and keeps the first pre-edit snapshots. `sync_text.py` aligns inventories and spatial references. `run_probe.py` loads each actual museum segment in an isolated control configuration; `verify.py` checks its output and the live book. `build_review.py` produces the local review; `publish_review.py` copies that completed result to the local encyclopedia. Generated whole-spine indexes use the existing project builders.

Next embodied check: approach each hero from −Z, reach all controls, circle the supporting exhibits, then traverse Game's crossing and bypass. Only after that should finer room compression or further supports be considered.
