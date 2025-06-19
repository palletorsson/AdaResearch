# Spectral Audio Analyzer System

A comprehensive real-time audio visualization system for the AdaResearch VR educational platform, featuring dual complementary displays that analyze and visualize game audio in both frequency and spectral-temporal domains.

## Overview

This system provides two distinct but complementary audio visualizers:

1. **Frequency Spectrum Analyzer** (Green) - Traditional FFT frequency bars showing audio content
2. **Spectral Sine Wave** (Cyan) - Innovative sine wave where amplitude is modulated by cycling through frequency spectrum values over time

Both visualizers analyze the Master Bus in real-time, capturing all game audio including ambient sounds, teleporter drones, pickup effects, and any other audio sources.

## Features

### Enhanced Grid Systems
- **Professional Grid Lines**: Both displays feature comprehensive grid systems with frequency/time and amplitude markers
- **Frequency Labels**: Spectrum analyzer shows 0Hz, 2kHz, 4kHz, 6kHz, 8kHz frequency divisions
- **Amplitude Markers**: Clear amplitude level indicators (0.2, 0.4, 0.6, 0.8) for precise readings
- **Time Scale Information**: Spectral sine wave includes time progression markers and current time display
- **Color-Coded Themes**: Green for spectrum analysis, cyan for spectral sine wave

### Advanced Audio Analysis
- **Master Bus Monitoring**: Analyzes ALL game audio through the Master Bus
- **Shared Spectrum Analyzers**: Intelligent detection and sharing of audio analysis resources
- **Enhanced Sensitivity**: 50x magnitude boosting for detecting even quiet audio sources
- **Smart Baseline**: Minimum 10% baseline activity ensures visual feedback even with low audio
- **Debug Monitoring**: Real-time debug output showing audio detection statistics

### Real-Time Performance
- **30 FPS Updates**: Smooth real-time visualization
- **Optimized Processing**: Efficient audio analysis with minimal performance impact
- **VR-Optimized**: Designed specifically for VR environments and spatial audio

## Core Concept: Spectral Sine Wave

The spectral sine wave represents a unique approach to audio visualization that bridges frequency and time domains:

### Traditional Approaches
- **Time Domain**: Shows amplitude changes over time (waveforms)
- **Frequency Domain**: Shows frequency content at specific moments (spectrum analyzers)

### Our Spectral Sine Wave Approach
- **Spectral-Temporal Domain**: Uses frequency spectrum magnitudes to modulate sine wave amplitude over time
- **Educational Value**: Demonstrates the relationship between frequency content and wave amplitude
- **Visual Innovation**: Creates a "breathing" sine wave that responds to audio frequency content

### Mathematical Foundation
```
For each display position i:
  time_position = i / sample_count
  freq_index = (time_position + time_offset) * 64 % 64
  freq_hz = (freq_index / 64) * 8000Hz
  magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(freq_hz, freq_hz + 125Hz)
  amplitude = magnitude * sensitivity_boost
  waveform[i] = sin(time_position * 4π + time_offset) * amplitude
```

## Technical Architecture

### Scene Structure
```
spectral_sine_wave.tscn:
├── SpectralSineWave (Node3D)
├── WaveformViewport (SubViewport)
│   └── WaveformDisplay (Control) - WaveformDisplay.gd
├── WaveformDisplayMaterial (MeshInstance3D) - SpectralDisplayController.gd
└── Label3D

spectrum_display.tscn:
├── SpectrumDisplay (Node3D)
├── AudioDisplay (SubViewport)
│   └── GameSoundMeter (Control) - GameSoundMeter.gd
├── SpectrumDisplayMaterial (MeshInstance3D) - SpectralDisplayController.gd
└── Label3D
```

### Key Components

#### WaveformDisplay.gd
- **Audio Analysis**: Connects to Master Bus spectrum analyzer
- **Spectral Sine Wave Generation**: Cycles through frequency bands to modulate sine wave amplitude
- **Real-time Rendering**: 256-sample sine wave updated at 30 FPS
- **Debug Monitoring**: Tracks audio magnitude, active frequency bands, and waveform values
- **Enhanced Sensitivity**: Multiple boosting stages for optimal visual response

#### GameSoundMeter.gd
- **Traditional Spectrum Analysis**: 64-band frequency spectrum with FFT analysis
- **Grid System**: Professional frequency and amplitude grid with labels
- **Multiple Display Modes**: Spectrum lines, bars, VU meter, waveform, oscilloscope
- **Enhanced Lower Frequency Response**: 2x amplification for bass frequencies
- **Master Bus Integration**: Analyzes all game audio sources

#### SpectralDisplayController.gd
- **Viewport Texture Linking**: Connects SubViewport rendering to 3D display materials
- **Material Configuration**: Sets up emission, unshaded rendering, and transparency
- **Multi-Display Support**: Handles both spectrum and waveform viewports independently

### Audio Analysis Features

#### Spectrum Analyzer Sharing
- **Intelligent Detection**: Automatically finds existing spectrum analyzers on Master Bus
- **Resource Efficiency**: Shares analysis between multiple displays when possible
- **Fallback Creation**: Creates dedicated analyzer if none exists
- **Configuration Sync**: Ensures consistent FFT size and buffer settings

