# Patterns: the room wears what we make

Current implementation plan · 10 September 2026

This revision governs the next Patterns pass. It supersedes the proposed encounter order in the two 9 September plans, while retaining their source research. It does not change the live seven-room order or claim that the upgrades below are already built.

**Make a motif → repeat it → give it different bodies → perform it → inspect its shader → wear and keep a fabric.**

Colour ended with a message and its receivers. Patterns asks what bodies a shared rule can dress, organise or enable. The hall is itself a receiving body. The avatar is another. Their common recipe lets us compare them without pretending they have identical geometry, mapping or collision.

## What exists, and what needs building

| Existing material | Source evidence | Required upgrade |
|---|---|---|
| `pattern_machine_a` | Editable punch card, touch areas, wallpaper groups and scrolling carpet | Export an editable recipe; receive edits from the hall panel and gesture input; send output beyond its own carpet |
| `pattern_maker_station` | Palette cells, source transforms, wallpaper groups, CPU texture and GPU carpet | Share the recipe and target adapters; distinguish motif shape from carrier shape |
| `super_drag_mirror` and catwalk | Mirror and four authored outfits, reused by the player and walking agents | Apply a saved fabric to named garment regions; keep outfit silhouette independently selectable |
| Existing shader lessons | Coordinates, shaping, repetition and material sources | Select and verify a closing shader studio; do not activate every legacy shader gallery |

The loom supports direct hand edits already. This does not establish continuous hand-motion control, whole-hall control, arbitrary surface mapping or motif-to-avatar transfer. Those connections are explicit work items.

## First build: a hall instrument with several outputs

Keep one machine as the authoring instrument. Upgrade `pattern_machine_a` first, with `pattern_maker_station` using the same recipe interface afterward. Avoid making a separate editor for every receiver.

The first demonstrable result is one asymmetric motif appearing on a swatch, a wall bay, a curved sculpture and one avatar garment region. Change the motif once and inspect all four. Then detach one receiver and keep a local difference. The four existing outfits remain available; they are not replaced by a single patterned suit.

**Different forms means two things.** Motifs must eventually include hand-drawn contours and imported masks as well as square colour cells. Carriers must include flat panels, bent surfaces, compound sculptures and moving garments. Begin with the existing cell motif and a plane plus a curved specimen; add contour input after the shared output works. Do not present a raster resolution increase as support for every form.

### The hall control panel

Place one reachable, clearly labelled panel at the hall entrance. Its master setting controls every registered pattern-bearing part of that hall: machine outputs, floor and wall fields, sculpture surfaces and consenting garment previews. A target selector offers **Whole hall / Architecture / Sculpture / Garment / Selected surface**. A visible highlight identifies what will change. Another hall must not change because it shares a material resource.

Provide motif, palette, repetition scale in metres, orientation, repetition rule, mapping frame and local animation speed. Expose only the controls needed by the current lesson; later controls open when their operation has been encountered. Lighting has a separate comparison control so a material change can be tested under fixed light.

**Hold / Play / Vary** governs the installation's own process. Taking a control holds its local automatic score at the current state; resuming is explicit. Hold does not stop the museum clock, tracking or the visitor's movement. Vary changes only selected axes within displayed bounds. Undo and restore recover the prior recipe, including its phase.

“Whole hall” is a deliberate registered scope, including its architectural surfaces. It must not recolour labels, controls or neighbouring exhibits by indiscriminately replacing every material in the scene tree.

### Hand movement as another input

Use an explicit grip or held handle to begin and end a gesture. Walking through the room with ordinary hand motion must not silently edit it. Offer one selected mapping at a time:

| Gesture | Pattern parameter | Comparison |
|---|---|---|
| Move one held hand sideways | Pattern offset | The field moves while the wall stays still |
| Move two held hands apart | Repeat spacing | The same motif occupies more or less room |
| Turn a held dial or handle | Pattern orientation | Rotating the sample frame differs from turning the body |
| Trace on a drawing surface | Motif contour | The sampled trace returns as a repeatable mark |

The panel and hand controls write to the same parameter state. The active gesture owns that parameter until release; automation cannot fight it. A panel/pointer equivalent remains available. Show the affected value and preserve the released state. Hand speed can become a later rate experiment, once Change has supplied the needed distinction.

## Revised teaching route

Keep the current room order while upgrading and writing hall by hall. The last section is a required shader-and-fabric conclusion, not an optional glitch collection.

