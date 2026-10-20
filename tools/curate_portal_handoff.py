"""Update only the Portals approach through the same save API as the editor."""
from pathlib import Path
import json, urllib.request
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-19-portals-carried-profile'
OUT.mkdir(parents=True,exist_ok=True)
URL = 'http://localhost:3003/api/void-layout'
payload = json.load(urllib.request.urlopen(URL))
rooms = payload['rooms']
floor = next(f for f in rooms['floors'] if f['map']=='Primitives_Portals')
(OUT/'before-floor.json').write_text(json.dumps(floor,indent=2),encoding='utf-8')
hall = next(a for a in floor['artifacts'] if a['id']=='hall')
parts = hall['config'].setdefault('parts',{})
parts['LimitTable'] = {'position':[0,0,5.7],'rotation':[0,90,0]}
parts['AchillesAndTortoise'] = {'position':[3,.84,5.7],'rotation':[0,90,0]}
floor['route'] = [{'label':label,'position':at} for label,at in [
    ('Arrival',[11,4]),('Around the shaft',[13.7,4]),
    ('Along the open approach',[6,3.8]),('01 / Smaller gaps, finite steps',[4.1,4.6]),
    ('Clear the table corner',[4.3,3.4]),('Along the limit table',[2.4,3.4]),('Continue to the carried profile',[-6,3.4]),
    ('Before the study',[-13.8,3.7]),('Round the study table',[-13.8,6.2]),('02 / Close the path; change the section',[-15.7,6.2]),
    ('Clear the study corner',[-18.5,6.2]),
    ('03 / Climb through the rings',[-18.5,4.4]),
]]
request = urllib.request.Request(URL,data=json.dumps({'rooms':rooms,'revision':payload['revision']}).encode(),headers={'Content-Type':'application/json'},method='POST')
receipt = json.load(urllib.request.urlopen(request))
(OUT/'layout-save.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
(OUT/'after-floor.json').write_text(json.dumps(floor,indent=2),encoding='utf-8')
print('Saved Portals approach; other floors and all original artifacts retained.')
