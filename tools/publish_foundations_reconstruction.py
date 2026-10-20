"""Publish complete Foundations readings, source copies and scoped native evidence."""
from pathlib import Path
from datetime import datetime,timezone
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from write_foundations_reconstruction import LESSONS
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-foundations-reconstruction'
HALLS=['Euclid_Parallel','NonEuclidean_Spaces']+[row[0] for row in LESSONS]
TITLES=['Euclid','Non-Euclidean Spaces','Russell','Gödel','Escher','Brouwer','Florensky','Synthesis']
REVIEW_DATE='12 October 2026'
SUMMARIES=[
"Carry the point, line and triangle into the existing Euclid hall. Move a corner, measure all three angles and construct a parallel through it. Keep the drawing separate from the measured relation, withhold a reading for a degenerate triangle, then predict an independent change of shape. The resulting coordinate record and renderer travel into the next lesson.",
"Keep the same three coordinate pairs and point instances, but interpret the pairs on a sphere. Draw great-circle samples and measure angles from tangents; compare with the inherited plane. Model switching preserves the record while changing positions and measurements. The larger installed wing remains an encounter beyond this deliberately bounded plane/sphere tutorial.",
"At the membership workbench, carry the same point between OUT and IN. Write the two-case Boolean test and find that neither assumption satisfies the unrestricted demand. Then filter an existing finite ordinal domain, changing its size while checking that the resulting collection lies outside that domain. Carry the distinction between a stated rule, its cases and a restricted construction.",
"Beside the timed sentence machine, build a real but deliberately small derivation checker: start at 0 and add S. Search with a budget, increase it to reach a missed target, then remove a proof step and detect the invalid chain. This decidable toy teaches checking versus bounded search; the reflection supplies the separate hypotheses of Gödel’s theorem.",
"Use the familiar sphere to visit four stored tread centres. Add each signed change in world height; closing the route returns the total to zero. Tilt the arrangement, then open the last link and stop at its end. Compare the measured small route with the installed staircase and perspective works, keeping an apparent connection distinct from a spatial one.",
"Make an array wait for the learner’s next bit. Distinguish absence of 1 in a finite prefix from a claim about all future choices, and retain an explicit index when a witness appears. Then construct a four-row diagonal witness, checking its disagreement at each named position. Keep chosen continuation, finite construction and infinite argument separate.",
"Retain independent support for and against a report, then extend the installed gate’s simple store in the student copy with explicit four-valued negation, conjunction and disjunction. Check the tables and exhibit P=BOTH with Q=NEITHER as a countermodel to explosion under those rules. Preserve the difference between stored reports, truth and a decision about access.",
"Reuse the five preceding model files to make fresh scoped evidence cards. Show each sentence at two sizes and one word at a time; change size, pace and pause without altering its evidence. An AI proposal receives the same presentation but no invented verifier. Bring the record and its limits into the encounter with Ada’s QFEP proposal, which remains open to testing and revision."
]
CSS='''*{box-sizing:border-box}body{margin:0;background:#f1eee6;color:#202a34;font:18px/1.6 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:32px}a{color:#28516b}h1{font:clamp(34px,5vw,64px)/1.08 Georgia,serif;max-width:960px}h2{font:32px/1.2 Georgia,serif;margin-top:2em}h3{font-size:21px}nav{display:flex;flex-wrap:wrap;gap:16px;border-bottom:1px solid #bcc2c5;padding:18px 0;margin-bottom:28px}p{max-width:850px}.lead{font-size:23px}.tag{font:13px system-ui;letter-spacing:.13em;text-transform:uppercase;color:#667581}img{max-width:100%;display:block}figure{margin:24px 0}figcaption{font-size:14px;color:#526371;margin-top:6px}pre{background:#152431;color:#e4edf1;overflow:auto;padding:22px;font:14px/1.55 Consolas,monospace;tab-size:4}code{font: .88em Consolas,monospace;overflow-wrap:anywhere}pre code{font:inherit}table{border-collapse:collapse;width:100%;font-size:16px}th,td{border-bottom:1px solid #bec9cc;padding:12px;text-align:left;vertical-align:top}.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.card{background:#fff;padding:18px}.card h2{margin:.6em 0;font-size:28px}.card p{font-size:16px}.card img{aspect-ratio:3/2;object-fit:cover}.flow,.note{background:#dfe8e9;padding:22px;margin:24px 0}.flow{font-size:21px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:30px}.pair article{min-width:0;max-height:85vh;overflow:auto;background:#fff;padding:26px}.pair h1{font-size:38px}.wide{max-width:1800px}.pair p,.pair li{font-size:17px}.pair pre{font-size:13px}.sticky{position:sticky;top:0;background:#f1eee6;z-index:2;padding:12px 0}.row{display:flex;gap:20px;flex-wrap:wrap}details{margin:16px 0}summary{cursor:pointer;font-weight:650}hr{border:0;border-top:1px solid #b3c1c8;margin:60px 0}.footnote{font-size:14px}@media(max-width:850px){main{padding:18px}.cards,.pair{grid-template-columns:1fr}.pair article{max-height:none}}@media print{nav,.sticky{display:none}.pair{display:block}.pair article{max-height:none;overflow:visible}pre{white-space:pre-wrap}.cards{display:block}}'''

