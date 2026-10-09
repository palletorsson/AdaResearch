# Scalar controls: the slot and the hand agree

The inclined component library now exercises repaired production sliders and dials. This pass includes the user's report of min/max overflow and sideways movement in vertical controls.

## Changes

- `linear_driver.gd` preserves XRTools metre limits, detents, signals and release defaults. It solves held offsets in local coordinates and preserves the hand's world position after the joint moves. The old wrapper clamps no longer compete with the grab driver.
- The legacy Y-axis driver gets the same stationary-hand correction. Its authored library scene now has ±0.07 m travel inside its 0.22 m plate, instead of a ±0.2 m range offset below that plate. Its automatic motion works and yields to both a hand and a pointer.
- Horizontal audio travel is centred on the slot. The vertical audio fader uses a rotated X-axis driver: upward travel increases the value. Its broad grip retains a horizontal orientation. Normalized setters remain silent for compatibility, but clamp and display the actual resulting value.
- Both dial families use the already tested angular driver. The audio dial now rotates in its face plane and its grab ring sits on the knob. The audio wrapper inherits the shared range/readout implementation.
- `scalar_pointer.gd` gives these families local-coordinate pointer motion, one pointer owner, hand precedence, fractional motion across detents, release/exit/focus/lost-pointer handling, and idle processing when unused. Returning variants keep their release distinction.
- Visible slider grips live on the constrained joint, while the invisible pickup proxy follows the hand. The audio controller's custom-skin hide list includes the new visual path. Public scene IDs, signal names, normalized APIs, logical ranges and node paths to drivers/pickup handles remain available.
- Invalid grab redirects without a target are removed. Axis and stepped panels use explicit cream materials. The axis cap is horizontal. Library captions say “AUTO / HAND” and “RETURN TO CENTRE”. A support bracket replaces the stem protruding through the desk.
- Text in the library remains flat surfaces. Legacy Label3D nodes remain hidden compatibility sinks; this pass does not claim all project text has been migrated.

## Evidence

1. `python doc/reports/interfaces-2026-09-21/scalar-controls/run.py after`: **471 checks pass**, no script errors. Real production library, native XRTools pickup and real collision-ray pointer dispatch. Both directions, two hall yaws with a 35-degree console inclination, hard stops, grip containment, correct axis, still-hand stability, automatic/manual handover, ownership, return behavior, lost pointer, chooser options and displayed bounds.
2. `python doc/reports/interfaces-2026-09-21/console-placement/run.py after`: **173 checks pass**, no script errors. All eleven pages, twenty-eight placements, current dimensions, paging guards, flat text and audio resource lifetime. Repeated after the final support-bracket change.
3. Existing `commons/testing/test_sliders.gd`: **12 checks pass**, zero failures. Updated the obsolete private-clamp assertion to real pickup in the actual ControlPanel mixer. Normalized values round-trip and native grabs move both ways.
4. `commons/testing/capture_scalar_endpoints.gd`: current Godot images at minimum and maximum; no script errors. Rendering uses desktop Vulkan Mobile and Dummy audio. These are the actual components, not mock-ups.

Existing engine diagnostics include an unresolved `uid://rwex60pqapc` and unassigned viewport textures during library loading. They are not represented as a clean whole-project run. No headset, seated reach, listening, or standalone Quest performance validation has occurred.

The archived baseline exposed missing ray paths and unstable legacy grabs. Its harness also encountered automatic handle drops, so its check count is diagnostic, not a comparable clean pass/fail score. The archived source and original images remain available.

## Placement finding

`python doc/reports/interfaces-2026-09-21/scalar-controls/run_hall.py library after` did **not** load Gallery_Furniture. That map belongs to the storage-gallery sequence, outside the current museum plan/spine. The builder fell back to Point_One. Its floor token therefore cannot be treated as proof that the library has a reachable place in the endless museum.

This pass does not change the museum route or add another object to Point_One. The radio there remains the previously placed secondary testing object. The next spatial task is to give the component library an intentional test-room entry, then measure its full approach and reach there. The failed isolated probe is retained as evidence, not published as a successful hall capture.

## Next

Test the library through a reachable test-room entry; then audit compact mixed-control racks under their actual authored rotations and skins. VR hand feel and comfortable reach remain a separate check when the headset is available.
