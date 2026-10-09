from pathlib import Path
import json, subprocess, sys
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
report = HERE/'checks.json'
if report.exists(): report.unlink()
command = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode','off','--audio-driver','Dummy','--resolution','1600x1200',
           '--rendering-method','mobile','--log-file',str(HERE/'engine.log'),
           '--script','res://commons/testing/test_mounted_physical_consoles.gd']
with (HERE/'run.log').open('w',encoding='utf-8') as log:
    try:
        result = subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=180,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    except subprocess.TimeoutExpired:
        print('TIMEOUT'); sys.exit(124)
if report.exists():
    data = json.loads(report.read_text(encoding='utf-8'))
    print(len(data['checks']),'checks; failures:',data['failures'])
else:
    print((HERE/'run.log').read_text(encoding='utf-8',errors='replace')[-6500:])
sys.exit(result.returncode)
