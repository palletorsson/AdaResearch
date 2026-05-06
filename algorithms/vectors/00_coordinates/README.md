# Coordinate System 3M

`CoordinateSystem3M` renders X/Y/Z axes with labels and optional runtime info panel.

## Files

- `CoordinateSystem3M.tscn`
- `CoordinateSystem3M.gd`

## Behavior

- Builds axis geometry at runtime (`CylinderMesh` shafts + cone tips).
- Uses transparent unshaded materials for legibility.
- Adds info panel and gyroscope gadget at runtime (not in editor hint mode).

## Usage

Registry key: `CoordinateSystem3M`

Typical map placement:

```json
"CoordinateSystem3M:0:1"
```
