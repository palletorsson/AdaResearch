# Audio Interfaces

VR and desktop audio visualization displays and control surfaces.

## VR Displays

| Script | Scene | Purpose |
|--------|-------|---------|
| `VRAudioMonitor.gd` | `VRAudioMonitor.tscn` | Main VR monitor — SubViewport with waveform display |
| `VRWaveformDisplay.gd` | `VRWaveformDisplay.tscn` | Time-domain waveform in 3D |
| `VRSpectrumDisplay.gd` | `VRSpectrumDisplay.tscn` | Frequency spectrum analyzer in 3D |
| `VRLissajousDisplay.gd` | `VRLissajousDisplay.tscn` | Phase relationship Lissajous figure |
| `VRSimpleWaveform.gd` | `VRSimpleWaveform.tscn` | Lightweight waveform display |
| `VRAudioControlDial.gd` | `VRAudioControlDial.tscn` | 3D rotary dial control |

## Scene Variants

- `VRAudioMonitorUI.tscn` — UI-layer variant of the monitor
- `VRSimpleWaveformSmall.tscn` — Compact waveform
- `VRSpectrumDisplaySmall.tscn`, `VRSpectrumDisplayWide.tscn` — Size variants
- `VRAudioControlSlider.tscn`, `VRAudioControlSliderVertical.tscn` — Slider controls

## Desktop Displays

- `SimpleWaveformDisplay.gd` — 2D waveform for desktop UI

## Coordinators

| Script | Purpose |
|--------|---------|
| `ModularSoundDesignerInterface.gd` | Composes modular components (`../components/`) into a unified interface |
| `SoundDesignerInterface.gd` | Original monolithic sound designer (legacy) |

## Subdirectories

- `materials/` — Shared visual materials for rack and display surfaces

## Usage

VR displays are instantiated by `UniversalVRAudioController.gd` (audio root) as part of the modular synth rack. They connect to the Godot audio bus system for real-time monitoring.
