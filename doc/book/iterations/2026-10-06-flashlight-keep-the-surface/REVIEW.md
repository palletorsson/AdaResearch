# Flashlight — keep the surface

Colour lesson 2 of 8. A pale board keeps its material while two spotlights contribute colour. The learner changes one lamp's value, aims it across the other beam, then aims it away.

The previous lesson assigned a palette to five familiar parts. This one returns to the same BoxMesh and material construction, with one shallow box as the receiving board. The selected new operation is light colour and aim; the museum's existing grabbable handles supply the embodied encounter.

## Read

- [Tutorial beside the existing reflection](parallel.html)
- [Tutorial alone](tutorial.html) · [tutorial.md](tutorial.md)
- [Reflection alone](final.html) · [final.md](final.md)
- [Complete program](lesson.gd) · [Code and tests](flashlight-review.zip)
- [Verification](verification.json) · [Native checks](normal-report.json) · [Render checks](render-report.json)
- [Previous: Colour — the same parts](../2026-10-06-colour-the-same-parts/parallel.html)

## The comparison

| Keep | Change | Observe |
|---|---|---|
| Board, material, light positions and aim | First light red → blue | One pool changes; the other stays green |
| Board, material, positions and light colours | Aim the red light at the green pool | Contributions overlap |
| Board, material, positions and light colours | Aim red away from the board | Its contribution leaves; green remains |

One complete program creates its own board, material and lights. The museum supplies camera, movement and room illumination. The reduced code does not create another grabbing system or automatically control an installed flashlight. The construction is explicit, and the student knows which interaction is supplied.

## What the two texts do

The tutorial makes a small relation executable and gives three exact edits plus an independent target choice. The unchanged reflection follows the handheld lamps, faceted sphere, white room, light well and pink sphere. Their wider experiences need not become additional coding requirements here.

Colour remains the subject. Local/world coordinates and rotation return to aim a light. The example adds no timer, input action, spectral model, class framework or colour picker.

## Evidence

Native checks extract the exact code printed in tutorial.md. They inspect real Godot nodes, materials and orientations under a translated and rotated host; test the printed edits; and verify that live light edits preserve the receiver and the other lamp. Deliberate faults check whether these assertions detect wrong ownership, omitted coordinate conversion, reversed aim and a disabled light.

A separate GPU fixture renders the exact variants with a fixed camera and modest ambient light. It checks channel changes, overlap and withdrawal through small sampled image regions. These comparisons validate the selected behaviour under stated rendering conditions, not a calibrated colour appearance or headset experience.

## Status and carry

Review draft. Canonical tutorial.md, final.md, installed artifacts, map, sequence and acceptance status remain unchanged. The lesson carries two named receivers of a Color value—surface albedo and light colour—and the ability to aim a light at a position.

Next: Nails, where the carried hand point supplies a colour for a surface. Six Colour tutorials remain after this draft.
