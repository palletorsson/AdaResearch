"""Publish the last Randomness hall with exact code and native evidence."""
from pathlib import Path
from urllib.parse import unquote,urlparse
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from publish_randomness_revision import ROOT,OUT,PLAN,STYLE,page,publish_plan
from publish_ten_print_lesson import Links
MAP='Random_Game'
HERE=OUT/MAP
NAMES=['crossing','student-ready','student-notice','student-no-cue','student-hidden','student-short-notice','crossing-and-study','hall-with-study']
REPORT='''# A wait kept

**Randomness, hall 14 of 14.** The tutorial closes with one stone and one clock. Its state order is known; its waits are sampled. A cue reads the current decision without replacing it.

## The teaching choice

The former tutorial offered a source walkthrough and fragments, then widened to several artifacts. The new tutorial prints the complete schedule, the body that displays it, and the unchanged PointBody. The larger crossing remains the encounter; the reconstruction is a smaller stone beside it, inspected from the existing museum floor.

The lesson returns to translation, clocks, states, collision and local random generators. Its new responsibility is specific: **draw at a defined moment, retain the result, and let several views read it**. The schedule uses four states with explicit deadlines. Only standing and hidden waits consume variable-duration draws. Movement and collider delays stay separate.

The complete student edit shortens notice from 1.2 to 0.3 seconds. At 0.9 seconds before the same deadline, the original ring is on and the edited ring is off. Both stones still leave at the same time. A second edit makes standing waits exactly three seconds; because that fixed duration consumes no RNG value, subsequent hidden waits read earlier values from the stream. Seed 43 supplies another complete tested variation.

## How the two texts work together

The reflection keeps its crossing, removal floor, doors, disclosure trials, falling field and waiting profiles. Its six GDScript excerpts become prose, and one short addition brings the learner's notice experiment into the encounter. The question remains embodied: before calling a missed step poor timing, where was its warning readable?

The tutorial reconstructs one primary mechanism. It does not claim to implement the other encounters, and the new model has not been registered as a permanent museum artifact.

## Validation

- **33 assertions passed in each of four complete printed programs:** baseline, short notice, seed 43 and fixed standing waits.
- Each version matches 200 alternating waits against the production stone's draw method, including RNG state. Deadline boundaries, sine easing, collider delay, replay, pause, local actions and coarse/fine elapsed-time partitions are checked.
- **Four faulty versions rejected:** reading a cue changes its deadline; replay omits the seed reset; a late update discards phase transitions; a local action uses world coordinates.
- **30 native museum checks passed.** Actual CUE and REPLAY button signals, a full source cycle, reset during motion, learner interactions, support/approach clearance and eight captures are included.

The first native probe looked for the source buttons under their old parent. The museum's compact-console staging had moved them while preserving callbacks. That probe failed four checks and produced null-reference errors; it is retained under `first-room-check`. The corrected probe finds the original buttons under their actual artifact root. No production repair was needed. The first before-closeup looked at the entrance door because the museum's hall placement includes a depth offset; the overhead and corrected close view show the crossing.

## What the evidence does not establish

The learner uses a pausable integer-millisecond clock. The installed crossing uses timers and tweens, with original fractional durations and a cancellation ticket. The tests establish the draw rule and phase logic, not frame-identical live synchronization. A large clock jump can preserve a schedule while skipping poses and physical contacts. This is stated in the tutorial.

The station's local floor and standing approach pass; the whole hall's traversal is not certified. The loader reports an existing blocked authored entrance at (9.5, 0.05, 0.5) and uses a fallback. This pass does not repair that entrance. Test events are supplied by the probe. Physical headset use, Quest performance and an unfamiliar student's understanding remain open. Native images were visually inspected; browser layout has not been checked. Existing engine warnings are retained in the log, with no script or parse errors in the accepted run.

Source algorithms, scenes, map, sequence and inherited PointBody are unchanged from the baseline. Only the tutorial, targeted reflection, learner study, tests and planning records change.

Next: read all fourteen revised pairs as one sequence, check the handoff to Noise, and export the complete tutorial and reflective tracks for review.

[Facing pages](parallel.html) · [Before / after](changes.html) · [Review ZIP](random-game-review.zip)
'''

