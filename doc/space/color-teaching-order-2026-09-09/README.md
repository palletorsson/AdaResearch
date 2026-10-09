# Colour: teaching order and drafting readiness

Applied 9 September 2026. The nine historical rooms remain; their order now follows an investigation rather than the recovered chronology. Prior sequence, plans and edited manuscripts are archived under `before/`.

| Room | Question to carry | Implementation to ground it | Manuscript |
|---|---|---|---|
| Color_Context_Placed | What changes when a colour gets different neighbours? | The specific warm Albers composition and its surroundings | Draft exists |
| Color_Flashlight | What does a surface receive when the lamp moves? | Four coloured SpotLight3D sources and the receiving canvas | To write |
| Color_Nails | What changes when a colour becomes a coordinate I can choose for my body? | RGB controller position, preview, available hand/nail material targets | Draft exists |
| Color_Rainbow | Which decisions make this order recognisable as a rainbow? | Authored ROYGBIV array, arc geometry, secondary reversed bands | To write |
| Color_Pillar | Where is the colour between the samples? | Shared HSV field on the floor and 35 discrete pillars; named palette wall | Draft exists |
| Color_Grid_Pallet | What can an address make a colour do? | GridColorMutator evaluates palette/gradient rules and writes MultiMesh instance colours | To write |
| Color_Paint | What has already happened while I was looking elsewhere? | Two oscillations, rate-limited strokes, the shared wet-paint surface and manual pigment | Draft exists |
| Color_Walls | Which views continue where the body has to turn? | Orthogonal glass cubicles, alpha compositing, separate coordinate and interpolation artifacts | Draft exists |
| Chamber_Color | What remains after an action, and which operation produced each change? | Random chromatic projectiles; impact recolours, transforms grid instances and emits small cubes | To write |

## Enough to write

Yes: a complete first draft can be written against the current material. Do not postpone it for more collection building. The existing five drafts need connective editing; four manuscripts remain to write. The sequence's truth and learning objectives now describe this particular implementation instead of calling RGB a lie or claiming every room simulates colour physics.

Use the oscillating voice already agreed: encounter a difference, make a small prediction or gesture, observe, open a short piece of actual code, then return to what the implementation has left unresolved. A critical paragraph should arise from the particular operation, not be attached as a general verdict.

## Specific cautions for the writing pass

- Flashlight: the current placement uses the white receiving canvas. The source also supports swatch, relief, mirror and none, but those are not visitor controls in this room. Do not instruct the reader to switch between them. A swatch comparison is an optional later addition.
- Rainbow: the current source builds chosen coloured arc bands. Older tutorial material describes wavelength conversion and repeated animated emitters; neither describes the current principal placement. The room is especially useful for showing the difference between a convincing appearance and the process it seems to represent.
- Grid: the colourizer applies named palette and gradient rules, automatically cycling by default. It is not a hand-paint-each-tile interface. Use the implementation in `commons/grid/mutators/grid_color_mutator.gd`, not the obsolete interface claims in the old summary.
- Chamber: `start_mode:chromatic` unlocked the mode but did not select it. The placement now also declares `active_mode:chromatic`; the runtime probe confirms selection. A chromatic impact changes both colour and visual geometry, so the text must account for those changes separately. Inspect contact/collision behaviour before making claims about changed traversability; the inspected impact routine mutates render-instance transforms.

These are grounds for accurate drafting and a focused walkthrough, not reasons to expand the room inventory before writing.

## Verification

Order agrees across the colour sequence, book navigation, map-authored ownership and both museum plans, including the runtime pearl indices. The spine, long-museum and necklace indices were regenerated. Thirty Python tests and twelve chamber runtime checks passed. The existing unrelated Tutorial_Disco ragged-layer warning still appears in the global index tools; that map was not edited. No headset walkthrough or completed manuscript is claimed.
