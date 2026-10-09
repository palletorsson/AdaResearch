# Two coordinates, one place for the hand

21 September 2026. The physical XY pad now moves across its own face, and the existing vector addition/subtraction console uses it directly. This continues the joystick pass with a position-setting encounter. A velocity-command demonstration remains a separate future task.

## Findings and repair

The preserved starting scene had three verified failures: the visible grip and grab target were separated, the two coordinates moved in the Y/Z plane behind an X/Y face, and the value was a floating Label3D. The root also used the scalar slider wrapper, which imposed one-axis constraints. In the vector console, extra geometry and a -90-degree rotation attempted to compensate; limits and starting values were assigned to the root although the relevant properties lived on the child, leaving the initial handles disconnected from the displayed vectors.

- `slider_plane.tscn` keeps its path and `SliderOrigin/InteractableSlider` child. The child still exposes its historical Y/Z metre limits, steps, default position, release rule and `slider_moved(Vector2)` signal. Its rest frame now maps those coordinates onto the face's X/Y directions. The scene limits are explicitly ±7 cm, fitting the 19 cm working surface and 4 cm knob. The backing is 22 × 29 cm; this is a deliberate footprint change.
- `slider_plane.gd` resolves the held handle in the stationary parent frame and preserves its world position when moving the constrained ancestor. A stationary hand no longer accumulates movement. The native pickup/release mechanism remains in use. Invalid hand-pose redirect stubs were removed; the native fallback grab is used, without a custom pose claim.
- `physical_xy_pad.gd` replaces the scalar wrapper. It provides signed normalized-position helpers, an explicit display-value scale, pointer ownership/cancellation, and a flat two-coordinate reading. The pointer bridges from the joystick pass are reused: despite their historical filenames they only forward events to the root. Plate, knob collider and grab proxy all forward input.
- The shared toy console removes the duplicate pad bezel/rotation workaround. It initializes and resynchronizes pads from their real operands, keeps controls alive while rebuilding the receiver, adds support blocks, and reduces centre spacing from 52 to 30 cm. Full-size pads stand at 1.06 m and tilt 50 degrees in front of the work.
- `vector_op_console.gd` opts into flat console printing and a viewport-backed monitor. Expression mode uses flat printed algebra too. Reconfiguration updates the operation heading as well as both pad values. Addition/subtraction, seed and workings variants retain their existing meanings.
- Other toy-console subclasses retain the legacy text contract for now. The new surface renderer is opt-in because some subclasses reposition or restyle their Label3D directly. This is a migration boundary, not a claim that their text meets the user's final standard.

The focused `commons/interactables/interactable_xy_demo.tscn` uses `InteractableDemo.gd` with `xy_reference=true` and instantiates the actual vector console. It is a reference artifact scene without its own player/camera. Existing sampler, audio-controller and component-gallery footprint declarations were updated. Their every assembled placement has not been tested.

## What is verified

**71 checks pass** through desktop Godot 4.6 Mobile, including:

- Real XR Tools pickup, constrained movement and release; tilted controls at yaw 0/90 degrees; no movement into the face; no drift while holding still; grip/grab alignment and idle processing.
- Real physics ray hits and XRToolsPointerEvent dispatch; agreement with hand directions; limits; optional steps and return behavior; competing and removed pointers.
- Initial operand/knob agreement, full control scale, front placement and compact spacing; actual grabs driving both operands at console yaw 0/180; the visible resultant endpoint and monitor agreeing with the arithmetic.
- Reconfiguration preserving controls and resynchronizing values; flat expression text; subtraction and the mounted pointer path.
- Four sibling consoles loading and constructing receivers with their retained text contracts: wedge_slide, dot_aligner, projection_shadow and circle_train. This is a construction regression, not an exhaustive input audit of those exhibits.

The final run contains no SCRIPT ERROR. The pre-existing unresolved UID warning remains. Before/after captures use the same cameras; the baseline was captured before editing, and source snapshots are preserved in `before/`. These are real Godot artifact renders, not a whole museum walk. Some captures include an existing project HUD from autoloads.

Known map context: the registry's `vector_add` and `vector_sub` use this script family. `Vectors_Act2_VectorArithmetic` contains `vector_add`; its `vector_sub` token has `lesson:room_gap`, which substitutes another encounter and is not certified by this console test. No maps, manuscripts or promoted artifacts were changed.

## Remaining evidence

Headset comfort, shorter/seated visitors, hand-pose fit, legibility on Quest, and Quest frame time remain untested. The geometry and synthetic input checks do not establish reach for a particular person. The console still rebuilds its receiver geometry after changes; this pass does not claim to solve its rendering cost. Resized museum placements and the large audio-control catalogue need their own operating-position review. The furniture support meshes are visual and do not add locomotion collision.

Next useful pass: inspect a real wheel/lever encounter and make clear whether its angle sets a position, commands speed or applies force. The remaining legacy toy-console text can migrate in those situated passes.

## Reproduce

```powershell
python doc/reports/interfaces-2026-09-21/xy-pad/run.py after
python doc/reports/interfaces-2026-09-21/xy-pad/publish_review.py
```

The before result is archived evidence from the pre-edit source. Running `run.py before` on the current checkout would replace it with current components; use the preserved source in a separate checkout if a fresh historical reproduction is needed.
