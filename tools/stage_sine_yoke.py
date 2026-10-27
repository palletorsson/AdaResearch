"""Register one hand-driven converter; stage and revision-save only floor59."""
import copy, json, sys, urllib.request, urllib.error, hashlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'ada_run/sine-yoke'
OUT.mkdir(exist_ok=True)
URL = 'http://localhost:3003/api/void-layout'
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def write(path, data): path.write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
def post(data):
    request = urllib.request.Request(URL, json.dumps(data).encode(), {'Content-Type':'application/json'}, method='POST')
    try:return json.load(urllib.request.urlopen(request, timeout=90))
    except urllib.error.HTTPError as error:raise RuntimeError(error.read().decode()) from error
def register():
    key='sine_yoke'
    definition=dict(lookup_name=key, name='Hand wheel / visible sine yoke', label='Hand wheel / visible sine yoke', scene='res://commons/artifacts/sine_yoke/sine_yoke.tscn',
        description='Turn the exposed crank by hand. The pin slides horizontally inside the yoke, whose height carries a timber cube on vertical guides. Stop or reverse at any position.',
        qfep_connection='Makes the ideal constraint visible: a circle becomes a line by allowing one direction and constraining the other. Kinematic linkage, not force-based mechanics.',
        category='wavefunctions',dev_category='wavefunctions',complexity='beginner',tags=['sine','rotation','translation','Scotch yoke','hand wheel'],
        interactions=['Desktop: drag around the wheel rim or crank.','XR: grip the wooden crank and move the hand around the wheel.'],
        parameters={'initial_angle':'Initial wheel position in degrees. No automatic drive.'},footprint=[1.9,2,.85],museum_import=True)
    registry=ROOT/'commons/artifacts/registry/sine_yoke.json'
    if not registry.exists():write(registry,dict(artifacts={key:definition}))
    catalog=ROOT/'commons/void/catalog.json';data=read(catalog)
    if key not in data['artifacts']:
        data['artifacts'][key]=definition;write(catalog,data)
    kitfile=ROOT/'commons/void/primitive-prefabs.json';kit=read(kitfile)
    if not any(p['id']==key for p in kit['prefabs']):
        kit['prefabs'].append(dict(id=key,title=definition['name'],map='WaveFunctions_Intro',family='Wavefunctions / motion converter',scene=definition['scene'],dimensions=[1.9,2,.85],
            anchor='Floor origin at timber feet. Mechanism and support are editable groups; wheel, pin, slot and cube stay coupled.',
            behaviour=definition['description'],learn='The circle\'s vertical coordinate becomes the cube\'s displacement. A sine in time requires constant turning speed.',icon='body',recipe=['timber_plank_2m','construction_cube'],
            placement=dict(artifact=key,source_floor=59,source_id='hand-sine-yoke',height=0,scale=1,config={'initial_angle':-25})))
        write(kitfile,kit)
    graphfile=ROOT/'commons/void/capacity-artifacts.json';graph=read(graphfile)
    if not any(n['id']==key for n in graph['nodes']):
        graph['nodes'].append(dict(id=key,title=definition['name'],sequence='wavefunctions',learn='A visible circular pin drives a guided timber cube.',use=definition['description'],icon='body',insertion=dict(map='WaveFunctions_Intro',basis='authored',reason='Hand-driven relationship between rotation and translation.')))
        for source in ['timber_plank_2m','construction_cube']:
            graph['edges'].append(dict(source=source,target=key,kind='combine',label='Known timber parts become a constrained motion converter.'))
        write(graphfile,graph)
def prepare():
    assert not (OUT/'before-rooms.json').exists(),'Draft already prepared; preserve it.'
    register()
    current=json.load(urllib.request.urlopen(URL,timeout=30));rooms=copy.deepcopy(current['rooms'])
    floor=rooms['floors'][59];assert floor['map']=='WaveFunctions_Intro'
    assert not any(a['id']=='hand-sine-yoke' for a in floor['artifacts'])
    floor['artifacts'].append(dict(id='hand-sine-yoke',artifact='sine_yoke',position=[-2.3,5.9],height=0,facing=0,scale=1,station='SW',config={'initial_angle':-25}))
    validation=post(dict(rooms=rooms,validateOnly=True));assert validation['valid'],validation
    write(OUT/'before-rooms.json',current['rooms']);write(OUT/'draft-rooms.json',rooms);write(OUT/'validation.json',validation)
    print('One converter registered and staged; live floor unchanged.')
def publish():
    report=read(OUT/'checks.json');assert report['passed'],report
    assert report['draft_sha256']==hashlib.sha256((OUT/'draft-rooms.json').read_bytes()).hexdigest()
    before=read(OUT/'before-rooms.json');draft=read(OUT/'draft-rooms.json')
    current=json.load(urllib.request.urlopen(URL,timeout=30));assert current['rooms']['floors'][59]==before['floors'][59],'Floor changed; review merge.'
    rooms=copy.deepcopy(current['rooms']);rooms['floors'][59]=draft['floors'][59]
    write(OUT/'before-publish-rooms.json',current['rooms'])
    result=post(dict(rooms=rooms,revision=current['revision']));write(OUT/'save-receipt.json',result)
    saved=json.load(urllib.request.urlopen(URL,timeout=30));assert saved['rooms']==rooms
    print('Saved one artifact on floor59; all existing items and other floors preserved.')
if __name__=='__main__':publish() if '--publish' in sys.argv else prepare()
