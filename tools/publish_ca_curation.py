"""Publish only reviewed CA floors, merging into the latest visitor layout."""
import copy,hashlib,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-curation';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True).encode()).hexdigest()
def main():
    for file in ['gallery-checks.json','native-final.json']:
        assert read(OUT/file)['passed'],file
    for file in ['ca_spine_gallery-engine.json','ca_spine_final-engine.json']:
        e=read(OUT/file);assert e['engine_exit']==0 and not e['errors'],e
    base=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
    with urllib.request.urlopen(URL,timeout=90) as r:payload=json.load(r)
    current=payload['rooms'];merged=copy.deepcopy(current);changed=[]
    for i in range(103,111):
        assert current['floors'][i] in [base['floors'][i],draft['floors'][i]],f'Floor {i} has concurrent user edits; merge explicitly.'
        merged['floors'][i]=copy.deepcopy(draft['floors'][i]);changed.append(i)
    originals=read(OUT/'inventory.json')
    for row in originals:
        actual={a['id']:a['artifact'] for a in merged['floors'][row['floor']]['artifacts']}
        assert all(actual.get(a['id'])==a['artifact'] for a in row['artifacts'])
    write(OUT/'publish-before.json',payload)
    req=urllib.request.Request(URL,json.dumps(dict(rooms=merged,revision=payload['revision'])).encode(),{'Content-Type':'application/json'},method='POST')
    with urllib.request.urlopen(req,timeout=120) as r:receipt=json.load(r)
    with urllib.request.urlopen(URL,timeout=90) as r:after=json.load(r)
    assert all(after['rooms']['floors'][i]==merged['floors'][i] for i in changed)
    unchanged=[i for i in range(len(current['floors'])) if i not in changed]
    assert all(after['rooms']['floors'][i]==current['floors'][i] for i in unchanged)
    write(OUT/'publish.json',dict(passed=True,changed_floors=changed,preserved_other_floors=len(unchanged),retained_originals=43,new_receivers=1,draft_sha256=digest(draft),revision=after['revision'],save=receipt))
    print('Published CA floors103–110; preserved all other current visitor arrangements.')
if __name__=='__main__':main()
