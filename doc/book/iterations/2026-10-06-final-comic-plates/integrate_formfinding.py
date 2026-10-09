"""Append the reviewed Form Finding editions without replacing earlier plates."""
from pathlib import Path
import json

here = Path(__file__).resolve().parent
def read(name):
    return json.loads((here / name).read_text(encoding='utf-8'))
def save(name, obj):
    (here / name).write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

spec = read('plates.json')
selected = read('selected-images.json')
new = read('formfinding-plates.json')
choices = read('formfinding-selected-images.json')
assert len(spec['plates']) == len(selected['plates']) == 57
assert len(new['plates']) == len(choices['plates']) == 6
assert not any(p.get('sequence') == 'formfinding' for p in spec['plates'])
assert [p['map'] for p in new['plates']] == [p['map'] for p in choices['plates']]
new['plates'][0]['source_review'] = 'A single schematic landscape overlays the histories of two separate runs; it is not a simultaneous-run mode or a new museum control. Plot height and arrow length are display choices. The main table view selects a rugged landscape while the step inset explains the bowl case; the page is not a temporal record of switching landscapes.'
spec['plates'].extend(new['plates'])
selected['plates'].extend(choices['plates'])
spec['scope'] = 'Fourteen Primitives, seven Transformation, five Arrays and Regularity, eight Colour, eight Tiling, two Change, thirteen Forces and six Form Finding halls; final-text companion illustrations.'
spec['description'] = spec['description'].replace('Change and Forces follow', 'Change, Forces and Form Finding follow').replace('Short passages accompany', 'Form Finding separates drawn constraints, formulae, retained simulations, ideal balance, search and authored success criteria. Short passages accompany')
save('formfinding-plates.json', new)
save('plates.json', spec)
save('selected-images.json', selected)
print('Preserved 57 previous editions; appended six Form Finding plates.')
