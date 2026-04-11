# Audio Components

Modular, reusable UI components for audio control and visualization.

## Files

| Script | Purpose |
|--------|---------|
| `AudioVisualizationComponent.gd` | Real-time waveform and spectrum display — monitors master bus with FFT analysis |
| `ParameterControlsComponent.gd` | Column-based sound parameter sliders and option buttons with preset support |
| `FileManagerComponent.gd` | JSON preset save/load, audio export (.tres, .wav), clipboard integration |
| `RealtimeSynthesizerComponent.gd` | Live synthesis control component |
| `SoundParameterManager.gd` | Parameter dictionary management and validation |
| `AudioLoadingIndicator.gd` | Loading progress indicator (scene: `AudioLoadingIndicator.tscn`) |

## Architecture

These components follow a modular pattern — each handles one responsibility and communicates via signals. They are composed together by coordinator interfaces like `ModularSoundDesignerInterface` in `interfaces/`.

See `README_ModularAudioInterface.md` for the before/after comparison and migration notes from the monolithic interface.
