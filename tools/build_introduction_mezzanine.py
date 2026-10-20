"""Install one editable Introduction arrangement through the shared save API."""
from pathlib import Path
import json, urllib.request, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-20-introduction-steel-route'
OUT.mkdir(parents=True,exist_ok=True)
URL='http://localhost:3003/api/void-layout?trial=transformation'
p=json.load(urllib.request.urlopen(URL))
before=OUT/'before-rooms.json'
if before.exists():
    raise SystemExit('Already installed. Edit the current revision rather than replacing it.')
before.write_text(json.dumps(p['rooms'],indent=2)+'\n',encoding='utf8')
protected=[ROOT/'commons/void/rooms.json',ROOT/'commons/void/layout.json']
protected+=list((ROOT/'commons/maps').glob('*/final.md'))+list((ROOT/'commons/maps').glob('*/tutorial.md'))
(OUT/'preserved.json').write_text(json.dumps({f.relative_to(ROOT).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in protected},indent=2),encoding='utf8')
rooms=p['rooms'];floor=rooms['floors'][2]
cells=[]
def cell(id,kind,x,y,z,facing=0,**extra):
    cells.append(dict(id=id,kind=kind,position=[x,y,z],facing=facing,**extra))
# Four waiting banks. The last landing is the museum's movable bank.
for label,xs,pillar in [('Start',range(13,19),14),('Scale',range(2,8),5),('Turn',range(-8,-1),-5),('Exit',range(-18,-14),-14)]:
    for x in xs:
        for z in [-1.5,-.5,.5,1.5]:
            cell(f'{label}Deck{x}_{z}'.replace('-','m').replace('.','p'),'deck',x,2.88,z)
        for side in [-1.5,1.5]:
            cell(f'{label}Edge{x}_{side}'.replace('-','m').replace('.','p'),'truss',x,2.38,side)
    # A transverse frame seats into two pillar collars, away from all gaps.
    for i in range(14):
        cell(f'{label}Spine{i}','truss',pillar,2.38,-6.5+i,90)
    for z in [-7,7]:
        cell(f'{label}Collar{z}'.replace('-','m'),'collar',pillar,2.38,z,90)
# Original wp rises one metre over two metres, to the three-metre decks.
for z in [-1.5,1.5]:
    cell('ExitTie'+str(z).replace('-','m').replace('.','p'),'truss',-14,2.38,z)
for label,x,side in [('Entry',16.5,-1),('Leave',-16.5,1)]:
    for level in range(3):
        z=side*(7-level*2)
        for dx in [-.5,.5]:
            cell(f'{label}Ramp{level}_{dx}'.replace('-','m').replace('.','p'),'wedge',x+dx,level,z,0 if side<0 else 180)
            for y in range(level):
                for dz in [-.5,.5]:
                    cell(f'{label}Base{level}_{dx}_{y}_{dz}'.replace('-','m').replace('.','p'),'cube',x+dx,y,z+dz)
# The final wedge ends exactly at the deck edge (Z +/-2).
cell('SuspendedPlatform','platform',11.5,3,0,0,travel=[-3,0,0],speed=1,pause=5)
floor['title']='Introduction / three transformations in the steel frame'
floor['walls']=[]
floor['props']=[]
floor['construction']=cells
floor['artifacts']=[dict(id='sequence',artifact='void_trial_introduction_mezzanine',position=[0,0],height=0,facing=0,scale=1,station='NW',config={'museum_origin':'Trans_Introduction','editor_label':'Move, grow, turn / original mechanisms'})]
# Preserve the two vertical shafts. Excavate their side aisles and the centre.
floor['basin']={'depth':2.5,'glass':False,'rects':[[-1.5,-9,3,18],[7.5,-9,5,6],[7.5,3,5,6],[-12.5,-9,5,6],[-12.5,3,5,6]]}
floor['route']=[{'label':t,'position':v} for t,v in [('B ARRIVAL / RAMP TO THE STEEL DECK',[17.5,-8.2]),('01 MOVE',[15,0]),('02 GROW',[4,0]),('03 TURN / MOVE THE BANK',[-5,0]),('DOWN THE RAMP / A SOUTH-WEST',[-17,7.9])]]
req=urllib.request.Request(URL,data=json.dumps({'rooms':rooms,'revision':p['revision']}).encode(),headers={'Content-Type':'application/json'})
with urllib.request.urlopen(req) as response:receipt=json.load(response)
(OUT/'save-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print(json.dumps({'modules':len(cells),'receipt':receipt}))
