"""The associations of the Primitives' forms (Palle, 2026-11-03): "where we first encounter a form we should add an
associative object, and the writing like association(config(cylinder)) on a tape on the wall or the floor. Then we
should add these to the inventory and build with them."

One table, written into every place that needs it, so the parts cannot drift apart:
  commons/modular/terms.json            each association a term (form -> configured -> recognised), mostly grabbable
  commons/artifacts/registry/associations.json   mod_<term> tokens + the association tape
  commons/data/inventory/items.json     an inventory item per new association, after the extinguisher
  commons/void/primitive-prefabs.json   the prefab timeline: the hall where the form is first met
  ada_run/associations/plan.json        the tower placement plan (object + its tape near the first encounter),
                                        measured by tools/probes/void_candidates.gd, written to rooms.json by --place
The pilot (fire_extinguisher, floor 9) is already in all of these; it is listed for the tower check only.
  python tools/associations_rollout.py [--write] [--place]
"""
from pathlib import Path
import json, os, sys

ROOT = Path(__file__).resolve().parents[1]

def mesh(shape, size, color, at=(0, 0, 0), rot=None):
    m = {"p": "mesh", "shape": shape, "size": list(size), "color": color, "at": list(at)}
    if rot: m["rot"] = list(rot)
    return m

def col(shape, size, at=(0, 0, 0)):
    return {"p": "collider", "shape": shape, "size": list(size), "at": list(at)}

def ticks(n, length, h, color):
    return [mesh("box", [0.006, 0.003, 0.02 if i % 5 else 0.034], color, (-length / 2 + length * i / n, h, -0.008)) for i in range(1, n)]

def pips():
    s, h = 0.16, 0.16
    top = [(0, h + .001, 0)] + [(dx, h + .001, dz) for dx in (-.045, .045) for dz in (-.045, .045)]
    front = [(-.045, h / 2 + .045, s / 2 + .001), (0, h / 2, s / 2 + .001), (.045, h / 2 - .045, s / 2 + .001)]
    out = [mesh("cylinder", [.014, .003], "1c1c1e", p) for p in top]
    out += [mesh("cylinder", [.014, .003], "1c1c1e", p, (90, 0, 0)) for p in front]
    return out

def tri_edges(side, color, y0):
    import math
    h = side * math.sqrt(3) / 2
    return [mesh("box", [side, .035, .03], color, (0, y0, 0)),
            mesh("box", [side, .035, .03], color, (-side / 4, y0 + h / 2, 0), (0, 0, 60)),
            mesh("box", [side, .035, .03], color, (side / 4, y0 + h / 2, 0), (0, 0, -60))]

