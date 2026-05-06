**Voxel Noise**
Discretizing the Continuum

## From Field to Block

Noise is mathematically continuous—a smooth field of values.
But computers are discrete. To build a world, we must **sample** or **quantize** that field.

Here, we turn the smooth noise function into **Voxels** (Volumetric Pixels).

---

## Thresholding

How do we decide where to place a block?

```
if noise(x, y, z) > threshold:
    place_block(x, y, z)
else:
    empty_space()
```

This simple rule creates caves, islands, and Swiss-cheese structures.

---

The