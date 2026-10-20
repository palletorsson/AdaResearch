from pathlib import Path
import json, math
O=Path(__file__).resolve().parents[1]/'doc/book/iterations/2026-10-09-tiling-placement/specs'
O.mkdir(parents=True,exist_ok=True)
specs={
 'Pattern_Foundry':{
  'shots':[{'name':'small-studies','eye':[6,1.65,6.2],'target':[5.5,1.35,4],'fov':76},{'name':'machines','eye':[12,3,24],'target':[13,1.2,14],'fov':82},{'name':'miniatures','eye':[6.2,3,34],'target':[6.2,0,29],'fov':72}],
  'approaches':[('tile source',[4,0,4.7]),('mirror source',[7,0,4.7]),('brick source',[4,0,9.7]),('herringbone source',[7,0,9.7]),('maker',[8,0,14.5])],
  'paths':[[(12,0,2),(12,0,35)],[(12,0,16),(17,0,16)],[(12,0,25),(3,0,25)]]},
 'Tutorial_Pattern':{
  'shots':[{'name':'small-studies','eye':[6,1.65,14],'target':[5.5,1.35,12],'fov':72},{'name':'three-plates','eye':[8,2.7,10],'target':[8,1,7],'fov':92},{'name':'comparison-bay','eye':[22,1.65,14],'target':[22,1.3,9],'fov':70}],
  'approaches':[('mirror editor',[4,0,12.7]),('tile puzzle',[7,0,12.7]),('plate left',[4,0,5.8]),('plate centre',[8,0,5.8]),('plate right',[12,0,5.8]),('comparison source',[22,0,12])],
  'paths':[[(9,0,2),(9,0,18)],[(9,0,11),(22,0,11)]]},
 'Array_Patterns':{
  'shots':[{'name':'small-studies','eye':[5.5,1.65,16],'target':[5.5,1.35,14],'fov':86},{'name':'study-floor','eye':[9,3.5,13],'target':[6,0,10],'fov':75},{'name':'tunnel','eye':[22,1.65,14],'target':[24,2,8],'fov':76}],
  'approaches':[('tile source',[4,0,4.7]),('mirror source',[4,0,7.7]),('brick source',[4,0,14.7]),('herringbone source',[7,0,14.7]),('editor console',[9,0,6.2]),('plate',[13,0,10.7])],
  'paths':[[(10,0,7),(10,0,16)],[(10,0,12),(19,0,12)]]},
 'Symmetry_Seventeen':{
  'shots':[{'name':'looms','eye':[10,1.65,9.5],'target':[10,1.4,5],'fov':100},{'name':'mills','eye':[13,1.65,16.5],'target':[7,1,12],'fov':85},{'name':'atlas','eye':[13,1.65,28],'target':[13,1.3,24],'fov':94}],
  'approaches':[('puzzle',[10,0,17.7]),('loom left',[4,0,6.8]),('loom middle',[10,0,6.8]),('loom right',[16,0,6.8]),('atlas first row',[13,0,27]),('atlas middle row',[13,0,24.8]),('atlas back row',[13,0,22.6]),('editor',[20,0,11.5])],
  'paths':[[(13,0,2),(13,0,20)],[(7,0,20),(7,0,27.5)]]}
}
for name,s in specs.items():
 checks=[{'name':n,'point':p} for n,p in s['approaches']]
 for i,path in enumerate(s.pop('paths')):
  a,b=path;count=math.ceil(math.dist(a,b)/.4)
  for j in range(count+1):checks.append({'name':f'walk {i+1} sample {j+1}','point':[a[k]+(b[k]-a[k])*j/count for k in range(3)]})
 s['approaches']=checks
 (O/(name+'.json')).write_text(json.dumps(s,indent=2)+'\n')
