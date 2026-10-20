"""Publish the installed Population Support controls and native evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
H = 'SwarmIntelligence_Swarm_Intelligence_Algorithms'
O = R / 'doc/book/iterations/2026-10-11-swarm-the-account-in-hand'
RUN = R / f'ada_run/encounter_pilot/{H}'
CODE = R / 'doc/book/iterations/2026-10-10-swarm-who-keeps-the-count'
NATIVE = 'account-hand-first'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


receipts = {'code': read(CODE / 'checks.json'),
            'museum': read(RUN / NATIVE / 'report.json'),
            'portals': read(RUN / 'account-hand-portals/report.json')}
assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts.values())
for p in [CODE / 'code.log', RUN / NATIVE / 'stdout.log', RUN / 'account-hand-portals/stdout.log']:
    log = p.read_text(encoding='utf-8')
    assert not any(s in log for s in ['SCRIPT ERROR', 'SHADER ERROR', 'blocked authored entry', 'blocked t exit']), p
preserved = read(O / 'before/preserved-hashes.json')
assert all(sha(R / p) == value for p, value in preserved.items()), 'Preserved source/text changed'
for name in ['study.gd', 'observed.gd', 'account.gd', 'point_body.gd']:
    assert (R / 'commons/artifacts/population_account_walk' / name).read_bytes() == (R / 'doc/book/studies/swarm-through-the-hands' / H / name).read_bytes()
for folder in ['assets', 'evidence']:
    (O / folder).mkdir(exist_ok=True)
for view in ['above', 'field', 'controls']:
    for label, tag in [('before', 'account-hand-before'), ('after', NATIVE)]:
        shutil.copy2(RUN / tag / f'{view}.png', O / 'assets' / f'{view}-{label}.png')
for view in ['dock', 'full-account', 'omitted-account', 'support-in-room']:
    shutil.copy2(RUN / NATIVE / f'{view}.png', O / 'assets' / f'{view}.png')
for name, tag in [('museum', NATIVE), ('portals', 'account-hand-portals')]:
    for source, suffix in [('report.json', 'checks.json'), ('stdout.log', 'log'), ('source_manifest.json', 'sources.json')]:
        shutil.copy2(RUN / tag / source, O / 'evidence' / f'{name}-{suffix}')
shutil.copy2(CODE / 'checks.json', O / 'evidence/code-checks.json')
shutil.copy2(CODE / 'code.log', O / 'evidence/code-log')
counts = {name: len(receipt['checks']) for name, receipt in receipts.items()}
total = sum(counts.values())
obs = receipts['museum']['observations']
samples = sum(r['samples'] for r in obs['routes'].values())
report = f'''# The account in hand

Endless Museum · Population Support · 11 October 2026

Carry the account beside a living point. Its two columns separate prey and predators; each records the initial population, births, losses and supplied bodies. Compare the expected population with the actual population in front of you. The selected sphere keeps its arrival source and health visible on the same panel.

## One paragraph for the lesson

Bring the familiar PointBody from Particle Swarm. Its best position is no longer the record we need: now ask how this body arrived and what keeps the population present. Run the existing ecosystem until a gold-ringed sphere appears. Hold it, select it with its trigger and inspect its supplied origin. Use the event dictionaries and their array to reconstruct the population: initial plus born, minus lost, plus supplied. Compare that prediction with the actual organism lists. Omit the supplied row and explain the gap while the same bodies remain visible. Restore the row; the count agrees again. Moving the sphere keeps its identity and origin. To demonstrate understanding, reconcile the predator column too, and explain why food added from outside is not itself another birth. Carry that distinction into Graph Theory: a line can represent an encounter, but it can also represent an operation that makes encounters possible.

Learning elements: **event dictionaries; an array of records; immutable history copies; aggregation by kind and species; expected versus observed count; the limits of an account.**

## In the museum

Enter **Swarm Intelligence → Swarm Intelligence Algorithms (Population Support)**. Take the small black grip beside the entrance control bank. Its trigger toggles RUN / PAUSE. Four buttons call the existing RUN / PAUSE, ONE STEP, RESTART and SUPPLY ROW commands.

Hold a large sphere with the other hand and press its trigger to select it. The model pauses while an organism is held. Its arrival source—INITIAL, BIRTH or SUPPLIED—and health appear above the account. Release the organism before stepping or restarting. Holding the control grip alone does not pause the simulation.

SUPPLY ROW filters only the calculation. It remains usable while a sphere is held, so the full and filtered accounts can be compared without another model update. Gold rings and recorded events remain. The gap turns red when actual and expected differ; zero is green. The original end controls operate the same state.

Drop the panel and it returns to its dock after five seconds. Regrabbing cancels that return. The panel grip is not another organism.

## A real comparison

After thirty seconds of this seeded run, the prey account reads **50 initial + 0 born − 49 lost + 10 supplied = 11**, matching the eleven living prey. Omitting supplied arrivals predicts one instead: ten bodies are unexplained by the filtered account. The photographed sphere and its gold ring remain in both views.

The first supply event occurred at tick {obs['first_supply_tick']}, or {obs['first_supply_tick']/60:.2f} seconds of model time. This is evidence from one run, not a guarantee about every intervention. Simulation pauses and slow frames also affect the wall-clock wait.

The supplied total is cumulative history. It can include bodies that have since died, so an omitted-row gap is not generally the number of gold rings still visible. The predator column may have a zero gap even when supply is omitted, if no predators have been supplied. Neither a zero gap nor a complete count establishes a complete explanation of the ecosystem.

Outside food and pressure remain recorded and visible in the original wall notes. They are not additional creatures. Those later effects are part of what this compact population account leaves open.

## What changed

Added one portable account through the existing museum wrapper, with a 25-degree panel, a small dock and four existing commands. The full-size ecosystem, original control banks and all simulation rules remain. No map, museum-plan, sequence, tutorial or final text changed. All {len(preserved)} recorded source/text hashes match, including the original ecosystem and printed student files.

The tutorial continues to teach the complete account and observer code. The new museum panel is a second view of that same account. The reflective text stays close to the encounter: changing a description of support does not remove the support itself.

## Evidence and limits

**{total}/{total} automated checks passed:** {counts['code']} exact printed-code assertions, {counts['museum']} installed-museum checks and {counts['portals']} portal checks. The printed-code test includes an independent filtered-default edit and three deliberately faulty versions. Across forty seconds of model time, the observer matched the unmodified ecosystem's positions, health, DNA, care interventions and random state.

Installed tests exercise the actual sphere and button methods, preserve held-body protections, verify both account columns and check that filtering leaves event history, identities and positions unchanged. Repeated panel reads leave body state, food, records and randomness untouched. Desktop grab/drop and supplied XRTools near-grab/release were exercised with synthetic controllers.

Three routes have supported floors and standing-capsule clearance at {samples} sampled positions. The portal coordinator completed Population Support → Graph Theory Foundations → Population Support, with supported arrivals and one resident hall. Graph Theory is the next sequence, ahead of Machine Learning.

Final runs contain no script or shader errors. Existing UID, Jolt, renderer and loading messages remain in the saved logs. This is author-operated automated verification, not physical-headset testing, Quest performance measurement or an independent learner trial.

Ten native Godot images show the installed museum. Before/after views use the same cameras and initial 50-prey/5-predator state. The full/omitted pair uses one camera and the same held body after thirty seconds of the actual simulation. No supplied bodies were invented for the photographs.

## What this closes

This completes the current pass through all seven Swarm halls: a written trail; supplied direction; nearby neighbours; a body's state; two channels chosen by that state; a remembered score; and the population support that keeps bodies present. The sphere returns while the relevant record changes. Those distinctions give the sequence continuity without pretending that all seven systems use one mechanism.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')


def fig(name, caption, eager=False):
    return (f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" '
            f'alt="{html.escape(caption)}" loading="{"eager" if eager else "lazy"}"></a>'
            f'<figcaption>{html.escape(caption)}</figcaption></figure>')


css = '''*{box-sizing:border-box}body{margin:0;background:#14222c;color:#e7edef;font:17px/1.65 system-ui}nav{display:flex;flex-wrap:wrap;gap:20px;padding:17px 4vw;background:#243542}a{color:#a3dcd9}main{max-width:1460px;margin:auto;padding:36px 26px 70px}h1{font:clamp(44px,7vw,78px)/1.08 Georgia,serif;margin:18px 0;color:#f2d278}h2{font:32px Georgia,serif;margin:36px 0 16px}.eyebrow{text-transform:uppercase;font-size:13px;letter-spacing:.15em;color:#f2d278}p{max-width:980px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:12px 0;background:#243542;padding:10px}img{display:block;width:100%}figcaption{padding:10px;font-size:14px}article{max-width:980px;margin-top:40px}strong{color:#f2d278}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:20px 12px}}'''
body = '<p class="eyebrow">Endless Museum / Population Support / native Godot captures</p><h1>The account in hand</h1><p>The population is recovering. The account asks how.</p>'
body += fig('full-account','Same ecosystem, thirty seconds later: eleven prey. Ten arrived through population support.',True)
body += '<section id="account"><h2>Change the account. The bodies remain.</h2><div class="pair">'
body += fig('full-account','Full record: 50 + 0 − 49 + 10 = 11. Expected and actual agree.')
body += fig('omitted-account','Omit the supplied row: the account predicts 1 while 11 remain. The gap is 10.') + '</div></section>'
body += '<section id="hand"><h2>Inspect a body beside its record</h2><p>Take the black grip. Hold a sphere and use its trigger to select it. The arrival source stays with that body when you move it.</p>'
body += fig('dock','Four familiar commands beside two clear population columns.')
body += fig('support-in-room','The full-size ecosystem after the actual thirty-second run. Supplied spheres retain their gold rings.') + '</section>'
for view,title,description in [
    ('above','The hall from above','The full-size field and central passage remain open.'),
    ('field','Among the same bodies','The familiar sphere now carries an arrival history.'),
    ('controls','Keep the original control banks','The hand account operates the same commands and shows the same state.'),
]:
    body += f'<section id="{view}"><h2>{title}</h2><p>{description}</p><div class="pair">'
    body += fig(view+'-before','Before — initial population, same camera.')
    body += fig(view+'-after','After — '+description) + '</div></section>'
body += '<article id="report">'+markdown.markdown(report,extensions=['extra'])+'</article><p>'
body += ' · '.join(f'<a href="evidence/{name}-checks.json">{name.title()} checks</a>' for name in receipts)+'</p><p><a href="before/preserved-hashes.json">Preserved sources</a></p>'
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The account in hand — Population Support</title><style>'+css+'</style></head><body><nav><a href="#account">Two accounts</a><a href="#hand">Hand controls</a><a href="#above">Before &amp; after</a><a href="#report">Report &amp; tests</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-pso-a-memory-in-hand/index.html">Previous: Particle Swarm</a><a href="../../../../commons/maps/'+H+'/tutorial.md">Full tutorial</a><a href="../../../../commons/maps/'+H+'/final.md">Reflective text</a></nav><main>'+body+'</main></body></html>'
(O/'index.html').write_text(page,encoding='utf-8')
sources = [Path(__file__),R/'commons/maps'/H/'map_data.json',R/'commons/data/museum/em_plan.json']
sources += list((R/'commons/artifacts/population_account_walk').glob('*'))
sources += list((R/'tools/probes').glob('account_hand_*.gd'))
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
print(f'Published {total}/{total} checks, {len(preserved)} preserved hashes, ten native images.')
