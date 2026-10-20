# The corridor has a spine

<!-- museum-placement:start -->
## Museum placement

**Preview only — not placed in the museum.** Separate Godot preview scene and web review only.

[Placement overview](/book-review/doc/book/iterations/2026-10-09-one-arcade-four-operations/placement.html). Checked against map placements and current route configuration; this is not a new headset test.

<!-- museum-placement:end -->

A corridor is a body with expectations attached. A floor should carry us, a railing should keep an edge, and the next doorway should lead somewhere. These expectations make architecture a useful next step after the procedural creature: a small change in a transform can change what a familiar structure allows us to do.

We built an **interactive Godot research model**: eight architectural bays, each with a floor, columns, roof and balustrades. They remain the same parts as the assembly folds, separates and changes scale. This is in a separate museum review room. It has not replaced a hall or changed the book's teaching order.

<figure><a href="museum/fold-roof.png"><img src="museum/fold-roof.png" alt="An arcade curls into a tall architectural spine, with pink hinges at its roofs." /></a><figcaption>Native Godot capture. The same eight bays rotate around roof-height hinges. A roof connection survives while the floor route breaks.</figcaption></figure>

## One set of parts, five readings

<div class="pair"><figure><img src="museum/passage.png" alt="Eight bays in a straight arcade." loading="lazy"/><figcaption>PASSAGE. An ordinary repeated corridor establishes what the structure is expected to do.</figcaption></figure><figure><img src="museum/fold-floor.png" alt="Bays fold upward about floor hinges; the roofs intersect." loading="lazy"/><figcaption>FOLD. The floor hinges remain connected. Roofs intersect. The transform passes its test; the building fails another requirement.</figcaption></figure></div>

<details><summary>Move the hinges to the roof</summary><figure><img src="museum/fold-roof.png" alt="The folded arcade with roof-height hinges." loading="lazy"/><figcaption>The angles and parts stay the same. Changing the centre changes the resulting structure.</figcaption></figure></details>
<details><summary>Separate the bays</summary><figure><img src="museum/separated.png" alt="The same architectural bays form a displaced ascending assembly." loading="lazy"/><figcaption>SLIP introduces alternating local offsets. It deliberately breaks the shared hinge positions.</figcaption></figure></details>
<details><summary>Repeat a scale ratio</summary><figure><img src="museum/diminishing.png" alt="Each architectural bay is smaller than the preceding bay." loading="lazy"/><figcaption>EACH BAY at 0.9 compounds through the hierarchy. Bay eight is 0.9⁷ of bay one. The hinge centre remains shared; matching widths do not.</figcaption></figure></details>
<details><summary>Hinge detail</summary><figure><img src="museum/hinge-detail.png" alt="Close view of the architectural hinge and floor gap." loading="lazy"/><figcaption>A pink axis identifies the chosen attachment. A gap elsewhere is a consequence of that choice.</figcaption></figure></details>
<details><summary>Controls and room from above</summary><figure><img src="museum/control.png" alt="Three dials, four nearby rectangular buttons and a pink handle." loading="lazy"/><figcaption>BEND / JOINT, SEPARATE, EACH BAY. Lift the pink point to move the hinges between floor and roof.</figcaption></figure><figure><img src="museum/above.png" alt="Overhead view of the architecture research room and observation area." loading="lazy"/><figcaption>The fixed stage retains the original footprints. The player stands outside the moving model.</figcaption></figure></details>

## What game architecture contributes

These are references for different operations, not claims about a shared implementation. The Ada proposals below are our own translations of them.

