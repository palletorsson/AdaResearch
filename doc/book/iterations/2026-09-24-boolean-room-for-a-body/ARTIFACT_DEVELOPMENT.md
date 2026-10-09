# Development continuation: Boolean bodies and spaces

24 September 2026. Author's steering after the three-chapter reading pass: bring the existing Boolean space-making work and Radiolaria into consideration. This is an artifact-development brief, not an assertion that either new encounter has been installed or walked.

## What changes in our direction

Keep working on Boolean before moving to Graph Theory. The sequence needs the pleasure of making forms and places as well as its existing critique of promises, defaults and representation. Reuse the existing artifact ecology. Do not treat the current reduced placement as the limit of the chapter.

The proposed progression is **combine regions → compare constructions → make a body → make somewhere for a body**. Radiolaria belongs as a constructive encounter in Boolean_Works; do not make the introductory hall carry the whole specimen collection. Its return from Soft Bodies can do different work here: investigate the construction of a rigid, porous form rather than assume that a biological appearance demonstrates softness or growth.

## Radiolaria: confirmed existing work

Lookup: `radiolaria`.
Registry: `commons/artifacts/registry/computational_biology.json`.
Active scene: `algorithms/computationalbiology/radiolaria2/radiolaria.tscn`.
Active script: `algorithms/computationalbiology/radiolaria2/radiolaria.gd`.
The older `radiolaria/` directory is another implementation; the registry resolves to `radiolaria2/`.

The existing generator has six form families. Basic and spiky forms join features to spheres. Some polyhedral variants cut boxes from a sphere. Pollen variants can subtract spherical pores. Lattice forms assemble rings as separate CSG roots. Those gaps are not the result of subtracting a cutter from one enclosing solid.

This is a useful comparison in its own right. A hole can be made by carving a volume or by constructing what surrounds it. Similar silhouettes need not have the same construction history. Do not tell readers that all visible pores are connected to a hollow interior: some current subtractions make surface indentations in a solid core.

The README contains biological, historical and theoretical claims without adequate supporting evidence. Treat them as earlier aspirations, not certification. Describe this generator as radiolaria-inspired geometry; it does not simulate silica deposition, evolution or living morphogenesis.

### First development slice

1. Make an opt-in museum presentation of the existing generator. Suppress its own environment, cameras, screen UI and global keyboard/mouse handling there. Preserve existing placements and standalone behavior.
2. Select a named family and a fixed seed, so comparing two constructions does not silently exchange specimens. A fixed seed already exists; family choice currently comes from a random draw.
3. Present a small, beautiful comparison at a reachable viewing height: added features, carved surface and assembled lattice. Reveal just the operand or structure needed to see the difference. Avoid covering the forms with a full control dashboard.
4. Develop one enlarged porous shell with a deliberate entrance and standing floor. Keep a small specimen nearby so the change of scale remains visible. An original lattice enlarged unchanged may make an enclosure without a usable entrance; check the route rather than assuming it.
5. Make a single consequential adjustment: change an opening while the rest stays comparable. A viewing aperture, a hand-sized opening and a doorway offer different relations to the same shell. Prevent moving geometry from trapping an occupying body.

The initial build should use bounded geometry and stable collision, not regenerate nine detailed CSG specimens every frame. Benchmark the actual selected shell before deciding what must be baked. In the current script, `enable_rotation` turns a camera controller; it does not rotate the specimens. Do not promise moving sculptures on the strength of that flag.

## Boolean spaces: dedicated gallery located

Follow-up search on 24 September found the exact named **Boolean Space Gallery** in the companion app: http://localhost:3003/boolean-space-gallery . Its page, six-entry manifest and an example room configuration returned HTTP 200. This is a much closer match to the author's reference than the earlier tunnel and Turrell candidates; the author has not separately confirmed it yet.

Form ID: `boolean_procedural_space`.

