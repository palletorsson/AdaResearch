# Radio mounting and the component library

21 September 2026. Continuation of the physical control pass: improve the observed radio readout obstruction, then bring the library's control families to a usable height.

## Point_One radio

The same secondary radio remains at `(3,4)` on its 0.85 m plinth, facing minus Z. Its token now includes `#orientation:inclined`. The optional mount inclines the complete case and controls by 32 degrees, with a support foot and a small forward displacement to keep all grips within the measured reach budget. Other radio placements default to `upright`.

The mount transforms each part from its recorded authored transform. It preserves public node paths, the map's yaw, wheel angles, station selection, gain and all four face modes. Reapplying settings does not accumulate rotation. Returning to upright restores the original part frames. This is a placement option rather than a change to the radio's tuning rule.

The existing Point_One hall probe is extended by `probe_radio_readouts.gd`: nine eye-to-window rays for each numeric display identify obstruction by the physical grips. Both displays fail in the archived upright placement and pass in the final mount. The probe still checks the actual floor, standing capsule, final metre of approach, all eight grips and real XRTools pickup under map rotation. Fifty-five final checks pass, including repeated configuration and face changes.

These are sampled collider sight lines from a 1.65 m standing eye, alongside actual rendered images. They do not establish text legibility for every eye position or headset.

## One operating station, eleven pages

`commons/ui/demo/vr_component_demo.gd` replaces the tall component wall with a supported inclined console. The former scene was 3.6 m high and centred below its origin; its lower rows could not serve as a normal floor-standing interface. The new visible bounds are 1.10 × 1.725 × 0.535 m, measured across all eleven pages.

All 28 original specimen placements remain represented: slider variants, dials, buttons, joysticks, levers, the XY pad, audio controls and displays. The physical Previous and Next buttons sit at 36 cm centres. The console holds only the current page's scene instances. Pages load fresh controls, and R resets the current page; this behavior is stated on the panel. Paging waits for a physical grab or active control drag to end.

The component code keeps its actual input implementations. Existing flat readouts remain in use. For legacy Label3D sources, the library hides their rendered glyphs and mirrors their current strings to backed 2D surfaces. The typed source nodes remain available to their original scripts. Only the current page's legacy strings are checked, at 10 Hz, and their viewports redraw only when text changes.

Embedded library instances no longer install their preview camera, lighting or environment into the host hall. The standalone scene keeps its preview. The existing `Gallery_Furniture` token loses its obsolete −0.5 m offset and explicitly requests no extra plinth; the library has its own stand. Registry placement metadata and measured dimensions now describe that stand. The surrounding furniture hall has not been walked as part of this pass.

## Audio display lifetime

Repeated page visits exposed a resource ownership issue in the older displays. `GameSoundMeter` added an analyser but never removed it. `SimpleWaveformDisplay` borrowed whichever analyser it found, or created one without a corresponding release.

Waveform views now acquire a shared, owned analyser per bus through `spectrum_analyzer_lease.gd`. Releasing the last view removes that analyser. A source-bus change releases the previous lease; a missing bus falls back to Master. Spectrum meters retain their own analysis settings and remove their own effect on exit. Removal matches the actual resource identity, so other instruments' effects survive. The private-bus spectrum path also resolves the instance it just added rather than assuming index zero.

The tests cycle through the audio pages repeatedly, verify that the effect count returns to its starting value, preserve an unrelated effect, keep a shared analyser while one view remains, and exercise bus changes and fallback. This is lifecycle evidence, not a Quest performance benchmark.

## Evidence and reproduction

- Component library: **173 passing checks**. All pages and specimen counts, flat visible text, unit scale, working-height origins, visible geometry above the floor, non-overlapping neighboring specimens, actual pager ray and pointer dispatch, wrapping/reset, held-control guards, lever behavior, legacy value synchronization and audio effect lifetime.
- Actual Point_One radio: **55 passing checks**.
- Existing radio regression suite: **78 passing checks** after the mounting and audio changes.

The before images and relevant original sources are archived under `before/`. The museum runner uses a private snapshot of the live builder with redirected output paths, leaving the active game's starting hall unchanged.

```powershell
python doc/reports/interfaces-2026-09-21/console-placement/run.py after
python doc/reports/interfaces-2026-09-21/console-placement/run_radio.py radio after
python doc/reports/interfaces-2026-09-21/radio-console/run.py after
python doc/reports/interfaces-2026-09-21/console-placement/publish_review.py
```

Godot runs with desktop rendering and Dummy audio output. No script errors appear in the final runs. The pre-existing unresolved UID `uid://rwex60pqapc` and two viewport-texture messages remain in the engine log. The two unresolved Nostromo sound IDs from the earlier radio review are unchanged.

## Next checks

Test Point_One's radio and the library from standing and seated headset positions. Check the library in the furniture hall, then audit the remaining old slider and audio-dial input drivers under inclined mounts. This pass validates their library presentation; it does not claim that every legacy control now has the same grab quality as the repaired wheel, lever and joystick families.
