"""Restore the Sandbox pearl as well as its authored floor plan; scoped edits only."""
from pathlib import Path
import json
H=Path(__file__).resolve().parent; R=H.parents[3]; M='QFEP_Sandbox'
def read(p): return json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d): (R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
path='commons/data/book/qfeplaboratory.json'; book=read(path)
b=next(p for p in book['pearls'] if p['map']==M); b.pop('drop',None)
write(path,book)
lines={l['token']:l['text'] for l in b['lines']}
tokens=['lambda_slider','phi_slider','qfep_reactor','reactive_particles','qfep_formula_3d','tt']
maps=read('commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']['maps']
for path in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(path); n=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 edits=d['hand_pearls']['qfeplaboratory']; e=next(e for e in edits if e.get('map')==M)
 e.pop('drop',None); e.update(hero='qfep_reactor',says=lines,says_by={k:'hand' for k in lines})
 if not any(p['map']==M for p in n['pearls']):
  n['pearls'].append({'pearl':'qfep sandbox','map':M,'index':6,'hero':'qfep_reactor','hero_by':'hand','tokens':tokens,'blurb':(R/'commons/maps'/M/'blurb.md').read_text(encoding='utf-8').strip(),'says':lines,'says_by':{k:'hand' for k in lines}})
 n['pearls'].sort(key=lambda p:maps.index(p['map']))
 for i,p in enumerate(n['pearls']): p['index']=i
 d['counts']['pearls']=sum(len(n.get('pearls',[])) for n in d['trunk'])
 write(path,d)
path='commons/artifacts/registry/qfep.json'; registry=read(path); a=registry['artifacts']['qfep_reactor']
a['qfep_connection']='A local experiment in who receives a control value. CONNECT delivers two handle values, CUT retains the last accepted inputs, and REPEAT restarts the animation. The response law remains authored: a colour or pulse is not a measurement of freedom, life or entropy.'
a['dna']['wiring_study_note']='2026-09-20: the historical driver account above describes the default mode. QFEP_Sandbox now opts into a separate, explicit same-hall connection with visible received values. Other placements retain their original mode.'
write(path,registry)
print('Sandbox restored in book and both trunk mirrors; historical driver notes qualified')