- `space_atrium_warm`: ceiling oculus and central column.
- `space_grotto_cool` and `space_grotto_warm`: two seeded sphere-cut variants.
- `space_light_well_klein`: vertical cylindrical cut and glowing floor disc.
- `space_apse_red`: spherical niche and coloured backing.
- `space_inverse_cube`: four wall cuts and a square ceiling opening.

Godot builder: `commons/testing/render_chromatic_form.gd`, `_build_boolean_procedural_space()` at line 1837. Recipes: `tools/build_chromatic_form_galleries.py`, `boolean_space_entries()`. Public manifests, PNGs and JSON recipes are in the sibling encyclopedia's `public/boolean-space-gallery/`.

The builder uses an outer CSG box, an inner box subtraction and a per-type feature. It explicitly sets `room.use_collision = false`. There is no general entrance cutter. These are existing gallery constructions, not yet demonstrated as traversable exhibits in the current Boolean halls. The map-placeable `chromatic_form_artifact` dispatches only the four Turrell types, so it does not currently instantiate this form ID.

Use these actual recipes as the starting point for the requested spatial encounter. Extract/reuse the generator in a map-placeable artifact; provide a deliberate entrance and floor, appropriate collision, and outside/inside views. Check the effect of each additional cutter against the already hollow interior: six spheres in a recipe do not necessarily yield six consequential caves. Preserve the gallery's original recipes for comparison.

The related `boolean-corridor-gallery` contains architectural corridor studies and can supply a useful approach to the room. `Turrell_Walk` is a separate four-room collection. Keep those relations clear; neither should silently stand in for the located Boolean spaces.

Retain `boolean_burrow` while developing this addition. It supplies a different bounded case of a turning passage; the new room can investigate light, niches, enclosure and dwelling.

## Additional match: a sphere cuts along a path through a large cube

The author clarified that another remembered work uses a path and a sphere to cut through a large cube. The existing Random Boolean Carving family directly matches this mechanism:

- `algorithms/proceduralgeneration/constraint_solvers/randomboolean/random_walk_carver.gd` builds a 10 x 10 x 10 base cube by default, generates path_points, and places a subtractive CSGSphere3D at each point. `show_path_line` exposes the route. This is sampled sphere subtraction, not a continuous swept-volume implementation.
- `advanced_carver.gd` extends it with random walk, spiral, branching, Perlin path and grid tunnels. The registered `boolean_patterns` artifact resolves to `all_patterns_demo.tscn`, which uses this script and is placed at grid (5,6) in `ProceduralGenerationBooleanPatterns`.
- The neighbouring `randboolean.tscn` contains a separate 40 x 40 x 40 cube experiment; its script duplicates five large sphere cutters in a straight row. Keep that distinct from the path-based implementations.

This belongs beside the newly located architectural gallery and Radiolaria, rather than replacing either. It offers a precise return from earlier chapters: a line becomes a sequence of spatial cuts, and their overlap can make a passage. Develop the visible path, the volume removed, and the remaining solid as related views of one seeded construction. To become an inhabitable exhibit, verify entrance, overlap, support and collision with an actual player; connected sampled voids alone do not establish a walkable route.

Source inspected; no new runtime test, placement or fix claimed. The advanced demo still references the earlier script path, so its current loading must be resolved/verified before installation.

## The writing this could earn

Do not add descriptions of unbuilt experiences to final.md. Build and observe the specific encounter first. Possible opening for the future passage, contingent on an actual hollow shell:

> From the aisle it looks like a specimen. At the opening, its scale changes what you can do with it. The lattice that held your eye can hold a space around your body. Through its smaller gaps you can still see the hall. You have gone inside without entirely disappearing.

The critical question follows the material: which openings admit a glance, a hand, a body? Enclosure may protect, display, expose or confine. Porosity alone does not settle which of these occurs. Queer possibility can lie in constructing room for an unanticipated body, keeping a view while withdrawing, or changing the relation between inside and outside. None requires declaring the most irregular form the freest one.

