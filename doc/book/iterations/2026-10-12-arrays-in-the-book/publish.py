"""Incorporate five source-checked manuscripts and publish paired reading pages."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
import copy
import difflib
import hashlib
import html
import json
import re
import shutil
import sys
import zipfile
import markdown
from prepare_texts import HERE, ROOT, HALLS

sys.path.insert(0,str(ROOT/'tools'))
import project_memory

def put(p,t):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(t,encoding='utf-8')

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None

CSS='''
:root{color-scheme:light;--paper:#f4f1e9;--ink:#242824;--accent:#703c57;--line:#ccc9c0}*{box-sizing:border-box}body{background:var(--paper);color:var(--ink);margin:0;font:17px/1.65 system-ui,sans-serif}a{color:var(--accent);text-underline-offset:3px}header{padding:1rem 3vw;border-bottom:1px solid var(--line);display:flex;gap:1.3rem;flex-wrap:wrap}header b{margin-right:auto;letter-spacing:.12em;font-size:.8rem}main{max-width:1380px;margin:auto;padding:2rem 3vw 4rem}h1{font:500 clamp(2rem,4vw,3.5rem)/1.15 Georgia,serif}h2{font:500 1.8rem/1.3 Georgia,serif;margin-top:2rem}h3{font-size:1.1rem}p,li{max-width:880px}.deck{font-size:1.15rem;max-width:860px}.route{padding:1rem;border-top:1px solid var(--line);border-bottom:1px solid var(--line);font-size:1.05rem}.muted,figcaption{color:#58605b;font-size:.85rem}.label{font-size:.78rem;letter-spacing:.13em;text-transform:uppercase}.links,.nav{display:flex;flex-wrap:wrap;gap:1.2rem;margin:1rem 0}.nav{justify-content:space-between;border-top:1px solid var(--line);padding-top:1rem}article{border-top:1px solid var(--line);margin-top:2rem;padding-top:1rem}figure{margin:1rem 0;max-width:820px}img{width:100%;height:auto}figcaption{margin-top:.4rem}.spread{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:3rem}.spread section{min-width:0}.spread section+section{border-left:1px solid var(--line);padding-left:2rem}pre{font:13px/1.6 Consolas,monospace;overflow:auto;background:#e9e6dc;border-radius:4px;padding:1rem;tab-size:4}code{font-family:Consolas,monospace;font-size:.9em;overflow-wrap:anywhere}pre code{font-size:inherit;overflow-wrap:normal}details{margin:1rem 0}summary{cursor:pointer}.changes{max-height:35rem;white-space:pre-wrap}.reading{max-width:850px}.reading article{break-before:page}table{border-collapse:collapse;max-width:100%}th,td{padding:.6rem;text-align:left;border-bottom:1px solid var(--line)}
@media(max-width:1000px){.spread{display:block}.spread section+section{border:0;border-top:1px solid var(--line);padding:1rem 0 0;margin-top:2rem}}@media print{header,details,.links,.nav{display:none}body{background:white;font-size:10pt}main{padding:0}pre{white-space:pre-wrap;font-size:8pt}.reading article:first-child{break-before:auto}}
'''

def render(text):
    text=text.replace('/book-images/','/book-review/doc/book/')
    return markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])

def page(title,body,depth=0):
    prefix='../'*depth
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / ARRAYS</b><a href="{prefix}index.html">Sequence</a><a href="{prefix}all.html">Tutorials</a><a href="{prefix}final.html">Reflections</a><a href="{prefix}arrays-review.zip">Review ZIP</a></header><main>{body}</main></body></html>'

def main():
    evidence=json.loads((HERE/'verification.json').read_text())
    assert evidence['passed']
    for path,digest in evidence['inputs'].items(): assert sha(ROOT/path)==digest,path
    before=json.loads((HERE/'before-sources.json').read_text())
    targets=[f'commons/maps/{h}/tutorial.md' for h in HALLS]
    promotion=HERE/'promotion.json'
    if not promotion.exists():
        for path,digest in before.items(): assert sha(ROOT/path)==digest,'Concurrent edit: '+path
        for hall in HALLS: shutil.copyfile(HERE/hall/'tutorial.md',ROOT/'commons/maps'/hall/'tutorial.md')
        put(promotion,json.dumps({'date':'2026-10-12','authorization':'Continue with Arrays after Transformation, one sequence at a time. Existing Array draft incorporated; other four outlines expanded.','tutorials':{p:{'before':before[p],'after':sha(ROOT/p)} for p in targets},'printed_code':'Array unchanged from reviewed draft; six new printed files in the other four lessons.','runtime_changed':False,'final_changed':False},indent=2)+'\n')
    for hall in HALLS:
        assert (HERE/hall/'tutorial.md').read_bytes()==(ROOT/'commons/maps'/hall/'tutorial.md').read_bytes()
        shutil.copyfile(ROOT/'commons/maps'/hall/'final.md',HERE/hall/'final.md')
    protected={p:d for p,d in before.items() if p not in targets and not p.startswith('doc/book/course/execution-plan/')}
    for path,digest in protected.items(): assert sha(ROOT/path)==digest,path
    put(HERE/'preserved.json',json.dumps(protected,indent=2)+'\n')
    lineage=json.loads((HERE/'lineage.json').read_text())
    scopes={s['id']:s for s in project_memory.model(ROOT)['scopes']}
    total=evidence['assertions']; faults=evidence['faults_rejected']
    intro=f'''<h1>Arrays: an address, then a reader</h1><p class="deck">The cube from Transformation becomes many independently addressed bodies. An address then chooses a turn, a saved image receives another surface, and a clock returns to a score.</p><p class="route">Collectible cube → row and plane → volume → rule underfoot → image on a wall → score in time</p><p>12 October 2026 · Five canonical tutorials, seven complete printed files. {total} fresh native assertions; {faults} deliberate faults detected; 22 configurations including baselines and exercises. Current reflections are preserved.</p><div class="links"><a href="Array/parallel.html">Start paired reading →</a><a href="ALL_TUTORIALS.md">Whole tutorial file</a><a href="ALL_FINAL.md">Whole reflective file</a><a href="SUMMARIES.md">Five short summaries</a><a href="verification.json">Test evidence</a></div><p>The first lesson incorporates the existing reviewed draft. The four following outlines now have complete programs. Each study belongs in the prepared Endless Museum; existing flight, room support and larger encounters remain declared. These pages do not install the study nodes into the live museum.</p>'''
    body=intro
    readings={'tutorial':[],'final':[]}
    manifest={'date':'2026-10-12','halls':[]}
    summary='# Arrays — five lesson summaries\n\n12 October 2026. Current canonical tutorials; revisable teaching decisions.\n\n'
    for i,item in enumerate(lineage):
        hall=item['id']; text=(HERE/hall/'tutorial.md').read_text(encoding='utf-8'); final=(HERE/hall/'final.md').read_text(encoding='utf-8')
        image=scopes['map:'+hall].get('image')
        if hall=='Tutorial_Tiling_Floor': image={'path':'doc/book/iterations/2026-09-28-tiling-rule-study/floor-rule-after.png','label':'Earlier view at the four-by-four rule desk','date':'2026-09-28'}
        photo=''
        if image and (ROOT/image['path']).is_file():
            photo=f'<figure><img loading="lazy" src="/book-review/{image["path"]}" alt="{html.escape(image["label"])}"><figcaption>{html.escape(image["label"])} · {image["date"]}. Archived museum image; not a new capture of the learner program.</figcaption></figure>'
        oldpath=HERE/'before/commons/maps'/hall/'tutorial.md'
        old=oldpath.read_text(encoding='utf-8-sig') if oldpath.exists() else ''
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile='Before/'+hall,tofile='Current/'+hall))
        put(HERE/hall/'tutorial.diff',diff)
        previous=f'<a href="../{HALLS[i-1]}/parallel.html">← Previous hall</a>' if i else '<a href="../index.html">← Overview</a>'
        following=f'<a href="../{HALLS[i+1]}/parallel.html">Next hall →</a>' if i<4 else '<a href="../index.html#colour">What carries into Colour →</a>'
        nav=f'<nav class="nav">{previous}<span>{i+1} / 5</span>{following}</nav>'
        paired=f'<p class="label">{hall}</p><p>{html.escape(item["summary"])}</p><details><summary>Inside this hall — earlier museum image</summary>{photo}</details>{nav}<div class="spread"><section><p class="label">Left page / tutorial</p>{render(text)}</section><section><p class="label">Right page / current reflection</p>{render(final)}</section></div><details><summary>Before / after tutorial text</summary><pre class="changes">{html.escape(diff)}</pre></details>{nav}'
        put(HERE/hall/'parallel.html',page(item['title'],paired,1))
        body+=f'<article id="{hall}"><p class="label">{i+1:02d} / {hall}</p><h2>{html.escape(item["title"])}</h2><p>{html.escape(item["summary"])}</p><p class="muted">Changed: {html.escape(item["change_note"])}</p><div class="links"><a href="{hall}/parallel.html">Tutorial + reflection</a><a href="{hall}/tutorial.diff">Exact changes</a><a href="{hall}/lesson.gd">Learner script</a></div><details><summary>Earlier view inside the museum</summary>{photo}</details></article>'
        summary+=f'## {hall} — {item["title"]}\n\n{item["summary"]}\n\n**Short AI:** {item["short"]}\n\n**Carry:** {item["carry"]}\n\n**Next:** {item["next"]}\n\n'
        for k,t in [('tutorial',text),('final',final)]: readings[k].append((hall,t))
        manifest['halls'].append({'id':hall,'tutorial_sha256':sha(ROOT/f'commons/maps/{hall}/tutorial.md'),'final_sha256':sha(ROOT/f'commons/maps/{hall}/final.md'),'image':image})
    body+='''<article id="colour"><h2>What carries into Colour</h2><p>The learner can now make independent instances, retain addresses, distinguish values from references, choose a result with a function and read a record through time. Colour can use those capacities with the familiar geometry. A material value can vary at one address while the arrangement remains available for comparison.</p><p>The next subject is what colour does through material, light and neighbours. It need not introduce another array framework. Colour texts are unchanged in this pass.</p></article><article><h2>What the tests establish</h2><p>The exact printed programs run. Tests include synthetic player overlaps, XYZ/YZX conversion, source-record retention, local exceptions, a PNG saved by Floor and loaded by Walls in a separate engine process, real collision under a turned panel, clock independence and declared stalled-frame behaviour. Faults must fail behavioural assertions; syntax errors do not count.</p><p>These are teacher-authored tests. They do not establish independent student understanding, physical headset usability, sound quality, or installation in the live halls. Dated museum photographs give context. The current reflections and runtime have been preserved.</p><p>The four new lessons remain open to editorial review, especially the pace of the 3D conversion and the two readings in Disco. Walls is deliberately a quieter reuse chapter.</p></article>'''
    put(HERE/'index.html',page('Arrays in the book',body))
    put(HERE/'SUMMARIES.md',summary)
    put(HERE/'manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    for kind,title,file in [('tutorial','Arrays — complete tutorials','all.html'),('final','Arrays — current reflections','final.html')]:
        collected='# '+title+'\n\n12 October 2026.\n'
        content=f'<div class="reading"><h1>{title}</h1>'
        for hall,text in readings[kind]:
            collected+='\n---\n\n<!-- hall:'+hall+' -->\n\n'+text+'\n'
            content+=f'<article id="{hall}"><p class="label">{hall}</p>{render(text)}</article>'
        put(HERE/('ALL_TUTORIALS.md' if kind=='tutorial' else 'ALL_FINAL.md'),collected)
        put(HERE/file,page(title,content+'</div>'))
    with zipfile.ZipFile(HERE/'arrays-review.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for hall in HALLS:
            for file in (HERE/hall).glob('*'):
                if file.suffix in ['.md','.gd','.diff']: archive.write(file,file.relative_to(HERE))
        for filename in ['README.md','ALL_TUTORIALS.md','ALL_FINAL.md','SUMMARIES.md','verification.json','manifest.json','verify.gd','run_checks.py','prepare_texts.py','Array/verification.json','Array/run_checks.py','Array/build.py']:
            archive.write(HERE/filename,filename)
    print('Published five canonical tutorials, paired pages, whole readings, summaries and review ZIP.')

if __name__=='__main__':main()
