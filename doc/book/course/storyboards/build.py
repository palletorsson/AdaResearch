"""Build the review route from authored paragraphs and attributed museum images.

Run collect.py first. This writes a proposal, never a canonical hall tutorial.
"""
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter
import hashlib
import html
import json
import os
import re
import subprocess
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OUT=ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'images').mkdir(exist_ok=True)
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def link(p): return os.path.relpath(ROOT/p,OUT).replace('\\','/')
def write(p,data): p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
inv=read(HERE/'inventory.json')
authored=sum((read(HERE/f'{part}.json') for part in ('opening','early','growth','later')),[])
assert [s['sequence'] for s in authored]==[s['id'] for s in inv['sequences']]
by_map={h['id']:h for h in inv['halls']}
registry={}
for p in (ROOT/'commons/artifacts/registry').glob('*.json'):
    try:
        raw=read(p)
        entries=raw.get('artifacts',{})
        if not isinstance(entries,dict): continue
        for key,a in entries.items():
            if not isinstance(a,dict):continue
            scene=a.get('scene','')
            info={'id':key,'name':a.get('name',key),'registry':link(p.relative_to(ROOT)),
                  'scene':link(scene[6:]) if scene.startswith('res://') and (ROOT/scene[6:]).exists() else None}
            registry[key]=info
            registry[a.get('lookup_name',key)]=info
    except (ValueError,OSError,AttributeError):continue

halls=[]
image_manifest=[]
previous_images={p['file']:p for p in read(OUT/'image-sources.json')} if (OUT/'image-sources.json').exists() else {}
photo_gaps=read(HERE/'photo-gaps.json')
for s,wanted in zip(authored,inv['sequences']):
    assert [h['id'] for h in s['halls']]==wanted['maps'],s['sequence']
    for h in s['halls']:
        assert '\n' not in h['storyboard'] and h['storyboard'].strip(),h['id']
        assert '\n' not in h['storyboard_short'] and h['storyboard_short'].strip(),h['id']
        assert len(h['storyboard_short'].split()) < len(h['storyboard'].split()),h['id']
        assert h['mode'] in ('make','deepen','reflect')
        raw=by_map[h['id']]
        record=dict(h,sequence=s['sequence'],number=len(halls)+1,index=raw['index'],plan_present=raw['plan_present'])
        record['docs']={k:link(v) for k,v in raw['docs'].items()}
        record['map_source']=link(raw['map_source'])
        if h.get('storyboard_notes'): record['storyboard_notes']=link(h['storyboard_notes'])
        record['artifact_links']=[dict(registry[r],requested_id=r) if r in registry else {'id':r,'name':r} for r in h['artifact_refs']]
        seen=set()
        record['placed']=[]
        for a in raw['placed']:
            if a['id'] in seen:continue
            seen.add(a['id'])
            record['placed'].append(dict(registry.get(a['id'],{'id':a['id'],'name':a['id']}),cell=[a['x'],a['z']]))
        photos=[]
        # Explicitly selected alternatives have been visually reviewed in contact sheets.
        choices=read(HERE/'image-choices.json') if (HERE/'image-choices.json').exists() else {}
        candidates=raw['images']
        record['photo_note']=photo_gaps.get(h['id'],'')
        if record['photo_note']:candidates=[]
        if h['id'] in choices:
            selected=choices[h['id']]
            candidates=sorted(candidates,key=lambda p: selected.index(p['path']) if p['path'] in selected else 99)
        for i,pic in enumerate(candidates[:2]):
            source=ROOT/pic['path']
            name=f'{h["id"]}-{i+1}.webp'
            target=OUT/'images'/name
            digest=hashlib.sha256(source.read_bytes()).hexdigest()
            previous=previous_images.get('images/'+name,{})
            if not target.exists() or previous.get('sha256')!=digest:
                with Image.open(source) as im:
                    im.thumbnail((1440,960))
                    im.convert('RGB').save(target,'WEBP',quality=84,method=4)
            date=datetime.fromtimestamp(pic['mtime'],tz=timezone.utc).date().isoformat()
            entry={'src':'images/'+name,'original':link(pic['path']),'evidence':link(pic['evidence']),
                   'date':date,'label':source.stem.replace('-',' ').replace('_',' '),
                   'kind':'Museum capture for this route' if source.parent.name.endswith('_storyboard') else 'Prior museum capture'}
            photos.append(entry)
            image_manifest.append({'map':h['id'],'file':entry['src'],'original':pic['path'],'evidence':pic['evidence'],'date':date,'sha256':digest})
        record['images']=photos
        halls.append(record)
