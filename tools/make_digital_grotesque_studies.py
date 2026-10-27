"""Author three comparable body recipes; never rewrite a resident's live archive."""
from pathlib import Path
import copy
import json
import math
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'commons/artifacts/chains_studies/futures.json'
OUT = SOURCE.with_name('beauty_studies.json')


def mesh(shape, size, color, at=None, scale=None, rot=None):
    item = {'p': 'mesh', 'shape': shape, 'size': size, 'color': color}
    for key, value in [('at', at), ('scale', scale), ('rot', rot)]:
        if value is not None:
            item[key] = [round(v, 5) for v in value]
    return item


def group(parts):
    return {'op': 'compose', 'parts': parts}


def make_study(key, label, description, palette, faceted=False):
    doc = json.loads(SOURCE.read_text(encoding='utf8'))
    recipe = copy.deepcopy(next(v['recipe'] for v in doc['versions'] if v['id'] == 'room-within'))
    parts = {p['id']: p for p in recipe['of']['parts']}
    # Preserve the already-walkable shell. The comparison changes its visible
    # construction, never stretches its sphere colliders or closes the doorway.
    for pearl in parts['torso']['of']['parts']:
        # Keep the round collision substrate, but let the overlapping folds make
        # the visible envelope. The first test looked too much like a bead box.
        pearl['of']['parts'] = [p for p in pearl['of']['parts'] if p.get('p') != 'mesh']
    folds = []
    shape = 'dodeca' if faceted else 'sphere'
    for col in range(22):
        angle = math.tau * col / 22
        x, z = 1.30 * math.sin(angle), .91 * math.cos(angle)
        if z > 0 and abs(x) < .76:
            continue
        for row in range(5):
            phase = row * .8 + col * .65
            y = .38 + row * .47
            bulge = 1 + .10 * math.sin(phase)
            color = palette[(col + row // 2) % len(palette)]
            folds.append(mesh(shape, [.25], color, [x * bulge, y - 1.23, z * bulge],
                              [.76, 1.36 if faceted else 1.72, .72],
                              [0, -math.degrees(angle), 16 * math.sin(phase)]))
    # The ruff is intentionally incomplete at the entrance: ornament offers a
    # threshold, rather than hanging across a visitor's face.
    ruff = []
    for i in range(17):
        angle = math.radians(43 + i * 17)
        r = 1.24 + .10 * math.sin(i * 1.2)
        ruff.append(mesh(shape, [.26], palette[(i + 1) % len(palette)],
                         [r * math.sin(angle), .15 * math.sin(i * .65), .87 * math.cos(angle)],
                         [.70, 1.0 + .35 * math.sin(i * .7), 1.75], [0, math.degrees(angle), 0]))
    parts['torso']['of']['parts'].append({'id': 'outer_folds', 'at': [0, 0, 0], 'of': group(folds)})
    parts['skirt'].update(at=[0, 2.58, 0], scale=[1, 1, 1], of=group(ruff))

    # An open fan and an off-centre face replace the upright crown. The head is
    # still legible as a component, not a goal of human anatomical correctness.
    fan = []
    for i in range(13):
        a = math.radians(-80 + i * 160 / 12)
        fan.append(mesh(shape, [.22], palette[i % len(palette)],
                        [.76 * math.sin(a), .50 * math.cos(a) - .22, -.12],
                        [.52, 1.70, .65], [0, 0, -math.degrees(a)]))
    parts['crown'].update(at=[.05, 3.15, -.18], of=group(fan))
    parts['head'].update(at=[-.13, 2.94, .06], of=mesh(shape, [.32], palette[1], scale=[.85, 1.0, .72]))

    for side, sign in [('left', -1), ('right', 1)]:
        flourish = []
        for i in range(8):
            a = i * .34
            flourish.append(mesh(shape, [.20], palette[i % len(palette)],
                                  [sign * (.42 * math.sin(a)), .48 * math.cos(a), -.08 * i],
                                  [.74, 1.3, .68], [0, 0, sign * i * 12]))
        parts[side + '_reach'].update(at=[sign * 1.40, 1.93 + (.15 if sign < 0 else 0), -.10],
                                     of=group(flourish), rot=[0, 0, sign * -15])
        parts[side + '_support']['of'] = group([
            mesh(shape, [.28], palette[2], [sign * .10, -.17, .05], [1.1, .65, 1.25]),
            mesh(shape, [.19], palette[0], [0, .18, 0], [.85, 1.85, .85])])

    for name in ['extra_reach', 'splice_loop']:
        # Retain Splice's ring and its identity, give the gifts the same palette.
        def recolor(expr):
            if isinstance(expr, dict):
                if expr.get('p') == 'mesh':
                    expr['color'] = palette[2]
                if expr.get('op') == 'associate':
                    return recolor(expr['of'])
                for k, v in list(expr.items()):
                    if isinstance(v, (dict, list)):
                        expr[k] = recolor(v)
            elif isinstance(expr, list):
                return [recolor(x) for x in expr]
            return expr
        parts[name]['of'] = recolor(parts[name]['of'])

    if key == 'velvet-excess':
        # A pair of flamboyant side fans makes this a different silhouette, not
        # just another colour preset. Nothing occupies the doorway in front.
        for side, sign in [('left', -1), ('right', 1)]:
            petals = []
            for i in range(9):
                a = math.radians(-75 + i * 18)
                petals.append(mesh('sphere', [.24], palette[i % len(palette)],
                                   [sign * .42 * math.cos(a), .68 * math.sin(a), -.16],
                                   [1.70, .55, .70], [0, 0, sign * math.degrees(a)]))
            recipe['of']['parts'].append({'id': side + '_fan', 'at': [sign * 1.45, 1.45, -.32], 'of': group(petals)})
            recipe['links'].append({'a': side + '_reach', 'b': side + '_fan', 'kind': 'rod'})
    if faceted:
        # Two generations of geometry coexist. No smoothing-away of the coarse
        # facets: tiny bright vertices make the construction visible at a distance.
        marks = []
        for i in range(22):
            a = math.tau * i / 22
            marks.append(mesh('octa', [.065], palette[2], [1.40 * math.sin(a), .07 * math.sin(i), .97 * math.cos(a)]))
        recipe['of']['parts'].append({'id': 'facet_memory', 'at': [0, 2.61, 0], 'of': group(marks)})
        recipe['links'].append({'a': 'crown', 'b': 'facet_memory', 'kind': 'rod'})
    return {'id': key, 'label': label, 'description': description, 'palette': palette,
            'inhabitable': True, 'authored': True, 'recipe': recipe}


if __name__ == '__main__':
    assert not OUT.exists() or '--replace-authored' in sys.argv, 'Existing studies are preserved; edit them deliberately.'
    studies = [
        make_study('rose-mantle', 'The folded host',
                   'Rose folds gather around an open body. A face, a fan and a borrowed loop remain legible; the visitor is invited into the space they make.',
                   ['b26086', 'f0bbbf', 'd6a866', 'd98fa7']),
        make_study('velvet-excess', 'An excess of limbs',
                   'Deep violet, turquoise and copper. Side fans exaggerate the silhouette; repetition becomes a chosen costume rather than a repair towards a normal body.',
                   ['492c64', '92649e', 'd8a26b', '48928e']),
        make_study('facet-memory', 'The obsolete becomes precious',
                   'Ivory facets and ink-coloured seams keep their angular construction. The older digital body is retained as material for ornament and shelter.',
                   ['c6c2ce', 'f4e5ce', '88728e', 'b8a4ae'], faceted=True)]
    OUT.write_text(json.dumps({'schema': 1, 'authored': True, 'studies': studies}, indent=2) + '\n', encoding='utf8')
    print(OUT)
