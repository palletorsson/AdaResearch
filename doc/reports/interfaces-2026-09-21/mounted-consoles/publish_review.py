from pathlib import Path
import difflib, hashlib, html, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-21-interface-mounted-console-review'
PREVIOUS = ROOT/'doc/book/iterations/2026-09-21-interface-hall-placement-review/index.html'
DEST.mkdir(parents=True,exist_ok=True)
checks = json.loads((HERE/'checks.json').read_text(encoding='utf-8'))
regressions = json.loads((HERE/'regressions.json').read_text(encoding='utf-8'))
inventory = json.loads((HERE/'inventory.json').read_text(encoding='utf-8'))
assert not checks['failures']
assert all(not item['failures'] for item in regressions.values())
assert 'SCRIPT ERROR' not in (HERE/'run.log').read_text(encoding='utf-8',errors='replace')
for name in ['checks.json','regressions.json','inventory.json']:
    shutil.copy2(HERE/name,DEST/name)
shutil.copy2(HERE/'README.md',DEST/'implementation.md')
for path in HERE.glob('*.png'): shutil.copy2(path,DEST/path.name)
files = ['commons/ui/exhibit_control_mount.gd',
         'commons/artifacts/exhibits/exhibit_furniture.gd',
         'commons/artifacts/grammar_provenance/grammar_provenance.gd',
         'commons/artifacts/fitness_landscape_politics/fitness_landscape_politics.gd',
         'commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd',
         'commons/testing/test_mounted_physical_consoles.gd']
