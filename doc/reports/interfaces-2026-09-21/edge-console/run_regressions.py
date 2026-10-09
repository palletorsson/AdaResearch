from pathlib import Path
import subprocess, json, shutil
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CASES = [
 ('grammar', 'commons/testing/test_physical_stepped_slider.gd', 'res://doc/reports/interfaces-2026-09-21/physical-slider/'),
 ('fitness', 'commons/testing/test_fitness_physical_console.gd', 'res://doc/reports/interfaces-2026-09-21/fitness-console/'),
]
results = {}
for name, source, previous in CASES:
    out = HERE/'regression'/name
    out.mkdir(parents=True, exist_ok=True)
    if name == 'fitness':
        shutil.copytree(HERE.parent/'fitness-console/before', out/'before', dirs_exist_ok=True)
    res_dir = 'res://' + out.relative_to(ROOT).as_posix() + '/'
    script = (ROOT/source).read_text(encoding='utf-8').replace(previous, res_dir)
    (out/'test.gd').write_text(script, encoding='utf-8')
    cmd = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
           '--xr-mode','off','--audio-driver','Dummy','--resolution','1600x1200',
           '--rendering-method','mobile', '--log-file', str(out/'engine.log'),
           '--script', res_dir+'test.gd']
    with (out/'run.log').open('w', encoding='utf-8') as log:
        result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, timeout=100,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    assert result.returncode == 0, (name, result.returncode)
    checkfile = out/('control-checks.json' if name=='shannon' else 'checks.json')
    data = json.loads(checkfile.read_text())
    assert not data['failures'], data
    results[name] = data
    print(name, data['checks'], 'PASS', flush=True)
(HERE/'regressions.json').write_text(json.dumps(results, indent=2))
