# First-Person Scene Slideshow

A first-person viewer for exploring all algorithm scenes in the project.

## Features

- **First-person movement** with WASD keys
- **Mouse look** for camera control
- **Sprint** with Shift key
- **Scene cycling** with N (next) and P (previous) keys
- **Automatic scene indexing** from `algorithms/` directory

## Usage

1. Open `first_person_slideshow.tscn`
2. Press F5 to run
3. Move around with WASD
4. Look with mouse
5. Press **N** to load the next scene
6. Press **P** to go back to the previous scene
7. Press **ESC** to release mouse (press again to recapture)

## Controls

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Look around |
| Shift | Sprint |
| N | Next scene |
| P | Previous scene |
| ESC | Toggle mouse capture |

## How It Works

### Scene Indexing

The `SceneSlideshowManager` automatically scans the `algorithms/` directory recursively and indexes all `.tscn` files. Scenes are sorted alphabetically.

### Scene Loading

When you press N or P:
1. The current scene is unloaded
2. The next/previous scene is loaded from the index
3. The scene is added to the scene tree
4. Console displays the scene path and number

### First-Person Controller

The `FirstPersonController` provides:
- Character controller physics with `CharacterBody3D`
- Mouse-based camera rotation
- WASD movement relative to camera direction
- Sprint multiplier when holding Shift

## Files

- `first_person_slideshow.tscn` - Main slideshow scene
- `first_person_controller.gd` - Character controller script
- `scene_slideshow_manager.gd` - Scene indexing and loading manager

## Notes

- The player starts at position (0, 1, 5) by default
- Some scenes may not have floors - use this as a floating camera viewer
- Scenes are loaded additively, allowing you to walk around and explore
- Press ESC if you need to access Godot UI while running
