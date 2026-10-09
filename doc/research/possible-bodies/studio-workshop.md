# A workshop of related instruments

**Current state — 10 September:** the closing [source-to-skirt studio](ribbon-patterns-03.html) now connects source editing and shader controls to a saved fabric, the player mirror and four walking performers. All seven Patterns rooms have a focused book passage. [Change_Intro now has a two-sample comparison](change-intro.html). Next: Accumulation_Riemann; headset and continuous gestures remain deferred. The entries below record the workshop's development.

The question stays: **what bodies are possible with these operations?** The editors already offer different ways of answering. Carry their editable structures into VR, not just the resulting images.

## First workstation: Pattern Studio

![Pattern Studio in the museum](pattern-studio-console.png)

The existing `pattern_studio_plate` now has a 1.32 m face, a 42 cm editable source, a tiled shader preview, separated paint swatches and explicit previous/next selectors. Row zero is at the top, matching the web editor. A loaded motif keeps its native 2, 4, 6 or 8 cell resolution; the Greek Key no longer loses half its cells. All seventeen group labels now address the corresponding engine rule. MIRROR reflects the whole source; two presses return it. Four ROTATE presses also return it.

Paint a cell near an edge, then change GROUP while keeping the source. Follow the copies in the preview and the carpet. Return with UNDO. The source and the rule are distinct decisions even when one image makes them hard to tell apart.

**WEB NEXT** reads saved JSON patterns in `res://commons/patterns`, the directory written by the web studio's save action. It keeps supported tile-shape, grout, distortion and weathering values and sends them through the existing Godot wallpaper shader. Shader finish is rendered here; its dedicated VR editing controls remain to be added. Zone is retained as metadata, not presented as an implemented spatial operation.

**SAVE / RESTORE** use a separate local file, `user://pattern_recipes/studio.json`. They preserve the source and its finish without overwriting a web-authored file. This is currently a web-to-VR load path, not automatic bidirectional synchronisation. UNDO retains up to 32 earlier source states. Unsupported sizes above 8 or palettes above 9 colours are rejected explicitly rather than reduced silently. Library loading on a packaged headset uses files bundled with that build; it does not watch the desktop web server.

![The workstation and its carpet](pattern-studio-room.png)

The station now stands at grid (30,11), inside an eight-metre curved room in the northern extension of the runway annex. A three-metre doorway connects the bays. The earlier teaching grid and runway remain intact; the new floor occupies previously unused cells and automatic sculptures are excluded from the room. The station remains a secondary workshop artifact. The book's three primary artifacts are unchanged.

## The studio can now select its receiving surfaces

The smaller console beside the studio selects WALL, NORTH, EAST, FLAT, CURVE, ARCHITECTURE (three walls), or ALL FIVE. Selecting a target changes nothing until you act.

- **APPLY LIVE** makes the selection follow the studio. Subsequent studio edits update only its live receivers.
- **HOLD** keeps the current material and domain image.
- **LOOM** explicitly returns the selection to the current loom recipe.
- **UNDO LINK** reverses the latest receiver transaction from either console, restoring both ownership and live/held state. A restored live source catches up; a restored held image stays exact.

The labels identify LOOM, STUDIO or mixed ownership. A studio-owned wall cannot be overwritten by edits to the loom. The adapters retain the two recipe types rather than converting one into the other. The studio's shader uses a 1.2 m reference square on room receivers, keeping the same physical repeat size across different wall widths and the bent specimen. Meshes and collision remain unchanged. If a studio leaves, its receivers hold their last image.

This bridge is confined to the studio's own authored hall. It does not apply to avatars, adjacent halls or every wall in the museum. SAVE/RESTORE still saves the source package, not these temporary receiver links. The studio's own preview and carpet still use their established normalized UV mapping.

## Enter the pattern

![Inside the curved pattern room](curved-room-inside.png)

The studio is now inside the space it can dress: an eight-metre room with a 300-degree curved wall, 3.2 metres high, a wide entrance and an opening in the roof. The source remains small enough to edit; its consequences surround your body. Start at the console, then step back and walk towards the wall.

**ROOM WALL**, **ROOM FLOOR** and **ROOM** join the selector. Apply to both, or hold the floor while the wall follows your edits. The existing ALL FIVE and ARCHITECTURE selections retain their original meanings. The room begins linked to the studio with a readable 60 cm card repeat. A loaded web recipe can choose another repeat count.

The wall maps the motif using distance along its curve. The floor uses a flat x/z grid. Equal repeat size does not guarantee that their marks meet at the seam. Pattern changes leave the curved wall, its collision and the entrance unchanged. The room's shape carries the body; its surface can change how that place is perceived.

![Entrance to the curved room](curved-room-entrance.png)

The captures use the Guilloche motif with the Renaissance palette. They are actual desktop Godot views. The wall has an outer plaster backing. The shell and roof do not cast shadows, avoiding the coarse sun-shadow edge across the print. The roof opening frames the sky; a fixed local light supports comparison under the museum lighting. Headset comfort and rendering performance still need a walkthrough.

