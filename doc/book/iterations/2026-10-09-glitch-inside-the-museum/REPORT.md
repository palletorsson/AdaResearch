# Glitch inside the Endless Museum

**Installed in Godot: Shaders → Patterns (`Shader_05_Patterns`).** Walk past the image instrument and pattern garden, through the former far doorway, into the new model gallery. Turn the dials on the console to change the architecture in front of you. The next portal continues to Queer Materials.

![Live Godot model and console inside the actual museum](museum/gallery.png)

The previous delivery left the studies in a standalone Godot courtyard and offered a Three.js viewer of saved meshes. That missed the requested setting. The same generator now runs as an artifact in the actual Endless Museum map. The browser viewer remains an optional inspection of saved states.

## Enter the actual museum

Open `res://commons/artifacts/model_disagreement/museum.tscn` in Godot and press **F6**. This scene instances the existing Endless Museum and selects the Shaders chapter and Patterns hall; it does not recreate a separate room. You can also choose Patterns through the normal museum controls. An already running session needs to reload the hall to pick up the changes.

In VR, press the rectangular buttons and grip the dials. **SOURCE** shows the original; **PRECISION**, **CLOCKS** and **FEEDBACK** choose the operation. **CONDITION** changes its amount, **STEPS** selects the iteration or logical time. **CONTROL** shows the corrected comparison. **PLAY / HOLD**, **STEP** and **RESET** stay on the same panel. Reset returns steps to zero and stops play; it retains the condition setting.

![Native console inside the hall](museum/console.png)

## Three operations on one retained object

| Study | What changes | What CONTROL restores |
|---|---|---|
| Precision | Coordinates pass through actual float32 storage at a large numerical offset, then return to local display. | Local coordinates retain the detail. The player stays near the museum's local origin. |
| Clocks | Eight parts read the same pose function at deliberately different times. | All parts read one shared time. This is authored timestamp skew, not a renderer race. |
| Feedback | Each deformation receives the previous result as input. The upper structure grows and leans. | The operation reads the original, so one change does not accumulate. |

![Precision: coordinate detail lost](museum/precision.png)

![Precision: local-coordinate control](museum/precision-control.png)

![Clocks: parts sampled at different moments](museum/clocks.png)

![Clocks: shared-time control](museum/clocks-control.png)

![Feedback: the output becomes the next input](museum/feedback.png)

![Feedback: read the original each time](museum/feedback-control.png)

The miniature original remains on its plinth. Only the large display mesh is scaled to 35% so even the bounded extreme states stay inside the gallery. The console and hand controls keep their native dimensions. Values on the instrument are still **model metres**, as its label states. These are visual geometry studies: the floor supports the visitor, and the deforming mesh has no changing collision.

## The arrangement

The five earlier artifacts keep their cells and orientations. The previous 21 × 31 map now has a 37 × 62 bounding grid: its narrow front rooms remain, and the rear expands for the new study. The old exit becomes a passage; the onward portal moves to the far wall. The existing museum generates the floor, walls, sky and route.

![Whole hall from above, including the earlier image studies and new model gallery](museum/above.png)

The entrance was also corrected. A corner spawn had required the museum's fallback landing. It now aligns with a three-cell opening. Widening the back room exposed an automatic check-in wall whose door was placed outside the narrow front room; that extra wall is disabled for this hall. Portal navigation remains in place.

![Passage from the image gallery into the model gallery](museum/connection.png)

## Native checks

**{{CHECKS}} checks pass in the actual museum loader.** They verify all six installed artifacts, map configuration, unit-size controls, each study and corrected control, real desktop pointer presses, play/hold/reset, source preservation, and the XRTools pickup/hinge/release path using synthetic controller poses. Sampled extremes stay inside the gallery. The entrance route is found around existing colliders; the onward route has {{SAMPLES}} supported capsule samples. The far portal targets `Shader_11_QueerRubber`.

All pictures here are Godot captures of the installed room. Comparison images use the same camera and restored museum lighting; the temporary test player's fog is removed. The first expanded entrance-route check failed on the check-in wall, leading to the access correction above. Failed receipts remain in the probe's attempt folders.

This is native desktop and simulated-controller validation. Physical headset use, Quest performance and a headset export remain untested. Existing unrelated project warnings remain in the log. No tutorial or reflective chapter was rewritten for this installation.

[Native test receipt](validation/report.json) · [Engine log](validation/engine.log) · [Placement audit](validation/placement.json) · [Source hashes](validation/source-hashes.json) · [Artifact source](source/model_disagreement.gd)

[Earlier research and exact mechanisms](../2026-10-09-when-parts-stop-agreeing/index.html)
