"""Collect the eight current readings; preserve sources and scope prior evidence."""
from pathlib import Path, PurePosixPath
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib, html, json, re, shutil, zipfile
import markdown

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-lsystems-complete-readings'
O.mkdir(exist_ok=True)
for d in ['assets','halls']: (O/d).mkdir(exist_ok=True)
def write(p,s): p.write_bytes(s.encode('utf-8'))
def dump(p,v): write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
sequence=json.loads((R/'commons/maps/sequences/lsystems.json').read_text(encoding='utf-8'))['sequences']['lsystems']
editorial_root=R/'doc/book/iterations/2026-10-09-lsystems-tightening'
editorial=json.loads((editorial_root/'editorial-checks.json').read_text(encoding='utf-8'))
assert editorial['passed']
revisions=[]
roots=['lsystems-a-sentence-and-a-reading','growth-what-a-branch-keeps','curves-one-sentence-three-readers','architecture-a-place-to-pass','competition-the-next-turn','living-a-design-kept','shape-grammar-a-face-continues','assemblage-the-choices-remain']
photos=['comparison','branch','three','built','two-turns','threshold','family','alphabet']
above=['above','above','above','above','above','above','student-above','above']
names=['Grammar Lab','Growth','Grammars and Curves','Architecture','Competition','Living','Shape Grammars','Assemblage']
summaries=[
 'Rewrite the old sentence into a separate next sentence. Interpret it as movement. Keep the sentence fixed while changing its angle, then retain a reading for comparison. The familiar point and cylinder return; the new capacity is to separate instructions from their spatial reading.',
 'Carry position, heading and stride in a saved state. A bracket pushes a copy onto a stack; its partner restores the most recent state. Follow a branch and its return before reading a larger tree. A branch can continue because another state was kept.',
 'Read one sentence with three readers in equal metre units. Change how a heading becomes a displacement while retaining the stored heading. Predict which relations a component exchange preserves. The tube bay has a separate optional reading; it is not required before Architecture.',
 'Give one fixed path a footprint. Combine overlapping cells and construct only exposed boundaries; then compare an opening with a particular collision body. The sentence supplies a plan, but passage also depends on width, occupancy and the body attempting it.',
 'Give two copies of the same grammar turns in shared soil. Record what each consumes before deciding whether it may rewrite. Reverse the order from the same initial state. Execution order and shared conditions can produce different histories without different starting rules.',
 'Keep a design while editing another. Follow a raw requested value through rounding, clamping, generated instructions and a body. Change the angle while retaining the sentence. Editable, held and planted records must remain independent; the available controls still delimit what can be requested.',
 'Return to the cube. Select its top triangles, inset, extrude and repeat on their growing tips. Current face indices change as the list is replaced; tags carry the continuation. Select one triangle instead of two and verify the complete resulting mesh.',
 'Keep random samples while changing decisions and marks independently. A witness retains its alphabet; a row queue retains eleven rows when the next arrives. Exchange large and small blocks without changing choices, colour or addresses. Distinguish the record from the paths a reader recognises.'
]
records=[]; sources={}; code_count=0
for i,(key,root) in enumerate(zip(sequence['maps'],roots)):
    D=R/'doc/book/iterations'/('2026-10-09-'+root)
    M=R/'commons/maps'/key
    H=O/'halls'/key; H.mkdir(exist_ok=True)
    for d in ['code','receipts']: (H/d).mkdir(exist_ok=True)
    manifest=json.loads((D/'manifest.json').read_text(encoding='utf-8'))
    hashes=manifest.get('canonical',manifest.get('files'))
    texts={}
    for kind in ['tutorial','final']:
        p=M/(kind+'.md')
        before=editorial_root/'before'/key/p.name
        assert sha(before)==hashes[p.name],('baseline does not match original hall receipt',key,p.name)
        revisions.append({'source':p.relative_to(R).as_posix(),'original_hall_sha256':sha(before),
                          'current_sha256':sha(p),'text_changed':sha(before)!=sha(p)})
        if kind=='final':
            old_text=before.read_text(encoding='utf-8'); new_text=p.read_text(encoding='utf-8')
            for pattern in [r'<!--\s*@([^>]*?)-->',r'!\[[^\]]*\]\(([^)]+)\)',r'^\[\^([^\]]+)\]: (.*)$']:
                assert re.findall(pattern,old_text,re.M)==re.findall(pattern,new_text,re.M),(key,'lost artifact marker, image or historical footnote')
        shutil.copyfile(p,H/p.name); sources[p.relative_to(R).as_posix()]=sha(p)
        texts[kind]=p.read_text(encoding='utf-8')
    marked=dict(re.findall(r'<!-- student-code:([^ >]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S))
    assert set(marked)==set(manifest['printed']),(key,list(marked),list(manifest['printed']))
    for name,expected in manifest['printed'].items():
        p=D/'printed'/name
        assert sha(p)==expected
        assert marked[name]+'\n'==p.read_text(encoding='utf-8'),(key,name)
        shutil.copyfile(p,H/'code'/name); code_count+=1
    learner=json.loads((D/'checks.json').read_text(encoding='utf-8'))
    museum=json.loads((D/'museum/report.json').read_text(encoding='utf-8'))
    assert learner['passed'] and museum['passed'],key
    for src,dst in [('checks.json','learner.json'),('museum/report.json','museum.json'),('manifest.json','hall-manifest.json')]:
        shutil.copyfile(D/src,H/'receipts'/dst)
    for filename in ['engine.log','museum/engine.log']:
        if (D/filename).exists():
            shutil.copyfile(D/filename,H/'receipts'/filename.replace('/','-'))
    images=[]
    for filename,label in [(photos[i]+'.png','primary'),(above[i]+'.png','above')]:
        target=f'{i+1:02d}-{label}.png'; shutil.copyfile(D/'assets'/filename,O/'assets'/target); images.append('assets/'+target)
    records.append({'id':key,'name':names[i],'summary':summaries[i],'source_report':D.relative_to(R).as_posix(),
        'printed_files':manifest['printed'],'learner_checks':len(learner['checks']),'museum_checks':len(museum['checks']),
        'source_comparisons':learner.get('production_comparisons',learner.get('source_comparisons')),
        'images':images,'texts':texts})

optional_source=R/'commons/maps/LSystems_Grammars_And_Curves/tutorial-applications.md'
optional_text=optional_source.read_text(encoding='utf-8')
original_curves=(editorial_root/'before/LSystems_Grammars_And_Curves/tutorial.md').read_text(encoding='utf-8')
retained_notes=original_curves.split('## Optional applications — existing tube-bay notes',1)[1]
assert optional_text.endswith(retained_notes), 'Optional application notes must be retained intact'
sources[optional_source.relative_to(R).as_posix()]=sha(optional_source)
shutil.copyfile(optional_source,O/'halls/LSystems_Grammars_And_Curves/tutorial-applications.md')

feedback_root=R/'doc/book/iterations/2026-10-09-lsystems-feedback'
feedback_receipt=json.loads((feedback_root/'variation-checks.json').read_text(encoding='utf-8'))
feedback_manifest=json.loads((feedback_root/'variation-manifest.json').read_text(encoding='utf-8'))
assert feedback_receipt['passed']
ghost_root=R/'doc/book/iterations/2026-10-09-lsystems-ghost-student'
ghost=json.loads((ghost_root/'validation.json').read_text(encoding='utf-8'))
assert ghost['passed'] and ghost['complete_eight_hall_program_run']
for name,digest in ghost['canonical_sources'].items():
    assert sha(R/name)==digest,('ghost-student evidence is stale',name)
shutil.copytree(ghost_root,O/'ghost-student',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.uid','__pycache__'))
review_target=O/'review-variation'; review_target.mkdir(exist_ok=True)
for name,digest in feedback_manifest['files'].items():
    assert sha(feedback_root/name)==digest,('feedback code hash',name)
    target=review_target/name; target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(feedback_root/name,target)
current_opening=dict(re.findall(r'<!-- student-code:([^ >]+) -->\s*```gdscript\n(.*?)\n```',records[0]['texts']['tutorial'],re.S))
for name,code in current_opening.items():
    assert (code+'\n').encode('utf-8')==(review_target/'printed'/name).read_bytes(),('feedback source has changed',name)
for name in ['variation-checks.json','variation-manifest.json','engine.log','stdout.log']:
    shutil.copyfile(feedback_root/name,review_target/name)
shutil.copyfile(R/'tools/probes/lsystems_review_variation.gd',review_target/'run.gd')
write(review_target/'RUN.md','''# Re-run the focused experiment

Use a working copy of the prepared Ada museum project with its existing XRTools installation. This folder is not a standalone project.

Copy this review-variation folder to `doc/book/iterations/2026-10-09-lsystems-feedback` inside that project, keeping printed/ and turns-reversed/ beside run.gd. Then invoke your Godot 4.6 executable:

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://doc/book/iterations/2026-10-09-lsystems-feedback/run.gd
```

run.gd is the exact probe used for the receipt. It loads both complete programs, reports each assertion and writes variation-checks.json in that folder, replacing the copied receipt. Keep the original ZIP for comparison. A nonzero exit or SCRIPT ERROR is a failure. The run is headless and does not establish headset behavior or independent learning.
''')
shutil.copyfile(feedback_root/'external-review.md',O/'EXTERNAL-REVIEW.md')
shutil.copyfile(feedback_root/'RESPONSE.md',O/'FEEDBACK.md')

# Preserve complete source readings; only references change in the portable compiled views.
def portable(s,prefix):
    for ref in set(re.findall(r'/book-images/[^\s)"<>]+',s)):
        source=R/'doc/book'/ref.removeprefix('/book-images/')
        assert source.is_file(),ref
        target='reference-'+sha(source)[:12]+source.suffix
        shutil.copyfile(source,O/'assets'/target)
        s=s.replace(ref,'assets/'+target)
    s=s.replace('](/book-review/','](http://localhost:3003/book-review/')
    s=s.replace('](tutorial-applications.md)','](applications.html)')
    s=s.replace('](tutorial.md)','](tutorial.html#LSystems_Grammars_And_Curves)')
    # Prevent footnote collisions when individual sources become one reading.
    s=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+prefix+'-'+m[1]+']',s)
    return s

def rendered(s,prefix):
    value=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    value=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],value,flags=re.S)
    return value

