"""Verify this Quest build and update the existing app without clearing saves."""
import argparse,hashlib,json,re,subprocess,sys,time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out',type=Path,default=ROOT/'ada_run/quest-menu-2026-10-28/apk')
parser.add_argument('--no-launch',action='store_true',help='Install the update without opening the game')
args=parser.parse_args()
OUT=args.out.resolve()
SERIAL='2G0YC5ZG4M0569'
SDK=Path.home()/'AppData/Local/Android/Sdk'
ADB=SDK/'platform-tools/adb.exe'
AAPT=SDK/'build-tools/35.0.1/aapt.exe'
sys.stdout.reconfigure(encoding='utf-8')

def run(args,timeout=60):
 p=subprocess.run([str(x) for x in args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=timeout)
 if p.returncode:raise RuntimeError(p.stdout+'\n'+p.stderr)
 return p.stdout+p.stderr

def adb(*args,timeout=60):return run([ADB,'-s',SERIAL,*args],timeout)

def version(package):
 text=adb('shell','dumpsys','package',package)
 code=re.search(r'versionCode=(\d+)',text)
 name=re.search(r'versionName=(\S+)',text)
 return {'code':int(code.group(1)) if code else None,'name':name.group(1) if name else None}

def main():
 build=json.loads((OUT/'build.json').read_text(encoding='utf-8'))
 assert build.get('exists') and build.get('export_completed'), 'Export did not finish producing an APK'
 # A completed file can survive the Windows renderer's teardown crash. This
 # exception requires independent CRC, signature, manifest and content checks.
 assert build.get('exit_code') in (0,3221225477),build.get('exit_code')
 assert build.get('zip_integrity_passed'), 'APK integrity has not been checked'
 assert build.get('runtime_payload_passed'),build.get('missing_runtime_assets')
 assert all(build['new_game_assets'].values()),build['new_game_assets']
 assert not build['authoring_leaks'],build['authoring_leaks'][:10]
 assert build['packaged_floor_maps']==build['expected_floor_maps'] and build['floor_20']==build['expected_floor_maps'][20],'Packaged floor list differs from reviewed source'
 assert build['packaged_rooms_sha256']==build['source_files']['commons/void/rooms.json'],'Packaged room placements differ from reviewed source'
 apk=Path(build['apk'])
 digest=hashlib.sha256()
 with apk.open('rb') as binary:
  for block in iter(lambda:binary.read(4*1024*1024),b''):digest.update(block)
 assert digest.hexdigest()==build['sha256'],'APK has changed since export'
 badging=run([AAPT,'dump','badging',apk])
 (OUT/'manifest-badging.txt').write_text(badging,encoding='utf-8')
 package=re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",badging,re.M)
 assert package and package.group(1)==build['package'] and int(package.group(2))==build['version_code'],badging[:500]
 signature=run(['java','-jar',SDK/'build-tools/35.0.1/lib/apksigner.jar','verify','--print-certs',apk])
 (OUT/'signature.txt').write_text(signature,encoding='utf-8')
 activity=re.search(r"^launchable-activity: name='([^']+)'",badging,re.M)
 if activity:activity_name=activity.group(1)
 else:
  manifest=run([AAPT,'dump','xmltree',apk,'AndroidManifest.xml'])
  (OUT/'manifest-tree.txt').write_text(manifest,encoding='utf-8')
  assert 'E: activity-alias' in manifest and 'com.godot.game.GodotAppLauncher' in manifest,'No verified launcher alias'
  activity_name='com.godot.game.GodotAppLauncher'
 state=adb('get-state')
 assert 'device' in [line.strip() for line in state.splitlines()],'Quest unavailable: '+state
 before=version(package.group(1))
 assert before['code'] is None or before['code']<=build['version_code'],'Refusing a downgrade'
 receipt={'serial':SERIAL,'package':package.group(1),'apk_sha256':build['sha256'],'before':before,'started':time.time()}
 install=adb('install','-r',apk,timeout=300)
 (OUT/'install.log').write_text(install,encoding='utf-8')
 assert 'Success' in install,install
 receipt['installed']=True
 receipt['after']=version(package.group(1))
 assert receipt['after']['code']==build['version_code'],receipt
 # Use the declared immersive entrypoint for this Quest game.
 if not args.no_launch:
  try:
   receipt['launch']=adb('shell','am','start','-W','-a','android.intent.action.MAIN',
                         '-c','org.khronos.openxr.intent.category.IMMERSIVE_HMD',
                         '-n',package.group(1)+'/'+activity_name)
  except (RuntimeError,subprocess.TimeoutExpired) as error:
   receipt['launch_error']=str(error)
 receipt['finished']=time.time()
 (OUT/'deployment.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(receipt,indent=2),flush=True)

if __name__=='__main__':main()
