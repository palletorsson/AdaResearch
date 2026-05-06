# Catalog UI Components

UI widgets for the audio catalog and song authoring tools.

## Pattern Editors

| Script | Purpose |
|--------|---------|
| `BasePatternEditor.gd` | Shared base class for all pattern editors |
| `DrumPatternEditor.gd` | Drum pattern grid editing |
| `BassPatternEditor.gd` | Bass pattern editing |
| `LeadPatternEditor.gd` | Lead melody pattern editing |
| `ChordPatternEditor.gd` | Chord progression editing |
| `ArpPatternEditor.gd` | Arpeggio pattern editing |
| `ArpeggioEditor.gd` | Detailed arpeggio configuration (scene: `ArpeggioEditor.tscn`) |

## Timelines

| Script | Scene | Purpose |
|--------|-------|---------|
| `SongTimeline.gd` | — | Top-level song arrangement |
| `DrumSequencer.gd` | `DrumSequencer.tscn` | Step-based drum sequencing |
| `BassTimeline.gd` | `BassTimeline.tscn` | Bass line timeline |
| `ChordTimeline.gd` | `ChordTimeline.tscn` | Chord progression timeline |
| `MidiPianoRoll.gd` | — | MIDI piano roll display |

## Displays and Panels

| Script | Purpose |
|--------|---------|
| `SoundCard.gd` | Compact sound summary card |
| `SoundDetailPanel.gd` | Expanded sound detail view |
| `SoundBrowser.gd` | Browsable sound library |
| `SoundPreview.gd` | Inline sound preview playback |
| `SoundEffectBoard.gd` | Effects chain display |
| `SoundIdentityPanel.gd` | Sound identity trait display |
| `AudioVisualizer.gd` | Real-time audio visualization |
| `AudioCatalogUI.gd` | Main catalog UI container (scene: `AudioCatalogUI.tscn`) |

## Parameter Controls

| Script | Purpose |
|--------|---------|
| `ParameterPanel.gd` | Sound parameter editing panel |
| `ParameterRandomizer.gd` | Random parameter exploration |
| `ParameterSnapshot.gd` | Parameter state snapshot/recall |
| `TraitCalibrationPanel.gd` | Calibrate sound trait mappings |
| `WordSynthDisplay.gd` | Word-to-synthesis mapping display |

## AI Integration

- `AIAssistantPanel.gd` — AI-assisted sound design suggestions within the catalog.

## Usage

These components are instantiated by the parent catalog editors (`SongDevTools`, `AudioCatalogDesktop`, etc.). They communicate via signals and share state through `SongStateStore`.