hashes = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in files}
(DEST/'source-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
for path in files[1:5]:
    before = HERE/'before'/(Path(path).name+'.txt')
    difference = ''.join(difflib.unified_diff(before.read_text(encoding='utf-8').splitlines(True),
                          (ROOT/path).read_text(encoding='utf-8').splitlines(True),
                          fromfile='before/'+path,tofile='after/'+path))
    (HERE/(Path(path).name+'.diff')).write_text(difference,encoding='utf-8')
previous = PREVIOUS.read_text(encoding='utf-8')
css = re.search(r'<style>(.*?)</style>',previous,re.S).group(1)
total = len(checks['checks'])+sum(r['checks'] for r in regressions.values())
def image(name,caption):
    return f'<figure><a href="{name}"><img src="{name}" width="1600" height="1200" alt="{html.escape(caption,quote=True)}"></a><figcaption>{caption}</figcaption></figure>'
names = {'grammar_provenance':'Grammar Provenance','fitness_landscape_politics':'Fitness Landscape Politics','edge_of_chaos_unlocked':'Edge of Chaos'}
rows = ''
for token,label in names.items():
    before,after = [m for m in checks['measurements'] if m['artifact']==token]
    count = sum(r['mounted'] and r['artifact']==token for r in inventory)
    rows += f'<tr><th>{label}</th><td>{before["height"]:.2f} → {after["height"]:.2f} m</td><td>{before["distance"]:.2f} → {after["distance"]:.2f} m</td><td>{count}</td></tr>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The work can rise · Ada Research</title><style>{css}</style></head><body>
<header><div class="eyebrow">Ada Research · Physical interfaces · 21 September 2026</div><h1>The work<br>can rise.</h1><p class="lead">The platform carries the exhibit. The controls stay with the visitor.</p><p><a href="../2026-09-21-interface-hall-placement-review/index.html">Previous: a place to stand</a></p><div class="metrics"><div class="metric"><strong>3 works</strong><span>One reusable mounting rule</span></div><div class="metric"><strong>30 mounts</strong><span>Recorded in project map files</span></div><div class="metric"><strong>{total} checks</strong><span>Fixtures and existing regressions pass</span></div></div></header>
<main><section><h2>A platform was lifting the hand as well.</h2><p>Putting an exhibit on furniture raised its whole body: screen, controls, stand and all. Edge of Chaos's console sat 31 cm higher, with its foot inside the platform. Its display belongs there; its operator needs a station at the front.</p><div class="comparison">{image('edge-before-overview.png','Before: the entire instrument stands on the platform, including the controls.')}{image('edge-after-overview.png','After: the display stays on the platform; the station stands on the visitor’s floor.')}</div><p>These are matched Godot fixture views using the actual furniture and registered artifact. The before view uses the preserved whole-artifact mounting option.</p></section>
<section><h2>Change the display scale. Keep the controls usable.</h2><p>Each of these three works now declares which parts form its control station. Furniture can raise or scale the exhibit while keeping those parts at their authored height and size. The station moves beyond the front edge when needed. Buttons remain physical; words remain flat on their surfaces.</p><div class="table-scroll"><table><thead><tr><th>Work</th><th>Console centre above floor</th><th>Distance in front of origin</th><th>Recorded mounts</th></tr></thead><tbody>{rows}</tbody></table></div><p>Values compare the existing metre-scale platform and floor-pad configurations. The 30 recorded mounts include mission and trial maps; they are not 30 independently tested active museum halls.</p>{image('edge-after-controls.png','Looking down at the Edge of Chaos controls from a 1.65 m eye height, 50 cm in front of the new station centre.')}</section>
<section><h2>The work and its controls have different needs.</h2>{image('fitness-after-overview.png','Fitness Landscape Politics: the seeded swarm remains over its platform; four scoring choices and the inertia fader stay at floor level.')}<p>The scoring choices, continuous inertia control and restart still change the actual simulation. Rebuilding a larger landscape repositions its new station without losing the mounting rule.</p>{image('grammar-after-overview.png','Grammar Provenance: the three forms keep their low marked display area. The depth selector and its foot now clear its front edge.')}<p>The grammar selector keeps its six choices. Its three provenance plaques and comparison forms remain together in the exhibit.</p></section>
<section><h2>What carries across</h2><p>The same mechanism handles translation, yaw rotation and uniform scaling. It responds to placement changes and explicit rebuilds, with no idle frame loop. The controls still belong to their artifact, so hiding or unloading the exhibit also hides or frees its station.</p><p>Edge of Chaos retains its differences: a withheld fader stays absent and a clamped handle stays clamped. Enclosed furniture keeps its existing restrictions. Other artifacts adopt this arrangement only when they explicitly declare their station.</p></section>
<section><h2>Evidence, and the next check</h2><p><strong>{len(checks['checks'])} mounted-fixture checks</strong> cover dimensions, physical grabs, pointer rays, button actions, model responses, live rebuilds, visibility and unloading. Synthetic scales of 0.6 and 1.4, rotated placements and a raised floor reference test the transform behaviour. <strong>172 existing regression checks</strong> also pass for the three direct-floor interfaces.</p><p>These desktop fixtures establish the mounting behaviour. They do not certify tracked-hand comfort or standalone Quest performance. The new station extends the exhibit footprint, so each hall still needs an approach and aisle check. The floor reference comes from the furniture placement; the adapter does not discover a floor automatically.</p><p><a href="checks.json">Fixture checks</a> · <a href="regressions.json">Regression results</a> · <a href="inventory.json">Recorded placements</a> · <a href="implementation.md">Reusable contract and reproduction</a> · <a href="source-hashes.json">Source hashes</a></p><p>Next: bring the same physical controls and placement check to another console family, while preserving the differences that matter to its lesson.</p></section></main><footer>Physical controls · Flat text · The exhibit and the visitor share a floor</footer></body></html>'''
(DEST/'index.html').write_text(page,encoding='utf-8')
link = '<p><a href="../2026-09-21-interface-mounted-console-review/index.html">Continue: the work can rise — controls on the visitor’s floor</a></p>'
if link not in previous: PREVIOUS.write_text(previous.replace('<footer>','<footer>'+link),encoding='utf-8')
print(DEST/'index.html')
print(total,'checks represented')
