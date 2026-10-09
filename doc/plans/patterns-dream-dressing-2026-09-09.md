# The pattern machine dresses the body and the room

> Current requirements and teaching order: [Patterns: the room wears what we make](patterns-room-body-shaders-2026-09-10.md). The source audit below remains useful; the newer plan requires hall controls, deliberate hand input, multiple carrier forms and a closing shader/fabric studio.

Extension to [Patterns and shaders](patterns-and-shaders-2026-09-09.md) · 9 September 2026 · proposed integration, not a runtime implementation

Implementation follow-up: a player wardrobe with four super-drag silhouettes and a camera mirror is now placed in Pattern_Foundry. See `commons/artifacts/super_drag_mirror/README.md`. The shared loom-to-body-to-wall recipe described below remains proposed work.

## Artistic proposition

**Let the same pattern become cloth, a sculpture's dress and an interior's surface.** A visitor edits the machine and sees those relations change. Automatic production gives the work a life before we arrive; taking control lets us discover which choices produced it.

Material belongs throughout the sequence. Gloss can invite a closer look; lace can alternately expose and obscure; an oversized buckle can become an architectural joint. These are authored invitations to desire, not predictions that everybody will desire the same thing. Drag can operate through a sculpture's changing presentation and through architecture performing as a dressed body. Fetish can draw attention to a seam, finish, fastening or fragment until it becomes the reason to approach the work.

Keep room for pleasure before explanation. The visitor should be able to linger, dress, combine and admire without every response being marked as a correct answer. The code becomes available when curiosity asks how the effect happens. Neither a material label nor a random mutation establishes queerness by itself; the research lives in the relations and possibilities that people make with them.

## Existing implementation we can reuse

| Source | Present capability | Integration needed |
|---|---|---|
| `commons/artifacts/dream_bodies/dream_skin.gd` | Shared StandardMaterial3D finishes including latex, patent, oil-slick, holographic, candy, chrome, pearl, neon, wet and matte looks | Preserve family-specific uses; expose selected material regions and controls |
| `commons/artifacts/dream_bodies/dream_shaders.gd` and `dream_gloss.gdshader` | Six shader surfaces; bare/strap/lace/buckle/cage/zip overlays; seeded outfit selection | Accept the shared motif and independent dressing seed; controlled updates without rebuilding the sculpture |
| `commons/artifacts/dream_bodies/bodies/fetish_idol.gd` | A generated continuous body with independent `surface` and `harness` axes | Good first shader specimen; its generated wrapper currently rebuilds on configuration changes |
| `commons/artifacts/dream_bodies/figures/crystal_suit.gd` | Seeded `crust` and `panels` geometry axes | Preserve this structural DNA while adding optional dressing through the builder/generator, not hand edits to generated wrappers |
| `commons/artifacts/pattern_machine_a/pattern_machine_a.gd` | Editable punch-card motif, symmetry and scrolling cloth | Export the edited card as the shared recipe; pin start-up randomness for teaching |
| `commons/artifacts/pattern_machine_c/pattern_machine_c.gd` | Editable motif, private seeded start-up option, and `bolt/unit/operation/catalogue` displays | Useful later mechanism/reveal comparison; connect to the same recipe adapter |
| `commons/artifacts/wall_pattern_colorizer/wall_pattern_colorizer.gd` | Patterned colours on GridSystem wall cubes, optional group cycling | It searches for `GridMultiMesh`; it is not a general endless-museum wall-material adapter |
| `commons/scenes/endless_museum.gd`, `tools/validate_museum_dna_wall_plan.py` | Measured and reserved DNA wall runs, placement checks and deferred construction | Reuse placement constraints; add explicit material targets for selected interior surfaces |

The dream shader's straps and buckles are fragment shading, not attached straps, working fasteners or collision. Its oil-slick and holographic looks are stylized procedural approximations. Its procedural reflected environment may differ from the actual room. Those differences can carry excellent experiments when described accurately.

## One recipe, several interpreters

Keep each artifact family's own builder. Add a small shared recipe that adapters interpret for cloth, sculpture and wall. Do not flatten every family into the same geometry generator.

| Recipe part | Responsibility |
|---|---|
| Structure | Family, its declared geometry axes, dimensions and `form_seed` |
| Pattern | Edited motif cells, palette, symmetry, phase and `pattern_seed` |
| Dressing | Finish, overlay, region mask and `dress_seed` |
| Mapping | Body-relative, per-panel, wall-continuous or world-fixed coordinates; physical pattern scale |
| Performance | Held, automatic score or bounded variation; current step and local phase |
| Evidence | Recipe version, builder/shader versions, parent recipe, explicit changed values and target placement IDs |

Save resolved choices as well as seeds. A seed alone cannot preserve an output after a generator changes. Separate random streams prevent changing a dress from silently regenerating the body. This separation is proposed work: the current idol builder uses one seeded stream for several decisions.

