"""Apply the office revision once, preserving the working-copy baseline."""
from pathlib import Path
import json
import hashlib
import shutil
import os

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAP = ROOT / 'commons/maps/Color_Walls'

def save(path, text):
    path = Path(path)
    old = HERE / 'before' / path.relative_to(ROOT)
    if path.exists() and not old.exists():
        old.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, old)
    pending = path.with_name(path.name+'.office-edit.tmp')
    pending.write_text(text.rstrip()+'\n', encoding='utf-8')
    os.replace(pending, path)

text = (MAP/'final.md').read_text(encoding='utf-8')
rest = text[text.index('<!-- @color_space_navigator -->'):]
rest = rest.replace('Leave the cubicle through its opening.', 'Find a gap between the panes and leave the office.')
save(MAP/'final.md', '''# The view has partitions

<!-- @color_constellation_office -->

A sheet of cyan stands higher than you. Beyond it, magenta crosses your view. The pale floor continues through both colours. For a moment, the room seems to have several distances at once.

Step sideways. A dark patch narrows, then opens into blue. Nothing in the office has moved. You have changed which panes stand between you and the far wall.

There are twelve sheets, staggered across the floor. Some turn away from the others. Their edges stop short of enclosing a room. Follow one edge until you can pass it; the colour that covered the next space falls behind you.

A desk waits to one side. Two more places to work are scattered among the partitions. Sit in imagination, or stand beside a chair and look back through the colours. How much of this office could you call your own without being able to close it?

![Looking through the overlapping colour planes in the museum office.](/book-review/doc/book/iterations/2026-10-01-office-open-colour/layers-glass.png)

*The overlap changes with your position. The panes and the gaps remain still.*

At the entrance, press **FILTER / OPAQUE**. The view closes into coloured surfaces. Take the same route again. The next opening is harder to see, although it has not become narrower.

Press once more. A chair returns through a pane. The pane still stops your body.

In filter mode, the surface lets the view behind it contribute to the colour:

```gdscript
surface.albedo_color.a = 0.52
```

An overlap adds another tint. The pale backing keeps the view bright enough to follow through the layers. This is a blend of screen colours, not a simulation of the wavelengths passing through real glass.

In Paint, your mark joined someone else's on a shared surface. Here the colour between two people changes what each can see. Opaque walls can interrupt that exchange. Gaps still let a view reach around them. Privacy depends on where you stand, where someone else stands, and how far the partition extends.

''' + rest)

text = (MAP/'tutorial.md').read_text(encoding='utf-8')
rest = text[text.index('At the navigator,'):]
save(MAP/'tutorial.md', '''# Three ways to pass

Begin with a chair seen through two coloured panes. Step sideways until only one pane covers it. The chair, its position and its material have stayed fixed. Follow the edge to a gap and walk around the pane. A view through a surface does not promise passage through it.

Return to the entrance and press FILTER / OPAQUE. Repeat your route. Inspect `toggle_office_glass()` in `algorithms/color/color_mixing/color_constellation_office.gd`: it changes the surface material and shadow setting, without rebuilding the collider. The twelve panes are positioned by `PANES` in `office_planes.gd`. Each row contains x, z, yaw, width, height and colour. The geometry uses transforms already introduced in Transformation and a repeated construction already introduced in Arrays.

The new decision is how the surface combines with the view behind it. Both states use `BLEND_MODE_MIX`. Filter mode enables alpha transparency with alpha 0.52; opaque mode disables transparency and sets alpha to 1.0. Start with one pane. Change only its colour, then compare the same chair with and without a second pane in front of it. Keep the supplied pale backing so dark surroundings do not obscure the furniture. This operation blends rendered RGB colours; it is not a model of spectral absorption. Transparent surfaces are sorted for rendering, so their order contributes to the result.

For a first alteration, change one row's yaw, rebuild, and find a new overlap by walking. Keep widths and gaps fixed until you have checked which routes remain possible. The furniture, support geometry and comparison button are supplied apparatus; rebuilding them is not the learning target here.

''' + rest)

