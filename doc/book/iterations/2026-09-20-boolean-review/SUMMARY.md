# Boolean Surfaces: connected for which body?

20 September 2026. [Text and museum comparison](http://localhost:3003/book-review#boolean_surfaces).

The three-hall order remains useful: learn the operations, inspect variants and their declarations, then test what the large forms let a body do. This pass concentrates on an overlooked existing artifact and on claims whose imprecision weakened that progression. It does not rebuild the whole sequence or apply every review suggestion.

## Findings and decisions

**Recover an encounter before inventing another.** The outside review proposed a walkable companion to the visual architectural wall. The live map already contained `boolean_burrow`, classified secondary and absent from the manuscript. Its CSG stock enabled collision. That made it a better first candidate than another new room.

**Collision was necessary but insufficient.** In the actual museum, the burrow reported eleven spherical cutters, one overlap component and eight graph cycles. The controlled body reached the first two centres but stalled on the way to the third, where the spherical hollows form a raised floor. A graph connection did not establish body clearance. The original file's suggestion that graph cycles necessarily imply islands of rock was also incorrect; the source now distinguishes these claims.

**Make the existing difference inhabitable.** A new optional `carver_profile:level` uses upright cylinders at the same seeded centres, with the same radius. Their bottoms reach just below the museum floor and their tops sit about 2.3 m above it. The Works placement uses this profile, keeps the roof and disables the photographic section cut. Three small lights make the inside visible; the entrance invitation sits above the opening. The original sphere profile remains the default elsewhere. In cast mode the invisible stock no longer retains collision.

**Give the objects room to disagree.** Works is lengthened from 36 to 44 cells. The visual wall, burrow and raised SDF model no longer overlap. All nine artifact families remain; a side aisle permits continuing without entering the burrow. Explicit museum placement and an open roof replace the old automatic dressing. The grid exit now names Swarm Intelligence instead of returning to Gallery; this destination is source/configuration checked, not a tested grid-mode transition.

**Promote what carries the new argument.** Burrow joins the compose workbench and SDF model as a primary encounter, in physical reading order, across roles, core and book index. Other roles remain. The chapter now asks the visitor to try the wall, enter the hollow and return before explaining the cutters and collision. The ending retains the critique of an outside photograph as an instrument but no longer makes the current lack of affordances into an intrinsic limit of Boolean construction.

**Correct representation claims in Verbs.** Union can retain disconnected components. Continuous boundary motion can accompany discrete changes in connectedness. A shared radius parameter can feed different representations; the sphere is not literally without a radius. Root material assignment is a choice, not a law forcing every cavity to inherit one skin. Difference can also return an empty set. The existing intersection volume display is now enabled and faced toward the approach, and its panel is enlarged to fit all three lines.

**Keep Gallery's comparisons.** Its map, all 24 placements and roles are unchanged. Targeted passages distinguish a default-first catalogue order from a monotonic teaching order, and a defined wildcard fallback from an undefined state. The visitor is invited to follow `distinct → necked → lobed → single` themselves. No production registry was reordered merely to erase the disagreement. Its simulated z-fight is identified as a diagram, while the possible coincident geometry remains a separate question.

## Text and evidence

- [Complete three-chapter diff](final.diff). Verbs: 1,571 → 1,281 words; Gallery: 1,890 → 1,943; Works: 2,440 → 2,474. Most of Works' artifact comparisons remain; its opening, burrow encounter and conclusion now admit a constructive answer.
- [Original burrow test](baseline-runtime.json): the actual 1.5 m high, 0.32 m radius museum collision capsule stalled at the third hollow. This diagnostic report records the blocked walk rather than treating it as a passing route.
- [Revised test](after-runtime.json): six successive inward waypoints and six return waypoints pass; intact rock blocks the same body. Separate tests pass along the gallery aisle and through the original visual wall. Eleven cutter centres and both graph counts are unchanged.
- [Verbs runtime](verbs-runtime.json): the configured intersection specimen and three-value readout instantiate in the actual hall. Capture inspection caught the original undersized panel; the current panel fits the text.
- [Integration checks](content-checks.json), [re-run](verify_content.py): route, retained artifacts, Gallery preservation, scoped plan changes, primary alignment and recorded runtime outcomes.
- [Before](before-overview.png) and [after](after-overview.png) use the same overview camera. [Entrance](after-burrow.png) and [inside](after-inside.png) are additional current views. These are Godot captures, not illustrations. The latest Works captures use Vulkan/mobile; the Verbs capture uses compatibility rendering.

The runtime harness pauses museum input/catch logic and drives the existing desktop CharacterBody. This proves a bounded collision route for that body and seed, not headset comfort, Quest performance, arbitrary body sizes, every branch, every seed or every roof setting. No full museum bake was regenerated. Source and current-input hashes are saved; the final grid-exit destination and source-comment edits occurred after the Works body test and do not change the tested geometry.

## Named next work

- Test the burrow in the headset, including approach, turning, height and retreat. The far slit is not claimed as an exit; the text asks the visitor to return through the entrance.
- Expose the workbench's existing `algebra` settings and implement its promised selection affordance. This pass does not pretend the turning presets became pickable.
- Review Gallery's remaining forensic detail against a beginner reading. Its map is preserved; counts and source-line citations should eventually give way where direct observation can carry the point.
- A general `carver_profile` control would need an occupancy rule before rebuilding collision around a visitor. The current profile is map configuration, not a live button.
- The shared builders still report unrelated pre-existing layer-size mismatches in Waves, Randomness and Noise. Those are not new failures in this pass.

Next sequence: **Swarm Intelligence** — from a body fitting a composed space to many bodies producing a space through their relations.
