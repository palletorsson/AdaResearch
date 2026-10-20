# One arcade, four operations

<!-- museum-placement:start -->
## Museum placement

**Preview only — not placed in the museum.** Separate Godot preview scene and web review only.

[Placement overview](/book-review/doc/book/iterations/2026-10-09-one-arcade-four-operations/placement.html). Checked against map placements and current route configuration; this is not a new headset test.

<!-- museum-placement:end -->

The previous corridor becomes a curved court, a hinged curl, a repeated field and a stretched canopy. All four studies reuse its actual bay constructor. A fixed miniature keeps the original visible.

**[Open the interactive 3D viewer](/research/architecture-variations/index.html#stretch)** — orbit, zoom, compare viewpoints and inspect the wireframe. The browser displays actual geometry exported from Godot; use the Godot scene for live parameters and grabbing.

![The roof becomes a canopy in the Godot courtyard.](museum/stretch-ground.png)

## 00 / The familiar assembly

Twelve upright bays repeat the original floor, columns, roof, rails and pink guide. The miniature beside the console retains eight bays at one quarter scale. The active object has a 4–24 bay control.

![The source and fixed reference.](museum/source.png)

## 01 / A curved court

A longitudinal position becomes an angle. Height stays unchanged. Width affects the circumference, so this is a deformation, not a chain of rigid rotated boxes. At the default eighteen bays, an ordinary passage nearly closes around a courtyard.

![The curved court seen from above eye level.](museum/curve.png)

<details><summary>Stand inside the curve</summary>

![The curved arcade at eye level.](museum/curve-inside.png)

</details>

## 02 / A moving centre

Here the bays remain rigid. Their shared hinge is near the roof, and the floors separate as the chain turns. Move the pink point down: the angles remain unchanged, but the whole assembly takes another position. At some settings roofs intersect. A valid joint transformation is not evidence of a habitable route.

![Rigid bays fold around high hinges.](museum/hinge.png)

<details><summary>The same angles with floor hinges</summary>

![Moving the centres changes the arrangement.](museum/hinge-floor.png)

</details>

## 03 / The repeated field

Eighteen bays, three rows, two tiers: 108 copies sharing one mesh. A single local decision becomes a large spatial order. CHANGE adds rows and tiers; BAYS changes the longitudinal count. This finite array does not simulate an infinite world.

![A bounded field of 108 bays.](museum/field.png)

<details><summary>The field at ground level</summary>

![Repetition viewed from below.](museum/field-ground.png)

</details>

## 04 / The stretched roof

A weighted displacement pulls the sampled roof and upper columns. Influence falls to zero away from the attachment and at ground level. Floor contact positions stay fixed while the upper assembly becomes a canopy. It retains its triangle count; it is not simulated fabric, damage, or a reconstructed game-engine fault.

![One attachment creates a canopy.](museum/stretch.png)

This is the strongest connection to the supplied game screenshots: a surface that exceeds its intended dimensions starts to suggest another architectural use. The source remains recognisable inside the strange result.

## In your hands

![Native dials, rectangular buttons and the shared pink grab point.](museum/console.png)

Run `res://commons/artifacts/architecture_variations/preview.tscn` with F6 in the Ada project. The standalone courtyard uses the existing desktop player. Aim/click presets, drag CHANGE or BAYS, and drag the pink point for Hinge or Stretch. Keys 1–5 select studies; left/right change strength; up/down change count; R restores Source. The same handle supports XRTools grip when used with an XR rig; this standalone preview spawns the desktop player.

## What this suggests for the research

These are our experiments in relation to the references, not reconstructions of their works. Borromini helps us look at geometric enclosure; Hadid and Gehry at deliberate formal invention and its realisation; Daniel Brown at exploring generative worlds; Superstudio at the reach of a repeated order. Escher opens a separate question about orientation that these four studies do not yet implement. Bacon and Bellmer make the body and its supporting or manipulating frame part of the inquiry.

- [Borromini / San Carlino](https://sancarlino.ch/espacios/the-church/)
- [Zaha Hadid / MAXXI](https://www.maxxi.art/wp-content/uploads/2017/06/MAXXI_ZahaHadid_PR.pdf)
- [Gehry / Guggenheim Bilbao construction](https://www.guggenheim-bilbao.eus/en/the-building/the-construction)
- [Daniel Brown / generative architecture](https://danielbrowns.com/)
- [Superstudio / The Continuous Monument](https://www.moma.org/collection/works/936)
- [Escher / Relativity](https://escherinhetpaleis.nl/en/about-escher/masterpieces/relativity)
- [Bacon / curator discussion of Invisible Rooms](https://www.sothebys.com/en/articles/francis-bacon-invisible-rooms-oliver-barker-in-conversation-with-dr-ina-conzen)
- [Bellmer / The Doll](https://www.moma.org/collection/works/43944)

## Room and evidence

![The research courtyard from above.](museum/above.png)

**35 native checks pass.** These cover curve radius and height, hinge coincidence, rigid lengths, repetition, bounded deformation, unchanged ground points, triangle count, preserved source/reference, exact reset, native dials, real desktop button rays, supplied XRTools controller poses and six native GLB exports. [Receipt](validation/report.json) · [Engine log](validation/native.log) · [Run instructions](source/README.md).

The changing architecture has no colliders: the fixed courtyard floor supplies walking support. These are visual research models, not structurally validated or climbable buildings. No physical headset or Quest performance run was performed. The log retains existing project UID and Jolt warnings. This is a separate museum-style research courtyard; no spine placement, canonical tutorial or final text has been changed.