| Game reference | What the source establishes | An Ada experiment to develop |
| --- | --- | --- |
| **Dishonored 2: Clockwork Mansion** | Levers initiate architectural transformations. Its designers kept sightlines and familiar room functions legible while spaces moved. | **The room behind the room.** Pull one handle: a wall rotates, a stair unfolds, a balcony becomes reachable. Expose the mechanism and retain a visible starting doorway. |
| **Manifold Garden** | Architecture repeats; changing gravity permits movement on different surfaces. Falling can return the player to the starting region. | **Six possible floors.** Keep one small room fixed; choose which face supports a test ball. A later version could carry the player once its movement is tested. |
| **Monument Valley** | The developers treat impossible architecture, navigation and wall walking as explicit design problems. | **The bridge from one place.** Pieces line up through a fixed inspection camera. Step aside and the gap becomes apparent. A convincing image alone does not establish a usable bridge. |
| **Antichamber** | Its creator describes hallways that wrap around and spaces that reconfigure. | **The door that changes its neighbour.** Keep the doorway and its appearance, but change the room it connects to. Show the adjacency change on a small map. |

Sources: [Clockwork Mansion — first-person account by Arkane's level design director](https://www.gamedeveloper.com/design/level-design-deep-dive-i-dishonored-2-s-i-clockwork-mansion); [Manifold Garden — studio press kit](https://manifold.garden/presskit/); [Monument Valley — developer's making-of announcement](https://monumentvalleygame.squarespace.com/blog/2014/5/9/how-we-made-monument-valley-what-do-you-want-to-know-1); [Antichamber — developer/publisher description](https://store.steampowered.com/app/219890/Antichamber/). Read 9 October 2026. No external game assets were copied.

Our current corridor explores the first family: ordinary transforms acting on a hierarchy. It has no portal topology, viewpoint-based connectivity or altered gravity. Those require their own implementations and tests. A folded building can look impossible while remaining ordinary Euclidean geometry with intersecting parts.

## What we already have in Ada

The project contains an **Escher Room**, **Impossible Geometry**, **Folding Menagerie Room**, and an **Architecture lesson**. Their source files provide leads for later reuse. The older folding creatures already use panel pivots; the new corridor gives an architectural assembly explicit parent-child joints and tests their connections. Existing impossible-space scripts should be audited before relying on their names as evidence of working portal navigation. The Architecture lesson belongs to ongoing work elsewhere and was left intact.

This creates a clear teaching connection: **cube → transform → repeated bay → hierarchy → changed connection**. The tutorial can teach the parent frame and pivot through one small assembly. The reflection can ask what the resulting architecture permits. A transform being valid, a hinge being connected, a passage being walkable and a building supporting weight are four separate claims.

> The doorway keeps its shape. The railing still names an edge. Nothing has disappeared, yet the way through has gone. Which part of the building did we think was holding the promise?

## Try the working study

Open `commons/artifacts/architecture_spine/preview.tscn` in Godot and press F6. The supplied desktop player can use the console. The pink handle also uses XRTools pickup; its 0.65 metre travel controls a hinge height of 0–2.6 metres. All controls are grouped at one position. RESET restores the original assembly.

The registry lookup is `architecture_spine`, marked **research prototype** and **not map-ready**. The moving bays have no collision or navigation. The fixed room, stage and console do. A low rail identifies the observation position; it is not a sealed barrier. This is a manipulable spatial model, not a released walkable game level. Strong folding can intersect pieces; some parameter combinations can cross the stage. These results are visible consequences, not a structural simulation.

## Evidence

**27 checks pass in Godot 4.6**, exit 0. The native probe checks the eight-joint hierarchy, retained source parts, rigid rotation, shared hinge coordinates, floor gaps, deliberate separation, compounded scale, full reset, handle bounds, actual desktop ray/button input and simulated XRTools grip, movement and release. No physical headset, structural physics or moving-platform traversal has been tested. The capture log retains a pre-existing unrelated UID warning. Ecosystem modulation was disabled for comparison lighting.

[Read the native receipt](validation/report.json), [test log](validation/native.log), [source guide](source/README.md), or [source hashes](source/manifest.json). All images here are native renders of the new Godot study.

## The next useful experiment

Make **one stair that becomes a bridge**, operated by one nearby handle, with matching moving colliders and two verified traversable states. Preserve a stable reference doorway. That would turn this visual study into an embodied test of access: the same parts become another route, and the player can prove it by crossing.
