"""Create the first bounded, parallel Museum-to-Void transfer batch.

Does not generate placements. Each worker authors its own trial folder; the
coordinator owns shared registration and native/export jobs.
"""
from pathlib import Path
import copy, hashlib, json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/void-transfer/2026-10-21-batch-01'
JOBS = {'shaders': 'Codex', 'cellularautomata': 'Claude', 'fractals': 'Antigravity Argon'}
# Optional explicit source selections let later batches continue a sequence in a
# new trial without overwriting an accepted or user-edited trial.
SOURCE_SELECTIONS = {}
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p, data): p.write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')

def resolve_definition(key, registry, seen=()):
    if key in seen:
        raise RuntimeError('Cyclic artifact delegate: '+key)
    definition = copy.deepcopy(registry.get(key, {}))
    if definition.get('delegate_to'):
        host = resolve_definition(definition['delegate_to'], registry, (*seen,key))
        config = dict(host.get('config', {}))
        config.update(definition.get('delegate_params', {}))
        host.update(definition)
        host['config'] = config
        definition = host
    return definition

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    registry = {}
    for p in sorted((ROOT/'commons/artifacts/registry').glob('*.json')):
        registry.update(json.loads(p.read_text(encoding='utf-8-sig')).get('artifacts', {}))
    playable = read('commons/void/trials/playable.json')
    catalog = read('commons/void/catalog.json')
    frame = read('commons/void/trials/noise/layout.json')
    jobs = []
    for seq, owner in JOBS.items():
        target = ROOT / 'commons/void/trials' / seq
        if target.exists() or seq in playable['trials']:
            raise RuntimeError('Refusing to overwrite existing work: '+seq)
        selection = SOURCE_SELECTIONS.get(seq, {})
        source_sequence = selection.get('sequence', seq)
        sequence_maps = read('commons/maps/sequences/'+source_sequence+'.json')['sequences'][source_sequence]['maps']
        maps = selection.get('maps', sequence_maps[:2])
        if not maps or len(set(maps)) != len(maps) or any(name not in sequence_maps for name in maps):
            raise RuntimeError('Expected distinct maps from the source sequence: '+seq)
        target.mkdir()
        sources = []
        hashes = {}
        for level, name in enumerate(maps, 1):
            data = read('commons/maps/'+name+'/map_data.json')
            for p in (ROOT/'commons/maps'/name).glob('*'):
                if p.is_file() and p.suffix in ['.md', '.json']:
                    hashes[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
            for z,row in enumerate(data['layers']['interactables']):
                for x, token in enumerate(row):
                    if str(token).strip() in ['', '0', '-1', 'None']: continue
                    key = str(token).split('#')[0].split(':')[0]
                    definition = resolve_definition(key, registry)
                    if not definition.get('scene'): raise RuntimeError('Unresolved: '+key)
                    if key not in catalog['artifacts']:
                        catalog['artifacts'][key] = dict(definition, museum_import=True)
                    sources.append({'id': f'f{level}_{key}_{x}_{z}', 'map':name, 'floor':level,
                                    'source_cell':[x,z], 'token':token, 'artifact':key,
                                    'scene':definition['scene'], 'status':'inventoried'})
        layout = copy.deepcopy(frame)
        layout['status'] = seq+' / transfer awaiting placement'
        layout['floor_roles'] = ['Canopy',*maps,'Catch floor']
        layout['levels'] = [-layout['storey_height'] * i for i in range(len(maps)+2)]
        layout['floor_styles'] = {str(i): 'abstract' for i in range(len(maps)+2)}
        layout['descent']['pad_shafts'] = {str(i): 'A' for i in range(1,len(maps)+2)}
        layout['route_note'] = 'Transfer first. Preserve original artifacts; curate after inspection.'
        write(target/'layout.json',layout)
        floors=[]
        for name in ['',*maps,'']:
            floors.append({'map':name,'title':name or 'Open structure','origin':False,
                           'walls':[],'artifacts':[],'props':[],'impact_cells':[],
                           'route':[],'supply_leads':False})
        write(target/'rooms.json',{'$schema':'../../rooms.schema.json','version':1,'floors':floors})
        (target/'trial.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n[node name="TransferTrial" instance=ExtResource("1")]\ntrial_id = "'+seq+'"\n',encoding='utf-8')
        write(target/'source-inventory.json',{'sequence':seq,'source_sequence':source_sequence,'maps':maps,'placements':sources,'preserved_sources':hashes})
        write(target/'transfer-status.json',{'owner':owner,'stage':'inventoried','maps':maps,'placed':0,'omitted':[],
                                             'native_tested':False,'headset_tested':False,'curated':False})
        playable['trials'][seq]={'title':seq.capitalize()+' / transfer study','label':seq.upper()+' / TRANSFER',
          'map':maps[0],'start_floor':1,'notice':'Museum transfer study. Placement and testing are being prepared; curation follows.',
          'rooms':f'res://commons/void/trials/{seq}/rooms.json','layout':f'res://commons/void/trials/{seq}/layout.json',
          'scene':f'res://commons/void/trials/{seq}/trial.tscn','models':f'/void-trials/{seq}/manifest.json',
          'retry_floors':{str(i): max(1,min(i,len(maps))) for i in range(len(maps)+2)},
          'spawn_points':{str(i): [0,.06,12] for i in range(1,len(maps)+1)}}
        jobs.append({'sequence':seq,'source_sequence':source_sequence,'owner':owner,'maps':maps,'source_placements':len(sources),
                     'folder':target.relative_to(ROOT).as_posix(),'stage':'assigned'})
    write(ROOT/'commons/void/catalog.json',catalog)
    write(ROOT/'commons/void/trials/playable.json',playable)
    write(OUT/'batch.json',{'date':'2026-10-21','phase':'transfer before curation','jobs':jobs})
    print(json.dumps(jobs,indent=2))

if __name__=='__main__':main()
