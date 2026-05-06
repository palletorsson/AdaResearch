# Audio Rack Presets

Pre-configured synth racks ready to use. Just instance them in your scene!

## Available Presets

| Preset | Sound Type | Description |
|--------|------------|-------------|
| `rack_sine_basic.tscn` | Basic Sine Wave | Simple oscillator with freq/amp/dur controls |
| `rack_303_acid.tscn` | TB-303 Acid Bass | Classic acid with cutoff & resonance knobs |
| `rack_808_drums.tscn` | 808 Kick | Deep kick drum with decay control |
| `rack_mario.tscn` | Mario Pickup | Sweep sound with start/end frequency |
| `rack_dx7_piano.tscn` | DX7 Electric Piano | FM piano with attack/release |
| `rack_moog_bass.tscn` | Moog Bass Lead | Fat analog bass with filter |
| `rack_ambient_drone.tscn` | Ambient Drone | Atmospheric pad with lissajous display |

## How to Use

### Option 1: Instance in Editor
1. Open your scene
2. **Add Child Node** → **Instance Child Scene**
3. Navigate to `res://commons/audio/rack_presets/`
4. Select a preset

### Option 2: Instance via Code
```gdscript
var rack_scene = preload("res://commons/audio/rack_presets/rack_303_acid.tscn")
var rack = rack_scene.instantiate()
rack.position = Vector3(0, 1.5, -2)  # Position in front of player
add_child(rack)
```

### Option 3: Use in Map Data
```json
{
  "interactables": [
    ["RackPreset#config:rack_303_acid", "", ""]
  ]
}
```

## Customizing

Each rack is an `ElementLayoutNode`. After instancing, you can:

- **Change sound type** in Inspector → `Sound Type`
- **Add/remove elements** using the Element Editor dock
- **Adjust grid** via `Grid Width`, `Grid Height`
- **Save as new preset** with Scene → Save Scene As

## Layout

All presets follow this general layout:
```
[Source     ] [Controls...] [Display____]
[           ] [           ] [           ]
[Play][Stop ] [           ] [___________]
```

## Creating New Presets

1. Create empty scene with `Node3D`
2. Add `ElementLayoutNode` script
3. Set `subset_id = "audio_rack"`
4. Place elements using Element Editor
5. Save as `.tscn` in this folder
