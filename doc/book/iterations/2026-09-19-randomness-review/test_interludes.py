"""Check route expansion and targeted-refresh preservation without touching live files."""
from pathlib import Path
import copy,sys,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
sys.path.insert(0,str(ROOT/'tools'))
from em_refresh_sequence import expanded_museum_maps,patch_plan,patch_declaration
checks=[]
def check(name,ok):
 checks.append(dict(name=name,ok=bool(ok)));assert ok,name
base={'maps':['One','Two','Three']}
check('Default chapters unchanged',expanded_museum_maps(base)==base['maps'])
spec={**base,'museum_interludes':[{'map':'Between','after':'One'},{'map':'Coda','after':'Three'}]}
order=expanded_museum_maps(spec)
check('Anchored insertion preserves chapter order',order==['One','Between','Two','Three','Coda'])
check('Expansion leaves its input intact',spec['maps']==['One','Two','Three'])
for name,extra in [('duplicate chapter',[{'map':'One','after':'Two'}]),('unknown anchor',[{'map':'Other','after':'Missing'}]),('duplicate interlude',[{'map':'Other','after':'One'},{'map':'Other','after':'Two'}]),('unsafe name',[{'map':'../Other','after':'One'}])]:
 try:expanded_museum_maps({**base,'museum_interludes':extra})
 except ValueError:check('Reject '+name,True)
 else:check('Reject '+name,False)
plan={'plans':[{'sequence':'earlier','map':'Outside','payload':[1,2]},*({'sequence':'here','map':n,'pearl_index':i,'pearls_total':len(order),'payload':[n]} for i,n in enumerate(order)),{'sequence':'later','map':'Last','payload':[3]}], 'extra':'retain'}
new={'sequence':'here','map':'Two','pearl_index':2,'pearls_total':5,'payload':['new token config']}
patched=patch_plan(plan,'here',['Two'],[new],['earlier','here','later'],order,True)
check('Targeted refresh keeps interludes and unrelated rows',[r for r in patched['plans'] if r['map']!='Two']==[r for r in plan['plans'] if r['map']!='Two'])
check('Targeted refresh retains sixteen-style order fields',[r['pearl_index'] for r in patched['plans'] if r['sequence']=='here']==list(range(5)))
check('Targeted refresh is idempotent',patch_plan(patched,'here',['Two'],[new],['earlier','here','later'],order,True)==patched)
d={'_readme':'keep','here':order,'later':['Last']}
check('Authored ownership keeps interludes',patch_declaration(d,'here',['Two'],order)==d)
record={'checks':checks,'count':len(checks),'scope':'Pure route expansion and patch preservation; no live mutations'}
(HERE/'interlude-checks.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(len(checks),'route helper checks passed')