css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;color:#20252a;background:#eeeae3;font-family:Georgia,serif;line-height:1.65}header,main,footer{max-width:1450px;margin:auto;padding:28px 4vw}header{border-bottom:1px solid #b9b7b1}nav{display:flex;flex-wrap:wrap;gap:10px 22px;font:15px system-ui}a{color:#315267}h1{font-size:clamp(2.5rem,6vw,5rem);line-height:1.06;font-weight:500}h2{line-height:1.2;font-size:2rem}h3{font-size:1.3rem}.eyebrow,figcaption,.meta{font:13px/1.5 system-ui}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#5e6667}.lead{font-size:1.4rem;max-width:900px}.reading{max-width:960px}.chapter{padding:36px 0;border-top:1px solid #aaa;scroll-margin-top:12px}article p,article li{max-width:82ch}pre{overflow:auto;background:#202730;color:#ebeff4;padding:20px;font:13px/1.5 Consolas,monospace;tab-size:4}code{font-family:Consolas,monospace}p code,li code{font-size:.88em;background:#dddcd6;padding:1px 4px}img{max-width:100%;height:auto}figure{margin:24px 0}figcaption{color:#50575b;padding-top:8px}.spread{display:grid;grid-template-columns:1fr 1fr;gap:36px;align-items:start}.spread article{min-width:0;background:#faf8f3;padding:22px}.spread h1{font-size:2rem}.spread pre{font-size:12px}.photos{display:grid;grid-template-columns:2fr 1fr;gap:20px;align-items:start}.toc{columns:2;column-gap:35px}.toc li{break-inside:avoid;margin-bottom:8px}table{border-collapse:collapse;width:100%;font:14px/1.5 system-ui}td,th{text-align:left;border-bottom:1px solid #c5c4bd;padding:10px}footer{color:#60666a;font:13px/1.5 system-ui}@media(max-width:850px){.spread,.photos{grid-template-columns:1fr}.toc{columns:1}}@media print{header nav,.download{display:none}body{background:white}main{padding:0}pre{white-space:pre-wrap;overflow-wrap:anywhere;color:black;background:#f2f2f2}.chapter{break-before:page}img{max-height:85vh;object-fit:contain}a{color:inherit}.spread{display:block}.spread article{break-before:page}}'''

