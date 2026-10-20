"""Publish current canonical Transformation readings and their fresh test receipts."""
from pathlib import Path
import difflib
import html
import json
import re
import sys
import zipfile
import markdown
from prepare import HERE, ROOT, HALLS, put, sha

sys.path.insert(0, str(ROOT / 'tools'))
import project_memory

CSS = '''
:root{color-scheme:light;--paper:#f5f2ec;--ink:#252624;--line:#c9c8bf;--accent:#854663}*{box-sizing:border-box}
body{margin:0;color:var(--ink);background:var(--paper);font:17px/1.65 system-ui,sans-serif}a{color:#753e5a;text-underline-offset:3px}
header{display:flex;gap:1.2rem;flex-wrap:wrap;align-items:center;border-bottom:1px solid var(--line);padding:1rem 3vw}header b{font-size:.78rem;letter-spacing:.12em;margin-right:auto}
main{max-width:1320px;margin:auto;padding:2rem 3vw 4rem}h1{font:500 clamp(2rem,4vw,3.3rem)/1.13 Georgia,serif}h2{font:500 1.8rem/1.2 Georgia,serif;margin-top:2.5rem}h3{font-size:1.18rem}p,li{max-width:900px}
.deck{max-width:850px;font-size:1.1rem}.muted,figcaption{font-size:.85rem;color:#565d58}.tags{display:flex;gap:.5rem;flex-wrap:wrap}.tags span{border:1px solid var(--line);padding:.35rem .7rem;font-size:.85rem;border-radius:4px}
article{border-top:1px solid var(--line);margin-top:2rem;padding-top:1rem}.links{display:flex;gap:1.1rem;flex-wrap:wrap;margin:1rem 0}.spread{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:3rem}.spread section{min-width:0}.spread section+section{border-left:1px solid var(--line);padding-left:2rem}
pre{font:13px/1.65 Consolas,monospace;background:#eae7df;padding:1rem;overflow:auto;tab-size:4;border-radius:5px}code{font-family:Consolas,monospace;overflow-wrap:anywhere;font-size:.9em}pre code{font-size:inherit;overflow-wrap:normal}
img{max-width:100%;height:auto}figure{margin:1rem 0;max-width:760px}figcaption{margin-top:.5rem}details{margin:1rem 0}summary{cursor:pointer}.label{font-size:.75rem;letter-spacing:.12em;text-transform:uppercase;color:#59605b}
.reading{max-width:850px}.reading article{break-before:page}.changes{max-height:38rem;overflow:auto;white-space:pre-wrap}.lesson-nav{display:flex;justify-content:space-between;gap:1rem;padding:1.2rem 0;border-top:1px solid var(--line);margin-top:2rem}
@media(max-width:1000px){.spread{display:block}.spread section+section{border-left:0;padding-left:0;border-top:1px solid var(--line);padding-top:1.5rem;margin-top:2rem}}
@media print{header,.lesson-nav,.links,.tags,details{display:none}body{font-size:10pt;background:white}main{padding:0}h1{font-size:23pt}pre{white-space:pre-wrap;font-size:8pt;overflow:visible}.spread{gap:1.5rem}.spread section+section{padding-left:1.5rem}.reading article:first-child{break-before:auto}}
'''

def render(text):
    # Canonical manuscripts keep their own URLs. The dated collection resolves them independently.
    text = text.replace('/book-images/', '/book-review/doc/book/')
    return markdown.markdown(text, extensions=['fenced_code','tables','footnotes'])

