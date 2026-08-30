# Cloth Drape, Two Corners

A rectangle of cloth held at its top two corners. Before it, a particle must already carry a position and a previous position — Verlet keeps velocity nowhere else.

Lay the mass points out in a grid.

```gdscript
for r in rows:
    for c in cols:
        var x: float = (float(c) - float(cols - 1) * 0.5) * cell_size
        var y: float = -float(r) * cell_size
        sim.add_particle(origin + Vector3(x, y, 0),
            _cloth_is_pin(pin_mode, c, r, cols, rows))
```

Sixteen by sixteen at 0.16 m, hanging down from row zero. Nothing in the grid says what shape it will find.

Pin exactly two of the 256.

```gdscript
static func _cloth_is_pin(mode: String, c: int, r: int, cols: int, rows: int) -> bool:
    match mode:
        "top_corners":  return r == 0 and (c == 0 or c == cols - 1)
        "top_row":      return r == 0
        "four_corners": return (r == 0 or r == rows - 1) and (c == 0 or c == cols - 1)
    return false
```

`pin_mode` is the whole difference between this room and sb02, sb03, sb04. One boolean per particle decides the drape.

String each point to its neighbours.

```gdscript
var idx: int = r * cols + c
if c < cols - 1:
    sim.add_spring(idx, idx + 1)
if r < rows - 1:
    sim.add_spring(idx, idx + cols)
```

Structural springs — the weave itself. Rest length defaults to the distance the pair already has, so the flat grid starts with zero stored energy.

Cross the squares, then skip a neighbour.

```gdscript
sim.add_spring(idx, idx + cols + 1)   # shear — stops the grid racking
sim.add_spring(idx + 1, idx + cols)
sim.add_spring(idx, idx + 2)          # bend — stops it folding onto itself
```

Neither family is visible in the finished drape. Both are why there is a drape and not a heap.

Integrate without storing a velocity.

```gdscript
func step(dt: float) -> void:
    for i in positions.size():
        if pinned[i]:
            continue
        var pos: Vector3 = positions[i]
        var vel: Vector3 = (pos - prev_positions[i]) * damping
        prev_positions[i] = pos
        positions[i] = pos + vel + gravity * dt * dt
```

Verlet: velocity is the gap between where a point is and where it was. A pinned point is simply skipped, so its gap stays zero and it never moves.

Pull every spring back toward its rest length.

```gdscript
for _p in constraint_passes:
    for s in springs:
        var diff: Vector3 = positions[s[1]] - positions[s[0]]
        var cur: float = diff.length()
        var corr: Vector3 = (diff / cur) * (cur - s[2]) * 0.5 * stiffness
        if not pinned[s[0]]:
            positions[s[0]] += corr
        if not pinned[s[1]]:
            positions[s[1]] -= corr
```

Four passes per step, each halving the error it can see. Nothing solves the cloth globally. The shape is what is left once the local disagreements stop moving.

Run it a fixed number of steps.

```gdscript
sim.simulate(240, 1.0 / 60.0)
```

Same config, same pose, every time. There is no random number anywhere in this room, which is why the still can be a piece of evidence.

Emit the surface from the settled positions.

```gdscript
for r in rows - 1:
    for c in cols - 1:
        var i0: int = r * cols + c
        var i2: int = (r + 1) * cols + c + 1
        indices.append_array([i0, i0 + 1, i2, i0, i2, (r + 1) * cols + c])
```

Two triangles per cell, normals recomputed afterward. The catenary was never drawn — it is what 256 points and their springs agree on once gravity has finished asking. Hang a chain, a cable or a soap film the same way and you get the same curve.