def page(title,body,klass=''):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · complete L-systems reading · 9 October 2026</p><nav><a href="index.html">Eight-hall route</a><a href="tutorial.html">Full tutorial</a><a href="final.html">Full reflection</a><a href="parallel.html">Facing texts</a><a href="applications.html">Optional tube bay</a><a href="feedback.html">Review response</a><a href="ghost-student/index.html">Ghost-student run</a><a href="evidence.html">Evidence</a><a href="REVIEW.md">Reviewer brief</a><a href="lsystems-review.zip">Download ZIP</a></nav></header><main class="'+klass+'">'+body+'</main><footer>All 31 primary learner files were freshly executed across eight lessons: 212 checks passed, plus 21 transfer-exercise checks. Competition has a fresh rendered museum comparison and 8 checks. Earlier hall receipts remain dated evidence. This authoring-AI simulation does not establish independent learner or physical-headset acceptance.</footer></body></html>'

def toc(kind): return '<ol class="toc">'+''.join('<li><a href="'+kind+'.html#'+r['id']+'">'+html.escape(r['name'])+'</a></li>' for r in records)+'</ol>'
def figure(path,caption): return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
body='<h1>A sentence.<br>A body.<br>Another reading.</h1><p class="lead">Eight halls, two continuous texts. The tutorial reconstructs selected operations inside the museum. The reflection follows what those operations let us do, and what they leave outside.</p>'
body+='<p>Keep the prepared museum and the familiar point. Each hall adds one main distinction; its other works remain part of the encounter. These photographs were captured during the individual hall passes.</p>'+toc('parallel')
body+='<p>The main route runs from string rewriting to interpretation, construction and conditions of growth. Shape Grammars extends replacement to faces; Assemblage closes by testing the distinction between choices and marks in another kind of generator. Finish with the independent variation at the end of the tutorial.</p><p><a href="applications.html">Optional tube-bay applications</a> · <a href="REVISIONS.md">What changed before this review</a></p>'
body+='<p><a href="feedback.html">External review and response</a>: clearer sequence framing, a selection walkthrough, and an executed turn-reversal experiment. The eight-hall order remains.</p>'
body+='<p><a href="ghost-student/index.html">New: the ghost student runs all eight lessons</a>. Current printed programs, predictions, a chosen resource-uptake variation and fresh museum images. The report distinguishes executable success from the remaining teaching and presentation questions.</p>'
body+='<p><a href="tutorial.md">Full tutorial Markdown</a> · <a href="final.md">Full reflective Markdown</a> · <a href="lsystems-review.zip">Portable review ZIP</a></p>'
for i,r in enumerate(records):
    body+='<section class="chapter" id="'+r['id']+'"><p class="eyebrow">'+str(i+1).zfill(2)+' / 08</p><h2>'+r['name']+'</h2><p class="lead">'+html.escape(r['summary'])+'</p><p><a href="parallel.html#'+r['id']+'">Read both texts</a> · <a href="evidence.html#'+r['id']+'">Scope and receipts</a></p><div class="photos">'+figure(r['images'][0],'Installed primary comparison — '+r['name'])+figure(r['images'][1],'Above the room during its tutorial pass — '+r['name'])+'</div></section>'
