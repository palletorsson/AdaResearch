"""Publish the eighth hall's full readings, native captures and test receipts."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Gaussian'
HERE=OUT/MAP
NAMES=['hall-before','sampler-gaussian','sampler-uniform','student-ten-bins','student-twenty-bins','student-uniform']
REPORT='''# Keep the values, change the bins

**Eighth of fourteen Randomness halls revised.** A retained list becomes a histogram. The required comparison stays with two laws, uniform and Gaussian; the point supplies the familiar hand control.

## The next capacity

Random Walk kept the order of accepted positions. Here the learner keeps sampled numbers, then counts how many belong to each interval. Arrays, counts, conditions and loops already have a purpose in the spine. The new distinction is between drawing a value, retaining it, and grouping it for display.

The code uses the installed cabinet's guarded Box–Muller recipe for Gaussian sampling. Mean and standard deviation become parameters the learner can change. The recipe is explained without making its mathematical derivation a prerequisite. Poisson, exponential, the Galton board and the paint-splatter refusal remain encounters in the hall; they are not four additional required implementations.

## One point, four actions

The unchanged PointBody from earlier lessons controls the comparison as it did in Random Rotate. Hold it over one of four labelled positions and press the trigger. Moving it alone draws nothing.

| Action | What changes | What stays |
|---|---|---|
| +100 | Appends up to one hundred samples | Earlier entries, current law and bins |
| BINS | Ten/twenty intervals and their counts | Raw values, order, clipped total and RNG state |
| REPLAY | Rebuilds the present sample from the seed | Amount, law, parameters and bins |
| LAW | Switches uniform/Gaussian and clears the sample | Seed and bins |

The full new script and unchanged PointBody are printed in the tutorial and extracted for testing. The prepared museum provides the camera, player, lighting and XR Tools. All display geometry is created by the script. It draws batches immediately; there is no falling animation or automatic timer to explain again.

The temporary reconstruction sits at hall-local (3, 0, 7), yaw 90°. The existing cabinet remains. The body-sized approach is clear and has floor. These are local placement checks, not a complete walking-route certification.

## Keep the difference between records visible

The learner retains raw values and clamps only a temporary value for choosing a display bin. The cabinet retains already-clamped landed values and a separate clipped counter. These are different records. The tutorial names the difference: the student's record can still reveal how far a value went beyond the screen.

For the deliberately supplied values −0.2, 0, 0.05, 0.49, 0.5, 0.99, 1 and 1.3, two bins contain four each; only two values were clipped. Edge-bin counts do not measure clipping, because they also include valid interior observations. One belongs to the final bin, despite multiplying it by the bin count producing an index just past the array.

Changing the bins uses no random draw. Returning to the original partition restores its earlier counts. Replay is different: it regenerates the same amount under the same seed, law and parameters in the same engine version. Switching laws changes draw consumption—one draw per uniform value, two per Gaussian value.

## Edits that test understanding

| Printed edit | Expected result |
|---|---|
| Deviation 0.15 → 0.30 | Each raw distance from 0.5 doubles; clipping prevents the displayed shape from simply doubling. |
| Limit 300 → 150 | +100 then +50; further presses consume no draws. |
| Twenty bins → forty | A finer partition of the same values, with no change in RNG state. |

The histogram scales by its largest count. TOP names that changing value; N names the total. A single observation can make a full-height bar. Empty bins have no cube. This display contains no theoretical curve: the learner must read a finite sample, rather than identify a familiar outline and stop looking.

In the captured default run, the same 300 Gaussian values have a highest count of 76 with ten bins and 40 with twenty. UNIFORM at N=300 and twenty bins has a highest count of 22. Those bar heights have different count scales; the labels keep the difference visible. Seed 42 was used without searching for a pleasing picture.

## How the two texts read together

The reflection keeps its existing question: **what changes when the values stay, but we count them differently?** It attends to the expectation suggested by the orange model, the distinction between issued and landed evidence, clipping, bin-centre estimates and the empty centre of the splatter plate.

Four code excerpts become prose. The approximate two-thirds and nineteen-in-twenty proportions are identified as properties of the ideal model, not promises about a finite batch. The splatter's refused disc is described by its radius, correcting the ambiguous phrase “one deviation across.” A brief passage links the student's point to the choice between adding evidence and changing its account.

The closing distinction remains: frequent under a chosen model does not mean preferable, healthy or correct. Random Mushrooms can now ask which features of a body a sampled number is allowed to change.

## Evidence

The exact printed program and three actual source edits each pass **30 Godot checks**. Four deliberate faults are rejected: drawing during rebinning, wrapping the value one to the first bin, failing to zero old counts, and losing raw values through premature clipping.

Checks cover initialization, seeded draw order, finite budgets, retained prefixes, replay, empty displays, boundary fixtures, bin limits, clipped counts, geometry, independent instances, supplied point actions under a rotated/translated root, and the fact that moving, releasing and waiting do not sample. The wider-deviation test compares raw offsets rather than expecting a particular statistical shape from a short run.

The native museum run passes **28 checks**, including six capture-camera checks. It compares the installed sampler with its actual source recipe, confirms rebinning without RNG changes, checks clear/replay and law changes, verifies the uniform model's expected count of ten per bin at N=300, and exercises capacity while four beads are in flight. It also checks the width cycle and the existing splatter refusal parameters.

The printed learner program is then reconstructed in the real isolated hall. Its four controls are exercised through the inherited point action at supplied poses. Three native images compare the saved Gaussian sample at ten and twenty bins with a uniform sample. All six final images were inspected directly.

## Scope

The map, installed sampler, splatter source and shared PointBody match their pre-edit hashes. This task updates the canonical tutorial and reflection, and supplies a temporary learner reconstruction; it does not replace or rearrange production exhibits.

This is an author-informed reconstruction, not a blind ghost-student reading or a physical-headset test. Supplied poses and action calls do not establish grab-driver behaviour or headset readability. The accepted museum log retains an existing unknown UID, renderer compatibility warnings and a fallback for a blocked authored entrance. It contains no script, parse or signal-callback error.

Local links, rendered-code parity and the ZIP are checked. Browser layout was not inspected because local file URLs were blocked earlier. The reflection's older cabinet image is preserved as an earlier figure and included in the packet; the report images are this run's captures.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-gaussian-review.zip)
'''

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert len(tests['results'])==8 and all(r['passed']==r['expected_pass'] and r['checks']==30 for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==28,receipt
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
    assert len(files)==2 and '```' not in texts['final']
    figures=HERE/'figures';figures.mkdir(exist_ok=True)
    shutil.copy2(ROOT/'doc/book/figures/randomness/sampler-visible-record.png',figures/'sampler-visible-record.png')
    portable={n:t.replace('/book-images/figures/randomness/sampler-visible-record.png','figures/sampler-visible-record.png') for n,t in texts.items()}
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="../index.html">Sequence plan</a>'
    diffs=[]
    for name,text in texts.items():
        (HERE/f'{name}.md').write_text(portable[name],encoding='utf8')
        (HERE/f'{name}.html').write_text(page(name.title(),portable[name],nav),encoding='utf8')
        old=(HERE/'before'/f'commons/maps/{MAP}/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (HERE/f'{name}.diff').write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Keep the values, change the bins</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    pictures='''<figure><img src="museum/student-ten-bins.png" alt="Pink histogram and familiar sphere inside Endless Museum, showing300 retained Gaussian values in10 bins"><figcaption>Exact printed reconstruction. Seed42,300 Gaussian values, ten bins. TOP names76 counts. Temporary station; production cabinet remains.</figcaption></figure><div class="pair"><figure><img src="museum/student-twenty-bins.png" alt="The same values regrouped into twenty narrower bars"><figcaption>Same values, twenty bins. Nothing redrawn. The tallest bin now contains40.</figcaption></figure><figure><img src="museum/student-uniform.png" alt="Uniform samples shown as black bars at the same count and20 bins"><figcaption>Uniform law, N300, twenty bins. TOP is22: a different count scale despite the same displayed height.</figcaption></figure></div><details><summary>Installed cabinet and existing hall</summary><img src="museum/sampler-gaussian.png" alt="Installed Gaussian cabinet with its falling-marker controls and expected-count bars"><img src="museum/sampler-uniform.png" alt="Installed sampler in uniform mode"><img src="museum/hall-before.png" alt="Existing Random Gaussian hall from above"></details>'''
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8')
    (HERE/'index.html').write_text(shell+'<h1>Keep the values, change the bins</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(portable[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Gaussian — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Gaussian</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='30 checks × 4 programs passed; 4 faults rejected',museum_test='28 passed; native images inspected; supplied point actions',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 08 ·');b=plan.index('### 09 ·')
    section=re.sub(r'\*\*Status:\*\*[^\n]*','**Status:** revised and tested; four programs with 30 checks each, four faults rejected, 28 museum checks. Learner keeps raw samples; cabinet retains clamped values. See `STATUS.json` and the eighth-hall report.',plan[a:b])
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_gaussian_lesson.py','tools/test_random_gaussian_lesson.py','tools/publish_random_gaussian_lesson.py','tools/probes/random_gaussian_student.gd','tools/probes/random_gaussian_museum.gd']:
        shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Randomness hall8. Start at index.html or parallel.html (tutorial left, reflection right). The learner files are extracted/08_values_and_bins.gd and point_body.gd. Other extracted scripts are test variants, including deliberate faults. Requires the prepared Endless Museum and XR Tools. This review packet is not a standalone Godot project. Run tools from the original repository. Native receipts and images are in museum/. The figure in final.md is an earlier preserved capture. Temporary station; no installed artifact changed. Headset and unfamiliar-reader acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-gaussian-review.zip';count=0
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
    verify={'printed_files':files,'rendered_code_parity':True,'protected_sources':protected,'positive_code_checks':[30]*4,'faults_rejected':4,'museum_checks':28,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked.','scope':'Author-informed reconstruction; action method at supplied poses, not physical grab driver or headset.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                text=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                text=text.replace('<a href="random-gaussian-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-gaussian-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),text)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Random Gaussian report</a>'))
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
