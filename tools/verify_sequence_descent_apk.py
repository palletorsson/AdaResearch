"""Check the exported connections and exercise Color launch using APK bytecode."""
import json, os, re, subprocess, sys, zipfile, zlib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from void_native_slot import acquire_native_slot

ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'ada_run/sequence-descents/quest'
build=json.loads((out/'build.json').read_text(encoding='utf8'))
assert build.get('export_completed') and build['zip_integrity_passed'] and build['runtime_payload_passed']
stage=Path(build['stage'])
runtime=out/'packaged-runtime'
runtime.mkdir(exist_ok=True)
assert runtime.resolve()==runtime, 'Extraction directory must not redirect elsewhere'
with zipfile.ZipFile(build['apk']) as z:
    names=set(z.namelist())
    baseline=ROOT/'ada_run/quest-point-zero-journal-2026-11-19/apk/build.json'
    prior=json.loads(baseline.read_text(encoding='utf8'))
    with zipfile.ZipFile(prior['apk']) as old:
        retained={n for n in old.namelist() if n.startswith('assets/') and not n.startswith('assets/.godot/') and not n.endswith('/')}
    missing=sorted(retained-names)
    assert not missing, ('Previously shipped resources missing',missing[:30])
    rooms=json.loads(z.read('assets/commons/void/rooms.json'))
    assert rooms['floors'][28]['map']=='Color_Context_Placed'
    routes=[a for f in rooms['floors'] for a in f['artifacts'] if a['artifact']=='sequence_descent']
    assert len(routes)==23
    for relative in ['commons/void/sequence_descent.gd','commons/void/sequence_descent.tscn','commons/artifacts/mesh_merge.gd','commons/scenes/main_menu/MainMenu3D.gd']:
        remap=z.read('assets/'+relative+'.remap').decode('utf8')
        target=re.search(r'path="res://([^"]+)"',remap)
        assert target and 'assets/'+target[1] in names,relative
    assert b'_open_requested_void_floor' in (stage/'commons/scenes/main_menu/MainMenu3D.gd').read_bytes()
    def extract(item):
        relative=Path(item.filename.removeprefix('assets/'))
        assert not relative.is_absolute() and '..' not in relative.parts
        target=runtime/relative
        if os.name=='nt': target=Path('\\\\?\\'+str(target.absolute()))
        target.parent.mkdir(parents=True,exist_ok=True)
        if target.is_file() and target.stat().st_size==item.file_size and zlib.crc32(target.read_bytes())==item.CRC:return
        target.write_bytes(z.read(item))
    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(extract,[item for item in z.infolist() if item.filename.startswith('assets/') and not item.is_dir()]))
print('APK extracted; starting packaged Color launch',flush=True)
(runtime/'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AdaQuestColorVerification"\n',encoding='utf8')
probe=ROOT/'tools/probes/quest_color_launch.gd'
with acquire_native_slot('Packaged Quest Color launch',timeout=60):
    with (out/'packaged-color.log').open('w',encoding='utf8') as log:
        result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(runtime),'--xr-mode','off','--script',str(probe),'--','--desktop','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW)
log=(out/'packaged-color.log').read_text(encoding='utf8',errors='replace')
match=re.search(r'QUEST_COLOR_LAUNCH (\{[^\n]+\})',log)
assert result.returncode==0 and match,log[-4000:]
report=json.loads(match[1]);assert report['passed']
report.update(apk_sha256=build['sha256'],packaged_connections=len(routes),retained_resources=len(retained),baseline_sha256=prior['sha256'])
(out/'packaged-color.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report))
