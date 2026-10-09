# Rack Controls

2D rack control widgets drawn with Godot primitives, designed for SVG-parity visual fidelity.

## Base System

| Script | Purpose |
|--------|---------|
| `RackControlBase.gd` | Base class — draw primitives map 1:1 to SVG elements |
| `RackDesignTokens.gd` | Centralized design tokens for consistent styling |

## Control Types

| Script | Scene | Type |
|--------|-------|------|
| `RackSliderH.gd` | — | Horizontal slider |
| `RackSliderV.gd` | — | Vertical slider |
| `RackSliderBipolar.gd` | — | Bipolar (center-zero) slider |
| `RackSliderStepped.gd` | — | Stepped/quantized slider |
| `RackKnob.gd` | `RackKnob.tscn` | Rotary knob |
| `RackWheel.gd` | — | Scroll wheel control |
| `RackLever.gd` | `RackLever.tscn` | Toggle/range lever |
| `RackJoystick.gd` | `RackJoystick.tscn` | XY joystick |
| `RackXYPad.gd` | — | XY pad controller |
| `RackButton.gd` | `RackButton.tscn` | Push button |

## Display Widgets

| Script | Scene | Type |
|--------|-------|------|
| `RackMeter.gd` | `RackMeter.tscn` | VU-style meter |
| `RackLabel.gd` | `RackLabel.tscn` | Text label |
| `RackGroup.gd` | `RackGroup.tscn` | Control grouping container |
| `RackDivider.gd` | `RackDivider.tscn` | Visual divider |

## VR Wrappers

The `vr_wrappers/` subdirectory provides 3D wrappers that make these 2D controls grabbable in VR.

## Usage

Used by `UniversalVRAudioController` and `RackLayoutCalculator` to build modular synth rack interfaces. Scalar controls emit `value_changed` and accept normalized values from 0.0 to 1.0. The bipolar control displays -1.0 to +1.0 and exposes `get_signed_value()`; its signal remains normalized.

### Discrete and returning input

`RackSliderStepped.steps` includes both endpoints. Values are clamped and snapped before storage and emission, including programmatic assignments. The selected value persists after release.

`RackSliderBipolar.return_to_center` defaults to true: releasing returns immediately to normalized 0.5 (signed zero). Set it to false for a signed setting that should persist. `ModuleFaceTexture` accepts this option in its control definitions and cancels a returning command when its active pointer exits the panel. It also protects a drag from another pointer's events.

Run `commons/interactables/interactable_release_demo.tscn` for the working comparison, or enable `release_reference` on `InteractableDemo`. [Input evidence and remaining wrapper work](../../../doc/reports/interfaces-2026-09-20/rack-input-pilot/README.md) distinguish the tested `ModuleFaceTexture` path from the standalone `VRRackControl` wrapper, which still needs pointer forwarding.
