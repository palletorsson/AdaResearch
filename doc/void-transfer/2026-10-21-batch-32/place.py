"""First source-preserving arrangement; refuses to overwrite saved objects."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
POSITIONS={
 'swarmintelligence_03':[
  [(0,7),(-18,6),(-14,-8),(14,-8)],
  [(0,7)],
 ],
 'machinelearning_02':[
  [(-10,-9),(10,-9),(0,8)],
  [(-14,-8),(0,8),(14,-8)],
  [(-13,8),(-17,-9),(3,8)],
 ],
}

def main():
    prepared=[]
    for trial,positions in POSITIONS.items():
        folder=ROOT/'commons/void/trials'/trial
        inv=json.loads((folder/'source-inventory.json').read_text())
        rooms=json.loads((folder/'rooms.json').read_text())
        assert not any(f['artifacts'] for f in rooms['floors']), 'Existing arrangement: '+trial
        for level,places in enumerate(positions,1):
            originals=[a for a in inv['placements'] if a['floor']==level]
            assert len(originals)==len(places)
            for source,(x,z) in zip(originals,places):
                head,*bits=source['token'].split('#');parts=head.split(':')
                yaw=float(parts[1]) if len(parts)>1 and parts[1] else 0
                height=float(parts[2]) if len(parts)>2 and parts[2] else 0
                scale=float(parts[3]) if len(parts)>3 and parts[3] else 1
                config={}
                for bit in bits:
                    k,_,v=bit.partition(':');config[k]=v or 'true'
                rooms['floors'][level]['artifacts'].append(dict(id=source['id'],artifact=source['artifact'],
                    station=('S' if z>=0 else 'N')+('E' if x>=0 else 'W'),position=[x,z],
                    facing=int((yaw+180)%360),height=height,scale=scale,config=config))
        layout=json.loads((folder/'layout.json').read_text())
        layout['status']=trial+' / placement-first transfer'
        layout['floor_sign_positions']={str(i):[18,12] for i in range(1,len(positions)+1)}
        prepared.append((folder,rooms,layout))
    for folder,rooms,layout in prepared:
        (folder/'rooms.json').write_text(json.dumps(rooms,indent=2)+'\n')
        (folder/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')
        print(folder.name, sum(len(f['artifacts']) for f in rooms['floors']), 'originals placed')
if __name__=='__main__':main()