write(O/'index.html',page('L-systems — complete readings',body))

for kind,title in [('tutorial','L-systems — complete tutorial'),('final','L-systems — complete reflective sequence')]:
    combined='# '+title+'\n\nEight halls in canonical spine order. Current source texts collected on 9 October 2026. See REVIEW.md and evidence.html for the scope of the accompanying checks.\n\n'
    html_body='<h1>'+title+'</h1>'+toc(kind)
    for i,r in enumerate(records):
        s=portable(r['texts'][kind],str(i+1)+'-'+kind)
        combined+='\n---\n\n<!-- hall: '+r['id']+' -->\n\n'+s+'\n'
        html_body+='<article class="chapter" id="'+r['id']+'"><p class="eyebrow">'+str(i+1).zfill(2)+' · '+r['name']+'</p>'+rendered(s,str(i+1))+'</article>'
    write(O/(kind+'.md'),combined);write(O/(kind+'.html'),page(title,html_body,'reading'))

body='<h1>Two texts,<br>one walk.</h1><p>Tutorial on the left; reflection on the right. On a narrow screen, each pair stacks in that order.</p>'+toc('parallel')
for i,r in enumerate(records):
    body+='<section class="chapter" id="'+r['id']+'"><p class="eyebrow">'+str(i+1).zfill(2)+' · '+r['name']+'</p><div class="spread">'
    for kind,label in [('tutorial','Left · tutorial.md'),('final','Right · final.md')]:
        body+='<article><p class="eyebrow">'+label+'</p>'+rendered(portable(r['texts'][kind],str(i+1)+'-'+kind),str(i+1))+'</article>'
    body+='</div></section>'
