# Effects

Visual effects and rendering techniques.

## Contents

| Folder | Description |
|--------|-------------|
| `clipping/` | Clipping planes — reveal cross-sections of objects |
| `flashlight_demo/` | Spotlight/flashlight effects |

## Clipping Planes

Slice through geometry to reveal internal structure:

```
    Before          After (clipped)
    ┌─────┐         ┌──┐
    │     │    →    │░░│ ← cross-section visible
    │     │         │░░│
    └─────┘         └──┘
```

## Files

- 1 GDScript file
- 3 scene files
