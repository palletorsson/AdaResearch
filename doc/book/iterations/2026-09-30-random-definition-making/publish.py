"""Freeze this focused revision and its actual Godot evidence."""
from pathlib import Path
import difflib, hashlib, html, json, os, re, shutil, zipfile
import markdown
from bs4 import BeautifulSoup

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAP = ROOT / 'commons/maps/Random_Definition'
STUDY = ROOT / 'doc/book/studies/random-definition'
RUN = ROOT / 'ada_run/encounter_pilot/Random_Definition'
URL = '/book-review/' + OUT.relative_to(ROOT).as_posix()
lesson = json.loads((STUDY / 'verification.json').read_text(encoding="utf-8"))
museum = json.loads((RUN / 'report.json').read_text(encoding="utf-8"))
assert lesson['passed'] and museum['passed']
assert (MAP / 'map_data.json').read_bytes() == (OUT / 'before/map_data.json').read_bytes()

def save(path, data):
    tmp = path.with_name(path.name + '.ada-tmp')
    tmp.write_text(data, encoding='utf-8')
    os.replace(tmp, path)

for name in ['museum-matched.png', 'museum-offset.png', 'report.json', 'source_manifest.json']:
    shutil.copy2(RUN / name, OUT / name)
shutil.copy2(STUDY / 'verification.json', OUT / 'lesson-verification.json')
for p in STUDY.glob('0*.png'):
    shutil.copy2(p, OUT / p.name)

