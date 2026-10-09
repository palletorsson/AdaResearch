# A volume can become a room — 14 September 2026

User approved a genuine 3D form laboratory with multiple seeds and solid/frame/shell mappings, following six architectural references and Zhang et al. (2021): https://ar5iv.labs.arxiv.org/html/2103.04130 . This implementation uses authored rules, not a trained GCA model.

Scene: res://commons/artifacts/ca_volume_lab/workshop.tscn. Reusable registered artifact: ca_volume_lab. No main sequence, map, hand, primary or book changes. The previous 2D-history vault remains intact.

State: 13³ binary sites, synchronous updates, 26-neighbour Moore neighbourhood, empty exterior, no protected alive cells. Every spatial cell is 2 m. Time is separate and capped at 16 updates in the interactive Godot workshop. All births read only the previous volume. Three explicit seeds: ground-based 3³ cluster (27); hash-scattered 38%-threshold cells in a 9³ region (258 actual); two separated 3³ clusters (54). Ground is an authored gallery floor, not a CA survival override.

Growth rule: B4/S4..26. Turnover rule: B5/S4..7. The latter changes both birth and survival conditions; it is not a single-parameter causal isolation. Under growth, G6 counts are 132,764,249. Turnover extinguishes the compact and paired seeds by G2 but preserves evolving activity in the scattered seed. Optional sine adds floor(2sin(2πy/13 + gπ/4)+.5) to the birth count. Optional bend shifts x by 1.5sin(2πz/26) and does not edit the state.

Mappings: solid exposes the occupied/empty boundary of filled cells. Frame retains unique boundary edges as 8 cm square bars; the cell interiors cease to be material. Shell adds 18 cm-outward folded panels and deliberately omits side panels where (x+y+z)%3==0; horizontal panels remain. These openings are mapping policy, not emergent vacancies. All physics triangles come from the same displayed geometry. CUT removes negative-X geometry and retains the cellular state. Empty state removes both mesh and collision.

Physical comparison at G0 uses the same 27 occupied cells, same route x=2 m, and the actual 1.8 m-tall/0.6 m-wide desktop capsule. Solid stops near z=9.70; frame crosses to z=17.50; shell enters and stops near z=15.75. A further ground walk reaches beneath the grown G6 shell, confirmed by collision overhead. This is not a comprehensive navigation proof for all seeds/generations/mappings. Face-connected component counts are separate from the 26-neighbour influence graph and from body clearance.

The clear gallery lighting disables the carried light's distance fog only on the workshop's player instance. Main player behaviour remains unchanged. Changes are refused while any recognized visitor is inside the marked domain. This addresses geometry replacement, not headset comfort. Headset testing remains deferred. The largest captured mesh is roughly 71k triangles; desktop rebuilds are measured in the report and do not establish Quest performance.

Read-only remote diagrams expose actual arrays through G6 and distinguish the time slider from the spatial Z slice. Diagrams simplify physical beams/facets; the separate labelled photographs show the real G6 growth specimens. Reproduce using python -X utf8 ada_run/review_ca_volume.py, then python -X utf8 tools/build_ca_volume_review.py. The isolated runner preserves the editor and owns only its hidden muted process. The existing missing-UID startup diagnostic is unrelated; no runtime script errors occurred in the accepted run.

Next experiments: compare isolated survival changes; vary cell scale to test which bodies pass; select and test connected interior routes in the evolved forms; preserve extinction as a result; compare explicit rules to a learned transition model only after choosing and documenting a training corpus. A body-dependent route measure is different from a claim of thermodynamic entropy or unlimited morphogenesis.


Runtime checks: 95. See receipt.json, report.json, states.json and publication/browser verification.

Final publication: http://localhost:3003/research/possible-bodies/ca-volume-lab.html . Accepted runtime PID 41204 exited normally, with all 95 checks passing and captured sources plus guarded museum files unchanged. The separate content verifier passed 53 checks, including all 22 served assets matching their repository hashes. Thirteen browser checks passed: seed/view selection, turnover and extinction, independent time and spatial-depth controls, view angle, loaded images and viewport fit. Evidence is in content-http-verification.json and browser-verification.json. The handoff prior to this update is preserved in before/HANDOFF.md.
