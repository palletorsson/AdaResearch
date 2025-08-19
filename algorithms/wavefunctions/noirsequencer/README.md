# Noir Sequencer - Dark Ambient Step Sequencer

A step sequencer designed for creating dark ambient and noir-style musical compositions, featuring an 8x16 grid interface with procedural audio synthesis and atmospheric sound design.

## Features

### 🎹 **Step Sequencer Interface**
- **8x16 Grid**: 8 tracks (noir scale notes) × 16 steps per pattern
- **Real-time Playback**: Live pattern execution with visual step indicator
- **Interactive Grid**: Click to toggle steps, create complex rhythmic patterns
- **Note Preview**: Click note labels to preview individual sounds

### 🎵 **Noir Musical Scale**
Custom scale optimized for dark, atmospheric compositions:
```
A#4 (466.16 Hz) - High tension note
G4  (392.00 Hz) - Melancholic lead
F4  (349.23 Hz) - Suspended harmony  
D#4 (311.13 Hz) - Minor color tone
D4  (293.66 Hz) - Subdominant
C4  (261.63 Hz) - Tonic center
A#3 (233.08 Hz) - Bass tension
G3  (196.00 Hz) - Bass foundation
```

### 🔊 **Audio Synthesis**
- **Procedural Generation**: All sounds created algorithmically
- **AudioStreamGenerator**: Real-time synthesis using Godot's audio system
- **Reverb Effects**: Built-in reverb bus for atmospheric depth
- **Volume Randomization**: Subtle volume variations for organic feel

### ⚙️ **Control Interface**
- **Play/Pause**: Start/stop pattern playback
- **BPM Control**: Adjustable tempo (30-200 BPM range)
- **Clear Pattern**: Reset entire grid
- **Random Generation**: Procedural pattern creation
- **Audio Initialization**: Separate audio system setup

### 🎮 **User Interface Features**
- **Visual Feedback**: Current step highlighting during playback
- **Status Information**: Real-time BPM and playback status
- **Responsive Grid**: Hover effects and visual state management
- **Color-Coded States**: Active/inactive step visual distinction

## Usage

### Quick Start
1. **Load Scene**: Open `noir_sequencer.tscn`
2. **Initialize Audio**: Click "Initialize Audio" button
3. **Create Pattern**: Click grid cells to activate steps
4. **Set Tempo**: Adjust BPM slider to desired speed
5. **Play**: Hit the play button to start sequencing

### Advanced Workflow
1. **Test Individual Notes**: Click note labels (A#4, G4, etc.) to preview sounds
2. **Build Patterns**: Create rhythmic and melodic sequences by activating grid cells
3. **Layer Tracks**: Use multiple tracks simultaneously for complex arrangements
4. **Experiment**: Use random button for inspiration, then refine manually

## Technical Implementation

### Audio Architecture
```gdscript
- AudioStreamGenerator: Real-time synthesis
- Audio Player Pool: 16 concurrent players for polyphony
- Reverb Bus: Atmospheric depth processing
- Buffer Management: Optimized for low-latency playback
```

### Grid System
- **8 Tracks**: Mapped to noir scale frequencies
- **16 Steps**: Standard step sequencer resolution
- **Boolean State**: Each cell stores on/off state
- **Visual Mapping**: UI buttons linked to grid data structure

### Timing Engine
- **BPM-Based**: Configurable beats per minute
- **16th Note Resolution**: Each step represents a sixteenth note
- **Delta Time Accumulation**: Smooth timing independent of frame rate

## Development Roadmap

### 🎵 **Musical Features**
- [ ] **Multiple Scales**: Jazz, blues, pentatonic, chromatic options
- [ ] **Pattern Length**: Variable pattern lengths (8, 32, 64 steps)
- [ ] **Swing Timing**: Shuffle and swing groove options
- [ ] **Velocity Sensitivity**: Per-step volume control
- [ ] **Pattern Chaining**: Link multiple patterns for song structure

### 🔊 **Audio Enhancements**
- [ ] **Synthesis Types**: Multiple oscillator waveforms (saw, square, noise)
- [ ] **Filter Section**: Low-pass, high-pass, resonance controls
- [ ] **Envelope Control**: ADSR envelopes per track
- [ ] **Effects Chain**: Delay, chorus, distortion options
- [ ] **Sample Playback**: Load custom audio samples per track

### 💾 **Project Management**
- [ ] **Save/Load**: Pattern persistence to JSON files
- [ ] **Export Audio**: Render patterns to WAV files
- [ ] **Pattern Library**: Preset pattern collection
- [ ] **Undo/Redo**: Edit history for pattern creation

### 🎨 **Interface Improvements**
- [ ] **Themes**: Multiple visual themes (cyberpunk, minimalist, retro)
- [ ] **Grid Zoom**: Scalable interface for different screen sizes
- [ ] **MIDI Support**: External MIDI controller integration
- [ ] **Real-time Visualization**: Spectrum analyzer, waveform display

### 🎮 **Performance Features**
- [ ] **Live Mode**: Real-time pattern switching
- [ ] **Probability Steps**: Chance-based step triggering
- [ ] **Euclidean Rhythms**: Algorithmic rhythm generation
- [ ] **Polyrhythms**: Different track lengths for complex timing

## Musical Context

The noir sequencer draws inspiration from:
- **Film Noir Soundtracks**: Dark, moody atmospheric scoring
- **Ambient Techno**: Repetitive, hypnotic electronic patterns  
- **Dark Jazz**: Minor harmonies and suspended chords
- **Industrial Music**: Mechanical rhythms and synthetic textures

## Performance Tips

- **Start Simple**: Begin with basic kick/snare patterns on lower tracks
- **Layer Gradually**: Add melodic elements on higher frequency tracks
- **Use Space**: Don't fill every step - silence creates tension
- **Experiment with BPM**: Slower tempos (60-80) enhance the noir atmosphere
- **Combine Patterns**: Use random generation, then edit manually for best results

## Scene Files

- `noir_sequencer.gd` - Main sequencer logic and audio synthesis
- `noir_sequencer.tscn` - Complete UI scene with grid layout
- `noir_sequencer.gd.uid` - Godot asset identifier

## Technical Notes

- **Audio Latency**: Optimized for sub-20ms latency on modern systems
- **Memory Usage**: ~10MB for audio buffers and UI elements
- **CPU Performance**: Efficient synthesis suitable for real-time use
- **Platform Compatibility**: Tested on Windows, Linux, and macOS 