changes = ['final.md', 'tutorial.md', 'technical.md', 'summary.md', 'intent.md']
manifest = {}
for name in changes:
    source = MAP / name
    dest = OUT / 'after' / name
    dest.parent.mkdir(exist_ok=True)
    shutil.copy2(source, dest)
    before = (OUT / 'before' / name).read_text(encoding='utf-8').splitlines(True)
    after = source.read_text(encoding='utf-8').splitlines(True)
    save(OUT / (name + '.diff'), ''.join(difflib.unified_diff(before, after, fromfile='before/' + name, tofile='after/' + name)))
    manifest[source.relative_to(ROOT).as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
p = ROOT / 'commons/scenes/em/em_portal_stream.gd'
shutil.copy2(p, OUT / 'after/em_portal_stream.gd')
save(OUT / 'em_portal_stream.gd.diff', ''.join(difflib.unified_diff((OUT / 'before/em_portal_stream.gd').read_text(encoding="utf-8").splitlines(True), p.read_text(encoding="utf-8").splitlines(True), fromfile='before/em_portal_stream.gd', tofile='after/em_portal_stream.gd')))
manifest[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()

study_files = sorted(p for p in STUDY.rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix in {'.gd', '.tscn', '.godot', '.md', '.json'} and '.ada-tmp' not in p.name)
with zipfile.ZipFile(OUT / 'random-definition-study.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in study_files:
        archive.write(p, p.relative_to(STUDY).as_posix())
        manifest[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
save(OUT / 'source-versions.json', json.dumps(manifest, indent=2) + '\n')

decisions = '''# Random Definition — a making route beside the encounter

The review is useful. Its strongest recommendation is to distinguish reading an instrument from learning to construct and change one.

## Adopted

- Keep the main encounter recognisable. Give the grids before the invitation to choose; give seed one short explanation. Let the bar strips show the offset, then show only the consequential unused request and RGB grouping. Retain “Nothing in a draw says that it is red.” Give the changed colours a moment before explaining replay again.
- Keep all seven placed artifacts. The textile comparison, number page and crank carry distinct questions; no artifact was demoted or removed. Make the return to the crank deliberate.
- Build a complete standalone study: one colour, seeded replay, one grid, a matched pair, an unused draw, then equal draws with exchanged channel roles. The final exercise returns to the matched pair first. It does not mix the two experiments.
- Correct the 13 × 20 layout and column 6, row 6 placement in current companions. Preserve the earlier tutorial and technical account as dated snapshots; move maintenance concerns out of the making route.
- Narrow the RAND comparison. A stored table and a calculated sequence offer different ways to recover a beginning. Remove the unsupported “last printed table” claim and the seed/table equivalence.
- Distinguish a fresh configured instance from restored visit state. Source inspection found the actual portal caller, and native checks exercised its save/restore methods.

## Implementation finding

During restoration, the instrument replaces its bar-strip nodes. The portal caller previously tried to compute addresses for those removed nodes later in the same traversal. It now checks that a node survives in the scene tree and implements restoration before looking up its saved state. The random generator, hall layout and artifact controls are unchanged.

## Sources and scope

Daniel Shiffman's [Randomness chapter](https://natureofcode.com/random/) supports the pedagogical observation: a small working construction can develop through changes the learner can see. We keep this hall's colour investigation; its walker remains later in Ada's sequence. The review was checked against the current files, not treated as a substitute for them.

[Godot's generator reference](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) scopes seeded repeatability and warns against relying on the underlying algorithm. [RAND's introduction](https://www.rand.org/pubs/monograph_reports/MR1418.html) describes the generated, tested and transformed table and its relation to later calculated numbers.

The current museum run still reports an unrecognised audio-resource UID and a blocked authored-entry/landing warning. The encounter loaded and the focused tests passed; this review does not certify navigation or headset comfort. No physical portal crossing or learner trial was performed. The standalone study is a separate desktop construction, clearly labelled as such in the images.
'''
save(OUT / 'DECISIONS.md', decisions)

css = '''
:root{color-scheme:light;--paper:#f5f1e8;--ink:#222725;--accent:#7b423f}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.75 Georgia,serif}a{color:var(--accent);text-underline-offset:4px}nav{position:sticky;top:0;z-index:5;background:#f5f1e8f5;border-bottom:1px solid #cec9bd;padding:13px max(24px,calc((100vw - 1100px)/2));font:14px/1.5 system-ui;display:flex;gap:24px;flex-wrap:wrap}main{max-width:1100px;margin:55px auto;padding:0 28px 70px}.reading{max-width:740px;margin:auto}.kicker{font:12px/1.5 system-ui;letter-spacing:.17em;text-transform:uppercase;color:#725a52}h1{font-weight:normal;font-size:clamp(36px,5vw,60px);line-height:1.12;margin:18px 0 30px}h2{font-weight:normal;line-height:1.3;margin-top:50px}h3{font:600 20px/1.5 system-ui}p{margin:1.15em 0}pre{overflow:auto;border-left:3px solid #bf9882;padding:19px 22px;background:#e9e5db;font:14px/1.65 Consolas,monospace;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:24px 0}img{width:100%;height:auto;display:block;border-radius:3px}figcaption,.note{font:14px/1.6 system-ui;color:#53605b;margin:10px 0}.panel{padding:20px 25px;background:#e9e5db;margin:22px 0}summary{cursor:pointer;font:16px/1.6 system-ui}table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid #cec9bd;padding:10px;text-align:left}.footnote{font-size:15px;border-top:1px solid #cec9bd;margin-top:40px}details{margin:15px 0}footer{margin-top:50px;font:13px/1.7 system-ui;color:#53605b}@media(max-width:700px){.pair{grid-template-columns:1fr}main{margin-top:28px}body{font-size:18px}}
'''
nav = '<nav><a href="index.html">Review</a><a href="reading.html#reading">Read the encounter</a><a href="making.html#making">Make the study</a><a href="random-definition-study.zip">Download Godot project</a><a href="index.html#changes">Exact changes</a></nav>'
render_number = 0
def md(text):
    global render_number
    render_number += 1
    soup = BeautifulSoup(markdown.markdown(text, extensions=['fenced_code','tables','footnotes']), 'html.parser')
    ids = {tag['id']: f'n{render_number}-' + tag['id'] for tag in soup.select('[id]')}
    for tag in soup.select('[id]'): tag['id'] = ids[tag['id']]
    for tag in soup.select('a[href^="#"]'):
        anchor = tag['href'][1:]
        if anchor in ids: tag['href'] = '#' + ids[anchor]
    return str(soup)
def page(name, title, body):
    save(OUT / name, '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main>'+body+'</main></html>')
def fig(file, caption): return f'<figure><img src="{file}" alt="{html.escape(caption)}"><figcaption>{html.escape(caption)}</figcaption></figure>'

page('reading.html', 'A pattern that returns · revised encounter', '<article class="reading" id="reading"><p class="kicker">Random Definition · Encounter · 30 September 2026</p>'+md((MAP/'final.md').read_text(encoding="utf-8"))+'</article>')
page('making.html', 'Make a colour return · complete teaching study', '<article class="reading" id="making"><p class="kicker">Random Definition · Making · 30 September 2026</p>'+md((MAP/'tutorial.md').read_text(encoding="utf-8"))+'<h2>The editable construction</h2>'+fig('01-colour.png','Step 1: one generated colour. Standalone Godot study.')+fig('05-unused-draw.png','Step 5: the right grid spends one unused draw. Standalone Godot study.')+fig('06-channel-roles.png','Step 6: both grids keep the same draws; only right-hand red and blue exchange roles. Standalone Godot study.')+'</article>')
body = '<p class="kicker">Random Definition · Focused revision · 30 September 2026</p><h1>A colour you can<br>learn to bring back.</h1><p>The encounter keeps its question. The tutorial now gives the reader a small construction to change, one decision at a time.</p><div class="panel"><a href="reading.html#reading">Read the revised chapter →</a> &nbsp; <a href="making.html#making">Follow the making route →</a></div>'
body += '<h2 id="museum">The current museum instrument</h2><div class="pair">'+fig('museum-matched.png','Inside Random Definition: the same seed and requests colour both grids alike.')+fig('museum-offset.png','Same viewpoint and seed. The right grid requests one unused value before colouring.')+'</div>'
body += '<h2>The construction becomes yours</h2><p>One cube → a repeatable colour → a grid → a matched pair → one unused draw → another assignment. Six complete scripts; one main scene.</p><div class="pair">'+fig('04-pair.png','Step 4 in the standalone study: begin each 4 × 4 grid from the same seed.')+fig('06-channel-roles.png','Step 6 in the standalone study: change the right grid’s colour roles, keeping all draws.')+'</div>'
body += md(decisions)
body += f'<h2>Verification</h2><p>{len(lesson["checks"])} standalone checks and {len(museum["checks"])} focused museum checks passed. The lesson tests include all six scripts, six seeds, the actual replay signal and two suggested code edits.</p><p><a href="lesson-verification.json">Lesson report</a> · <a href="report.json">Museum report</a> · <a href="source-versions.json">Frozen source hashes</a></p>'
body += '<h2 id="changes">Before / after</h2>'
for name in changes:
    body += '<details><summary>'+html.escape(name)+'</summary><div class="pair"><section><h3>Before</h3>'+md((OUT/'before'/name).read_text(encoding="utf-8"))+'</section><section><h3>After</h3>'+md((MAP/name).read_text(encoding="utf-8"))+'</section></div><p><a href="'+name+'.diff">Exact diff</a></p></details>'
body += '<details><summary>Portal restoration guard</summary><pre>'+html.escape((OUT/'em_portal_stream.gd.diff').read_text(encoding="utf-8"))+'</pre></details><footer>Current manuscript promoted to final.md. The map and generator implementation were preserved. No commit or push in this pass.</footer>'
page('index.html','Random Definition · a making route',body)
print('Published',URL+'/index.html')
