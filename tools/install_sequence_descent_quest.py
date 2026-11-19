"""Install the verified descent build, retain saves, and launch Color once."""
import hashlib,json,re,subprocess,sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/sequence-descents/quest'
ADB=Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'
SERIAL='2G0YC5ZG4M0569'
PKG='com.example.adaresearchzeroone'
sys.stdout.reconfigure(encoding='utf8')

def adb(*args):
    result=subprocess.run([str(ADB),'-s',SERIAL,*args],capture_output=True,timeout=90)
    if result.returncode:raise RuntimeError(result.stderr.decode('utf8',errors='replace'))
    return result.stdout

build=json.loads((OUT/'build.json').read_text(encoding='utf8'))
checks=json.loads((OUT/'packaged-color.json').read_text(encoding='utf8'))
assert checks['passed'] and checks['apk_sha256']==build['sha256'] and checks['floor']==28
adb('shell','am','force-stop',PKG)
backup=OUT/'save-backup';backup.mkdir(exist_ok=True)
saved={}
for name in ['map_progress.json','capability_progression.json','ecosystem_progression.json','void_scaffold_work.json','void_space_build_20.json','void_space_build_21.json','void_space_build_7.json','void_space_items_6.json']:
    data=adb('exec-out','run-as',PKG,'cat','files/'+name)
    (backup/name).write_bytes(data)
    saved[name]=hashlib.sha256(data).hexdigest()
(OUT/'save-hashes-before.json').write_text(json.dumps(saved,indent=2)+'\n')
subprocess.run([sys.executable,str(ROOT/'tools/deploy_quest_game.py'),'--out',str(OUT),'--no-launch'],check=True,cwd=ROOT)
for name,digest in saved.items():
    assert hashlib.sha256(adb('exec-out','run-as',PKG,'cat','files/'+name)).hexdigest()==digest,name
apk_path=adb('shell','pm','path',PKG).decode().strip().removeprefix('package:')
assert re.fullmatch(r'/data/app/[^\s]+/base\.apk',apk_path),apk_path
device_hash=adb('shell','sha256sum',apk_path).decode().split()[0]
assert device_hash==build['sha256']
request=OUT/'void_launch.json'
request.write_text('{"map":"Color_Context_Placed"}\n',encoding='utf8')
adb('push',str(request),'/data/local/tmp/ada-color-launch.json')
adb('shell','run-as',PKG,'cp','/data/local/tmp/ada-color-launch.json','files/void_launch.json')
for port in (8771,8772):adb('reverse','tcp:'+str(port),'tcp:'+str(port))
launch=adb('shell','am','start','-W','-a','android.intent.action.MAIN','-c','org.khronos.openxr.intent.category.IMMERSIVE_HMD','-n',PKG+'/com.godot.game.GodotAppLauncher').decode()
receipt={'installed_hash_verified':True,'sha256':device_hash,'version':build['version_code'],'saves_unchanged':list(saved),'requested_map':'Color_Context_Placed','requested_floor':28,'launch':launch}
(OUT/'quest-launch.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print(json.dumps(receipt,indent=2))
