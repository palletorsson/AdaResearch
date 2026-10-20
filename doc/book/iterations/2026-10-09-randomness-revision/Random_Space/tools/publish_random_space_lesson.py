"""Publish Random Space's printed reconstruction and native museum evidence."""
from pathlib import Path
from urllib.parse import unquote, urlparse
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from publish_randomness_revision import ROOT, OUT, PLAN, STYLE, page, publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Space'
HERE=OUT/MAP
NAMES=['installed-one','installed-four','student-one','student-four','student-low-weight','student-quarter-sum','hall-with-study']
REPORT='''# Fields add

**Randomness, hall 13 of 14.** Return to Synthesis's weighted sum and Space Geometry's sample addresses. This time the sum is spatial: several contributions make one field. The familiar PointBody controls the learner's reconstruction inside the existing Endless Museum.

## What changed

The previous tutorial described an arena of Gaussian markers, butterflies and drippers, with missing scenes and undeclared helpers. It did not reconstruct this hall's main artifact. The new lesson prints a complete finite field mixer and its unchanged PointBody dependency.

The learner keeps the installed mixer's actual five-sine base function and eight seeded offsets. OCT includes one to four weighted contributions. LAC multiplies successive frequencies; PER multiplies successive amplitudes. Parameter changes recompute samples without drawing offsets again. One layer is the useful baseline: changing either ratio has no effect until another layer exists.

The student can inspect the last contribution, their complete sum, and a contrast-stretched view of that same sum. The reconstruction uses 32 × 32 samples and grey values; the installed mixer uses 128 × 128 and an earth-toned palette. At shared addresses the raw sums agree. Neither a new palette nor more layers automatically adds sample resolution.

## The change that makes the distinction visible

At seed 42 with four layers, the sampled sum ranges from about **-1.014 to 1.132**. The student adds a two-line loop that multiplies every completed sum by 0.25. The range becomes about **-0.254 to 0.283**. The fixed-scale picture loses contrast. In this native run the stretched picture's pixels are **identical**. Both still read the same array; only the display range differs.

That experiment now enters the reflection. It asks how a smaller difference can still occupy the full distance from black to white. The existing passages about violet ground, cellular distances and the entropy gauge remain. Their different jobs in the room do not become additional compulsory code lessons.

## Evidence

- **33 checks passed for each of six complete programs:** printed baseline, seed 43, LAC 3, PER 0.7, resolution 64, and the quarter-sum intervention.
- For each program, every address under one, two, three and four layers is compared against the production mixer's sum. The 64 × 64 version checks 16,384 source samples; each other version checks 4,096. The quarter-sum variant compares against a quarter of the source result.
- Replay, retained offsets, contribution prefixes, single-layer invariance, raw/pixel separation, constant-range handling, label alignment and local PointBody actions are checked. The deliberately edited programs are executed, not just described.
- **Four faults rejected:** redrawing an offset during parameter edits, retaining only the last contribution instead of the sum, integer division collapsing sample coordinates, and world coordinates used for local actions.
- **27 native museum checks passed.** These exercise the actual mixer sliders and seed-button signals, both complete learner versions, their visible labels, source/learner agreement, and local support and standing clearance.

## The museum view

The temporary learner station stands at hall-local **(9.5, approximately 0.232, 12), yaw -90°**, on the existing violet surface. The tested height was found from that surface's collision, not assumed to be the grey hall floor. Its support and nearby standing approach passed. The screenshots show the reconstruction in the hall; it has not been registered as another permanent artifact.

The first close capture exposed a layout fault: a combined caption did not line up with the three screens, and some action labels did not lie within their intended trigger zones. Each now has its own position, the screens clear the parked point, and a regression check verifies the action labels. That first layout is retained for review. The final comparison and overhead captures were visually inspected.

The museum loader still reports that the authored entrance has no clear supported landing and uses a fallback near the drop point. This task did not change the room or certify its full traversal. The local study checks must not be read as a repair of that existing issue.

## Scope

Production algorithms, scenes, map, sequence and inherited PointBody are unchanged from the snapshot. These are author-informed executable tests and supplied interaction events; physical headset use, an unfamiliar student's understanding and Quest performance remain untested. Browser layout is unverified. The native log retains existing UID/renderer/entrance warnings; no script or parse errors occurred in the accepted run.

Next is **Random Game**: a drawn wait becomes a retained deadline. Carry forward the distinction between changing an event and changing how it is shown.

[Tutorial and reflection](parallel.html) · [Before / after](changes.html) · [Review ZIP](random-space-review.zip)
'''

