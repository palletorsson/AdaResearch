# Physical control, flat lettering

21 September 2026. User correction: “2D in 3D” meant text. The grammar station now defaults to a physical six-position slider in front of the work. This is a single-artifact pilot and a reusable helper, not a project-wide conversion.

## Implementation

- `commons/interactables/physical_stepped_slider.gd` supplies a raised, grabbable cap, an 18 cm track, six numbered positions and flat baked lettering. XR Tools' slider, handle and grab driver provide the underlying near-grab mechanics. Both direct grabbing and pointer dragging drive the same stepped state.
- The track corrects a parent/handle feedback problem: moving the track must preserve the held proxy's world position, or a stationary hand repeats the same offset on later frames. The local subclass also uses affine coordinate conversion. Addon sources are unchanged.
- `ArtifactControls.add_physical_stepped_slider` explicitly selects this physical implementation. Existing screen methods remain available. The grammar artifact's `use_physical_controls` defaults to true; false restores its screen version for comparison.
- The physical station uses unit scale for its physics nodes. Case and status-screen geometry retain the previous visual size. The station remains at local `(0, .86, 1.7)`, inclined -55 degrees, ahead of the three grammar forms. The selected depth also follows external artifact changes.
- Pointer ownership, exit, focus loss and pointer removal are handled. A near grab takes priority over a pointer drag. Released selection persists. Idle components do not run frame processing. Numbers, title, ticks and release label are static surface graphics; only the separate status screen uses a viewport.

These are visible discrete stops, not physical force feedback. No controller haptics or simulated resistance were added. The existing six-generation algorithm and provenance text are preserved.

## Evidence

Run `python doc/reports/interfaces-2026-09-21/physical-slider/run.py` for the 46-check physical test and captures. It calls the real XR Tools pickup/driver/release path using a generated grabber pose, moves through all six positions in both directions, checks stationary-hand stability, and casts physics rays into the actual collider before dispatching pointer events.

The complete selector range is tested on the isolated component. Real artifact tests cover generation one to two through both grab and pointer input: the first grammar changes from 5 to 25 segments, with its depth readout and cap aligned. Rendering the existing million-segment generation-six comparison repeatedly is outside this input test; Quest performance at that complexity remains a separate concern.

Run `python doc/reports/interfaces-2026-09-21/physical-slider/run_screen_regression.py` for 46 retained screen/helper checks. It copies the existing regression with private output paths, preserving earlier screenshots and reports.

Both final runs exit successfully. Known startup UID, certificate-store and shader-cache messages remain; final runs report no script errors. The first prototype had a grab-feedback failure that the bidirectional tests caught; the final checks pass after correction.

The four captures compare both implementations at generation two with identical camera positions. Close view: `(0.35, 1.60, 2.15)`. Operating view: `(0, 1.65, 2.1)`. Both use the real artifact in a test scene. They are not museum-hall or headset captures. Physical reach, tracked-hand/controller comfort, haptic choices and Quest performance remain unverified.

Next: try the physical station in the headset, and migrate the next actual control family using the same distinction between moving 3D geometry and flat text.
