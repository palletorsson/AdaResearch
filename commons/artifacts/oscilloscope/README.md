# Oscilloscope

A virtual CRT oscilloscope with multiple display modes (Waveform, Lissajous, XY Plot), interactive VR sliders, and classic phosphor glow aesthetics. Teaches waveform visualization, frequency ratios, and Lissajous curve patterns formed by harmonic relationships.

## How It Works

The display renders waveforms by sampling mathematical oscillator functions (sine, square, sawtooth, triangle) at 512 points per frame onto a SubViewport with CRT-style visual effects. In Lissajous mode, two frequencies are combined as x = sin(at + phase) and y = sin(bt), where the ratio b/a determines the pattern shape -- integer ratios like 2:1 (octave) or 3:2 (perfect fifth) produce stable closed curves. The phosphor trace is drawn with multiple glow passes for a realistic CRT look, complete with scanlines, grid overlay, vignette corners, and configurable phosphor colors (green, amber, blue, white). The SubViewport texture is projected onto a 3D screen mesh with emission for in-world visibility.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `initial_mode` | int | 0 |
| `initial_freq_a` | float | 440.0 |
| `initial_freq_b` | float | 660.0 |
| `initial_amplitude` | float | 0.8 |
| `phosphor_style` | String | "green" |
| `show_3d_trace` | bool | false |

## Features

- Three display modes: Waveform, Lissajous, and XY Plot
- Four wave shapes: sine, square, sawtooth, triangle
- VR sliders for frequency A/B, amplitude, phase, and time division
- Logarithmic frequency mapping (20-2000 Hz) for musical control
- Harmonic presets: octave, fifth, fourth, major third, unison, tritone
- CRT phosphor glow with persistence trails and scanline effects
- Optional 3D Lissajous trace rendered in world space
- Four phosphor color styles: green, amber, blue, white

## Files

- `oscilloscope_artifact.gd` — Main artifact script with VR controls and grid config
- `oscilloscope_display.gd` — Display rendering engine (waveform, Lissajous, XY drawing)
- `oscilloscope_artifact.tscn` — Scene file
