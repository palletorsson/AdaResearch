# Isosurfaces: what makes an opening possible?

20 September 2026. [Text and image comparison](http://localhost:3003/book-review#isosurfaces).

The thirteen chapters already sustain a useful thread: a value becomes a classification, then a selected boundary; a boundary may be visible without being available for touch or passage. Keep that distinction and the existing comparisons. The consequential gaps were in the route and the opportunity to perform an experiment, rather than in the amount of explanation.

## Decisions and applied changes

- **Restore the authored route.** Portal Landscape, Cave Generation, Animated Noise, Implicit Modeling and Rhizome Body were absent from `map_authored`'s Isosurfaces list. All thirteen declared halls now appear there, in both museum plans and in the derived museum order. Other sequences' plan rows are unchanged. The existing off-route Chamber pearl remains in the book data; it has not been deleted to make an inventory look tidier.
- **Make Portal Landscape's proposed comparison possible.** The new secondary desk controls the existing landscape generator. TERMS steps through hillside, overhung, quarried, arched and compound. HOLD retains one independently copied mesh in a neighbouring bay; RESET restores the live hillside while preserving the held surface; CLEAR removes the comparison; RULE reveals the field expression. Coordinates, display scale, sampling and level stay fixed. No new terrain kernel was substituted. The held mesh deliberately has no collision.
- **Give the restored encounters usable placements.** Portal Landscape has two six-metre display bays and an unobstructed control approach. Cave Generation and Animated Noise retain both of their original specimens; a small secondary staging helper fits their large source domains to the room without changing their fields. Rhizome Body remains full size, moved away from the back wall. Rectangular layers, aligned entrances and explicit museum placement replace the legacy arrangements in the other four restored halls.
- **Respect the raymarcher's coordinate system.** The first placement attempt scaled its proxy box but left the shader's world-space field full size, visibly clipping the spheres. The final Implicit Modeling placement keeps unit scale, raises the field clear of the floor and uses the existing `fusion:necked` setting so the joins discussed in the chapter are visible. Its twelve-metre proxy is a rendering volume, not a twelve-metre solid body. No shared shader was changed.
- **Keep the prose selective.** Eleven `final.md` files are byte-for-byte preserved. Portal Landscape now begins with a ridge to follow and an action to perform, then gives the short density expression. Its question remains whether another fold creates any usable room for this body. Metaballs changes only its final sentence, leading into raymarching before the passage-making question returns in Rhizome Body. [Exact text diff](final.diff).
- **Keep supporting work available.** All original artifact tokens in the five restored maps remain. Existing roles remain. The console and staging helpers are secondary. The Rhizome pearl, previously missing from the book index, is added. The sequence objective now names sampled gyroid level sets without promising a minimal surface at every level.

## Evidence

- [Portal runtime report](review-report.json): 38 controlled checks, plus two successful CharacterBody approaches. Tests use the real GPU-produced mesh and actual button signals. They verify independent held geometry, fixed non-varied parameters and transforms, all five field states, reset/clear, unavailable-renderer handling and capture-camera ownership.
- [Restored halls](restored-checks.json): all four other primary encounters instantiate, fit horizontally inside their rooms and permit the tested gallery route. Cave Generation and Animated Noise also retain and fit their secondary specimens. These checks do not certify the walk inside the rhizome.
- [Navigation](navigation.json): 41 checks of the production museum's selection and advancement through all thirteen halls. This checks route selection, not a headset walk through every connecting portal.
- [Content and preservation](content-checks.json): 88 checks pass, including unchanged prose/maps, original tokens and roles, scoped plan changes, current hashes and derived order. [Re-run script](verify_content.py).
- Actual Godot museum captures use the desktop Vulkan/mobile renderer. The paired Portal images show two settings of the revised artifact from the same camera; they are not a matched before/after software pair. [Encounter](after-encounter.png), [overhung](after-overhung.png), [compound](after-compound.png), [caves](ISO_CaveGeneration.png), [animated noise](ISO_AnimatedNoise.png), [implicit field](ISO_ImplicitModeling.png), [rhizome](ISO_RhizomeBody.png).

The arch and outcrop additions cause small mesh changes in this fixed example; the last two states have the same triangle count. Neither a name nor a triangle count establishes an accessible arch. The text asks the visitor to examine that difference instead of promising a large opening on every press.

Before-files and their hashes are retained in this folder. The current input manifest records the inspected revision. Runtime helpers create private encounter-probe copies; the full museum bake was not regenerated. Local/shipped plans and derived listings were refreshed. The builders still report pre-existing layer-size mismatches in Waves, Randomness and Noise; these are outside this pass.

## Remaining work

1. Headset approach, reach, readability and performance. Button-signal checks are not tracked-hand interaction or learner acceptance.
2. Rhizome Body's internal route: test intended graph connections against actual openings and body clearance. A clear outer gallery aisle proves neither a usable interior loop nor a tunnel.
3. Export closure for the existing lesson consoles and shared helpers, so future online review bundles include their dependencies. The live project was inspected here; a small source bundle can still miss them.
4. A later raymarching comparison could render the same field as a marching-cubes mesh at two resolutions, as its preserved chapter proposes. World-space field scaling and shader depth deserve a separate implementation pass if this artifact is to become a general resizable exhibit.

Next in the spine: **Boolean Surfaces**. Carry forward the distinction between an operation on a field, a change in the visible boundary and a change in what a body can do.
