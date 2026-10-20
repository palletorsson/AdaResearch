"""Extract the printed QFEP Phi lesson, then run Godot assertions and hand-input tests."""
from datetime import datetime
import hashlib
import json
import os
import re
import subprocess
from build_qfep_phi import ROOT, OUT, prepare

def main():
    learner = prepare()
    receipt = OUT/'headless.json'
    if receipt.exists():
        receipt.unlink()
    engine = os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
    command = [engine, '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--log-file', str(OUT/'headless-engine.log'),
        '--script','res://tools/probes/qfep_phi_student.gd','--',
        'res://'+learner.relative_to(ROOT).as_posix()+'/',str(receipt),'--no-bridges']
    started = datetime.now().astimezone().isoformat()
    with (OUT/'headless.log').open('w',encoding='utf8') as log:
        result = subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=90,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    text = (OUT/'headless.log').read_text(encoding='utf8',errors='replace')
    errors = [line for line in text.splitlines() if re.search(r'(SCRIPT ERROR|^ERROR:|Assertion failed)',line)]
    data = json.loads(receipt.read_text(encoding='utf8')) if receipt.exists() else {'passed':False,'checks':[],'failures':['No fresh receipt']}
    data.update(started=started,exit_code=result.returncode,errors=errors,
        printed_assertions=len(re.findall(r'^\s*assert\(', (learner/'change_checks.gd').read_text(encoding='utf8'),re.M)),
        extraction_sha256=hashlib.sha256((OUT/'extraction.json').read_bytes()).hexdigest())
    data['passed'] = data['passed'] and result.returncode==0 and not errors
    receipt.write_text(json.dumps(data,indent=2),encoding='utf8')
    print(json.dumps(data,indent=2))
    return 0 if data['passed'] else 1

if __name__=='__main__':
    raise SystemExit(main())
