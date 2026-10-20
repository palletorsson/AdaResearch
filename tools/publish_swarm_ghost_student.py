"""Publish the bounded ghost-student rehearsal, including contrary results."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-swarm-ghost-student'
S = R / 'doc/book/iterations/2026-10-10-swarm-sequence-review'
N = R / 'ada_run/encounter_pilot/SwarmIntelligence_Particle_Swarm_Optimization/ghost-ridge'


def read(p): return json.loads(p.read_text(encoding='utf8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(s.encode('utf8'))


inputs, transfer, suite, native = map(read, [O/'input-manifest.json', O/'transfer-checks.json', S/'sequence-checks.json', N/'report.json'])
assert suite['passed'] and suite['completed'] and suite['total_checks'] == 265
for receipt, count in [(transfer, 78), (native, 31)]:
    assert receipt['passed'] and receipt['completed'] and not receipt['failures']
    assert len(receipt['checks']) == count and all(c['passed'] for c in receipt['checks'])
assert transfer['input_manifest_sha256'] == sha(O/'input-manifest.json')
assert transfer['predictions_sha256'] == sha(O/'PREDICTIONS.md')
assert transfer['probe_sha256'] == sha(R/'tools/probes/swarm_ghost_transfer.gd')
assert transfer['canonical_code_and_reflections_unchanged']
for before, current in zip(inputs['halls'], suite['halls']):
    assert before['hall'] == current['hall']
    hall = R/'commons/maps'/before['hall']
    assert sha(hall/'final.md') == before['canonical_final_sha256'] == current['final_sha256']
    assert sha(hall/'tutorial.md') == current['tutorial_sha256']
    blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', (hall/'tutorial.md').read_text(encoding='utf8'), re.S)
    assert {name: hashlib.sha256((code+'\n').encode()).hexdigest() for name, code in blocks} == before['printed_files']
    for name, digest in before['printed_files'].items():
        assert sha(O/'halls'/before['hall']/'code'/name) == digest
for path, digest in inputs['protected'].items():
    assert sha(R/path) == digest
native_sources = read(N/'source_manifest.json')
for path, digest in native_sources['sources'].items():
    assert sha(R/path) == digest, path
for log in [O/'engine.log', N/'engine.log', N/'stdout.log']:
    contents = log.read_text(encoding='utf8', errors='replace')
    assert 'SCRIPT ERROR' not in contents and 'Parse Error' not in contents

# Archive the successful evidence beside the report; rejected capture stays separate.
(O/'evidence/sequence').mkdir(parents=True, exist_ok=True)
shutil.copy2(S/'sequence-checks.json', O/'evidence/sequence/sequence-checks.json')
shutil.copytree(S/'receipts', O/'evidence/sequence/receipts', dirs_exist_ok=True)
for hall in suite['halls']:
    target = O/'evidence/sequence'/hall['log']
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(S/hall['log'], target)
(O/'museum').mkdir(exist_ok=True)
for p in N.iterdir():
    if p.name in ['report.json', 'source_manifest.json', 'engine.log', 'stdout.log'] or p.suffix == '.png':
        shutil.copy2(p, O/'museum'/p.name)
for name in ['run_swarm_ghost_student.py', 'probes/swarm_ghost_transfer.gd', 'probes/swarm_ghost_ridge_museum.gd']:
    target = O/'evidence/tools'/name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(R/'tools'/name, target)

names = ['Physarum', 'Flow Fields', 'Boids', 'Agent-Based Modeling', 'Ant Colony', 'Particle Swarm', 'Population Support']
reading = [
    ('A mark outlives its maker', 'The point, addressed grid and sensor samples give a small, reconstructable operation: read, move, fade and deposit. I changed retention to 0.8 and removed all agents; a mark of strength 2 became 1.28 after two ticks. The reflection’s inherited trace has a concrete counterpart. The exact-value exercise needed a clean starting field; its reset is now explicit.'),
    ('A direction is supplied', 'The familiar field lookup now returns a vector, not a deposited quantity. From velocity (1,0), a zero direction gives (0.9,0): the body brakes. Reading leaves the field unchanged. This distinction prepares the next hall and keeps received direction separate from collective agreement. The return-to-exhibit passage also names the larger exhibit’s different zero-direction response.'),
    ('Neighbours supply competing requests', 'This is the steepest lesson: neighbour selection, three requests, limits and one shared snapshot arrive together. Reused steering makes it manageable. No neighbours means coast; neighbours with cancelling velocities can request braking. The strict radius boundary is testable. The one-step recipe was ambiguous because RUN is continuous; the text now locates exact stepping in flock.gd and keeps spatial observation in the room.'),
    ('The point carries a state', 'The Boolean and visible cargo give a clear change of task. With return speed 2, the stated fixture reaches (7.99,8) and ignores a stronger side trace: it is returning toward a known home. Replacing bodies keeps the field; Reset clears it. This is a return to earlier trace work with a new decision, not an unnoticed continuation of the flocking model.'),
    ('State selects the channel', 'The strongest consecutive handoff is ABM to Ant Colony. The same carrying flag now selects which trail to read and which to leave. A stronger home-side sample bends a returner; a searcher ignores that channel. A changed deposit affects only its named field. The full-size host makes the shared ground visible, while the reflection can ask what travellers inherit without promising an optimal route.'),
    ('A score keeps a position', 'The model change is stated: trails give way to personal and shared best records. Changing the objective preserves current motion but rebuilds scored memories. Zero shared attraction does not erase personal memory. The independent RIDGE comparison then asks a question the normal assertions do not decide. A good remembered score and a dispersed current population are different observations.'),
    ('The account exposes support', 'The final hall deliberately changes scale. The supplied ecosystem remains declared background; the new operation counts and reconciles copied events. In a fresh fixture, 8 + 3 − 2 + 4 gives 13; hiding supply reports 9 while all bodies remain. Food is not counted as a creature. The reflective question about dependence stays attached to this visible omission and leads coherently to relations in Graph Theory.'),
]
hall_text = ''
for index, (name, (title, body), hall) in enumerate(zip(names, reading, suite['halls']), 1):
    hall_text += f'### {index}. {name} — {title}\n\n{body}\n\n'
    hall_text += f'Original input: [tutorial](halls/{hall["hall"]}/tutorial.md) · [reflection](halls/{hall["hall"]}/final.md). Known lesson checks: {hall.get("checks", hall.get("check_count", "see receipt"))}.\n\n'

table = '| Seed | Shared pull | Step | Spread | Mean current score | Shared best |\n| --- | --- | --- | --- | --- | --- |\n'
for run in transfer['observations']['ridge']:
    for sample in run['samples']:
        table += f'| {run["seed"]} | {run["social_pull"]} | {sample["step"]} | {sample["spread"]:.6f} | {sample["mean_current_score"]:.4g} | {sample["shared_best_score"]:.4g} |\n'

report = f'''# Swarm — the ghost student tries the sequence

**All seven printed lessons reconstructed and ran. Two instruction gaps surfaced and are corrected.** The progression holds: trace → supplied direction → neighbours → state → two trails → scored memory → population account.

This was an **author-operated ghost-student rehearsal with prior project context**. I read the supplied review package, wrote predictions, reconstructed its named code blocks, exercised the complete hosts and tried changes across the handoffs. It is not a blind reader study or a physical headset session.

## What actually ran

| Evidence | Result | What it establishes |
| --- | --- | --- |
| Fresh reconstruction | 22 printed scripts; 7 minimal attached-script scenes | The lessons supply the student code. No author study scripts or prebuilt lesson scenes were used as reconstruction inputs. |
| Existing lesson suite, rerun | 265 checks passed | Seven code variations and 21 deliberately faulty variants are included in the established checks. This is reused test coverage. |
| New ghost-student tests | 78 checks passed | New predictions, cross-hall differences, full host creation, synthetic desktop grab/release under translation and rotation, accounting and seeded repeats. |
| New native museum investigation | 31 checks passed; 9 images | Reconstructed PSO host in the existing hall, four parameter/seed cases, numerical agreement and displayed-position agreement after rendering. |

These counts describe different check sets, not a percentage of everything a learner might do. The prepared museum supplies XRTools, buttons and the declared ecosystem. The examples are not empty-project starters. PointBody is byte-identical across the seven lessons; that means a reused class, not one persistent instance automatically carried through every portal.

## Reading the seven halls

{hall_text}
## Two instructions that code tests alone missed

**Physarum: establish the starting state.** A sensor reading of exactly 1 is only predictable after clearing earlier marks. Without Reset, the reproduced fixture read 2. The tutorial now says Pause, Reset, deposit once, then repeat the comparison from another reset.

**Boids: identify where a step happens.** The room exposes RUN, RULE, RADIUS and RESET. It has no one-step button. The tutorial now tells the reader to instantiate flock.gd, select the mode, call step() once and inspect velocities[0] for the numerical checks. Each comparison begins with a fresh model; the room remains the place to observe its continuous response.

Two additional status sentences now link the completed optional investigation. See [instruction-fixes.json](instruction-fixes.json) for all four text edits. All printed code, all seven reflections, museum runtime code, sequence order and plan decisions remain unchanged. The 265 checks were rerun against the corrected canonical texts. The new 78 checks still execute the original printed code, which is identical.

## The open question produced an answer we should keep

The prediction was that lowering shared attraction from 1.5 to 0.3 might preserve more dispersion on RIDGE. I compared the same starts at steps 0, 20 and 100, repeated both settings, and then repeated the comparison with a second seed. Spread means the largest pairwise distance in model units. Current scores and the remembered shared best are recorded separately.

**Weaker attraction left a wider group at step 100 in both seeds, but all four cases still formed a very small cluster.** It did not maintain a scattered population. Many equally scoring positions are available on the diagonal; the update rule nevertheless gathers these runs around one neighbourhood. The two seeded trials do not establish a general theorem about dispersion.

{table}
At step 100 the largest weak-pull spread is about 0.026 model units, far smaller than a displayed sphere. Overlapping spheres therefore appear as one body in the images. A numerical shared best of zero does not mean every current score is exactly zero. The hypothesis about worse current scores is not consistently supported at step 100; keep the measured values rather than turn it into a passing assertion.

The images below come from a fresh isolated run of the actual Endless Museum PSO hall. The reconstructed host temporarily occupied its existing placement. Production artifact files were not edited. The model paused at each recorded step, while the host kept updating its display.

### Same camera, same starting seed

![RIDGE start: 24 spheres in the existing museum hall](museum/ridge-start.png)

Seed 101006, before stepping. Current positions are distributed across the floor.

![Shared pull 1.5 at step 20](museum/ridge-101006-pull-1-5-step-20.png)

Shared pull 1.5, step 20. Spread 4.202247.

![Shared pull 0.3 at step 20](museum/ridge-101006-pull-0-3-step-20.png)

Shared pull 0.3, step 20. Spread 4.895802.

![Shared pull 0.3 at step 100](museum/ridge-101006-pull-0-3-step-100.png)

Shared pull 0.3, step 100. Twenty-four records remain, but their overlapping display looks like one body. Spread 0.025625. All nine captures and their exact cases are listed in the [native receipt](museum/report.json).

## A useful failure in the test itself

The first museum capture passed numerical comparisons but showed stale sphere positions: the probe had disabled the host's display processing. Visual inspection caught the discrepancy. The corrected probe leaves the host processing while its simulation is paused, then asserts displayed positions against model positions after rendering. The successful 31 checks include that guard. The rejected attempt is retained under rejected-native-capture/, with its explanation. This was a capture-harness correction, not a repair to the lesson or museum algorithm.

## What this says about the chapter

The route builds capacity through recognisable tools and explicit changes of model. ABM → Ant Colony is its strongest continuous development. Boids carries the highest local density; keep its individual rule comparisons before the combined result. PSO → Population Support works because the text names a new scale of inquiry instead of implying that the ecosystem extends the optimizer.

The reflective texts retain their own work. A recorded mark can support an encounter with inheritance; an omitted supply can support a question about dependence. Neither code execution nor an assertion proves a social interpretation. No additional theory or code is needed in final.md to complete this test.

The remaining concern is spatial integration. The first four learner hosts are temporary comparison studies; the last three are permanent full-size installations. This run instantiated every complete host, but rendered only the PSO investigation freshly inside its hall. It did not traverse all seven rooms in a headset or validate every existing exhibit. The earlier artifact inventory's visibility and missing-placement findings remain open.

## Evidence and replay

- [Predictions recorded before execution](PREDICTIONS.md)
- [Original package and reconstructed-file hashes](input-manifest.json)
- [78 new checks and all RIDGE measurements](transfer-checks.json)
- [265 fresh checks on the corrected canonical texts](evidence/sequence/sequence-checks.json)
- [31 native checks](museum/report.json) and [native source hashes](museum/source_manifest.json)
- [Exact instruction corrections](instruction-fixes.json)

The halls/ directory preserves the original review inputs; the current canonical tutorials include the corrections above. The updated reviewer ZIP contains the corrected texts at its top level and this original-input record under ghost/.

In the prepared AdaResearch project: run `python tools/run_swarm_ghost_student.py`, then the native probe with `python tools/run_encounter_probe.py SwarmIntelligence_Particle_Swarm_Optimization --sequence swarmintelligence --render --no-bridges --output-tag ghost-ridge --probe tools/probes/swarm_ghost_ridge_museum.gd`. The --prepare option is for the original extraction only and refuses to overwrite its input record. If canonical text changes again, rerun `python tools/test_swarm_sequence.py` before publishing.

Short memory: Same PointBody; seven distinct models. ZIP→predict→reconstruct→vary→compare→inspect images. 22 scripts; 265 existing + 78 new + 31 native checks pass. Reset and one-step instructions clarified. RIDGE weak pull widens these runs slightly, does not sustain dispersion. Author-operated, not blind/headset. First4 spatial integration remains open. Keep order and reflections.
'''
write(O/'REPORT.md', report)
css = '''*{box-sizing:border-box}body{margin:0;background:#f3f1e9;color:#193b3d;font:18px/1.65 Georgia,serif}nav{background:#163c3c;padding:16px 24px;font:14px/1.5 system-ui}nav a{color:#d9f3eb;margin-right:25px}main{max-width:1080px;margin:38px auto;padding:0 24px 70px}h1{font-size:46px;line-height:1.15}h2{margin-top:48px}h3{margin-top:32px}a{color:#0d6570}table{display:block;overflow:auto;border-collapse:collapse;font:15px/1.55 system-ui}th,td{padding:12px;text-align:left;border-bottom:1px solid #b5c6be;vertical-align:top}img{display:block;max-width:100%;height:auto;margin-top:25px}code{font:14px/1.5 Consolas,monospace;overflow-wrap:anywhere}pre{white-space:pre-wrap;background:#e4ebe3;padding:16px}@media(max-width:700px){h1{font-size:34px}main{padding:0 18px 50px}}'''
body = markdown.markdown(report, extensions=['extra', 'sane_lists'])
write(O/'index.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Swarm · ghost-student rehearsal</title><style>'+css+'</style></head><body><nav><a href="http://localhost:3003/book-review/doc/book/iterations/2026-10-10-swarm-complete-readings/index.html">Seven halls</a><a href="REPORT.md">Report text</a><a href="transfer-checks.json">New checks</a><a href="museum/report.json">Museum evidence</a></nav><main>'+body+'</main></body></html>')
write(O/'publication-checks.json', json.dumps({'passed':True, 'printed_files':22, 'existing_checks':265, 'new_checks':78, 'native_checks':31, 'same_pointbody':True, 'printed_code_and_reflections_unchanged':True, 'input_manifest_sha256':sha(O/'input-manifest.json'), 'transfer_receipt_sha256':sha(O/'transfer-checks.json'), 'sequence_receipt_sha256':sha(S/'sequence-checks.json'), 'native_receipt_sha256':sha(N/'report.json')}, indent=2)+'\n')
print('Ghost report published: 22 scripts, 265 existing / 78 new / 31 native checks; two instruction gaps corrected.')
