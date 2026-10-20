"""Render three proposed passages beside exact excerpts; leave map texts untouched."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
samples = json.loads((HERE / 'samples.json').read_text(encoding='utf-8'))
for folder in ['originals', 'excerpts', 'trials', 'images']:
    (HERE / folder).mkdir(exist_ok=True)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def words(text):
    return len(re.findall(r"\b\w+(?:['’-]\w+)*\b", text))

plans = read_json(ROOT / 'commons/data/museum/em_plan.json')['plans']
checks = []
sources = {}
css = '''
:root{color-scheme:light;--ink:#233331;--muted:#546762;--line:#cbd5cc;--accent:#306857;--paper:#fffcf5}
*{box-sizing:border-box}body{margin:0;color:var(--ink);background:#e8ede7;font-family:system-ui,sans-serif}
header{padding:16px 28px 14px;background:#f6f7f1;border-bottom:1px solid var(--line)}
.eyebrow{font-size:12px;letter-spacing:.12em;text-transform:uppercase;margin:0 0 4px;color:var(--muted)}
h1{font-size:clamp(22px,2.2vw,32px);font-weight:550;line-height:1.15;margin:0 0 8px}
.intro{font-size:14px;line-height:1.5;margin:0;max-width:110ch}nav{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0 0}
a{color:var(--accent);text-underline-offset:3px}nav a{padding:7px 12px;border:1px solid var(--line);border-radius:5px;text-decoration:none;font-size:14px;background:#fffdf8}
nav a[aria-current=page]{background:var(--accent);color:white;border-color:var(--accent)}
main{padding:16px 28px 28px;max-width:1800px;margin:auto}.sample-head{display:flex;justify-content:space-between;align-items:baseline;gap:20px;margin-bottom:12px}
h2{font-size:20px;font-weight:550;margin:0}.map{font-size:13px;color:var(--muted);margin:3px 0 0}
.columns{display:grid;grid-template-columns:1fr 1fr;gap:22px}.column{min-width:0}
.label{display:flex;justify-content:space-between;font-size:13px;letter-spacing:.02em;margin:0 0 7px;color:var(--muted)}
article{background:var(--paper);border:1px solid var(--line);border-top:4px solid #aab6ad;border-radius:4px;padding:24px clamp(22px,3vw,50px);height:calc(100dvh - 294px);min-height:360px;overflow:auto;scrollbar-gutter:stable;font:19px/1.64 Georgia,'Times New Roman',serif}
.trial article{border-top-color:var(--accent)}article p{margin:0 0 1.1em}article p:last-child{margin-bottom:0}article:focus{outline:2px solid var(--accent);outline-offset:2px}
article img{max-width:100%;max-height:200px;object-fit:contain}pre{font:13px/1.5 monospace;background:#edf0e9;padding:12px;white-space:pre-wrap;overflow-wrap:anywhere}
details{background:#f5f7f1;border:1px solid var(--line);border-radius:4px;margin-top:16px;padding:12px 17px;font-size:15px;line-height:1.6}
summary{cursor:pointer;font-weight:550}details p{max-width:105ch}details h3{font-size:16px;margin-bottom:0}.links{font-size:13px;margin-top:12px;display:flex;flex-wrap:wrap;gap:15px}
.reading{max-width:860px;background:var(--paper);padding:32px 45px;margin:24px auto;font:19px/1.65 Georgia,serif}.reading h1{font-family:system-ui}.reading h2{font-family:system-ui;margin-top:1.5em}.reading code{font-size:14px;overflow-wrap:anywhere}
@media(max-width:850px){header{padding:16px}main{padding:16px}.columns{grid-template-columns:1fr}.sample-head{display:block}article{height:auto;max-height:70vh;font-size:18px}.reading{padding:24px}.label{margin-top:6px}}
@media print{header nav,details,.links{display:none}.columns{display:block}article{height:auto;max-height:none;overflow:visible;border:0}.column{break-inside:avoid}.trial{break-before:page}body{background:white}}
'''

def render(text):
    return markdown.markdown(text, extensions=['tables', 'fenced_code', 'footnotes'])

def page(title, body, active=''):
    links = [('index.html','1 · Cloth'),('noise.html','2 · Noise'),('bridge.html','3 · Bridge'),('notes.html','Reading notes')]
    nav = ''.join('<a href="'+url+'"'+(' aria-current="page"' if url==active else '')+'>'+label+'</a>' for url,label in links)
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+css+'</style></head><body><header><p class="eyebrow">Ada Research · 15 October 2026 · proposed passages</p><h1>Voice studies across three maps</h1><p class="intro">Can the encounter carry more of the explanation? Compare a current passage with a new trial. Each column scrolls independently. Original chapters remain unchanged.</p><nav>'+nav+'</nav></header>'+body+'</body></html>'

for s in samples:
    name=s['map']; ident=s['id']; source=ROOT/'commons/maps'/name/'final.md'
    snapshot=HERE/'originals'/f'{name}.md'
    if not snapshot.exists(): shutil.copyfile(source,snapshot)
    text=snapshot.read_text(encoding='utf-8-sig')
    start=text.index(s['start']); end=text.index(s['end'],start)+len(s['end'])
    excerpt=text[start:end]
    (HERE/'excerpts'/f'{ident}.md').write_text(excerpt+'\n',encoding='utf-8')
    (HERE/'trials'/f'{ident}.md').write_text(s['trial']+'\n',encoding='utf-8')
    assert excerpt in text
    assert digest(source)==digest(snapshot), 'Current original changed; review before rebuilding.'
    source_paths=[f'commons/maps/{name}/final.md', f'commons/maps/{name}/map_data.json', f'commons/maps/sequences/{s["sequence"]}.json']+s['source_files']
    for p in source_paths: sources[p]=digest(ROOT/p)
    sequence=read_json(ROOT/f'commons/maps/sequences/{s["sequence"]}.json')
    sequence=sequence.get('sequences',sequence).get(s['sequence'],sequence)
    order=sequence['maps'];i=order.index(name)
    hall=next(p for p in plans if p.get('map')==name)
    placements=[a for a in hall['artifacts'] if a['token'] in [s['token'],'soft_workshop_console']]
    assert any(a['token']==s['token'] for a in placements)
    assert s['token'] in (ROOT/f'commons/maps/{name}/map_data.json').read_text(encoding='utf-8-sig')
    checks.append({'map':name,'previous':order[i-1] if i else None,'next':order[i+1] if i+1<len(order) else None,'museum_placements':placements,'claims_checked_by_source_inspection':s['claims'],'runtime_checked_this_trial':False})
    display=render(excerpt)
    # Preserve source Markdown; make the existing figure readable in this collection.
    for url in re.findall(r'<img[^>]+src="([^"]+)"',display):
        if url.startswith('/book-images/'):
            image_source=ROOT.parent/'ada_encyclopedia/public'/url.lstrip('/')
        else: image_source=source.parent/url
        assert image_source.is_file(), image_source
        dest=HERE/'images'/f'{ident}-{image_source.name}'
        shutil.copyfile(image_source,dest)
        display=display.replace('src="'+url+'"','src="images/'+dest.name+'"')
    original_words=words(re.sub(r'<!--.*?-->', '', excerpt,flags=re.S)); trial_words=words(s['trial'])
    columns='<div class="columns"><section class="column"><div class="label"><span>Current final · selected passage</span><span>'+str(original_words)+' words*</span></div><article tabindex="0" aria-label="Original passage">'+display+'</article></section><section class="column trial"><div class="label"><span>New trial · shared we</span><span>'+str(trial_words)+' words</span></div><article tabindex="0" aria-label="Proposed passage">'+render(s['trial'])+'</article></section></div>'
    notes='<details><summary>After reading · what this trial changes</summary><h3>Strategy</h3><p>'+html.escape(s['strategy'])+'</p><h3>Provisional editorial judgement</h3><p>'+html.escape(s['assessment'])+'</p><h3>What may be lost</h3><p>'+html.escape(s['risk'])+'</p><h3>Reading check</h3><p>'+html.escape(s['reading_check'])+'</p><p>Sources checked; no new visitor or runtime result. *Original count includes any displayed code and caption.</p></details>'
    links='<div class="links"><a href="originals/'+name+'.md">Complete original snapshot</a><a href="trials/'+ident+'.md">Trial text</a><a href="source-checks.json">Apparatus checks</a><a href="/long-museum/writing-wall?map='+name+'">Writing wall</a></div>'
    filename='index.html' if ident=='cloth' else ident+'.html'
    body='<main><div class="sample-head"><div><h2>'+html.escape(s['title'])+'</h2><p class="map">'+html.escape(name)+'</p></div></div>'+columns+notes+links+'</main>'
    (HERE/filename).write_text(page(s['title'],body,filename),encoding='utf-8')

(HERE/'notes.html').write_text(page('Reading notes','<main class="reading">'+render((HERE/'README.md').read_text(encoding='utf-8'))+'</main>','notes.html'),encoding='utf-8')
plan_path='commons/data/museum/em_plan.json'
sources[plan_path]=digest(ROOT/plan_path)
(HERE/'source-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
manifest={'date':'2026-10-15','status':'proposed_passages_for_comparison','canonical_adoption':False,'reader_responses':[],'runtime_checked':False,'source_sha256':sources,'originals_byte_exact':True,'comparisons':[{'map':s['map'],'trial_words':words(s['trial'])} for s in samples],'files':{str(p.relative_to(HERE)).replace('\\','/'):digest(p) for p in HERE.rglob('*') if p.is_file() and p.name not in ['manifest.json','preview.png']}}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'originals_unchanged':True,'samples':manifest['comparisons'],'placements_checked':len(checks)}))
