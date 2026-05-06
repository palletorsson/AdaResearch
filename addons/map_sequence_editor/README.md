# Map Sequence Editor

Godot editor plugin for managing map sequences and editing map metadata.

## Overview

Adds a main screen tab ("Map Sequences") for working with the sequence JSON files that define how maps are ordered in the curriculum. Reads sequences from `commons/maps/sequences/` and map data from `commons/maps/`.

## Features

- Browse all sequence JSON files
- View and reorder maps within a sequence (move up/down, add, remove)
- Browse all available maps with `map_data.json`
- Edit map name and description fields
- Save changes back to sequence and map JSON files

## Usage

1. Enable the plugin in **Project > Project Settings > Plugins**
2. Click the "Map Sequences" tab in the main editor toolbar
3. Select a sequence from the left panel
4. Reorder maps, add/remove entries, or edit map descriptions
5. Save with the dedicated save buttons (sequence and map data are saved separately)

## Files

| File | Role |
|------|------|
| `plugin.cfg` | Plugin metadata |
| `map_sequence_editor_plugin.gd` | Plugin entry point — loads the editor as a main screen tab |
| `map_sequence_editor.gd` | Editor logic — sequence/map browsing, reordering, saving |
| `map_sequence_editor.tscn` | Editor UI layout |
