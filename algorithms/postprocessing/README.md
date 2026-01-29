# Post-Processing

Screen-space effects applied after rendering.

## Contents

| Folder | Description |
|--------|-------------|
| `bloom/` | Glow effect for bright areas |
| `alfahash/` | Alpha hashing for transparency |

## Bloom

Makes bright pixels bleed light into neighbors:

```
Before:  ★        After:  ✨★✨
         │                 │
    dark │ bright     glow around bright
```

## Alpha Hash

Alternative to alpha blending that avoids sorting issues:
- Hash pixel position to determine visibility
- No depth sorting needed
- Stable across frames

## Files

- 2 GDScript files
- 2 scene files
- 2 sub-READMEs
