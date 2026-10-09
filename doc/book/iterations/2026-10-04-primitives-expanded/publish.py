"""Publish actual museum captures and refresh only the Primitives route metadata."""
from pathlib import Path
import collections
import copy
import html
import json
import re
import shutil

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
ROUTE=ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
NAMES=['Primitives_Godot','Primitives_Columns','Primitives_Profiles']

def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d): p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def backup(p):
    q=OUT/'before'/p.relative_to(ROOT)
    if not q.exists(): q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(p.read_bytes())

def main():
    chapters=load(ROOT/'doc/book/course/storyboards/opening.json')
    primitives=next(x for x in chapters if x['sequence']=='primitives')
    assert all(n in [h['id'] for h in primitives['halls']] for n in NAMES)
    for name in NAMES:
        run=ROOT/'ada_run/encounter_pilot'/name
        assert load(run/'report.json')['passed']
        dest=OUT/name;dest.mkdir(exist_ok=True)
        for f in ['entry.png','inside.png','report.json','source_manifest.json']:
            shutil.copy2(run/f,dest/f)
    backup(ROUTE/'route.json');backup(ROUTE/'index.html')
    route=load(ROUTE/'route.json')
    prior={h['id']:h for h in route['halls']}
    registry={}
    for p in (ROOT/'commons/artifacts/registry').glob('*.json'):
        try: rows=load(p).get('artifacts',{})
        except (ValueError,AttributeError): continue
        for token,entry in rows.items():
            registry[token]=(entry,p.relative_to(ROOT).as_posix())
    updated=[]
    for i,h in enumerate(primitives['halls'],1):
        record=copy.deepcopy(prior.get(h['id'],{}));record.update(h)
        record.update(sequence='primitives',number=i,index=i,plan_present=True)
        name=h['id']
        if name in NAMES or name=='Primitives_Ignorance':
            record['docs']={k:f'../../../../commons/maps/{name}/{k}.md'
                for k in ['final','tutorial','intent','critical','technical','artifacts']
                if (ROOT/f'commons/maps/{name}/{k}.md').exists()}
            record['map_source']=f'../../../../commons/maps/{name}/map_data.json'
            record['placed']=[]
            md=load(ROOT/f'commons/maps/{name}/map_data.json')
            for z,row in enumerate(md['layers']['interactables']):
                for x,token in enumerate(row):
                    if not str(token).strip():continue
                    token=str(token).split(':')[0].split('#')[0]
                    entry,path=registry.get(token,({},''))
                    record['placed'].append({'id':token,'name':entry.get('name',token),
                        'registry':'../../../../'+path,'scene':'../../../../'+entry.get('scene','').replace('res://',''),
                        'cell':[x,z]})
            record['artifact_links']=[x for x in record['placed'] if x['id'] in h.get('artifact_refs',[])]
        if name in NAMES:
            record['images']=[{'src':f'../2026-10-04-primitives-expanded/{name}/{shot}.png',
                'original':f'../../../../ada_run/encounter_pilot/{name}/{shot}.png',
                'evidence':f'../2026-10-04-primitives-expanded/{name}/report.json',
                'date':'2026-10-04','label':f'{name.replace("_"," ")} — {shot}',
                'kind':'Native Endless Museum capture'} for shot in ['entry','inside']]
        updated.append(record)
    route['halls']=updated+[h for h in route['halls'] if h['sequence']!='primitives']
    for i,h in enumerate(route['halls'],1):h['index']=i
    meta=next(s for s in route['sequences'] if s['id']=='primitives')
    meta.update(maps=[h['id'] for h in updated],arc=primitives['arc'])
    route['stats'].update(halls=len(route['halls']),pictured=sum(bool(h.get('images')) for h in route['halls']),
                          modes=dict(collections.Counter(h['mode'] for h in route['halls'])))
    save(ROUTE/'route.json',route)
    page=(ROUTE/'index.html').read_text(encoding='utf-8')
    payload=json.dumps(route,ensure_ascii=False).replace('</','<\\/')
    page=re.sub(r'(<script id="route-data" type="application/json">).*?(</script>)',
                lambda m:m[1]+payload+m[2],page,count=1,flags=re.S)
    page=page.replace('25 sequences and 204 halls','25 sequences and 207 halls').replace('of 204 halls','of 207 halls')
    (ROUTE/'index.html').write_text(page,encoding='utf-8')
    sections=[]
    for name in NAMES:
        h=next(h for h in updated if h['id']==name)
        sections.append(f'''<section id="{name}"><p class="eyebrow">{html.escape(name)}</p>
<h2>{html.escape(h['title'])}</h2><p>{html.escape(h['storyboard'])}</p>
<figure><img src="{name}/entry.png" alt="Entrance view inside {name.replace('_',' ')}"><figcaption>Standing view inside the actual Endless Museum.</figcaption></figure>
<details><summary>A second view and source evidence</summary><img src="{name}/inside.png" alt="Inside the hall"><p><a href="{name}/report.json">Native room and walk checks</a> · <a href="/compose/sources?map={name}&amp;doc=final">Reading</a> · <a href="/project-memory?scope=map%3A{name}&amp;outline=sequence%3Aprimitives&amp;detail=0">Memory and teaching proposal</a></p></details></section>''')
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — room for exploration</title>
<style>:root{color-scheme:light}body{margin:0;background:#eeeae3;color:#25242a;font:18px/1.65 Georgia,serif}main{max-width:1160px;margin:auto;padding:50px 5vw}h1{font-size:clamp(36px,5vw,66px);line-height:1.08;font-weight:400;max-width:900px}h2{font-size:36px;font-weight:400}p{max-width:860px}a{color:#833c65}nav,.eyebrow,summary{font:14px/1.6 system-ui}nav{display:flex;gap:20px;flex-wrap:wrap}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#715d68}section{padding:50px 0;border-top:1px solid #bfb3b3;margin-top:45px}figure{margin:30px 0}img{width:100%;display:block;border-radius:3px}figcaption{font:14px/1.5 system-ui;margin-top:10px;color:#5b5360}details{padding:15px 0}details img{margin:20px 0}code{font-size:.85em;background:#ddd6d2;padding:.1em .25em}aside{background:#e1d9d8;padding:18px 26px;max-width:860px}</style>
<main><p class="eyebrow">4 October 2026 · installed in Endless Museum</p><h1>Primitives has room for exploration.</h1>
<p>The engine's forms, a family of columns, and borrowed letter outlines now have their own halls. The mesh library and seven-form choir have moved out of Ignorance; its older comparisons remain in the side alcove.</p>
<nav><a href="#Primitives_Godot">Godot forms</a><a href="#Primitives_Columns">Column court</a><a href="#Primitives_Profiles">Letter architecture</a><a href="/project-memory?scope=sequence%3Aprimitives&amp;outline=sequence%3Aprimitives&amp;detail=0">Sequence memory</a></nav>
<p><strong>Walk:</strong> Ignorance → Godot forms → Columns → Profiles → Portals → existing biome interlude → Melencolia.</p>
<aside><strong>Try the route in VR</strong><p>Use the existing Endless Museum launch. In its Inspector choose <code>start_chapter: primitives</code> and <code>start_map: Primitives_Godot</code>, or start at Ignorance to see the handoff. Continue through the museum's usual doorways. The local and shipped plan data include all three halls; this pass does not install a new Quest build.</p></aside>
'''+'\n'.join(sections)+'''
<section><h2>What was checked</h2><p>All three actual museum halls loaded and passed a player-body walk along their central routes, with floor checks at entry and exit. Four production portal transitions from Ignorance to Portals passed native checks. These are desktop engine checks; headset controls, comfort and the experience of the sequence remain for the VR walk.</p><p><a href="integration-verification.json">Placement preservation</a> · <a href="passages/report.json">63 passage checks</a> · <a href="colonnade-verification.json">Column geometry and clearance</a> · <a href="glyph-gallery-verification.json">Glyph geometry and clearance</a></p><p>The wider courts intentionally exceed the old 13–19-cell room-width guideline. Existing unrelated startup UID/material warnings remain in the native logs; the new rooms and passage checks passed.</p></section></main></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    print('Published three native museum views and refreshed Primitives metadata: 207 book halls.')

if __name__=='__main__':main()