# term, form, first-met floor/hall, anchor (where the form is met), the thing, its parts, inventory size, grabbable
TABLE = [
 {"term": "rubber_ball", "form": "point", "floor": 1, "hall": "Point_One", "near": [0, 3], "thing": "a rubber ball",
  "config": "red rubber, 11 cm", "size": [.22, .22, .22],
  "parts": [mesh("sphere", [.11], "d23b2f", (0, .11, 0)), col("sphere", [.11], (0, .11, 0))]},
 {"term": "measuring_stick", "form": "line", "floor": 3, "hall": "Point_Lines", "near": [0, 5.8], "thing": "a measuring stick",
  "config": "yellow, one metre, ticks every 10 cm", "size": [1.0, .03, .045],
  "parts": [mesh("box", [1.0, .02, .045], "f2c94c", (0, .01, 0))] + ticks(10, 1.0, .021, "1c1c1e") + [col("box", [1.0, .02, .045], (0, .01, 0))]},
 {"term": "warning_triangle", "form": "triangle", "floor": 5, "hall": "Point_Triangle_Context", "near": [16, 2.7], "thing": "a warning triangle",
  "config": "red, reflective, on a stand", "size": [.45, .45, .2],
  "parts": tri_edges(.45, "d0342c", .06) + [mesh("box", [.3, .02, .18], "1c1c1e", (0, .01, 0)), col("box", [.45, .45, .2], (0, .225, 0))]},
 {"term": "door_stop", "form": "wedge", "floor": 6, "hall": "Primitives_Polythedra", "near": [16, 3.8], "thing": "a door stop",
  "config": "brown rubber, 14 cm", "size": [.14, .05, .07],
  "parts": [mesh("wedge", [.14, .05, .07], "6b4a2f", (0, 0, 0)), col("box", [.14, .05, .07], (0, .025, 0))]},
 {"term": "gem", "form": "bipyramid", "floor": 6, "hall": "Primitives_Polythedra", "near": [14.4, 2], "thing": "a gem",
  "config": "two cones base to base, glassy blue", "size": [.2, .3, .2],
  "parts": [mesh("cone", [.1, .12], "6fc3e6", (0, .21, 0)), mesh("cone", [.1, .18], "4aa6d6", (0, .09, 0), (180, 0, 0)), col("sphere", [.1], (0, .15, 0))]},
 {"term": "dice", "form": "cube", "floor": 7, "hall": "Point_Animatedcube", "near": [13.7, 4], "thing": "a die",
  "config": "white, 16 cm, black pips", "size": [.16, .16, .16],
  "parts": [mesh("box", [.16, .16, .16], "f4f1ea", (0, .08, 0))] + pips() + [col("box", [.16, .16, .16], (0, .08, 0))]},
 {"term": "beach_ball", "form": "sphere", "floor": 8, "hall": "Primitives_Ignorance", "near": [4.8, 3.8], "thing": "a beach ball",
  "config": "60 cm, white and red", "size": [.6, .6, .6],
  "parts": [mesh("sphere", [.3], "f4f1ea", (0, .3, 0)), mesh("dome", [.302, .302], "e0473a", (0, .3, 0)), col("sphere", [.3], (0, .3, 0))]},
 {"term": "tyre", "form": "torus", "floor": 10, "hall": "Primitives_Profiles", "near": [0, 4.8], "thing": "a tyre",
  "config": "black rubber, 68 cm across, lying flat", "size": [.68, .12, .68],
  "parts": [mesh("torus", [.34, .12], "202226", (0, .06, 0)), col("cylinder", [.34, .12], (0, .06, 0))]},
 # the classics (Palle, 2026-11-03: "yes and cinder block association(cube) very good to prop up, wooden board
 # association(quad)") - each also a piece the physics plays are built from
 {"term": "oil_drum", "form": "cylinder", "floor": 9, "hall": "Primitives_Columns", "near": [2.5, -2], "thing": "an oil drum",
  "config": "blue steel, 58 cm across, 88 cm tall, two rolling ribs", "size": [.58, .88, .58],
  "parts": [mesh("cylinder", [.29, .88], "1f5fa8", (0, .44, 0)), mesh("torus", [.296, .02], "17497f", (0, .3, 0)), mesh("torus", [.296, .02], "17497f", (0, .6, 0)),
            mesh("cylinder", [.27, .01], "9aa3a8", (0, .885, 0)), col("cylinder", [.29, .88], (0, .44, 0))]},
 {"term": "tin_can", "form": "cylinder", "floor": 9, "hall": "Primitives_Columns", "near": [-2, -2], "thing": "a tin can",
  "config": "8 cm across, 12 cm tall, a red label", "size": [.08, .12, .08],
  "parts": [mesh("cylinder", [.04, .12], "b8bec4", (0, .06, 0)), mesh("cylinder", [.041, .07], "c8102e", (0, .06, 0)), col("cylinder", [.04, .12], (0, .06, 0))]},
 {"term": "bowling_pin", "form": "revolve", "floor": 10, "hall": "Primitives_Profiles", "near": [0, -2.8], "thing": "a bowling pin",
  "config": "a profile turned round its axis, 38 cm, white with a red neck band", "size": [.12, .38, .12],
  "parts": [mesh("cylinder", [.035, .03], "f4f1ea", (0, .015, 0)), mesh("sphere", [.06], "f4f1ea", (0, .11, 0)), mesh("cylinder", [.045, .08], "f4f1ea", (0, .19, 0)),
            mesh("cylinder", [.025, .07], "f4f1ea", (0, .265, 0)), mesh("cylinder", [.027, .015], "c8102e", (0, .27, 0)), mesh("sphere", [.036], "f4f1ea", (0, .335, 0)),
            col("cylinder", [.055, .38], (0, .19, 0))]},
 {"term": "marble", "form": "point", "floor": 1, "hall": "Point_One", "near": [1.5, 3], "thing": "a marble",
  "config": "glass, 4 cm", "size": [.04, .04, .04],
  "parts": [mesh("sphere", [.02], "4fb3d9", (0, .02, 0)), col("sphere", [.02], (0, .02, 0))]},
 {"term": "marble_chute", "form": "channel", "floor": 10, "hall": "Primitives_Profiles", "near": [2, 4.8], "thing": "a marble chute",
  "config": "the C profile swept straight: a 1.2 m timber channel", "size": [1.2, .05, .1],
  "parts": [mesh("box", [1.2, .012, .1], "c9a66b", (0, .006, 0)), mesh("box", [1.2, .04, .012], "b8925a", (0, .03, -.044)), mesh("box", [1.2, .04, .012], "b8925a", (0, .03, .044)),
            col("box", [1.2, .012, .1], (0, .006, 0)), col("box", [1.2, .04, .012], (0, .03, -.044)), col("box", [1.2, .04, .012], (0, .03, .044))]},
 {"term": "wooden_block", "form": "cube", "floor": 7, "hall": "Point_Animatedcube", "near": [16, 4], "thing": "a wooden block",
  "config": "light wood, 30 x 10 x 10 cm, the stacking block", "size": [.3, .1, .1],
  "parts": [mesh("box", [.3, .1, .1], "d9b27c", (0, .05, 0)), col("box", [.3, .1, .1], (0, .05, 0))]},
 {"term": "domino_tile", "form": "cube", "floor": 7, "hall": "Point_Animatedcube", "near": [16, 2], "thing": "a domino tile",
  "config": "ivory, 30 cm tall, a line and pips", "size": [.05, .3, .15],
  "parts": [mesh("box", [.05, .3, .15], "f4f1ea", (0, .15, 0)), mesh("box", [.052, .006, .13], "1c1c1e", (0, .15, 0))]
           + [mesh("cylinder", [.012, .003], "1c1c1e", (.026, y, z), (0, 0, 90)) for y, z in ((.23, -.035), (.23, .035), (.07, 0))]
           + [col("box", [.05, .3, .15], (0, .15, 0))]},
 {"term": "cinder_block", "form": "cube", "floor": 7, "hall": "Point_Animatedcube", "near": [17, 5], "thing": "a cinder block",
  "config": "grey concrete, 39 x 19 x 19 cm, two cores - the thing that props things up", "size": [.39, .19, .19],
  "parts": [mesh("box", [.39, .19, .19], "8d8f8f", (0, .095, 0)), mesh("box", [.13, .004, .12], "4a4c4d", (-.095, .191, 0)), mesh("box", [.13, .004, .12], "4a4c4d", (.095, .191, 0)),
            col("box", [.39, .19, .19], (0, .095, 0))]},
 {"term": "wooden_board", "form": "quad", "floor": 5, "hall": "Point_Triangle_Context", "near": [16, 4], "thing": "a wooden board",
  "config": "the quad thickened: 1.2 x 0.6 m, 2.5 cm timber", "size": [1.2, .025, .6],
  "parts": [mesh("box", [1.2, .025, .6], "c9a66b", (0, .0125, 0))] + [mesh("box", [1.18, .002, .004], "a8854f", (0, .026, z)) for z in (-.2, 0, .2)]
           + [col("box", [1.2, .025, .6], (0, .0125, 0))]},
 {"term": "hinge", "form": "rotation", "floor": 16, "hall": "Trans_Rotation", "near": [16.5, 4.5], "thing": "a hinge",
  "config": "two steel leaves and a pin: rotation about one axis, held", "size": [.2, .02, .09],
  "parts": [mesh("box", [.09, .004, .08], "9aa3a8", (-.05, .01, 0)), mesh("box", [.09, .004, .08], "9aa3a8", (.05, .01, 0)),
            mesh("cylinder", [.008, .09], "6f767e", (0, .01, 0), (90, 0, 0)), col("box", [.2, .02, .09], (0, .01, 0))]},
]
# terms the grammar already has, into the inventory only (no new placement)
INVENTORY_ONLY = [
 {"term": "skateboard", "name": "Skateboard - plank + wheel * 4", "floor": 15, "size": [.8, .12, .22]},
 {"term": "wheel", "name": "Wheel - association(cylinder, rubber)", "floor": 15, "size": [.07, .07, .04]},
 {"term": "eu_pallet", "name": "EU pallet - cube * 9 + plank * 11", "floor": 7, "size": [1.2, .144, .8]},
 {"term": "brick", "name": "Brick - a 12 cm block", "floor": 7, "size": [.12, .12, .12]},
 {"term": "wooden_box", "name": "Wooden box - association(cube)", "floor": 7, "size": [.5, .5, .5]},
 {"term": "walk_ramp", "name": "Ramp - association(wedge)", "floor": 6, "size": [1.0, .45, .6]},
]
# already terms (association(tetrahedron), association(cube)): first-encounter placement and tape only
EXISTING = [
 {"term": "plastic_cone", "expr": "plastic_cone = association(tetrahedron)", "floor": 6, "hall": "Primitives_Polythedra", "near": [17, 2.5]},
 {"term": "cardboard_box", "expr": "cardboard_box = association(cube)", "floor": 7, "hall": "Point_Animatedcube", "near": [15, 4]},
]