assert len(halls)==204 and len(set(h['id'] for h in halls))==204
seqs=[dict(id=s['sequence'],label=w['label'],order=w['order'],arc=s['arc'],maps=w['maps']) for s,w in zip(authored,inv['sequences'])]
data={'date':'2026-10-04','status':'Proposed — awaiting your correction','sequences':seqs,'halls':halls,
      'preparation':read(HERE/'preparation.json'),'plan_extras':inv['plan_extras'],
      'stats':{'sequences':len(seqs),'halls':len(halls),'pictured':sum(bool(h['images']) for h in halls),'modes':dict(Counter(h['mode'] for h in halls))},
      'links':{'manuscript':'storyboards.md','brief':link('doc/book/course/storyboards/BRIEF.md'),'handover':link('doc/book/course/HANDOVER.md'),'inventory':link('doc/book/course/storyboards/inventory.json')}}
write(OUT/'route.json',data)
write(OUT/'image-sources.json',image_manifest)
assert data['preparation']['storyboard_short'].strip()

overview=['# The whole route · 25 sequence arcs','',
    'Generated from the authored storyboard arcs in current spine order. All teaching arcs remain proposals. This is orientation, not proof that the curriculum works or that its dependencies have been reconciled.','',
    '[Local ↔ global working method](CONTEXT.md) · [Shared brief](BRIEF.md)','']
for s in seqs:
    overview += [f'## {s["order"]}. {s["label"]}',s['arc'],'',
        f'{len(s["maps"])} halls · `{s["maps"][0]}` → `{s["maps"][-1]}` · [Open sequence](../../iterations/2026-10-04-museum-tutorial-storyboards/index.html#hall={s["maps"][0]}&view=walk&summary=short)','']
overview_text='\n'.join(overview)
(HERE/'SEQUENCES.md').write_text(overview_text,encoding='utf-8')
(OUT/'sequences.md').write_text(overview_text.replace('(CONTEXT.md)', '('+link('doc/book/course/storyboards/CONTEXT.md')+')').replace('(BRIEF.md)', '('+link('doc/book/course/storyboards/BRIEF.md')+')').replace('(../../iterations/2026-10-04-museum-tutorial-storyboards/index.html#', '(index.html#'),encoding='utf-8')

brief=(HERE/'BRIEF.md').read_text(encoding='utf-8').replace('(../sketch/', '(sketch/')
for name in ('LINES-TRACE-GRID.md','CONTEXT.md','SEQUENCES.md'):
    brief=brief.replace('('+name+')','(storyboards/'+name+')')
lines=[brief,'## Day Zero',data['preparation']['storyboard'],'','**Short AI alternative**',data['preparation']['storyboard_short'],'',
       '## The proposed route','25 sequences · 204 halls. Each paragraph is a teaching proposal. Existing artifacts are the starting material; a proposed teaching interface or cross-hall transfer still needs implementation checks.','']
for s in authored:
    seq=next(x for x in seqs if x['id']==s['sequence'])
    lines += [f'## {seq["order"]}. {seq["label"]}',s['arc'],'']
    for h in s['halls']:
        lines += [f'### {h["id"]} — {h["title"]}',h['storyboard'],'','**Short AI alternative**',h['storyboard_short'],'']
        if h['review_note']:lines += [f'*For correction:* {h["review_note"]}','']
        if h.get('storyboard_notes'):lines += ['[Storyboard notes](storyboards/LINES-TRACE-GRID.md)','']
lines += ['## Source and route differences','',
          'The current spine JSON defines the reading order. The saved Endless Museum plan is compared separately; it is not automatically promoted into a curriculum. Lab_Path and LSystems_Shape_Grammars are in the spine but absent from that plan. Chamber_Color remains in the saved plan despite the author removing it from Colour. The other saved-plan extras are biome side encounters, not additional tutorial chapters.','',
          'Photographs show attributed museum views. Earlier photographs may predate changes. New standing-camera captures establish an image of a loaded hall, not a successful lesson, complete route traversal or physical-headset test.','',
          'The older subject register remains planning material. First teaching, supplied use and later return must be reconciled after the teaching choices are agreed. Source correctness does not certify teaching progression.','',
          'Next: correct these paragraphs, then write and verify one full tutorial at a time. Do not expand the full course automatically.','']
