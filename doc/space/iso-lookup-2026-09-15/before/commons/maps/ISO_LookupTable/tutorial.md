# 256 Cases, 15 Shapes

Eight corners, each in or out: 256 configurations. Symmetry collapses them to fifteen.

```gdscript
func corner_mask(corners: Array[float], iso: float) -> int:
    var mask := 0
    for i in 8:
        if corners[i] > iso:
            mask |= 1 << i
    return mask     # 0..255
```

The mask is the cell's whole situation compressed to one byte. Case 0 (all outside) and case 255 (all inside) draw nothing — the surface does not pass through. Every other case cuts the cube somehow.

Rotate and mirror the 256 and only fifteen genuinely different cuts remain: one corner clipped, an edge tunnel, a diagonal saddle... The lookup table stores triangle recipes for all 256, but the recipes are the fifteen, turned.

```gdscript
func polygonize(mask: int, corners: Array[float], iso: float) -> void:
    for t in range(0, 16, 3):
        if TRI_TABLE[mask][t] == -1:
            break
        var v := []
        for k in 3:
            var edge := TRI_TABLE[mask][t + k]
            v.append(edge_vertex(edge, corners, iso))
        emit_triangle(v[0], v[1], v[2])
```

The table answers *which edges*; interpolation answers *where on the edge*:

```gdscript
func edge_vertex(edge: int, corners: Array[float], iso: float) -> Vector3:
    var a: int = EDGE_ENDS[edge][0]
    var b: int = EDGE_ENDS[edge][1]
    var t := (iso - corners[a]) / (corners[b] - corners[a])
    return CORNER_POS[a].lerp(CORNER_POS[b], t)
```

The vertex slides along the edge toward whichever corner is closer to the threshold. That `lerp` is why marching cubes looks smooth despite living on a grid — the grid decides *which* edges, the field decides *where*.

Try: stand at the fifteen-cases display and find the two ambiguous cases (the diagonal saddles). Two corners inside, diagonally opposite — should the surface tunnel or pinch? The table simply *decides*, and every marching-cubes cave in this sequence inherits that decision.
