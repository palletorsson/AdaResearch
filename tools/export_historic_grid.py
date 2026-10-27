"""Export pre-Museum Grid scenes from a complete isolated Git snapshot on D:."""
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, subprocess, tarfile
from generated_storage import generated_root, public_directory
from void_native_slot import acquire_native_slot
from void_log_diagnostics import split_errors

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent/'ada_encyclopedia'
EXE = os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')


def snapshot(commit):
    base = generated_root()/'history'
    base.mkdir(parents=True,exist_ok=True)
    folder = base/commit
    marker = folder/'snapshot-receipt.json'
    if not marker.exists():
        folder.mkdir(exist_ok=True)
        archive = base/(commit+'.tar')
        subprocess.run(['git','-c','core.autocrlf=false','archive','--format=tar','-o',str(archive),commit],cwd=ROOT,check=True)
        with tarfile.open(archive) as source:
            for member in source.getmembers():
                target = (folder/member.name).resolve()
                if not target.is_relative_to(folder.resolve()) or member.issym() or member.islnk():
                    raise ValueError('Unsafe historical archive member: '+member.name)
            source.extractall(folder)
        archive.unlink()
        project = (folder/'project.godot').read_text(encoding='utf-8')
        project = re.sub(r'config/name="[^"]+"','config/name="Ada Historical Grid Comparison"',project,count=1)
        project = re.sub(r'enabled=PackedStringArray\([^\n]*\)', 'enabled=PackedStringArray()',project,count=1)
        (folder/'project.godot').write_text(project,encoding='utf-8')
        marker.write_text(json.dumps({'commit':commit,'overlay':['project.godot: isolated application name; editor plugins disabled','comparison_tools: export-only adapter'],'source':'git archive; no current map or artifact files copied into the historical project'},indent=2),encoding='utf-8')
    dependencies=folder/'external-dependencies.json'
    if not dependencies.exists():
        copied=[]
        for name in ['godot-xr-tools','map_tool_3d','element_editor','tutorial_text_editor']:
            # These directories were ignored, not present in the historical
            # tree. Record their installed versions as compatibility support.
            present=subprocess.run(['git','cat-file','-e',commit+':addons/'+name+'/plugin.cfg'],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0
            if present:continue
            source=ROOT/'addons'/name;target=folder/'addons'/name
            if not source.is_dir():continue
            hashes=[]
            for directory,dirs,files in os.walk(source,followlinks=False):
                dirs[:]=[d for d in dirs if d not in {'.git','.godot','node_modules'} and not (os.stat(Path(directory)/d,follow_symlinks=False).st_file_attributes & 0x400)]
                relative=Path(directory).relative_to(source);(target/relative).mkdir(parents=True,exist_ok=True)
                for file in files:
                    origin=Path(directory)/file
                    if origin.is_symlink():continue
                    shutil.copy2(origin,target/relative/file)
                    hashes.append((relative/file).as_posix()+':'+hashlib.sha256(origin.read_bytes()).hexdigest())
            copied.append({'directory':'addons/'+name,'files':len(hashes),'sha256':hashlib.sha256('\n'.join(sorted(hashes)).encode()).hexdigest(),'source':'Installed unversioned compatibility dependency; original dependency revision unavailable in Git'})
        shutil.copy2(ROOT/'default_bus_layout.tres',folder/'default_bus_layout.tres')
        copied.append({'file':'default_bus_layout.tres','source':'Installed unversioned audio bus layout'})
        project=(folder/'project.godot').read_text(encoding='utf-8')
        for uid,target in [('uid://bqgb8i74tm0t','res://addons/godot-xr-tools/user_settings/user_settings.gd'),('uid://by853dk86g1qw','res://addons/godot-xr-tools/rumble/rumble_manager.gd'),('uid://rwex60pqapc','res://default_bus_layout.tres')]:
            project=project.replace(uid,target)
        (folder/'project.godot').write_text(project,encoding='utf-8')
        dependencies.write_text(json.dumps(copied,indent=2)+'\n',encoding='utf-8')
    support=json.loads(dependencies.read_text(encoding='utf-8'))
    for name in ['rack_metal.tres','rack_panel.tres','rack_panel_dark.tres','rack_accent.tres']:
        relative='commons/interactables/materials/'+name
        if (folder/relative).exists():continue
        source=ROOT/relative
        if not source.is_file():continue
        (folder/relative).parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,folder/relative)
        support.append({'file':relative,'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'visual_substitute':True,'source':'Installed material substitute. This resource was not versioned at the historical baseline; exact historical appearance is unverified.'})
    dependencies.write_text(json.dumps(support,indent=2)+'\n',encoding='utf-8')
    return folder


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('map',nargs='?',default='Trans_Rotation')
    args=parser.parse_args()
    assert re.fullmatch('[A-Za-z0-9_]+',args.map)
    baseline=json.loads((ROOT/'commons/data/spatial_comparison_sources.json').read_text())['historic_grid']
    commit=baseline['commit'];assert re.fullmatch('[a-f0-9]{40}',commit)
    map_file=f'commons/maps/{args.map}/map_data.json'
    original=subprocess.check_output(['git','show',commit+':'+map_file],cwd=ROOT)
    protected=['commons/void/rooms.json',map_file,'commons/data/museum/em_plan.json','commons/data/museum/em_overrides.json']
    digest=lambda p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() if (ROOT/p).is_file() else None
    before={p:digest(p) for p in protected}
    slot=acquire_native_slot('Historical Grid / '+args.map)
    folder=snapshot(commit)
    restored=(folder/map_file).read_bytes()
    if restored!=original and restored.replace(b'\r\n',b'\n')==original.replace(b'\r\n',b'\n'):
        # Windows Git archive may apply checkout EOL conversion. Pin the map
        # to exact blob bytes for the receipt without touching the live map.
        (folder/map_file).write_bytes(original)
    assert (folder/map_file).read_bytes()==original,'Historical source differs from its Git blob'
    helper=folder/'comparison_tools';helper.mkdir(exist_ok=True)
    # Reuse the tested collector only; all authored Grid/artifact resources are old.
    base=(ROOT/'tools/probes/export_void_editor.gd').read_text(encoding='utf-8')
    collector=base[base.index('func snapshot('):]
    collector=re.sub(r'^func export_environment\(.*?(?=^func collect\()', '',collector,flags=re.S|re.M)
    base='extends SceneTree\nconst ModelStorage = preload("res://comparison_tools/generated_storage.gd")\nvar public_base := ""\nvar out := ""\nvar shader_count := 0\nvar failures: Array[String] = []\nvar manifest := {"notes":[]}\n'+collector
    (helper/'export_base.gd').write_text(base,encoding='utf-8')
    shutil.copy2(ROOT/'tools/generated_storage.gd',helper/'generated_storage.gd')
    shutil.copy2(ROOT/'tools/probes/export_historic_grid.gd',helper/'export.gd')
    out=ROOT/'ada_run/spatial-comparison'/args.map/'historic';out.mkdir(parents=True,exist_ok=True)
    if not (folder/'import-receipt.json').exists():
        print('Importing isolated historical resources',flush=True)
        ignored=[]
        for name in ['doc','docs','tools','ada_run']:
            location=folder/name
            if location.is_dir() and not (location/'.gdignore').exists():
                (location/'.gdignore').write_text('')
                ignored.append(name)
        runtime_project=(folder/'project.godot').read_text(encoding='utf-8')
        # Import resources without starting the old game's autoloads in the
        # editor. Restore their exact runtime configuration before exporting.
        import_project=re.sub(r'\[autoload\]\n.*?(?=\n\[)', '[autoload]\n',runtime_project,flags=re.S)
        (folder/'project.godot').write_text(import_project,encoding='utf-8')
        try:
            with (out/'import.log').open('w',encoding='utf-8') as log:
                imported=subprocess.run([EXE,'--headless','--path',str(folder),'--editor','--import','--quit','--xr-mode','off'],stdout=log,stderr=subprocess.STDOUT,timeout=600,creationflags=subprocess.CREATE_NO_WINDOW)
        finally:(folder/'project.godot').write_text(runtime_project,encoding='utf-8')
        assert imported.returncode==0,'Historical resource import failed; see '+str(out/'import.log')
        (folder/'import-receipt.json').write_text(json.dumps({'commit':commit,'engine':'Godot 4.6','status':'imported','export_scan_only_ignores':ignored,'autoloads_paused_only_during_import':True}))
    # The snapshot preparation may take minutes while other editors remain
    # active. Check preservation across the actual native capture separately.
    before={p:digest(p) for p in protected}
    models=public_directory('spatial-comparison')/args.map/'historic'/commit[:12];models.mkdir(parents=True,exist_ok=True)
    base_url='/spatial-comparison/'+args.map+'/historic/'+commit[:12]
    with (out/'export.log').open('w',encoding='utf-8') as log:
        result=subprocess.run([EXE,'--no-window','--path',str(folder),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://comparison_tools/export.gd','--','--map='+args.map,'--out='+str(models),'--public-base='+base_url],stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
    assert all(digest(p)==v for p,v in before.items()),'Current authoring source changed during historical export'
    log=(out/'export.log').read_text(encoding='utf-8',errors='replace')
    errors,shutdown=split_errors(log,'HISTORIC_GRID_EXPORT ',allow_shutdown=result.returncode==0)
    assert result.returncode==0 and not errors,(result.returncode,errors,log[-4000:])
    manifest=json.loads((models/'manifest.json').read_text())
    assert not manifest['failures']
    files={map_file,'commons/grid/GridSystem.gd','commons/grid/GridInteractablesComponent.gd','commons/grid/GridStructureComponent.gd'}
    for item in manifest['objects']:
        source_script=item.get('sourceScript','')
        if source_script.startswith('res://'):
            text=(folder/source_script[6:]).read_text(encoding='utf-8-sig')
            intent={};active=False
            for line in text.splitlines():
                if line.strip()=='# @identity':active=True;continue
                if not active:continue
                if not line.startswith('#'):break
                match=re.match(r'#\s*([a-z_]+):\s*(.*)',line)
                if match:intent[match[1]]=match[2]
            if intent:item['intent']=intent
            if not item['model'].get('url') and not item['model'].get('labels') and 'GridMultiMesh' in text:
                item['geometryRole']='shared-grid-controller'
        for field in ['sourceScene','sourceScript']:
            if item.get(field,'').startswith('res://'):files.add(item[field][6:])
    verified={}
    for file in sorted(files):
        try:blob=subprocess.check_output(['git','show',commit+':'+file],cwd=ROOT,stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            dependencies=json.loads((folder/'external-dependencies.json').read_text())
            assert any(file.startswith(d.get('directory','_missing')+'/') for d in dependencies),'Unrecorded non-historical dependency: '+file
            verified[file]={'compatibility_dependency':True,'snapshot_sha256':hashlib.sha256((folder/file).read_bytes()).hexdigest(),'not_versioned_at_baseline':True}
            continue
        actual=(folder/file).read_bytes()
        assert actual.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),'Authored historical source changed: '+file
        verified[file]={'git_blob_sha256':hashlib.sha256(blob).hexdigest(),'snapshot_sha256':hashlib.sha256(actual).hexdigest(),'content_equal_ignoring_checkout_line_endings':True}
    manifest.update(history=baseline,source_sha256=hashlib.sha256(original).hexdigest(),source_map=json.loads(original),source_snapshot=str(folder),verified_archive_sources=verified,runtime_overlay=json.loads((folder/'snapshot-receipt.json').read_text()),compatibility_dependencies=json.loads((folder/'external-dependencies.json').read_text()),import_support=json.loads((folder/'import-receipt.json').read_text()),shutdown_diagnostics=shutdown)
    (models/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    public=WEB/'public/spatial-comparison'/args.map/'historic'/commit[:12];public.mkdir(parents=True,exist_ok=True)
    for f in models.iterdir():
        if f.is_file() and f.name!='manifest.json':shutil.copy2(f,public/f.name)
    shutil.copy2(models/'manifest.json',public/'manifest.json')
    receipt={'passed':True,'map':args.map,'commit':commit,'objects':len(manifest['objects']),'dimensions':[manifest['width'],manifest['depth']],'source_blob_sha256':manifest['source_sha256'],'verified_archive_sources':verified,'current_source_files_unchanged':before,'scope':baseline['scope']}
    (out/'checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt,indent=2))


if __name__=='__main__':main()