write(O/'parallel.html',page('L-systems — facing texts',body))

optional_portable=portable(optional_text,'optional')
write(O/'applications.md',optional_portable)
write(O/'applications.html',page('Optional applications — the tube bay',rendered(optional_portable,'optional'),'reading'))

feedback_html=rendered((feedback_root/'RESPONSE.md').read_text(encoding='utf-8'),'feedback')
feedback_html+='<p><a href="EXTERNAL-REVIEW.md">Full external review</a> · <a href="review-variation/variation-checks.json">30-check native receipt</a> · <a href="review-variation/variation-manifest.json">Code hashes</a> · <a href="review-variation/engine.log">Engine log</a> · <a href="review-variation/RUN.md">Re-run instructions</a> · <a href="review-variation/run.gd">Exact test probe</a></p><h2>Complete programs used in the experiment</h2><table><tr><th>Original printed file</th><th>Turn-reversal copy</th></tr>'
for name in current_opening:
    feedback_html+='<tr><td><a href="review-variation/printed/'+name+'">'+name+'</a></td><td><a href="review-variation/turns-reversed/'+name+'">'+name+'</a></td></tr>'
feedback_html+='</table><p>Only the two turn handlers in grammar.gd differ. The host, PointBody and line renderer are unchanged.</p>'
feedback_html+='<p><strong>Subsequent whole-sequence follow-up:</strong> <a href="ghost-student/index.html">the ghost-student report</a> records a fresh run of all eight printed programs, a different unprescribed edit and its actual museum comparison. The earlier response above retains the scope of its original narrow experiment.</p>'
write(O/'feedback.html',page('L-systems — response to external review',feedback_html,'reading'))

