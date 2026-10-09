"""Verify inventory conservation, ownership and walk-space reservations."""
from pathlib import Path
from collections import Counter
import json

ROOT = Path.cwd()
OUT = ROOT/'doc/space/ribbon-pattern-consolidation-2026-09-09'
def read(p): return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def token(v): return str(v).split(':')[0].split('#')[0].strip()
def inventory(d): return Counter(token(v) for row in d['layers']['interactables'] for v in row if token(v))
report=read(OUT/'report.json'); checks=0
def check(ok, message):
    global checks
    checks+=1
    assert ok,message
before=Counter(); after=Counter()
for name in report['source_maps']:
    check(not (ROOT/'commons/maps'/name).exists(), name+' retired from active maps')
    a=OUT/'retired'/name/'map_data.json';b=OUT/'before/commons/maps'/name/'map_data.json'
    check(a.read_bytes()==b.read_bytes(),name+' archived without changes')
    before.update(inventory(read(a)))
names=[r['map'] for r in report['rooms']]
for r in report['rooms']:
    d=read(ROOT/'commons/maps'/r['map']/'map_data.json');i=inventory(d);after.update(i)
    check(i==Counter(p['token'] for p in r['placements']),r['map']+' inventory matches destinations')
    w,h=r['dimensions'];middle=w//2
    check(all(len(rows)==h and all(len(row)==w for row in rows) for rows in d['layers'].values()),r['map']+' layers aligned')
    for p in r['placements']:
        b=p['reserved_bounds']
        check(b[0]>1 and b[2]<w-1 and b[1]>1 and b[3]<h-1,p['token']+' inside room')
        check(b[2]<middle-1.5 or b[0]>middle+1.5,p['token']+' clear of aisle')
    for a_index,a in enumerate(r['placements']):
        for b in r['placements'][a_index+1:]:
            x=a['reserved_bounds'];y=b['reserved_bounds']
            check(x[2]<=y[0] or y[2]<=x[0] or x[3]<=y[1] or y[3]<=x[1],a['token']+' and '+b['token']+' reservations separate')
removed=Counter(p['token'] for p in report['removed'])
check(before==after+removed,'every original placement retained or accounted for as a duplicate')
check(len(after)==37 and all(n==1 for n in after.values()),'37 unique remaining artifacts, exactly once')
for removal in report['removed']:
    check(any(removal['token'] in inventory(read(ROOT/'commons/maps'/owner['map']/'map_data.json')) for owner in removal['retained_at']),removal['token']+' retained in authored room')
for seq in ['color','tiling']:
    maps=read(ROOT/f'commons/maps/sequences/{seq}.json')['sequences'][seq]['maps']
    check(not any(m.startswith('Ribbon_Color_') for m in maps),seq+' contains no old ribbon rooms')
    check(all((m in maps)==(seq=='tiling') for m in names),seq+' owns correct annexes')
    book=read(ROOT/f'commons/data/book/{seq}.json')
    check([p['map'] for p in book['pearls']]==maps,seq+' book follows sequence')
    for plan in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
        rows=read(ROOT/plan)['plans']
        check([r['map'] for r in rows if r.get('sequence')==seq]==maps,seq+' matches '+plan)
for fn in ['long_museum.json','museum_order_effective.json']:
    d=read(ROOT/'commons/data'/fn)
    check('Ribbon_Color_' not in json.dumps(d),fn+' has no obsolete ribbon entries')
print(f'{checks} consolidation invariants passed.')