def update_plan():
    path=PLAN/'STATUS.json';status=json.loads(path.read_text(encoding='utf8'))
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='33 checks × 6 programs passed; 4 faults rejected; source sum parity',museum_test='27 passed; native comparison images inspected; supplied actions; existing entrance issue remains',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    path.write_text(json.dumps(status,indent=2),encoding='utf8')
    path=PLAN/'PLAN.md';plan=path.read_text(encoding='utf8');a=plan.index('### 13 ·');b=plan.index('### 14 ·')
    section='''### 13 · Random_Space — fields add

**Primary:** noise_mixer. **Bring:** PointBody, Synthesis's weighted sum and Space Geometry's sample addresses. Preserve the actual five-sine base and eight seeded offsets; sum one to four weighted contributions. OCT chooses count, LAC multiplies frequencies, PER multiplies amplitudes. One layer ignores both ratios; returning settings recovers the same raw field without random draws. Show last contribution, fixed-scale sum and its independently stretched view. A quarter-sum edit reduces values while keeping stretched contrast; SIDE64 adds addresses, not layers. Other fields remain comparisons. **Status:** revised; six printed programs pass33checks each and match source sums at all addresses for1..4layers. Four faults rejected;27native checks, images inspected. Label layout corrected. Existing unsupported entrance/fallback remains an open room issue. Carry raw/view separation into Random Game's event and warning.

'''
    path.write_text(plan[:a]+section+plan[b:],encoding='utf8')
    path=ROOT/'doc/book/course/execution-plan/plan.json';execution=json.loads(path.read_text(encoding='utf8'))
    row=next(r for r in execution['lessons'] if r['id']==MAP)
    if not (HERE/'execution-row-before.json').exists():(HERE/'execution-row-before.json').write_text(json.dumps(row,indent=2),encoding='utf8')
    row.update(given='Prepared Endless Museum player, floor, camera, light and XR Tools. Full field-study and unchanged PointBody printed together.',
        reuses='PointBody actions; Synthesis weighted sums; addressed grids; seeded offsets; stored arrays and colour mapping.',
        checks=['33 checks in each of six complete printed programs; every sample matches source under1..4layers; four faults rejected.','27 native museum checks; real console signals, exact learner/edit, labels, local support and approach. Existing entrance issue remains.'],
        transfer='Change LAC2 to3, PER to0.7, or SIDE32 to64. Quarter only the completed sum and explain why fixed contrast changes while stretched contrast remains.',
        next='Random Game: a sampled wait is retained as a deadline; changing its warning must not redraw the event.',
        notes='Revised/tested2026-10-09; report doc/book/iterations/2026-10-09-randomness-revision/Random_Space/index.html. Uses actual five-sine mixer, not Perlin or missing arena prefabs. No production edit or headset/unfamiliar-reader acceptance.',
        summary='Return to the point as a control and build a small field mixer in the existing museum. Keep eight seeded offsets, sample one to four contributions, and retain each weighted part beside their sum. Change layer count, frequency ratio and amplitude ratio separately; explain why both ratios do nothing with one layer. Compare a fixed grey scale with a view stretched to the current range. Scale the sum to a quarter and observe what the display conceals. Carry the separation between values and their disclosure into Random Game.')
    path.write_text(json.dumps(execution,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    publish_plan()

def main():
    tests=json.loads((HERE/'tests.json').read_text(encoding='utf8'))
    positive=[r for r in tests['results'] if r['expected_pass']];faults=[r for r in tests['results'] if not r['expected_pass']]
    assert len(positive)==6 and all(r['passed'] and r['checks']==33 for r in positive)
    assert len(faults)==4 and all(not r['passed'] and r['failures'] for r in faults)
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text(encoding='utf8'));assert receipt['passed'] and len(receipt['checks'])==27
    log=(run/'engine.log').read_text(encoding='utf8');assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for n in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(run/n,museum/n)
    before_run=run/'space-before';before=HERE/'museum-before';before.mkdir(exist_ok=True)
    for n in ['hall-before.png','mixer-before.png','report.json','engine.log','source_manifest.json']:shutil.copy2(before_run/n,before/n)
    baseline=json.loads((HERE/'before-manifest.json').read_text(encoding='utf8'))
    unchanged={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in baseline.items() if not p.endswith(('tutorial.md','final.md'))}
    assert all(unchanged.values()),unchanged
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S))
    assert set(blocks)=={'13_fields_add.gd','point_body.gd'}
    for n,c in blocks.items():
        assert (HERE/'extracted'/n).read_text(encoding='utf8')==c+'\n'
        assert hashlib.sha256((HERE/'extracted'/n).read_bytes()).hexdigest()==tests['printed_sha256'][n]
    reference='/book-images/figures/randomness/cellular-field-violet-ground.png'
    shutil.copy2(ROOT.parent/'ada_encyclopedia/public'/reference.lstrip('/'),HERE/'reference-cellular-field.png')
    def portable(text):return text.replace(reference,'reference-cellular-field.png')
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="sequence-plan.html">Sequence plan</a>'
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fields add</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    diffs=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(portable(text),encoding='utf8')
        (HERE/f'{name}.html').write_text(page(name.title(),portable(text),nav),encoding='utf8')
        old=(HERE/f'before/commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8');diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    def figure(n,caption,folder='museum'):return f'<figure><img src="{folder}/{n}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
    pictures=figure('student-four','Four contributions. Left: the last included layer; middle: sum on a fixed scale; right: that sum stretched to its own range.')
    pictures+=figure('student-quarter-sum','Same retained parts, but the completed sum is multiplied by 0.25. The middle loses contrast; the right-hand pixels remain identical in this run.')
    pictures+='<details><summary>One layer, weights and the installed museum</summary>'+figure('student-one','One layer: the last contribution and complete sum agree.')+figure('student-low-weight','Four layers with PER 0.3. The first contribution remains; later terms have smaller weights.')
    pictures+='<div class="pair">'+figure('installed-one','Installed noise mixer: one layer, earth-toned palette.')+figure('installed-four','Installed mixer: four layers, same offsets.')+'</div>'
    pictures+='<div class="pair">'+figure('hall-before','Existing hall before the temporary learner station.','museum-before')+figure('hall-with-study','Temporary study at the side of the existing violet surface.')+'</div></details>'
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8');(HERE/'index.html').write_text(shell+'<h1>Fields add</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(portable(texts[name]),extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Space — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Space</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    update_plan()
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8')
    (HERE/'sequence-plan.md').write_text(plan,encoding='utf8');(HERE/'sequence-plan.html').write_text(page('Randomness — plan',plan,'<a href="index.html">Fields add</a>'),encoding='utf8')
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_space_lesson.py','tools/test_random_space_lesson.py','tools/publish_random_space_lesson.py','tools/probes/random_space_student.gd','tools/probes/random_space_museum.gd','tools/probes/random_space_before.gd']:shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Open parallel.html for tutorial/reflection or index.html for evidence and native captures. Learner files: extracted/13_fields_add.gd and point_body.gd. Other extracted files include intentionally broken programs; do not start from them. Prepared Endless Museum + XR Tools required; this is not a standalone project. first-label-layout is a rejected layout, museum/ the accepted run. Reference cellular-field image was already in the reflection; it is not a new capture. The portable final.md changes only that image URL; canonical file retains its site URL. Existing hall entrance landing warning remains. No physical headset or unfamiliar-reader acceptance.\n',encoding='utf8')
    (HERE/'first-label-layout/README.md').write_text('Rejected first layout: combined captions did not align with screens/actions and parked point covered part of the middle screen. Corrected positions and action-label regression test are in the accepted version.\n',encoding='utf8')
    rendered=[html.unescape(c) for c in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(HERE/'tutorial.html').read_text(encoding='utf8'),re.S)]
    assert all((c+'\n').expandtabs(4) in rendered for c in blocks.values())
    archive=HERE/'random-space-review.zip';count=0
    for p in HERE.glob('*.html'):
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0]);assert target==archive or target.exists(),(p,link);count+=1
    verify={'rendered_code_parity':True,'positive_program_checks':[33]*6,'faults_rejected':4,'museum_checks':27,'local_targets_checked':count,'native_principal_images_inspected':True,'unchanged_since_baseline':unchanged,'portable_final_image_url':reference+' -> reference-cellular-field.png','browser_layout':'Not browser-verified.','scope':'Author-informed printed/source reconstruction; supplied events, not physical headset. Existing entrance landing warning unresolved.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                content=p.read_text(encoding='utf8').replace('<a href="random-space-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-space-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),content)
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
