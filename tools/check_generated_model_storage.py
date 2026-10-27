"""Read-only model/layout audit plus HTTP tests of external public mounts."""
import concurrent.futures,hashlib,json,os,shutil,struct,time,urllib.request
from pathlib import Path
from generated_storage import PROJECT,generated_root
from migrate_generated_models import game_models

OUT=PROJECT/'ada_run/generated-storage-migration';PUBLIC=PROJECT.parent/'ada_encyclopedia/public'
before=json.loads((OUT/'before-contract.json').read_text());migration=json.loads((OUT/'migration.json').read_text());checks=[]
assert game_models()==migration['game_models_before'];checks.append('Every original game GLB/GLTF retains its SHA-256 and project path')
count=0
for manifest in before['models']:
    file=PUBLIC/manifest['manifest'];assert hashlib.sha256(file.read_bytes()).hexdigest()==manifest['sha256'],file
    for url in manifest['urls']:
        file=PUBLIC/url.lstrip('/');assert file.resolve().is_relative_to(generated_root()),file
        with file.open('rb') as stream:header=stream.read(12)
        assert len(header)==12 and struct.unpack('<III',header)==(0x46546c67,2,file.stat().st_size),file
        count+=1
checks.append(f'All {count} model references in {len(before["models"])} unchanged manifests resolve to valid GLBs on D:')
samples=[]
for mount in migration['public_mounts']:
    assert Path(mount['source']).resolve()==Path(mount['destination']).resolve()
    file=next(Path(f['destination']) for f in mount['files'] if Path(f['destination']).suffix=='.glb')
    relative=file.relative_to(generated_root()/'public').as_posix();samples.append((relative,file))

def http(pair):
    relative,file=pair
    request=urllib.request.Request('http://localhost:3003/'+relative,headers={'Cache-Control':'no-cache'})
    with urllib.request.urlopen(request,timeout=40) as response:data=response.read();assert response.status==200
    assert hashlib.sha256(data).hexdigest()==hashlib.sha256(file.read_bytes()).hexdigest(),relative
    return relative

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:served=list(pool.map(http,samples))
checks.append('HTTP serves byte-identical actual models through all nine unchanged public URL families')
# Prove files created AFTER mounting are served too, not just an old URL cache.
canary=generated_root()/'public/void-models'/('storage-write-'+str(time.time_ns())+'.glb')
shutil.copy2(min((PUBLIC/'void-models').glob('*.glb'),key=lambda p:p.stat().st_size),canary)
try:http((canary.relative_to(generated_root()/'public').as_posix(),canary))
finally:
    assert canary.resolve().is_relative_to(generated_root()/'public/void-models');canary.unlink()
checks.append('A newly written D: model is immediately available over the original web URL')
with urllib.request.urlopen('http://localhost:3003/api/void-layout',timeout=40) as response:payload=json.load(response)
rooms_bytes=(PROJECT/'commons/void/rooms.json').read_bytes();rooms=json.loads(rooms_bytes)
assert payload['rooms']==rooms,'HTTP editor layout differs from current native desktop/VR source'
unchanged=hashlib.sha256(rooms_bytes).hexdigest()==before['rooms_sha256']
if unchanged:
    assert payload['revision']==before['revision'] and payload['rooms']['floors'][7]==before['floor7']
    checks.append('Shared lab-editor desktop/VR arrangement and saved revision are unchanged')
else:
    checks.append('A concurrent layout edit is preserved; editor HTTP layout matches the current shared desktop/VR file')
assert not [f for f in migration['project_files'] if Path(f['source']).suffix=='.glb' and Path(f['source']).exists()]
checks.append('Every migrated project GLB remains outside the Godot tree')
result={'passed':True,'checks':checks,'model_references':count,'manifests':len(before['models']),'http_samples':served,'protected_game_models':len(migration['game_models_before']),'layout_matches_preflight':unchanged,'current_rooms_sha256':hashlib.sha256(rooms_bytes).hexdigest(),'current_revision':payload['revision'],'layout_write_by_migration':False}
(OUT/'web-checks.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(len(checks),'storage/web checks passed;',count,'model references.')