#### Enhanced Sensitivity System
```gdscript
# Multi-stage audio boosting
boosted_magnitude = raw_magnitude * 50.0  # Initial sensitivity boost
db_value = 20.0 * log(boosted_magnitude) / log(10.0)
normalized = clamp((db_value + 40.0) / 40.0, 0.0, 1.0)  # -40dB to 0dB range
baseline = 0.1 + normalized * 0.9  # 10% minimum + 90% audio-responsive
```

#### Debug and Monitoring
- **Real-time Statistics**: Average magnitude, active frequency bands, waveform peaks
- **Audio Detection Status**: Clear indication of audio source availability
- **Performance Metrics**: FPS monitoring and processing efficiency
- **Fallback Patterns**: Test patterns when no audio is detected

## Grid Artifacts Integration

Both displays are integrated into the AdaResearch grid system:

```json
{
  "spectrum_display": {
    "name": "Frequency Spectrum Analyzer",
    "description": "Real-time frequency analysis of game audio",
    "scene_path": "res://algorithms/wavefunctions/spectralanalysis/spectrum_display.tscn",
    "category": "audio_analysis"
  },
  "spectral_sine_wave": {
    "name": "Spectral Sine Wave",
    "description": "Sine wave modulated by spectral frequency content",
    "scene_path": "res://algorithms/wavefunctions/spectralanalysis/spectral_sine_wave.tscn",
    "category": "audio_analysis"
  }
}
```

## Educational Applications

### STEM Learning Concepts
- **Signal Processing**: Real-time demonstration of FFT and frequency analysis
- **Wave Physics**: Relationship between frequency, amplitude, and wave behavior
- **Mathematics**: Trigonometric functions, logarithmic scaling, and data visualization
- **Computer Science**: Real-time processing, optimization, and resource sharing

### VR Educational Benefits
- **Spatial Understanding**: 3D visualization of abstract audio concepts
- **Interactive Learning**: Students can move around and observe from different angles
- **Real-time Feedback**: Immediate visual response to audio changes in the environment
- **Comparative Analysis**: Side-by-side comparison of different visualization approaches

### Practical Demonstrations
- **Audio Source Identification**: Visual identification of different game audio sources
- **Frequency Content Analysis**: Understanding which frequencies are present in different sounds
- **Amplitude Relationships**: How spectral content translates to wave amplitude
- **Time-Frequency Evolution**: How audio content changes over time

## Usage Instructions

### In VR Environment
1. **Navigate** to maps containing the audio analyzers (e.g., Tutorial_2D)
2. **Observe** the green spectrum display showing traditional frequency bars
3. **Compare** with the cyan spectral sine wave showing frequency-modulated amplitude
4. **Listen** to game audio (teleporter drones, pickup sounds) and watch the displays respond
5. **Move** around to experience the visualizations from different spatial perspectives

### Debug Information
Enable debug output to see:
- Audio magnitude levels
- Active frequency band counts
- Spectrum analyzer connection status
- Real-time performance metrics

### Configuration Options
- **Amplitude Scale**: Adjust display sensitivity
- **Time Scale**: Control sine wave animation speed
- **Color Themes**: Customize display colors
- **Grid Density**: Modify grid line spacing
- **Update Rate**: Adjust refresh frequency

## Performance Considerations

### Optimization Features
- **Shared Resources**: Multiple displays share audio analysis when possible
- **Efficient Rendering**: Optimized drawing routines for VR frame rates
- **Smart Updates**: Intelligent refresh scheduling based on audio activity
- **Memory Management**: Efficient array handling for real-time processing

### VR-Specific Optimizations
- **Stereo Rendering**: Efficient handling of dual-eye rendering
- **Distance Culling**: Optional performance optimization for distant displays
- **Frame Rate Targeting**: Maintains stable 90 FPS for smooth VR experience

## Future Enhancements

### Potential Extensions
- **3D Spectrograms**: Time-frequency-amplitude visualization in 3D space
- **Harmonic Analysis**: Detection and visualization of harmonic relationships
- **Real-time Filtering**: Interactive frequency filtering and audio modification
- **Spatial Audio Visualization**: Direction-aware audio analysis for VR environments
- **Machine Learning Integration**: AI-powered audio pattern recognition and classification

### Educational Expansions
- **Guided Tutorials**: Step-by-step learning modules for audio analysis concepts
- **Interactive Experiments**: Student-driven audio analysis challenges
- **Collaborative Learning**: Multi-user VR sessions with shared audio visualizations
- **Assessment Tools**: Quantitative measures of student understanding

## Technical Requirements

- **Godot Engine**: Version 4.4+ with VR support
- **Audio System**: Real-time audio processing capabilities
- **VR Hardware**: OpenXR-compatible VR headset
- **Performance**: Minimum 90 FPS capability for smooth VR experience

## Troubleshooting

### Common Issues
- **Flat Waveform**: Check audio source availability and Master Bus configuration
- **Performance Drops**: Verify VR system requirements and reduce display complexity if needed
- **Audio Conflicts**: Ensure proper spectrum analyzer sharing between displays
- **Visual Artifacts**: Check viewport resolution and material settings

### Debug Commands
Enable debug output to diagnose issues:
- Audio magnitude tracking
- Spectrum analyzer connection status
- Performance metrics
- Resource usage statistics

This spectral audio analyzer system represents a significant advancement in educational VR audio visualization, combining traditional frequency analysis with innovative spectral-temporal display techniques to create an engaging and informative learning experience. 