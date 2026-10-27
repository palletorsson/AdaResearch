"""Refresh generated Grid/Museum comparison models for one saved spine map."""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]


def sequence_for(map_name):
    spine = json.loads((ROOT/'commons/maps/curriculum_spine.json').read_text(encoding='utf-8'))
    for item in spine.get('spine',{}).get('sequences',[]):
        name = item['name']
        source = ROOT/'commons/maps/sequences'/f'{name}.json'
        if not source.is_file(): continue
        doc = json.loads(source.read_text(encoding='utf-8'))
        sequence = doc.get('sequences',{}).get(name,doc)
        maps = [m if isinstance(m,str) else m.get('name') for m in sequence.get('maps',[])]
        if map_name in maps: return name
    raise ValueError('No spine sequence owns this map; its Museum hall cannot be inferred safely')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('map')
    parser.add_argument('--grid-edition',choices=['historic','current'],default='historic')
    args = parser.parse_args()
    assert args.map.replace('_','').isalnum()
    out = ROOT/'ada_run/spatial-comparison'/args.map
    out.mkdir(parents=True,exist_ok=True)
    status = out/('prepare-historic.json' if args.grid_edition=='historic' else 'prepare.json')
    def record(state,message):
        data = dict(map=args.map,edition=args.grid_edition,pid=os.getpid(),state=state,message=message,updatedAt=time.time())
        temp = out/(status.name+'.tmp')
        temp.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
        os.replace(temp,status)
    try:
        record('running',f'Preparing {args.grid_edition} Grid and current Museum views; waiting for the shared native slot if occupied.')
        sequence = sequence_for(args.map)
        baseline=json.loads((ROOT/'commons/data/spatial_comparison_sources.json').read_text())['historic_grid']
        historic=args.grid_edition=='historic'
        for label,command in [('Grid',['tools/export_historic_grid.py' if historic else 'tools/export_spatial_comparison.py',args.map]),
                              ('Museum',['tools/export_spatial_museum.py',args.map,'--sequence',sequence])]:
            public = ROOT.parent/'ada_encyclopedia/public/spatial-comparison'/args.map
            manifest = public/(('historic/'+baseline['commit'][:12]+'/manifest.json' if historic else 'manifest.json') if label=='Grid' else 'museum/manifest.json')
            if manifest.is_file():
                previous=json.loads(manifest.read_text(encoding='utf-8'))
                digest=lambda p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() if (ROOT/p).is_file() else None
                fresh=(previous.get('history',{}).get('commit')==baseline['commit'] if historic else previous.get('source_sha256')==digest(f'commons/maps/{args.map}/map_data.json')) if label=='Grid' else previous.get('isolated_outputs') and all(digest(p)==v for p,v in previous.get('sources',{}).items())
                if fresh: continue
            record('running',f'Building {label} geometry. Native jobs run serially; your layouts remain untouched.')
            with (out/f'prepare-{label.lower()}.log').open('w',encoding='utf-8') as log:
                result = subprocess.run([sys.executable,*command],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                                        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0,timeout=1500)
            if result.returncode and label=='Museum':
                failure=(out/'prepare-museum.log').read_text(encoding='utf-8',errors='replace')
                if 'shader compilation failed' in failure and 'out of memory' in failure:
                    record('running','Graphics memory ran out; retrying the static geometry export without GPU rendering.')
                    with (out/'prepare-museum-headless.log').open('w',encoding='utf-8') as log:
                        result=subprocess.run([sys.executable,*command],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                            env={**os.environ,'SPATIAL_EXPORT_HEADLESS':'1'},creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0,timeout=1500)
            if result.returncode:
                raise RuntimeError(f'{label} export failed. The existing view is retained; see {out/f"prepare-{label.lower()}.log"}')
        record('ready','Full Grid and Museum views are ready.')
    except Exception as error:
        record('failed',str(error))
        raise


if __name__=='__main__': main()
