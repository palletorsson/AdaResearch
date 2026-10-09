"""Publish the evidence without changing the lessons or museum."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import zipfile
from html.parser import HTMLParser
from urllib.parse import unquote, urlparse
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-wavefunctions-ghost-student'

NOTES=[
 ('Time → position; inherited cube.', 'height_at; amplitude, frequency, phase.', 'The smallest entry works: 33 lines, all objects initialized. A photograph of the middle cannot distinguish rising from falling; the reflection gives a reason to inspect phase.', 'Make the second-cube prediction before consulting the supplied table. A successful copy alone does not demonstrate that distinction.'),
 ('Forces integration + Trace → timestamped observations.', '_physics_process; Sample; display_position.', 'The 20-slot variation retained 1.9 seconds after eight simulated seconds. The swing was unchanged. Data, retention policy and drawing can be varied separately.', 'First density jump: 33 to 107 main-script lines. Read the swing update, then the record, then the drawing in three passes; do not treat all three as equally new.'),
 ('Grid + faces + carried physical PointBody → a contact surface.', 'height_at; row/column indices; the mesh used for collision.', 'Separate X and Z frequencies produced different spatial periods without changing connectivity. The code and text distinguish static terrain from a wave moving in time.', 'Retain the explicit finite-sheet limitation: the ball may roll off. The broad walkable museum basin is a separate, larger encounter.'),
 ('One angle → circle coordinates and graph coordinates.', 'circle_position; graph_position; one shared angle.', 'Changing radius, centre and angular speed preserved the shared height and the independent four-metre angle axis.', 'The lesson comes after using sine. This works as a return that opens an already-used function; it should not be sold as the first-ever introduction to sine.'),
 ('Forces + arrays → neighbour coupling.', 'reset; step; old and next arrays.', 'The first step matched a hand calculation. Reversing iteration for 120 steps preserved the result; an in-place mutation failed. This is a substantial new capacity.', 'Keep the numerical timestep and boundary explanation. A wave-shaped animation is not evidence of coupling; the reflection asks exactly the useful question.'),
 ('Oscillation + the carried hand control → phase-modulated audio.', 'phase_depth; sample_at; reference versus captured comparison.', 'Changing the ratio to 1.5 preserved all zero-depth bytes and changed the positive-depth sound data. Both retained 26,460 samples. The fresh museum study loaded and accepted its action.', 'Highest conceptual load: modulation, envelopes, PCM bytes, asynchronous playback and plotting coexist. The text already identifies the core and supplied encoder. Protect that distinction in layout; do not require mastery of every support function.'),
 ('Unit Circle + face lists → a turn distributed through height.', 'ring_position; rebuild; separate parent rotation.', 'The taller twelve-corner shaft produced 206 positions and 408 faces. Triggered rotation changed its pose without rewriting stored geometry.', 'The oval profile makes the operation legible. The reflection can ask what the gallery contributes without making mathematical generation explain the whole architectural reference.'),
 ('Recorded observations → a retained event score.', 'new_score; replay; elapsed time and cursor.', 'A .75-second interval produced six cumulative timestamps. A late frame dispatched four overdue events in order. Replay preserved the score and RNG state.', 'This is a bounded introduction to chance before Randomness. Keep the focus on choosing once versus replaying; do not expand it into distributions here.'),
 ('Contact events + recorded audio → independent voice lifetimes.', '_on_contact; ages_now; sum_at.', 'Real sphere-area contacts started two equal-pitch voices at different ages. The first continued when the second began. Same sound data did not imply one shared clock.', 'Nearly 200 printed lines including helpers. Read contact and voice ownership first, then the scope. The plain decaying sine does not model metal resonance; the revised text states that correctly.'),
 ('Cube + sampled coordinates → support.', 'sample_position; tread transform; matching shape dimensions.', 'Constant radius with a new rise gave top heights 0, .75 and 1.5 m. Tread transforms matched sampled tops. Existing teacher checks also exercised physical contact.', 'This study proves construction, not a comfortable climb. The reflection productively distinguishes a visible invitation from bodily access. Keep the step controller outside the promised lesson.'),
 ('Independent waves → a signed sum and relative phase.', 'values_at; candidate_frequency; restart_pair; plot gain.', 'The 6 and 5.75 Hz variation cancelled after two seconds and reinforced after four. It retained the envelope period despite different source rates.', 'The half-gain label matters: an equally tall picture need not represent equal raw amplitude. Return explicitly to Air Music after the spatial stair interlude.'),
 ('A two-wave sum → a list of harmonic contributions.', 'contribution; sum_at; duplicate baseline; shared phase.', 'The new odd recipe gave .5 at PI/2. Removing H3 raised it to 1. Restoring baseline preserved phase and hold. The fresh museum reconstruction also passed.', 'The finite visual instrument completes the required tutorial. Audible synthesis and Room Memory remain extensions. Small labels and a busy background deserve a separate visual refinement; no need for another mandatory concept.')
]

def main():
    manifest=json.loads((OUT/'manifest.json').read_text())
    regressions=json.loads((OUT/'regression-results.json').read_text())
    transfer=json.loads((OUT/'transfer-corrected.json').read_text())
    mutations=json.loads((OUT/'mutation-results.json').read_text())
    assert all(r['passed'] for r in regressions) and transfer['passed']
    assert all(r['rejected_for_expected_reason'] for r in mutations)
    assert hashlib.sha256((OUT/'predictions-before.md').read_text(encoding='utf8').encode()).hexdigest()==manifest['predictions_sha256']
    unchanged={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in manifest['protected'].items()}
    assert all(unchanged.values())
    parity=[]
    for row in manifest['rows']:
        assert row['archive_matches']==[True]
        text=(OUT/'packet'/row['map']/'tutorial.md').read_text(encoding='utf8')
        for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S):
            assert (OUT/'attempt'/row['map']/name).read_text(encoding='utf8')==code+'\n'
            parity.append({'map':row['map'],'file':name,'matches_printed_listing':True})
        assert hashlib.sha256((OUT/'attempt'/row['map']/'transfer.gd').read_bytes()).hexdigest()==row['transfer_hash']
    museum=[]
    for folder in sorted((OUT/'museum').iterdir()):
        receipt=json.loads((folder/'report.json').read_text())
        assert receipt['passed']
        log=(folder/'engine.log').read_text(encoding='utf8',errors='replace')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
        museum.append({'map':folder.name,'checks':len(receipt['checks']),'passed':True,'reported_errors':[s for s in log.splitlines() if s.startswith('ERROR:')]})
    total=sum(r['checks'] for r in regressions)
    report=f'''# Wavefunctions — a ghost student goes through the sequence

**All twelve printed studies ran successfully from newly extracted files. The sequence holds as a continuation of the earlier spine. The main remaining work is reducing reading friction, especially around audio.**

This is a same-assistant ghost-student simulation. I had already read and helped develop the material and its tests. It is a fresh reconstruction and an executable reading, not a blind learner study. A prepared Endless Museum project supplies XR Tools, player, camera, light and floor. These are not standalone empty-project examples.

## What was tested

- Read the twelve current `tutorial.md` and `final.md` pairs in spine order. Each tutorial matched the review ZIP.
- Extracted all **32 complete printed listings** into new hall folders; no production lesson script filled a missing dependency.
- Saved predictions before the fresh run. Reconstructed the six companion exercise versions required by the existing checks, plus a new variation for every hall.
- Ran the existing teacher-authored checks against the extracted files: **{total} assertions passed across 12 halls**.
- Executed the new twelve-hall variations: **37 checks passed**, after correcting one faulty test assertion described below.
- Deliberately broke three rules. All three were rejected for the intended reason: mixed old/next state, a score redrawn during replay, and unsigned harmonic contributions.
- Loaded the extracted opening, Effect Sound and Synthesis programs inside the actual Endless Museum: **223 checks passed across those three representative halls**. Captured and inspected their images.

No lesson-code or manuscript correction was needed to run the required examples. The 24 canonical manuscripts remain unchanged. This run does not certify human understanding, audible timbre, headset comfort, all twelve placements afresh, or continuous travel through every portal. Audio ran through Godot's Dummy driver; sample data and playback/contact behaviour were checked rather than listened to.

## What the student can carry

The continuity is in objects **and operations**. The cube carries a prescribed return into a measured swing and later becomes a tread. PointBody returns as a physical ball, an ungrabbable marker, a hand control and several independent controls. Those role changes are declared. Trace's recorded list becomes timestamped history and later an event score. The final sum extends two named contributions into a list and loop.

This is not one script receiving an extra function in every room. It is a set of related studies in the same prepared world, reusing known constructions. That distinction should remain explicit. No new order is needed on the evidence of this run: Bernini and Sky Stairs are deliberate returns to spatial construction, and Cage interrupts periodic expectation with retained choices. The transitions now explain those turns.

## Where I would improve the teaching next

1. **Guide the first reading through functions.** Pendulum jumps from 33 to 107 main-script lines. Its swing, recorder and display deserve three distinct reading passes. Effect Sound and Air Music need an equally clear core-operation route before their encoding and display support. Keep complete code available; do not shorten it into an incomplete example.
2. **Separate prediction from the answer.** Many useful predictions are immediately followed by their results. For a stronger learner test, collect the prediction before revealing the explanation, then ask for another parameter choice. This run's edited versions demonstrate executable possibilities, not that an unassisted reader discovered them.
3. **Make the learner study easier to identify in the museum.** The fresh opening capture contains background orbital labels, and the Synthesis readout is small against other exhibits. Existing objects need not be removed. A quiet display backing and nearby readable instructions are candidates for a separate visual pass.

The reflective texts continue to do their own work: they ask what a record omits, what support a drawing promises, what chance can select and what restoring a recipe cannot restore. They should not become another copy of the implementation explanation. Several exact distinctions in the tutorials give those questions something to rest on.

## First-run failure: the test was wrong

The first transfer run passed 36 of 37 checks. My Air Music assertion expected sample 60 from `int((60.0 / 44100) * 44100)`. In this run the floating-point result truncated to **59**. The lesson's sample lookup behaved as written; the checker assumed exact arithmetic at a bin boundary. The measured sum was −0.1295205542 instead of the checker's −0.1334269234.

I preserved [the first result](transfer-first.json), [its log](transfer-first.log) and [the original checker](transfer-first-probe.gd). The corrected check chooses ages inside the intended bins, at 60.25 and 180.25 samples. [The corrected result](transfer-corrected.json) passes all 37 checks and records the boundary diagnosis. No lesson code was altered to make the test pass. An earlier Python setup guard also needed newline-normalized hashing on Windows; it failed before Godot execution and did not change the saved predictions.

## Scope of the engine results

The museum runs still log an unrecognized project UID; Effect Sound also logs two ViewportTexture setup errors from the existing environment. No GDScript parse or runtime script error was reported, and the nominated checks passed. These logs are retained: a passing lesson is not a claim that the whole project has no warnings or errors. The rendered captures show the learner studies in the real halls, not substitute rooms.

## Hall-by-hall reading

'''
    for i,(row,note,result) in enumerate(zip(manifest['rows'],NOTES,regressions),1):
        lineage,core,finding,pressure=note
        count=sum(c['hall']==row['map'] for c in transfer['checks'])
        report+=f'''### {i:02}. {row['title']}

**Carries:** {lineage} **Read/change:** {core}

{finding}

**Attention:** {pressure}

**Before execution:** {row['prediction']}

**Result:** {result['checks']} existing checks + {count} new transfer checks passed. Main program: {row['main_lines']} lines; complete listing with helpers: {row['code_lines']} lines. These are scope counts, not learning scores.

[Printed tutorial](packet/{row['map']}/tutorial.md) · [Reflection](packet/{row['map']}/final.md) · [Reconstructed main script](attempt/{row['map']}/{row['main']}) · [Changed version](attempt/{row['map']}/transfer.gd) · [Runtime receipt](evidence/{row['map']}/teacher-checks.json)

'''
    report+='''## Evidence and continuation

[Predictions before the run](predictions-before.md) · [Source manifest](manifest.json) · [All existing-check results](regression-results.json) · [New variation results](transfer-corrected.json) · [Deliberate faults](mutation-results.json) · [Verification](verification.json)

Keep the current sequence and its required studies. The next useful evidence is an unfamiliar reader recording predictions and reconstruction difficulties without access to these answers, followed by a headset visit for the physical comparisons. The current exercise confirms that the printed construction can support that test; it does not replace it.
'''
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    style='''*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#202624;font:18px/1.65 Georgia,serif}header,main{max-width:1100px;margin:auto;padding:40px 32px}header{padding-bottom:16px}h1{font-size:clamp(32px,5vw,64px);line-height:1.07;max-width:900px}h2{font-size:30px;margin-top:2em}h3{font-size:24px;border-top:1px solid #b4b7ad;padding-top:28px}a{color:#255349;text-underline-offset:4px}nav,.tag,figcaption,.stats{font:14px/1.5 system-ui}nav{display:flex;flex-wrap:wrap;gap:20px}.tag{text-transform:uppercase;letter-spacing:.12em;color:#466357}.stats{display:flex;gap:12px;flex-wrap:wrap;margin:26px 0}.stats span{background:#dce4d8;padding:12px 18px;border-radius:5px}.pictures{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.pictures img{width:100%;height:auto;border:1px solid #b4b7ad}figure{margin:0}figcaption{padding:10px 0}code{font-size:.85em;background:#e3dfd6;padding:2px 4px}p,li{max-width:900px}article>h1{display:none}table{border-collapse:collapse;width:100%}td,th{text-align:left;padding:8px;border-bottom:1px solid #bbb}@media(max-width:750px){.pictures{grid-template-columns:1fr}main,header{padding:24px 18px}}'''
    images=[('WaveFunctions_Intro','The cube and its initialized readout. Background orbital displays compete for attention.'),('WaveFunctions_Effect_Sound','The carried point selects phase depth beside the existing instrument.'),('WaveFunctions_Synthesis_Lab','Five carried points select five amounts. Readout size remains a visual concern.')]
    pictures=''.join(f'<figure><a href="museum/{m}/student.png"><img src="museum/{m}/student.png" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)} <a href="museum/{m}/report.json">Museum checks</a></figcaption></figure>' for m,caption in images)
    body=markdown.markdown(report,extensions=['tables','fenced_code'])
    page=f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Wavefunctions — ghost student test</title><style>{style}</style></head><body><header><div class="tag">Endless Museum · 8 October 2026 · Executable reading</div><h1>A ghost student goes through Wavefunctions</h1><nav><a href="REPORT.md">Report as text</a><a href="ghost-student-evidence.zip">Download evidence</a><a href="../2026-10-08-wavefunctions-reading-pass/tutorial.html">Full tutorial</a><a href="../2026-10-08-wavefunctions-reading-pass/final.html">Full reflection</a></nav><div class="stats"><span>12 printed programs run</span><span>334 existing checks</span><span>37 new transfer checks</span><span>3 fresh museum visits</span></div><p>Fresh files and real execution. Same assistant, so this is not a blind learner test.</p><div class="pictures">{pictures}</div></header><main><article>{body}</article></main></body></html>'
    (OUT/'index.html').write_text(page,encoding='utf8')
    (OUT/'README.md').write_text('Start with REPORT.md. packet/ freezes current printed readings. attempt/ contains exactly extracted required files, exercise variants and new transfer.gd edits. predictions-before.md precedes execution. Existing teacher receipts and new author-made transfer receipts are distinct. museum/ contains three native museum visits. This is not a standalone Godot project: run in the prepared Endless Museum. No independent-reader or physical-headset claim. First failed test and corrected test are preserved. The source scripts in tools/ require the repository; their paths are evidence of how this run was made.\n',encoding='utf8')
    target=OUT/'tools';target.mkdir(exist_ok=True)
    for file in ['tools/test_wavefunctions_ghost_sequence.py','tools/probes/wavefunctions_ghost_transfer.gd']:
        shutil.copy2(ROOT/file,target/Path(file).name)
    for row in manifest['rows']:
        src=ROOT/f'tools/probes/wavefunctions_{row["probe"]}_student.gd'
        shutil.copy2(src,target/src.name)
    class Links(HTMLParser):
        def __init__(self):super().__init__();self.links=[]
        def handle_starttag(self,tag,attrs):
            for k,v in attrs:
                if k in ['href','src']:self.links.append(v)
    parser=Links();parser.feed(page)
    local=[]
    for link in parser.links:
        if urlparse(link).scheme or link.startswith('#') or link in ['ghost-student-evidence.zip','verification.json']:continue
        path=(OUT/unquote(link.split('#')[0])).resolve()
        assert path.is_file(),link
        local.append(link)
    verification=dict(passed=True,canonical_manuscripts_unchanged=unchanged,printed_file_parity=parity,all_tutorials_match_review_zip=True,predictions_unchanged=True,transfer_files_unchanged=True,regression_assertions=total,new_transfer_checks=len(transfer['checks']),museum_visits=museum,local_page_references=len(local),method='Same-assistant reconstruction and runtime tests, not independent learning evidence.')
    (OUT/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf8')
    archive=OUT/'ghost-student-evidence.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for file in OUT.rglob('*'):
            if not file.is_file() or file==archive or file.suffix in ['.uid','.import']:continue
            # Mutant copies are redundant; retain each mutation's receipts, logs and changed script.
            relative=file.relative_to(OUT)
            if relative.parts[0]=='mutations' and 'attempt' in relative.parts and file.name!='transfer.gd':continue
            # Evidence packet links to text, not the repository-hosted HTML navigation.
            if file.name=='index.html':continue
            z.write(file,relative.as_posix())
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
    print(json.dumps({'passed':True,'printed_files':len(parity),'existing_assertions':total,'transfer_checks':len(transfer['checks']),'museum_assertions':sum(r['checks'] for r in museum),'local_links':len(local),'zip_mb':round(archive.stat().st_size/1048576,2)},indent=2))

if __name__=='__main__':main()
