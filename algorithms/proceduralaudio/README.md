# Procedural Audio Algorithms

This directory contains 3D visualizations of various procedural audio synthesis and analysis techniques. Each algorithm demonstrates core concepts of computational audio generation and digital signal processing.

## Algorithms Included

### Synthesis Methods
- **Additive Synthesis** (`additive_synthesis/`) - Building complex sounds by summing sine waves
- **Subtractive Synthesis** (`subtractive_synthesis/`) - Shaping sounds by filtering rich harmonics
- **FM Synthesis** (`fm_synthesis/`) - Frequency modulation synthesis for complex timbres
- **Granular Synthesis** (`granular_synthesis/`) - Microsound techniques and grain-based synthesis

### Audio Processing
- **Audio Effects** (`audio_effects/`) - Real-time audio processing effects (reverb, delay, chorus, distortion)
- **Psychoacoustics** (`psychoacoustics/`) - Human auditory perception and masking effects

### Generative Systems
- **Generative Music** (`generative_music/`) - Algorithmic composition and rule-based music generation

## Technical Implementation

Each algorithm is implemented as:
- `.tscn` file: 3D scene with visual elements (oscilloscopes, spectrometers, particle systems)
- `.gd` file: GDScript implementing synthesis algorithms and real-time visualization

## VR Compatibility

All visualizations are designed for XR environments:
- Automatic, self-running demonstrations
- No desktop UI dependencies
- 3D spatial representation of audio concepts
- Real-time parameter visualization

## Educational Focus

These visualizations help understand:
- Digital signal processing concepts
- Synthesis parameter relationships
- Audio perception and psychoacoustics
- Real-time audio programming principles

## Usage

Load any `.tscn` file in Godot 4 to see the algorithm in action. Each scene demonstrates the core principles through animated 3D representations of waveforms, frequency spectra, and synthesis parameters.
