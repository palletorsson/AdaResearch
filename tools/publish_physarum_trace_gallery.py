"""Publish native Physarum views and verify the scope of the installed encounter."""
from pathlib import Path
import hashlib, html, json, shutil
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-11-physarum-a-mark-left-behind'
H = 'SwarmIntelligence_PhysarumColony'
RUN = R / f'ada_run/encounter_pilot/{H}/physarum-trace-final'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

code = read(R / 'ada_run/physarum_trace_checks.json')
native = read(RUN / 'report.json')
assert code['passed'] and native['passed']
for path in [R/'ada_run/physarum-trace-checks.log', RUN/'stdout.log']:
    assert not any(s in path.read_text(encoding='utf-8') for s in ['SCRIPT ERROR', 'SHADER ERROR']), path
preserved = read(O/'before/preserved-hashes.json')
assert all(sha(R/p) == value for p, value in preserved.items())
old = read(O/'before/commons/data/museum/em_plan.json')
new = read(R/'commons/data/museum/em_plan.json')
assert [r for r in old['plans'] if r['map'] != H] == [r for r in new['plans'] if r['map'] != H]
assert {k:v for k,v in old.items() if k != 'plans'} == {k:v for k,v in new.items() if k != 'plans'}
before = read(O/f'before/commons/maps/{H}/map_data.json')
after = read(R/f'commons/maps/{H}/map_data.json')
for layer, rows in before['layers'].items():
    for z, row in enumerate(rows):
        for x, cell in enumerate(row):
            if layer == 'structure' and (x,z) in [(12,4),(12,5),(12,6)]:
                assert after['layers'][layer][z][x] == '1'
            elif layer == 'interactables' and (x,z) == (4,2):
                assert cell.startswith('PhysarumColony') and after['layers'][layer][z][x] == ''
            else:
                assert cell == after['layers'][layer][z][x], (layer,x,z)
assert all(len(rows)==11 and all(len(row)==28 for row in rows) for rows in after['layers'].values())
assert after['layers']['interactables'][5][20].startswith('physarum_trace_gallery:')
warning = 'blocked t exit; safe fallback in SwarmIntelligence_PhysarumColony'
assert warning in (R/f'ada_run/encounter_pilot/{H}/all-artifacts/stdout.log').read_text(encoding='utf-8')
for folder in ['assets','evidence']:
    (O/folder).mkdir(exist_ok=True)
figures = [
    ('wall','The original yellow colony after about 32 seconds at normal engine settings. Wall, original table and hand surface show the same state.'),
    ('controls','Take the black point beside the hand surface. Pause/play and restart are within reach; the controls leave the drawing position open.'),
    ('hand-mark','The held point draws a loop into the original field. The colony is paused for this comparison, while the hand remains active.'),
    ('mark-on-wall','The same loop on the six-metre wall. It is a field deposit, not a separate line laid over the image.'),
    ('after-release','Eight more seconds after release and resume. The original agents, diffusion and decay continue changing the marked field.'),
    ('hall-above','The new east court beside the existing hall. A three-cell opening connects them; the table, wall and hand surface leave a central viewing aisle.')]
for name, _ in figures:
    shutil.copy2(RUN/f'{name}.png', O/'assets'/f'{name}.png')
for source, name in [(R/'ada_run/physarum_trace_checks.json','code-checks.json'),(R/'ada_run/physarum-trace-checks.log','code.log'),(RUN/'report.json','museum-checks.json'),(RUN/'stdout.log','museum.log'),(RUN/'source_manifest.json','museum-sources.json')]:
    shutil.copy2(source,O/'evidence'/name)
