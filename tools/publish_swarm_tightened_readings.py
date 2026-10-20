"""Package the tightened seven-hall reading with unchanged code and fresh receipts."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import html
import json
import re
import shutil
import zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-11-swarm-tightened-readings'
TEST = R / 'doc/book/iterations/2026-10-10-swarm-sequence-review'
seq = json.loads((R / 'commons/maps/sequences/swarmintelligence.json').read_text(encoding='utf-8'))['sequences']['swarmintelligence']['maps']
names = ['Physarum', 'Flow Fields', 'Boids', 'Agent-Based Modelling', 'Ant Colony', 'Particle Swarm', 'Population Support']
focus = ['A trace outside the body', 'A direction supplied to the body', 'Nearby bodies supply steering', 'A state changes the response', 'State selects two trail channels', 'A position remembered for its score', 'An account of what keeps bodies present']
photos = [
    ('2026-10-11-physarum-a-mark-left-behind', 'hand-mark'),
    ('2026-10-11-flow-a-direction-left-behind', 'directions-written'),
    ('2026-10-11-boids-who-enters-the-radius', 'wide'),
    ('2026-10-11-abm-a-state-in-the-hand', 'carrying'),
    ('2026-10-11-colony-the-channels-in-hand', 'returning'),
    ('2026-10-11-pso-a-memory-in-hand', 'memory-kept'),
    ('2026-10-11-swarm-the-account-in-hand', 'omitted-account'),
]


def write(p, text):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(text.encode('utf-8'))


def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


evidence = json.loads((TEST / 'sequence-checks.json').read_text(encoding='utf-8'))
assert evidence['passed'] and evidence['completed'] and evidence['same_pointbody_all_seven']
assert [row['hall'] for row in evidence['halls']] == seq
protected = json.loads((O / 'before/protected-hashes.json').read_text(encoding='utf-8'))
assert all(sha(R / p) == expected for p, expected in protected.items()), 'Protected code/layout/order changed'
copy(TEST / 'sequence-checks.json', O / 'evidence/sequence-checks.json')
for row in evidence['halls']:
    for kind in ['tutorial', 'final']:
        assert sha(R / 'commons/maps' / row['hall'] / (kind + '.md')) == row[kind + '_sha256'], 'Stale code-run provenance'
    for key in ['receipt', 'log']:
        copy(TEST / row[key], O / 'evidence' / row[key])

copy(R / 'doc/book/iterations/2026-10-10-boids-who-is-near/assets/tank-two-runs-part.png', O / 'assets/tank-two-runs-part.png')
for p in (R / 'commons/artifacts/navigator_noise').iterdir():
    if p.is_file() and p.suffix in ['.md', '.gd', '.tscn']:
        copy(p, O / 'supplied/navigator_noise' / p.name)
for name in ['ecosystem.gd', 'Creature.gd', 'food.gd']:
    copy(R / 'algorithms/emergentsystems/ecosystemsimulation' / name, O / 'supplied/ecosystemsimulation' / name)
for folder in ['physarum_trace_gallery', 'flow_direction_table', 'boids_neighbour_lens', 'abm_state_table', 'ant_colony_walk', 'particle_swarm_walk', 'population_account_walk']:
    for p in (R / 'commons/artifacts' / folder).rglob('*'):
        if p.is_file() and p.suffix in ['.gd', '.tscn', '.md']:
            copy(p, O / 'museum-controls' / folder / p.relative_to(R / 'commons/artifacts' / folder))
copy(R / 'commons/maps/sequences/swarmintelligence.json', O / 'evidence/sequence.json')
brief = (R / 'doc/book/course/storyboards/SWARM-OPEN-STUDY.md').read_text(encoding='utf-8')
brief = brief.replace('../../iterations/2026-10-10-swarm-ghost-student/index.html', 'prior-investigation/REPORT.md')
write(O / 'OPEN-STUDY.md', brief)
# Include the past investigation as dated evidence; keep its relative resources intact.
shutil.copytree(R / 'doc/book/iterations/2026-10-10-swarm-ghost-student', O / 'prior-investigation', dirs_exist_ok=True,
                ignore=shutil.ignore_patterns('*.zip', '*.import', '*.uid'))

CSS = '''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f5f3ed;color:#202b31;font:18px/1.65 Georgia,serif}nav{padding:14px 3vw;background:#202b31;color:#fff;font:14px/1.7 system-ui}nav a{color:#e5e9df;margin-right:22px}main{max-width:1080px;margin:auto;padding:45px 30px 80px}a{color:#155a63}h1{font-size:clamp(32px,5vw,58px);line-height:1.12;font-weight:normal;margin:12px 0 25px}h2{font-size:28px;line-height:1.3;margin-top:40px}h3{font-size:22px}p{max-width:78ch}article{border-top:1px solid #adb5b1;margin-top:55px;padding-top:30px;scroll-margin-top:20px}.meta,figcaption,summary{font:14px/1.6 system-ui}.meta{letter-spacing:.06em;text-transform:uppercase;color:#5b6667}.notice{padding:18px 24px;border-left:4px solid #ae5c7e;background:#ebe5de}.cards{display:grid;grid-template-columns:1fr 1fr;gap:28px}.card{background:white;border:1px solid #d8dad1;padding:20px}.card img,img{max-width:100%;height:auto}.card h2{margin:12px 0}.card p{margin:8px 0}figure{margin:25px 0}figcaption{color:#596566;margin-top:8px}pre{max-width:100%;background:#172b32;color:#e3ece9;padding:20px;overflow:auto;font:13px/1.6 Consolas,monospace;tab-size:4}code{font-family:Consolas,monospace;font-size:.88em}pre code{font-size:inherit}details{border-left:2px solid #bcc7c2;padding-left:18px;margin:24px 0}summary{cursor:pointer;font-weight:600}table{border-collapse:collapse;width:100%;font-size:16px}th,td{text-align:left;border-bottom:1px solid #c4ccc6;padding:12px;vertical-align:top}.parallel{max-width:1900px}.spread{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:42px}.spread>section{min-width:0}.spread>section+section{border-left:1px solid #c4ccc6;padding-left:30px}.spread h1{font-size:34px}.spread pre{font-size:12px}.turn{display:flex;justify-content:space-between;gap:20px;margin:20px 0;font:15px/1.5 system-ui}.toc{columns:2;padding-left:22px}.footnote{font-size:14px;color:#536266}@media(max-width:850px){.cards,.spread{grid-template-columns:1fr}.spread>section+section{border:0;padding:0}.toc{columns:1}main{padding:25px 18px}}@media print{nav,.turn{display:none}body{background:white;color:black}main{max-width:none;padding:0}article{break-before:page}pre{white-space:pre-wrap;overflow-wrap:anywhere;color:black;background:#f0f0f0;font-size:9px}details{display:block}.spread{display:block}a{color:inherit}.card{break-inside:avoid}figure{break-inside:avoid}}'''


def render(text, prefix=''):
    # Full code is visible by default, including inherited source inside details.
    text = re.sub(r'<details(?:\s[^>]*)?>', '<details open markdown="1">', text)
    out = markdown.markdown(text, extensions=['extra', 'sane_lists'])
    # Markdown expands tabs. Preserve the exact source for copy/paste from HTML too.
    fenced = re.findall(r'```gdscript\n(.*?)\n```', text, re.S)
    if fenced:
        blocks = iter(fenced)
        out, count = re.subn(r'<pre><code class="language-gdscript">.*?</code></pre>',
                            lambda _: '<pre><code class="language-gdscript">' + html.escape(next(blocks)) + '\n</code></pre>', out, flags=re.S)
        assert count == len(fenced)
    if prefix:
        out = re.sub(r'id="([^"]+)"', lambda m: 'id="' + prefix + m[1] + '"', out)
        out = re.sub(r'href="#([^"]+)"', lambda m: 'href="#' + prefix + m[1] + '"', out)
    return out


def page(path, title, body, root='', wide=False):
    nav = ''.join('<a href="' + root + href + '">' + label + '</a>' for href, label in [
        ('index.html', 'Seven halls'), ('tutorial.html', 'Full tutorial'), ('final.html', 'Full reflection'),
        ('REVIEW.md', 'Review brief'), ('swarm-review.zip', 'Download ZIP')])
    write(path, '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + CSS + '</style></head><body><nav>' + nav + '</nav><main' + (' class="parallel"' if wide else '') + '>' + body + '</main></body></html>')


def portable(text, root=''):
    return (text.replace('/book-images/figures/swarmintelligence/tank-two-runs-part.png', root + 'assets/tank-two-runs-part.png')
            .replace('../../artifacts/navigator_noise/tutorial.md', root + 'supplied/navigator_noise/tutorial.md')
            .replace('../../../doc/book/course/storyboards/SWARM-OPEN-STUDY.md', root + 'OPEN-STUDY.md'))


manifest = []
texts = {'tutorial': [], 'final': []}
cards = []
all_blocks = 0
for i, (hall, name, operation, (report, photo)) in enumerate(zip(seq, names, focus, photos), 1):
    photograph = R / 'doc/book/iterations' / report / 'assets' / (photo + '.png')
    copy(photograph, O / 'assets' / (str(i) + '.png'))
    entry = {'hall': hall, 'order': i, 'name': name, 'focus': operation, 'texts': {}, 'printed_files': {},
             'image_source': photograph.relative_to(R).as_posix(), 'image_sha256': sha(photograph), 'image_date': '2026-10-11'}
    hall_texts = {}
    for kind in texts:
        p = R / 'commons/maps' / hall / (kind + '.md')
        text = p.read_text(encoding='utf-8')
        before = (O / 'before' / hall / (kind + '.md')).read_text(encoding='utf-8')
        assert re.findall(r'```[^\n]*\n.*?```', text, re.S) == re.findall(r'```[^\n]*\n.*?```', before, re.S)
        copy(p, O / 'canonical' / hall / (kind + '.md'))
        write(O / 'halls' / hall / (kind + '.md'), portable(text, '../../'))
        hall_texts[kind] = portable(text, '../../')
        texts[kind].append((hall, name, portable(text)))
        entry['texts'][kind] = {'path': p.relative_to(R).as_posix(), 'sha256': sha(p)}
        if kind == 'tutorial':
            for filename, code in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', text, re.S):
                study_file = R / 'doc/book/studies/swarm-through-the-hands' / hall / filename
                assert code + '\n' == study_file.read_text(encoding='utf-8')
                entry['printed_files'][filename] = sha(study_file)
                all_blocks += 1
    for p in (R / 'doc/book/studies/swarm-through-the-hands' / hall).iterdir():
        if p.suffix in ['.gd', '.tscn']:
            copy(p, O / 'halls' / hall / p.name)
    previous = '<a href="../' + seq[i-2] + '/parallel.html">← ' + names[i-2] + '</a>' if i > 1 else '<span>First hall</span>'
    following = '<a href="../' + seq[i] + '/parallel.html">' + names[i] + ' →</a>' if i < len(seq) else '<span>End of Swarm → Graph Theory</span>'
    turn = '<div class="turn">' + previous + following + '</div>'
    body = '<div class="meta">Endless Museum · Hall ' + str(i) + ' / 7</div><h1>' + name + '</h1><p>' + operation + '</p>' + turn
    body += '<figure><img src="../../assets/' + str(i) + '.png" alt="' + name + ' installed museum encounter"><figcaption>Native Godot capture, 11 October. Existing evidence; the prose revision did not rerender or change this room.</figcaption></figure>'
    body += '<div class="spread"><section><div class="meta">Left page · tutorial</div>' + render(hall_texts['tutorial'], 't-') + '</section><section><div class="meta">Right page · reflection</div>' + render(hall_texts['final'], 'f-') + '</section></div>' + turn
    page(O / 'halls' / hall / 'parallel.html', name + ' · facing pages', body, '../../', True)
    cards.append('<section class="card"><img loading="lazy" src="assets/' + str(i) + '.png" alt="' + name + ' museum encounter"><div class="meta">' + str(i) + ' / 7</div><h2>' + name + '</h2><p>' + operation + '</p><a href="halls/' + hall + '/parallel.html">Facing pages</a> · <a href="tutorial.html#' + hall + '">Tutorial</a> · <a href="final.html#' + hall + '">Reflection</a></section>')
    manifest.append(entry)

assert all_blocks == 22
toc = '<ol class="toc">' + ''.join('<li><a href="#' + hall + '">' + name + '</a></li>' for hall, name in zip(seq, names)) + '</ol>'
for kind, title in [('tutorial', 'Swarm Intelligence — complete tutorial'), ('final', 'Swarm Intelligence — complete reflective sequence')]:
    intro = 'Seven halls in the existing spine order. Revised 11 October 2026. The prepared Endless Museum is the setting.'
    raw = '# ' + title + '\n\n' + intro + '\n\n'
    body = '<div class="meta">Endless Museum · review edition · 11 October 2026</div><h1>' + title + '</h1><p>' + intro + '</p>' + toc
    if kind == 'tutorial':
        note = 'Each lesson carries the same PointBody class and declares what changes in its model. Installed hand controls are described before the reconstruction. The complete printed code and its named dependencies remain intact. All code panels are open for reading and printing.'
        raw += note + '\n\n'
        body += '<p class="notice">' + note + '</p>'
    for hall, name, text in texts[kind]:
        raw += '\n---\n\n<a id="' + hall + '"></a>\n\n## ' + name + '\n\n' + text + '\n'
        body += '<article id="' + hall + '"><div class="meta">' + name + '</div>' + render(text, hall + '-') + '</article>'
    write(O / (kind + '.md'), raw)
    page(O / (kind + '.html'), title, body)

readme = '''# Swarm Intelligence — review edition, 11 October 2026

Start with **tutorial.html** and **final.html** for the two complete readings. **tutorial.md** and **final.md** contain the same complete text for another AI. **index.html** provides the route, native museum images and facing pages with tutorial left / reflection right. The ZIP works as an offline reading package after extraction.

The setting is the existing Endless Museum. Each hall has one focused reconstruction; other artifacts remain available for comparison and reflection. The first three small studies deliberately simplify their larger exhibits. ABM's installed study and the final three room-scale lessons use the printed models. Added museum controls are named equipment around those models, not hidden steps needed to run the printed reconstruction.

The scripts require the prepared AdaResearch project: Godot, XRTools, player, environment, physical button and the declared source paths. This ZIP is a review package, not a standalone Godot project. Per-hall printed `.gd` and `.tscn` files are in `halls/`; supplied ecosystem and optional navigator sources are in `supplied/`. `museum-controls/` records the installed wrappers separately. Keep project dependencies at the paths declared by the lessons when reconstructing.

All 22 printed GDScript blocks and the seven-hall order are unchanged. Seventy saved code/layout/order hashes match the pre-edit state. Every tutorial was freshly reconstructed and run in Godot after editing: **265 checks passed**, including seven independent variations and 21 deliberately faulty versions detected. PointBody is identical across the seven lessons. `evidence/sequence-checks.json` and its logs bind the runs to the current tutorial and final hashes. These are author-operated checks with synthetic inputs, not a new independent ghost-student trial or physical-headset session.

Seven native museum images are copied from the 11 October hall reports. Their source paths and hashes are in `manifest.json`. Rooms were not rerendered in this prose-only pass. The earlier ghost investigation remains dated under `prior-investigation/`; it is evidence for the optional RIDGE exercise, not a fresh assessment of this edition.

`canonical/` preserves exact current hall text bytes. Reading copies rebase three inherited links for portability; their words and code remain the same. `before/` and `changes.json` preserve the editorial comparison.
'''
review = '''# Review the Swarm sequence

Read as the ghost student: you already know the carried PointBody, arrays, coordinates and steering from the earlier museum. You are here to reconstruct and investigate, with pleasure and room for uncertainty. The new lesson must be discoverable without treating every exhibit as required work.

Read the complete tutorial first, then the reflection; compare the facing pages where they meet. Report a specific passage or missing prerequisite rather than requesting more content everywhere.

1. Can you identify one main operation and one primary experiment per hall?
2. Is it clear what PointBody keeps, what the model replaces, and what equipment the museum supplies?
3. Can the declared code and dependencies reconstruct the focused example? Distinguish reading a passing receipt from independently running it.
4. Do the hand instructions tell you whether you are moving an agent, writing a field, changing radius or carrying a readout? Are the installed controls distinguished from the minimal study?
5. Can you predict a result, make the independent edit and explain a failed prediction?
6. Do Boids → ABM and Ant Colony → Particle Swarm make their model changes clear?
7. Does the reflection stay close to the encounter while making its own claim? Identify any analogy presented as proof or any repetition that obstructs the walk.
8. Does Population Support earn its place as the ending and prepare a useful question for Graph Theory?

The order is Physarum → Flow Fields → Boids → Agent-Based Modelling → Ant Colony → Particle Swarm → Population Support. The code and order are fixed in this editorial revision; propose any later structural change separately and explain its benefit.

## Changes in this edition

- Shortened Boids from 1,699 to 1,173 tutorial-prose words and from 1,083 to 716 reflective words (including source notes). Its complete code and source notes remain.
- Added a clear starting experiment and current hand-control instructions in all seven tutorials.
- Made the switch from installed exhibits to small reconstruction studies explicit.
- Connected Physarum and Flow Fields reflections to the new writing gestures; the closing reflection now carries its account beside a sphere.
- Clarified that omitted supply is cumulative history, not necessarily the number of living gold rings.
- Preserved all printed code, models, museum layout and sequence order; freshly ran all seven printed lessons.

See README.md for reconstruction context and evidence limits. Code passing is evidence about implementation; it is not evidence that every reader will understand the lesson.
'''
write(O / 'README.md', readme)
write(O / 'REVIEW.md', review)
page(O / 'review.html', 'Swarm · review brief', render(review))
write(O / 'manifest.json', json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
page(O / 'index.html', 'Swarm · where coordination lives', '<div class="meta">Endless Museum · complete review edition · 11 October 2026</div><h1>Where coordination lives</h1><p>Trace → direction → neighbours → state → two trails → remembered score → support.</p><p class="notice">Seven complete tutorials and seven reflective texts. Current hand controls, tighter Boids pacing, unchanged code and order. All 265 printed-code checks passed after editing.</p><p><a href="tutorial.html">Read the full tutorial</a> · <a href="final.html">Read the full reflection</a> · <a href="swarm-review.zip">Download the review ZIP</a></p><p><a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a> · <a href="review.html">Review brief and changes</a></p><div class="cards">' + ''.join(cards) + '</div><article>' + render(readme) + '</article>')

# HTML completeness and local-link checks cover the new review pages.
class Inspect(HTMLParser):
    def __init__(self):
        super().__init__(); self.refs = []; self.ids = set(); self.pre = 0
        self.in_pre = False; self.code_blocks = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            assert attrs['id'] not in self.ids, ('duplicate id', attrs['id'])
            self.ids.add(attrs['id'])
        for key in ['href', 'src']:
            if key in attrs:
                self.refs.append(attrs[key])
        if tag == 'pre':
            self.pre += 1
            self.in_pre = True; self.code_blocks.append('')
    def handle_endtag(self, tag):
        if tag == 'pre':
            self.in_pre = False
    def handle_data(self, data):
        if self.in_pre:
            self.code_blocks[-1] += data


pages = [O / p for p in ['index.html', 'tutorial.html', 'final.html', 'review.html']] + list((O / 'halls').glob('*/parallel.html'))
inspections = {}
for p in pages:
    obj = Inspect(); obj.feed(p.read_text(encoding='utf-8')); inspections[p.resolve()] = obj
assert inspections[(O / 'tutorial.html').resolve()].pre == all_blocks
expected_code = [block + '\n' for _, _, text in texts['tutorial']
                 for block in re.findall(r'```gdscript\n(.*?)\n```', text, re.S)]
assert inspections[(O / 'tutorial.html').resolve()].code_blocks == expected_code, 'HTML copy/paste source differs'
checked = 0
for p, obj in inspections.items():
    for ref in obj.refs:
        u = urlsplit(ref)
        if u.scheme or u.netloc:
            continue
        dest = (p.parent / unquote(u.path)).resolve() if u.path else p
        if dest.name == 'swarm-review.zip':
            continue
        assert dest.exists(), (p, ref)
        if u.fragment and dest in inspections:
            assert unquote(u.fragment) in inspections[dest].ids, (p, ref, 'missing anchor')
        checked += 1
verification = {'passed': True, 'halls': seq, 'printed_blocks_preserved': all_blocks,
                'displayed_code_matches_source': True,
                'protected_hashes_preserved': len(protected), 'fresh_godot_checks': evidence['total_checks'],
                'new_html_pages_checked': len(pages), 'local_links_and_anchors_checked': checked,
                'native_images_reused': 7, 'new_headset_test': False, 'independent_learner': False}
write(O / 'verification.json', json.dumps(verification, indent=2) + '\n')
with zipfile.ZipFile(O / 'swarm-review.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in sorted(O.rglob('*')):
        if p.is_file() and p.suffix != '.zip':
            archive.write(p, p.relative_to(O))
with zipfile.ZipFile(O / 'swarm-review.zip') as archive:
    assert archive.testzip() is None
    for name in ['tutorial.md', 'final.md', 'tutorial.html', 'final.html', 'README.md', 'evidence/sequence-checks.json']:
        assert archive.read(name) == (O / name).read_bytes()
print(json.dumps(verification, indent=2))
print('Review ZIP:', round((O / 'swarm-review.zip').stat().st_size / 1024 / 1024, 1), 'MiB')
