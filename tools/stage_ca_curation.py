"""Reflow existing CA occurrences for the actual 42x18 tower; never regenerate sources."""
import copy,json,math,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-curation';TRIALS=ROOT/'commons/void/trials'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def turn(p,degrees):
    c=math.cos(math.radians(degrees));s=math.sin(math.radians(degrees))
    return [c*p[0]+s*p[1],-s*p[0]+c*p[1]]
def corners(lo,hi):return [[x,z] for x in [lo[0],hi[0]] for z in [lo[1],hi[1]]]
def rect(points):return [min(v[0] for v in points),min(v[1] for v in points),max(v[0] for v in points),max(v[1] for v in points)]
# Desired centres of full drawn XZ bounds, yaw. These retain human-scale geometry.
PLANS={
103:{'ca_rule_explorer':(-3.5,2,0),'persian_rug':(3.5,3.4,0),'synthesis_stand':(5.5,6,0),'dark_sphere':(3.5,3.8,0),'langton_swarm':(0,0,0),'line_network_ca':(3.5,-3,0),'ca_showcase':(-3.5,-3,0),'rule110_computer':(0,-6.5,0)},
104:{'structure_growth':(0,0,0),'dark_sphere':(5,5,0)},
105:{'ca_bridge':(0,0,90),'lab_room':(-16.4,0,270),'film_cellular_history':(5.5,6.6,0),'dark_sphere':(16,-4.5,0),'ca_columns':(16,0,0),'mirrored_cellular_automata':(16,4.5,0)},
106:{'game_of_life_petri':(0,0,90),'science_screen':(-16,-5,90),'mold_network':(-16,1,0),'dark_sphere':(-16,5,0),'hexagon_ca_vr':(16,0,0),'ca_growth_network':(16,5.5,0)},
107:{'decaying_bridge':(0,0,90),'crossway_ca':(16,3,0),'ca_chair_test':(16,-3,0),'dark_sphere':(16,6,0),'catalyst_vent':(-16,1,0),'catalyst_prompter_box':(-16,5,0),'cellular_automata_3d_tree':(-16,-3,0)},
108:{'rd_artifact':(0,1,180),'the_clockmaker_of_rules':(0,-5.5,0),'crack_propagation_ca':(-16,-5,0),'lattice_gas_pump':(16,0,0),'ca_sphere':(-16,0,0),'rule_30_110_gravity':(16,-5,0)},
109:{'ca_rule_explorer':(-1,0,0),'film_ca_triplet':(-16,0,0),'sierpinski_pyramid':(16,0,0)},
110:{'self_organization_ca':(0,0,0),'ca_screen':(16,5.5,0),'disease_spread_ca':(16,-.5,0),'volumetric_fog_ca':(-16,-2,0),'crackpropagation_ca':(-16,4,0)}}
def main():
    rooms=read(OUT/'before-rooms.json');draft=copy.deepcopy(rooms);bounds={};sources={}
    for trial in ['cellularautomata','cellularautomata_02','cellularautomata_03']:
        src=read(TRIALS/trial/'rooms.json');layout=read(TRIALS/trial/'layout.json')
        if trial=='cellularautomata':
            measured=[dict(v,floor=int(k.split('/')[0]),id=k.split('/')[1],local_y=True) for k,v in read(TRIALS/trial/'evidence/measure.json').items()]
        else:measured=read(TRIALS/trial/'evidence/measured-bounds.json')
        for m in measured:
            f=src['floors'][m['floor']];a=next(a for a in f['artifacts'] if a['id']==m['id']);sources[m['id']]=(a,f)
            bounds[m['id']]=m
    notes=[]
    for index,plan in PLANS.items():
        floor=draft['floors'][index]
        for a in floor['artifacts']:
            before=copy.deepcopy(a)
            old,sourcefloor=sources[a['id']];m=bounds[a['id']];x,z,yaw=plan[a['artifact']]
            if a['artifact']=='structure_growth':a['scale']=1.35
            ratio=float(a['scale'])/float(old['scale'])
            points=[turn([p[0]-old['position'][0],p[1]-old['position'][1]],yaw-float(old['facing'])) for p in corners([m['min'][0],m['min'][2]],[m['max'][0],m['max'][2]])]
            points=[[v*ratio for v in p] for p in points];b=rect(points)
            newpos=[round(x-(b[0]+b[2])/2,4),round(z-(b[1]+b[3])/2,4)]
            a['position']=newpos;a['facing']=yaw
            a['station']=('S' if z>=0 else 'N')+('E' if x>=0 else 'W')
            if a['artifact']=='lab_room':a['config']['void_auto_door']=True
            if a['artifact'] in ['game_of_life_petri','ca_bridge']:
                def local(p):
                    q=turn([p[0]-newpos[0],p[2]-newpos[1]],-yaw)
                    return [round(q[0],4),p[1]-a['height'],round(q[1],4)]
                a['config']['curated_console']=dict(position=local([0,1.06,6.35]),yaw=-yaw,dock=local([-1.3,0,6.35]),readout=local([1.65,1.55,6.35])) if a['artifact']=='game_of_life_petri' else dict(position=local([0,1.4,5.55]),yaw=-yaw,readout=local([-2,1.55,5.55]))
            if a['artifact'] in ['ca_screen','rule110_computer','langton_swarm']:
                a['interface']=dict(style='ceiling_instrument',clearance=.25,accent='#ef80b8',title={'ca_screen':'CA / LIVE SURFACE','rule110_computer':'RULE110 / SIGNALS','langton_swarm':'TURMITES / SHARED FIELD'}[a['artifact']],action='OBSERVE THE LOCAL RULE / FOLLOW ITS CONSEQUENCES')
            if a['artifact'] in ['disease_spread_ca','crack_propagation_ca']:a['config']['ca_live']=True
            if a['artifact']=='disease_spread_ca':
                # Full original 64³ field, fitted to a six-metre storey instead
                # of silently drawing only the infection samples that fit.
                a['scale']=.21;a['height']=2.85;a['position']=[16.042,-.458]
            if a['artifact'] in ['ca_bridge','decaying_bridge','structure_growth'] and sourcefloor.get('basin'):
                ratio=float(a['scale'])/float(old['scale'])
                basin=copy.deepcopy(sourcefloor['basin']);raw=basin.get('rects',[basin['rect']] if 'rect' in basin else [])
                changed=[]
                for r in raw:
                    transformed=[]
                    for p in corners(r[:2],[r[0]+r[2],r[1]+r[3]]):
                        q=turn([p[0]-old['position'][0],p[1]-old['position'][1]],yaw-float(old['facing']))
                        transformed.append([newpos[0]+q[0]*ratio,newpos[1]+q[1]*ratio])
                    r2=rect(transformed);changed.append([round(r2[0],4),round(r2[1],4),round(r2[2]-r2[0],4),round(r2[3]-r2[1],4)])
                basin.pop('rect',None);basin['rects']=changed;floor['basin']=basin
            notes.append(dict(floor=index,id=a['id'],artifact=a['artifact'],before=before,after=copy.deepcopy(a),planned_bounds=[round(x-(b[2]-b[0])/2,3),round(z-(b[3]-b[1])/2,3),round(b[2]-b[0],3),round(b[3]-b[1],3)]))
        floor['title']=floor['map'].replace('CA_','CA / ').replace('_',' ')
        # Transfer provenance remains in the inventory; it is not floor signage.
        floor['route']=[]
        if index==109:
            floor['artifacts'].append(dict(id='ca-architectural-history',artifact='void_ca_history_wall',station='NW',position=[0,-5.8],height=0,facing=0,scale=1,config=dict(source_id='f4_ca_rule_explorer_3_5')))
        def wall(name,a,b,height):
            floor.setdefault('walls',[]).append(dict(id='ca-stage-'+name,**{'from':a,'to':b},height=height,finish='unfinished'))
        if index==103:
            wall('row-pocket',[-6.5,.3],[-6.5,4.5],1.7)
            wall('rug-back',[1.5,.7],[6,.7],1.55)
            wall('showcase-edge',[-6.5,-4.8],[-6.5,-1.5],1.7)
            wall('network-edge',[6.5,-4.8],[6.5,-1.5],1.7)
        elif index==104:
            wall('neighbour-left',[-5.5,-3.5],[-5.5,3],1.7)
            wall('neighbour-right',[6,-3.5],[6,3],1.7)
        else:
            wall('west-work-pocket',[-20.4,-5.6],[-20.4,5.6],2.2)
            wall('east-work-pocket',[20.4,-5.6],[20.4,5.6],2.2)
            wall('west-back',[-20.3,-6.3],[-13.3,-6.3],1.4)
            wall('east-back',[13.3,-6.3],[20.3,-6.3],1.4)
        cells=floor.setdefault('construction',[])
        for number,(kind,p,yaw) in enumerate([('cube',[-6.5,0,6.2],0),('wedge',[-6.5,0,4.7],0)] if index in [103,104] else [('cube',[-19.2,0,6.5],0),('wedge',[-17.7,0,6.5],270),('cube',[19.2,0,6.5],0),('wedge',[17.7,0,6.5],90)]):
            cells.append(dict(id='ca-stage-threshold-'+str(number),kind=kind,position=p,facing=yaw))
        lamps=[([-6.5,5.5],270),([7,5.9],0)] if index==103 else [([-18.6,6.1],0),([18.6,6.1],0)]
        if index==104:lamps=[([-6.8,4.5],270),([6.8,4.5],90)]
        if index>=105:lamps.append(([-6.5,6.5],270))
        for number,(p,yaw) in enumerate(lamps):floor.setdefault('props',[]).append(dict(id='ca-stage-light-'+str(number),kind='work_light',position=p,facing=yaw,scale=1))
    write(OUT/'draft-rooms.json',draft);write(OUT/'reflow.json',notes)
    req=urllib.request.Request('http://localhost:3003/api/void-layout',json.dumps(dict(rooms=draft,validateOnly=True)).encode(),{'Content-Type':'application/json'},method='POST')
    with urllib.request.urlopen(req,timeout=90) as r:validation=json.load(r)
    write(OUT/'draft-validation.json',validation);assert validation['valid'],validation
    print('Drafted all43 original CA occurrences on eight standard floors; not published.')
if __name__=='__main__':main()
