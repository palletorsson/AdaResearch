# Desktop Testing System

First-person desktop player for testing Ada Research maps without VR.

## Quick Start Options

### Option 1: Lab (Recommended - Full Experience)
1. **Open**: `commons/scenes/lab_desktop.tscn`
2. **Run** (F5)
3. **Click on artifacts** to start sequences
4. This gives you the full lab → sequence → lab flow

### Option 2: Direct Map Testing
1. **Open**: `commons/scenes/desktop_map_tester.tscn`
2. **Configure** in Inspector:
   - `Start Sequence`: e.g., "wavefunctions", "noise"
   - `Start Map Index`: 0 = first map
   - `Auto Load On Ready`: true
3. **Run** (F5)
4. Use Page Up/Down to navigate maps

## Controls

### Movement
- **WASD**: Move around
- **Mouse**: Look around
- **Shift**: Sprint
- **Space**: Jump
- **ESC**: Toggle mouse capture (to interact with UI)

### Lab Mode (lab_desktop.tscn)
- **Left Click / Enter**: Interact with teleporters and artifacts
- **R**: Return to lab from sequence
- **N**: Next map in current sequence
- **P**: Previous map in current sequence

### Direct Map Testing (desktop_map_tester.tscn)
- **Page Down**: Load next map in sequence
- **Page Up**: Load previous map in sequence
- **Home**: Reload current map

## Sequences Available

Edit the `start_sequence` property in the Inspector to choose:
- `wavefunctions` - Wave function demonstrations
- `noise` - Noise algorithm demonstrations
- `random` - Randomness demonstrations
- And any other sequences defined in `commons/maps/sequences/`

## How It Works

The Desktop Tester:
1. Connects to AdaSceneManager to get sequence configurations
2. Loads map data from JSON files
3. Uses GridSystem to build the map
4. Spawns a CharacterBody3D player instead of VR player

## Files Created

- `commons/scenes/desktop_map_tester.tscn` - Main test scene
- `commons/scenes/DesktopMapTester.gd` - Map loading logic
- `commons/scenes/desktop_player.tscn` - First-person player
- `commons/scenes/DesktopPlayer.gd` - Player movement controller

## Notes

- This uses the same map system and data as VR mode
- All map sequences from `commons/maps/sequences/` work
- GridSystem must have `build_from_data()` method
- Player spawns at 's' marker in map utilities layer
