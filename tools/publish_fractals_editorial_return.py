"""Publish the bounded Fractals editorial revision and its execution evidence."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil
import zipfile
import markdown
from bs4 import BeautifulSoup

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-08-fractals-a-question-of-your-own'
def read(p): return p.read_text(encoding='utf-8')
def write(p, value): p.write_text(value, encoding='utf-8', newline='\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
for folder in ['tests', 'composition-example', 'changes', 'images']:
    (O / folder).mkdir(exist_ok=True)
before = json.loads(read(O / 'before.json'))
changed = []
for name in before:
    old = O / 'before' / name
    assert sha(old) == before[name]
    current = R / name
    if sha(current) != before[name]:
        diff_name = name.replace('/', '__') + '.diff'
        before_text, after_text = read(old), read(current)
        scope = 'file'
        if name == 'doc/book/course/execution-plan/plan.json':
            # Other sessions share this plan. Attribute only this lesson row.
            old_row = next(v for v in json.loads(before_text)['lessons'] if v['id'] == 'Fractal_Synthesis')
            new_row = next(v for v in json.loads(after_text)['lessons'] if v['id'] == 'Fractal_Synthesis')
            assert old_row['baseline'] == new_row['baseline'] and old_row['decision'] == new_row['decision']
            before_text, after_text = (json.dumps(v, ensure_ascii=False, indent=2) + '\n' for v in [old_row, new_row])
            scope = 'Fractal_Synthesis row only; concurrent edits to other rows are excluded'
        write(O / 'changes' / diff_name, ''.join(difflib.unified_diff(before_text.splitlines(True), after_text.splitlines(True), fromfile='before/' + name, tofile=name)))
        changed.append({'path': name, 'scope': scope, 'before_sha256': before[name], 'after_sha256': sha(current), 'diff': 'changes/' + diff_name})

for source, target in [
    ('ada_run/fractal_composition_student/assertions.json', 'composition.json'),
    ('ada_run/fractal_composition_student/engine.log', 'composition-engine.log'),
    ('ada_run/fractal_composition_student/extraction.json', 'composition-extraction.json'),
    ('ada_run/synthesis_recipe_tests.json', 'required-recipe.json'),
    ('ada_run/synthesis-recipe-engine.log', 'recipe-engine.log'),
    ('ada_run/synthesis_student/extraction.json', 'recipe-extraction.json'),
]:
    shutil.copy2(R / source, O / 'tests' / target)
tests = {}
for name in ['composition', 'required-recipe']:
    data = json.loads(read(O / 'tests' / (name + '.json')))
    assert data['passed'] and not data['failures']
    tests[name] = len(data['checks'])

for name in ['tree.gd', 'noise_tree.gd', 'point_body.gd', 'line_skin.gd', 'recipe.json']:
    shutil.copy2(R / 'ada_run/fractal_composition_student' / name, O / 'composition-example' / name)
write(O / 'composition-example' / 'README.md', '''# One possible composition: noise enters a tree's turn

This example was authored by the writing agent to check feasibility. It is not an independent ghost-student submission or a required silhouette.

Use the prepared Endless Museum workspace with its camera, lights, player and installed XRTools. Copy this folder into that project. Attach tree.gd to an empty, unit-scale Node3D on the floor for the unchanged Recursive Trees study. Attach noise_tree.gd to a second empty Node3D and leave clear space between the studies. PointBody and LineSkin stay alongside the scripts; there are no named scene-child dependencies.

The added code creates FastNoiseLite, declares its seed, Simplex type, disabled fractal layering and frequency before construction. A sample at (remaining depth, left/right sign) supplies a bounded offset to each child’s local Z rotation. Branches at the same depth and side share a sample. The offset defaults to 12 degrees and is capped at 15. This is static construction: re-run to rebuild. The inherited hand grips subsequently replace the first forks’ orientation; they do not resample the noise.

At three generations both studies have fifteen segments and the same lengths and attachments. Endpoints differ. Set influence to 0.0 in noise_tree.gd to recover the original. Identical settings reproduce the initial geometry before grip edits. recipe.json names the choices and prediction. Source changes are intentionally local to this optional study; no museum generator was replaced.

Twenty-one native Godot assertions checked those properties, bounded depth, independent originals, station placement and the carried XRTools pickup with supplied controller poses. This establishes one feasible response. It does not establish student understanding, aesthetic quality or headset comfort.
''')
with zipfile.ZipFile(O / 'composition-example.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for p in sorted((O / 'composition-example').iterdir()): z.write(p, 'composition-example/' + p.name)

changes = [
    ('Fractal_Synthesis', 'tutorial', 'Choose one connection', 'Added an optional authored composition after the required recipe lesson. It names the carried files, edit location, setup order, sampling decision, invariants, comparison and revision. The full required code remains identical.'),
    ('Fractal_Synthesis', 'final', 'Reach the question sooner', 'Shortened the interval/tree recap and removed three repeated source excerpts. The comparison table is explicitly one part of the wider research practice; choosing the next relationship remains the maker’s work.'),
    ('Fractal_MengerSponge', 'final', 'Stay with the passage', 'The main text follows the attempt to enter. Capsule dimensions and occupied-room controls remain available in a note.'),
    ('Fractal_KochSierpinski', 'final', 'Make the detours visible', 'Box-counting and the inherited pyramid are named as two optional side benches before the route into Menger.'),
]
code_before = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', read(O / 'before/commons/maps/Fractal_Synthesis/tutorial.md'), re.S)
code_after = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', read(R / 'commons/maps/Fractal_Synthesis/tutorial.md'), re.S)
assert code_before == code_after
review = '''# A question of your own

The seven-hall Fractals route keeps its progression. The revision gives its ending more room for authorship: reconstruct the known example, predict a change, then optionally compose one existing construction with one earlier influence.

The required Synthesis study still compares independently copied interval recipes. Its complete code is unchanged. The new assignment asks the student to choose an input and receiver, preserve an original, name an invariant, run the work in the museum workspace and revise a choice because of what the comparison reveals. Noise entering a tree’s turn is one feasible example, not the required answer. The interval table does not save this independent tree study.

The reflective text now reaches the kept comparison sooner. It identifies the table as one local practice within the larger movement between description, code and bodily encounter. Menger’s collision details move into a note; Koch’s box-counting and pyramid become explicit side detours. Their mathematical distinctions remain.

## What the checks establish

- Required recipe: 46 native assertions pass, including the exact printed code, independent variation, copy/restore, real rendered lengths, supplied XRTools hand poses and the following lab’s actual Cantor grammar.
- One optional tree/noise response: 21 native assertions pass. It changes endpoints while preserving segment count, lengths and attachment; zero influence recovers the original; repeated settings reconstruct it; the carried grips work.
- Both engine runs exit successfully without script errors. The composition was made by the writing agent, not an independent student. These runs do not grade the chosen shape or establish comprehension, headset feel or a new artifact placed in Synthesis.

## What we take forward

Reconstruct → predict → compose. An authored composition can have exact tests without one prescribed appearance. Keep the original, record the receiving relationship, and give a reason for the next edit. Surprise and precision are both possible reasons to stay with a work; neither is a score assigned by its object count.
'''
write(O / 'REVIEW.md', review)
write(O / 'SUMMARY.md', 'Fractals | keep seven halls; Synthesis core=copy/compare interval recipe; optional=one prior construction + one prior influence; learner chooses input→receiver; original+settings kept; predict invariant→execute→inspect→revise; static noise/tree feasibility only; tests constrain geometry/budget/replay, not silhouette/value; final keeps local exercise distinct from research method; no museum logic changes.\n')
shutil.copy2(R / 'doc/book/iterations/2026-10-08-synthesis-a-rule-kept/images/comparison.png', O / 'images/comparison.png')
style = 'body{margin:0;background:#f5f1ea;color:#27232c;font:19px/1.65 Georgia,serif}main{max-width:1050px;margin:3rem auto;padding:0 28px}h1{font-size:3.4rem;line-height:1.05;font-weight:normal}h2,h3{line-height:1.2;font-weight:normal}a{color:#783c56}nav{display:flex;gap:18px;flex-wrap:wrap;font:15px system-ui}figure{margin:2rem 0}img{width:100%}figcaption,.small{font:14px/1.5 system-ui;color:#67545c}.pair{display:grid;grid-template-columns:1fr 1fr;gap:35px}.pair>article{min-width:0}pre{overflow:auto;font:12px/1.55 Consolas,monospace;background:#27232c;color:white;padding:18px;tab-size:4}details{border-top:1px solid #cdbac1;padding:18px 0}.note{border-left:3px solid #b07b90;padding:12px 22px;background:#eee3df}@media(max-width:800px){.pair{display:block}h1{font-size:2.6rem}}'
body = '<main><p class="small">ENDLESS MUSEUM · FRACTALS · 8 OCTOBER 2026</p><h1>A question of your own.</h1><nav><a href="REVIEW.md">Editorial note</a><a href="composition-example.zip">One tested composition</a><a href="tests/required-recipe.json">46 recipe checks</a><a href="tests/composition.json">21 composition checks</a></nav>'
body += markdown.markdown(review, extensions=['fenced_code', 'tables'])
body += '<figure><img src="images/comparison.png" alt="Live and kept interval rows in the Synthesis museum hall"><figcaption>Existing native museum capture: the comparison table that supplies the required lesson. The optional tree composition is a separate learner study.</figcaption></figure><h2>Read the editorial changes</h2>'
for hall, track, title, detail in changes:
    old = read(O / 'before/commons/maps' / hall / (track + '.md'))
    new = read(R / 'commons/maps' / hall / (track + '.md'))
    body += '<details><summary>' + html.escape(hall + ' / ' + track + ' — ' + title) + '</summary><p>' + html.escape(detail) + '</p><div class="pair">'
    for label, text in [('Before', old), ('After', new)]:
        soup = BeautifulSoup(markdown.markdown(text, extensions=['fenced_code', 'footnotes']), 'html.parser')
        # Each excerpt has its own footnote namespace and exact code whitespace.
        prefix = hall + '-' + track + '-' + label
        for tag in soup.find_all(id=True): tag['id'] = prefix + '-' + tag['id']
        for a in soup.find_all('a', href=True):
            if a['href'].startswith('#'): a['href'] = '#' + prefix + '-' + a['href'][1:]
        for code, original in zip(soup.select('pre>code'), re.findall(r'```[^\n]*\n(.*?)\n```', text, re.S)): code.string = original + '\n'
        body += '<article><h3>' + label + '</h3>' + str(soup) + '</article>'
    body += '</div></details>'
body += '</main>'
write(O / 'index.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fractals — a question of your own</title><style>' + style + '</style></head><body>' + body + '</body></html>')
evidence = {'date': '2026-10-08', 'changes': changed, 'required_printed_code_unchanged': True, 'tests': tests, 'source_sha256': {name: sha(R / name) for name in before if name.startswith('commons/')}, 'scope': 'Editorial revision; unchanged required lesson and one agent-authored optional composition executed. No new museum placement, independent ghost student or headset certification.'}
write(O / 'evidence.json', json.dumps(evidence, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({'output': str(O), 'changed_files': len(changed), 'checks': tests, 'required_code_unchanged': True}))
