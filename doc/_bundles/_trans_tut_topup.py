import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

generic = """

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.
"""

maps = ['Trans_Introduction', 'Trans_Translation', 'Trans_AxisDecomposition', 'Trans_Rotation', 'Trans_RotationSpectacle', 'Trans_Scale', 'Trans_Pit', 'Chamber_Transformation']

for m in maps:
    p = Path('commons/maps/' + m + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + generic, encoding='utf-8')

print('done', len(maps))
