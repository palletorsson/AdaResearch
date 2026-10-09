# Patterns: the room wears what we make

**Current implementation:** all seven Patterns rooms now have focused book passages and primary encounters. Ribbon_Patterns_03 implements the closing source/shader/skirt studio, live player mirror and saved-fabric runway. [Review the evidence](ribbon-patterns-03.html). Headset testing, continuous gestures, more garment receivers and a common cross-tool recipe library remain open. The plan and earlier milestones below preserve the route by which we arrived here.

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
2. **Plane and curved-sheet pilot implemented:** matching 1.2 metre surface dimensions and UV addresses, linked or locally held curved preview. The existing inner wall now receives a larger field at matching metre spacing. The selector addresses each of five surfaces, the three-wall ARCHITECTURE group, or ALL FIVE; garment-region adapters and seam comparisons remain open.
3. **First registered scope and undo implemented:** source editing stays shared, while TARGET and LINK / HOLD govern five explicit receivers; UNDO LINK restores held images or live links. REPEAT SIZE now offers 15, 30 and 60 cm, saved with the source recipe; held images retain their own spacing. ARCHITECTURE now groups the original wall plus NORTH and EAST, with reversible mixed membership. OFFSET +5CM now advances sampling from zero to 30 cm while preserving the motif and repeat size; held receivers and source saving retain offset. Next add explicit held-hand input. Whole-hall Hold/Play/Vary and gesture takeover remain open.
4. Add the three parameter gestures, then bounded contour sampling; verify release, tracking loss, reset and panel equivalence.
5. Save and wear one fabric; restore the previous outfit and verify that other garments, agents and rooms remain independent.
6. Stage the shader conclusion with readable code tied to each live operation; test appearance, mesh and collision separately.
7. Walk the whole route, profile its selected shaders and transparent surfaces on the target headset, and write/update the primary-linked book passages from those observations.

The immediate next action is explicit held-hand control of the bounded pattern offset, including release, tracking loss and panel equivalence. Pattern_Foundry now connects two specimens and three existing inner-wall faces, with individual selection, an ARCHITECTURE group and ALL FIVE. Group undo preserves mixed link states and held images. Whole-hall coverage remains open: these names deliberately describe the registered subset. The loom now joins the two tile lessons as a primary artifact with a matching book passage. Whole-hall control, continuous hand gestures and garment transfer remain to be built; shaders remain the required conclusion. See the working guide for the museum capture and test report.

Source anchors: `commons/artifacts/pattern_machine_a/pattern_machine_a.gd`, `commons/artifacts/pattern_maker_station/pattern_maker_station.gd`, `commons/resourses/shaders/wallpaper_tile.gdshader`, `commons/player/super_drag_outfit.gd`, `commons/artifacts/super_drag_mirror/super_drag_mirror.gd`, `commons/artifacts/drag_catwalk/README.md`, and `algorithms/shaders/book_of_shaders/`.


## Workshop interfaces, 10 September follow-up

The physical Pattern Studio is now upgraded and desktop verified: native motif resolution, corrected group selection, source/preview layout, undo, and loading saved web packages with their existing shader finish. Its own source editor remains separate from the Foundry loom recipe. Before adding another editor, consolidate the physical studio, Pattern Maker Station and existing Panel Bridge pattern state adapters. The provided loom, meander, mosaic and facade editors each retain a distinct source model. See [the workshop comparison](../research/possible-bodies/studio-workshop.html) for the relevant source files, reuse points, missing adapters and sequence of next actions. Shaders remain the final explicit teaching section; using the shader to display a saved pattern here does not complete that section.


### Explicit studio-to-surface adapter

Implemented the first cross-editor receiving adapter: the physical studio selects one of the Foundry's five surfaces, the three-wall Architecture scope or All Five. APPLY LIVE, HOLD, LOOM and shared UNDO LINK track both the source and accepted material. Source recipes remain distinct. Live links catch up to their owner; held images survive source edits and source departure. This establishes the receiver protocol for future Panel Bridge, mosaic and weaving adapters without claiming they are already connected. The immediate next step remains deliberate held-hand control or the next source adapter; whole-hall coverage, avatar transfer and the shader conclusion remain open.

### Inhabit the source: curved studio room

Pattern_Foundry now includes an eight-metre curved studio room in the northern runway annex. ROOM WALL and ROOM FLOOR are independent receivers; ROOM selects both. Its 300-degree wall, broad entrance and roof opening make the editable pattern surround the player. Wall repetition follows arc length; floor repetition follows a planar grid. Holding one while editing the other separates stored state from the shape that carries the body. The existing five samples and three-wall Architecture scope retain their meanings.

