# Spectral Analysis

A suite of real-time audio visualisation tools that teach **frequency spectrum analysis**, **Fourier decomposition**, and **signal processing** by capturing live audio from the Godot audio bus system and rendering it as frequency spectra, waveforms, VU meters, and oscilloscope displays.

## How It Works

The system uses Godot's `AudioEffectSpectrumAnalyzer` to perform real-time FFT (Fast Fourier Transform) on audio streams. The analyzer samples magnitude data across frequency bands, converts it to decibels, normalises it, and feeds it to visual renderers.

**SpectralMeter** is a lightweight spectrum line display that reads magnitude data from a dedicated analysis bus. It samples 64 frequency bars across 0--11 kHz, converts magnitudes to normalised dB values, and draws connected lines with peak indicators. It includes distance-based culling to skip updates when the player is far away.

**GameSoundMeter** is a full-featured multi-mode display supporting 5 visualisation styles: spectrum line, spectrum bars, waveform, VU meter, and oscilloscope. It uses logarithmic frequency scaling (20 Hz to 20 kHz, the full human hearing range), boosts lower frequencies for visibility, and draws labelled grids with frequency markers. It can auto-detect teleport cube audio sources and monitor the master bus directly.

**WaveformDisplay** creates a sine wave whose amplitude is modulated by spectral data over time. It cycles through 64 frequency bands, sampling magnitude at each position, and uses the result to scale a scrolling sine wave -- a visual metaphor for how sound is composed of many frequencies.

**SpectralAnalyzerController** is a scene controller that ties the meters together. It auto-detects nearby `AudioStreamPlayer3D` nodes, manages activation/deactivation based on player proximity, and maps viewport textures onto 3D display surfaces.

**SpectralDisplayController** bridges a `SubViewport` to a `MeshInstance3D` by assigning the viewport's texture as both albedo and emission on an unshaded material, creating a glowing in-world screen.

## Parameters

### SpectralMeter
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `target_audio_player` | AudioStreamPlayer3D | -- | Audio source to analyse |
| `bar_count` | int | 64 | Number of frequency bars |
| `update_rate` | float | 30.0 | Analysis updates per second |
| `line_color` | Color | green | Spectrum line colour |
| `height_multiplier` | float | 200.0 | Vertical scale factor |
| `smoothing_factor` | float | 0.85 | Animation smoothing (0--1) |
| `max_distance_from_player` | float | 50.0 | Distance culling threshold |

### GameSoundMeter
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `display_style` | enum | SPECTRUM_LINE | Visual mode (line/bars/waveform/VU/oscilloscope) |
| `bar_count` | int | 32 | Number of frequency bars |
| `monitor_master_bus` | bool | false | Analyse all game audio |
| `update_fps` | float | 30.0 | Updates per second |
| `max_display_distance` | float | 50.0 | Distance culling threshold |

### WaveformDisplay
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `sample_count` | int | 256 | Waveform resolution |
| `amplitude_scale` | float | 100.0 | Vertical amplitude |
| `time_scale` | float | 2.0 | Scrolling speed |
| `source_bus` | String | "Master" | Audio bus to monitor |

### SpectralAnalyzerController
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `activation_distance` | float | 3.0 | Player proximity to activate |
| `auto_activate` | bool | true | Activate on scene start |

## Features

- Real-time FFT-based frequency spectrum analysis
- 5 display modes: spectrum line, spectrum bars, waveform, VU meter, oscilloscope
- Logarithmic frequency scaling matching human hearing (20 Hz -- 20 kHz)
- Lower-frequency boost for better visibility
- Peak hold indicators with decay
- Glow rendering with multi-pass line drawing
- Labelled grids with frequency and amplitude markers
- Distance-based performance culling
- Auto-detection of nearby audio sources
- Viewport-to-3D-mesh texture mapping for in-world displays
- Test pattern fallback when no audio is active
- Master bus monitoring for whole-scene analysis

## Files

| File | Description |
|------|-------------|
| `SpectralMeter.gd` | Lightweight spectrum line display with distance culling |
| `GameSoundMeter.gd` | Multi-mode audio visualiser with logarithmic scaling and grid labels |
| `WaveformDisplay.gd` | Scrolling sine wave modulated by spectral magnitude data |
| `SpectralAnalyzerController.gd` | Scene controller for activation, audio detection, and display management |
| `SpectralDisplayController.gd` | Viewport texture bridge to 3D display mesh |
