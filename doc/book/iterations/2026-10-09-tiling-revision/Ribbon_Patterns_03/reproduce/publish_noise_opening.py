"""Publish a source-linked first Noise revision with native evidence and facing pages."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-noise-revision/Random_Noise_Types'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def md(s):
    s=s.replace('../../artifacts/geometry_noise/tutorial.md','http://localhost:3003/book-review/commons/artifacts/geometry_noise/tutorial.md')
    s=s.replace('../../artifacts/related_weather/README.md','http://localhost:3003/book-review/commons/artifacts/related_weather/README.md')
    return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])

def page(title,body,wide=False):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title>
<style>*{{box-sizing:border-box}}html{{background:#ece8e0;color:#262a28}}body{{margin:0;font:19px/1.65 Georgia,serif}}main{{max-width:{'1700' if wide else '1080'}px;margin:auto;padding:36px}}nav,.meta,table,summary{{font:14px/1.5 system-ui}}nav{{display:flex;flex-wrap:wrap;gap:18px;border-bottom:1px solid #b9c4bb;padding-bottom:20px;margin-bottom:30px}}a{{color:#315d55}}h1{{font-size:clamp(36px,5vw,62px);line-height:1.06;max-width:950px}}h2{{font-size:29px;line-height:1.2;margin-top:1.6em}}h3{{font-size:23px}}.kicker{{text-transform:uppercase;letter-spacing:.1em;color:#4b6455}}.pair{{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:32px}}.sheet{{min-width:0;background:#faf8f3;padding:30px;border-top:4px solid #415c51}}.sheet h1{{font-size:39px}}pre{{padding:18px;background:#182b29;color:#e8f1e5;font:13px/1.5 Consolas,monospace;overflow:auto;tab-size:4}}code{{font-size:.84em}}pre code{{font-size:inherit}}img{{max-width:100%;height:auto;display:block}}figure{{margin:24px 0}}figcaption{{font:14px/1.5 system-ui;margin-top:8px;color:#516357}}td,th{{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #c4cdc4}}table{{width:100%;border-collapse:collapse}}details{{margin:24px 0}}.status{{padding:16px 20px;border-left:4px solid #426956;background:#e1e9df}}.diff{{white-space:pre;max-height:700px}}@media(max-width:850px){{main{{padding:22px}}.pair{{grid-template-columns:1fr}}.sheet{{padding:20px}}}}@media print{{nav{{display:none}}body{{font-size:11pt}}pre{{white-space:pre-wrap;font-size:8pt}}.pair{{display:block}}.sheet{{break-before:page}}}}</style>
<main><nav><a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="../plan.html">Noise route</a><a href="noise-opening-review.zip">Review ZIP</a></nav>{body}</main></html>'''

def main():
    tests=json.loads((OUT/'tests.json').read_text());faults=json.loads((OUT/'mutations.json').read_text())
    assert tests['all_passed'] and faults['all_rejected']
    run=ROOT/'ada_run/encounter_pilot/Random_Noise_Types/noise-lesson-student'
    native=json.loads((run/'report.json').read_text());assert native['passed']
    dest=OUT/'museum/after';dest.mkdir(parents=True,exist_ok=True)
    for n in ['report.json','engine.log','encounter.png','overhead.png','crowded.png','student.png','source_manifest.json']:
        shutil.copy2(run/n,dest/n)
    sources=[];tracks={};diffs=[]
    prediction=json.loads((OUT/'prediction.json').read_text())
    assert prediction['source_sha256']==sha(ROOT/'commons/maps/Random_Noise_Types/tutorial.md')
    for track in ['tutorial','final']:
        p=ROOT/'commons/maps/Random_Noise_Types'/(track+'.md')
        sources.append({'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)})
        text=p.read_text(encoding='utf8');tracks[track]=text
        (OUT/(track+'.md')).write_text(text,encoding='utf8')
        before=(OUT/'before'/(track+'.md')).read_text(encoding='utf8')
        delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+track+'.md',tofile='after/'+track+'.md'))
        (OUT/(track+'.diff')).write_text(delta,encoding='utf8')
        diffs.append(f'<h2>{track}.md</h2><pre class="diff">{html.escape(delta)}</pre>')
        (OUT/(track+'.html')).write_text(page('Noise · '+track,md(text)),encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S))
    for name,code in blocks.items():
        p=OUT/'learner/printed'/name
        assert p.read_text()==code+'\n' and sha(p)==prediction['files'][name]
    assert (ROOT/'commons/maps/Random_Noise_Types/map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes(),'Hall changed concurrently; inspect before publishing.'
    assert tracks['tutorial'].split('## Optional experiment:')[1]==(OUT/'before/tutorial.md').read_text().split('## Optional experiment:')[1]
    (OUT/'sources.json').write_text(json.dumps(sources,indent=2)+'\n')
    code_links=' · '.join(f'<a href="learner/printed/{n}">{n}</a>' for n in blocks)
    (OUT/'parallel.html').write_text(page('Noise · tutorial / reflection',f'<p class="meta kicker">Noise 01 / Random Noise Types</p><p>One operation to reconstruct; a wider field to reflect on. {code_links}</p><div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>{md(tracks["tutorial"])}</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>{md(tracks["final"])}</article></div>',True),encoding='utf8')
    (OUT/'changes.html').write_text(page('Noise · what changed','<h1>From fragments to a working cloud</h1><p>The canonical tutorial now reconstructs one operation. The reflection retains every encounter; its code blocks have become prose. The optional Uncertain Surface section is unchanged.</p>'+''.join(diffs)),encoding='utf8')
    before_code=(OUT/'before/tutorial.md').read_text().count('```gdscript')
    report=f'''# A place is still a request

Noise · first hall revised · 9 October 2026

Randomness taught us to draw, retain and replay values. Noise begins by making a proposed position depend on the points already admitted. The same PointBody returns as a cloud you can carry apart after construction.

The tutorial now gives the complete two-file reconstruction: local generator, position list, spacing test, per-place attempt budget, readable counts and the familiar held-point action. It keeps three accounts distinct: accepted points, refused candidates and unfilled places. A finite unsuccessful search does not prove maximal packing.

The reflective text retains the plane, paired clouds, needle field, sound comparisons, Related Weather and the optional Uncertain Surface. Code blocks have become prose so the reflection can keep its own rhythm. The optional surface tutorial is unchanged. Museum artifacts, scene logic and sequence order were not edited in this pass.

## What passed

- **{tests['checks']} Godot assertions:** {tests['results'][0]['checks']} on the exact printed reconstruction and {tests['results'][1]['checks']} on a separately edited deeper cloud. The inherited point source is unchanged apart from text line endings.
- **Five faulty programs rejected by assertions:** no reseed, missing break, missing distance rule, lost refusal count and a restore that resamples. These were executable faults, not parse errors.
- **{len(native['checks'])} museum checks:** installed behavior, generated positions after physics frames, a supported and unobstructed learner approach, and simulated XR Tools pickup, movement, release and control action. Captures below come from the real museum.

The ghost student's prediction was saved before execution. Increasing the depth changes the first point's Z while keeping X and Y; later admissions can change because distances change. A separate impossible-spacing case correctly reports one accepted point, four unfilled places and twenty-eight refusals. Restore keeps the existing point identities and consumes no draw.

## What the test caught

The first museum probe compared live physics positions with exact generated coordinates and failed on sub-micrometre rounding. It now compares the saved generation record for exact replay. More importantly, the first student capture showed misplaced bodies despite passing immediate construction checks. Moving the host before creation was insufficient. The lesson now assigns each body's initial position before adding it to the tree, which passed the museum run. The probe checks displayed positions after physics frames, not just immediately after construction. Earlier receipts and failed captures remain in attempts/.

This is an author-informed ghost-student run. It does not demonstrate human learning, physical headset comfort or Quest performance. The native log still reports the hall's existing blocked authored entry and safe fallback, plus unrelated project warnings. The local working bay is tested; the entire Noise route and entry arrangement are not certified by this lesson.

## The next room

**Noise Columns:** keep the column recipe fixed and compare a held value, a sine and a field-derived value. What receives a value is the next subject. The other seven halls remain plans and existing encounter texts until their printed reconstructions are tested.

Read the [facing pages](parallel.html), [source changes](changes.html), [test receipts](tests.json), [fault checks](mutations.json), [museum receipt](museum/after/report.json), and [eight-hall plan](../plan.html).
'''
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    images=''.join(f'<figure><img src="museum/after/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in [
        ('encounter','Installed artifact: two shallow slabs, one stream continued through two admission rules.'),
        ('student','Exact printed reconstruction, temporarily mounted in the existing museum working bay. The spheres retain the PointBody construction. This is the student study, not a replacement installation.'),
        ('crowded','Installed LOAD comparison. Requested places, admitted centres and refused candidates have separate counts.'),
        ('overhead','The existing hall from above. The optional surface study and Related Weather remain in place.')])
    body='<p class="meta kicker">Endless Museum / Noise 01</p>'+md(report)+'<h2>Inside the museum</h2>'+images
    (OUT/'index.html').write_text(page('Noise · a place is still a request',body),encoding='utf8')
    plan=(OUT.parent/'PLAN.md').read_text(encoding='utf8')
    plan_html=page('Noise · eight-hall plan',md(plan)).replace('href="index.html"','href="Random_Noise_Types/index.html"').replace('href="parallel.html"','href="Random_Noise_Types/parallel.html"').replace('href="tutorial.html"','href="Random_Noise_Types/tutorial.html"').replace('href="final.html"','href="Random_Noise_Types/final.html"').replace('href="changes.html"','href="Random_Noise_Types/changes.html"').replace('href="../plan.html"','href="plan.html"').replace('href="noise-opening-review.zip"','href="Random_Noise_Types/noise-opening-review.zip"')
    (OUT.parent/'plan.html').write_text(plan_html,encoding='utf8')
    methods=OUT/'reproduce';methods.mkdir(exist_ok=True)
    for path in ['tools/revise_noise_opening.py','tools/test_noise_opening.py','tools/publish_noise_opening.py','tools/probes/noise_opening_student.gd','tools/probes/noise_opening_room.gd']:
        shutil.copy2(ROOT/path,methods/Path(path).name)
    (OUT/'README.md').write_text('''# Noise opening review

Open index.html or parallel.html. tutorial.md and final.md are the canonical reading snapshot. The two files in learner/printed/ were extracted from the tutorial, then run in Godot 4.6 inside the prepared Endless Museum project with its Day Zero XR Tools dependencies. learner/deeper/ contains the predicted one-line depth variation; the other learner folders deliberately contain faulty programs for testing.

This packet is not a standalone Godot project. tools/test_noise_opening.py runs from the original repository and recreates evidence from current canonical text. The museum probe is run through tools/run_encounter_probe.py using spec-student.json. Reproduction tools in this packet are source copies for review, not a relocated self-contained runner. No physical headset or independent human learning trial is claimed.
''',encoding='utf8')
    with zipfile.ZipFile(OUT/'noise-opening-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(OUT).parts:
                z.write(p,'Random_Noise_Types/'+p.relative_to(OUT).as_posix())
        for n in ['PLAN.md','plan.html']:z.write(OUT.parent/n,n)
    print('Published',OUT/'index.html')

if __name__=='__main__':main()
