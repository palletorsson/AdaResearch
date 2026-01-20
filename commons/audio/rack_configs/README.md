# VR Audio Rack Configuration System

JSON-based configuration system for defining VR audio controller interfaces declaratively, similar to the `map_data.json` pattern used in the grid system.

## Desktop Preview

A 3D desktop preview scene is available for testing rack configurations without VR:

**To use:**
1. Open `res://commons/audio/rack_configs/RackPreview.tscn` in Godot
2. Run the scene (F6 or Play Scene button)
3. Use the dropdown to select different rack configurations
4. Use Right-Click + Drag to rotate the camera around the rack
5. Click "Play Sound" to test the audio output

The preview instantiates the actual 3D `UniversalVRAudioController` and its controls, allowing you to verify the 3D layout and visual appearance on a desktop.

## Overview

This system allows you to define complete audio rack interfaces in JSON files with:
- Grid-based layout (2D array positioning like map_data.json)
- Control naming conventions (`sl_N`, `nb_N`, etc.)
- Direct parameter mapping to audio synthesis parameters
- Customizable spacing and positioning

## Quick Start

### 1. Using a Rack Configuration

In Godot editor:
1. Open `UniversalVRAudioController.tscn`
2. Select the root node
3. Set `rack_config_path` to your JSON file (e.g., `res://commons/audio/rack_configs/basic_rack.json`)
4. Run the scene

The controls will spawn automatically based on your JSON configuration.

### 2. Creating a New Rack

Create a new `.json` file in this directory:

```json
{
  "rack_info": {
	"name": "My Custom Rack",
	"description": "Description of what this rack does",
	"version": "1.0",
	"sound_type": "basic_sine_wave"
  },
  "layout": {
	"col_spacing": 0.22,
	"row_spacing": 0.1
  },
  "grid": [
	["sl_1", "nb_1"],
	["sl_2", "nb_2"]
  ],
  "control_definitions": {
	"sl_1": {
	  "type": "slider",
	  "label": "Frequency",
	  "parameter": "freq",
	  "min": 20.0,
	  "max": 2000.0,
	  "default": 440.0
	},
	"nb_1": {
	  "type": "knob",
	  "label": "Amplitude",
	  "parameter": "amp",
	  "min": 0.0,
	  "max": 1.0,
	  "default": 0.5
	}
  }
}
```

## JSON Schema

### Top-Level Structure

```json
{
  "rack_info": { ... },      // Required: Rack metadata
  "layout": { ... },          // Optional: Grid spacing configuration
  "grid": [ ... ],            // Required: 2D array of control IDs
  "control_definitions": { ... }  // Required: Control specifications
}
```

### `rack_info` Section

Metadata about the rack configuration.

```json
{
  "name": "String",           // Display name shown in VR
  "description": "String",    // Human-readable description
  "version": "String",        // Version number (e.g., "1.0")
  "sound_type": "String"      // Sound engine to use (see Sound Types below)
}
```

### `layout` Section

Controls the spacing and layout of the rack. Supports fixed or auto-spacing.

**Fixed Spacing:**
```json
{
  "col_spacing": 0.22,    // Horizontal spacing between columns (meters)
  "row_spacing": 0.1      // Vertical spacing between rows (meters)
}
```

**Auto-Spacing (Recommended):**
```json
{
  "auto_spacing": true,   // Enable smart spacing based on control sizes
  "padding": 0.02,        // Padding around the entire rack (meters)
  "gap": 0.02             // Gap between controls (meters)
}
```

When `auto_spacing` is true (or col_spacing is 0), the system automatically calculates spacing based on each control type's size:

| Control Type | Default Size (W x H) |
|-------------|---------------------|
| slider | 0.22 x 0.06 m |
| slv (vertical) | 0.06 x 0.15 m |
| knob | 0.08 x 0.08 m |
| xy/pad | 0.15 x 0.15 m |
| button | 0.06 x 0.06 m |
| monitor | 0.30 x 0.22 m |
| meter | 0.04 x 0.12 m |
| label | 0.20 x 0.03 m |

