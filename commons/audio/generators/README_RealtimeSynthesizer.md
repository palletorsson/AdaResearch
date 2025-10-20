# Realtime Audio Synthesizer Integration

This document explains how to use the new RealtimeAudioSynthesizer with your existing audio system.

## Files Created

1. **RealtimeAudioSynthesizer.gd** - The main synthesizer class
2. **RealtimeSynthesizerTest.gd** - Simple test script with UI controls
3. **RealtimeSynthesizerComponent.gd** - Integration component for existing audio interface
4. **RealtimeAudioSynthesizer.tscn** - Scene file for the synthesizer
5. **RealtimeSynthesizerTest.tscn** - Test scene

## Basic Usage

### Simple Integration

```gdscript
# Add to any scene
var synthesizer = RealtimeAudioSynthesizer.new()
add_child(synthesizer)

# Set a pattern
synthesizer.set_pattern({
    "notes": [0, 0, -7, -5, -2, -5, -2, 0, -3, 2, 1],
    "transpose": 7,
    "scale": "g:minor",
    "synth": "supersaw",
    "octave": 3
})

# Enable trance gate
synthesizer.set_trance_gate(1.5, 5, 45, 1)

# Control parameters
synthesizer.set_bpm(140)
synthesizer.set_filter(0.7)
synthesizer.set_pan(0.5)
```

### Integration with Existing Audio Interface

```gdscript
# Add the component to your existing interface
var synth_component = RealtimeSynthesizerComponent.new()
your_interface.add_child(synth_component)

# Get the synthesizer instance
var synthesizer = synth_component.export_synthesizer()

# Control via parameters (compatible with existing system)
var params = {
    "bpm": 120,
    "filter_cutoff": 0.6,
    "trance_gate_active": true
}
synth_component.set_audio_parameters(params)
```

## Pattern Format

The synthesizer uses a dictionary-based pattern format:

```gdscript
var pattern = {
    "notes": [0, 0, -7, -5, -2],  # Scale degrees
    "durations": [2, 2, 3, 1, 1], # Note durations (optional)
    "transpose": 7,                # Transposition in semitones
    "scale": "g:minor",           # Scale type
    "synth": "supersaw",          # Synthesis method
    "octave": 3,                  # Octave offset
    "trance_gate": [1.5, 5, 45, 1], # [speed, cycles, depth, shape]
    "filter_cutoff": 0.593,       # Filter cutoff (0.0-1.0)
    "delay": 0.7,                 # Delay time in seconds
    "lpenv": 2                    # Low-pass envelope
}
```

## Features

- **Real-time audio generation** using AudioStreamGenerator
- **Supersaw synthesis** with multiple detuned oscillators
- **Trance gate effects** with configurable parameters
- **Resonant low-pass filter** with biquad implementation
- **Delay effects** with feedback
- **Stereo panning** support
- **Pattern-based sequencing** with G minor scale
- **BPM control** for tempo changes
- **Integration** with existing audio parameter system

## Testing

1. Open `RealtimeSynthesizerTest.tscn` to test the basic functionality
2. Use the UI controls to adjust BPM, filter, and pattern
3. Toggle the trance gate on/off
4. Switch between the two provided patterns

## Integration Notes

- The synthesizer extends `AudioStreamPlayer` so it can be used anywhere audio is needed
- It's compatible with the existing parameter system in `ModularSoundDesignerInterface`
- The component provides a ready-to-use UI for integration
- All parameters can be controlled programmatically or via UI

## Performance

- Uses efficient biquad filtering
- Optimized delay buffer management
- Real-time audio generation with minimal CPU overhead
- Compatible with Godot's audio threading

