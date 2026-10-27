"""Checksum-verified local migration. Game asset folders are never moved.

Run after reviewing ada_run/generated-storage-migration/inventory.json.
Public originals remain as reversible cutover backups until --finish verifies
the D: copies again. No recursive delete and no traversal of junctions.
"""
import hashlib,json,os,re,shutil,subprocess,sys,time
from pathlib import Path
from generated_storage import PROJECT,generated_root
from void_native_slot import acquire_native_slot

HERE=PROJECT/'ada_run/generated-storage-migration';PLAN=HERE/'inventory.json';RECEIPT=HERE/'migration.json'
sys.stdout.reconfigure(encoding='utf-8')

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for data in iter(lambda:stream.read(1024*1024),b''):h.update(data)
    return h.hexdigest()

def bounded(path,root):
    result=path.resolve();base=root.resolve()
    if result==base or not result.is_relative_to(base):raise ValueError(f'Path leaves named directory: {path}')
    return result

def walk(root):
    stack=[root];files=[];directories=[]
    while stack:
        folder=stack.pop();directories.append(folder)
        for item in os.scandir(folder):
            st=item.stat(follow_symlinks=False)
            if getattr(st,'st_file_attributes',0)&1024:raise ValueError('Unexpected reparse point: '+item.path)
            if item.is_dir(follow_symlinks=False):stack.append(Path(item.path))
            else:files.append(Path(item.path))
    return sorted(files),sorted(directories,key=lambda p:len(p.parts),reverse=True)

def copy_verified(source,destination,source_root):
    bounded(source,source_root);bounded(destination,generated_root())
    sha=digest(source);destination.parent.mkdir(parents=True,exist_ok=True)
    if destination.exists():
        if digest(destination)!=sha:raise ValueError('Destination differs; preserving both: '+str(destination))
    else:
        temporary=destination.with_name(destination.name+'.moving')
        shutil.copy2(source,temporary)
        if digest(temporary)!=sha:raise ValueError('Copy failed verification: '+str(source))
        temporary.replace(destination)
    return {'source':str(source),'destination':str(destination),'sha256':sha,'bytes':source.stat().st_size}

def remove_verified(record,source_root):
    source=Path(record['source']);target=Path(record['destination'])
    bounded(source,source_root);bounded(target,generated_root())
    if source.exists():
        if digest(source)!=record['sha256'] or digest(target)!=record['sha256']:raise ValueError('Changed during migration: '+str(source))
        source.unlink()

def game_models():
    result={}
    for name in ['addons','algorithms','assets','commons','core']:
        base=PROJECT/name
        if not base.exists():continue
        stack=[base]
        while stack:
            folder=stack.pop()
            for e in os.scandir(folder):
                if getattr(e.stat(follow_symlinks=False),'st_file_attributes',0)&1024:continue
                if e.is_dir(follow_symlinks=False):stack.append(Path(e.path))
                elif e.name.lower().endswith(('.glb','.gltf')):result[Path(e.path).relative_to(PROJECT).as_posix()]=digest(Path(e.path))
    return result

def save(receipt):
    temporary=RECEIPT.with_suffix('.tmp');temporary.write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');temporary.replace(RECEIPT)

def main():
    slot=acquire_native_slot('Generated model storage migration')
    plan=json.loads(PLAN.read_text());assert Path(plan['project_root']).resolve()==PROJECT
    assert Path(plan['destination']).resolve()==generated_root()
    public=Path(plan['public_root']).resolve();stamp=str(time.time_ns())
    if '--finish' in sys.argv:
        receipt=json.loads(RECEIPT.read_text());assert receipt['game_models_before']==game_models()
        for mount in receipt['public_mounts']:
            source=Path(mount['source']);backup=Path(mount['backup']);destination=Path(mount['destination'])
            assert source.resolve()==destination.resolve(),source
            for record in mount['files']:remove_verified(record,backup)
            _,folders=walk(backup)
            for folder in folders:
                # Paths were checked before every operation; only empty dirs go.
                if folder!=backup:bounded(folder,backup)
                else:bounded(folder,public)
                folder.rmdir()
        receipt['phase']='complete';receipt['game_models_after']=game_models();save(receipt)
        print('Verified external copies; removed only verified old public backups.');return
    if RECEIPT.exists():raise RuntimeError('Migration receipt exists; inspect it rather than repeating cutover')
    receipt={'phase':'copying','storage_root':str(generated_root()),'project_files':[],'cache_files':[],'public_mounts':[],'game_models_before':game_models()}
    save(receipt)
    cache=set()
    for item in plan['project']:
        relative=Path(item['relative']);source=PROJECT/relative
        assert relative.suffix.lower()=='.glb' and relative.parts[0] in ['ada_run','doc']
        if relative.parts[0]=='doc':assert relative.as_posix().startswith('doc/book/iterations/')
        destination=generated_root()/'project'/relative
        record=copy_verified(source,destination,PROJECT);remove_verified(record,PROJECT);receipt['project_files'].append(record)
        sidecar=source.with_suffix(source.suffix+'.import')
        if sidecar.exists():
            text=sidecar.read_text(encoding='utf-8',errors='replace')
            for path in re.findall(r'"res://(\.godot/imported/[^"\r\n]+)"',text):
                cached=PROJECT/path
                if cached.is_file():cache.add(cached)
                md5=cached.with_suffix('.md5')
                if md5.is_file():cache.add(md5)
            meta=copy_verified(sidecar,destination.with_suffix(destination.suffix+'.import'),PROJECT);remove_verified(meta,PROJECT);receipt['project_files'].append(meta)
        if source.parent.name=='native-models':(source.parent/'.gdignore').touch()
        if len(receipt['project_files'])%50==0:save(receipt)
    for source in sorted(cache):
        bounded(source,PROJECT/'.godot/imported')
        record=copy_verified(source,generated_root()/'import-cache'/source.name,PROJECT/'.godot/imported')
        remove_verified(record,PROJECT/'.godot/imported');receipt['cache_files'].append(record)
    save(receipt);print('Moved',len(plan['project']),'project GLBs and',len(cache),'specific generated import-cache files.',flush=True)
    for mount in plan['public_roots']:
        source=Path(mount['source']);destination=Path(mount['destination'])
        bounded(source,public);bounded(destination,generated_root())
        files,folders=walk(source);records=[]
        for file in files:records.append(copy_verified(file,destination/file.relative_to(source),source))
        # Verified same-volume rename; originals retained until HTTP/native checks.
        backup=source.with_name(source.name+'.migration-old-'+stamp)
        bounded(backup,public);assert not backup.exists()
        source.rename(backup)
        try:subprocess.run(['cmd','/c','mklink','/J',str(source),str(destination)],check=True,capture_output=True)
        except BaseException:
            backup.rename(source);raise
        for record in records:record['source']=str(backup/Path(record['source']).relative_to(source))
        receipt['public_mounts'].append({'source':str(source),'destination':str(destination),'backup':str(backup),'files':records})
        save(receipt);print('Mounted',source.relative_to(public),'on D:',len(records),'verified files',flush=True)
    assert game_models()==receipt['game_models_before']
    receipt['phase']='cutover_verified_copies_waiting_checks';save(receipt)
    print('Cutover complete. Originals retained for --finish after HTTP/native verification.')

if __name__=='__main__':main()
