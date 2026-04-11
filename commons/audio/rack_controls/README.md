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

Used by `UniversalVRAudioController` and `RackLayoutCalculator` to build modular synth rack interfaces. Controls emit value-change signals and accept normalized values (0.0–1.0 or bipolar -1.0–1.0).
