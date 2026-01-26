# Array Primitives - Pattern & Tile Systems

> "The loom was the first computer. Every carpet is an algorithm."

## Overview

Array primitives explore the relationship between **2D data structures** and **visual patterns**. From textile traditions to pixel art, these tools make array indexing tangible.

## Components

### PatternTilePuzzle

Interactive tile-based pattern editor with physical drag-and-drop interaction.

**Features:**
- Editable grid (4×4 to 16×16)
- 8-color palette (textile-inspired)
- **Grabbable color cubes** - drag and drop to place on grid
- Cubes snap and freeze in place when dropped on cells
- 10 repeat modes (simple, mirror, rotate, brick, herringbone, diamond)
- Live preview showing tiled result
- Carpet spawning (physical output)

**Interaction:**
1. **Grab** a color cube from the spawner pedestals on the right
2. **Move** the cube over the grid
3. **Release** - cube snaps to nearest cell and freezes in place
4. Grid cell updates, preview regenerates with new pattern
5. New cube automatically spawns at the pedestal

**Symmetry Modes:**

Two symmetry systems are available:

1. **Legacy RepeatMode** (10 simple modes)
2. **WallpaperGroups** (17 mathematical plane symmetries)

Toggle with `W` key or call `toggle_symmetry_mode()`.

**Legacy Repeat Modes:**

| Mode | Effect |
|------|--------|
| Simple | Basic XY tiling |
| Mirror X | Horizontal reflection |
| Mirror Y | Vertical reflection |
| Mirror XY | Kaleidoscope |
| Rotate 90° | Quarter-turn symmetry |
| Rotate 180° | Half-turn symmetry |
| Brick X | Half-offset rows |
| Brick Y | Half-offset columns |
| Herringbone | Diagonal weave |
| Diamond | 45° rotation |

**Wallpaper Groups (17 Mathematical Tilings):**

| Lattice | Groups |
|---------|--------|
| Oblique | p1, p2 |
| Rectangular | pm, pg, pmm, pmg, pgg |
| Rhombic | cm, cmm |
| Square | p4, p4m, p4g |
| Hexagonal | p3, p3m1, p31m, p6, p6m |

**VR Navigation (Wallpaper Mode):**
- **B/Y buttons**: Cycle lattice types (oblique → rectangular → rhombic → square → hexagonal)
- **A/X buttons**: Cycle groups within current lattice

**Keyboard Shortcuts:**
- `W`: Toggle between Legacy and Wallpaper modes
- `Q/E`: Previous/Next lattice
- `A/D`: Previous/Next group within lattice
- `Tab`: Next mode (works in both modes)
- `1-8`: Select color

**Cursor (Index Visualization):**
- `C`: Toggle cursor visibility
- `Space`: Play/Pause cursor animation
- `←/→`: Step cursor left/right
- `↑/↓`: Move cursor up/down one row
- `Home`: Reset cursor to (0,0)
- `End`: Stop cursor animation

### Cursor: The Index Incarnate

The cursor makes array indexing visible. When enabled, it shows:

1. **Yellow highlight** on preview: Current position being read
2. **Green highlight** on editor: Source cell (where the value comes from)
3. **Index math label**: Shows the calculation `position % size = source`

This reveals the fundamental insight: **an array is a function from indices to values**.

```
Preview position (5, 3) with tile_size=4:
  5 % 4 = 1
  3 % 4 = 3
  → reads from source (1, 3)
```

The cursor shows WHY patterns repeat: modular arithmetic wraps indices back into the tile.

### WallpaperGroups

Mathematical implementation of the 17 wallpaper groups—ALL possible ways to tile a 2D plane.

**Groups by lattice:**

- **Oblique**: p1, p2
- **Rectangular**: pm, pg, pmm, pmg, pgg
- **Rhombic**: cm, cmm
- **Square**: p4, p4m, p4g
- **Hexagonal**: p3, p3m1, p31m, p6, p6m

## Usage

### In Artifact Registry

```json
{
  "pattern_tile_puzzle": {
	"scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn"
  },
  "pattern_tile_mirror": {
	"scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn",
	"config": {
	  "tile_size": 4,
	  "repeat_mode": 3
	}
  },
  "pattern_tile_p4m": {
	"scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn",
	"config": {
	  "tile_size": 4,
	  "wallpaper_group": "p4m"
	}
  },
  "pattern_tile_hexagonal": {
	"scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn",
	"config": {
	  "wallpaper_group": "p6m"
	}
  },
  "pattern_tile_cursor": {
	"scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn",
	"config": {
	  "cursor_enabled": true,
	  "cursor_speed": 1.5,
	  "show_index_math": true
	}
  }
}
```

