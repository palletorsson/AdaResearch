"""Check the selected comic editions and their Encyclopedia URLs."""
from pathlib import Path
from hashlib import sha256
from urllib.request import Request, urlopen
from concurrent.futures import ThreadPoolExecutor
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
APP = ROOT.parent / 'ada_encyclopedia'
BASE = 'http://localhost:3003'
FINAL = 'doc/book/iterations/2026-10-06-final-comic-plates'
TUTORIAL = 'doc/book/iterations/2026-10-05-tutorial-comic-plates'
GHOST = 'doc/book/iterations/2026-10-05-ghost-student-comic'
POST = '2026-10-06-what-a-picture-has-to-carry'

def read(relative):
    return json.loads((ROOT / relative).read_text(encoding='utf-8'))

targets = {'/illustrations', '/illustrations?plate=final-Point_Trace', '/blog/' + POST, '/blog', '/illustrations?sequence=change', '/illustrations?sequence=change&plate=final-Change_Intro', '/illustrations?sequence=forces', '/illustrations?sequence=forces&plate=final-Vectors_Act1_WhatAVectorIs', '/illustrations?sequence=formfinding', '/illustrations?sequence=formfinding&plate=final-FormFinding_Descent'}
targets.update({'/illustrations?sequence=wavefunctions', '/illustrations?sequence=wavefunctions&plate=final-WaveFunctions_Intro'})
targets.update({'/illustrations?sequence=randomness', '/illustrations?sequence=randomness&plate=final-Random_Definition'})
selected = []
for directory in [FINAL, TUTORIAL]:
    evidence = read(directory + '/provenance.json')['plates']
    for p in evidence:
        image = ROOT / directory / p['image']
        assert sha256(image.read_bytes()).hexdigest() == p['image_sha256'], image
        selected.append(dict(map=p['map'], kind='final' if directory == FINAL else 'tutorial', image=directory + '/' + p['image'], sha256=p['image_sha256']))
        for relative in [directory + '/' + p['image'], p['source'], directory + '/PROMPTS.md', directory + '/provenance.json']:
            assert (ROOT / relative).is_file(), relative
            targets.add('/book-review/' + relative)
        if directory == FINAL:
            relative = directory + '/sources/' + p['map'] + '.md'
            targets.add('/book-review/' + relative)

ghost = read(GHOST + '/provenance.json')
image = ROOT / GHOST / ghost['asset']
assert sha256(image.read_bytes()).hexdigest() == ghost['sha256']
selected.append(dict(map=None, kind='synopsis', image=GHOST + '/' + ghost['asset'], sha256=ghost['sha256']))
for f in [ghost['asset'], 'SYNOPSIS.md', 'PROMPT.txt', 'provenance.json']:
    targets.add('/book-review/' + GHOST + '/' + f)
assert len({p['image'] for p in selected}) == len(selected)
count = len(selected)

article_path = APP / 'src/content/blog' / (POST + '.md')
article = article_path.read_text(encoding='utf-8')
for target in re.findall(r'\]\((/[^)]+)\)', article):
    targets.add(target)

def check(target):
    with urlopen(Request(BASE + target, method='HEAD'), timeout=60) as response:
        assert response.status == 200, (target, response.status)
        return dict(url=target, status=response.status)

with ThreadPoolExecutor(max_workers=4) as pool:
    links = list(pool.map(check, sorted(targets)))
with urlopen(BASE + '/illustrations') as response:
    html = response.read().decode('utf-8')
assert html.count('<img ') == count
assert str(count) in html and 'What a picture has to carry' in html
with urlopen(BASE + '/illustrations?sequence=change') as response:
    filtered = response.read().decode('utf-8')
assert filtered.count('<img ') == 2, 'Change filter must contain only two illustrations.'
assert 'WHAT DID THE INTERVAL KEEP?' in filtered and 'THE NEXT READING' in filtered
with urlopen(BASE + '/illustrations?sequence=forces') as response:
    forces = response.read().decode('utf-8')
assert forces.count('<img ') == 13, 'Forces filter must contain thirteen illustrations.'
assert 'THE SAME DIFFERENCE' in forces and 'WHAT CARRIES YOU ACROSS?' in forces
with urlopen(BASE + '/illustrations?sequence=formfinding') as response:
    formfinding = response.read().decode('utf-8')
assert formfinding.count('<img ') == 6, 'Form Finding filter must contain six illustrations.'
assert 'WHERE DOES DOWNHILL TAKE YOU?' in formfinding and 'A SHAPE THAT COUNTS' in formfinding
with urlopen(BASE + '/illustrations?sequence=wavefunctions') as response:
    waves = response.read().decode('utf-8')
assert waves.count('<img ') == 12, 'Wavefunctions filter must contain twelve illustrations.'
assert 'RETURNING DIFFERENTLY' in waves and 'THE SUM ON THE BENCH' in waves
with urlopen(BASE + '/illustrations?sequence=randomness') as response:
    randomness = response.read().decode('utf-8')
assert randomness.count('<img ') == 14, 'Randomness filter must contain fourteen illustrations.'
assert 'THE PICTURE NEEDED MORE THAN A NAME' in randomness and 'DECIDED, OR NOT YET DRAWN?' in randomness
with urlopen(BASE + '/blog') as response:
    assert POST in response.read().decode('utf-8')
with urlopen(BASE + '/blog/' + POST) as response:
    assert 'What a picture has to carry' in response.read().decode('utf-8')

report = dict(date='2026-10-06', collection='/illustrations', blog='/blog/' + POST,
              count=count, tutorial=sum(p['kind']=='tutorial' for p in selected),
              final=sum(p['kind']=='final' for p in selected), synopsis=1, image_records=selected,
              article_sha256=sha256(article_path.read_bytes()).hexdigest(),
              local_urls_checked=links, blog_index_contains_article=True,
              typecheck='Passed for the new route and its dependencies.',
              browser_review='Previously checked: Tutorial filter (8), Transformation filter (7), Trace search (2), tutorial/final companion and rendered blog. Arrays: five-page sequence filter, Array reader layout and Next navigation. Colour: eight-page filter and Next navigation through Context, Flashlight, Nails, Rainbow, Pillar, Grid, Paint and Walls checked in the in-app browser. Tiling: eight-page filter, direct reader links and Next navigation through Foundry, Pattern, Array Patterns, Symmetry, Volume, Carrier and Fabric verified; reader screenshot inspected. Change: two-page sequence filter, Change Intro selection, Next to Flow Field and disabled sequence-end navigation checked; collection screenshot saved. Forces: thirteen-page filter, first selection, Next to Operations, direct last-hall link, disabled end navigation and Previous to Arena checked; collection screenshot saved. Form Finding: six-page filter, Descent selection with Previous disabled, Next to Catenary with filter retained, direct Forge link with Next disabled, Previous to Annealing and return to collection checked; collection screenshot saved.',
              scope='Selected comic editions, not all museum captures or discarded image drafts. No source chapters or museum runtime changed.')
report['browser_review'] += ' Wavefunctions: twelve-page filter, Intro with Previous disabled, Next to Pendulum with filter retained, direct Synthesis Lab link with Next disabled, Previous to TrigWalkingPath and return to collection checked; collection screenshot saved.'
report['browser_review'] += ' Randomness: fourteen-page filter, Definition with Previous disabled, Next to Entropy with filter retained, direct Game link with Next disabled, Previous to Space and return to collection checked; collection screenshot saved.'
(HERE / 'checks.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(f'{count} image hashes match; {len(links)} local URLs return 200; article appears in blog index.')
