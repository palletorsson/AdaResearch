# Glass Pipe System Architecture

## Current State
- `TurtlePipeBase` - turtle graphics commands (f, l, r, u, d)
- `GlassRackController` - glass-specific segments (spiral, flask, wobbly, junction)
- Linear path strings: `"f,f,spiral,u,f,flask"`

## Problem
Linear paths can't handle:
- Y-junctions (one input, two outputs)
- Complex branching networks
- Reconnecting pipes
- Parallel runs

## Proposed Architecture

### 1. Segment Types (Complete Set)

| Segment | Ports | Description |
|---------|-------|-------------|
| `straight` | in→out | Basic tube |
| `corner` | in→out | 90° elbow |
| `corner45` | in→out | 45° elbow |
| `ubend` | in→out | 180° turn |
| `sbend` | in→out | Horizontal offset |
| `ypipe` | in→out1,out2 | Y-junction (splits flow) |
| `tee` | in→out,branch | T-junction |
| `cross` | in→out,left,right | 4-way |
| `reducer` | in(large)→out(small) | Diameter transition |
| `spiral` | in→out | Coiled condenser |
| `wobbly` | in→out | Sine-wave tube |
| `flask` | in→out | Round-bottom flask |
| `beaker` | in(top) | Open vessel |
| `drip` | in→drip | End drip tip |
| `cap` | in | Sealed end |

### 2. Layout Format (Graph-Based)

```json
{
  "nodes": {
    "start": {"type": "flask", "position": [0, 0, 0]},
    "split": {"type": "ypipe", "position": [0, 0.3, 0]},
    "left_coil": {"type": "spiral", "params": {"turns": 4}},
    "right_coil": {"type": "spiral", "params": {"turns": 6}},
    "merge": {"type": "ypipe", "rotation": 180},
    "end": {"type": "beaker"}
  },
  "connections": [
    ["start.out", "split.in"],
    ["split.out1", "left_coil.in"],
    ["split.out2", "right_coil.in"],
    ["left_coil.out", "merge.out1"],
    ["right_coil.out", "merge.out2"],
    ["merge.in", "end.in"]
  ]
}
```

### 3. Path String Extensions (Stack-Based Branching)

```
f,f,[,l,f,spiral,f,],r,f,spiral,f
    ^                 ^
    push cursor       pop cursor (return to junction)
```

Commands:
- `[` - Push cursor state (position + orientation)
- `]` - Pop cursor state (return to saved position)
- `ypipe` - Creates Y, auto-pushes for second branch

Example: `flask,f,ypipe,[,l,spiral,f,beaker,],r,spiral,f,beaker`

### 4. Auto-Routing

For connections between nodes:
1. Calculate 3D positions
2. Find shortest path avoiding obstacles
3. Insert straight + corner segments automatically

### 5. Port System

Each segment declares its ports:
```gdscript
func get_ports() -> Dictionary:
    return {
        "in": {"position": Vector3.ZERO, "direction": Vector3.BACK},
        "out": {"position": Vector3(0, 0, length), "direction": Vector3.FORWARD}
    }
```

Y-pipe:
```gdscript
func get_ports() -> Dictionary:
    return {
        "in": {"position": Vector3.ZERO, "direction": Vector3.BACK},
        "out1": {"position": Vector3(-0.05, 0, length), "direction": Vector3(-1, 0, 1).normalized()},
        "out2": {"position": Vector3(0.05, 0, length), "direction": Vector3(1, 0, 1).normalized()}
    }
```

## Implementation Plan

### Phase 1: New Segments
1. Add `sbend` segment (copy from BigPipeSystem, adapt for glass)
2. Add `ypipe` segment (proper Y-junction)
3. Add `corner45` segment
4. Add `ubend` segment
5. Add `reducer` segment
6. Add `cap` and `drip` end pieces

### Phase 2: Stack-Based Branching
1. Add `[` and `]` commands for cursor push/pop
2. Modify `ypipe`/`tee` to work with branching
3. Test with complex configs

### Phase 3: Graph-Based Layout (Optional)
1. Node + connection format
2. Auto-routing between nodes
3. Visual editor support

## File Structure

```
commons/glass_rack/
├── GlassRackController.gd    # Main controller
├── TurtlePipeBase.gd         # Base turtle system
├── GlassPipeSegments.gd      # NEW: All segment generators
├── GlassPipePorts.gd         # NEW: Port system
├── segments/                  # NEW: Segment scenes (optional)
│   ├── glass_ypipe.tscn
│   ├── glass_sbend.tscn
│   └── ...
└── configs/
    ├── simple_tube.json
    ├── distillation_rack.json
    ├── branching_condenser.json  # NEW: Uses Y-pipes
    └── ...
```
