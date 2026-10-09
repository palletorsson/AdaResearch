# Current interface state — 20 September 2026

The requested `interactive_demo` is registered as **`interactable_demo`**. Ada already has a substantial interface vocabulary, common controls, reusable panels, several housing families and web galleries. The missing step is evidence that each assembled interface works for a player in its actual hall.

Follow-up: [interface-principle coverage and integration plan](coverage-plan.md), with source-grounded candidate examples and a proposed first implementation slice.

**Expanded audit:** [full project inventory and findings](full-inventory/README.md), [searchable artifact/source table](full-inventory/index.html). This supersedes the three-directory scan below as the coverage inventory. It includes scenes, embedded scripts, audio/player systems and configuration, and records a component-level input gap in two 2D rack sliders.

**Subsequent implementation:** the user's requirement that all text be 2D in 3D is now part of the [integration plan](coverage-plan.md#required-text-treatment-2d-in-3d). The shared panel/console glyph-mesh path has been replaced with flat textured text, with [runtime evidence](flat-text-check.json) and [a capture](flat_text_allcontrols_front.png). The inventory below and the full census describe the earlier snapshot; they have not been relabelled as a completed text migration.

This report records the current working tree. It makes no production interface, map, artifact-role or manuscript changes. Counts below are source classifications; the new Godot capture is a runtime construction check, not a playtest or Quest performance measurement.

## Open and inspect

