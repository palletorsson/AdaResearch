# Floor 16 / Rotation — comparison before changing the map

Status: **proposal only**. No floor, artifact configuration, collision, construction or source map was changed. Recommendations are also in the comparison's **Carry forward** notebook, prefixed PROPOSAL.

Compare: http://localhost:3003/lab-editor?mode=void&floor=16&compare=1&grid=historic

## The central question

How does a fixed cube, turned about a different axis, change what the body can walk across? The main encounter should let the player try a foot placement, meet a slope/ridge/edge, change direction and recover. A blocked passage or a fall can communicate the relation; success on every course is not the design goal.

## What each source contributes

| Arrangement | Observed setup | Recommendation |
| --- | --- | --- |
| Before-Museum Grid | 7 × 53 m. A controller transforms the shared one-metre Grid cubes and their collision bodies. Its authored score alternates Z, flat, Y, flat, negative X, flat, combined, flat bands. | Keep the experience of the **ground becoming the lesson**, its lateral field and its rhythm of altered ground followed by a flat pause. Adapt the rhythm to the Void rather than copy the whole long strip. |
| Current Museum | 62 × 87 m envelope around the current lesson. The array has four axis bands, each **2 columns × 6 rows**, full-size 2.04 m cubes at 2 m pitch, 18° steps through 0–90°. Thresholds/walls distinguish the hall; the broader sequence separates crossings, arrays and later studies. | Keep the **two-dimensional walking opportunity**, stable approaches and separation between encounters. Borrow a local threshold/edge/support, not the entire lobby and hall footprint. Use the project's cubes and wedges for a temporary local frame. |
| Saved Void | Standard 42 × 18 m floor. Four parallel **1 column × 6 row** lanes, full-size 2.04 m cubes, same six angles; raised to 3 m and turned 90° in the saved placement. Recovery is on the floor below the study. Two-width witnesses, shaft connections and the hollow-cube descent remain present. | Keep this full-scale baseline, comparable axis lanes, matching collision geometry, visible face witnesses and recoverable consequences. Keep the shaft descent as a deliberate onward choice after the walking encounter. |

The two newer versions use the same cube dimensions and angular progression, but offer different width. The old Grid uses a different one-metre substrate. They are not three identical tests with different decoration.

## Walking: what the evidence establishes

`commons/artifacts/rotation_studies/array_compare.gd` keeps cube centres fixed, rotates their actual static collision bodies with their meshes, and marks edges/faces. In the tower-walkway mode it explicitly forces one column and positions the lanes on raised banks. A `columns=2` editor change alone would therefore not create the proposed wider study.

Earlier native evidence in `ada_run/transformation-walkability/native.json` reports the following bounded, constant-forward-input capsule trials:

| Axis | 0.44 m body | 1.20 m body |
| --- | --- | --- |
| Y | Arrived | Arrived |
| X | Blocked | Blocked |
| Z | Blocked | Fell |
| X then Y then Z | Fell | Blocked |

These witnesses use gravity, a 1.6 m capsule, 2 m/s forward speed, a 45° floor-angle limit and no jumping, steering or step assistance. This is earlier solver evidence, not a new playthrough of every current arrangement or a headset verdict. It shows why width and strategy are worth comparing; it does not establish an exact critical angle or that a wider body always passes more easily.

At 90° a cube can present an axis-aligned face again. The six-angle sequence should therefore be read through actual contact and marked faces, not as a simple difficulty meter that increases with angle.

## Suggested encounter sequence

1. A stable common approach lets the player see the four lanes and choose an entry.
2. Y provides a horizontal-rotation control. Then compare X's forward slopes, Z's sideways ridges, and the combined case. This is a proposed order, not a request to move the existing lanes now.
3. Leave enough lateral room where the player is meant to steer. Keep the consequences of missed footing and an understandable route back to the starting bank.
4. Use flat pauses/observation space to compare what happened before another attempt. Keep recovery distinct from the actual tilted collision surface.
5. Place composition, the hinge and speed/profile studies in optional adjoining encounters, followed by a clear choice to descend. Their parts remain available; visual priority belongs to the walking study first.

## First small experiment to discuss

**One two-column Z section, compared with the existing one-column section, with the same cube size, pitch, six angles and body scale.**

Z is a useful first candidate because steering across a rolled ridge is directly bodily, and the earlier two-width observations differ. Width would be the deliberate variable. This could reveal whether the extra lateral choice makes a better encounter or merely makes bypassing the difficult part easy. A comparison sketch must account for neighbouring lanes and banks; widening all four lanes in their current positions could remove their separation.

Only after agreeing on that study should we stage its surrounding path and consider the combined-axis course. This is not a proposal to rearrange all thirteen exhibits at once.

## Pressure points to inspect later

The existing static diagnostics flag nine close exhibit-envelope pairs. Particularly relevant are the left carousel cluster beside the shaft/crossing approaches (roughly 0.5–0.74 m between some envelopes), the adjacent lower-left carousel pair (0.11 m), the walking-study/hollow-descent envelopes (0.23 m), and the film/composition fronts. Their projected bounds are prompts for an eye-level review, not collision or access failures. Height, active fronts, motion and real standing positions matter.

I would lower the visual priority of the five carousel profiles and protect the approaches to the walking lanes, composition instrument and descent before adding any more scenery. Museum-style framing should support those approaches using selective local structures, with room to walk around the encounter.

## Review evidence

- Historical Grid geometry/reference and exact archived `RotateGridCubes.gd/.tscn` at `a36f33c996004abcdc67ea2a0ac3fce72eba42fd`.
- Current native Museum and saved Void documents from `/api/map-comparison?floor=16&grid=historic`; exact configurations, poses, footprints and source intentions inspected.
- Current `commons/artifacts/rotation_studies/array_compare.gd`, `array_body_comparison.gd` and `parts.gd`.
- Current source `commons/maps/Trans_Rotation/intent.md`; `walked.md` explicitly labels its account historical, so it was not taken as a description of the current hall.
- Existing native collision receipt above. No new Godot job or mechanics test was launched.
- Read-only Three.js captures in `doc/ports/2026-10-26-rotation-comparison/`; no browser authoring requests or uncaught page errors.

The shared notebook stores recommendations, not accepted changes. The map remains available exactly as before for discussion and playtesting.
