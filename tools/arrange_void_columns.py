"""Place the Columns walk through the same revision-checked API as the editor."""
from pathlib import Path
import json,urllib.request
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-columns-comparisons'
URL='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(URL))
rooms=payload['rooms'];before=json.loads(json.dumps(rooms))
index=next(i for i,f in enumerate(rooms['floors']) if f['map']=='Primitives_Columns')
floor=rooms['floors'][index]
film=next(a for a in floor['artifacts'] if a['artifact']=='film_foundation_function')
film['position']=[-10,7.4];film['config']['museum_yaw']=180
floor['route']=[{'label':label,'position':at} for label,at in [
 ('Arrival',[11,3.7]),('Enter the comparisons',[6.9,3.7]),('North aisle',[6.9,-3.6]),
 ('01 / count around',[0,-3.6]),('Return beside the columns',[6.9,-3.6]),
 ('South aisle',[6.9,3.7]),('02 / count along the profile',[0,3.7]),
 ('Towards the outlines',[-6.7,3.7]),('Around the open shaft',[-13.3,3.7]),
 ('West comparison aisle',[-16.3,3.7]),('03 / five outlines',[-16.3,0]),
 ('Spindle and Cairn',[-16.3,-3.7]),('North wing',[-13.3,-3.7]),
 ('Cross the north aisle',[13.3,-3.7]),('East comparison aisle',[16.3,-3.7]),
 ('04 / five heights',[16.3,0]),('The taller columns',[16.3,3.7]),
 ('Around the second shaft',[13.3,3.7]),('Back to the centre',[6.9,3.7]),
 ('Read the family from the aisle',[0,3.7]),('Original function film',[-10,3.7]),
 ('05 / combine the choices',[-10,5.6]),('Return from the film',[-10,3.7]),
 ('Ready for Profiles',[6.9,3.7])]]
assert all(a==b for i,(a,b) in enumerate(zip(before['floors'],rooms['floors'])) if i!=index)
def post(data):
 req=urllib.request.Request(URL,json.dumps(data).encode(),{'Content-Type':'application/json'},method='POST')
 return json.load(urllib.request.urlopen(req))
validation=post({'rooms':rooms,'validateOnly':True})
assert validation['valid'],validation
receipt=post({'rooms':rooms,'revision':payload['revision']})
(OUT/'layout-receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
saved=json.load(urllib.request.urlopen(URL))['rooms']
assert saved==rooms
backup=Path.home()/'Desktop/Ada Void/rooms.json'
assert json.loads(backup.read_text())==rooms
print(f'Floor {index}: saved; other floors preserved; Desktop backup matches.')
