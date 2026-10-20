"""Publish the continuing-die lesson and scoped evidence."""
from pathlib import Path
from urllib.parse import urlparse,unquote
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links

MAP='Random_Cubes'
HERE=OUT/MAP
NAMES=['hall-before','die-before','die-physical-six','student-open','student-closed','student-limited']

REPORT='''# Random Cubes — a six permits another draw

**Fifth of fourteen Randomness halls revised.** One primary tutorial object: a column whose growth is governed by the continuing-die rule. The inherited PointBody operates the small reconstruction.

## What changes

The old tutorial focused on bevelled cube edges. It referenced missing construction functions and a prepared scene, and claimed every generated profile would be unique. That was neither a complete runnable example nor the strongest lesson offered by the hall.

The replacement keeps the cube as a unit of height. One draw returns an integer from one through six; the value enters an ordered history and a running total. Six permits another event. A different face closes the chain. A display cap can leave the rule unfinished. The whole program and its unchanged point-class dependency are printed in `tutorial.md`.

The lesson states its boundary: this is a **coded draw**. The installed die reads a physical orientation after release and settlement. The generator can reproduce a number sequence; it cannot replay the visitor's hand. In both cases the result can enter the same continuation rule.

## What the student brings

10 PRINT supplied a local generator, a record and a rule for interpreting each draw. The new example expands two choices to six and makes one outcome decide whether another event is allowed. Trace and Arrays supply the list and loop; the cube returns as a visible unit. The sphere retains its existing pickup and action behaviour.

The new work is therefore small: an event adds a contribution, then changes permission. The student's edits alter that decision or the display budget. They do not need to build dice physics, a histogram, paired throws and edge-profile geometry in the same lesson.

## What the two texts do

The reflection was already strong. It keeps the physical die, rewards, paired columns, continuing chain, coins, disappearing heap and profiled slabs. Its opening now connects with the previous two-mark field. The two-line code fragment becomes prose. A short passage distinguishes the tutorial's reproducible stream from the hand's throw.

The tutorial makes the continuation rule reconstructible. The reflection asks where the permission to keep growing resides, what a record retains, and how conditions of a throw disappear from a tally. The wider museum remains available without every artifact becoming compulsory code.

## Student changes and predictions

| Case | Record | Total | Ending |
|---|---|---:|---|
| Six-only rule, supplied 6, 6, 3 | 6, 6, 3 |15|Closed|
| Five-place budget, five sixes |6, 6, 6, 6, 6|30|Unfinished at limit|
| Last allowed result is not six |Earlier sixes, then 3|Depends on budget|Closed, not limited|
| Three-place edit, three sixes |6, 6, 6|18|Unfinished at limit|
| Default seed42, six-only rule |6, 5|11|Closed|
| Same seed42, five-or-six rule |6, 5, 3|14|Closed after one more event|

The first four rows test defined rule cases. The last two are actual generated runs in the tested Godot4.6 build. A seed is not a permanent cross-version guarantee. The inclusive bounds of `randi_range(1, 6)` are part of the declared operation. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

## Test evidence

The exact printed program and two source edits—five-or-six continuation and a three-place cap—each passed **32 checks**. All four faulty variants were rejected: sampling zero through five, overwriting the total, treating the cap as closure, and drawing again after the chain had ended.

Checks cover initialization, independent bounded draws, retained order and sum, replay, invalid values, no draws after closure or limit, all six predicate cases, direct supplied inputs, visual section boundaries, accumulated height, redraw without mutation, smaller displays and separate instances. They compare generator state, not just the visible result. No test requires a short run to look evenly distributed.

The native museum run passed **32 checks**, including six capture-camera checks. A real low drop onto the installed tray produced one six and kept the chain open; waiting did not count it again. Explicit event inputs exercised repeated-result rejection, six-six-three closure, return versus reset, five-sixes limitation and closure on the final place. These supplied events are identified as tests, not represented as hand-thrown outcomes. The paired-dice comparison retained both contributions and waited for its second result.

The extracted learner program then ran in a temporary bay beside the existing exhibit. Floor and a body-sized approach were checked. The inherited point action drew, closed and replayed a chain. The three-place code edit showed an unfinished eighteen-unit column.

The images use seed364 for six-six-three and seed119 for three sixes. Both seeds were deliberately located for those demonstrations, then replayed through the real generator. They show possible cases, not typical runs. Each image labels its seed and CODED DRAW.

## What remains open

This was an author-informed reconstruction, not a blind student reading or physical-headset test. A scripted low drop exercises settlement but does not establish fairness of hand throws. Full walking-route and headset reach remain untested.

The temporary study was removed after capture. The map, installed artifact code and inherited point class match their saved pre-edit hashes. The accepted runs contain no script or parse errors; the existing unknown-UID warning remains. A type-inference error in the new test harness was corrected before these accepted runs.

Native images were inspected directly. Printed code parity, local links and the review ZIP were checked. Browser layout was not inspected because the available browser blocks local file URLs.

Next is Random Rotate: keep the cube, distinguish assigning an orientation from accumulating a turn, and make the history of those changes inspectable.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Review ZIP](random-cubes-review.zip)
'''.replace('seed42','seed 42').replace('Godot4.6','Godot 4.6').replace('seed364','seed 364').replace('seed119','seed 119')

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert all(r['passed']==r['expected_pass'] for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==32
    log=(run/'engine.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for name in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(run/name,museum/name)
    baseline=json.loads((HERE/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in baseline.items() if not p.endswith(('tutorial.md','final.md'))}
    assert all(protected.values()),protected
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    files=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S):
        p=HERE/'extracted'/name
        assert p.read_text(encoding='utf8')==code+'\n'
        assert (ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8')==code+'\n'
        assert hashlib.sha256(p.read_bytes()).hexdigest()==tests['printed_sha256'][name]
        files.append(name)
    assert len(files)==2 and '```' not in texts['final']
    changes=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(text,encoding='utf8')
        before=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        changes.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8')
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    for name,text in texts.items():(HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
    pictures='''<figure><img src="museum/student-closed.png" alt="Printed student reconstruction closes a six-six-three chain inside Endless Museum"><figcaption>Temporary reconstruction in the real hall. Seed364 was selected for this demonstration:6 +6 +3 closes at15.</figcaption></figure><div class="pair"><figure><img src="museum/student-open.png" alt="Two sixes leave the chain open"><figcaption>After the second draw: twelve units, permission to continue.</figcaption></figure><figure><img src="museum/student-limited.png" alt="Three-place edit reaches the display limit with eighteen units"><figcaption>Three-place code edit. Seed119: three sixes reach the limit; the rule remains unfinished.</figcaption></figure></div><details><summary>Existing exhibit and hall</summary><img src="museum/die-physical-six.png" alt="Installed physical die after a real low drop recorded six"><p>A supplied low physical drop, read once after settlement. The larger six-six-three column beside it is the installed labelled worked example.</p><img src="museum/hall-before.png" alt="Random Cubes hall from above before reconstruction"></details>'''.replace('Seed364','Seed 364').replace('Seed119','Seed 119').replace('demonstration:6 +6 +3 closes at15','demonstration: 6 + 6 + 3 closes at 15')
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Cubes — revised lesson</title><style>{STYLE}main{{max-width:1100px}}figure{{margin:20px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    (HERE/'index.html').write_text(shell+'<h1>A six permits another draw</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(changes)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Cubes — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Cubes</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='32 checks × 3 programs passed; 4 faults rejected',museum_test='32 passed; native images inspected',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 05 ·');b=plan.index('### 06 ·')
    section=re.sub(r'\*\*Status:\*\*[^\n]*','**Status:** revised and tested; three programs with 32 checks each, four faults rejected, 32 museum checks. See `STATUS.json` and the fifth-hall report.',plan[a:b])
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    tools_dir=HERE/'tools';tools_dir.mkdir(exist_ok=True)
    for name in ['tools/revise_random_cubes_lesson.py','tools/test_random_cubes_lesson.py','tools/probes/random_cubes_student.gd','tools/probes/random_cubes_museum.gd','tools/publish_random_cubes_lesson.py']:shutil.copy2(ROOT/name,tools_dir/Path(name).name)
    (HERE/'README.md').write_text('Hall 5 of Randomness. Start at index.html or parallel.html (tutorial left, reflection right). Use extracted/05_a_continuing_die.gd and point_body.gd; other files are test variants, some deliberately broken. Requires prepared Endless Museum and XR Tools. The learner display is a temporary reconstruction. Tests run from the original repository; this is a review packet, not a standalone Godot project. Native captures and receipts are in museum/. Before sources are retained. Physical-headset, unfamiliar-reader and full-route acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-cubes-review.zip';count=0
    for p in [*HERE.glob('*.html'),OUT/'index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0])
            if target==archive:continue
            assert target.exists(),(p,link)
            count+=1
    verification={'printed_files':files,'protected_sources':protected,'code_checks':[32]*3,'faults_rejected':4,'museum_checks':32,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked.','scope':'Authored reconstruction, not headset or unfamiliar-reader acceptance.'}
    (HERE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                content=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                content=content.replace('<a href="random-cubes-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-cubes-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),content)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Random Cubes report</a>'))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names=set(z.namelist())
        for name in names:
            if not name.endswith('.html'):continue
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if urlparse(link).scheme or link.startswith('#'):continue
                assert (Path(name).parent/unquote(link.split('#')[0])).as_posix() in names,(name,link)
    print(json.dumps({**verification,'zip_crc':'pass','zip_links':'pass'},indent=2))

if __name__=='__main__':main()
