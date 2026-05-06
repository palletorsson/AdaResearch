# Curves

Interactive editable curves with grabbable control points.

## Files

- `editable_curve.gd`: main curve system with multiple interpolation modes
- `curve_control_point.gd`: individual draggable control point
- `editable_curve.tscn`: base curve scene
- `editable_bezier.tscn`: Bezier interpolation preset
- `editable_catmull_rom.tscn`: Catmull-Rom interpolation preset

## Behavior

- Supports Bezier, Catmull-Rom, and Linear interpolation modes.
- Emits `curve_changed` signal when control points move.
- Works as @tool script for editor preview.
