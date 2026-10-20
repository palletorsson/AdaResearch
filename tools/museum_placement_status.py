"""Make a report distinguish a built preview from an installed museum artifact."""
from pathlib import Path
import hashlib, html, json, re, subprocess
from datetime import datetime, timezone

ROOT=Path(__file__).resolve().parents[1]
OVERVIEW='/book-review/doc/book/iterations/2026-10-09-one-arcade-four-operations/placement.html'

def strings(value):
    if isinstance(value,str):yield value
    elif isinstance(value,list):
        for item in value:yield from strings(item)
    elif isinstance(value,dict):
        for item in value.values():yield from strings(item)

def inspect(lookup,registry_name):
    registry=ROOT/'commons/artifacts/registry'/registry_name
    entry=json.loads(registry.read_text(encoding='utf-8-sig'))['artifacts'][lookup]
    route=ROOT/'commons/data/long_museum.json'
    route_names=set(strings(json.loads(route.read_text(encoding='utf-8-sig'))))
    result=subprocess.run(['rg','-l',r'"'+re.escape(lookup)+r'[:"#]','commons/maps','-g','map_data.json'],cwd=ROOT,text=True,capture_output=True)
    if result.returncode not in (0,1):raise RuntimeError(result.stderr)
    placements=[];evidence=[registry,route]
    for filename in result.stdout.splitlines():
        path=ROOT/filename;data=json.loads(path.read_text(encoding='utf-8-sig'))
        cells=data.get('layers',{}).get('interactables',[])
        hits=[]
        for z,row in enumerate(cells):
            if not isinstance(row,list):continue
            for x,value in enumerate(row):
                if isinstance(value,str) and value.split(':')[0].split('#')[0]==lookup:
                    hits.append({'row':z,'column':x,'token':value})
        if hits:
            placements.append({'map':path.parent.name,'main_route':path.parent.name in route_names,'cells':hits});evidence.append(path)
    on_route=any(p['main_route'] for p in placements)
    status='On the museum route' if on_route else ('Placed outside the main route' if placements else 'Preview only — not placed in the museum')
    return {'lookup':lookup,'status':status,'main_route':on_route,'placements':placements,'scene':entry['scene'],'map_ready':entry.get('map_ready'),
        'checked_at':datetime.now(timezone.utc).isoformat(),'basis':'Exact artifact tokens in map_data.json interactables; map membership in current long_museum.json. Registration and standalone previews do not count as route placement. This is a configuration audit, not a fresh headset traversal.',
        'source_hashes':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in evidence}}

def decorate(folder,lookup,registry_name):
    folder=Path(folder);data=inspect(lookup,registry_name)
    locations=', '.join(p['map'] for p in data['placements']) if data['placements'] else 'Separate Godot preview scene and web review only.'
    text=f'<section id="museum-placement" aria-label="Museum placement" style="max-width:1300px;margin:20px auto;padding:20px 28px;background:#eee2d0;border-left:5px solid #a44a70;font:16px/1.55 Arial,sans-serif;color:#28383b"><strong>MUSEUM STATUS: {html.escape(data["status"])}</strong><br>{html.escape(locations)}<br><a href="{OVERVIEW}">What has actually been added? View placement list →</a></section>'
    page=folder/'index.html';content=page.read_text(encoding='utf-8')
    content=re.sub(r'<section id="museum-placement".*?</section>','',content,flags=re.S)
    content=content.replace('<main>','<main>'+text,1)
    page.write_text(content,encoding='utf-8')
    (folder/'museum-placement.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    note=f'## Museum placement\n\n**{data["status"]}.** {locations}\n\n[Placement overview]({OVERVIEW}). Checked against map placements and current route configuration; this is not a new headset test.\n\n'
    report=folder/'REPORT.md'
    if report.exists():
        md=report.read_text(encoding='utf-8')
        md=re.sub(r'<!-- museum-placement:start -->.*?<!-- museum-placement:end -->\n*','',md,flags=re.S)
        first,separator,rest=md.partition('\n')
        report.write_text(first+'\n\n<!-- museum-placement:start -->\n'+note+'<!-- museum-placement:end -->\n\n'+rest.lstrip(),encoding='utf-8')
    return data

if __name__=='__main__':
    for slug,key,registry in [('2026-10-09-move-the-centre','omoss','randomness.json'),('2026-10-09-the-corridor-has-a-spine','architecture_spine','architecture_spine.json'),('2026-10-09-one-arcade-four-operations','architecture_variations','architecture_variations.json')]:
        result=decorate(ROOT/'doc/book/iterations'/slug,key,registry)
        print(json.dumps({'artifact':key,'status':result['status'],'maps':[p['map'] for p in result['placements']]}))
