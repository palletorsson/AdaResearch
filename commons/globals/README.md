# Globals & Trace System

This directory contains global Autoload singletons for the AdaResearch project.

## TraceData (`trace_data.gd`)

**Status**: ✅ Active (Jan 2026)

The `TraceData` singleton provides persistent storage for user-generated movement traces, allowing them to be shared between different scenes (e.g., drawn in a primitive scene and visualized in a grid editor).

### Architecture
- **Autoload**: Registered as `TraceData` in `project.godot`.
- **Storage**: Maintains an Array of Traces (`Array[Vector3]`).
- **Signals**: Emits `trace_added(points)` whenever a new trace is stored.

### Usage

**Saving a Trace (e.g., from DrawDot):**
```gdscript
var trace_data = get_node_or_null("/root/TraceData")
if trace_data:
    trace_data.add_trace(points_array)
```

**Listening for Traces (e.g., in GridLines):**
```gdscript
func _ready():
    var trace_data = get_node_or_null("/root/TraceData")
    if trace_data:
        # Load existing
        for trace in trace_data.get_all_traces():
            create_mesh(trace)
        # Listen for new
        trace_data.trace_added.connect(_on_trace_added)
```

### Integration
- **Producers**: `commons/primitives/point/draw_dot.gd` (Saves on drop)
- **Consumers**: `commons/primitives/line/grid_lines.gd` (Renders on grid)
