import collections
import json
import re
import urllib.request
from stage import ROOT,OUT,ROOMS,read,save
checks=[]
def check(ok,label):checks.append(dict(passed=bool(ok),check=label))
roles=read(ROOT/'commons/data/artifact_roles.json')
plans=[read(ROOT/p)['plans'] for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']]
all_tokens=[]
for name,(w,d,items,_) in ROOMS.items():
 data=read(ROOT/'commons/maps'/name/'map_data.json')
 tokens=[token.split('#')[0].split(':')[0] for _,_,token in items]; all_tokens+=tokens
 for key,rows in data['layers'].items():check(len(rows)==d and all(len(r)==w for r in rows),name+': '+key+' dimensions')
 primary={k for k,v in roles['roles'][name].items() if v=='primary'}
 prose=(ROOT/'commons/maps'/name/'final.md').read_text(encoding='utf-8')
 check(set(re.findall(r'<!--\s*@([^\s>]+)\s*-->',prose))==primary,name+': book anchors match primary roles')
 check(set(roles['roles'][name])==set(tokens),name+': roles match inventory')
 rows=[next(r for r in p if r.get('map')==name) for p in plans]
 check(rows[0]==rows[1],name+': shipped and desktop plans agree')
 check(collections.Counter(a['token'] for a in rows[0]['artifacts'])==collections.Counter(tokens),name+': plan inventory')
 runtime=read(OUT/(name+'-runtime.json'));checks.extend(runtime['checks'])
 check(not runtime['failures'],name+': all runtime checks pass')
 check({a['lookup'] for a in runtime['artifacts']}==set(tokens),name+': every artifact instantiates')
 for sample in runtime['floor_checks']:check(sample['supported'],name+': floor '+sample['cell'])
 log=(OUT/(name+'-process.log')).read_text(encoding='utf-8')
 check('SCRIPT ERROR' not in log,name+': no script errors')
 check('[em-walk]' not in log,name+': no automatic route repair')
 for a in runtime['artifacts']:
  if a['lookup'] in ['random_butterflies','cube_projectile_spawner']:continue
  b=a['bounds']
  check(b['min'][0]>=0.49 and b['max'][0]<=w-1.49 and b['min'][2]>=0.49 and b['max'][2]<=d-1.49,name+': '+a['lookup']+' fits inside walls')
 with urllib.request.urlopen('http://localhost:3003/api/book-text?map='+name,timeout=25) as response: live=json.load(response)
 check(live['sections']['final'].replace('\r\n','\n').strip()==prose.strip(),name+': live book serves revision')
 check(live['artifacts'].replace('\r\n','\n').strip()==(ROOT/'commons/maps'/name/'artifacts.md').read_text(encoding='utf-8').strip(),name+': live inventory serves revision')
counts=collections.Counter(all_tokens)
check({k:v for k,v in counts.items() if v>1}=={'random_removal_arena':2},'Only repeated work is the intentional removal-floor application in Game')
report=dict(checks=len(checks),failed=[c['check'] for c in checks if not c['passed']],details=checks,placements=len(all_tokens),headset_verified=False)
save(OUT/'verification.json',report)
print(json.dumps({k:v for k,v in report.items() if k!='details'},indent=2))
raise SystemExit(bool(report['failed']))