| Room | Question and material | Required result |
|---|---|---|
| `Pattern_Foundry` | What can share one decision? Existing asymmetric tile comparisons, then the loom as a room instrument | First machine-to-swatch, wall, curved form and garment demonstration; a hall panel with visible scope |
| `Tutorial_Pattern` | What changes when the mark stays fixed? | Shared motif under translation and reflection; deliberate hand control of one parameter |
| `Array_Patterns` | What turns repetition into an environment? | Extend controlled outputs across tunnel/wall surfaces; inspect corners, scale and actual passage |
| `Symmetry_Seventeen` | What does a symmetry preserve, and under which assumptions? | Hold the motif while comparing operations; keep classification distinct from taste |
| `Ribbon_Patterns_01` | What changes when an address gains depth? | Compare a planar arrangement with a spatial array; distinguish volume from a pattern wrapped around a surface |
| `Ribbon_Patterns_02` | What does the carrier and its viewing condition contribute? | Same recipe on different forms and under fixed/changing light; seam and sampling comparisons; keep recovered colour exhibits as supporting material |
| `Ribbon_Patterns_03` — closing shader and fabric studio | Where does the pattern run, and what does the material promise? | Coordinates → repetition → edge/mask → material response → visible deformation; save a fabric and try it on the avatar in the existing mirror/catwalk |

The existing glitch objects do not by themselves complete the final room. Use verified configurations from the shader lesson sources to supply the missing steps. Keep glitches as optional limit experiments. If the terminal room cannot hold this progression comfortably, propose a split from a measured layout; do not silently add every shader map to the route.

Shaders may power earlier exhibits. Their code becomes the explicit object of discovery at the end: UV versus body/world coordinates, `floor`/`fract`, threshold and soft edge, then roughness/specular/alpha and a separately tested vertex displacement. A shaded hole, discarded fragment, displaced vertex and physical opening require different accounts. Noise, feedback and reaction-diffusion return later with their prerequisites.

## Fabric as a result the player can keep

A fabric recipe stores a version, resolved motif or contour samples, palette, repetition rule, physical scale, mapping frame, finish parameters, local phase, seeds and resolved generator choices. It records intended garment regions and the source recipe. Save the recipe and a preview; applying it to an avatar is a separate action from changing a wall.

Support **linked preview**, **detached copy**, **save**, **wear**, **undo** and **restore outfit**. Keep skin, garment, trim and silhouette separate. Do not overwrite the visitor's skin or every agent's outfit when they dress one garment. Let a runway agent preview the same fabric by explicit selection; its motions provide another mapping test.

Matte print, glossy latex, reflective metal and cutout lace are material comparisons to author and inspect. Calling a surface fabric does not mean cloth dynamics exist. Pattern continuity across primitive parts, seams, world-locked mapping during movement, and the difference between visible softness and rigid support are part of the discovery.

Drag, fetish and desire enter through attention and choice: a seam enlarged until it dominates a wall, a print that refuses to stay aligned with the body, a familiar silhouette taking an unexpected finish. The learner can make an unanticipated combination; the machine does not score how queer an outfit is.

## Build queue and completion evidence

1. **Implemented, desktop verified:** export/import one resolved loom recipe; restore source and history pixels, card, palette and animation phase without changing another instance. JSON fractional values are checked within parser roundoff.
2. **Plane and curved-sheet pilot implemented:** matching 1.2 metre surface dimensions and UV addresses, linked or locally held curved preview. Next: a registered wall receiver and visible scope selector; garment-region adapters and seam comparisons remain open.
3. Build the hall panel with explicit target registration, local Hold/Play/Vary, takeover and undo; verify one hall cannot mutate another.
4. Add the three parameter gestures, then bounded contour sampling; verify release, tracking loss, reset and panel equivalence.
5. Save and wear one fabric; restore the previous outfit and verify that other garments, agents and rooms remain independent.
6. Stage the shader conclusion with readable code tied to each live operation; test appearance, mesh and collision separately.
7. Walk the whole route, profile its selected shaders and transparent surfaces on the target headset, and write/update the primary-linked book passages from those observations.

The immediate next action is a registered wall receiver and an explicit target selector in Pattern_Foundry. It begins the hall-panel build; the current specimen console controls only its own comparison. The loom now joins the two tile lessons as a primary artifact with a matching book passage. Whole-hall control, continuous hand gestures and garment transfer remain to be built; shaders remain the required conclusion. See the working guide for the museum capture and test report.

Source anchors: `commons/artifacts/pattern_machine_a/pattern_machine_a.gd`, `commons/artifacts/pattern_maker_station/pattern_maker_station.gd`, `commons/resourses/shaders/wallpaper_tile.gdshader`, `commons/player/super_drag_outfit.gd`, `commons/artifacts/super_drag_mirror/super_drag_mirror.gd`, `commons/artifacts/drag_catwalk/README.md`, and `algorithms/shaders/book_of_shaders/`.
