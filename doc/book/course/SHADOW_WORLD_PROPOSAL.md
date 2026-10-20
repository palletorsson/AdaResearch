# Shadow world: objects that carry the learning

17 October 2026. Design proposal following the tutorial output gallery. No tutorial subjects, museum logic or runtime persistence changed by this proposal.

Implementation follow-up: [Shadow Game — Make a crossing](../iterations/2026-10-17-shadow-game/REPORT.md) is now the first playable episode. It reuses the sphere, block and line builders with a physical crossing and its own persistent trace. The broader route below remains a proposal.

Second playable application: [Museum Runner](../iterations/2026-10-17-museum-runner/REPORT.md) turns the sphere into a runner through seeded arrangements of blocks, beams, faces and the actual museum columns. It preserves high score and repeats a course on retry. It is a separate game mode, not a replacement for the continuing construction world or the walking museum spine.

## Author direction

Return to sphere/ball, cube and stick across halls. Give them new interactions and uses in space. Build toward one continuing student scene, related to the existing biome and produced through learning in the Endless Museum. Keep a small vocabulary whose possibilities expand.

## Working idea

The museum offers encounters. The tutorials let the student understand and reconstruct selected operations. The shadow world is where those operations meet: a continuing place that the student can rearrange and inhabit. Each return should make an earlier choice matter in a new way.

Start with a modest piece of ground adjoining the museum. A point can be placed there. Two points support a line; moving a point changes the relation. A recorded gesture stays after the hand leaves. Faces and bodies introduce surfaces, edges and passages. Transformation changes an existing arrangement. Later rules distribute, colour, deform and animate it. The place can eventually acquire the density and relations of a biome.

This need not be a new exhibit for every hall. Several lessons can deepen one object, and a reflective hall can revisit what is already there.

## Recurring vocabulary

| Family | First useful role | Possible returns | Required distinction |
| --- | --- | --- | --- |
| Sphere / point | Visible position, then held body | Endpoint; recording instrument; catalyst; colour or field control; later agent | A marker, a physics body and an agent can share geometry without sharing their update rule. |
| Cube / block | Constructed solid | Pickup; support; step; repeated unit; door panel; moving platform | A rendered box is not yet a physical or grabbable object. Add those abilities explicitly. |
| Stick / line | Relation between two positions | Trace segment; frame; handle; lever; bridge; branch | An endpoint-driven line and a rigid stick have different constraints. Name the transition. |
| Surface / field | A bounded face or ground | Wall; painting receiver; tile array; height field; cellular or reaction-diffusion surface | Mesh, address system and stored state are different things. |
| Record | Ordered positions from a gesture | Snapped copy; construction points; route; placement source | Preserve the source record; identify derived versions and their coordinate frame. |

The domains are handheld interaction, spatial construction, time and motion, material/appearance, and collective systems. An object may cross domains, but each crossing must introduce a precise new operation and visible consequence.

## First route through the shared scene

1. **Primitives:** place, hold, connect and record; use learned faces and solids to compose a small arrangement. Keep the student's trace. Exact construction remains the teaching focus; physical architecture requires an explicit collision addition.
2. **Transformation:** return to that arrangement. Move a block across a gap, turn a panel around a hinge, vary an opening. Distinguish the tutorial's visual motion from the extra work needed to carry or block a player.
3. **Arrays:** repeat a chosen part to make a walkway, fence or field. Retain a source definition; decide whether copies share changes or become independent.
4. **Colour:** make the same materials or receivers respond to a held object. Colour may reveal state or change atmosphere; neither requires collecting a new unrelated prop.
5. **Later sequences:** vary placement under randomness; change ground or motion with noise; retain surface state in cellular automata or reaction diffusion; branch from a rule; let several bodies respond locally. These are candidate applications, not replacements for the agreed hall lessons.

The environment can stay familiar while its relations become richer. A panel that once divided a room can later provide an obstacle or a planting exclusion. Do not call geometric clearance simulated ecology.

## Evidence already in the project

- `commons/biome_layers/biome_grammar.gd` reads the actual spine and authored hall order and accumulates `made_of`, `does`, `knows` vocabulary. Declared vocabulary is not proof that a student implemented each ability.
- `commons/artifacts/biome_primitives/biome_primitives.gd` already offers a full-size staged point/line/trace/grid/form study, driven by visitor movement. Its movement input differs from the student's held point.
- `commons/artifacts/biome_inheritance/biome_inheritance.gd` preserves panel bodies while changing hall state and rebuilding habitat. Its clearance study records excluded/accepted cover candidates. The registry still identifies it as a prototype; it is not an integrated student-world solution.
- `doc/book/iterations/2026-10-12-biome-is-the-arena/HANDOVER.md` documents the catalyst encounter inside the existing biome, including prior test evidence and limitations. No new runtime or headset verification was performed for this proposal.
- The gallery's `PointBody` is already pickable. The carried Transformation `BoxBody` is only a `MeshInstance3D`. Sharing appearance or source is not yet persistent identity, pickup or collision.

## Small first implementation candidate

One museum-connected study scene, using the supplied environment and player. Begin with the carried sphere, a block and a line/stick, plus the existing trace record. Stage a short construction and return to it through Translation, Rotation and Scale. Retain each earlier snapshot so the change can be compared and undone.

Use shared form builders and small explicit behaviours; avoid a universal object with every future ability. Only one subsystem should own a body's movement at a time. Infrastructure such as storage, the player and scene hosting can be supplied and named rather than retaught in every lesson.

Before expanding the world, test: reconstruction from the previous snapshot plus printed edits; earlier abilities still work; a new operation changes the intended object; source traces survive derivation; save/reload preserves declared identities and values; a student-chosen parameter changes the predicted consequence. Physical passage and pickup need physics/input tests as well as images. Synthetic tests do not establish human learning or headset comfort.

## Compact instruction for future work

Museum remains host. One continuing student place. Reuse sphere/block/stick/surface/record. Per hall: inherit → one new operation → visible consequence → retained output. Declare whether continuity is source, data, recipe or live object. Print changes; link full snapshot. Test reconstruction + preservation + chosen variation. Supplied infrastructure stays named. No universal class; no automatic biome growth claims; no curriculum rewrite until reviewed.
