# A sphere in pink light

Ada study, 1 October 2026. One pale sphere, five pink spotlights and a fixed view. Made after Palle's supplied photograph of Sol LeWitt's *A sphere lit from the top, four sides, and all their combinations* (2004).

Open `project.godot` in the Godot 4.6 environment prepared in Day Zero. The project is independent of the museum and has no plugins or external assets. The main scene is `study.tscn`; its construction and controls are in `study.gd`.

## Look, then change one condition

The five switches operate lamps above, to the left, to the right, in front and behind the sphere. Their pink value, energy and positions stay fixed. The sphere's geometry and pale base colour stay fixed. Follow the edge of a shadow while switching a second lamp on.

**One switch at a time** visits every on/off setting, changing exactly one switch per step. **Next** takes a single step. The order uses Gray code; this is our investigation method, not LeWitt's original arrangement. There are 32 states including all five lamps off. A faint fixed neutral ambient contribution remains even when the lamps are off.

The spotlights retain their individual energy when more lamps are added. Total illumination is not normalized. This lets accumulation become visible. RGB light colours and the renderer's material and shading calculations are used; this is not a spectral or photographic reproduction.

Right-drag to look around, use the wheel to move closer, and use **Front view** to recover the comparison viewpoint. The recorded sheet keeps the camera fixed. The runtime lets the observer move.

## Is the pink on the body or in the light?

**Compare: pink material / white light** keeps the selected lamp positions and energies but gives the sphere the pink material and makes the lamps white. The floor keeps its original material. Compare what happens around the sphere. Return to the pale material and pink lamps with the same button.

This comparison deliberately changes two linked assignments; the main 32-state series changes only which lamps are on. The two procedures should not be mistaken for the same experiment. Neither is a colour-matched physical experiment: equal RGB numbers in an albedo field and a light field have different roles.

## In the spine

This belongs in **Color_Flashlight**, beside the existing lamps and faceted sphere, as a compact return to the earlier primitive. The sphere has already been built. The new question is what makes its surface appear as it does. A fixed comparison station could precede the rooms whose light changes around the visitor.

Point One's sun switch supplies the first dependency; Coordinates locates the lights; the Sphere chapter supplies the receiver; Arrays provides the comparison and enumeration. Here students can hold geometry still and vary illumination. The camera, spotlight setup, renderer and controls remain supplied apparatus, so they need not learn all of them at once.

The three new lines to read first are the assignment to `lamp.light_color`, the assignment to `sphere_material.albedo_color`, and `lights[i].visible` in `set_lights()`. Bit masks and Gray-code enumeration are optional later reading, not the first Colour lesson.

## Source and distinction

The [Sol LeWitt Prints Catalogue Raisonné](https://www.sollewittprints.org/artwork/lewitt-raisonne-2004-06/) documents the 2004 work as 28 inkjet prints. [Fraenkel Gallery](https://fraenkelgallery.com/exhibitions/sol-lweitt-photographic-works-1968-2004) describes the four-high, seven-wide arrangement. Our 32-state pink series does not claim to transcribe those 28 plates or explain the historical selection. The sphere, direct spotlights, sharp shadows, faint ambient fill and dark backdrop are our digital conditions.

## Verification and limits

Run `godot --path . --xr-mode off --script res://capture.gd` with a rendering window to produce the sheet, individual views, comparison pair and report under `captures/`. Eight checks pass in Godot 4.6: unique switch states, one-switch transitions including the return, image proportions, actual sheet contents, unchanged sphere/material/camera/light energies, distinct rendered images and reversible light/material comparison. The sheet is assembled from actual Godot renders inside Godot. An initial capture-format mismatch and aspect-ratio error were corrected before publication.

The pale sphere still casts shadows on the floor. Shadow-map receiving is disabled on this isolated convex sphere, whose light-facing side is computed from its normals; there are no other objects that should cast shadows onto it. This setting should be reconsidered if the scene gains occluders.

This is a standalone desktop study. It has not been placed in the museum, tested with a learner or run in a headset. Canonical maps and manuscripts are unchanged.


## Museum placement, 2 October 2026

The study now has an installed museum adapter and an application passage in the book. See the [current spine integration](../2026-10-02-studies-in-the-spine/index.html). This page preserves the earlier companion evidence.
