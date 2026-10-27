"""Render the current transfer batch from each worker's durable handoff."""
from pathlib import Path
import html
import json
import shutil
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
batch_number = sys.argv[1] if len(sys.argv) > 1 else '01'
assert batch_number in ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24')
BATCH = ROOT / ('doc/void-transfer/2026-10-21-batch-' + batch_number)
OUT = ROOT / ('doc/book/iterations/2026-10-21-void-transfer-batch' + ('-'+batch_number if batch_number != '01' else ''))
OUT.mkdir(parents=True, exist_ok=True)
shutil.copy2(BATCH / 'README.md', OUT / 'agreement.md')
batch = json.loads((BATCH / 'batch.json').read_text(encoding='utf-8'))
esc = lambda value: html.escape(str(value))
cards = []
for job in batch['jobs']:
    folder = ROOT / job['folder']
    status = json.loads((folder / 'transfer-status.json').read_text(encoding='utf-8-sig'))
    rooms = json.loads((folder / 'rooms.json').read_text(encoding='utf-8-sig'))
    inventory = json.loads((folder / 'source-inventory.json').read_text(encoding='utf-8-sig'))
    snapshot = OUT / job['sequence']
    (snapshot / 'evidence').mkdir(parents=True, exist_ok=True)
    for name in ['source-inventory.json', 'transfer-status.json', 'HANDOFF.md', *[p.name for p in folder.glob('HANDOFF-floor-*.md')]]:
        if (folder / name).is_file():
            shutil.copy2(folder / name, snapshot / name)
    for path in (folder / 'evidence').glob('*'):
        if path.is_file() and path.suffix in ('.json', '.png'):
            shutil.copy2(path, snapshot / 'evidence' / path.name)
    placed = {a['id'] for f in rooms['floors'] for a in f.get('artifacts', [])}
    matched = sum(p['id'] in placed for p in inventory['placements'])
    job['stage'] = status.get('stage', 'inventoried')
    job['placed'] = matched
    job['native_tested'] = status.get('native_tested', False)
    job['headset_tested'] = status.get('headset_tested', False)
    rows = []
    for level, name in enumerate(job['maps'], 1):
        entries = [p for p in inventory['placements'] if p['map'] == name]
        rows.append(f'<tr><td>{level}</td><td>{esc(name)}</td><td>{sum(p["id"] in placed for p in entries)} / {len(entries)}</td></tr>')
    checks = []
    for filename, label in [('source-checks.json', 'Source preservation'), ('checks.json', 'Native'), ('editor-checks.json', 'Editor')]:
        path = folder / 'evidence' / filename
        if path.exists():
            report = json.loads(path.read_text(encoding='utf-8-sig'))
            check_list = report.get('checks', [])
            passed = sum(c.get('passed', False) for c in check_list)
            verdict = 'accepted' if report.get('passed') else 'not accepted'
            checks.append(f'<li>{label}: {verdict}; {passed} / {len(check_list)} assertions passed. <a href="{job["sequence"]}/evidence/{filename}">Evidence</a></li>')
    if not checks:
        checks.append('<li>Native and editor validation pending coordinator review.</li>')
    base = job['sequence']
    notes = status.get('adaptations', []) + status.get('omitted', []) + status.get('unresolved_dependencies', status.get('dependencies', []))
    notes_html = ''.join('<li>' + esc(n if isinstance(n, str) else json.dumps(n)) + '</li>' for n in notes)
    shots = sorted((folder / 'evidence').glob('*.png'))
    if job['sequence'] == 'cellularautomata':
        shots = [folder/'evidence'/name for name in ['f1-arrival.png', 'f1-explorer.png', 'f2-console.png', 'f2-neighbour-room.png'] if (folder/'evidence'/name).exists()]
    gallery = ''.join(f'<figure><a href="{base}/evidence/{p.name}"><img loading="lazy" src="{base}/evidence/{p.name}" alt="{esc(p.stem)}"></a><figcaption>{esc(p.stem.replace("-", " "))} · {"web editor capture" if "editor" in p.stem else "native Godot capture"}</figcaption></figure>' for p in shots[:(len(shots) if batch_number in ('19','20','21','22','23','24') else max(4,len(job['maps'])))])
    handoff = f'<a href="{base}/HANDOFF.md">Handoff</a>' if (folder/'HANDOFF.md').exists() else '<span>Handoff in progress</span>'
    editor_links = ''.join(f'<a href="http://localhost:3003/lab-editor?mode=void&amp;trial={base}&amp;floor={level}">Arrange floor {level}</a>' for level in range(1,len(job['maps'])+1))
    cards.append(f'''<section id="{job['sequence']}"><p class="eyebrow">{esc(job['owner'])} / {esc(job['stage'])}</p><h2>{esc(job['sequence'].replace('cellularautomata','Cellular Automata').title())}</h2>
      <p class="count">{matched}<span> / {len(inventory['placements'])} original placements</span></p>
      <table><thead><tr><th>Floor</th><th>Source map</th><th>Present</th></tr></thead><tbody>{''.join(rows)}</tbody></table>
      <div class="links">{editor_links}{handoff}<a href="{base}/source-inventory.json">Source inventory</a></div>
      <ul>{''.join(checks)}<li>Physical headset: {'tested' if status.get('headset_tested') else 'not tested'}.</li><li>Curation: {'reviewed' if status.get('curated') else 'pending'}.</li></ul>
      {('<details><summary>Adapters and unresolved dependencies</summary><ul>'+notes_html+'</ul></details>') if notes else ''}
      <div class="gallery">{gallery}</div></section>''')
