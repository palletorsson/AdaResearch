"""Publish Randomness hall eleven with exact-code and native-museum evidence."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Randomness_Examples_of_Randomness'
HERE=OUT/MAP
NAMES=['hall-before','installed-dartboard','student-sixteen','student-uniform','student-strip','hall-with-study']
REPORT='''# A draw estimates

**Randomness, hall 11 of 14.** The point returns as the learner's control. Two sampled coordinates become a retained position, a circle verdict and one step in an estimate's history.

## What changed

The earlier tutorial surveyed four works. It now reconstructs one operation in complete code: uniform sampling of a square to estimate the inscribed circle's area. Arrays, conditions, ratios, sphere markers and the inherited PointBody do familiar work. The new question is whether the sampling procedure supports the estimate being claimed.

The complete program builds its own board, graph and labels in the prepared Endless Museum. It starts with no samples and shows `--`, avoiding a ratio with a zero denominator. ONE adds a point, BATCH adds sixteen, REPLAY clears and rewinds. A finite 256-point budget keeps every sample visible. The graph retains each intermediate estimate; it does not replace the previous answer with a promise of progress.

## What the comparison reveals

At seed 42, 205 of 256 uniform samples fall inside: **3.203125**. With the same seed and only the horizontal range narrowed to a central strip, 255 fall inside: **3.984375**. These are observations from the executed examples, not universal outcomes. The latter program runs correctly, but its sampling area no longer supports the original factor-four estimate of π. That distinction connects the technical exercise to the reflection without making either text repeat the other.

Changing BATCH to 32 preserves the complete sample sequence. Changing the seed to 43 changes it. The student can predict and test those consequences before judging whether the final number looks convincing. In the original seed-42 run, 171 additions moved the estimate farther from π than the preceding one; individual improvement is not guaranteed.

## The installed hall

The learner board was reconstructed temporarily at hall-local (10.5, 0, 13), yaw 180°. Its origin and standing approach have floor support; the approach is clear for a body-sized collision capsule. The close native captures make the square, circle, counts and history readable. The high view shows the study beside the existing painting and dartboard, with the pipe and particle works farther along. This is a tested learner placement, not a newly registered museum exhibit.

Concurrent project work changed the installed dartboard while this lesson was being prepared. The first museum run caught a parse error in that new option; it was corrected by the concurrent work before this task's attempted fix. The next run revealed that the old THROW/AUTO/RESET controls had been replaced in this hall by a sampling-budget console. Those failed receipts are preserved. This task made no production-code or map edits.

The final text and probe follow the current console: THROW, +100, FILL, REPLAY, NEXT SEED and 8 SEEDS. Its dial selects budgets of 100, 500, 2000 or 8000; that dial range was checked in source. Runtime checks exercise the current 500-sample setting and actual button signals, including replay and comparison without changing the current run. The installed board keeps only its newest 300 marks while retaining the complete count. The printed study keeps all 256. Under shared seed 42, the source and learner tally agree for all 256 trials.

## The reflective track

The four encounters remain: painting, estimation, bounded pipe growth and five particle procedures. The revision updates the console directions, removes fragile left/right cues, and adds a short passage about a steady number that answers a different question. The historical naming anecdote is removed from this encounter; it was not needed to explain what the player can observe. The handoff remains Pheromone, where a visit changes the conditions of a later choice.

## Evidence and limits

- **21 checks for each of four complete printed programs passed:** original, batch 32, seed 43 and the deliberately biased strip.
- **Four faults rejected:** omitted seed rewind, integer division, a smaller counting circle, and world coordinates used for local action zones.
- **28 native museum checks passed**, including the installed sample/count relation, button signals, finite visual budget, private comparisons, learner placement and supplied PointBody actions.
- Six native captures accompany the report. Principal learner and hall images were visually inspected. The first failed runs remain separately labelled.

The harness is author-informed. It tests code, source edits and supplied interaction events; it is not an unfamiliar reader or a physical headset session. Existing UID, renderer and shutdown-resource warnings remain in the logs; the accepted run has no script or parse errors. The whole hall's visual quality and Quest performance are not established by these checks.

[Tutorial and reflection side by side](parallel.html) · [Before / after](changes.html) · [Review ZIP](random-examples-review.zip)
'''

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text());assert receipt['passed'] and len(receipt['checks'])==28
    log=(run/'engine.log').read_text(encoding='utf8');assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for n in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(run/n,museum/n)
    baseline=json.loads((HERE/'before-manifest.json').read_text())
    unchanged={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in baseline.items() if not p.endswith(('tutorial.md','final.md'))}
    assert unchanged['commons/maps/sequences/randomness.json'] and unchanged['doc/book/studies/randomness-lineage/point_body.gd']
    source_snapshot=HERE/'tested-sources';source_snapshot.mkdir(exist_ok=True)
    hashes={}
    for p in ['algorithms/randomness/monte_carlo_dartboard/'+n for n in ['monte_carlo_dartboard.gd','sample_run.gd','sample_console.gd']]+[f'commons/maps/{MAP}/map_data.json']:
        shutil.copy2(ROOT/p,source_snapshot/Path(p).name);hashes[p]=hashlib.sha256((ROOT/p).read_bytes()).hexdigest()
    (source_snapshot/'hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf8')
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S))
    for n,c in blocks.items():
        assert (HERE/'extracted'/n).read_text(encoding='utf8')==c+'\n'
        assert hashlib.sha256((HERE/'extracted'/n).read_bytes()).hexdigest()==tests['printed_sha256'][n]
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="sequence-plan.html">Sequence plan</a>'
    diffs=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(text,encoding='utf8');(HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
        old=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8');diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A draw estimates</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    def figure(n,caption):return f'<figure><img src="museum/{n}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
    pictures=figure('student-uniform','Exact printed study in the museum: seed 42, 205 of 256 inside. The right-hand history records successive estimates; gold marks π.')
    pictures+=figure('student-strip','Only x_span changes to 0.2. Same seed and circle; 255 of 256 inside. A steadier result can answer the wrong question.')
    pictures+='<details><summary>Early sample and existing hall</summary>'+figure('student-sixteen','Sixteen samples: the beginning of the same retained record.')+figure('installed-dartboard','The current installed budget console. This study tested button signals at the 500-sample setting; the larger dial settings remain source-inspected.')+'<div class="pair">'+figure('hall-before','Existing gallery before temporary learner placement.')+figure('hall-with-study','The temporary learner board fits beside the retained artworks.')+'</div></details>'
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8');(HERE/'index.html').write_text(shell+'<h1>A draw estimates</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A draw estimates — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Examples of Randomness</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text());row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='21 checks × 4 programs passed; 4 faults rejected',museum_test='28 passed; native images inspected; current budget-console button signals and supplied point actions',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 11 ·');b=plan.index('### 12 ·')
    section='''### 11 · Randomness_Examples_of_Randomness — a draw estimates

**Primary:** monte_carlo_dartboard. **Bring:** PointBody, retained samples, counts, ratios and seeds. Reconstruct a bounded square/circle sampler with a retained estimate history, reusing the point for replay/one/batch actions. Batch size changes grouping, not the sample sequence. A central-strip edit keeps code executable while breaking the original area argument; distinguish finite-sample fluctuation from sampling bias. Other artworks remain reflective encounters. Installed console now offers budget/replay/seed comparisons; learner keeps every one of 256 samples. Carry sampling assumptions into Pheromone's history-dependent choices. **Status:** revised; four printed programs pass 21 checks each, four faults rejected, 28 native checks. Concurrent console changes and failed initial probes retained in the report.

'''
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    execution_path=ROOT/'doc/book/course/execution-plan/plan.json'
    execution=json.loads(execution_path.read_text(encoding='utf8'))
    lesson=next(r for r in execution['lessons'] if r['id']==MAP)
    if not (HERE/'execution-row-before.json').exists():
        (HERE/'execution-row-before.json').write_text(json.dumps(lesson,indent=2),encoding='utf8')
    lesson.update(given='Prepared Endless Museum player, floor, camera, light and XR Tools; unchanged PointBody printed beside complete study.',
        reuses='PointBody actions; positions and arrays; counters and ratios; local seed/replay; sphere markers and thin-cylinder lines.',
        checks=['21 native checks for each of four exact printed programs; four semantic faults rejected.','28 native museum checks; source/learner tally agreement, controls, floor and approach, supplied point actions.'],
        transfer='Change batch16 to32 while preserving every sample; try seed43; narrow x_span to0.2 and explain why factor4 loses its square-area justification.',
        next='Pheromone: retained visits influence later choices; expose feedback rather than assuming independent sampling.',
        notes='Revised/tested 2026-10-09; report doc/book/iterations/2026-10-09-randomness-revision/Randomness_Examples_of_Randomness/index.html. Current source budget console described; learner bounded256 with all marks retained. No headset or unfamiliar-reader acceptance.',
        summary='Reuse PointBody to request samples on a self-built board in the existing museum. Draw two uniform coordinates, retain the position, test the unit circle and keep each successive estimate. Compare one-by-one and batched requests under the same seed; then narrow the sampled region and explain why a steady number can answer the wrong question. Carry the sample record, its counting rule and its assumptions into Pheromone, where history changes a later choice.')
    execution_path.write_text(json.dumps(execution,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    (HERE/'sequence-plan.md').write_text((PLAN/'PLAN.md').read_text(encoding='utf8'),encoding='utf8')
    (HERE/'sequence-plan.html').write_text(page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">A draw estimates</a>'),encoding='utf8')
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_examples_lesson.py','tools/test_random_examples_lesson.py','tools/publish_random_examples_lesson.py','tools/probes/random_examples_student.gd','tools/probes/random_examples_museum.gd']:shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Open parallel.html for tutorial left/reflection right; index.html for native pictures/evidence. extracted/11_a_draw_estimates.gd + point_body.gd are the learner files. Other extracted variants include deliberately broken examples: do not use as the starting lesson. Requires prepared Endless Museum and XR Tools, not a standalone project. first-museum-attempt and changed-console-attempt are failed historical runs; museum/ is the accepted run. No headset or unfamiliar-reader acceptance.\n',encoding='utf8')
    rendered=[html.unescape(c) for c in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(HERE/'tutorial.html').read_text(encoding='utf8'),re.S)]
    assert all((c+'\n').expandtabs(4) in rendered for c in blocks.values())
    archive=HERE/'random-examples-review.zip';links=0
    for p in HERE.glob('*.html'):
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0]);assert target==archive or target.exists(),(p,link);links+=1
    verify={'rendered_code_parity':True,'positive_program_checks':[21]*4,'faults_rejected':4,'museum_checks':28,'local_targets_checked':links,'native_principal_images_inspected':True,'unchanged_since_baseline':unchanged,'concurrent_changes':'Dartboard implementation and console changed during this task; snapshots retained. Map matches this task baseline. No production edits by this tutorial task.','browser_layout':'Not browser-verified.','scope':'Author-informed executable reconstruction; supplied events, not physical headset.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                text=p.read_text(encoding='utf8').replace('<a href="random-examples-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-examples-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),text)
            else:z.write(p,p.relative_to(HERE).as_posix())
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
