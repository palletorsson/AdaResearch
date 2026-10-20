"""Build a complete, offline-readable ML review from canonical texts and receipts."""
from pathlib import Path
from datetime import datetime, timezone
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from review_ml_sequence import ROOT, OUT, HALLS
from publish_ml_pose_lesson import CSS

TITLES = ['Evolution', 'Gradient Landscape', 'Classification', 'Neural Networks', 'Perception', 'Sequence Memory', 'Generative', 'Synthesis']
JOBS = ['Conditions select', 'A chosen loss', 'A group made', 'Weights fitted', 'A pose taught', 'A phrase kept', 'A variation sampled', 'An intention checked']

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def md(text):
    return markdown.markdown(text, extensions=['fenced_code','tables','footnotes'])

def page(title, body, prefix='', wide=False):
    extra = '.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(285px,1fr));gap:22px}.cards article{background:#1b2330;padding:18px}.cards h2{font-size:24px;margin:16px 0}.cards p{font-size:16px}.cards img{aspect-ratio:3/2;object-fit:cover}.flow{background:#092629;padding:25px;white-space:pre-wrap}.sticky{position:sticky;top:0;background:#11151ded;z-index:5}.pair{align-items:start}.pair>article{max-height:86vh}code{overflow-wrap:anywhere}'
    nav = ' · '.join(f'<a href="{prefix}{url}">{label}</a>' for url,label in [('index.html','Route & report'),('tutorial.html','Complete tutorial'),('final.html','Complete reflection'),('parallel.html','Facing pages'),('changes.html','Changes'),('lineage.html','Editable plan'),('ml-sequence-review.zip','Review ZIP')])
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}{extra}</style></head><body><main class="{"wide" if wide else ""}"><p class="eyebrow">Endless Museum / eight ML halls / 11 October 2026</p><nav>{nav}</nav>{body}</main></body></html>'

def convert(text, hall, combined=False, html_links=False):
    text = text.replace('/book-images/figures/machinelearning/fresh-ground-runs-out.png', ('images/' if combined else '../../images/')+'fresh-ground-runs-out.png')
    for target,*_ in HALLS:
        dest = f'halls/{target}/tutorial.md' if combined else f'../{target}/tutorial.md'
        if html_links: dest = dest.removesuffix('.md')+'.html'
        text = text.replace(f'../{target}/tutorial.md',dest)
    return text

