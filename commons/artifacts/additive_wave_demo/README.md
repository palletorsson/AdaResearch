# Additive Wave Demo

Interactive demonstration of additive wave synthesis, teaching Fourier's principle that any complex waveform can be built by summing simple sine waves at integer multiples of a fundamental frequency: f(t) = A1 sin(wt) + A2 sin(2wt) + ... + A5 sin(5wt).

## How It Works

Five VR sliders control the amplitude of harmonics 1 through 5. The combined waveform renders as an animated line, with individual harmonic components displayed as color-coded lines below it. A formula label updates in real time showing the active terms. Preset detection identifies when the current harmonic mix approximates a square wave (odd harmonics at 1/n), sawtooth (all harmonics at 1/n), or triangle wave (odd harmonics at 1/n squared).

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `fundamental_slider_path` | NodePath | `"ControlPanel/FundamentalSlider"` |
| `harmonic2_slider_path` | NodePath | `"ControlPanel/Harmonic2Slider"` |
| `harmonic3_slider_path` | NodePath | `"ControlPanel/Harmonic3Slider"` |
| `harmonic4_slider_path` | NodePath | `"ControlPanel/Harmonic4Slider"` |
| `harmonic5_slider_path` | NodePath | `"ControlPanel/Harmonic5Slider"` |

## Features

- Real-time animated waveform using ImmediateMesh line strips
- Color-coded component waves (green, blue, pink, yellow, purple) for each harmonic
- Live formula display showing active terms
- Automatic waveform preset detection (sine, square, sawtooth, triangle)
- Programmatic preset API via `set_preset()` and `toggle_components()`
- Grid configuration support via `apply_grid_config()`

## Files

- `additive_wave_demo.gd` -- Main script
- `additive_wave_demo.tscn` -- Scene file
