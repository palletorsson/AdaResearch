# VR Modular Synth Cable System

Physical patch cables for VR modular synthesizer interaction.

## Components

### SynthJack
Socket on a module that receives cable plugs.

```gdscript
# Add to any synth element
var jack = SynthJack.new()
jack.jack_type = SynthJack.JackType.OUTPUT  # or INPUT
jack.parameter_name = "frequency"
```

**Properties:**
- `jack_type`: OUTPUT or INPUT
- `parameter_name`: Parameter this jack controls/receives
- `socket_radius`, `socket_depth`: Physical dimensions

**Signals:**
- `cable_connected(cable, plug)`
- `cable_disconnected(cable, plug)`

### SynthCable
Patch cable with two grabbable plugs.

```gdscript
var cable = SynthCable.new()
cable.cable_color = Color.RED
add_child(cable)
```

**Properties:**
- `cable_color`: Color of cable and plugs
- `cable_thickness`: Tube diameter
- `gravity_sag`: How much cable droops

**Signals:**
- `connection_changed(output_jack, input_jack)`

### SynthCablePlug
Grabbable plug end (created automatically by SynthCable).

- Snaps into SynthJack sockets when released nearby
- Unsnaps when grabbed while connected
- Works with XRToolsPickable for VR hand interaction

### SynthCableManager
Central manager for all cables and routing.

```gdscript
var manager = SynthCableManager.new()
add_child(manager)

# Register jacks
manager.register_jack(freq_output_jack)
manager.register_jack(freq_input_jack)

# Spawn a cable
var cable = manager.spawn_cable(Vector3(0, 1, 0))

# Check routing
if manager.has_route("frequency", "filter_cutoff"):
    print("Frequency is routed to filter!")
```

**Signals:**
- `parameter_routed(from_param, to_param)`
- `parameter_unrouted(from_param, to_param)`
- `connection_made(cable, output_jack, input_jack)`
- `connection_broken(cable)`

## Usage Flow

1. **Create jacks** on your synth modules (sliders, displays, etc.)
2. **Register jacks** with the SynthCableManager
3. **Spawn cables** via manager or place in scene
4. **User grabs plug** → plug unsnaps from any jack
5. **User releases plug** near jack → plug snaps in
6. **Both plugs connected** → manager emits `parameter_routed`
7. **Audio system** queries manager for routing

## Integration with ElementLayoutNode

The element editor's audio elements can auto-create jacks:

```json
{
  "id": "sl_freq",
  "control": {
    "parameter": "frequency",
    "create_jack": true,
    "jack_type": "output"
  }
}
```

When `create_jack: true`, ElementLayoutNode will:
1. Instantiate a SynthJack alongside the control
2. Register it with the SynthCableManager
3. Route parameter changes through the cable system

## Cable Colors

Manager auto-assigns colors from palette:
- Red, Cyan, Orange, Green, Pink, Purple, Yellow, Gray

Or set manually:
```gdscript
cable.set_cable_color(Color(0.2, 0.8, 1.0))
```
