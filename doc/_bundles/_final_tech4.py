import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

p = Path('commons/maps/Point_Lines/technical.md')
p.write_text(p.read_text(encoding='utf-8').rstrip() + """

## Performance

The map's grid is small enough that all rendering and interaction costs are trivial. For larger grids the geometry batches into MultiMeshInstance3D and scales to hundreds of thousands of instances on modern hardware. The map deliberately stays small because the concept being taught is multiplicity of points and their linear connections, and only a handful of examples is needed for the concept to land cleanly.
""", encoding='utf-8')

t = Path('commons/maps/Trans_Introduction/technical.md')
t.write_text(t.read_text(encoding='utf-8').rstrip() + """

## More Code Examples

```gdscript
# Combining two transforms into one chain
var combined := Transform3D.IDENTITY * first * second

# Inverse of a transform
var inverse := t.affine_inverse()

# Interpolating between two transforms for smooth animation
var midway := start.interpolate_with(end, 0.5)
```
""", encoding='utf-8')

print('done')
