# The console, close up

20 September 2026. Refinement of the compact QFEP console, with a second working receiver to test whether its design can be reused.

## What changed

- `InterfacePresets.build(..., "braun", "instrument")` selects a full-size console with grouped control wells, medium-weight printed labels, a slim 18 mm casing margin and four flush plate fasteners. It retains three columns by default; the reference uses two. Select this construction profile before adding controls. Existing legacy callers retain their layout, and non-console housing forms retain their own contract.
- The QFEP workbench adopts that profile. Its four quantities, ranges, KEEP comparison, manuscript and map remain intact. The head is shorter because the extra top border is gone and the control rows are closer. Controls and their physical travel remain unscaled.
- Compact and instrument faders and dials now share `control_value_surface.gd`: 240×80 2D Labels rendered on 78×26 mm QuadMeshes with backing. A value change requests one redraw. The fader backing extends above the handle's swept area so the larger number cannot be covered at the minimum position. Old Label3D values remain hidden compatibility sinks. Other standalone control variants still need migration.
- `InteractableDemo.reference_console` selects a focused live example while preserving the complete sampler as the default. `interactable_console_demo.tscn` enables it. The shared example uses a slider to scale a specimen, a dial to rotate it, a joystick to position it and RESET to restore all three. The two axes appear in the shared 2D summary display; the joystick's physical geometry stays unchanged.

## Verification

- 132 legacy/compact console regression checks pass: three mounting forms, casing coverage, scale, 14 cm fader travel, forward/back pointer drag, KEEP input and logical value formatting.
- 70 shared panel row checks pass, including pointer events, layout and a backed readout with no controls.
- 46 new reference checks pass across Braun and Black Mesa finishes: two-column mixed controls, unscaled geometry, casing fit, actual slider/dial pointer paths changing the specimen, joystick signals moving it, RESET, value surfaces and fader-window clearance.
- QFEP Introduction's existing 21 encounter checks and five selected collision-body walks pass in private before/after museum snapshots. Both zoomed captures use the same camera pose, 42-degree field of view and comparison values.
- Actual desktop renders were visually inspected. The initial reference stage obscured its readout; it was raised and moved back. Tests of control values alone had not caught that spatial problem.

These are desktop and direct-handler checks, not tracked-hand or Quest performance measurements. Seated reach and headset legibility remain to be tested. QFEP Introduction is the checked museum placement; other placements of the same workbench still need inspection. Logs retain pre-existing UID/certificate, shader cache and unrelated synthesis viewport warnings.

## Review and repeat

- Review URL: `/book-review/doc/book/iterations/2026-09-20-interface-finish-review/index.html`
- Run `python doc/reports/interfaces-2026-09-20/console-finish/run_pilot.py after` for the actual QFEP museum capture and semantic checks. It writes privately, without replacing the live museum bake.
- Run Godot with `--xr-mode off --script res://commons/testing/test_instrument_console.gd` using a desktop renderer for reference checks and pictures.
- `regression.gd` and `layout-regression.gd` are copies of existing regression scripts with private report paths, preserving earlier reports.
- Run `python doc/reports/interfaces-2026-09-20/console-finish/publish_review.py` after verification to publish the local review, exact changes and source hashes.

The profile is a reusable option, not an automatic project-wide replacement. For each next console, preserve its meaningful actions, select a column count, inspect from the operating position and check the visible receiver along with the controls.
