"""Correct only this hall's authored and shipped caption records."""
from pathlib import Path
import copy,json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-08-ca-two-ways-to-make'
folder=O/'before/catalogue';folder.mkdir(exist_ok=True)
replacements={
 'Five copies of yourself, arranged just so, and you contain yourself forever':'Six placements repeat at half the spacing. The cubes keep their size; neighbouring copies overlap.',
 'An 8-bit number is a universe — Rule 110 proves that three neighbors and one bit can compute …':'Change the seed. Follow the same row history from the desk onto the floor; the pyramid stays fixed.',
 'Wireworld: cells can be empty, electron head, electron tail, or conductor.':'A cellular history and a recursive cube construction resemble one another. Change the seed and compare what each procedure reads.'}
def update_scoped(value):
 if isinstance(value,dict):
  if value.get('map')=='CA_AgentsCircuits':
   if 'blurb' in value:value['blurb']=replacements.get(value['blurb'],value['blurb'])
   for token,sentence in value.get('says',{}).items():value['says'][token]=replacements.get(sentence,sentence)
  for item in value.values():update_scoped(item)
 elif isinstance(value,list):
  for item in value:update_scoped(item)
for suffix,path in [('source-trunk','commons/data/trunk_branches.json'),('shipped-trunk','commons/data/museum/trunk_branches.json')]:
 p=R/path;shutil.copy2(p,folder/(suffix+'.json'))
 text=p.read_text(encoding='utf-8');old=json.loads(text);expected=copy.deepcopy(old);update_scoped(expected)
 for a,b in replacements.items():text=text.replace(a,b)
 assert json.loads(text)==expected,'Replacement reached outside target hall'
 p.write_bytes(text.encode('utf-8'))
p=R/'commons/data/book/cellularautomata.json';shutil.copy2(p,folder/'cellularautomata.json')
d=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(d)
row=next(row for row in d['pearls'] if row['map']=='CA_AgentsCircuits')
for line in row['lines']:
 line['text']=replacements[line['text']]
 line['by']='codex-ca-comparison-2026-10-08'
 if line['token']=='sierpinski_pyramid':
  line['note']='This installed configuration uses six recursive calls, including an extra crown. Spacing halves; leaf cube size stays fixed. It is a finite collection with overlapping instances.'
  line['note_src']={'file':'algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd','quote':'_recursive_build(pos + Vector3(0, half_size, 0), half_size, current_depth - 1)'}
assert all(a==b for a,b in zip(old['pearls'],d['pearls']) if a['map']!='CA_AgentsCircuits')
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/maps/CA_AgentsCircuits/blurb.md';shutil.copy2(p,O/'before/blurb.md')
p.write_bytes((list(replacements.values())[-1]+'\n').encode('utf-8'))
print('Target hall blurb and two captions aligned in book, source trunk and shipped trunk.')