### `grid` Section

2D array defining control positions. Each cell contains a control ID or empty string.

```json
[
  ["sl_1", "nb_1", "sl_2"],  // Row 0 (top)
  ["nb_2", "", "sl_3"],      // Row 1 (middle, center empty)
  ["sl_4", "nb_3", ""]       // Row 2 (bottom, right empty)
]
```

**Grid Layout Rules:**
- Position (0,0) is top-left
- X increases to the right (columns)
- Y increases downward (rows)
- Use `""` or `" "` for empty cells
- Control IDs must match keys in `control_definitions`

### `control_definitions` Section

Dictionary mapping control IDs to their specifications.

**Slider Example:**
```json
"sl_1": {
  "type": "slider",         // Required: "slider" or "knob"/"dial"
  "label": "Frequency",     // Required: Display label
  "parameter": "freq",      // Required: Audio parameter name
  "min": 20.0,              // Optional: Minimum value (default: 0.0)
  "max": 2000.0,            // Optional: Maximum value (default: 1.0)
  "default": 440.0          // Optional: Initial value (default: 0.5)
}
```

**Knob Example:**
```json
"nb_1": {
  "type": "knob",           // or "dial" - both are equivalent
  "label": "Amplitude",
  "parameter": "amp",
  "min": 0.0,
  "max": 1.0,
  "default": 0.5
}
```

**Vertical Slider Example:**
```json
"slv_1": {
  "type": "slv",            // Vertical fader
  "label": "Volume",
  "parameter": "amp",
  "min": 0.0,
  "max": 1.0
}
```

**Snap Slider Example (Discrete Steps):**
```json
"sls_1": {
  "type": "sls",            // Stepped slider
  "label": "Octave",
  "parameter": "octave",
  "min": -2,
  "max": 2,
  "step": 1                 // Step size (1 = whole numbers)
}
```

**Zero-Centered Slider Example:**
```json
"slz_1": {
  "type": "slz",            // Returns to center on release
  "label": "Pitch Bend",
  "parameter": "pitch",
  "min": -1.0,
  "max": 1.0,
  "return_to_zero": true    // Default: true
}
```

**XY Pad Example (2 Parameters):**
```json
"xy_1": {
  "type": "xy",             // XY pad controls 2 parameters
  "label": "Filter",
  "parameter_x": "cutoff",  // X-axis parameter
  "parameter_y": "resonance", // Y-axis parameter
  "min_x": 20.0,
  "max_x": 2000.0,
  "min_y": 0.0,
  "max_y": 1.0,
  "size": 0.1               // Pad size in meters
}
```

**Button Example:**
```json
"btn_1": {
  "type": "btn",
  "label": "Play",
  "action": "play"          // "play", "stop", or "toggle"
}
```

**Toggle Button Example:**
```json
"btn_2": {
  "type": "btn",
  "label": "Mute",
  "parameter": "mute",      // Maps to parameter when toggled
  "action": "toggle"
}
```

**Wheel Example (Pitch Bend Style):**
```json
"whl_1": {
  "type": "wheel",
  "label": "Mod",
  "parameter": "mod_amount",
  "min": 0.0,
  "max": 1.0
}
```

**Lever Example:**
```json
"lv_1": {
  "type": "lever",
  "label": "Throw",
  "parameter": "intensity",
  "min": 0.0,
  "max": 1.0
}
```

**Monitor Example (Waveform Display):**
```json
"mon_1": {
  "type": "monitor",
  "label": "Output"
}
```

**VU Meter Example:**
```json
"mtr_L": {
  "type": "meter",
  "label": "L",
  "source": "output_left"     // Audio source to monitor
}
```

**Label Example:**
```json
"lbl_osc": {
  "type": "label",
  "text": "OSCILLATOR",
  "font_size": 28,
  "color": "#aaaaaa"
}
```

**Group Container Example:**
```json
"grp_filter": {
  "type": "group",
  "label": "FILTER",
  "color": "#4a2a6a",         // Accent color for border
  "width": 0.3,               // Width in meters
  "height": 0.2               // Height in meters
}
```