### In Map Data

```
"pattern_tile_4x4:0:-0.5"
"pattern_tile_puzzle#p4m:0:-0.5"
"pattern_tile_puzzle#hexagonal:0:-0.5"
"pattern_tile_puzzle#cursor:0:-0.5"
"pattern_tile_puzzle#p6m#cursor:0:-0.5"
"pattern_tile_puzzle#8x8#mirror#cursor:0:-0.5"
```

### Programmatic

```gdscript
var puzzle = pattern_tile_puzzle.instantiate()

# Legacy mode
puzzle.tile_size = 8
puzzle.repeat_mode = PatternTilePuzzle.RepeatMode.MIRROR_XY
puzzle.set_cell(0, 0, 1)  # Set top-left to color 1

# Wallpaper mode
puzzle.set_wallpaper_group(WallpaperGroups.Group.P4M)  # Sets group and switches mode
puzzle.next_lattice()        # Cycle to next lattice type
puzzle.next_wallpaper_group() # Cycle within current lattice
puzzle.toggle_symmetry_mode() # Switch between legacy and wallpaper

# VR controller integration
puzzle.handle_vr_button("by_button", "right")  # Cycle lattice
puzzle.handle_vr_button("ax_button", "right")  # Cycle group
```

## Signals

| Signal | Description |
|--------|-------------|
| `cell_changed(x, y, color_idx)` | Cell was painted |
| `pattern_complete()` | Pattern matches target (if any) |
| `repeat_mode_changed(mode)` | Legacy tiling mode changed |
| `wallpaper_group_changed(group)` | Wallpaper group changed |
| `color_selected(color_idx)` | Palette selection changed |
| `cursor_moved(preview_x, preview_y, source_x, source_y)` | Cursor position changed |

## Configuration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `tile_size` | int | 4 | Grid dimensions (NxN) |
| `preview_repeats` | Vector2i | (4,4) | How many times to tile in preview |
| `cell_size` | float | 0.05 | Size of each cell in meters |
| `symmetry_mode` | enum | LEGACY | LEGACY (10 modes) or WALLPAPER (17 groups) |
| `repeat_mode` | enum | SIMPLE | Legacy tiling algorithm |
| `wallpaper_group` | enum | P1 | Wallpaper group (when symmetry_mode=WALLPAPER) |
| `palette` | Color[] | [8 colors] | Available colors |
| `selected_color` | int | 1 | Currently selected color |
| `preview_offset` | Vector3 | (0,0,-0.8) | Position of preview relative to editor |
| `cube_size_ratio` | float | 0.8 | Cube size relative to cell size |
| `spawner_offset` | Vector3 | (0.25,0,0) | Position of cube spawners relative to grid |
| `cursor_enabled` | bool | false | Show cursor visualization |
| `cursor_speed` | float | 2.0 | Cursor animation speed (cells/second) |
| `show_index_math` | bool | true | Show index calculation label |

## Mathematical Background

### The 17 Wallpaper Groups

Discovered in the 19th century, these represent a complete classification of 2D plane symmetries:

1. **Symmetry operations**: translation, rotation (2,3,4,6-fold), reflection, glide reflection
2. **Lattice types**: oblique, rectangular, rhombic, square, hexagonal
3. **Impossibilities**: 5-fold symmetry doesn't tile (see Penrose tilings for quasi-crystals)

### Why This Matters

- **Textiles**: Every woven pattern is a wallpaper group
- **Architecture**: Floor tiles, brick patterns, mosaics
- **Digital**: Shader textures, procedural generation, game tiles
- **Nature**: Crystal structures, molecular patterns

The same mathematical structures underlie Persian carpets and pixel art.

## Cultural Connections

- **Kilim rugs** (Anatolia) - geometric abstraction
- **Ikat** (Indonesia) - warp-dyed patterns
- **Kente** (Ghana) - symbolic color combinations
- **Islamic geometry** - infinite patterns from finite rules
- **Celtic knots** - interlacing without ends

## Files

- `pattern_tile_puzzle.gd` - Main puzzle script with grid, preview, and spawners
- `pattern_tile_puzzle.tscn` - Default scene
- `pattern_tile_cube.gd` - Grabbable color cube (extends XRToolsPickable)
- `pattern_tile_cube.tscn` - Cube scene with collision and mesh
- `wallpaper_groups.gd` - Mathematical symmetry implementation
- `array_sequencer.gd` - Step sequencer (arrays as sound)
- `array_sequencer.tscn` - Sequencer scene
- `sequencer_presets.gd` - Pattern presets and Euclidean rhythm generator

---

# ArraySequencer - Arrays as Sound

> "A sequencer is a pattern machine where the cursor plays sound instead of color."

