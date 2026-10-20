"""Publish the chapter journal and its new, author-operated composition evidence."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib, html, json, re, shutil, urllib.request
import markdown, yaml

R=Path(__file__).resolve().parents[1]
BLOG=R/'doc/blog/2026-10-09-what-holds-what-gives'
O=R/'doc/book/iterations/2026-10-09-soft-bodies-three-attachments'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Cloth_Physics/ghost-three-attachments'
CANONICAL=R.parent/'ada_encyclopedia/src/content/blog/2026-10-09-what-holds-what-gives.md'
def text(p):return p.read_text(encoding='utf8')
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

result=json.loads(text(RUN/'report.json'))
assert result['passed'] and not result['failures']
assert any(c['name']=='All planned composition checks completed' and c['passed'] for c in result['checks'])
for n in ['stdout.log','engine.log']:
    s=text(RUN/n);assert 'SCRIPT ERROR' not in s and 'Parse Error' not in s
for n in ['hanging_sheet.gd','point_body.gd']:
    assert (O/'student'/n).read_bytes()==(R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics'/n).read_bytes()
    assert (O/'student'/n).read_bytes()==(O/'first-submission'/n).read_bytes()
assert text(O/'student/study.gd')==text(O/'first-submission/study.gd').replace('Color("25212a")','Color("f4e9d7")')
for rel,digest in json.loads(text(R/'doc/book/iterations/2026-10-09-soft-bodies-complete-readings/protected-hashes.json')).items():assert sha(R/rel)==digest,rel
(O/'images').mkdir(exist_ok=True);(O/'evidence').mkdir(exist_ok=True)
for n in ['three-places.png','in-the-hall.png']:shutil.copyfile(RUN/n,O/'images'/n)
for n in ['report.json','stdout.log','engine.log','source_manifest.json']:shutil.copyfile(RUN/n,O/'evidence'/n)
shutil.copyfile(R/'tools/probes/soft_three_attachments.gd',O/'evidence/probe.gd')
v=result['observations']['comparison'];n=len(result['checks']);distance=v['free_corner_motion_m'];error=v['largest_pin_error_m']
report=f'''# Three places to hold a sheet

9 October 2026 · An additional ghost-student composition inside the existing Cloth hall

**{n} native checks passed.** This exercise goes beyond the chapter's supplied parameter edits. It asks whether the student can reuse its sheet to pose another question about attachment.

The authoring assistant performed this rehearsal with prior knowledge of the chapter. It is not a blind second-model or human-student assessment. The earlier nine-hall run remains the evidence for all 263 supplied checks; this new run adds a composition and native images.

## Prediction and result

Keep two identical sheets. A holds its upper corners. B holds upper left, lower left and the existing vertex nearest middle right. Clear all other pins. Keep the same mesh, mass, stiffness, damping, pressure, starting orientation and height.

Both retain 112 reference positions and identical connectivity. The engine reported A's pins as {v['a_pins']} and B's as {v['b_pins']}. These are results of coordinate selection, not hardcoded instructions. The upper-right vertex is held in A and free in B.

After 120 awaited physics callbacks, B's freed corner had moved **{distance:.3f} metres**. The largest drift at its three held points was **{error:.8f} metres**, below the predicted 1 mm tolerance. The prediction specified movement, not an exact fold or distance. No material coefficient was changed to produce that difference.

The same PointBody can be grabbed with XRTools. Its trigger reconstructs the two sheets while retaining the point instance; release parks it in the transformed host. Keyboard R was also exercised through actual input dispatch. A moved and turned host retains the same local selection. The study's visitor approach has museum floor. These are synthetic input and native desktop checks, not a physical headset session.

## What this adds to the learning evidence

The new composition uses reference coordinates, a loop and nearest-point selection to choose a boundary the original exercise did not prescribe. It demonstrates that the sheet construction can support another material question. It does not establish that an unfamiliar beginner would formulate or implement that question without help.

The host, sheet and point are available in student/. The sheet and point files are unchanged from Cloth. The comparison is temporary inside the real museum; no permanent artifact, map or chapter code was changed.

## Retained failed attempt

The first checker called a PrimitiveMesh method after Godot had exposed an ArrayMesh. Execution stopped early with SCRIPT ERROR, although the generic runner printed a passing subtotal. attempt-1/ records that rejected run. The corrected checker uses surface_get_arrays(0) and refuses to pass without reaching its completion check.

The next run passed all checks. Its pictures showed a dark caption lost against the sky. Only caption colour changed for the final run, which passed again. attempt-2/ retains the earlier pictures and receipt. The attachment rule was unchanged throughout.

## Reproduce

Run inside AdaResearch_46 with its prepared museum and dependencies:

```powershell
python tools/run_encounter_probe.py SoftBodies_Cloth_Physics --sequence softbodies --render --no-bridges --output-tag ghost-three-attachments --probe tools/probes/soft_three_attachments.gd
```

Require the completed-run check and inspect both engine logs for script/parse errors; exit zero alone is insufficient. The print/step count is a numerical test interval, not a promise about wall-clock time.
'''
write(O/'REPORT.md',report)
CSS=re.search(r'<style>(.*?)</style>',text(R/'doc/blog/2026-10-08-everything-worked-and-this-happened/index.html'),re.S)[1]
CSS+='\narticle>h2,article>h3,article>ul,article>ol,article>pre,article>details{max-width:720px;margin:30px auto}pre{overflow:auto;padding:20px;background:#25232d;color:#f4eee7;font:13px/1.6 Consolas,monospace}summary{cursor:pointer}details{padding:14px;border:1px solid #cec4c5}'
def page(title,subtitle,body,nav):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' — Endless Museum</title><style>'+CSS+'</style></head><body><nav><span>Endless Museum · Research journal</span>'+nav+'</nav><header><div class="eyebrow">Soft Bodies · 9 October 2026</div><h1>'+html.escape(title)+'</h1><div class="subtitle">'+html.escape(subtitle)+'</div></header><article id="reading">'+body+'</article><footer>Ada Research · Native Godot captures · The museum is the learning environment.</footer></body></html>'
body='<figure><img src="images/three-places.png" alt="Two matching sheets with two and three attachments"><figcaption>Two corners and three places. The other material settings are shared.</figcaption></figure>'
body+=markdown.markdown(report.split('\n\n',1)[1],extensions=['fenced_code','tables'])
body+='<figure><img src="images/in-the-hall.png" alt="Temporary sheet comparison beside the existing curtain"><figcaption>The temporary composition in the real Cloth hall.</figcaption></figure>'
body+='<p><a href="PREDICTIONS.md">Predictions recorded before execution</a> · <a href="evidence/report.json">All final checks</a> · <a href="attempt-1/REJECTED.txt">Rejected attempt</a> · <a href="student/study.gd">New student host</a> · <a href="student/study.tscn">Study scene</a></p>'
for file in ['study.gd','hanging_sheet.gd','point_body.gd']:
    body+='<details><summary>'+html.escape(file)+'</summary><pre><code>'+html.escape(text(O/'student'/file))+'</code></pre></details>'
write(O/'index.html',page('Three places to hold a sheet','A new question using the chapter’s existing objects.',body,'<a href="REPORT.md">Report source</a>'))

post=text(BLOG/'post.md')
paragraph=f'Before running, we predicted that the three selected points would stay fixed while the released corner moved. The native museum run confirmed both: that corner moved about {distance:.2f} metres over the observation interval, while the greatest attachment drift stayed below one millimetre. All {n} checks passed, including the carried point’s grip, trigger and rebuild. The exact fold was left open. The exercise used a known construction to ask a new question.'
if '{{GHOST_RESULT}}' in post:
    post=post.replace('{{GHOST_RESULT}}',paragraph);write(BLOG/'post.md',post)
assert '{{' not in post
assert not CANONICAL.exists() or CANONICAL.read_bytes()==(BLOG/'post.md').read_bytes(), 'Blog destination already has different content.'
CANONICAL.write_bytes((BLOG/'post.md').read_bytes())
front,body_md=post[4:].split('\n---\n',1)
meta=yaml.safe_load(front)
body=markdown.markdown(body_md,extensions=['fenced_code','tables'])
body=re.sub(r'<p>(<img [^>]+>)</p>\s*<p><em>(.*?)</em></p>',r'<figure>\1<figcaption>\2</figcaption></figure>',body,flags=re.S)
(BLOG/'images').mkdir(exist_ok=True)
copied=[]
for i,src in enumerate(re.findall(r'<img[^>]+src="([^"]+)"',body)):
    assert src.startswith('/book-review/')
    original=R/src[len('/book-review/'):]
    filename=f'{i+1:02d}-'+original.name
    shutil.copyfile(original,BLOG/'images'/filename)
    body=body.replace('src="'+src+'"','src="images/'+filename+'"')
    copied.append({'source':original.relative_to(R).as_posix(),'local':'images/'+filename,'sha256':sha(original)})
body=re.sub(r'href="(/book-review/[^"#]*)(#[^"]*)?"',lambda m:'href="'+(R/m[1][len('/book-review/'):]).resolve().as_uri()+(m[2] or '')+'"',body)
write(BLOG/'index.html',page(meta['title'],meta['subtitle'],body,'<a href="post.md">Markdown source ↗</a>'))
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.figures=0
    def handle_starttag(self,tag,attrs):
        self.links.extend(v for k,v in attrs if k in ['src','href'] and v)
        if tag=='figure':self.figures+=1
parser=Links();parser.feed(text(BLOG/'index.html'));assert parser.figures==6
for img in copied:assert sha(R/img['source'])==sha(BLOG/img['local'])==img['sha256']
for src in re.findall(r'\]\((/book-review/[^)]+)\)',body_md):assert (R/src[len('/book-review/'):].split('#')[0]).exists(),src
for p in [O/'index.html',BLOG/'index.html']:
    parser=Links();parser.feed(text(p))
    for link in parser.links:
        if link.startswith(('http:','https:','file:','#')):continue
        assert (p.parent/link.split('#')[0]).exists(),link
assert CANONICAL.read_bytes()==(BLOG/'post.md').read_bytes()

fresh_path=R/'doc/book/iterations/2026-10-09-soft-bodies-complete-readings/ghost-rerun/validation.json'
fresh=None
if fresh_path.exists():
    fresh=json.loads(text(fresh_path))
    assert fresh['passed'] and fresh['fresh_lesson_checks']==263 and fresh['fresh_composition_checks']==21
dump(O/'manifest.json',{'passed':True,'checks':n,'comparison':v,'files':{p.name:sha(p) for p in (O/'student').glob('*') if p.suffix in ['.gd','.tscn']},'first_submission_preserved':True,'change_after_submission':'Caption colour only. Checker API corrected separately.','native_images':['images/three-places.png','images/in-the-hall.png'],'author_operated':True,'independent_learner':False,'headset':False})
dump(BLOG/'publication-checks.json',{'canonical_source':str(CANONICAL),'portable_copy_matches_source':True,'image_count':len(copied),'images':copied,'all_images_unmodified':True,'new_composition_checks':n,'earlier_sequence_checks':263,'fresh_rehearsal':str(fresh_path.relative_to(R)) if fresh else None,'fresh_rehearsal_passed':bool(fresh),'native_images_inspected':True,'browser_layout_checked':False,'words':len(re.findall(r"\b[\w’'-]+\b",body_md)),'links_valid':True})
print(json.dumps({'post':str(CANONICAL),'blog_images':len(copied),'new_checks':n,'free_corner_motion_m':distance,'report':str(O/'index.html')}))