total = len(code['checks'])+len(native['checks'])
report = f'''# A mark left behind

Endless Museum · 11 October 2026

The yellow Physarum colony now has a six-metre wall view and a hand surface. The original 2.8 m table is still present. All three show one running colony: 300 original agents, one field, one history.

## Try it

Reload **Swarm Intelligence → Physarum Colony** and enter the new east opening. Take the black point beside the smaller surface. Hold the trigger and move it above the surface to draw. A cyan ring shows where your mark will land. Release the trigger and watch the colony continue working on what you left.

The nearby buttons pause/play the colony or restart it. You can draw while paused. Desktop uses the existing right-click carry/drop and left-click action. The point returns to its dock three seconds after you drop it.

## What we kept, what we added

This reuses the existing `physarum_museum` exhibit and its original colony, agent, grid and shader. Its private 50 m simulation is viewed through the original camera, so enlarging the picture does not enlarge its physics. The original anchors still change every 20 simulation seconds. There is no hidden warmup and no automatic reset.

The new operation is a **hand deposit into the same field the agents sense**. Carrying alone does not write. Holding action above the surface deposits a bounded brush, with continuous segments between accepted positions. Moving outside the surface ends the segment; returning does not draw a bridge across the gap. A screen border corresponding to space outside the original simulation is excluded.

The agents' sensing, movement and deposition rules are unchanged. Their environment changes because your hand has added a trace. What happens afterward depends on the existing state and those rules; a visible mark need not persist or become a route. This is a Physarum-inspired model, a related trace mechanism rather than another ant simulation.

## Place in the sequence

Point → hand movement → trace → a field other bodies read. The carried point returns with another ability: it leaves something that keeps acting after the hand stops. The distinction is visible in the room without requiring a new primary tutorial. The seven canonical `tutorial.md` and `final.md` pairs are unchanged.

The hall expands from 13 × 11 to 28 × 11 cells. The old table moves into this new host, leaving only one Physarum colony running. A three-cell east opening gives standing access to the table and controls. All other saved artifact and utility cells remain as before; other museum-plan rows are unchanged.

## What the images show

These are actual Godot museum captures. The colony developed for {native['observations']['growth_wall_seconds']:.2f} elapsed seconds before being paused for the first photographs. A scripted desktop pickup and action then moved the actual PointBody in a loop above the pad. That gesture made {native['observations']['marks']} brush deposits, including interpolation. After release, the colony ran for eight more seconds. Pauses keep the before/drawing comparisons legible; normal play does not insert them automatically.

The gestures are test inputs, not a recording of a person's hand. The images establish what rendered in this run, not a guaranteed final pattern.

## Checks and limits

**{total}/{total} checks passed:** {len(code['checks'])} production-scene checks and {len(native['checks'])} museum checks. They cover shared state, the original resources, camera/input agreement in all quadrants, a translated and rotated host, held-action gating, brush size and cap, continuous strokes, leaving/re-entering, pause and restart, release and return, original simulation advancement, floor support and standing access.

All {len(preserved)} recorded source/text hashes match their before-state. No script or shader errors occurred in the final runs. Existing UID/Jolt and museum warnings remain in the retained logs. The south sequence exit still reports a fallback warning also present in the earlier artifact-inventory run; this work does not establish portal traversal. Physical headset use and Quest performance remain untested.

The first native views exposed an oversized status label in front of the controls. It was reduced and moved behind them, then the complete checks and museum run were repeated.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
esc = html.escape
css = '''*{box-sizing:border-box}body{margin:0;background:#121719;color:#ececdf;font:17px/1.6 system-ui}nav{padding:18px 4vw;background:#20282b;display:flex;gap:22px;flex-wrap:wrap}a{color:#a5dbe1;text-underline-offset:4px}main{max-width:1400px;margin:auto;padding:42px 26px 80px}h1{font:clamp(44px,6vw,78px)/1.08 Georgia,serif;color:#e5eb8c;margin:.3em 0}h2{font:32px/1.2 Georgia,serif;margin-top:38px}p{max-width:920px}figure{margin:26px 0;background:#20282b;padding:10px}img{width:100%;display:block}figcaption{padding:12px 8px;font-size:14px;color:#c4ced0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}.grid figure{margin:0}article{max-width:940px;margin-top:46px}.eyebrow{color:#e5eb8c;font-size:13px;letter-spacing:.15em;text-transform:uppercase}@media(max-width:760px){.grid{grid-template-columns:1fr}main{padding:24px 14px}}'''
def figure(name, caption):
    return f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" alt="{esc(caption)}" loading="lazy"></a><figcaption>{esc(caption)}</figcaption></figure>'
body = '<p class="eyebrow">Endless Museum · Physarum Colony · native Godot views</p><h1>A mark left behind</h1><p>Take the point. Leave a trace. Watch the colony continue after your hand stops.</p>'
body += figure(*figures[0])
body += '<section id="hands"><h2>One colony, three views</h2><div class="grid">'+''.join(figure(*f) for f in figures[1:3])+'</div></section>'
body += '<section id="change"><h2>Draw, release, return to the field</h2><div class="grid">'+''.join(figure(*f) for f in figures[3:5])+'</div></section>'
body += '<section id="room"><h2>The hall from above</h2>'+figure(*figures[5])+'</section>'
body += '<article id="report">'+markdown.markdown(report,extensions=['extra'])+'</article>'
body += '<p><a href="evidence/code-checks.json">Code checks</a> · <a href="evidence/museum-checks.json">Museum checks</a> · <a href="evidence/museum.log">Native log</a></p>'
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A mark left behind — Physarum</title><style>'+css+'</style></head><body><nav><a href="#hands">Use the point</a><a href="#change">Before / after</a><a href="#room">Room from above</a><a href="#report">What changed</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-ants-time-and-scale/index.html#v2">Ant Colony V2</a></nav><main>'+body+'</main></body></html>',encoding='utf-8')
sources = list((R/'commons/artifacts/physarum_trace_gallery').glob('*'))+[R/'commons/artifacts/registry/physarum_trace_gallery.json',R/f'commons/maps/{H}/map_data.json',R/'commons/data/museum/em_plan.json',R/'tools/probes/physarum_trace_checks.gd',R/'tools/probes/physarum_trace_museum.gd']
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
print(f'Published {total} passing checks, six native images; preserved {len(preserved)} hashes, all other plan rows and old artifact/utility cells.')
