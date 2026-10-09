# QFEP console: fit the housing to the controls

20 September 2026. Continued from the Foundry compact-panel pilot, preserving the QFEP Introduction review's four-quantity arithmetic and KEEP comparison.

The original workbench's cabinet shrank every control to 30.27% scale. The optional `compact` argument to `InterfacePresets.build()` wraps at three columns with 0.22 m base slots; `ControlConsole.fit_controls` fits its casing around the panel. A slider keeps its authored 14 cm travel. The profile is selected by QFEP Balance; default console callers keep their current fitting policy.

Compact panel faders also replace their visible Label3D value with a 128×48 2D Label rendered to a small QuadMesh on the existing frame. The viewport redraws only when the formatted value changes. Existing parameter ranges, formatting and signals remain. The hidden original value label remains a compatibility sink; dial/joystick values and other project captions still need migration.

## Verification

- `console-checks.json`: 132 passing checks across legacy/compact and kiosk/lectern/wall mounting. Includes backing extents, unchanged control scale, 14 cm slider travel, forward/backward pointer motion, KEEP events, current 2D values and signed range formatting. Events call the actual pointer handlers; this is not tracked-hand evidence.
- `before/runtime/report.json` and `after/runtime/report.json`: the existing introduction review's 21 encounter checks and five selected CharacterBody walks pass. This preserves equal totals with different tuples, zero-lambda behaviour, retained outlines, configuration rebuilds and secondary works.
- Matched actual museum renders: same two camera poses and same two input tuples, with the original tuple retained. `run_pilot.py` copies current museum code into private output folders rather than replacing the running museum's bake or inventory.
- The first new formatting assertion expected trailing zeros that the existing formatter does not produce. The test was corrected to check its existing output and numerical value; formatting behaviour was preserved.
- Final runtime logs retain the known UID/certificate, shader-cache and unrelated scene warnings. These runs are not a warning-free whole-project certification.

The larger casing makes full-size controls possible. It still needs headset, seated-reach and Quest performance checks; the lower row and the neighbouring detail screen are specific things to inspect. The new compact layout does not certify every placement of the artifact. `placements.json` lists ten map-file placements, including trial layouts, and only QFEP Introduction received the museum walk/capture pass here.

## Source boundaries

Changed shared console sizing, the preset's optional layout, compact slider value rendering and the QFEP Balance preset call. No manuscript, map configuration, calculation, input ranges or KEEP semantics were edited. Explicit caller scaling such as an authored `plate_scale` remains a caller decision and can still change world dimensions.

Evidence and [before/after page](../../../book/iterations/2026-09-20-interface-console-review/index.html) make this one reusable implementation plus one verified museum placement. Next: check the interactive demo and dial/joystick value surfaces, then examine large neighbouring screens from the operating position.
