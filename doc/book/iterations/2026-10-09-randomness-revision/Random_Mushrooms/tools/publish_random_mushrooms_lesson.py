"""Publish full ninth-hall readings and bounded, reproducible evidence."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Mushrooms'
HERE=OUT/MAP
NAMES=['hall-before','specimens','bed-varied','bed-unit-scale','student-varied','student-unit-scale','student-third-recipe','hall-with-study']
REPORT='''# A population kept

**Randomness, hall 9 of 14.** The student now keeps a record for each body: recipe, place, turn and scale. The same PointBody supplies the hand control. The existing garden remains the encounter; a small temporary table reconstructs its SIZE comparison.

## What this lesson adds

The last room separated a sampled value from its grouping. This room assigns values to named properties. A dictionary holds related fields; an array retains the population. A discrete recipe index chooses a construction, while a continuous scale changes its dimensions. These operations reuse primitive meshes, arrays, loops, transforms and local coordinates.

The table begins with twelve fixed places and two mushroom recipes. Fixing the places lets the learner compare the same members. The cap and stem follow the installed standard tan and red recipes, omitting gills; all geometry is created in the printed script. The learner changes the range, reduces the population to six, then adds a tall third recipe. The third recipe changes the available repertoire; a new seed alone cannot add it.

The required construction stays small. Noise filtering, fairy rings, clusters, edible mushrooms, arriving silhouettes and couture remain museum encounters. Their presence does not oblige this lesson to teach all their implementations.

## A comparison that survives its control

SIZE changes only the existing nodes' scales. The records, positions, turns and RNG state stay. Restoring SIZE restores each sampled scale. At scale one, red and tan recipes still have different dimensions: equal scale is not equal size.

REPLAY instead regenerates records and nodes under the same seed. NEXT SEED adds one and rebuilds; it is deliberately named differently from the garden's random NEW SEED control. The SIZE setting stays across both actions.

The installed garden also preserves its comparison, but does so by rebuilding under the seed and consuming the scale draws even when their values are not used. The tutorial distinguishes the implementations. A seed is sufficient for replay only with the same procedure, parameters and engine behaviour.

The student's point is the unchanged class from the preceding lessons. Its trigger chooses REPLAY, SIZE or NEXT SEED according to its X position in the table's local frame. Moving or releasing it does not sample. These are simple X zones, not proximity-sensitive buttons or sockets. The table and specimen meshes are visual; the prepared museum supplies the player and floor.

## What the installed hall established

The source and native run agree: six templates, six-metre bed, eighty scattered candidates, one requested ring and two requested clusters. At seed 42 this run had 73 accepted candidates and seven rejected, plus five placed ring members and fourteen cluster members: 92 generated mushrooms. Three edible mushrooms belong to a separate scene and count.

REGROW reproduced every recorded template, kind, group, position, turn and scale, together with the ground signature and generator state. SIZE retained all those fields except scale, setting it to one; switching back restored the earlier records. SHOW's counts matched the selected template's members. Seed 43 changed the population, and returning to 42 recovered it.

The temporary learner table occupies hall-local (3, 0, 7), yaw 90 degrees. Floor and a clear body-sized approach were checked. Close views make the twelve specimens and labels readable in the capture. The first elevated garden comparison was obscured by the cage frame; its replacement views move inside the frame, and the first images remain in the evidence. The overview shows the table beside the existing bubble dish. It is a reconstruction for review, not a new permanently registered exhibit.

## How the two texts work together

The tutorial teaches a retained population and an intervention on one property. The reflection keeps its larger movement: family resemblance, unchosen templates, rejected positions, authored circles, separate permissions and wardrobes whose limits cannot be escaped by a luckier draw.

Five code excerpts become prose. The clearing rule is described as threshold-based rejection rather than automatically identifying it with a particular Monte Carlo target distribution. A claim about its metre-wide clearings is removed: frequency alone does not establish that bound. The bubble passage now says the exhibit has no replay control, rather than declaring replay impossible. A short passage connects the student's retained record to a difference that can be withheld and restored.

The old tutorial jumped ahead to Random Game. Its successor now points to Random Space Geometry: what changes when neighbouring values have a relation? The reflection's cage interlude remains; the native exit is visibly labelled Biome Cage, while the fourteen-hall teaching list names Random Space Geometry next. This pass does not reconcile or change the runtime route.

## Tests and their limits

The exact printed script and unchanged PointBody are extracted from tutorial.md. Four programs pass **32 Godot checks each**: the printed version, wider scale range, six bodies and third recipe. Four deliberate faults fail the expected checks: SIZE spending a draw, discarding the stored scale, fixing all stem heights and using world X for local action zones.

A supplied two-body fixture tests known dimensions: a 0.15-metre stem scaled by 0.7 and 1.3 gives 0.105 and 0.195 metres. SIZE makes same-recipe dimensions equal but leaves different-recipe dimensions unequal. Other checks cover prefixes, replay with SIZE disabled, stable nodes, draw order, repeated reconstruction, independent instances, zero and bounded counts, and inherited point actions after translating and rotating the whole study.

The first harness used an unavailable Dictionary helper and then an exact comparison for a stored 3D float. Both harness errors were repaired; their failed evidence is retained. The learner code required no behavioural repair. The plinth was thickened for a grounded display, after which the printed versions were retested.

The final native museum run passes **32 checks**, including eight capture-camera checks. The tested printed program runs inside the real isolated museum; its inherited action is invoked at supplied poses. The third-recipe variation is also shown there. Native images were inspected directly. This is author-informed testing, not a blind ghost student, physical grab-driver test or headset acceptance.

The logs retain existing unknown-UID, renderer, material-remapping and Jolt warnings, plus a fallback for a blocked authored entrance. There are no script, parse or signal-callback errors in the accepted run. Local links, rendered code and the ZIP are checked. Browser layout has not been accepted: file URLs were blocked earlier.

The installed map, mushroom source, sequence file and shared PointBody retain their pre-edit hashes. The changes are the canonical texts, learner program, tests and review material.

[Facing pages](parallel.html) · [Full tutorial](tutorial.html) · [Full reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-mushrooms-review.zip)
'''

def main():
    tests=json.loads((HERE/'tests.json').read_text())
    assert len(tests['results'])==8 and all(r['passed']==r['expected_pass'] and r['checks']==32 for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot'/MAP
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==32,receipt
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
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A population kept</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:22px 0}}figcaption{{font:14px/1.5 system-ui;margin:8px 0}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    def figure(n,caption):return f'<figure><img src="museum/{n}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
    pictures=figure('student-varied','Exact printed study in Endless Museum: seed 42, twelve bodies, two recipes, sampled scale.')
    pictures+='<div class="pair">'+figure('student-unit-scale','The same records at scale one. Recipe dimensions still differ.')+figure('student-third-recipe','A third recipe adds a tall, narrow body. The construction has changed; the seed remains 42.')+'</div>'
    pictures+='<details><summary>The installed bed and the reconstruction in its hall</summary>'+figure('specimens','The existing six-template garden and five controls.')+'<div class="pair">'+figure('bed-varied','Garden seed 42 with per-instance scaling.')+figure('bed-unit-scale','Garden seed 42 with scaling disabled; other recorded fields remain.')+'</div><div class="pair">'+figure('hall-before','Existing hall before adding the temporary learner table. Initial garden seed differs from the controlled comparison.')+figure('hall-with-study','Temporary learner table near the entrance beside the bubble dish; the existing garden and wider encounters remain.')+'</div></details>'
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8')
    (HERE/'index.html').write_text(shell+'<h1>A population kept</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Mushrooms — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}.spread article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Mushrooms</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='32 checks × 4 programs passed; 4 faults rejected',museum_test='32 passed; native images inspected; supplied point actions',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8');a=plan.index('### 09 ·');b=plan.index('### 10 ·')
    section='''### 09 · Random_Mushrooms — a draw within a repertoire

**Primary:** mushrooms. **Bring:** primitive constructors, scale, bounded sampling and retained values. Keep twelve fixed grid places, sample recipe ID, yaw and size, and store named fields in a dictionary per member. SIZE changes only scales; records and RNG stay. Reuse PointBody for REPLAY/SIZE/NEXT SEED. Two cylinder-and-sphere recipes carry the required comparison; add a third tall recipe, widen the scale range, and recover the six-member prefix. Distinguish retained-record intervention from the garden's seeded rebuild. Rings, clearings, garments and eating remain museum comparisons. **Status:** revised and tested; four printed programs with 32 checks each, four faults rejected, 32 museum checks. Next teaching hall: Random Space Geometry; native route also shows the existing Biome Cage interlude. See `STATUS.json` and the ninth-hall report.

'''
    (PLAN/'PLAN.md').write_text(plan[:a]+section+plan[b:],encoding='utf8');publish_plan()
    evidence=HERE/'tools';evidence.mkdir(exist_ok=True)
    for p in ['tools/revise_random_mushrooms_lesson.py','tools/test_random_mushrooms_lesson.py','tools/publish_random_mushrooms_lesson.py','tools/probes/random_mushrooms_student.gd','tools/probes/random_mushrooms_museum.gd']:
        shutil.copy2(ROOT/p,evidence/Path(p).name)
    (HERE/'README.md').write_text('Randomness hall9. Open index.html or parallel.html (tutorial left, reflection right). Learner files: extracted/09_a_population_kept.gd and point_body.gd. Other extracted scripts include tested edits and deliberately faulty programs. Requires prepared Endless Museum and XR Tools; not a standalone Godot project. The table is a temporary reconstruction. Production source unchanged. Museum photos/receipt in museum/. Initial harness errors and first obstructed camera views are retained. Headset and unfamiliar-reader acceptance remain open.\n',encoding='utf8')
    archive=HERE/'random-mushrooms-review.zip';count=0
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
    verify={'printed_files':files,'rendered_code_parity':True,'protected_sources':protected,'positive_code_checks':[32]*4,'faults_rejected':4,'museum_checks':32,'local_targets_checked':count,'native_images_inspected':True,'browser_layout':'Not inspected: local file URLs blocked earlier.','scope':'Author-informed reconstruction, supplied point actions; not physical grab driver or headset.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                text=p.read_text(encoding='utf8').replace('../../../course/randomness-revision/PLAN.md','sequence-plan.md').replace('href="../index.html"','href="sequence-plan.html"')
                text=text.replace('<a href="random-mushrooms-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-mushrooms-review.zip)','Review packet: this folder')
                z.writestr(p.relative_to(HERE).as_posix(),text)
            else:z.write(p,p.relative_to(HERE).as_posix())
        z.write(PLAN/'PLAN.md','sequence-plan.md')
        z.writestr('sequence-plan.html',page('Randomness — plan',(PLAN/'PLAN.md').read_text(encoding='utf8'),'<a href="index.html">Random Mushrooms report</a>'))
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
