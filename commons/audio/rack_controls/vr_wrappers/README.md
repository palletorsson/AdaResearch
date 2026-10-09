# VR rack surfaces

- `VRRackControl.gd` renders one canonical 2D control inside a 3D case. Interactive controls receive pointer events through a screen-sized collider. It does not create a physical grab handle. `pointer_enabled = false` disables this route; meters, labels, dividers and groups have no pointer collider.
- `ModuleFaceTexture.gd` lays out several controls on one module face and forwards their input to the audio controller when configured.
- `rack_pointer_surface.gd` is their shared world-hit → viewport GUI bridge. A drag belongs to the pointer that began it. Release, exit, focus loss or a freed pointer releases the GUI control. It processes frames only while pressed.
- `VRFacePlate.gd` renders a visual plate behind a separate physical interactable; the physical mechanism drives that plate. Its render role should not be confused with the pointer surface.

Wrapper pixels scale the entire canonical drawing, including its text. The hit box follows the actual inset screen (92% of the case dimensions), including parent rotation and scale. Values and labels set before tree entry survive construction; step counts are applied before discrete initial values are quantized.

The bridge supplies input transport, not missing control behaviour. Each inner control must implement its own GUI handlers. [46 wrapper/consumer checks and 43 module regression checks](../../../../doc/reports/interfaces-2026-09-20/rack-wrapper-pilot/README.md) cover the tested slider and button paths. Desktop automation is not evidence of headset reach, tracked-hand grabbing, or Quest performance.