SUMMARIES[3]+=' Before a next-budget trial, record a prediction; carry its actual inputs, candidate, outcome and source identity into Synthesis. The text bridges symbol records to arithmetic encoding without claiming the toy constructs incompleteness.'
SUMMARIES[7]='Import the experiments saved in Gödel, keeping wrong predictions and original model identities. Five reused models also provide clearly labelled reference cards; an AI proposal still has no verifier. Change size, pace and pause without rewriting the evidence. Distinguish models, contradictory demands, search limits, projections, witnesses and conflicting reports; return to an earlier museum artifact with these questions.'

def write(path,text):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text,encoding='utf-8')
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def page(title,body,prefix='',wide=False):
    links=[('index.html','Route + report'),('feedback.html','Latest revision'),('ghost.html','Ghost student'),('tutorial.html','Full tutorial'),('final.html','Full reflection'),('parallel.html','Facing pages'),('changes.html','Changes'),('foundations-review.zip','Review ZIP')]
    nav=''.join(f'<a href="{prefix}{url}">{label}</a>' for url,label in links)
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style><main class="{"wide" if wide else ""}"><nav>{nav}</nav>{body}</main></html>'
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    sources={};evidence=[];changes=[];cards=[];facing=[];collected={'tutorial':[],'final':[]}
    opening=json.loads((OUT/'opening-hashes.json').read_text())
    guard={rel:digest(ROOT/rel)==value for rel,value in opening.items() if rel.endswith('map_data.json') or 'sequences/' in rel or rel.endswith('curriculum_spine.json') or '/Euclid_Parallel/' in rel or '/NonEuclidean_Spaces/' in rel}
    changed=[k for k,v in guard.items() if not v]
    notes=[]
    for rel in changed:
        if rel=='commons/maps/Euclid_Parallel/tutorial.md':
            before=(OUT/'before'/rel).read_text(encoding='utf-8')
            now=(ROOT/rel).read_text(encoding='utf-8')
            expected=before.replace('The supplied `museum.tscn` launcher', 'The supplied `res://doc/book/studies/euclid-lineage/museum.tscn` launcher')
            expected=expected.replace('It is room infrastructure, not a second geometry implementation.', 'To run your reconstructed folder, change the `LESSON` preload in `res://doc/book/studies/euclid-lineage/museum.gd` to your `euclid_study.gd`, then run the launcher scene with F6. It is room infrastructure, not a second geometry implementation.')
            assert now==expected, 'Euclid changed beyond its declared launcher clarification'
            notes.append('The 12 October ghost pass clarifies Euclid\'s launcher path and how it loads reconstructed student code. All printed code is unchanged and has been rerun.')
            continue
        assert rel=='commons/maps/NonEuclidean_Spaces/map_data.json',changed
        before=json.loads((OUT/'before'/rel).read_text(encoding='utf-8'))
        now=json.loads((ROOT/rel).read_text(encoding='utf-8'))
        before['map_info'].pop('description');now['map_info'].pop('description')
        assert before==now,'Concurrent map edit changed more than the description'
        native=json.loads((ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces/foundations_reconstruction/source_manifest.json').read_text())
        assert native['sources'][rel]==digest(ROOT/rel),'Native capture predates current map'
        notes.append('Separate Non-Euclidean work corrected the map description during this pass. Every other map field is unchanged; the latest capture uses the current map. This pass did not edit that description.')
    write(OUT/'preservation.json',json.dumps({'unchanged_from_start':guard,'concurrent_notes':notes},indent=2))
    def register(p):sources[p.relative_to(ROOT).as_posix()]=digest(p)
    def copy(p,target):target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target);register(p)
    first=[('Euclid_Parallel','2026-10-11-euclid-the-same-triangle','euclid-lineage'),('NonEuclidean_Spaces','2026-10-11-noneuclid-what-counts-as-straight','noneuclid-lineage')]
    testsets=[]
    for hall,folder,study in first:
        author=ROOT/'doc/book/iterations'/folder/'author'
        result=json.loads((author/'results.json').read_text());assert result['passed']
        latest=max(author.glob('20*.json'),key=lambda p:p.stat().st_mtime)
        log=latest.with_suffix('.log');assert 'SCRIPT ERROR' not in log.read_text(encoding='utf-8')
        assert json.loads(latest.read_text())['tutorial_sha256']==digest(ROOT/'commons/maps'/hall/'tutorial.md'), 'Opening tutorial changed after its test: '+hall
        for p in [author/'results.json',latest,log]:copy(p,OUT/'evidence'/hall/p.name)
        testsets.append({'hall':hall,'checks':len(result['checks']),'passed':True,'kind':'Exact-print author tests; timestamp '+latest.stem,'receipt':f'evidence/{hall}/results.json'})
    ghost=json.loads((OUT/'ghost-results.json').read_text());assert ghost['passed']
    reconstruction=json.loads((OUT/'reconstruction.json').read_text())
    for rel,value in reconstruction['sources'].items():
        assert digest(ROOT/rel)==value, 'Tutorial changed after reconstruction: '+rel
    testsets.append({'halls':HALLS[2:],'checks':len(ghost['checks']),'passed':True,'kind':ghost['scope'],'receipt':'ghost-results.json'})
    total=sum(t['checks'] for t in testsets)
    write(OUT/'sequence-tests.json',json.dumps({'date':datetime.now(timezone.utc).isoformat(),'total_checks':total,'sets':testsets},indent=2))
    ref=ROOT/'doc/research/qfep/entropic-morality.md';copy(ref,OUT/'references'/ref.name)
    copy(ref,OUT/'source'/ref.relative_to(ROOT))
    for i,hall in enumerate(HALLS):
        local=OUT/'halls'/hall;run=ROOT/'ada_run/encounter_pilot'/hall/'foundations_reconstruction'
        receipt=json.loads((run/'report.json').read_text());assert receipt['passed'],hall
        log=(run/'stdout.log').read_text(encoding='utf-8');assert 'SCRIPT ERROR' not in log,hall
        for n in ['report.json','source_manifest.json','stdout.log']:copy(run/n,OUT/'evidence'/hall/n)
        picture='scalene' if i==0 else 'sphere' if i==1 else 'result'
        above='above' if i<2 else 'hall'
        copy(run/(picture+'.png'),OUT/'images'/(hall+'.png'))
        copy(run/(above+'.png'),OUT/'images'/(hall+'-hall.png'))
        evidence.append({'hall':hall,'checks':len(receipt['checks']),'passed':True,'mount':receipt['observations'].get('mount'),'capture':f'images/{hall}.png','receipt':f'evidence/{hall}/report.json'})
        texts={}
        for kind in ['tutorial','final']:
            p=ROOT/'commons/maps'/hall/(kind+'.md');raw=p.read_text(encoding='utf-8');copy(p,OUT/'source'/p.relative_to(ROOT))
            texts[kind]=raw.replace('../../../doc/research/qfep/entropic-morality.md','../../references/entropic-morality.md')
            write(local/(kind+'.md'),texts[kind])
            write(local/(kind+'.html'),page(TITLES[i]+' / '+kind,md(texts[kind]),'../../'))
            combined=raw.replace('../../../doc/research/qfep/entropic-morality.md','references/entropic-morality.md')
            # Distinct footnotes when eight canonical chapters are compiled together.
            combined=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+hall+'-'+m[1]+']',combined)
            collected[kind].append(f'<!-- Source: commons/maps/{hall}/{kind}.md -->\n\n'+combined)
            before=(OUT/'before/commons/maps'/hall/(kind+'.md')).read_text(encoding='utf-8')
            if raw!=before:
                diff=''.join(difflib.unified_diff(before.splitlines(True),raw.splitlines(True),fromfile='Before',tofile='After'))
                changes.append(f'<details><summary>{html.escape(TITLES[i])} / {kind}.md</summary><pre>{html.escape(diff)}</pre></details>')
        copy(ROOT/'commons/maps'/hall/'map_data.json',OUT/'source/commons/maps'/hall/'map_data.json')
        control='<p class="sticky">'
        if i:control+=f'<a href="../{HALLS[i-1]}/parallel.html">← {TITLES[i-1]}</a> · '
        control+=f'{i+1} / 8'
        if i<7:control+=f' · <a href="../{HALLS[i+1]}/parallel.html">{TITLES[i+1]} →</a>'
        control+='</p>'
        pair='<div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+md(texts['tutorial'])+'</article><article><p class="tag">final.md · reflection</p>'+md(texts['final'])+'</article></div>'
        figure=f'<details><summary>See the working copy inside this hall</summary><img src="../../images/{hall}.png" alt="Native Godot capture of {html.escape(TITLES[i])}"><p>Printed lesson mounted in the existing museum. Synthetic controls, not a headset session.</p></details>'
        write(local/'parallel.html',page(TITLES[i]+' / facing pages',control+figure+pair,'../../',True))
        cards.append(f'<article class="card"><a href="halls/{hall}/parallel.html"><img loading="lazy" src="images/{hall}.png" alt="{html.escape(TITLES[i])} working copy inside the museum"></a><h2>{i+1}. {TITLES[i]}</h2><p>{SUMMARIES[i]}</p><a href="halls/{hall}/parallel.html">Read both texts →</a> · <a href="images/{hall}-hall.png">Room from above</a></article>')
        facing.append(f'<li><a href="halls/{hall}/parallel.html">{i+1}. {TITLES[i]}</a></li>')
    for kind,parts in collected.items():
        raw=f'# Foundations Crisis — complete {kind} sequence\n\nEight halls in the existing Endless Museum. Review snapshot, {REVIEW_DATE}.\n\n'+'\n\n---\n\n'.join(parts)
        write(OUT/(kind+'.md'),raw);write(OUT/(kind+'.html'),page('Complete '+kind,md(raw)))
    write(OUT/'parallel.html',page('Eight pairs of facing pages','<h1>Make a claim.<br>Keep what supports it.</h1><p>Tutorial on the left; reflection on the right. Each hall has previous and next navigation.</p><ol>'+''.join(facing)+'</ol>'))
    write(OUT/'changes.html',page('Changes in this pass','<h1>Before → after</h1><p>Six legacy tutorial sketches become complete reconstructions. Their reflections keep the existing arguments, clarify their computational scope, and remove unnecessary code excerpts. Euclid now names its launcher path and how to load a reconstructed folder; its printed code and the Non-Euclidean text are retained.</p><p>The Non-Euclidean working-copy launcher moved from (13,1,7) to (8,1,11), freeing the new wing entrance. The production hall, wing and geometry lesson are unchanged.</p>'+''.join(changes)))
    write(OUT/'museum-evidence.json',json.dumps(evidence,indent=2))
    # Source copies at original relative paths support reconstruction in the prepared Ada project.
    for folder in ['euclid-lineage','noneuclid-lineage','foundations-lineage']:
        for p in (ROOT/'doc/book/studies'/folder).iterdir():
            if p.suffix in ['.gd','.tscn']:copy(p,OUT/'source'/p.relative_to(ROOT))
    for pattern in ['*foundations*.py','test_euclid_lesson.py','test_noneuclid_lesson.py']:
        for p in (ROOT/'tools').glob(pattern):
            if 'graph_' not in p.name and (p.name in ['test_euclid_lesson.py','test_noneuclid_lesson.py'] or p.name in ['write_foundations_reconstruction.py','revise_foundations_reflections.py','build_foundations_launchers.py','run_foundations_rooms.py','test_foundations_reconstruction.py','publish_foundations_reconstruction.py']):copy(p,OUT/'reproduction'/p.relative_to(ROOT))
    for name in ['foundations_student.gd','foundations_reconstruction_museum.gd','foundations_surface_museum.gd','euclid_lesson_test.gd','noneuclid_lesson_test.gd','euclid_lesson_museum.gd','noneuclid_lesson_museum.gd','transformation_encounters.gd']:
        p=ROOT/'tools/probes'/name;copy(p,OUT/'reproduction'/p.relative_to(ROOT))
    copy(ROOT/'tools/run_encounter_probe.py',OUT/'reproduction/tools/run_encounter_probe.py')
    copy(ROOT/'commons/maps/sequences/foundationscrisis.json',OUT/'source/commons/maps/sequences/foundationscrisis.json')
    copy(ROOT/'doc/book/course/storyboards/FOUNDATIONS-RECONSTRUCTION-PASS.md',OUT/'PLAN.md')
    review=(OUT/'REVIEW.md').read_text(encoding='utf-8')
    overview='<p class="tag">Endless Museum · Foundations Crisis · '+REVIEW_DATE+'</p><h1>What lets us claim<br>that something follows?</h1><p class="lead">Eight halls. The familiar point returns, while the kind of evidence changes.</p><div class="flow">Model → demand → derivation → route → witness → consequence → warrant</div><p><strong>'+str(total)+' printed-code checks recorded across both passes.</strong> Eight halls with passing native receipts, '+str(sum(x['checks'] for x in evidence))+' checks. Author-operated reconstruction with synthetic inputs.</p><p class="note"><a href="feedback.html">New: carry your own experiment from Gödel into Synthesis →</a></p>'
    revision=(OUT/'feedback-2026-10-12/RESPONSE.md').read_text(encoding='utf-8')
    pictures=''.join(f'<figure><img src="images/{h}.png" alt="{h} with the revised experiment journal"><figcaption>Actual museum working copy. Synthetic trial; {REVIEW_DATE}. <a href="halls/{h}/parallel.html">Read tutorial and reflection</a>.</figcaption></figure>' for h in ['Godel_Incompleteness','Crisis_Synthesis'])
    revision_diffs=[]
    for h in ['Godel_Incompleteness','Crisis_Synthesis']:
        for kind in ['tutorial','final']:
            rel=Path('commons/maps')/h/(kind+'.md')
            old=(OUT/'feedback-2026-10-12/before'/rel).read_text(encoding='utf-8')
            now=(ROOT/rel).read_text(encoding='utf-8')
            diff=''.join(difflib.unified_diff(old.splitlines(True),now.splitlines(True),fromfile='Before feedback',tofile='After feedback'))
            revision_diffs.append(f'<details><summary>{h} / {kind}.md</summary><pre>{html.escape(diff)}</pre></details>')
    write(OUT/'feedback.html',page('An experiment travels',md(revision)+pictures+'<h2>Focused before / after</h2>'+''.join(revision_diffs)+'<p><a href="feedback-2026-10-12/PREDICTIONS.md">Predictions before the run</a> · <a href="feedback-2026-10-12/first-run-errors.log">First-run faults</a></p>'))
    ghost_pass=ROOT/'doc/book/iterations/2026-10-12-foundations-ghost-student'
    for p in ghost_pass.rglob('*'):
        if p.is_file() and p.suffix not in ['.uid','.import']:
            copy(p,OUT/'ghost-2026-10-12'/p.relative_to(ghost_pass))
    write(OUT/'ghost.html',page('Foundations Crisis / ghost student',md((ghost_pass/'REPORT.md').read_text(encoding='utf-8'))))
    write(OUT/'index.html',page('Foundations Crisis / full review',overview+'<div class="cards">'+''.join(cards)+'</div>'+md(review)+'<p><a href="sequence-tests.json">Code results</a> · <a href="museum-evidence.json">Museum results</a> · <a href="GHOST-PREDICTIONS.md">Predictions before execution</a> · <a href="PLAN.md">Editable plan snapshot</a> · <a href="README.md">Reproduction</a></p>'))
    write(OUT/'summaries.md','# Foundations Crisis — one paragraph per hall\n\n'+'\n\n'.join(f'## {title}\n\n{summary}' for title,summary in zip(TITLES,SUMMARIES)))
    write(OUT/'README.md',f'''# Foundations Crisis review

Open index.html for the eight-hall route, native images and report. parallel.html gives full tutorial/final facing pages. tutorial.md and final.md collect the complete readings; summaries.md has one paragraph per hall. Changes and before/ preserve the starting texts. The source/ folder keeps exact canonical sources and supplied museum launchers at repository-relative paths. Reading copies adjust one local research link and namespace footnotes.

This is not a standalone game. Use the existing AdaResearch_46 project with Godot 4.6, XR Tools and museum dependencies. The six new lessons share doc/book/studies/foundations-lineage/; run each named .tscn with F6. The first two keep their existing euclid-lineage/ and noneuclid-lineage/ folders. Complete new code is visible in tutorial.md; carried dependencies are explicitly named. Only the small museum launcher and installed push-button/player infrastructure are supplied.

From the repository root:

    python -X utf8 tools/test_euclid_lesson.py
    python -X utf8 tools/test_noneuclid_lesson.py
    python tools/test_foundations_reconstruction.py
    python tools/run_foundations_rooms.py

The native first two hall runs use tools/run_encounter_probe.py with --sequence foundationscrisis --render --no-bridges --output-tag foundations_reconstruction, and --probe tools/probes/euclid_lesson_museum.gd or tools/probes/foundations_surface_museum.gd. The command takes the map ID first. Run tools/publish_foundations_reconstruction.py to rebuild this package after all checks. The reproduction/ directory retains these tools; source/ retains lessons and launchers. They expect their stated paths inside the prepared repository, not an extracted ZIP as project root.

{total} author-operated exact-print checks passed in the 12 October ghost rerun: 23 Euclid, 32 Non-Euclidean and 76 across the six later lessons. All eight halls also have fresh passing native receipts in this pass; see ghost.html for the hall-by-hall results and reading investigation. Native checks exercise actual button signals, floor/solid clearance and rendered working copies; they are synthetic. No blind new student, human headset reach, full walking route, Quest performance or proof of learning is claimed. Earlier independent ghost work on the opening two halls remains in its original review folders and is not counted as new here.

The 12 October feedback revision is in feedback.html, with its focused before/after texts and fault log. The printed Gödel study saves to user://ada_foundations_trials_v1.json. Synthesis reads the actual saved trials alongside six reference cards. Tests use synthetic-trials.json, synthetic-controls.json and native-synthetic-trials.json under this review folder, never the visitor's default journal. Run the native Gödel probe before Synthesis to create its synthetic source record.

Review the fit between the implemented operation and its words. Ask whether each independent variation demonstrates transferable understanding. Distinguish the finite executable model from the mathematical theorem and the reflective association. Keep the installed Non-Euclidean wing in view: its expanded tutorial remains a separate pending decision.
''')
    write(OUT/'source-register.json',json.dumps(sources,indent=2))
    package=OUT/'foundations-review.zip'
    with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ['.zip','.uid','.import'] and '__pycache__' not in p.parts:z.write(p,p.relative_to(OUT))
    with zipfile.ZipFile(package) as z:assert z.testzip() is None
    print('Published',len(HALLS),'halls;',total,'code checks;',sum(x['checks'] for x in evidence),'native checks;',round(package.stat().st_size/1024**2,1),'MiB')

if __name__=='__main__':main()
