# Audio Catalog

Desktop tools for sound design, song authoring, and semantic audio control.

## Core Editors

| Script | Scene | Purpose |
|--------|-------|---------|
| `SongDevTools.gd` | `SongDevTools.tscn` | Deep editing — transport, timeline, semantic controls |
| `SongPreviewDesktop.gd` | `SongPreviewDesktop.tscn` | Fast preview and export |
| `AudioCatalogDesktop.gd` | `AudioCatalogDesktop.tscn` | Sound browser for synth elements |
| `GenreSynthBrowser.gd` | `GenreSynthBrowser.tscn` | Genre suite browser by sound role |
| `AudioCatalogTablet3D.gd` | `AudioCatalogTablet3D.tscn` | 3D tablet variant for VR |

## Support Systems

| Script | Purpose |
|--------|---------|
| `SoundIdentity.gd` | Bidirectional sound understanding — maps traits to recipes and back |
| `SoundDescriptions.gd` | Sound metadata and descriptions |
| `SongRuntimeEngine.gd` | Runtime playback engine for composed songs |
| `SongStateStore.gd` | Persistent state for song editing sessions |
| `AudioCatalogDataProvider.gd` | Data access layer for catalog browsers |
| `LayerRenderer.gd` | Renders individual track layers |
| `StemEditor.gd` | Stem-level editing |
| `SynthConfigRegistry.gd` | Known layer configuration references |

## UI Components

The `ui/` subfolder contains pattern editors, timelines, displays, and panels — see `ui/README.md`.

## Architecture

See `ARCHITECTURE.md` and `README_SynthLab.md` in this directory for detailed design documentation.
