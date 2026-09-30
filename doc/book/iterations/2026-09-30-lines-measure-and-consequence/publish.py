from pathlib import Path
import json, hashlib, shutil, difflib, html, zipfile, re, os
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
MAP=ROOT/'commons/maps/Point_Lines'
run=ROOT/'ada_run/encounter_pilot/Point_Lines'
report=json.loads((run/'report.json').read_text(encoding='utf-8'))
lesson=ROOT/'doc/book/studies/point-lines'
lesson_report=json.loads((lesson/'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and lesson_report['passed']
before=json.loads((OUT/'before/commons/maps/Point_Lines/map_data.json').read_text(encoding='utf-8'))
after=json.loads((MAP/'map_data.json').read_text(encoding='utf-8'))
assert before['layers']['structure']==after['layers']['structure']
assert before['layers']['utilities']==after['layers']['utilities']
changed=[]
for z,(old,new) in enumerate(zip(before['layers']['interactables'],after['layers']['interactables'])):
    for x,(a,b) in enumerate(zip(old,new)):
        if a!=b:changed.append([x,z])
assert changed==[[12,z] for z in range(29,35)],changed

def atomic(path,text):
    t=path.with_name(path.name+'.ada-tmp');t.write_text(text,encoding='utf-8');os.replace(t,path)
def backup(path):
    dest=OUT/'before'/path.relative_to(ROOT)
    if not dest.exists():
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)

p=ROOT/'commons/data/museum_core_encounters.json';backup(p)
data=json.loads(p.read_text(encoding='utf-8'))
data['rooms']['Point_Lines'].update(primary_tokens=['line_black_box','line_demo','do_not_cross_barrier','redline','walk_this_line_marking','player_trace','line_relations_gallery','laser_measure','anamorphic_cross','health_cross'],reason='Measure in the black box; connect for passage; walk and compare a trace; rearrange bodies of lines; measure and break; cross alternating harm and recovery.',text_sha256=hashlib.sha256((MAP/'final.md').read_bytes()).hexdigest(),map_sha256=hashlib.sha256((MAP/'map_data.json').read_bytes()).hexdigest(),local_review=OUT.relative_to(ROOT).as_posix()+'/index.html',learner_verified=False)
atomic(p,json.dumps(data,ensure_ascii=False,indent=2)+'\n')
p=ROOT/'doc/book/tutorial-lineage/curriculum.json';backup(p)
data=json.loads(p.read_text(encoding='utf-8'))
for node in data['nodes']:
    if node['id']=='line':node['status']='desktop-tested';node['borrow']='Prepared A/B markers, segment.gd cylinder renderer and readout. XR hold remains supplied by the museum.'
for issue in data['issues']:
    if issue['id']=='line-grid':
        issue.update(severity='resolved',finding='Replaced the grid-first lesson with two known positions, subtraction, length and a supplied renderer. A standalone Godot project passed 22 geometry/readout checks.',action='Keep the portable study aligned with tutorial.md. A self-contained XR starter remains a separate Coordinates task.',evidence=['commons/maps/Point_Lines/tutorial.md','doc/book/studies/point-lines/verification.json'])
atomic(p,json.dumps(data,ensure_ascii=False,indent=2)+'\n')
p=MAP/'critical.md';backup(p)
s=p.read_text(encoding='utf-8').replace('Point_Line showed a single measured relation: two points, one distance.','The current Point_Lines hall begins with a single measured relation in the black box: two points, one distance.')
atomic(p,s)

sources=[p.relative_to(ROOT).as_posix() for p in (OUT/'before').rglob('*') if p.is_file()]
sources=[s.split('/before/',1)[1] for s in sources]
sources+=['commons/artifacts/health_cross/recovery_feedback.gd']
versions={}
diffs={}
for rel in sources:
    p=ROOT/rel
    target=OUT/'sources'/rel
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
    versions[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
    baseline=OUT/'before'/rel
    if baseline.exists():
        diffs[rel]=''.join(difflib.unified_diff(baseline.read_text(encoding='utf-8-sig').splitlines(True),p.read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
        (OUT/(p.name+'.diff')).write_text(diffs[rel],encoding='utf-8')
for name in ['report.json','source_manifest.json']:
    shutil.copy2(run/name,OUT/name)
shutil.copy2(lesson/'verification.json',OUT/'lesson-verification.json')
for name in ['entrance-line','black-box-passage','line-length-changed','barrier-before','barrier-broken','rod-broken','line-room','corridor']:
    shutil.copy2(run/(name+'.png'),OUT/(name+'.png'))
with zipfile.ZipFile(OUT/'point-lines-study.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in lesson.iterdir():
        if p.suffix in ['.gd','.tscn','.godot','.md']:
            z.write(p,'point-lines/'+p.name)
(OUT/'source-versions.json').write_text(json.dumps(versions,indent=2)+'\n',encoding='utf-8')

def md(path):
    content=markdown.markdown(path.read_text(encoding='utf-8'),extensions=['fenced_code','footnotes','tables'])
    def link(match):
        href=match[1]
        if href.startswith(('http:','https:','#','/')):return match[0]
        target=(path.parent/href).resolve()
        if target.is_relative_to(ROOT):return 'href="/book-review/'+target.relative_to(ROOT).as_posix()+'"'
        return match[0]
    return re.sub(r'href="([^"]+)"',link,content)

css='''*{box-sizing:border-box}body{margin:0;background:#f5f1eb;color:#29252b;font:19px/1.75 Georgia,serif}main{max-width:1220px;margin:auto;padding:50px 28px}header{border-bottom:1px solid #cfc6bd;padding-bottom:28px}h1{font-weight:400;font-size:clamp(2.6rem,5vw,4.4rem);line-height:1.1}h2{font-weight:400;font-size:2rem;line-height:1.3;margin-top:1.6em}nav{display:flex;gap:24px;flex-wrap:wrap;font:15px/1.6 system-ui}a{color:#8c365c;text-underline-offset:4px}article{max-width:750px;margin:54px auto}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{font-size:16px;min-width:0}.pair h1{font-size:2rem}img{width:100%;display:block}figure{margin:32px 0}figcaption,.note,footer{font:14px/1.6 system-ui;color:#625560}.eyebrow{font:12px/1.4 system-ui;letter-spacing:.14em;text-transform:uppercase;color:#8c365c}pre{overflow:auto;background:#24232a;color:#f9ece5;padding:22px;font:14px/1.6 Consolas,monospace}code{font-size:.85em}pre code{font-size:inherit}details{border-top:1px solid #cfc6bd;padding:20px 0}summary{cursor:pointer}.footnote{font-size:.83em}footer{border-top:1px solid #cfc6bd;padding:25px 0}@media(max-width:780px){.pair{display:block}main{padding:24px 18px}pre{font-size:12px}}'''
nav='<nav><a href="index.html#museum">Museum</a><a href="reading.html#reading">Read the chapter</a><a href="making.html#making">Make a line</a><a href="index.html#changes">Changes</a><a href="point-lines-study.zip" download>Download study</a><a href="/compose/sources?map=Point_Lines&amp;doc=final">Live manuscript</a></nav>'
def page(title,body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{css}</style></head><body><main><header><p class="eyebrow">Point Lines · 30 September 2026</p><h1>{title}</h1>{nav}</header>{body}<footer>Native museum: {len(report["checks"])} checks passed. Portable lesson: 22 checks passed. Real museum screenshots; no headset or learner trial. One pre-existing unrecognised audio UID warning remains in the museum log.<br><a href="report.json">Museum checks</a> · <a href="lesson-verification.json">Lesson checks</a> · <a href="source-versions.json">Frozen sources</a></footer></main></body></html>'
(OUT/'reading.html').write_text(page('What a line can do','<article id="reading">'+md(MAP/'final.md')+'</article>'),encoding='utf-8')
(OUT/'making.html').write_text(page('Two ends, one relation','<article id="making">'+md(MAP/'tutorial.md')+'</article>'),encoding='utf-8')
body='''<article><p>The order now begins with the measuring line in the black box. Connect the dots to open the barrier; walk the black stripe; enter the four-view line room. The small exit passage alternates <strong>× + × + × +</strong>: hurt and recovery.</p><p>The reading keeps two lines of code. The separate making companion supplies a complete, small Godot project that continues from Coordinates.</p></article><section id="museum">'''
for name,caption in [('entrance-line','The first encounter: two endpoints, a pale segment and a changing length.'),('line-room','Inside the line room. Every one of its twenty grabbable rods was tested with the actual held-laser ray.'),('corridor','Three pairs in the authored exit corridor. X costs health; the front-facing plus restores it with a spatial chime and a burst of strokes.')]:
    body+=f'<figure><img src="{name}.png" alt="{html.escape(caption)}"><figcaption>{caption}</figcaption></figure>'
body+='''<div class="pair"><figure><img src="barrier-before.png" alt="Barrier before connection"><figcaption>Before the points connect.</figcaption></figure><figure><img src="barrier-broken.png" alt="Barrier broken"><figcaption>After connection: the complete barrier and its collision boundary are suspended. It waits for a visitor to clear its place before rebuilding.</figcaption></figure></div></section><article id="changes"><h2>What was repaired</h2><p>The laser's burn flag was stranded on its pickup wrapper. Its instrument now reads that configuration, and desktop carrying reaches the same held-tool condition as XR pickup. The beam breaks the room's studies after its existing dwell time. It stops at architecture; tools, resets and health services remain available.</p><p>The connection demonstration can open a rebuilt barrier again. Restoration now recognises the museum's layer-1 Walker as well as XR bodies.</p><p>The X gates use their own damage timing instead of the museum's shared creature-bite cooldown, which could skip the next X. Each plus offers up to 21 health when below full, and returns after eight seconds.</p><p>The floor plan and passage walls are unchanged. Only the six exit placements were changed or added.</p></article>'''
for name in ['final.md','tutorial.md']:
    body+=f'<details><summary>{name}: exact before / after</summary><pre>'+html.escape(diffs['commons/maps/Point_Lines/'+name])+'</pre></details>'
(OUT/'index.html').write_text(page('Measure. Cross. Recover.',body),encoding='utf-8')
log=ROOT/'doc/book/iterations/WORKING.md'
entry='''

### 2026-09-30 — Point Lines: measure and consequence

Updated the canonical chapter and beginner tutorial to begin in the black box, then connection/barrier, walk/trace, four-view line room and ×/+ exit. Kept main prose at two code lines; supplied a complete standalone two-endpoint/length study. Replaced stale companion guidance and synchronized encounter metadata and tutorial lineage.

Fixed the laser child missing #burns:1 on its pickup root and not hearing desktop carry. Actual held rays now break all twenty gallery rods; XR pickup remains supported. A disconnected/reconnected demo opens the restored barrier again. Shared restoration recognises the museum Walker's layer 1 as well as XR bodies. Kept the floor plan and all non-corridor placements; configured three X damage gates and three + recovery gates. Local passage damage bypasses the museum's generic 33-point bite/cooldown; pluses emit generated spatial audio and expanding strokes.

Review: 2026-09-30-lines-measure-and-consequence/index.html. Native museum checks and 22 standalone lesson checks passed; screenshots are museum interiors. No physical headset, learner trial or Quest performance claim. A pre-existing unrecognised audio UID warning remains. Current Primitives capture refreshed. No commit.
'''
if '### 2026-09-30 — Point Lines: measure and consequence' not in log.read_text(encoding='utf-8'):
    atomic(log,log.read_text(encoding='utf-8')+entry)
print('Published',len(report['checks']),'museum checks; 22 standalone checks;',len(changed),'corridor cells.')
