"""Re-run existing physical-control suites without overwriting earlier evidence."""
from pathlib import Path
import json, shutil, subprocess
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CASES = [
    ('grammar','test_physical_stepped_slider.gd','physical-slider'),
    ('fitness','test_fitness_physical_console.gd','fitness-console'),
    ('edge','test_edge_physical_console.gd','edge-console'),
]
results = {}
for name, source, previous in CASES:
    out = HERE/'regression'/name
    out.mkdir(parents=True, exist_ok=True)
    if name != 'grammar':
        shutil.copytree(HERE.parent/previous/'before',out/'before',dirs_exist_ok=True)
    prefix = 'res://'+out.relative_to(ROOT).as_posix()+'/'
    script = (ROOT/'commons/testing'/source).read_text(encoding='utf-8')
    script = script.replace('res://doc/reports/interfaces-2026-09-21/'+previous+'/',prefix)
    (out/'test.gd').write_text(script,encoding='utf-8')
    report = out/'checks.json'
    if report.exists(): report.unlink()
    command = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),
               '--xr-mode','off','--audio-driver','Dummy','--resolution','1600x1200',
               '--rendering-method','mobile','--log-file',str(out/'engine.log'),
               '--script',prefix+'test.gd']
    with (out/'run.log').open('w',encoding='utf-8') as log:
        result = subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=180,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    assert result.returncode == 0, (name,result.returncode)
    assert 'SCRIPT ERROR' not in (out/'run.log').read_text(encoding='utf-8',errors='replace'), name
    data = json.loads(report.read_text(encoding='utf-8'))
    assert not data['failures'], data
    results[name] = data
    print(name,data['checks'],'PASS',flush=True)
(HERE/'regressions.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