## Control Types (Ableton-Style)

All available control types for your rack:

### Sliders (Faders)

| Type | Aliases | Description |
|------|---------|-------------|
| `slider` | `slh`, `slider_horizontal`, `fader` | Horizontal slider (default) |
| `slv` | `slider_vertical`, `vfader` | Vertical slider |
| `sls` | `slider_snap`, `stepped` | Snap slider with discrete steps |
| `slz` | `slider_zero`, `bipolar` | Zero-centered, returns to center |

### Rotary Controls

| Type | Aliases | Description |
|------|---------|-------------|
| `knob` | `dial`, `nb`, `rotary` | Rotary knob/dial |
| `wheel` | `whl`, `pitchbend` | Scroll wheel (like pitch bend) |

### 2D Controls

| Type | Aliases | Description |
|------|---------|-------------|
| `xy` | `xypad`, `2df`, `pad` | XY pad (controls 2 parameters) |
| `js` | `joystick` | Joystick (alternative 2D control) |

### Discrete Controls

| Type | Aliases | Description |
|------|---------|-------------|
| `btn` | `button`, `trigger` | Push button (trigger or toggle) |
| `lv` | `lever`, `throw` | Lever (vertical throw) |

### Displays & Meters

| Type | Aliases | Description |
|------|---------|-------------|
| `mon` | `monitor`, `waveform`, `scope` | Waveform/spectrum monitor |
| `lissajous` | `liss`, `xy_wave`, `paramwave` | Lissajous XY figure from two frequency params |
| `mtr` | `meter`, `vu`, `level` | VU/level meter with peak hold |
| `lbl` | `label`, `text` | Text label/header |
| `grp` | `group`, `container` | Group container with background |

### Naming Convention

Use prefixes for control IDs: `type_N` where N is any number.

Examples: `sl_1`, `slv_2`, `knob_freq`, `xy_filter`, `btn_play`, `mon_out`, `mtr_L`

Numbers don't need to be sequential.

## Audio Parameters

Common parameter names that map to audio synthesis:

| Parameter | Description | Typical Range |
|-----------|-------------|---------------|
| `freq` | Oscillator frequency | 20.0 - 2000.0 Hz |
| `amp` | Amplitude/volume | 0.0 - 1.0 |
| `duration` | Sound duration | 0.1 - 10.0 seconds |
| `hardness` | Waveform hardness | 0.0 - 1.0 |
| `quality` | Filter Q/resonance | 0.5 - 10.0 |
| `detune` | Oscillator detuning | 0.0 - 1.0 |
| `blend` | Waveform blend/mix | 0.0 - 1.0 |
| `ring_mod` | Ring modulation amount | 0.0 - 1.0 |

Check `SoundParameterManager.gd` for available parameters for each sound type.

## Sound Types

Available in `rack_info.sound_type`:

- `basic_sine_wave` - Simple sine wave oscillator
- `synth_wave` - Synthesizer with multiple parameters
- `pickup_mario` - Mario-style pickup sound
- `teleport_drone` - Drone with teleport effect
- `lift_bass_pulse` - Bass pulse with lift
- `ghost_drone` - Ghostly drone sound
- `melodic_drone` - Musical drone
- `laser_shot` - Laser shot effect
- `power_up_jingle` - Power-up sound
- `explosion` - Explosion effect
- `retro_jump` - Retro jump sound
- `shield_hit` - Shield impact sound
- `ambient_wind` - Wind ambience

## Example Configurations

### Minimal Configuration

```json
{
  "rack_info": {
	"name": "Simple Synth",
	"version": "1.0",
	"sound_type": "basic_sine_wave"
  },
  "grid": [
	["sl_1"]
  ],
  "control_definitions": {
	"sl_1": {
	  "type": "slider",
	  "label": "Frequency",
	  "parameter": "freq"
	}
  }
}
```

### Complex Layout

