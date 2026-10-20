"""Defer the closing interlude; retain its authored sources and restoration data."""
from copy import deepcopy
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-randomness-without-the-ladder'
TARGET = 'Biome_Ladder_Randomness'


def read(rel):
    return json.loads((ROOT / rel).read_text(encoding='utf-8-sig'))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    seq_rel = 'commons/maps/sequences/randomness.json'
    plan_rel = 'commons/data/museum/em_plan.json'
    authored_rel = 'commons/data/map_authored.json'
    long_rel = 'commons/data/long_museum.json'
    seq_doc = read(seq_rel)
    seq = seq_doc['sequences']['randomness']
    if TARGET in seq.get('deferred_maps', []):
        print('Already deferred; no route rewritten.')
        return
    originals = {rel: (ROOT / rel).read_bytes() for rel in [seq_rel, plan_rel, authored_rel, long_rel]}
    plan, authored, long = read(plan_rel), read(authored_rel), read(long_rel)
    old_plan = deepcopy(plan)
    interlude = next(x for x in seq['museum_interludes'] if x['map'] == TARGET)
    row = next(x for x in plan['plans'] if x.get('map') == TARGET)
    assert row['sequence'] == 'randomness' and interlude['after'] == 'Random_Game'
    old_route = authored['randomness'][:]
    assert old_route[-2:] == ['Random_Game', TARGET]
    route = old_route[:-1]
    assert len(seq['maps']) == 14 and len(route) == 15 and 'Biome_Cage' in route
    seq['museum_interludes'].remove(interlude)
    seq['deferred_maps'].append(TARGET)
    seq['deferred_reason'][TARGET] = 'Palle, 2026-10-09: leave the closing biome ladder out for now. Random Game closes the sequence and leads directly to Noise. Keep map and artifacts for later.'
    seq.setdefault('deferred_museum_interludes', []).append(interlude)
    seq['local_review_history'].append({'date': '2026-10-09', 'reason': 'Defer only the closing biome ladder. Fourteen teaching halls and the earlier Biome Cage interlude remain in their existing order.', 'previous_museum_route': old_route})
    plan['plans'].remove(row)
    for r in plan['plans']:
        if r.get('sequence') == 'randomness':
            assert r['map'] in route
            r['pearl_index'] = route.index(r['map'])
            r['pearls_total'] = len(route)
    chapter = next(c for c in plan['_map_halls']['chapters'] if c['chapter'] == 'randomness')
    chapter['maps'] = route
    chapter['halls'] -= 1
    chapter['replaced'] -= 1
    plan['_map_halls']['halls'] -= 1
    authored['randomness'] = route

    # This is an older strip snapshot, not a new engine measurement. Remove
    # only this hall/vestibule and translate subsequent coordinates as a unit.
    i = next(i for i, s in enumerate(long['segments']) if s.get('name') == TARGET)
    removed = long['segments'][i-1:i+1]
    assert removed[0]['kind'] == 'vestibule' and removed[0]['sequence'] == 'randomness'
    start, end = removed[0]['z0'], removed[1]['z1']
    span = end-start
    n_artifacts = len(removed[1]['artifacts'])
    del long['segments'][i-1:i+1]
    for s in long['segments']:
        if s['z0'] >= end:
            s['z0'] -= span
            s['z1'] -= span
    for c in long['chapters']:
        if c['sequence'] == 'randomness':
            c['halls'] -= 1
            c['artifacts'] -= n_artifacts
            c['z1'] -= span
            c['walked'] -= 1
            c['walked_metres'] -= removed[1]['h'] * long['unit_m']
        elif c['z0'] >= end:
            c['z0'] -= span
            c['z1'] -= span
    totals = long['totals']
    for k in ['halls', 'vestibules', 'walked_halls']:
        totals[k] -= 1
    totals['cells_z'] -= span
    for k in ['metres', 'built_metres']:
        totals[k] -= span * long['unit_m']
    totals['walked_metres'] -= removed[1]['h'] * long['unit_m']
    totals['artifacts'] -= n_artifacts
    long['_route_revision'] = {'date': '2026-10-09', 'deferred': TARGET, 'note': 'Targeted removal from the existing strip snapshot. Other hall geometry is preserved, subsequent Z offsets close the gap. Not a fresh engine walk or regeneration of unrelated chapters.'}

    # Verify that unrelated plan rows and every retained room are preserved.
    assert [r for r in plan['plans'] if r.get('sequence') != 'randomness'] == [r for r in old_plan['plans'] if r.get('sequence') != 'randomness']
    for before in old_plan['plans']:
        if before.get('sequence') == 'randomness' and before.get('map') != TARGET:
            after = next(r for r in plan['plans'] if r.get('map') == before['map'])
            assert {k:v for k,v in before.items() if k not in ('pearl_index','pearls_total')} == {k:v for k,v in after.items() if k not in ('pearl_index','pearls_total')}
    assert [r['map'] for r in plan['plans'] if r.get('sequence') == 'randomness'] == route
    source_hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'commons/maps'/TARGET).rglob('*') if p.is_file()}
    restore = {'map': TARGET, 'interlude': interlude, 'museum_plan_row': row, 'strip_segments': removed, 'previous_route': old_route, 'source_hashes': source_hashes}
    (OUT/'deferred-ladder.json').write_text(json.dumps(restore,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for rel, data in originals.items():
        assert (ROOT/rel).read_bytes() == data, f'Concurrent edit: {rel}'
        backup = OUT/'before'/rel
        backup.parent.mkdir(parents=True,exist_ok=True)
        backup.write_bytes(data)
    # Keep the compact formats of the two large generated documents.
    for rel, doc, opts in [(seq_rel,seq_doc,{'indent':2}), (authored_rel,authored,{'indent':2}), (plan_rel,plan,{}), (long_rel,long,{'separators':(',',':')})]:
        (ROOT/rel).write_text(json.dumps(doc,ensure_ascii=False,**opts)+'\n',encoding='utf-8')
    print(json.dumps({'teaching_halls':len(seq['maps']), 'museum_halls':len(route), 'last_hall':route[-1], 'deferred_map_files_preserved':len(source_hashes), 'strip_span_removed':span}))


if __name__ == '__main__':
    main()