batch['updated'] = datetime.now(timezone.utc).isoformat()
(BATCH / 'batch.json').write_text(json.dumps(batch, indent=2) + '\n', encoding='utf-8')
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Museum to Void — transfer batch 01</title>
<style>:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#15141a;color:#eee9df;font:17px/1.6 system-ui}main{max-width:1260px;margin:auto;padding:48px 28px 100px}header{max-width:900px}h1{font-size:clamp(36px,5vw,70px);line-height:1.05;letter-spacing:-.04em;margin:18px 0 28px}h2{font-size:32px;margin:0}.eyebrow{color:#c5abd8;text-transform:uppercase;letter-spacing:.14em;font-size:12px}.lead{font-size:23px;line-height:1.5}nav,.links{display:flex;gap:12px;flex-wrap:wrap}a{color:#d7bee8;text-underline-offset:4px}.links a{padding:7px 12px;border:1px solid #514757;border-radius:4px;text-decoration:none}section{border-top:1px solid #4b424e;margin-top:52px;padding-top:30px}.count{font-size:42px;margin:16px 0}.count span{font-size:17px;color:#c2b6c5}table{border-collapse:collapse;width:100%;text-align:left}td,th{padding:10px;border-bottom:1px solid #36313c}th{color:#b4a5be;font-weight:500}.links{margin:22px 0}.gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px;margin-top:28px}figure{margin:0}img{width:100%;display:block;border-radius:4px}figcaption{color:#b7aebd;font-size:13px;margin-top:7px}details{background:#211e28;padding:16px;border-radius:5px}footer{margin-top:48px;color:#aa9db2;font-size:14px}@media(max-width:700px){.gallery{grid-template-columns:1fr}main{padding:28px 18px}table{font-size:13px}}
</style><main><header><p class="eyebrow">21 October 2026 / parallel transfer / batch 01</p><h1>First, see what we have.</h1><p class="lead">Bring the museum's instruments into separate Void floors. Preserve their behaviour and source identity. Then compose the path together.</p><p>Three workers own three separate trial folders. Codex integrates the shared catalog and serializes native testing on this computer. The curated tower, original maps and chapter texts stay outside this transfer.</p><nav><a href="#shaders">Shaders / Codex</a><a href="#cellularautomata">Cellular Automata / Claude</a><a href="#fractals">Fractals / Argon</a><a href="../../../void-transfer/2026-10-21-batch-01/README.md">Working agreement</a></nav></header>
<section><h2>One collection, four checkpoints</h2><ol><li><b>Inventory:</b> every original placement, configuration and source reference is accounted for.</li><li><b>Transfer:</b> real objects fit the tower and remain independently editable.</li><li><b>Validation:</b> native load, important interactions, floor sleep, retry and editor save work. Synthetic XR is recorded separately from headset play.</li><li><b>Curation:</b> together we decide the encounter order, path, light, danger and what carries forward. Text revisions follow that decision.</li></ol><p>Play a completed transfer through the Godot game menu → Void trials. Web models are arrangement snapshots; the native game runs the shaders and interactions.</p></section>
''' + ''.join(cards) + f'<footer>Snapshot generated {esc(batch["updated"])}. Agent handoffs are evidence to review, not automatic approval. A transferred floor is not yet a finished map.</footer></main></html>'
page = page.replace('../../../void-transfer/2026-10-21-batch-01/README.md', 'agreement.md')
if batch_number != '01':
    page = page.replace('batch 01', 'batch '+batch_number).replace('Three workers own three separate trial folders.', 'Claude and Codex own separate trial folders.')
    page = page.replace('real objects fit the tower and remain independently editable.', 'real objects load in the trial and remain independently editable; measured fit conflicts are recorded.')
    page = page.replace('<h2>Lsystems</h2>', '<h2>L-Systems</h2>').replace('<h2>Proceduralgeneration</h2>', '<h2>Procedural Generation</h2>')
    page = page.replace('<h2>L-Systems</h2>', '<h2>L-Systems</h2><p><b>Fit pending:</b> the 19.52 m cypress penetrates the upper slabs; part of Grammar Provenance lies below the deck. Original geometry is retained for curation. Claude delivered the placements and then reached its quota; Codex completed integration and validation.</p>')
    page = page.replace('<h2>Softbodies</h2>', '<h2>Soft Bodies</h2>')
    page = page.replace('<h2>Foundationscrisis</h2>', '<h2>Foundations Crisis</h2>')
    page = page.replace('<h2>Qfeplaboratory</h2>', '<h2>QFEP Laboratory</h2>')
    page = page.replace('<h2>Postfoundationscrisis</h2>', '<h2>Post-Crisis: Applied Limits</h2>')
    if batch_number == '08':
        page = page.replace('<h2>Postfoundationscrisis_02</h2>', '<h2>Post-Crisis: Conflict and Situated Claims</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Paraconsistent Engineering; Claude transferred Situated Computation as a separate floor fragment, reviewed and integrated by Codex.')
    if batch_number == '09':
        page = page.replace('<h2>Postfoundationscrisis_03</h2>', '<h2>Post-Crisis: Collective Knowledge and Rhizome Network</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Collective Knowledge; Claude transferred Rhizome Network as a separate floor fragment, reviewed and integrated by Codex.')
    if batch_number == '10':
        page = page.replace('<h2>Postfoundationscrisis_04</h2>', '<h2>Post-Crisis: Laboratory and Synthesis</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Lab Equipment; Claude transferred Post-Crisis Synthesis as a separate floor fragment, reviewed and integrated by Codex.')
    if batch_number == '12':
        page = page.replace('<h2>Array_Tutorial_02</h2>', '<h2>Arrays: Third Index and A Rule Underfoot</h2>').replace('<h2>Array_tutorial_02</h2>', '<h2>Arrays: Third Index and A Rule Underfoot</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Fly into the Third Index; Claude transferred A Rule Underfoot as a separate floor fragment, reviewed and integrated by Codex.')
    if batch_number == '13':
        page = page.replace('<h2>Array_Tutorial_03</h2>', '<h2>Arrays: The Same Rule Stands Up and A Grid with a Clock</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Tiling Walls; Claude transferred Disco as a separate floor fragment, reviewed and integrated by Codex.')
    if batch_number == '16':
        page = page.replace('<h2>Color_04</h2>', '<h2>Colour: Paint and Walls</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Paint; Claude transferred Walls as a separate floor fragment, reviewed and integrated by Codex. Standard 42 by 32 metre floors and six-metre storeys are retained.')
    if batch_number == '17':
        page = page.replace('<h2>Tiling_02</h2>', '<h2>Patterns: Foundry and Tutorial</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Pattern Foundry; Claude transferred Tutorial Pattern as a separate floor fragment, reviewed and integrated by Codex. Standard 42 by 32 metre floors and six-metre storeys are retained.')
    if batch_number == '18':
        page = page.replace('<h2>Tiling_03</h2>', '<h2>Patterns: addresses, symmetry, architecture and carriers</h2><p><b>Fit pending:</b> the original 8.35 m Pattern Temple crosses the upper slab of its six-metre storey. One original PatternArtifact is unconfigured and has a labelled editor marker. Raised tunnel access and the standalone scanner display remain recorded for later curation.</p>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Array Patterns, Symmetry Seventeen and Pattern Temple. Claude Opus transferred Ribbon Patterns 01 and 02; Codex reviewed and integrated those floor files. All five use standard 42 by 32 metre floors and six-metre storeys.')
    if batch_number == '24':
        shutil.copy2(BATCH / 'COORDINATOR_REVIEW.md', OUT / 'coordinator-review.md')
        page = page.replace('</header>', '<p><a href="coordinator-review.md">Coordinator review: interactions and remaining fit limits</a></p></header>')
        page = page.replace('<h2>Wavefunctions_05</h2>', '<h2>Walking Waves and Synthesis Lab</h2>')
        page = page.replace('<h2>Randomness_02</h2>', '<h2>Entropy: arrangement, exchange and support</h2>')
        page = page.replace('<h2>Randomness_03</h2>', '<h2>Withdrawal and 10 PRINT</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Walking Waves, Synthesis Lab and Entropy. Claude Opus transferred Random Remove and 10 PRINT and ran their Godot tests; Codex reviewed the implementation and evidence. All five retain standard 42 by 32 metre floors and six-metre storeys. Original oversized exhibits and dependencies are documented for later curation.')
    if batch_number == '23':
        shutil.copy2(BATCH / 'COORDINATOR_REVIEW.md', OUT / 'coordinator-review.md')
        page = page.replace('</header>', '<p><a href="coordinator-review.md">Coordinator review: interactions, tests and fit limits</a></p></header>')
        page = page.replace('<h2>Wavefunctions_03</h2>', '<h2>Sound, Bernini and John Cage</h2><p><b>Fit pending:</b> the original Bernini assembly reaches 9.25 m above its floor and the Asawa wire sculpture spans about 10 m. Both cross the upper slab of a six-metre storey. They retain their source size for later curation.</p>')
        page = page.replace('<h2>Wavefunctions_04</h2>', '<h2>Air Music and Sky Stairs</h2><p><b>Fit pending:</b> the original 80-step staircase reaches an 8.69 m top tread (8.99 m overall), crossing the upper slab. It is preserved at full size; making it a through-floor route requires a later architectural opening. The small mathematical objects retain their source size at floor level.</p>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Sound, Bernini and John Cage. Claude Opus transferred Air Music and Sky Stairs and ran their Godot tests; Codex reviewed his implementation and evidence. All 55 source placements remain editable, on standard 42 by 32 metre floors with six-metre storeys.')
    if batch_number == '22':
        page = page.replace('<h2>Formfinding_03</h2>', '<h2>Form Finding: Forge</h2>')
        page = page.replace('<h2>Wavefunctions_02</h2>', '<h2>Waves: Pendulum, Sine Space, Unit Circle and Propagation</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Forge, Pendulum and Sine Space. Claude Opus transferred Unit Circle and 3D Wave Propagation; Codex reviewed and tested both. All 32 source placements are editable. Standard 42 by 32 metre floors and six-metre storeys remain. The unbuilt source pipe has a labelled editor marker; larger exhibits retain their recorded fit and access limitations for later curation.')
    if batch_number == '21':
        page = page.replace('<h2>Forces_04</h2>', '<h2>Forces: Force as Place</h2>')
        page = page.replace('<h2>Formfinding_02</h2>', '<h2>Form Finding: catenary, relaxation, equilibrium and annealing</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Force as Place, Catenary and Relaxation. Claude Opus transferred Equilibrium and Annealing; Codex reviewed the original scripts and tested both floors. All 32 original placements remain individually editable. The tower retains its standard 42 by 32 metre floor and six-metre storeys.')
    if batch_number == '20':
        page = page.replace('<h2>Forces_03</h2>', '<h2>Forces: oscillation, timing, gravity, support and impact</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Oscillation, Choreography and Gravity. Claude Opus transferred Legs and Arena; Codex reviewed both and tested the combined trial. All thirty original placements remain editable. Standard 42 by 32 metre floors and six-metre storeys are retained.')
    if batch_number == '19':
        page = page.replace('<h2>Tiling_04</h2>', '<h2>Patterns: fabric, performers and hand trails</h2>')
        page = page.replace('<h2>Forces_02</h2>', '<h2>Forces: launch, motion, fields and resistance</h2><p><b>Fit pending:</b> the original gravity loop and friction lanes use their own platforms beside the tower. The launch frame exceeds the six-metre storey; the large mowing garden overlaps neighbouring exhibits. All instruments retain their source scale. These are transfer floors awaiting curation.</p>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Ribbon Patterns 03, Launch and Motion. Claude Opus transferred Fields and Kinetic Forces; Codex reviewed and integrated both. The tower retains its standard 42 by 32 metre floors and six-metre storeys.')
    if batch_number == '15':
        page = page.replace('<h2>Color_03</h2>', '<h2>Colour: Pillar and Grid Pallet</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Pillar; Claude transferred Grid Pallet as a separate floor fragment, reviewed and integrated by Codex. Standard 42 by 32 metre floors and six-metre storeys are retained.')
    if batch_number == '14':
        page = page.replace('<h2>Color_02</h2>', '<h2>Colour: Nails and Rainbow</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Nails; Claude transferred Rainbow as a separate floor fragment, reviewed and integrated by Codex. The standard 42 by 32 metre tower and six-metre storeys remain unchanged.')
    if batch_number == '11':
        page = page.replace('<h2>Transformation_02</h2>', '<h2>Transformation: The Body and The Moving Boundary</h2>')
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred The Body; Claude transferred The Moving Boundary as a separate floor fragment, reviewed and integrated by Codex.')
    if batch_number == '07':
        page = page.replace('Claude and Codex own separate trial folders.', 'Codex transferred Algorithmic Bias; Claude transferred Applied Ethics as a separate floor fragment, reviewed and integrated by Codex.')
        coverage = BATCH / 'spine-coverage.json'
        if coverage.exists():
            shutil.copy2(coverage, OUT / 'spine-coverage.json')
            page = page.replace('<footer>', '<p>Spine checkpoint: specimens now exist in 23 trial sequences, with Primitives in the main tower and Change deliberately skipped. This is broad coverage, not a complete migration: later maps and curation remain. <a href="spine-coverage.json">Map-level transfer inventory</a>.</p><footer>')
    page = page.replace('<h2>Graphtheory</h2>', '<h2>Graph Theory</h2>')
    page = page.replace('<h2>Machinelearning</h2>', '<h2>Machine Learning</h2><p><b>Fit pending:</b> this trial has wide slabs and eight-metre storeys to retain the original creature arenas at source scale. Final circulation and a compact arrangement await curation.</p>')
    page = page.replace('<h2>Boolean_Surfaces</h2>', '<h2>Boolean Surfaces</h2>')
    page = page.replace('<h2>Swarmintelligence</h2>', '<h2>Swarm Intelligence</h2><p><b>Fit pending:</b> the original 20-metre particle-swarm volume is displayed beside the tower at its original scale. The standalone ant retains its original independent wandering behaviour. These are transfer specimens for later curation.</p>')
    page = page.replace('<h2>Isosurfaces</h2>', '<h2>Isosurfaces</h2><p><b>Fit pending:</b> the original cave spans 45 m and is displayed beside the tower. Its original generator omits collision at this triangle count. This is a transfer specimen, not a walkable cave route.</p>')
    nav = ''.join(f'<a href="#{esc(job["sequence"])}">{esc(job["sequence"])} / {esc(job["owner"])}</a>' for job in batch['jobs'])
    start = page.index('<nav>'); end = page.index('</nav>', start)
    page = page[:start] + '<nav>' + nav + '<a href="agreement.md">Working agreement</a>' + page[end:]
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(OUT / 'index.html')
