# Task: Audit All Interactable Usages → Define Template Modules → Rebuild

## What This Task Is

Audit every place in the project that uses interactive elements (sliders, knobs, buttons, monitors, speakers, meters, text displays). Define a set of **template rack modules** — standardized building blocks that combine these elements. Then replace all existing ad-hoc usages with the templates.

## Why

Currently, interactive controls are used in many different ways across the project:
- `UniversalVRAudioController` spawns raw 3D interactables or 2D face textures
- `EurorackModule` uses `ModuleFaceTexture` for per-module SubViewport rendering
- `InteractableDemo` builds procedural meshes for visual reference
- Various artifacts use custom combinations of sliders, knobs, and displays
- The `timbre_sculptor`, `flocking_controls`, `spring_demo`, etc. each have their own control setups

There's no unified system. Each usage reinvents the wheel.

## The Plan

### Phase 1: Audit — Find every interactable usage

Search the entire codebase for:
1. Scenes that instance `slider_smooth.tscn`, `slider_horizontal.tscn`, `dial_smooth.tscn`, `push_button.tscn`, `lever_smooth.tscn`, `wheel_smooth.tscn`, `joystick_smooth.tscn`, `slider_plane.tscn`
2. Scripts that call `preload()` or `load()` on these scenes
3. Artifacts that use `AudioContr`, `SoundscapeRadioRack`, or custom audio control setups
4. Any script that creates sliders/knobs/buttons procedurally

For each usage, document:
- What controls are used (types, count)
- How they're laid out (grid, vertical, horizontal, custom)
- What parameters they control
- Whether they use face plates, ModuleFaceTexture, or raw 3D meshes

### Phase 2: Define Template Modules

From the audit, identify recurring patterns and define template modules:

**Candidate templates (from interactable_demo Row 3 + Row 4):**
- `FADER_BANK_2/3/4` — 2, 3, or 4 vertical sliders side by side
- `MIXER_STRIP` — vertical slider + horizontal slider + button
- `MONITOR_FADERS` — waveform display on top, faders below
- `SPEAKER_METERS` — speaker grille + VU meters
- `METER_BANK_3` — 3 VU meters side by side
- `KNOB_PANEL_2/3/4` — 2, 3, or 4 knobs in a row
- `BUTTON_PANEL` — row of buttons (various types)
- `TEXT_DISPLAY_1/2/3` — static or scrolling text, 1-3 slots
- `SCOPE_PANEL` — monitor display, 2-3 slots
- `TOUCH_SURFACE` — XY pad, 2+ slots
- `PATCH_BAY` — jack matrix, routing module
- `ROTARY_SELECTOR` — stepped knob with position indicators
- `NEEDLE_GAUGE` — analog needle meter

Each template:
- Has a fixed HP width and row span
- Uses the Dieter Rams aesthetic (cream panel, dark controls, copper accents)
- Works in VR (grabbable handles) AND desktop (pointer_event)
- Renders the same in Three.js mirror (`/interactable-demo`)

### Phase 3: Build Templates

For each template:
1. Create a `.tscn` scene with proper structure
2. Use existing interactable scenes where they work (slider_smooth, dial_smooth, etc.)
3. Add Rams-styled materials
4. Add numbered tick marks, labels, value displays
5. Register in `module_library.json` with HP width, controls, jacks
6. Test in `interactable_demo.tscn` and in VR

### Phase 4: Replace Existing Usages

For each usage found in Phase 1:
1. Identify which template module matches
2. Replace the ad-hoc control setup with the template
3. Pass parameters via `apply_grid_config()` or `@export` properties
4. Verify functionality preserved

## Key Files to Audit

### Audio rack system
- `commons/audio/UniversalVRAudioController.gd` — `_instantiate_control()`, `_spawn_controls_from_json()`
- `commons/audio/EurorackModule.gd` — `_spawn_control()`
- `commons/audio/EurorackRack.gd` — module layout
- `commons/audio/eurorack_modules/module_library.json` — module definitions
- `commons/audio/rack_configs/*.json` — 10 rack config files

### Existing artifacts with custom controls
- `commons/audio/rack_configs/SoundscapeRadioRack.gd` — custom wheel controls
- `algorithms/wavefunctions/spectralanalysis/timbre_sculptor.gd` — harmonic sliders
- `algorithms/nature_system/studio/flocking_controls.gd` — parameter sliders
- `algorithms/physics_simulation/spring_demo.gd` — spring parameter controls
- Any artifact with `slider_moved`, `hinge_moved`, `pressed` signal connections

### Interactable scenes
- `commons/interactables/*.tscn` — all 20+ interactable scene files
- `commons/interactables/InteractableDemo.gd` — current demo with 4 rows
- `commons/interactables/RackPassiveElements.gd` — procedural speakers/meters/monitors

### Template reference
- Three.js: `ada_encyclopedia/src/components/interactable-demo/InteractableDemo3D.tsx`
- Three.js: `ada_encyclopedia/src/components/audio-rack-builder/EurorackRack3D.tsx`
- Dieter Rams: `commons/audio/rack_controls/rack_design_tokens.json`

## Deliverables
1. **Audit report** — blog post with images showing every usage found
2. **Template module definitions** — added to `module_library.json`
3. **Template scenes** — `.tscn` files in `commons/audio/rack_templates/` (new directory)
4. **Replaced usages** — all existing control setups migrated to templates
5. **Updated Three.js mirror** — templates reflected in `/interactable-demo`

## Dieter Rams Design Rules
- Panel: cream (#C6BEAC → material 0.90, 0.87, 0.80)
- Controls: black body, copper accents
- Text: dark on light, monospace
- Numbers: tick marks with labels (0-10)
- No glow effects, no gradients
- Clean thin lines, precise geometry
- Green waveforms on dark screens

## Current Interactable Demo Layout (Reference)
- **Row 1**: 11 real interactable scenes + 4 procedural button types
- **Row 2**: 5 procedural passive + 4 grid monitors (scope, spectrum, lissajous)
- **Row 3**: 9 compound layouts (multi-sliders, monitor+sliders, speaker+meters)
- **Row 4**: 10 new modules (touch_grid, rotary_selector, needle_meter, patch_matrix, 6 text displays)
