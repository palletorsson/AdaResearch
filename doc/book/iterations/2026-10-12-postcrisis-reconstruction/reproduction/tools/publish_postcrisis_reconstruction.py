"""Publish the eight printed lessons and their scoped reconstruction evidence."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
from write_postcrisis_tutorials import ROOT, OUT, STUDY, HALLS, KEYS, TITLES, ELEMENTS

SUMMARIES = [
    'Move the familiar sphere to interpolate six authored word positions. Keep identities and colours fixed; measure changing gaps. Carry Transformation’s interpolation and Arrays’ indices into a question about which distinctions a representation makes available. The example does not train an embedding or measure social bias.',
    'Rearrange six identical seats from rows into a ring. Reuse whole-mesh transformations, arrays, sine and cosine; select a seat with the same sphere and measure the next indexed gap. Then keep the ring still and change an acceptance criterion: the same positions pass one minimum distance and fail another. Equal participation remains a separate question.',
    'Extend Florensky’s support pair into source-tagged records about the same proposition. Select a branch without deleting either account; check that BOTH stays supported and an unrelated Q does not gain support. Selection, retention and inference now have separate operations.',
    'Keep one subject while changing the predicate and address of the displayed claim. Reuse the preceding record class. Cover and reveal the source through a deep copy, proving that presentation has not erased provenance. Authored confidence is labelled as such.',
    'Build a small collection of contributions. Count arrivals, distinct sources, participations and revisions separately. Use the sphere to move a disputed piece while retaining its source and original pose; begin another version without erasing lifetime totals. Revision does not automatically settle the dispute.',
    'Grow a seeded graph from two unlinked points. Compare one earlier neighbour with three at the same positions; cut and restore a node, count active components, and replay. Carry the point and cylinder into explicit adjacency. A graph relation and a walkable passage remain different things.',
    'Reuse that graph to construct the thirteen-joint body. With one carried sphere, select and move a joint or reroute either end of one connection. Convert between display and body coordinates, reject invalid links, and write the latest validated pose. Optionally record a prediction before editing. Carry these actual files into the next hall.',
    'Open the saved student pose in another hall and process. Rebuild it beside the starting body; compare edit count, displacement and connected groups. Optionally finish the prediction with an observation and a reason for keeping the result. The note retains both poses and the original prediction; its structure does not establish the truth of the explanation.'
]

CSS = '''*{box-sizing:border-box}body{margin:0;background:#f0eee8;color:#202c32;font:18px/1.6 system-ui}main{max-width:1200px;margin:auto;padding:32px}main.wide{max-width:1800px}a{color:#17576c}h1{font:clamp(36px,5vw,66px)/1.07 Georgia;max-width:980px}h2{font:32px/1.2 Georgia;margin-top:1.8em}h3{font-size:22px}p{max-width:900px}nav{display:flex;flex-wrap:wrap;gap:16px;padding:16px 0;border-bottom:1px solid #adb9bb;margin-bottom:28px}pre{padding:20px;background:#172b35;color:#edf1ee;overflow:auto;font:14px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;overflow-wrap:anywhere}pre code{font:inherit}.tag{font-size:13px;letter-spacing:.13em;text-transform:uppercase}.lead{font-size:23px}.note{padding:22px;background:#dbe7e5}.cards,.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.card,.pair article{background:#fff;padding:20px;min-width:0}.card h2{margin:.7em 0;font-size:28px}.card p{font-size:17px}.pair article{max-height:84vh;overflow:auto}.pair h1{font-size:38px}.pair pre{font-size:13px}img{display:block;max-width:100%;height:auto}figure{margin:24px 0}figcaption{font-size:15px;color:#485c63}table{border-collapse:collapse;width:100%;font-size:16px}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #b6c3c5}details{margin:22px 0}summary{cursor:pointer;font-weight:650}hr{border:0;border-top:1px solid #b3bfc0;margin:48px 0}@media(max-width:850px){main{padding:18px}.cards,.pair{grid-template-columns:1fr}.pair article{max-height:none}}@media print{nav{display:none}.pair{display:block}.pair article{max-height:none;overflow:visible}pre{white-space:pre-wrap}}'''

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf8')

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def md(text): return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])

def page(title, body, prefix='', wide=False):
    links=[('index.html','Route + report'),('feedback.html','Feedback response'),('ghost.html','Ghost student'),('tutorial.html','Full tutorial'),('final.html','Full reflection'),('parallel.html','Facing pages'),('changes.html','Changes'),('postcrisis-review.zip','Review ZIP')]
    nav=''.join(f'<a href="{prefix}{url}">{label}</a>' for url,label in links)
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><main class="{"wide" if wide else ""}"><nav>{nav}</nav>{body}</main></body></html>'

def main():
    hashes={}
    def copy(source, target):
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
        hashes[source.relative_to(ROOT).as_posix()]=digest(source)
    baseline=json.loads((OUT/'before-hashes.json').read_text())
    unchanged={rel:digest(ROOT/rel)==h for rel,h in baseline.items() if rel!='doc/final_lap_scores.json' and not rel.endswith('/tutorial.md')}
    assert all(unchanged.values()), [p for p,ok in unchanged.items() if not ok]
    write(OUT/'preservation.json',json.dumps(unchanged,indent=2))
    reconstruction=json.loads((OUT/'reconstruction.json').read_text())
    for rel,h in reconstruction['sources'].items(): assert digest(ROOT/rel)==h,rel
    for name,h in reconstruction['files'].items():
        assert hashlib.sha256((OUT/'learner'/name).read_text(encoding='utf8').encode()).hexdigest()==h,name
    ghost=json.loads((OUT/'ghost-results.json').read_text());assert ghost['passed']
    commands=json.loads((OUT/'student-commands.json').read_text());assert len(commands)==8 and all(c['passed'] for c in commands)
    assert all(c['extracted_files']==reconstruction['files'] for c in commands),'Stale individual lesson checks'
    cards=[];pairs=[];diffs=[];evidence=[];collected={'tutorial':[],'final':[]}
    # Retain the one image referenced by the unchanged Assembly reflection.
    illustration=ROOT/'doc/book/figures/postfoundationscrisis/rerouted-connection-three-states.png'
    if not illustration.exists():
        candidates=list(ROOT.glob('**/rerouted-connection-three-states.png'))
        assert candidates,'Assembly reflection image missing'
        illustration=candidates[0]
    copy(illustration,OUT/'images/rerouted-connection-three-states.png')
    for i,(hall,key) in enumerate(zip(HALLS,KEYS)):
        run=ROOT/'ada_run/encounter_pilot'/hall/'postcrisis_reconstruction'
        receipt=json.loads((run/'report.json').read_text());assert receipt['passed'],hall
        assert receipt['observations']['fixed_launcher'],hall
        for rel,h in receipt['observations']['tested_code'].items():assert digest(ROOT/rel.removeprefix('res://'))==h,(hall,rel)
        for rel,h in receipt['runtime_sources'].items():assert digest(ROOT/rel)==h,(hall,rel)
        log=(run/'stdout.log').read_text(encoding='utf8');assert 'SCRIPT ERROR' not in log,hall
        assert 'Viewport Texture must be set' not in log and 'rwex60pqapc' not in log,hall
        warnings=sorted(set(line.strip() for line in log.splitlines() if line.startswith(('WARNING:','ERROR:'))))
        for n in ['report.json','source_manifest.json','stdout.log']:copy(run/n,OUT/'evidence'/hall/n)
        for n in ['opening','result','hall']:copy(run/(n+'.png'),OUT/'images'/(hall+'-'+n+'.png'))
        evidence.append({'hall':hall,'checks':len(receipt['checks']),'passed':True,'mount':receipt['observations']['mount'],'warnings':warnings,'loading_warnings':receipt['loading_warnings'],'runtime_sources':receipt['runtime_sources']})
        texts={};local=OUT/'halls'/hall
        for kind in collected:
            source=ROOT/'commons/maps'/hall/(kind+'.md');raw=source.read_text(encoding='utf8')
            copy(source,OUT/'source'/source.relative_to(ROOT))
            # Bundle-local links: source/ mirrors the original project hierarchy.
            readable=raw.replace('/book-images/figures/postfoundationscrisis/rerouted-connection-three-states.png','../../images/rerouted-connection-three-states.png')
            readable=re.sub(r'\]\(\.\./([^/]+)/tutorial\.md\)',r'](../../source/commons/maps/\1/tutorial.md)',readable)
            readable=readable.replace('](../../../doc/book/studies/','](../../source/doc/book/studies/')
            texts[kind]=readable
            write(local/(kind+'.md'),readable)
            write(local/(kind+'.html'),page(TITLES[i]+' / '+kind,md(readable),'../../'))
            combined=readable.replace('](../../source/','](source/').replace('](../../images/','](images/')
            combined=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+hall+'-'+m[1]+']',combined)
            collected[kind].append(f'<!-- Source: commons/maps/{hall}/{kind}.md -->\n\n'+combined)
            before=(OUT/'before'/source.relative_to(ROOT)).read_text(encoding='utf8')
            if raw!=before:
                diff=''.join(difflib.unified_diff(before.splitlines(True),raw.splitlines(True),fromfile='Before',tofile='After'))
                diffs.append(f'<details><summary>{html.escape(TITLES[i])} / {kind}.md</summary><pre>{html.escape(diff)}</pre></details>')
        copy(ROOT/'commons/maps'/hall/'map_data.json',OUT/'source/commons/maps'/hall/'map_data.json')
        navigation=f'<p>{i+1} / 8'
        if i:navigation+=f' · <a href="../{HALLS[i-1]}/parallel.html">← Previous</a>'
        if i<7:navigation+=f' · <a href="../{HALLS[i+1]}/parallel.html">Next →</a>'
        navigation+='</p>'
        picture=f'<figure><img src="../../images/{hall}-result.png" alt="{html.escape(TITLES[i])}: actual Godot working copy in its museum hall"><figcaption>Native museum capture using the printed code and synthetic controls; not a headset session.</figcaption></figure>'
        pair='<div class="pair"><article><p class="tag">tutorial.md · build and investigate</p>'+md(texts['tutorial'])+'</article><article><p class="tag">final.md · reflection</p>'+md(texts['final'])+'</article></div>'
        write(local/'parallel.html',page(TITLES[i],navigation+f'<details><summary>Inside the hall</summary>{picture}</details>'+pair,'../../',True))
        cards.append(f'<article class="card"><a href="halls/{hall}/parallel.html"><img loading="lazy" src="images/{hall}-result.png" alt="{html.escape(TITLES[i])}"></a><h2>{i+1}. {TITLES[i]}</h2><p>{SUMMARIES[i]}</p><p><b>Learning elements:</b> {" · ".join(ELEMENTS[i])}</p><a href="halls/{hall}/parallel.html">Read both texts →</a></article>')
        pairs.append(f'<li><a href="halls/{hall}/parallel.html">{i+1}. {TITLES[i]}</a></li>')
    # The body actually written in one native process must be the body read by the next.
    a=json.loads((OUT/'evidence'/HALLS[6]/'report.json').read_text())['observations']['saved_record']
    b=json.loads((OUT/'evidence'/HALLS[7]/'report.json').read_text())['observations']['read_record']
    assert a==b,'Cross-process record mismatch'
    saved_note=json.loads((OUT/'evidence'/HALLS[6]/'report.json').read_text())['observations']['saved_prediction']
    synthesis=json.loads((OUT/'evidence'/HALLS[7]/'report.json').read_text())['observations']
    assert saved_note==synthesis['read_prediction'],'Cross-process prediction mismatch'
    assert synthesis['completed_note']['prediction']==saved_note['prediction'] and synthesis['completed_note']['before']==saved_note['before'] and synthesis['completed_note']['after']==a,'Note does not identify tested change'
    write(OUT/'museum-evidence.json',json.dumps(evidence,indent=2))
    for hall in ['Euclid_Parallel','Russell_Paradox','Florensky_Paraconsistent']:
        p=ROOT/'commons/maps'/hall/'tutorial.md';copy(p,OUT/'source'/p.relative_to(ROOT))
    for p in STUDY.iterdir():
        if p.suffix in ['.gd','.tscn']:copy(p,OUT/'source'/p.relative_to(ROOT))
    for p in (ROOT/'tools').glob('*postcrisis*.py'):copy(p,OUT/'reproduction/tools'/p.name)
    for name in ['postcrisis_student.gd','postcrisis_museum.gd','foundations_reconstruction_museum.gd','transformation_encounters.gd']:
        copy(ROOT/'tools/probes'/name,OUT/'reproduction/tools/probes'/name)
    copy(ROOT/'tools/run_encounter_probe.py',OUT/'reproduction/tools/run_encounter_probe.py')
    for rel in ['commons/maps/sequences/postfoundationscrisis.json','doc/book/course/storyboards/POSTCRISIS-READING-PASS.md','doc/final_lap_scores.json']:
        copy(ROOT/rel,OUT/'source'/rel)
    for rel in ['project.godot','addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn','addons/godot-xr-tools/LICENSE']:
        copy(ROOT/rel,OUT/'source'/rel)
    for kind,parts in collected.items():
        text=f'# Post-crisis — complete {kind} sequence\n\nEight halls in the existing Endless Museum. Review snapshot: 12 October 2026.\n\n'+'\n\n---\n\n'.join(parts)
        write(OUT/(kind+'.md'),text);write(OUT/(kind+'.html'),page('Complete '+kind,md(text)))
    write(OUT/'parallel.html',page('Facing pages','<h1>Eight halls, two readings</h1><p>Tutorial on the left. Existing reflection on the right. Each hall has next and previous navigation.</p><ol>'+''.join(pairs)+'</ol>'))
    write(OUT/'changes.html',page('What changed','<h1>Complete working copies</h1><p>All eight tutorials now print their new code, declare earlier dependencies, name the supplied museum launchers and include assertions. The eight final.md texts, hall maps and sequence order are unchanged in this pass. The sphere returns to its selected position after physics; the supplied launchers use measured clear positions.</p>'+''.join(diffs)))
    total=len(ghost['checks']);native=sum(x['checks'] for x in evidence)
    feedback=OUT/'feedback-2026-10-12'
    response=(feedback/'RESPONSE.md').read_text(encoding='utf8')
    feedback_diffs=[]
    for i,hall in enumerate(HALLS):
        before=(feedback/'before/commons/maps'/hall/'tutorial.md').read_text(encoding='utf8')
        after=(ROOT/'commons/maps'/hall/'tutorial.md').read_text(encoding='utf8')
        if before!=after:
            diff=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='Before feedback',tofile='After feedback'))
            feedback_diffs.append(f'<details><summary>{TITLES[i]} / tutorial.md</summary><pre>{html.escape(diff)}</pre></details>')
    loading=[(TITLES[i],w['artifact'],w['milliseconds']) for i,row in enumerate(evidence) for w in row['loading_warnings']]
    load_rows=''.join(f'<tr><td>{hall}</td><td>{artifact}</td><td>{ms} ms</td></tr>' for hall,artifact,ms in loading)
    pictures=''.join(f'<h3>{TITLES[i]}</h3><div class="cards"><figure><img src="feedback-2026-10-12/before-images/{HALLS[i]}-result.png" alt="{TITLES[i]} before feedback"><figcaption>Before this feedback pass.</figcaption></figure><figure><img src="images/{HALLS[i]}-result.png" alt="{TITLES[i]} after feedback"><figcaption>{caption}</figcaption></figure></div>' for i,caption in [(1,'After: the unchanged ring fails the new centre-distance criterion.'),(6,'After: PREDICT records an expectation before the changes.'),(7,'After: Synthesis completes a separate note for the changed body. These inputs are synthetic.')])
    result_note=f'<p class="note">Final revision: {total} model and interaction checks; {native} native checks across all eight halls. All passed. Both reported resource errors are absent. Author-operated reconstruction, not an independent learner or headset test.</p>'
    write(OUT/'feedback.html',page('After the assessment',md(response)+result_note+'<h2>Inside the revised halls</h2>'+pictures+'<h2>Remaining construction stalls</h2><p>Measured during artifact creation in this isolated desktop run. These are not steady-state frame-time measurements.</p><table><tr><th>Hall</th><th>Artifact</th><th>Reported construction</th></tr>'+load_rows+'</table><h2>Changes since the review</h2>'+''.join(feedback_diffs)+'<p><a href="feedback-2026-10-12/external-assessment.md">Original assessment</a> · <a href="feedback-2026-10-12/RESPONSE.md">Response Markdown</a> · <a href="ghost.html">Current test evidence</a></p>'))
    report=(OUT/'review-template.md').read_text(encoding='utf8').replace('{{HEADLESS}}',str(total)).replace('{{NATIVE}}',str(native))
    write(OUT/'REPORT.md',report)
    write(OUT/'REVIEW.md',report)
    rows=''.join(f'<tr><td>{i+1}. {TITLES[i]}</td><td>{x["checks"]} passed</td><td><a href="evidence/{x["hall"]}/report.json">Receipt</a></td></tr>' for i,x in enumerate(evidence))
    write(OUT/'ghost.html',page('Ghost student',md(report)+'<h2>Native receipts</h2><table><thead><tr><th>Hall</th><th>Checks</th><th>Evidence</th></tr></thead><tbody>'+rows+f'</tbody></table><p><a href="reconstruction.json">Extraction and dependency lineage</a> · <a href="ghost-results.json">{total} model and interaction checks</a> · <a href="student-commands.json">Eight individual lesson commands</a> · <a href="museum-evidence.json">Native results and engine warnings</a></p>'))
    opening=f'<p class="tag">Endless Museum · post-crisis · 12 October 2026</p><h1>Keep the distinction.<br>Carry what changed.</h1><p class="lead">Eight complete tutorials. The familiar point becomes a handle for positions, claims, contributions, connections and a body that returns.</p><p class="note"><b>{total} printed-code assertions and interaction checks passed.</b> All eight native museum studies passed {native} checks. An author-operated ghost reconstruction, with synthetic inputs and an actual saved handoff between processes.</p><p>The order holds: representation → arrangement → conflicting accounts → provenance → contribution → connectivity → alteration → return. The substantial new step is the graph in Rhizome. Assembly reuses it; Synthesis adds no replacement model.</p><p><a href="ghost.html">Read the test report and limits</a> · <a href="tutorial.md">Whole tutorial Markdown</a> · <a href="final.md">Whole reflection Markdown</a></p>'
    write(OUT/'index.html',page('Post-crisis: runnable sequence',opening+'<p><a href="feedback.html">After external review: change the criterion, keep an observation →</a></p><div class="cards">'+''.join(cards)+'</div>'))
    write(OUT/'source-hashes.json',json.dumps(hashes,indent=2))
    write(OUT/'README.md',f'''# Post-crisis review package

Open index.html for the route, ghost.html for evidence, or parallel.html for facing pages. tutorial.md and final.md contain the whole sequence. REPORT.md records scope and limitations.

This is a review/extraction package, not a standalone Godot game. Use Godot 4.6 in AdaResearch_46 with the existing XRTools and museum infrastructure. source/ mirrors project paths; learner/ contains the {len(reconstruction['files'])} exact printed and inherited scripts. Eight supplied .tscn launchers and their scripts are under source/doc/book/studies/postcrisis-lineage/. Point their LESSON preload at your reconstructed folder and run with F6. Preserve your working tree when comparing source copies. feedback.html explains the latest revisions, with the assessment, earlier files and logs in feedback-2026-10-12/.

Reproduce from project root with python tools/test_postcrisis_reconstruction.py, then python tools/run_postcrisis_rooms.py. These create private test records; they do not overwrite the installed visitor's Assembly pose. The native runner checks isolated actual halls; full-route walking and headset comfort remain untested.

{total} headless checks and {native} native checks passed. The eight individual assertion commands repeat the model assertions and are not added to those totals. See logs for engine warnings. No claim of independent learner comprehension or ethical validation is made by these tests.
''')
    archive=OUT/'postcrisis-review.zip'
    class Links(HTMLParser):
        def __init__(self): super().__init__(); self.urls=[]
        def handle_starttag(self, tag, attrs):
            self.urls.extend(v for k,v in attrs if k in ['href','src'] and v)
    checked=0
    for path in [*OUT.glob('*.html'),* (OUT/'halls').rglob('*.html')]:
        parser=Links();parser.feed(path.read_text(encoding='utf8'))
        for url in parser.urls:
            parts=urlsplit(url)
            if parts.scheme or parts.netloc or not parts.path or parts.path.startswith('/'):continue
            target=(path.parent/unquote(parts.path)).resolve()
            if target==archive.resolve():continue
            assert target.is_file(),(path,url)
            checked+=1
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and '__pycache__' not in p.parts:z.write(p,p.relative_to(OUT))
    with zipfile.ZipFile(archive) as z:assert z.testzip() is None
    print(f'Published 8 halls: {total} headless + {native} native checks; {checked} local links checked. ZIP {archive.stat().st_size:,} bytes, CRC passed.')

if __name__=='__main__':main()
