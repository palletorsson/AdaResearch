# CLASS NAMING UPDATE

## Issue
The original class names (`AirPointListener`, `AirPointOscillator`, `AirPointSynth`) conflicted with existing global script classes in `commons/audio/systems/air_points/`.

## Solution
All classes have been renamed to use the `SystemsMusic` prefix to avoid conflicts:

### Renamed Classes
- `AirPointListener` → `SystemsMusicListener`
- `AirPointOscillator` → `SystemsMusicOscillator`
- `AirPointSynth` → `SystemsMusicSynth`

### Updated Files
1. **Scripts** (class_name declarations):
   - `SystemsMusicListener.gd` (formerly AirPointListener.gd)
   - `SystemsMusicOscillator.gd` (formerly AirPointOscillator.gd)
   - `SystemsMusicSynth.gd` (formerly AirPointSynth.gd)

2. **Test Controllers** (type references):
   - `AirPointAudioTest.gd`
   - `AirPointSynthTest.gd`

3. **Test Scenes** (node names and paths):
   - `AirPointAudioTest.tscn`
   - `AirPointSynthTest.tscn`

### Usage
```gdscript
# Create listener
var listener = SystemsMusicListener.new()

# Create synth
var synth = SystemsMusicSynth.new()
synth.listener = listener

# Or in scene tree:
@onready var listener: SystemsMusicListener = $SystemsMusicListener
@onready var synth: SystemsMusicSynth = $SystemsMusicSynth
```

## Existing Air Points System
The original Air Points system remains at:
- `commons/audio/systems/air_points/AirPointListener.gd`
- `commons/audio/systems/air_points/AirPointOscillator.gd`

Our new **Systems Music** implementation (Teropa-style) is separate and uses the `SystemsMusic` namespace.

---

**Status**: ✅ All naming conflicts resolved. Scenes should now load without errors.
