"""Rebuild missing tower previews into local generated storage, without editing rooms.

Resumable: publish completed batches atomically and retain a recovery receipt.
The public junction is switched separately, after priority-floor verification.
"""
import hashlib, json, os, shutil, subprocess, sys, time
from pathlib import Path
from generated_storage import PROJECT, generated_root
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_model_publication import editor_directory, publish_models

OUT = PROJECT/'ada_run/editor-storage-recovery'
PUBLIC = generated_root()/'public/void-models'
RECEIPT = OUT/'recovery.json'
BACKUP = PROJECT/'ada_run/line-association-miniature-models/before-models.json'

def write(path, data):
    temp=path.with_suffix('.next.json')
    temp.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    os.replace(temp,path)

def urls(value):
    if isinstance(value,dict):
        for v in value.values(): yield from urls(v)
    elif isinstance(value,list):
        for v in value: yield from urls(v)
    elif isinstance(value,str) and value.startswith('/void-models/'):
        yield value

def valid_file(url):
    file=PUBLIC/Path(url).name
    if not file.is_file(): return False
    if file.suffix=='.glb':
        with file.open('rb') as stream:
            header=stream.read(12)
        return len(header)==12 and header[:4]==b'glTF' and int.from_bytes(header[8:12],'little')==file.stat().st_size
    return file.stat().st_size>0

def release_published_copies(staged):
    """Remove only temporary files with an identical, valid published copy."""
    staging_root=(generated_root()/'recovery').resolve()
    if not staged.resolve().is_relative_to(staging_root):
        raise ValueError('Recovery staging must stay inside the recovery directory')
    if not staged.is_dir(): return
    for source in staged.iterdir():
        if source.name=='manifest.json' or source.is_symlink() or not source.is_file(): continue
        target=PUBLIC/source.name
        digest=hashlib.sha256(source.read_bytes()).hexdigest()
        versioned=PUBLIC/(source.stem+'-'+digest[:20]+source.suffix)
        if versioned.is_file(): target=versioned
        if not source.resolve().is_relative_to(staging_root): continue
        if not valid_file('/void-models/'+target.name): continue
        if source.stat().st_size!=target.stat().st_size: continue
        if hashlib.sha256(source.read_bytes()).digest()==hashlib.sha256(target.read_bytes()).digest():
            source.unlink()

def status(state, receipt, **extra):
    write(OUT/'status.json',dict(state=state,pid=os.getpid(),updated=time.time(),
        completed=len(receipt['completed']),failed=receipt['failed'],**extra))

def publish(batch, staged, data):
    return publish_models(staged,data,PUBLIC)