def expr_of(row): return "%s = association(config(%s))" % (row["term"], row["form"])

def write_terms():
    p = ROOT / 'commons/modular/terms.json'; raw = p.read_text(encoding='utf8'); d = json.loads(raw)
    assert json.dumps(d, indent=2, ensure_ascii=False) + '\n' == raw
    for r in TABLE:
        d['terms'][r['term']] = {"chapter": "association", "label": r['term'],
            "expr": "association(config(%s)) = %s (Palle, 2026-11-03: the %s, configured - %s - and recognised as a thing)" % (r['form'], r['thing'], r['form'], r['config']),
            "from": [r['form'] if r['form'] in d['terms'] else {"bipyramid": "tetrahedron", "torus": "cylinder", "sphere": "point", "revolve": "cylinder", "channel": "line", "rotation": "quad"}.get(r['form'], "cube")],
            "config": {"form": r['form'], "as": r['thing'], "note": r['config']},
            "build": {"op": "associate", "of": {"op": "compose", "parts": r['parts'] + [{"t": "grabbable"}]}}}
    tmp = p.with_suffix('.json.tmp'); tmp.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n', encoding='utf8', newline='\n'); os.replace(tmp, p)

def write_registry():
    p = ROOT / 'commons/artifacts/registry/associations.json'; d = json.loads(p.read_text(encoding='utf8'))
    for r in TABLE:
        d['artifacts']['mod_' + r['term']] = {"lookup_name": 'mod_' + r['term'], "name": "%s / association(config(%s))" % (r['thing'].split(' ', 1)[1].capitalize(), r['form']),
            "description": "%s: the %s of %s, configured (%s) and recognised as %s. A term of the modular class system (commons/modular/terms.json); a grabbable body." % (expr_of(r), r['form'], r['hall'], r['config'], r['thing']),
            "category": "modular", "complexity": "beginner", "scene": "res://commons/modular/composite.tscn", "default_params": {"term": r['term']},
            "configure_before_ready": True, "map_ready": True, "include_in_map_data": True, "map_sequences": ["primitives"], "tags": ["association", r['form'], "inventory", "void"]}
    p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n', encoding='utf8', newline='\n')

