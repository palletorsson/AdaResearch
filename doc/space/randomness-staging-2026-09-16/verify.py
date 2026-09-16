import collections
import json
import re
import urllib.request
from stage import ROOT, OUT, ROOMS, load, placements

checks = []
def check(ok, label):
    checks.append({'passed': bool(ok), 'check':label})

roles = load(ROOT/'commons/data/artifact_roles.json')
plans = [load(ROOT/p)['plans'] for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']]
all_tokens = []
for name, (w,d,_,_) in ROOMS.items():
    data = load(ROOT/'commons/maps'/name/'map_data.json')
    items = placements(data)
    tokens = [p['lookup'] for p in items]
    all_tokens += tokens
    for layer, rows in data['layers'].items():
        check(len(rows)==d and all(len(row)==w for row in rows),f'{name}: {layer} dimensions')
    primary = {k for k,v in roles['roles'][name].items() if v=='primary'}
    final = (ROOT/'commons/maps'/name/'final.md').read_text(encoding='utf-8')
    anchors = set(re.findall(r'<!--\s*@([^\s>]+)\s*-->', final))
    check(anchors == primary, f'{name}: final.md anchors equal primary roles')
    check(set(roles['roles'][name])==set(tokens),f'{name}: role inventory equals placed inventory')
    rows = [next(r for r in plan if r.get('map')==name) for plan in plans]
    check(rows[0]==rows[1],f'{name}: desktop and shipped plans agree')
    check(collections.Counter(a['token'] for a in rows[0]['artifacts'])==collections.Counter(tokens),f'{name}: museum plan contains exact inventory')
    runtime = load(OUT/(name+'-runtime.json'))
    check(not runtime['failures'],f'{name}: museum instantiation and floor probe pass')
    check({a['lookup'] for a in runtime['artifacts']}==set(tokens),f'{name}: all curated scenes instantiate')
    logs = (OUT/(name+'-process.log')).read_text(encoding='utf-8')
    check('SCRIPT ERROR' not in logs, f'{name}: no runtime script errors')
    check('[em-walk]' not in logs,f'{name}: no automatic walk-route repair required')
    for a in runtime['artifacts']:
        if a['lookup'] in ['random_butterflies','cube_projectile_spawner']: continue
        box = a['bounds']
        check(box['min'][0]>=0.49 and box['max'][0]<=w-1.49 and box['min'][2]>=0.49 and box['max'][2]<=d-1.49,
              f'{name}: {a["lookup"]} visual footprint inside walls')
    with urllib.request.urlopen('http://localhost:3003/api/book-text?map='+name,timeout=25) as response:
        live = json.load(response)
    check(live['sections']['final'].replace('\r\n','\n').strip()==final.strip(),f'{name}: live book serves revised prose')
    check(live['artifacts'].replace('\r\n','\n').strip()==(ROOT/'commons/maps'/name/'artifacts.md').read_text(encoding='utf-8').strip(),f'{name}: live room inventory agrees')

check(len(all_tokens)==len(set(all_tokens)), 'No artifact lookup repeats across the seven active halls')
report = {'checks':len(checks),'failed':[c['check'] for c in checks if not c['passed']], 'details':checks,
          'placements':len(all_tokens),'headset_verified':False}
(OUT/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='details'},indent=2))
raise SystemExit(bool(report['failed']))
