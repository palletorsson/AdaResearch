# Origin Primitive

`origin.tscn` visualizes `(0,0,0)` as a rotating octahedron with cycling aliases.

## Files

- `origin.tscn`: scene wrapper
- `origin.gd`: runtime marker + label cycle

## Behavior

- Generates octahedron mesh at runtime.
- Rotates continuously for visibility.
- Cycles textual aliases (e.g. `Vector3.ZERO`, `origin`, `world origin`).

## Usage

Registry key: `origin`

Typical map placement:

```json
"origin:180:-0.5"
```

Use as conceptual anchor, not as a highly interactive object.
