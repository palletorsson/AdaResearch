"""Align the necklace's short encounter cards with the promoted works and current source."""
from pathlib import Path
import copy,json
HERE=Path(__file__).resolve().parent
rel='commons/data/book/randomness.json'
book=json.loads((HERE/'before'/rel).read_text(encoding='utf-8'));proposals=[]
def propose(keys,new):
 old=book
 for k in keys:old=old[k]
 proposals.append(dict(path=rel,keys=keys,old=old,new=new))
for i,pearl in enumerate(book['pearls']):
 name=pearl.get('map')
 if name=='Random_Mushrooms':
  lines=copy.deepcopy(pearl['lines']);lines[1:1]=[
   dict(token='silhouette_arrivals',text='The arrivals keep their places while DRESS changes a wardrobe and FORMS changes the available outlines. Which change needs a different construction?',by='local-review-2026-09-19'),
   dict(token='couture_comparison',text='Keep three seeds and change the garment. The same numbers meet another way of making a body.',by='local-review-2026-09-19')]
  propose(['pearls',i,'lines'],lines)
 updates={
  'Random_Space_Geometry':('perlin_noise_bridge','Compare independent heights with correlated neighbours. Similar looking land can come from different procedures.'),
  'Random_Space':('noise_mixer','Several sine-based contributions make a field. Change the layers and compare the pattern while each image rescales its own contrast.'),
  'Random_Pheromone':('pheromone_terrain','Leave a mark that enters the next decision. From the same seeded starts, compare walkers drawn towards scent with walkers that avoid it.')}
 if name in updates:
  token,text=updates[name]
  if pearl['hero']!=token:propose(['pearls',i,'hero'],token)
  index=next(j for j,line in enumerate(pearl['lines']) if line['token']==token)
  line=copy.deepcopy(pearl['lines'][index]);line.update(text=text,by='local-review-2026-09-19')
  propose(['pearls',i,'lines',index],line)
(HERE/'root-book-proposals.json').write_text(json.dumps(proposals,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(len(proposals),'guarded book-card changes prepared; all existing cards and notes retained.')
