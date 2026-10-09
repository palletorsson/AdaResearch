from pathlib import Path
import copy, difflib, hashlib, html, json, re
import markdown

H = Path(__file__).resolve().parent
R = H.parents[3]
MAPS = ['Trans_Pre', 'Trans_Translation', 'Trans_Rotation', 'Trans_Scale', 'Trans_Pit']
LABELS = ['The first cube', 'Translation', 'Rotation', 'Scale', 'The passage']
NOTES = [
    'The closing paragraph returns to what each operation preserves, then asks which change can give us somewhere to stand. The cube demonstrations and the opening from Melencolia stay.',
    'Deck heights and socket arithmetic give way to the relation that matters to the visitor: coordinates must agree with the surrounding floor. The rides, attention and permissions remain.',
    'The existing axial-sweep study joins the hall between the arrays and the tunnel. A turning cube describes a cylinder; a triangle describes a cone. The prose now follows a placed encounter. All earlier works remain.',
    'One heading changes level. Alice, the instantaneous change of room scale, the witness frame and the comparison with the body remain exactly as written.',
    'Exact travel times and repeated operational explanation move out of the reader\'s way. Watching, waiting, bodily clearance and the final door remain. Supporting implementation detail is kept in a separate encounter reference.'
]

def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def render(s, prefix):
    s = re.sub(r'<!--\s*@[^>]*-->', '', s)
    out = markdown.markdown(s, extensions=['fenced_code', 'footnotes', 'tables'])
    out = re.sub(r'id="([^"]+)"', lambda m: 'id="'+prefix+m[1]+'"', out)
    return re.sub(r'href="#([^"]+)"', lambda m: 'href="#'+prefix+m[1]+'"', out)

checks = []
def check(name, ok):
    checks.append({'check': name, 'passed': bool(ok)})

for path, digest in read(H/'preserved.json').items():
    check('Preserved '+path, sha(R/path) == digest)
oldmap = read(H/'before/commons/maps/Trans_Rotation/map_data.json')
newmap = read(R/'commons/maps/Trans_Rotation/map_data.json')
oldlayers = copy.deepcopy(oldmap['layers'])
oldlayers['interactables'][39][14] = 'axial_sweep:0:0#plinth:0'
check('Only the one axial-sweep placement changes the map layers', oldlayers == newmap['layers'])
for key in ['utility_definitions', 'lighting', 'settings', 'rotation_studies', 'gallery', 'refresh']:
    check('Rotation retains '+key, oldmap[key] == newmap[key])
oldroles = read(H/'before/commons/data/artifact_roles.json')
roles = read(R/'commons/data/artifact_roles.json')
oldroles['roles']['Trans_Rotation']['axial_sweep'] = 'primary'
oldroles['order']['Trans_Rotation']['primary'].insert(2, 'axial_sweep')
check('Role changes are only the added study and its order', oldroles == roles)
core = read(R/'commons/data/museum_core_encounters.json')
oldcore = read(H/'before/commons/data/museum_core_encounters.json')
check('Other core records unchanged', {k:v for k,v in core['rooms'].items() if k not in MAPS} == {k:v for k,v in oldcore['rooms'].items() if k not in MAPS} and core['_meta'] == oldcore['_meta'])
parts, counts = [], []
for name, label, note in zip(MAPS, LABELS, NOTES):
    path = Path('commons/maps')/name/'final.md'
    old = (H/'before'/path).read_text(encoding='utf-8')
    now = (R/path).read_text(encoding='utf-8')
    expected = []
    order = roles['order'][name]
    for token in order['primary']:
        expected.extend(order['primary|'+token[1:]] if token.startswith('@') else [token])
    expected = [token for token in expected if not token.startswith('#')]
    check(name+' primary markers agree with authored order and core', re.findall(r'<!-- @([A-Za-z_0-9]+) -->', now) == expected == core['rooms'][name]['primary_tokens'])
    for key, file in [('text_sha256','final.md'), ('map_sha256','map_data.json')]:
        check(name+' '+key, core['rooms'][name][key] == sha(R/path.parent/file))
    check(name+' review status remains unchanged', core['rooms'][name]['status'] == oldcore['rooms'][name]['status'] and core['rooms'][name]['learner_verified'] == oldcore['rooms'][name]['learner_verified'])
    if name == 'Trans_Pre':
        check('Pre demonstrations retained', old.rsplit('A few lines of code', 1)[0] == now.rsplit('A few lines of code', 1)[0])
    if name == 'Trans_Scale':
        check('Scale has only its heading correction', old.replace('# A door, at last', '## A door, at last', 1) == now)
    if name == 'Trans_Pit':
        check('Pit final airlock passage preserved', old.split('## Make room')[1] == now.split('## Make room')[1])
    if name == 'Trans_Rotation':
        check('Rotation no longer has a localhost/publication-status footnote', 'localhost' not in now and '[^turning-studies]' not in now)
        check('Rotation retains the time and sameness question', 'A shape can return without giving back the time it took, or undoing where it carried you.' in now)
    counts.append({'map':name, 'before_words':len(old.split()), 'after_words':len(now.split())})
    diff = path.as_posix().replace('/','__')+'.diff'
    parts.append('<section id="'+name+'"><div class="eyebrow">'+label+'</div><h2>'+html.escape(name.replace('_',' '))+'</h2><p>'+html.escape(note)+'</p><nav><a href="/compose/sources?map='+name+'&amp;doc=final">Read and comment</a><a href="'+diff+'">Exact diff</a><a href="/long-museum/encounters?map='+name+'">Encounter map</a></nav><details><summary>Read the current chapter</summary><div class="reading">'+render(now,name+'-read-')+'</div></details><details><summary>Compare original and current</summary><div class="compare"><article><h3>Original</h3>'+render(old,name+'-before-')+'</article><article><h3>Current</h3>'+render(now,name+'-after-')+'</article></div></details></section>')
