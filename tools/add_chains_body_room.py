"""Add the walk-in body to the authored score; leaves live history untouched."""
from pathlib import Path
import copy,json,math
p=Path(__file__).resolve().parents[1]/'commons/artifacts/chains_studies/futures.json'
doc=json.loads(p.read_text(encoding='utf8'))
assert not any(v['id']=='room-within' for v in doc['versions']), 'Room already authored.'
def solid(shape,size,color):
    return {'op':'compose','parts':[{'p':'body','kind':'static'}, {'p':'mesh','shape':shape,'size':size,'color':color}, {'p':'collider','shape':shape,'size':size}]}
recipe=copy.deepcopy(doc['versions'][4]['recipe']);parts=recipe['of']['parts'];shell=[]
for row in range(11):
    y=.2+row*.245
    radius=1.25-.31*((y-1.35)/1.5)**2
    count=30
    for i in range(count):
        angle=2*math.pi*i/count;x=radius*math.sin(angle);z=.85*math.cos(angle)
        # An actual open doorway, not a transparent collider filling the cavity.
        if z>0 and abs(x)<.61 and y<2.15:continue
        color='816385' if z<-.25 else ('e6aacd' if abs(x)>.6 else 'f0c7df')
        shell.append({'id':f'pearl_{row}_{i}','at':[round(x,5),round(y-1.23,5),round(z,5)],'of':solid('sphere',[.16],color)})
for part in parts:
    id=part['id']
    if id=='torso':part['of']={'op':'assemblage','parts':shell}
    elif id=='head':part.update(at=[0,3.02,0],of={'op':'associate','surface':'paper','of':{'p':'mesh','shape':'sphere','size':[.31]}})
    elif id=='crown':part['at']=[0,3.48,0]
    elif id=='left_reach':part['at']=[-1.47,1.9,0]
    elif id=='right_reach':part['at']=[1.47,1.9,0]
    elif id=='extra_reach':part['at']=[-1.5,2.65,-.35]
    elif id=='splice_loop':part['at']=[1.38,2.67,-.22]
    elif id=='skirt':part.update(at=[0,2.65,0],scale=[2.0,.7,1.5])
    elif id=='left_support':part.update(at=[-1.05,.35,.05],rot=[0,0,-12])
    elif id=='right_support':part.update(at=[1.05,.35,.05],rot=[0,0,12])
parts.append({'id':'room_floor','at':[0,-.06,0],'of':{'op':'compose','parts':[{'p':'body','kind':'static'},{'p':'mesh','shape':'plane','size':[1.65,1.7],'color':'9f7c9a','at':[0,.055,0]},{'p':'collider','shape':'box','size':[1.65,.09,1.7]}]}})
parts.append({'id':'inside_light','at':[0,2.2,0],'of':{'p':'light','energy':.65,'range':4,'color':'ffe5ca'}})
# Route visible connections around the room rather than across its doorway.
recipe['links']=[{'a':a,'b':b,'kind':'rod'} for a,b in [('head','crown'),('left_support','left_reach'),('right_support','right_reach'),('left_reach','extra_reach'),('right_reach','splice_loop')]]
doc['modules']['room']={'recipe':recipe}
doc['labels']['room']='A room within the body'
doc['versions'].append({'id':'room-within','parent':'v-004','resident':'lumen','stage':5,'label':doc['labels']['room'],'seed':916,'grammar_version':doc['grammar_version'],'operation':'room','inhabitable':True,'recipe':recipe})
doc['events'].append({'id':'event-6','parent':'v-004','proposer':'lumen','recipient':'lumen','operation':'room','outcome':'accepted','result':'room-within','approvals':[{'resident':'lumen','decision':'accept'}],'seed':916,'grammar_version':doc['grammar_version'],'time':'authored score','authored':True})
doc['cursor']='room-within'
p.write_text(json.dumps(doc,indent=2)+'\n',encoding='utf8')
print('Walk-in body: open doorway; individual static pearl colliders; tower floor retained.')