brief='''# Review the L-systems sequence

You are the ghost student. You already know the earlier point, line, trace, arrays, transforms, randomness, fractals and cellular updates, and you work inside the prepared Endless Museum. The point is a familiar object. Read for pleasure and possibility, while taking the executable claims seriously.

Read tutorial.html and final.html separately, or parallel.html together. Follow the eight halls in order. For each, identify what you bring, the new operation, what you can construct, a prediction you can test, and what travels onward. Report a precise missing dependency or unexplained transition rather than asking every exhibit to become a lesson. Distinguish a software fact, a bodily encounter and an interpretive claim. Shape Grammars deliberately extends beyond string rewriting; Assemblage uses independent random samples. Assess those as transfers, not as claims that every generator is an L-system.

Finish with the independent variation in Assemblage: choose an edit not prescribed by an exercise, predict its effect, keep a comparison and test an invariant. Say whether the preceding lessons gave you enough to choose and explain that edit. If you only read the package, distinguish your predicted outcome from an executed test. The optional tube-bay reading in applications.html is not a prerequisite for completing this task or reaching Architecture.

The primary lesson files in halls/<map>/code are exactly the marked code printed in that hall's tutorial. They require the prepared museum/XRTools dependencies; this ZIP is not a standalone Godot project. Repeated filenames belong to separate hall folders and may contain deliberate revisions. Current tutorial.md/final.md copies in those folders are unchanged canonical source; compiled readings only adapt image, local-link and footnote references.

The receipts under halls record author-led tests already run during each hall pass. They do not replace your independent reconstruction or prove headset comfort. The original hall manifests retain their earlier text hashes; editorial-revisions.json records subsequent text changes. Optional tube-making prose and snippets have a separate reading and remain outside the four-file reader test. Their earlier report link requires the local review server. Historical image references in the compiled readings have portable copies.

A subsequent ghost-student simulation freshly extracted and executed all 31 current primary files across the eight lessons: 212 native checks passed. Its chosen quarter-uptake edit passed 21 checks and a rendered Competition comparison passed 8. See ghost-student/index.html for predictions, per-hall capacity assessments, exact code and fresh receipts. This pass reused the established author-led suites; it is not a blind independent learner assessment. Only Competition was freshly rendered inside its actual hall. Other current lesson hosts ran in the prepared project; there was no fresh eight-hall physical traversal. The report names remaining density and close-view legibility concerns.

After external review, a focused native experiment executed the proposed turn reversal using the exact printed Grammar Lab base files. Its 30 checks cover 20 model cases and the complete base/edited hosts. See feedback.html and review-variation. This authoring-AI run does not establish independent learner success. Keep it as reviewer evidence, rather than treating it as the required answer to the final open assignment.

Use REVIEW-NOTES.md to record proposed revisions. Do not treat the eight drafts as locked. Concentrate on continuity, useful capacity, clarity and the division of labour between tutorial and reflection. A passing assertion verifies its stated behaviour, not every possible use of a program or the quality of learning.
'''
write(O/'REVIEW.md',brief)
if not (O/'REVIEW-NOTES.md').exists():
    write(O/'REVIEW-NOTES.md','# L-systems review notes\n\nFor each note: hall; exact passage; observed difficulty; proposed change; what must remain intact.\n\n'+''.join('## '+r['name']+'\n\n- \n\n' for r in records))
write(O/'README.txt','Open index.html, tutorial.html, final.html or parallel.html. Eight tightened source pairs; portable images; 31 unchanged primary lesson files; prior native hall receipts. ghost-student/index.html records the fresh eight-lesson printed-code run (212 checks), a chosen transfer exercise (21) and actual Competition comparison (8 checks, three images). This is an authoring-AI simulation, not an independent human or headset test. Optional tube-bay notes: applications.html. Earlier external review and focused turn-reversal experiment: feedback.html. Not a complete Godot project. REVIEW.md explains scope; REVISIONS.md names the editorial pass. REVIEW-NOTES.md is editable. Canonical hall texts retain original image URLs; compiled readings include portable copies. The earlier optional tube-making report requires localhost:3003.\n')

