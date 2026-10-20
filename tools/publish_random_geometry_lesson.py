"""Publish paired readings and evidence for Randomness hall ten."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Space_Geometry'
HERE=OUT/MAP
NAMES=['hall-before','installed-comparison','student-low-frequency','student-high-frequency','student-checkerboard','student-split','hall-with-study']
REPORT='''# What neighbours share

**Randomness, hall 10 of 14.** Keep the grid and the independent heights. Change the frequency of a field sampled at matching addresses. The familiar cubes, records and PointBody carry the new lesson.

## The progression

Mushrooms separated a sampled record from the decision to apply its scale. This lesson keeps that separation and asks how neighbouring values relate. The student reconstructs the installed Perlin comparison as two 8 × 8 height grids. One side uses independent uniform draws; the other asks a spatial function for a value at each address.

The new operation is a position-based field query. Replay, arrays, nested loops, dictionaries, cube construction, local coordinates and point actions return with another purpose. One explicit Perlin layer keeps the required lesson bounded. The installed bench's OCTAVES control remains a comparison; building layered noise belongs to the later Noise sequence.

The old tutorial described seeded ceiling chambers and referenced objects it never initialized. It did not reconstruct this hall's comparison. Its replacement prints a complete program and the unchanged PointBody dependency. The museum supplies the working world and XR Tools. The table and columns are visual geometry, not walkable terrain.

## What the learner can investigate

FREQUENCY replaces only the field values, retaining every independent draw and its generator state. REPLAY reconstructs both procedures under the current settings. NEXT SEED increments the seed. All three actions use the point's local X position, as in the preceding lesson; they are not proximity-sensitive buttons.

At seed 42, the independent mean neighbour gap is **0.338522**. The Perlin gap is **0.047514** at frequency 0.1 and **0.118982** at 0.3. These are measured results for this particular grid. The lesson does not promise monotonically increasing roughness, identical value distributions or a universally smaller Perlin gap.

The student also changes physical grid spacing without changing any values. Field coordinates and display coordinates are distinct. A query repeated at one position gives the same answer even if another position was queried between: it does not consume the next draw from a sequence.

The independent experiment returns to Entropy. An alternating grid and a split grid each contain thirty-two zeros and thirty-two ones. Their mean neighbour gaps are one and 1/14 respectively. Counts stay the same; arrangement matters. Both fixtures are authored patterns, not generated noise.

## The installed museum

The existing bench has two 16 × 16 grids. At seed 42, every displayed height matches either the uniform draw or the configured FastNoiseLite Perlin sample, including the minimum column height. The live frequency and octave slider signals change the coherent side and leave every independent height unchanged. Returning to the settings reproduces both grids. The source's default fractal mode is FBM; its initial octave count is three.

The learner study was temporarily reconstructed at hall-local (3, 0, 12), yaw 90 degrees, with a supported root and a clear body-sized approach. It is not a newly registered production exhibit. The first wide close-up was inside surrounding generated geometry, despite passing the floor and approach checks. Moving the camera closer made the columns and controls visible; the obstructed attempt is retained in `first-cameras/`.

The images expose remaining spatial problems in the existing hall: generated scenery spreads outside the room, and bright lighting washes out parts of the installed bench and the learner's rear label. The accepted close views support comparison of the grids; they do not establish that the whole hall is well arranged. No scenery or museum lighting was changed to obtain a cleaner claim. The two overview images are from the same accepted run, while background populations can differ between runs.

## The two texts

The reflection keeps its movement from local relations to the invitation to see a landscape. A short passage connects the learner's neutral columns and neighbour measurement to arrangements that contain the same numbers. The field's frequency is described as a sampling-coordinate choice, and an overprecise historical footnote is replaced with a bounded account of the implementation. A common height scale does not imply common distributions; a terrain palette does not supply geological history.

The next teaching hall is the dartboard, Randomness Examples of Randomness. It turns from making related surfaces to estimating a quantity from samples. The handoff asks which sampling rule that estimate depends on.

## Evidence and limits

The exact printed files were extracted into fresh files and run in Godot 4.6. The main program and three actual source edits—frequency 0.3, spacing 0.20, seed 43—pass **27 checks each**. Four deliberate faults are rejected: spending an independent draw during a field update, omitting the signed-value mapping, joining across row boundaries, and using world X for the local controls.

Checks cover all 128 rendered columns, row-ordered addresses, sample values and draw count, the shared height rule, neutral material, replay, independent instances, field query order, neighbouring-edge calculations, constant and binary fixtures, and inherited actions after translating and rotating the study. None of the printed code required a behavioural repair during this pass.

The accepted native museum run passes **29 checks**, including seven retained-camera checks. Native images were visually inspected. Interactions use explicit slider signals and PointBody actions at supplied poses. This is author-informed reconstruction, not a blind ghost student, physical grab-driver, headset, performance or full-route acceptance test.

The logs retain existing UID, registry, Jolt, unsupported renderer-feature and resource-cleanup diagnostics, plus the authored-entry fallback. There are no script, parse or signal-callback errors in the accepted run. Protected map, bench source and scene, sequence and PointBody hashes remain unchanged. The publication checks exact rendered code, local links and the reviewer ZIP. Browser layout is unverified because local file previews were blocked earlier.

[Facing pages](parallel.html) · [Full tutorial](tutorial.html) · [Full reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-geometry-review.zip)
'''

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert len(tests['results'])==8 and all(r['passed']==r['expected_pass'] and r['checks']==27 for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==29,receipt
    log=(run/'engine.log').read_text(encoding='utf8')
    assert not any(s in log for s in ['SCRIPT ERROR','Parse Error','Error calling from signal'])
    museum=HERE/'museum';museum.mkdir(exist_ok=True)
    for n in [*(n+'.png' for n in NAMES),'report.json','engine.log','source_manifest.json','spec.json']:
        shutil.copy2(run/n,museum/n)
    baseline=json.loads((HERE/'before-manifest.json').read_text())
    protected={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in baseline.items() if not p.endswith(('tutorial.md','final.md'))}
    assert all(protected.values()),protected
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    files=[]
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S):
        path=HERE/'extracted'/name
        assert path.read_text(encoding='utf8')==code+'\n'
        assert (ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8')==code+'\n'
        assert hashlib.sha256(path.read_bytes()).hexdigest()==tests['printed_sha256'][name]
        files.append(name)
    assert len(files)==2 and '```' not in texts['final']
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    diffs=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(text,encoding='utf8')
        (HERE/f'{name}.html').write_text(page(name.title(),text,nav),encoding='utf8')
        old=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What neighbours share</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    def figure(n,caption):return f'<figure><img src="museum/{n}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
    pictures=figure('student-low-frequency','Printed study inside Endless Museum. Seed 42: independent draws at left, one Perlin layer at right, frequency 0.1.')
    pictures+=figure('student-high-frequency','Frequency 0.3: every independent height is retained; only the field samples change. The point supplies the familiar trigger action.')
    pictures+='<div class="pair">'+figure('student-checkerboard','Authored fixture in both grids: thirty-two zeros and thirty-two ones, mean neighbour gap 1. The seed label is the retained setting, not the source of this fixture.')+figure('student-split','The same category counts rearranged into two halves: gap 1/14. These fixtures replace both sampled records; REPLAY restores them.')+'</div>'
    pictures+='<details><summary>The installed bench and the study within the hall</summary>'+figure('installed-comparison','Existing 16 × 16 bench. Its controls work under supplied slider signals, but the capture exposes washed-out material and control labels.')+'<div class="pair">'+figure('hall-before','Existing room before the temporary study. Generated scenery extends outside the enclosure.')+figure('hall-with-study','Temporary paired table beside the wall, seen from above. Existing artifacts remain. Same run as the preceding overview.')+'</div></details>'
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8')
    (HERE/'index.html').write_text(shell+'<h1>What neighbours share</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Space Geometry — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Space Geometry</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='27 checks × 4 programs passed; 4 faults rejected',museum_test='29 passed; native images inspected; supplied point actions; lighting/layout limits recorded',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 10 ·');b=plan.index('### 11 ·')
    section='''### 10 · Random_Space_Geometry — what neighbours share

**Primary:** perlin_noise_bridge; surrounding kitbash remains a museum comparison. **Bring:** fixed cube grids, named population records, retained values and Wavefunctions' spatial functions. Reconstruct two 8 × 8 grids: uniform draws and one FastNoiseLite Perlin layer at matched addresses. Frequency changes only field values; physical spacing changes neither record. Reuse PointBody for replay/frequency/next seed. Mean absolute neighbour gap counts 112 edges without wrapping; checkerboard and split fixtures return to Entropy's unchanged counts/different arrangement. Same value bounds do not imply identical distributions. Field query order differs from RNG draw order; noise internals and layers remain for Noise. **Status:** revised; four printed programs pass 27 checks each, four faults rejected,29 native museum checks. Initial views were obstructed; accepted close images inspected. Existing bright lighting and overflowing backdrop remain spatial limits. See `STATUS.json` and the tenth-hall report.

'''
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_geometry_lesson.py','tools/test_random_geometry_lesson.py','tools/publish_random_geometry_lesson.py','tools/probes/random_geometry_student.gd','tools/probes/random_space_geometry_museum.gd']:
        shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Randomness hall10. Open index.html or parallel.html (tutorial left, reflection right). Learner files: extracted/10_neighbours_share.gd and point_body.gd. Other extracted scripts include tested edits and deliberate faults. Requires prepared Endless Museum and XR Tools; not a standalone Godot project. Study is a temporary reconstruction. Production unchanged. Native receipts/images in museum/; initial obstructed views in first-cameras/. Headset and unfamiliar-reader acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-geometry-review.zip';count=0
    rendered=[html.unescape(b) for b in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(HERE/'tutorial.html').read_text(encoding='utf8'),re.S)]
    for name in files:assert (HERE/'extracted'/name).read_text(encoding='utf8').expandtabs(4) in rendered,name
    for p in [*HERE.glob('*.html'),OUT/'index.html']:
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0])
            if target==archive:continue
            assert target.exists(),(p,link)
            count+=1
    verify={'printed_files':files,'rendered_code_parity':True,'protected_sources':protected,'positive_code_checks':[27]*4,'faults_rejected':4,'museum_checks':29,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Unverified: file preview blocked earlier.','scope':'Author-informed reconstruction; supplied actions, not headset or physical grab driver.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                text=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                text=text.replace('<a href="random-geometry-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-geometry-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),text)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Random Space Geometry report</a>'))
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