# Refresh all exact diffs against this pass's preserved baseline.
for oldfile in (H/'before').rglob('*'):
    if not oldfile.is_file(): continue
    rel = oldfile.relative_to(H/'before')
    if not (R/rel).is_file(): continue
    old = oldfile.read_text(encoding='utf-8').splitlines(keepends=True)
    new = (R/rel).read_text(encoding='utf-8').splitlines(keepends=True)
    delta = ''.join(difflib.unified_diff(old,new,fromfile='before/'+rel.as_posix(),tofile='current/'+rel.as_posix()))
    if delta: (H/(rel.as_posix().replace('/','__')+'.diff')).write_text(delta,encoding='utf-8')
results = read(H/'museum-runtime.json')
check('Controlled museum assertions pass', results['passed'] and len(results['checks']) == 14 and all(c['ok'] for c in results['checks']) and not results['failures'])
check('Seven continuous approach and onward walking segments pass', len(results['walks']) == 7 and all(c['passed'] for c in results['walks']))
for name in ['cube.png','cube-boundary.png','triangle-boundary.png','museum-study-context.png']:
    check('Actual capture '+name, (H/name).stat().st_size > 10000)
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
(H/'chapter-counts.json').write_text(json.dumps(counts,indent=2)+'\n',encoding='utf-8')
failed = [c['check'] for c in checks if not c['passed']]
if failed: raise SystemExit('Checks failed: '+repr(failed))
style = (R/'doc/book/iterations/2026-09-21-point-one-return/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style += 'section{margin:48px 0;border-top:1px solid var(--line);padding-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.pair figure{margin:14px 0}article{min-width:0}.compare{align-items:start}.still-link{font-size:14px}@media(max-width:760px){.pair{grid-template-columns:1fr}}'
nav = ''.join('<a href="#'+n+'">'+label+'</a>' for n,label in zip(MAPS,LABELS))
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation — what survives the turn?</title><style>'+style+'</style></head><body><main><div class="eyebrow">Ada Research · a light Transformation pass · 21 September 2026</div><h1>What survives the turn?</h1><p class="intro">An edge keeps arriving somewhere else. The cube stays a cube. Follow its turn, then ask what space that movement has described.</p><p>The sequence keeps its seven halls and its central movement: the operations that make a pickup conspicuous can carry a body, occupy a passage, or make room at a door. This pass lightens the technical inventory and restores one existing study to the hall.</p><nav>'+nav+'<a href="SUMMARY.md">Decisions and evidence</a></nav><div class="pair"><figure><a href="cube-boundary.png"><img src="cube-boundary.png" alt="Actual museum cube on its spindle with a cylindrical cyan boundary"></a><figcaption>The turning cube and the outside of the space it sweeps. The boundary is optional and starts hidden.</figcaption></figure><figure><a href="triangle-boundary.png"><img src="triangle-boundary.png" alt="The same actual museum study with a triangle and its conical sweep boundary"></a><figcaption>A triangle turns about its upright edge. The operation stays; the resulting boundary changes.</figcaption></figure></div><p class="note">Two controlled states of the same existing Godot artifact, now placed in Trans_Rotation. These are museum renders, not before/after geometry comparisons or headset photographs. The cyan boundaries are drawn guides; they add no collision wall.</p><blockquote>The triangle from Primitives has acquired another possibility without acquiring another corner.</blockquote><figure><a href="museum-study-context.png"><img src="museum-study-context.png" alt="The compact spindle study on the museum floor before the existing tunnel and carousel gallery"></a><figcaption>The new placement sits after the rotated arrays and before the tunnel. Its viewing plate is 1.7 m above the arena floor. All previous artifacts, floor geometry and the five carousel profiles remain. The larger four-drum comparison stays in its separate research scene.</figcaption></figure><p><strong>Introduction and Body are preserved in full.</strong> Their crossings, openings and bodily measurements already carry the argument. The panels below show the five chapters with bounded changes.</p>'+''.join(parts)+'<section><div class="eyebrow">Next · Arrays</div><h2>The same cube, in company.</h2><p>Transformation gives the cube operations. Arrays let us address several bodies and apply operations through an arrangement. That is the next connection to read, without losing the cube we have already learned to recognise.</p><nav><a href="/compose/sources?map=Array&amp;doc=final">Read Array</a><a href="/book-review/doc/book/review-feedback/2026-09-21/transformation/DECISIONS.md">Claude feedback decisions</a><a href="/book-review/doc/book/iterations/2026-09-21-primitives-finish/index.html">Previous Primitives pass</a></nav></section><p class="note">Verification: fourteen controlled artifact checks and seven connected walking segments passed. Headset reach, comfort and learner understanding remain open. The run also logged a nested GridSystem null-player error; it is recorded separately in the evidence, and this is not presented as an error-free museum run. Claude\'s frozen full-book export remains unchanged.</p></main></body></html>'
(H/'index.html').write_text(page,encoding='utf-8')
print('Published:', len(checks), 'content/preservation checks passed; 14 runtime assertions and 7 walking segments passed.')
print(json.dumps(counts))