text = (MAP/'technical.md').read_text(encoding='utf-8')
middle = text[text.index('## Colour coordinates'):text.index('## Verification')]
save(MAP/'technical.md', '''# Colour as partition, coordinate and path

## Office — current layout, 1 October 2026

The active placement is `color_constellation_office:0:0:1#layout:planes#compare:visibility#plinth:0`. It remains at map cell (23,20), seated on the museum floor. `office_planes.gd` supplies twelve independent QuadMesh sheets, 2.75–3.55 m high, with thin matching box colliders. Fine edge strips and foot clamps make the obstacles legible. Three desks, monitors and chairs retain the office association without enclosing eight workstations.

The staggered transverse panes alternate the central route. Three smaller angled screens interrupt the rectangular pattern. A pale floor, interrupted side wings, rear opening and two overhead strips provide a neutral ground for the colour; a central ceiling slot stays open to the museum sky. The display backing is unshaded and does not cast shadows, so the global dark sky cannot erase the comparison. It does not simulate colour transmitted onto the floor by lights.

Each filter uses one double-sided quad, alpha transparency at 0.52, normal blending, unshaded colour and no cast shadow. One quad avoids applying the tint twice as would happen with two faces of a thin glass box. Fog is disabled on the filter itself; the background retains the museum's rendering. FILTER / OPAQUE disables transparency, sets alpha to 1.0 and enables shadow casting, while preserving RGB values, transforms and the exact collision bodies. Colour filtering here is layered RGB tint, not wavelength-dependent glass absorption. A multiplication trial darkened even a white pane in the current Compatibility renderer, and was rejected on visual inspection. The retained alpha mix is order-dependent; transparent sorting is a rendering limit, especially at intersecting sheets.

`layout=cubicles` retains the earlier forty-pane layout. No layout selects the older eighteen-pane installation and its `mixture=bench/light/retina` variants. These are separate configurations; mixture does not modify the active open office. Reapplying the same placement configuration does not rebuild it.

''' + middle + '''## Verification

Replay the focused production-museum probe:

```powershell
python tools/run_encounter_probe.py Color_Walls --sequence color --render --probe doc/book/iterations/2026-10-01-office-open-colour/probe.gd
```

The probe checks the actual placed artifact, pane/furniture count, filter material, ordinary-controller passage along the staggered route and out through the rear opening in both visibility states, refusal at a pane, real pointer press/release callbacks, unchanged collider identity and idempotent placement configuration. See the saved report and native interior comparisons in the review directory. This is a supplied desktop input journey, not a headset or learner trial. Quest performance, tracked-hand reach and first-time navigation remain to be checked.

The 23/28 September reports remain historical evidence for the former cubicles and the two unchanged colour benches. Their forty-pane and eight-entrance claims do not describe this revision. The current probe confirms both benches remain placed; their previous sample/interpolation checks are not presented as rerun here.
''')

