"""Publish this bounded text review; does not run Godot or change canonical text."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil
from urllib.parse import unquote

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAPS = ROOT / 'commons/maps'
PAGES = {
    'rhizome-final': ('SpeculativeComputation_Rhizome_Network', 'final.md'),
    'assembly-tutorial': ('AdvancedLaboratory_Lab_Equipment_Simulation', 'tutorial.md'),
    'synthesis-final': ('PostCrisis_Synthesis', 'final.md'),
    'synthesis-tutorial': ('PostCrisis_Synthesis', 'tutorial.md'),
}
CSS = '''body{margin:0;background:#eeeae1;color:#202a2c;font:18px/1.65 Georgia,serif}
main{max-width:1040px;margin:auto;padding:40px 28px}h1{font-size:2.3em;line-height:1.15}
nav,small{font:14px/1.5 system-ui}nav a{margin-right:22px}a{color:#205965}
table{border-collapse:collapse;width:100%;font-size:16px}td,th{padding:12px;border-bottom:1px solid #bfc3be;text-align:left;vertical-align:top}
pre{padding:18px;background:#fffdf8;overflow:auto;font:14px/1.6 monospace}code{font-size:.9em}
img{max-width:100%}.pair{display:grid;grid-template-columns:1fr 1fr;gap:26px}.pair article{min-width:0}
.wide{max-width:1580px}summary{cursor:pointer}section{margin:48px 0}
@media(max-width:900px){.pair{display:block}main{padding:24px 16px}table{font-size:14px}}'''


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def render(text, source=None):
    result = markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])
    if source:
        def href(match):
            url = html.unescape(match[1])
            if url.startswith(('/', '#')) or ':' in url:
                return match[0]
            target = (source.parent / url.split('#')[0]).resolve()
            fragment = '#' + url.split('#', 1)[1] if '#' in url else ''
            return 'href="/book-review/' + target.relative_to(ROOT).as_posix() + fragment + '"'
        result = re.sub(r'href="([^"]+)"', href, result)
    return result


def page(name, title, body, wide=False):
    nav = '<nav><a href="index.html">Reading report</a><a href="changes.html">Before / after</a><a href="validation.json">Validation</a></nav>'
    (OUT / name).write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style><main class="{"wide" if wide else ""}">{nav}{body}</main></html>', encoding='utf8')


before = json.loads((OUT / 'before-hashes.json').read_text())
after = {rel: digest(ROOT / rel) for rel in before}
changed = [rel for rel in before if before[rel] != after[rel]]
expected = {(MAPS / hall / filename).relative_to(ROOT).as_posix() for hall, filename in PAGES.values()}
expected.add('doc/final_lap_scores.json')
assert set(changed) == expected, changed

old_scores = json.loads((OUT / 'before/doc/final_lap_scores.json').read_text(encoding='utf8'))
new_scores = json.loads((ROOT / 'doc/final_lap_scores.json').read_text(encoding='utf8'))
for hall, record in old_scores['maps'].items():
    for key in ('thesis', 'helper', 'aesthetic'):
        assert record.get(key) == new_scores['maps'][hall].get(key), (hall, key)
score_halls = [hall for hall, record in old_scores['maps'].items() if record != new_scores['maps'][hall]]
assert set(score_halls) == {'SpeculativeComputation_Collective_Knowledge', 'SpeculativeComputation_Rhizome_Network', 'AdvancedLaboratory_Lab_Equipment_Simulation', 'PostCrisis_Synthesis'}

sequence = json.loads((ROOT / 'commons/maps/sequences/postfoundationscrisis.json').read_text(encoding='utf8'))['sequences']['postfoundationscrisis']['maps']
plans = json.loads((ROOT / 'commons/data/museum/em_plan.json').read_text(encoding='utf8'))['plans']
assert [row['map'] for row in plans if row.get('map') in sequence] == sequence

source_paths = [ROOT / rel for rel in before if rel.endswith('.gd')]
source_paths.append(ROOT / 'algorithms/computationalbiology/molecular_framework/Part.gd')
clean = lambda text: '\n'.join(line.strip() for line in text.splitlines() if line.strip())
code = '\n'.join(clean(path.read_text(encoding='utf8')) for path in source_paths)
excerpts = 0
links = 0
sections = []
for name, (hall, filename) in PAGES.items():
    source = MAPS / hall / filename
    rel = source.relative_to(ROOT)
    text = source.read_text(encoding='utf8')
    previous = (OUT / 'before' / rel).read_text(encoding='utf8')
    if filename == 'tutorial.md':
        for block in re.findall(r'```gdscript\s*\n(.*?)```', text, re.S):
            assert clean(block) in code, (hall, block)
            excerpts += 1
    assert text.count('```') % 2 == 0
    assert re.findall(r'<!-- @.*?-->', text) == re.findall(r'<!-- @.*?-->', previous) or hall == 'PostCrisis_Synthesis' and filename == 'tutorial.md'
    for url in re.findall(r'\]\(([^)]+)\)', text):
        if url.startswith(('/', '#')) or ':' in url:
            continue
        assert (source.parent / unquote(url.split('#')[0])).resolve().is_file(), (hall, url)
        links += 1
    page(name + '.html', hall, render(text, source))
    diff = ''.join(difflib.unified_diff(previous.splitlines(True), text.splitlines(True), fromfile='before/' + str(rel), tofile='after/' + str(rel)))
    sections.append(f'<section><h2>{html.escape(hall)} · {filename}</h2><details><summary>Exact diff</summary><pre>{html.escape(diff)}</pre></details><div class="pair"><article><h3>Before</h3>{render(previous,source)}</article><article><h3>After</h3>{render(text,source)}</article></div></section>')

for rel in changed:
    target = OUT / 'after' / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / rel, target)
    old = (OUT / 'before' / rel).read_text(encoding='utf8')
    new = (ROOT / rel).read_text(encoding='utf8')
    diff = ''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), fromfile='before/' + rel, tofile='after/' + rel))
    dest = OUT / 'diffs' / (rel.replace('/', '__') + '.diff')
    dest.parent.mkdir(exist_ok=True)
    dest.write_text(diff, encoding='utf8')
    if rel.endswith('.json'):
        sections.append('<section><h2>Review register</h2><pre>' + html.escape(diff) + '</pre></section>')

validation = {
    'date': '2026-10-12', 'kind': 'source-and-text-validation',
    'changed_sources': changed, 'all_code_and_map_sources_unchanged': True,
    'sequence_and_plan_order_match': sequence, 'numeric_scores_unchanged': True,
    'score_notes_updated': score_halls, 'tutorial_excerpts_found_in_current_scripts': excerpts,
    'relative_source_links_resolve': links, 'runtime_rerun': False, 'headset_tested': False,
    'student_reconstruction_tested': False,
}
(OUT / 'validation.json').write_text(json.dumps(validation, indent=2) + '\n', encoding='utf8')
(OUT / 'source-register.json').write_text(json.dumps(after, indent=2) + '\n', encoding='utf8')
page('index.html', 'Post-crisis: what the record can support', render((OUT / 'REPORT.md').read_text(encoding='utf8')))
page('changes.html', 'Post-crisis before / after', '<h1>The applied changes</h1>' + ''.join(sections), True)
print(json.dumps(validation, indent=2))