before_words=sum(h['reflection_before_words'] for h in editorial['halls'])
after_words=sum(h['reflection_after_words'] for h in editorial['halls'])
revision_note=f'''# Before external review — editorial revision

The eight-hall order and all 31 marked learner programs are preserved. No production artifact, map geometry or runtime logic was changed in this pass.

- Reflections shortened from {before_words:,} to {after_words:,} whitespace-counted words, keeping the encounters, distinctions, image references and historical notes. Repeated control instructions and detailed counts remain in the tutorials.
- Curves now ends its main lesson after the three readers. Its existing tube-bay applications are retained intact in a separate linked reading.
- Shape Grammars and Assemblage explicitly identify their move beyond L-system string rewriting.
- Assemblage ends with an independent variation, a prediction and an invariant the learner must test. This is an assignment, not an already passed learner test.
- Living's prose now agrees with its unchanged code: taper 0.68.

Current source hashes and links are checked again. Every marked learner file must match its original tested copy. Historical receipts and images are preserved; their original text hashes are not silently replaced. See editorial-revisions.json for the before/current hash mapping. The optional application notes remain outside the primary reader tests.

After external review: the opening names the broader route, Shape Grammars separates eligibility from list addresses, and Competition explicitly states the limits of its deterministic experiment. A separate turn-reversal copy was executed in Godot: 30 checks, 20 model cases. See FEEDBACK.md for the response and its evidence limits. This addition does not alter the 31 primary lesson files.
'''
write(O/'REVISIONS.md',revision_note)
dump(O/'editorial-revisions.json',{'scope':'Text-only tightening; unchanged marked learner programs; no new runtime run.','sources':revisions,'counts':editorial['halls']})
evidence='<h1>What the evidence covers.</h1><p>The 16 main texts were tightened after their hall passes; one optional application reading is now separate. All 31 marked primary code files still match their tested copies. The current manifest hashes the revised sources. Original receipts remain unchanged; <a href="editorial-revisions.json">the editorial record</a> connects their earlier text hashes to this version.</p><p>No new whole-sequence runtime or independent learner test was performed during this editorial pass. Read each receipt for its actual scope. Counts include different kinds of assertion and are not a quality score.</p><table><tr><th>Hall</th><th>Printed lesson checks</th><th>Museum checks</th><th>Files</th></tr>'
for r in records:
    evidence+='<tr><td>'+r['name']+'</td><td>'+str(r['learner_checks'])+'</td><td>'+str(r['museum_checks'])+'</td><td>'+str(len(r['printed_files']))+'</td></tr>'
evidence+='</table><p>The <a href="applications.html">optional tube-bay reading</a> remains outside the primary four-file reader test. The independent final variation is for a learner to choose and test. Native images are prior hall captures. Physical-headset, Quest-performance and independent-student acceptance remain separate evidence.</p>'
evidence+='<p><strong>Focused run after review:</strong> <a href="review-variation/variation-checks.json">30 checks passed</a> for the proposed turn reversal, including 20 model cases and the full original/edited hosts. Its <a href="feedback.html">scope and negative control</a> are separate from the eight original hall receipts.</p>'
evidence+='<p><strong>Subsequent fresh eight-lesson run:</strong> <a href="ghost-student/index.html">ghost-student report</a> · <a href="ghost-student/validation.json">current receipt</a>. All 31 printed programs were extracted and executed again: 212 checks passed; a different chosen transfer exercise passed 21. One actual museum hall was freshly rendered with 8 checks. The report includes the current texts, predictions and results without replacing the historical receipts listed here. No independent learner or headset acceptance is claimed.</p>'
for r in records:
    base='halls/'+r['id']+'/'
    evidence+='<section class="chapter" id="'+r['id']+'"><h2>'+r['name']+'</h2><p><a href="'+base+'receipts/learner.json">Learner receipt</a> · <a href="'+base+'receipts/museum.json">Museum receipt</a> · <a href="'+base+'receipts/hall-manifest.json">Original hall manifest</a></p><p><a href="'+base+'tutorial.md">Canonical tutorial</a> · <a href="'+base+'final.md">Canonical reflection</a></p><ul>'+''.join('<li><a href="'+base+'code/'+f+'">'+f+'</a></li>' for f in r['printed_files'])+'</ul></section>'
