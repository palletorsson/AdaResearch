extends Node

var text = '''[center][font_size=28][b]Simplex Noise[/b][/font_size][/center]
[center][i]Improved Perlin, Fewer Artifacts, Higher Dimensions[/i][/center]

**Simplex noise improves on Perlin noise.**

**Ken Perlin (2001)** - fixed Perlin's directional artifacts.

**Key improvements:**
- **Simpler gradient calculations** (fewer operations)
- **Better visual quality** (no directional bias)
- **Scales better to higher dimensions** (3D, 4D+)
- **Faster** (fewer gradient lookups)

[hr]

[b]Differences from Perlin[/b]

**Grid shape:**
- **Perlin:** Square/cubic grid
- **Simplex:** Triangular/tetrahedral (simplex) grid

**Interpolation:**
- **Perlin:** Bilinear/trilinear (4/8 points)
- **Simplex:** Barycentric (3/4 points - fewer)

**Result:** Smoother, less artifacts, faster.

[hr]

[b]Applications[/b]

Same as Perlin:
- **Terrain**
- **Textures**
- **Procedural detail**

But better quality and performance.

[hr]

[b]Queer Simplex[/b]

**Simplex improves on Perlin** - iterative refinement, not revolution.

**This is queer progress:**
- **Not starting from scratch** (building on Perlin)
- **Addressing artifacts** (fixing visible biases)
- **Optimization** (better performance without changing essence)

**Both Perlin and Simplex = smooth organic noise.** **Simplex just does it better.**

**Queerness:** Sometimes we improve existing structures rather than rejecting them entirely. **Reform and revolution both valid.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Simplex noise: improved Perlin (2001). Simplex grid (not square), fewer gradients, less artifacts, faster, scales to higher dimensions. Same applications. Queer simplex: iterative improvement vs revolution, building on existing structures, reform as valid strategy.

'''