def write_items():
    p = ROOT / 'commons/data/inventory/items.json'; raw = p.read_bytes().decode('utf8'); nl = '\r\n' if '\r\n' in raw else '\n'
    d = json.loads(raw); have = {i['id'] for i in d['items']}
    anchor_end = '"defaults": {"term": "fire_extinguisher"},'
    i = raw.index(anchor_end); j = raw.index('    },', i) + len('    },')
    blocks = []
    for r in TABLE:
        iid = r['term'].replace('_', '')
        if iid in have: continue
        blocks.append(nl.join(['    {', '      "id": "%s",' % iid, '      "name": "%s - association(config(%s))",' % (r['thing'].split(' ', 1)[1].capitalize(), r['form']),
            '      "token": "mod_%s",' % r['term'], '      "unlock": "%s",' % ("primitives" if r['floor'] < 13 else "transformation"), '      "floor": %d,' % r['floor'], '      "mount": "any",',
            '      "size": %s,' % json.dumps(r['size']), '      "defaults": {"term": "%s"},' % r['term'],
            '      "knobs": [{"key": "_yaw", "label": "Turned", "choices": ["0", "90", "180", "270"], "names": ["north", "east", "south", "west"]}]', '    },']))
    for r in INVENTORY_ONLY:
        iid = r['term'].replace('_', '')
        if iid in have: continue
        blocks.append(nl.join(['    {', '      "id": "%s",' % iid, '      "name": "%s",' % r['name'], '      "token": "mod_%s",' % r['term'],
            '      "unlock": "%s",' % ("primitives" if r['floor'] < 13 else "transformation"), '      "floor": %d,' % r['floor'], '      "mount": "any",',
            '      "size": %s,' % json.dumps(r['size']), '      "defaults": {"term": "%s"},' % r['term'],
            '      "knobs": [{"key": "_yaw", "label": "Turned", "choices": ["0", "90", "180", "270"], "names": ["north", "east", "south", "west"]}]', '    },']))
    if blocks:
        new = raw[:j] + nl + nl.join(blocks) + raw[j:]
        json.loads(new)
        tmp = p.with_suffix('.json.tmp'); tmp.write_bytes(new.encode('utf8')); os.replace(tmp, p)

