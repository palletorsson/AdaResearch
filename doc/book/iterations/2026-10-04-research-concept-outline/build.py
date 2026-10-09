"""Assemble the edited concept index; validate it against the current museum route."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ROUTE_PATH = ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json'
SPINE_PATH = ROOT/'commons/maps/curriculum_spine.json'
FOUNDATION_PATH = HERE.parent/'2026-10-04-foundations-before-randomness/plan.json'
VISUAL_PLAN_PATH = HERE.parent/'2026-10-04-foundations-visible/visual-plan.json'

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def main():
    route, spine = load(ROUTE_PATH), load(SPINE_PATH)
    sequences = load(HERE/'concepts-early.json') + load(HERE/'concepts-late.json')
    order = [s['name'] for s in sorted(spine['spine']['sequences'], key=lambda s:s['order'])]
    assert order == [s['id'] for s in route['sequences']], 'The route and spine order differ; review before rebuilding.'
    assert order == [s['id'] for s in sequences], 'Edited concept groups must follow the current spine.'
    halls = {h['id']:h for h in route['halls']}
    for sequence in sequences:
        assert sequence['title'].strip() and sequence['concepts']
        labels = [c['label'] for c in sequence['concepts']]
        assert len(labels) == len(set(labels)), sequence['id']
        for concept in sequence['concepts']:
            assert concept['label'].strip() and concept['maps']
            assert 'status' not in concept or concept['status'] == 'proposed', (sequence['id'], concept)
            assert len(concept['maps']) == len(set(concept['maps']))
            for hall in concept['maps']:
                assert hall in halls and halls[hall]['sequence']==sequence['id'], (sequence['id'], hall)
    data = dict(date='2026-10-04', source=ROUTE_PATH.relative_to(ROOT).as_posix(),
        note='Selected algorithmic and programming concepts in museum order. The proposed foundation layer is marked separately from existing encounters; teaching depth and implementation vary.',
        sequences=sequences)
    save(HERE/'concepts.json', data)
    lines = ['# Research concept outline', '', data['note'], '']
    for i, sequence in enumerate(sequences, 1):
        lines += [f'## {i:02d}. {sequence["title"]}', '']
        lines += [f'- {c["label"]}' + (' (proposed)' if c.get('status') == 'proposed' else '') for c in sequence['concepts']]
        lines += ['']
    (HERE/'outline.md').write_text('\n'.join(lines), encoding='utf-8')
    sources = [ROUTE_PATH, SPINE_PATH, FOUNDATION_PATH, VISUAL_PLAN_PATH, HERE/'concepts-early.json', HERE/'concepts-late.json']
    save(HERE/'manifest.json', dict(sequence_count=len(sequences),
        concept_count=sum(len(s['concepts']) for s in sequences),
        referenced_halls=len({m for s in sequences for c in s['concepts'] for m in c['maps']}),
        route_hall_count=len(halls),
        sources=[dict(path=p.relative_to(ROOT).as_posix(), sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in sources]))
    print(f'Assembled {len(sequences)} sequences; {sum(len(s["concepts"]) for s in sequences)} concept entries; order and hall references valid.')

if __name__ == '__main__':
    main()
