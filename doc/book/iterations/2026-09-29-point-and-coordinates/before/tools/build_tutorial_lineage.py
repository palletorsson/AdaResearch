"""Build the source-aware tutorial lineage atlas. Does not edit halls or manuscript."""
from pathlib import Path
from datetime import datetime, timezone
import copy, hashlib, html, json, re, shutil
from urllib.parse import quote
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'doc/book/tutorial-lineage'
OUT=ROOT/'doc/book/iterations/2026-09-29-tutorial-lineage'
read=lambda p:p.read_text(encoding='utf-8-sig')
write=lambda p,t:p.write_bytes(t.encode('utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
OUT.mkdir(parents=True,exist_ok=True)
config=json.loads(read(SOURCE/'curriculum.json'))
spine_path=ROOT/'commons/maps/curriculum_spine.json'
spine=json.loads(read(spine_path))
seqs=sorted(spine['spine']['sequences'],key=lambda s:s['order'])
sources={}
def record(p):
    sources[p.relative_to(ROOT).as_posix()]=sha(p)
record(spine_path);record(SOURCE/'curriculum.json')
record(Path(__file__))
for name in ['README.md','atlas.html']:
    record(SOURCE/name)
LABELS={'array_tutorial': 'Arrays', 'color': 'Colour', 'formfinding': 'Form Finding', 'wavefunctions': 'Wave Functions', 'cellularautomata': 'Cellular Automata', 'lsystems': 'L-Systems', 'proceduralgeneration': 'Procedural Generation', 'softbodies': 'Soft Bodies', 'boolean_surfaces': 'Boolean Surfaces', 'swarmintelligence': 'Swarm Intelligence', 'machinelearning': 'Machine Learning', 'graphtheory': 'Graph Theory', 'foundationscrisis': 'Foundations Crisis', 'qfeplaboratory': 'QFEP Laboratory', 'postfoundationscrisis': 'After the Crisis'}
sequences=[];halls=[];seen=set();byseq={}
source_style='body{max-width:920px;margin:48px auto;padding:0 24px;background:#f6f3ec;color:#252d2a;font:16px/1.6 system-ui}a{color:#28594b}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#fffdf8;border:1px solid #d7d9cd;padding:22px;font:14px/1.7 ui-monospace,Consolas,monospace}h1{font:42px/1.1 Georgia}h2{margin-top:42px}nav{display:flex;flex-wrap:wrap;gap:15px}section{scroll-margin-top:20px}'
for s in seqs:
    path=ROOT/'commons/maps/sequences'/(s['name']+'.json');record(path)
    raw=json.loads(read(path))['sequences'][s['name']]
    names=raw['maps'];byseq[s['name']]=names
    sequences.append(dict(id=s['name'],order=s['order'],label=LABELS.get(s['name'],s['name'].replace('_',' ').title()),maps=names,question=config['sequence_questions'][s['name']]))
    for index,m in enumerate(names):
        assert m not in seen,'Duplicate active hall '+m
        seen.add(m)
        folder=ROOT/'commons/maps'/m
        docs={};sections=[]
        for kind in ['final','tutorial','technical','intent','critical','artifacts','summary','blurb']:
            p=folder/(kind+'.md')
            if not p.exists(): continue
            record(p);text=read(p)
            dest=OUT/'sources'/m/(kind+'.md');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
            # Facts about the file, never an automatic verdict on lesson quality.
            body=re.sub(r'```[\s\S]*?```','',text)
            body=re.sub(r'<!--.*?-->','',body,flags=re.S)
            body=re.sub(r'^#.*$','',body,flags=re.M)
            docs[kind]=dict(path=p.relative_to(ROOT).as_posix(),url='sources/'+m+'.html#'+kind,raw='sources/'+m+'/'+kind+'.md',words=len(text.split()),code_blocks=len(re.findall(r'^```',text,re.M))//2,headings=re.findall(r'^#{1,4} (.+)',text,re.M)[:12],opening=' '.join(body.split())[:850],sha256=sha(p))
            sections.append('<section id="'+kind+'"><h2>'+kind+'.md</h2><p><a href="'+m+'/'+kind+'.md">Raw captured source</a></p><pre>'+html.escape(text)+'</pre></section>')
        mapfile=folder/'map_data.json';mapurl=None
        if mapfile.exists():
            record(mapfile);dest=OUT/'sources'/m/'map_data.json';shutil.copy2(mapfile,dest);mapurl='sources/'+m+'/map_data.json'
        status='source-present' if 'tutorial' in docs and docs['tutorial']['words'] else 'no-tutorial'
        h=dict(id=m,sequence=s['name'],sequence_order=s['order'],index=index+1,docs=docs,status=status,map_source=mapurl,encounter_url='/long-museum/encounters?map='+quote(m),reading_url='/compose/sources?map='+quote(m)+'&doc=final',review_scope='Inventory only; source presence does not certify a runnable lesson.')
        halls.append(h)
        nav=''.join('<a href="#'+k+'">'+k+'</a>' for k in docs)
        page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(m)+' · Lineage sources</title><style>'+source_style+'</style><body><p><a href="/tutorial-lineage#hall='+m+'">← Tutorial lineage</a></p><h1>'+html.escape(m.replace('_',' '))+'</h1><p>Captured current source, 29 September 2026. These documents may describe different iterations. This page does not certify their claims.</p><nav>'+nav+'</nav>'+''.join(sections)+'</body></html>'
        write(OUT/'sources'/(m+'.html'),page)
nodes=copy.deepcopy(config['nodes']);ids={n['id'] for n in nodes};assert len(ids)==len(nodes)
hallids={h['id'] for h in halls};coverage={m:[] for m in hallids}
for n in nodes:
    assert all(x in ids for x in n['requires']),n['id']
    if n['sequence']=='preparation':assert n['halls']==[]
    else:
        names=byseq[n['sequence']]
        assert n['halls'] and all(m in names for m in n['halls']),n['id']
        n['halls']=sorted(n['halls'],key=names.index)
        for m in n['halls']:coverage[m].append(n['id'])
    n['parent']=n['requires'][0] if n['requires'] else None
    n['used_by']=[x['id'] for x in nodes if n['id'] in x['requires']]
assert all(coverage.values()),[m for m,c in coverage.items() if not c]
lookup={n['id']:n for n in nodes}
def ancestors(key,trail=()):
    assert key not in trail,('Cycle',trail,key)
    result=set()
    for p in lookup[key]['requires']:
        result.add(p);result.update(ancestors(p,trail+(key,)))
    return result
for n in nodes:
    n['ancestors']=sorted(ancestors(n['id']))
    n['depth']=0
    p=n['parent']
    while p:n['depth']+=1;p=lookup[p]['parent']
for h in halls:h['capabilities']=coverage[h['id']]
issues=copy.deepcopy(config['issues'])
for item in issues:
    assert all(x in ids for x in item['nodes'])
    links=[]
    for rel in item['evidence']:
        p=ROOT/rel;assert p.is_file(),rel;record(p)
        dest=OUT/'evidence'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        links.append(dict(path=rel,url='evidence/'+rel))
    item['sources']=links
missing=[h['id'] for h in halls if h['status']=='no-tutorial']
issues.append(dict(id='missing-tutorials',title='Encounters without a tutorial file',nodes=sorted({c for m in missing for c in coverage[m]}),severity='inventory',finding=str(len(missing))+' active halls have no non-empty tutorial.md. They may have strong manuscripts, artifacts or technical notes.',action='Decide whether each hall needs a making lesson, an explicit borrowed component or a deliberate reflective role. Do not generate filler to fill the column.',halls=missing,sources=[]))
active=set(byseq);extensions=[]
for p in sorted((ROOT/'commons/maps/sequences').glob('*.json')):
    try:entries=json.loads(read(p)).get('sequences',{})
    except (ValueError,AttributeError):continue
    if not isinstance(entries,dict):continue
    for name,value in entries.items():
        if name not in active and isinstance(value,dict) and isinstance(value.get('maps'),list):
            extensions.append(dict(id=name,hall_count=len(value['maps']),status='Outside active spine; lineage not mapped in this edition.'))
# Known portable starting material is reported as evidence, not general certification.
studies=[]
for name in ['day-zero','point-zero','point-one']:
    folder=ROOT/'doc/book/studies'/name
    studies.append(dict(id=name,files=[p.name for p in folder.iterdir() if p.is_file()]))
    for p in folder.iterdir():
        if p.is_file():record(p)
proposals=[]
for n in nodes:
    if n['sequence']=='preparation':continue
    order=next(s['order'] for s in sequences if s['id']==n['sequence'])
    for req in n['requires']:
        p=lookup[req]
        if p['sequence']=='preparation':continue
        parentorder=next(s['order'] for s in sequences if s['id']==p['sequence'])
        if parentorder>order:proposals.append(dict(node=n['id'],requires=req))
assert not proposals,proposals
state=dict(title=config['title'],generated_at=datetime.now(timezone.utc).isoformat(),scope=config['scope'],nodes=nodes,sequences=sequences,halls=halls,issues=issues,extensions=extensions,studies=studies,counts=dict(capabilities=len(nodes),sequences=len(sequences),halls=len(halls),missing_tutorials=len(missing),additional_requirements=sum(max(0,len(n['requires'])-1) for n in nodes)),sources_sha256=sources)
plan=['# What the student can carry','',config['scope'],'','Proposed learning targets, not an assertion that every lesson is delivered. The active walking order is preserved. Each dependency must be taught earlier or supplied explicitly.','']
for seq in [dict(id='preparation',label='Preparation')]+sequences:
    plan+=['## '+seq['label'],'',seq.get('question','Establish a working place and a prepared receiver.'),'']
    for n in nodes:
        if n['sequence']!=seq['id']:continue
        plan+=['### '+n['label']+' ('+n['kind']+')','','Requires: '+(', '.join(lookup[i]['label'] for i in n['requires']) or 'The supplied starting project')+'.','',n['learn'],'','Leave able to make: '+n['make'],'','Try elsewhere: '+n['transfer'],'','Supplied: '+n['borrow'],'','Halls: '+(', '.join(n['halls']) or 'Before the spine')+'.','']
plan+=['## Handover notes','']
for issue in issues:plan+=['### '+issue['title'],'',issue['finding'],'',issue['action'],'']
write(OUT/'lineage.md',chr(10).join(plan))
encoded=json.dumps(state,ensure_ascii=False,indent=2)
write(OUT/'lineage.json',encoded+'\n')
shutil.copy2(SOURCE/'curriculum.json',OUT/'curriculum.json')
shutil.copy2(SOURCE/'README.md',OUT/'README.md')
template=read(SOURCE/'atlas.html')
assert template.count('/*ATLAS_DATA*/')==1
write(OUT/'index.html',template.replace('/*ATLAS_DATA*/',encoded.replace('</','<\/')))
report=dict(passed=True,coverage=state['counts'],requires_acyclic=True,all_active_halls_mapped=True,requires_from_prior_or_current_sequences=True,known_issues=len(issues),source_count=len(sources),scope='Structural and source inventory validation. No whole-project runtime or learner acceptance claims.')
write(OUT/'verification.json',json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
