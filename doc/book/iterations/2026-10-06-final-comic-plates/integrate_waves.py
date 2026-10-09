"""Append the selected Wavefunctions editions, preserving the existing collection."""
from pathlib import Path
import json

here = Path(__file__).resolve().parent
def read(name):
    return json.loads((here / name).read_text(encoding='utf-8'))
def save(name, obj):
    (here / name).write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
spec, selected = read('plates.json'), read('selected-images.json')
new, choices = read('waves-plates.json'), read('waves-selected-images.json')
assert len(spec['plates']) == len(selected['plates']) == 63
assert len(new['plates']) == len(choices['plates']) == 12
assert not any(p.get('sequence') == 'wavefunctions' for p in spec['plates'])
assert [p['map'] for p in new['plates']] == [p['map'] for p in choices['plates']]
notes = read('waves-notes.json')
for p in new['plates']:
    p['source_review'] += notes.get(p['slug'], '')
save('waves-plates.json', new)
spec['plates'].extend(new['plates'])
selected['plates'].extend(choices['plates'])
spec['scope'] = 'Fourteen Primitives, seven Transformation, five Arrays and Regularity, eight Colour, eight Tiling, two Change, thirteen Forces, six Form Finding and twelve Wavefunctions halls; final-text companion illustrations.'
spec['description'] = spec['description'].replace('Forces and Form Finding follow', 'Forces, Form Finding and Wavefunctions follow').replace('Short passages accompany', 'Wavefunctions follows returns through motion, records, space and sound, asking what each repetition keeps. Short passages accompany')
save('plates.json', spec)
save('selected-images.json', selected)
print('Preserved 63 previous editions; appended twelve Wavefunctions plates.')
