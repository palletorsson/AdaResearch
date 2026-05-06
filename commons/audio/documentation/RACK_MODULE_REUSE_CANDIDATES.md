# Rack Module Reuse Candidates

Concrete shortlist of rack modules that can be built mostly by reusing existing
AdaResearch controls, displays, and interaction systems.

This is not a theory note. It is a build queue.

## Existing Rack Surface

The current rack system already supports these control/display types in
[UniversalVRAudioController.gd](/Users/palle/Documents/GitHub/AdaResearch_46/commons/audio/UniversalVRAudioController.gd:882):

- `slv`, `slh`, `sls`, `slz`
- `knob`, `wheel`
- `xy`, `js`
- `btn`, `lv`
- `monitor`, `spectrum`, `waveform`, `simple_waveform`, `lissajous`
- `meter`, `label`, `group`, `divider`

The 2D rack-face mapping for those types is defined in
[ModuleFaceTexture.gd](/Users/palle/Documents/GitHub/AdaResearch_46/commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd:15).

## Priority Order

1. Patch Matrix
2. Needle Meter
3. Rotary Mode Selector
4. Speaker / Output Module
5. Vector Scope / Radar
6. Lambda / Phi Macro Pair
7. Touch Plate Strip
8. Segment Display
9. Waterfall Spectrum
10. Guarded Arming Switch

## Module Specs

| Module | Slots | Reuse Source | Rack Type | Build Approach |
|---|---:|---|---|---|
| Patch Matrix | 2-3w x 1h | `commons/audio/cables/synth_jack.tscn`, `commons/audio/cables/synth_cable.tscn`, `commons/audio/cables/synth_cable_manager.gd` | new wrapper | Add a rack panel that lays out jacks in a compact grid and delegates routing to the existing cable manager. |
| Needle Meter | 1w x 1h | `commons/audio/rack_controls/RackMeter.tscn`, `commons/audio/rack_controls/RackMeter.gd` | `meter` variant | Keep the existing value logic and replace the bar display with a pivoting needle and printed scale. |
| Rotary Mode Selector | 1w x 1h | `commons/audio/rack_controls/RackKnob.tscn`, `commons/interactables/dial_smooth.tscn`, `commons/audio/rack_controls/RackSliderStepped.tscn` | `knob` stepped variant | Reuse knob interaction with discrete detents and a labeled function ring. |
| Speaker / Output Module | 1w x 1h | `commons/interactables/RackPassiveElements.gd` | passive panel | Wrap the Braun-style speaker grilles as rack-native passive/output faces. |
| Vector Scope / Radar | 2w x 1h | `commons/audio/interfaces/VRLissajousDisplay.tscn`, `commons/audio/interfaces/VRAudioMonitor.tscn`, `commons/interfaces/qfep/qfep_oscilloscope.gd` | `lissajous` or `monitor` variant | Use the existing display logic but change skinning and labeling toward scope/radar language. |
| Lambda Macro | 1w x 1h | `commons/interfaces/qfep/lambda_slider.gd`, `commons/audio/rack_controls/RackSliderV.tscn` | `slv` semantic variant | Port lambda semantics onto a rack-native vertical slider with color-coded scale and value display. |
| Phi Macro | 1w x 1h | `commons/interfaces/qfep/phi_slider.gd`, `commons/audio/rack_controls/RackSliderBipolar.tscn` | `slz` semantic variant | Port phi semantics onto a rack-native bipolar slider with centered zero and mirrored labeling. |
| Touch Plate Strip | 2w x 1h | `commons/audio/rack_controls/RackButton.tscn`, `commons/interactables/push_button_2d3d.tscn` | `button` bank | Build a flat multi-pad strip using rack button logic but render as Buchla-like touch plates. |
| Segment Display | 1w x 0.5-1h | `commons/audio/rack_controls/RackLabel.tscn`, `commons/audio/rack_controls/RackLabel.gd` | `label` variant | Use the existing label module with segmented typography and numeric formatting. |
| Waterfall Spectrum | 2-3w x 1h | `commons/audio/interfaces/VRSpectrumDisplay.tscn`, `commons/audio/interfaces/VRSpectrumDisplayWide.tscn` | `spectrum` variant | Extend spectrum display rendering to a scrolling waterfall display. |
| Guarded Arming Switch | 1w x 1h | `commons/audio/rack_controls/RackLever.tscn`, `commons/interactables/lever_smooth.tscn` | `lever` variant | Add a cover/guard mesh and latched state to the existing lever control. |

## Detailed Notes

### 1. Patch Matrix

- Why first: highest gain in "real instrument" feeling.
- Historical references: EMS Synthi matrix, studio patchbay, telecom switchboard.
- Minimal implementation path:
  - Create a rack module scene or rack-face panel that places `SynthJack` nodes.
  - Keep routing in `SynthCableManager`.
  - Add printed labels and route grouping through `RackLabel` and `RackDivider`.
- Good first shape:
  - `2w` module with `2 x 4` jack grid.
  - Inputs on one row, outputs on another.

### 2. Needle Meter

- Why second: adds hardware credibility fast.
- Historical references: VU meter, analog voltmeter, avionics instrument.
- Minimal implementation path:
  - Reuse `RackMeter` update logic.
  - Replace bar fill with one rotating needle mesh or 2D pointer.
  - Add printed tick marks on the face texture.
