# Element Editor

A Godot editor plugin for visually placing grid-based elements in 3D space, with integrated audio controller support.

## Features

- **Grid-based placement**: Place elements on a configurable grid in XY, YZ, or XZ planes
- **Subset system**: Different element sets for different purposes (audio rack, glass rack, etc.)
- **Audio integration**: Elements can have parameter bindings that wire up automatically at runtime
- **Live preview**: See elements in the 3D viewport while editing
- **Undo/redo**: Full editor integration

## Audio Rack Subset

The `audio_rack` subset provides synth rack elements with automatic parameter binding:

### Controls
Elements that output parameter values:

```json
{
  "id": "sl_freq",
  "name": "Frequency",
  "scene": "res://commons/interactables/slider_smooth.tscn",
  "control": {
	"type": "slider",
	"parameter": "frequency",
	"min": 20.0,
	"max": 2000.0,
	"default": 440.0,
	"label": "FREQ"
  }
}
```

### Displays
Elements that visualize audio or bind to parameters:

```json
{
  "id": "disp_waveform",
  "name": "Waveform",
  "scene": "res://commons/audio/interfaces/VRSimpleWaveform.tscn",
  "display": {
	"type": "waveform",
	"source": "rack",
	"freq_param": "frequency",
	"amp_param": "amplitude",
	"label": "OUTPUT"
  }
}
```

### How Binding Works

1. **Control → Parameter**: When a slider with `"parameter": "frequency"` moves, it updates the `frequency` value
2. **Parameter → Display**: Displays with `"freq_param": "frequency"` read from the same value
3. **Parameter → Sound**: The `ElementLayoutNode` collects all parameter values and generates sound

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  sl_freq    │ ──────► │   frequency      │ ──────► │  disp_waveform  │
│  (slider)   │         │   parameter      │         │  (monitor)      │
└─────────────┘         └────────┬─────────┘         └─────────────────┘
								 │
								 ▼
						┌──────────────────┐
						│  Sound Generator │
						└──────────────────┘
```

## Cable Visualization

The editor draws cables between connected elements:

- **Cyan** → frequency
- **Green** → amplitude  
- **Yellow** → duration
- **Orange** → cutoff
- **Pink** → resonance
- **Purple** → attack
- **Blue** → release
- **Gray** → other parameters

Cables curve naturally with a droop effect. Connection ports show as:
- **Green ✚** = output (control)
- **Orange ✚** = input (display)

Toggle cables with the `show_cables` property on ElementLayoutNode.

## Usage

### In the Editor

1. Create an `ElementLayoutNode` in your scene
2. Select it to open the Element Editor dock
3. Choose a subset (e.g., "Audio Rack")
4. Double-click elements to place them
5. Press `R` to rotate, `Delete` to remove

### At Runtime

The `ElementLayoutNode` automatically:
- Creates a dedicated audio bus
- Wires up control signals to parameters
- Updates displays when parameters change
- Generates and plays sound on changes (if `auto_play_on_change` is enabled)

### API

```gdscript
# Get current parameter values
var values = element_layout.get_current_values()
# Returns: { "frequency": 440.0, "amplitude": 0.5, ... }

# Play sound with current values
element_layout.play_current_sound()

# Export as rack config (for UniversalVRAudioController)
var config = element_layout.export_as_rack_config()
```

## Element Definition Schema

```json
{
  "id": "unique_id",
  "name": "Display Name",
  "category": "controls",
  "size": [width_cells, height_cells],
  "icon": "∿",
  "description": "Tooltip text",
  "scene": "res://path/to/scene.tscn",
  
  "control": {
	"type": "slider|knob|button|slider_h",
	"parameter": "param_name",
	"min": 0.0,
	"max": 1.0,
	"default": 0.5,
	"label": "LABEL",
	"action": "play|stop"
  },
  
  "display": {
	"type": "waveform|spectrum|lissajous|monitor|meter",
	"source": "rack|master",
	"freq_param": "frequency",
	"amp_param": "amplitude",
	"label": "LABEL"
  }
}
```

## Available Elements

### Controls
- `sl_freq` - Frequency slider (20-2000 Hz)
- `sl_amp` - Amplitude slider (0-1)
- `sl_dur` - Duration slider (0.1-5 sec)
- `sl_decay` - Decay rate slider
- `sl_start_freq` / `sl_end_freq` - Sweep frequency sliders
- `knob_freq` - Frequency knob
- `knob_cutoff` - Filter cutoff knob
- `knob_resonance` - Filter resonance knob
- `knob_attack` / `knob_release` - Envelope knobs
- `sl_h_mix` - Horizontal mix slider
- `sl_h_pan` - Horizontal pan slider
- `btn_play` / `btn_stop` - Play/stop buttons

### Displays
- `disp_waveform` - Waveform display (4x3 cells)
- `disp_spectrum` - Spectrum analyzer (4x3 cells)
- `disp_lissajous` - Lissajous XY display (4x3 cells)
- `disp_monitor` - Combined monitor (4x3 cells)
- `disp_wave_small` - Small waveform (2x2 cells)
- `disp_spec_small` - Small spectrum (2x2 cells)
- `meter_vu` - VU meter (1x2 cells)

## Creating Custom Subsets

Create a JSON file in `res://tools/grid_editor/subsets/` and add it to `SUBSET_FILES` in `subset_data.gd`:

```json
{
  "id": "my_subset",
  "name": "My Custom Elements",
  "version": "1.0",
  "orientation": {
	"plane": "XY",
	"grid_size": 0.08
  },
  "audio": {
	"sound_type": "basic_sine_wave",
	"create_dedicated_bus": true,
	"auto_play_on_change": true
  },
  "categories": [...],
  "elements": [...]
}
```
