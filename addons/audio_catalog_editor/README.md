# 🎧 Audio Catalog Editor

**Version 1.0**

The **Audio Catalog Editor** is a custom Godot editor plugin designed to streamline the management, preview, and editing of the procedural audio system in AdaResearch. It provides a visual interface for interacting with the JSON-based sound parameters and the underlying generator systems.

## 🌟 Features

- **Preset Browser**: Browse all sound parameter JSON files organized by category (Basic, Drums, Synths, etc.).
- **Real-time Preview**: Listen to generated sounds directly in the editor without running the game.
- **Visualizations**: View real-time **Waveform** and **Frequency Spectrum** analysis of the generated audio.
- **Parameter Editing**: Tweak sound parameters (frequency, envelope, modulation) and hear changes instantly.
- **Export/Import**: Save modified parameters back to JSON or export new presets.
- **Generators Support**: Native support for:
    - `AudioSynthesizer` (Classic Synths)
    - `TechnoNoirGenerator` (Cyberpunk Ambience)
    - `TrapBeatsGenerator` (Rhythm & Percussion)
    - `CustomSoundGenerator` (General Purpose)

## 🛠️ Usage

Once enabled in **Project Settings > Plugins**, the editor appears as a main screen plugin (look for "Audio Catalog" next to "2D", "3D", "Script", "AssetLib").

### 1. Audio Preset Tab
This is the main interface for sound design.
- **Left Panel**: Tree view of all detected JSON presets in `res://commons/audio/parameters/`.
- **Center Panel**:
    - **Header**: Shows file path and metadata (sound key, description, tags).
    - **Action Bar**: Play, Stop, Save, Export JSON.
    - **Visualizers**: See the shape and frequency content of your sound.
    - **Parameters**: Dynamic sliders and input fields for every parameter defined in the JSON. Changes here update the sound immediately.

### 2. Sequencer Tab (Rhythm Machine)
A 16-step drum sequencer for creating beats.
- **Tracks**: Dedicated rows for Kick, Snare, HiHat, OpenHat, and Clap.
- **Grid**: Click buttons to toggle steps (16 steps per bar).
- **Controls**: Play/Stop, Clear, and Tempo adjust (BPM).
- **Genre Presets**: One-click patterns for **Techno**, **House**, **Trap**, **Breakbeat**, and **Minimal**.
- **Melody Timeline**: Visualizes melodic events synchronized with the beat.

### 3. Soundtracks Tab
Manages and previews complex ambient presets (from `ambient_presets.json`).
- **Browser**: List of all available ambient presets.
- **Details View**: Shows description and composition layers.
- **Layer Control**: Double-click any layer (Continuous or Random Event) to preview it in isolation.
- **Arpeggiator**: Use the "Loop" icon to play a generated arpeggio of the sound.
- **Full Playback**: "Play Full Soundtrack" to hear the entire soundscape composed of multiple layers.


## 📁 File Structure

The editor reads from and writes to:
`res://commons/audio/parameters/`

It automatically detects categories based on the directory structure (e.g., `basic/`, `drums/`, `synthesizers/`).

## 🔧 Technical Details

- **Plugin Entry Point**: `plugin.gd`
- **Main Dock Logic**: `audio_catalog_dock.gd`
- **Generators Used**:
    - `commons/audio/generators/TechnoNoirGenerator.gd`
    - `commons/audio/generators/TrapBeatsGenerator.gd`
    - `commons/audio/generators/CustomSoundGenerator.gd`

## 📝 Troubleshooting

- **No Sound?**: Ensure your volume is up and the specific generator script is working. Check the Output console for any generation errors.
- **"Dirty" State**: If you modify parameters, the preset name in the tree will have an asterisk (*). Don't forget to **Save** if you want to keep your changes.