write(O/'evidence.html',page('L-systems — evidence',evidence))
dump(O/'manifest.json',{'date':'2026-10-09','scope':'Tightened eight-hall readings and optional applications; prior native hall evidence; focused turn-reversal experiment; fresh exact-code eight-lesson ghost-student simulation, unprescribed uptake variation and rendered Competition follow-up. No independent human or physical-headset assessment.','canonical_sources':sources,'primary_files':code_count,'ghost_student':ghost,'focused_review_experiment':{'checks':len(feedback_receipt['checks']),'cases':feedback_receipt['model_cases'],'passed':feedback_receipt['passed'],'independent_learner':False},'halls':[{k:v for k,v in r.items() if k!='texts'} for r in records]})
assert code_count==31
archive=O/'lsystems-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p != O/'validation.json':
            data=p.read_bytes()
            if p.suffix=='.html': data=data.replace(b'href="lsystems-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]; self.ids=[]
    def handle_starttag(self,tag,attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
        self.ids.extend(v for k,v in attrs if k=='id')
parsers={}
for p in O.glob('*.html'):
    v=Links();v.feed(p.read_text(encoding='utf-8'));parsers[p.name]=v
    assert len(v.ids)==len(set(v.ids)),('duplicate IDs',p)
refs=0
for name,parser in parsers.items():
    for v in parser.links:
        u=urlsplit(v)
        if u.scheme: continue
        path=unquote(u.path) or name
        assert (O/path).is_file(),(name,v)
        if u.fragment and path in parsers: assert u.fragment in parsers[path].ids,(name,v)
        refs+=1
for kind in ['tutorial','final']:
    original=[b+'\n' for r in records for b in re.findall(r'```gdscript\n(.*?)\n```',r['texts'][kind],re.S)]
    actual=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/(kind+'.html')).read_text(encoding='utf-8'),re.S)]
    assert original==actual,(kind,'rendered code')
optional_original=[s+'\n' for s in re.findall(r'```gdscript\n(.*?)\n```',optional_text,re.S)]
optional_rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'applications.html').read_text(encoding='utf-8'),re.S)]
assert optional_original==optional_rendered, 'optional rendered snippets'
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members=set(z.namelist())
    for name in parsers:
        v=Links();v.feed(z.read(name).decode('utf-8'))
        for ref in v.links:
            u=urlsplit(ref)
            if not u.scheme: assert (unquote(u.path) or name) in members,(name,ref)
    for r in records:
        for kind in ['tutorial','final']:
            relative='halls/'+r['id']+'/'+kind+'.md'
            canonical=R/'commons/maps'/r['id']/(kind+'.md')
            assert canonical.read_bytes()==(O/relative).read_bytes()==z.read(relative),(relative,'canonical copy mismatch')
    assert z.read('halls/LSystems_Grammars_And_Curves/tutorial-applications.md')==optional_source.read_bytes()
for name,digest in sources.items(): assert sha(R/name)==digest,(name,'source changed during publication')
dump(O/'validation.json',{'passed':True,'canonical_hashes':len(sources),'primary_file_parity':code_count,'local_refs_and_anchors':refs,'unique_html_ids':True,'all_rendered_gdscript_blocks_match':True,'optional_notes_retained_intact':True,'reflection_markers_images_and_footnotes_preserved':True,'canonical_hall_copies_match_zip':True,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_tested':False,'new_runtime_test':True,'runtime_scope':'Fresh exact printed programs across all eight lessons:212 checks. Unprescribed quarter-uptake edit:21. Fresh Competition museum render:8. Prior focused turn-reversal:30.','new_whole_sequence_runtime_test':True,'whole_sequence_runtime_scope':'Printed lesson programs, guided edits and supplied poses; not a fresh eight-hall museum traversal.','fresh_museum_halls':['LSystems_Competition'],'independent_learner_test':False})
with zipfile.ZipFile(archive,'a',zipfile.ZIP_DEFLATED) as z: z.write(O/'validation.json','validation.json')
with zipfile.ZipFile(archive) as z: assert z.testzip() is None
print(json.dumps({'published':str(O/'index.html'),'halls':len(records),'code_files':code_count,'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