| Resource | Location | What it shows |
|---|---|---|
| Browser component demo | [interactable-demo](http://localhost:3003/interactable-demo) | Three.js reference, separately implemented from Godot |
| Godot layout gallery | [interactable-layouts-gallery](http://localhost:3003/interactable-layouts-gallery) | Configured composite boards made with the demo vocabulary |
| Interface types | [interface-presets-gallery](http://localhost:3003/interface-presets-gallery) | Reference housings and panels |
| Interface materials | [interface-skins-gallery](http://localhost:3003/interface-skins-gallery) | Material/style variations |
| Existing progress page | [interface-overhaul](http://localhost:3003/interface-overhaul) | Historical, hard-coded rollout totals; not the fresh audit below |
| Composer | [interface-composer](http://localhost:3003/interface-composer) | Existing route; functionality not exercised in this audit |
| Godot demo scene | [interactable_demo.tscn](../../../commons/interactables/interactable_demo.tscn) | Scene using `InteractableDemo.gd` |
| Demo implementation | [InteractableDemo.gd](../../../commons/interactables/InteractableDemo.gd) | The actual control sampler and configurable layout builder |

All six web URLs returned HTTP 200 during collection. Browser controls and gallery assets were not tested. The browser demo is not an embedded Godot build and cannot prove that VR input works.

## Fresh Godot baseline

![Default Godot control sampler](default-demo.png)

Captured from the unmodified default configuration using the existing studio capture script. The camera is orthographic and frames the full board; it is not a visitor's eye position. The small labels in this overview do not establish their readability at operating distance.

Runtime evidence: [runtime.json](runtime.json), [capture-run.json](capture-run.json), [capture.log](capture.log).

| Measurement | Observed value |
|---|---|
| Mesh bounds | approximately 5.30 m wide × 1.81 m high × 0.218 m deep |
| Mesh bounds, local Y | approximately −0.475 to 1.335 m |
| Nodes under demo | 1,702 |
| MeshInstance3D nodes | 1,105 |
| CollisionObject3D nodes | 95 |
| RigidBody3D nodes | 40 |

These counts describe construction, not draw calls, frame time or proven usable controls. The studio ground is positioned by the capture harness; negative local Y does not by itself prove a hall buries part of the demo. World placement must be measured separately.

The capture exited successfully. Startup still logged an unrecognised UID and a certificate-store error, and the wheel scene used a path fallback for an invalid UID. There were no reported GDScript parse errors. An initial attempt failed while opening the default user log and crashed; directing the engine log into this report folder allowed the capture to complete. Both attempts are retained.

## What the demo contains

| Row | Contents | Current status |
|---|---|---|
| Main controls | 11 scene instances: button, front button, dial, smooth vertical slider, horizontal slider, snap slider, zero slider, lever, wheel, joystick, XY pad | Real control scenes; runtime collision objects present. Input behaviour not exercised in this collection. |
| Extra buttons | Small rectangle, wide rectangle, tall rectangle, toggle | **Visual mockups.** Each has zero collision objects and no attached scripts in the generated subtree. |
| Passive elements | 9 entries: three speaker designs, two VU meters, two scopes, spectrum and Lissajous | Mix of passive decoration and procedural displays; a moving display is not evidence of a connected input. |
| Compound layouts | 9 packs: vertical/horizontal slider groups, monitor plus sliders, speaker plus meters, meter group | Slider packs instantiate controls; passive groups remain passive. Some control paths apply scale. |
| Prototype/display modules | 10 entries: touch grid, rotary selector, needle meter, patch matrix, three static and three scrolling text widths | First four are visual mockups built from meshes. Text modules are displays, not input controls. |

The file's identity comment says “all live, all grabbable”; that is broader than the implementation supports. Preserve the visual prototypes as useful design material, but distinguish them from functioning controls.

Defaults: 0.30 m horizontal spacing; row centres at local Y 1.10, 0.65, 0.20 and −0.25 m. The first row's 15 positions span 4.20 m between end centres, so it is a walk-along catalogue rather than a single-position console.

There are **21 JSON variants** in `commons/interactables/demo_configs/auto`. `load_demo_config_from_dict()` accepts contents, titles, positions, colours and optional hand-size guides. The gallery harness calls it explicitly. **`apply_grid_config()` is currently a no-op**: map-token options alone do not select these layouts through that method. The hand guides are visual references, not tracked reach tests.

Direct placements were found in seven map-data files, plus two indirect curation-station lists; all are listed in [snapshot.json](snapshot.json). None of those map names belongs to the map lists of the currently configured curriculum-spine sequences. This is a map-data membership check, not a claim that no dynamic loader can instantiate the artifact. Historical documentation naming `WaveFunctions_Effect_Sound` is not evidence of its current placement there.

## Shared interface architecture

| Layer | Current implementation | What can be reused |
|---|---|---|
| Individual controls | `commons/interactables/` | Buttons, smooth sliders, dials, joysticks, levers, wheels and other variants |
| Control board | [ControlPanel](../../../commons/ui/control_panel.gd) | `add_slider`, `add_button`, `add_dial`, `add_joystick`, screens and readouts; common spacing, tilt, labels and seating |
| Instrument housing | [ControlConsole](../../../commons/ui/control_console.gd) | Kiosk, lectern or wall mounting; board housing; monitor, cube-space, plan and specimen-jar hosts |
| Form/material recipes | [InterfacePresets](../../../commons/ui/interface_presets.gd), [InterfaceHousing](../../../commons/ui/interface_housing.gd) | 17 type configurations and five skins |
| Text surfaces | [TextScreen](../../../commons/ui/text_screen.gd) | Screen, stand and pad modes; wrapping and a minimum-glyph policy in code, still requiring headset validation |
| Force interfaces | [ForcesRackPanel](../../../algorithms/forces/forces_rack_panel.gd) | Adapter that builds through ControlPanel |
| Audio racks | [RackTemplates](../../../commons/audio/rack_templates/RackTemplates.gd) | Separate eurorack builder using shared control scenes; preserve its distinct form |

The 17 types are workbench, machine, console, readout, rack, plaque, dashboard, pedestal, tower, table, monitor bank, grid board, vitrine, tank, dish, frame and launcher. The five skins are Braun, Black Mesa, sci-fi, civic and warm wood. These are configuration options; this audit did not render and validate all 85 combinations.

### Concrete differences and risks to investigate

1. **The shared board has one horizontal row.** `ControlPanel._relayout()` expands width as controls are added; there is no row wrapping in that function. At default spacing, eight ordinary slots occupy 2.40 m before outer casing. Sliders occupy 1.4 slots. Using the common component therefore does not guarantee a compact interface.
2. **The demo and common board use different horizontal-slider paths.** ControlPanel rotates `slider_smooth` for a horizontal fader; the demo uses `slider_horizontal`. RackTemplates also loads that older horizontal scene. The two implementations have different constraint code; compare their actual grab behaviour before declaring them equivalent.
3. **Physics scaling policy is inconsistent.** ControlPanel explicitly preserves the scale of controls containing rigid bodies. Demo compound/embedded layouts and RackTemplates still scale controls or their parents. This is a candidate for VR interaction testing, not a newly measured failure.
4. **The bare console's SNAP button has no demonstrated purpose.** `ControlConsole._build_demo()` connects the slider to the readout, but adds SNAP without connecting an effect. That reference instrument is not yet a complete interaction specification.
5. **Layout selection stops at the demo's map adapter.** Configured gallery layouts work through direct dictionary loading, while `apply_grid_config()` does nothing.
6. **Registry size metadata disagrees internally.** The demo has legacy `[1,1,1]`/`compact` fields alongside a measured 5.3 m width and six-cell spatial footprint. The measured width matches the fresh capture. Consumers may pick different fields.
7. **Documentation and galleries have drifted.** The April artifact plan says no dedicated script was found, although the scene references `InteractableDemo.gd`. The interaction startpack calls `slider_horizontal` the standard, while ControlPanel uses `slider_smooth`. The overhaul page's totals are hard-coded; the presets page still describes skins as forthcoming although five are implemented.

## Fresh source inventory

Generated with the existing [ui_audit.py](../../../tools/ui_audit.py). Full rows: [source-inventory.json](source-inventory.json).

| Script classification | Shared panel/console marker (`done`) | Recognised base/sibling (`converged`) | Neither marker (`todo`) | Total |
|---|---:|---:|---:|---:|
| Console | 9 | 0 | 44 | 53 |
| Machine | 11 | 0 | 85 | 96 |
| Rack | 9 | 179 | 0 | 188 |
| Workbench | 13 | 9 | 42 | 64 |
| Readout | 5 | 1 | 615 | 621 |
| **All** | **47** | **189** | **786** | **1,022** |

Excluding the readout-only category gives **401 control-bearing script classifications**, of which **171** have neither recognised marker. This is a useful investigation queue, not 171 confirmed broken interfaces or a count of placed artifacts.

The scanner examines `.gd` source in `commons/artifacts`, `commons/ui` and `algorithms`. It does not scan all of `commons/interactables` or `commons/audio`; this means the requested demo and RackTemplates themselves are outside its normal roots. It matches strings, including comments, and does not fully resolve scene inheritance or every factory. Its `done` status means a source marker exists, not that operation, reach, readability or Quest performance passed.

## Existing verification and what it proves

| Tool | Evidence available | Limit |
|---|---|---|
| `ui_audit.py` | Fresh source classification above | Component adoption only |
| `artifact_controls.py` | Scene references, builder calls and control kinds; unknown/floor counts supported | Static evidence, not proof of operation |
| `capture_interactable_demo_config.gd` | Fresh default render and our runtime subtree inspection | Studio view, no player, no inputs |
| `capture_interface_presets.gd` | Existing reference-gallery capture harness | Not rerun across all types in this collection |
| `test_control_panel.gd`, `test_control_console.gd`, `test_console_allcontrols.gd` | Existing construction and front/side screenshot scripts | They do not press or drag the displayed controls; not rerun here |
| `check_interaction.py` / `probe_interaction.gd` | Existing signal-driven change checks against spontaneous drift | Signal emission bypasses physical targeting and grab reach |
| `wcn_desktop_driver.gd` | Existing synthetic mouse input through the actual desktop pointer | Different from headset interaction; uses a separate desktop rig |

No new TypeSafe requests, Quest deployment or human headset test were performed. The earlier CA_SoftRules exchange pilot demonstrates a stronger input-test approach, but it is not evidence that these demo controls passed.

## Recommended next unit of work

Use **the demo as the vocabulary catalogue**, **ControlPanel/ControlConsole as reusable implementation**, and **InterfacePresets as the family of design references**.

1. Mark each catalogue entry as functioning control, passive display or visual prototype, with its actual input mode and evidence.
2. Build one compact reference experiment: a parameter slider, one working action, a visible receiver and a useful readout. Record world placement, comfortable operating positions and control effects.
3. Inspect a dense console and one eurorack example against it. Test row width, slider behaviour and parent scaling before applying a common fix.
4. Add evidence statuses alongside adoption: source checked, rendered, desktop operated, headset checked, unknown. Keep justified differences explicit.
5. Connect fresh inventory results to the web tracker after the evidence contract is settled; preserve older captures as dated history.

For each comparison ask: can I approach, read, reach, target, understand the first action, observe the result, identify state, repeat the experiment, and keep the artifact in view? Does the difference from the reference serve the encounter? A deliberate visual or spatial variation is not automatically a defect.

Restoration principle remains in force: strengthen the encounter and its evidence before weakening a manuscript passage or removing a distinctive artifact.

## Reproduce

Run from the repository root:

```powershell
python doc/reports/interfaces-2026-09-20/collect.py
```

The exact successful Godot command is recorded as an argument array in `capture-run.json`. The capture wrapper adds descriptive node counts to the existing harness; it does not modify the demo. Source hashes and map placements are in `snapshot.json`.
