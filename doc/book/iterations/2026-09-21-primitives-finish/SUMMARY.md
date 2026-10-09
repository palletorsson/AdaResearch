# Primitives — enough to continue

21 September 2026. Applied focused finishing pass, authorised by the request to finish the remaining mature sequence and move to the next. [Read the comparisons and actual Grid image](index.html).

## Decisions and changes

- **Point Line Grid:** the placed vitrine now opts into `#pen_pair:space_grid`. Cyan keeps sampled spatial positions; amber rounds horizontal positions to local one-metre floor addresses and retains hand height. The frame follows the exhibit when translated or rotated. The book now invites this comparison. The legacy time-domain pair remains the default for other placements and is available for a later hall.
- **Triangle:** the boundary/fill discovery, first-corner fan, unchanged boundary and overspill remain. The L experiment arrives sooner. Exact six-corner coordinates, readiness instructions and the manual two-fill alternative are preserved in the technical companion, linked from the chapter. Existing footnotes remain; one construction note is added. The chapter changes from 1,214 to 994 whitespace-counted words including code and footnotes.
- **Polyhedra:** the closing asks about changing the barrier or slope and whose movement would change. A catalogue of other works is removed from prose only.
- **Animated Cube:** take the crease onward. Remove the repeated closing catalogue while keeping all three encounters.
- **Ignorance:** remove one deferral paragraph; keep the smoothness comparison, budget and five-sided capsule.
- **Portals and Melencolia:** final.md preserved in full. Their stopping question and unfinished looking are meaningful returns, not filler.
- **Transformation begins:** Trans_Pre now picks up Melencolia's question: what survives the movement? Its existing still collectible, three additive demonstrations and final four pickups remain. Everything after its primary marker is unchanged. The next hall is **Trans_Introduction**.

No artifacts were removed or promoted. Existing role files and all Primitives map geometry remain untouched by this pass; only Grid's one placement option changes. Core encounter lists for the six edited chapters now agree with their already authored primary order and current hashes. This corrects stale lists, including Grid's old simulation_grid entry and Ignorance's missing capsule; it does not curate new primaries.

## Evidence and limits

- `commons/testing/probe_plan_vitrine_grid.gd`: 20 controlled assertions pass, using the production scene, real occupancy polling and supplied controller positions. Covers rotated/translated frame alignment, within-address movement, boundary crossing, continuous height, negative addresses, no stationary time progression, exit/linger/reentry, reconfiguration and cleanup.
- Existing `probe_plan_vitrine_hands.gd`: 9 checks pass for the unchanged default pair, including competing vitrine claims and teardown.
- The rendered spatial probe passes its additional screenshot assertion. `grid-spatial-pair.png` is an actual Godot view of the production vitrine receiving the same supplied circular trajectory in both hands. It is an isolated artifact view, not a full museum or headset capture.
- Both runtime logs include the existing startup notice `Unrecognized UID: uid://rwex60pqapc`. No script or behavioral failure occurred. Headless runs also report the absent headset. These logs are retained, not described as clean headset runs.
- The museum's `_stamp_inner()` delivers placement configuration through `apply_grid_config` before the node enters the tree. This was inspected in source; the full museum was not restarted.
- The Triangle implementation is unchanged. Its existing controlled construction evidence is referenced by the technical companion; there is no new Triangle runtime or headset claim here.
- Sixty scoped preservation/content checks pass, including one explicitly recorded concurrent-change exception. Existing footnotes, authored roles, unaffected core records and the frozen Claude full-book files are checked. `git diff --check` passes for touched tracked files (line-ending advisories only).

**Concurrent change:** Point_One/map_data.json changed after this pass's baseline was recorded, outside these edits. It was left untouched. `concurrent-changes.json` records its initial and observed hashes; this report makes no preservation claim for that map. Point One's final.md is preserved.

Headset ease, reach and visitor understanding remain to be tried. No live game restart, live bake replacement, visitor-save change or commit. Collective Knowledge remains parked. The existing full-book review snapshot was not rebuilt; the current chapters and exact diffs are linked on the review page.

## Next

Continue Transformation from Trans_Introduction: read the actual crossing encounter and current chapter together, preserving its mature work. The guiding question is what changes for a body when an object changes position, orientation or size. Do not restart an exhaustive seven-hall source audit without a concrete mismatch.