def update_plan():
    path=PLAN/'STATUS.json';status=json.loads(path.read_text(encoding='utf8'));row=next(r for r in status['halls'] if r['map']==MAP)
    row.update(status='revised; ready for review',tutorial_test='33 checks × 4 complete programs; 200 source waits per version; 4 faults rejected',museum_test='30 native checks passed; source cycle and controls; images inspected; headset untested',report=(HERE/'index.html').relative_to(ROOT).as_posix())
    path.write_text(json.dumps(status,indent=2),encoding='utf8')
    path=PLAN/'PLAN.md';text=path.read_text(encoding='utf8');start=text.index('### 14 ·');end=text.index('## Order and pressure points',start)
    text=text[:start]+'''### 14 · Random_Game — a wait kept

**Primary:** one cycling stone from r_c. **Bring:** cube translation, states, clocks, collision, seeded draws and PointBody. Full schedule class plus self-built model inside existing museum. Draw standing/hidden waits once, retain deadlines; fixed movement phases keep support and appearance distinct. One clock avoids stale timers on replay. Pause/quarter-step inspect exact instants. Shorten notice from1.2s to0.3s without changing events; fixed3s standing consumes no draw, shifting later stream use. Explicit clock differs from production timers/tweens; no frame-identical synchronization or skipped-contact guarantee. **Status:** revised;33 assertions ×4 complete programs,200 source wait comparisons each,4 faults rejected;30 native checks, images inspected. First probe assumed old button parent, corrected to actual compact console without production edits. Next: whole fourteen-hall reading, Noise handoff and combined review packet. Headset/unfamiliar learner remain separate.

'''+text[end:]
    path.write_text(text,encoding='utf8')
    path=ROOT/'doc/book/course/execution-plan/plan.json';plan=json.loads(path.read_text(encoding='utf8'));row=next(r for r in plan['lessons'] if r['id']==MAP)
    if not (HERE/'execution-row-before.json').exists():(HERE/'execution-row-before.json').write_text(json.dumps(row,indent=2),encoding='utf8')
    row.update(object='One cycling cube and its retained event schedule.',given='Existing Endless Museum player, XR Tools, camera, light and floor. Complete schedule, host and unchanged PointBody printed.',reuses='Cube translation, PointBody, local coordinates, clocks, states, seeded draws and collision.',later='Other hall encounters remain reflective comparisons. No rebuild of the full crossing, doors or field.',checks=['33 assertions in each of four complete printed programs;200 source waits each;4 faults rejected.','30 native museum checks; source controls/cycle, reset during motion, learner variants and local approach.'],transfer='Shorten advance notice to0.3s without changing events. Fix standing wait at3s and account for subsequent RNG stream use. Change seed to43.',next='Whole Randomness reading and review export; Noise asks about relationships between neighbouring samples.',notes='Revised/tested2026-10-09. Explicit pausable millisecond schedule reconstructs draw/phase semantics, not exact timer frames. No production changes or headset/independent learner acceptance.',summary='Return to the cube and give one stone a fixed sequence of states with sampled standing and hidden waits. Store each deadline once, then let the clock, ring, readout and collider respond to it. Pause or step through the sequence using the carried point. Shorten the warning while preserving every event; fix a wait and inspect which draws remain. Replay restores seed, clock, height and support. The larger crossing and other games remain encounters around this one complete reconstruction.')
    path.write_text(json.dumps(plan,indent=2,ensure_ascii=False)+'\n',encoding='utf8');publish_plan()

