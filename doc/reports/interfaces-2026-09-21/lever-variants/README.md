# Point One radio and lever variants

21 September 2026. This continues the physical interface pass. Text remains printed on flat surfaces; controls retain real geometry, grab proxies and colliders.

## Radio in Point_One

The authored interactable at zero-based cell `(3,4)` is now:

`SoundscapeRadioRack:180#plinth:0.85#pin:1`

It faces minus Z on a 0.85 m station plinth. Its role and order entry are **secondary**. The map's count and `artifacts.md` inventory agree. No primary role, manuscript passage or existing placement was removed.

The isolated museum probe builds the actual hall using current map, hand and placement configuration. Its copy of the museum script redirects generated reports to this report folder; it does not change the active game's starting hall. It measures the actual floor, a 0.44 m wide / 1.7 m tall standing capsule, a supported final metre of approach, all eight wheel grips, and real XRTools pickup under the authored rotation. Audio uses the production player and Dummy output; no listening judgment is made.

The first stance, 0.65 m from the radio centre, intersected the plinth foot. A 0.78 m stance clears it. Grip heights measure approximately 0.97–1.06 m and horizontal distances 0.68–0.70 m. These are layout measurements, not evidence of comfortable reach for every body. The plinth and radio carry the same inventory token, so the unique-radio check counts actual radio scripts rather than treating the support as a second radio.

## Three lever laws

- `lever_smooth.tscn`: continuous angle, retained on release.
- `lever_snap.tscn`: native 5° detents, retained on release.
- `lever_zero.tscn`: continuous angle, returns to 0° on release.

Snap and zero now inherit the shared smooth lever scene instead of duplicating the old geometry. Both keep their existing scene UIDs, node paths and valid left/right hand-pose redirects. Their 18 × 25 cm plates, collider layers, angle solver, pointer handling and flat readouts therefore follow the same base. A configurable printed caption identifies the variants when used outside the reference.

The old zero scene configured `default_position = 0.5` degrees and left `default_on_release` false. The new behavior is an explicit semantic repair: return to the neutral angle. The return is immediate; this is not a simulated damped spring. The only existing non-test direct consumer of these variants found in the source scan is the VR component library.

Small pointer movements now accumulate across a detent. Previously the wrapper replaced its raw accumulated angle with the snapped result after every event, so frequent sub-detent movements could remain stuck forever. The accumulator now preserves fractional motion, while discarding overshoot at the configured mechanical stops. Native quantization remains responsible for the actual joint value.

## Reference and evidence

`interactable_lever_demo.tscn` opts into `InteractableDemo`'s new lever reference. It groups the three full-size controls at 24 cm centres, on an inclined console in front of three identical receivers. Move each to 23°: continuous reads 23°, stepped reads 25°, returning reads 23°. Let go: the first two remain, and the third returns to zero. Holding the receiver constant makes the behavior difference visible.

The before capture and original component sources are archived. Three baseline checks failed: pointer APIs on snap/zero, and actual return-to-zero configuration. The final lever suite has 100 passing checks, covering both 0° and 90° mounting yaw with inclined panels, real XRTools pickup/release, stationary-hand stability, native detents, small pointer steps through real ray dispatch, limits, pointer loss/focus/exit release, flat readouts and visible receiver agreement. The hall probe has 42 passing checks. The existing angular suite (100) and radio suite (78) also pass after the shared wrapper change.

Reproduce from the project root, in sequence:

```powershell
python doc/reports/interfaces-2026-09-21/lever-variants/run.py after
python doc/reports/interfaces-2026-09-21/lever-variants/run_point_one.py radio after
python doc/reports/interfaces-2026-09-21/angular-controls/run.py after
python doc/reports/interfaces-2026-09-21/radio-console/run.py after
python doc/reports/interfaces-2026-09-21/lever-variants/publish_review.py
```

The displayed images are Godot captures. The test hands are synthetic drivers of the real grab API, not tracked headset hands. Headset comfort, sound quality and standalone Quest performance remain to be tested. The known unresolved legacy Nostromo sound IDs are unchanged. The pre-existing unresolved resource UID `uid://rwex60pqapc` and two viewport-texture messages still appear in the full hall log; the focused suites report no script errors.

## Next useful pass

The standing radio capture reveals partial occlusion of the lower wheel readouts by their physical grips. The main station panel is clear; test a supported inclined mount to improve the lower readings before treating that detail as finished.

Check these controls in the component library and other assembled panels. The reference demonstrates a compact arrangement, but does not establish that every old consumer has adequate spacing or accessible placement. In Point_One, test reach while standing and seated, turn through stations, check volume during playback, and look back at the main point encounter before deciding whether this test station should stay.