The source, receiver controls, museum route, collision and shared undo pass 86 studio/room checks; 99 existing Foundry regression checks also pass. The next step is a headset walkthrough of approach, readability and turning, then deliberate held-hand control of pattern offset with release/tracking-loss handling. Garment transfer, the other editor adapters and the closing shader lesson remain open.

### Continue the route: Tutorial_Pattern

User deferred headset and gesture work while working remotely. The next-room pass now equips Tutorial_Pattern with a primary Pattern Maker comparison bay: one editable 4x4 source, fixed P1 and PM panels, selectable floor rule, source flip/rotation, undo and reset. The book and room documents follow the verified controls. 41 desktop museum checks pass. Continue to Array_Patterns next; gestures and headset inspection remain open for later.

### Ground-up route and Array_Patterns

The agreed progression builds on arrays and colour: address and palette index → motif → repetition → relations between copies → surface mapping → shader/material → dressed body. Shaders appear first as short code tied to a visible operation; the closing room gathers coordinates, lookup, edges and material response. Repeated physical objects and repeated surface images need separate comparisons because they affect passage differently.

Array_Patterns now supplies the address-to-environment step. A fixed 4x4 source feeds a six-metre passage with floor/right-wall address inspection, 40/60cm cells, drawn-grid visibility and undo. Surface directions and partial edge cells make the carrier's role visible. The earlier generic timed reveal is deferred in this lesson; no gesture or headset requirement blocks the route. Continue to Symmetry_Seventeen next: organise the encountered operations and state the classification's assumptions. Garment transfer and the shader conclusion remain open.


## Symmetry_Seventeen: hold a comparison

[One mark, three rules](symmetry-seventeen.html) now follows the raised Array_Patterns corridor. The primary editor supplies P1, PM and PG, sixteen editable source addresses, four paints, HOLD, UNDO and RESET. The held panel owns its pixels while the live panel and carpet share the changing result. A plain backing wall and a reachable console stage the comparison in the existing east bay.

The book now asks what remains the same before naming the symmetry. An unusually symmetric source can conceal a construction rule or add symmetries; pressing a group button does not certify the resulting image's exact group. The cage remains a diagram. The next room is Ribbon_Patterns_01. Forty desktop checks pass; headset work remains deferred.


## Ribbon_Patterns_01: an address gains depth

[The paired array study and book passage](ribbon-patterns-01.html) follow the saved plan's surface-to-volume progression. Sixteen source cells supply four height layers. A shared console selects x, z and height, switches repeated/shifted lookup, reveals a single slice and undoes changes. The source frame tracks the lookup while the volume address stays fixed. Visible and stored counts distinguish hiding from deletion.

The two primary arrays stand together in the west bay. Nine secondary exhibits remain. Initialization now avoids a duplicate volume when configuration arrives before _ready. Twenty-two desktop checks cover the lesson and the default/early-configuration paths. Headset work remains deferred. Next: Ribbon_Patterns_02 for carrier and viewing conditions, then the planned closing shader/fabric studio.


## Ribbon_Patterns_02: what the surface contributes

[The context and carrier studies](ribbon-patterns-02.html) now lead the room. One comparison changes surrounds while holding target RGB values fixed. The other shares a source texture across a plane and half-cylinder with matched physical spacing, then varies a stated directional shading rule. Repeat boundaries, horizontal repeat size, light side, undo and reset have mounted controls.

Twenty-three desktop checks pass. The inherited MetamerismLab token supplies the carrier study, with no claim of spectral computation. The other ten exhibits remain supporting material. Next: Ribbon_Patterns_03 for the closing shader/fabric studio and garment transfer. Headset and gesture work remain deferred.

## Closing studio implemented — 10 September

Ribbon_Patterns_03 now contains `fabric_shader_studio`, `super_drag_mirror` and `drag_catwalk` as its three book primaries. The fourteen existing exhibits remain secondary. The console edits a 4x4 source; its own spatial shader separates UV view, offset/repeat, fragment discard, matte/metal response and static vertex displacement. Wall and skirt each use their own UV domain; no claim of equal metre spacing or cloth dynamics is made.

SAVE stores a validated versioned recipe. WEAR SAVED targets the current player's selected skirt and persists that appearance independently of progression. RUNWAY SAVED targets four current performer skirts. Neither action follows unsaved preview changes. Undo restores prior assignments; SAVE is not a versioned history. The mirror reflects actual live geometry.

Next actionable room: **Change_Intro**. Keep the distinction between a configuration, its rate of change, accumulated history and the forces that govern its motion. Open workshop work: headset/standing reach and stereo comfort, continuous deliberate gestures, full secondary curation, more named garment adapters, and explicit interoperability between the existing Foundry/editor recipes and the closing fabric recipe. Do not describe those as completed.