save(MAP/'summary.md', '''# The view has partitions

Twelve freestanding coloured panes break the former cubicle arrangement into overlapping views and gaps. Three workstations remain. A FILTER / OPAQUE console changes how the surfaces render while preserving their positions and collisions. A pale architectural backing makes the filters visible against the museum's dark surroundings.

Two standing exhibits then separate colour coordinates from colour interpolation: finite RGB/HSV sample models, and sixteen gradient samples with endpoint and mode controls. Color_Walls closes the authored Colour sequence. Pattern_Disco follows in Patterns, returning to the familiar floor in colour.
''')
save(MAP/'intent.md', '''Concept: distinguish a changing overlap in the view, fixed physical passage, colour coordinates and interpolation paths.
Sequence role: after Color_Paint's shared changing canvas, Color_Walls introduces colour as a condition between the visitor and the surrounding world. It closes Colour; Pattern_Disco follows in Patterns.
Key artifacts: color_constellation_office, color_space_navigator, gradient_interpolator. All three remain primary and anchored in final.md.
Teaching order: walk to change the overlap of fixed panes; pass through a gap; compare filter and opaque modes with unchanged collision; inspect RGB/HSV models; keep two endpoints while changing interpolation space.
Inherited capabilities: points and coordinates, transforms, repeated construction and material colour. New decision: the rule combining a surface with the view behind it. Supporting fabrication and UI are supplied.
Critical question: what does a partition separate if it never quite encloses a place? Visibility, privacy and bodily passage depend on different conditions.
Open work: tracked-hand reach, headset performance and a first-time visitor walkthrough; no headset readiness claimed.
''')
save(MAP/'blurb.md', 'Step sideways and another colour gathers between the panes. Find a gap to pass through. Change what the walls let you see, then follow two colours along different paths.')
text = (MAP/'critical.md').read_text(encoding='utf-8')
end = text[text.index('A queer reading'):]
save(MAP/'critical.md', '''# An invitation to look

The coloured sheets stop short of enclosing a room. A chair is visible through two of them, concealed by an opaque version of the same surfaces, or visible again from another angle. The comparison separates visibility from passage, but the gaps complicate its promise of privacy: opacity is local to a surface, while a view can go around its edge.

The pale backing is a further condition. The earlier dark render concealed the overlaps; the surrounding architecture and material treatment had to change for them to become legible. The exhibit's setting participates in its argument.

''' + end)

path = MAP/'map_data.json'
text = path.read_text(encoding='utf-8').replace('The view has partitions: compare glass and opaque cubicles with unchanged passage, inspect RGB and HSV coordinates, then change the path between two colours.', 'The view has partitions: walk among overlapping colour planes, compare filter and opaque surfaces with unchanged passage, then inspect colour coordinates and interpolation.')
save(path, text)
path = ROOT/'commons/maps/sequences/color.json'
save(path, path.read_text(encoding='utf-8').replace('Colour at office scale through orthogonal glass cubicles', 'Overlapping colour planes, fixed gaps, colour coordinates and paths'))

path = ROOT/'commons/artifacts/registry/color.json'
text = path.read_text(encoding='utf-8').replace('Eight furnished cubicles with 40 tinted glass panes, 2.6 m high, all at right angles; default retains the mixing installation.', 'Color_Walls selects twelve freestanding colour filters, three workstations and a pale open gallery setting; filter/opaque comparison preserves passage. Cubicles and default mixing installation remain separate configurations.')
# Keep the older DNA refusal as history, but remove its now-false universal claim.
text = text.replace('A fourth reading, refused. Subtractive mixing needs a white ground to subtract FROM,', 'Legacy mixture axis only (not layout=planes, added 2026-10-01 with pale backing and layered alpha tint). A fourth reading, refused. Subtractive mixing needs a white ground to subtract FROM,')
save(path, text)

path = ROOT/'commons/data/museum_core_encounters.json'
data = json.loads(path.read_text(encoding='utf-8'))
rooms = data['rooms']
room = rooms['Color_Walls']
old_text_sha, old_map_sha = room['text_sha256'], room['map_sha256']
text = path.read_text(encoding='utf-8')
text = text.replace(old_text_sha, hashlib.sha256((MAP/'final.md').read_bytes()).hexdigest())
text = text.replace(old_map_sha, hashlib.sha256((MAP/'map_data.json').read_bytes()).hexdigest())
text = text.replace('Historical configuration recovered with perimeter walls; selected colour encounters restored as the primary thread.', 'Open overlapping filters replace the office cubicles; bodily passage stays fixed across visibility modes. Colour coordinates and interpolation follow.')
text = text.replace(room['local_review'], 'doc/book/iterations/2026-10-01-office-open-colour/index.html')
save(path, text)
print('Updated canonical Color_Walls reading, making, technical and current companions; synchronized metadata.')