- Best use cases:
  - output level
  - modulation depth
  - entropy / lambda / phi amount

### 3. Rotary Mode Selector

- Why third: function selectors are everywhere in historical hardware.
- Historical references: oscilloscopes, radios, bench analyzers.
- Minimal implementation path:
  - Start from `RackKnob`.
  - Add discrete states and printed labels.
  - Map to integer mode values.
- Good first modes:
  - waveform
  - routing
  - display source
  - quantization amount

### 4. Speaker / Output Module

- Why now: visual payoff is high and the assets already exist.
- Source: `build_speaker_dots`, `build_speaker_lines`, `build_speaker_grid` in
  [RackPassiveElements.gd](/Users/palle/Documents/GitHub/AdaResearch_46/commons/interactables/RackPassiveElements.gd:17).
- Minimal implementation path:
  - Build one passive module with switchable grille styles.
  - Optionally add a lamp or mute button.
- Best role:
  - output panel
  - talkback/intercom panel
  - decorative filler with slight signal response

### 5. Vector Scope / Radar

- Why next: strongest overlap between real lab gear and sci-fi.
- Historical references: CRT oscilloscopes, radar, med-tech screens.
- Minimal implementation path:
  - Re-skin `VRLissajousDisplay` or `VRAudioMonitor`.
  - Add a source selector knob.
  - Optionally port styling from `QFEPOscilloscope`.
- Best role:
  - XY relation monitor
  - phase/routing monitor
  - conceptual state monitor

### 6. Lambda / Phi Macro Pair

- Why here: these are meaningful system controls, not generic widgets.
- Historical references: scientific control surfaces, macro modulation panels.
- Minimal implementation path:
  - Keep rack-native face and sizing.
  - Pull logic and labeling ideas from `lambda_slider.gd` and `phi_slider.gd`.
  - Expose them as reusable module defs in `module_library.json`.
- Best role:
  - system-wide entropy/order control
  - global bias/phase control

### 7. Touch Plate Strip

- Why later: strong identity piece, but more custom than the others.
- Historical references: Buchla touch keyboard, membrane instrument panels.
- Minimal implementation path:
  - Create a bank of rack buttons.
  - Flatten the visuals and remove "button cap" appearance.
  - Use emissive copper or brass plates.
- Best role:
  - note triggers
  - preset banks
  - route selection

### 8. Segment Display

- Why useful: converts labels into instrument readouts.
- Historical references: seven-segment counters, synth tuners, frequency displays.
- Minimal implementation path:
  - Use `RackLabel`.
  - Introduce segmented font styling and zero-padded formatting.
- Best role:
  - frequency
  - clock
  - preset number
  - mode number

### 9. Waterfall Spectrum

- Why useful: gives the rack one "advanced analyzer" display.
- Historical references: RF analyzers, sonar, surveillance instrumentation.
- Minimal implementation path:
  - Extend the existing spectrum display rather than inventing a new display path.
  - Make it a wide module for readability.
- Best role:
  - signal forensics
  - frequency history
  - room/output analysis

### 10. Guarded Arming Switch

- Why last: high style value, lower systems value.
- Historical references: avionics, reactor panels, industrial safety hardware.
- Minimal implementation path:
  - Reuse `RackLever`.
  - Add a simple hinged or transparent guard.
  - Pair with warning lamp and label.
- Best role:
  - destructive action
  - record/overwrite
  - reset all
  - "dangerous" mode enable

## Recommended Build Sequence

### Phase 1: Establish Hardware Credibility

- Patch Matrix
- Needle Meter
- Rotary Mode Selector
- Speaker / Output Module

### Phase 2: Establish Instrument Identity

- Vector Scope / Radar
- Lambda Macro
- Phi Macro

### Phase 3: Add Signature Panels

- Touch Plate Strip
- Segment Display
- Waterfall Spectrum
- Guarded Arming Switch

## Best First Repo Edits

If implementing now, the cleanest first targets are:

1. Add new module defs to
   [module_library.json](/Users/palle/Documents/GitHub/AdaResearch_46/commons/audio/eurorack_modules/module_library.json).
2. Add rack-native variants in
   [commons/audio/rack_controls](/Users/palle/Documents/GitHub/AdaResearch_46/commons/audio/rack_controls).
3. Reuse existing display scenes in
   [commons/audio/interfaces](/Users/palle/Documents/GitHub/AdaResearch_46/commons/audio/interfaces).
4. Reuse passive speaker geometry from
   [RackPassiveElements.gd](/Users/palle/Documents/GitHub/AdaResearch_46/commons/interactables/RackPassiveElements.gd).
5. Reuse semantic control logic from
   [commons/interfaces/qfep](/Users/palle/Documents/GitHub/AdaResearch_46/commons/interfaces/qfep).

## Recommendation

If only one module is built next, build **Patch Matrix**.

If two are built next, build **Patch Matrix** and **Needle Meter**.

If the goal is a stronger project identity rather than generic synth UI, build
**Patch Matrix**, **Vector Scope / Radar**, and the **Lambda / Phi Macro Pair**.