def write_prefabs():
    p = ROOT / 'commons/void/primitive-prefabs.json'; raw = p.read_text(encoding='utf8'); d = json.loads(raw)
    assert json.dumps(d, indent=2, ensure_ascii=False) + '\n' == raw
    have = {x['id'] for x in d['prefabs']}
    for r in TABLE:
        if r['term'] in have: continue
        idx = max([k for k, x in enumerate(d['prefabs']) if x.get('map') == r['hall']], default=len(d['prefabs']) - 1)
        d['prefabs'].insert(idx + 1, {"id": r['term'], "title": "%s / association(config(%s))" % (r['thing'].split(' ', 1)[1].capitalize(), r['form']), "map": r['hall'],
            "family": "%s / association" % r['form'].capitalize(), "dimensions": r['size'], "anchor": "Base centre",
            "behaviour": "Carry and place from the inventory; a body that stands, stacks and falls.", "scene": "res://commons/modular/composite.tscn",
            "token": "mod_" + r['term'], "icon": r['form'], "learn": "association(config(%s)): the %s, configured - %s - is recognised as %s." % (r['form'], r['form'], r['config'], r['thing']),
            "recipe": [r['form']]})
    tmp = p.with_suffix('.json.tmp'); tmp.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n', encoding='utf8', newline='\n'); os.replace(tmp, p)

def plan():
    rows = []
    for r in TABLE:
        rows.append({"floor": r['floor'], "token": "mod_" + r['term'], "near": r['near'], "term": r['term'], "text": expr_of(r)})
        rows.append({"floor": r['floor'], "token": "association_tape", "near_previous": True, "term": r['term'], "text": expr_of(r), "tape": True})
    for r in EXISTING:
        rows.append({"floor": r['floor'], "token": "mod_" + r['term'], "near": r['near'], "term": r['term'], "text": r['expr']})
        rows.append({"floor": r['floor'], "token": "association_tape", "near_previous": True, "term": r['term'], "text": r['expr'], "tape": True})
    # only what does not stand yet: an object already in rooms.json is not measured or placed again
    rooms = json.loads((ROOT / 'commons/void/rooms.json').read_text(encoding='utf8'))
    standing = {a['id'] for f in rooms['floors'] for a in f.get('artifacts', [])}
    rows = [r for r in rows if 'association-%s%s' % (r['term'].replace('_', '-'), '-tape' if r.get('tape') else '') not in standing]
    out = ROOT / 'ada_run/associations'; out.mkdir(parents=True, exist_ok=True)
    (out / 'plan.json').write_text(json.dumps(rows, indent=1), encoding='utf8')
    return rows

def place():
    rows = json.loads((ROOT / 'ada_run/associations/plan.json').read_text(encoding='utf8'))
    res = json.loads((ROOT / 'ada_run/associations/placements.json').read_text(encoding='utf8'))
    p = ROOT / 'commons/void/rooms.json'; raw = p.read_text(encoding='utf8'); d = json.loads(raw)
    assert json.dumps(d, indent=2, ensure_ascii=False) + '\n' == raw
    for r in res:
        row = r['row']; s = r['spot']
        if not s: print('NO SPOT', row['token'], row['term']); continue
        f = d['floors'][int(row['floor'])]
        ident = 'association-%s%s' % (row['term'].replace('_', '-'), '-tape' if row.get('tape') else '')
        if any(a['id'] == ident for a in f['artifacts']): continue
        cfg = ({"text": row['text'], "mount": "floor", "editor_label": "Association tape / " + row['term']} if row.get('tape')
               else {"term": row['term'], "editor_label": "Association / %s - where the form is first met" % row['text']})
        f['artifacts'].append({"id": ident, "artifact": row['token'], "station": ('N' if s['z'] < 0 else 'S') + ('W' if s['x'] < 0 else 'E'),
            "position": [s['x'], s['z']], "height": 0, "scale": 1, "facing": s['facing'], "config": cfg})
        print('placed', ident, 'floor', row['floor'], (s['x'], s['z']))
    tmp = p.with_suffix('.json.tmp'); tmp.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n', encoding='utf8', newline='\n'); os.replace(tmp, p)

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf8')
    if '--write' in sys.argv:
        write_terms(); write_registry(); write_items(); write_prefabs(); print('wrote', len(TABLE), 'associations')
    rows = plan(); print(len(rows), 'plan rows')
    if '--place' in sys.argv: place()