## Completion evidence for the next artifact pass

- Actual museum placement and entry/return route; existing aisle and all relevant artifacts preserved.
- Ordinary player collision at the solid parts, clearance through the chosen doorway, and safe adjustment while occupied.
- Stable specimen identity across the intended comparison; verify that the changed variable causes the observed difference.
- Native outside/inside images from the same artifact for the museum and book, with source and settings recorded.
- Only then add or revise the corresponding canonical encounter and primary status. A staged desktop traversal is not headset or learner evidence.

## Status

This brief follows the applied Boolean reading pass. It changes the next development priority; no Radiolaria or space-generator placement, interaction, runtime test or headset test is claimed. The existing three final.md revisions remain available with full originals and exact comparisons.


## Follow-through: Boolean colour study built, 24 September

The author's subsequent three image references led to a first implemented study: [Boolean colour spaces](../2026-09-24-boolean-colour-spaces/index.html). Three new constructions have deliberate entrances, level support and collision, with pearl, amber, chrome and chalk finishes. The registered `boolean_colour_chamber` is placed three times in the separate `Boolean_Colour_Spaces` study map. Its standalone F6 scene passed bounded bidirectional capsule and pointer-control checks; native images also illustrate its new final.md. This is not yet a test of the full museum loader or headset. The previous status describes the earlier brief; the study's [decisions and evidence](../2026-09-24-boolean-colour-spaces/DECISIONS.md) supersede it for this addition. No old gallery recipe or Radiolaria placement has been silently replaced.


## Later thread requested by the author: Rachel Whiteread

Keep this as a later elaboration after the current coloured-space experiments. The author explicitly connects Boolean space-making with Rachel Whiteread. This is a conceptual relation between positive and negative space, not a claim that her sculptures were made with digital Boolean operations.

**References checked:** [Ghost (1990), National Gallery of Art](https://www.nga.gov/artworks/131285-ghost), [the NGA account of the casting process](https://www.nga.gov/press/first-comprehensive-survey-rachel-whitereads-work-makes-american-debut-national-gallery-art), and [House (1993), Artangel's construction account](https://www.artangel.org.uk/project/house/construction/). Ghost's plaster sections preserve impressions of an actual room, assembled with those traces facing outward. House cast the interior of a domestic building in concrete. Avoid saying either simply filled a complete room or house with a homogeneous solid: the documented processes involve panels or reinforced layers.

The connection changes the question. Our subtraction makes room to enter. A cast can make the room's former interior present as an object to approach from outside. Domestic traces, the prior lives of a place and loss matter here; do not reduce Whiteread to an illustration of a set operation.

**Proposed later encounter, not built:** retain a specific traversable room and present beside it the positive form corresponding to its interior, including a doorway recess, window detail or other particular trace. The walkable negative and its positive counterpart should share a verifiable construction. Let the visitor move around the counterpart rather than instantly swap the space to solid while someone occupies it. A digital volume comparison can be inspired by Whiteread without pretending to reproduce her casting process or a named artwork.

Possible writing lead: *The space that held you is now something you must walk around.* Follow it with the actual preserved detail and its history. Which traces let a room remain recognisable when it can no longer receive a body? What does the apparent reversibility of a digital operation leave out of a place's loss?

Whiteread's cast makes absent space tangible; the computational complement lets us compare two representations. Keep both the relation and the difference available. Develop this as its own encounter before adding claims to the canonical final.md.


**Facade follow-up:** The author points out the existing facade works. [Source-grounded elaboration and proposed encounter](../2026-09-24-boolean-more-spaces/FACADE-WHITEREAD.md) now connects the existing Facade Assembly branch, plan-based composer and tenement/classical works to a future room/positive comparison. A named Whiteread-inspired cast mode already exists, but source inspection shows stacked blocks, not a cast of a particular interior. No new runtime or integration claim.