Body mapping needs a shared root coordinate frame and measured bounds. Applying an object-space shader independently to every primitive can restart the pattern on every piece. A wall needs a planar frame and a corner policy; a body-height uniform is not an adequate wall adapter. Make continuity across a corner an explicit choice the visitor can inspect.

Target named regions: skin/panels/trim on a sculpture; a selected wall bay on the room. Preserve semantic details, existing light fixtures and control markings. Changing one outfit must not mutate a material resource used by another exhibit.

## Automatic and controlled

Offer three operating modes, visibly indicated by the machine:

- **Hold and edit:** the recipe stays fixed while the visitor changes one selected property. Compare with the saved baseline and undo.
- **Perform:** an authored sequence repeats—cloth feeds, one finish changes, then one mapping changes. Record the current step. A visitor taking the controls holds the local score immediately at that state; resumption is explicit.
- **Vary:** produce a small batch, initially four candidates, from chosen unlocked axes and declared ranges. The visitor chooses what to keep. Show what changed and retain the parent recipe.

Automation should execute an inspectable score rather than reshuffle everything at load. For example: hold form, motif and light; compare latex, patent and chrome; then hold the chosen finish and compare a body-following pattern with a world-fixed field. These are separate questions.

Categorical geometry states such as `spire` and `bloom` are discrete builds, not automatically continuous morphs. Rebuild or swap prebuilt geometry at a deliberate step; update material uniforms directly for inexpensive dressing changes. Bound geometry, texture size and transparent area; measure the selected room on the target renderer/device. Do not regenerate a marched sculpture every frame to change its finish.

The held state belongs to this experiment. The museum clock and XR tracking continue. View-dependent sheen can still change as the visitor moves while the recipe is held: **the observer is one of the inputs**. A reference camera and fixed lighting are needed when making comparable captures.

For automatic room preparation, use declared slots: one machine bay, one sculpture position and one reserved wall surface. Generate candidates within their measured bounds and preserve entrances, routes and interaction reach. Save the accepted result into the normal placement plan. Live visitor dressing affects its named installation, not every room that shares the artifact family. A saved variant can be promoted later through the existing book/primary/placement checks.

## A first installation: the dressing loom

Two primary artifacts: **`pattern_machine_a` and one `fetish_idol` specimen**. A reserved wall bay acts as the machine's third output, part of this installation. A crystal-suit or abstract family can become the next target once the adapter works.

1. A small motif is already coming off the loom. Its pattern appears on the body and the wall at a comparable physical scale. This connection needs implementation; it is not present merely because the objects share wallpaper utilities.
2. Touching a motif cell takes over the local score. The cloth, body and wall update from the same saved edit.
3. Hold the body and motif; change the finish. Walk around it. What seemed like a property of the object now varies with the position from which we look.
4. Change only mapping. Move the sculpture: does its dress travel with it or does it move through a field? Then follow that field onto the wall.
5. Choose a material relation and save it. The machine presents the edited recipe and the small piece of code responsible for the selected operation.

Initial mapping/material combinations should be curated. In early rooms, a strap or lace field can be recognized as repetition without requiring the reader to understand the full gloss shader. The later material room returns to the same familiar dress and opens its implementation.

## Three further visual arguments

| Experiment | Controlled change | What it opens |
|---|---|---|
| **The wall wears the sculpture's dress** | Hold motif and finish; change carrier and scale | A wall can read as enclosure, fabric or costume. An enlarged seam becomes a border one follows through a room |
| **A buckle too large to remain a detail** | Compare a shaded buckle with a built, enlarged fastener | Fetish attention becomes spatial: a detail becomes an object, then possibly a doorway. A functioning opening requires actual geometry and collision work |
| **Chrome remembers another room** | Compare the procedural environment with a deliberately implemented room-reflection alternative | The surface's reflected world may be authored elsewhere. Desire attaches to an appearance whose source is displaced |

Lace can become a printed pattern, transparent fragments or built perforations. Stage these as different constructions. Do not promise that alpha changes privacy, visibility and bodily passage in the same way. Investigate each with the implemented view and collision conditions.

## Build order and review

1. Capture a fixed idol, one loom motif and the intended museum wall bay; document present controls and coordinate frames.
2. Implement recipe export/import with separate seeds and resolved values; test exact restoration within the same implementation version.
3. Add material-region and coordinate adapters to those three targets. Verify that a finish change preserves the mesh, collision, motif and other exhibits.
4. Add Hold/Perform/Vary to the existing control infrastructure, with takeover, undo, local-phase persistence and explicit resume.
5. Build one authored score; test the same motif edit across cloth, body and wall, including movement, corners and actual museum lighting.
6. Save one complete installation and write its primary-linked book passage from observations. Then extend to `crystal_suit` and an abstract sculpture family.

A successful first version lets someone understand what the machine changed and also make a combination we did not anticipate. Record their selection and explanation without turning desire into an optimization score. Keep candidates outside the initial taste palette possible through intentional editing; make the generator's chosen limits visible.

No runtime code, live placements or material assignments are changed by this proposal.
