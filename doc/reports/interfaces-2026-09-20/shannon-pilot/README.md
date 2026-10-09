# Shannon: a source and a choice

20 September 2026. Continuation of the console finish pilot, adopting the shared instrument profile in the actual QFEP F Term hall.

## Implemented

- Shannon's slider and two optional EXPECT buttons retain their authored scale. The measured study console previously scaled them to 56.99%, reducing 14 cm rail travel to about 8 cm. The cabinet now fits the controls, with 2D value windows and printed labels. Its width grows from 70 cm to 85.2 cm.
- `push_button.set_selected(bool)` supplies persistent choice feedback without changing momentary press semantics. The owner selects the state; it never toggles automatically. Shannon selects exactly one predictor button, and the existing prediction readout names the choice. Repeated presses preserve that choice. Ordinary buttons retain their existing behaviour.
- A direction assertion exposed an old shared ControlPanel bug: the horizontal slider's increasing direction pointed left. The scene's live movement axis is +Y, so the panel now rotates it -90 degrees. The value screen counter-rotates and stays above the handle. Standalone vertical scenes are unchanged. This repair applies to shared horizontal panel sliders, including earlier pilots.
- `ControlConsole.add_monitor()` now places its main support behind the screen. Its previous front edge occluded bottom-centre sample cells. Stacked displays already had their support behind the screen.
- Explicit, coalesced `refit_housing()` lets a console fit newly added controls. Only cabinet geometry is replaced. Shannon calls it when prediction buttons are first added; the sample, controls, grid and live readout retain their instances/state. No rebuilding is triggered by ordinary parameter updates.

## Evidence

- `control-checks.json`: 23 checks of source/predictor independence, actual pointer drag and button paths, selection before tree entry and after release, ordinary momentary semantics, material isolation, physical travel after physics settles, increasing direction, support clearance, runtime expansion and preserved display instances.
- `after/runtime/report.json`: all 26 existing room semantic checks and five selected museum collision-body walks pass. Includes entropy endpoints and symmetry, observed versus expected errors, no-sample state, evidence changes, seed restoration and mode toggles.
- `console-checks.json`: 156 shared console checks pass across legacy/compact and kiosk/lectern/wall. Expanded with panel-right direction checks; earlier tests verified value changes and distances but had not checked that direction.
- `layout-checks.json`: 70 shared row checks pass.
- `instrument-checks.json`: 46 mixed-reference checks pass in light and dark finishes after the orientation correction. These results and captures are written here, leaving the previous pilot's evidence untouched.
- Before/after captures use the same cameras and input values. The final after run pins the first capture's museum plan, because the global plan changed during other review work. Only private output files are replaced; the live museum remains untouched. Source manifests retain that provenance.

Headset legibility, seated reach, tracked-hand interaction and Quest performance remain open. This verifies one assembled museum placement plus the shared component regressions; other Shannon placements are not thereby certified. Known unrelated engine warnings and test-exit resource warnings remain recorded in the logs.

## Continue from here

The next distinct control principle is discrete and spring-return input. The full inventory found that the 2D stepped and bipolar rack sliders draw these behaviours but do not implement their own pointer handlers. Resolve and test those contracts before promoting their visual designs as working references.

Review: `/book-review/doc/book/iterations/2026-09-20-interface-shannon-review/index.html`.

Reproduce: `python doc/reports/interfaces-2026-09-20/shannon-pilot/run_pilot.py after`, then `python doc/reports/interfaces-2026-09-20/shannon-pilot/publish_review.py`. Use Godot `--headless --xr-mode off --script res://commons/testing/test_shannon_console.gd` for the component/receiver checks.