## What each web instrument contributes

| Source | Editable structure | VR continuation |
| --- | --- | --- |
| [Pattern Studio](http://localhost:3003/pattern-studio) and [Pattern Maker](http://localhost:3003/pattern-maker) | A colour-indexed domain, palette, symmetry rule and material settings | One shared source editor, tiled preview and explicit receiver selection. This turn improves the physical studio; the other station and Panel Bridge still exist and need a deliberate consolidation pass. |
| [Loom](http://localhost:3003/loom) | Threading, tie-up and treadling matrices compute a drawdown | Improve the existing Panel Bridge loom so a selected crossing can be traced back through the matrices. The wallpaper loom and spring-based cloth are different systems; neither is automatically this weaving computation. |
| [Meander Editor](http://localhost:3003/meander-editor) | Separate straight and corner tiles, bands and field parameters | Edit an edge, then walk to its corner and inspect the join. Existing border motifs provide geometry/rendering sources; a dedicated VR editing adapter still needs to be built. |
| [Mosaic Editor](http://localhost:3003/mosaic-editor) | A central field, ordered border/separator rings and a threshold | Select one spatial region and change its rule. Reuse pattern packages and the existing composite loader. Ring order and widths belong to the composition, not to a single motif. |
| [Facade Builder](http://localhost:3003/facade-builder) | Parts placed in bays, stories and zones; symmetry expands placements | Select a bay and compose at model scale, then inspect the full-size wall. The Godot facade builder already accepts plan JSON; its source identifies direct VR interaction as missing. Openings must be checked against collision. |

These links were inspected through their local source implementations and HTTP responses. The browser automation connection was unavailable; their full interactive web workflows were not exercised during this pass.

## Shared conventions, distinct models

Use **source → operation → receiving body** as the common arrangement. Keep the source visible while its consequences appear beside it and in the room. Use previous/next for named choices, bounded sliders for quantities, and an explicit held control for continuous hand movement. Select the receiver before applying; distinguish a live link from a held copy.

Reuse the existing `commons/ui/panel_bridge` machinery for matrix and multi-panel editors. It already loads layout/data JSON and hosts loom, pattern and grid widgets. The physical studio adds a more tangible front end to the existing pattern model, rather than replacing that infrastructure.

A shared package envelope should eventually identify the maker type, version, editable source, operation parameters, mapping, finish, receiver scope and provenance. Keep the type-specific payload: a weaving draft, border pair and facade plan are not interchangeable pixel grids. Do not flatten them into textures and claim the source survived.

## Next actionable improvements

1. Compare the physical studio, Pattern Maker Station and Panel Bridge pattern editor; choose one common state adapter before duplicating more controls.
2. **Implemented:** explicit studio-to-surface APPLY LIVE / HOLD / LOOM / UNDO LINK, with shared receiver transactions and distinct source schemas.
3. Connect a deliberately held hand control to offset; verify release, tracking loss and independence from walking.
4. Make the existing Panel Bridge loom's source-to-crossing explanation readable in VR.
5. Add straight/corner editing, then ordered mosaic regions using those motifs.
6. Add a facade bay selector and a tested model-to-room scale transition.
7. Finish the sequence with shader controls and code: coordinates, repeat, masks, surface finish, then separately tested mesh displacement and collision. Garment transfer remains an explicit later action.

## Verification

86 studio/adapter/room checks and 99 Foundry regression checks cover this step. See [the studio checks](pattern-studio-check.json) and [the Foundry receiver checks](pattern-recipe-check.json). Captures are actual desktop Godot museum views with the player outfit hidden for inspection. Headset reach, touch comfort and performance remain untested.

[Return to the working guide](index.html#Pattern_Foundry) · [Patterns sequence plan](patterns-plan.html)

## Next room: the mark stays

[Tutorial_Pattern now has a focused comparison bay](tutorial-pattern.html). One source feeds fixed translation and reflection panels and a floor with P1/PM selection. Source painting, FLIP X, ROTATE, UNDO and RESET work through the desktop pointer. The text follows these controls. Headset and continuous gestures are deferred; the next hall is Array_Patterns.

![One source, two rules](fixed-motif-bay.png)

## Array_Patterns: enter the addressed surface

[The tunnel now has a source/address inspector](array-patterns.html). Move between floor and right-wall coordinates, change cell spacing and hide the drawn grid without changing collision. The book follows those controls. 50 desktop checks pass; continue to Symmetry_Seventeen next.

![An address becomes a passage](tunnel-address-bay.png)

The Array_Patterns corridor now stands on a platform with wp ramps and side wings that require the bay crossing to pass through it. The inspector remains reachable from the lower floor.


## Symmetry_Seventeen: hold a comparison

[One mark, three rules](symmetry-seventeen.html) now follows the raised Array_Patterns corridor. The primary editor supplies P1, PM and PG, sixteen editable source addresses, four paints, HOLD, UNDO and RESET. The held panel owns its pixels while the live panel and carpet share the changing result. A plain backing wall and a reachable console stage the comparison in the existing east bay.

The book now asks what remains the same before naming the symmetry. An unusually symmetric source can conceal a construction rule or add symmetries; pressing a group button does not certify the resulting image's exact group. The cage remains a diagram. The next room is Ribbon_Patterns_01. Forty desktop checks pass; headset work remains deferred.


## Ribbon_Patterns_01: an address gains depth

[The paired array study and book passage](ribbon-patterns-01.html) follow the saved plan's surface-to-volume progression. Sixteen source cells supply four height layers. A shared console selects x, z and height, switches repeated/shifted lookup, reveals a single slice and undoes changes. The source frame tracks the lookup while the volume address stays fixed. Visible and stored counts distinguish hiding from deletion.

The two primary arrays stand together in the west bay. Nine secondary exhibits remain. Initialization now avoids a duplicate volume when configuration arrives before _ready. Twenty-two desktop checks cover the lesson and the default/early-configuration paths. Headset work remains deferred. Next: Ribbon_Patterns_02 for carrier and viewing conditions, then the planned closing shader/fabric studio.


## Ribbon_Patterns_02: what the surface contributes

[The context and carrier studies](ribbon-patterns-02.html) now lead the room. One comparison changes surrounds while holding target RGB values fixed. The other shares a source texture across a plane and half-cylinder with matched physical spacing, then varies a stated directional shading rule. Repeat boundaries, horizontal repeat size, light side, undo and reset have mounted controls.

Twenty-three desktop checks pass. The inherited MetamerismLab token supplies the carrier study, with no claim of spectral computation. The other ten exhibits remain supporting material. Next: Ribbon_Patterns_03 for the closing shader/fabric studio and garment transfer. Headset and gesture work remain deferred.

## Ribbon_Patterns_03: from source to skirt

[Open the studio and book passage](ribbon-patterns-03.html). Three primaries now close the sequence: the source/shader console, the live player mirror and the runway. Paint an address; inspect UVs, repetition, fragment cut-outs, finish and static vertex displacement. Save a recipe before deliberately wearing it or dressing the four performers. Only their named skirts receive it; studio undo restores previous assignments.

![One saved fabric on the actual player in the mirror](fabric-mirror.png)

This closes a specific path from arrays and colour to surfaces and garments. It does not yet unify every workshop tool into a shared recipe library. The Foundry's wall/floor ownership remains its own adapter; continuous gestures, other garment parts, stereo mirror work and headset reach are still open. The next room, Change_Intro, can ask how these configurations vary over time.

## Change_Intro: two samples before the tangent

[Open the room and book passage](change-intro.html). The existing workbench now starts with two sample points. STEP narrows their interval; DERIVATIVE reveals the analytic tangent and derivative subplot. At the starting point a wide secant falls while the local tangent rises: the interval has crossed a crest. This makes the transition from appearance to variation specific without silently turning a spatial x-axis into time.

The five controls join the original slider in one floor-standing cabinet. The sign card now says near zero under a declared threshold, without asserting an extremum. The book follows the sole primary; all ten supporting exhibits and the existing grid layout remain. Next: Accumulation_Riemann.


## Accumulation_Riemann: keep one account beside another

[Open the comparison and book passage](accumulation-riemann.html). The same curve now supplies rectangle contributions. HOLD preserves a picture and total; RULE moves samples between midpoint and edges; the count slider refines the partition. The reference appears only when requested and names its finite 4,096-midpoint calculation.

![Different sampling rules, one unchanged curve](accumulation-rules.png)

The primary has moved into a position where both panels are visible. The existing walls and three secondary placements remain. Twenty-six desktop checks pass; the revised book and tutorial follow the one primary. Headset work is deferred. Next: Flow_Field, where the path through sampling addresses can depend on earlier updates.


## Compact Patterns ribbon galleries

[View the new walls and room layouts](compact-ribbons.html). The three ribbon halls now measure 25 x 25 m, 27 x 31 m and 31 x 49 m, reducing their floor areas by 53%, 75% and 83%. Continuous gallery walls and short returns frame the exhibits around clear central passages. All forty artifacts remain. Main encounters, the mirror and the runway retain full scale; selected supporting installations are smaller.

Layout and primary interaction probes pass after the move. Headset comfort, supporting controls and legibility remain for the walkthrough. The active research thread continues at Flow_Field.


## Change consolidated

[Two halls, all 23 artifacts](change-two-halls.html): rate, accumulation, net change and flow. Next: Forces; headset testing remains deferred.


## Timing machines after oscillation

[Twenty clocks and the receiver](timing-machines.html) now give phase differences and throughput mismatch their own hall. Two primary encounters, with discovery text and desktop evidence; headset review remains open.


## Change wishes and the next sequence

[From an arrow to a room that acts](vectors-forces-plan.html): four if_not_exist_create proposals are now placed in Change_Choreography, and the first VectorBasics encounter connects its editable arrow to two wall views. The plan follows the accumulating method across Vector and Forces applications.
