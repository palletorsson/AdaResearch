extends Node

# Tutorial content for in-game BBCode display
var text = '''
[center][b]Melting Bernini Columns[/b][/center]
[center][i]Baroque geometry liquefied for VR[/i][/center]

[hr]
[b]What You Are Seeing[/b]
- Five Solomonic columns orbit a queer palette.
- SurfaceTool sculpts fluted shafts with melt compression, bulges, and chaos.
- Capitals and plinths stay intact while only the shaft mesh re-generates.

[hr]
[b]Key Controls[/b]
[color=yellow]Inspector[/color]
[code]
rotate_columns  : spin choreography
animate_melting  : toggle live mesh rebuilds
melt_strength    : intensity of downward sag
rib_depth        : carve deeper or softer flutes
[/code]

[hr]
[b]Algorithm Notes[/b]
- Spiral offsets + sine/cosine waves bend the centerline.
- Rib patterns follow abs(sin(n * theta))^sharpness to emulate carved grooves.
- `base_melt_phase` stores each column's resting deformation so lerp updates stay silky.
- Marble shader blends base/vein colors with layered FBM; disable `use_marble_shader` to fall back to displacement.
- Shader path: res://algorithms/patterngeneration/fabrics/displacement.gdshader (falls back to procedural normals).

[hr]
[b]Try This[/b]
1. Drop `rotate_columns` to study silhouette changes.
2. Animate `melt_speed` from a controller dial for performance art.
3. Swap `queer_colors` at runtime to tint the spotlights and emission.

[hr]
[i]VR Tip[/i]
Keep `vertical_segments` <= 80 on standalone headsets; the dictionary caching lets you animate without GC spikes.
'''