def main():
    tests=json.loads((HERE/'tests.json').read_text(encoding='utf8'))
    good=[r for r in tests['results'] if r['expected_pass']];bad=[r for r in tests['results'] if not r['expected_pass']]
    assert len(good)==4 and all(r['passed'] and r['checks']==33 for r in good)
    assert len(bad)==4 and all(not r['passed'] and r['failures'] for r in bad)
    run=ROOT/'ada_run/encounter_pilot'/MAP;receipt=json.loads((run/'report.json').read_text(encoding='utf8'))
    assert receipt['passed'] and len(receipt['checks'])==30
    log=(run/'engine.log').read_text(encoding='utf8');assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    for directory,names in [('museum',[n+'.png' for n in NAMES]+['report.json','engine.log','source_manifest.json','spec.json']),('museum-before',['hall-before.png','report.json','engine.log','source_manifest.json'])]:
        dest=HERE/directory;dest.mkdir(exist_ok=True);source=run if directory=='museum' else run/'game-before'
        for n in names:shutil.copy2(source/n,dest/n)
    baseline=json.loads((HERE/'before-manifest.json').read_text(encoding='utf8'))
    unchanged={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==sha for p,sha in baseline.items() if not p.endswith(('tutorial.md','final.md'))};assert all(unchanged.values()),unchanged
    texts={n:(ROOT/f'commons/maps/{MAP}/{n}.md').read_text(encoding='utf8') for n in ['tutorial','final']}
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S))
    for n,c in blocks.items():
        p=HERE/'extracted/printed'/n;assert p.read_text(encoding='utf8')==c+'\n' and hashlib.sha256(p.read_bytes()).hexdigest()==tests['printed_sha256'][n]
    reference='/book-images/figures/randomness/waiting-and-seeing.png'
    shutil.copy2(ROOT.parent/'ada_encyclopedia/public'/reference.lstrip('/'),HERE/'reference-waiting-and-seeing.png')
    def portable(text):return text.replace(reference,'reference-waiting-and-seeing.png')
    nav='<a href="index.html">Report</a><a href="parallel.html">Facing pages</a><a href="changes.html">Before/after</a><a href="sequence-plan.html">Sequence plan</a>'
    shell=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A wait kept</title><style>{STYLE}main{{max-width:1200px}}figure{{margin:24px 0}}figcaption{{font:14px/1.6 system-ui}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}@media(max-width:800px){{.pair{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav>'
    diffs=[]
    for n,text in texts.items():
        (HERE/f'{n}.md').write_text(portable(text),encoding='utf8');(HERE/f'{n}.html').write_text(page(n.title(),portable(text),nav),encoding='utf8')
        old=(HERE/f'before/commons/maps/{MAP}/{n}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),text.splitlines(True),fromfile=f'before/{n}.md',tofile=f'after/{n}.md'))
        (HERE/f'{n}.diff').write_text(diff,encoding='utf8');diffs.append(f'<h2>{n}.md</h2><pre>{html.escape(diff)}</pre>')
    def fig(name,caption,folder='museum'):return f'<figure><img src="{folder}/{name}.png" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'
    pictures=fig('crossing-and-study','The temporary learner model beside the existing crossing, inside Endless Museum.')
    pictures+='<div class="pair">'+fig('student-notice','Original: 0.9 seconds before the stored deadline, the ring is on.')+fig('student-short-notice','Edited notice: same clock and deadline, but the ring waits until the final 0.3 seconds.')+'</div>'
    pictures+='<details><summary>Other states and the hall</summary>'+fig('student-ready','Replay initializes the stone, its support and first wait, paused.')+fig('student-no-cue','CUE off: the ring changes; the tablet still discloses the same deadline.')+fig('student-hidden','GONE: the displayed stone has descended and its actual collider is disabled.')+fig('crossing','The installed three-stone crossing.')
    pictures+='<div class="pair">'+fig('hall-before','Existing hall before adding the temporary learner.','museum-before')+fig('hall-with-study','Same hall with the learner study beside the first crossing.')+'</div></details>'
    (HERE/'REPORT.md').write_text(REPORT,encoding='utf8');(HERE/'index.html').write_text(shell+'<h1>A wait kept</h1>'+pictures+markdown.markdown(REPORT,extensions=['extra'])+'</main></html>',encoding='utf8')
    (HERE/'changes.html').write_text(shell+'<h1>Before / after</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(portable(texts[n]),extensions=["extra"])}</article>' for n,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (HERE/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Game — facing pages</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}article{{min-width:0}}.spread h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase;color:#7c365b}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}<a href="tutorial.md">Tutorial source</a><a href="final.md">Reflection source</a></nav><h1>Random Game</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    update_plan();plan=(PLAN/'PLAN.md').read_text(encoding='utf8');(HERE/'sequence-plan.md').write_text(plan,encoding='utf8');(HERE/'sequence-plan.html').write_text(page('Randomness — plan',plan,'<a href="index.html">A wait kept</a>'),encoding='utf8')
    (HERE/'tools').mkdir(exist_ok=True)
    for p in ['tools/revise_random_game_lesson.py','tools/test_random_game_lesson.py','tools/publish_random_game_lesson.py','tools/probes/random_game_student.gd','tools/probes/random_game_museum.gd','tools/probes/random_game_before.gd']:shutil.copy2(ROOT/p,HERE/'tools'/Path(p).name)
    (HERE/'README.md').write_text('Start with parallel.html or index.html. Complete learner files are under extracted/printed; positive edits each have a full folder. Four other folders deliberately contain faulty programs. Prepared Endless Museum + XR Tools required, not a standalone project. The waiting-profile reference image predates this pass; all images under museum/ are new native captures. Portable final.md changes only its image URL. first-room-check retains a failed probe (old button parent) and an obstructed before-camera. These are author-informed checks, not headset or independent learner acceptance.\n',encoding='utf8')
    rendered=[html.unescape(c) for c in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(HERE/'tutorial.html').read_text(encoding='utf8'),re.S)]
    assert len(rendered)==3 and all((c+'\n').expandtabs(4) in rendered for c in blocks.values())
    archive=HERE/'random-game-review.zip';count=0
    for p in HERE.glob('*.html'):
        parser=Links();parser.feed(p.read_text(encoding='utf8'))
        for link in parser.links:
            if urlparse(link).scheme or link.startswith('#'):continue
            target=p.parent/unquote(link.split('#')[0]);assert target==archive or target.exists(),(p,link);count+=1
    verify={'rendered_code_parity':True,'positive_program_checks':[33]*4,'source_waits_per_version':200,'faults_rejected':4,'museum_checks':30,'local_targets_checked':count,'native_images_inspected':True,'unchanged_since_baseline':unchanged,'browser_layout':'Unverified','scope':'Author-informed reconstruction; supplied events, not headset or unfamiliar reader.'}
    (HERE/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf8')
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or p==archive or p.suffix=='.uid':continue
            if p.suffix in ['.md','.html']:
                content=p.read_text(encoding='utf8').replace('<a href="random-game-review.zip">Review ZIP</a>','Review packet: this folder').replace('[Review ZIP](random-game-review.zip)','Review packet: this folder');z.writestr(p.relative_to(HERE).as_posix(),content)
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
    print(json.dumps({**verify,'zip_crc':'pass','zip_links':'pass','zip_megabytes':round(archive.stat().st_size/1e6,2)},indent=2))
if __name__=='__main__':main()
