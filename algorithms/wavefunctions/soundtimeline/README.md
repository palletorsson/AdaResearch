# Sound Timeline Visualizer

A comprehensive real-time audio visualization system for Godot that displays sound as a colorful timeline with waveform and frequency spectrum analysis.

## Features

### Visual Components
- **Real-time Waveform Display**: Shows audio amplitude over time
- **Rainbow Frequency Spectrum**: Displays frequency content with color-coded bands
- **Interactive Timeline**: Click and drag to scrub through audio
- **Playhead Indicator**: Shows current playback position
- **Time Markers**: Grid lines with time labels
- **Zoom and Scroll Controls**: Navigate through long audio recordings

### Audio Processing
- **Real-time Audio Capture**: Records system audio using AudioEffectCapture
- **FFT Frequency Analysis**: Breaks down audio into frequency bands
- **Smoothing and Filtering**: Reduces noise in frequency display
- **Beat Detection**: Identifies rhythmic patterns
- **Peak Finding**: Locates amplitude peaks in waveform

### Interactive Controls
- **Space**: Play/Pause timeline playback
- **R**: Start/Stop recording
- **C**: Clear timeline data
- **Mouse Click**: Set playback position
- **Mouse Drag**: Scrub through timeline
- **Zoom Slider**: Adjust timeline scale
- **Scroll Slider**: Navigate through timeline

## Files

### Core Components
- `SoundTimelineVisualizer.gd`: Main visualizer class with drawing and audio processing
- `TimelineController.gd`: UI controller that connects buttons to visualizer
- `AudioAnalyzer.gd`: Audio analysis utilities (FFT, peak detection, etc.)

### Scenes
- `sound_timeline.tscn`: Complete timeline interface with controls
- `timeline_demo.tscn`: Demo scene with example audio generators

### Demo
- `timeline_demo.gd`: Demonstration with various audio patterns

## Usage

### Basic Setup
1. Add the `sound_timeline.tscn` to your scene
2. The timeline will automatically start recording system audio
3. Use the control buttons to play, pause, record, and clear
4. Click on the timeline to scrub to different positions

### In Code
```gdscript
# Create timeline visualizer
var timeline = SoundTimelineVisualizer.new()
add_child(timeline)

# Start recording
timeline.start_recording()

# Control playback
timeline.start_playback()
timeline.stop_playback()

# Clear data
timeline.clear_timeline()

# Export timeline data
var data = timeline.export_timeline_data()
```

### Audio Configuration
The visualizer can be customized with various parameters:

```gdscript
# Timeline appearance
timeline.timeline_width = 1200
timeline.timeline_height = 300
timeline.waveform_color = Color.CYAN
timeline.background_color = Color(0.1, 0.1, 0.1, 1.0)

# Frequency analysis
timeline.fft_size = 1024
timeline.frequency_bands = 64
timeline.frequency_smoothing = 0.8
timeline.amplitude_scale = 100.0

# Playback controls
timeline.zoom_level = 1.0
timeline.auto_scroll = true
```

## Audio Analysis Features

### Frequency Spectrum
- **64 frequency bands** mapped to rainbow colors
- **Logarithmic frequency scaling** for better musical representation
- **Real-time smoothing** to reduce flickering
- **Adjustable amplitude scaling** for different audio levels

### Waveform Display
- **High-resolution waveform** showing audio amplitude
- **Scrollable timeline** for long recordings
- **Grid lines** with time markers
- **Interactive scrubbing** with mouse

### Data Export
- Export timeline data as Dictionary
- Includes audio buffer, frequency data, and metadata
- Can be saved to file or processed further

## Demo Sounds

The demo includes several test audio patterns:

1. **Sine Wave Sweep**: Frequency sweep from 220Hz to 880Hz
2. **Drumbeat Pattern**: Rhythmic percussion pattern
3. **Chord Progression**: Musical chord sequence
4. **White Noise Burst**: Noise burst for testing

Use keyboard shortcuts:
- **1-4**: Trigger demo sounds
- **Space**: Play/pause
- **R**: Record/stop
- **C**: Clear timeline

## Technical Details

### Audio Capture
- Uses Godot's `AudioEffectCapture` on the Master bus
- Converts stereo to mono for visualization
- Buffers audio data with configurable maximum length
- Processes audio at 44.1kHz sample rate

### Frequency Analysis
- Simple frequency binning for real-time performance
- Configurable FFT size (default 1024 samples)
- Logarithmic frequency mapping for musical visualization
- Smoothing filter to reduce noise

### Performance
- Optimized for real-time display
- Configurable buffer sizes to manage memory usage
- Efficient drawing with minimal allocations per frame
- Adjustable quality settings for different hardware

## Integration

### With Existing Audio
The timeline can visualize any audio playing through Godot's audio system:

```gdscript
# Play audio and visualize it
var player = AudioStreamPlayer.new()
add_child(player)
player.stream = load("res://my_audio.ogg")
player.play()

# Timeline will automatically capture and display it
```

### Custom Audio Processing
Extend the visualizer with custom analysis:

```gdscript
# Add custom frequency analysis
func custom_analysis(samples: PackedFloat32Array):
    var spectrum = AudioAnalyzer.analyze_spectrum(samples, 44100, 64)
    var beats = AudioAnalyzer.detect_beats(spectrum, previous_spectrum)
    # Process results...
```

## Troubleshooting

### No Audio Visible
- Check that audio is playing through the Master bus
- Verify AudioEffectCapture is properly added
- Ensure microphone permissions if recording input

### Performance Issues
- Reduce `frequency_bands` count
- Lower `fft_size` value
- Decrease `timeline_width` resolution
- Increase `frequency_smoothing` value

### Audio Latency
- Adjust audio buffer sizes in Project Settings
- Use smaller `fft_size` for lower latency
- Enable "Real Time" priority in audio settings

## Future Enhancements

Planned features for future versions:
- Audio file loading and playback
- Multi-track timeline support
- MIDI note detection and display
- Advanced audio effects visualization
- Timeline export to video/image formats
- Custom color schemes and themes