def main():
    tests=json.loads((OUT/'sequence-tests.json').read_text(encoding='utf-8'))
    handoff=json.loads((OUT/'handoff-tests.json').read_text(encoding='utf-8'))
    assert tests['passed'] and handoff['passed']
    images=OUT/'images'; images.mkdir(exist_ok=True)
    shutil.copy2(ROOT/'doc/book/figures/machinelearning/fresh-ground-runs-out.png',images/'fresh-ground-runs-out.png')
    sources={}
    def register(path):
        sources[path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    content={'tutorial':[], 'final':[]}
    facing=[]; cards=[]; changes=[]; evidence=[]
    for i,(hall,suffix,report,study,picture) in enumerate(HALLS):
        run=ROOT/'ada_run/encounter_pilot'/hall/(suffix+'_lesson')
        receipt=json.loads((run/'report.json').read_text(encoding='utf-8'))
        assert receipt['passed'] and not receipt['failures']
        log=(run/'stdout.log').read_text(encoding='utf-8',errors='replace')
        assert 'SCRIPT ERROR' not in log
        local=OUT/'halls'/hall; local.mkdir(parents=True,exist_ok=True)
        ev=OUT/'evidence'/hall
        shutil.copy2(run/'report.json',ev/'museum-tests.json')
        write(ev/'museum-diagnostics.json',json.dumps([line for line in log.splitlines() if line.startswith(('ERROR:','WARNING:'))],indent=2))
        shutil.copy2(run/(picture+'.png'),images/(hall+'.png'))
        register(run/'report.json');register(run/(picture+'.png'))
        pass_origin = 'rerun after external feedback' if suffix in ['evolution','network'] else ('rerun after whole-route position fix' if suffix=='gradient' else 'retained individual hall run')
        evidence.append({'hall':hall,'checks':len(receipt['checks']),'pass':pass_origin,'native_png':f'images/{hall}.png'})
        texts={}
        for kind in ['tutorial','final']:
            source=ROOT/'commons/maps'/hall/(kind+'.md'); register(source)
            raw=source.read_text(encoding='utf-8')
            texts[kind]=convert(raw,hall,html_links=True)
            write(local/(kind+'.md'),convert(raw,hall))
            write(local/(kind+'.html'),page(TITLES[i]+' / '+kind,md(texts[kind]),'../../'))
            content[kind].append(f'<!-- Canonical chapter: commons/maps/{hall}/{kind}.md -->\n\n'+convert(raw,hall,combined=True))
            before=(OUT/'before'/hall/(kind+'.md')).read_text(encoding='utf-8')
            if before!=raw:
                diff=''.join(difflib.unified_diff(before.splitlines(True),raw.splitlines(True),fromfile='Before',tofile='Now'))
                changes.append(f'<h2>{html.escape(TITLES[i])} / {kind}</h2><pre>{html.escape(diff)}</pre>')
        controls='<p class="sticky">'
        if i: controls+=f'<a href="../{HALLS[i-1][0]}/parallel.html">← {TITLES[i-1]}</a> · '
        controls+=f'{i+1} / 8'
        if i<7: controls+=f' · <a href="../{HALLS[i+1][0]}/parallel.html">{TITLES[i+1]} →</a>'
        controls+='</p>'
        pair='<div class="pair"><article><p class="eyebrow">Tutorial / build and investigate</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Reflection / final.md</p>'+md(texts['final'])+'</article></div>'
        write(local/'parallel.html',page(TITLES[i]+' / facing pages',controls+pair,'../../',True))
        facing.append(f'<li><a href="halls/{hall}/parallel.html">{i+1}. {TITLES[i]} — {JOBS[i]}</a></li>')
        cards.append(f'<article><a href="halls/{hall}/parallel.html"><img loading="lazy" src="images/{hall}.png" alt="{html.escape(TITLES[i])} printed lesson rendered inside the actual museum"></a><h2>{i+1}. {TITLES[i]}</h2><p>{JOBS[i]} · {tests["lessons"][i]["checks"]} reconstruction checks</p><a href="halls/{hall}/parallel.html">Read both texts →</a></article>')
        study_dir=ROOT/'doc/book/studies'/study
        for path in study_dir.glob('*.gd'): register(path)
        # These launchers are supplied museum infrastructure, not hidden lesson code.
        supplied=OUT/'supplied-museum'/study; supplied.mkdir(parents=True,exist_ok=True)
        for path in list(study_dir.glob('*.tscn'))+list(study_dir.glob('*_museum.gd')):
            shutil.copy2(path,supplied/path.name);register(path)
        for path in [ROOT/f'tools/test_ml_{suffix}_lesson.py',ROOT/f'tools/probes/ml_{suffix}_lesson_test.gd',ROOT/f'tools/probes/ml_{suffix}_lesson_museum.gd']:
            if path.exists():
                register(path); destination=OUT/'reproduction'/path.relative_to(ROOT);destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,destination)
    for kind in content:
        combined='# Machine Learning — complete '+('tutorial' if kind=='tutorial' else 'reflective sequence')+'\n\nEight halls of the existing Endless Museum. Review snapshot, 11 October 2026.\n\n'+'\n\n---\n\n'.join(content[kind])
        write(OUT/(kind+'.md'),combined)
        write(OUT/(kind+'.html'),page('Complete ML '+kind,md(combined.replace('/tutorial.md','/tutorial.html'))))
    write(OUT/'parallel.html',page('Eight pairs of facing pages','<h1>Build on the left.<br>Reflect on the right.</h1><p>Each hall keeps the full code and its reflective encounter together, with previous and next navigation.</p><ol>'+''.join(facing)+'</ol>'))
    write(OUT/'changes.html',page('Whole-route changes','<h1>What changed in this pass</h1><p>Changes to the canonical texts from the saved beginning-of-pass versions. Other passages remain intact.</p>'+''.join(changes)))
    plan=ROOT/'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md';register(plan)
    shutil.copy2(plan,OUT/'ML-SPHERE-LINEAGE.md')
    write(OUT/'lineage.html',page('Editable route snapshot',md(plan.read_text(encoding='utf-8'))+'<p class="note">Edit the canonical file named above; this page is a dated snapshot.</p>'))
    write(OUT/'museum-evidence.json',json.dumps(evidence,indent=2))
    review=(OUT/'REVIEW.md').read_text(encoding='utf-8')
    flow='<div class="flow">Conditions → loss → grouping → weights → poses → phrases → variation → evaluation<br><br>Memory ONE ──→ Generative / source → mean → sample<br>Memory A/B ──→ Synthesis / intention → fresh check → journal</div>'
    body='<h1>What the sphere carries.</h1><p class="lead">Eight halls. One recognisable body, changing roles. Complete runnable tutorials beside their reflective texts.</p>'+flow+'<div class="cards">'+''.join(cards)+'</div>'+md(review)
    body+=f'<p><a href="sequence-tests.json">{tests["total_checks"]} printed-code checks</a> · <a href="handoff-tests.json">{len(handoff["checks"])} saved-data checks</a> · <a href="museum-evidence.json">Museum evidence</a> · <a href="README.md">Reproduction and review instructions</a></p>'
    feedback=ROOT/'doc/book/iterations/2026-10-11-ml-feedback'
    if (feedback/'RESPONSE.md').exists():
        for name in ['RESPONSE.md','artifact-tests.json','ML-HUMAN-PILOT.md','ML-HUMAN-PILOT.csv']:
            shutil.copy2(feedback/name,OUT/name)
        for name in ['input-audit.png','renewal-clock.png']: shutil.copy2(feedback/name,images/name)
        write(OUT/'feedback.html',page('ML / feedback response',md((feedback/'RESPONSE.md').read_text(encoding='utf-8'))+'<figure><img src="images/input-audit.png" alt="Actual network disclosure panel"><figcaption>The revised artifact in the museum.</figcaption></figure><p><a href="pilot.html">Proposed human pilot</a> · <a href="artifact-tests.json">Production-artifact checks</a></p>'))
        write(OUT/'pilot.html',page('ML / human pilot',md((OUT/'ML-HUMAN-PILOT.md').read_text(encoding='utf-8'))+'<p><a href="ML-HUMAN-PILOT.csv">Blank observation sheet</a></p>'))
        body='<div class="card">Revised after external feedback. <a href="feedback.html">Read the response and changes</a> · <a href="pilot.html">Proposed human pilot</a></div>'+body
    write(OUT/'index.html',page('ML whole-route review',body))
    readme='''# Eight Machine Learning halls — review bundle

Open index.html for the route, actual museum images and review. Open parallel.html to read each tutorial on the left and final.md on the right. tutorial.md and final.md contain the complete sequences as separate files; halls/ holds each chapter. Links and Evolution's figure are made relative for offline reading; the source register hashes the canonical repository originals.

learner/ contains exact printed Godot files for every hall, including each declared carried dependency. This is not a standalone Godot project. It requires the existing AdaResearch_46 project, Godot 4.6, XR Tools, museum runtime and RackTemplates. Put the chapter's files in its documented res://doc/book/studies/ folder and use its supplied museum launcher. supplied-museum/ includes those launchers. Existing room artifacts remain in the full project.

Inside that project, run:

    python tools/review_ml_sequence.py
    python tools/test_ml_feedback_artifacts.py
    python tools/publish_ml_sequence_review.py

The first command reconstructs all eight tutorials, compares extracted files to working studies, runs their native Godot assertions, and exercises the ONE and A/B file handoffs. Reproduction scripts are retained under reproduction/ at their repository paths; probes expect the dated review folders at the same paths as in Ada. The native room captures require tools/run_encounter_probe.py and the existing museum. This ZIP contains evidence from their individual runs; it does not include the entire game or a headset test.

Read REVIEW.md for what changed and what remains untested. The new handoff probe uses private fixture files under this review directory, not the visitor's saves. Reports label synthetic inputs and author-informed reconstruction explicitly. Feedback should distinguish numerical behaviour, sufficiency of explanation, progression, reflective claims and physical usability.
'''
    write(OUT/'README.md',readme)
    for rel in ['tools/review_ml_sequence.py','tools/publish_ml_sequence_review.py','tools/probes/ml_sequence_handoff_test.gd','tools/probes/movement_fixture.gd','tools/publish_ml_pose_lesson.py','tools/test_ml_feedback_artifacts.py','tools/probes/ml_feedback_artifacts_test.gd','tools/publish_ml_feedback.py','algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.gd','algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.gd']:
        path=ROOT/rel;register(path);dest=OUT/'reproduction'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
    write(OUT/'source-register.json',json.dumps(sources,indent=2))
    package=OUT/'ml-sequence-review.zip'
    with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(OUT.rglob('*')):
            if path.is_file() and path.suffix not in ['.zip','.uid','.import'] and not path.name.endswith('-debug.json') and '__pycache__' not in path.parts:
                archive.write(path,path.relative_to(OUT))
    with zipfile.ZipFile(package) as archive: assert archive.testzip() is None
    print('Published',len(HALLS),'halls;',tests['total_checks'],'+',len(handoff['checks']),'fresh assertions;',sum(row['checks'] for row in evidence),'museum checks')
    print(package,round(package.stat().st_size/1024/1024,1),'MiB')

if __name__=='__main__': main()