```json
{
  "rack_info": {
	"name": "Advanced Modular Synth",
	"version": "1.0",
	"sound_type": "synth_wave"
  },
  "layout": {
	"col_spacing": 0.20,
	"row_spacing": 0.12
  },
  "grid": [
	["sl_1", "sl_2", "sl_3"],
	["nb_1", "nb_2", "nb_3"],
	["nb_4", "nb_5", "nb_6"],
	["sl_4", "", "sl_5"]
  ],
  "control_definitions": {
	"sl_1": {
	  "type": "slider",
	  "label": "Freq 1",
	  "parameter": "freq",
	  "min": 20.0,
	  "max": 2000.0,
	  "default": 220.0
	},
	// ... more controls
  }
}
```

## Grid Positioning Details

The grid system calculates 3D positions as follows:

```
x = col_index * col_spacing
y = -row_index * row_spacing
z = 0
```

**Example:**
With `col_spacing: 0.22` and `row_spacing: 0.1`:

```
Grid:           Position in 3D space:
["sl_1", "nb_1"]   sl_1: (0.00, 0.00, 0)  nb_1: (0.22, 0.00, 0)
["sl_2", "nb_2"]   sl_2: (0.00, -0.1, 0)  nb_2: (0.22, -0.1, 0)
```

Controls are spawned as children of the `ParameterGrid` node.

## Validation

The system validates JSON files on load:

**Required checks:**
- `grid` must exist and be an Array
- `control_definitions` must exist and be a Dictionary
- Each control must have `type` and `parameter` fields

**Errors:**
- Missing/invalid JSON structure → Error logged, falls back to traditional mode
- Control ID in grid but not in definitions → Warning logged, control skipped
- Unknown control type → Warning logged, control skipped

## Backward Compatibility

The system maintains full backward compatibility:

- If `rack_config_path` is empty → Uses traditional `SoundParameterManager` mode
- If file doesn't exist → Falls back to traditional mode
- Old code continues to work unchanged

## Technical Details

### Signal Flow

```
Control moved
  → _on_parameter_changed_json(value, control_id)
  → 50ms debounce timer
  → play_current_sound()
  → _get_current_values() reads all controls
  → Maps control_id → parameter via control_definitions
  → CustomSoundGenerator.generate_custom_sound()
  → Audio playback
```

### Active Controls Structure

In JSON mode, `active_controls` uses this structure:

```gdscript
active_controls = {
  "sl_1": {
	"instance": Node,           // The instantiated control scene
	"parameter": "freq",        // Parameter name from JSON
	"config": { ... }           // Full config from control_definitions
  }
}
```

### File Locations

- **Rack configs:** `res://commons/audio/rack_configs/*.json`
- **Controller script:** `res://commons/audio/UniversalVRAudioController.gd`
- **Control scenes:** `res://commons/audio/interfaces/VRAudioControl*.tscn`

## Tips & Best Practices

1. **Start simple:** Begin with basic_rack.json as a template
2. **Test incrementally:** Add controls one at a time
3. **Use descriptive IDs:** `sl_freq_osc1` is clearer than `sl_7`
4. **Match parameters:** Ensure parameter names match your sound engine
5. **Reasonable ranges:** Set min/max values appropriate to the parameter
6. **Grid spacing:** Adjust spacing to prevent control overlap
7. **Empty cells:** Use them for visual grouping and organization

## Troubleshooting

**Controls not appearing:**
- Check console for validation errors
- Verify file path is correct in `rack_config_path`
- Ensure control IDs in grid match control_definitions keys

**Controls overlapping:**
- Increase `col_spacing` or `row_spacing`
- Reduce grid size or rearrange layout

**Parameters not working:**
- Verify parameter names match the sound engine
- Check min/max ranges are appropriate
- Ensure sound_type supports the parameters

**JSON parse errors:**
- Validate JSON syntax (use a JSON validator)
- Check for trailing commas (not allowed in JSON)
- Ensure all strings use double quotes

## Future Extensions

Planned features:
- Button controls (`b_N`)
- 2D field controls (`2df_N`) using slider_plane
- 3D field controls (`3df_N`) for spatial control
- Visual theming (colors, sizes)
- Multiple pages/tabs
- Preset save/load
- Modular routing/patching system
