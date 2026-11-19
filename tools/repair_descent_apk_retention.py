"""Restore only omitted, unchanged cached scenes; preserve the original APK receipt."""
import hashlib,json,re,subprocess,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/sequence-descents/quest'
build=json.loads((OUT/'build.json').read_text(encoding='utf8'))
assert not build.get('post_export_repair'), 'Already repaired'
prior=json.loads((ROOT/'ada_run/quest-point-zero-journal-2026-11-19/apk/build.json').read_text())
sdk=Path.home()/'AppData/Local/Android/Sdk/build-tools/35.0.1'
def run(args):
    p=subprocess.run([str(a) for a in args],capture_output=True,text=True,timeout=180)
    if p.returncode:raise RuntimeError(p.stdout+p.stderr)
    return p.stdout
def cert(apk):
    output=run(['java','-jar',sdk/'lib/apksigner.jar','verify','--print-certs',apk])
    return re.search(r'certificate SHA-256 digest: ([a-f0-9]+)',output)[1]
unsigned=OUT/'retained-unsigned.apk';aligned=OUT/'retained-aligned.apk'
target=OUT/'ada-research-2026.11.19-sequence-descents-v20-retained.apk'
with zipfile.ZipFile(build['apk']) as current,zipfile.ZipFile(prior['apk']) as old:
    names=set(current.namelist())
    missing=sorted(n for n in old.namelist() if n.startswith('assets/') and not n.startswith('assets/.godot/') and not n.endswith('/') and n not in names)
    assert len(missing)==337
    for n in missing:
        assert n.startswith('assets/commons/data/museum/cartridges/') and n.endswith('.scn'),n
        assert (ROOT/n[7:]).read_bytes()==old.read(n),n
    with zipfile.ZipFile(unsigned,'w') as patched:
        for entry in current.infolist():
            name=entry.filename.upper()
            if name=='META-INF/MANIFEST.MF' or (name.startswith('META-INF/') and name.endswith(('.SF','.RSA','.DSA','.EC'))):continue
            patched.writestr(entry,current.read(entry))
        for name in missing:patched.writestr(old.getinfo(name),old.read(name))
run([sdk/'zipalign.exe','-P','16','-f','4',unsigned,aligned])
run(['java','-jar',sdk/'lib/apksigner.jar','sign','--ks',Path.home()/'AppData/Roaming/Godot/keystores/debug.keystore','--ks-key-alias','androiddebugkey','--ks-pass','pass:android','--key-pass','pass:android','--v4-signing-enabled','false','--out',target,aligned])
assert cert(target)==cert(build['apk'])==cert(prior['apk'])
run([sdk/'zipalign.exe','-c','-P','16','4',target])
with zipfile.ZipFile(target) as z:assert z.testzip() is None
(OUT/'build-original.json').write_text(json.dumps(build,indent=2)+'\n',encoding='utf8')
build['post_export_repair']={'reason':'337 unchanged cached scenes absent from frozen stage','original_apk':build['apk'],'original_sha256':build['sha256'],'baseline_sha256':prior['sha256'],'restored':missing,'matches_current_source':True,'signature_matches_original':True,'alignment_verified':True}
build.update(apk=str(target),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),bytes=target.stat().st_size)
(OUT/'build.json').write_text(json.dumps(build,indent=2)+'\n',encoding='utf8')
print(json.dumps({'restored':len(missing),'apk':str(target),'sha256':build['sha256']}))
