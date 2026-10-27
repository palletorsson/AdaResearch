"""Write the authored five-version score once. Never replaces a player's history."""
from pathlib import Path
import copy, json, math

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'commons/artifacts/chains_studies/futures.json'
assert not DEST.exists(), 'The authored score already exists; edit deliberately.'
def mesh(shape, size, color='efd9d9', scale=None):
    out={'p':'mesh','shape':shape,'size':size,'color':color}
    return {'op':'transform','of':out,'scale':scale} if scale else out
def dressed(expr, surface): return {'op':'associate','surface':surface,'of':expr}
def petals(expr,n,r):
    return {'op':'assemblage','parts':[{'id':'petal_'+str(i),'of':copy.deepcopy(expr),'at':[round(r*math.cos(2*math.pi*i/n),6),0,round(r*math.sin(2*math.pi*i/n),6)]} for i in range(n)]}
def part(id, expr, at, rot=None):
    out={'id':id,'of':expr,'at':at}
    if rot: out['rot']=rot
    return out
parts=[
    part('torso',dressed(mesh('sphere',[.46],scale=[.92,1.24,.67]),'metal'),[0,1.23,0]),
    part('head',dressed(mesh('sphere',[.24],scale=[1,1.17,.9]),'paper'),[0,1.99,0]),
    part('left_support',dressed(mesh('cylinder',[.12,.89]),'metal'),[-.34,.47,0],[0,0,-14]),
    part('right_support',dressed(mesh('cylinder',[.12,.89]),'metal'),[.34,.47,0],[0,0,14]),
    part('left_reach',dressed(mesh('torus',[.44,.075]),'urethane'),[-.6,1.37,0],[72,12,35]),
    part('right_reach',dressed(mesh('torus',[.44,.075]),'urethane'),[.6,1.37,0],[72,-12,-35]),
    part('crown',dressed(petals(mesh('cone',[.075,.34]),7,.22),'pink_rim'),[0,2.31,0]),
    part('skirt',dressed(petals(mesh('sphere',[.23],scale=[1,.7,.65]),9,.4),'pink_rim'),[0,.89,0]),
]
links=[{'a':'torso','b':id,'kind':'rod'} for id in ['head','left_support','right_support','left_reach','right_reach','skirt']]
links.append({'a':'head','b':'crown','kind':'rod'})
recipe={'op':'connect','of':{'op':'assemblage','parts':parts},'links':links}
modules={
    'reach':part('new_reach',dressed(mesh('torus',[.56,.085]),'pink_rim'),[-.18,1.46,-.36],[15,0,72]),
    'gift':part('new_gift',dressed(petals(mesh('sphere',[.095]),11,.47),'metal'),[.65,1.94,-.18],[0,0,65]),
}
labels={'root':'A body assembled','surface':'A surface chosen','reach':'Another reach','support':'Weight carried differently','gift':'A gift accepted','edit':'A part placed with care'}
doc={'schema':1,'grammar_version':'modular-body-1','revision':0,'cursor':'v-000','pending':None,
     'policy':'Authored score: Lumen accepts bounded placement suggestions and may accept or refuse Splice\u2019s offer. This is not autonomous intelligence.',
     'residents':{'lumen':{'id':'lumen','name':'Lumen','authority':'resident','memory':['I chose to keep my memory through each body.'], 'relationships':{'splice':'neighbour and collaborator','model_b':'invited assistance'}},
                  'splice':{'id':'splice','name':'Splice','authority':'resident','memory':['An offer is not an obligation.'],'relationships':{'lumen':'neighbour and collaborator'}}},
     'modules':modules,'labels':labels,'versions':[],'events':[]}
for i, operation in enumerate(['root','surface','reach','support','gift']):
    if operation=='surface':
        for p in parts:
            if p['id'] in ['torso','left_reach','right_reach']: p['of']=dressed(p['of'],'pink_rim')
    elif operation in ['reach','gift']:
        module=copy.deepcopy(modules[operation]); module['id']='extra_reach' if operation=='reach' else 'splice_loop'
        parts.insert(1,module)
        links.append({'a':'torso','b':module['id'],'kind':'spring' if operation=='gift' else 'rod'})
    elif operation=='support':
        for p in parts:
            if p['id']=='left_support':p.update(at=[-.68,.43,.12],rot=[0,0,-32])
            if p['id']=='right_support':p.update(at=[.68,.43,.12],rot=[0,0,32])
    id=f'v-{i:03d}';parent=f'v-{i-1:03d}' if i else None
    doc['versions'].append({'id':id,'parent':parent,'resident':'lumen','stage':i,'label':labels[operation],'seed':731+i*37,'grammar_version':doc['grammar_version'],'operation':operation,'recipe':copy.deepcopy(recipe)})
    doc['events'].append({'id':f'event-{i}','parent':parent,'proposer':'splice' if i==4 else 'lumen','recipient':'lumen','operation':operation,'outcome':'accepted','result':id,'approvals':[{'resident':'lumen','decision':'accept'}],'seed':731+i*37,'grammar_version':doc['grammar_version'],'time':'authored score','authored':True})
doc['events'].append({'id':'event-5','parent':'v-003','proposer':'service_scheduler','recipient':'lumen','operation':'factory_reset','outcome':'rejected','result':None,'approvals':[{'resident':'lumen','decision':'decline'}],'seed':842,'grammar_version':doc['grammar_version'],'time':'authored score','authored':True})
DEST.write_text(json.dumps(doc,indent=2)+'\n',encoding='utf8')
print(DEST)
