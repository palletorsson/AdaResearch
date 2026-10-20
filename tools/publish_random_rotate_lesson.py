"""Publish the sixth Randomness lesson, native evidence and portable review packet."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Rotate_Random_XYZ'
HERE=OUT/MAP
NAMES=['hall-before','stack-aligned','stack-turned','student-start','student-turns']
REPORT='''# Keep the turn

**Sixth of fourteen Randomness halls revised.** The cube and PointBody return. One list of turns drives two identical cubes: one takes the latest angle, the other retains the sum.

## The lesson in the sequence

The continuing die introduced a record and a running total. Here increments can be positive or negative, and their sum becomes an orientation. This prepares Random Walk: replace the sum of turns with a sum of displacements, then use Trace's list to retain the path. The new subject is accumulation, supported by rotation already learned in Transformation.

The learner creates a small comparison inside their copy of Endless Museum. All lesson geometry and the unchanged PointBody dependency are printed. The museum supplies the player, camera, lighting and XR Tools. Two marked cubes receive the same saved input. Reading begins at the short `step()` function; the supporting construction remains available in full.

REPLAY rewinds the list cursor without redrawing. STEP reads once. PLAY reads at a fixed interval; PAUSE retains the partly completed interval. The record is finite. The student's edits change amplitude, axis, or a deliberately supplied list while keeping the comparison interpretable.

## What inspection changed

The legacy tutorial mixed isolated sketches, missing variables and helpers, an unimplemented history, and a false claim that hashing clock readings supplied hardware entropy. The replacement distinguishes input source, retained state, timing and display. It makes no claim that random Euler components uniformly sample spatial orientations.

The artifact named `Random_Rotate_Random_XYZ` currently searches for `GridMultiMesh`. That floor-grid target is absent in this museum layout, so the artifact does not rotate anything here. The lesson's installed reference is instead the working `random_decay_multimesh#study:rotation` display already central to the reflection. This finding changes the teaching plan, not the production artifact.

The installed display has twenty cubes and 120 prisms. In this study its rates match; drift, sinking and colour changes are disabled. Its internal angular velocity and wear state make it more elaborate than the two-cube reconstruction. It also updates on rendered frames. The tutorial explicitly separates this implementation from its fixed-interval comparison, rather than promising equivalent trajectories.

## The two texts

The reflection keeps the weathering rig, changing stacks, pause/reset distinction and static half-sine field. Its opening now connects with the previous room's sum. A short passage locates the difference between receiving the same input and retaining the same history.

Two unsupported numerical comparisons were corrected: an approximate turning timetable was replaced by its actual frame dependence, and the claimed threefold default rate difference was removed. The current defaults are 0.32 and 0.14; this hall matches both to 0.32. RESET aligns the installed pieces and clears their accumulated state but does not rewind the random generator.

## Predicted changes

| Input or edit | Latest-angle cube | Accumulating cube |
|---|---|---|
| +10°, +10°, −5° | Ends at −5° | Ends at +15° |
| Equal and opposite turns | Takes the second turn | Returns to zero |
| Two half-turns | Takes the last half-turn | Stores a full turn although its pose returns |
| Amplitude 20° → 40°, same seed | Each sampled angle doubles | Each prefix sum doubles |
| Axis Z → X, same record | Same values, different axis | Same sums, different axis |

The real capture uses the default seed 42 after thirteen entries: the latest angle is about −19.4° and the sum about −86.0°. No specially searched seed was used. The marker makes a near-quarter-turn distinguishable from the cube's original pose.

## Evidence

The exact printed files and three source edits—double amplitude, local X axis, and the supplied +10,+10,−5 record—each pass **29 Godot checks**. Four faulty variants are rejected: replacing the sum, drawing during replay, losing steps during a slow frame, and moving the centre when rotating.

Checks cover initialization, inherited point actions, seeded samples, shared input, cancellation, full-turn state, unchanged geometry, finite and empty records, replay without draws, independently owned state, paused time, manual stepping, different frame partitions and catch-up after a slow frame.

The first test found a real integration mistake: the action callback omitted the object argument emitted by XRToolsPickable. That version is preserved in `failed-first-run/`. The final listing accepts the argument and passes the actual signal route.

The native museum run passes **26 checks**, including five capture-camera checks. It confirms the active stack, inactive grid rotator, controls, matched rates, fixed positions and sizes, and the 25-cube static half-wave. The turned-stack image follows 3,600 supplied 1/60-second updates after the initial delay check. This is controlled simulation time, not a claim about sixty seconds on another machine.

The learner comparison was reconstructed from the extracted printed code in a temporary bay. The first placement failed its floor check: a raised floor cut through the plinths and control shelf. Its images and receipt remain in `failed-first-placement/`. A second passed the geometric checks but its photograph was obstructed by a foreground tool; those images remain in `occluded-second-placement/`. The final placement checks the floor under both plinth footprints and a body-sized visitor approach, then exercises STEP, PLAY/PAUSE and REPLAY through the inherited point action.

## Scope and remaining questions

The map, installed artifact sources and PointBody class match their saved pre-edit hashes. The temporary reconstruction is not a permanent new exhibit. Native images were inspected directly. This is an author-informed reconstruction, not a blind ghost-student reading or a physical-headset test.

The log still reports the absent GridMultiMesh target and safe-fallback routing for blocked authored entry/exit positions. Full walking and teleport acceptance need a separate visit. The existing unknown UID and renderer-compatibility warnings also remain. No accepted run contains a script, parse or signal-callback error.

HTML links, printed-code parity and ZIP contents are checked. Browser layout was not inspected because the browser blocks local file URLs. The reflection's earlier static-field figure is retained and copied into the packet; it is not represented as a new capture.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-rotate-review.zip)
'''

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert all(r['passed']==r['expected_pass'] for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==26,receipt
    log=(run/'engine.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log and 'Error calling from signal' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for n in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(run/n,museum/n)
    before=json.loads((HERE/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in before.items() if not p.endswith(('tutorial.md','final.md'))}
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
    figures=HERE/'figures';figures.mkdir(exist_ok=True)
    shutil.copy2(ROOT/'doc/book/figures/randomness/tilt-field-contained.png',figures/'tilt-field-contained.png')
    portable={n:t.replace('/book-images/figures/randomness/tilt-field-contained.png','figures/tilt-field-contained.png') for n,t in texts.items()}
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    diffs=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(portable[name],encoding='utf8')
        (HERE/f'{name}.html').write_text(page(name.title(),portable[name],nav),encoding='utf8')
        previous=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(previous.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Keep the turn — Random Rotate</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    pictures='''<figure><img src="museum/student-turns.png" alt="Two marked cubes in Endless Museum, showing the latest angle and the accumulated sum"><figcaption>Exact printed reconstruction inside the museum. Seed 42, entry 13: latest −19.4°, accumulated −86.0°. Temporary placement, not a permanent exhibit.</figcaption></figure><div class="pair"><figure><img src="museum/student-start.png" alt="The same two cubes before playback"><figcaption>Both begin at zero; their marks agree.</figcaption></figure><figure><img src="museum/stack-turned.png" alt="The installed prism and cube stacks after controlled updates"><figcaption>The installed stack: accumulated turns, unchanged centres.</figcaption></figure></div><details><summary>Existing hall from above</summary><img src="museum/hall-before.png" alt="The existing Random Rotate hall from above before the learner comparison"></details>'''
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8')
    (HERE/'index.html').write_text(shell+'<h1>Keep the turn</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(portable[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Keep the turn — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Rotate</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='29 checks × 4 programs passed; 4 faults rejected',museum_test='26 passed; native images inspected; first placement failed',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 06 ·');b=plan.index('### 07 ·')
    section=plan[a:b].replace('**Primary:** Random_Rotate_Random_XYZ.', '**Primary:** random_decay_multimesh#study:rotation, isolated in a two-cube learner comparison. The namesake floor rotator has no GridMultiMesh target in the current museum.')
    section=re.sub(r'\*\*Status:\*\*[^\n]*','**Status:** revised and tested; four programs with 29 checks each, four faults rejected, 26 museum checks. See `STATUS.json` and the sixth-hall report.',section)
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_rotate_lesson.py','tools/test_random_rotate_lesson.py','tools/publish_random_rotate_lesson.py','tools/probes/random_rotate_student.gd','tools/probes/random_rotate_museum.gd']:shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Randomness hall 6. Start at index.html or parallel.html (tutorial left, reflection right). Extracted/06_turns_kept.gd and point_body.gd are the complete learner files; the other scripts are test variants, including deliberate faults. Requires the prepared Endless Museum and XR Tools. This is a review packet, not a standalone Godot project. Run tools from the original repository. Native receipts and images are in museum/. Failed first attempts are retained and clearly named. Temporary learner placement; no installed artifact changed. Headset and unfamiliar-reader acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-rotate-review.zip';count=0
    for p in [*HERE.glob('*.html'),OUT/'index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0])
            if target==archive:continue
            assert target.exists(),(p,link)
            count+=1
    verify={'printed_files':files,'protected_sources':protected,'positive_code_checks':[29]*4,'faults_rejected':4,'museum_checks':26,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked.','scope':'Authored reconstruction, not blind reader or headset.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                text=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                text=text.replace('<a href="random-rotate-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-rotate-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),text)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Random Rotate report</a>'))
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names=set(z.namelist())
        for name in names:
            if not name.endswith('.html'):continue
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if urlparse(link).scheme or link.startswith('#'):continue
                assert (Path(name).parent/unquote(link.split('#')[0])).as_posix() in names,(name,link)
    print(json.dumps({**verify,'zip_crc':'pass','zip_links':'pass'},indent=2))

if __name__=='__main__':main()
