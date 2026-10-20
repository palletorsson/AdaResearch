"""Publish Random Walk with exact printed-code and native museum evidence."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Walk'
HERE=OUT/MAP
NAMES=['hall-before','terrarium-planar','terrarium-volume','student-trail','student-new-start']
REPORT='''# A point keeps its steps

**Seventh of fourteen Randomness halls revised.** The familiar PointBody gains a sampled displacement. The existing Trace cylinder joins its accepted positions. One point, one planar rule, one retained path.

## What travels forward

Random Rotate accumulated turns. Random Walk accumulates displacements. Coordinates supplies the local frame; Wavefunctions supplies sine and cosine; Trace supplies the positions list and connecting cylinders. The learner changes what an existing object does, rather than learning another construction for a sphere.

The lesson asks what depends on the path so far. Each new heading ignores the trail. The endpoint nevertheless depends on the current position, and the enclosure can change a proposal. A record can remember something without participating in the next decision.

The student holds the point to pause, releases it to choose a new planar start, or presses its trigger before release to replay from the previous start. Ordinary release clears the old run. This is stated before the code: the hand supplies a starting place here, rather than continuously drawing the trace.

## What the tutorial now contains

Three complete printed files: the new walker, unchanged PointBody, and unchanged LineSkin from Point Trace. The prepared museum supplies its player, camera, lighting and XR Tools. The script creates its table, boundary and labels; those display meshes are not collision bodies. Read the short `step()` function first, then its supporting construction.

The normal run contains 128 steps, 129 retained positions and 128 cylinders. It stops consuming random draws when complete. The trail joins accepted endpoints, so it does not draw contact with a wall. The boundary applies to the sphere's centre; this is a position rule, not a rigid-body simulation of a bounce.

The reconstruction was checked at hall-local (4, 0, 7), with no rotation and an approach on its positive-Z side. It is a temporary lesson station in the student's museum copy. The installed hall and artifacts have not been replaced.

## Three edits with different consequences

| Change | Prediction |
|---|---|
| Step 0.12 → 0.24 m | Same headings; doubled displacements before either path reaches a boundary. |
| Interval 0.25 → 0.5 s | Same path at equal step counts, reached more slowly. |
| Fold → clamp at the boundary | Same random draws, different accepted positions near an edge. |
| New starting position, same seed | Same proposals relative to the current position; different boundary encounters. |
| Erase the stored trail only | The next step is unchanged: it does not read that record. |

An independent exercise asks the learner to predict a corner overshoot and explain why the displayed chord is shorter than the proposed step. The next hall, Random Gaussian, groups samples by value: a histogram keeps counts while giving up the order visible in this path.

## What inspection established

The terrarium has five walkers sharing a private generator. ONE and ALL change emphasis without removing walkers or consuming draws. Planar steps consume one draw per walker; 3D consumes two; LONG STEP consumes three. The last mode samples a bounded length. It does not demonstrate an unbounded Lévy process or prove a better search strategy.

The installed cabinet retains a rolling window of 200 previous positions; the bead shows the current position. At step 300 those trail entries are positions 100–299. The learner program instead retains the start and every accepted endpoint for its short finite run. Both conventions are explicit.

Installed RESET restores the seed and positions but retains a partial step timer. The cabinet accepts at most five batches per rendered frame and drops excess time. Its clock still counts the supplied frame time. Our finite reconstruction clears its timer on restart and handles complete intervals up to the step budget. Replay comparisons therefore specify equal step counts and the same engine version, start and rule.

The other artifacts remain part of the hall: the rails compare fresh position with accumulated displacement; the held drawing dot combines a carried origin with a wandering tip; the lattice counts revisits; a small self-avoiding sculpture consults occupied cells. They extend the inquiry without making all their implementations compulsory here.

## What changed in the reflection

The existing question remains: **what does a trail remember that its next step does not use?** The writing still moves from the terrarium through the rails, drawing dot and raised field. Code excerpts become prose. Claims that long steps remedy revisiting or constitute better searching become questions the artifacts can support. A count of returns does not decide what a good walk should do.

A short closing passage connects the learner's point to that reflection. The tutorial explains and reconstructs the operation; the reflective text examines how we read the resulting movement and what the visible record leaves out.

## Test evidence

The exact printed program and three actual source edits each pass **30 Godot assertions**. Four faulty versions fail the expected checks: forgetting the previous position, omitting the boundary, losing the final record, and failing to reset the generator. Tests cover all 128 steps, cylinder geometry, replay, independent instances, local/world conversion, held time, corner folding, finite completion and frame partitioning.

The initial harness referenced an XR Tools class before its required autoload was available. All assertions printed PASS, but startup compile errors invalidated that run. The harness bootstrap was corrected and every variant rerun cleanly. The first log and harness are retained in `failed-first-run/`; they are not presented as accepted evidence.

The native museum run passes **32 checks**, including five capture-camera checks. It checks the installed terrarium's actual state, draw consumption and time policy, then reconstructs the extracted learner files. The station and body-sized approach have floor; the approach collision query is clear. Pickup/drop signals and the inherited action method exercise pause, release and replay. Additional checks confirm the sphere remains at its endpoint after rendering and physics frames.

The endpoint check found a real error after ordinary release: the frozen body returned to its previous physics pose while the trail recorded the new position. The study now assigns its saved position on physics frames when free and yields to the hand while held, including after a run finishes. The isolated headless check did not reproduce that fault; the museum did. Its failed native receipt is why the numerical checks alone are insufficient. The rejected receipt and printed code remain in `endpoint-check-first-run/`.

The first reconstruction photographs exposed dark text against a dark wall. A pale backing was added, then the printed variants and museum reconstruction were rerun. The earlier images remain in `first-capture-low-contrast/`.

## What these checks do not establish

This is an author-informed reconstruction, not an unfamiliar ghost student's reading or a physical-headset test. Pickup/drop events were supplied explicitly; the physical grab driver was not simulated. The station's table is a display, so the floor and approach checks are not a promise of collision against its tabletop.

Existing native diagnostics remain: an unknown UID, renderer compatibility warnings, and a safe fallback for a blocked authored entrance. Full walking, teleport transitions and headset readability still need a visit. Accepted runs contain no script, parse or signal-callback errors. No production artifact, map configuration or shared point/line class was edited for this lesson.

Native images were inspected directly. Printed-code parity, local links and ZIP contents are checked. Browser layout was not inspected because local file URLs were blocked earlier.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-walk-review.zip)
'''

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert len(tests['results'])==8 and all(r['passed']==r['expected_pass'] for r in tests['results'])
    assert all(r['checks']==30 for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==32,receipt
    log=(run/'engine.log').read_text(encoding='utf8')
    assert not any(s in log for s in ['SCRIPT ERROR','Parse Error','Error calling from signal'])
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for n in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:
        shutil.copy2(run/n,museum/n)
    before=json.loads((HERE/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in before.items() if not p.endswith(('tutorial.md','final.md'))}
    assert all(protected.values()),protected
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    files=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S):
        path=HERE/'extracted'/name
        assert path.read_text(encoding='utf8')==code+'\n'
        assert (ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8')==code+'\n'
        assert hashlib.sha256(path.read_bytes()).hexdigest()==tests['printed_sha256'][name]
        files.append(name)
    assert len(files)==3 and '```' not in texts['final']
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    diffs=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(text,encoding='utf8')
        (HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
        old=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A point keeps its steps</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    pictures='''<figure><img src="museum/student-trail.png" alt="The familiar sphere with its pink trail above a pale tabletop inside Endless Museum"><figcaption>Exact printed program in a temporary museum station. Seed 42 after 64 steps: 65 retained positions and 64 connecting cylinders.</figcaption></figure><div class="pair"><figure><img src="museum/student-new-start.png" alt="The point's changed path after choosing another starting position"><figcaption>Same seed and step count, new start. The enclosure changes where the proposals can end.</figcaption></figure><figure><img src="museum/terrarium-volume.png" alt="The installed five-walker terrarium in three-dimensional mode"><figcaption>Existing terrarium: five walkers, shared generator, a rolling trail. It remains the comparison.</figcaption></figure></div><details><summary>Existing planar view and hall from above</summary><img src="museum/terrarium-planar.png" alt="Planar trails in the installed terrarium"><img src="museum/hall-before.png" alt="Random Walk's existing gallery and large raised-cell field from above"></details>'''
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8')
    (HERE/'index.html').write_text(shell+'<h1>A point keeps its steps</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Walk — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Walk</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='30 checks × 4 programs passed; 4 faults rejected',museum_test='32 passed; native images inspected; supplied interaction events',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 07 ·');b=plan.index('### 08 ·')
    section=re.sub(r'\*\*Status:\*\*[^\n]*','**Status:** revised and tested; four programs with 30 checks each, four faults rejected, 32 museum checks. See `STATUS.json` and the seventh-hall report.',plan[a:b])
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_walk_lesson.py','tools/test_random_walk_lesson.py','tools/publish_random_walk_lesson.py','tools/probes/random_walk_student.gd','tools/probes/random_walk_museum.gd']:
        shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Randomness hall 7. Start at index.html or parallel.html (tutorial left, reflection right). The three learner files are extracted/07_a_point_keeps_steps.gd, point_body.gd and line_skin.gd. Other extracted scripts are test variants, including deliberate faults. Requires the prepared Endless Museum and XR Tools. This review packet is not a standalone Godot project. Run tools from the original repository. Native receipts and images are in museum/. First failed harness and low-contrast photographs are retained in clearly named folders. Temporary station; no installed artifact changed. Physical headset and unfamiliar-reader acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-walk-review.zip';count=0
    rendered=[html.unescape(b) for b in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(HERE/'tutorial.html').read_text(encoding='utf8'),re.S)]
    for name in files:
        assert (HERE/'extracted'/name).read_text(encoding='utf8').expandtabs(4) in rendered,name
    for p in [*HERE.glob('*.html'),OUT/'index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0])
            if target==archive:continue
            assert target.exists(),(p,link)
            count+=1
    verify={'printed_files':files,'rendered_code_parity':'All three match; Markdown expands tabs to four spaces.','protected_sources':protected,'positive_code_checks':[30]*4,'faults_rejected':4,'museum_checks':32,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked.','scope':'Author-informed reconstruction; supplied pickup/drop events, not physical grab driver or headset.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                text=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                text=text.replace('<a href="random-walk-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-walk-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),text)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Random Walk report</a>'))
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
