# Random Remove review — 12 September 2026

Continued from Random Entropy. **Next: Random_Walk.** The thread moves from what a measurement retains to the set a draw can choose from, then to the places a walker can reach. Headset work remains deferred while Palle is remote.

## Delivered

- Review: http://localhost:3003/research/possible-bodies/random-remove.html
- Primary/book: http://localhost:3003/necklace/thread?map=Random_Remove&role=primary
- Builder: `tools/build_remove_review.py`
- Text helper: `ada_run/write_remove_text.py`
- Alignment: `ada_run/align_remove.py`
- Independent runner: `ada_run/review_remove.py`
- Verification/publication preparation: `ada_run/verify_remove_review.py`

The existing bench and Claude's side-station visual pass are preserved. Both `algorithms/randomness/RemoveRandom.gd` and `remove_random_fixture.gd` match the before snapshot byte for byte. All map layers, utilities, lighting, settings and museum clearances are unchanged. The remover stays at (6,7), facing east, with controls to the right and a cased account to the left. Map metadata now describes this encounter and correctly states the existing 13×18 layers and height-3 structure; it previously said 12×24 and maximum height 2.

Three placements remain declared. `remove_random` and `dark_sphere` instantiate; secondary `hazards_demo` has no living scene. The current pack ledger is 3 planned/matched, 2 placed, 1 refused, no extras. This is not a claim that all three build. The dark sphere's body remains beside the bench, limiting one adjacent lane; the tested routes on either side remain open.

## Book and metadata

Final and supporting texts now follow an excluded cube, separate filtering from the draw and zero-scaling, compare equal-sized ROW/COLUMN masks and inspect the means of restoration. NEW SEED can repeat; retaining a seed while changing candidate count also changes draw bounds. Waiting between completed removals does not advance the removal generator; presses during a highlight are ignored, and reset/mode changes cancel delayed removals from the old generation. An unfinished pattern can preserve differences that a fully emptied range loses from its visible shape.

The final has 1,034 whitespace-delimited words; the primary card exposes 866 words inside the `remove_random` anchor. Its opening description of the side stations belongs to the room introduction outside that anchor. Primary, final anchor and hero agree. Eleven production excerpts match the source.

Old book and registry notes still described searching the host museum grid and an inability to restore cells. Those prose fields now describe the explicit descendant grid, private resource copy, optional local bench and reset. Registry changes are limited to this artifact's description, QFEP connection and two DNA notes. Scene, runtime parameters, axes, spatial metadata, historical measurements and every other registry entry are unchanged. Legacy capture harness inputs and zero bounds remain documented as a separate review need.

The critical text no longer asserts that a full board is “maximum order,” that gaps are inherently more legible, or that removal is automatically an entropy increase. It distinguishes protection from deletion here from exclusion from an opportunity elsewhere. The result depends on what being chosen does. Return depends on retained instance addresses, original transforms, a seed and the rest of the procedure.

## Independent run

**21:38:35–21:40:23 +02:00, PID 36196: 87 checks, zero assertion failures, exit 0.** Another Godot review was allowed to finish before this run began. This review used an isolated hand-file copy and preserved the original. Production and probe sources remained unchanged throughout the run; afterward only map metadata changed among fingerprinted runtime inputs. The probe's inherited wording about a real hand is superseded by the receipt: no tracked-hand test occurred.

The prior 79 checks are retained, with two probabilistic assertions corrected: NEW SEED must choose a five-digit value and produce a valid permutation, not guarantee a different seed or order. Eight additional checks cover complete column/all histories, equal ROW/COLUMN offsets, different address lists, pending reset, pending mode change and rapid presses. Existing checks include seven button signal paths, desktop pointer REMOVE ONE/RESET, masks, removal without replacement, exhaustion, replay, access and streaming.

Six full histories are exported, totalling 128 removal entries:

| History | Seed | Removed cells |
|---|---:|---:|
| Range | 29640 | 16 |
| Range replay | 29640 | 16 |
| Range, new selection | 37468 | 16 |
| Row | 777 | 8 |
| Column | 777 | 8 |
| All | 777 | 64 |

Every history is a permutation of its initial set. The replay is identical. At seed 777, ROW removes indices 31,24,29,27,26,28,25,30; COLUMN removes 59,3,43,27,19,35,11,51. The offsets in the shrinking lists agree: 7,0,4,2,1,1,0,0. The fourth selection meets at the shared address (3,3), index 27. Same count does not make the two sets identical; different sets need not be disjoint.

One-removed and exhausted RANGE captures share a camera pose and seed 29640. The separate desktop-pointer front capture uses seed 777 after one removal; do not describe it as that same run. The probe's late primary capture overwrites its initial primary image after reset; the explicit one/empty pair is the evidence for the range comparison. A dedicated close status image shows the cased account.

The surrounding count of meshes/MultiMeshes/bodies remains 1,056. Ownership is also supported by the explicit descendant binding and private resource copy in source. Counting unchanged objects alone would not prove their transforms remained unchanged. The streaming checks free and rebuild the bench bound to 64 cubes with sixteen eligible.

## Limits retained

The front view keeps the board and both side stations visible. From the dedicated oblique close camera, the tray overlaps part of RANGE. It remains a viewpoint/reach issue for a tracked-hand visit; no new spatial fix was inferred from that one close angle. The named controls, masks and desktop pointer paths tested here are distinct from headset readiness.

No script errors or ObjectDB shutdown leak warning occur in this run. The audio-bus UID, root-certificate and logger errors remain, together with environment/renderer/registry warnings. Generated decorations took 127, 130 and 298 ms to build. The exact diagnostics are in `verification.json`; exit 0 does not settle them or establish Quest performance.

## Publication and continuity

All 55 published files match their local hashes over HTTP. The browser review at 1280 px confirms four loaded images, no horizontal overflow, two 64-cell boards, ROW/COLUMN counts and offsets, exhausted buttons, disclosed order labels, different intermediate range gaps, equal final range gaps, exact replay and reset. The book disclosure opens, and the hydrated primary page shows one written `remove_random` card with the restoration and repeatable-seed passages.

The browser uses captured histories, not a replacement random generator. Its flat arrangement and optional order numbers are named as review features. The in-game plate retains only the last removal. Entropy's onward links now open this review. The WCN audit reports 35 maps, 19 active, all with final text, zero primary/book mismatches. Existing Tutorial_Disco and other global index warnings remain in the saved logs. Scoped `git diff --check` passed. No commit was made.

Original files are in `before/`. Runtime outputs are under `ada_run/remove-review-2026-09-12/`. See `verification.json`, `browser-verification.json`, `http-verification.json`, the publication manifests and hashes. Leave this review available while proceeding to Random_Walk.
