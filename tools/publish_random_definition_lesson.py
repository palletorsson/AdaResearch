"""Publish current source, before/after text and native evidence for hall one."""
from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,page,STYLE,main as publish_plan

HERE=OUT/'Random_Definition'

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert all(x['passed']==x['expected_pass'] for x in tests['results'])
    run=ROOT/'ada_run/encounter_pilot/Random_Definition'
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and receipt['observations']['student_yaw_degrees']==-90
    log=(run/'engine.log').read_text(encoding='utf8',errors='replace')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for p in run.iterdir():
        if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(p,museum/p.name)
    # First code attempt preserves the harness error; don't replace it with the passing run.
    assert (HERE/'first-harness.log').is_file()
    tutorial=(ROOT/'commons/maps/Random_Definition/tutorial.md').read_text(encoding='utf8')
    final=(ROOT/'commons/maps/Random_Definition/final.md').read_text(encoding='utf8')
    parity=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S):
        assert code+'\n'==(HERE/'extracted'/name).read_text(encoding='utf8')
        parity.append(name)
    (HERE/'tutorial.md').write_text(tutorial,encoding='utf8')
    (HERE/'final.md').write_text(final,encoding='utf8')
    diffs=[]
    for name in ['tutorial','final']:
        before=(OUT/'before/Random_Definition'/f'{name}.md').read_text(encoding='utf8')
        after=(HERE/f'{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+name+'.md',tofile='after/'+name+'.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    report='''# Randomness begins with a repeatable picture

The retrospective and fourteen-hall plan are ready. **Random Definition is the first revised and tested lesson. The other thirteen are planned, not yet reconstructed or validated.**

## What changed

The tutorial now gives a complete two-file construction inside the prepared Endless Museum. It creates two four-by-four cube grids and all labels. The second file is the unchanged PointBody from Wavefunctions. No `$Display`, prepared mesh child or hidden display helper is needed.

The carried point selects REPLAY, +1 DRAW and NEXT SEED by local position; its existing action triggers the operation. NEXT SEED increments the integer, while the installed table uses a RANDOM button. That difference is stated. The new operation is a local generator, its reset, draw order and colour assignment. Existing cube, material, array and interaction knowledge does the supporting work.

The reflective opening now connects both Cage's retained score and Synthesis's recipe to the paired grids. One unnecessary GDScript block became a sentence. The existing encounter, colour-group diagram and question about what a seed leaves out remain. The two texts do different jobs.

## Evidence

- Extracted the two named files directly from the printed `tutorial.md` into a fresh folder. Verified exact parity with the visible listings.
- Original program: **22 native Godot checks passed**.
- Actual edited grayscale and red/blue-swapped programs: **23 checks passed for each**. Both retain three draws per cube.
- Transfer inside those runs: a two-by-two grid at seed 731 uses 13 requests when shifted; a separate instance keeps its own record.
- Two deliberately broken versions were rejected for the intended stream-assignment failures. Discarding after colouring is particularly useful: its draw count is correct, but the picture is wrong.
- Actual current museum: **15 checks passed**, including floor and approach, material agreement with the installed instrument, held-point action dispatch and native captures. These counts include capture-camera checks.

The checker calls the inherited point's actual `action()` method at prescribed positions. This verifies the connection and local-coordinate choice, not an end-to-end physical headset grab. The rehearsal is author-informed, not a blind ghost student or human learning study.

## What the inspection changed

The first proposed bay had clear floor but placed the textile panels behind the learner's grids. The revised bay is hall-local `(10.5, 0, 18.5)`, Y rotation −90 degrees. Its front faces into the room; the east wall gives a quieter background. The production museum and its existing artifacts are unchanged. The reconstruction was attached for the test and capture; the tutorial tells the learner how to place their own study there.

## A checker error preserved

The first run's 22 assertions returned true, but it also logged XR Tools compilation errors, so it was **not accepted**. The checker referred directly to the global XR pickable class while the main script was being parsed, bringing in dependencies before their autoloads were ready. Removing that premature type reference from the checker let the lesson load those dependencies normally after initialization. The lesson and inherited PointBody required no change. The first checker, receipt and log are retained beside the corrected evidence.

## Limits and remaining work

The museum still reports an unrecognized project UID, compatibility-renderer feature warnings and a blocked authored entry with a safe spawn fallback. The tested study bay has floor and a clear approach; this does not repair or certify the hall's original entrance. Headset reach, travel through every portal and an unfamiliar reader's experience remain open.

The fourteen-hall order has a plausible line: **replay → count → eligibility → marks → events → accumulation → walk → distribution → population → neighbours → estimation → feedback → layered field → deadline**. This is an initial teaching judgement, not a completed test of every hall. The plan identifies the three largest pressures: entropy arrives early, pheromone introduces feedback, and spatial fields must prepare Noise without duplicating that sequence.

The existing Random Definition reflection holds because its question is anchored in an operation we can reproduce. The next task is **Random Entropy**: retain a categorical list, sort a copy, compare unchanged counts with changed neighbours, then read what the entropy formula can and cannot measure. We must explicitly introduce symbol IDs rather than pretend the stored RGB colours have already become ten categories.

[Read the facing pages](parallel.html) · [Tutorial alone](tutorial.html) · [Reflection alone](final.html) · [Before/after](changes.html) · [Editable whole-sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions](predictions.md) · [Code tests](tests.json) · [Museum checks](museum/report.json) · [First checker log](first-harness.log) · [Complete local review packet](random-definition-review.zip)
'''
    (HERE/'REPORT.md').write_text(report,encoding='utf8')
    pictures='''<div class="pictures"><figure><img src="museum/primary.png" alt="Existing seed replay instrument inside Random Definition"><figcaption>Installed work: the larger comparison already present in the museum.</figcaption></figure><figure><img src="museum/student-matched.png" alt="Student's two matching cube grids and carried black point"><figcaption>Printed reconstruction: two matching grids, the familiar held point.</figcaption></figure><figure><img src="museum/student-shifted.png" alt="One discarded draw changes only the right grid"><figcaption>Same seed, one unused draw. No cube moves.</figcaption></figure></div>'''
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Changes</a><a href="../index.html">Sequence plan</a>'
    for name,text in [('tutorial',tutorial),('final',final)]:
        (HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
    body=markdown.markdown(report,extensions=['extra'])
    (HERE/'index.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Definition — revised lesson</title><style>{STYLE}.pictures{{display:grid;gap:24px}}figure{{margin:0}}figcaption{{font:14px/1.5 system-ui;margin:10px 0}}main{{max-width:1100px}}</style><main><nav>{nav}</nav>{pictures}{body}</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><title>Random Definition — text changes</title><style>{STYLE}</style><main><nav>{nav}</nav><h1>Changes from the saved texts</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Definition — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;letter-spacing:.1em;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Definition</h1><p>The left page makes the operation reconstructable. The right follows the encounter.</p><div class="spread"><article><p class="track">Tutorial · left</p>{markdown.markdown(tutorial,extensions=["extra"])}</article><article><p class="track">Reflection · right</p>{markdown.markdown(final,extensions=["extra"])}</article></div></main></html>',encoding='utf8')
    baseline=json.loads((OUT/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in baseline.items() if p not in ['commons/maps/Random_Definition/tutorial.md','commons/maps/Random_Definition/final.md']}
    assert all(protected.values()),[p for p,v in protected.items() if not v]
    status=json.loads((PLAN/'STATUS.json').read_text())
    status['halls'][0].update(status='revised; ready for review',tutorial_test='22 + 23 + 23 passed; 2 faults rejected',museum_test='15 passed; native images inspected',report='doc/book/iterations/2026-10-09-randomness-revision/Random_Definition/index.html')
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8').replace('**Status:** first revision in progress.','**Status:** revised and tested; see `STATUS.json` and the first-hall report. Remaining hall contracts are still provisional.')
    (PLAN/'PLAN.md').write_text(plan,encoding='utf8')
    publish_plan()
    tools=HERE/'tools';tools.mkdir(exist_ok=True)
    for p in ['tools/test_random_definition_lesson.py','tools/probes/random_definition_student.gd','tools/probes/randomness_revision_museum.gd','tools/revise_random_definition.py']:
        shutil.copy2(ROOT/p,tools/Path(p).name)
    archive=HERE/'random-definition-review.zip'
    (HERE/'README.md').write_text('Start with index.html or REPORT.md. This packet contains one revised lesson, not the complete Randomness sequence. The printed code requires the prepared Endless Museum project with XR Tools; it is not an empty-project download. Extracted listings, changed programs, deliberate faults and logs are evidence. Tests in tools/ run from the repository. The retained first harness log is a rejected run. Native museum captures show a temporary student reconstruction in the actual hall, not a new permanent artifact.\n',encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if p.is_file() and p!=archive and p.suffix not in ['.uid'] and '.godot' not in p.parts:
                if p.suffix in ['.md','.html']:
                    packed=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                    z.writestr(p.relative_to(HERE).as_posix(),packed)
                else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — sequence plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">First lesson</a>'))
        z.write(OUT/'before/Random_Definition/tutorial.md','before/tutorial.md')
        z.write(OUT/'before/Random_Definition/final.md','before/final.md')
    with zipfile.ZipFile(archive) as z:assert z.testzip() is None
    class Links(HTMLParser):
        def __init__(self):super().__init__();self.links=[]
        def handle_starttag(self,tag,attrs):
            for k,v in attrs:
                if k in ['href','src']:self.links.append(v)
    missing=[];count=0
    for p in [*HERE.glob('*.html'),OUT/'index.html',ROOT/'doc/blog/2026-10-09-what-a-tutorial-must-keep/index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            if link.startswith('/book-review/'):target=ROOT/unquote(link.removeprefix('/book-review/').split('#')[0])
            else:target=p.parent/unquote(link.split('#')[0])
            count+=1
            if not target.exists():missing.append(str(p)+': '+link)
    assert not missing,missing
    verification={'printed_files':parity,'protected_manuscripts_and_maps_unchanged':all(protected.values()),'protected_count':len(protected),'local_links_checked':count,'missing':missing,'archive_crc':'pass','code_checks':[22,23,23],'museum_checks':len(receipt['checks']),'limits':'Native rendering inspected; no browser layout or headset/independent-reader acceptance. localhost:3003 was offline; portable HTML supplied.'}
    (HERE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf8')
    print(json.dumps(verification,indent=2))

if __name__=='__main__':main()