The ArraySequencer applies the same array/index concepts to audio:
- **Grid**: `grid[track][step]` instead of `grid[y][x]`
- **Cursor**: Playhead moving through time = index incarnate
- **Values**: Sound triggers instead of colors

## Core Insight

```
PatternTilePuzzle:  grid[y][x] → color_index → visual pixel
ArraySequencer:     grid[track][step] → sound_type → audio trigger
```

Both are **arrays as functions**: Index → Value

## Features

- **4x8 grid** (default): 4 tracks, 8 steps
- **808 kit** (default): kick, snare, hi-hat, sub bass
- **Playhead visualization**: Yellow column highlight
- **VR cube interaction**: Drag cubes to toggle cells
- **BPM control**: 30-300 BPM with swing
- **Preset cycling**: 808, trap, synth, tech_noir, retro

## Keyboard Controls

| Key | Action |
|-----|--------|
| `Space` | Play/Pause |
| `←/→` | Move playhead |
| `+/-` | Adjust BPM |
| `Tab` | Next sound preset |
| `1-8` | Toggle steps 1-8 on track 0 |
| `Home` | Reset playhead to start |
| `C` | Clear all cells |

## VR Controls

| Button | Action |
|--------|--------|
| **A/X** | Play/Pause |
| **B/Y** | Change sound preset |
| **Trigger** | Toggle cell at pointer |
| **Grab cubes** | Drag to grid to place sounds |

## Map Config Examples

```
"array_sequencer:0:1"
"array_sequencer#4x8:0:1"
"array_sequencer#4x16#trap:0:1"
"array_sequencer#120bpm:0:1"
"array_sequencer#808#90bpm:0:1"
```

## Artifact Registry

```json
{
  "array_sequencer": {
    "scene": "res://commons/primitives/arrays/array_sequencer.tscn",
    "config": {
      "num_tracks": 4,
      "num_steps": 8,
      "bpm": 120,
      "sound_preset": "808_kit"
    }
  }
}
```

## Sound Presets

| Preset | Sounds |
|--------|--------|
| `808_kit` (default) | dark_808_kick, tr909_kick, acid_606_hihat, dark_808_sub_bass |
| `trap_beats` | kick, explosion, hi-hat, shield_hit |
| `synth_kit` | tb303_acid_bass, moog_bass_lead, dx7_piano, ppg_wave_pad |
| `tech_noir` | melodic_drone, ghost_drone, ambient_wind, teleport_drone |
| `retro` | c64_sid_lead, amiga_mod_sample, retro_jump, pickup_mario |

## Configuration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `num_tracks` | int | 4 | Number of sound tracks (1-8) |
| `num_steps` | int | 8 | Steps per pattern (4-32) |
| `bpm` | float | 120.0 | Beats per minute (30-300) |
| `swing` | float | 0.0 | Swing amount (0.0-1.0) |
| `sound_preset` | String | "808_kit" | Sound collection name |
| `auto_play` | bool | false | Start playing on load |
| `loop` | bool | true | Loop playback |

## Signals

| Signal | Description |
|--------|-------------|
| `step_triggered(track, step, sound_name)` | Sound triggered at step |
| `playhead_moved(step)` | Playhead position changed |
| `pattern_changed(track, step, active)` | Cell toggled |
| `bpm_changed(new_bpm)` | BPM changed |
| `preset_changed(preset_name)` | Sound preset changed |
| `playback_started()` | Playback started |
| `playback_stopped()` | Playback stopped |

## Pattern Presets (SequencerPresets)

Pre-defined rhythm patterns:

| Pattern | Description |
|---------|-------------|
| `four_on_floor` | Classic house/disco kick |
| `backbeat` | Rock/pop snare on 2 and 4 |
| `trap_basic` | Trap with rolling hi-hats |
| `breakbeat` | Syncopated break pattern |
| `minimal` | Sparse minimal techno |
| `euclidean_5_8` | 5 hits over 8 steps |
| `euclidean_3_8` | Tresillo pattern |

## Programmatic Usage

```gdscript
var seq = array_sequencer.instantiate()
seq.bpm = 90
seq.sound_preset = "trap_beats"

# Toggle cells
seq.toggle_cell(0, 0)  # Kick on beat 1
seq.toggle_cell(1, 4)  # Snare on beat 3

# Control playback
seq.play()
seq.stop()
seq.toggle_playback()

# Apply pattern preset
SequencerPresets.apply_pattern(seq, "four_on_floor")

# Generate Euclidean rhythm
var pattern = SequencerPresets.generate_euclidean(5, 8)
for step in range(pattern.size()):
    seq.set_cell(0, step, pattern[step])
```
