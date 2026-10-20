from pathlib import Path
import subprocess,json,sys,hashlib,re
from write_postcrisis_tutorials import ROOT,HALLS
runtime=['project.godot','addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn']
runtime_hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in runtime}
for hall in HALLS:
    if len(sys.argv)>1 and hall not in sys.argv[1:]:continue
    command=[sys.executable,'tools/run_encounter_probe.py',hall,'--sequence','postfoundationscrisis','--render','--no-bridges','--output-tag','postcrisis_reconstruction','--probe','tools/probes/postcrisis_museum.gd']
    result=subprocess.run(command,cwd=ROOT)
    folder=ROOT/'ada_run/encounter_pilot'/hall/'postcrisis_reconstruction'
    assert result.returncode==0,hall
    log=(folder/'stdout.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log,hall
    assert 'Viewport Texture must be set' not in log,hall
    assert 'rwex60pqapc' not in log,hall
    report=json.loads((folder/'report.json').read_text());assert report['passed'],report['failures']
    report['runtime_sources']=runtime_hashes
    report['loading_warnings']=[{'artifact':m[0],'milliseconds':int(m[1])} for m in re.findall(r': (\S+) took (\d+) ms to build',log)]
    (folder/'report.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    print(hall,len(report['checks']),'native checks',flush=True)
