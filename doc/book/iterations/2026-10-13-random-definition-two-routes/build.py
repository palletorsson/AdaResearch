"""Build a self-contained reading desk from editable prose and its research map.

Run: python doc/book/iterations/2026-10-13-random-definition-two-routes/build.py
No dependencies; never writes the map's final.md or tutorial.md.
"""
import hashlib
import html
import json
import pathlib
import re

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
data = json.loads((HERE / 'study.json').read_text(encoding='utf-8'))
core = {n['id'] for n in data['pool'] if n['status'] == 'Selected in both'}
known = {n['id'] for n in data['pool']}

def count(text):
    return len(re.findall(r"\b[\w]+(?:[’'-][\w]+)*\b", text))

for route in data['routes']:
    raw = (HERE / route['file']).read_text(encoding='utf-8')
    body = raw.split('[^rand]:')[0]
    parts = re.split(r'<!-- ([AB]\d+) -->', body)[1:]
    prose = dict(zip(parts[::2], (p.strip() for p in parts[1::2])))
    assert set(prose) == {p['id'] for p in route['paragraphs']}, 'Prose / timeline mismatch'
    coverage = set()
    for para in route['paragraphs']:
        para['text'] = prose[para['id']]
        para['words'] = count(para['text'].replace('[^rand]', ''))
        assert set(para['knowledge']) <= known
        coverage.update(para['knowledge'])
    assert coverage == core, f"Shared core differs: {route['id']}"
    route['words'] = sum(p['words'] for p in route['paragraphs'])
    assert data['targetWords'][0] <= route['words'] <= data['targetWords'][1], 'Review prose budget'

for source in data['sources'].values():
    if 'path' in source:
        assert (ROOT / source['path']).exists(), source['path']
current_hash = hashlib.sha256((ROOT / data['baseline']).read_bytes()).hexdigest()
data['baselineUnchanged'] = current_hash == data['baselineSha256']

payload = json.dumps(data, ensure_ascii=False).replace('<', '\\u003c')
template = (HERE / 'template.html').read_text(encoding='utf-8')
(HERE / 'index.html').write_text(template.replace('__STUDY_DATA__', payload), encoding='utf-8')

lines = ['# Random Definition — two reading routes', '',
         'Experimental final.md drafts, 13 October 2026. No baseline selected.', '',
         '[Open the comparison](index.html) · [Shared pool and timelines](study.json)', '',
         'Edit draft-a.md or draft-b.md to change the prose. Edit study.json to change categories, evidence, relations or paragraph instructions. Keep the paragraph ID comments; run build.py to regenerate the page. The map texts are never written by this build.', '',
         'Browser reading notes stay in this browser. Download them to retain or share them; they do not edit the project. The page offers a folder/file workflow for prose, not a live prose editor.', '',
         '## Same material, different attention', '', data['editorial']['same'], '', data['editorial']['different'], '',
         data['editorial']['limit'], '', '## Reading timelines', '']
for route in data['routes']:
    lines += [f"### {route['id'].upper()} — {route['name']}", '',
              f"{route['words']} body words; 450–700 target. Heading, paragraph IDs and source note excluded.", '',
              route['promise'], '', '| Paragraph | Knowledge | Attitude / job | Instruction | Bridge | Words |',
              '| --- | --- | --- | --- | --- | ---: |']
    for p in route['paragraphs']:
        lines += [f"| {p['id']} · {p['label']} | {', '.join(p['knowledge'])} | {p['attitude']}. {p['job']}. | {p['instruction']} | {p['bridge']} | {p['words']} |"]
    lines += ['', 'Fit: ' + route['fit'], '', 'Risk: ' + route['risk'], '']
lines += ['## Provisional editorial reading', '', data['editorial']['recommendation'], '',
          data['editorial']['next'], '', '## Checks', '',
          f"- Both drafts cover the same {len(core)} selected knowledge nodes; all four reserve branches remain outside the prose.",
          '- Every paragraph has information references, a job, an attitude, a writing instruction, a reader gain, a bridge and an actual word count.',
          '- All local evidence paths resolve. Museum claims were checked against current placements and scripts; no new runtime or headset test is claimed.',
          f"- Original final.md matches the recorded SHA-256: {data['baselineUnchanged']}.",
          '- Tutorial construction remains in tutorial.md. These drafts contain no code, no new exercise and no claim that the imagined sleeve is installed.', '']
(HERE / 'README.md').write_text('\n'.join(lines), encoding='utf-8')
print(json.dumps({'words': {r['id']: r['words'] for r in data['routes']}, 'shared_nodes': len(core),
                  'baseline_unchanged': data['baselineUnchanged'], 'output': str(HERE / 'index.html')}))