manuscript='\n'.join(lines)
(HERE.parent/'TUTORIAL_STORYBOARDS.md').write_text(manuscript,encoding='utf-8')
# This reading copy has links relative to the review output directory.
(OUT/'storyboards.md').write_text(manuscript.replace('(sketch/','('+link('doc/book/course/sketch')+'/').replace('(storyboards/', '('+link('doc/book/course/storyboards')+'/'),encoding='utf-8')

# A separate compact document avoids making a future AI read both versions.
compact=['# Ada · Tutorial storyboards · Short AI alternatives','',
    '4 October 2026. Day Zero + 204 halls, current spine order. Teaching proposals, not approved lessons.','',
    '## Shared brief','',
    'Summaries only. Do not change code logic, artifacts, maps, order, tutorial.md or final.md. Agree each teaching choice before drafting a full lesson. Imperatives below guide future writing; they do not authorize implementation.','',
    'Host: existing Endless Museum. Counter, rooms, player and artifacts already exist. Select useful operations; do not duplicate the world. Tutorial, reflection and wider museum material overlap without matching one-to-one. Reflective halls may reuse known tools without new syntax.','',
    'Use = encounter. Reuse = prior learning. Teach/Do = selected operation. Supply = named support, not a prerequisite already mastered. Carry = reusable result. Open = unresolved choice. Defer = later learning. Keep proposed adapters distinct from verified behavior.','',
    'Keep types and reference frames explicit. A value is not its mesh; a surface is not collision. Prefer code-created teaching geometry and direct references; no hidden scene lookups. Source conflicts become notes, not runtime edits. Read the full summary and review note when resolving a choice.','',
    '## Day Zero',data['preparation']['storyboard_short'],'']
for s in authored:
    seq=next(x for x in seqs if x['id']==s['sequence'])
    compact += [f'## {seq["order"]}. {seq["label"]}','']
    for h in s['halls']:
        compact += [f'### {h["id"]}',h['storyboard_short'],'']
compact_text='\n'.join(compact)
(HERE.parent/'TUTORIAL_STORYBOARDS_SHORT.md').write_text(compact_text,encoding='utf-8')
(OUT/'storyboards-short.md').write_text(compact_text,encoding='utf-8')

template=(HERE/'viewer.html').read_text(encoding='utf-8')
encoded=json.dumps(data,ensure_ascii=False).replace('<','\\u003c')
assert template.count('__ROUTE_DATA__')==1
(OUT/'index.html').write_text(template.replace('__ROUTE_DATA__',encoded),encoding='utf-8')
javascript=re.findall(r'<script>([\s\S]*?)</script>',template)[0]
syntax=subprocess.run(['node','--check'],input=javascript,text=True,encoding='utf-8',capture_output=True)
assert syntax.returncode==0,syntax.stderr

checks={'date':data['date'],'sequences':25,'halls':204,'day_zero':True,
        'one_paragraph_per_hall':True,'unique_exact_spine_order':True,
        'full_and_short_pairs':len(halls)+1,
        'short_alternatives_all_shorter':all(len(h['storyboard_short'].split())<len(h['storyboard'].split()) for h in [data['preparation'],*halls]),
        'with_images':data['stats']['pictured'],'missing_images':[h['id'] for h in halls if not h['images']],
        'photo_gaps':photo_gaps,
        'javascript_syntax_checked':True,'browser_interaction_tested':False,
        'map_sources_unchanged':all(v==hashlib.sha256((ROOT/k).read_bytes()).hexdigest() for k,v in inv['map_source_hashes'].items() if v),
        'missing_registry_refs':[{'map':h['id'],'id':r} for h in halls for r in h['artifact_refs'] if r not in registry],
        'scope':'Data, linked files and map-source hashes checked. Native images are observations. Pedagogy, transfer implementation, full journey and physical headset remain unverified.'}
for h in halls:
    for href in [h['map_source'],*h['docs'].values(),*[p['src'] for p in h['images']]]:
        assert (OUT/href).exists(),href
assert checks['map_sources_unchanged']
write(OUT/'checks.json',checks)
print(json.dumps(checks,indent=2))