def page(title, body, depth=0):
    up='../' * depth
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / TRANSFORMATION</b><a href="{up}index.html">Sequence</a><a href="{up}all.html">All tutorials</a><a href="{up}final.html">All reflections</a><a href="{up}transformation-review.zip">Review ZIP</a></header><main>{body}</main></body></html>'''

def main():
    evidence=json.loads((HERE/'verification.json').read_text())
    assert evidence['passed'] and evidence['hall_count']==7
    for path,digest in evidence['inputs'].items():
        assert sha(ROOT/path)==digest, 'Test evidence drift: '+path
    for path,digest in json.loads((HERE/'preserved-before.json').read_text()).items():
        assert sha(ROOT/path)==digest, 'Preserved source drift: '+path
    lineage=json.loads((HERE/'lineage.json').read_text())
    model=project_memory.model(ROOT)
    scope={s['id']:s for s in model['scopes']}
    readings={'tutorial':[], 'final':[]}
    gallery=[]
    manifest={'date':'2026-10-12','source':'Canonical commons/maps/Trans_*/tutorial.md and unchanged current final.md',
              'verification':'verification.json','scope':'Fresh learner-program tests; archived museum images; no new headset or installed-hall test.', 'halls':[]}
    intro='''<h1>Transformation, now in the book</h1><p class="deck">Seven complete tutorials, carried forward from the reviewed drafts. The familiar cube moves, turns and changes size; by the exit those operations make a solid opening.</p><div class="tags"><span>7 canonical lessons</span><span>204 native assertions passed</span><span>19 exercise variants</span><span>12 deliberate faults rejected</span></div><p>12 October 2026. Tutorial on the left; the current reflection on the right. Each lesson creates its own small study in the prepared Endless Museum. Geometry and player setup already learned remain available; each new operation has a concrete spatial purpose.</p><p>The learner programs match the reviewed drafts exactly. Current reflections contain later additions and are preserved. Maps, museum code and Arrays chapters are unchanged. The last tutorial names the precise return to the collectible cube for the next sequence.</p><div class="links"><a href="Trans_Pre/parallel.html">Start reading →</a><a href="ALL_TUTORIALS.md">Tutorials as Markdown</a><a href="ALL_FINAL.md">Reflections as Markdown</a><a href="SUMMARIES.md">Seven short summaries</a><a href="verification.json">Fresh test evidence</a></div>'''
    for i,entry in enumerate(lineage):
        hall=entry['id']
        tutorial=(ROOT/'commons/maps'/hall/'tutorial.md').read_text(encoding='utf-8')
        final=(ROOT/'commons/maps'/hall/'final.md').read_text(encoding='utf-8')
        assert tutorial==(HERE/hall/'tutorial.md').read_text(encoding='utf-8')
        assert final==(HERE/hall/'final.md').read_text(encoding='utf-8')
        image=scope['map:'+hall].get('image')
        shot=''
        if image and (ROOT/image['path']).is_file():
            shot=f'<details><summary>Earlier view inside this hall</summary><figure><img loading="lazy" src="/book-review/{html.escape(image["path"])}" alt="{html.escape(image["label"])}"><figcaption>{html.escape(image["label"])} · recorded {html.escape(image["date"])}. Archived context, not a new capture or proof of this tutorial installation.</figcaption></figure></details>'
        previous=f'<a href="../{HALLS[i-1]}/parallel.html">← Previous hall</a>' if i else '<a href="../index.html">← Sequence overview</a>'
        following=f'<a href="../{HALLS[i+1]}/parallel.html">Next hall →</a>' if i<6 else '<a href="../index.html#arrays">What carries into Arrays →</a>'
        nav=f'<nav class="lesson-nav" aria-label="Hall navigation">{previous}<span>{i+1} / 7</span>{following}</nav>'
        diff=''.join(difflib.unified_diff((HERE/'before'/hall/'tutorial.md').read_text(encoding='utf-8-sig').splitlines(True),tutorial.splitlines(True),fromfile='Before/'+hall,tofile='Current/'+hall))
        put(HERE/hall/'tutorial.diff',diff)
        compare=f'<details><summary>What changed in tutorial.md</summary><p>{html.escape(entry["change_note"])}</p><pre class="changes">{html.escape(diff)}</pre></details>'
        body=f'<p class="label">{hall} · {i+1} / 7</p><p>{html.escape(entry["summary"])}</p>{shot}{nav}<div class="spread"><section><p class="label">Left page / tutorial</p>{render(tutorial)}</section><section><p class="label">Right page / reflection — current text preserved</p>{render(final)}</section></div>{compare}{nav}'
        put(HERE/hall/'parallel.html',page(entry['title'],body,1))
        gallery.append(f'<article id="{hall}"><p class="label">{i+1:02d} / {hall}</p><h2>{html.escape(entry["title"])}</h2><p>{html.escape(entry["summary"])}</p><p class="muted">Change: {html.escape(entry["change_note"])}</p><div class="links"><a href="{hall}/parallel.html">Tutorial + reflection</a><a href="{hall}/lesson.gd">Complete learner script</a><a href="{hall}/tutorial.diff">Before / after</a></div>{shot}</article>')
        for kind,text in [('tutorial',tutorial),('final',final)]:readings[kind].append((hall,text))
        manifest['halls'].append({'map':hall,'tutorial_sha256':sha(ROOT/'commons/maps'/hall/'tutorial.md'),
            'final_sha256':sha(ROOT/'commons/maps'/hall/'final.md'),'image':image,'code_sha256':sha(HERE/hall/'lesson.gd')})
    ending='''<article id="arrays"><h2>What carries into Arrays</h2><p>Return to Trans_Pre's still collectible cube. Create independent copies, give each an address, and retain those addresses when one cube is collected. Carry BoxMesh, local placement, loops and overlap detection. The composed door stays as a finished study; its moving solid leaves are not a new prerequisite for every copy.</p><p><a href="../2026-10-06-array-a-slot-kept/parallel.html">Existing first-Array draft</a> — for the next sequence pass. No Arrays source was changed here.</p></article><article><h2>Evidence and remaining review</h2><p>Fresh Godot 4.6 checks execute the exact canonical printed programs and 19 source variations. Assertions include real physics overlap, a capsule stopped by the closed door and passing through the open one, and matching collision while leaves shrink. Twelve behavioural faults fail their intended assertions; parser errors do not count as detection.</p><p>These are author-informed synthetic tests, not an independent student reconstruction, a physical headset trial or a whole-museum rider-system test. Archived photographs locate encounters; they do not depict a new installation. The current reflections remain available for their own editorial and factual review.</p></article>'''
    put(HERE/'index.html',page('Transformation, now in the book',intro+''.join(gallery)+ending))
    for kind,filename,title in [('tutorial','all.html','Transformation — all seven tutorials'),('final','final.html','Transformation — current reflections')]:
        label='Complete canonical learner texts, with declared museum support.' if kind=='tutorial' else 'Current final.md texts preserved from the start of this pass; not replaced by the older paired drafts.'
        md=f'# {title}\n\n12 October 2026. {label}\n\n'
        body=f'<div class="reading"><h1>{title}</h1><p>{label}</p>'
        for hall,text in readings[kind]:
            md+=f'\n---\n\n<!-- hall:{hall} -->\n\n'+text+'\n'
            body+=f'<article id="{hall}"><p class="label">{hall}</p>{render(text)}</article>'
        put(HERE/('ALL_TUTORIALS.md' if kind=='tutorial' else 'ALL_FINAL.md'),md)
        put(HERE/filename,page(title,body+'</div>'))
    summary='# Transformation — seven lessons in sequence\n\n12 October 2026. Current canonical tutorials; existing museum host. Full code and fresh evidence accompany this reading.\n\n'
    for entry in lineage:
        summary+=f'## {entry["id"]} — {entry["title"]}\n\n{entry["summary"]}\n\n**Short AI:** {entry["short"]}\n\n'
    summary+='## Into Arrays\n\nReturn to Trans_Pre’s still BoxMesh pickups; assign addresses and retain presence after collection. Arrays remains the next sequence to reconcile.\n'
    put(HERE/'SUMMARIES.md',summary)
    put(HERE/'manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    with zipfile.ZipFile(HERE/'transformation-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for name in ['ALL_TUTORIALS.md','ALL_FINAL.md','SUMMARIES.md','lineage.json','manifest.json','promotion.json','verification.json','normal-report.json','run_checks.py','verify.gd','prepare.py']:
            z.write(HERE/name,name)
        for hall in HALLS:
            for name in ['tutorial.md','final.md','lesson.gd','tutorial.diff']:z.write(HERE/hall/name,hall+'/'+name)
    print('Published seven facing-page readings, complete manuscripts, summaries, diffs and review ZIP.')

if __name__=='__main__':main()