def main():
    editor_directory()
    OUT.mkdir(parents=True,exist_ok=True); PUBLIC.mkdir(parents=True,exist_ok=True)
    if not (PUBLIC/'manifest.json').exists(): shutil.copy2(BACKUP,PUBLIC/'manifest.json')
    receipt=json.loads(RECEIPT.read_text()) if RECEIPT.exists() else {'root':str(PUBLIC),'completed':[],'failed':{},'batches':[]}
    rooms=json.loads((PROJECT/'commons/void/rooms.json').read_text(encoding='utf8'))
    for batch in receipt['batches']:
        release_published_copies(generated_root()/'recovery'/'-'.join(map(str,batch['floors'])))
    requested=[int(x) for x in sys.argv[1].split(',')] if len(sys.argv)>1 else list(range(len(rooms['floors'])))
    priority_file=OUT/'priority.json'
    preferred=json.loads(priority_file.read_text()) if priority_file.exists() else [155,154,3,88,38,1,31,30]
    priority=[n for n in dict.fromkeys(preferred) if n in requested]
    remaining=[n for n in priority+[n for n in requested if n not in priority] if n not in receipt['completed']]
    batches=[[n] for n in priority if n in remaining]
    tail=[n for n in remaining if n not in priority]
    batches += [tail[i:i+6] for i in range(0,len(tail),6)]
    os.environ['ADA_GENERATED_ROOT']=str(generated_root())
    stage=stage_runtime()
    while batches:
        # A newly requested floor can jump ahead without discarding completed work.
        if priority_file.exists():
            urgent=json.loads(priority_file.read_text())
            available={n for group in batches for n in group}
            next_floor=next((n for n in urgent if n in available),None)
            if next_floor is not None:
                batches=[[n for n in group if n!=next_floor] for group in batches]
                batches=[[next_floor]]+[group for group in batches if group]
        batch=batches.pop(0)
        if shutil.disk_usage(PUBLIC).free<600*1024**2: raise RuntimeError('Stopped recovery before disk free space falls below 600 MB')
        tag='-'.join(map(str,batch)); staged=generated_root()/'recovery'/tag; staged.mkdir(parents=True,exist_ok=True)
        (staged/'manifest.json').unlink(missing_ok=True)
        log=OUT/(tag+'.log')
        first=not receipt['completed']
        args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--script','res://tools/probes/export_void_editor.gd','--','--no-bridges','--floors='+','.join(map(str,batch)),'--out='+staged.as_posix()]
        args+=['--workbench'] if first else ['--skip-palette']
        print('Rebuilding floors '+tag,flush=True)
        status('waiting_for_native_slot',receipt,floors=batch,total=len(requested))
        with acquire_native_slot('recover tower floors '+tag,timeout=1200):
            status('exporting',receipt,floors=batch,total=len(requested),log=str(log))
            with log.open('w',encoding='utf8') as stream:
                try:
                    result=subprocess.run(args,stdout=stream,stderr=subprocess.STDOUT,timeout=420,creationflags=subprocess.CREATE_NO_WINDOW)
                    code=result.returncode
                except subprocess.TimeoutExpired: code=-1
        file=staged/'manifest.json'
        data=json.loads(file.read_text(encoding='utf8')) if file.exists() else {}
        if code!=0 or data.get('failures') or not data.get('floors'):
            if len(batch)>1:
                batches[0:0]=[[n] for n in batch]
            else:
                receipt['failed'][str(batch[0])]={'exit':code,'log':str(log),'failures':data.get('failures',[])}
                print('FAILED floor '+tag+'; see '+str(log),flush=True)
            write(RECEIPT,receipt); continue
        published=publish(batch,staged,data)
        missing=[u for n in batch for u in urls(published['floors'][str(n)]) if not valid_file(u)]
        if missing: raise RuntimeError('Published preview references missing/invalid files: '+str(missing[:10]))
        receipt['completed']+=batch
        for n in batch: receipt['failed'].pop(str(n),None)
        receipt['batches'].append({'floors':batch,'files':len(list(staged.glob('*.glb'))),'finished':time.time()})
        write(RECEIPT,receipt)
        release_published_copies(staged)
        status('published',receipt,floors=batch,total=len(requested))
        print('RESTORED '+tag+' / '+str(len(receipt['completed']))+' floors complete',flush=True)
    manifest=json.loads((PUBLIC/'manifest.json').read_text(encoding='utf8'))
    receipt['missing_urls']=sorted(set(u for u in urls(manifest) if not valid_file(u)))
    write(RECEIPT,receipt)
    status('complete' if not receipt['failed'] and not receipt['missing_urls'] else 'needs_attention',receipt,total=len(requested),missing_urls=receipt['missing_urls'])
    print('Recovery complete; failed floors: '+str(receipt['failed'])+'; missing URLs: '+str(len(receipt['missing_urls'])),flush=True)
    return bool(receipt['failed'] or receipt['missing_urls'])

if __name__=='__main__':
    try:
        sys.exit(main())
    except Exception as error:
        if RECEIPT.exists():
            status('interrupted',json.loads(RECEIPT.read_text()),error=str(error))
        raise
