"""An isolated floor108 draft from this task's fresh API snapshot."""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/wind-tunnel-108'
p=json.loads((OUT/'before.json').read_text(encoding='utf8'));draft=copy.deepcopy(p['rooms'])
f=draft['floors'][108];a=next(a for a in f['artifacts'] if a['artifact']=='lattice_gas_pump')
a['position']=[17,0];a['facing']=270;a['height']=0;a['scale']=1
a['config']={'wind_tunnel_study':True,'initial_angle':0,'plinth':'0','editor_label':'Wind tunnel / turn the obstacle'}
(OUT/'draft-rooms.json').write_text(json.dumps(draft,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
print('Only the existing wind-tunnel occurrence on108 changes; all other objects remain.')
